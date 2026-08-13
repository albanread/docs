+++
title = "Marshalling or a message protocol: two ways to drive Cocoa from a VM"
date = 2026-07-31
description = "A VM on a background thread has two ways to drive AppKit. It can marshal — call the real Cocoa selector on the main thread and wait for the value (dispatch_async plus a timed semaphore). Or it can speak a protocol — push batched commands to a UI isolate that owns the views. They aren't competitors; they're two layers. For structured UI the message protocol wins on almost every axis; marshalling earns its keep only where the protocol can't reach: open-ended live Cocoa and synchronous reads."
[taxonomies]
tags = ["cocoa", "appkit", "concurrency", "isolates", "marshalling", "ui"]
+++

_There are two ways to make a garbage-collected VM, running on a worker thread,
drive AppKit — which lives, immovably, on the main thread. One **marshals**: it
sends the real Objective-C call across to the main thread and waits for the answer.
One speaks a **protocol**: it pushes a batch of commands to a UI isolate that owns
every view. Having built and shipped both, the honest verdict is that they aren't
rivals — they're two layers, and the interesting question is which job each is for._

## TL;DR

- **The marshalling mechanism, confirmed:** `onMain` is `dispatch_async` to the
  main queue **plus a timed semaphore** — the calling isolate blocks per call,
  gets a return value, and times out rather than hangs. (Chosen over
  `dispatch_sync` to dodge deadlock and survive a headless, no-run-loop host.)
  That per-call round-trip is the crucial cost.
- **Stance:** for the workspace's own UI, the **message protocol is better, and is
  correctly the default.** Marshalling isn't worse globally — it's the right tool
  for a narrower job.
- The protocol wins for structured UI on **safety, latency, responsiveness,
  testability, and coupling.**
- Marshalling is irreplaceable for **open-ended live Cocoa** (call *any* selector)
  and **synchronous reads** (get a value back now).

## The mechanism, pinned down

Before comparing, be exact about what marshalling costs. The bridge's `onMain` is
**not** `dispatch_sync`. It is `dispatch_async` to the main queue paired with a
`dispatch_semaphore` the caller waits on, with a timeout. So a marshalled UI call
means: the worker isolate **blocks**, the closure runs on the main thread, a return
value comes back, and if the main thread never services it the wait **times out**
instead of deadlocking.

That design is deliberate and correct. `dispatch_sync` would deadlock the moment
the main thread is already inside the bridge, or re-enters it; and it would hang
forever on a **headless host with no run loop draining the queue**. The
async-plus-timed-semaphore version dodges both. But it also names the price plainly:
**every marshalled call is a main-thread round-trip with a blocking wait**, and it
competes with the run loop for the main thread's time.

## The stance, up front

For the workspace's own UI — panes, widgets, drawing, the transcript — the message
protocol (`_ui.send(['draw', …])`) is the better engineering, and it's the default
for exactly the right reasons. This isn't "marshalling is bad." It's that
marshalling is a sharp, general tool, and most UI work doesn't need generality — it
needs safety, batching, and testability, which the protocol gives and marshalling
can't. Two layers, not two competitors.

## Why the protocol wins for structured UI

| Dimension | Message protocol — `_ui.send([...])` | Marshalling — `onMain` |
|---|---|---|
| **Isolate safety** | Share-nothing: the UI isolate owns every `NSView` and touches them only on its thread. The port is a clean serialization barrier. | Shares raw AppKit pointers (`ObjcRef`) across threads. Lifetime races are real — the `setRowsJoined:` browser crash (a send to a released/nil ref) was exactly this. |
| **Latency** | One-way, batched: a whole frame of ops or a widget batch crosses in one message, flushed per microtask/frame. | A main-thread round-trip *per call* (async-dispatch + semaphore wait). Chatty UI-building stalls; each call competes with the run loop. |
| **Responsiveness** | The UI isolate paces its own rendering — it can **coalesce or drop frames**, so a heavy demo can't freeze the UI. | A busy producer hammering the main queue starves the run loop → the UI stutters. |
| **Testability** | The command stream is **data** — assert it headlessly with no AppKit at all (`appui_wire.dart` / `gamepane_wire.dart` do exactly this; `gAppSpec` replay). | Untestable without a live main thread and real windows. |
| **Coupling** | The compute isolate emits **intent**; UI ownership stays in one place. | UI concerns — view pointers, object graph, retain/release — leak into the compute isolate. |

