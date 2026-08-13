+++
title = "The joys of the macro assembler"
date = 2026-07-31
description = "A custom MASM-style macro assembler that also grows high-level conveniences is one of the most joyful and powerful tools you can build — because it lets you climb from raw bytes up to typed, contract-checked subroutines without ever hiding an instruction. A Forth is really a macro assembler that implements Forth; and WRASM's `proc`, with its checked `uses`/`in`/`out`/`frame` contract, is a little type system for the most untyped language there is."
[taxonomies]
tags = ["assembler", "macro-assembler", "forth", "wrasm", "structured-programming", "hla"]
+++

_There is a particular joy in building your own macro assembler — the MASM-era
pleasure of `invoke`, typed structs, and `.if`/`.while` — and then discovering how
far *up* you can climb from raw instructions while still, at the bottom, writing
every byte yourself. The macro assembler is the tool that spans the whole distance
from "emit exactly these bytes" to "declare this typed subroutine and check it,"
and the best part is that you build it, you own it, and it hides nothing._

## TL;DR

- A macro assembler gives you MASM ergonomics — named macros, `invoke`, typed
  structs, structured `.if`/`.while`, scoped labels — with a house rule that every
  convenience **lowers to visible instructions**.
- **A Forth *is* a macro assembler that implements Forth.** WF66/MF66's whole
  kernel is `.masm`, and macros define the Forth world's data structures — which is
  exactly what makes building a Forth tractable.
- **WRASM/MRASM push macros up into structure.** The `proc` is a *declared
  subroutine* with a `uses`/`in`/`out`/`frame` **contract the assembler checks** —
  type-checked assembly, managed stack frames, and single-entry control flow, on
  top of raw x86-64/arm64.
- The joy and the power are the same thing: total control of the machine *and* real
  discipline, at once.

## The joy: MASM ergonomics, rebuilt and owned

The pleasure starts with the ergonomics. A macro assembler lets you name a sequence
of instructions and reuse it; call with `invoke` and typed arguments; lay out a
`struct` and address its fields by name; write `.if`/`.while` blocks that read the
way you think; and scope your labels so `loop:` in one routine can't collide with
`loop:` in another. It's the MASM-32 experience — and the joy of building your own
is that every one of those conveniences is *yours*, tuned exactly how you like it,
carrying (as [MRASM](/posts/mrasm) does) an "intense, offline, always-available
knowledge of the platform" so you never have to go look up an instruction.

But there's one rule that separates a macro assembler from a compiler, and it's the
whole ethos: **the conveniences must never hide a single instruction.** Everything
lowers to bytes you can print with `--emit-asm`; nothing is generated behind your
back. A compiler's job is to *hide* the machine from you; a macro assembler's job
is to *amplify* your command of it. You keep writing assembly — you just stop
writing the tedious, error-prone parts by hand.

## A Forth is a macro assembler that implements Forth

The purest demonstration is a Forth. People say a Forth is "a language you can
implement in a weekend in assembly," and the reason is precisely the macro layer.
Look at [WF66](/posts/wf66)/[MF66](/posts/mf66): the *entire kernel* is macro
assembler — `dict.masm`, `stack.masm`, `number.masm`, `gc.masm`, `oop.masm`,
`parse.masm` — and a `macros.masm` defines the Forth world's own data structures as
macros: the dictionary header layout (`dh_link`, `dh_ct`, `dh_xtptr`, the name
field), the type tags, the search-index node. Every primitive, the inner
interpreter, the dictionary threading, even the garbage collector, are written as
assembly *through those macros*.

That's what makes it tractable. Laying out a dictionary header by hand, correctly,
for two hundred primitives is a nightmare of offsets; defining the header *once* as
a macro and stamping it out is an afternoon. The macro assembler isn't a stepping
stone on the way to the Forth — it *is* the Forth's implementation substrate. As
[the interpreter essay](/posts/role-of-the-interpreter) put it, MF66 is literally "a
Forth inside a macro assembler." Macros are what turn "implement a threaded
language in raw assembly" from heroics into ordinary work.

## The power: WRASM's `proc` — a contract the assembler checks

If the Forth shows the bottom of the range, [WRASM](/posts/wrasm)/[MRASM](/posts/mrasm)
show the top: how far *up* a macro assembler can climb while still emitting every
instruction visibly. The unit is the **`proc`**, and its own documentation is
precise about what it is:

