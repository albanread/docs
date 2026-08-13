+++
title = "Racing the emulator"
date = 2026-08-13
description = "Native arm64 against the same VM's x64 build under Prism — same source, same machine. Where translation costs 1.5×, where it costs nothing, and the rows where the emulator wins outright."
[taxonomies]
tags = ["arm64", "x86-64", "emulation", "prism", "benchmarks", "windows", "jit", "snapdragon"]
+++

_Ports rarely get to benchmark themselves against a counterfactual. Ours
can: the build system produces two binaries from one tree — `dart.exe`
for arm64 (this port, native on the Snapdragon's Oryon cores) and
`dart.exe` for x64 (the original backend), which Windows 11 runs through
**Prism**, its x86-to-ARM translation layer. Same VM source, same commit,
same benchmarks, same silicon._

Two questions in one experiment, then. How good is Prism? And — less
comfortably — how good is our side?

A methodological note: [the previous article](@/posts/slow-mandelbrot.md)
matters here. Both binaries now hold Smalltalk at 1.01× of Dart
internally, so every cross-binary ratio below is backend-plus-translation,
with no front-end skew. All runs warmed, best-of-N, translation cache hot;
Claude wrote and ran the driver.

## The numbers

![Diverging bar chart of the emulated-to-native runtime ratio per workload. Integer compare-branch loops and the compile-heavy boot sit at 1.3–1.5× (native wins); allocation at 1.09×; sumDbl and fib are ties; the double-heavy escape loops and mandel sit at 0.88–0.91× — the emulator wins those](/images/racing-the-emulator/emu-vs-native.svg)

    geometric mean: ~1.26× (classic suite), ~1.16× (microbenchmarks)

## Reading the clusters

**Prism's tax lands on throughput-bound integer code.** The 1.5× rows are
tight compare-and-branch loops running at ~1.2 cycles per iteration
natively — nothing but x86 flag traffic, which is where x86-to-ARM
translation has to work hardest. When the loop has no slack, every extra
translated micro-op shows.

**The tax vanishes on latency-bound floating point.** The double loops
chain each iteration on the previous `fadd` result — about a nanosecond of
unavoidable dependency latency per iteration — and translation overhead
hides inside that shadow entirely. Parity, to the percent.

**Statically-compiled C++ pays about 1.34×** — parsing, compiling, GC. Set
against the folk estimate of a decade ago ("emulating x86 costs several
times"), that is a quietly excellent number.

One correctness note that deserves more attention than it tends to get:
our x64 binary is a *JIT*. It writes freshly generated x86 machine code
into writable-executable pages at runtime, patches it, discards it, writes
more. Prism translated all of it, continuously, without a single wrong
answer across the full test battery. Translating a foreign JIT's output on
the fly is the hard case, and it simply worked.

## The row that stings

Look again at the bottom of the chart: **0.88×**. The x64 binary — running
through an emulator — beats our native arm64 build by about 12% on the
workload this project exists to showcase.

The logic is worth walking through, because it only cuts one way. Prism
cannot execute x64 code at better-than-native efficiency; translation only
subtracts. So if translated x64 wins, the input to the translator — the
mature x64 backend's generated code — must be enough better than our arm64
backend's output to pay Prism's toll and still finish first. What we are
really racing is two code generators: Google's x64 backend (years of
desktop tuning, by the lineage of team that built V8) plus Microsoft's
translator, against Dart 1.24's arm64 backend — written for
Cortex-A53-era phone cores, and meeting a wide out-of-order machine like
Oryon for the first time.

The call-heavy `fib` tying at 0.98× points at one concrete suspect: our
arm64 frame entry maintains *two* stack pointers (an architectural
requirement covered in [the first article](@/posts/windart-arm64.md)), and
that bookkeeping is per-call overhead the x64 backend does not carry. The
FP rows suggest the arm64 backend's instruction selection gives a little
away besides. Neither is confirmed; both are now measurable, which is the
point.

## The doctrine

We now treat the emulated binary as **the performance floor**. It is the
best available evidence of what this silicon can do for this VM — produced
by a better-tuned code generator, handicapped by a translator. Any
workload where the emulated build beats the native one is, by
construction, native-backend headroom. Current list: the escape loops
(0.88–0.92) and `fib` (0.98). That list is the tuning roadmap, and
re-running one script says when it is empty.

For users, the practical summary is friendlier: native wins where software
feels — boot-and-compile 34% faster, general object-oriented workloads
25–50% faster — and the FP-heavy demo code sits within 12% of the best
code generation known for this chip. The last 12% is ours to collect.

*Next in the series:
[the payload all this infrastructure carries](@/posts/smalltalk-on-a-snapdragon.md)
— a 97-file Smalltalk world, written on a Mac, booting byte-identical on a
Snapdragon.*
