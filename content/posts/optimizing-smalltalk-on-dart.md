+++
title = "The tax below the flow graph: optimizing Smalltalk on the Dart VM"
date = 2026-08-02
description = "A hosted language sat 4.6× behind Cog on DeltaBlue. Twelve commits later it was level — with no VM source changed. The cost was never the compiler or the collector: it was the shape mismatch between Smalltalk's object model and Dart's, paid one send at a time, in C++ the flow graph cannot see."
[taxonomies]
tags = ["smalltalk", "dart", "jit", "optimization", "profiling", "dispatch", "runtime", "compiler"]
+++

_Three separate times during this work I concluded "the benchmark is allocation-bound
now — this is the floor." Twice more, it wasn't. Each time, one layer further down,
there was another piece of dispatch machinery doing per-operation what should have
been done once. That pattern — and the fact that the compiler's own tooling was
blind to all of it — is the story._

## TL;DR

- **The setup.** Smalltalk runs as a second language on [MACDART](/posts/macdart),
  a port of the Dart 1.24.3 VM. The VM is inherited and **frozen**: every lever is
  in the front end. Against Cog (the production Squeak/Pharo JIT) it won five of
  seven benchmarks and lost DeltaBlue by **4.6×**.
- **The outcome.** DeltaBlue **1271 → 297 µs (−77%)**, now a statistical tie with
  Cog's 280. Six clear wins, one tie, **zero VM source changed**, full Dart
  conformance re-validated at 0 crashes across 5,033 cases.
- **The cause was a shape mismatch.** Dart's `String` is sealed and its `int` is
  not extensible, so Smalltalk's Symbol, Character and Integer protocols live in
  separate `"<Type> ext"` holder classes — and every send to a native receiver
  re-resolved its holder **by name string**. `between:and:` on a small integer,
  from a bounds check, fired ~30,000 times per run, each one a library scan.
- **The tooling lied by omission.** `--print-flow-graph` showed exactly the IL we
  emitted, and the IL was fine. The cost lived *below* it, in our own C++. Only an
  OS-level sampler found it.
- **Three levers were proven dead by measurement** before being built — including
  a polymorphic-devirtualization pass that a single experiment killed in ten
  minutes.
- **It is mostly not code generation.** Roughly two-thirds of the win was
  runtime-system work: method caches, interning, marshalling. The oldest ideas in
  dynamic-language implementation, rediscovered one layer at a time.

## Before and after

Seven checksum-verified Smalltalk benchmarks, three VMs, one protocol: a cold run,
30 warmup iterations, then 41 single-workload microsecond samples reporting median
and MAD, interleaved same-thermal rounds, best-of-7, JIT hot everywhere. µs per
iteration, warm — lower is better.

| bench | before | **after** | Cog | verdict |
|---|--:|--:|--:|---|
| arith | 719 | **697** | 5203 | 7.5× ahead |
| fib | 7187 | **6807** | 18634 | 2.7× ahead |
| sieve | 410 | **197** | 361 | loss → 1.8× ahead |
| dict | 599 | **483** | 1021 | 2.1× ahead |
| alloc | 458 | **405** | 704 | 1.7× ahead |
| richards | 799 | **633** | 2211 | 3.5× ahead |
| **deltablue** | **1271** | **297** | 280 | 4.6× loss → **tie** |

DeltaBlue is the honest one to watch, because it was the failure. Its trajectory,
commit by commit:

```
1271 → 1236   helper fast-paths, per-site sends
     → 1138   thunk-free symbol interning
     → 1132   per-site block-call lowering
     →  729   ext-holder dispatch cache          ← the big one
     →  537   class-side dispatch cache (negative)
     →  399   compile-time symbol interning
     →  297   native-send tax removal
```

Note where the money is. The two dispatch caches alone account for more than half
the total reduction. Nothing in that list is a classical optimization pass.

## The shape mismatch

Smalltalk says: `String subclass: Symbol`. A Symbol is a String that happens to be
interned and compares by identity. Characters are objects ordered by code point.
Integers are objects you can add methods to.

Dart 1 says: no. `String` is final and cannot be subclassed. `int` is not
extensible. You cannot reopen `num` and add `between:and:`.

So the port emulates. `StSymbol` and `StChar` become distinct Dart classes of their
own — which is precisely what makes `#foo = 'foo'` correctly **false** and
`$a == $a` correctly **true**. This is not a wart; it is the representation working.

