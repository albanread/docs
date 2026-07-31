+++
title = "The role of Tcl for agents"
date = 2026-07-31
description = "Across the portfolio, one small language keeps showing up in the same role: Tcl, the remote control an agent — human or AI — uses to drive a living VM, IDE, or game. A look at how, and why."
[taxonomies]
tags = ["tcl", "agents", "automation", "control-plane", "testing", "vm-service", "tooling"]
+++

_None of these projects is written in Tcl. Every one of them can be **driven** by
it. That gap is the whole story._

## TL;DR

- Each system in the portfolio — a Smalltalk VM, a Dart IDE, a Modula-2 game, an
  assembled arcade cabinet — grows the same appendage: a small vocabulary of
  **Tcl verbs** that let something *outside* the program poke it, step it,
  screenshot it, read its state, and assert on it.
- That "something outside" is increasingly an **AI agent**. The verbs are the
  agent's hands and eyes; Tcl is the language they're written in.
- It shows up in two shapes: **embedded in-process** (link `libtcl` into the
  binary — MACVM's `rusttcl`, MRASM's `nanotcl`) and **out-of-process over a
  socket** (a `tclsh` client — MACDART's `dartui.tcl`).
- The design that makes it work for agents isn't the language, it's the
  discipline: **never hang, never deadlock, demux your events, expose the private
  introspection.**

## The problem: how do you drive something that's alive?

A compiler you can test with files in and files out. A *running system* — a VM
holding a heap, an IDE with a cursor in a live method, a game mid-frame — you
can't. To check that it works, to capture a screenshot for the gallery, to let
an agent explore it, you need a way to reach **into a process that is already
running** and: send it input, advance its clock, read its state, take its
picture — without recompiling it, and without wedging it.

That is a remote-control problem, and across the portfolio it gets the same
answer every time: a little Tcl.

## The shape: a vocabulary of verbs

The pattern is always a **small set of verbs** that read like a domain-specific
remote control. From MacModula2's headless test of its Cocoa asteroids demo:

```tcl
# Headless smoke test: render, then spray-fire in a sweep and confirm rocks
# get hit (score climbs) using the `get` state-query verb.
snap /tmp/ast_a.png
while {$i < 30} {
  key fire
  key left
  step 4
  incr i
}
snap /tmp/ast_b.png
puts "score=[get score]  asteroids=[get asteroids]  wave=[get wave]  over=[get gameover]"
```

Four verbs — `snap`, `key`, `step`, `get` — and you have a complete agent loop:
*act* (`key`), *advance time* (`step`), *observe* (`snap`, `get`), *assert*.
Point an AI agent at those four words and it can play the game, notice when the
score stops climbing, and file a bug — no access to the source required.

This is why the verbs matter more than the language: **the verb list is the API
an agent programs against.** Tcl is just the most convenient thing to write them
in.

## In-process: embed the interpreter (MRASM's `nanotcl`)

The tightest coupling links a Tcl interpreter straight into the running program's
address space, then exposes the program's own internals as plain Tcl variables.
MRASM does exactly this — and names the intent in the first line of the file:

```tcl
# check.tcl — an agent test hook. nanotcl runs this at every frame-sync sample
# with the game's registers exposed as TCL vars (rax, rcx, … and prev_rax, …).
assert [expr {$rax > $prev_rax}] "tick must advance (rax=$rax prev=$prev_rax)"
assert [expr {$rcx != $prev_rcx || $rdx != $prev_rdx}] "ship orbit is stuck"
Pset rcx=8 rdx=8 r8=15   ;# the hook can also drive: drop a marker pixel
```

`nanotcl attach 2 6 check.tcl` and the hook fires every frame with the machine
registers (`rax`, `rcx`, …) *and their previous values* (`prev_rax`, …) bound as
Tcl variables. The script asserts invariants across frames and can write back
into the machine (`Pset`). An assembler — the lowest-level project in the set —
gets an agent-legible conscience for the cost of embedding a tiny interpreter.

[MACVM](/posts/macvm) does the in-process embed at the other end of the
abstraction ladder: its Cocoa VM hosts **`rusttcl`**, a Tcl interpreter living
inside `macvm-cocoa`, so a `tcl` verb *inside the running Smalltalk VM* can drive
the world and its live Cocoa windows. It's the earliest instance of the pattern,
and the one the others were shaped to match.

> _To expand once the `rusttcl` details are confirmed: the exact verb surface it
> exposes inside macvm-cocoa, and how a script reaches the Smalltalk world and
> the ObjC bridge from Tcl._

## Out-of-process: one socket, two powers (MACDART's `dartui.tcl`)

The other shape keeps Tcl *outside* the program and talks to it over a socket —
no rebuild of the target, and a crash in the driver can't take down the app.
[MACDART](/posts/macdart)'s control plane is a standalone `tclsh` client that
opens **one WebSocket** to the Dart VM's own vm-service (the old "Observatory", a
JSON-RPC 2.0 server the VM already hosts) and gets *both* halves of control
through it. From the header of `dartui.tcl`:

