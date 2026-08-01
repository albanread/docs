+++
title = "JASM — a JIT macro-assembler, source in, function pointer out"
date = 2026-05-18
description = "A JIT macro-assembler for x86-64 Windows and Apple Silicon: MASM32-era ergonomics, the whole Win32 API by name, and from-scratch native encoders (x86-64 and AArch64) gated against an LLVM-MC oracle — the AArch64 side is the encoder MACVM vendors as wfasm."
[taxonomies]
tags = ["assembler", "jit", "rust", "x86-64", "arm64", "windows", "apple-silicon"]
[extra]
repo = "https://github.com/albanread/JASM"
language = "Rust (native x86-64 + AArch64 encoders; LLVM-MC as oracle)"
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
- **Stack:** Rust. Its **from-scratch native encoder is now the default backend**,
  gated **byte-for-byte against LLVM-MC** (kept only as an oracle); the original
  LLVM-MC + MCJIT path remains available behind a feature flag. Two ISA back-ends
  ship behind one `Encoder` trait: **`rasm`** (x86-64, Windows) and **`a64`** — a
  **native, LLVM-free AArch64 encoder for Apple Silicon** with a `MAP_JIT` loader —
  which is what [MACVM](/posts/macvm)'s Smalltalk VM vendors as `wfasm`.
- **Ergonomics:** MASM32-era conveniences — the whole Win32 API exposed by name,
  a crash dumper for when hand-written asm goes sideways.
- **Get it:** [Downloads](#download-run) · [Source](https://github.com/albanread/JASM)

## Where it sits

JASM is the **foundation stone** of the portfolio. The Forth line was built on
it — WF65 is "a complete, working 64-bit STC Forth, JIT-compiled via the JASM
assembler" — before the Forth work moved to its own LLVM-free assembler in MF66.
Its knowledge-rich sibling for macOS is [MRASM](/posts/mrasm), and its AArch64
encoder is what [MACVM](/posts/macvm)'s Smalltalk VM vendors (as `wfasm`) to
generate code from its own adaptive compiler. A separate QBE-based JIT experiment
is [QBEJIT](/posts/qbejit). See the [timeline](/timeline).

## What it is

> _Expand: the pitch in your own words. From the README —_ "A JIT
> macro-assembler for x86-64 Windows **and** Apple Silicon. Source in, function
> pointer out. Brings MASM32-era ergonomics to a modern LLVM-MC + MCJIT
> pipeline, exposes the entire Win32 API by name, and ships a crash dumper for
> when your hand-written asm goes sideways."

> _Note (2026-06): the repo has since made the **native encoder the default**, with
> LLVM-MC kept as the byte-for-byte oracle. The cross-platform claim holds — JASM
> carries both a `rasm` x86-64 encoder and an `a64` AArch64 encoder for Apple
> Silicon; the latter is vendored into [MACVM](/posts/macvm) as `wfasm`.
> ([MRASM](/posts/mrasm) is a separate, knowledge-rich macOS assembler — not JASM's
> arm64 back-end.)_

## Why I built it

- _The itch: wanting MASM32 ergonomics on a modern, cross-platform JIT._
- _Why a function pointer straight out matters — the tight write/run loop._

## How it works

- **Native encoder (default):** two ISA back-ends behind one `Encoder` trait — the
  **`rasm`** x86-64 encoder (Windows: VirtualAlloc + relocations under W^X) and the
  **`a64`** AArch64 encoder (Apple Silicon). Both are gated **byte-for-byte against
  an LLVM-MC oracle** — every instruction is verified against the reference
  assembler. _Expand: how the differential test harness works._
- **LLVM-MC path (optional):** the original LLVM-MC + MCJIT pipeline, now opt-in
  behind the `llvm` feature and used mainly as the oracle.
- **arm64 / `MAP_JIT`:** the `a64` encoder is a genuine LLVM-free AArch64 assembler
  with its own macOS `MAP_JIT` W^X loader (`native_macos.rs`) — the piece
  [MACVM](/posts/macvm) vendors as `wfasm` to JIT its Smalltalk on Apple Silicon.
- **Win32 by name:** the entire Win32 API surface, generated from Microsoft's
  `Windows.Win32.winmd` metadata (via `windows_api.db`). _Expand: the `invoke`
  wrappers._
- **Crash dumper:** a VEH/SEH dumper (registers + stack) for when hand-written asm
  faults or hits an `int 3`.

## What works today

> _Fill from the repo's tests. Note the byte-for-byte gate against LLVM-MC as the
> correctness story — it's a strong, checkable claim._

## Screenshots

> _Add to `static/images/jasm/`: a source→pointer→call session; the crash dumper
> output; the AArch64 encoder differential test passing._

![JASM assembling and calling in one step](/images/jasm/01.png)

## Download & run

Prebuilt binaries: the [GitHub Releases page](https://github.com/albanread/JASM/releases).
JASM builds for both x86-64 Windows and Apple Silicon; [MRASM](/posts/mrasm) is a
separate, knowledge-rich macOS assembler.

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
- Generates MACVM's code: JASM's AArch64 encoder, vendored as `wfasm` in [MACVM](/posts/macvm)
- Built on it: the WF65 → [WF66](/posts/wf66) Forth line
