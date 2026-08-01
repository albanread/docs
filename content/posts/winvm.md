+++
title = "WINVM — a Windows x86-64 Smalltalk in the Strongtalk lineage"
date = 2026-08-01
description = "The Windows sibling of MACVM: a from-scratch x86-64 Smalltalk VM in the Self → Strongtalk lineage — a two-tier adaptive JIT gated byte-identical against its interpreter, a moving generational GC that runs under live compiled frames, and the 1996 Strongtalk hypertext environment recreated in WebView2 over COM."
[taxonomies]
tags = ["smalltalk", "vm", "jit", "rust", "adaptive-compiler", "com", "webview2", "windows", "x86-64"]
[extra]
repo = "https://github.com/albanread/WINVM"
language = "Rust VM + own x86-64 adaptive compiler + Smalltalk world"
platform = "x86-64 Windows (WebView2 + Win32 + COM)"
status = "Working — two-tier JIT, gated byte-identical vs. the interpreter"
period = "2026-07 → 2026-08"
downloads = []
+++

_[MACVM](/posts/macvm) proved the Strongtalk idea on Apple Silicon. WINVM is the
same idea on Windows x86-64 — the same portable front and middle end, a new
back half, and the 1996 Strongtalk environment rebuilt in WebView2._

## TL;DR

- **What:** a from-scratch **Windows x86-64** Smalltalk VM in the **Self →
  Strongtalk** lineage — a class-based object model with an **adaptive
  optimizing compiler** driven by type feedback.
- **Sibling of [MACVM](/posts/macvm):** it shares the **entire portable front
  and middle end** with MACVM and re-vendors the x86-64 JIT substrate (the
  [JASM](/posts/jasm) encoder and the [WF66](/posts/wf66) shipping Windows JIT)
  for the architecture-specific back half.
- **Honest bar:** a **two-tier engine** (simple interpreter + tier-1 JIT) gated
  by one invariant — _compiled output must be byte-identical to interpreted
  output_ — checked by **5,860 in-language tests run four ways**; benchmarked
  head-to-head against **Cog** (the OpenSmalltalk JIT behind Pharo), which it
  matches or beats on five of seven.
- **The environment:** the 1996 **Strongtalk hypertext programming
  environment**, recreated as a live web GUI in **WebView2 over COM**.
