+++
title = "Test, test, test"
date = 2026-07-31
description = "The unnerving thing about a compiler is that it can be a quarter finished and still run most of the programs you throw at it — so 'it runs' proves almost nothing. The defense is testing at every altitude at once: a spec and someone else's conformance suite if you're lucky, hundreds of your own tests if you're not, the exact bytes and the exact results, and a corpus of whole programs where features finally collide. You can't have enough coverage. You try anyway."
[taxonomies]
tags = ["testing", "compiler", "conformance", "correctness", "test-suite", "corpus"]
+++

_You would think a bug in something as hairy as a compiler would be obvious. It
isn't — and that's the whole problem. A compiler can be a quarter finished and run
a startling amount of real code perfectly, because most programs only ever ask for
the part you already got right. "It runs" is almost worthless as evidence. Which is
why the answer to a compiler is the same word, three times._

## TL;DR

- A **25%-complete compiler runs most programs**, because programs cluster in a
  small common subset. So passing is not evidence of correctness — the bugs are in
  the long tail you didn't exercise.
- **Best case: a spec and someone else's test suite** (ANSI, ISO, a language's own
  conformance corpus). [MACDART](/posts/macdart) inherits Dart's — 5,033 cases,
  zero crashes — and *that's* how you know you're at parity, not hoping.
- **No suite? Write it.** Hundreds of tests is a floor. Every exhaustive sweep
  [MACVM](/posts/macvm) wrote found real engine bugs.
- Test the **shape** of the code (exact bytes) *and* the **results** (right
  answers). And a **corpus of whole programs**, because isolated tests never catch
  feature interactions.
- You can't have enough coverage. You can try.

## The quiet catastrophe: it runs anyway

Here is the fact that should scare anyone writing a compiler: a program will run
fine on a badly broken one. Not sometimes — *usually*. Real programs cluster hard
in a common subset — integer and float arithmetic, `if`/`while`, function calls, a
handful of types, the standard collections — and a compiler that nails that subset
will happily run the large majority of code you feed it, while being wrong,
missing, or absent everywhere else. Twenty-five percent of the language, done well,
covers a shocking fraction of programs.

That means **"it runs" tells you almost nothing.** It tells you the program stayed
inside the part you happened to get right. It does not tell you the compiler is
correct, because the bugs don't live in the common path — they live in the tail:
the edge cases, the rarely-used features, and above all the places where two
correct-looking features interact. And a program that never reaches the tail runs
perfectly on a compiler riddled with holes. A compiler is the rare artifact where
*working* and *correct* are almost unrelated until you deliberately go looking for
the gap.

## The jackpot: a spec and someone else's suite

The best situation you can be in is to not be reimplementing correctness from
scratch. If the language is standardized — ANSI Common Lisp, ISO Modula-2, ANS
Forth, or a living implementation like Dart — you inherit two priceless things: a
**specification** that defines "correct" externally, and, if you're lucky, an
**exhaustive test suite someone else already wrote.** That suite is an oracle you
did not have to invent, and it is merciless in exactly the way you can't be about
your own work.

[MACDART](/posts/macdart) is the clearest case: it inherits the Dart 1.24.3
conformance suite and runs it — **4,602 language cases, 5,033 total, zero crashes,
99.1% passing.** That number is the entire reason it can claim *parity* with the
upstream VM rather than merely "it seems to work." [NCL](/posts/newcl) is measured
against the ANSI suite (~757 of 919 forms); Modula-2 against ISO 10514.

**Forth is the model of the arrangement**, because ANSI standardized the language
*and* shipped a conformance test suite with it. The ANS Forth / Forth-2012 standard
comes with the Hayes `tester` harness (the `T{ … -> … }T` framework) and word-set
tests, and [WF66](/posts/wf66) simply *bundles those exact files* — `lib/tester.fs`
and `lib/ans_core_tests.fs` — running the standard's own tests **in addition to**
its homegrown Rust harness. That's the ideal in full: an external suite you didn't
write, adjudicating conformance to the letter of the standard, running alongside
your own suite that covers the parts and quirks the standard doesn't reach — both
oracles at once.

As the [substrate essay](/posts/shared-substrate)
put it: a shared runtime lets you *reach* a language quickly, but only a standard's
suite lets you *know* you got it right. If a suite exists, adopting it is the
highest-leverage day of testing you will ever spend.

## No suite? Then you write it — and hundreds is the floor

Often there's no drop-in suite — Smalltalk-80 has a de-facto standard but no single
conformance corpus you can just run — so you have to build one. This is not
optional busywork; it is where the bugs are, and [MACVM](/posts/macvm) has sixteen
sprints of test documents to prove it. Its approach was to sweep entire *protocols*
methodically — the whole Number protocol (96 methods), the whole String protocol
(~75), the whole Collection protocol — writing a test for every method whether or
not it seemed to work. Every sweep found real engine bugs:

- The **Number** sweep turned up four, including floored division and a
  nested-closure capture bug.
- The **String** sweep found that `copy` was broken across the *entire object
  model* — a primitive fell through to `^self`, so every "copy" silently aliased
  its receiver: `OrderedCollection copy` shared its elements, a `String copy` stayed
  read-only. That is a catastrophic bug that had been sitting under a green build,
  invisible, because nothing in the common path copies-then-mutates.
