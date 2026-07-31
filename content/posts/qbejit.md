+++
title = "QBEJIT — an in-process, W^X-compliant ARM64 JIT on top of QBE"
date = 2026-07-05
description = "QBE IL in, executable machine code in mmap'd memory out — no external assembler, no linker, no temp files, no subprocess. A Zig runtime and a Rust crate over one vendored QBE fork."
[taxonomies]
tags = ["jit", "qbe", "arm64", "zig", "rust", "wx"]
[extra]
repo = "https://github.com/albanread/QBEJIT"
language = "Zig and Rust (over a vendored QBE fork via FFI)"
platform = "Apple Silicon (arm64-apple-darwin)"
status = "Working"
period = "2026-07"
downloads = []
+++

_QBE's optimizing back-end, but the output goes straight into executable memory
instead of a `.s` file — no toolchain round-trip at all._

## TL;DR

- **What:** an in-process, W^X-compliant ARM64 JIT built on the
  [QBE](https://c9x.me/compile/) optimizing compiler back-end.
- **Pipeline:** QBE IL goes in; executable machine code in `mmap`'d memory comes
  out — **no external assembler, no linker, no temp files, no subprocess.**
- **Two front doors:** a **Zig** runtime and a standalone **Rust** crate
  (`qbejit`), both driving the same vendored QBE fork over FFI.
- **License:** MIT; bundles QBE (MIT, © Quentin Carbonneaux).
- **Get it:** [Downloads](#download-run) · [Source](https://github.com/albanread/QBEJIT)

## Where it sits

QBEJIT is the JIT back-end the flagship [MACVM](/posts/macvm) Smalltalk engine
compiles through — "Rust VM + QBEJIT backend." It also hosts the house
reference write-up for JIT executable memory on Apple Silicon. See the
[timeline](/timeline).

## What it is

> _From the README —_ "An in-process, W^X-compliant ARM64 JIT built on the QBE
> optimizing compiler backend. QBE IL goes in; executable machine code in
> `mmap`'d memory comes out — no external assembler, no linker, no temporary
> files, no subprocess."

## Why I built it

- _Wanting QBE's optimizer without shelling out to `as`/`ld` on every compile._
- _A single JIT substrate reusable from both Zig and Rust._

## How it works — and W^X on Apple Silicon

This is the natural home for the **W^X story** that recurs across the whole
portfolio. Apple Silicon forbids a page being writable and executable at once,
so JIT engines allocate `MAP_JIT` memory and switch it between write and execute
modes:

1. **Allocate** `mmap(PROT_READ|PROT_WRITE|PROT_EXEC, MAP_PRIVATE|MAP_ANON|MAP_JIT)`.
2. **Write** — enter write mode (`pthread_jit_write_protect_np(0)`), emit code.
3. **Finalize** — enter execute mode, then `sys_icache_invalidate` (arm64 has a
   split I/D cache).
4. **Never `mprotect` a `MAP_JIT` page** on the strict/entitlement-independent
   path — though under a hardened runtime with `com.apple.security.cs.allow-jit`,
   MAP_JIT + `mprotect` is also legal.

> _Expand from `design/macjitbuffer.md` — the canonical write-up. This section
> can be the definitive reference the other JIT articles link to._

## What works today

> _Fill in: which IL features round-trip, benchmarks, the Zig-vs-Rust parity._

## Screenshots

> _Add to `static/images/qbejit/`: IL → machine code → call; the W^X mode
> transitions; a disassembly of a JIT'd function._

![QBE IL compiled to callable arm64 in mmap'd memory](/images/qbejit/01.png)

## Download & run

Prebuilt binaries / library artifacts: the [GitHub Releases page](https://github.com/albanread/QBEJIT/releases).

```bash
git clone https://github.com/albanread/QBEJIT
cd QBEJIT
# Rust crate:
cargo build --release
# Zig runtime: see the repo's build.zig
```

## Notes, dead-ends, lessons

- _The per-thread toggle vs. mprotect-under-entitlement trade-off._
- _FFI'ing one vendored QBE fork from two languages._

## Links

- Source: https://github.com/albanread/QBEJIT
- QBE upstream: https://c9x.me/compile/
- Compiles through it: [MACVM](/posts/macvm)
