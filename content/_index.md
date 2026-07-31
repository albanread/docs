+++
title = "Building Compilers for Apple Silicon"
description = "A personal series on from-scratch compilers, JITs, assemblers and language runtimes for macOS arm64 — with the executables to download."
+++

# Building Compilers for Apple Silicon

I build compilers, JITs and language runtimes from scratch. Over the last year
that turned into a whole portfolio of them — an assembler, a couple of JIT
back-ends, and then one language after another brought up on top: Forth, BCPL,
Lisp, Modula-2, Smalltalk, Dart. Most run **natively on Apple Silicon**, drive
**Cocoa** directly, and were built **without LLVM** in the hot path.

This blog is one article per project. Each one explains what it is, why it
exists, how it works, and — where the binary is ready — lets you **download and
run it yourself**.

Start with:

- **[The timeline](/timeline)** — how the projects connect, in order.
- **[About this portfolio](/about)** — the thesis behind all of it.
- **[All articles](/posts)** — the full list.

Newest and most substantial first: the [Smalltalk VM](/posts/macvm) and the
[Dart V1 port](/posts/macdart). The foundations everything else stands on: the
[JASM assembler](/posts/jasm) and the [QBEJIT back-end](/posts/qbejit).
