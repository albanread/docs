+++
title = "NewFB — FasterBASIC rebuilt as a Windows-first Rust + LLVM compiler"
date = 2026-05-12
description = "A from-scratch reimplementation of the FasterBASIC dialect for Windows: Rust + LLVM, JIT-first with AOT, single-inheritance OO, a precise tracing GC, and a retro graphics stack — palette framebuffer, sprites, tilemaps, D3D11, XAudio2."
[taxonomies]
tags = ["basic", "compiler", "jit", "aot", "llvm", "rust", "windows", "retro"]
[extra]
# NOTE (factual): E:\NewFB has no configured git remote — this URL is the
# conventional name and is unverified. Confirm/replace before publishing.
repo = "https://github.com/albanread/NewFB"
language = "Rust + LLVM (Inkwell) — MCJIT + AOT"
platform = "x86-64 Windows (x86_64-pc-windows-msvc)"
status = "Working — OO + precise GC + retro graphics (the repo's README status line understates it)"
period = "2026-05 → 2026-07"
downloads = []
+++

_A modern BASIC that sits on serious infrastructure: from-scratch FasterBASIC on
Rust + LLVM, with OO, a precise GC, and a retro sprite/tilemap graphics stack._

## TL;DR

- **What:** a from-scratch reimplementation of the **FasterBASIC** dialect,
  Windows-first, on **Rust + LLVM** — JIT-first (`newfb run`) with opt-in AOT
  (`newfb build`). _(The original FasterBASIC is a Zig-compiler-fork + LLVM,
  macOS-first project; NewFB shares no source with it — it's a tribute at the
  language/demo level.)_
- **Not a toy underneath:** single-inheritance OO with devirtualization, a **precise
  tracing GC** (ported from NewCP, with LLVM `gc.statepoint` stack maps), WORKER/
  SPAWN/AWAIT concurrency, automatic SIMD, Win32/COM FFI, and a **retro graphics**
  layer (palette framebuffer, sprites, tilemaps, CRT-scanline shader, D3D11,
  XAudio2/MIDI).
- **Get it:** [Downloads](#download-run) · Source (see note above)

## Where it sits

NewFB is one of the Windows "New*" family of from-scratch Rust + LLVM compilers,
built on the shared substrate: it reuses NewCP's `iGui` shell and precise GC, the
NewCormanLisp SEH machinery, and lessons from NewM2's JIT. See the
[timeline](/timeline).

## What it is

> _From the repo —_ a Windows-first modern BASIC. Its README still opens with a
> "Pre-bootstrap (v0.0.0), workspace skeleton only" line **that dates to the first
> commit and no longer reflects reality** — by mid-2026 the repo has OO
> polymorphism + devirtualization, `new`/`delete`, COM interfaces, Win32 windows,
> D3D11, generated Win32 bindings, tilemaps/blitting/sound, and a "value-flow
> integrity net" that has caught real codegen bugs. _Trust the commit log /
> `docs/divergence.md`, not the README status line._

## Why I built it

- _TODO (editorial): "a toy language can sit on serious infrastructure" — the actual
  thesis; the retro-graphics angle._

## How it works

- **Pipeline:** lex → parse → sema → typed IR/CFG → LLVM IR → **MCJIT** (JIT-first),
  with opt-in **AOT** (`newfb build`); every phase has a stable textual dump.
  Workspace of 8 crates (`newfb-lexer/parser/sema/ir/llvm/runtime/loader/driver`).
  "No hand-written assembly" is a stated rule (SIMD via `core::arch` / LLVM
  vectors).
- **Objects + memory:** classes with single inheritance, virtual dispatch and
  devirtualization; a precise tracing GC (from NewCP) with `gc.statepoint` stack
  maps, write barriers, and a multi-threaded mutator.
- **Concurrency:** WORKER / SPAWN / AWAIT with mailbox isolation; complex numbers
  first-class; automatic SIMD on eligible UDTs.
- **Platform + retro:** iGui (Direct2D + DirectWrite + DXGI) with the BASIC on its
  own thread behind an event mailbox; a `RetroCanvas` indexed-colour framebuffer, a
  palette-lookup pixel shader, sprites/tilemaps, an optional CRT-scanline filter,
  D3D11 demos, and XAudio2 + Win32 MIDI. Win32/COM FFI over a committed
  Win32-metadata snapshot.

## What works today

> _Grounded facts:_ 63 Rust files, 38 `.bas` demos incl. a Brickout; OO,
> `new`/`delete`, COM, D3D11 clear, ADDRESSOF callbacks under a catch boundary, a
> Console TUI module written in BASIC. _Fill specifics from the repo (and correct
> the stale README)._

## Screenshots

> _Add to `static/images/newfb/`: the Brickout demo; a tilemap/sprite scene; the CRT
> filter._

![NewFB running a retro demo](/images/newfb/01.png)

## Download & run

> _Note: confirm the repository is published (no remote was configured locally at
> scaffolding time)._

```bash
# once published:
git clone https://github.com/albanread/NewFB
cd NewFB
cargo build --release
```

## Notes, dead-ends, lessons

- _TODO (editorial): the stale-README hazard; the "value-flow integrity net" that
  caught codegen bugs._

## Links

- Reuses: NewCP's iGui shell + precise GC (see [timeline](/timeline#the-shared-windows-substrate))
- Sibling compilers: [NewBCPL](/posts/newbcpl), NewBF, [NCL](/posts/newcl)
