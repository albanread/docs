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

Common Lisp has never lacked implementations; what it lost when Corman Lisp
faded was an *experience* — a Lisp that felt like a first-class Windows
citizen. Roger Corman's system compiled to native x86 on the fly, talked to
the Win32 API without apology, and wrapped it all in an IDE a Windows
programmer recognised. That totality, not any single feature, is what NCL
sets out to recreate. The language spec you can get anywhere; the feeling
of Lisp *belonging* on the machine is the scarce thing.

Underneath, the ambition was to see how much of that experience a modern
core could carry: Rust for the runtime, LLVM for the codegen, a
generational collector designed fresh — new compiler, new GC, new
everything, as the README warns. Recreating a classic on modern
foundations tells you which parts of the classic were essential and which
were period furniture.

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

A working, JIT-compiled Common Lisp — pre-1.0 and saying so. It self-hosts
its ~800-form standard library and runs real programs: a Prolog engine
solving the Zebra puzzle, the Norvig Othello AI, Mandelbrot, a
neural-net-plus-GA tank simulation. The ANSI conformance suite stands at
≈757 pass / ≈83 fail / ≈79 error of 919 forms — published as the three
numbers, not a percentage chosen to flatter. Benchmarked honestly against
SBCL 2.6.5: within ~6× on Zebra (SBCL has had thirty years; fair play to
it), while the unboxed float kernels run ~3–4× *faster*. No image or fasl
save yet — sessions rebuild from source, which is less painful than it
sounds when the compiler is a JIT.

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

- **An experience is a harder spec than a standard.** ANSI CL tells you what
  `format` does; nothing tells you what made Corman Lisp *feel* right — the
  latency of the REPL, the IDE-and-canvas-in-one-window shape, the sense
  that Windows was home rather than a compatibility target. Recreating that
  meant treating demos, editor behaviour and API reach as requirements with
  the same standing as the numeric tower.
- **Refusing to run `.fasl`/`.img` was the right call.** Compiled artifacts
  are an implementation's private property — resurrecting another
  compiler's binary formats buys compatibility theatre and a permanent
  archaeology burden. Source is the durable interface; NCL ports Corman
  programs by *recompiling* them, which is also this portfolio's answer in
  general (see [not image-based](/posts/not-image-based)).
- The collector grew up and left home: NCL's generational page-heap was
  later generalized into the shared **NewGC** used across the family — a
  reminder that the reusable part of a language project is rarely the part
  you expected.

## Links

- Source: https://github.com/albanread/NewCL
- Inspiration: Corman Lisp
- Apple Silicon port: [MacNCL](/posts/macncl)