- **Get it:** [Downloads](#download-run) · [Source](https://github.com/albanread/WINVM)

## Where it sits

WINVM is the **Windows original** of the Smalltalk line, and the sibling of the
Apple Silicon [MACVM](/posts/macvm): Self (1986) → **Strongtalk** (2002) →
**MACVM** (Apple Silicon) ↔ **WINVM** (Windows x86-64). The two share the whole
portable compiler — reader, bytecode, interpreter, the adaptive middle end, the
object model, the world source — and diverge only in the **back half** (x86-64
vs. AArch64 codegen) and the **host layer** (WebView2 + COM + Win32 vs. Cocoa +
`WKWebView`). The x86-64 substrate itself comes from elsewhere in the portfolio:
the [JASM](/posts/jasm) `rasm` encoder and the [WF66](/posts/wf66) Windows JIT.
See the [timeline](/timeline).

## What it is

> _From the README —_ "A from-scratch Windows x86-64 compiler for Smalltalk —
> the most complex compiler project in my repos… WINVM is a research virtual
> machine for **Windows on x86-64**, in the **Self → Strongtalk** lineage: a
> **class-based object model** with an **adaptive optimizing compiler** driven
> by type feedback. It takes the adaptive-optimization machinery those VMs share
> (inline caches, PICs, type feedback, deoptimization) and Strongtalk's
> representation (classes + direct pointers, no object table), reimplemented in
> Rust for 64-bit Windows."

The stance is deliberate: _"I'm cheating to the maximum extent possible: the
bytecode interpreter and compiler are written in Rust, my own **x86-64
assembler** is reused in the compiler, and only the GC had to be entirely new."_

## Why I built it

- Strongtalk's documentation and C++ source were a lifelong influence — _"one of
  the most rewarding ways to work is re-implementing a strong, well-documented
  design."_
- The adaptive-optimization ideas (PICs, type feedback, deoptimization) that
  Self and Strongtalk pioneered and HotSpot later made famous — rebuilt, on
  Windows, on my own terms.
- A Windows-native twin to [MACVM](/posts/macvm), to prove the shared front/middle
  end really is portable and only the back half needs to change.

## How it works

- **Two-tier engine.** A simple dispatch-based bytecode **interpreter**
  (fetch-decode-`match` with inline caches) is the baseline tier — kept plain and
  obviously correct on purpose, because it doubles as the **differential oracle**
  and the **deoptimization target**. A **tier-1 optimizing JIT** recompiles hot
  code with type feedback and can deoptimize back to the interpreter safely.
- **The invariant.** _Compiled output must be byte-identical to interpreted
  output_ — enforced by a differential suite of **5,860 in-language tests run
  four ways** (interpreter, JIT, JIT + GC-stress, JIT + deopt-stress) that must
  all agree. Every optimization below is validated under that four-way gate.
- **Object model.** Strongtalk-style classes, direct tagged pointers, **no
  object table**, a two-word `[mark][klass]` header — arch-neutral, identical to
  the Mac side.
- **Garbage collection** (the only all-new part): a generational scavenger plus a
  full compacting collector, both running **under live, moving compiled frames**
  via precise oop-maps and a mixed-tier frame walker (RBP-chain walking on x64).
- **The JIT.** A vendored pure-Rust **x86-64 encoder** behind an `Assembler`
  trait; PICs and type feedback; method + block inlining; per-klass
  **customization** with self-send and block-arg **devirtualization**;
  **deoptimization**, **on-stack replacement**, and recompile-on-trap. Uncommon
  traps are `int3` sites recovered through a **Vectored Exception Handler** — the
  Windows counterpart of MACVM's Mach signal traps.
- **Closures without allocation.** Literal blocks compile and splice inline,
  including multi-block non-local-return (`^`) blocks, with `Context`
  elision / materialization / adoption across the tier boundary — a recursive
  call never heap-allocates its activation (`contexts_allocated == 0` on the
  benchmarks).
- **Scalar float regions.** A mono-`Double` send site compiles to a guarded
  unbox and native SSE2 (`movsd`/`addsd`/`mulsd`/`ucomisd`), boxing only where a
  boxed value is actually observed — inside a region, no allocation, no GC, no
  message send.
- **Win32 FFI.** Native calls through `GetProcAddress` + shape-keyed
  trampolines + an `Alien` raw-memory type; a `Platform` global (`#windows`)
  lets the **shared** world source pick the right OS surface at load time (e.g.
  `Time` via `GetSystemTimePreciseAsFileTime` where the Mac line used
  `clock_gettime`).
- **Multi-VM workers.** Share-nothing parallelism from Smalltalk: `Worker spawn:`
  boots worker VMs — each its own heap, JIT, and GC on its own OS thread — that
  talk to the primary by **deep-copy message passing**, Erlang-style, fully
  asynchronous. A crashed worker dies alone and is reported as an ordinary
  `#workerDied` message.
- **Image store.** Offline **SQLite** image editing plus a DB→VM boot loader
  that reconstructs the world byte-identically to a `.mst` boot.

## Measured against Cog

WINVM doesn't compete with Squeak, Pharo, or Cog — those are mature production
systems. But a JIT needs an honest yardstick that _isn't_ its own (deliberately
simple) interpreter, and Cog — the x86-64 OpenSmalltalk JIT behind Pharo — is
the meaningful one: same language, same benchmarks, a high bar. Both processes
pinned to one performance core of an i7-12700, timed with a microsecond clock
(Windows' millisecond timer quantizes to 15.6 ms and made Cog's sub-tick numbers
read as zero):

