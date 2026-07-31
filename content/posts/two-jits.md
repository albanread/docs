+++
title = "Two things called JIT: compile-to-memory, and the real thing"
date = 2026-07-31
description = "Most of the portfolio's 'JITs' are the easy, delightful kind — compile source to memory and jump to it, the Turbo Pascal / QuickBASIC trick that makes development feel alive. Two of them are the other kind: adaptive, profile-guided, deoptimizing, on-stack-replacing recompilers in the Strongtalk / HotSpot / V8 line — which are harder than an AOT compiler, not easier. The word hides the gap."
[taxonomies]
tags = ["jit", "compiler", "deoptimization", "osr", "adaptive-optimization", "interpreter", "runtime"]
+++

_"It has a JIT" is one of the least informative sentences in systems programming,
because it can mean either the easiest good trick in the field or one of the
hardest programs anyone writes. This portfolio has both, and they are not the
same kind of thing at all — one is a compiler with its output pointed at RAM; the
other is a live control system that happens to contain a compiler._

## TL;DR

- **JIT #1 — compile to memory.** Source → machine code in RAM → jump. No file, no
  linker, no adaptation. Its whole gift is *interactivity* — the Turbo Pascal /
  QuickBASIC edit-run loop. Most of the portfolio is this, and it's genuinely not
  hard: it's an AOT compiler minus the file-writing.
- **JIT #2 — adaptive recompilation.** The Strongtalk → HotSpot → V8 lineage:
  interpret, profile, speculatively recompile hot code, and **deoptimize** when a
  guess is wrong — with **on-stack replacement** to catch loops mid-flight.
  [MACVM](/posts/macvm) and [MACDART](/posts/macdart) do this.
- A real JIT is **harder than an AOT compiler**, because it must do everything AOT
  does *and* run a self-observing, self-modifying feedback loop that can go
  unstable (**deopt storms**) — and be correct and fast while the program runs.

## JIT #1: a compiler pointed at RAM

The kind of JIT most projects have is the one that made Turbo Pascal and QuickBASIC
feel like magic in the 1980s: you hit a key and your program is *running*, with no
visible compile, link, or launch. Mechanically it's simple — compile to machine
code in a `mmap`'d buffer and jump to it. [JASM](/posts/jasm) states the entire
contract in five words: **"source in, function pointer out."** No object file, no
linker, no subprocess.

The portfolio is full of this, and it's the same substrate every time:
[QBEJIT](/posts/qbejit) turns QBE IL into executable bytes in place; [NCL](/posts/newcl)
MCJIT-compiles each Lisp function on first call; the STC [Forths](/posts/wf66)
compile every definition to native the instant you type it at the REPL;
[MacBCPL](/posts/macbcpl)'s `run` JITs a program in-process; and
[NewBCPL](/posts/newbcpl)'s `bedit` editor "JITs the current buffer" — you edit and
the thing is already live. That immediacy *is* the point. The development
experience feels interactive because the gap between "I changed it" and "it's
running" has collapsed to nothing.

But notice what this kind of JIT does **not** do: it never watches the program
run, never changes its mind, never recompiles anything. It compiles once,
statically, exactly like an ahead-of-time compiler — it just hands you a function
pointer instead of writing an `.exe`. That's why it's not hard in the way the next
kind is. It's the *easy, wonderful* JIT, and it deserves its own name so it stops
borrowing the other one's difficulty.

## JIT #2: the real thing

The other JIT optimizes your program **while it runs, based on what it observes
about itself.** This is the Strongtalk idea — the line that runs through Java's
HotSpot and V8 — and it's the one [MACVM](/posts/macvm) (Strongtalk-inspired by
design) and [MACDART](/posts/macdart) (the Dart optimizing VM) actually implement.
Four pieces, each hard, and each a place to be subtly wrong.

**Tiers and type feedback.** Start by interpreting. Inline caches at each call
site record the receiver types actually seen — monomorphic, polymorphic,
megamorphic. When a method gets hot, a tier-1 compiler recompiles it
*speculatively* against that feedback: inline the callee you've only ever seen,
unbox the number you've only ever added, assume the class you've always met.

**Deoptimization — being wrong on purpose, safely.** Speculation is only sound if
you can undo it. So every optimistic assumption is guarded by an **uncommon trap**,
and when the guess is violated the VM *deoptimizes*. MACVM's own description:

> "A trap DEOPTIMIZES — it reconstructs the interpreter frame(s), re-executes the
> trapping operation interpreted, and returns the result to the compiled caller as
> if the method had returned normally. This is correct by construction: a wrong
> guess never produces a wrong answer, it just falls back to the interpreter." —
> MACVM `deopt_fixes.md`

That invariant — *a wrong guess never produces a wrong answer* — is the whole
license to be aggressive. It is also brutally hard to earn: reconstructing a valid
interpreter frame from an optimized one means tracking, for every program point,
exactly which live values are where (a whole `deopt_liveness_findings.md` of it),
and getting it wrong is a crash or a corrupted result at a random moment.

**Deopt storms — when the metrics go wrong.** Here is the failure mode that has no
analogue in an AOT compiler, because it's a *control-loop instability*. Traps are
supposed to be rare and self-correcting; a recompile-on-trap loop re-reads the
profile and recompiles against the new truth. But:

