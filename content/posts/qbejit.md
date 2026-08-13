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

QBEJIT is a standalone QBE-based JIT experiment. [MACVM](/posts/macvm) **reviewed
it as a possible backend and set it aside** — an adaptive, Strongtalk-style
compiler needs a different shape than a static QBE-IL→machine-code JIT — so MACVM
ships its own compiler and assembler instead. QBEJIT's lasting contribution is
the house reference write-up for JIT executable memory on Apple Silicon (its
ChakraCore-derived `MAP_JIT` W^X recipe, reused across the sibling JITs). See the
[timeline](/timeline).

## What it is

> _From the README —_ "An in-process, W^X-compliant ARM64 JIT built on the QBE
> optimizing compiler backend. QBE IL goes in; executable machine code in
> `mmap`'d memory comes out — no external assembler, no linker, no temporary
> files, no subprocess."

## Why I built it

QBE is a lovely piece of engineering — 70-something percent of LLVM's
optimization for a few percent of its size — but it speaks the batch
dialect: IL in, `.s` file out, then `as`, then `ld`, then `dlopen` if you
want to call the result. Four process round-trips to run one function is no
way to live inside a JIT. QBEJIT keeps the optimizer and removes the
ceremony: the assembly QBE produces is encoded straight into `mmap`'d
executable memory, in-process.

The second motive was substrate economics: one vendored, patched QBE fork
with two front doors — a Zig runtime and a Rust crate — so whichever
language a future project starts in, the same JIT is a dependency away.
Vendor once, bind twice.

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

That four-step recipe (derived from ChakraCore's approach; the full
write-up lives in the repo's `design/macjitbuffer.md`) is this project's
most-travelled export — it is the pattern the portfolio's other Apple
Silicon JITs reuse, whatever they compile.

## What works today

The pipeline works end to end from both front doors: QBE IL in, a callable
function out of `mmap`'d memory, driven identically from the Zig runtime
and the Rust crate over the one vendored fork. Its production role in the
portfolio, though, turned out to be the *knowledge* rather than the binary:
[MACVM](/posts/macvm) evaluated QBEJIT as its backend and set it aside — an
adaptive, Strongtalk-style compiler wants to make decisions QBE's static
IL→code shape doesn't expose — but kept the W^X recipe. Some projects ship
code; this one shipped a technique, which is a perfectly respectable thing
for an experiment to do.

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

- **Two legal W^X paths, one rule of thumb.** The per-thread
  `pthread_jit_write_protect_np` toggle works everywhere and needs no
  entitlement; `mprotect` on MAP_JIT pages is legal only under the hardened
  runtime's `allow-jit`. Ship the toggle path unless you control the
  signing story — an engine that works before notarization is an engine you
  can debug.
- **One vendored fork, two language bindings** keeps the patched QBE as the
  single source of truth: fixes land once, and neither binding can drift
  into its own private dialect of the fork. The FFI surface stays small on
  purpose — IL string in, pointer out — because a narrow waist is what
  makes binding twice cheap.
- Not every experiment has to graduate. QBEJIT was auditioned, declined,
  and strip-mined for its best idea — which is the system working exactly
  as intended.

## Links

- Source: https://github.com/albanread/QBEJIT
- QBE upstream: https://c9x.me/compile/
- Reviewed it as a backend but uses its own instead: [MACVM](/posts/macvm)