```
# MACDART control plane in Tcl — VM introspection AND GUI control, one socket.
#   obs <method> ?k v …?   built-in RPC    getVM, getStack, _getCpuProfile, …
#   ui  <control line>     GUI control     via the ext.dartui.send extension
#   on  <stream>           subscribe       Debug, GC, Extension, …
#   events                 drain pushed events
```

So `obs getStack` walks the call stack, `obs _getCpuProfile` pulls the profiler,
and `ui open browser Integer` drives the actual IDE — over the same connection.
For an agent, that's the dream: introspection and actuation in one vocabulary,
against a live process, with no instrumentation added to the target.

### The interesting part is the discipline, not the socket

What makes this *usable by an agent* rather than merely possible is a set of
decisions that all point the same way — the driver must stay in control even
when the target misbehaves:

- **Never hang; a silent server is an error.** Every read has a deadline:
  > "the old blocking read parked the whole suite when a do-it stopped at a
  > breakpoint" — so a timeout raises `no reply within 30000ms — is the isolate
  > paused, or the app gone?` instead of freezing the agent forever.
- **Never deadlock.** A "do-it" that will stop at a breakpoint can't answer until
  you continue it — so `dartui.tcl` adds `uibg`, which fires the command with
  `nowait true` and gets an immediate "started" back. Awaiting the real reply on
  the one socket would wedge both sides.
- **Demux replies from events.** Responses and server-pushed events share the
  socket; the client matches replies by JSON-RPC `id` and stashes everything else
  for `events` to drain. An agent never loses a GC or breakpoint notification
  just because it was mid-request.
- **Own the transport.** tcllib's `websocket` "silently never completes" the 101
  upgrade with the bundled http package, so the client hand-rolls the ~30 lines
  of RFC 6455 it actually needs. Determinism beats a dependency that fights you.
- **Track a moving target.** Service extensions register *per isolate*, so `ui`
  re-resolves which isolate owns `ext.dartui.send` after every respawn.

None of that is about Tcl. It's about what an *agent-facing* control plane has to
guarantee: bounded time, no deadlocks, no lost events, no surprises.

## The shared runtime

All of this stands on one locally-built **Tcl 8.6.15 + Tcllib** (no Tk —
`tclsh` only), compiled once with `sqlite3`, `thread`, `tdbc`, and `json`
support and reused across the portfolio. The design note that accompanies it is
blunt about the key realization:

> "The Observatory is **not** a library you link against. It is the VM's own
> vm-service … a client for the server already running."

That sentence is the whole philosophy: don't build control *into* the tool as a
bespoke API — expose a **generic surface** (a socket, a register table, a verb
set) and let a small, throwaway Tcl script be the client. The client is ~150
lines you can own, regenerate, or let an agent rewrite on the fly.

## Why Tcl, specifically, for agents

Any language can open a socket. Tcl keeps winning this particular job for
reasons that line up almost exactly with what an agent needs from a driver:

- **It embeds in anything.** `libtcl` links into a Rust VM (`rusttcl`) or an
  assembler's runtime (`nanotcl`) in a few lines, giving you an in-process
  scripting surface with no IPC at all.
- **It's string-first, so host state maps onto it directly.** Exposing CPU
  registers or a game's score as ordinary Tcl variables (`rax`, `score`) is
  natural, not a serialization project. `upvar`/`uplevel` make "the program's
  state *is* your variables" the default.
- **The event loop is built in.** `fileevent`, `vwait`, and `after` are exactly
  the primitives a socket client and a frame-sampling hook need — including the
  timeouts that keep an agent from hanging.
- **No compile step, and a REPL.** An agent writes a verb sequence and runs it
  immediately, watches the result, and iterates — the same edit-run loop the
  agent already lives in. A compiled client would put a build between every
  thought.
- **The verbs read like something an agent would generate.** `key fire; step 4;
  snap out.png; get score` is a plan, not a program. That legibility is the
  point: the control surface is small enough for a model to use correctly on the
  first try.

## The through-line

Look across the portfolio and the same organ keeps growing in different animals:
`nanotcl` inside an assembler, `rusttcl` inside a Smalltalk VM, `dartui.tcl`
outside a Dart IDE, `key`/`step`/`snap`/`get` around a Modula-2 game. Different
hosts, one idea — **give the system a small Tcl remote control, and it becomes
something an agent can operate.** In a portfolio increasingly built and tested
*with* AI agents, that remote control isn't a convenience. It's the interface.

## Screenshots

> _Add to `static/images/tcl-for-agents/`: a `dartui.tcl` session driving the
> live IDE; a MacModula2 gallery shot captured by `snap`; a `nanotcl` assert
> log; a side-by-side of the same verb vocabulary across two projects._

![A Tcl session driving a live VM over the vm-service socket](/images/tcl-for-agents/01.png)

## Related

- [MACVM](/posts/macvm) — the in-process `rusttcl` embed (the origin of the verb shape)
- [MACDART](/posts/macdart) — the out-of-process `dartui.tcl` control plane
- [MacModula2](/posts/macmodula2) — `key`/`step`/`snap`/`get` driving Cocoa game demos
- [MRASM](/posts/mrasm) — `nanotcl`, the "agent test hook" with registers as Tcl vars
