+++
title = "The pain of GC is never the GC"
date = 2026-07-31
description = "The collector is a few thousand lines you can unit-test to green. It will still be wrong — because the pain was never the collector. It's the language's interface to it: roots, pins, barriers, safepoints. And those bugs lose one object in a hundred thousand, so your test suite stays green while the heap quietly bleeds."
[taxonomies]
tags = ["gc", "garbage-collection", "debugging", "testing", "correctness", "runtime"]
+++

_You can lift a garbage collector near-verbatim from a working one, unit-test it
to 312 passing cases, and ship it — and it will still corrupt the heap. Not
because the marking is broken. Because the compiler lied to it about where the
pointers were. Every time I've watched GC pain up close, it turned out not to be
the GC. It was the **interface** to the GC._

## TL;DR

- A collector's core — mark, evacuate, promote — is small and testable. The bugs
  don't live there.
- They live in the **promises the language makes to the collector**: where the
  roots are, which words are pointers, which stores need a write barrier, when
  it's safe to collect. Break one and the *correct* collector corrupts the heap.
- These bugs are **probabilistic** — they fire only when a collection lands in the
  tiny window where a promise is briefly broken — so they pass every unit test and
  most real runs.
- [NCL](/posts/newcl) chased exactly one of these: a "tiny leak" that lost ~50
  objects out of five million, hidden behind a *different, real* bug whose fix
  didn't move the symptom.
- The lesson that cost the most: **your tests are green because they test
  mechanics, not semantics.**

## The engine is the easy part

Here is the uncomfortable truth the [GC essay](/posts/gc-in-these-compilers) only
hinted at. The collector proper — the thing that walks live objects, copies them,
fixes up pointers — is a solved problem. NCL's `NewGC` is literally "a
near-verbatim lift" of an older Lisp's page heap; you can borrow one. What you
*cannot* borrow is the seam where **your** language meets it, because that seam is
specific to your representation, your calling convention, and your native frames.
And that seam is where every real bug I've seen actually lived.

The interface is a short list of promises the compiler and runtime must keep,
continuously, on every path:

- **Roots** — a complete, current enumeration of every live pointer at the moment
  a collection runs. Miss one and its object is freed under you; report a
  non-pointer as one and the collector "relocates" an integer.
- **Pointer identity** — for every word in a traced slot, is it a pointer or a
  scalar? Get the tag wrong and the collector either updates a number or fails to
  update a real reference.
- **Pins** — pointers held in native/foreign frames the collector can't walk, so
  they must be conservatively pinned for the duration. Drop a pin and its object
  moves or dies while C code still holds the old address.
- **Write barriers** — every store of a young pointer into an old object must be
  recorded, or a minor collection won't know the young object is still reachable.
- **Safepoints** — a collection may only happen where every thread's roots are
  known. Collect a nanosecond early and the roots are garbage.

Notice what these have in common: **not one of them is inside the collector.**
They're all things the *language* asserts to the collector. The collector, tested
in isolation, is correct. The program that drives it is what's wrong.

## The NCL nightmare: the tiny leak that wasn't a leak

NCL wrote the whole thing down, because it nearly beat them. Under sustained GC
pressure, real Lisp workloads "would lose a tiny, randomized number of objects."
The reproducer built a 50-element list a hundred thousand times and summed the
walks — expecting exactly `5000000`:

> "Observed: `4999949`, or `4999988`, or `4999971`. **Always close, never right,
> never the same number twice.**" — NCL `gc_bughunt_tinyleak.md`

Fifty-odd lost objects out of five million: **one in a hundred thousand.** And the
tell that it was an *interface* bug, not a *collector* bug, is right there in the
diagnosis — a 50-element list can't come back with 47 elements unless "a stale
pointer in a `pins[]` slot now references freed memory," i.e. the **root/pin
machinery** handed the marker a bad set. The marker did exactly what it was told.
It was told wrong.

### The part that should scare you

They found a bug. A real one — a conservative-pin path that dropped a pinned
object's children — reviewed it, fixed it, landed the commit, passed the tests,
and reran the workload:

> "`conses sum=4999949 (expect 5000000)`. **Same deficit. Same magnitude. Same
> flavor.** The fix had landed, the tests passed, and the symptom was unchanged."

