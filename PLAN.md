# Editorial plan

The through-line: **a personal history of building compilers, JITs, assemblers
and language runtimes — moving from Windows + LLVM to LLVM-free, self-contained
tools native to Apple Silicon.** Each article stands alone, but read in order
they tell one story: build an assembler → build a JIT on top → use both to bring
a language up → learn to drive Cocoa from that language → repeat for the next
language, each time deeper into the Mac.

## The five narrative threads

1. **The metal — assemblers & JIT substrate.** JASM, MRASM, QBEJIT. Turning
   source text into executable bytes in `MAP_JIT` memory under Apple Silicon's
   W^X rules. Everything else stands on this.
2. **The languages.** One family per lineage: Forth (WF66 → MF66 → MF67), BCPL
   (NewBCPL → MacBCPL), Lisp (NCL → MacNCL), Modula-2 (MacModula2), Smalltalk
   (MACVM), Dart (MACDART).
3. **Windows → Apple Silicon.** Several languages started as Windows + LLVM +
   Direct2D projects and were re-homed to arm64 + Cocoa + Metal. That port is a
   recurring, teachable subplot.
4. **The Cocoa bridge.** How each compiler learned to treat an Objective-C
   object as a first-class value — and `cocoa_data`, the shared SQLite mirror of
   the macOS SDK that feeds them all.
5. **Off to the side.** locus (a research language about effects), MacGamePane
   (a retro game engine), and a couple of edge cases.

## Article status

Legend: ✍️ stub written (needs expansion) · 🟡 drafting · ✅ published

