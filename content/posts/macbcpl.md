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

- _Bringing BCPL to Apple Silicon and giving it a real AOT story._
- _Proving JIT/AOT parity — the same program, same behaviour, two back-ends._

## How it works

- **`run` (JIT):** in-process MCJIT, like NewBCPL.
- **`build` (AOT):** _emit object code → link → codesign → standalone Mach-O.
  Describe how parity with the JIT is maintained._
- **Cocoa:** system classes plus **user-defined `CLASS`es with inheritance** —
  querying the shared [cocoa_data](/posts/cocoa-data) metadata.

## What works today

> _Fill from `tests/`, `examples/`, `modules-active/`. Emphasise the JIT/AOT
> parity claim and Cocoa with inheritance._

## Screenshots

> _Add to `static/images/macbcpl/`: `run` vs `build` producing identical output;
> a Cocoa program; the signed Mach-O in Finder/`codesign -dv`._

![MacBCPL: run (JIT) and build (AOT) side by side](/images/macbcpl/01.png)

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

- _Keeping a JIT and an AOT back-end at behavioural parity._
- _Direct2D → Cocoa: what the Mac port changed vs. NewBCPL._

## Links

- Source: https://github.com/albanread/MacBCPL
- Windows predecessor: [NewBCPL](/posts/newbcpl)
- Cocoa metadata: [cocoa_data](/posts/cocoa-data)
