+++
title = "A FasterBASIC runtime-module writer's guide"
date = 2026-08-01
description = "How to extend FasterBASIC in FasterBASIC: reach the whole OS from BASIC today with DECLARE…LIB, TYPE, COM interfaces, ADDRESSOF and WSTR — and, as the module system lands, ship your BASIC as first-class language vocabulary other people IMPORT. The companion how-to to 'Don't freeze the runtime.'"
[taxonomies]
tags = ["basic", "fasterbasic", "runtime", "ffi", "com", "guide", "extensibility"]
+++

_Every feature you can write in FasterBASIC is a feature a FasterBASIC user can
write. This is the guide to doing that — reaching the operating system from BASIC
today, and packaging your BASIC as real language vocabulary as the module system
lands. It's the hands-on companion to [Don't freeze the
runtime](/posts/user-editable-runtime)._

## TL;DR

- FasterBASIC's runtime is meant to be **written in FasterBASIC**. Rust keeps a
  small floor — the compiler, the memory model, the JIT, `PRINT` and the
  numeric/string primitives. Everything above (graphics, windowing, sprites,
  audio, files) is a candidate for BASIC.
- **Today (runnable):** reach the whole OS from BASIC with `DECLARE … LIB` (flat
  DLL exports), `TYPE`/`CONSTANT` (OS-layout structs), COM `INTERFACE` (Direct2D
  and friends), `ADDRESSOF` (callbacks), and `WSTR` (UTF-16 marshalling). A
  library is just a `.bas` file of those plus `SUB`/`FUNCTION`.
- **Designed (near-future):** `MODULE` + `EXPORT COMMAND`/`EXPORT FUNCTION` +
  `IMPORT` turn a `.bas` file into registered **vocabulary** — a module can add
  real BASIC verbs (`CLS 0`, `PANE FILL …`) that compile to the same call a
  built-in makes.
- Two rules are load-bearing: **only machine types cross the FFI**, and
  **callbacks must be extern-shaped and panic-safe.**

## The boundary: what BASIC owns, what Rust keeps

Adding a command to FasterBASIC *the old way* means editing four Rust tables (the
keyword list, the compound-verb namespaces, the signature table, the builtin
binding) and writing a Rust shim. Vocabulary and implementation drift apart:
`PALETTE`, `RECT`, `SPRITE`, `MAT`, `ITEM` and `PATH` all *parse* — they're named
in the keyword list — but have no shim, so they reach codegen, call a symbol that
doesn't exist, and fail to verify. Ten demos are blocked on exactly that.

