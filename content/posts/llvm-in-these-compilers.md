+++
title = "The role of LLVM in these compilers"
date = 2026-07-31
description = "LLVM is everywhere in the Windows-era languages and almost nowhere in the mature Apple-Silicon ones. The reason is the interesting part: it became a byte-for-byte oracle that licensed its own removal."
[taxonomies]
tags = ["llvm", "jit", "compiler", "mcjit", "orc", "code-generation", "apple-silicon"]
+++

_LLVM did three jobs across this portfolio, in sequence: it was the engine that
made a language-a-week possible, then a byte-for-byte oracle, then the thing the
mature projects deliberately walked away from. The third only happened because
of the second._

## TL;DR

- **Engine.** The Windows-era languages (NCL, NewBCPL, NewCP, NewFB, NewBF,
  NewModula2, [locus](/posts/locus)) all stand on Rust + LLVM 22.1, each
  quarantining the dependency in its own `*-llvm` crate.
- **Two JIT strategies, and the split is forced** — **MCJIT** for the ones that
  emit inline assembly, **ORC** for the ones that stay pure-IR. Not a taste call.
- **Oracle.** The x86-64 assemblers ([WRASM](/posts/wrasm) and its JIT sibling
  [JASM](/posts/jasm) — with [MRASM](/posts/mrasm) the arm64 port) keep a
  from-scratch native encoder gated **byte-for-byte against LLVM-MC**, with LLVM
  behind an *opt-in test feature* — present to certify the encoder, absent from
  the shipping binary.
- **Graduate from it.** The Forth line and the Apple-Silicon projects shed LLVM
  entirely (own assembler, QBE, or the Dart VM's own backend). The oracle is what
  made that safe.

## Engine: how a language a week was possible

Look in almost any Windows-era compiler's `Cargo.toml` and you find the same two
lines — `inkwell = "=0.9.0"` and `llvm-sys = "=221.0.1"`, i.e. **LLVM 22.1** via
`LLVM_SYS_221_PREFIX`, shared across the whole family. And you find LLVM confined
to exactly one crate per project: `locus-llvm`, `newm2-llvm` (MacModula2),
`ncl-llvm` (NCL/MacNCL), `newbcpl-llvm` (NewBCPL/MacBCPL). That quarantine is
deliberate — as locus's manifest puts it, the `*-llvm` crate is "the only place
the inkwell / llvm-sys dependencies enter." Everything above it is arch- and
backend-neutral.

That's what let each new language reuse the last one's spine and come up fast: a
real optimizer, a portable IR, and a JIT for free meant the work was the
front-end and the runtime, not the code generator.

### MCJIT vs ORC — a forced choice, not a preference

The one genuinely interesting engine decision is which JIT to drive, and the
projects split cleanly:

- **MCJIT** — [NCL](/posts/newcl) ("LLVM 22.1 MCJIT"), NewBCPL, NewFB, and the
  MRASM oracle. These lean on a specific trick: an IR `declare` makes a symbol
  resolvable while a module-level **inline-asm body provides the bytes**.
- **ORC LLJIT** — locus, NewBF (Beef), NewModula2, with lazy materialization and
  a clean AOT path.

Why not just use ORC everywhere? Because the inline-asm pattern *can't* work
under it, and MRASM's hand-written LLVM-C binding says exactly why:

> "ORC's lazy materialization inventories which symbols a module *provides* from
> IR alone, before MC runs on the inline asm — so asm-defined symbols are
> invisible to ORC and lookups fail. MCJIT compiles eagerly and reaps both IR and
> asm symbols out of the final object in one pass." — MRASM `src/llvm.rs`

So the JIT flavor is dictated by the codegen strategy: emit assembly inside your
IR and you need MCJIT; stay pure-IR and ORC gives you laziness and AOT. Several
projects also emit **objects for AOT** — [MacBCPL](/posts/macbcpl)'s `build`
links a standalone signed Mach-O "at parity with the JIT."

## Oracle: LLVM as ground truth for hand-written encoders

Here is where LLVM's role inverts. The assemblers don't *use* LLVM to generate
code — they generate it themselves, and use LLVM only to **prove they did it
right.** On Windows x86-64 the standalone assembler is **[WRASM](/posts/wrasm)**,
and its manifest is blunt about the arrangement:

> "From-scratch x86-64 machine-code encoder (Intel-syntax text in, bytes out),
> byte-identical to LLVM-MC. No LLVM, no JIT." — WRASM `Cargo.toml`

The native encoder is the shipping build; there is no LLVM in it at all. LLVM
enters only as a **differential oracle** — a frozen corpus of **5,109 golden
forms** (integer, SSE/SSE2, AVX/AVX2, AVX-512 EVEX) that every build re-checks,
recorded once against LLVM-MC so the encoder can be certified "byte-identical to
LLVM-MC without depending on LLVM" (`src/lib.rs`). Source text in, a Windows PE
`.exe` out — no linker.

[JASM](/posts/jasm) — the JIT sibling WRASM's encoder was extracted from — runs
the identical play, and its design notes make the numbers concrete:

> "the x86 differential (integer + SSE/SSE2 + AVX/AVX2) is complete: 3393/3393
> forms match, 0 mismatch … harness/oracle/driver needed zero changes." —
> JASM `docs/design/rasm-difftest.md`

LLVM here is a **test oracle**: the shipping assembler has no LLVM dependency at
all; the LLVM build exists only so a difftest can assert the two encoders emit
the same bytes. The arm64 version of exactly this play — the same encoder design
carried to Apple Silicon — is [MRASM](/posts/mrasm).

## Graduate from it: the mature projects leave LLVM behind

Once your encoder is certified against LLVM-MC byte-for-byte, you no longer need
LLVM at runtime — and the mature projects take that exit:

- **The Forth line** sheds it in stages: [WF64](/posts/wf64) uses LLVM-MC,
  [WF65](/posts/wf65) makes the native encoder the default and demotes LLVM to an
  oracle, [WF66](/posts/wf66) removes LLVM entirely. [MF66](/posts/mf66) states
  the motive plainly — "WF64 was embedded inside an LLVM macro assembler, which
  carries a huge overhead … eventually we broke free of LLVM."
- **[MACVM](/posts/macvm)** never shipped LLVM — its Smalltalk runs through
  MACVM's **own adaptive compiler and own assembler** (both an LLVM backend and
  [QBEJIT](/posts/qbejit) were evaluated and set aside; its codegen is its own).
