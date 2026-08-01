+++
title = "NCL — a from-scratch Common Lisp in the Corman spirit"
date = 2026-05-10
description = "A from-scratch reimplementation of the Common Lisp / Corman Lisp language and user-facing experience: Rust core, LLVM 22.1 MCJIT, a generational page-heap GC, 64-bit Windows, with a Mac port planned."
[taxonomies]
tags = ["lisp", "common-lisp", "compiler", "jit", "llvm", "rust", "windows"]
[extra]
repo = "https://github.com/albanread/NewCL"
language = "Rust + LLVM 22.1 — MCJIT (generational page-heap GC)"
platform = "64-bit Windows (Mac port → MacNCL)"
status = "Working — JIT Common Lisp, pre-1.0 (~760/919 ANSI forms)"
period = "2026-05 → 2026-07"
downloads = []
+++

_Corman Lisp made Common Lisp feel native on Windows. NCL is a from-scratch run at
that same experience — new compiler, new GC, new everything._

## TL;DR

- **What:** a from-scratch reimplementation of the **Common Lisp / Corman Lisp**
  language *and* user-facing experience — Rust core, LLVM-based JIT, 64-bit,
  Windows-first with a Mac port planned.
- **Not a re-runner:** it ports some Corman Lisp source and demos, but does not
  run the original's compiled artifacts (`.img`, `.fasl`) — recompile from
  source.
- **Warning from the README:** "Beware this compiler and GC are all new."
- **Get it:** [Downloads](#download-run) · [Source](https://github.com/albanread/NewCL)

## Where it sits

NCL is the Windows original of the Lisp line: Corman Lisp → **NCL** →
[MacNCL](/posts/macncl). See the [timeline](/timeline).

## What it is

> _From the README —_ "A from-scratch reimplementation of the Common Lisp /
> Corman Lisp **language and user-facing experience** — Rust core, LLVM-based
> JIT, 64-bit, Windows-first with a Mac port planned." See `MANIFESTO.md`.

## Why I built it

- _Corman Lisp's developer experience as the thing worth recreating, not just the
  language._
- _A modern Rust + LLVM core underneath a classic CL surface._

## How it works

- **JIT-first, no interpreter:** reader → NCL's own IR (`ncl-ir`) → **LLVM 22.1
  MCJIT** (`-O2`), compiled per function. Optimizations include self-tail-call
  elimination, unboxed `double-float` inference, no-capture closure elision, and
  inlining of `declaim inline`.
- **GC:** a custom **generational page-heap** collector (G0/G1/Tenured) with
  conservative stack pinning, a precise inline root stack, and card marking — the
  collector later generalized into the shared **NewGC**.
- **Surface:** a numeric tower (fixnum/bignum/ratio/double-float/complex), a full
  macro system, a condition system with restarts, and a CLOS derived from Closette;
  function cells are atomic for single-store redefinition (SBCL/CCL-style hot
  reload).
- **GUI:** the Direct2D / Direct3D 11 / DirectWrite **`iGui`** shell, borrowed from
  sibling project [NewCP](/posts/newcp).

## What works today

> _Grounded facts:_ a working JIT-compiled Common Lisp (pre-1.0) that self-hosts its
> ~800-form stdlib and runs real programs (a Prolog/Zebra solver, an Othello AI,
> Mandelbrot, a neural-net + GA tank sim). The ANSI suite is ≈757 pass / ≈83 fail /
> ≈79 error of 919 forms; benchmarked honestly against SBCL 2.6.5 (within ~6× on
> Zebra; float kernels ~3–4× faster via unboxing). No image/fasl save yet. _Fill
> more from `demos/` and the `.lisp` files._

## Screenshots

The NCL IDE — a Direct2D `iGui` MDI workspace — running the demos, each with its
source open in the simple structural `ledit` editor beside the live window.

**Mandelbrot**, direct pixel access: the editor on `mandelbrot.lisp` — note the
`double-float` declarations that keep the inner loop unboxed in registers (~25×
faster than the boxed version) — beside the live escape-time render.

![NCL: the mandelbrot.lisp source beside the live Mandelbrot render](/images/newcl/mandelbrot.png)

The **live JIT REPL** and the canvas API together — `ncl> (sqrt 25)` → `5.0`, the
F5-eval log, `shapes.lisp` in the editor, and the drawing primitives it paints
(filled and stroked ovals, arcs, circles):

![NCL: the live REPL, the F5 eval log, and the shapes drawing-primitives demo](/images/newcl/repl-shapes.png)

**Othello** — Roger's Othello-with-an-AI (Norvig, *Paradigms of AI Programming*
ch. 18: minimax with alpha-beta and a weighted-squares heuristic), the game logic
in Lisp over the iGui board:

![NCL: the Othello AI demo, board mid-game](/images/newcl/othello.png)

Conway's **Life** on a 15×15 grid — live cells as rainbow-cycled ellipses through
iGui's retained-mode batch — with a canvas colour-gradient test alongside:

![NCL: Conway's Life and a canvas gradient test](/images/newcl/life.png)

## Download & run

Prebuilt Windows binaries: the [GitHub Releases page](https://github.com/albanread/NewCL/releases).

```bash
git clone https://github.com/albanread/NewCL
cd NewCL
cargo build --release
```

## Notes, dead-ends, lessons

- _Recreating an *experience*, not just a language spec._
- _Why not run `.fasl`/`.img` — the case for recompiling from source._

## Links

- Source: https://github.com/albanread/NewCL
- Inspiration: Corman Lisp
- Apple Silicon port: [MacNCL](/posts/macncl)
