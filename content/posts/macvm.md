+++
title = "MACVM — a Smalltalk from scratch for Apple Silicon"
date = 2026-07-01
description = "The most complex compiler in the portfolio: a from-scratch Apple Silicon Smalltalk inspired by Strongtalk — with its own adaptive compiler and its own assembler for code generation, and a live Cocoa bridge."
[taxonomies]
tags = ["smalltalk", "vm", "jit", "rust", "adaptive-compiler", "cocoa", "arm64"]
[extra]
repo = "https://github.com/albanread/MACVM"
language = "Rust VM + own adaptive compiler + own assembler + Smalltalk world"
platform = "Apple Silicon (arm64-apple-darwin)"
status = "Under development — a large, live system"
period = "2026-07"
downloads = []
+++

_Strongtalk was the Smalltalk that proved the language could be fast. This is my
own run at that idea, on Apple Silicon, from a blank file._

## TL;DR

- **What:** a from-scratch Apple Silicon compiler and VM for **Smalltalk**,
  inspired by Strongtalk.
- **Stack:** a **Rust** VM with its **own adaptive compiler** (Strongtalk-style)
  generating code through its **own assembler**, a live **Cocoa** bridge, and a
  Smalltalk world image.
- **Scale:** the most complex project here — 600+ commits, and the origin of the
  Cocoa-bridge machinery the other languages reuse.
- **Get it:** [Downloads](#download-run) · [Source](https://github.com/albanread/MACVM)

## Where it sits

MACVM is the flagship of the "from-scratch language" thread and the **progenitor
of the runtime Cocoa bridge** — its fixed-shape Objective-C dispatch shim and
live `@encode` marshalling are the reference design that [MACDART](/posts/macdart)'s
`dart:cocoa` and the [cocoa_data](/posts/cocoa-data) mirror build on. Its
Smalltalk world later boots *inside* MACDART as a second language. See the
[timeline](/timeline).

## What it is

> _From the README —_ "A from-scratch Apple Silicon compiler for Smalltalk — the
> most complex compiler project in my repos… Strongtalk was released to the
> public in 2002 — first as documentation I thoroughly enjoyed reading, then as
> full C++ source. At the time it executed Smalltalk [fast]…"
>
> _Expand with your own history-of-experience framing from the README._

## Why I built it

- _Strongtalk's documentation and source as a lifelong influence._
- _Proving a dynamic language can be fast on Apple Silicon, on your own terms._

## How it works

- **Front-end → adaptive compiler → own assembler:** Smalltalk methods are
  compiled by MACVM's **own adaptive (Strongtalk-style) compiler** and emitted
  through its **own AArch64 assembler** (the vendored `wfasm`/[JASM](/posts/jasm)
  encoder) into `MAP_JIT` W^X memory. **[QBEJIT](/posts/qbejit) was reviewed as a
  backend and set aside** — a static QBE-IL→machine-code JIT is the wrong shape
  for an *adaptive* compiler that profiles, recompiles, deoptimizes, and does
  OSR — and an LLVM backend was scaffolded and left commented out. The compiler
  is MACVM's own, which means the performance is too: _entirely our fault when
  it's slow, and entirely the Strongtalk design's credit when it's fast._
- **The Cocoa bridge (the crux):** one fixed-shape AAPCS64 `objc_msgSend` shim
  (`objc_shim.m`) inside `@try/@catch`, with argument classification driven by
  **live `@encode`**, not a static table. `doesNotUnderstand:` is the language
  surface — any unknown selector marshals and dispatches. _Expand from
  `docs/cocoa_bridge_design.md`._
- **Memory model across a moving GC and ARC:** _raw `id`s in GC-opaque storage,
  retain-on-wrap, the +1-family selector classifier._
- **The pieces around it:** a `cocoa_gui`, an `ffi_gen` offline generator, an
  `image_store`, an `abc_player`, example worlds in `world/*.mst`.

## What works today

> _Fill from the repo — benchmarks (richards, deltablue), the live Cocoa GUI,
> the world image. Note MACDART later measured MACVM as its baseline: the Dart
> VM inlining Smalltalk beats it by 52–230× on those benchmarks, which is itself
> a compliment to how much MACVM does dynamically._

## Screenshots

The MACVM Smalltalk environment — here via the **WINVM** Windows port's Win32 +
WebView2 shell. The start page states the lineage outright ("inspired by
Strongtalk — polymorphic inline caches, type feedback, and deoptimization"), and
it's a *live* page: it's viewed in the MACVM browser, not a plain HTML browser,
because pages can carry executable Smalltalk (a `smappl` tag whose code runs when
you click a link). A live class tree hangs below — `Object`, `Boolean`, the SIMD
lane types `Float64x2` / `Float32x4`, `Alien`.

![The MACVM Smalltalk environment (WINVM WebView2 GUI): the Strongtalk-lineage start page and a live class tree](/images/macvm/strongtalk-gui.png)

_That Windows port now has its own home: **[WINVM](/posts/winvm)** — the x86-64
sibling that shares this entire front and middle end — with a full tour of the
environment (class browser, workspace, benchmarks, and its colour themes)._

## Download & run

Prebuilt binaries: the [GitHub Releases page](https://github.com/albanread/MACVM/releases).

```bash
git clone https://github.com/albanread/MACVM
cd MACVM
cargo build --release
```

## Notes, dead-ends, lessons

- _Why the Cocoa bridge is a *fixed-shape* shim rather than libffi or per-call
  JIT — and how that decision propagated to every other language._
- _Bridging a moving GC to ARC without corrupting tagged pointers._

## Links

- Source: https://github.com/albanread/MACVM
- Windows sibling (shared front/middle end): [WINVM](/posts/winvm)
- Assembler: the vendored `wfasm`/[JASM](/posts/jasm) AArch64 encoder ([QBEJIT](/posts/qbejit) was reviewed, not used)
- Inspiration: Strongtalk (2002)
- Its Cocoa design feeds: [cocoa_data](/posts/cocoa-data), [MACDART](/posts/macdart)
