+++
title = "Don't freeze the runtime: let users write it in the language"
date = 2026-08-01
description = "Every language has a runtime, and the best ones let you extend it in the language itself — not in the C or Rust underneath. FutureBASIC proved it on the Mac and grew a community; open source makes the opportunity bigger. A survey of how far down each language in this portfolio actually goes."
[taxonomies]
tags = ["runtime", "language-design", "extensibility", "stdlib", "basic", "community"]
+++

_Every language has a runtime — a standard library, a set of built-in words, the
code that's already there when your program starts. The only real question is who
is allowed to edit it. Freeze it behind C or Rust and a user who wants a new
feature has to leave the language to get it. Write it in the language instead, and
they never have to._

## TL;DR

- **Every language has a runtime.** The interesting design choice is the *line*
  between the small native core and the large part written in the language itself.
- **FutureBASIC's lesson:** it shipped its runtime as **editable source**, and a
  community grew that extended the language *in the language* — no C required.
- **Open source makes this bigger, not smaller.** If the runtime is in the
  language and the source is public, "add a feature" and "write a program" become
  the same skill.
- **The rule: push the line down.** Implement in the language everything you can;
  keep the native core minimal. It's natural for some languages and real work for
  others — and it's always worth it.
- **In this portfolio** the line sits remarkably low: a Smalltalk *image*, a Forth
  *dictionary*, ~110 Lisp library files, a 506-file Beef corlib, 975 Modula-2
  modules, and — the point of this piece — a **FasterBASIC** whose Console,
  Graphics, Retro and Turtle libraries are all written in BASIC.

## The FutureBASIC lesson

FutureBASIC, on the classic Mac, did something most language products didn't: it
handed you its **runtime as editable source**. The behaviour that stood behind
your program wasn't a sealed binary blob — it was code you could open, read, and
change. And a community formed around exactly that. People added capabilities to
the language by writing more of the language, shared those additions, and folded
them back in. The barrier to "make BASIC do a new thing" wasn't "learn C and the
Toolbox" — it was "write some BASIC."

That's the whole idea, and it long predates FutureBASIC — it's the Lisp tradition,
the Forth tradition, the Smalltalk tradition. But FutureBASIC is the sharpest
reminder that it works for an *ordinary, friendly* language too, not just the ones
famous for it. Open source only sharpens the point: when the runtime is written in
the language **and** the source is in the open, extending the language and using
it stop being two different activities.

## Every language has a runtime — the only question is who can edit it

Draw a horizontal line through any language implementation. Below it: the native
core — the compiler or interpreter, the garbage collector, the handful of
primitives that genuinely need the host language because they touch registers,
memory, or the OS. Above it: everything else — the collections, the string
formatting, the math, the I/O vocabulary, the GUI helpers, the parts a user thinks
of as "the language."

Where you put that line is a *policy*, not a fact. You can implement `map` as a C
builtin or as three lines in the language. You can make the windowing API a native
binding or a library written in the language over a few native primitives. Every
feature you push **above** the line is a feature a user can read, copy, fix, and
extend without ever leaving the language. Every feature you keep **below** it is a
feature that requires a second language — and a much smaller set of people — to
touch.

Freezing the runtime is the default because it's easy and it performs well. But it
quietly tells your users: *the language is ours; you get to write programs, not
extend the language.* Refusing to freeze it says the opposite.

## A survey: how far down each language goes

The languages in this portfolio land all along that spectrum — and mostly far
toward the "written in itself" end. (File counts are the language's own source in
its own runtime/library trees.)

**The runtime _is_ the language.** For some, there was never a question:

- **Smalltalk ([MACVM](/posts/macvm))** keeps its class library in a live
  **image** (`docs/IMAGE.md`, `image_store/`) — the whole system is editable
  Smalltalk objects and methods you can change while it runs, over a small Rust
  kernel of primitives. This is the purest form of a user-editable runtime: there
  is barely a "below the line" to hide behind.
