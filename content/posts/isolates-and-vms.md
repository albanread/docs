+++
title = "Isolates and VMs: the same conclusion, reached twice"
date = 2026-07-31
description = "We built MACVM's multi-VM concurrency model — spawned Smalltalk worker VMs, each with its own heap, exchanging deep-copied messages, share-nothing, Erlang-style — before we looked closely at Dart's isolates. Then we looked, and found the same architecture under a different name. That convergence isn't a coincidence: a garbage-collected language that wants safe multicore parallelism, with a heap-per-unit collector, has essentially one good answer."
[taxonomies]
tags = ["concurrency", "isolates", "vm", "actors", "message-passing", "gc", "dart", "smalltalk"]
+++

_Our path was Strongtalk, then [MACVM](/posts/macvm), then Dart — in that order. So
we designed MACVM's multi-VM concurrency model, and convinced ourselves it was
right, **before** we studied Dart's isolates. When we finally did, we found the
same conclusion waiting for us, built by other people from a different start. Two
independent designs landing on one architecture is the strongest evidence there is
that the architecture is not a choice but a consequence._

## TL;DR

- **[MACVM](/posts/macvm)** got multicore Smalltalk by spawning **worker VMs** —
  each with its own heap, JIT, and code cache, on its own OS thread — that talk
  **only by deep-copied messages.** No shared heap, no shared state. Its own docs
  call it *"Erlang-style share-nothing parallelism."*
- **Dart isolates** are exactly this: an isolate is a heap + a thread + an event
  loop, sharing no mutable memory, communicating only by messages over ports.
- We reached MACVM's model **before** looking at isolates, and arrived at the same
  place — because the real driver is the **GC**: a per-unit heap makes collection a
  *local* operation, never a cross-thread negotiation.
- Where the two meet: **[MACDART](/posts/macdart)** runs MACVM's Smalltalk inside
  Dart isolates. The two independent conclusions were identical enough that one
  hosts the other.

## First, MACVM: a fleet of worker VMs

MACVM's answer to "how do I use all the cores?" is not threads sharing a heap. It
is **more VMs.** The model is grounded in a working demo — "Mandelbrot in a spawned
VM" — where, as the design doc puts it,

> "two full VM instances — each with its own heap, JIT, and code cache — already run
> in parallel on their own OS threads inside one process, coordinated only by
> channels." — MACVM `multi-smalltalk-worker.md`

From Smalltalk, a primary VM spawns workers and exchanges messages with them, and
the entire discipline is one rule: **everything that crosses a VM boundary is a
copy.**

```smalltalk
| w |
w := Worker spawn.
w send: { #lengthOf. 'hello' }
  onReply: [:r | Transcript show: r printString].  "fires when the reply lands"
w terminate.
```

Three properties define it, and they are worth stating precisely because they are
the same three that define an isolate:

- **No shared state.** "No shared heap, no shared globals, no proxies, no remote
  references. A message is pickled in the sender's heap and rebuilt in the
  receiver's; the two graphs never alias." Even object *identity* never crosses a
  heap boundary.
- **Copy-passing messages.** A message is serialized out of one heap and
  reconstructed in another. Nothing is shared by reference, ever, so there are no
  locks and no data races — not managed, but *absent by construction*.
- **Async, never blocking.** "The primary never waits on a worker." Every send is
  fire-and-forget; the reply arrives later as an event that wakes the primary, and
  is handled by a continuation (`send:…onReply:`), never by a poll or a block.

And MACVM went one step further, building the *recovery* layer explicitly on the
oldest working model of this idea:

> "the worker substrate gives us **Erlang's process layer: isolated heaps,
> copy-only messages, let-it-crash, death as an ordinary message** … The spec is
> OTP itself." — MACVM `otp_workers_design.md`

So workers get supervisors, restart policies, supervision trees — Erlang/OTP,
ported deliberately. MACVM did not set out to reimplement Erlang; it set out to run
Smalltalk on many cores, and Erlang's process model is where it landed. (It's
careful to distinguish this from *green processes* — cooperative, zero-copy
concurrency **within** one heap — which is a different, orthogonal thing. Workers
are parallelism **across** heaps.)

## Why MACVM landed there: it's the GC

The temptation is to read share-nothing as a safety preference. It's deeper than
that, and the reason is the [garbage collector](/posts/gc-in-these-compilers). MACVM
runs a **moving, generational scavenger** — objects relocate on every collection.
Now imagine that heap shared across threads: every collection would have to stop and
coordinate *every* thread, and every pointer any thread holds could move underneath
it mid-access. That is the concurrent-moving-GC problem, and it is one of the
hardest in the field.

