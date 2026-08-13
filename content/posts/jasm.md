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

An assembler with the batch processing removed. You hand JASM assembly
source as a string; it hands you back a callable `extern "C"` function
pointer, in-process, immediately — no object file, no linker, no temp
directory, no subprocess. The README's own pitch: "A JIT macro-assembler for
x86-64 Windows **and** Apple Silicon. Source in, function pointer out.
Brings MASM32-era ergonomics to a modern pipeline, exposes the entire Win32
API by name, and ships a crash dumper for when your hand-written asm goes
sideways."

> _Note (2026-06): the repo has since made the **native encoder the default**, with
> LLVM-MC kept as the byte-for-byte oracle. The cross-platform claim holds — JASM
> carries both a `rasm` x86-64 encoder and an `a64` AArch64 encoder for Apple
> Silicon; the latter is vendored into [MACVM](/posts/macvm) as `wfasm`.
> ([MRASM](/posts/mrasm) is a separate, knowledge-rich macOS assembler — not JASM's
> arm64 back-end.)_

## Why I built it

The itch was straightforward: MASM32-era ergonomics — `invoke`, structs,
the platform API by name — on a modern, cross-platform JIT. The MASM32
community had assembly programming feeling *convenient* twenty-odd years
ago, and that convenience simply never got ported forward.

The function-pointer-out contract is the part I care about most, because it
changes what assembly programming *feels* like. Write a routine, call it,
see the result, adjust — the same tight loop an interpreter gives you, at
the lowest level there is. Assembly with a batch toolchain is homework;
assembly with a two-second write/run loop is play. Most of what this
portfolio believes about programming is in that difference.

## How it works

- **Native encoder (default):** two ISA back-ends behind one `Encoder` trait — the
  **`rasm`** x86-64 encoder (Windows: VirtualAlloc + relocations under W^X) and the
  **`a64`** AArch64 encoder (Apple Silicon). Both are gated **byte-for-byte against
  an LLVM-MC oracle** — the same instruction is assembled by both, and any byte of
  difference fails the build. (The x86-64 side of that discipline later graduated
  into [WRASM](/posts/wrasm)'s frozen 5,109-instruction corpus.)
- **LLVM-MC path (optional):** the original LLVM-MC + MCJIT pipeline, now opt-in
  behind the `llvm` feature and used mainly as the oracle.
- **arm64 / `MAP_JIT`:** the `a64` encoder is a genuine LLVM-free AArch64 assembler
  with its own macOS `MAP_JIT` W^X loader (`native_macos.rs`) — the piece
  [MACVM](/posts/macvm) vendors as `wfasm` to JIT its Smalltalk on Apple Silicon.
- **Win32 by name:** the entire Win32 API surface, generated from Microsoft's
  `Windows.Win32.winmd` metadata (via `windows_api.db`) — so `invoke
  MessageBoxA, …` marshals per the Win64 ABI and just works, MASM32-style.
- **Crash dumper:** a VEH/SEH dumper (registers + stack) for when hand-written asm
  faults or hits an `int 3`.

## What works today

The correctness story is the byte-for-byte gate, and it is a checkable
claim, not a vibe: both native encoders assemble the same instructions as
LLVM-MC or the build fails. Beyond the gate, the strongest evidence is
*use*: the WF64→WF65 Forths were built and JIT-loaded through JASM, and the
`a64` encoder is vendored into [MACVM](/posts/macvm) as `wfasm` — a
from-scratch Smalltalk VM trusts it to emit every instruction of its
adaptive compiler's output, on hardware that punishes sloppy JITs. An
assembler's best testimonial is a VM that stakes itself on it.

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

- **Gate a hand-rolled encoder against an oracle from day one.** Encoders
  fail in ways tests written by the encoder's author never catch — the
  author's misreadings of the manual are *correlated* between the code and
  the tests. A reference assembler is an independent misreading. Byte
  identity against LLVM-MC is the cheapest strong claim in this whole
  portfolio, and it is the practice every later project inherited.
- **What LLVM-free actually bought.** On Windows, WF64 shipped a stock
  67.7 MB `LLVM-C.dll` in a 71 MB release folder — a dependency an order of
  magnitude larger than the program. The LLVM-free path costs you the
  encoder (once, gated) and buys back the footprint, the build time, and on
  Apple Silicon the freedom to own the `MAP_JIT` story outright. Renting was
  the right way to start; owning was the right way to finish.

## Links

- Source: https://github.com/albanread/JASM
- Sibling assembler: [MRASM](/posts/mrasm)
- Generates MACVM's code: JASM's AArch64 encoder, vendored as `wfasm` in [MACVM](/posts/macvm)
- Built on it: the WF65 → [WF66](/posts/wf66) Forth line
