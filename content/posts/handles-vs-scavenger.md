+++
title = "Two ways to move a heap: handles vs. the scavenger"
date = 2026-07-31
description = "Both Locus and MACVM run moving, generational collectors — objects relocate on every cycle. But they answer the one hard question of a moving GC in opposite ways. Locus never lets a raw pointer onto the stack: the program holds self-identifying generational handles, and one table is the entire root set. MACVM holds raw oops and runs a Cheney scavenger that scans the stack and forwards every object. One designs the interface bug away; the other tests it to death for speed."
[taxonomies]
tags = ["gc", "garbage-collection", "handles", "scavenger", "roots", "moving-gc", "runtime"]
+++

_Both of these collectors move every object on every cycle. Neither difference
between them is "moving vs. non-moving." The difference is where the indirection
lives — and that single choice decides whether the hardest bug class in
[the GC pain essay](/posts/gc-pain-is-the-interface) exists in your compiler at
all._

## TL;DR

- The one hard question of a moving GC: **when objects relocate, how does every
  pointer to them get found and fixed?**
- **[Locus](/posts/locus): put an indirection in front of every access.** The
  program holds a *self-identifying generational handle* — an index into one
  table — never an address. That table *is* the root set. Objects move; the
  collector rewrites the table; the program's indices never change. No stack scan.
- **[MACVM](/posts/macvm): put no indirection anywhere.** The program holds raw
  object pointers, and a Cheney generational scavenger scans the stack, copies
  every live object, and forwards every pointer to it. Maximum speed; maximal
  interface.
- Locus *designs away* the root-tracking bug class; MACVM *tests it to death*
  because it wants to beat Pharo's Cog. Both are right, for what they are.

## The fork in the road

Locus's GC document opens by naming the two miserable roads into a moving
collector — and it's describing its siblings:

> "Writing your own heap manager that is actually correct is a multi-year tar pit …
> Precise root tracking — telling a moving collector exactly which machine
> registers and stack slots hold live pointers at every safe point — is where both
> siblings bled. Not in the collector: in the *compiler* feeding it roots." —
> Locus `gc.md`

[MACVM](/posts/macvm) walked **both** of those roads on purpose. Locus refused
both. That single decision is the whole comparison, so take each side in turn.

## Locus: the program never holds a pointer

Locus reaches a moving heap through a layer of **handles**, and the payoff is
stated flatly: the handle table is "simultaneously the program's only references
to the heap" *and* "**the collector's entire root set**." Which means:

> "the compiler never has to enumerate roots … the collector walks the *table* — a
> data structure the runtime owns — not the compiler's registers and stack frames.
> The thing that gave both siblings their hardest bugs simply isn't in Locus's
> compiler." — Locus `gc.md`

A handle isn't a bare index; it's a 64-bit **self-identifying, generational name**:

```text
  bit 63                                             bit 0
  ┌────────────┬─────────┬──────────────────┬──────────────────┐
  │  MAGIC 16  │ TYPE 8  │  GENERATION 22   │     INDEX 18     │
  │   0xABCD   │         │                  │   (table slot)   │
  └────────────┴─────────┴──────────────────┴──────────────────┘
```

Two of those fields carry the whole design:

- **MAGIC (`0xABCD`) makes it self-identifying.** The pattern is a non-canonical
  address no real pointer can hold and a 1-in-65 536 fluke for an integer, so
  `is_well_formed` (`bits >> 48 == 0xABCD`) is a reliable "is this word a handle?"
  test *anywhere* — a register, a stack slot, a closure capture. That's what lets
  even a conservative scan be precise, with the worst case being harmless
  over-retention: **there is no address to mis-rewrite.**
- **GENERATION detects staleness.** A slot's generation bumps every time it's
  reused, so a handle left over from a slot's previous occupant fails validation —
  a use-after-free becomes a *clean error, not silent corruption.* And crucially, a
  moving collection keeps the slot and its generation (only the table entry's
  address changes), so **relocation never invalidates a live handle.**

The seam between the two worlds is exactly one indirection —
`handle → table[handle] → object` — and only handles pay it: ordinary `Int`s and
pointers don't wear the magic, so integer math runs at full speed on raw `i64`s.
When NewGC moves an object, it rewrites one table slot. The program, holding an
index, notices nothing. The cost is a load per heap access and a table slot per
live reference; the benefit is that the entire "did the compiler report every
stack root correctly?" bug class **does not exist here.**

## MACVM: hold the pointer, and chase it

