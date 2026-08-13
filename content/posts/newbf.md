+++
title = "NewBF — the Beef language, reimplemented on Rust + LLVM"
date = 2026-05-29
description = "A from-scratch compiler for Beef — a C#-shaped systems language with manual memory and no GC — on Rust + LLVM 22, ORC JIT and AOT, with monomorphized generics, comptime code generation, reflection, and a deterministic use-after-free guard."
[taxonomies]
tags = ["beef", "compiler", "jit", "aot", "llvm", "rust", "windows", "systems"]
[extra]
repo = "https://github.com/albanread/NewBF"
language = "Rust + LLVM 22.1 (ORC JIT + AOT)"
platform = "x86-64 Windows (x86_64-pc-windows-msvc)"
status = "Under active development — ~60% of the Beef language; the most-worked repo in the family"
period = "2026-05 → 2026-07"
downloads = []
+++

_Beef — a C#-shaped systems language whose whole point is manual memory — rebuilt
from scratch in Rust on LLVM 22, with a debug guard that turns "no GC" into a
checkable contract._

## TL;DR

- **What:** a from-scratch compiler for **Beef** (beeflang.org), a C#-like systems
  language with **manual memory and no GC**. NewBF reimplements the language, not
  Beef's own C++ compiler. _(Yes — "BF" is Beef, not Brainfuck.)_
- **Stack:** Rust + **LLVM 22.1**, full pipeline lexer → parser → sema → typed SSA
  IR → LLVM → **ORC JIT** (REPL/hot-reload) **and** AOT `.exe`.
- **Reach:** ~60% of the language — value structs and heap classes, vtables and
  interfaces, monomorphized generics, payload enums, comptime code generation, and
  runtime reflection — plus a **deterministic use-after-free / double-free guard**.
- **Get it:** [Downloads](#download-run) · [Source](https://github.com/albanread/NewBF)

## Where it sits

NewBF is the manual-memory member of the Windows "New*" family of from-scratch
Rust + LLVM compilers (it shares LLVM 22 and the toolchain with NewM2, NCL, and
Locus, and an `igui`/IDE crate with the others). See the [timeline](/timeline).

## What it is

> _From the repo —_ a "manual-memory member of a portfolio of from-scratch Rust +
> LLVM language implementations." Beef's defining trait is C#-shape ergonomics with
> **explicit `new`/`delete`** and no garbage collector; NewBF keeps that and builds
> tooling around making manual memory safe to work with.

## Why I built it

Beef caught my eye because it declines the fashionable answer twice: it wants
C#'s ergonomics *without* C#'s runtime — no collector, explicit `new` and
`delete`, and no apology for either. Most of this portfolio carries a GC;
building the family's manual-memory member was partly a control experiment on
my own substrate assumptions.

But the real conviction is this: if a language makes deletion the
programmer's job, the toolchain owes the programmer **instrumentation**.
"Manual memory" has meant "discipline plus luck" for fifty years, and it
never needed to. The allocator can testify — which allocation, freed where,
used again where — deterministically, every run. A GC absolves; a good
allocator gives evidence. NewBF is built around that idea.

## How it works

- **Pipeline:** lexer → parser → sema → typed SSA IR → **LLVM 22** → ORC JIT for the
  inner loop (REPL/hot-reload) and AOT `.exe` for shipping; links via `link.exe`,
  Win64 SEH. Workspace `newbf-lexer/parser/sema/ir/llvm/…` + `newbf-winapi` with a
  committed Win32 ABI snapshot.
- **Type system:** value structs, heap classes (manual `new`/`delete`), vtables,
  interfaces as both generic constraints (monomorphization) and dynamic-dispatch
  itable slots; generic methods on generic owners, const generics; payload enums /
  tagged unions with `switch` binding, `Option<T>` / `Result<T,E>`.
- **Manual-memory guard:** a quarantining stomp allocator + tombstone ledger gives
  deterministic use-after-free / double-free reports with a named site, plus a
  compile-time delete-flow pass (provable double-free + leak, reported zero false
  positives across 401 `.bf` files).
- **Comptime + reflection:** width-correct const-fold; an `[EmitGenerator]` that
  emits Beef source and splices it back via an `extension` fixpoint; runtime
  reflection through in-module LLVM-emitted accessors.
- **Language surface:** lambdas with heap-env capture, closures returning closures,
  hygienic mixins, `Try!` error handling.

## What works today

The most heavily worked repository in the Windows family — 421 commits across
294 Rust files, on a branch named `work/compiler-honesty`, which tells you
something about the editorial policy. The gate is a **245-program
JIT-and-run corpus** plus 160/160 LLVM-verify; the delete-flow analysis has
reported zero false positives across 401 `.bf` files. Current work (Wave 3)
is generic-constraint enforcement, the iterator protocol, and comptime
reflection. Roughly 60% of the language, honestly counted.

## Download & run

Prebuilt Windows binaries: the [GitHub Releases page](https://github.com/albanread/NewBF/releases).

```bash
git clone https://github.com/albanread/NewBF
cd NewBF
cargo build --release
```

## Notes, dead-ends, lessons

- **Manual memory becomes a contract the moment it is deterministic.** The
  quarantining stomp allocator and tombstone ledger mean a use-after-free
  reports the same named site every run — which converts a class of folklore
  bug ("it crashes sometimes, somewhere") into something you can write a
  failing test for. That is the whole difference between discipline and
  engineering.
- **Comptime codegen that emits *source* pays for itself.** The
  `[EmitGenerator]` path generates Beef text and splices it back through an
  `extension` fixpoint — which means generated code is readable, diffable,
  and debuggable with the same tools as handwritten code. Generating IR
  directly would have been faster to implement and worse to live with.
- The branch name `work/compiler-honesty` is the lesson in miniature: the
  corpus counts what runs, not what parses.

## Links

- Source: https://github.com/albanread/NewBF
- Upstream language: Beef (beeflang.org)
- Sibling compilers: [NCL](/posts/newcl), NewFB, [Locus](/posts/locus)