- The **Collection** sweep found `withAll:` crashing every growable collection,
  because `self new` from an inherited factory took a slow path that skipped the
  subclass initializer.

Notice the pattern: **the tests you write in order to be thorough find the bugs you
had no idea you had.** None of these would ever surface from "run a program and see
if it works," because no ordinary program pokes them. Hundreds of tests is a
minimum, and the reason isn't ceremony — it's that a compiler has hundreds of
distinct behaviors and each one is a place to be wrong.

## Two things to test: the shape and the result

There are two fundamentally different questions a test can ask, and a serious
compiler asks both.

**The shape** — did you emit the *right code*? The assemblers test this to the
byte: a from-scratch encoder is diffed instruction-by-instruction against LLVM-MC
over a frozen corpus — [WRASM](/posts/wrasm)'s **5,109 golden forms**,
[JASM](/posts/jasm)'s **3,393/3,393 matching**. This catches a wrong opcode even
when the program's *answer* would happen to come out right, and it catches
codegen regressions the instant they appear. (Test the shape of *unoptimized* code:
the optimizer is a moving target, but the naive lowering is a stable baseline you
can pin exactly — see [text at every stage](/posts/text-at-every-stage), where the
diff being empty *is* the test.)

**The result** — did the program compute the *right answer*? This is what the
conformance suites and MACVM's protocol sweeps assert. Shape testing is precise and
early; result testing is what actually proves semantics and catches the cases where
your model of the language is simply wrong. You want both, because each is blind to
what the other sees: correct bytes can still implement the wrong semantics, and a
right answer can come out of accidentally-canceling wrongs.

## The matrix isn't enough: you need whole programs

Here is the limit of every test suite, however large: a matrix tests **tiny
isolated parts.** A protocol sweep exercises each method alone; a difftest exercises
each instruction alone. That is necessary and it is not sufficient, because the
bugs that survive isolated testing are precisely the ones that only appear when
features *interact* — like MACVM's `withAll:` crash, which needed a growable
collection *and* an inherited factory *and* a subclass initializer to collide
before it showed. No test of any one of those three finds it.

So beyond the unit matrix you need a **corpus of whole programs** — real code that
makes features work together, so you're testing the compiler *building programs*
rather than answering trivia about single functions. The portfolio leans on this
hard: MACVM and MACDART run **richards** and **deltablue** verbatim (205 and 186
mentions in the docs — real object-oriented benchmarks, thousands of interacting
sends), plus mandelbrot; [NCL](/posts/newcl) runs a Prolog/Zebra solver, an Othello
AI, and a neural-net tank simulator; the assemblers build entire games; MacModula2
builds Cocoa demos. A whole program is the ultimate integration test, and it echoes
the hardest-won lesson from the [GC bughunt](/posts/gc-pain-is-the-interface): *"the
workload disagreeing is more important than the code disagreeing."* The corpus is
the workload. It's the only thing that exercises the compiler the way reality will.

## You can't have enough — so layer it

There is no single test that proves a compiler correct, so you stack the kinds that
each catch what the others miss:

1. **Shape** — exact bytes, diffed against an oracle. Precise, early, regression-proof.
2. **Result** — a conformance suite if one exists (adopt it), your own protocol
   sweeps if not (write hundreds; they *will* find bugs).
3. **Whole programs** — a corpus that forces feature interactions the matrix can't.
4. **Stress** — run the collector on every allocation, fuzz, soak, to force the
   one-in-a-hundred-thousand windows out of hiding.

Each layer is blind alone. Together they approach — never reach — confidence.
Coverage is asymptotic; you get closer, you never arrive, and the honest posture is
to keep adding layers because the 25%-complete compiler that fooled you ran only
because you had tested the 25%.

## The through-line

The defining hazard of a compiler is that it can be deeply, silently wrong and look
completely healthy — programs run, the suite is green, nothing crashes. Nothing
*fails* your way into finding the bug; you have to go get it. The only defense is
to test at every altitude at once: the exact instruction, the exact answer, the
whole protocol, the whole program, under stress, against an external oracle when
you're lucky and one you wrote when you're not. The compilers in this portfolio you
can actually *trust* are, without exception, the ones with the longest test paper
trail — sixteen sprints of it, five thousand conformance cases, five thousand
golden encodings — and every one of those tests exists because "it runs" is a lie a
compiler tells you by default. You can't have enough test coverage. But you can
try, and trying is the whole job.

## Screenshots

> _Add to `static/images/test-test-test/`: the MACDART conformance summary (5,033
> cases, 0 crashes); a MACVM protocol-sweep report finding a bug; the difftest diff
> going empty; richards/deltablue running as whole-program corpus._

![Layers of testing: exact bytes, exact results, whole programs, under stress.](/images/test-test-test/01.png)

## Related

- [The shared substrate](/posts/shared-substrate) — a standard's suite is what turns "it runs" into "it's correct"
- [The pain of GC is never the GC](/posts/gc-pain-is-the-interface) — 312 tests green and still wrong; the workload is the oracle
- [The role of LLVM](/posts/llvm-in-these-compilers) — the differential oracle that tests the shape of the code
- [Text at every stage](/posts/text-at-every-stage) — where the test *is* an empty diff
