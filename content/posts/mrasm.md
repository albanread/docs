+++
title = "MRASM — an assembler that conceals nothing, and knows the platform cold"
date = 2026-06-27
description = "The macOS arm64 port of WRASM: a self-contained macro assembler whose high-level conveniences never hide a single instruction, with deep offline platform knowledge built in."
[taxonomies]
tags = ["assembler", "arm64", "rust", "macos"]
[extra]
repo = "https://github.com/albanread/MRASM"
language = "Rust"
platform = "Apple Silicon (arm64-apple-darwin)"
status = "Working"
period = "2026-06 → 2026-07"
downloads = []
+++

_A high-level assembler where `invoke`, typed structs and subroutine contracts
are conveniences that expand to instructions you can see — never magic that
hides them._

## TL;DR

- **What:** a from-scratch, self-contained macro assembler for Apple Silicon —
  the macOS arm64 port of WRASM.
- **Principle:** the "high-level assembler" conveniences (`invoke`, typed
  structs, declared-subroutine contracts) must **never hide a single
  instruction**.
- **Differentiator:** it carries an "intense, offline, always-available
  knowledge of the platform it targets," so you don't have to go look things up.
- **Get it:** [Downloads](#download-run) · [Source](https://github.com/albanread/MRASM)

## Where it sits

MRASM is the macOS arm64 port of **WRASM** (Windows). It's the knowledge-rich
counterpart to [JASM](/posts/jasm)'s JIT focus. See the [timeline](/timeline).

## What it is

> _From the README —_ "The macOS arm64 port of WRASM, a from-scratch,
> self-contained assembler whose whole premise is that macro assembly and the
> 'high-level assembler' conveniences … should never hide a single instruction —
> and that an assembler should carry an intense, offline, always-available
> knowledge of the platform it targets, instead of making you go look things up."

## Why I built it

- _Transparency as a design value: conveniences that expand to visible code._
- _Wanting the platform's knowledge inside the tool, offline, at your fingertips._

## How it works

- **Non-hiding macros:** _how `invoke` / typed structs / subroutine contracts
  lower to instructions the programmer can inspect._
- **Built-in platform knowledge:** _where the offline knowledge comes from and
  how it's surfaced (see `help.md`, `editor_help.md`, the `library/` and
  `corpus/`)._
- **GPU angle:** _the repo carries a `gpu/` area — describe it._

## What works today

> _Fill from the repo. Note the `corpus/`, `library/`, `projects/` and `release/`
> areas as evidence of breadth._

## Screenshots

> _Add to `static/images/mrasm/`: the assembler expanding an `invoke`; the
> built-in help/knowledge feature in action._

![MRASM showing the instructions a macro expands to](/images/mrasm/01.png)

## Download & run

Prebuilt binaries: the [GitHub Releases page](https://github.com/albanread/MRASM/releases).

```bash
git clone https://github.com/albanread/MRASM
cd MRASM
cargo build --release
```

## Notes, dead-ends, lessons

- _"Conceal nothing" as a testable design constraint._
- _WRASM → MRASM: what the port to Apple Silicon actually cost._

## Links

- Source: https://github.com/albanread/MRASM
- Windows predecessor: WRASM (github.com/albanread/WRASM)
- Sibling: [JASM](/posts/jasm)
