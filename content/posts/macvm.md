+++
title = "MACVM — a Smalltalk from scratch for Apple Silicon"
date = 2026-07-01
description = "The most complex compiler in the portfolio: a from-scratch Apple Silicon Smalltalk inspired by Strongtalk — with its own adaptive compiler and its own assembler for code generation, and a live Cocoa bridge."
[taxonomies]
tags = ["smalltalk", "vm", "jit", "rust", "adaptive-compiler", "cocoa", "arm64"]
[extra]
repo = "https://github.com/albanread/MACVM"
language = "Rust VM + own adaptive compiler + own assembler + Smalltalk world"
platform = "Apple Silicon (arm64-apple-darwin)"
status = "Under development — a large, live system"
period = "2026-07"
downloads = []
+++

_Strongtalk was the Smalltalk that proved the language could be fast. This is my
own run at that idea, on Apple Silicon, from a blank file._

## TL;DR

- **What:** a from-scratch Apple Silicon compiler and VM for **Smalltalk**,
  inspired by Strongtalk.
- **Stack:** a **Rust** VM with its **own adaptive compiler** (Strongtalk-style)
  generating code through its **own assembler**, a live **Cocoa** bridge, and a
  Smalltalk world image.
- **Scale:** the most complex project here — 600+ commits, and the origin of the
  Cocoa-bridge machinery the other languages reuse.
