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

Language design mostly proceeds by accretion: exceptions here, a macro
system there, compile-time evaluation bolted on when the templates get
embarrassing — each feature with its own rules, its own corners, its own
interactions nobody fully enumerated. The research question in Locus is
whether one idea, taken seriously all the way down, *derives* those
features instead: effects and staging as dual graded modalities, joined by
a distributive law. If the calculus is right, the feature list is a
corollary.

The second principle is total visibility: **every effect a computation can
have is written in its type** — IO, exceptions, right down to `{gc}`
itself. Nothing ambient, nothing implicit. And that principle has a
distinctly modern beneficiary: Locus is aimed, in its own words, at
"people and their AI colleagues." An agent reasoning about code can only be
as safe as what the code *admits to* — a signature that declares its full
effect row is machine-checkable honesty, which is precisely what you want
when your collaborator reads ten thousand lines a minute and takes
signatures at their word.

## How it works

- **Graded modalities:** effects as a graded monad, staging as its dual;
  the distributive law between them is the hinge that lets staged code and
  effectful code compose lawfully. (The mathematics is developed in
  `docs/calculus.md`; this article stays at street level.)
- **Effect rows in types:** a signature carries its effect row as a
  **checked upper bound** — the body cannot exceed what the type admits —
  and capabilities seal the raw powers, so authority is passed, never
  ambient.
- **Compilation:** Rust front-end → LLVM; staging is the same mechanism
  pointed at compile time, so "macro", "comptime" and "codegen" are one
  facility wearing three hats.

## What works today

The repo carries the three kinds of evidence a research language owes:
worked programs in `examples/`, a machine-checked formal development under
`formal/` (the core is Lean-verified — the calculus isn't just prose), and
a GUI test runner (`gui_runit`) exercising the implementation. Active, and
honest about being research rather than product.

## Download & run

Prebuilt binaries: the [GitHub Releases page](https://github.com/albanread/locus/releases).

```bash
git clone https://github.com/albanread/locus
cd locus
cargo build --release
```

## Notes, dead-ends, lessons

- **Derivation is stricter than accretion, and that's the value.** A
  bolted-on feature can be adjusted when it pinches; a derived one can only
  be fixed by fixing the calculus — which hurts more and teaches more.
  Several times a design "convenience" died because the distributive law
  refused to bless it, and the law was right every time.
- **Designing for AI colleagues turns out to mean designing honestly.**
  Everything that makes Locus legible to an agent — total effects in
  types, no ambient authority, semantics with a formal development behind
  them — is what rigorous language design always wanted anyway. The agents
  didn't add requirements; they removed the excuses for skipping them. The
  same lesson [runs through this whole portfolio](/about): the machines
  made the old virtues non-negotiable.

## Links

- Source: https://github.com/albanread/locus
- Reading: `docs/calculus.md`, `The_locus_programming_language.md`
