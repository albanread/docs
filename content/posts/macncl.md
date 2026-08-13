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

The point of [NCL](/posts/newcl) was that Lisp should feel *native* on its
host; moving to a Mac and running the Windows build under some compatibility
arrangement would have been a joke at the project's own expense. The Mac
port had to be the same thesis restated: Corman's experience, on Apple
Silicon, speaking the platform's own dialects — which means **Metal** for
pixels and **Core Text** for glyphs, not a portability shim that renders
everything slightly wrong everywhere equally.

## How it works

- **Core:** reader → compiler → LLVM 22 JIT → run, with the new GC and a console
  REPL — the Windows compiler re-homed to `aarch64-apple-darwin`.
- **GUI:** the `iGui` shell's *pattern* survives intact — the GUI owns the
  main thread, the Lisp runtime lives behind an event mailbox — while its
  substance is re-targeted wholesale: Direct2D → Metal-backed drawing,
  DirectWrite → Core Text, the D3D11/DXGI plumbing → CAMetalLayer. Same
  architecture, new skin; the split that made the port tractable.

## What works today

The honest status is *younger sibling*: the core track — compiler, GC,
console REPL on arm64 — runs, exercised by the repo's demo `.lisp` files
(bouncing graphics, smoke tests, load probes) and `bench/`; the GUI
re-targeting is the in-progress half. MacNCL has not yet caught up with its
Windows parent's conformance numbers, and this article will say so until it
has. Portfolio policy: the status line tells the truth or it doesn't ship.

## Download & run

Prebuilt Apple Silicon binaries: the [GitHub Releases page](https://github.com/albanread/MacNCL/releases).

```bash
git clone https://github.com/albanread/MacNCL
cd MacNCL
cargo build --release
```

## Notes, dead-ends, lessons

- **The porting map is one-for-one, which is the finding.** Direct2D →
  Metal drawing, DirectWrite → Core Text, D3D11/DXGI → CAMetalLayer — each
  Windows subsystem has a Mac counterpart doing the same job with different
  paperwork. What made the mapping mechanical was `iGui`'s discipline: the
  language runtime never touched a platform handle directly, so only the
  shell's internals changed. Architecture is what makes ports boring, and
  boring is the goal.
- **Port the brain before the face.** Running the core track first —
  compiler, GC, REPL, no windows — meant the compiler could be tested to
  destruction from a terminal while the GUI was still scaffolding. A
  console REPL is a perfectly good proof of a language; pixels are morale.

## Links

- Source: https://github.com/albanread/MacNCL
- Windows predecessor: [NCL](/posts/newcl)
- Kindred GUI port: [MacBCPL](/posts/macbcpl)
