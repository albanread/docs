+++
title = "SuperTerminalMetal — a Metal-rendered terminal / fantasy runner"
date = 2026-01-04
description = "The earliest project in the repo set: a Metal-rendered terminal with a Lua BaseRunner, cartridge model, display, editor and audio subsystems."
[taxonomies]
tags = ["terminal", "metal", "lua", "runtime", "macos"]
[extra]
repo = "https://github.com/albanread/SuperTerminalMetal"
language = "Objective-C++ / C++ + Metal + Lua"
platform = "macOS (Metal)"
status = "Draft article — decide whether this belongs on the blog"
period = "2026-01"
downloads = []
+++

> **Editorial note.** SuperTerminalMetal is a terminal/runtime rather than a
> compiler, and it's the oldest thing in the repo set (January 2026). It's
> included here as a **"tools I built along the way"** candidate — keep it as
> context for the later work, or drop it. Decide before publishing.

_Before the compilers, a Metal-rendered terminal with a Lua runner and a
cartridge model — a fantasy-console-ish playground._

## TL;DR

- **What:** a Metal-rendered terminal with a Lua `BaseRunner`, plus display,
  editor, input, audio and cartridge (`Cart`) subsystems.
- **Why it's here:** the earliest project — useful as the "where the Metal / Mac
  tooling habit started" backstory, if you want it.
- **Get it:** [Downloads](#download-run) · [Source](https://github.com/albanread/SuperTerminalMetal)

## Where it sits

Chronologically first (see the [timeline](/timeline)), and stylistically a
precursor to the Metal/Cocoa GUI work in the later language projects. Not part of
any language lineage.

## What it is

> _Fill in your own words. From the tree: `BaseRunner.mm` / `LuaBaseRunner.mm`, a
> `Cart` cartridge model, `Display`, `Editor`, `Input`, `Audio`, and
> `BaseRunner_Architecture.txt` / `BaseRunner_README.md`._

## Why I built it

- _A Metal-rendered terminal / fantasy-console experiment._
- _Where the Metal + macOS tooling that later projects reuse got started._

## How it works

- **Metal display + text rendering.**
- **Lua BaseRunner:** _how cartridges are loaded and run._
- _Editor / input / audio subsystems._

## What works today

> _Fill from the repo (17 commits). A short demo GIF would carry this one._

## Screenshots

> _Add to `static/images/superterminalmetal/`: the terminal running a Lua
> cartridge; the editor; a Metal text-rendering close-up._

![SuperTerminalMetal running a Lua cartridge](/images/superterminalmetal/01.png)

## Download & run

Prebuilt binaries: the [GitHub Releases page](https://github.com/albanread/SuperTerminalMetal/releases).

```bash
git clone https://github.com/albanread/SuperTerminalMetal
cd SuperTerminalMetal
# build via the included CMakeLists.txt
cmake -B build -S . && cmake --build build
```

## Notes, dead-ends, lessons

- _What this experiment taught you that fed the compiler work._

## Links

- Source: https://github.com/albanread/SuperTerminalMetal
