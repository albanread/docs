+++
title = "The shared substrate: how a language a week was possible"
date = 2026-07-31
description = "The honest mechanics behind a portfolio of compilers: almost nothing was new each time. One optimizer, one assembler-plus-oracle, two collectors, a metadata-driven platform binding, one GUI shell, one control plane — reused. And an equally honest reckoning of what's a finished, standard-tested language versus what's still an experiment."
[taxonomies]
tags = ["substrate", "reuse", "compilers", "standards", "conformance", "engineering"]
+++

_"A language a week" sounds like a boast. It isn't, in two directions at once.
It was possible for a boring reason — almost nothing was new each time — and it
does **not** mean a finished language a week. Some of these are experiments that
run; a few are held to a published standard and tested against it. The honest
story is both halves._

## TL;DR

- Each new language reused a common spine: an **optimizer** (LLVM), an
  **assembler + byte-for-byte oracle**, **two shared collectors**, a
  **metadata-driven platform binding**, a **GUI shell**, and a **Tcl control
  plane**. The novelty each time was the front-end.
- The five preceding essays each dissected one layer of that spine. This one is
  the map.
- **Reuse buys speed, not completeness.** Several projects are openly
  experimental or incomplete ([NewBCPL](/posts/newbcpl), [MacBCPL](/posts/macbcpl),
  [locus](/posts/locus)).
- The ones anchored to a **standard** are genuinely tested against it — Common
  Lisp ([NCL](/posts/newcl)), Modula-2 ([MacModula2](/posts/macmodula2)), the ANS
  Forths, and Dart ([MACDART](/posts/macdart)) — and that's the difference between
  "an experiment that runs" and "a language you can trust."

## The substrate, layer by layer

The reason the twentieth language came up as fast as the second is that they
shared almost everything below the front-end. Each preceding essay is really a
tour of one layer of this stack:

- **Code generation — LLVM.** A real optimizer, a portable IR, and a JIT for
  free, quarantined in one `*-llvm` crate so it could later be swapped out. See
  [The role of LLVM](/posts/llvm-in-these-compilers).
- **The encoder and its oracle — WRASM / JASM.** A from-scratch machine-code
  encoder, certified **byte-for-byte against LLVM-MC**, so a project could own its
  codegen without giving up correctness. Same essay; it's the hinge that let the
  Apple-Silicon projects leave LLVM behind.
- **Memory — two shared collectors.** `NewGC` (moving, generational, born in the
  Lisp) and `NewCP`'s non-moving mark-sweep, each written once and plugged into
  many languages behind a layout trait. See [The role of the GC](/posts/gc-in-these-compilers).
- **The platform binding — metadata, not hand-written FFI.** On Windows, the whole
  Win32/COM surface projected from `Windows.Win32.winmd`; on the Mac, the Obj-C
  surface mirrored into [cocoa_data](/posts/cocoa-data). See
  [Cocoa and the bridge](/posts/cocoa-bridge) and
  [Windows was already an OS](/posts/win32-and-com).
- **The GUI shell — iGui.** One immediate-mode Direct2D/DirectWrite shell, born in
  NewCP, borrowed by NCL, NewBCPL and NewFB, then re-targeted to Cocoa / Metal /
  Core Text on the Mac ports.
- **The control plane — Tcl.** One small verb vocabulary that makes every runtime
  scriptable, testable, and agent-drivable. See [Tcl for agents](/posts/tcl-for-agents).
- **JIT memory — the W^X recipe / QBEJIT.** The Apple-Silicon `MAP_JIT` dance,
  solved once and reused. See [arm64 vs x64](/posts/arm64-vs-x64).

Stack those up and a "new language" is a lexer, a parser, a semantic pass, a
lowering, and an object model — bolted onto machinery that was already paid for.
That is the whole trick. Not speed of typing; **depth of reuse.**

## The accelerant: never fly blind

Reuse explains the *cost*; it doesn't explain the *confidence* to move that fast.
That came from a habit visible in every layer: always keep an oracle. The native
encoder is checked byte-for-byte against LLVM-MC. The moving GC was paid for once,
against a brutal real workload, so no one had to re-derive its invariants. And —
crucially for what follows — the languages that target a **standard** inherit a
conformance suite as their oracle: a fixed, external definition of "correct" that
no amount of self-testing can fake. Speed without a truth source is just fast
wrongness; the substrate always shipped a truth source.

