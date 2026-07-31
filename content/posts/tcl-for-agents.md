+++
title = "The role of Tcl for agents"
date = 2026-07-31
description = "Across the portfolio the same organ keeps growing in different animals: a small Tcl-shaped remote control an agent — human or AI — uses to drive a living VM, IDE, or game. It was reimplemented from scratch three times rather than imported, which tells you what it's really for."
[taxonomies]
tags = ["tcl", "agents", "automation", "control-plane", "mcp", "testing", "tooling"]
+++

_Almost none of these projects links a Tcl library. Most of them **rebuilt Tcl
from scratch** — in Rust, in Modula-2, in x86-64 assembly — just to get the same
small remote control. That nobody imported it, and everyone rebuilt it, is the
whole story._

## TL;DR

- Each living system in the portfolio grows the same appendage: a small
  vocabulary of **Tcl verbs** that let something *outside* the program drive it,
  step it, screenshot it, read its state, and assert on it.
- That "something outside" is increasingly an **AI agent**. The verbs are the
  agent's hands and eyes.
- It comes in two shapes. **Out-of-process:** one project ([MACDART](/posts/macdart))
  runs a real `tclsh` client on a socket. **In-process:** everyone else embeds a
  *reimplemented* Tcl core — `rust-tcl` (Rust), `ptcl` (Modula-2), nano-TCL
  (assembly) — because it's the **shape** of Tcl they want, not any particular
  distribution.
- [Locus](/posts/locus) closes the loop: it exposes Tcl as a `run_tcl` **MCP
  tool**, so an agent scripts the compiler in one call. Tcl *is* the agent API.

## The problem: how do you drive something that's alive?

A compiler you can test with files in and files out. A *running system* — a VM
holding a heap, an IDE with a cursor in a live method, a game mid-frame — you
can't. To check that it works, to capture a gallery screenshot, to let an agent
explore it, you need to reach **into a process that is already running** and send
it input, advance its clock, read its state, take its picture — without
recompiling it and without wedging it.

That is a remote-control problem, and across the portfolio it gets the same
answer every time: give the system a small set of Tcl verbs.

## The shape: a vocabulary of verbs

The pattern is always a **verb list** that reads like a domain-specific remote
control. Here is MacModula2's headless test of its Cocoa asteroids demo — four
verbs and you have a complete agent loop:

```tcl
# render, then spray-fire in a sweep and confirm rocks get hit (score climbs)
snap /tmp/ast_a.png
while {$i < 30} { key fire; key left; step 4; incr i }
snap /tmp/ast_b.png
puts "score=[get score]  asteroids=[get asteroids]  wave=[get wave]  over=[get gameover]"
```

*Act* (`key`), *advance time* (`step`), *observe* (`snap`, `get`), *assert*.
Point an AI agent at those four words and it can play the game, notice when the
score stops climbing, and file a bug — with no access to the source. **The verb
list is the API an agent programs against;** Tcl is just the most convenient way
to spell it.

## The tell: it was reimplemented three times

Here is the part that turns a convenience into a thesis. If you `grep` the whole
portfolio for the C Tcl entry points (`Tcl_CreateInterp`, `Tcl_Main`), you find
**nothing** — no binary links `libtcl`. And yet Tcl verbs are everywhere. The
resolution: the in-process embeddings are **independent reimplementations of
Tcl-the-idea**, written from scratch in whatever the host language happened to
be:

| Implementation | Written in | Lives in |
|---|---|---|
| **`rust-tcl`** | pure Rust, zero-dependency | born in [locus](/posts/locus); embedded in MACVM, MF66/MF67, MRASM |
| **`ptcl`** ("PaneShell Tcl") | Modula-2 | [MacModula2](/posts/macmodula2)'s IDE + demo harness |
| **nano-TCL (Tier-1)** | x86-64 assembly | inside MRASM/WRASM game `.exe`s |

Three teams, three host languages, and each one chose to **rebuild** the verb
table + string values + `[command]`/`$var` substitution + deferred `{}` blocks
rather than import a Tcl. You don't reimplement a language three times by
accident. What they wanted wasn't Tcl the distribution — it was the *minimal
shape of Tcl* as a control surface, and it was worth rewriting to get it exactly
and dependency-free. `rust-tcl`'s own README states the design intent:

> "designed for application-owned verbs: the language kernel parses and runs
> scripts, while each embedding project registers the verbs that make sense for
> its own automation surface." — `rust-tcl` README

## In-process, case by case

### MACVM — `rusttcl`, an introspection shell that scripts the VM

