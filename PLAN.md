# Editorial plan

The through-line: **a personal history of building compilers, JITs, assemblers
and language runtimes — moving from Windows + LLVM to LLVM-free, self-contained
tools native to Apple Silicon, and then bringing the strongest line back to
Windows-on-ARM.** Each article stands alone, but read in order they tell one
story: build an assembler → build a JIT on top → use both to bring a language
up → learn to drive Cocoa from that language → repeat for the next language,
each time deeper into the Mac — until the two constants of the portfolio,
Windows and arm64, converge on a Snapdragon.

_Status note (2026-08-13): every article below is live on the site. The
editorial sweep of 2026-08-13 resolved all stub markers — the "Why I built
it" / "What works" / lessons sections are written, empty screenshot sections
were removed, and the two "decide" items below are decided. The remaining
depth differences are noted per row._

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

Legend: ✅ published, full depth · ◐ published, concise (filled from the
grounded record in the 2026-08-13 sweep; will deepen when its repo is next
open on a machine)

| # | Article | Slug | Thread | Stack | Period | Status |
|---|---------|------|--------|-------|--------|--------|
| 1 | JASM — JIT macro-assembler | `jasm` | Metal | Rust | 2026-05→06 | ◐ |
| 2 | MRASM — knowledge-rich assembler | `mrasm` | Metal | Rust | 2026-06→07 | ◐ |
| 3 | QBEJIT — W^X ARM64 JIT on QBE | `qbejit` | Metal | Zig + Rust | 2026-07 | ◐ |
| 4 | NewBCPL — BCPL JIT (Windows) | `newbcpl` | Language / Win | Rust + LLVM | 2026-05 | ◐ |
| 5 | MacBCPL — BCPL on Apple Silicon | `macbcpl` | Language / Port | Rust + LLVM | 2026-06→07 | ◐ |
| 6 | NCL — Common Lisp (Windows) | `newcl` | Language / Win | Rust + LLVM | 2026-05→07 | ◐ |
| 7 | MacNCL — Lisp on Apple Silicon | `macncl` | Language / Port | Rust + LLVM | 2026-06 | ◐ |
| 8 | MacModula2 — Cocoa-native Modula-2 | `macmodula2` | Language / Cocoa | Rust + LLVM | 2026-06→07 | ◐ |
| 9 | WF66 — token-IR Forth | `wf66` | Language / Forth | Rust | 2026-06 | ✅ |
| 10 | MF66 — Apple Silicon Forth | `mf66` | Language / Forth | Rust | 2026-06 | ✅ |
| 11 | MF67 — Objective Forth | `mf67` | Language / Cocoa | Rust | 2026-06→07 | ✅ |
| 12 | MACVM — Smalltalk from scratch | `macvm` | Language / Flagship | Rust (own compiler + assembler) | 2026-07 | ◐ |
| 13 | MACDART — Dart V1 on arm64 | `macdart` | Language / Flagship | C++ | 2026-07→ | ◐ |
| 14 | cocoa_data — the SDK mirror | `cocoa-data` | Cocoa bridge | Python + SQLite | 2026-06→07 | ◐ |
| 15 | MacGamePane — retro game engine | `macgamepane` | Side | Rust + Metal | 2026-07 | ◐ |
| 16 | Locus — effects as modalities | `locus` | Side / Research | Rust + LLVM | 2026-05→06 | ◐ |
| 17 | SuperTerminalMetal — Metal terminal | `superterminalmetal` | Side (draft) | ObjC/C++ + Metal | 2026-01 | ◐ |
| 18 | Raven — design fiction | `raven` | Not a compiler | — | 2026-07 | ◐ |
| 19 | NewCP — Component Pascal / BlackBox (Windows) | `newcp` | Language / Win | Rust + LLVM | 2026-05 | ◐ |
| 20 | WF64 — 64-bit STC Forth (Windows) | `wf64` | Language / Forth | Rust + LLVM | 2026-05→06 | ✅ |
| 21 | WF65 — STC Forth, native encoder | `wf65` | Language / Forth | Rust | 2026-06 | ✅ |
| 22 | WRASM — x86-64 assembler (Windows) | `wrasm` | Metal | Rust | 2026-06→07 | ◐ |
| 23 | Windows Modula-2 (NewModula2) | `newmodula2` | Language / Win | Rust + LLVM | 2026-06 | ◐ |
| 24 | NewFB — FasterBASIC (Windows) | `newfb` | Language / Win | Rust + LLVM | 2026-05→07 | ◐ |
| 25 | NewBF — Beef (Windows) | `newbf` | Language / Win | Rust + LLVM | 2026-05→07 | ◐ |
| 26 | NewFactor — Forth on Factor's VM | `newfactor` | Language / Forth | Rust + Factor | 2026-05→06 | ◐ |
| 27 | WINVM — Windows Smalltalk, sibling of MACVM | `winvm` | Language / Win | Rust (own compiler + assembler) | 2026-07→08 | ◐ |
| 28 | WF32 — the adopted seed, reviewed (Alex McDonald's, not mine) | `wf32` | Language / Forth | Forth (self-hosting) | 2005→2017 | ✅ |

**Decisions taken (2026-08-13):**

- **#17 SuperTerminalMetal** — kept, as a "tools I built along the way" piece:
  it is the chronological start of the Mac tooling habits and the later work
  reads better with it visible. The article now says so.
- **#18 Raven** — kept, as an explicitly-labelled design-fiction interlude.
  The label is carried in its title, status line and body; nothing about it
  can be mistaken for shipping engineering. Publishing the odd one out beats
  silently omitting it.

## The Snapdragon series (Act III)

Added 2026-08-13 — the WINDARTTALK Windows-on-ARM64 port, five posts in
reading order, all ✅ with screenshots and figures:

| Article | Slug | Date |
|---|---|---|
| A 2017 JIT meets a 2026 laptop | `windart-arm64` | 2026-08-11 |
| Unified memory is real — we measured it | `snapdragon-unified-memory` | 2026-08-12 |
| The case of the slow Mandelbrot | `slow-mandelbrot` | 2026-08-13 |
| Racing the emulator | `racing-the-emulator` | 2026-08-13 |
| A Smalltalk world, byte-identical, on a Snapdragon | `smalltalk-on-a-snapdragon` | 2026-08-13 |

## Essays

Cross-cutting pieces that read *across* the portfolio rather than documenting one
project — the role of LLVM, of the GC, of Tcl; x86-64 vs arm64; why do any of this
at all. All fully drafted and live on the site.

| Essay | Slug | Theme | Status |
|-------|------|-------|--------|
| Why write compilers | `why-write-compilers` | Manifesto | ✅ |
| Why Smalltalk — and how we ended up with two, or several | `why-smalltalk` | History / Smalltalk | ✅ |
| An agent's-eye view of automating an assembler | `agent-eye-view` | Meta / agents | ✅ |
| The shared substrate: how a language a week was possible | `shared-substrate` | Meta / substrate | ✅ |
| Don't freeze the runtime: let users write it in the language | `user-editable-runtime` | Language design / runtime | ✅ |
| A FasterBASIC runtime-module writer's guide | `fasterbasic-runtime-modules` | Guide (FasterBASIC) | ✅ |
| The role of LLVM in these compilers | `llvm-in-these-compilers` | Backend | ✅ |
| The role of the GC in these compilers | `gc-in-these-compilers` | Runtime / GC | ✅ |
| The pain of GC is never the GC | `gc-pain-is-the-interface` | Runtime / GC | ✅ |
| Two ways to move a heap: handles vs. the scavenger | `handles-vs-scavenger` | Runtime / GC | ✅ |
| arm64 vs x64, across these compilers | `arm64-vs-x64` | Metal / port | ✅ |
| The joys of the macro assembler | `macro-assembler` | Metal | ✅ |
| Two things called JIT: compile-to-memory, and the real thing | `two-jits` | Metal / JIT | ✅ |
| Text at every stage: the transparent compiler | `text-at-every-stage` | Compiler design | ✅ |
| Not image-based: source in, running system | `not-image-based` | Compiler design | ✅ |
| The role of the interpreter | `role-of-the-interpreter` | Compiler design | ✅ |
| Isolates and VMs: the same conclusion, reached twice | `isolates-and-vms` | Runtime / concurrency | ✅ |
| The role of Cocoa and the bridge | `cocoa-bridge` | Cocoa bridge | ✅ |
| Marshalling or a message protocol: two ways to drive Cocoa from a VM | `marshalling-vs-protocol` | Cocoa bridge | ✅ |
| Windows was already an operating system: Win32 and COM | `win32-and-com` | Windows / platform | ✅ |
| The role of Tcl for agents | `tcl-for-agents` | Tooling / agents | ✅ |
| Debuggers, from a brk to the Observatory | `debuggers` | Tooling | ✅ |
| Test, test, test | `test-test-test` | Practice / testing | ✅ |
| Little pixel-art games are a serious compiler test | `games-for-compiler-testing` | Practice / testing | ✅ |

_Fact-check resolved: `arm64-vs-x64`'s "JASM carries both backends" framing is
**correct** — JASM's `a64` AArch64 encoder + macOS `MAP_JIT` loader live in the
`wfasm` that MACVM vendors (`src/vendor/wfasm/a64/`, "the native LLVM-free AArch64
encoder for Apple Silicon"), even though the standalone `E:\JASM` checkout only
tracks the x86-64 side. jasm.md has been reconciled to match._

## Reading order (the publish-order question is settled — everything is live)

For a new reader, lead with the strongest, most self-contained stories:

1. **The Snapdragon series** (`windart-arm64` →) — current, complete, and
   carries the whole method: measurement, honesty, agents, games.
2. **MACDART** and **MACVM** (the flagships) — then **why-smalltalk** for the
   forty-year backstory.
3. **JASM** → **WRASM/MRASM** → **QBEJIT** (the substrate everything rests on).
4. The language families in lineage order, Windows original before Mac port;
   **cocoa_data** as the connective tissue.
5. The essays as the mood takes you; `why-write-compilers` is the front door.
