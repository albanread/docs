+++
title = "Articles"
description = "One article per compiler, JIT, assembler and language runtime in the portfolio — plus the essays that read across them."
sort_by = "date"
page_template = "post.html"
+++

# Articles

Every project in the portfolio. The full list below runs newest first; the
groups here are the reading map. See the [timeline](/timeline) for the order
things were built and how they connect.

**The Snapdragon series (Windows-on-ARM64)** — in reading order:
- [A 2017 JIT meets a 2026 laptop](/posts/windart-arm64) — the bring-up
- [Unified memory is real](/posts/snapdragon-unified-memory) — the Adreno, measured
- [The case of the slow Mandelbrot](/posts/slow-mandelbrot) — a JIT performance mystery
- [Racing the emulator](/posts/racing-the-emulator) — native arm64 vs Prism
- [A Smalltalk world, byte-identical, on a Snapdragon](/posts/smalltalk-on-a-snapdragon)

**The metal — assemblers & JIT substrate**
- [JASM](/posts/jasm) — a JIT macro-assembler for Windows and Apple Silicon
- [WRASM](/posts/wrasm) — JASM's native encoder, grown into a standalone `.exe`-writing assembler
- [MRASM](/posts/mrasm) — the knowledge-rich macro assembler for macOS
- [QBEJIT](/posts/qbejit) — an in-process, W^X-compliant ARM64 JIT on QBE

**The languages**
- [MACDART](/posts/macdart) — Dart 1.24.3 (the last V1) ported to arm64
- [MACVM](/posts/macvm) — Smalltalk from scratch, inspired by Strongtalk
- [WINVM](/posts/winvm) — its Windows x86-64 sibling
- [MacModula2](/posts/macmodula2) — Modula-2 with a Cocoa-native object model
- [NewModula2](/posts/newmodula2) — the canonical Windows Modula-2 it grew from
- [MF67](/posts/mf67) — "Objective Forth", Forth as the Mac's system language
- [MF66](/posts/mf66) — a token-IR optimizing Forth for Apple Silicon
- [WF66](/posts/wf66) — the token-IR Forth these grew out of
- [WF65](/posts/wf65) / [WF64](/posts/wf64) / [wf32](/posts/wf32) — the Forth line back to its 2020 seed
- [NewFactor](/posts/newfactor) — an ANS Forth running on Factor's production VM
- [MacBCPL](/posts/macbcpl) — BCPL on Apple Silicon, JIT and AOT
- [NewBCPL](/posts/newbcpl) — the Windows BCPL JIT it came from
- [MacNCL](/posts/macncl) — Common Lisp on Apple Silicon, with a Cocoa/Metal GUI
- [NCL](/posts/newcl) — the Windows Common Lisp it came from
- [NewCP](/posts/newcp) — Component Pascal, BlackBox, and the birthplace of the shared GUI shell
- [NewFB](/posts/newfb) — FasterBASIC with a retro graphics stack
- [NewBF](/posts/newbf) — Beef: manual memory as a debuggable contract

**The Cocoa bridge**
- [cocoa_data](/posts/cocoa-data) — the shared SQLite mirror of the macOS SDK

**Off to the side**
- [Locus](/posts/locus) — a research language: effects as graded modalities
- [MacGamePane](/posts/macgamepane) — a retro 2D game engine
- [SuperTerminalMetal](/posts/superterminalmetal) — a Metal-rendered terminal, one of the tools built along the way
- [Raven](/posts/raven) — design fiction; an interlude, and clearly labelled as one

**The essays** — the pieces that read *across* the projects (LLVM's role, the
GC's role, arm64 vs x64, testing, agents, why do any of this at all) — are all
in the list below; [Why write compilers](/posts/why-write-compilers) is the
front door.
