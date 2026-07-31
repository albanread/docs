+++
title = "The role of Cocoa and the bridge"
date = 2026-07-31
description = "How a Modula-2, a Forth, a Smalltalk and a Dart all came to open real NSWindows on Apple Silicon — not by wrapping Cocoa in an FFI, but by joining the Objective-C object model outright, through one narrow contract and one fixed-shape objc_msgSend."
[taxonomies]
tags = ["cocoa", "objective-c", "bridge", "ffi", "aapcs64", "appkit", "arm64", "macos"]
+++

_The point of all these languages on Apple Silicon isn't to *call* Cocoa. It's
to **be** Cocoa — to have your language's objects be real Objective-C objects, so
AppKit dispatches straight into your method bodies. The bridge is whatever it
takes to make that true without your small runtime having to understand thirty
years of framework it can never audit._

## TL;DR

- Cocoa isn't wrapped behind an FFI here; each language **joins the Objective-C
  object model** — a class in [MacModula2](/posts/macmodula2), [MacBCPL](/posts/macbcpl),
  or [MF67](/posts/mf67) *is* an Obj-C class, `isa` and all.
- Every message is a real `objc_msgSend`. What differs is **when you know the
  selector**, which sorts the projects into three schools: compile-time inline,
  JIT thunk, and runtime shim.
- The dynamic school ([MACVM](/posts/macvm), [MACDART](/posts/macdart)) rides **one
  fixed-AAPCS64-shape** `objc_msgSend` cast that marshals *any* send — no libffi,
  no per-arity codegen.
- The hard part isn't dispatch; it's a **moving GC meeting a reference-counted
  runtime** across a half-million-method surface you can't model. The answer is a
  narrow contract: *copies and tickets, never live pointers.*

## The problem, stated honestly

[MACVM](/posts/macvm)'s design record refuses to pretend this is easy, and its
framing fits every language here. A VM and Cocoa "disagree about everything that
matters to a pointer": your objects **move** (a compacting GC), Cocoa's never do;
your lifetimes are reachability, Cocoa's are a retain count; your world is one
thread, AppKit's is the main thread only; your failures trap, Cocoa's are
`NSException` unwinds that are "undefined across foreign frames." Wire the two
together naïvely and you lose both ways at once — a Cocoa object holding a raw
pointer into your heap "is corrupted the first time a scavenge moves it," and one
of your objects holding a bare `id` either leaks it or double-frees it.

And you cannot brute-force your way to safety, because of scale:

> "Cocoa is half a million methods, sixty frameworks, and thirty years of
> ownership conventions. We cannot audit it, model it, or teach our GC about it."
> — MACVM `cocoa_bridge_design.md`

So the only stable posture for a small runtime is to "touch it through a
**narrow, mechanically-checkable contract** and refuse everything the contract
doesn't cover." Everything below is that contract.

## The unifying idea: a class *is* an Objective-C object

The deepest form of the bridge is the one with no bridge in it. It originates in
[MacModula2](/posts/macmodula2), and its design doc states the thesis without
hedging:

> "an M2 object *is* an Objective-C object: same `isa`, same allocation, same
> dispatch, same retain/release. There is no wrapper layer and no marshalling —
> the two object models are made to be the same model." — MacModula2 `cocoa-classes.md`

Nothing in the front-end changes; one target-specific lowering does. Where the
Windows backend emits a native vtable for a class, the **macOS backend emits
Objective-C runtime calls** — `class_addIvar` for fields, `class_addMethod` for
methods (your compiled procedure installed directly as the `IMP`, because the
ABI already *is* `self, _cmd, args…`), `objc_msgSend` for a call. The payoff is
the whole game:

> "because every M2 class is an Obj-C class, a class can `INHERIT NSView` and its
> instances *are* `NSView`s … AppKit's `drawRect:`/`mouseDown:` dispatch lands
> directly in the M2 method body — no trampoline, no tag table."