But those emulated types still need their full Smalltalk protocol, and it cannot
live on the Dart classes. So it lives in **extension holder** classes registered in
the image — `"Integer ext"`, `"Symbol ext"`, `"Character ext"` — and any send to a
native receiver that misses a hardcoded fast path is routed, via `noSuchMethod`,
into a C++ native that finds the right holder and dispatches into it.

That native resolved the holder **by name**, on every single send:

```
5 between: 1 and: 10
  → noSuchMethod → stSendExt → ST_extSendTry
      → FindStClassByName("SmallInteger ext")   ← library scan
      → FindStClassByName("LargeInteger ext")   ← + a String::ToCString each
      → FindStClassByName("Integer ext")        ← until one has the method
      → walk its superclass chain
      → build an args Array in old space
      → DartEntry::InvokeFunction
```

`OrderedCollection>>at:` begins with `(i between: 1 and: self size)`. DeltaBlue
indexes collections constantly. That one bounds check fired the sequence above
roughly **330 times per iteration** — about 30,000 times over a benchmark run.

The correctness feature and the performance disaster were the same mechanism. The
fix was never to flatten the representation — it was to **memoize the resolution**.

## Why the flow graph could not see it

Here is the uncomfortable part. The Dart VM ships good introspection —
`--print-flow-graph-optimized` dumps the exact optimized IL of any method,
`--trace-inlining` explains every inline decision with its bailout reason. All of it
was used. All of it was truthful. And for three consecutive changes it pointed the
wrong way.

It showed a call-heavy constraint cascade with a few closure allocations, so three
changes went after inlining and allocation — and moved the target benchmark by
noise. The flow graph faithfully described the IL we generated. **The IL was fine.**
The cost was one layer beneath it, in the C++ dispatch helpers, which no IL dump can
show.

An OS-level sampler found it in about six seconds:

```
dart::Library::LookupEntry(...)         1077
dart::String::ToCString()                834
dart::Library::LookupLocalClass(...)     329
st::FindStClassByName(...)               220
```

Roughly a third of the benchmark's CPU, spent looking up class names in a hash
table. Nothing in that list is generated code.

**For a hosted language, sample first.** Your dispatch and marshalling layer is
C++, and it is exactly the part your compiler's tooling is not built to observe.

## Three dead ends, proven cheaply

The most valuable measurements were the ones that stopped work rather than
directing it.

**Polymorphic devirtualization.** The plan was a hand-rolled class-hierarchy
analysis pass to devirtualize a hot 3-way polymorphic call the inliner declined.
Before writing it, one experiment: raise the inliner's thresholds until *everything*
inlines. Result: ~3%, inside noise. If forcing full inlining doesn't help, no
inlining-shaped change can — and devirtualization is a subset of forced inlining.
A day's work avoided by a two-minute flag experiment.

**Raised inliner budgets.** Zero effect at any setting.

**More inlining, later.** After the dispatch caches landed, the same experiment was
re-run at the new baseline. Forcing full inlining now made things **8% worse**. Past
a point, splicing everything costs more in instruction-cache and register pressure
than the calls it removes. Landscapes shift; re-run your old experiments.

## The laws

These are the transferable rules, each bought with a measurement. They are written
up at length in the port's own `docs/dart_engine_laws.md`, as a companion to its
front-end guide.

**Profile before you optimize; the flow graph lies by omission.** Order of
diagnosis: OS sampler → inline trace → IL dump → a forced-inline experiment to test
whether inlining is the lever at all.

**A shared helper funnel poisons specialization image-wide.** Routing every call
site for a selector through one shared helper means its polymorphic slow path
aggregates *every receiver in the program* into one inline cache, and the optimizer
can never specialize any individual site. Measured: an `OrderedCollection>>add:`
through the shared funnel cost 57 ns; the *identical body* reached as a per-site
call cost 15 ns.

**Cache dispatch that re-resolves per call — and cache the misses too.** A hit-only
cache on the class-side path was completely inert, because the hot selector was
`basicNew`, which has no class-side method: it *always* missed, fell through to a
default, and re-scanned forever. Caching the negative result — "no method here,
take the fallback" — took DeltaBlue from **729 to 537 µs**. If a hot lookup fails
and falls back, the failing scan is pure waste, and only a negative entry removes
it.

**Cache only what the key faithfully discriminates.** Booleans are excluded from the
extension cache: `true` and `false` share a class id but resolve to *different*
holders, because the resolver splits on the value. Prove your key discriminates
every case the resolver does, before you memoize it.