Give each VM its **own** heap and the problem evaporates. A worker collects its own
heap, alone, on its own thread, coordinating with no one — GC becomes a purely
*local* operation. Share-nothing isn't primarily about avoiding data races (though
it does); it's what makes a *moving* collector tractable under real parallelism. The
"one heap, one thread, strictly" rule is a GC decision first and a concurrency
model second.

## Now Dart: the isolate

A Dart **isolate** is an independent unit of concurrency with its own memory heap,
its own single thread of execution, and its own event loop. Isolates share **no
mutable memory**; they communicate **only** by passing messages through ports — a
`SendPort` writes, a `ReceivePort` reads — and a message is **copied** from the
sender's heap into the receiver's. You start one with `Isolate.spawn`, and it runs
truly in parallel, on its own core, with — crucially — **its own garbage
collector** over its own heap.

Read that paragraph again next to the MACVM one. Own heap. Own thread. No shared
mutable state. Copy-passing messages over ports. Async. Per-unit GC. It is the same
model, feature for feature. Dart calls the unit an *isolate*; MACVM calls it a
*worker VM*; Erlang calls it a *process*. The three descriptions are
interchangeable.

## The comparison, line by line

| | MACVM worker VM | Dart isolate |
|---|---|---|
| Unit of concurrency | a spawned VM | an isolate |
| Memory | its own heap | its own heap |
| Execution | its own OS thread | its own thread + event loop |
| Shared mutable state | none | none |
| Communication | deep-copied messages via channels | copied messages via `SendPort`/`ReceivePort` |
| Reply model | `send:onReply:` continuation, async | `ReceivePort` + `async`, non-blocking |
| GC | per-VM, local | per-isolate, local |
| Recovery | OTP supervision trees | isolate `onError`/`onExit` (thinner, same lineage) |

The rows line up because they *must*. Both are answers to the same question — safe
multicore for a GC'd language — and once you accept the GC constraint (a
heap-per-unit, so collection stays local) and the safety constraint (no shared
mutable memory, so no races), almost everything else is forced. Messages must be
copied, because nothing is shared. Sends must be async, because the receiver is a
separate scheduling unit. Failure must be a message, because there's no shared stack
to unwind across. Erlang discovered this in the 1980s; Dart's team arrived at it for
a modern GC'd language; we arrived at it from the Smalltalk side, reasoning about
MACVM's scavenger, before we read Dart's version. **Convergent evolution is how you
recognize a law.**

## Where they meet: MACDART

The best evidence that these two conclusions are the *same* conclusion is that one
now runs inside the other. [MACDART](/posts/macdart) inherits Dart's isolate model
and *also* hosts MACVM's Smalltalk as a second language — so both models live in one
process, and they didn't have to be reconciled, because they were never different.
MACDART's IDE is **multi-isolate**; the Smalltalk world boots in a dedicated
**language isolate**; the Smalltalk games run in their own isolate driven over a
port. What MACVM would have spawned as a worker VM, MACDART spawns as a Dart isolate
— and nothing about the Smalltalk concurrency model had to change, because a MACVM
worker *is* an isolate. The two independent designs turned out to be so identical
that the Dart one could simply be the substrate for the Smalltalk one.

## The through-line

An isolate and a worker VM are one idea wearing two names, and the way we know it's
the right idea for a garbage-collected language is that nobody had to be told. A
Smalltalk exploration descended from Strongtalk and a team building Dart at Google
reached the identical architecture without consulting each other, both pushed there
by the same quiet force: a collector that wants a heap of its own, with no other
thread reaching into it. Take "safe parallelism plus a moving GC" seriously and you
do not get to *design* the isolate — you get *led* to it. We felt that pull building
MACVM; Dart felt it too; Erlang felt it first. When three roads from three different
places arrive at the same crossroads, the crossroads was always going to be there.

## Screenshots

> _Add to `static/images/isolates-and-vms/`: two worker VMs computing Mandelbrot
> halves in parallel; a message being pickled out of one heap and rebuilt in
> another; MACDART's multi-isolate IDE with a Smalltalk language isolate; the
> side-by-side worker/isolate comparison table._

![Left: MACVM spawns worker VMs with copy-passing messages. Right: Dart spawns isolates with port messages. The same diagram.](/images/isolates-and-vms/01.png)

## Related

- [MACVM](/posts/macvm) — the multi-VM worker fleet and its OTP supervision
- [MACDART](/posts/macdart) — where Smalltalk workers become Dart isolates
- [The role of the GC](/posts/gc-in-these-compilers) — why a per-heap collector wants share-nothing
- [Two ways to move a heap](/posts/handles-vs-scavenger) — MACVM's moving scavenger, the thing that must not be shared
- [The role of Cocoa and the bridge](/posts/cocoa-bridge) — "one heap, one thread," and the main-thread doorway