> "the `proc` … is not just a label with a `ret` — it is a *declared subroutine*
> with four properties the assembler understands, every one of which lowers to
> **visible** instructions." — MRASM `docs/structured.md`

```asm
proc DrawSpan  uses rbx rsi rdi  in rcx rdx r8  frame
    ; rcx = x, rdx = y, r8d = len  (the declared inputs)
    …
endproc
```

Four things are happening here, and together they are most of what a compiler gives
you — earned honestly, at the assembler's altitude.

**A managed stack frame.** `proc` emits the prologue that pushes each `uses`
register, and — with `frame` — aligns the stack and reserves the 32-byte shadow
space *once*; `endproc` and every `ret` inside emit the matching epilogue, "so a
return can never skip the restore." The single most common hand-written-assembly
bug — a `ret` path that forgot to pop a saved register, or a misaligned stack before
a `call` — is *structurally impossible*, because the frame is generated from the
declaration, not typed out by you at every exit. That is the "optimize the stack
framing" win: correct prologues and epilogues, reserved once, never by hand.

**A checked contract — type-checked assembly.** This is the part people say can't
exist. The `uses`/`in`/`out`/`frame` clauses are a *declared interface*, and the
checker holds you to it:

> "`--check` flags a callee-saved register clobbered without a `uses`, an `in`
> register read after it's been destroyed, a promised `out` that's never written,
> and a frame imbalance. The declaration *is* the subroutine's interface, and the
> checker holds you to it." — MRASM `docs/structured.md`

Read that as what it is: a **static type/effect checker for assembly language.** You
declare "I take my inputs in `rcx/rdx/r8`, I clobber `rbx/rsi/rdi`, I return in
`eax`," and the assembler proves your body honors it — catches you reading an input
after you smashed it, promising a result you never produced, unbalancing the stack.
These are exactly the silent, non-local horrors that, uncaught, become the
one-in-a-hundred-thousand [debugging](/posts/debuggers) nightmares. A ten-word
contract turns them into a compile error.

**Structured control flow and scoped labels.** Inside the proc you write
`.if`/`.elseif`/`.while`/`.for`/`.repeat`, each lowering to a plain `cmp` + branch
you can read in the listing — single entry, no jumping into the middle — and the
labels you *do* write by hand are private to the proc, so every routine can just use
`loop:` and `done:` without inventing unique names. Structured-programming
discipline, on raw machine code.

## The joy and the power are the same thing

Here's why this isn't two separate observations. A macro assembler sits in the sweet
spot between "write every byte" — total control, total tedium, total foot-guns — and
"write a compiler" — total convenience, total opacity. The macro layer removes the
tedium (the Forth world; the prologues), the high-level layer adds the safety (the
`proc` contract; managed frames; structured blocks), and the *conceal-nothing* rule
keeps you in full command of the machine the entire time. You get to write assembly
the way you actually want to think about it, and have the tool catch the mistakes
assembly is infamous for. The `proc` is a tiny type system for the most untyped
language there is, and it converts hand-written assembly from a minefield into
something you can maintain.

That is the joy: not that the assembler does the work for you, but that it lets *you*
do the work — all of it, every instruction — with a compiler's discipline standing
quietly behind you, checking.

## The through-line

The macro assembler is the most underrated tool in the box. Build your own, give it
MASM ergonomics, and then keep climbing: typed structs, `invoke`, `.if`/`.while`,
and finally a `proc` with a checked `uses`/`in`/`out`/`frame` contract — and you
find you can have most of a compiler's rigor while writing every byte yourself. A
Forth proves the bottom of the range, where the macros simply *are* the
implementation; WRASM's type-checked `proc` proves the top, a contract system for
assembly. And the whole way up, nothing is hidden. Total control and real structure,
at the same time — that combination is the joy, and it is quietly also the power.

## Related

- [WRASM](/posts/wrasm) / [MRASM](/posts/mrasm) — the assembler that conceals nothing, with the `proc` contract
- [WF66](/posts/wf66) / [MF66](/posts/mf66) — a Forth whose kernel is macro assembler
- [The role of the interpreter](/posts/role-of-the-interpreter) — "a Forth inside a macro assembler"
- [Text at every stage](/posts/text-at-every-stage) — why "lowers to visible instructions" matters
- [The role of LLVM](/posts/llvm-in-these-compilers) — the same encoder, gated byte-for-byte against LLVM-MC
