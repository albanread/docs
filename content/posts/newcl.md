+++
title = "NCL — a from-scratch Common Lisp in the Corman spirit"
date = 2026-06-15
description = "A from-scratch reimplementation of the Common Lisp / Corman Lisp language and user-facing experience: Rust core, LLVM-based JIT, 64-bit, Windows-first with a Mac port planned."
[taxonomies]
tags = ["lisp", "common-lisp", "compiler", "jit", "llvm", "rust", "windows"]
[extra]
repo = "https://github.com/albanread/NewCL"
language = "Rust + LLVM (JIT)"
platform = "64-bit Windows (Mac port → MacNCL)"
status = "New — early"
period = "2026-06"
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

- **Reader → compiler → LLVM JIT**, with a new GC. _Expand: the object
  representation, the JIT strategy, the REPL._

## What works today

> _Fill from the `Lisp/` sources, `demos/`, and the many `.lisp` files (deriv,
> bouncing, smoke). Be candid about "early / all new."_

## Screenshots

> _Add to `static/images/newcl/`: the REPL evaluating a classic demo; a Direct2D
> `iGui` window._

![The NCL REPL](/images/newcl/01.png)

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
