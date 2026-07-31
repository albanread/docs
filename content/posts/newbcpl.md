+++
title = "NewBCPL — a modern BCPL JIT on Windows"
date = 2026-05-10
description = "A recreation of a modern BCPL dialect on Rust + LLVM for Windows: full source-to-run pipeline, precise mark-sweep GC, a module loader, and a Direct2D editor that JITs the current buffer."
[taxonomies]
tags = ["bcpl", "compiler", "jit", "llvm", "rust", "windows"]
[extra]
repo = "https://github.com/albanread/NewBCPL"
language = "Rust + LLVM (MCJIT)"
platform = "x86-64 Windows"
status = "Under development — JIT works, no AOT yet"
period = "2026-05"
downloads = []
+++

_BCPL — the language behind B, behind C — recreated in a modern dialect, JIT-compiled,
with an editor that runs your buffer as you type._

## TL;DR

- **What:** a recreation of a modern **BCPL** dialect, Rust + LLVM, targeting
  x86-64 Windows, with an integrated Direct2D + DirectWrite GUI.
- **Pipeline:** source → lex → parse → sema → IR → LLVM emit → MCJIT → run, with
  a **precise mark-sweep GC**, a module loader, and a `bedit` editor that JITs
  the current buffer.
- **Status:** end-to-end but incomplete — a JIT, not (yet) an executable
  producer.
- **Get it:** [Downloads](#download-run) · [Source](https://github.com/albanread/NewBCPL)

## Where it sits

NewBCPL is the **Windows** entry in the BCPL line: **NBCPL** (the author's earlier
Apple-Silicon ARM64 C++ BCPL, vendored here under `reference/` as the language
spec) → **NewBCPL** (Windows, Rust + LLVM) → [MacBCPL](/posts/macbcpl). Its
Direct2D shell follows **[NewCP](/posts/newcp)'s `iGui`** — the shared Windows GUI
the family reuses. See the [timeline](/timeline).

## What it is

> _From the README —_ "NewBCPL is a recreation of the modern BCPL dialect
> prototyped at NBCPL. Built on Rust + LLVM, targeted at
> `x86_64-pc-windows-msvc`, with an integrated Direct2D + DirectWrite GUI in the
> spirit of NewCP's iGui." The design contract is in `docs/manifesto.md`; the
> reference implementation under `reference/` is the spec this builds against.

## Why I built it

- _A modern take on BCPL — the ancestral systems language — that actually runs._
- _An editor that JITs the live buffer as the tightest possible feedback loop._

## How it works

- **Full pipeline** to MCJIT, with a precise mark-sweep GC and a module loader.
- **bedit:** _the Direct2D/DirectWrite editor that JITs the current buffer
  (`newbcpl-driver gui`)._

## What works today

> _Fill from the README's "What works" and the `tests/`, `examples/`,
> `modules-active/` dirs. Be candid about the "incomplete / no AOT" status._

## Screenshots

> _Add to `static/images/newbcpl/`: `bedit` JITing a buffer; a Direct2D demo; the
> REPL._

![The bedit editor JIT-running a BCPL buffer](/images/newbcpl/01.png)

## Download & run

Prebuilt Windows binaries: the [GitHub Releases page](https://github.com/albanread/NewBCPL/releases).

```bash
git clone https://github.com/albanread/NewBCPL
cd NewBCPL
cargo build --release
```

## Notes, dead-ends, lessons

- _What carried over to the Mac port, and what didn't (Direct2D → Cocoa/Metal)._

## Links

- Source: https://github.com/albanread/NewBCPL
- Prototype: NBCPL — Apple Silicon, C++ (github.com/albanread/NBCPL)
- Shared GUI shell: [NewCP](/posts/newcp)'s iGui
- Apple Silicon port: [MacBCPL](/posts/macbcpl)
