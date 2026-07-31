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

- _Modula-2 as a serious, modern systems language on the Mac._
- _Testing the thesis that a language's own classes can just *be* ObjC objects._

## How it works

- **Front-end:** PIM 4 + ISO 10514-1 Modula-2 → LLVM IR → JIT (`newm2 run`).
- **The object model:** _how a `CLASS` is lowered to `objc_allocateClassPair` +
  `class_addMethod`, with compiled methods installed directly as IMPs because the
  ABI already matches `self, _cmd, args…`._
- **Per-call-site dispatch:** the compiler synthesises a typed `objc_msgSend`
  cast **per call site** (selector known at compile time), querying the SDK
  metadata for `@encode` shapes — the "school (a)" marshalling style. _Expand._

## What works today

> _Fill from `demos/`, `cocoademos/`, `library/`, `projects/`. Note the breadth:
> 238 commits, a real standard library, Cocoa demos._

## Screenshots

> _Add to `static/images/macmodula2/`: a Cocoa demo window built from Modula-2;
> `newm2` compiling and running; the REPL/STAT tooling._

![A Cocoa app written in Modula-2](/images/macmodula2/01.png)

## Download & run

Prebuilt binaries: the [GitHub Releases page](https://github.com/albanread/MacModula2/releases).

```bash
git clone https://github.com/albanread/MacModula2
cd MacModula2
cargo build --release
# newm2 run <program.mod>
```

## Notes, dead-ends, lessons

- _Why "a CLASS is an ObjC object" beats an FFI layer for a Mac-native language._
- _How the ABI-token vocabulary invented here became shared infrastructure._

## Links

- Source: https://github.com/albanread/MacModula2
- Grew into: [cocoa_data](/posts/cocoa-data)
- Kindred Cocoa-native language: [MF67](/posts/mf67)
