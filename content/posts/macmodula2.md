+++
title = "MacModula2 — a Modula-2 where a CLASS is an Objective-C object"
date = 2026-06-14
description = "A from-scratch, Mac-native Modula-2 compiler on Rust + LLVM: PIM 4 + ISO 10514-1, JIT-first, with an object model where a Modula-2 CLASS literally is an Objective-C object."
[taxonomies]
tags = ["modula-2", "compiler", "llvm", "rust", "cocoa", "arm64"]
[extra]
repo = "https://github.com/albanread/MacModula2"
language = "Rust + LLVM"
platform = "Apple Silicon (arm64-apple-darwin)"
status = "Working — a large, active compiler"
period = "2026-06 → 2026-07"
downloads = []
+++

_Not a portable Modula-2 that happens to run on a Mac — one that targets Apple
Silicon to the hilt, where your `CLASS` is a real Objective-C class._

## TL;DR

- **What:** a from-scratch **Modula-2** compiler and runtime, PIM 4 + ISO
  10514-1, JIT-first. The toolchain driver is `newm2`.
- **The idea:** a **Cocoa-native object model** — a Modula-2 `CLASS` *is* an
  Objective-C object, so Cocoa/AppKit are first-class, not FFI.
- **Role:** the **progenitor** of the portfolio's Cocoa bridge — the ABI-token
  vocabulary and the "a class is an ObjC class" model originate here.
- **Get it:** [Downloads](#download-run) · [Source](https://github.com/albanread/MacModula2)

## Where it sits

MacModula2 is where the Cocoa-bridge design was born: its `newm2-cocoa-gen`
produced the first `cocoa-selectors.json`, which generalised into the shared
[cocoa_data](/posts/cocoa-data) mirror that later languages all query. See the
[timeline](/timeline).

## What it is

> _From the README —_ "A from-scratch **Modula-2** compiler and runtime
> **specialized for macOS**, on **Rust + LLVM** — PIM 4 + ISO 10514-1,
> JIT-first, with a **Cocoa-native object model**: a Modula-2 `CLASS` *is* an
> Objective-C object. The toolchain driver is `newm2`. This is deliberately
> **Mac-native** Modula-2… one that targets Apple silicon and uses the platform
> to the hilt — the Objective-C runtime, Cocoa / AppKit…"

See also the repo's `MANIFESTO.md`.

## Why I built it

Wirth's languages have always deserved better company than their
implementations kept. Modula-2 on the Mac historically meant a portable
compiler that treated macOS as a file system with a C ABI attached; the
platform's actual riches — the Objective-C runtime, AppKit, the whole
living object system — sat behind an FFI wall, reachable but foreign.

The thesis here was that the wall is optional. The Objective-C runtime is
*open*: classes are created at runtime, methods are C functions with a
known calling shape. So why should a Modula-2 `CLASS` be a private record
that *talks to* ObjC objects, when it could simply **be one**? MacModula2
is the test of that thesis, and the thesis held — well enough that the
approach became the template for every Mac language that followed.

## How it works

- **Front-end:** PIM 4 + ISO 10514-1 Modula-2 → LLVM IR → JIT (`newm2 run`).
- **The object model:** a `CLASS` lowers to `objc_allocateClassPair` +
  `class_addMethod` — the compiled Modula-2 methods are installed **directly
  as IMPs**, because the native calling convention already matches
  `self, _cmd, args…`. No thunks, no proxy objects: the class the runtime
  sees *is* the class you wrote.
- **Per-call-site dispatch:** the compiler synthesises a typed
  `objc_msgSend` cast **per call site** — the selector is known at compile
  time, so the SDK metadata supplies the `@encode` shape and the call is a
  direct, correctly-typed message send. (The "school (a)" style, in the
  taxonomy of [marshalling vs protocol](/posts/marshalling-vs-protocol).)

## What works today

A large, active compiler — 238 commits, a real standard library, and the
breadth is on disk: `demos/`, `cocoademos/` (Cocoa windows built from pure
Modula-2), `library/`, `projects/`. The claim in this article's title is
demonstrated code, not a design sketch.

## Download & run

Prebuilt binaries: the [GitHub Releases page](https://github.com/albanread/MacModula2/releases).

```bash
git clone https://github.com/albanread/MacModula2
cd MacModula2
cargo build --release
# newm2 run <program.mod>
```

## Notes, dead-ends, lessons

- **"Is an object" beats "talks to objects" on every axis that matters.**
  With an FFI layer there are two object systems and a customs post between
  them: marshalling, identity puzzles, inheritance that stops at the border.
  When the language's classes *are* ObjC classes, inheritance from system
  classes just works, the platform's introspection sees your types, and
  delegates/callbacks are ordinary methods. The price — committing to the
  platform — is the price this portfolio pays gladly everywhere.
- **The ABI-token vocabulary outgrew its birthplace.** The per-call-site
  typed-dispatch scheme needed machine-readable knowledge of every
  selector's shape; `newm2-cocoa-gen` built the first
  `cocoa-selectors.json`, and that generalised into
  [cocoa_data](/posts/cocoa-data) — the shared SDK mirror that
  [MF67](/posts/mf67)'s Forth and the rest of the Mac family now query. The
  most valuable output of a language project was, once again, not the
  language.

## Links

- Source: https://github.com/albanread/MacModula2
- Grew into: [cocoa_data](/posts/cocoa-data)
- Kindred Cocoa-native language: [MF67](/posts/mf67)
