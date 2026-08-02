+++
title = "Timeline"
description = "Every project in the portfolio, in the order it was built — the Windows years that built the substrate, then the move to Apple Silicon."
path = "timeline"
+++

# Timeline

Dates are from each repository's first and last commit. The story runs in two
acts.

**Act I — the Windows years.** A single seed from 2020 (a 32-bit Forth), then a
six-week burst across May–July 2026 in which an entire toolchain and roughly a
dozen from-scratch language compilers were built on Windows, almost all on the
same substrate: **Rust + LLVM, a Direct2D/DirectWrite GUI shell called _iGui_, a
shared garbage collector, and a hand-written x86-64 assembler.** Each new
language reused the last one's runtime, GUI, and GC, which is why a language a
week was even possible.

**Act II — Apple Silicon.** The strongest lines were then re-homed to
`arm64-apple-darwin`, trading Direct2D for Cocoa/Metal and — the throughline —
shedding LLVM for native arm64 codegen through the house assembler and JIT.

> _Editor's note: Act I below is reconstructed from the actual Windows
> repositories (first/last commit dates, READMEs, manifestos). Most of these
> Windows projects don't have their own article yet — they're the pre-history
> the published articles grow out of._

## The articles at a glance

The projects that have (or are getting) a full article. The Windows-origin rows
here — NewBCPL, NCL, JASM — are the tip of a much larger first act, detailed
under [Act I](#act-i-the-windows-years) below.

| Date (first commit) | Project | What it is | Thread |
|---|---|---|---|
| 2020-06-14 | [wf32](/posts/wf32) | Alex McDonald's meta-compiled 32-bit STC Forth — the adopted seed | Forth |
| 2026-01-04 | [SuperTerminalMetal](/posts/superterminalmetal) | A Metal-rendered terminal / Lua runner | Side |
| 2026-05-10 | [NewBCPL](/posts/newbcpl) | Modern BCPL, JIT, Windows + Direct2D | BCPL |
| 2026-05-10 | [NCL](/posts/newcl) | Corman-Lisp-style Common Lisp, Windows | Lisp |
| 2026-05-18 | [JASM](/posts/jasm) | JIT macro-assembler (x86-64 Windows; arm64 → MRASM) | Metal |
| 2026-05-30 | [Locus](/posts/locus) | Research language — effects as graded modalities | Research |
| 2026-06-10 | [WF66](/posts/wf66) | Token-IR optimizing Forth (successor to WF65) | Forth |
| 2026-06-14 | [MacModula2](/posts/macmodula2) | From-scratch Modula-2, Cocoa-native objects | Modula-2 |
| 2026-06-24 | [MacNCL](/posts/macncl) | NCL re-homed to Apple Silicon + Cocoa/Metal | Lisp |
| 2026-06-26 | [MF66](/posts/mf66) | Apple Silicon Forth, LLVM-free | Forth |
| 2026-06-27 | [MRASM](/posts/mrasm) | Knowledge-rich macro assembler for macOS | Metal |
| 2026-06-28 | [MacBCPL](/posts/macbcpl) | BCPL on Apple Silicon — JIT **and** AOT | BCPL |
| 2026-06-28 | [cocoa_data](/posts/cocoa-data) | Shared SQLite mirror of the macOS ObjC SDK | Cocoa bridge |
| 2026-06-28 | [MF67](/posts/mf67) | "Objective Forth" — Forth as the Mac's system language | Forth |
| 2026-07-01 | [MACVM](/posts/macvm) | From-scratch Smalltalk, inspired by Strongtalk | Smalltalk |
| 2026-07-05 | [QBEJIT](/posts/qbejit) | In-process W^X ARM64 JIT built on QBE | Metal |
| 2026-07-05 | [MacGamePane](/posts/macgamepane) | Retro 2D game engine (Metal + AVFoundation) | Side |
| 2026-07-18 | [Raven](/posts/raven) | Design fiction — not a compiler | Off-topic |
| 2026-07-25 | [MACDART](/posts/macdart) | Port of Dart 1.24.3 (last V1) to arm64 | Dart |
| 2026-08-01 | [WINVM](/posts/winvm) | Windows x86-64 Smalltalk — the sibling of MACVM | Smalltalk |

## Act I — the Windows years

The first act is a Windows story, and a denser one than the articles above let
on. It begins in **2020** with a single adopted Forth and then detonates across
**May–July 2026**, when compiler after compiler comes up on a common Windows
substrate before the whole effort pivots to the Mac.

Two things make the pace possible. First, a **shared substrate**: the Component
Pascal project **NewCP** produces _iGui_ — an immediate-mode Direct2D/DirectWrite
MDI shell — and after that every new language starts life with a working GUI,
editor, and crash dumper it can borrow wholesale. A shared GC and a shared
hand-written assembler play the same role. Second, a **differential-oracle
habit**: native code generators are gated byte-for-byte against LLVM-MC, so the
project can grow its own encoders without giving up correctness — the exact skill
that later lets it leave LLVM behind on Apple Silicon.

### The Windows projects, in order

Dates are first commits. Linked names have an article; the rest are repositories
only (so far).

| Date | Project | What it is | Stack / back-end |
|---|---|---|---|
| 2020-06-14 | [wf32](/posts/wf32) | Alex McDonald's 32-bit Win32 STC Forth — the adopted **seed** of the whole Forth line | Forth-hosted x86 assembler; console |
| 2026-05-03 | [NewCP](/posts/newcp) | From-scratch **Component Pascal** + BlackBox recreation; **birthplace of the _iGui_ shell** | Rust + LLVM 22 (Inkwell) + MCJIT |
| 2026-05-10 | [NewBCPL](/posts/newbcpl) | Modern **BCPL** dialect with an editor that JITs the live buffer | Rust + LLVM 22 MCJIT; mark-sweep GC |
| 2026-05-10 | [NCL](/posts/newcl) ("NewCL") | From-scratch **Common Lisp** in the Corman spirit | Rust + LLVM 22.1 MCJIT; page-heap GC |
| 2026-05-12 | [NewFB](/posts/newfb) | From-scratch **FasterBASIC** with a retro graphics stack | Rust + LLVM MCJIT/AOT; iGui + D3D11 |
| 2026-05-13 | NewM2 / M2NEW | First Windows **Modula-2** (PIM 4 / ISO 10514), GC, ISO-OO → [NewModula2](/posts/newmodula2) | Rust + LLVM MCJIT/AOT |
| 2026-05-18 | [JASM](/posts/jasm) | MASM-style **JIT macro-assembler** — "source in, function pointer out" | Rust; LLVM-MC/MCJIT → native _Rasm_ |
| 2026-05-18 | NewGC | Language-agnostic **generational mark-evacuate GC** | Rust (Windows + Unix) |
| 2026-05-19 | [WF64](/posts/wf64) | 64-bit **STC Forth**, JIT-loaded through JASM | Rust + `.masm` kernel; LLVM-MC |
| 2026-05-24 | [NewFactor](/posts/newfactor) | An ANS **Forth** that runs on **Factor's** production JIT VM | Rust; embeds a patched `factor.dll` |
| 2026-05-29 | [NewBF](/posts/newbf) | From-scratch **Beef** — a C#-shaped, manual-memory systems language | Rust + LLVM 22.1 ORC JIT + AOT |
| 2026-05-30 | [Locus](/posts/locus) (dev "RNim") | Research language: **effects + staging as graded modalities**, Lean-verified core | Rust + LLVM 22.1 ORC JIT + AOT |
| 2026-06-08 | [WF65](/posts/wf65) | STC Forth where the **native encoder becomes default** and LLVM becomes an oracle | Rust; native _Rasm_ + peephole opt |
| 2026-06-10 | [WF66](/posts/wf66) | **Token-IR optimizing** Forth — LLVM removed entirely; adds an OOP system | Rust; token IR → native _Rasm_ |
| 2026-06-14 | [NewModula2](/posts/newmodula2) | The **canonical Windows Modula-2**: manual memory, machine-checked COM, D3D/audio, self-hosted IDEs | Rust + LLVM 22.1 ORC JIT + AOT |
| 2026-06-19 | [WRASM](/posts/wrasm) | From-scratch **x86-64 assembler**: source text → a running `.exe`, no LLVM/JIT/linker | Rust; native encoder + knowledge IDE |

A few smaller repositories round out the act and are best read as footnotes to
the projects above: **SFCL**, a 21 May snapshot of NCL carrying an (uncommitted)
"Self-Hosted Corman Lisp" design that proposed dropping LLVM for a Lisp-written
assembler; **WindowsModula2**, a distribution snapshot (a shallow clone) of
NewModula2; and **NewOpenDylan** (now retired), an Open Dylan reimplementation
that — together with NCL — drove the design of the shared NewGC.

### The Windows compilers, family by family

**The assembler line — JASM → WRASM (→ MRASM).**
[JASM](/posts/jasm) (crate `wfasm`) is the foundation stone: a MASM32-spirited
JIT macro-assembler that takes assembly source and hands back a callable
`extern "C"` function pointer — no linker, no object file, no subprocess. It
exposes the entire Win32 API by name (generated from Microsoft's
`Windows.Win32.winmd` metadata) and ships a VEH/SEH crash dumper for when
hand-written asm goes sideways. It began on an **LLVM-MC + MCJIT** pipeline, then
grew a **from-scratch native x86-64 encoder** (_Rasm_) that is now the default
build, with LLVM kept only as a byte-for-byte differential **oracle**. That
encoder was then lifted out on 2026-06-19 into **WRASM** — a standalone assembler
that writes a complete Windows **PE `.exe`** directly (its own import thunks, no
`link.exe`), validated byte-identical to LLVM-MC across a frozen 5,109-instruction
corpus, wrapped in a Direct2D "studio" IDE with a ~165,000-symbol Win32 knowledge
database (`winkb`). WRASM is the Windows original that [MRASM](/posts/mrasm) is
the macOS arm64 port of.

**The Forth line — wf32 → WF64 → WF65 → WF66 (→ MF66/MF67).**
The oldest lineage in the portfolio. It starts with **[wf32](/posts/wf32)**, Alex
McDonald's mature 32-bit subroutine-threaded Win32 Forth (BSD-2-clause, 2020) —
meta-compiled from Forth source into a Windows PE with no C anywhere in the
build, and eagerly inlining about half its primitives — adopted as a seed and
left untouched for six years. In 2026 its STC compiler and primitives
are ported up to 64-bit **[WF64](/posts/wf64)**, whose `.masm` kernel is assembled
and JIT-loaded through JASM's LLVM-MC path — which is what the phrase "a Forth
embedded inside an LLVM macro assembler" means, and where the "huge overhead"
(a stock 67.7 MB `LLVM-C.dll`, in a 71 MB release folder) comes from. The port
also dropped WF32's eager inliner and spent three attempts winning it back.
**[WF65](/posts/wf65)** sheds the LLVM — the native _Rasm_
encoder (in JASM) becomes the default backend and LLVM is demoted to a byte-exact
oracle — and, in three days, builds a codegen measurement gate and then spends
nine commits winning WF32's inliner back against it: **−58% calls for +7.5%
bytes**, almost exactly WF32's own trade. Its largest single win is not an
optimization at all but a W^X fix worth **~143×** on variable access.
**[WF66](/posts/wf66)**
then replaces the compiler outright — it captures each definition as a **token
IR, optimizes the tokens as data, and only then emits**, drops LLVM entirely, and
adds a single-inheritance OOP system (measured ~2.6–3.7× faster than eager WF65
on a Forth Mandelbrot). The Apple Silicon continuation is
[MF66](/posts/mf66) → [MF67](/posts/mf67).

**BCPL — NBCPL → NewBCPL (→ MacBCPL).**
The Windows entry is [NewBCPL](/posts/newbcpl): a modern BCPL dialect rebuilt in
Rust on **LLVM 22 (MCJIT)**, with a precise mark-sweep GC (ported from NewCP), a
Win64-SEH-aware JIT memory manager, and a Direct2D/DirectWrite editor (`bedit`)
that JITs the current buffer on Ctrl+R. The dialect adds `CLASS`/`EXTENDS`/
`VIRTUAL`, SIMD vector types, and RAII-style scope cleanup on top of classic
BCPL. Its own predecessor, **NBCPL**, is the author's earlier Apple-Silicon
(ARM64, C++) BCPL, vendored inside NewBCPL as the language spec — so the chain is
NBCPL (arm64) → NewBCPL (Windows) → [MacBCPL](/posts/macbcpl).

**Lisp — Corman Lisp → NCL (→ MacNCL).**
[NCL](/posts/newcl) (GitHub `NewCL`, internally "NCL") is a from-scratch
reimplementation of the **Corman Lisp** language and developer experience — not
its codebase. It is JIT-first with no interpreter: Lisp → its own IR → **LLVM
22.1 MCJIT** per function, over a **generational page-heap GC** (the collector
that was later generalized into NewGC). It brings a numeric tower, a full macro
system, a condition system with restarts, and a CLOS derived from Closette, and
runs the classic Corman demos while passing ~760 of 919 ANSI conformance forms
(benchmarked honestly against SBCL 2.6.5). Its iGui shell — Direct2D + Direct3D 11
+ DirectWrite — is borrowed from NewCP. The started-but-not-finished Apple Silicon
port is [MacNCL](/posts/macncl). _(A short-lived fork, **SFCL** — "Self-Hosted
Corman Lisp" — explored replacing LLVM with a Lisp-written x64 assembler; it
stayed a design sketch and never merged.)_

**Modula-2 — ADW/Stony Brook M2 → NewM2 / M2NEW → NewModula2 (→ MacModula2).**
The Windows Modula-2 effort telescopes quickly. **NewM2** is the plan and
reference trove (a clean-room port of ADW's Extended/Stony Brook Modula-2 to
PIM 4 + ISO 10514-1); **M2NEW** is the first working compiler (GC-by-default,
ISO-10514-2 objects with vtables, MCJIT + AOT, an iGui editor borrowed from
NewFB); and **NewModula2** is the canonical restart that **drops the GC for
classical manual memory** and explodes in scope: a machine-checked **COM object
model** (interfaces carry an IID and per-method `@ordinal`; the compiler computes
each vtable slot by walking the `INHERIT` chain), a full **Direct3D 11 / Direct2D
/ GDI / WinMM-audio** stack reachable from pure Modula-2, and **two self-hosted
IDEs written in Modula-2** (FastM2 and the GPU-pane FastPanesM2). It is the direct
Windows predecessor of the Cocoa-native [MacModula2](/posts/macmodula2).

**Component Pascal — NewCP.**
The earliest 2026 project and the wellspring of the shared shell. **NewCP** is a
from-scratch recreation of Component Pascal and the **BlackBox Component
Builder** — a memory-resident, JIT-first system (parse → typecheck → typed IR →
LLVM IR → MCJIT, with a dynamic on-demand module loader) that even reads a
675-file BlackBox `.odc` corpus. Along the way it invents **iGui**, the
immediate-mode Direct2D/DirectWrite MDI shell (the GUI owns the main thread; the
language runtime talks to it through an event mailbox) that becomes the reusable
front for almost every later language.

**BASIC — NewFB.** A from-scratch **FasterBASIC** (Windows-first; the original
FasterBASIC is a Zig+LLVM macOS project — no shared source). Rust + LLVM,
JIT-first with opt-in AOT, single-inheritance OO with devirtualization, a precise
tracing GC (from NewCP), a WORKER/SPAWN/AWAIT concurrency model, and a retro
graphics layer — indexed-colour framebuffer, sprites, tilemaps, a CRT-scanline
shader, D3D11 demos, XAudio2/MIDI. _(Its README still says "skeleton only"; the
commit log says otherwise — it's a working compiler.)_

**Beef — NewBF.** A from-scratch compiler for **Beef** (beeflang.org), a
C#-shaped systems language whose signature is **manual memory, no GC**. Rust +
**LLVM 22.1**, ORC JIT for the inner loop plus AOT `.exe`; it reaches ~60% of the
language with monomorphized generics, comptime code generation, runtime
reflection, and a deterministic use-after-free / double-free guard that turns
manual memory into a debuggable contract. The most heavily worked of the New*
repositories.

**Factor-hosted Forth — NewFactor.** The odd one out, and a good one: an ANS
**Forth** front-end whose back-end is **Factor's** production JIT VM. It compiles
Forth to canonical Factor source and runs it on Factor's optimizing, PIC-driven,
generational-GC engine (embedded as a patched `factor.dll`) — the bet being that
generated Factor beats hand-written assembly, with the programmer never seeing
Factor at all.

### The shared Windows substrate

What ties the act together is a handful of components that every project reused —
the reason a solo effort could stand up a compiler roughly every week.

- **iGui — the GUI shell.** An immediate-mode **Direct2D + DirectWrite** MDI shell
  over **Direct3D 11 + DXGI**, born in NewCP and then reused (often literally by
  name) across NewBCPL, NCL, NewFB, NewBF, NewFactor, the Modula-2 line, the WF64→
  WF66 Forths, and Locus. The pattern is always the same: the GUI owns the main
  thread; the language runtime runs behind an event mailbox and never touches an
  HWND directly.
- **Two garbage collectors, deliberately.** NewCP's non-moving **mark-sweep**
  `gc.rs` was ported into NewBCPL, NewFB, and the Modula-2 line; separately,
  **NewGC** — a language-agnostic **moving, generational mark-evacuate** collector
  in the SBCL `gencgc` mould — was extracted from NCL's page-heap and shared with
  NewOpenDylan and the Forths. (Two different family trees; easy to conflate,
  worth keeping straight.)
- **The native encoder.** The _Rasm_ x86-64 encoder inside JASM, later split out
  as WRASM, gated byte-for-byte against LLVM-MC. The same discipline recurs in
  WF65 and WRASM: keep LLVM only as a byte-exact oracle, and you can own your
  codegen without losing correctness.
- **docpane / selkie.** A shared Markdown + Mermaid **DirectWrite** render core
  (from the WF66 line) that also renders WRASM's IDE documentation panes.
- **windows_api.db.** A SQLite projection of Microsoft's `Windows.Win32.winmd`
  metadata (built in the Modula-2 line) that feeds JASM's "Win32 by name" macros
  and WRASM's `winkb` knowledge layer.
- **The toolchain.** Rust (edition 2021 → 2024) with **LLVM 22.1** via
  Inkwell / `llvm-sys`, targeting `x86_64-pc-windows-msvc` with MSVC-style SEH;
  MCJIT at first, increasingly ORC. And the throughline of the whole act: an arc
  from **renting** codegen from LLVM toward **owning** it — the move that Act II
  completes on Apple Silicon.

## The lineages

Several projects are explicitly descendants of earlier ones (some ancestors live
in other repositories, or upstream):

- **Assembler:** MASM32-era ergonomics → **[JASM](/posts/jasm)** (JIT, x86-64
  Windows) → **WRASM** (its native encoder, split out to emit `.exe`s) →
  **[MRASM](/posts/mrasm)** (the macOS arm64 port). JASM is the JIT-focused
  sibling both Windows and Apple Silicon share.
- **Forth:** **[wf32](/posts/wf32)** STC (Alex McDonald, 2020) → WF64 (LLVM-MC via JASM) → WF65
  (native encoder default, LLVM as oracle) → **[WF66](/posts/wf66)** (token IR) →
  **[MF66](/posts/mf66)** (Apple Silicon) → **[MF67](/posts/mf67)** (Objective
  Forth).
- **BCPL:** NBCPL (Apple Silicon, C++) → **[NewBCPL](/posts/newbcpl)** (Windows,
  Rust + LLVM) → **[MacBCPL](/posts/macbcpl)** (Apple Silicon, JIT + AOT).
- **Lisp:** Corman Lisp (Roger Corman) → **[NCL](/posts/newcl)** (Windows) →
  **[MacNCL](/posts/macncl)** (Apple Silicon).
- **Component Pascal:** BlackBox Component Builder → **NewCP** (Windows) — the
  project that gave the family its iGui shell.
- **Modula-2:** ADW / Stony Brook Extended Modula-2 → NewM2 / M2NEW → **NewModula2**
  (canonical Windows) → **[MacModula2](/posts/macmodula2)** (Cocoa-native).
- **BASIC / Beef:** FasterBASIC → **NewFB**; Beef → **NewBF** — two more
  Windows-native Rust + LLVM compilers on the same substrate.
- **Smalltalk:** Self (1986) → Strongtalk (2002, C++) → **[MACVM](/posts/macvm)**
  (from scratch, Apple Silicon) ↔ **[WINVM](/posts/winvm)** (Windows x86-64
  sibling) — Rust, each with its own adaptive compiler + assembler.
- **Dart:** dart-lang/sdk `1.24.3` (last V1 release) → **[MACDART](/posts/macdart)**
  (arm64 JIT, C++).

## The recurring subplots

- **A shared Windows substrate.** iGui, NewGC, the _Rasm_ encoder, and
  `windows_api.db` meant each new Windows language started from a running GUI, a
  GC, an assembler, and the whole Win32 surface — which is why an entire family of
  compilers came up in a single season.
- **From renting LLVM to owning codegen.** The Windows projects lean on LLVM
  (22.1), but repeatedly grow native encoders gated against it as an oracle
  (JASM → _Rasm_ → WRASM; WF65 → WF66). The Apple Silicon act finishes the move:
  emitting arm64 directly, LLVM-free.
- **W^X on Apple Silicon.** Every JIT in Act II has to satisfy the same rule: a
  page can't be writable and executable at once. The house solution (MAP_JIT + a
  per-thread toggle, or MAP_JIT + mprotect under the allow-jit entitlement) shows
  up in JASM, QBEJIT, MACVM and MACDART. A single article's worth of detail,
  reused everywhere.
- **Teaching a language to speak Cocoa.** From MacModula2's "a CLASS _is_ an
  Objective-C object" onward, each Mac language finds its own way to make an
  `objc_msgSend` feel native — culminating in the shared `cocoa_data` mirror. On
  Windows the same instinct spoke COM instead (NewModula2's machine-checked
  `@ordinal` vtables).
