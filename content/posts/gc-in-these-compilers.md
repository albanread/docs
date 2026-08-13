+++
title = "The role of the GC in these compilers"
date = 2026-07-31
description = "One collector, written once and plugged into a Lisp, a Forth, and an effect language alike; a candid field report on why GC is uniquely hard; the languages that opt out on purpose; and the moving-collector-meets-ARC boundary where it all gets dangerous."
[taxonomies]
tags = ["gc", "garbage-collection", "memory", "runtime", "rust", "moving-gc", "effects"]
+++

_A garbage collector is the one component in this portfolio that was written
once, shared everywhere, approached with visible humility, sidestepped where
possible, tracked as a type-level effect in one language, and refused outright by
two others. That spread is the story._

## TL;DR

- **Write it once.** `NewGC` — a page-based, mark-evacuate, generational
  collector born in the Lisp — is generalized behind layout traits so **one
  engine serves many languages**, down to a Forth.
- **GC is uniquely hard**, and the codebase says so out loud: 312 passing unit
  tests and it still broke on the first real workload.
- **One engine, many root strategies.** [NCL](/posts/newcl) does precise roots the
  hard way; [Locus](/posts/locus) sidesteps the hard part with a handle table; a
  Forth walks two fixed regions.
- **The spectrum is full** — manual memory ([MacModula2](/posts/macmodula2)),
  mark-sweep (NewCP's `gc.rs` → BCPL, BASIC), moving-generational (Lisp,
  Smalltalk, Dart) — and `{gc}` is a *checked effect* in Locus.
- The collector is **hardest exactly where it meets the non-GC'd world**: a moving
  GC bridging to Objective-C's ARC.

## First, respect: GC is uniquely hard

Most components in this portfolio get built and moved past. The collector got a
dozen design documents and a field report, and the field report is unusually
honest. From NCL's `GC_LESSONS.md`, after sub-phases 1–10:

> "we built a garbage collector with several working open-source examples sitting
> next to us … in a memory-safe language, with 312 unit tests passing, and **it
> still didn't work on the first real Lisp workload we threw at it.**"

And the diagnosis, which is the reason a GC can't just be lifted from a textbook:

> "Memory-safe Rust doesn't help — the bug class is in *invariants between unsafe
> regions and bookkeeping*, not in pointer arithmetic." — NCL `GC_LESSONS.md`

That sentence is why the rest of this article exists. If the hard part were
pointer math, Rust would solve it and every language could roll its own. The hard
part is the *invariants* — is every live pointer accounted for before you move
objects? — so the sane move is to get those invariants right **once** and share
the result.

## The shared engine: NewGC

That shared result is **NewGC**. Its own header states exactly what it is and
where it came from:

> "NewGC — page-based mark-evacuate generational garbage collector … a
> near-verbatim lift of NewCormanLisp's `page_heap`." — `newgc-core/src/lib.rs`

So the collector was extracted from the Lisp ([NCL](/posts/newcl), the laboratory
where the bugs above were paid for) and vendored into the projects that need it —
[locus](/posts/locus) carries it as `newgc-core`, and the same lineage shows up
in [MacNCL](/posts/macncl), [MACVM](/posts/macvm), and the Forths. It is
generational (young `G0` → `G1` → `Tenured`), it moves objects (**mark-evacuate**,
i.e. compacting), and it uses a **card table** and write barriers so a minor
collection doesn't have to rescan the old generation.

The generalization is the interesting engineering. NewGC is being lifted out of
its Lisp origins by parameterizing it over *object layout*:

> "Phase 2 will extract `HeapWord` and `ObjectShape` traits so the GC engine can
> serve more than one language runtime without re-importing this code wholesale."

A `PageHeap<L>` is generic over a layout `L`; each language plugs in its own
(`LispLayout`, `TinyLayout`, and so on). The collector knows how to *move and
trace*; the language tells it how its objects are *shaped*. That is what makes one
collector serve a Lisp and a Forth.

## The other shared collector: NewCP's mark-sweep

NewGC is written once and shared — but it's the *moving* collector, and it isn't
the only one. Alongside it runs a second, **non-moving** lineage that began in
[NewCP](/posts/newcp), the Component Pascal system: a **precise mark-sweep**
`gc.rs` — cluster/block layout, tagged allocations, finalizers, module roots, no
compaction. Where NewGC flowed to the Lisp's descendants, NewCP's collector flowed
to the Windows languages that wanted a simpler, non-relocating heap, and they
lifted it near-verbatim:

> "precise mark-sweep tracing GC (**port of NewCP's `gc.rs`**): per-thread TLABs,
> stop-the-world via safepoints … finalizer support." — [NewBCPL](/posts/newbcpl) `README`

