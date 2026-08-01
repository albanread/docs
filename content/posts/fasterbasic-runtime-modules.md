+++
title = "A FasterBASIC runtime-module writer's guide"
date = 2026-08-01
description = "How to extend FasterBASIC in FasterBASIC — the working MODULE / EXPORT COMMAND / IMPORT system, the DECLARE…LIB / COM / ADDRESSOF floor it stands on, and the read-back discipline that lets a module self-test through the OS. Grounded in the real Retro and Console modules, where the whole graphics and text-UI vocabulary now lives in BASIC."
[taxonomies]
tags = ["basic", "fasterbasic", "runtime", "ffi", "com", "guide", "extensibility"]
+++

_Every feature you can write in FasterBASIC is a feature a FasterBASIC user can
write — and, increasingly, has. This is the guide to doing it: packaging BASIC as
real language vocabulary other people `IMPORT`, over an FFI floor that reaches the
whole OS. It's the hands-on companion to [Don't freeze the
runtime](/posts/user-editable-runtime), and it describes a system that is
implemented and in daily use, not a plan._

## TL;DR

- FasterBASIC's runtime is **written in FasterBASIC.** Rust keeps a small floor —
  the compiler, the memory model, the JIT, `PRINT` and the numeric/string
  primitives. Everything above is BASIC.
- **The module system works today.** `MODULE` + `EXPORT COMMAND`/`EXPORT FUNCTION`
  + `IMPORT` turn a `.bas` file into registered **vocabulary** — real verbs
  (`SCREEN CREATE`, `PALETTE SET`, `LOCATE`) compiled to the same call a built-in
  makes, via a compile-time interface (`.fbi`) and an `IMPORT` pre-pass.
- **The proof:** the entire graphics and text-UI vocabulary now lives in BASIC —
  `Graphics.bas`, `Retro.bas` (the full RASM layer model: fx shaders, per-line
  palettes, tiles, sprites, a text HUD), `Console.bas`, `Turtle.bas` — and the old
  Rust `newfb-wingui` graphics crate was **deleted** once they reached parity.
- **The floor a module stands on:** `DECLARE … LIB` (flat DLL exports), `TYPE` /
  `CONSTANT` (OS-layout structs), COM `INTERFACE` (Direct2D & friends), `ADDRESSOF`
  (callbacks), `WSTR` (UTF-16). Two rules are load-bearing: only machine types
  cross the FFI, and callbacks must be extern-shaped and panic-safe.
- **A module can self-test through the OS.** The house discipline is a read-back —
  `PIXEL()` for graphics, `CHARAT()`/`COLORAT()` for the console — plus synthetic
  input injection, so a demo *proves* its verbs against the real screen or console
  buffer.

## The boundary: what BASIC owns, what Rust keeps

Adding a command the old way meant editing four Rust tables and writing a shim, and
vocabulary drifted from implementation — `PALETTE`, `SPRITE`, `RECT` all *parsed*
but had no shim and failed at codegen. The fix is the thesis: **a module's exports
are the compiler's source of truth**, so a verb is written and declared in one
file. What stays in Rust is deliberately small — the compiler, the memory model
(manual heap, string heap, RTTI, COM plumbing), bootstrap + JIT, and `PRINT` plus
the numeric/string primitives a BASIC program can't write in terms of anything
smaller. Everything above that line — graphics, windowing, sprites, audio, files,
the console — is BASIC.

## Writing a module

A **module** is a `.bas` file that declares what it exports. Compiling it emits a
text interface (`.fbi`, via `newfb emit-interface`) and a compiled artifact:

```
Retro.bas ──compile──▶ Retro.fbi   (interface: names + shapes)
                       Retro.fbo   (compiled artifact)
```

```basic
MODULE Retro

' Private unless EXPORTed.
DIM screenHandle AS LONG

EXPORT FUNCTION KeyDown(vk AS LONG) AS LONG      ' function:  IF KeyDown(37) THEN ...
    ' ...
END FUNCTION

EXPORT COMMAND Cls(index AS LONG)                ' simple verb:   CLS 0
    ' ...
END COMMAND

EXPORT COMMAND Palette.Set(index AS LONG, rgb AS LONG)   ' compound verb: PALETTE SET 1, &hFF0000
    ' ...
END COMMAND

END MODULE
```

Three export forms map to the three shapes the language already has:

| Form | Registers | Used as |
| --- | --- | --- |
| `EXPORT FUNCTION f(...) AS T` | a function | `x = f(1, 2)` |
| `EXPORT COMMAND Cls(...)` | a simple verb | `CLS 0` |
| `EXPORT COMMAND Palette.Set(...)` | a compound verb | `PALETTE SET 1, c` |

A program uses it by importing first:

