+++
title = "Little pixel-art games are a serious compiler test"
date = 2026-07-31
description = "I like little pixel-art games, and I have an excuse that happens to be true: a game at 60fps is a compiler stress test with a stopwatch. Sixteen milliseconds a frame to run the logic, move a river of sprite memory, and make sound — forever, without a stutter. And the audio is the sharpest oracle of all: port the ABC-notation player to each language and a bug doesn't just fail a diff, it sounds wrong."
[taxonomies]
tags = ["games", "testing", "graphics", "audio", "retro", "metal", "performance"]
+++

_I like little pixel-art games. I also have a justification for putting a whole
retro engine in every one of these compilers' standard libraries, and it isn't a
rationalization — it's the best excuse there is. A game running at sixty frames a
second is a compiler stress test with a hard deadline: the generated code has
sixteen milliseconds to do everything, and if it doesn't, you see it, and you hear
it. Nothing in a unit-test suite pushes a compiler like a loop that must not miss a
frame, forever._

## TL;DR

- **60fps is a 16 ms deadline**, held continuously. It surfaces exactly the
  problems static tests hide: codegen that's too slow, a **GC pause you see as a
  stutter**, a JIT still warming up.
- **Sprites are memory movement.** "Virtually unlimited sprites" means a river of
  fast blitting — a direct, relentless test of the codegen's hot loops (and its
  SIMD).
- **A game uses the *whole* language and platform at once** — graphics, input,
  sound, timing, the object model, and the **Metal / DirectX** binding — so it's the
  ultimate whole-program test.
- **Audio is the sharpest oracle.** Port the **ABC-notation player** to each
  language: it's objectively diffable (same tune → same MIDI → same samples) *and*
  audibly wrong the instant there's a bug.
- The fun is a feature: **a test you enjoy is a test you actually run.**

## The sixteen-millisecond deadline

A game is a soak test with a stopwatch. Sixty frames a second gives the generated
code **16 ms** to run the game logic, composite the screen, and drive the sound
before the frame is late — and a late frame isn't a silent failure, it's a visible
hitch. That deadline, held for an hour, stresses things no assertion reaches:

- **Codegen throughput.** Is the code the compiler produced *actually fast enough*
  to do real work in real time? A benchmark answers this once; a game answers it
  every 16 ms, under a changing, realistic load.
- **The garbage collector, made visible.** This is the one I love most. A
  collection that blows the frame budget shows up as a **stutter you can see**, and
  a game loop that allocates per frame will find your GC's worst-case pause faster
  than any [heap-walk test](/posts/gc-pain-is-the-interface). The game turns an
  invisible latency bug into a perceptible one — the pause you'd never notice in a
  batch job is a jerk in the scrolling.
- **The JIT, warming up in public.** A [real adaptive JIT](/posts/two-jits) is slow
  for the first frames until the hot methods tier up and the game loop gets its
  on-stack replacement; a game is a live demonstration of warmup, tier-up, and — if
  you've got a bug — a deopt storm you'll *feel* as the framerate sagging. There's
  no better place to watch a JIT behave than a loop that runs sixty times a second.

## Pixel art, palette-indexed, sprites without limit

The graphics are deliberately old-fashioned, and every project here has some
version of the same retro library — MacGamePane in Rust, its ancestors in
Modula-2 and in the C++/Obj-C++ of SuperTerminalMetal, the pixel engine MACVM's
Smalltalk games draw on. The common shape is the classic one: a **palette-indexed
framebuffer**, several **layers**, **per-scanline palette tricks** (change the
palette mid-screen for gradients and raster effects, the way the hardware used to),
**tilemaps**, and a **sprite layer** — all composited and handed to **Metal** on
Apple Silicon or **DirectX / D3D11** on Windows.

What I enjoy most is the *virtually unlimited sprites*, and that enjoyment is also
the test. Real retro hardware capped sprites because each one cost dedicated
silicon; on a modern CPU a sprite is just "move these bits of memory into that
frame, fast" — a blit. So unlimited sprites means an unlimited **river of memory
movement**, and pushing thousands of them is a continuous, brutal test of exactly
the code a compiler most needs to get right: tight inner loops, palette lookups,
compositing, bounds math, cache behavior. It's the code that lives or dies on good
register allocation and [SIMD](/posts/arm64-vs-x64) — the same NEON paths the
[interpreter essay](/posts/role-of-the-interpreter) added to QBE — and a game
exercises them harder, and more realistically, than any microbenchmark. And because
it all flows through Metal or DirectX, the game is simultaneously a 60 Hz stress
test of the [Cocoa](/posts/cocoa-bridge) / [Win32-COM](/posts/win32-and-com)
binding.

## Sound: the ABC player, an oracle you can hear

Here is the part I think is genuinely clever, and it's the audio. Every language
gets a port of the **ABC-notation music player** (plus MIDI) — it exists as
`abc_player.mod` in Modula-2, as MACVM's `abc_player`, as MacGamePane's `abc`
module — and it is one of the best single tests I know, for two reasons that don't
usually come together.

