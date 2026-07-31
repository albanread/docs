+++
title = "MacNCL — Common Lisp on Apple Silicon, with a Cocoa + Metal GUI"
date = 2026-06-24
description = "The Apple Silicon port of NCL: an LLVM-22 JIT Common Lisp modelled on Corman Lisp, with the iGui shell re-targeted from Direct2D/Direct3D11 to Cocoa + Metal + Core Text."
[taxonomies]
tags = ["lisp", "common-lisp", "compiler", "jit", "llvm", "rust", "arm64", "metal", "cocoa"]
[extra]
repo = "https://github.com/albanread/MacNCL"
language = "Rust + LLVM 22"
platform = "Apple Silicon (aarch64-apple-darwin)"
status = "Under development"
period = "2026-06"
downloads = []
+++

_NCL, re-homed to Apple Silicon — the compiler on LLVM 22, and the whole GUI shell
moved from DirectX to Cocoa + Metal + Core Text._

## TL;DR

- **What:** an Apple Silicon port of [NCL](/posts/newcl) — a from-scratch,
  LLVM-JIT Common Lisp modelled on Corman Lisp.
- **Two tracks:** **Core** — compiler + GC + runtime + console REPL on **LLVM 22**
  for Apple Silicon; **GUI** — re-target the `iGui` shell from
  Direct2D/Direct3D11/DirectWrite to **Cocoa + Metal + Core Text**.
- **Get it:** [Downloads](#download-run) · [Source](https://github.com/albanread/MacNCL)

## Where it sits

MacNCL is the Lisp line's arrival on the Mac: Corman Lisp → [NCL](/posts/newcl) →
**MacNCL**. The GUI re-targeting mirrors what the BCPL line did in
[MacBCPL](/posts/macbcpl). See the [timeline](/timeline).

## What it is

> _From the README —_ "An Apple Silicon (macOS / `aarch64-apple-darwin`) port of
> NCL — a from-scratch, LLVM-JIT Common Lisp modelled on Corman Lisp. Two tracks:
> **Core** — compiler + GC + runtime + console REPL on LLVM 22 for Apple Silicon.
> **GUI** — re-target the `iGui` shell from Direct2D/Direct3D11/DirectWrite to
> Cocoa + Metal + Core Text."

## Why I built it

- _Bringing the NCL experience to the Mac, natively._
- _A real graphics stack (Metal + Core Text) instead of a portability shim._

## How it works

- **Core:** reader → compiler → LLVM 22 JIT → run, with the new GC and a console
  REPL.
- **GUI:** _the iGui shell on Cocoa + Metal + Core Text — what porting from
  Direct2D/Direct3D11/DirectWrite actually involved._

## What works today

> _Fill from the many demo `.lisp` files (bouncing, smoke, load-probe), `bench/`,
> and `NCLMac.md`. Show a Metal-rendered Lisp demo._

## Screenshots

> _Add to `static/images/macncl/`: the console REPL on arm64; a bouncing-graphics
> demo rendered via Metal; Core Text output._

![A MacNCL graphics demo rendered through Metal](/images/macncl/01.png)

## Download & run

Prebuilt Apple Silicon binaries: the [GitHub Releases page](https://github.com/albanread/MacNCL/releases).

```bash
git clone https://github.com/albanread/MacNCL
cd MacNCL
cargo build --release
```

## Notes, dead-ends, lessons

- _Direct2D/Direct3D11/DirectWrite → Cocoa/Metal/Core Text: the porting map._
- _Living on LLVM 22 on Apple Silicon._

## Links

- Source: https://github.com/albanread/MacNCL
- Windows predecessor: [NCL](/posts/newcl)
- Kindred GUI port: [MacBCPL](/posts/macbcpl)