```basic
IMPORT Retro                     ' everything it exports
IMPORT Console (Locate, Cls)     ' just these
IMPORT Retro AS R                ' qualified: R.Pixel(x, y)
```

**Why `IMPORT` must come first.** `CLS 0` is a *statement*, not an expression — the
parser can't tell a verb call from a syntax error unless it already knows `CLS` is a
verb. So a module's vocabulary must be known before the body parses. The front end
does exactly that, as a pre-pass (`newfb-loader/src/prepass.rs`): **lex → scan the
header `IMPORT`s → load each `.fbi` (recompiling the module if stale) → build the
verb registry from base + imports → parse the body with it → sema/IR/codegen as
usual.** A module verb's symbol is `Module.Proc`, the same shape as `Class.Method`,
so it compiles to precisely the call a built-in makes — no dispatch layer, nothing
bound at runtime. The one language rule that falls out: **`IMPORT` before any
statement.** Collisions are errors, not silent overrides (a module may not redefine
an intrinsic; two imports of one name error at the import; arity overloads are fine,
type-only overloads are not).

## The floor a module stands on

A module gets its power from the FFI floor — all implemented, all callable from
BASIC.

**Flat DLL exports — `DECLARE … LIB`** (QuickBASIC/VB spelling; `ALIAS` names a
decorated or wide export):

```basic
DECLARE FUNCTION Metric LIB "user32" ALIAS "GetSystemMetrics" (index AS INTEGER) AS INTEGER
```

**OS-layout structs — `TYPE` + `CONSTANT`.** The `win32/*` bindings are generated
from the Windows metadata database by `tools/win32gen.py`, so a BASIC `TYPE` has the
exact byte layout the OS expects.

**COM interfaces — `INTERFACE`.** FasterBASIC's object layout *is* the COM ABI, and
`INTERFACE` with machine-checked `@N` ordinals drives Direct2D/DirectWrite/DXGI —
how a graphics module reaches the GPU without a line of Rust.