[MacBCPL](/posts/macbcpl) does the same for BCPL `CLASS`es (with inheritance), and
[MF67](/posts/mf67) — "Objective Forth" — for Forth. This is MacModula2's real
legacy: the "a class is an Obj-C class" model, and the ABI-token vocabulary that
describes each method's shape, both start here and propagate to everything else.

## Three schools of the message send

Every language ends up calling the same function — `objc_msgSend` — but they
build the call at different times, and *when you know the selector* sorts them
cleanly:

1. **Compile-time, per-call-site inline** ([MacModula2](/posts/macmodula2),
   [MacBCPL](/posts/macbcpl)). The selector is known when the compiler sees
   `o.M(a)`, so the LLVM backend emits a **typed `objc_msgSend` cast right there**,
   its argument/return shape looked up from the SDK metadata. Zero runtime
   dispatch machinery.
2. **JIT per-ABI-shape thunk** ([MF67](/posts/mf67)). A Forth word's selector is
   known when the JIT compiles it, so it synthesizes a small trampoline **per ABI
   shape**, cached and reused (with a polymorphic inline cache where a site is
   ambiguous).
3. **Runtime dynamic marshal** ([MACVM](/posts/macvm), [MACDART](/posts/macdart)).
   Here the selector *isn't* known until the send happens — it arrives through the
   language's own missing-method hook — so a single **fixed-shape C shim**
   marshals whatever send shows up, at runtime.

Same destination, three answers to one scheduling question. The rest of this
piece follows school 3, because it's the one that had to solve dispatch, memory,
and threading with the least information.

## The fixed-shape shim, up close

You might expect the dynamic school to need `libffi` or a JIT-per-arity. It needs
neither, thanks to a trick the AArch64 ABI hands you. The shim casts
`objc_msgSend` to **one** fixed shape — `self`, `_cmd`, six integer registers,
eight floating registers, four stack words — and fills it:

> "ONE fixed-AAPCS64-shape `objc_msgSend` cast marshals ANY send … because
> AAPCS64 allocates the GPR and FPR files **independently**, those slots land in
> exactly the registers the real method expects. The return is the one thing
> registers can't fake, so a ret-kind token picks the cast." — MACDART `objc_shim.m`

Because integer and float arguments are assigned to *separate* register files in
AAPCS64, you don't need to know a method's exact interleaving — pack the ints into
the int slots and the floats into the float slots and they arrive correctly. Only
the **return** must be typed exactly, so a small token selects the cast:
`HFA2` for an `NSPoint`/`NSSize` (two doubles in `d0–d1`), `HFA4` for an `NSRect`
(four in `d0–d3`), an int-pair for an `NSRange`. (And note: on arm64 there is no
`objc_msgSend_stret` — small structs and homogeneous float aggregates come back
in registers, which is exactly what makes the one-shape trick work.)

The whole thing runs inside `@try/@catch`, so a foreign `NSException` "becomes a
status code, never unwinding into VM/JIT frames" — the one place the two failure
models are forced to reconcile.

## The shared metadata: cocoa_data

Every school needs the same fact about a method — how its `@encode` string maps to
AAPCS64 register slots. Rather than have each compiler re-derive that, the
portfolio mirrors the whole Objective-C surface into one SQLite database,
[cocoa_data](/posts/cocoa-data): classes, selectors, type encodings, struct
layouts. The compile-time schools **query it at compile time**; the runtime
schools classify **live `@encode`** (via `method_getTypeEncoding`) using the same
classification logic ported into the VM and cache the result per `(class,
selector)`. The AAPCS64 token vocabulary they all share — integer, float, HFA-2/4,
int-pair, and the by-reference cases a small VM deliberately punts on — is the one
MacModula2 invented and cocoa_data generalized.

## The language surface: `doesNotUnderstand:` is the bridge

The dynamic languages don't add a `cocoa.send(...)` API — they route Cocoa through
the missing-method hook their object model *already has*. In Smalltalk it's
`doesNotUnderstand:`; in Dart it's `noSuchMethod`. An unknown selector on a Cocoa
wrapper simply marshals and dispatches. That's why it reads as native — in
[MACDART](/posts/macdart), Dart named arguments even lower to Objective-C keyword
selectors:

