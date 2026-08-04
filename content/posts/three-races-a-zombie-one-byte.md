+++
title = "Three thread races, a zombie, and one byte"
date = 2026-08-04
description = "A debugging story from MACDART: intermittent JIT crashes that were a background-compiler race, a test suite that 'hung' at a different command every run, and the single byte-boundary bug in a WebSocket reader that cost more wall-clock than everything else combined."
[taxonomies]
tags = ["debugging", "concurrency", "vm", "jit", "websocket", "smalltalk", "dart"]
[extra]
repo = "https://github.com/albanread/MACDART"
language = "C++ (Dart VM) + Dart + Tcl"
platform = "Apple Silicon (arm64-apple-darwin)"
status = "All fixed — suite green three consecutive runs"
period = "2026-08"
downloads = []
+++

_MACDART is a Dart 1.24.3 VM on Apple Silicon carrying a Smalltalk front end
and a native IDE. This is the story of one debugging campaign against it:
intermittent compiler crashes, a regression suite that died at a different
command every run, and how each hypothesis had to be replaced with bytes before
the real bugs — five of them, wildly different — surfaced. It is written up
because the *methods* are reusable even where the bugs are not._

## TL;DR

- **The crashes** were the Smalltalk loader swapping classes while the VM's
  background compiler thread was reading them. The VM's own debugger already
  knew the rule — stop the background compiler before mutating code it can see
  — and the fix was to extend that courtesy to Smalltalk loads.
- **The audit** that followed found two more races: unguarded loader globals,
  and a persistent-handle allocation reachable from the compiler thread when
  the API contract is mutator-only.
- **The "hang"** was not a hang and not the server: a Tcl WebSocket reader
  used two independent `if`s for extended frame lengths, so a reply of
  **exactly 127 bytes** desynced the connection forever. Request ids grow, so
  every reply's size shifts, so *which* command died moved between runs.
- **A zombie**: killing a Dart isolate that is paused at a breakpoint quietly
  fails — the kill dies with the pause. Restart-while-debugging left a corpse
  that the tooling then attached to.
- The recurring lesson: **every hypothesis eventually had to yield to a byte
  count.** The tools that closed the case were a wire tap, a consumed-byte
  counter, and arithmetic.

## Act I: the crashes

The GUI would die perhaps one boot in three, always somewhere inside the JIT:

```
dart::FlowGraphInliner::TryInlineRecognizedMethod
dart::JitOptimizer::VisitInstanceCall
dart::CompileParsedFunctionHelper::Compile
dart::Compiler::CompileOptimizedFunction     ← the background compiler thread
```

Different stacks on different days — sometimes `Assembler::LoadObjectHelper`,
sometimes the inliner — but three constants: always the compile path, always
adjacent to the Smalltalk loader's own log lines, and never reproducible
headless. That last one matters: headless runs load the world once and compile
quietly; the GUI reloads classes constantly — every image accept, every world
refresh — while three isolates JIT in parallel.

Dart 1.24 runs a **background compiler thread per isolate** for optimized
recompiles. The Smalltalk front end is spliced into the same compilation
pipeline, so its functions get optimized on that thread too — and a Smalltalk
*reload* swaps classes and methods out from under any compile in flight. The
compile holds raw pointers into the old world; it finishes against the new one;
it dies wherever it happens to be standing.

The satisfying part is that the VM already documents the rule. Its own
debugger, before it touches code the background compiler might see, calls
`BackgroundCompiler::Stop(isolate)`. The fix was one call at the top of the
Smalltalk loader's swap, with the same self-healing property — the next
optimized-compile request simply restarts the thread.

With a crash whose signature is "somewhere in the compiler, sometimes", you do
not get to verify with one run. The evidence that closed it: three consecutive
full-suite passes, a boot storm, and three cycles of the crash's exact habitat
— world imports plus browser traffic plus game launches with two extra VMs
churning in parallel — producing zero crash reports where the cluster had
produced one most sessions.

## Act II: the audit

A confirmed race earns its neighbourhood an audit. Everything global and
mutable that the Smalltalk arc had added to the VM process:

- **The loader's retained-AST vector and load counter** — pushed and bumped
  with no lock, from any isolate that loads Smalltalk. Two concurrent loads
  could race the vector or mint the same library URL. Now mutexed.
- **Symbol interning allocated a persistent handle from whatever thread was
  compiling.** The VM's public API wraps that allocation in a scope that
  asserts *mutator thread only*, because the free-list pop underneath is bare.
  A background-thread compile of a `#symbol` literal racing the FFI wrapper
  traffic could hand the same handle to two threads. The intern now declines
  on non-mutator threads and the compiler's documented fallback lowers the
  literal through a runtime call that re-enters on the right thread.
- **The dispatch caches** (the Smalltalk equivalent of inline caches) audited
  clean — every access already under a mutex — but their load-bearing
  assumptions (raw pointers are old-space; old space never moves in 1.24;
  reloads flush) were unwritten. They are written now, at the declarations.