**Callbacks — `ADDRESSOF`.** `ADDRESSOF proc` yields a procedure address for a
`WndProc` or a worker. Two enforced rules: the target must be **extern-shaped**
(machine-type params/return only — sema rejects a `STRING` or class parameter), and
it must be **panic-safe** (codegen wraps it in a catch boundary, because it runs on
the OS's stack).

**Strings — `WSTR`.** BASIC strings are refcounted, length-prefixed UTF-8; Win32 `W`
APIs want UTF-16, so the conversion is explicit: `w = WSTR(caption$)`. Under all of
it: **only machine types cross the FFI** — hand the OS a `STRING` and sema stops you
at the declaration, not the crash.

## A real module, top to bottom: `Retro`

`Retro.bas` is the showcase, because it implements **RASM's entire layer model in
BASIC** — every layer a program composes for a 2D game, with colour index 0 as the
transparency key between levels:

```
  fx shader (HLSL, layer 0)  →  per-line palette  →  indexed background
     →  tilemap  →  sprites (per-sprite palette + frames)  →  text HUD (layer 6)
```

The vocabulary the module exports, by layer:

- **`SCREEN SHADER fx$` / `SHADER PARAM n, value`** — the bottom layer is a
  user-supplied **HLSL** effect (plasma, tunnel, starfield). Wherever the
  framebuffer holds 0 and no sprite covers it, the shader paints instead of the
  per-line background. It receives `uv`, seconds-since-install, and four `SHADER
  PARAM` floats through a dynamic constant buffer streamed each `FLIP`; a compile
  error surfaces the HLSL compiler's own diagnostics.
- **`PALETTE SET` / `PALETTE LINE` / `PALETTE ROTATE`** — the indexed and per-line
  palettes (raster bars, colour-cycling waterlines).
- **`CLS index` / `PSET` / `RECTFILL`** — the indexed framebuffer.
- **`TILE DEFINE` / `MAP DEFINE` / `MAP DRAW camX, camY`** — a scrolling tile world.
- **`SPRITE DEFINE/ADDFRAME/FRAME/COLOUR/PALETTE/POS/SHOW/HIDE`**, plus **`BLIT` /
  `BLITKEY` / `SPRITE GRAB`** — framed sprites with their own palettes.
- **`TEXT col, row, s$, colour` / `TEXT CLEAR` / `TEXT COLOUR`** — a retained
  **text HUD** (layer 6): a 53×25 cell grid over a 5×7 dot-matrix font authored as
  hex rows inside the module, composited *after* sprites (lit pixels only), so a
  score floats over everything.

Using it is one `IMPORT` and then verbs that read like built-ins:

```basic
IMPORT Retro

SCREEN CREATE 320, 200, "demo"
SCREEN SHADER "plasma.hlsl"           ' layer 0, on the GPU
PALETTE SET 1, &hFF0000
SPRITE DEFINE 1, shipArt$
SPRITE POS 1, 100, 80

DO
    CLS 0                             ' 0 = show the shader through
    MAP DRAW camX, 0
    SHADER PARAM 0, seconds
    TEXT 1, 1, "SCORE " + STR$(score), 15
    FLIP
LOOP UNTIL KeyHit(27)
```

The CPU contribution to that plasma background is zero — no framebuffer writes at
all after `CLS 0`. Brickout, ported to this module, took about twenty minutes and
shows a live score through `TEXT`.

## A second domain: `Console`

Same pattern, a different surface. `Console.bas` is a Text-UI vocabulary over the
generated `kernel32` console bindings — it opens `CONOUT$`/`CONIN$` directly, so it
keeps working when stdout is a pipe (which is how the headless test corpus runs it):

```basic
IMPORT Console

CONSOLE TITLE "panel"
CLS
COLOR 15, 1                           ' also spelled COLOUR
BOX 2, 4, 40, 10
PRINTAT 3, 6, "Ready."
LOCATE 5, 6
DIM k$ : k$ = WAITKEY()               ' or INKEY() non-blocking, READLINE() cooked
```

The full set: `LOCATE`, `COLOR`/`COLOUR`, `CLS`, `PRINTAT`, `BOX`, `CURSOR
SHOW`/`CURSOR HIDE`, `CONSOLE TITLE`, `PAUSE`, `CONSOLECOLS()`/`CONSOLEROWS()`, and
input via `INKEY()`, `WAITKEY()`, `READLINE()`. (`CURSOR SHOW`/`HIDE` rather than
`CURSOR ON` — `ON` is reserved, and the reserved-word diagnostic said so.)

## Verify through the OS: the read-back discipline

The reason these modules are trustworthy is a house rule — *verify before
entertaining* — and modules are built to make it possible. Each exposes a
**read-back**: the graphics module's `PIXEL(x, y)` and the console module's
`CHARAT(row, col)` / `COLORAT(row, col)` read state back from the real GPU
framebuffer or the console's own screen buffer — the text-mode equivalent of
`PIXEL()`. Input gets the mirror treatment: `INJECTKEY ch` pushes a synthetic
keystroke through the genuine input queue (the `PostMessageW`/`WriteConsoleInputW`
pattern), so a demo can drive itself.

So the demos are self-tests. `82_console.bas` asserts thirty facts through the OS —
cell contents and attributes after `CLS`/`PRINTAT`/`BOX`, caret position after
`LOCATE`, key ordering through the queue, a full `READLINE` fed by injected
keystrokes. `80_shader_background.bas` probes a deterministic two-tone effect
through `PIXEL()` before swapping in a plasma. `81_showcase.bas` runs every Retro
layer at once — a starfield/nebula shader sky, raster bars, a tilemap ground with a
`PALETTE ROTATE` waterline, a ship sprite on a `SIN` path, and a title, frame
counter and scrolltext in the HUD. The suite is green: 28 demos.

## What this replaced

None of this is additive-only. The commit `Remove wingui and the graphics
vocabulary` **deleted** the Rust `newfb-wingui` crate and the built-in graphics
commands it implemented, once the BASIC modules reached parity against its demos —
the Rust version served as the oracle, then went away. The migration the design
imagined in stages actually happened: the graphics and console vocabularies a
FasterBASIC program uses are now BASIC that a FasterBASIC programmer can read, fork,
and extend.

## The through-line

FasterBASIC's promise is [FutureBASIC's](/posts/user-editable-runtime), kept and
then some: you add to the language by writing the language, and the language's own
graphics and text-UI vocabularies are the proof — real verbs, defined in `.bas`
modules, compiled to the same call a built-in makes, verified through the OS, with
the Rust originals deleted. Rust holds a small, honest floor. Everything a BASIC
program can be written in terms of, is — and it ships with the source.

## Screenshots

> _Add to `static/images/fasterbasic-runtime-modules/`: `81_showcase.bas` running
> (plasma sky + tiles + sprite + HUD scrolltext); a `Retro.bas` `EXPORT COMMAND`
> beside a program that `IMPORT`s it; the `.fbi` interface file; `83_tui.bas`; the
> reserved-word diagnostic catching `DIM band`._

![The showcase: every Retro layer live in one scene, all verbs from Retro.bas](/images/fasterbasic-runtime-modules/01.png)

## Related

- [Don't freeze the runtime](/posts/user-editable-runtime) — the essay this guide follows from
- [FasterBASIC (NewFB)](/posts/newfb) — the compiler and its `.bas` module libraries
- [Windows Modula-2](/posts/newmodula2) — "a library's exports are the compiler's source of truth," the same model
- [Windows was already an operating system: Win32 and COM](/posts/win32-and-com) — the platform a module reaches
- [The role of the interpreter](/posts/role-of-the-interpreter) — the FasterBASIC journey
