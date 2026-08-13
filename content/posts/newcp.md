+++
title = "NewCP — Component Pascal and BlackBox, rebuilt as a JIT"
date = 2026-05-03
description = "A from-scratch recreation of Component Pascal and the BlackBox Component Builder on Rust + LLVM: a memory-resident JIT with a dynamic module loader — and the birthplace of the Direct2D iGui shell the whole Windows family reuses."
[taxonomies]
tags = ["component-pascal", "oberon", "compiler", "jit", "llvm", "rust", "windows"]
[extra]
repo = "https://github.com/albanread/NewCP"
language = "Rust + LLVM 22 (Inkwell) + MCJIT"
platform = "x86-64 Windows (x86_64-pc-windows-msvc)"
status = "Under development — compiler working (phases 0–6), framework/GUI in progress"
period = "2026-05"
downloads = []
+++

_Component Pascal — the Oberon-2 descendant behind Oberon microsystems' BlackBox —
recreated from scratch as a memory-resident JIT, and the project where the family's
Direct2D "iGui" shell was born._

## TL;DR

- **What:** a from-scratch recreation of **Component Pascal** and the **BlackBox
  Component Builder** environment — compiler, JIT runtime, dynamic module loader,
  and a partial BlackBox framework port.
- **Stack:** Rust (edition 2024) → typed IR → **LLVM IR → MCJIT** (via Inkwell,
  `llvm22-1`), executed in-process. A 10-phase pipeline, each phase emitting a
  stable textual dump.
- **Why it matters here:** NewCP is the **earliest 2026 project** in the portfolio
  and the **origin of `iGui`**, the immediate-mode Direct2D/DirectWrite MDI shell
  that later languages reuse.
- **Get it:** [Downloads](#download-run) · [Source](https://github.com/albanread/NewCP)

## Where it sits

NewCP is the wellspring of the Windows family's shared GUI. Its `iGui` shell is
reused (often by name) by [NewBCPL](/posts/newbcpl), [NCL](/posts/newcl), NewFB,
NewBF, NewFactor, the Modula-2 line, and the WF64→[WF66](/posts/wf66) Forths. Its
own home-grown mark-sweep `gc.rs` was ported into NewBCPL and others. See the
[timeline](/timeline).

## What it is

> _From the repo —_ "CP" = **Component Pascal**, the Oberon-2-derived language from
> Oberon microsystems' BlackBox. NewCP is all of: a real compiler for Component
> Pascal; a JIT runtime with a dynamic, on-demand module loader; a partial BlackBox
> framework port (Kernel, Files, Fonts, Stores/Views/Models, the ODC document
> model); and the birthplace of `iGui`. It is memory-resident, not a batch/object-
> file compiler: parse → type-check → typed IR → LLVM IR → MCJIT into the running
> process. It reads a 675-file BlackBox 1.7 `.odc` corpus via `newcp-odc`.

## Why I built it

BlackBox is one of those systems more people should have used: Component
Pascal — the tidied Oberon-2 descendant, Wirth discipline with components —
inside an environment where documents, views and live modules compose in one
running image. It was quietly doing in the 1990s what gets rediscovered
noisily every decade since. When it faded, the *shape* of it faded too, and
the shape is the valuable part.

Which is why "memory-resident, JIT-first" was not an implementation choice
but the point. A batch compiler that accepts Component Pascal syntax would
miss what BlackBox *is*: a module space you load into, extend, and never
leave. So NewCP parses, type-checks and JITs into the running process, with
a loader that treats Rust-hosted and Component-Pascal modules identically —
the recreation of an environment, with a compiler attached.

## How it works

- **Pipeline:** a 10-phase compiler (lexer / parser / sema / module-graph / CFG /
  typed-IR / LLVM-IR / asm / heap), each phase emitting a reviewable textual dump.
  Workspace of ~10 crates (`newcp-lexer/parser/sema/ir/llvm/runtime/loader/odc/
  driver`).
- **Dispatch on MCJIT:** virtual method dispatch works on MCJIT via vtables patched
  after materialization (a workaround for MCJIT relocation gaps); record extension
  and cross-module OOP run on the JIT.
- **Module loader:** active/retired generations with a hot-reload drop-predicate;
  Rust-hosted and Component-Pascal modules look identical to the loader.
- **iGui:** an immediate-mode MDI windowing layer built directly on **Direct2D +
  DirectWrite over Direct3D 11 + DXGI** (`src/newcp-runtime/src/igui/`). The GUI
  owns the main thread; the language runtime is launched behind it and talks to it
  through an event mailbox + a synchronous query channel — it never owns an HWND or
  a Direct2D resource directly.
- **GC:** its own `gc.rs` (~1,800 lines) — cluster/block layout, tagged alloc,
  mark/sweep, finalizers, module roots, `dump-heap` introspection.

## What works today

The compiler is real: phases 0–6 done properly, with the test counts to show
for it — 188/188 integration, 50/50 runtime, 29/29 loader, 474/490 in
`newcp-tests`. Virtual dispatch, record extension and cross-module OOP all
run on the JIT.

The framework is not. Phase 7 — recovering enough of BlackBox's Kernel,
Stores, Views and document model to be *usable* — is in progress, and the
repo's own strategic assessment says so without varnish: green tests, not
yet a user-demoable environment. I'd rather publish that sentence than a
screenshot pretending otherwise. Meanwhile the project's most durable output
is arguably `iGui` itself, which every later Windows language borrowed.

## Download & run

Prebuilt Windows binaries: the [GitHub Releases page](https://github.com/albanread/NewCP/releases).

```bash
git clone https://github.com/albanread/NewCP
cd NewCP
cargo build --release
```

## Notes, dead-ends, lessons

- **MCJIT will let you down on relocations; patch after materialization.**
  Virtual dispatch could not rely on MCJIT resolving vtable slots, so NewCP
  writes the vtables *after* the module is materialized, when the addresses
  are real. Inelegant, dependable, and precisely the kind of workaround that
  later made "own the whole encoder" look attractive.
- **A corpus is worth a specification.** The 675-file BlackBox 1.7 `.odc`
  document corpus is what kept the recreation honest — real documents from
  the real system, read by `newcp-odc`, not examples invented to pass.
- **Green tests and a useful system are different claims.** NewCP has the
  first and not yet the second, and keeping those two statements separate —
  in the repo and here — is worth more than either. Test counts measure what
  you tested.
- The accidental legacy: `iGui`. Built as scaffolding for BlackBox's sake, it
  became the shell for a dozen languages. The most reused code I wrote that
  year was the part I thought was disposable.

## Links

- Source: https://github.com/albanread/NewCP
- Reuses its shell: [NewBCPL](/posts/newbcpl), [NCL](/posts/newcl), [WF66](/posts/wf66)
- The shared collector story: see the [timeline](/timeline#the-shared-windows-substrate)
