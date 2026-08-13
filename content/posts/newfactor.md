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

Most of this portfolio is about *owning* the pipeline — encoders gated
against oracles, JITs written from scratch. NewFactor is the deliberate
counter-experiment: when is it smarter to **borrow a great JIT** than to
write one? Factor's VM is two decades of serious engineering — an
optimizing, register-allocating, PIC-driven compiler with a generational
GC — sitting mostly unvisited. Slava Pestov and colleagues built a
production engine; it seemed only polite to bring it some traffic.

What makes the borrowing clean rather than a bodge is the shape match: Forth
and Factor are both concatenative. Lowering Forth to canonical Factor is a
short semantic hop, not a translation across paradigms — the stack
discipline, the word-at-a-time composition, even the mental model survive
intact. The programmer writes 1990s ANS Forth and gets 2010s codegen, and
never has to know.

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

Phases 0–4 are complete, behind **226 tests across 16 suites** including a
61-assertion Forth-2012 conformance corpus, and the IDE binary
(`newfactor-ui.exe`) runs the graphical demos — Mandelbrot, a negamax
Othello, bouncing balls — from inside the editor. Still owed: the formal
Mandelbrot-vs-WF64-MASM benchmark that would settle the project's founding
bet with a number, and a few ANS stragglers (`?DUP`, `DEFER`,
`CATCH`/`THROW`). The pending list is short and stated, which is how I
prefer pending lists.

## Download & run

Prebuilt Windows binaries: the [GitHub Releases page](https://github.com/albanread/FactorForth/releases).

```bash
git clone https://github.com/albanread/FactorForth
cd FactorForth
cargo build --release
```

## Notes, dead-ends, lessons

- **Embedding someone else's VM is systems work, not glue.** The patched
  `factor.dll` grew `nf_*` embedding exports; the ~134 MB Factor image is
  zstd-compressed to ~30 MB; and the process runs three threads (GUI, IDE
  worker, Factor VM worker) behind **three levels of crash recovery** — VEH,
  `catch_unwind`, then session restart. A production VM assumes it owns the
  process; teaching it to be a guest is most of the project.
- **What "30 lines vs 150" really shows.** The `fractal-iter` demo in ~30
  lines of pure Forth against WF64's ~150 lines of hand-written MASM isn't
  about brevity — it's that Factor's optimizer *recovers automatically* (the
  unboxing, the register allocation) what the assembly encoded by hand. When
  a back-end is good enough, the front end can afford to be honest about
  what the programmer meant.
- The quiet lesson for the rest of the portfolio: knowing how to build a JIT
  is precisely what tells you when not to.

## Links

- Source: https://github.com/albanread/FactorForth
- Borrows its GUI from: [WF64](/posts/wf64)
- The other Forth line: [WF66](/posts/wf66) → [MF66](/posts/mf66)
