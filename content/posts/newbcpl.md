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

BCPL is the grandparent everyone forgets to visit: Martin Richards' 1967
systems language, the direct ancestor of B and therefore of C — which means
of nearly everything. It deserves better than to exist only in emulators
and history papers. A *modern* BCPL — with classes, SIMD types and scope
cleanup grafted onto the word-oriented core, garbage-collected, JIT-compiled
— is both a tribute and a genuine question: how far does the old design
stretch? (Further than you'd think.)

And BCPL earned the liveliest treatment I could give it: `bedit` JITs the
**current editor buffer** on Ctrl+R. No file, no build step — the text in
front of you *is* the program, running. That loop — type, run, see, adjust
— is the tightest feedback a compiled language can offer, and once you have
worked that way, batch compilation feels like correspondence chess.

## How it works

- **Full pipeline** — lex → parse → sema → IR → LLVM emit → MCJIT — with a
  precise mark-sweep GC (ported from [NewCP](/posts/newcp)) and a module
  loader, over a Win64-SEH-aware JIT memory manager.
- **The dialect:** classic BCPL plus `CLASS`/`EXTENDS`/`VIRTUAL`, SIMD vector
  types, and RAII-style scope cleanup — the modern graft, kept in the
  language's own idiom. The design contract lives in `docs/manifesto.md`,
  with the vendored NBCPL reference implementation as the spec.
- **bedit:** the Direct2D/DirectWrite editor (`newbcpl-driver gui`) that
  compiles and runs the live buffer.

## What works today

The JIT path is end to end: source (or a live buffer) through the full
pipeline to running code, with the GC and module loader underneath, and
`tests/`, `examples/` and `modules-active/` exercising it. What it is
*not* yet is an executable producer — there is no AOT; NewBCPL runs
programs, it doesn't ship them. That gap was closed downstream:
[MacBCPL](/posts/macbcpl), the Apple Silicon successor, does both JIT and
AOT.

## Download & run

Prebuilt Windows binaries: the [GitHub Releases page](https://github.com/albanread/NewBCPL/releases).

```bash
git clone https://github.com/albanread/NewBCPL
cd NewBCPL
cargo build --release
```

## Notes, dead-ends, lessons

- **What travelled to the Mac, and what didn't.** The language — dialect,
  semantics, the GC's design — carried over; the *platform skin* did not:
  Direct2D/DirectWrite became Cocoa/Metal, and the Win64-SEH JIT plumbing
  became `MAP_JIT` and cache flushes. That split — portable brain,
  disposable skin — is the recurring shape of every Windows→Mac port in the
  portfolio, and the projects that kept the two separated ported in weeks.
- **The pleasing circularity:** NBCPL (an earlier Apple Silicon BCPL, in
  C++) was vendored here as the *specification*; NewBCPL rebuilt it on
  Windows in Rust; MacBCPL then carried it back to Apple Silicon with the
  AOT story the Windows version never got. The reference implementation
  travelled as cargo, and came home improved.

## Links

- Source: https://github.com/albanread/NewBCPL
- Prototype: NBCPL — Apple Silicon, C++ (github.com/albanread/NBCPL)
- Shared GUI shell: [NewCP](/posts/newcp)'s iGui
- Apple Silicon port: [MacBCPL](/posts/macbcpl)