| # | Article | Slug | Thread | Stack | Period | Status |
|---|---------|------|--------|-------|--------|--------|
| 1 | JASM — JIT macro-assembler | `jasm` | Metal | Rust | 2026-05→06 | ✍️ |
| 2 | MRASM — knowledge-rich assembler | `mrasm` | Metal | Rust | 2026-06→07 | ✍️ |
| 3 | QBEJIT — W^X ARM64 JIT on QBE | `qbejit` | Metal | Zig + Rust | 2026-07 | ✍️ |
| 4 | NewBCPL — BCPL JIT (Windows) | `newbcpl` | Language / Win | Rust + LLVM | 2026-05 | ✍️ |
| 5 | MacBCPL — BCPL on Apple Silicon | `macbcpl` | Language / Port | Rust + LLVM | 2026-06→07 | ✍️ |
| 6 | NCL — Common Lisp (Windows) | `newcl` | Language / Win | Rust + LLVM | 2026-05→07 | ✍️ |
| 7 | MacNCL — Lisp on Apple Silicon | `macncl` | Language / Port | Rust + LLVM | 2026-06 | ✍️ |
| 8 | MacModula2 — Cocoa-native Modula-2 | `macmodula2` | Language / Cocoa | Rust + LLVM | 2026-06→07 | ✍️ |
| 9 | WF66 — token-IR Forth | `wf66` | Language / Forth | Rust | 2026-06 | ✍️ |
| 10 | MF66 — Apple Silicon Forth | `mf66` | Language / Forth | Rust | 2026-06 | ✍️ |
| 11 | MF67 — Objective Forth | `mf67` | Language / Cocoa | Rust | 2026-06→07 | ✍️ |
| 12 | MACVM — Smalltalk from scratch | `macvm` | Language / Flagship | Rust (own compiler + assembler) | 2026-07 | ✍️ |
| 13 | MACDART — Dart V1 on arm64 | `macdart` | Language / Flagship | C++ | 2026-07→ | ✍️ |
| 14 | cocoa_data — the SDK mirror | `cocoa-data` | Cocoa bridge | Python + SQLite | 2026-06→07 | ✍️ |
| 15 | MacGamePane — retro game engine | `macgamepane` | Side | Rust + Metal | 2026-07 | ✍️ |
| 16 | Locus — effects as modalities | `locus` | Side / Research | Rust + LLVM | 2026-05→06 | ✍️ |
| 17 | SuperTerminalMetal — Metal terminal | `superterminalmetal` | Side (draft) | ObjC/C++ + Metal | 2026-01 | ✍️ (optional) |
| 18 | Raven — design fiction | `raven` | Not a compiler | — | 2026-07 | ✍️ (optional) |
| 19 | NewCP — Component Pascal / BlackBox (Windows) | `newcp` | Language / Win | Rust + LLVM | 2026-05 | ✍️ |
| 20 | WF64 — 64-bit STC Forth (Windows) | `wf64` | Language / Forth | Rust + LLVM | 2026-05→06 | ✍️ |
| 21 | WF65 — STC Forth, native encoder | `wf65` | Language / Forth | Rust | 2026-06 | ✍️ |
| 22 | WRASM — x86-64 assembler (Windows) | `wrasm` | Metal | Rust | 2026-06→07 | ✍️ |
| 23 | Windows Modula-2 (NewModula2) | `newmodula2` | Language / Win | Rust + LLVM | 2026-06 | ✍️ |
| 24 | NewFB — FasterBASIC (Windows) | `newfb` | Language / Win | Rust + LLVM | 2026-05→07 | ✍️ |
| 25 | NewBF — Beef (Windows) | `newbf` | Language / Win | Rust + LLVM | 2026-05→07 | ✍️ |
| 26 | NewFactor — Forth on Factor's VM | `newfactor` | Language / Forth | Rust + Factor | 2026-05→06 | ✍️ |
| 27 | WINVM — Windows Smalltalk, sibling of MACVM | `winvm` | Language / Win | Rust (own compiler + assembler) | 2026-07→08 | ✍️ |
| 28 | WF32 — the adopted seed, reviewed (Alex McDonald's, not mine) | `wf32` | Language / Forth | Forth (self-hosting) | 2005→2017 | 🟡 |

**Decisions to confirm:**

- **#17 SuperTerminalMetal** is a terminal/runtime, not a compiler — include as a
  "tools I built along the way" piece, or drop it?
- **#18 Raven** is design fiction (a speculative cybernetics concept), not a
  compiler at all. Included as a stub only so nothing is silently omitted; likely
  belongs on a different blog, or as an explicitly-labelled "off-topic" post.

## Essays

Cross-cutting pieces that read *across* the portfolio rather than documenting one
project — the role of LLVM, of the GC, of Tcl; x86-64 vs arm64; why do any of this
at all. Fully drafted prose (unlike the project stubs), but unpublished and each
still carrying a screenshot-montage TODO.

| Essay | Slug | Theme | Status |
|-------|------|-------|--------|
| Why write compilers | `why-write-compilers` | Manifesto | 🟡 |
| An agent's-eye view of automating an assembler | `agent-eye-view` | Meta / agents | 🟡 |
| The shared substrate: how a language a week was possible | `shared-substrate` | Meta / substrate | 🟡 |
| Don't freeze the runtime: let users write it in the language | `user-editable-runtime` | Language design / runtime | 🟡 |
| A FasterBASIC runtime-module writer's guide | `fasterbasic-runtime-modules` | Guide (FasterBASIC) | 🟡 |
| The role of LLVM in these compilers | `llvm-in-these-compilers` | Backend | 🟡 |
| The role of the GC in these compilers | `gc-in-these-compilers` | Runtime / GC | 🟡 |
| The pain of GC is never the GC | `gc-pain-is-the-interface` | Runtime / GC | 🟡 |
| Two ways to move a heap: handles vs. the scavenger | `handles-vs-scavenger` | Runtime / GC | 🟡 |
| arm64 vs x64, across these compilers | `arm64-vs-x64` | Metal / port | 🟡 |
| The joys of the macro assembler | `macro-assembler` | Metal | 🟡 |
| Two things called JIT: compile-to-memory, and the real thing | `two-jits` | Metal / JIT | 🟡 |
| Text at every stage: the transparent compiler | `text-at-every-stage` | Compiler design | 🟡 |
| Not image-based: source in, running system | `not-image-based` | Compiler design | 🟡 |
| The role of the interpreter | `role-of-the-interpreter` | Compiler design | 🟡 |
| Isolates and VMs: the same conclusion, reached twice | `isolates-and-vms` | Runtime / concurrency | 🟡 |
| The role of Cocoa and the bridge | `cocoa-bridge` | Cocoa bridge | 🟡 |
| Marshalling or a message protocol: two ways to drive Cocoa from a VM | `marshalling-vs-protocol` | Cocoa bridge | 🟡 |
| Windows was already an operating system: Win32 and COM | `win32-and-com` | Windows / platform | 🟡 |
| The role of Tcl for agents | `tcl-for-agents` | Tooling / agents | 🟡 |
| Debuggers, from a brk to the Observatory | `debuggers` | Tooling | 🟡 |
| Test, test, test | `test-test-test` | Practice / testing | 🟡 |
| Little pixel-art games are a serious compiler test | `games-for-compiler-testing` | Practice / testing | 🟡 |

_Fact-check resolved: `arm64-vs-x64`'s "JASM carries both backends" framing is
**correct** — JASM's `a64` AArch64 encoder + macOS `MAP_JIT` loader live in the
`wfasm` that MACVM vendors (`src/vendor/wfasm/a64/`, "the native LLVM-free AArch64
encoder for Apple Silicon"), even though the standalone `E:\JASM` checkout only
tracks the x86-64 side. jasm.md has been reconciled to match._

## Suggested publish order

Not chronological — lead with the strongest, most self-contained stories:

1. **MACDART** or **MACVM** (flagship, most depth, current) — hook the reader.
2. **JASM** → **QBEJIT** (the substrate everything rests on).
3. Then the language families in lineage order, Windows original before Mac port.
4. **cocoa_data** as the connective-tissue piece once a few Cocoa-using
   languages are published.
5. Side pieces (locus, MacGamePane) whenever.
