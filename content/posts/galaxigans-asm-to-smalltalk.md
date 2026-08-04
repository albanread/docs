+++
title = "Galaxigans — porting 6,000 lines of x64 assembler to Smalltalk"
date = 2026-08-04
description = "A complete Galaxian-style shooter moved from hand-written x64 assembler to Smalltalk on the MACDART workspace — same constants, same dive AI, same shaders, 3.1× less text — and the high-score table persisted as a class in the image."
[taxonomies]
tags = ["smalltalk", "dart", "games", "metal", "assembler", "porting"]
[extra]
repo = "https://github.com/albanread/MACDARTV1"
language = "Smalltalk (on the MACDART Dart 1.24.3 VM)"
platform = "Apple Silicon (arm64-apple-darwin)"
status = "Complete — every gameplay subsystem ported, suite-verified"
period = "2026-08"
downloads = []
+++

_Galaxigans is a Galaxian/Galaga-style fixed shooter I originally wrote in
hand-rolled x64 assembler — 6,251 lines across 35 files, D3D11 underneath. This
is the story of moving the whole game to Smalltalk running on the MACDART
workspace, and what each side of that trade actually costs._

![The Galaxigans title screen: the fleet swaying over the nebula backdrop](/images/macdart/galaxigans-title.png)

## TL;DR

- **The whole game came across**: the swaying formation, the seeded dive AI,
  ten alien species with flap animation, twelve levels with twelve GPU-shader
  backdrops, the bonus saucer and its beating "wah-wah", the spinning mine, the
  capture boss with its tractor beam and pilot abduction, the victory dance,
  four music cues, and the high-score table.
- **It is a faithful port, not a homage.** Every constant comes from the
  original's `data.inc` — grid geometry, timers, speeds, scores — and the dive
  AI is transcribed instruction-for-instruction, so the two games are
  comparable line by line.
- **Honest size**: covering the same subsystems, the assembler is 5,980 lines
  to Smalltalk's 1,923 — **3.1×** overall and 3.1× on code alone. Matched
  subsystems vary: game *logic* compresses about 3×, asset *ceremony* 6–9×.
- **The port was a test campaign in disguise.** Driving it headless found a
  broken `Boolean =` in the ST engine, an image-import path that silently
  destroyed classes, and four missing engine surfaces (HUD text, per-game
  resolution, sprite frames, the per-scanline palette) that every future game
  now gets.
- **The high score is a class in the image.** The game rewrites
  `GxHallOfFame` through the same checked accept the class browser uses, so
  scores are browsable source and survive a full quit-and-relaunch.

## The original

The assembler game runs on a small D3D11 stack: an indexed framebuffer with
per-scanline palettes, an instanced sprite compositor, a text layer, particles,
and a synth. The game itself is 35 `.was` files — formation logic, per-enemy
dive state machines, collision, a boss, art as `BYTE` rows, palettes as
`DWORD` tables, and twelve HLSL scene functions for the backdrops.

MACDART's game pane happens to mirror that stack almost exactly — Metal instead
of D3D11, but the same layers: shader background, indexed pane with per-line
palettes, sprites, text overlay, synth. The port is therefore a fair experiment:
**same machine underneath, same game on top, only the language changes.**

## The discipline: numbers first

The porting rule was that every constant comes from the original's own
`galaxigans_data.inc`, so behaviour is comparable rather than "inspired":

```smalltalk
Galaxigans class >> colGap [ ^56 ]      "COL_GAP  equ 56"
Galaxigans class >> rowGap [ ^34 ]      "ROW_GAP  equ 34"
Galaxigans class >> divePeriod [ ^60 ]  "DIVE_PERIOD equ 60"
Galaxigans class >> saucerPeriod [ ^420 ]
```

The dive AI is the heart of Galaga and the most interesting transcription. In
the original, each dive gets a random seed whose *bits are the flight plan* —
weave speed, phase, amplitude, plus a "fast" bit and a "hard homing" bit. The
assembler:

```asm
; vy = 2 + dt/4, cap 8 (or 10 when the 'fast' bit is set)
mov     ecx, [rdi + EN_DT]
shr     ecx, 2
add     ecx, 2
test    eax, 0x80
...
; weave velocity = sineLUT[(dt*wspeed + phase) & 255] * wamp >> 8
```

The Smalltalk, same arithmetic, same integer sine table:

```smalltalk
diveStep: playerX height: fieldH [
    | vy weave amp speed phase pull |
    dt := dt + 1.
    vy := 2 + (dt // 4).
    vy := vy min: ((seed bitAnd: 128) = 0 ifTrue: [ 8 ] ifFalse: [ 10 ]).
    y := y + vy.
    speed := ((seed bitShift: -3) bitAnd: 7) + 3.
    phase := ((seed bitShift: -8) bitAnd: 255).
    amp := (seed bitAnd: 7) + 2.
    weave := (Galaxigans sineAt: dt * speed + phase) * amp // 256.
    dt >= 12 ifTrue: [
        pull := (seed bitAnd: 64) = 0 ifTrue: [ 1 ] ifFalse: [ 3 ].
        weave := x < playerX ifTrue: [ weave + pull ] ifFalse: [ weave - pull ] ].
    x := x + weave.
    ...
```

That method is 22 lines. The assembler's `FormationStep` walk that contains the
same logic is 130. Nothing clever happened — the ratio is what naming your
variables and not spelling out register allocation buys you.

## Art is data on both sides

The original's creatures are `BYTE` rows of hex digits — which is,
character-for-character, the format the pane's `defineSprite:` takes. Ten
species, two flap frames each, and their palettes (documented as comment blocks
above each table) came across **mechanically**, via a small extractor, not by
redrawing:

```
gruntArt   BYTE "................"        →   '................/..A........A....
           BYTE "..A........A...."             /...1......1...../....122222....
           BYTE "...1......1....."             ...'
```

The same held for the boss's four poses, the mine's eight rotation frames, and
the pilot figure. Where the assembler then spends 297 lines of `lea / mov /
call` per-frame registration ceremony (`BuildSprAssets`), the Smalltalk spends
33 — this is where the big ratios live.

## Twelve skies

Each level picks one of twelve GPU-shader backdrops — nebula, galaxy, black
hole, alien world, moon, supernova, wormhole, gas giant, aurora, pulsar,
plasma, binary stars. The originals are HLSL scene functions; the pane compiles
Metal at runtime, so they were translated with the same maths and constants —
`frac`→`fract`, `lerp`→`mix`, and the hardcoded 16:9 aspect read from a uniform
instead. All twelve compiled offline with `xcrun metal` before ever reaching
the engine.

![Level 3: the black-hole backdrop, with the accretion disk swirling behind the fleet](/images/macdart/galaxigans-lv3.png)

![Level 8: the ringed gas giant](/images/macdart/galaxigans-lv8.png)

## The sounds are physics, and they are tested

The saucer's classic "wah-wah" is not a tremolo: it is two sine oscillators a
few hertz apart, and the *beat between them* is the pulse — the detune **is**
the wah rate. The original bakes exactly that (280 Hz + 5 Hz); the pane's synth
gained the same recipe as `preset_wah`, plus its low sibling for the boss hum
(110 Hz + 4 Hz).

Because the synth is pure C++, this is *testable as sound*: a unit test renders
the preset, extracts the amplitude envelope, and counts beats — 4–5 in 0.9
seconds, doubling the detune must double the count, and a plain tone must count
zero. That last check is the one that proves the pulsing is interference and
not an artifact of the envelope generator.

The four melodic cues came across note-for-note from the original's inline ABC
— including "Alien Victory", the square-lead triumph in C minor the aliens
dance to when they take your last ship. The wire test reads the *compiled MIDI*
and asserts the dance emits a program change to GM 80: right notes on the wrong
instrument would otherwise pass silently.

## The boss, and the copper-bar beam

The capture boss is the original's best subsystem: it comes for your *pilots*,
not your ship. It enters, stations, descends, charges, and fires a tractor
beam down into the row of lives; a pilot rises up the beam, and if you shoot
the boss first the pilot falls home, saved. It refuses to appear at all when
you are down to your last pilot — the original's own rule, and the right one.

![The boss over the black hole, tractor beam down into the pilot row, a pilot halfway up it](/images/macdart/galaxigans-gx-boss.png)

The beam is drawn **once** per frame as a cone in palette index 1 — and it
*flows* because index 1 means something different on every scanline. Rewriting
the per-line palette each frame scrolls the energy bands down the beam without
touching a single pixel: the copper-bar trick, exactly as the original's
`BeamCascade` does it. The port exposed that the Smalltalk `GamePane` had never
been given the per-line palette; one wire verb later
(`linePaletteAt:index:r:g:b:`), every future Smalltalk game has copper bars.

## The victory dance

When the aliens win, the survivors leave formation and orbit the centre of the
field on a pinwheel whose radius breathes at half the angular rate. Integer
sines throughout — the same 256-entry table the dive weave uses — so the dance
is exactly reproducible, and *asserted headless*: mean distance from home slots
is 0 in formation, over 100 mid-dance, and a **different** number ninety frames
later. A dance that froze would pass a "did they move" check; it cannot pass
the breathing check.