First, it's **objectively comparable.** An ABC parser is real, meaty work — key-
signature-aware accidentals with bar-scoped overrides, fractional and dotted
durations, ties, broken rhythm, tuplets, chords, repeats, multi-voice tunes —
"compiled down to a flat, time-sorted list of MIDI events with absolute millisecond
timestamps." That means the same tune, fed to any correct port, must produce the
*same MIDI events at the same timestamps*. And since the synth is fully
deterministic (its own seeded RNG, no hidden global state), you can render to a
`.wav` or write a Standard MIDI File and **diff it, byte for byte, against another
language's version or a reference.** It's a [differential
oracle](/posts/llvm-in-these-compilers), but for a whole subsystem: a wrong note is
a non-empty diff.

Second — and this is the magic — it's **subjectively unforgiving. It just sounds
wrong.** A one-tick timing error, a rounding bug in a duration, a mishandled
accidental, an envelope that releases a hair too early: you would scroll right past
all of these in a data dump, and you cannot miss a single one of them with your
ears. Press play and a bug announces itself instantly as a flat note, a dragging
rhythm, a detuned voice, a click. Your ear is a correctness oracle with zero setup
and a false-negative rate near zero for exactly the class of arithmetic-and-timing
bug compilers love to introduce. Porting the ABC player to a new language and
having it *sound right* is a stronger statement than a page of green assertions —
because the assertions test what you thought to check, and the music tests
everything at once.

## Port the same game everywhere

There's a cross-language bonus that falls straight out of this. The retro library
was, by the README's own account, "built three separate times across sibling
projects" before MacGamePane consolidated it — palette graphics, a sprite layer, an
SFX synth, an ABC player, reimplemented in Modula-2, in C++/Obj-C++, in Rust. That
repetition is a gift: porting the *same well-understood, non-trivial* library to
each new language exercises each compiler on identical, demanding ground, and the
results are comparable objectively — same frames, same WAV. And these games are
already wired to the [Tcl game-driver harness](/posts/tcl-for-agents) — `key fire;
step 4; snap out.png; get score` — so the very same game that stress-tests the
codegen at 60fps is *also* a scriptable, headless, snapshot-diffable regression
test. Fun to play, and mechanically checkable.

## Fun is a feature

I'll be honest about the last reason, because it's a real engineering property and
not a joke: **the best test is the one you actually run.** A conformance suite you
run out of discipline gets run when you remember to; a game you enjoy gets run every
day, for an hour, for the pleasure of it — and a bug that only surfaces after a
million frames, or a subtle audio glitch on one voice, *will* surface, because
you're really playing, really watching, really listening. Testing that depends on
willpower decays. Testing that's fun compounds. A retro engine in the standard
library isn't self-indulgence I have to excuse; it's a test rig I'll never stop
using because I don't want to.

## The through-line

A little pixel-art game running at sixty frames a second with sound is, whether you
set out to build one or not, one of the most complete compiler tests there is. The
16 ms deadline turns latency bugs — a GC pause, a cold JIT — into stutters you can
see. The unlimited sprites turn your codegen's hot loops into a river of memory
movement that never stops flowing. The whole language and the whole platform
binding run together, the way they will in anger. And the ABC player gives you the
rarest thing in testing: an oracle that is both a precise byte-diff and a sense you
were born with. That every compiler here ships a retro library isn't a hobby with a
justification stapled on. The justification is simply true — and it happens to be
the most fun way to find out your compiler is wrong.

## Screenshots

All **WRASM**-assembled programs, captured live. **BrickOut FX** mid-play — the
procedural brick-wall shader behind the field, sprite bricks (some already knocked
out), the ball, the paddle, and the `SCORE / LIVES / BRICKOUT` text HUD: the whole
layer stack in one frame.

![BrickOut FX in play: a shader wall, brick sprites, the ball, the paddle, and a text HUD](/images/games-for-compiler-testing/brickout.png)

**Galaxigans**, a Galaxians-style shooter — an aurora-shader sky, a starfield, rows
of enemy sprites, a boss UFO, and `+10` score pops.

![Galaxigans: a shader sky, starfield, enemy sprite rows, a boss, and score pops](/images/games-for-compiler-testing/galaxigans.png)

**Jewels**, a match-3 — this board was dealt by driving the *running* game over
nano-TCL (`send "newgame"`, `setpiece`, `drop`): the same harness an agent uses to
regression-test it (see [Tcl for agents](/posts/tcl-for-agents)).

![RASM Jewels: a colourful board, set up by driving the game over nano-TCL](/images/games-for-compiler-testing/jewels.png)

And two GPU demos the same toolchain assembles — a sine-table **plasma** and a
full-window **GPU Mandelbrot**:

![A demoscene plasma from a precomputed sine table](/images/games-for-compiler-testing/plasma.png)

![A full-window GPU Mandelbrot set](/images/games-for-compiler-testing/mandelbrot.png)

## Related

- [Test, test, test](/posts/test-test-test) — games as the whole-program corpus that forces feature interactions
- [The pain of GC is never the GC](/posts/gc-pain-is-the-interface) — a game makes a GC pause visible as a stutter
- [Two things called JIT](/posts/two-jits) — watch warmup, tier-up, and deopt storms in a live game loop
- [arm64 vs x64](/posts/arm64-vs-x64) — the SIMD/NEON paths that sprite-blitting exercises
- [Tcl for agents](/posts/tcl-for-agents) — the `key`/`step`/`snap`/`get` harness that turns a game into a regression test
- [MacGamePane](/posts/macgamepane) — the retro engine itself