| benchmark | WINVM (JIT) | Cog | |
|-----------|-------------|-----|---|
| arith     | 36 ms   | 48 ms  | **faster** |
| sieve     | 3 ms    | 4 ms   | **faster** |
| alloc     | 14 ms   | 18 ms  | **faster** |
| dict      | 12 ms   | 11 ms  | parity |
| deltablue | 4 ms    | 4 ms   | parity |
| richards  | 33 ms   | 29 ms  | ~1.15× behind |
| fib       | ~207 ms | ~180 ms | ~1.2× behind |

Warm, ×10 inner reps, checksum-verified equal work on both VMs. WINVM matches or
beats Cog on **five of seven** and trails only on the two deepest-recursion,
send-heavy micro-benchmarks — a known, scoped codegen gap, not a correctness or
GC problem.

## Screenshots

The WINVM programming environment — the 1996 **Strongtalk hypertext environment**
recreated as a live web GUI, hosted in **WebView2** inside a native **Win32**
window, the whole integration going through **COM**. These pages aren't plain
HTML: a `<smappl>` tag embeds a live widget computed by the running VM, and an
`<a doit="…">` link *executes* Smalltalk instead of navigating.

The **class browser** — the four-pane structural browser at the heart of the
environment: class categories, classes, instance-variable / method categories,
and the method list, with the selected method's source below (here
`LargeInteger` arithmetic, `<primitive: 41>` falling through to Smalltalk):

![WINVM class browser: four panes over a LargeInteger method source](/images/winvm/class-browser.png)

The **Workspace** — the classic Smalltalk scratchpad: type an expression, *Do
it* to run the selection, *Print it* to run it and splice the result back inline:

![WINVM Workspace: 3 + 4 with the do-it / print-it prompt](/images/winvm/workspace.png)

**Implementors** — one of the code-navigation tools the Smalltalk environment is
known for: every method, across every class, that implements a given selector:

![WINVM Implementors browser: all implementors of a selector](/images/winvm/implementors.png)

The **text editor** on a method's source — editing directly against the live
object world:

![WINVM text editor: editing Smalltalk source in the environment](/images/winvm/text-editor.png)

A **demo / benchmark page** — bar charts drawn live by the VM (the *Run Demo /
Mandelbrot / Waves / Benchmarks* strip), the same kind of measured work the
[Cog comparison](#measured-against-cog) above reports:

![WINVM benchmark page: live bar charts rendered by the VM](/images/winvm/benchmarks.png)

The **toolbar reference** — itself a live in-app help page (a `smappl`),
documenting the browser's own navigation model (Start page, Find definition,
Implementors, Senders, hierarchies, Workspace, editor, Documentation):

![WINVM toolbar reference help page](/images/winvm/toolbar.png)

…and because the environment is HTML, it **themes**. Here's the same class
browser in several of its colour themes — light, teal, blue, green-on-black,
amber-on-black, and a classic Windows grey:

![WINVM class browser rendered in six different colour themes](/images/winvm/themes.png)

## Download & run

Prebuilt Windows binaries: the [GitHub Releases page](https://github.com/albanread/WINVM/releases).

```bash
git clone https://github.com/albanread/WINVM
cd WINVM
cargo build --release
```

## Notes, dead-ends, lessons

- _The portability payoff: how much of MACVM's compiler survived unchanged, and
  exactly where the x86-64 back half and the COM/WebView2 host layer had to
  diverge from the AArch64 / Cocoa original._
- _Recovering uncommon traps with a Vectored Exception Handler where the Mac
  side used Mach signals — the same design, two OS trap mechanisms._

## Links

- Source: https://github.com/albanread/WINVM
- Apple Silicon sibling: [MACVM](/posts/macvm)
- x86-64 substrate: [JASM](/posts/jasm) encoder · [WF66](/posts/wf66) Windows JIT
- Inspiration: Strongtalk (2002), Self before it