- **Forth ([WF66](/posts/wf66) → [MF66](/posts/mf66))** builds its world as a
  **dictionary** of words defined in Forth — `lib/core.f` on up, and an OOP system
  "built almost entirely in Forth" — over a tiny set of STC kernel primitives.
- **Lisp ([NCL](/posts/newcl))** self-hosts a ~800-form standard library across
  ~110 `.lisp` files (`Lisp/Library/…`); the reader, compiler and GC are the only
  parts that are Rust.

**A large library in the language, a compiler underneath.** Idiomatic, and still
overwhelmingly in-language:

- **Component Pascal ([NewCP](/posts/newcp))** — 410 `.cp` files, up to and
  including `Kernel.cp`: the Oberon habit of writing the system in itself.
- **Modula-2 ([Windows Modula-2](/posts/newmodula2) → [MacModula2](/posts/macmodula2))**
  — 975 `.mod`/`.def` files, and it pushes the line about as far as it goes. Pure
  Modula-2 reaches the whole platform in-language, including a **machine-checked
  COM object model** — `INTERFACE`s carry an IID and a per-method `@ordinal`, and
  the compiler proves each vtable slot by walking the `INHERIT` chain (`GUARD` /
  `ISMEMBER` via `QueryInterface`), so even COM interop is written and checked in
  the language rather than hand-bound in C. And its **two IDEs, FastM2 and the
  GPU-pane FastPanesM2, are themselves written in Modula-2** — the tooling lives
  above the line too.
- **Beef ([NewBF](/posts/newbf))** — a 506-file `corlib` written in Beef
  (`Attribute.bf`, `Compiler.bf`, …), the C# way: the core library is the language.
- **Locus ([Locus](/posts/locus))** — an in-language `stdlib/` (`array.locus`,
  `list.locus`, `agent.locus`, …) over the Rust runtime.
- **Dart ([MACDART](/posts/macdart), and its Windows sibling **WINDART**)** — the
  Dart SDK's core libraries (`dart:core`, `dart:async`, …) are ~300 `.dart` files
  written in **Dart**, with only the primitives patched in from the C++ VM (the
  `external` + patch pattern). WINDART ports the 1.24.3 VM to Windows "with ~zero
  source changes," so that whole in-Dart runtime comes along intact — a big,
  battle-tested example of a standard library written in its own language. And it
  goes further: MACDART's **`dartui` workspace/IDE is itself a Dart program**,
  driving the native UI through a built-in **`dart:cocoa`** bridge (on Windows,
  WINDART's view-server has Dart *describe* widgets that a C++ materializer
  realizes) — the tooling, like Modula-2's, written in the language it serves.

**The opportunity — and the one that needs a nudge.**

- **BCPL ([NewBCPL](/posts/newbcpl))** sits nearer the middle: it *does* ship
  modules in BCPL (`.bcl` — `maths`, `geom`, `igui`, `audio`), but more of its
  standard library still lives as Rust builtins. It's the clearest "worth the
  effort to push lower" case here.

## FasterBASIC: a runtime you write in BASIC

Which brings it back to [FasterBASIC](/posts/newfb) and the FutureBASIC lesson.
FasterBASIC already does the right thing, and it's worth naming so it gets done
*more*. Its libraries are written **in BASIC**: `Console`, `Graphics`, `Retro` and
`Turtle` are `.bas` files, and so are the `win32/console`, `win32/window` and
`win32/d3d11` wrappers — a BASIC programmer reaching Direct3D through a vocabulary
another BASIC programmer wrote. There's a module / `declare lib` mechanism so a
library written in BASIC loads like any other.

That is the FutureBASIC contract, brought forward: **a FasterBASIC user adds to
the language by writing FasterBASIC.** Want a new drawing verb, a new data
structure, a new device binding? You write it in the language you already know,
drop it in as a module, and share the `.bas` file — you don't open a Rust
workspace and learn the compiler internals. The native core (LLVM, the GC, a few
primitives) stays small on purpose so that the interesting surface — the part
people actually want to extend — stays in reach.

