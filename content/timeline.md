+++
title = "Timeline"
description = "Every project in the portfolio, in the order it was built, and how each one led to the next."
path = "timeline"
+++

# Timeline

Dates are from each repository's first and last commit. The story runs roughly:
a Metal terminal experiment, then a Windows BCPL JIT, then the assembler that
became the substrate for everything, then one language after another — each new
one reusing the last one's runtime, and each Mac project pushing deeper into
Cocoa and Apple Silicon.

> _Editor's note: this is the skeleton. Expand each row into a sentence or two
> of narrative once the individual articles are written — the timeline should
> read as a story, not just a table._

## At a glance

| Date (first commit) | Project | What it is | Thread |
|---|---|---|---|
| 2026-01-04 | [SuperTerminalMetal](/posts/superterminalmetal) | A Metal-rendered terminal / Lua runner | Side |
| 2026-05-10 | [NewBCPL](/posts/newbcpl) | Modern BCPL, JIT, Windows + Direct2D | BCPL |
| 2026-05-18 | [JASM](/posts/jasm) | JIT macro-assembler (Windows **and** arm64) | Metal |
| 2026-05-30 | [Locus](/posts/locus) | Research language — effects as graded modalities | Research |
| 2026-06-10 | [WF66](/posts/wf66) | Token-IR optimizing Forth (successor to WF65) | Forth |
| 2026-06-14 | [MacModula2](/posts/macmodula2) | From-scratch Modula-2, Cocoa-native objects | Modula-2 |
| 2026-06-15 | [NCL](/posts/newcl) | Corman-Lisp-style Common Lisp, Windows | Lisp |
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

## The lineages

Several projects are explicitly descendants of earlier ones (some of the
ancestors live in other repositories):

- **Assembler:** MASM32-era ergonomics → WRASM (Windows) → **MRASM** (macOS);
  **JASM** is the JIT-focused sibling that both Windows and Apple Silicon share.
- **Forth:** WF32 STC → WF64 → WF65 (JIT via JASM) → **WF66** (token IR) →
  **MF66** (Apple Silicon) → **MF67** (Objective Forth).
- **BCPL:** NBCPL → **NewBCPL** (Windows) → **MacBCPL** (Apple Silicon).
- **Lisp:** Corman Lisp → **NCL** (Windows) → **MacNCL** (Apple Silicon).
- **Smalltalk:** Strongtalk (2002, C++) → **MACVM** (from scratch, Rust + QBEJIT).
- **Dart:** dart-lang/sdk `1.24.3` (last V1 release) → **MACDART** (arm64 JIT, C++).

## The recurring subplots

- **W^X on Apple Silicon.** Every JIT here has to satisfy the same rule: a page
  can't be writable and executable at once. The house solution (MAP_JIT + a
  per-thread toggle, or MAP_JIT + mprotect under the allow-jit entitlement)
  shows up in JASM, QBEJIT, MACVM and MACDART. A single article's worth of
  detail, reused everywhere.
- **Leaving LLVM behind.** The early Windows projects lean on LLVM; the Apple
  Silicon ones increasingly emit arm64 directly through the house assembler.
  That migration is a story in itself.
- **Teaching a language to speak Cocoa.** From MacModula2's "a CLASS *is* an
  Objective-C object" onward, each language finds its own way to make an
  `objc_msgSend` feel native — culminating in the shared `cocoa_data` mirror.
