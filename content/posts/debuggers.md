+++
title = "Debuggers, from a brk to the Observatory"
date = 2026-07-31
description = "A debugger is one idea — see the program's state at a moment you chose — and the machinery around it ranges from a single CPU instruction to a full JSON-RPC service. A movable breakpoint you binary-search a crash with; the system debugger that's powerful but painful to drive; WRASM's per-frame introspector that debugs a running game from the inside; and Dart's Observatory, a scriptable remote debugger. The cheapest rung is often the most useful."
[taxonomies]
tags = ["debugger", "breakpoints", "diagnostics", "observatory", "introspection", "agents"]
+++

_A debugger does exactly one thing: it lets you see the program's state at a
moment you chose. Breakpoints, stepping, watchpoints, evaluate — all of it is
machinery around that single idea. And the machinery spans an enormous range, from
one CPU instruction to a hosted service with a protocol. You want the whole rack,
because the cheapest lens is very often the one that finds the bug._

## TL;DR

- **Rung 0 — a movable `brk`.** One trap instruction, a good signal handler, and
  an argument to *move the breakpoint from the command line*. Binary-search a
  crash: divide and conquer until you're standing on the exact instruction, looking
  at the registers.
- **Rung 1 — the system debugger (lldb/gdb).** Everything, but a whole language to
  drive — and *wrong* on a bespoke runtime whose stack it can't read.
- **Rung 2 — the in-process introspector.** WRASM's per-frame hook that stops a
  running game at a frame boundary and shows its registers *from the inside*.
- **Rung 3 — the Observatory.** Dart's VM hosts a full JSON-RPC debugger; once the
  protocol is on, you set breakpoints from the command line. Deeply sophisticated.
- The axis that matters most now isn't simple↔powerful. It's **who can drive it** —
  a human at a REPL, or a script (and an agent).

## Rung 0: one instruction, moved from the command line

The smallest possible debugger is a single instruction — `int3` on x86, `brk` on
arm64 — that raises a trap, plus a handler that catches it and dumps everything:
registers, stack, the faulting location. [JASM](/posts/jasm)'s crash dumper does
precisely this, and adds the trick that makes it a *tool* rather than a
tombstone — the breakpoint doesn't have to be fatal:

> "`int 3` is non-fatal … the handler dumps state, advances `RIP` past the 1-byte
> `0xCC`, and returns `EXCEPTION_CONTINUE_EXECUTION` — so a `brk()` macro becomes a
> 'dump state and keep going' inspector." — JASM `seh.rs`

(A nice architecture wrinkle lives right here: x86's `int3` leaves `RIP` past the
byte, but "aarch64 `brk` does not" advance `PC` — so the arm64 handler has to step
it itself. The debugger has to know the shape of its own trap.)

Now add the one feature that turns this from a print statement into a method: **let
the command line move the breakpoint.** A hit-count — "fire on the Nth time you
reach here" — plus a chosen location is all you need to **divide and conquer.** Put
the break halfway through the suspect region; does the program reach it in a good
state? Move it later, or earlier; halve the interval again. In a handful of runs
you've bracketed the exact instruction where the state first goes wrong, and you're
looking at the registers *the moment before* it does. No protocol, no external
process, no debug info — just you, a trap you can place anywhere, and the truth.

That this is often the *most* useful debugger is not a paradox. You control exactly
where you stop, you see exactly what's there, and nothing sits between you and the
machine to lie to you.

## Rung 1: the system debugger, powerful and painful

lldb and gdb are the full article: breakpoints, single-stepping, watchpoints,
expression evaluation, backtraces, the works. When you have native code with real
debug info, reach for them. But two things push in the other direction.

First, they are a language of their own to drive. Scripting lldb well is a project;
driving it *interactively* is a human sitting at a prompt. The simplicity of rung 0
is a genuine, underrated advantage — a `brk` you move from `argv` has no learning
curve and no session to manage.

Second, and more sharply: a system debugger only knows what the platform's ABI
tells it, and a bespoke runtime often breaks that contract on purpose. JASM's
subroutine-threaded Forth *cannot* satisfy the Win64 unwind ABI — `RSP` is the
Forth return stack, not a call stack — so a stack-walking debugger "would produce
confidently-wrong frames." For that runtime, the hand-rolled, Forth-aware dump
isn't a poor substitute for lldb; it's *more correct* than lldb, because it
understands the machine's actual discipline and lldb assumes a discipline that
isn't there.

## Rung 2: debugging from the inside (WRASM's introspector)

Between "stop from outside" and "printf" is a third thing: a debugger that *runs
with* the program and samples it from within. [WRASM](/posts/wrasm)/[MRASM](/posts/mrasm)'s
**nano-TCL** does this to a running game. Turn it on and it stops the world at a
frame boundary and shows you the machine, live:

> "`intro rcx=N` → every `N` frames, `TclFrameSync` **blocks the game thread at the
> frame boundary**, pings the 16 shadow registers down the pipe, and waits; `cont`
> releases the held frame." — MRASM `nano-tcl-breakpoints.md`

So it can "stop the world, show registers, and continue" — a debugger built *into*
the program, stepping it a frame at a time, speaking the program's own terms
(registers as named variables, game state as values). Its design notes draw the
exact distinction that separates it from rung 3: this pause is **temporal** —
"stop every N frames" — whereas a true breakpoint is **spatial** — "stop when
control reaches `Pset`, and show me the arguments *the game itself* passed." That
gap ("closer than it looks," the doc says, but not yet closed) is precisely the
line between a per-frame introspector and a real debugger — and it's a clarifying
way to see what a breakpoint actually *is*: a location trigger, not a clock.

