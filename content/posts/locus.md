+++
title = "Locus — effects and staging as one mechanism"
date = 2026-05-30
description = "A small expression-oriented language built on a single idea taken all the way down: effects and staging are dual graded modalities joined by a distributive law, so every effect a computation can have is written in its type."
[taxonomies]
tags = ["language", "effects", "type-system", "staging", "compiler", "llvm", "rust", "research"]
[extra]
repo = "https://github.com/albanread/locus"
language = "Rust + LLVM"
platform = "Apple Silicon / portable"
status = "Research language — active"
period = "2026-05 → 2026-06"
downloads = []
+++

_What most languages accrete as separate magical features — effect tracking,
macros, compile-time evaluation, codegen — Locus derives from one idea._

## TL;DR

- **What:** a small, expression-oriented language built on a single idea taken
  all the way down: **effects and staging are dual graded modalities, joined by a
  distributive law.**
- **The payoff:** every effect a computation can have is **written in its type**
  — nothing hidden, ambient or implicit, down to `{gc}` itself — which buys
  transparency and safety (the effect row is a checked upper bound; capabilities
  seal every raw power).
- **The odd one out:** the most theory-driven project here, and the one aimed at
  "people and their AI colleagues."
- **Get it:** [Downloads](#download-run) · [Source](https://github.com/albanread/locus)

## Where it sits

Locus is the research language of the portfolio — less about porting an old
language to Apple Silicon, more about a new idea in language design. It sits
apart from the "bring language X to the Mac" thread. See the [timeline](/timeline).

## What it is

> _From the README —_ "Locus is a small, expression-oriented language built on a
> single idea taken all the way down: effects and staging are dual graded
> modalities, joined by a distributive law. What other languages accrete as
> separate, magical features — exception/effect tracking, macros and compile-time
> evaluation, code generation — are in Locus facets of *one* mechanism."

See `docs/calculus.md`, `MANIFESTO.md`, `The_locus_programming_language.md`, and
the `formal/` directory.

## Why I built it

- _One mechanism instead of many bolted-on features._
- _Effects fully visible in types — transparency and safety as first principles._
- _A language designed to be read and reasoned about by humans **and** AI._

## How it works

- **Graded modalities:** _effects and staging as dual graded monads/comonads;
  the distributive law that joins them._
- **Effect rows in types:** _how `{gc}`, IO, exceptions, etc. surface in
  signatures as checked upper bounds; how capabilities seal raw powers._
- **Compilation:** Rust front-end → LLVM. _Expand: staging → codegen._

## What works today

> _Fill from `examples/`, `formal/`, `gui_runit`. This one benefits from small
> worked examples showing an effect row and a staged/generated program._

## Screenshots

> _Add to `static/images/locus/`: a function signature with its effect row; a
> staged program generating code; the formal development._

![A Locus signature with its full effect row](/images/locus/01.png)

## Download & run

Prebuilt binaries: the [GitHub Releases page](https://github.com/albanread/locus/releases).

```bash
git clone https://github.com/albanread/locus
cd locus
cargo build --release
```

## Notes, dead-ends, lessons

- _Deriving features from one calculus vs. accreting them._
- _Designing a language for AI collaborators as well as human ones._

## Links

- Source: https://github.com/albanread/locus
- Reading: `docs/calculus.md`, `The_locus_programming_language.md`