The fix is the thesis of this whole line of work: **the runtime is BASIC.** A
module's exports become the compiler's source of truth, so there is one place a
procedure is written and one place it is declared — the same file. (It's the model
[Windows Modula-2](/posts/newmodula2) already uses, where a library's `.def`
exports *are* the compiler's view of it.)

What stays in Rust, deliberately small so the boundary doesn't drift:

- the compiler (lexer, parser, sema, IR, LLVM codegen);
- the memory model (manual heap, string heap, RTTI, COM plumbing);
- process bootstrap and the JIT;
- `PRINT` and the numeric/string builtins — the primitives a BASIC program can't
  write in terms of anything smaller.

Everything above that line is yours to write in BASIC.

## Today: reach the OS from BASIC (the implemented floor)

This all works now. FasterBASIC reaches the OS two ways, and both are how a library
gets its power.

**Flat DLL exports — `DECLARE … LIB`.** Most of Win32 (window creation, the message
loop, console, GDI) is plain `__stdcall` exports with no COM interface:

```basic
DECLARE FUNCTION GetTickCount LIB "kernel32" () AS LONG

' ALIAS names the real export when it differs from what you call it —
' Win32 decorates heavily, and the wide forms end in `W`.
DECLARE FUNCTION Metric LIB "user32" ALIAS "GetSystemMetrics" _
    (index AS INTEGER) AS INTEGER

PRINT "uptime (ms)  = "; GetTickCount()
PRINT "screen width = "; Metric(0)          ' SM_CXSCREEN
```

Deliberately the QuickBASIC/VB spelling, because it's the one BASIC programmers
already know. (Runnable: `newfb-driver run bas/demo/66_declare_lib.bas`.)

**OS-layout structs — `TYPE` + `CONSTANT`.** A BASIC `TYPE` can match the exact byte
layout the OS expects — the `win32/*` bindings are generated from the Windows
metadata database by `tools/win32gen.py`, so the offsets are the official ones:

```basic
TYPE COORD
    X AS SHORT
    Y AS SHORT
END TYPE

CONSTANT GENERIC_WRITE = 1073741824

DECLARE FUNCTION SetConsoleTextAttribute LIB "KERNEL32" _
    (hConsoleOutput AS LONG, wAttributes AS SHORT) AS INTEGER
```

**COM interfaces — `INTERFACE`.** Already implemented: FasterBASIC's object layout
*is* the COM ABI, and `INTERFACE` with machine-checked `@N` ordinals drives
Direct2D, DirectWrite, DXGI, WIC and the shell (see `bas/demo/63_com_interface.bas`).
That's how a graphics module reaches the GPU without a line of Rust.

So a **library today** is a `.bas` file of `TYPE` / `CONSTANT` / `DECLARE … LIB` /
`INTERFACE` plus ordinary `SUB`/`FUNCTION` wrappers — which is precisely what
`Console`, `Graphics`, `Retro`, `Turtle` and the `win32/*` bindings already are.

## The two sharp edges: callbacks and strings

**Callbacks — `ADDRESSOF`.** A message loop needs the OS to call *into* BASIC;
without it, no amount of FFI makes a window:

```basic
FUNCTION WndProc(hwnd AS LONG, msg AS INTEGER, wp AS LONG, lp AS LONG) AS LONG
    ' ...
END FUNCTION

wc.lpfnWndProc = ADDRESSOF WndProc
```

`ADDRESSOF proc` yields the procedure's address as a `LONG`, with two enforced
rules: the target must be **extern-shaped** (machine-type params and return only —
sema rejects `ADDRESSOF` on a procedure taking a `STRING` or a class instance), and
it must be **panic-safe** (codegen wraps it in the same catch boundary the runtime
installs, because a callback runs on the OS's stack at the OS's whim).

**Strings — `WSTR`.** BASIC strings are refcounted, length-prefixed, NUL-terminated
UTF-8; Win32 `W` APIs want UTF-16. The conversion is explicit — a silent transcode
on every call would be surprising and slow:

```basic
DIM w AS LONG
w = WSTR(caption$)          ' UTF-16 copy, a statement temporary
MessageBoxW(0, w, w, 0)
```

Under both: **only machine types cross the FFI.** Hand a `STRING` to the OS and sema
stops you at the declaration, not at the crash.

## The module system: turning a .bas into vocabulary (designed)

> **Status** (from `docs/design/basic-runtime-modules.md`): _design, not yet
> implemented._ The FFI floor above is what ships today; this is the mechanism that
> promotes a `.bas` library into a first-class part of the language.

A **runtime module** declares what it exports. Compiling it yields an interface file
and a compiled artifact:

```
Graphics.bas ──compile──▶ Graphics.fbi   (interface: names + shapes)
                          Graphics.fbo   (compiled artifact)
```

```basic
MODULE Graphics

DIM currentPane AS INTEGER              ' private unless EXPORTed

EXPORT FUNCTION Rgb(r AS INTEGER, g AS INTEGER, b AS INTEGER) AS LONG
    RETURN (r * 65536) + (g * 256) + b
END FUNCTION

EXPORT COMMAND Cls(colour AS LONG)              ' registers the verb: CLS 0
    ' ...
END COMMAND

EXPORT COMMAND Pane.Fill(id AS INTEGER, x AS INTEGER, y AS INTEGER, _
                         w AS INTEGER, h AS INTEGER, colour AS LONG)
    ' a dotted name registers a compound verb: PANE FILL 1, 0, 0, ...
END COMMAND

END MODULE
```

Three export forms map to the three shapes the language already has:

| Form | Registers | Used as |
| --- | --- | --- |
| `EXPORT FUNCTION f(...) AS T` | a function | `x = f(1, 2)` |
| `EXPORT COMMAND Cls(...)` | a simple verb | `CLS 0` |
| `EXPORT COMMAND Pane.Fill(...)` | a compound verb | `PANE FILL 1, 0, 0, ...` |

`COMMAND` is a `SUB` that's also callable in statement position without
parentheses; keeping it a distinct keyword makes the module say plainly which
procedures become vocabulary — the intent `EXPORT` carries in Modula-2's `.def`.
Importing:

```basic
IMPORT Graphics                  ' everything it exports
IMPORT Graphics (Cls, Rgb)       ' just these
IMPORT Graphics AS Gfx           ' qualified: Gfx.Rgb(...)
```

**Why an interface, read first.** `CLS 0` is a *statement*, not an expression — the
parser can't tell a verb call from a syntax error unless it already knows `CLS` is a
verb. So a module's vocabulary must be known **before** the body parses. Hence a
compile-time `.fbi` (text, diffable, carrying a `source-hash` for staleness), and
the one real language restriction: **`IMPORT` must come before any statement.** A
module verb's symbol is `Module.Proc` — the same shape as `Class.Method` today — so
it compiles to exactly the call a built-in makes: no dispatch layer, nothing bound
at runtime.

The only new machinery is a front-end pre-pass: **lex → scan the header IMPORTs →
load each `.fbi` (recompiling the module if stale) → build a verb registry from base
+ imports → parse the body with it → sema/IR/codegen as today.** The three `const`
tables that hold today's vocabulary become registries, seeded with intrinsics and
extended per import.

**Collision rules:** a module may not redefine an intrinsic (`EXPORT COMMAND Print`
is an error, not a silent override); two imports of the same name error *at the
import* with the fix named; arity overloads are allowed, type-only overloads are not
(BASIC's implicit numeric conversions make them ambiguous more often than useful).

## A worked example: a `BEEP` verb, two ways

Today — a library procedure over the FFI floor:

```basic
DECLARE FUNCTION MessageBeep LIB "user32" (kind AS UINTEGER) AS INTEGER

SUB PlayBeep(kind AS INTEGER)
    MessageBeep(kind)
END SUB
' call it:  PlayBeep 0
```

Tomorrow — the *same* wrapper, shipped as vocabulary:

```basic
MODULE Sound
DECLARE FUNCTION MessageBeep LIB "user32" (kind AS UINTEGER) AS INTEGER

EXPORT COMMAND Beep(kind AS INTEGER = 0)      ' default arg → variable arity
    MessageBeep(kind)
END COMMAND
END MODULE
```

```basic
IMPORT Sound

BEEP            ' a real verb the module added — no parens, statement position
BEEP 16
```

The BASIC that *implements* `BEEP` and the declaration that *makes* `BEEP` a verb
live in one file. That's the whole idea.

## Migrating a built-in down into BASIC

The design's own acceptance test is the ten demos blocked on missing Rust shims
(`PALETTE`, `RECT`, `LINEWIDTH`, `SPRITE`, `MAT`, `ITEM`, `PATH`): they become the
*first* modules, because they're vocabulary that was named but never implemented, so
writing it in BASIC is the natural first use rather than a retrofit. Retiring the
Rust `newfb-wingui` crate runs in stages with both stacks live — compiler support,
then a pure-declaration `Win32` module, then `Window`/`Pane`/`Sprite` modules in
BASIC checked against the Rust reference as an oracle, then delete the crate.

## The through-line

FasterBASIC's promise is [FutureBASIC's](/posts/user-editable-runtime), kept: you
add to the language by writing the language. Today that means wrapping the OS from
BASIC through `DECLARE … LIB`, `TYPE`, COM and `ADDRESSOF`; as the module system
lands it means shipping those wrappers as real verbs other people `IMPORT`, compiled
to the very same call a built-in makes. Rust holds a small, honest floor. Everything
a BASIC program can be written in terms of, is — and you hand the next person the
source.

## Screenshots

> _Add to `static/images/fasterbasic-runtime-modules/`: a `Sound.bas` module beside
> a program that `IMPORT`s `BEEP`; a generated `win32/console.bas` binding; the
> `.fbi` interface file; the front-end pre-pass as a diagram._

![A FasterBASIC module registering a verb, and a program that imports it](/images/fasterbasic-runtime-modules/01.png)

## Related

- [Don't freeze the runtime](/posts/user-editable-runtime) — the essay this guide follows from
- [FasterBASIC (NewFB)](/posts/newfb) — the compiler and its `.bas` libraries
- [Windows Modula-2](/posts/newmodula2) — "a library's exports are the compiler's source of truth," the model being adopted
- [Windows was already an operating system: Win32 and COM](/posts/win32-and-com) — the platform a module reaches
- [The role of the interpreter](/posts/role-of-the-interpreter) — the FasterBASIC journey