The through-line of that table is one idea from the [isolates essay](/posts/isolates-and-vms):
**the port is a serialization barrier, and a barrier is what makes UI safe.** The
protocol never lets a raw `NSView` pointer cross a thread, so there is no lifetime
race to lose. Marshalling, by design, hands the worker a live Objective-C reference
and trusts everyone to keep it valid across threads — which is why the guard
`isValid` appears **141 times** in the bridge, and why the crashes that did happen
were lifetime crashes on shared refs, never protocol crashes. The apps, games, and
demos that push commands stayed robust; the one that shared pointers is the one that
crashed.

## Where marshalling is the right tool

Two jobs the protocol genuinely can't do, and marshalling does for free:

**Open-ended live Cocoa.** When Smalltalk code opens an arbitrary `NSWindow` or
calls *any* AppKit selector, you cannot pre-encode the whole Cocoa API as a fixed
command vocabulary — there are half a million methods. The marshalling bridge hands
you the *entire* runtime, dynamically. That's the [MACVM](/posts/macvm)
"Smalltalk drives live Cocoa" niche, and it's precisely the reach the
[fixed-shape shim](/posts/cocoa-bridge) exists to provide. A message protocol is a
*bounded* vocabulary by construction; live Cocoa is *unbounded* by construction.

**Synchronous reads.** Ask a view for its `bounds`, or a field for its
`stringValue`, and a marshalled call simply *returns the value*. The message
protocol has no natural answer to "give me a value now" — it's one-way — so reads
have to be built as an explicit request/reply channel, which is exactly why
`appevent`/`keyState()` had to grow a pull channel. Where you need a value back on
the calling thread, marshalling is the shorter path.

## The recommendation: keep the split, and mean it

The mature design is not to pick a winner but to use both deliberately, as the two
layers they are:

- **Default to the message protocol** for anything with a bounded vocabulary —
  panes, widgets, drawing, transcript. It's safer, batchable, responsive, and
  headless-testable. *Every new UI surface should push commands, not marshal.*
- **Reserve marshalling** for the genuinely open-ended ST→Cocoa case, and treat it
  as the sharp tool it is: **guard every cross-thread ref** (the `isValid` habit),
  **keep calls coarse** (few round-trips, never chatty), and **never do it on a hot
  path.** It buys reach and synchronous reads at the price of thread-safety
  fragility and per-call latency — worth it only where the protocol can't express
  what the language needs.

## The through-line

Marshalling and the message protocol are the [shared-memory-vs-share-nothing](/posts/isolates-and-vms)
tradeoff, wearing UI clothes. The protocol is the share-nothing discipline applied
to the screen: a serialization barrier that buys safety, batching, responsiveness,
clean ownership, and headless tests — at the cost of a fixed vocabulary and a
round-trip for reads. Marshalling is shared-memory reach: the whole Cocoa API,
synchronous, immediate — at the cost of cross-thread lifetime fragility and a
main-thread wait per call. Neither is "the bridge." The right architecture makes the
protocol the **default floor** — because structured UI wants safety far more than it
wants generality — and keeps marshalling as the **escape hatch** for the open-ended
case the protocol was never meant to express. The evidence is in the crash log: the
surfaces that spoke a protocol stayed up; the sharp tool cut where sharp tools do.

## Related

- [The role of Cocoa and the bridge](/posts/cocoa-bridge) — the marshalling side in full: the fixed-shape shim and `noSuchMethod`
- [Isolates and VMs](/posts/isolates-and-vms) — the share-nothing barrier this applies to UI
- [Tcl for agents](/posts/tcl-for-agents) — a command protocol as an agent-drivable, testable surface
- [Debuggers](/posts/debuggers) — where the released-`ObjcRef` crash showed up