[MACVM](/posts/macvm) sits a rung higher still with a genuine source-level
debugger (`DEBUGGER.md`, the HALT debugger, `bp`/`bp-clear`/`bp-list` verbs) — a
Smalltalk debugger you drive with the same [Tcl verbs](/posts/tcl-for-agents) that
introspect the JIT, which is the natural bridge to the top of the ladder.

## Rung 3: the Observatory, a debugger as a service

At the far end is something genuinely amazing: the DartVM's **Observatory** (its
vm-service), and [MACDART](/posts/macdart) inherits it whole. It is a debugger
turned inside-out — not a tool you attach, but a **JSON-RPC 2.0 service the VM
itself hosts** over a WebSocket, once you launch with `--observe`. Everything a
sophisticated debugger does is an RPC: `addBreakpoint`, `resume` (with step modes),
`getStack` (with async causal chains), `evaluate` (run code inside a paused
isolate), object-graph walks, retaining paths, a CPU profiler, and live event
streams for pause/GC/isolate events.

The consequence the framing calls out is exactly right: **once the protocols are
enabled and defined, you set breakpoints from the command line.** MACDART's Tcl
client exposes `obs bp <isolate> <script> <line>` → `addBreakpoint` and `obs
resume`, so a full source debugger is driven by typing verbs — or by a script, or
by an agent. This is the opposite of rung 0's simplicity, and both are right: rung
0 is zero-setup and speaks raw machine state; rung 3 is heavyweight and speaks your
*language's* state (isolates, frames, source lines, live objects), remotely and
programmatically. The price is that the VM has to host the protocol and you have to
turn it on; the reward is a complete, scriptable, remote debugger.

## Expanding the topic: the axes underneath the ladder

The four rungs aren't just "more powerful"; they trade along several independent
axes, and knowing which one you need is the skill:

- **In-process vs. out-of-process.** Rungs 0 and 2 live *inside* the program — a
  signal handler, an embedded hook — so they're trivial and speak your
  abstractions, but a fully-wedged process can't run them. Rungs 1 and 3 attach
  from *outside* and survive a hang, but must reconstruct your runtime's meaning
  through a general lens (and sometimes get it wrong, as lldb does on the Forth).
- **Temporal vs. spatial.** A frame-sampler ("every N frames") answers *what is
  happening over time / why is it slow*; a breakpoint ("when control reaches here")
  answers *what is the exact state at this point.* WRASM's doc naming this gap is
  the clearest statement of it I know.
- **Stopping vs. continuing.** JASM's dump-and-continue `brk` is a hybrid — a
  breakpoint that doesn't stop, a `printf` that shows you *everything* — and it's
  underused. Not every look needs a halt.
- **Optimized code fights back.** The moment a [real JIT](/posts/two-jits) inlines
  and elides, an optimized frame stops matching the source: variables vanish into
  registers, callees vanish into their callers. Debugging it means either dropping
  to the machine (rung 0 shows you the JIT's output, not your source) or leaning on
  the VM's deopt metadata to reconstruct a source-level view (rung 3's whole
  advantage). This is why a serious runtime wants *both* ends of the ladder, not
  one.
- **Who drives it — the modern axis.** As with [text](/posts/text-at-every-stage),
  the reviewer might be an agent, and it changes the ranking. A movable `brk`
  (rung 0) and a protocol you send verbs to (rung 3) are trivially scriptable and
  agent-friendly. An interactive lldb session (rung 1) is agent-*hostile*. So the
  ladder isn't only simple→sophisticated; it's also human-only → programmable, and
  the two useful ends are the ones you can drive without a human at a prompt.

## The through-line

Buy the whole rack of lenses. A single `brk` you can move from the command line is
the fastest way in existence to bracket a crash and read the registers the instant
before it dies — build it yourself, it's an afternoon, and it never lies to you.
An in-process introspector debugs your running game in its own language, from the
inside. The Observatory is a complete, scriptable, remote debugger for when you've
earned the protocol to host it. The system debugger sits in the powerful, awkward
middle. None of them is "the debugger" — they're points on a line from *one
instruction* to *a hosted service*, and the craft is reaching for the lowest rung
that can see your bug. Increasingly, that choice is also about who's holding the
lens — and the simplest and the most protocol-driven debuggers are the two a script,
or an agent, can actually use.

## Screenshots

> _Add to `static/images/debuggers/`: a movable-`brk` dump at three binary-search
> positions; WRASM's frame-sync register ping; MACVM's HALT debugger; `obs bp …`
> setting a Dart breakpoint from the command line._

![The ladder: a brk + signal handler, lldb, WRASM's frame introspector, the Observatory.](/images/debuggers/01.png)

## Related

- [Text at every stage](/posts/text-at-every-stage) — a debugger is text-at-a-chosen-moment; the crash dump is rung 0's output
- [Tcl for agents](/posts/tcl-for-agents) — the verbs that drive both the introspector and the Observatory
- [Two things called JIT](/posts/two-jits) — why optimized code needs the top of the ladder
- [JASM](/posts/jasm) — the `brk`/VEH dump-and-continue inspector · [MACDART](/posts/macdart) — the Observatory
