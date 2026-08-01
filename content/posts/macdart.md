+++
title = "MACDART — bringing Dart's last V1 release to Apple Silicon"
date = 2026-07-25
description = "Porting the Dart 1.24.3 VM (the final V1 release) to macOS arm64 with the JIT on — and finding it took only three source-level changes to reach parity."
[taxonomies]
tags = ["dart", "vm", "jit", "arm64", "cpp", "cocoa", "smalltalk"]
[extra]
repo = "https://github.com/albanread/MACDART"
language = "C++ (Dart VM) + Dart"
platform = "Apple Silicon (arm64-apple-darwin)"
status = "Under active development — VM at parity; native IDE and a second language live"
period = "2026-07 → ongoing"
downloads = []
+++

_Dart 1.x — the language before null-safety, when `new` was still required — has
no official Apple Silicon build. So I made one, JIT and all._

## TL;DR

- **What:** a port of the **Dart 1.24.3** VM/SDK — the *last* V1 release
  (2017-12-13) — to **macOS Apple Silicon**, **ARM64 JIT only**. Dart 2 and its
  null-safety are explicitly out of scope.
- **Stack:** the stock Dart VM in C++, our own CMake/Ninja build, no
  gclient/gyp/GN.
- **The headline:** reaching full-conformance parity took **three source-level
  changes** to the VM.
- **Beyond the port:** a native Dart IDE, a `dart:cocoa` bridge, and **Smalltalk
  running as a second language on the same VM.**
- **Get it:** [Downloads](#download-run) · [Source](https://github.com/albanread/MACDART)

## Where it sits

The base is `dart-lang/sdk` at tag `1.24.3` (the final V1; 1.25 never shipped
stable). It's the newest and most involved project in the portfolio, and the one
where the [Cocoa bridge](/posts/cocoa-data) work and the [Smalltalk
VM](/posts/macvm) converge — Dart and Smalltalk share one VM here. See the
[timeline](/timeline).

## What it is

A true **V1** Dart on Apple Silicon. `dart --version` reports:

```
Dart VM version: 1.24.3 (MACDART) on "macos_arm64"
```

and it means it — `new` is required for constructors, there is no null-safety
(`!` is a syntax error), the semantics are 2017's. It runs hello-world, closures,
generics, polymorphism, exceptions, `async`/`await`, collections and math, with
the optimizing JIT active.

> _Expand: why V1 specifically — nostalgia, a frozen target, a teaching VM, the
> pleasure of a self-contained 2017 codebase that still builds clean._

## Why I built it

- _Dart 1.x has no arm64 macOS build; V2 changed the language you wanted._
- _A 435k-line VM that compiles clean under a modern toolchain is a rare gift._

## How it works

**The porting thesis, confirmed:** Dart's ARM64 backend already existed (for
mobile), and `globals.h` already mapped `__aarch64__` to `HOST_ARCH_ARM64`. The
*untested* combination was **darwin + arm64** — 2017 Macs were x86-only, and the
Apple-ABI arm64 path only ever ran in AOT mode, where the JIT's
self-modifying-code path never executes.

The entire VM-source delta to get a high-conformance V1 JIT turned out to be
**three files**:

1. **`cpu_arm64.cc`** — `CPU::FlushICache` → `sys_icache_invalidate` (arm64's
   split I/D cache; this was the essential change).
2. **`stub_code_arm64.cc`** — the deopt stub pushed every register with
   `str r,[SP,#-8]!`; when `r == SP` that's a CONSTRAINED-UNPREDICTABLE encoding
   Apple Silicon *traps* as SIGILL. Special-cased to `mov R25,SP; str R25,…`.
   This was crashing every test that deoptimized.
3. **`flow_graph_compiler.cc`** — a latent null-reference bind that a modern
   clang's optimizer legally exploits into a NULL deref during snapshot
   generation. Guarded.

Everything else was build-layer plumbing, not language changes.

> _Expand: the W^X story (MAP_JIT + mprotect; the dev binary is unsigned so plain
> mprotect works), the snapshot machinery, the `DART_NO_SNAPSHOT` compile-time
> split that builds the engine twice._

## What works today

- **Conformance:** corelib **396/431 (95%)**, language **4487/4602 (99.1%)**,
  and **zero crashes across all 5033 cases** — parity with upstream 1.24.3, no
  VM bugs. (The remaining fails are harness-config, `-D` env flags, and
  Dart-2-feature tests, not VM defects.)
- **Speed:** snapshot startup **2.18s → 0.03s (73×)**; a release build gets a
  cold start to **~0.02s**.
- **`dart:cocoa`:** a Cocoa bridge built into the VM — `NSColor.colorWithRed(1,
  green:0, blue:0, alpha:1)` lowers to the real Objective-C keyword selector via
  `noSuchMethod`, with a real memory model (weak-persistent-handle finalizers →
  `objc_release`). ST opens live `NSWindow`s.
- **A native IDE (dartui):** a multi-isolate Dart workspace with a debugger,
  driven over the VM service.
- **A second language:** **Smalltalk runs on the Dart VM** — a whole
  [MACVM](/posts/macvm)-style world image boots inside MACDART, editable in a
  bilingual workspace, with the VM inlining Smalltalk to near native-Dart parity.

