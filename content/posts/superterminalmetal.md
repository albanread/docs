+++
title = "SuperTerminalMetal — a Metal-rendered terminal / fantasy runner"
date = 2026-01-04
description = "The earliest project in the repo set: a Metal-rendered terminal with a Lua BaseRunner, cartridge model, display, editor and audio subsystems — where the Mac tooling habits started."
[taxonomies]
tags = ["terminal", "metal", "lua", "runtime", "macos"]
[extra]
repo = "https://github.com/albanread/SuperTerminalMetal"
language = "Objective-C++ / C++ + Metal + Lua"
platform = "macOS (Metal)"
status = "Kept as-is — a tool built along the way, pre-dating the compilers"
period = "2026-01"
downloads = []
+++

_Before the compilers, a Metal-rendered terminal with a Lua runner and a
cartridge model — a fantasy-console-ish playground, and in hindsight the
first rehearsal for everything after._

This one is on the blog as **context, not portfolio**: it's a
terminal/runtime rather than a compiler, and by half a year the oldest
thing in the repo set. It stays because the later work makes more sense
with it visible — the Metal habit, the runner-and-cartridge shape, and the
conviction that a programmable machine should boot straight into something
you can type at all start here.

## TL;DR

- **What:** a Metal-rendered terminal with a Lua `BaseRunner`, plus display,
  editor, input, audio and cartridge (`Cart`) subsystems.
- **Why it's here:** the earliest project — where the Metal / Mac tooling
  habit started, months before the first compiler.
- **Get it:** [Downloads](#download-run) · [Source](https://github.com/albanread/SuperTerminalMetal)

## Where it sits

Chronologically first (see the [timeline](/timeline)), and stylistically a
precursor to the Metal/Cocoa GUI work in the later language projects. Not part of
any language lineage.

## What it is

A fantasy console with the serial numbers left on: a terminal whose text is
rendered through **Metal**, hosting a Lua **`BaseRunner`** that loads and
runs **cartridges** (`Cart`) — self-contained programs the way the old
machines meant it — with `Display`, `Editor`, `Input` and `Audio`
subsystems around it. The tree carries its own design notes
(`BaseRunner_Architecture.txt`, `BaseRunner_README.md`), which is a habit
that stuck.

## Why I built it

For the pleasure of a machine that boots into a prompt. The fantasy-console
idea — PICO-8 being the famous one — recovers the thing home computers had
and modern machines mislaid: switch on, get a cursor, type, and the machine
does what you typed, with graphics and sound a keyword away. Building one on
Metal was equal parts homage and apprenticeship: the homage is the
cartridge model; the apprenticeship was learning the Mac's GPU and text
machinery properly, on a project small enough to survive my learning it.

## How it works

- **Metal display + text rendering** — the terminal grid drawn on the GPU.
- **Lua `BaseRunner`** — the host loads a cartridge and runs it against the
  subsystem APIs; the runner owns the lifecycle.
- **Editor / input / audio subsystems** — enough of each that a cartridge is
  a *program*, not a config file.

## What works today

What a 17-commit January experiment should: the subsystems exist and the
shape is complete, and it was left where it stood when the compiler work
began. It is presented here as history, not as a maintained tool — the
ideas moved on into the later projects and kept going.

## Download & run

Prebuilt binaries: the [GitHub Releases page](https://github.com/albanread/SuperTerminalMetal/releases).

```bash
git clone https://github.com/albanread/SuperTerminalMetal
cd SuperTerminalMetal
# build via the included CMakeLists.txt
cmake -B build -S . && cmake --build build
```

## Notes, dead-ends, lessons

- **The rehearsal turned out to be the point.** Metal text rendering
  reappears in the language IDEs; the runner-hosting-cartridges shape
  reappears as VMs hosting programs; the boot-to-a-prompt conviction
  reappears as every REPL and live workspace in the portfolio. None of that
  was planned in January; experiments pay their way in directions you
  don't get to choose.
- Writing the architecture notes *inside the repo* — a small habit begun
  here — is why a six-month-old experiment could still be read, and
  written about, without archaeology.

## Links

- Source: https://github.com/albanread/SuperTerminalMetal