![The triumphal dance: the surviving fleet pinwheeling around the game-over card](/images/macdart/galaxigans-gx-dance.png)

## The hall of fame is a class in the image

The last subsystem is where the port stops translating and starts speaking its
own language. The original keeps six high-score rows in `.DATA` and loses them
at exit. Here, the table is a **class in the image**:

```smalltalk
Object subclass: GxHallOfFame [
    GxHallOfFame class >> table [
        ^#( #('ACE' 30000) #('ZAP' 22000) #('BUG' 16000)
            #('YOU' 12345) #('FOE' 11000) #('POW' 7000) )
    ]
]
```

When your score makes the table, the game *rewrites that class* through
`STHostService acceptEditorClass:` — the same parse-checked, image-persisted,
hot-reloading accept the class browser's own button uses. The consequences are
exactly the Smalltalk pitch, made concrete in a game:

- your scores are **source** — open `GxHallOfFame` in the browser and edit them;
- they **survive a full quit-and-relaunch**, because the image is the source of
  truth (verified: earn a score, quit the app, reboot it, the table answers);
- re-filing the game from the Games menu cannot clobber them, because the hall
  deliberately lives outside the game's own file.

There is one dragon, documented rather than hidden: the accept hot-reloads the
image, which replaces the *running game's own class mid-frame*. The instance
survives by morph — the game keeps playing through its own reload — but class
variables reset, so the game re-registers its handle after each save. Watching
a game hot-reload itself as a side effect of saving your high score is the
most Smalltalk thing in the whole project.

![The hall of fame: YOU at row four in blinking gold](/images/macdart/galaxigans-gx-hall.png)

## What the port found

Driving a complete game through the engine was a better test campaign than any
test campaign. In the ST engine and workspace it found, among others:

- **`false = anything` threw.** Boolean equality worked only for `true = true`
  (the identity fast path); every other pair fell through to a dispatch a Dart
  `bool` has no method for. Any comparison of a *computed* Boolean raised
  instead of answering false. Found by a game test asserting `lives < before`;
  fixed in the equality fast path and locked into the feature suites.
- **A single-file image import destroyed classes.** Importing an overlay file
  that merely *reopens* a class replaced that class's whole stored declaration
  — importing the game-pane wiring alone deleted `defineSprite:` from
  `GamePane`. Reopen-only imports now extend the stored source.
- **Images went silently stale.** The world-freshness check lived in only one
  of the two launchers; the language isolate now compares the vendored world's
  signature at boot and re-imports, announcing it in the transcript.
- **Four missing engine surfaces**, each now a permanent capability: real HUD
  text (a 5×7 atlas replacing seven-segment-digits-and-boxes), per-game pane
  resolution declared by the game class, multi-frame sprites with `hide`, and
  the per-scanline palette.

## The honest numbers

Same classifier over both sides (code / comment / data split, `.ASCIISTRING`
and `BYTE` art counted as data on the assembler side, art and shader methods
as data on the Smalltalk side), covering the same subsystems:

| | assembler | Smalltalk | ratio |
|---|--:|--:|--:|
| total lines | 5,980 | 1,923 | **3.1×** |
| code | 3,335 | 1,088 | 3.1× |
| comments | 680 | 347 | 2.0× |
| data (art, tables, shaders) | 1,707 | 333 | 5.1× |

Matched subsystems spread wider than the average: the dive AI is 130 → 22
(5.9×), asset registration 297 → 33 (9×), while dense state machines like the
boss run nearer 2×. An earlier core-only measurement said 4.6× — the ratio
*fell* as the port grew, because the late subsystems are logic-heavy and logic
is where assembler is least penalised.

Caveats I would insist on if I were reading this: the data ratio is partly
formatting (one string per sprite vs one `BYTE` line per row — same content);
and the Smalltalk stands on a 97-file world image as its runtime where the
assembler stands on the CPU. No line count captures that asymmetry; the fair
statement is that the *game-shaped* text shrank 3×, and the ceremony shrank
most.

## What I actually think

The assembler version was never about practicality — it exists to prove the
GPU stack and because writing a game in assembler is its own pleasure. But the
port settled something for me: the Smalltalk version is not just shorter, it
is **testable in a way the assembler version never was**. The whole game —
attract, dives, collisions, the boss lifecycle, the dance, the hall insert —
runs headless with every pane primitive a no-op, deterministic under a seeded
RNG, asserted in a battery tier that fails the build if a diver stops weaving.
The assembler game is verified by a filmstrip you look at. The Smalltalk game
is verified by forty-odd assertions a machine checks on every push — and the
port itself is what forced the engine to grow the seams that make that
possible.