## Screenshots

Every shot below was captured live on Apple Silicon by driving the running IDE
over its control plane — the Dart VM service on `ws://8181` plus a single
`ext.dartui.send` service extension, spoken to by a small
[Tcl client](/posts/tcl-for-agents) (`connect; ui snap out.png`). The VM renders
its own client area to a PNG on the main thread, so these are the real pixels,
grabbed permission-free.

### The native IDE (dartui): bilingual, live, debuggable

The whole IDE is itself a **`dart:cocoa` application** — the Dart VM driving AppKit
directly. The **editor** is a syntax-highlighted V1 Dart buffer with Do It / Print
It / Accept, a class picker, and a live `MEM · JIT · CODE · GC` status bar; here it
holds a little `Vec2` — note `new`, `const`, and `operator +`: this is 2017's Dart.

![The dartui code editor — a syntax-highlighted V1 Dart Vec2 class, with Load / Save to Image / Add to World / File In / Format / Analyze](/images/macdart/dartui-editor.png)

The headline feature is the **second language**: Smalltalk runs on the *same* Dart
VM, and its whole world is browsable and editable in a four-pane class browser.
Here it's parked on `Fraction>>+` — exact rational arithmetic, with a
Strongtalk-style typed signature (`+ aNumber <Number> ^ <Number>`). "Accept saves
(image + live)" is the very live-edit contract from [MACVM](/posts/macvm), except
the host VM underneath is now Dart.

![The Smalltalk class browser embedded in the Dart IDE — Numbers to Fraction to arithmetic to +, showing the exact-rational source and "Accept saves (image + live)"](/images/macdart/smalltalk-browser.png)

And it has a real **source-level debugger** over that same VM service. This one is
stopped at a breakpoint (the red gutter dot) inside a Mandelbrot worker's
escape-time loop — `zr`, `zi`, `n` caught mid-iteration in the Variables pane, the
call stack beside it. The status line states the
[multi-isolate](/posts/isolates-and-vms) model outright: "the window stays live
because this is a different isolate."

![The dartui debugger paused at a breakpoint inside a Mandelbrot worker — source with the breakpoint dot, the call stack, and live local variables](/images/macdart/debugger.png)

### The JIT, actually running

A port is only real if the optimizing JIT runs, and the demos make that visible.
The **Mandelbrot zoom** spreads its work across four persistent worker isolates and
prints its own frame time: the first frame is **17 ms (cold JIT)**, and once the
optimizer has seen the loop it collapses to **3 ms** — self-modifying code on Apple
Silicon, the whole point of the port, working.

![Mandelbrot zoom rendered by four worker isolates, overlaid with its own live timing: compute 3ms (first was 17ms — cold JIT)](/images/macdart/mandelbrot-zoom.png)

The same warm-up, quantified: a **Benchmark Dashboard** of cold (compile) vs warm
milliseconds across arith / fib / sieve / dict / alloc / Richards / DeltaBlue. It is
the direct counterpart to [MACVM](/posts/macvm)'s chart — and `fib` is again the
honest outlier, deep recursion the [JIT](/posts/two-jits) can't optimise away.

![Benchmark Dashboard — cold vs warm milliseconds for arith, fib, sieve, dict, alloc, Richards, DeltaBlue](/images/macdart/benchmarks.png)

Finally, because a [game at 60 fps](/posts/games-for-compiler-testing) is a JIT
stress test with a stopwatch, the workspace ships a Metal game pane driven by the
same VM. **Sprite Invaders** runs the whole retained stack (indexed framebuffer,
sprites, SFX, HUD); **Julia** skips it and writes palette indices straight into
GPU-shared memory — "CPU→GPU is a write, not a protocol."

![Sprite Invaders on the Metal game pane — the invader grid, bunkers, player ship, and a score/lives HUD](/images/macdart/invaders.png)

![A Julia set written directly into GPU-shared memory by the Dart VM](/images/macdart/julia.png)

## Download & run

Prebuilt Apple Silicon `dart`: the [GitHub Releases page](https://github.com/albanread/MACDART/releases).

```bash
xattr -d com.apple.quarantine ./dart 2>/dev/null || true
./dart --version
./dart hello.dart
```

Build from source:

```bash
git clone https://github.com/albanread/MACDART
cd MACDART/macdart
cmake -G Ninja -B build-release -S . -DCMAKE_BUILD_TYPE=Release
ninja -C build-release dart
```

> Distribution note: for a clean Gatekeeper experience the binary should be
> signed with `com.apple.security.cs.allow-jit` and notarized; the dev binary
> runs unsigned/ad-hoc.

## Notes, dead-ends, lessons

- _The best kind of port: the hard part (codegen) was already there; the work
  was finding the three places where darwin-arm64 + JIT had never actually run._
- _A Rust rewrite of the VM was considered and rejected — GC/JIT/tagged-pointers
  are rewrite-hostile._

## Links

- Source: https://github.com/albanread/MACDART
- Upstream base: dart-lang/sdk @ `1.24.3`
- Shares a Cocoa bridge lineage with [cocoa_data](/posts/cocoa-data)
- Runs Smalltalk from [MACVM](/posts/macvm)
