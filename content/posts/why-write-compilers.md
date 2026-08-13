+++
title = "Why write compilers"
date = 2026-08-01
description = "Ten reasons to build a language from scratch in an age that already has LLVM and more languages than anyone can learn — each one with a project in this portfolio attached to it: absence, hardware, understanding, love, history, preservation, nostalgia, timing, and the future."
[taxonomies]
tags = ["essay", "compilers", "motivation", "preservation", "history", "apple-silicon"]
+++

_People ask why anyone would write a compiler now — with LLVM sitting right there,
with more languages than a person can learn already shipping. Here are eleven
answers. Every one of them has a project in this portfolio attached to it, which
is the point: these aren't abstractions, they're the reasons a specific pile of
code exists._

## TL;DR — ten reasons

- **(a) Because it isn't there.** The language has no good, current, runnable
  implementation any more.
- **(b) Because it isn't there for your machine.** It exists — just not native to
  the thing you actually sit in front of.
- **(c) Because it doesn't use your machine.** It runs, but ignores the GPU, the
  vector units, the OS, the object runtime you paid for.
- **(d) To understand how they really work.** The only way to *know* a compiler is
  to build one.
- **(e) Because you loved using them.** Some languages are worth keeping in your
  hands.
- **(f) Because they are cultural history.** A language is a record of how people
  thought about computing.
- **(g) Because they deserve to be preserved.** A language whose only
  implementation is bit-rotting is a language dying.
- **(h) To recapture something you miss.** The feel of a machine, or a language,
  from your past.
- **(i) Because now is the best time.** The tools to bring a language up in a week
  finally exist.
- **(j) To build tools for your future.** A compiler you wrote is a tool you own.
- **(k) Because you can extend them.** What if a language had never been
  superseded — and evolved instead?

The rest of this is those eleven, with the receipts.

## Because they're not there (a, b, c)

The first three reasons are all about **absence**, and they're different kinds.

**(a) The language isn't there at all.** BCPL is the language behind B, behind C —
and there was no good, current, runnable modern dialect of it to just pick up. So
one got built: [NewBCPL](/posts/newbcpl), then [MacBCPL](/posts/macbcpl).
Component Pascal and Oberon microsystems' BlackBox are quietly dormant; that
absence is exactly what [NewCP](/posts/newcp) fills. Corman Lisp made Common Lisp
feel native on Windows and is no longer maintained — [NCL](/posts/newcl) is a
from-scratch run at that same experience. The ADW / Stony Brook Modula-2 line is
old; [Windows Modula-2](/posts/newmodula2) → [MacModula2](/posts/macmodula2) is a
clean-room implementation from the specs. You write the compiler because the
shelf where it should be is empty.

**(b) It isn't there for _your_ machine.** This is the whole
[Windows → Apple Silicon](/posts/arm64-vs-x64) thread. A language can be perfectly
alive and still not exist for the computer on your desk: Dart 1.24.3 — the last of
the optionally-typed V1 line — had no arm64 build you could just run, so
[MACDART](/posts/macdart) ports it. Beef lives on Windows; [NewBF](/posts/newbf)
brings it up on the toolchain the rest of the family uses. "Runs on a VM that
happens to be available here" is not the same as "is native to here," and the gap
is a compiler-shaped hole.

**(c) It runs, but doesn't _use_ your machine.** This is the conviction the whole
portfolio is built on: **native, not portable-that-happens-to-run-here.** A
cross-platform runtime that targets a lowest common denominator leaves the machine
on the table — the Metal GPU, the vector units, the Objective-C runtime, Cocoa,
Core Text, the OS you actually paid for. So these target `arm64-apple-darwin`
specifically and use it to the hilt ([MacGamePane](/posts/macgamepane) on Metal,
the whole [Cocoa bridge](/posts/cocoa-bridge)), and on Windows they reach the real
platform too — [Win32 and COM](/posts/win32-and-com), Direct3D, AVX-512 in the
[assembler](/posts/wrasm). Writing the compiler is how you stop apologizing to the
hardware.