[MACVM](/posts/macvm) makes the opposite bet, because it is a Smalltalk chasing
raw throughput, and an indirection on every send is a tax it won't pay. So the
program holds **raw object pointers (oops)**, and the collector is a classic
**Cheney-style generational scavenger**: a bump-allocated **eden**, `from`/`to`
semispaces with **forwarding pointers**, promotion through a **survivor** space to
an **old** generation, minor scavenges and major full-GC **compaction**. Because
the pointers are real addresses living anywhere, moving them means the collector
must do exactly what Locus's compiler never does — **scan the stack** (with stack
maps), find every root, copy every live object, and **rewrite every pointer** that
referred to it.

That is the maximal version of the interface: every root must be found precisely,
every reference forwarded, on every cycle. It is the "multi-year tar pit" *and*
the "precise root tracking where both siblings bled," taken on deliberately. And
it buys what it's meant to buy — MACVM benchmarks its collector head-to-head
against Pharo's **Cog** VM and, with two non-GC pathologies removed, comes out
*3.5× faster*. Its own verdict on the exercise is the same punchline the
[GC-pain essay](/posts/gc-pain-is-the-interface) keeps hitting:

> "The headline of the investigation: **it is mostly not the GC.** … The
> collector's core is competitive; the losses are a compiler gap and a
> configuration gap." — MACVM `gc_alloc_gap.md`

The scavenger is fast and correct. Making it correct is the part that costs a
year, because everything MACVM saved by not indirecting, it now owes to the stack
scanner and the forwarding logic — and every mistake there is a one-in-a-hundred-
thousand corruption.

## The same heap, mirrored choices

Line the two up and the symmetry is exact:

| | Locus | MACVM |
|---|---|---|
| Heap | moving, generational (NewGC) | moving, generational (Cheney scavenger) |
| What the program holds | a **handle** (index) | a raw **oop** (address) |
| The root set | one **table** the runtime owns | the **stack**, registers, VM roots |
| Finding roots | free — the table *is* the roots | **scan the stack** every cycle |
| When an object moves | rewrite **one table slot** | **forward every pointer** to it |
| Per-access cost | one indirection | none (direct deref) |
| Stale reference | caught by **generation** → clean error | undefined behavior if mishandled |
| The root-tracking bug class | **doesn't exist** | present, and stress-tested to death |

Both heaps move. The knob they set differently is *where the pointer-fixup
bookkeeping lives.* Locus centralizes it into one relocatable table — cheap and
safe to fix up, but a load in front of every access. MACVM distributes it across
the entire machine state — free to read, but the collector must chase it
everywhere and dares not miss a slot. There is no free lunch; there's a table slot
and an indirection, or a stack scanner and a testing budget.

## Why each is right

The choice isn't fashion; it follows from what each project is *for*.

**Locus** is a research language whose entire thesis is that dangerous things
should be impossible by construction — its effect system even tracks `{gc}` in the
type. A handle table is that thesis applied to memory: the unsound move (a raw
pointer the compiler forgot to report) is simply not representable. Paying an
indirection to delete a bug class is exactly the trade Locus exists to make.

**MACVM** is a Smalltalk built to be *fast* — it inlines, it JITs, it benchmarks
against Cog. For it, an indirection on every object access is a permanent tax on
the thing it's optimizing, so it takes the hard road and pays the correctness cost
in engineering: precise stack maps, forwarding, and the relentless
[GC-stress testing](/posts/gc-pain-is-the-interface) that forces the rare
corruption to show itself. ([MACDART](/posts/macdart)'s inherited Dart collector is
the same family — raw pointers, a moving generational heap, precise roots — which
is exactly why *its* hardest integration was the moving-GC-meets-ARC
[Cocoa boundary](/posts/cocoa-bridge).)

## The through-line

Two collectors, both moving every object on every cycle, arriving at opposite
architectures from one question: *who keeps the map of where the pointers are?*
Locus answers "one table the collector owns, and the program only ever holds names
into it" — and the whole class of root-reporting bugs evaporates, at the price of
an indirection. MACVM answers "the pointers live wherever the program put them, and
the scavenger will find and forward every one" — and gets the speed, at the price
of owning the hardest interface in systems programming. The handle table trades
throughput for a bug class you'll never have; the scavenger trades that safety for
raw speed and then earns it back, one stress test at a time. Neither is the right
answer. Each is the right answer to a different question.

## Related

- [The pain of GC is never the GC](/posts/gc-pain-is-the-interface) — the root-reporting bug class this is a response to
- [The role of the GC in these compilers](/posts/gc-in-these-compilers) — the shared NewGC engine both sit on (one directly, one in spirit)
- [Locus](/posts/locus) — the handle table, and `{gc}` as a tracked effect
- [MACVM](/posts/macvm) — the scavenger built to beat Cog · [MACDART](/posts/macdart) — the same raw-pointer family, meeting ARC
