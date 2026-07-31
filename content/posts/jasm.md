+++
title = "JASM — a JIT macro-assembler, source in, function pointer out"
date = 2026-05-18
description = "A JIT macro-assembler for x86-64 Windows and Apple Silicon: MASM32-era ergonomics, a from-scratch AArch64 encoder, and a MAP_JIT loader."
[taxonomies]
tags = ["assembler", "jit", "rust", "arm64", "windows"]
[extra]
repo = "https://github.com/albanread/JASM"
language = "Rust"
platform = "x86-64 Windows and Apple Silicon (arm64-apple-darwin)"
status = "Working"
period = "2026-05 → 2026-06"
downloads = []
+++

_Feed it assembly source, get back a function pointer you can call. No linker, no
temp files, no subprocess._

## TL;DR

- **What:** a JIT macro-assembler — assemble in memory and get a callable
  function pointer straight back.
- **Stack:** Rust. On x86-64 Windows it rides an LLVM-MC + MCJIT pipeline; on
  Apple Silicon it runs **LLVM-free** with a from-scratch AArch64 encoder.
- **Ergonomics:** MASM32-era conveniences — the whole Win32 API exposed by name,
  a crash dumper for when hand-written asm goes sideways.
- **Get it:** [Downloads](#download-run) · [Source](https://github.com/albanread/JASM)

## Where it sits

JASM is the **foundation stone** of the portfolio. The Forth line was built on
it — WF65 is "a complete, working 64-bit STC Forth, JIT-compiled via the JASM
assembler" — before the Forth work moved to its own LLVM-free assembler in MF66.
Its knowledge-rich sibling for macOS is [MRASM](/posts/mrasm); the QBE-based
back-end that later took over JIT duties is [QBEJIT](/posts/qbejit). See the
[timeline](/timeline).

## What it is

> _Expand: the pitch in your own words. From the README —_ "A JIT
> macro-assembler for x86-64 Windows **and** Apple Silicon. Source in, function
> pointer out. Brings MASM32-era ergonomics to a modern LLVM-MC + MCJIT
> pipeline, exposes the entire Win32 API by name, and ships a crash dumper for
> when your hand-written asm goes sideways."

## Why I built it

- _The itch: wanting MASM32 ergonomics on a modern, cross-platform JIT._
- _Why a function pointer straight out matters — the tight write/run loop._

## How it works

- **Windows path:** LLVM-MC assembles, MCJIT relocates and executes in-process.
- **Apple Silicon path:** a **from-scratch AArch64 encoder**, gated
  **byte-for-byte against LLVM-MC** so every instruction it emits is verified
  against the reference assembler, plus a `MAP_JIT` loader for W^X-compliant
  executable memory. _Expand: how the differential test harness works._
- **Win32 by name:** _how the API surface is exposed to the assembly programmer._
- **Crash dumper:** _what it captures and why hand-written asm needs it._

## What works today

> _Fill from the repo's tests. Note the byte-for-byte gate against LLVM-MC as the
> correctness story — it's a strong, checkable claim._

## Screenshots

> _Add to `static/images/jasm/`: a source→pointer→call session; the crash dumper
> output; the AArch64 encoder differential test passing._

![JASM assembling and calling in one step](/images/jasm/01.png)

## Download & run

Prebuilt binaries: the [GitHub Releases page](https://github.com/albanread/JASM/releases). Windows and Apple
Silicon builds are separate artifacts.

```bash
git clone https://github.com/albanread/JASM
cd JASM
cargo build --release
```

## Notes, dead-ends, lessons

- _The value of gating a hand-rolled encoder against LLVM-MC byte-for-byte._
- _What "LLVM-free on Apple Silicon" bought you vs. the Windows LLVM path._

## Links

- Source: https://github.com/albanread/JASM
- Sibling assembler: [MRASM](/posts/mrasm)
- Later JIT back-end: [QBEJIT](/posts/qbejit)
- Built on it: the WF65 → [WF66](/posts/wf66) Forth line