[NewBCPL](/posts/newbcpl) took it; **NewFB** (FasterBASIC) took it ("precise GC,
ported from NewCP's design"); and the first Windows Modula-2 cut (M2NEW) took it
too, before that line dropped GC for manual memory. So the Windows era actually
standardized on **two** shared collectors — NewGC's moving/generational engine and
NewCP's non-moving mark-sweep — and each language picked the one that matched its
object model. (The moving one is the harder, more reused engine, which is why the
rest of this article follows it.)

## One engine, three ways to find the roots

The single hardest thing in a moving GC is knowing **where the live pointers
are** before you relocate everything. What's striking is that the projects, on
the *same* engine, answer that question three different ways.

**NCL — precise roots, the hard way.** The Lisp does it head-on: conservative
stack pinning plus a *precise inline root stack*, card marking, heap-walk
closures — an entire `GC_PRECISE_ROOTS_PLAN.md` of it. This is the work that
generated the field report, and it's why the engine is trustworthy.

**Locus — don't have the problem.** [Locus](/posts/locus) reaches the heap through
an indirection and sidesteps precise roots entirely:

> "Locus uses a proven, moving, generational collector (NewGC) that it reaches
> through … a **handle** … the *compiler never has to tell the collector where the
> live pointers are* — the thing that is hardest to get right in a moving GC
> simply isn't in Locus's compiler." — locus `gc-explained.md`

The program holds *validated indices* into a handle table (the root set); objects
move every collection and the collector rewrites the **table**, but the indices
never move. There are no raw heap pointers in the generated code to fix up.

**WF64 / WF66 — walk two regions.** A Forth is about as far from a Lisp as a
GC client gets, and it still rides the same engine:

> "Heap is a `PageHeap<Wf64Layout>` … Root set: two contiguous user-area regions …
> both walked precisely by `evac.visit_cell` on every collection." — WF64 `forth_gc_needs.md`

`Wf64Layout` is the Forth's plug-in shape; its roots are just its user-area
arrays. That a stack language and a Lisp share a collector — differing only in a
layout trait and a root-walk — is the whole thesis in one comparison.

## The representation boundary: what may not be scanned

A moving collector imposes a contract on the compiler: it must be able to tell a
pointer from a non-pointer in every traced slot, or it will "relocate" an integer
and corrupt the heap. Locus writes that contract into its design rulings — a
generic `Int` is `i62` **only** in a traced heap cell (full `i64` on the stack), a
raw scalar or float on the stack is never scanned, and only a wide value in a
traced slot is a (loud) error. This is the exact seam where GC design meets code
generation, and getting the tag scheme wrong is one of those invisible-until-the-
first-real-workload bugs the field report warned about.

## The languages that say no

Not everything here is collected, and that's a design position, not an omission:

- **[MacModula2](/posts/macmodula2) — manual memory.** Modula-2 keeps explicit
  allocation and reference counting; the language wants the programmer in control,
  and its object model leans on Objective-C's own lifetime rules rather than a
  tracing GC.
- **Beef (NewBF) — manual, by design.** The C#-shaped systems language is manual-
  memory on purpose, the whole point being a managed *feel* without a managed
  runtime.
- **[BCPL](/posts/macbcpl) — mark-sweep, the middle path.** [NewBCPL](/posts/newbcpl)
  has a *precise* mark-sweep collector; MacBCPL runs a *conservative* one. No
  moving, no generations — a simpler collector for a simpler object model.

So the portfolio spans the full memory-management spectrum — manual → reference
counting → mark-sweep → moving-generational — often deliberately, per language.

## `{gc}` as a checked effect

[Locus](/posts/locus) takes the boldest position: garbage collection is a **tracked
effect in the type system.** Its effect rows put *every* effect a computation can
have into its signature —

> "every effect a computation can have is written in its type — nothing hidden,
> ambient, or implicit, down to `{gc}` itself." — locus `gc-explained.md`

— so whether a function may allocate (and therefore may trigger a collection) is
a checked, visible fact about it, not ambient magic. A routine typed without
`{gc}` cannot move the heap under you. The collector underneath is the same
NewGC; what's new is that the language makes its presence *legible and bounded*.

## Where it gets dangerous: a moving GC meets ARC

The hardest GC problem in the portfolio isn't inside any collector — it's at the
border between one and the non-GC'd world. [MACVM](/posts/macvm) (its own moving
Smalltalk GC) and [MACDART](/posts/macdart) (upstream Dart's moving, generational,
compacting GC) both drive Cocoa, where objects are Objective-C `id`s under ARC —
and a moving collector plus a raw ObjC pointer is a live hazard. The house
solution is careful on every axis:

- **Store the raw `id` in GC-opaque storage** the collector never scans — because
  a scanned slot holding a tagged ObjC pointer risks being "relocated" as if it
  were a managed object.
- **Retain on wrap, release on finalize** — a weak persistent handle with a
  finalizer that calls `objc_release`, so the ObjC object's lifetime is tied to
  the GC object's without either side scanning the other.
- **Classify the `+1` selector family** (`alloc`/`new`/`copy`) so ownership
  transfers are counted correctly across the boundary.

In other words: the moving GC is *precisely why* the Cocoa bridge is hard, and
most of the bridge's design exists to keep the collector and ARC from ever
touching the same pointer.

## The through-line

The collector is the portfolio's most respected component — and the most reused.
It was paid for once, in the Lisp, at a bug-per-week for a month; extracted into
`NewGC` and parameterized by layout so a Forth and a Lisp share it; approached
three different ways at the root-finding seam; made a *checked effect* in Locus;
declined on principle by the manual-memory languages; and treated as a live wire
exactly where it meets Objective-C. Everything else in these systems you can read
top to bottom. The GC is the part they wrote carefully, once, and then refused to
write again.

## Related

- [NCL](/posts/newcl) / [MacNCL](/posts/macncl) — the GC laboratory; NewGC's birthplace
- [NewCP](/posts/newcp) → [NewBCPL](/posts/newbcpl) / [NewFB](/posts/newfb) — the *other* shared collector: NewCP's non-moving mark-sweep `gc.rs`
- [Locus](/posts/locus) — handles instead of precise roots; `{gc}` as an effect
- [MACVM](/posts/macvm) / [MACDART](/posts/macdart) — moving collectors meeting Objective-C ARC
- [MacModula2](/posts/macmodula2) / [MacBCPL](/posts/macbcpl) — manual memory and mark-sweep, the other end of the spectrum
- [The role of LLVM in these compilers](/posts/llvm-in-these-compilers) · [arm64 vs x64](/posts/arm64-vs-x64) · [Tcl for agents](/posts/tcl-for-agents)