- **[MACDART](/posts/macdart)** is a C++ Dart VM with its *own* ARM64 backend; LLVM
  isn't in the picture.

The `*-llvm` crate quarantine is what makes this a clean exit rather than a
rewrite: the LLVM backend was always one swappable module behind a neutral seam.

### Why leave something that works?

Weight, mostly. JASM's own notes capture the cost — Homebrew's `libLLVM-C.dylib`
is an ~89 KB reexport shim over the **~160 MB** `libLLVM.dylib`, and a binary
built `--features llvm` "fails to launch with a dyld error if LLVM is
absent/moved." Their conclusion is the whole philosophy in one line:

> "This only affects the oracle/test build; the native shipping build (default
> features) has no LLVM dependency." — JASM design doc

A 160 MB dependency with a fragile load path is worth it to *bring a language
up*, and not worth shipping once you own a verified encoder that fits in a crate.

## The through-line

LLVM's arc across the portfolio is a promotion followed by a graceful handoff.
It was the engine that made half a dozen languages possible in a season; then it
was demoted — on purpose — to a **differential oracle** that certifies
hand-written encoders byte-for-byte; and that demotion is precisely what let the
Apple-Silicon projects drop it from the shipping path without losing an ounce of
correctness. The most important thing LLVM does in the mature projects is
**authorize its own removal.**

## Screenshots

> _Add to `static/images/llvm-in-these-compilers/`: a difftest run showing native
> vs LLVM-MC bytes matching; an MCJIT-vs-ORC diagram; `otool -L` on the LLVM
> reexport shim; a WF64→WF66 "LLVM removed" commit._

![Native encoder output verified byte-for-byte against LLVM-MC](/images/llvm-in-these-compilers/01.png)

## Related

- [WRASM](/posts/wrasm) (Windows x86-64, source→`.exe`) / [JASM](/posts/jasm) / [MRASM](/posts/mrasm) — native encoders gated against the LLVM-MC oracle
- [Locus](/posts/locus) — the canonical inkwell + ORC setup
- [MacBCPL](/posts/macbcpl) — LLVM JIT **and** AOT at parity
- The Forth line: [WF64](/posts/wf64) → [WF65](/posts/wf65) → [WF66](/posts/wf66) → [MF66](/posts/mf66) — shedding LLVM in stages
- [MACVM](/posts/macvm) (QBE) and [MACDART](/posts/macdart) (Dart's own backend) — no LLVM at all
