+++
title = "NewFactor — an ANS Forth that runs on Factor's JIT VM"
date = 2026-05-24
description = "A Rust ANS Forth compiler whose back-end is Factor's production VM: it does the whole Forth front end, emits canonical Factor as an internal IR, and runs it on Factor's optimizing JIT — the bet being that generated Factor beats hand-written assembly."
[taxonomies]
tags = ["forth", "factor", "compiler", "jit", "rust", "windows", "concatenative"]
[extra]
repo = "https://github.com/albanread/FactorForth"
language = "Rust (embeds a patched Factor VM, factor.dll)"
platform = "x86-64 Windows"
status = "Working — ANS Core ~95%+; formal benchmark pending"
period = "2026-05 → 2026-06"
downloads = []
+++

_Give 1990s-vintage ANS Forth a world-class engine by brokering an introduction to
Factor's optimizing JIT — the programmer writes Forth and never sees Factor._

## TL;DR

- **What:** a Rust **ANS Forth** compiler whose back-end is **Factor's production
  VM**. It runs the whole Forth front end, then lowers to canonical Factor source
  as an internal IR and executes it on Factor's optimizing JIT. Both languages are
  concatenative; the programmer writes Forth and never sees Factor.
- **How:** embeds a **patched `factor.dll`** (with `nf_*` embedding-API exports) via
  `libloading`, reusing Factor's register-allocated CFG, polymorphic inline caches,
  and generational GC. No own codegen.
- **The bet:** generated Factor beats hand-written assembly — `fractal-iter` in ~30
  lines of pure Forth vs WF64's ~150 lines of hand-written MASM, on the same
  Direct2D `iGui`.
- **Get it:** [Downloads](#download-run) · [Source](https://github.com/albanread/FactorForth)

## Where it sits

NewFactor is one of the Windows "New*" family; it reuses [WF64](/posts/wf64)'s
`iGui` Direct2D shell but is explicitly decoupled from WF64's Forth runtime and GC.
_(The published repository is `FactorForth`; the project/binary name is
`newfactor`.)_ Built against Factor (Pestov / Ehrenberg / Groff, DLS 2010). See the
[timeline](/timeline).

## What it is

> _From the repo —_ a from-scratch ANS Forth front end over an embedded Factor VM.
> The Forth programmer gets a modern optimizing runtime (Factor's) without leaving
> Forth; Factor's optimizer does the unboxing and register allocation that a naive
> Forth would leave on the table.

## Why I built it

- _TODO (editorial): "borrow a great JIT instead of writing one" — when reuse beats
  building, and the concatenative-to-concatenative match that makes it clean._

## How it works

- **Front end → Factor IR:** full ANS Forth lexer/compiler, lowering each definition
  to canonical Factor source.
- **Embedded VM:** a patched `factor.dll` loaded via `libloading`, with `zstd`
  compressing Factor's ~134 MB image to ~30 MB; a three-thread architecture (GUI /
  IDE worker / Factor VM worker) with three-level crash recovery (VEH → `catch_unwind`
  → session restart).
- **Runtime surface:** ANS Core ~95%+ (defining words, control flow, floats,
  pictured numeric output); a `LET` infix-algebra DSL with transcendentals (Factor's
  optimizer unboxes it); managed strings backed by Factor's native string type;
  ANS-style locals `{: x y :}`.
- **GUI:** reuses WF64's Direct2D/DirectWrite `iGui`; graphical in-IDE demos —
  Mandelbrot, a negamax Othello, bouncing balls.

## What works today

> _Grounded facts:_ Phases 0–4 complete; 226 tests across 16 suites including a
> 61-assertion Forth-2012 conformance corpus; working IDE binary `newfactor-ui.exe`.
> Pending: the formal Mandelbrot-vs-WF64-MASM benchmark and some ANS stragglers
> (`?DUP`, `DEFER`, `CATCH`/`THROW`). _Fill specifics from the repo._

## Screenshots

> _Add to `static/images/newfactor/`: the graphical Othello; Mandelbrot; the IDE._

![NewFactor running graphical Othello](/images/newfactor/01.png)

## Download & run

Prebuilt Windows binaries: the [GitHub Releases page](https://github.com/albanread/FactorForth/releases).

```bash
git clone https://github.com/albanread/FactorForth
cd FactorForth
cargo build --release
```

## Notes, dead-ends, lessons

- _TODO (editorial): embedding Factor's VM; what "the same demo, 30 vs 150 lines"
  really shows._

## Links

- Source: https://github.com/albanread/FactorForth
- Borrows its GUI from: [WF64](/posts/wf64)
- The other Forth line: [WF66](/posts/wf66) → [MF66](/posts/mf66)