**Hot helpers must be tiny, with a rare tail.** The inline budget is a real cliff.
An early change merely *reordered* the type tests in a comparison helper; the body
grew past the threshold, stopped being inlined, and `fib` regressed **2.7×**. The
shape that works is one type test plus a branch, with everything unusual in a
split-out `_rare` function.

**A symbol is a unique interned object — resolve the literal once, at compile time.**
The representation was already right; the *lowering* wasn't. `#foo` compiled to a
runtime call that re-discovered the canonical object by spelling on every
evaluation. Baking it as a constant at compile time — sharing one intern table with
the runtime, so a compiled literal and `'foo' asSymbol` remain the same object — was
expected to be neutral and delivered 26%.

**Never hand a hot helper a closure argument.** `Map.putIfAbsent(k, () => …)`
allocates a context and a closure on *every* call, including the hit path where the
thunk never runs. Three of one method's four closure allocations turned out to be
that, inlined from the symbol interner.

## The experience

Two gates, both mandatory for every change: the Smalltalk battery (world boot,
conformance, feature suites, benchmark checksums) and the three-VM benchmark
harness. One lever per commit, so attribution is never ambiguous.

The gates earned their cost repeatedly. They caught the `fib` regression within
minutes. They caught a `SIGBUS` from passing a closure object where the VM's
closure-call instruction wanted the closure's *function* — a mistake with no
compile-time signal, which would otherwise have surfaced as a mysterious crash days
later. And they caught the inert hit-only cache, which looked correct, tested
correct, and did nothing.

The strangest bug was invisible in the language. A helper defined as `namespace st`
*inside* a file that was already `namespace dart::bin` becomes
`dart::bin::st::foo` — which does not match the `::st::foo` the header declares.
The linker quietly resolved every call to a weak fallback stub instead. Symptom:
every Smalltalk symbol evaluated to nil. Worse, finding it revealed that an existing
function had the *same* bug and had been a silent no-op — meaning the dispatch
caches were never being flushed on a hot reload, a live-editing correctness hole
that no benchmark would ever have exposed. `nm` found both in one command.

The recurring intellectual mistake was declaring victory on diagnosis. Three times
the profile went quiet in the place I was looking, and three times I wrote "now it's
allocation-bound — this is the boxing floor." Twice more it was another layer of
removable dispatch. The lesson isn't "be more pessimistic"; it's that **a profile is
only trustworthy when it goes flat** — when the top frames are generated code and
single-digit samples, not one named C++ function towering over the rest.

## What it actually was

It is tempting to call this "optimizing code generation for Smalltalk on Dart," and
about a third of it was: per-site call lowering, compile-time constant folding of
literals, and matching the parser's contract for entry stack checks (the inliner
strips nothing — the parser simply *declines to attach* a check when it builds for
inlining, and our builder attached unconditionally, so a hot method carried nine).

But by impact the majority was runtime-system work — method caches, interning,
argument marshalling. The recurring pattern in every single win was the same:
**something that should be resolved once was being resolved per operation.** That is
the oldest theme in dynamic-language implementation. Inline caches, interned
symbols, method lookup caches — Smalltalk-80 implementors were fighting exactly this
in 1983.

What makes it specific to *hosting* is the constraint geometry. When you own the
whole stack, "improve the code generator" is where the leverage is. When the VM is
frozen, code generation is one of four layers you can touch, and the leverage turns
out to sit in the seams between the IL you emit and the VM that runs it — in the
runtime helpers and the native dispatch layer that only exist because the two object
models don't line up.

The final number is the one worth keeping: a Smalltalk hosted on someone else's
2017 VM, matching the production Smalltalk JIT on its own benchmark suite, with that
VM's source untouched. Not because the code generator got clever, but because the
emulation stopped paying its tax twice.

## Related

- [MACDART](/posts/macdart) — the Dart 1.24.3 port and the bilingual workspace this runs in
- [MACVM](/posts/macvm) — the sibling Rust Smalltalk VM, and still the winner on allocation-bound work
- [Two things called JIT](/posts/two-jits) — why the adaptive kind is the hard kind
- [The role of the GC](/posts/gc-in-these-compilers) — the collector question this benchmark kept *not* being about
- [arm64 vs x64](/posts/arm64-vs-x64) — the other place this VM met Apple Silicon