The design commitment is: **if a feature can be written in FasterBASIC, it should
be** — and only what genuinely can't (a new primitive, a new intrinsic, a hardware
hook) drops below the line into Rust.

**[A FasterBASIC runtime-module writer's guide](/posts/fasterbasic-runtime-modules)**
walks through actually doing it — the `DECLARE … LIB` / COM / `ADDRESSOF` floor you
have today, and the `MODULE` / `EXPORT COMMAND` / `IMPORT` system that turns your
BASIC into language vocabulary other people import.

## The rule: push the line down

Stated as guidance for any of these languages:

1. **Default to the language.** New standard-library feature? Write it in the
   language. Reach for the host (Rust/C) only when you hit a real primitive —
   memory, registers, a syscall, an intrinsic the compiler must know about.
2. **Keep the native core minimal and stable.** The smaller the frozen part, the
   more of the language is in the community's hands. A few dozen primitives can
   carry a library of thousands of lines written above them.
3. **Make loading language-level code first-class.** A module system, a
   `declare`/`import`, a dictionary, an image — some way for user code to *become*
   runtime without a rebuild. FasterBASIC's module loader, Forth's dictionary, and
   Smalltalk's image are three answers to the same need.
4. **Publish it.** Open source turns a readable runtime into a *shared* one: every
   library someone writes in the language is a feature everyone else can adopt,
   read, and improve.

## Why it's worth the effort — even when it's an effort

For the "natural" languages this is free; the runtime was always going to be
written in itself. For the others it's real work: you have to design a clean
primitive boundary, expose enough of the machine through the language to make
library code capable, and resist the temptation to just add one more C builtin.

Do it anyway. A runtime written in the language is **documentation that runs** —
the best example of how to use the language is the language's own library. It's
**testable and fixable by its users**, not just its authors. It **grows a
community**, because contribution doesn't require a second skill set. And it keeps
the language *honest*: if the language can't express its own standard library,
that's a design bug worth finding early. FutureBASIC's community was not an
accident of nostalgia — it was the direct consequence of a runtime you could open
and edit. Build the language so that's true, and the community is possible; freeze
the runtime, and it never is.

## The through-line

Every language ships a runtime; the only question is whether your users can edit
it. Push that line as far down as the language will go — implement in the language
everything that *can* be, and keep below it only what truly must be. It is
effortless for a Smalltalk, a Forth, a Lisp; it is deliberate work for a BASIC or
a BCPL; it pays off every time, in documentation that runs, in bugs users can fix
themselves, and in a community that extends the language *by using it*. Don't
freeze the runtime. Let them write it.

## Screenshots

> _Add to `static/images/user-editable-runtime/`: a FasterBASIC `.bas` library
> module (`Console.bas`) side by side with a program that `declare`s it; a
> Smalltalk image browser editing a kernel method live; a Forth `lib/core.f`
> definition; the primitive-boundary "line" as a diagram._

![A FasterBASIC library, written in BASIC, loaded as runtime](/images/user-editable-runtime/01.png)

## Related

- [FasterBASIC (NewFB)](/posts/newfb) — Console/Graphics/Retro/Turtle libraries written in BASIC
- [A FasterBASIC runtime-module writer's guide](/posts/fasterbasic-runtime-modules) — the hands-on how-to companion to this essay
- [The role of the interpreter](/posts/role-of-the-interpreter) — the FasterBASIC journey
- [MACVM](/posts/macvm) — a live Smalltalk image, the runtime as editable objects
- [WF66](/posts/wf66) → [MF67](/posts/mf67) — the Forth dictionary, and an OOP system written in Forth
- [NCL](/posts/newcl) — a ~800-form standard library self-hosted in Lisp
- [Windows Modula-2](/posts/newmodula2) — a library (and two IDEs) in Modula-2, reaching COM in-language
- [MACDART](/posts/macdart) — the Dart SDK core (`dart:core`, `dart:async`) written in Dart; **WINDART** is the Windows port
- [The shared substrate](/posts/shared-substrate) — the small native core these libraries stand on