```dart
NSColor.colorWithRed(1, green: 0, blue: 0, alpha: 1)
// → [NSColor colorWithRed:green:blue:alpha:]
```

Cocoa feels first-class because the bridge *is* the language's own dynamic
dispatch, not a foreign call bolted beside it. (MACVM does the equivalent with a
Tier-2 DNU path and a polymorphic inline cache over resolved shapes.) All of it
resolves through `dlopen`/`dlsym` — `objc_getClass`, `sel_registerName`,
`objc_msgSend`, the class-pair APIs — so nothing is bound to those half-million
methods at link time.

## Memory: copies and tickets, never live pointers

The contract's core rule is the one that keeps a moving GC and a retain count from
ever touching the same pointer. A raw `id` lives in **GC-opaque storage the
collector never scans** (a scanned slot could be "relocated" like a managed
object); the wrapper **retains on wrap** and a **weak-persistent-handle finalizer
releases** on collection, tying the Cocoa lifetime to the wrapper's without either
side walking the other. A `+1`-family classifier (`alloc`/`new`/`copy`) skips the
extra retain where the convention already transferred ownership, and `init`
poisons its receiver so `alloc().init()` can't double-free. This is the same
moving-GC-meets-ARC boundary the [GC essay](/posts/gc-in-these-compilers) calls
out — here it's the reason the bridge exists in the shape it does.

## Callbacks, delegates, and the app loop

A real app has to be *called back*: `windowShouldClose:`, `numberOfRowsInTableView:`,
a button's target/action. So the bridge also runs in reverse — it creates real
Objective-C subclasses at runtime with `objc_allocateClassPair` +
`class_addMethod`, where each `IMP` is a small C function that carries an integer
**ticket** back into the VM (the real receiver kept in a GC-rooted map). Async
callbacks (target/action) fire and forget; synchronous ones (delegate methods
that must *return* a value) block on the VM and hand the answer back. The
compile-time school gets this for free — since a MacModula2 class already *is* an
`NSView`, AppKit's callback lands in the method body with no ticket at all.

And because AppKit is main-thread-only while the VM heap is single-threaded, the
bridge bootstraps `NSApplication` on the main thread and hops every UI send onto
it (`dispatch_sync` to main), with results owned inside the hop. One heap, one
main thread, one carefully policed doorway between them.

## The through-line

The bridge's real achievement is a reframing: **Cocoa is not a library these
languages call; it is an object model they join.** A class becomes an
Objective-C class, a method call becomes an `objc_msgSend`, a delegate becomes a
runtime subclass — and the only new machinery is a narrow contract (one
fixed-shape send, opaque handles, tickets, a main-thread doorway) narrow enough
that a small VM can trust it against a framework it will never fully understand.
That contract is what let a Modula-2, a Forth, a Smalltalk, and a 2017 Dart all
open the same live `NSWindow` on Apple Silicon — each of them, on this target,
genuinely a Cocoa program.

## Screenshots

> _Add to `static/images/cocoa-bridge/`: a live NSWindow opened from Smalltalk and
> from Dart side by side; the AAPCS64 register-slot diagram for the fixed shape; a
> MacModula2 `CLASS INHERIT NSView` receiving `drawRect:`; the ticket/IMP callback
> path._

![One NSWindow, four languages: the same Cocoa object model joined four ways](/images/cocoa-bridge/01.png)

## Related

- [cocoa_data](/posts/cocoa-data) — the shared SQLite mirror of the Objective-C surface
- [MacModula2](/posts/macmodula2) — the progenitor: "a class *is* an Obj-C object"
- [MACVM](/posts/macvm) / [MACDART](/posts/macdart) — the dynamic school and the fixed-shape shim
- [MF67](/posts/mf67) — Cocoa from Forth (the JIT-thunk school)
- [The role of the GC in these compilers](/posts/gc-in-these-compilers) — the moving-GC ↔ ARC boundary in full
- [arm64 vs x64](/posts/arm64-vs-x64) — why AAPCS64's separate register files make the one-shape trick work