> "A **deopt storm** is the pathological case: a compiled method traps on
> essentially every call, forever … A storming method is **slower than
> interpreting** — every call pays the full deopt-materialize-reinterpret-return
> cost on top of the compiled prologue — while looking 'compiled' in every coverage
> metric … nothing fails, it's just slow." — MACVM `deopt_fixes.md`

Read that twice. The optimizer, fed bad metrics, made the program *slower than not
optimizing at all* — and hid the damage, because every dashboard says the method
is compiled and every answer is still correct. MACVM had to build a named deopt
trace (`MACVM_TRACE=deopt`) just to *see* storms, then hunt three distinct classes
of them. An AOT compiler cannot fail this way; it has no metrics to get wrong.

**On-stack replacement — accelerating a loop you're already in.** The tier machinery
keys off method *calls*, which leaves a hole exactly where it hurts: a program
sitting in one long loop never re-enters its method, so it never tiers up, and
your hottest code stays interpreted forever. The fix is **OSR** — compile an
optimized version and swap the *running* frame for it mid-loop, transferring the
live locals and loop state into the new frame. MACVM instruments loop backedges
with a counter and tiers up when it trips; the payoff is the entire point of the
exercise:

> "deltablue 30.6×, richards 34×, **ctxloop 134×**." — MACVM `osr_closure_design.md`

That 134× is a pure loop microbench — the difference between an interpreted loop
and an OSR-compiled one. And the machinery is exactly as fiddly as it sounds: in
one bug, the loop-counter bitfield overlapped a "compilation disabled" flag, so "a
single backedge through a loopy method clobbers the disable bit," making methods
silently re-attempt compilation forever. Loops counting themselves into an
optimizer is a lot of moving parts.

## Why the real JIT is harder than AOT

Put plainly, because the user is right: an adaptive JIT is *strictly more* than an
AOT compiler, not a cheaper version of one.

An AOT compiler — and a compile-to-memory JIT, which is the same compiler minus
the file — has one job: translate source to good code, with all the time in the
world, once. Correctness is a function of the source alone. When it's done, it's
done.

A real JIT must do **all of that**, and then wrap it in a live feedback controller:

- **Profile** the running program without slowing it too much to be worth it.
- **Speculate** optimistically, and **prove every speculation undoable** — a
  deopt-correct liveness map at every program point.
- **Deoptimize** on demand, rebuilding interpreter state from optimized frames.
- **Replace frames on the stack** mid-loop (OSR) without losing the computation.
- **Track dependencies** so that a new type, a redefined method, or a changed class
  hierarchy invalidates exactly the compiled code that assumed otherwise.
- Keep the whole thing **stable** — no deopt storms — because the controller can
  oscillate.
- And do it all **fast** (compilation now competes for time with the program it's
  accelerating) and **correct** (a bug is a wrong answer at a random instant).

The AOT compiler is a function. The real JIT is a function wrapped in a control
system that observes and rewrites the running program — and control systems have a
failure mode compilers don't: they can go unstable. That's the gap the single word
"JIT" papers over.

## The portfolio's two real ones

Only [MACVM](/posts/macvm) and [MACDART](/posts/macdart) took this on, and it shows
in what they had to build. MACVM has a paper trail no compile-to-memory project
needs — deopt-storm fixes, a budgeted inliner, OSR-for-closures, deopt-liveness
findings — and it benchmarks its adaptive collector-and-JIT against Pharo's Cog.
MACDART inherited Dart's optimizing JIT whole, and the very *first* bug its
Apple-Silicon port hit was inside the **deoptimization stub** — a register-restore
sequence Apple Silicon trapped as illegal — because deopt is exactly the machinery
a compile-to-memory JIT never has. That the same adaptive VM can inline Smalltalk
to near native-Dart speed is the reward; the deopt stub is the price.

## The through-line

The word "JIT" stretches from the easiest delightful trick in the field to one of
its hardest artifacts. Compile-to-memory gives you Turbo Pascal's interactivity for
the cost of pointing your compiler at RAM — and it's wonderful, and most of this
portfolio wisely stops there. The real JIT gives you an *interpreter that outruns
ahead-of-time code on real workloads* — for the cost of a self-observing,
self-rewriting, deoptimizing control system that is genuinely, categorically harder
than the AOT compiler it beats. So when someone tells you a language "has a JIT,"
there's really only one useful question back: **which one?**

## Screenshots

> _Add to `static/images/two-jits/`: NewBCPL's `bedit` JIT-running the live buffer;
> a `MACVM_TRACE=deopt` storm trace naming `Klass>>selector`; an OSR backedge
> counter tripping mid-loop; the deltablue/richards/ctxloop speedup table._

![Left: compile-to-memory (source in, function pointer out). Right: interpret → profile → speculate → deopt → OSR.](/images/two-jits/01.png)

## Related

- [JASM](/posts/jasm) — "source in, function pointer out": compile-to-memory in five words
- [NewBCPL](/posts/newbcpl) — `bedit` JITs the live buffer (the interactive dev loop)
- [QBEJIT](/posts/qbejit) — the reusable compile-to-memory substrate
- [MACVM](/posts/macvm) — the real thing: deopt storms, OSR, a budgeted inliner
- [MACDART](/posts/macdart) — Dart's optimizing JIT, deopt stub and all
- [arm64 vs x64](/posts/arm64-vs-x64) — where that deopt stub met Apple Silicon
