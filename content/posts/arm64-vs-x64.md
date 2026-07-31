+++
title = "arm64 vs x64, across these compilers"
date = 2026-07-31
description = "The portfolio spans both Windows x86-64 and Apple-Silicon arm64, and several projects carry both backends at once — so the real differences show up side by side in one codebase. A tour of the four that matter: encoding, executable memory, calling convention, and the cache."
[taxonomies]
tags = ["arm64", "aarch64", "x86-64", "apple-silicon", "jit", "assembler", "abi", "wx"]
+++

_Most "arm64 vs x64" comparisons are abstract. This one isn't: several of these
projects carry **both** backends in the same repo, gated against the same oracle,
so you can read the differences off diffs instead of folklore. Four of them
matter — how you spell an instruction, how you get executable memory, how you
pass an argument, and what the cache does behind your back._

## TL;DR

- The portfolio has a **Windows/x86-64 era** (NCL, NewBCPL, NewCP, NewFB,
  NewModula2, WF64/65, WRASM) and an **Apple-Silicon/arm64 era** (MacBCPL,
  MacNCL, MacModula2, MF66/67, [MACVM](/posts/macvm), [MACDART](/posts/macdart),
  [MRASM](/posts/mrasm)). [JASM](/posts/jasm) targets **both**.
- The surprise, stated in JASM's port doc: most of a compiler is
  **architecture-neutral** and ports *unchanged*. The differences concentrate in
  four places.
- **Encoding:** x86-64 variable-length CISC vs AArch64 fixed 32-bit words —
  visible right down to the lexer and the relocation table.
- **Executable memory:** Windows lets you have RWX; **Apple Silicon enforces
  W^X** and a split instruction cache — the single biggest porting tax.
- **ABI:** Windows-x64 shadow space vs AArch64's AAPCS64 — and 16 vs 31 registers.

## The shape of a port: mostly nothing changes

When JASM went from x86-64 Windows to arm64 macOS, the striking part is how
little moved. Its design doc lists the arch-**neutral** core — the macro
front-end, the `Encoder`/`Loader`/`EncodedModule` backend traits, the diff
driver, corpus record/replay — and notes they "compile + pass on macOS
unchanged." The strategy was explicitly to rerun the x86 playbook:

> "Bring JASM to Apple Silicon by running the *same play* the project already ran
> for x86-64" — stand up LLVM-MC as the AArch64 oracle, build a native encoder
> gated byte-for-byte against it, then swap the loader. — JASM `docs/design/aarch64-apple-silicon.md`

So the assemblers keep **parallel** `corpus/x86_64.tsv` and `corpus/aarch64.tsv`,
`difftest/x86.rs` and `difftest/aarch64.rs`, behind one neutral harness. That
framing — a small arch-specific edge around a large neutral core — is what the
rest of this article is really about: what's in that edge.

## 1. Encoding: variable-length CISC vs fixed 32-bit words

x86-64 instructions are **1–15 bytes**: optional prefixes, an optional REX byte,
opcode, ModRM, SIB, displacement, immediate — the length depends on the operands.
AArch64 instructions are **always one 32-bit word**, operands packed into
bitfields. That difference leaks upward in concrete ways the code has to handle:

- **The lexer.** AArch64 has *compound tokens* x86 never produces, so JASM's
  lexer keeps an interior `.` inside `b.<cond>` and `v0.8b`, and an interior `@`
  inside `sym@PAGE` / `sym@PAGEOFF`, rather than splitting them as it would an
  x86 token.
- **Relocations.** x86-64 gets by with essentially one RIP-relative displacement
  form. AArch64 addressing is a **pair** — `adrp` computes a ±4 GB page, `add`/
  `ldr` the 12-bit offset within it — so the encoder grows `AdrpPage21`
  (`ARM64_RELOC_PAGE21`), `AddPageOff12` (`ARM64_RELOC_PAGEOFF12`), and `Branch26`
  (`ARM64_RELOC_BRANCH26`, a `b`/`bl` with a 26-bit word offset) where x86 needed
  none of them.
- **Assembler syntax and features.** The oracle pins `x86_64-pc-windows-msvc` with
  `+avx512*` versus `aarch64-apple-darwin` at base ARMv8-A, and x86 goes through
  `.intel_syntax noprefix` while AArch64 text passes as GAS verbatim.

## 2. Executable memory: RWX vs enforced W^X — the porting tax

This is the biggest single difference, and the reason [QBEJIT](/posts/qbejit),
JASM, MACVM, and MACDART all carry **two** loaders.

**Windows x86-64.** Ask for `VirtualAlloc(PAGE_EXECUTE_READWRITE)` (or flip with
`VirtualProtect`) and you can hold a page **writable and executable at once**.
The instruction cache is coherent with the data cache, so freshly written code
just runs — no flush.