A correct-looking patch for a genuine bug that *did not move the symptom* — because
the actual cause was a *different* flaw in the same interface. Their hard-won rule:

> "the workload disagreeing is more important than the code disagreeing. A
> correct-looking patch that doesn't move the symptom is a sign that the actual
> cause is elsewhere." — NCL `gc_bughunt_tinyleak.md`

That is the signature of interface bugs: they cluster, they mimic each other, and
a plausible fix for one hides another.

## Why your test suite is green while the heap bleeds

Here is the sharpest sentence in NCL's entire GC file, and it is the whole reason
this class of bug survives to production:

> "**all 312 of our Rust tests can pass and the GC can still be wrong.**" — NCL `GC_LESSONS.md`

The tests check that `try_alloc` returns non-null, that a counter incremented,
that a from-generation ended empty. None of that is correctness:

> "Mechanics are pre-conditions for correctness, not evidence of it. A GC that
> correctly bumps every counter and correctly transitions every page descriptor
> can still freely lose pointers, double-free objects, leave dangling references,
> or grow the heap monotonically."

And memory-safe Rust doesn't save you, because the bug isn't a pointer-arithmetic
mistake it can catch — "the bug class is in *invariants between unsafe regions and
bookkeeping*." The invariant is "every live pointer is reported before a
collection," and it holds 99.999% of the time. The 0.001% is a window a few
instructions wide — a temporary that's live but not yet rooted, a store whose
barrier hasn't run — and the bug fires *only if a collection lands inside that
window.* Which is why it passes every unit test, runs clean for a million
allocations, and drops three cons cells on the hundred-thousand-and-first.

## What actually catches them

You cannot find a one-in-a-hundred-thousand invariant break by hoping. NCL's
methodology is the real deliverable of that whole ordeal:

1. **Test semantics, not mechanics.** A real GC test builds a graph with *known*
   reachability (hold 100 of 1000 cons cells), runs a cycle **through the mutator
   allocation path** — not a direct allocator call — then walks the 100 survivors
   asserting every `car`/`cdr` still matches its pre-cycle value, and verifies the
   900 unreachable cells are actually gone. Then does it across *multiple* cycles,
   with pins, cards, and cycles in the graph.
2. **Stress the window shut.** Run the collector on *every* safepoint/allocation
   (`gc stress`) so a one-in-a-hundred-thousand window becomes one-in-one — the
   rare corruption now fires on the first iteration instead of the millionth.
3. **Walk the whole heap and assert.** After each collection, a heap-walk closure
   checks that every cell on every live page is a valid word or unreachable — the
   invariant the counters never checked.
4. **Trust the workload over the code.** In the end it was a real Lisp program
   losing data, not a unit test, that both *found* the bug and *adjudicated* the
   fix. The workload is the oracle; the tests are scaffolding.

## Two ways out

Given how expensive this is, the portfolio shows two honest responses.

**Delete the hardest promise.** [Locus](/posts/locus) reaches the heap through a
handle table, so "the compiler never has to tell the collector where the live
pointers are." The single most bug-prone promise — precise, current, complete root
reporting — simply doesn't exist in its compiler, and this entire failure mode
goes with it. If you can afford the indirection, designing the interface away beats
testing it to death.

**Or pay the testing tax in full.** NCL kept precise roots — the fast, hard path —
and bought correctness with semantic tests, GC-stress mode, heap-walk assertions,
and long real workloads. It works. It also took sub-phases 1 through 10 and a
document titled *lessons* to get there.

## The through-line

Borrow the collector; you can't borrow the contract. A garbage collector is a few
thousand lines of well-understood algorithm, and lifting one is a weekend. The
year is in the interface — the roots, the pins, the barriers, the safepoints —
because that's where your language's specifics collide with the collector's
assumptions, and every collision is a one-in-a-hundred-thousand heap corruption
that your green test suite will cheerfully never mention. When GC hurts, don't
debug the GC. Debug what you promised it.

## Related

- [The role of the GC in these compilers](/posts/gc-in-these-compilers) — the systems view: the shared collector and its root strategies
- [NCL](/posts/newcl) / [MacNCL](/posts/macncl) — where the bughunt happened
- [Locus](/posts/locus) — the handle table that designs the root-reporting bug class away
- [The shared substrate](/posts/shared-substrate) — why you can lift a collector but must earn its interface