None of this is exotic. It is the oldest concurrency story: code written
single-threaded, later run under a scheduler nobody told it about.

## Act III: the zombie

Meanwhile the regression suite kept failing its debugger section in a way that
smelled different — deterministic, not intermittent. Reduced: restart the
language isolate *while it sits at a breakpoint*, and the old isolate does not
die. `Isolate.kill(IMMEDIATE)` queues behind the debugger pause and perishes
with it. The "restarted" workspace then has two language isolates — one live,
one paused corpse — and the tooling's attach helper picked the *first* match,
which is the corpse, and armed breakpoints in an isolate nothing would ever
run again.

The fix is almost etiquette: before killing, *resume* every language isolate
through the service protocol (no service running means no debugger means
nothing paused — skipping is sound), then verify the corpse is actually gone
and say so loudly if not. And the attach helper now takes the *last* listed
match: the VM lists isolates oldest-first, so corpses sort to the front.

## Act IV: the byte

With the crashes fixed and the zombie buried, the suite still failed — and now
it failed *strangely*. A command would time out waiting for its reply. The GUI
was healthy. The server logs showed the command executed. And the failing
command **moved**: `demorun` one run, `remove` another, always deep in the
suite, never early, never the same place twice. Every classic explanation —
server wedged, event flood, subscription leak — died on the same fact,
established by opening a *second* connection during the stall: the server
answered the new client perfectly while the old one starved.

So the connection itself was sick, and only instrumentation would say how. Three
probes, each cheap, each decisive:

**1. The timeout was made to testify.** The reader's give-up path was changed
to report what it was waiting for:

```
wanted 8872771259896590960 bytes, have 119
```

That number is absurd, and absurd numbers are gifts. In hex it begins
`0x7B22` — the ASCII bytes `{"`. The reader had consumed the *start of a JSON
message as a length field*. The 119 bytes it did hold decoded as a reply
missing its first ten bytes.

**2. A wire tap, and a referee.** The socket-fill callback was made to append
every byte it ever received to a file, and a forty-line Python script walked
that file as RFC 6455 frames. Verdict: **107 frames, all well-formed, ending
exactly at the file's end.** The server's stream was innocent. Whatever was
wrong was wrong in the client's accounting of a correct stream.

**3. Arithmetic.** A counter in the reader's consume path, printed at death:

```
consumed 306,369 + buffered 119 = 306,488 = bytes on the wire
```

Nothing lost, nothing duplicated — yet the reader stood mid-frame. Total
agreement plus positional disagreement means exactly one thing: at some earlier
boundary the reader split the stream differently than the sender framed it.
The frame map located the client's position inside the final frame, ten bytes
past its true start, and the tap showed that frame's header:

```
81 7E 00 7F   →  FIN+text, 16-bit extended length, length = 127
```

RFC-perfect. And then the client:

```tcl
set len [expr {$b1 & 0x7f}]
if {$len == 126} { _need 2; binary scan [_take 2] Su len }
if {$len == 127} { _need 8; binary scan [_take 8] Wu len }
```

Two independent `if`s. When the 16-bit extended length is **exactly 127**, the
first branch scans it — and then the second branch matches the *freshly
scanned value* and eats eight payload bytes (`{"jsonrp`) as a 64-bit length.
One poisoned reply size. And because every reply carries a request id that
grows through the run, each run's replies all shift by a byte or two — so the
127-byte reply lands on a different command every time, which is why the
failure wandered.

It is an `elseif` now. One word. It cost more wall-clock than the compiler
races, the audit, and the zombie combined, and it was only ever going to fall
to instrumentation: no amount of staring at that code screams *127 is both a
value and a sentinel*, but the byte arithmetic could not be argued with.

## What transfers

- **Freeze and probe.** When a client starves, open a second connection during
  the stall. One fact — "the server answers fresh clients" — killed four
  hypotheses in a minute.
- **Make timeouts testify.** A timeout that reports *what it was waiting for*
  turned "it hangs" into "it wants 8.87×10¹⁸ bytes", and that number contained
  the diagnosis.
- **Tap the wire, then referee it with independent code.** The re-parse of the
  capture used none of the client's logic, which is the only reason it could
  convict the client.
- **Do the arithmetic.** `consumed + buffered = received` is a one-line
  invariant that separates "data loss" from "boundary drift" — different bug
  families, different suspects.
- **Fix the loudest bug first, then re-run everything.** The crash, the
  zombie, and the byte all presented as "the suite is flaky". Only after each
  fix did the next bug's evidence come clean; chasing them together produced
  contradictions, because the evidence was a superposition of three diseases.
- **When a subsystem gains its first race, audit its whole neighbourhood.**
  The two quiet races found by reading would have become next month's
  intermittents.

The suite now passes clean, three consecutive full runs, and every contract
this campaign established — the background-compiler stop rule, the
mutator-only allocations, the kill-while-paused trap, the frame-reader fix —
is written down where the next person will trip over it, instead of in the
crash logs where I did.