[MACVM](/posts/macvm) vendors `rust-tcl` and wraps it in a `RusttclCtx` that owns
a live `VmState`, so a script drives the running Smalltalk VM with real control
flow. On top of the core verbs (`set/if/while/proc/expr/…`) it registers a
diagnostics vocabulary:

| verb | does |
|---|---|
| `disasm` / `disasm-native` | dump a method's bytecode / its JIT machine code |
| `ic <Class> <sel>` | inline-cache state per send site (Mono/Poly/Mega + klasses) |
| `stats`, `ring` | VM counters; the PROBE compile/deopt/invalidate history |
| `flag jit off`, `trace` | flip live VM flags and trace channels |
| `pin` / `unpin` | force-interpret a method / restore tier-up |
| `gui …` | drive a running `macvm-cocoa` window |

The rationale (`docs/RUSTTCL.md`) is exactly the "living system" argument:

> "a diagnostic session is a script, not just a sequence of one-shot commands."

And the `gui` verb makes the screenshot point explicit — even the in-process
shell reaches the Cocoa GUI over a tiny opt-in loopback channel
(`MACVM_COCOA_CTL`), marshalled onto the AppKit main thread:

> "'only a human can look at it' is false the moment the screen is scriptable:
> `gui view browser`, `gui snap out.png`, read the PNG." — `cocoa_gui/src/control.rs`

### MF66 / MF67 — the "TCL agentic control layer"

The [Forth](/posts/mf66) [workspaces](/posts/mf67) embed the same `rust-tcl` in a
`wsdriver` whose header says the quiet part out loud:

> "The TCL agentic control layer … so a script (or an agent emitting TCL) can
> manipulate and observe the workspace without a desktop." — `src/wsdriver.rs`

Its verbs — `eval type key focus open save click drag stack depth output screen
screenshot assert assert-eq` — are a full headless-IDE driver: an agent can open
a file, type into the editor, click a splitter, screenshot the result, and
assert on the stack, all without a display attached.

### MRASM — nano-TCL, a two-tier agent test harness

[MRASM](/posts/mrasm) uses it twice. The **studio** embeds `rust-tcl` to drive
its IDE for scripted UI tests. And **nano-TCL** is an explicit CI harness with a
sharp two-tier split — the smart half in the tool, a dumb executor in the game:

> "Smart TCL in Rust. Dumb register-machine execution in the live game …
> The game never learns what a variable is." — `docs/nano-tcl.md`

The driver runs full `rust-tcl` locally and forwards `reg=val` verbs over a pipe
to a Tier-1 nano-TCL executor **hand-written in x86-64 assembly** inside the
game. That is where `check.tcl` runs — "an agent test hook" with the machine's
registers bound as Tcl variables every frame:

```tcl
# nanotcl runs this at every frame-sync sample, registers exposed as TCL vars
assert [expr {$rax > $prev_rax}] "tick must advance (rax=$rax prev=$prev_rax)"
assert [expr {$rcx != $prev_rcx || $rdx != $prev_rdx}] "ship orbit is stuck"
Pset rcx=8 rdx=8 r8=15   ;# the hook can also drive: drop a marker pixel
```

The doc's own framing: "a probe rather than a remote control: it drives,
inspects, watches, and reports faults, all on one wire."

### MacModula2 — `ptcl`, a Tcl dialect written in Modula-2

[MacModula2](/posts/macmodula2) didn't reach for Rust or C; it wrote its own Tcl
dialect *in Modula-2* (`Ptcl.mod`), embedded in the IDE and the demo harness.
`Ptcl.def` states the whole philosophy in a line:

> "a tiny embeddable Tcl dialect (PaneShell Tcl) … Everything is a string."

Same verbs you'd expect: `help/topics/describe/open/snap/resize` for the IDE,
`step/key/snap/get` for headless game-demo testing to offscreen PNGs.

## Out-of-process — MACDART's one-socket control plane

Only [MACDART](/posts/macdart) uses **real C Tcl** — a standalone `tclsh8.6`
client (the shared, locally-built Tcl 8.6.15 + Tcllib) that opens **one
WebSocket** to the Dart VM's own vm-service and gets both halves of control
through it:

```
# MACDART control plane in Tcl — VM introspection AND GUI control, one socket.
#   obs <method> ?k v …?   built-in RPC    getVM, getStack, _getCpuProfile, …
#   ui  <control line>     GUI control     via the ext.dartui.send extension
#   on  <stream>           subscribe       Debug, GC, Extension, …
```

