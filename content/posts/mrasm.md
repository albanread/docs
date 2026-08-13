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

Every "high-level assembler" faces the same temptation: the conveniences
grow until they are a small compiler, and the programmer can no longer say
what instructions a line produces — at which point you have the drawbacks
of assembly *and* the drawbacks of a compiler. MRASM's founding rule is the
refusal: `invoke`, typed structs and subroutine contracts are shorthand
that **expands to instructions you can inspect**, always. If you cannot see
the expansion, the feature does not ship.

The second conviction is that an assembler should *know things*. Writing
assembly against a modern platform means living in the architecture manual
and the SDK headers; MRASM carries that knowledge inside the tool, offline,
at the point of use — the same instinct that put 165,000 Win32 symbols
inside [WRASM](/posts/wrasm)'s `winkb`, aimed at the Mac.

## How it works

- **Non-hiding macros:** the conveniences lower openly — an `invoke` becomes
  the visible argument setup and call sequence, a struct field becomes the
  offset arithmetic it always was. The discipline is inherited directly from
  WRASM, where the expansions can be read beside the source in the IDE.
- **Built-in platform knowledge:** surfaced through the in-tool help
  (`help.md`, `editor_help.md`) and the repo's `library/` of ready material,
  with a `corpus/` of assembled goldens keeping the encoder honest — the
  same frozen-corpus discipline as its Windows parent.

## What works today

Working, per its status — and the repository's shape is the evidence of
breadth: a `corpus/` (the correctness gate), a `library/`, a `projects/`
area of real programs, and cut `release/` bundles. For the mechanics of the
shared design — the two-pass encoder, the transparent macro layer — the
[WRASM article](/posts/wrasm) covers the Windows original this ports.

## Download & run

Prebuilt binaries: the [GitHub Releases page](https://github.com/albanread/MRASM/releases).

```bash
git clone https://github.com/albanread/MRASM
cd MRASM
cargo build --release
```

## Notes, dead-ends, lessons

- **"Conceal nothing" is testable, which is why it survived.** Because every
  convenience expands to visible instructions, the expansions can be
  golden-tested like any other assembly — a macro is correct when its
  expansion bytes match, full stop. Design values that can't be tested decay
  into slogans; this one became part of the corpus.
- **The port's real costs were the architecture's, not the code's.** Moving
  WRASM's design to Apple Silicon means new encodings, a different calling
  convention, W^X ceremony instead of `VirtualAlloc`, and an instruction
  cache that must be flushed — the same four differences every port in this
  portfolio pays, catalogued in
  [arm64 vs x64, across these compilers](/posts/arm64-vs-x64). The design —
  transparent macros over a knowledge layer over a gated encoder — moved
  without complaint, which is the strongest evidence it was the right
  shape.

## Links

- Source: https://github.com/albanread/MRASM
- Windows predecessor: WRASM (github.com/albanread/WRASM)
- Sibling: [JASM](/posts/jasm)