**Apple Silicon arm64.** A page may not be writable and executable simultaneously
(**W^X**), and the I-cache is *not* coherent with the D-cache. So the JIT dance
is: `mmap(MAP_JIT)`, then a **per-thread write/execute toggle**
(`pthread_jit_write_protect_np`, or `mprotect` under the
`com.apple.security.cs.allow-jit` entitlement), then **`sys_icache_invalidate`**
so the core actually fetches the new bytes — on **16 KB** pages, not 4 KB. JASM
sums up the loader swap exactly:

> "a macOS native loader — `mmap(MAP_JIT)` + the per-thread W^X toggle + icache
> invalidation + **far-call veneers** — replacing the Windows
> `VirtualAlloc2`/`VirtualProtect` loader." — JASM design doc

That last item is its own arm64 tax: a `bl` reaches only **±128 MB**, so distant
calls need trampoline **veneers**, where x86-64's `call rel32` spans ±2 GB and
rarely bothers. (This W^X recipe is shared house infrastructure — MACVM literally
vendors JASM's macOS loader rather than reimplement it.)

## 3. Calling convention: shadow space vs AAPCS64

- **Windows x64** passes the first four integer args in `rcx/rdx/r8/r9` (floats in
  `xmm0–3`) and makes the caller reserve **32 bytes of shadow space** even when
  the callee has few args. System V (Linux/mac x86-64) instead uses
  `rdi/rsi/rdx/rcx/r8/r9` and no shadow space — so "x86-64" isn't even one ABI.
- **AArch64 AAPCS64** passes `x0–x7` / `v0–v7`, returns small composites and
  homogeneous float aggregates **in registers**, and uses `x8` for an indirect
  result. A consequence that matters to the Cocoa bridges here: **there is no
  `objc_msgSend_stret` on arm64** — ≤16-byte structs and HFAs come back in
  registers — so the shared marshaller classifies each `@encode` into AAPCS64
  slots (int in GPRs, float in FPRs, HFA across `d0–d3`, an int-pair across
  `x0–x1`) and calls one fixed-shape `objc_msgSend`.
- **Register file.** x86-64 has **16** general registers; arm64 has **31**
  (`x0–x30`) plus a dedicated `SP` and 32 vector registers. More registers mean
  fewer spills — and the occasional arm64-only footgun (below).

## 4. The cache and the memory model: what x86-64 lets you get away with

Apple Silicon is stricter in ways that turn latent x86 habits into hard failures:

- **You must flush the I-cache.** MACDART's *entire* first bring-up hinged on one
  function: `CPU::FlushICache` had to become `sys_icache_invalidate`, because the
  Dart VM's self-modifying-code path had only ever run in AOT mode on Apple arm64.
  On x86-64 the coherent I-cache made this a no-op you never noticed.
- **`UNPREDICTABLE` means trap, not tolerate.** MACDART's deopt stub pushed every
  register with `str r,[SP,#-8]!`; when `r == SP` that's a CONSTRAINED-
  UNPREDICTABLE encoding — other ARM cores execute it, **Apple Silicon traps it as
  SIGILL** — so it had to special-case `mov x25, SP; str x25, …`. There is no
  x86-64 analogue; the machine just does what you wrote.
- **Weak vs strong ordering.** arm64 has a **weakly-ordered** memory model; x86-64
  is essentially TSO. Lock-free queues, GC handshakes, and JIT publish/consume
  that "just worked" under x86's strong ordering need explicit acquire/release
  barriers on arm64, or they race only on the M-series.
- **16 KB pages** change every page-rounding assumption a loader inherited from a
  4 KB world.

## The through-line

Read across the two eras and the lesson is consistent: **the compiler is
portable; the machine is not.** The front-end, the IR, the optimizer, even the
diff harness cross from x86-64 to arm64 untouched. What doesn't cross is the
thin, unavoidable edge — the instruction encoding and its relocations, the rules
for getting executable memory, the calling convention, and the cache's promises.
And Apple Silicon's version of that edge is the strict one: it enforces W^X,
traps the encodings x86 tolerates, reorders memory x86 wouldn't, and makes you
flush a cache x86 kept coherent. Porting to it is less "rewrite the compiler" and
more "do correctly the four things x86-64 let you be sloppy about" — which is
exactly why a byte-for-byte oracle for the new encoder is the first thing every
one of these ports stands up.

## Screenshots

> _Add to `static/images/arm64-vs-x64/`: parallel `difftest/x86.rs` vs
> `difftest/aarch64.rs` passing; a MAP_JIT + W^X toggle trace; the MACDART
> `str SP,[SP,#-8]!` SIGILL in lldb; an `adrp`/`add` pair vs a RIP-relative load._

![Parallel x86-64 and AArch64 encoders, both gated against LLVM-MC](/images/arm64-vs-x64/01.png)

## Related

- [JASM](/posts/jasm) — one assembler, both backends, gated against the same oracle
- [QBEJIT](/posts/qbejit) — the W^X ARM64 JIT recipe in full
- [MACDART](/posts/macdart) — the arm64 bring-up war stories (I-cache, SIGILL)
- [MACVM](/posts/macvm) — vendors JASM's macOS loader
- [The role of LLVM in these compilers](/posts/llvm-in-these-compilers) — the byte-for-byte oracle that makes an encoder port safe