## The honest part: experiment, or standard met?

This is where a portfolio blog earns its keep — by saying plainly what is and
isn't finished. Reuse made everything come up *fast*; it did not make everything
*done*. The projects sit on a spectrum, and it's worth naming where.

**Experiments and works-in-progress.** [NewBCPL](/posts/newbcpl) says it outright —
"under development, incomplete," a JIT that doesn't emit executables yet.
[MacBCPL](/posts/macbcpl) is "under development." [locus](/posts/locus) is a
research language exploring an idea (effects and staging as graded modalities),
not a settled tool. These are real and they run — but they are explorations, and
they're labelled as such.

**Anchored to a standard, and tested against it.** The other end of the spectrum
is where the substrate's payoff turns into something trustworthy, because there's
an external yardstick:

- **[NCL](/posts/newcl) — ANSI Common Lisp.** A JIT-compiled Common Lisp measured
  against the ANSI suite (≈757 pass / ≈83 fail / ≈79 error of 919 forms) and
  benchmarked honestly against SBCL 2.6.5. Pre-1.0, and it says so — but held to
  the actual standard, not a private notion of done.
- **[MacModula2](/posts/macmodula2) — PIM 4 + ISO 10514-1.** A Modula-2 built to
  the Wirth *and* ISO definitions, with a green `m2_tests` gate suite behind
  features like COM type-guards.
- **The Forths — ANS Forth / Forth-2012.** WF65 was "a complete, working 64-bit
  STC Forth"; the line carries a standard-referenced test suite forward into
  [WF66](/posts/wf66) / [MF66](/posts/mf66).
- **[MACDART](/posts/macdart) — the Dart 1.24.3 conformance suite.** The strongest
  data point of all: **99.1% of the language suite, 95% of corelib, and zero
  crashes across 5,033 cases** — parity with the upstream VM. When your standard
  ships its own exhaustive test suite, "done" becomes a number.
- **[MACVM](/posts/macvm) — Smalltalk feature suites.** Self-validating conformance
  suites (no external oracle) that found and fixed real engine bugs.

The distinction matters, and it's the caveat this whole blog should carry: a
shared substrate lets you *reach* a language quickly, but only a standard lets you
*know* you got it right. NCL, Modula-2, the Forths, and the Dart port are the
projects with that external check; the rest are honest experiments at various
distances from it.

## The through-line

The real, cumulative product of this portfolio isn't any one language — it's the
substrate. An optimizer, an encoder with an oracle, two collectors, two
metadata-mirrored platform bindings, a GUI shell, and a control plane: paid for
once, hardened over a dozen uses, and carried from Windows x86-64 to Apple Silicon
arm64. Each language is a demonstration of what that spine can carry — and the
honest way to read the collection is on two axes at once: *how much of the
substrate it exercises*, and *how close it is to a standard it can be measured
against.* "A language a week" was never the claim that each was finished. It was
the claim that the machinery underneath had gotten good enough that the only new
work left was the language itself — and, for the ones that chose a standard, the
patient work of proving it.

## Screenshots

> _Add to `static/images/shared-substrate/`: a diagram of the shared spine
> (front-end vs reused substrate); the NCL ANSI-conformance run; the MACDART
> conformance summary (5,033 cases, 0 crashes); a `m2_tests` green board._

![The shared substrate: a thin per-language front-end on a deep reused spine](/images/shared-substrate/01.png)

## The six essays this ties together

- [Tcl for agents](/posts/tcl-for-agents) — the control plane
- [The role of LLVM](/posts/llvm-in-these-compilers) — codegen and the oracle
- [arm64 vs x64](/posts/arm64-vs-x64) — the target and the W^X JIT recipe
- [The role of the GC](/posts/gc-in-these-compilers) — the two shared collectors
- [Cocoa and the bridge](/posts/cocoa-bridge) — joining the Obj-C object model
- [Windows was already an OS](/posts/win32-and-com) — plugging into Win32 and COM
