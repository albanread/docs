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
- **Get it:** [Downloads](#download--run) · [Source](https://github.com/albanread/NewBF)

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

- _TODO (editorial): why Beef; why manual memory deserves first-class debug
  tooling instead of a GC._

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

> _Grounded facts:_ the most active repo in the family (421 commits, 294 Rust
> files) on branch `work/compiler-honesty`; a 245-program JIT-and-run corpus +
> 160/160 LLVM-verify; Wave 3 in progress (generic-constraint enforcement, iterator
> protocol, comptime reflection). _Fill specifics from `docs/journals/`._

## Screenshots

> _Add to `static/images/newbf/`: the use-after-free guard naming a site; a comptime
> generator; the JIT REPL._

![NewBF's manual-memory guard catching a use-after-free](/images/newbf/01.png)

## Download & run

Prebuilt Windows binaries: the [GitHub Releases page](https://github.com/albanread/NewBF/releases).

```bash
git clone https://github.com/albanread/NewBF
cd NewBF
cargo build --release
```

## Notes, dead-ends, lessons

- _TODO (editorial): making manual memory a debuggable contract; comptime codegen
  that splices generated source back into the program._

## Links

- Source: https://github.com/albanread/NewBF
- Upstream language: Beef (beeflang.org)
- Sibling compilers: [NCL](/posts/newcl), NewFB, [Locus](/posts/locus)
