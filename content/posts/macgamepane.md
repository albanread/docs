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

- _A reusable retro engine to hang games (and language demos) off._
- _Authentic palette/sprite/chiptune model, modern GPU/audio underneath._

## How it works

- **Graphics:** _palette-indexed layers and sprites composited via Metal._
- **Audio:** _chiptune synthesis / playback through AVFoundation._
- **API:** _how a game drives it; the subsystem boundaries (see `graphics/`,
  `audio/`, `objc/`)._

## What works today

> _Fill: the subsystems and their 76 tests; a runnable demo game._

## Screenshots

> _Add to `static/images/macgamepane/`: a sprite/tile scene; the palette in
> action; a demo game frame._

![A palette-indexed sprite scene rendered via Metal](/images/macgamepane/01.png)

## Download & run

Prebuilt binaries / demo: the [GitHub Releases page](https://github.com/albanread/MacGamePane/releases).

```bash
git clone https://github.com/albanread/MacGamePane
cd MacGamePane
cargo build --release
```

## Notes, dead-ends, lessons

- _Modelling custom-silicon-era graphics/audio faithfully on Metal/AVFoundation._
- _"Working port, not hardened library" — what that gap actually contains._

## Links

- Source: https://github.com/albanread/MacGamePane
- A potential front-end: [MF67](/posts/mf67) (Objective Forth)
