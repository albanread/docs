+++
title = "MacBCPL — modern BCPL on Apple Silicon, JIT and AOT"
date = 2026-06-28
description = "The Apple Silicon fork of NewBCPL: run JITs a program in-process, build emits a standalone signed Mach-O — at parity, with the full memory model and Cocoa, including user-defined CLASSes with inheritance."
[taxonomies]
tags = ["bcpl", "compiler", "jit", "aot", "llvm", "rust", "arm64", "cocoa"]
[extra]
repo = "https://github.com/albanread/MacBCPL"
language = "Rust + LLVM"
platform = "Apple Silicon (arm64-apple-darwin)"
status = "Under development — JIT and AOT both work"
period = "2026-06 → 2026-07"
downloads = []
+++

_The same modern BCPL, now on Apple Silicon — and this one can hand you a signed
standalone executable, not just a JIT session._

## TL;DR

- **What:** modern **BCPL** on Apple Silicon — a Rust + LLVM compiler for macOS
  arm64 with **both** a JIT (`run`) and AOT standalone executables (`build`).
- **Parity:** `build` emits a standalone **signed Mach-O** at parity with the
  JIT — console programs, the full memory model, **Cocoa** (system classes and
  user-defined `CLASS`es with inheritance), and `modules-active/` linking.
- **Get it:** [Downloads](#download-run) · [Source](https://github.com/albanread/MacBCPL)

## Where it sits

MacBCPL is the Apple Silicon fork of [NewBCPL](/posts/newbcpl) (which came from
NBCPL). It's the BCPL line's arrival on the Mac, gaining AOT and Cocoa. See the
[timeline](/timeline).

## What it is

> _From the README —_ "Modern BCPL on Apple Silicon — a Rust + LLVM compiler for
> macOS arm64, with both a JIT (`run`) and AOT standalone executables (`build`).
> `run` JITs and executes a program in-process; `build` emits a standalone signed
> Mach-O executable — at parity with the JIT: console programs, the full memory
> model, Cocoa… and `modules-active/` linking."

## Why I built it

[NewBCPL](/posts/newbcpl) proved the modern dialect but stopped at a JIT —
it could *run* programs, not *ship* them. Bringing the line to Apple
Silicon was the moment to fix that: a language isn't fully resident on a
platform until it can hand you a standalone, signed executable that runs on
a machine with no toolchain installed. `build` is BCPL earning its Mach-O.

Having two back-ends immediately creates the obligation the project treats
as a feature: **parity**. The same program must behave identically whether
JITed in-process or built to a standalone binary — otherwise "AOT" is
quietly a second dialect. Same behaviour, two emission strategies, checked
rather than assumed.

## How it works

- **`run` (JIT):** in-process MCJIT, like NewBCPL.
- **`build` (AOT):** the same front and middle end — one pipeline down to
  LLVM IR — then object emission, linking, and `codesign` to a standalone
  signed Mach-O. Parity is a consequence of the architecture (everything
  above emission is shared code) and then held by running the same
  programs down both paths.
- **Cocoa:** system classes plus **user-defined `CLASS`es with inheritance** —
  querying the shared [cocoa_data](/posts/cocoa-data) metadata.

## What works today

Both paths, at parity, per the README's own claim: console programs, the
full memory model, `modules-active/` linking, and Cocoa — including
user-defined `CLASS`es *inheriting* from system classes, which is the point
where a bridge stops being a foreign-function veneer and becomes an object
model. The `build` output is a signed Mach-O you can hand to another
machine. For a language whose reference manual predates the microprocessor,
that is a satisfying sentence to type.

## Download & run

Prebuilt Apple Silicon binaries: the [GitHub Releases page](https://github.com/albanread/MacBCPL/releases).

```bash
git clone https://github.com/albanread/MacBCPL
cd MacBCPL
cargo build --release
# run <program.b>   — JIT
# build <program.b> — standalone signed Mach-O
```

## Notes, dead-ends, lessons

- **Parity is a practice, not a property.** Two back-ends drift the moment
  you stop checking; the only affordable defence is structural (share
  everything above emission) plus habitual (run the corpus down both paths,
  every time). A parity claim without the second half is a press release.
- **What the Mac actually changed:** the platform skin (Direct2D →
  Cocoa/Metal), the memory ceremony (SEH-aware JIT pages → `MAP_JIT`), and
  one thing Windows never asked for — the **signing** step. On macOS an AOT
  compiler must also be a `codesign` orchestrator, or its output won't run
  on the machine next door. The language didn't change at all, which was
  the point of keeping the brain and the skin separate.

## Links

- Source: https://github.com/albanread/MacBCPL
- Windows predecessor: [NewBCPL](/posts/newbcpl)
- Cocoa metadata: [cocoa_data](/posts/cocoa-data)
