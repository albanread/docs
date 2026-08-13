+++
title = "MacGamePane — a retro 2D game engine, Metal and AVFoundation underneath"
date = 2026-07-05
description = "A reusable macOS component for building 1980s-90s-style games: layered, palette-indexed, sprite-driven, chiptune-scored — running today through Metal and AVFoundation instead of custom silicon."
[taxonomies]
tags = ["game-engine", "graphics", "audio", "metal", "avfoundation", "rust", "macos"]
[extra]
repo = "https://github.com/albanread/MacGamePane"
language = "Rust"
platform = "macOS (Metal + AVFoundation)"
status = "Working port — not yet a hardened library"
period = "2026-07"
downloads = []
+++

_The layered, palette-indexed, sprite-and-chiptune engine of a 1980s home
computer — rebuilt on Metal and AVFoundation._

## TL;DR

- **What:** a retro-2D-game **audio + graphics engine** for macOS, in Rust — a
  reusable component for building 2D retro-style games.
- **The aesthetic:** layered, **palette-indexed**, sprite-driven, chiptune-scored
  — the kind of engine that powered 1980s-90s home computers and consoles, now
  through **Metal** and **AVFoundation** instead of custom silicon.
- **Status:** a quick, working port — every subsystem real and tested (76 tests),
  but not yet polished/hardened.
- **Get it:** [Downloads](#download-run) · [Source](https://github.com/albanread/MacGamePane)

## Where it sits

MacGamePane is a **component**, not a language — the graphics/audio substrate a
game (or a Cocoa-driving language like [MF67](/posts/mf67)) can build on. See the
[timeline](/timeline).

## What it is

> _From the README —_ "A retro-2D-game audio + graphics engine for macOS, in Rust
> — a reusable component for building 2D retro-style games: the kind of layered,
> palette-indexed, sprite-driven, chiptune-scored engine that powered 1980s-1990s
> home computers and consoles, running today through Metal and AVFoundation."

## Why I built it

Half the projects in this portfolio end up wanting the same thing: a pane
that draws sprites over layers and goes *bleep* convincingly. Games are the
house test workload — they exercise a compiler's codegen, GC, FFI and
timing all at once, and they're the demos people actually enjoy — so the
engine deserved to be a component built once, not re-improvised per
language.

And the old model is worth preserving *on its merits*. The 8-bit and 16-bit
machines' graphics architecture — indexed palettes, layers, hardware
sprites, a chiptune channel or three — wasn't a limitation to escape; it
was a remarkably good abstraction for 2D games, arrived at under pressure
and refined across a decade of custom silicon. Keeping that model alive on
a modern GPU is the same instinct as keeping the languages alive: the
design knowledge is the artifact.

## How it works

- **Graphics:** palette-indexed layers and sprites, composited through
  **Metal** — the palette that was once a DAC lookup is now a texture
  lookup, and the layers that were once scanline hardware are draw passes.
  Same model, different silicon.
- **Audio:** chiptune-style synthesis and playback through **AVFoundation**.
- **API:** a game drives the engine through the subsystem boundaries visible
  in the tree — `graphics/`, `audio/`, and an `objc/` layer for the
  platform plumbing — designed so a language runtime (an
  [MF67](/posts/mf67) Forth, say) can sit in front of it as easily as a
  Rust program.

## What works today

Every subsystem is real and tested — **76 tests** across the engine — but
the honest label is the one in the status line: a quick, *working* port,
not yet a hardened library. It draws, it sounds, it's exercised; what it
lacks is the boring armour (API stability promises, hostile-input paths,
documentation) that separates "works for its author" from "works for
strangers."

## Download & run

Prebuilt binaries / demo: the [GitHub Releases page](https://github.com/albanread/MacGamePane/releases).

```bash
git clone https://github.com/albanread/MacGamePane
cd MacGamePane
cargo build --release
```

## Notes, dead-ends, lessons

- **The old hardware was already a rendering pipeline.** Palettes, layers
  and sprites map onto a modern GPU with almost embarrassing directness —
  the palette is a lookup the fragment stage performs, layers are ordered
  passes, sprites are instanced quads. The custom silicon's designers had
  found the right decomposition; Metal just runs it faster than the
  scanline ever allowed.
- **"Working port, not hardened library" is a real category and worth
  naming.** The gap isn't features — it's API stability you'd promise a
  stranger, error paths for inputs you didn't write, and documentation.
  Calling a component *done* before that work is how ecosystems fill with
  libraries that work only in their author's repos; better to label the
  shelf honestly.

## Links

- Source: https://github.com/albanread/MacGamePane
- A potential front-end: [MF67](/posts/mf67) (Objective Forth)