- **Get it:** [Downloads](#download-run) · [Source](https://github.com/albanread/MACVM)

## Where it sits

MACVM is the flagship of the "from-scratch language" thread and the **progenitor
of the runtime Cocoa bridge** — its fixed-shape Objective-C dispatch shim and
live `@encode` marshalling are the reference design that [MACDART](/posts/macdart)'s
`dart:cocoa` and the [cocoa_data](/posts/cocoa-data) mirror build on. Its
Smalltalk world later boots *inside* MACDART as a second language. See the
[timeline](/timeline).

## What it is

> _From the README —_ "A from-scratch Apple Silicon compiler for Smalltalk — the
> most complex compiler project in my repos… Strongtalk was released to the
> public in 2002 — first as documentation I thoroughly enjoyed reading, then as
> full C++ source. At the time it executed Smalltalk [fast]…"
>
> _Expand with your own history-of-experience framing from the README._

## Why I built it

- _Strongtalk's documentation and source as a lifelong influence._
- _Proving a dynamic language can be fast on Apple Silicon, on your own terms._

## How it works

- **Front-end → adaptive compiler → own assembler:** Smalltalk methods are
  compiled by MACVM's **own adaptive (Strongtalk-style) compiler** and emitted
  through its **own AArch64 assembler** (the vendored `wfasm`/[JASM](/posts/jasm)
  encoder) into `MAP_JIT` W^X memory. **[QBEJIT](/posts/qbejit) was reviewed as a
  backend and set aside** — a static QBE-IL→machine-code JIT is the wrong shape
  for an *adaptive* compiler that profiles, recompiles, deoptimizes, and does
  OSR — and an LLVM backend was scaffolded and left commented out. The compiler
  is MACVM's own, which means the performance is too: _entirely our fault when
  it's slow, and entirely the Strongtalk design's credit when it's fast._
- **The Cocoa bridge (the crux):** one fixed-shape AAPCS64 `objc_msgSend` shim
  (`objc_shim.m`) inside `@try/@catch`, with argument classification driven by
  **live `@encode`**, not a static table. `doesNotUnderstand:` is the language
  surface — any unknown selector marshals and dispatches. _Expand from
  `docs/cocoa_bridge_design.md`._
- **Memory model across a moving GC and ARC:** _raw `id`s in GC-opaque storage,
  retain-on-wrap, the +1-family selector classifier._
- **The pieces around it:** a `cocoa_gui`, an `ffi_gen` offline generator, an
  `image_store`, an `abc_player`, example worlds in `world/*.mst`.

## What works today

MACVM boots a real Smalltalk world and runs it on a **two-tier engine** — a
dispatch-based bytecode interpreter plus a tier-1 **adaptive JIT** (inline caches,
type feedback, method and block inlining, deoptimization, OSR) that owns
essentially all of the runtime. Around it: a live Cocoa GUI written in Smalltalk,
a world image, SIMD lane types, up-to-16 worker-VM share-nothing parallelism, and
an optional Strongtalk-style type checker over the whole core library.

And it is genuinely fast. On the classic Smalltalk benchmarks — richards,
deltablue, and a set of micro workloads, all checksum-verified and run **three ways
under one microsecond-clocked protocol**
([`xvm-bench.sh`](https://github.com/albanread/MACVM/blob/main/scripts/xvm-bench.sh)) —
**MACVM's JIT is ahead of Cog, the production Squeak/Pharo JIT, on all seven.** It
trades wins with [MACDART](/posts/macdart)'s Smalltalk-on-the-Dart-VM: MACVM takes
the allocation-bound benches (its generational scavenger's home turf), MACDART the
compute-bound ones — and Cog is never the fastest of the three (µs per iteration,
warm, best-of-7):

| bench | MACVM | Cog | MACDART |
|---|--:|--:|--:|
| arith | 1411 | 5224 | **715** |
| richards | 1087 | 2223 | **628** |
| sieve | **180** | 362 | 196 |
| deltablue | **150** | 280 | 300 |

The performance is entirely MACVM's own — its **own adaptive compiler** generating
code through its **own assembler** — so the slow parts are our fault and the fast
parts are the Strongtalk design's credit.

The allocation-bound wins are the durable ones: a generational scavenger simply
beats a boxing runtime on allocation churn, which is why sieve, dict, and
deltablue stay MACVM's.

Both sides of that table moved in August 2026, and the sequence is the point.
First MACDART spent a twelve-commit arc stripping dispatch overhead out of *its*
Smalltalk front end (deltablue 1271 → 300 µs), which closed its one bad loss and
narrowed MACVM's allocation-bound lead. That prompted the same treatment here —
a register-allocator arc for MACVM (richards 1440 → 1087, fib 10790 → 9034), which
narrowed MACDART's compute lead straight back, from 2.3× to 1.7× on richards.
Neither VM changed its *engine* to chase the other; each simply had a layer that
was costing more than it should, and the sibling made that visible. Having
something to lose to is the most useful thing about running identical benchmarks
on two VMs — and four of the changes attempted in that MACVM arc were **rejected
by the A/B gate** rather than shipped, which is the other half of the same
discipline.

_(An earlier draft of this post repeated a benchmark in which MACDART "beat MACVM
by 52–230×." That number was wrong: MACVM's JIT was switched off in that run,
leaving it in the interpreter. With every VM JIT-hot under one honest protocol,
MACVM is ahead of Cog across the board — the table above.)_

## Screenshots

The MACVM Smalltalk environment — here via the **WINVM** Windows port's Win32 +
WebView2 shell. The start page states the lineage outright ("inspired by
Strongtalk — polymorphic inline caches, type feedback, and deoptimization"), and
it's a *live* page: it's viewed in the MACVM browser, not a plain HTML browser,
because pages can carry executable Smalltalk (a `smappl` tag whose code runs when
you click a link). A live class tree hangs below — `Object`, `Boolean`, the SIMD
lane types `Float64x2` / `Float32x4`, `Alien`.

![The MACVM Smalltalk environment (WINVM WebView2 GUI): the Strongtalk-lineage start page and a live class tree](/images/macvm/strongtalk-gui.png)

_That Windows port now has its own home: **[WINVM](/posts/winvm)** — the x86-64
sibling that shares this entire front and middle end — with a full tour of the
environment (class browser, workspace, benchmarks, and its colour themes)._

### The Smalltalk IDE: browser, source editor, live benchmarks

And here is the macOS environment you actually *program* the VM in — hand-captured
on Apple Silicon.

The classic four-pane **class browser**: the world's classes, a class's method
categories, its methods, and the live source below. It's parked on
`Breakout>>bouncePaddle` — the paddle-bounce logic of one of the bundled games —
mid-edit, and the status line spells out the model: **"Accept saves (image +
live)."** There is no separate build step and no memory image to save — an
accepted method is compiled straight into the running VM *and* written back to the
[source-of-truth database](/posts/not-image-based) in one motion. The status bar
across the top is live too (`MEM` · `JIT` code-cache · `CODE` · `ALLOC` · `GC`).

![The class browser parked on Breakout>>bouncePaddle — the four-pane Smalltalk browser (classes → categories → methods → source), edited live, "Accept saves (image + live)"](/images/macvm/class-browser.png)

The **source view** on the Mandelbrot renderer's `pixmapForWidth:height:`, where
the comment is the whole [fast-floats](/posts/arm64-vs-x64) story in miniature: the
coordinates are *strength-reduced* — accumulated by `+ step` in native
double-double rather than recomputed as `int * step` per pixel — precisely because
"a mixed smi × double send … fails every call (the receiver is the int) and takes
the boxed asDouble fallback … the source of the recurring uncommon traps in the
render stats." That is an [adaptive compiler](/posts/two-jits) describing its own
deopts, in a code comment.

![The Source view on the Mandelbrot renderer — strength-reduced coordinates, with a comment explaining the mixed smi×double send that would otherwise cause uncommon traps](/images/macvm/source-editor.png)

The **benchmark chart**, cold vs warm: the orange bar is the first (cold) run,
which pays to compile the method; the green bar is steady state once it is hot.
Most workloads — `arith`, `sieve`, `dict`, `richards`, `deltablue` — collapse to
0–2 ms warm while the cold bar carries the one-time compile cost. `fib` is the
honest exception: deep recursion is call volume the JIT can't optimize away, so
warm barely beats cold. It's the adaptive JIT's thesis in one picture, on the very
[richards and deltablue](/posts/macdart) workloads MACDART later measured against —
and the status bar shows the code-cache had climbed to 308 compiled methods as they
ran.

![Benchmark chart — cold (compile) vs warm milliseconds for arith, fib, sieve, dict, alloc, richards, deltablue: the adaptive JIT's warmup made visual](/images/macvm/benchmarks.png)

### The native macOS environment, driven and snapped from the VM itself

These were captured on Apple Silicon by driving the *running* VM over its own
control channel — `macvm rusttcl` sending `gui doit …` / `gui game …` / `gui snap
…` to the live `macvm-cocoa` — exactly the [Tcl-verb surface](/posts/tcl-for-agents)
the essays describe. No external screen-grab: the VM renders its own client area to
a PNG on the main thread.

![The native macOS Cocoa workspace — Do It / Print It, and a live status bar (MEM · JIT code-cache · ALLOC · GC) that updates as the VM runs](/images/macvm/workspace.png)

![ParallelMandel — the Mandelbrot set rendered across spawned worker VMs: the multi-VM / isolate model at work](/images/macvm/parallel-mandelbrot.png)

![MandelZoom — the Strongtalk "fast floats" Mandelbrot demo, zoomed into the boundary](/images/macvm/mandelzoom.png)

![Breakout on the Metal pane — a Smalltalk game, which is also a 60fps stress test of the JIT-generated code](/images/macvm/breakout.png)

## Download & run

Prebuilt binaries: the [GitHub Releases page](https://github.com/albanread/MACVM/releases).

```bash
git clone https://github.com/albanread/MACVM
cd MACVM
cargo build --release
```

## Notes, dead-ends, lessons

- _Why the Cocoa bridge is a *fixed-shape* shim rather than libffi or per-call
  JIT — and how that decision propagated to every other language._
- _Bridging a moving GC to ARC without corrupting tagged pointers._

## Links

- Source: https://github.com/albanread/MACVM
- Windows sibling (shared front/middle end): [WINVM](/posts/winvm)
- Assembler: the vendored `wfasm`/[JASM](/posts/jasm) AArch64 encoder ([QBEJIT](/posts/qbejit) was reviewed, not used)
- Inspiration: Strongtalk (2002)
- Its Cocoa design feeds: [cocoa_data](/posts/cocoa-data), [MACDART](/posts/macdart)