`obs _getCpuProfile` pulls the profiler; `ui open browser Integer` drives the
actual IDE — same connection, no instrumentation added to the target, and if the
driver crashes it can't take the app down with it.

### The discipline is the point, not the socket

What makes this *usable by an agent* is a set of decisions that all guarantee the
driver stays in control even when the target misbehaves:

- **Never hang.** Every read has a deadline; a silent server raises `no reply
  within 30000ms — is the isolate paused, or the app gone?` rather than freezing
  the agent. (It was written after "the old blocking read parked the whole suite
  when a do-it stopped at a breakpoint.")
- **Never deadlock.** A command that will stop at a breakpoint can't reply until
  you continue it, so `uibg` fires with `nowait true` and gets an immediate
  "started" instead of wedging the one socket.
- **Demux replies from events.** Responses and pushed events share the wire; the
  client matches by JSON-RPC `id` and stashes the rest for `events` to drain.
- **Own the transport.** tcllib's `websocket` "silently never completes" the 101
  upgrade with the bundled http, so the client hand-rolls the ~30 lines of RFC
  6455 it needs. Determinism beats a dependency that fights you.

None of that is about Tcl. It's what an agent-facing control plane has to
promise: bounded time, no deadlocks, no lost events.

## The endpoint: Tcl as an MCP tool (Locus)

[Locus](/posts/locus) — where `rust-tcl` was born — makes the "for agents" part
literal. It embeds the same core inside its **MCP server** as a single tool:

> "run_tcl executes a small Tcl automation language over MCP worker verbs for
> multi-step compiler workflows." — `locus/src/help.rs`

The registered verbs are `locus/check`, `locus/effects`, `locus/ir`,
`locus/asm`, `locus/run`, `locus/help-*`. So an AI agent connected over the Model
Context Protocol doesn't fire six round-trips to compile-check-inspect — it sends
**one** Tcl script that sequences them with real control flow, and gets the
result back. Tcl stops being the language the *test harness* is written in and
becomes the language the *agent* writes.

## Why Tcl, specifically

MacModula2's design note has a section literally titled "Why Tcl," and it lines
up almost exactly with what an agent needs from a driver:

- **Embeddable by design.** "Tk was just its first host; the IDE is the same
  shape — an app with a verb vocabulary that wants glue. We are adopting the
  language built for this, not inventing one."
- **Almost no syntax.** "One rule: `command arg arg …`. Even `if`/`while`/`proc`
  are ordinary commands." (Which is also why rebuilding it three times was
  cheap.)
- **REPL and file format are the same thing** — an agent's script is also its log.
- **Automation is the primary surface**, with "three consumers: the user … the
  config/automation files … the agent harness."

And then the sentence that is really this whole article, from the same note:

> "'Introspectable', 'scriptable', and 'agent-drivable' stop being three
> properties and become the same vocabulary. That is the real prize."

## The through-line

The same organ keeps growing in different animals: `rusttcl` inside a Smalltalk
VM, a `wsdriver` inside two Forth IDEs, nano-TCL split across a Rust tool and an
assembly game, `ptcl` written in Modula-2, `dartui.tcl` on a socket outside a
Dart IDE, and finally a `run_tcl` MCP tool an agent calls directly. Different
hosts, one idea — **give the system a small Tcl remote control and it becomes
something an agent can operate** — held so firmly that four codebases rewrote the
language rather than do without it. In a portfolio increasingly built and tested
*with* agents, that remote control isn't a convenience. It's the interface.

## Screenshots

> _Add to `static/images/tcl-for-agents/`: a `dartui.tcl` session driving the live
> IDE; a MacModula2 gallery shot captured by `snap`; a `nano-TCL` assert log; the
> `run_tcl` MCP tool sequencing compiler verbs._

![A Tcl session driving a live VM over the vm-service socket](/images/tcl-for-agents/01.png)

## Related

- [Locus](/posts/locus) — birthplace of `rust-tcl`; the `run_tcl` MCP tool
- [MACVM](/posts/macvm) — `rusttcl`, the VM-introspection shell + Cocoa driver
- [MACDART](/posts/macdart) — `dartui.tcl`, the one-socket vm-service control plane
- [MRASM](/posts/mrasm) — nano-TCL, the two-tier agent test harness
- [MacModula2](/posts/macmodula2) — `ptcl`, a Tcl dialect written in Modula-2
- [MF66](/posts/mf66) / [MF67](/posts/mf67) — the "TCL agentic control layer"
