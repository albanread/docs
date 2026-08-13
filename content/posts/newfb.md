+++
title = "NewFB — FasterBASIC rebuilt as a Windows-first Rust + LLVM compiler"
date = 2026-05-12
description = "A from-scratch reimplementation of the FasterBASIC dialect for Windows: Rust + LLVM, JIT-first with AOT, single-inheritance OO, a precise tracing GC, and a retro graphics stack — palette framebuffer, sprites, tilemaps, D3D11, XAudio2."
[taxonomies]
tags = ["basic", "compiler", "jit", "aot", "llvm", "rust", "windows", "retro"]
[extra]
# The repo is not yet on GitHub (verified 404, 2026-08-13; E:\NewFB has no
# remote). Restore the field when it is published:
# repo = "https://github.com/albanread/NewFB"
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
- **Get it:** not yet — the repository hasn't been pushed to GitHub at the time
  of writing. It will appear under [albanread](https://github.com/albanread)
  when it does.

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

BASIC was the first language most of my generation ever typed, and it has
spent forty years being condescended to for it. The thesis of NewFB is that
the condescension was always about the *implementations*, not the language:
put single-inheritance OO, devirtualization, a precise statepoint-mapped GC
and a real module system **under** the friendly syntax, and BASIC turns out
to carry serious programs perfectly well. A toy surface on serious
infrastructure is not a contradiction; it is rather a good idea.

The retro graphics stack is not decoration either. An indexed-colour
framebuffer, sprites, tilemaps and a CRT-scanline shader are the *native
idiom* of the language — the pictures BASIC programmers were always trying
to make — and they double as compiler tests that exercise everything at
once: codegen, GC under animation, FFI, audio timing. If the Brickout demo
plays smoothly, a great deal of the compiler is working. And you get to
play Brickout, which the test suite never offers.

## How it works

- **Pipeline:** lex → parse → sema → typed IR/CFG → LLVM IR → **MCJIT** (JIT-first),
  with opt-in **AOT** (`newfb build`); every phase has a stable textual dump.
  Workspace of 8 crates (`newfb-lexer/parser/sema/ir/llvm/runtime/loader/driver`).
  "No hand-written assembly" is a stated rule (SIMD via `core::arch` / LLVM
  vectors).
- **Runtime written in BASIC:** a `MODULE` / `EXPORT COMMAND` / `IMPORT` system
  (compile-time `.fbi` interface + an `IMPORT` pre-pass) lets a `.bas` file register
  real BASIC verbs. The graphics, retro (fx shaders, palettes, tiles, framed
  sprites, a text HUD) and console vocabularies are now BASIC modules —
  `Graphics.bas`, `Retro.bas`, `Console.bas` — over a `DECLARE … LIB` / COM /
  `ADDRESSOF` floor, and the Rust `newfb-wingui` graphics crate was **deleted** once
  they reached parity. See [the runtime-module writer's guide](/posts/fasterbasic-runtime-modules).
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

63 Rust files and **38 `.bas` demos** including a playable Brickout; objects
with `new`/`delete` and virtual dispatch; COM interfaces and Win32 windows;
D3D11; `ADDRESSOF` callbacks running safely under a catch boundary; and a
Console TUI module written in BASIC itself. The runtime-in-BASIC programme
got far enough that the Rust graphics crate was **deleted** once the
`.bas` modules reached parity — the language now implements a good part of
its own runtime, which was rather the point.

(The README's opening line still says "workspace skeleton only." It is wrong
by several months and about sixty files — see the lessons below.)

## Download & run

Not published yet. The repository will go up under
[albanread](https://github.com/albanread) once tidied; until then this
article is the public record. When it lands:

```bash
git clone https://github.com/albanread/NewFB
cd NewFB
cargo build --release
```

## Notes, dead-ends, lessons

- **READMEs rot from the moment they are written.** NewFB's still declares
  itself a "pre-bootstrap workspace skeleton" while the commit log shows a
  working compiler with OO, COM, D3D11 and a self-hosted runtime layer. The
  durable records are the commit log and `docs/divergence.md`; a status line
  nobody re-reads is a trap for future readers — including, months later,
  the author. (This article exists partly to out-vote that README.)
- **The "value-flow integrity net" earned its keep.** A checking layer that
  follows values across the IR boundary caught real codegen bugs — the kind
  that otherwise surface as a demo drawing slightly wrong pixels a week
  later. Cheap insurance, bought early.
- **Letting the language eat its own runtime is a forcing function.** Every
  vocabulary moved from Rust into `.bas` modules (graphics, retro, console)
  found weaknesses in the FFI, the module system, or the GC — and fixed
  them for every future user. The deleted `newfb-wingui` crate is the
  happiest kind of tombstone.

## Links

- Reuses: NewCP's iGui shell + precise GC (see [timeline](/timeline#the-shared-windows-substrate))
- Sibling compilers: [NewBCPL](/posts/newbcpl), NewBF, [NCL](/posts/newcl)