## Because you want to know them, and because you love them (d, e)

**(d) To understand how they really work.** You do not understand a JIT until
you've fought W^X and had to flush an instruction cache by hand; you don't
understand code generation until you've written an encoder and proved it
[byte-for-byte against LLVM-MC](/posts/llvm-in-these-compilers); you don't
understand garbage collection until [it breaks on the first real
workload](/posts/gc-pain-is-the-interface) with 312 tests green. That's why this
portfolio owns its pipeline all the way down — the [macro
assembler](/posts/macro-assembler), the [two kinds of JIT](/posts/two-jits), the
[transparent compiler where every stage is text](/posts/text-at-every-stage). The
understanding *is* the artifact; the running language is the proof you got it.

**(e) Because you loved using them.** Some of this is just that certain languages
are worth keeping in your hands. Forth is a lifetime habit here — the line runs
all the way from a 2020 STC Forth up through [WF66](/posts/wf66) and onto Apple
Silicon in [MF66](/posts/mf66) / [MF67](/posts/mf67). Smalltalk (by way of
Strongtalk) becomes [MACVM](/posts/macvm). BASIC gets its due in
[the interpreter's story](/posts/role-of-the-interpreter). You rebuild the
language because you want to keep writing *in* it — on this machine, on your terms.

## Because they matter, and because you miss them (f, g, h)

**(f) They are cultural history.** A language is a fossil of how a community
thought about computing at a moment in time. BCPL, Smalltalk (Strongtalk, 2002),
Wirth's Modula-2 and the Oberon/Component-Pascal lineage, Corman Lisp, the last
optionally-typed Dart before Dart 2 turned the corner — each encodes a real,
distinct idea about types, objects, effects, memory. Reimplementing one is reading
that idea closely enough to make it run again.

**(g) They deserve to be preserved.** History that can't be *run* is history in a
museum case. Originals rot: Corman's `.img`/`.fasl`, BlackBox's `.odc`, a Dart VM
you can no longer build with a modern toolchain. The preservation that matters is
the kind that boots — a from-scratch, dependency-light reimplementation that a
person can clone and run in ten years. [MACDART](/posts/macdart) keeps the last V1
Dart alive; the Forth line carries a 2020 STC Forth (Alex McDonald's) forward
instead of letting it strand. Preservation here is a verb, not a shelf.

**(h) To recapture something you miss.** Some of it is unashamedly nostalgic — and
that's a legitimate reason to build. The retro graphics stack in
[NewFB](/posts/newfb) — palette framebuffer, sprites, a CRT-scanline shader —
isn't there for benchmarks; it's there because it feels like something. [Little
pixel-art games](/posts/games-for-compiler-testing) double as a serious compiler
test *and* a way back to a machine you remember. You rebuild the feel, on hardware
that can finally render it without breaking a sweat.

## Because they never got to finish — so you extend them (k)

Preservation (g) keeps a language frozen at its last release. But you own the
compiler now (j), which means you don't have to stop at the historical spec — you
can pick the thread up where it was dropped and ask _what would have come next?_
Most languages aren't superseded because the idea ran out; they're superseded
because a market, a vendor, or a fashion moved on.

Dart is the cleanest case. Dart 2 replaced the optionally-typed Dart 1.x with a
sound static type system — a genuine fork in the road.
[MACDART](/posts/macdart) takes 1.24.3, the *last* V1 release, as a **living**
base: what if optional typing had been allowed to keep evolving instead of being
replaced wholesale? The other lines do the same, quietly. BCPL didn't have to stay
in the 1960s — [NewBCPL](/posts/newbcpl) grows it `CLASS`/`EXTENDS`/`VIRTUAL`, SIMD
vector types, and RAII-style scope cleanup. Forth didn't have to stop at threaded
code — [WF66](/posts/wf66) rebuilds its compiler around a token IR and adds an OOP
system, and [MF67](/posts/mf67) pushes it toward an "Objective Forth" that speaks
Cocoa. Modula-2 reaches machine-checked COM, SIMD lane types, and Direct3D in
[Windows Modula-2](/posts/newmodula2). None of these are museum restorations;
they're **counterfactual continuations** — the version the language might have
grown into if the timeline had been kinder. Owning the compiler is what buys you
the right to write that next chapter.

## Because of the moment (i, j)

**(i) Now is the best time to write a compiler.** This is the least obvious reason
and maybe the strongest. The [shared substrate](/posts/shared-substrate) — a
mature backend (LLVM 22), one reusable GUI shell, a shared garbage collector, a
house assembler — meant a new language could reuse the last one's spine and come
up in about a week. And a second shift stacks on top: a living system is now
[drivable and testable by an AI agent](/posts/tcl-for-agents), which changes the
economics of bringing a language all the way to *usable*. It has never been
cheaper, or faster, to go from an idea about a language to a thing that runs.

**(j) To build tools for your future.** A compiler you wrote is a tool you own and
can bend to your needs — not a black box you file bugs against. [MF67](/posts/mf67)
wants Forth to be the Mac's own system language; the [assemblers](/posts/wrasm)
are daily drivers with the whole platform's knowledge built in; [Locus](/posts/locus)
is aimed squarely at working *alongside* AI colleagues. You're not only rescuing
the past — you're machining the tools you'll want to be holding next year.

## The through-line

Eleven reasons, but one shape underneath: **writing a compiler is how you refuse
to accept the languages and machines you were handed as final.** If the
implementation isn't there, or isn't there for your machine, or wastes your
machine — you make one that is and does. If you want to understand it, or you love
it, or it's worth remembering, or you just miss it — the way to hold onto a
language is to make it run again, and then to make it *grow* the way it never got
to. And the moment is right: the substrate to do it quickly exists, and the thing
you build becomes a tool you keep. A compiler is the most leveraged artifact in
computing — it turns text into behavior. Writing one is the most direct way to have
the exact language you want, on the exact machine you have.

## Related

- **(a) not there:** [NewBCPL](/posts/newbcpl) · [NewCP](/posts/newcp) · [NCL](/posts/newcl) · [Windows Modula-2](/posts/newmodula2)
- **(b) not there for your machine:** [MACDART](/posts/macdart) · [MacBCPL](/posts/macbcpl) · [MacNCL](/posts/macncl) · [arm64 vs x64](/posts/arm64-vs-x64)
- **(c) doesn't use your machine:** [Cocoa bridge](/posts/cocoa-bridge) · [Win32 and COM](/posts/win32-and-com) · [MacGamePane](/posts/macgamepane)
- **(d) understand them:** [The macro assembler](/posts/macro-assembler) · [Two things called JIT](/posts/two-jits) · [Text at every stage](/posts/text-at-every-stage) · [The role of LLVM](/posts/llvm-in-these-compilers)
- **(e) loved them:** [WF66](/posts/wf66) → [MF67](/posts/mf67) · [MACVM](/posts/macvm) · [The role of the interpreter](/posts/role-of-the-interpreter)
- **(f/g) history & preservation:** [MACDART](/posts/macdart) · [Not image-based](/posts/not-image-based)
- **(h) recapture the past:** [NewFB](/posts/newfb) · [Games as a compiler test](/posts/games-for-compiler-testing)
- **(i/j) the moment & the future:** [The shared substrate](/posts/shared-substrate) · [Tcl for agents](/posts/tcl-for-agents) · [Locus](/posts/locus)
- **(k) extend / evolve them:** [MACDART](/posts/macdart) (Dart V1, continued) · [WF66](/posts/wf66) → [MF67](/posts/mf67) · [NewBCPL](/posts/newbcpl) · [Windows Modula-2](/posts/newmodula2)
