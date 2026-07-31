+++
title = "JASM — a JIT macro-assembler, source in, function pointer out"
date = 2026-05-18
description = "A JIT macro-assembler for x86-64 Windows: MASM32-era ergonomics, the whole Win32 API by name, and a from-scratch native encoder gated byte-for-byte against LLVM-MC. Its arm64 sibling is MRASM."
[taxonomies]
tags = ["assembler", "jit", "rust", "x86-64", "windows"]
[extra]
repo = "https://github.com/albanread/JASM"
language = "Rust (native x86-64 encoder; LLVM-MC as oracle)"
platform = "x86-64 Windows (arm64 realized in the sibling MRASM)"
status = "Working"
period = "2026-05 → 2026-06"
downloads = []
+++

_Feed it assembly source, get back a function pointer you can call. No linker, no
temp files, no subprocess._

## TL;DR

- **What:** a JIT macro-assembler — assemble in memory and get a callable
  function pointer straight back.
- **Stack:** Rust, x86-64 Windows. Its **from-scratch native encoder is now the
  default backend**, gated **byte-for-byte against LLVM-MC** (kept only as an
  oracle); the original LLVM-MC + MCJIT path remains available behind a feature
  flag. The LLVM-free **arm64** realization is its macOS sibling
  [MRASM](/posts/mrasm).
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

> _Note (2026-06): the repo has since made the **native encoder the default**, with
> LLVM-MC kept as the byte-for-byte oracle; the LLVM-free **arm64** line is carried
> by the sibling [MRASM](/posts/mrasm)._

## Why I built it

- _The itch: wanting MASM32 ergonomics on a modern, cross-platform JIT._
- _Why a function pointer straight out matters — the tight write/run loop._

## How it works

- **Native encoder (default):** a **from-scratch x86-64 encoder** assembles and
  loads in-process (VirtualAlloc + relocations under W^X), gated **byte-for-byte
  against LLVM-MC** — every instruction it emits is verified against the reference
  assembler. _Expand: how the differential test harness works._
- **LLVM-MC path (optional):** the original LLVM-MC + MCJIT pipeline, now opt-in
  behind the `llvm` feature and used mainly as the oracle.
- **arm64 / `MAP_JIT`:** the LLVM-free AArch64 encoder and the `MAP_JIT` W^X loader
  live in the macOS arm64 sibling, [MRASM](/posts/mrasm).
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

Prebuilt Windows binaries: the [GitHub Releases page](https://github.com/albanread/JASM/releases).
(The macOS arm64 assembler is its sibling [MRASM](/posts/mrasm).)

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
