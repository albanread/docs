+++
title = "NewCP — Component Pascal and BlackBox, rebuilt as a JIT"
date = 2026-05-03
description = "A from-scratch recreation of Component Pascal and the BlackBox Component Builder on Rust + LLVM: a memory-resident JIT with a dynamic module loader — and the birthplace of the Direct2D iGui shell the whole Windows family reuses."
[taxonomies]
tags = ["component-pascal", "oberon", "compiler", "jit", "llvm", "rust", "windows"]
[extra]
repo = "https://github.com/albanread/NewCP"
language = "Rust + LLVM 22 (Inkwell) + MCJIT"
platform = "x86-64 Windows (x86_64-pc-windows-msvc)"
status = "Under development — compiler working (phases 0–6), framework/GUI in progress"
period = "2026-05"
downloads = []
+++

_Component Pascal — the Oberon-2 descendant behind Oberon microsystems' BlackBox —
recreated from scratch as a memory-resident JIT, and the project where the family's
Direct2D "iGui" shell was born._

## TL;DR

- **What:** a from-scratch recreation of **Component Pascal** and the **BlackBox
  Component Builder** environment — compiler, JIT runtime, dynamic module loader,
  and a partial BlackBox framework port.
- **Stack:** Rust (edition 2024) → typed IR → **LLVM IR → MCJIT** (via Inkwell,
  `llvm22-1`), executed in-process. A 10-phase pipeline, each phase emitting a
  stable textual dump.
- **Why it matters here:** NewCP is the **earliest 2026 project** in the portfolio
  and the **origin of `iGui`**, the immediate-mode Direct2D/DirectWrite MDI shell
  that later languages reuse.
- **Get it:** [Downloads](#download-run) · [Source](https://github.com/albanread/NewCP)

## Where it sits

NewCP is the wellspring of the Windows family's shared GUI. Its `iGui` shell is
reused (often by name) by [NewBCPL](/posts/newbcpl), [NCL](/posts/newcl), NewFB,
NewBF, NewFactor, the Modula-2 line, and the WF64→[WF66](/posts/wf66) Forths. Its
own home-grown mark-sweep `gc.rs` was ported into NewBCPL and others. See the
[timeline](/timeline).

## What it is

> _From the repo —_ "CP" = **Component Pascal**, the Oberon-2-derived language from
> Oberon microsystems' BlackBox. NewCP is all of: a real compiler for Component
> Pascal; a JIT runtime with a dynamic, on-demand module loader; a partial BlackBox
> framework port (Kernel, Files, Fonts, Stores/Views/Models, the ODC document
> model); and the birthplace of `iGui`. It is memory-resident, not a batch/object-
> file compiler: parse → type-check → typed IR → LLVM IR → MCJIT into the running
> process. It reads a 675-file BlackBox 1.7 `.odc` corpus via `newcp-odc`.

## Why I built it

- _TODO (editorial): the pull of Component Pascal / BlackBox, and why "memory-
  resident, JIT-first" was the right shape._

## How it works

- **Pipeline:** a 10-phase compiler (lexer / parser / sema / module-graph / CFG /
  typed-IR / LLVM-IR / asm / heap), each phase emitting a reviewable textual dump.
  Workspace of ~10 crates (`newcp-lexer/parser/sema/ir/llvm/runtime/loader/odc/
  driver`).
- **Dispatch on MCJIT:** virtual method dispatch works on MCJIT via vtables patched
  after materialization (a workaround for MCJIT relocation gaps); record extension
  and cross-module OOP run on the JIT.
- **Module loader:** active/retired generations with a hot-reload drop-predicate;
  Rust-hosted and Component-Pascal modules look identical to the loader.
- **iGui:** an immediate-mode MDI windowing layer built directly on **Direct2D +
  DirectWrite over Direct3D 11 + DXGI** (`src/newcp-runtime/src/igui/`). The GUI
  owns the main thread; the language runtime is launched behind it and talks to it
  through an event mailbox + a synchronous query channel — it never owns an HWND or
  a Direct2D resource directly.
- **GC:** its own `gc.rs` (~1,800 lines) — cluster/block layout, tagged alloc,
  mark/sweep, finalizers, module roots, `dump-heap` introspection.

## What works today

> _Fill from the repo's status docs. Grounded facts to date:_ compiler phases 0–6
> "real and done well"; test counts 188/188 integration, 50/50 runtime, 29/29
> loader, 474/490 in `newcp-tests`. In **Phase 7 (framework recovery)** — the
> framework/GUI is not yet user-demoable (the repo's own strategic assessment is
> candid about this). _Be honest about the "does nothing useful yet" framework
> status._

## Screenshots

> _Add to `static/images/newcp/`: the phase dumps; an iGui MDI window; a JITed CP
> module running._

![NewCP JITing a Component Pascal module](/images/newcp/01.png)

## Download & run

Prebuilt Windows binaries: the [GitHub Releases page](https://github.com/albanread/NewCP/releases).

```bash
git clone https://github.com/albanread/NewCP
cd NewCP
cargo build --release
```

## Notes, dead-ends, lessons

- _TODO (editorial): patching vtables around MCJIT; what the `.odc` corpus taught
  you; the honest "green tests, not yet useful" framework gap._

## Links

- Source: https://github.com/albanread/NewCP
- Reuses its shell: [NewBCPL](/posts/newbcpl), [NCL](/posts/newcl), [WF66](/posts/wf66)
- The shared collector story: see the [timeline](/timeline#the-shared-windows-substrate)
