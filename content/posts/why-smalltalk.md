+++
title = "Why Smalltalk — and how we ended up with two, or several"
date = 2026-08-13
description = "I have wanted a Smalltalk of my own since the August 1981 Byte — not to admire behind glass, but to write programs in. Strongtalk wouldn't build for me; Squeak and Pharo — the living originals — weren't my style; so I wrote one. Then it split: by CPU, by operating system, and finally across two virtual machines — the one I built, and the one I borrowed from Google, which turned out to be a cousin of the Smalltalk I started from."
[taxonomies]
tags = ["essay", "smalltalk", "strongtalk", "dart", "vm", "jit", "history"]
+++

_The balloon went up, for me, in the August 1981 *Byte* — the Smalltalk issue,
the one with the hot-air balloon lifting off the cover. I have wanted a Smalltalk
of my own ever since. Not to keep behind glass, and not merely to preserve: to
**write programs in**, on whatever machine I happen to be sitting at. This is the
story of how that single want turned into two virtual machines, and then quietly
into several._

## TL;DR

- **The want was never "a Smalltalk."** It was *a Smalltalk I can write programs
  in, on my own machines* — and my machines are plural and keep changing.
- **Strongtalk was the lodestar, and I could never run it.** Released in 2002,
  first as documentation I read cover to cover, then as full C++ source I could
  never get to build on anything I owned. [MACVM](/posts/macvm) is my own run at
  that idea, from a blank file.
- **Squeak is the original and true Smalltalk — and it taught me the language.**
  Revived by the people who made Smalltalk-80, it keeps the real thing alive, and
  without it I'd never have learned Smalltalk at all. The gap is purely mine: I
  want native controls and I'll happily trade some dynamism for speed, where
  Squeak's genius runs the other way — toward Morphic and a wholly live,
  self-drawn world.
- **Building my own split it in two immediately** — along the machine. One
  portable front and middle end, an AArch64 back half on the Mac
  ([MACVM](/posts/macvm)) and an x86-64 one on Windows ([WINVM](/posts/winvm)).
- **Wanting it faster, I remembered Dart — and learned two things.** I couldn't
  *borrow* Dart's speed for my own VM (I already had the Smalltalk parts, and I
  will never have Google's person-years). But I could **host my Smalltalk on
  Dart's VM** ([MACDART](/posts/macdart)) — and that VM turns out to be a cousin
  of Strongtalk.
- **So: two VMs, the built and the borrowed** — and each then split by CPU and OS
  again, until "two" was really "several."

## The balloon went up in *Byte*

Some people meet Smalltalk and see a slow, strange language with an odd syntax.
I met it on a magazine cover and saw a whole world you could live inside — a
system made of objects sending each other messages, where the environment *was*
the language and you edited the thing while it ran. It never quite let go. The
promise underneath the balloon was that a program needn't be a document you
compile and launch; it could be a place you inhabit and reshape from within.

What I wanted from it, though, was narrower and more stubborn than the poster
version. I didn't want to admire Smalltalk. I wanted to keep it in my hands and
write real programs with it — on the machines I actually own, for years, the way
you keep a language you [loved using](/posts/why-write-compilers).

## What I actually wanted

It is worth being precise about the want, because it rules out most of the ways
you might scratch it.

I did not want to *emulate* Smalltalk — to reconstruct a museum piece and put it
back behind glass. I wanted a Smalltalk that was **mine to program in**: one I
could open on a Tuesday, add a class to, and ship something small from. That is a
higher bar than "it runs the old benchmarks," and a different bar from "it is
faithful to 1980." A language you write programs in has to build on your machine,
boot quickly enough to be worth opening, and let you get work out of it without
first adopting someone else's idea of a user interface.

Two things about Strongtalk specifically had lodged themselves as
non-negotiables. First, that a dynamic language could be genuinely *fast* — the
adaptive, profile-guided [kind of compilation](/posts/two-jits) that Self
pioneered and Strongtalk proved on Smalltalk. Second, and less remarked on, that
Smalltalk could be **optionally typed** — Strongtalk's pluggable type system, put
on top of the language without making it rigid.

And I knew two things about my own taste that cut against Smalltalk's purest
instincts. I am happy to be **less dynamic in order to be faster** — to accept
optional types, sealed representations, a little less "change anything at any
instant" — when speed is the reward. And I want **native controls**: the
platform's real buttons, windows and text, drawn by the operating system, not a
faithful simulation of them painted by the language. I wanted all of this, and I
wanted it in something I owned.

## Failing to run Strongtalk, and bouncing off the living ones

The obvious move was to run the real thing. Strongtalk went public in 2002 —
the documentation first, which I enjoyed enormously, then the full C++ source.
I spent a great deal of time trying to make that release actually *go* on my own
hardware, and I failed. It was a late-1990s Windows codebase, and the years had
not been kind to it; what builds cleanly the day it ships rarely builds a decade
later on a machine that didn't exist yet. The most influential system I knew was,
for me, an unbootable brick — which is exactly the fate that [befalls software
whose only form is a binary or an image](/posts/not-image-based).

The living Smalltalks were the other obvious move, and I gave them a fair go — and
here I have to choose my words with care, because it would be easy to sound
dismissive of something I owe a great deal to. **Squeak is the original and true
Smalltalk.** It was brought up in 1996 by Alan Kay, Dan Ingalls, Ted Kaehler and
colleagues — the people who built Smalltalk-80 in the first place — and it carries
the real lineage forward, unbroken, from Xerox PARC to a system you can download
and run tonight. Pharo grows from that same root. These are not imitations of
Smalltalk; between them they *are* Smalltalk, alive and cared for. And **if it were
not for Squeak I would never have learned Smalltalk at all** — everything in this
essay is downstream of an education Squeak gave me for nothing.

So the distance is entirely mine, and it is a matter of taste, not merit. Some of
it is exactly the two wants above: I lean toward native controls and toward a
system content to be a little less dynamic if that buys speed, where Squeak's
genius runs the other way — toward Morphic and a world it draws and keeps wholly
live itself. I never got on with Morphic; I could open it, admire it, and still
never make anything of my own inside it. None of that is a criticism of Squeak —
it is a description of me, and of a different set of wants. Wanting a workshop of
your own is no verdict at all on the one that taught you the craft.

So the shelf held a museum piece I couldn't switch on and a set of living systems
that weren't for me. The only way left to have the Smalltalk I actually wanted was
the same conclusion this whole portfolio keeps reaching: [write it
yourself](/posts/why-write-compilers).

## So I built my own — and it split in two

[MACVM](/posts/macvm) is that Smalltalk, from an empty file. It has its own
adaptive compiler in the Strongtalk mould — inline caches, type feedback,
deoptimization, on-stack replacement — generating code through its own AArch64
assembler, so the speed is genuinely mine to answer for: our fault when it's
slow, and the Strongtalk design's credit when it's fast. It boots from `.mst`
source text rather than thawing an image, and it carries the other thing I came
for — an optional, Strongtalk-style type checker over the core library. It is, at
last, a Smalltalk I write programs in.

And the moment it was real, "my machines" asserted themselves. The modern Mac is
Apple Silicon and got the first build; the Windows box — the real reason x86-64
matters here at all — is x64 and got the next. There is an old Intel Mac besides,
but it runs hot, an English summer runs hotter, and so its x64 port is *scheduled*
for colder weather rather than written. Two CPU families and two operating systems
between them, and that is all it takes. A language you actually use
has to be *on* the machine in front of you, not on a VM that merely happens to run
there; that conviction — [native, not portable-that-happens-to-run-here](/posts/why-write-compilers)
— is the whole point, and it has a cost, and the cost is that one Smalltalk became
two builds.

They are not two Smalltalks. [WINVM](/posts/winvm) shares MACVM's entire portable
front and middle end — the reader, the bytecode, the interpreter, the adaptive
optimiser, the object model, the world source — and diverges only where the metal
and the OS force it to: an x86-64 back half instead of AArch64, and a
WebView2-over-COM host where the Mac uses Cocoa. Same language, two back halves,
split precisely along the seam the hardware gives you. That was the first "two,"
and it was already teaching the lesson the rest of the story just keeps
restating: the splits are never in the *language*; they are in the machine
underneath it.

## Wanting it faster, I remembered Dart

Once you live in your own VM, the next itch is inevitable: could it be faster? And
I remembered Dart, which had a reputation for real speed, and went to study it —
half hoping to carry some of that speed home into my own engine.

That part did not really work, and the reason is worth saying plainly because it
is the honest half of this essay. My VM was already fast for the same reasons
Dart is: we already had the parts that make a dynamic language quick — the
adaptive compiler, the caches, the deopts — because those *are* the Strongtalk
idea, and copying them out of Dart would have been copying them from myself. What
Dart has that I do not, and never will, is the person-years Google poured into it:
a decade of a large, brilliant team on one production VM. You cannot borrow that
by reading the source over a weekend. "Study the fast thing and get faster" is a
tempting plan and mostly a fantasy.

## What I couldn't borrow, and what I could

But there was a second door, and it was open. I couldn't borrow Dart's speed *into*
my engine — so I put my Smalltalk *onto* Dart's engine instead.
[MACDART](/posts/macdart) is the Dart 1.24.3 VM — the last of the optionally-typed
V1 line — brought to Apple Silicon, and it hosts my entire Smalltalk world as a
*second language* on that borrowed engine. The same class browser, the same
`.mst` world, the same "Accept saves" live-edit contract — running on someone
else's VM.

And here the story closes a loop I did not plan. Dart's VM is not merely *like*
Strongtalk; it is descended from it. The line runs Self (1986) → Strongtalk
(2002) → Java's HotSpot → V8 → Dart, with some of the same people and unmistakably
the same ideas carried the whole way — Lars Bak the throughline from Animorphic to
Google. I went looking for a faster engine and came home to a cousin of the one I
started from. Even the optional typing rhymes: Strongtalk's pluggable types, Dart
1.x the last optionally-typed Dart, and my Smalltalk wearing Strongtalk-style
signatures on both engines at once. Two roads from the same crossroads — which is
the same convergence, seen [from another angle](/posts/isolates-and-vms), that let
Dart's isolates host my worker-VMs without a redesign.

The engineering coda is the most humbling and the most useful part. Making the
borrowed Smalltalk *fast* — closing a 4.6× loss on DeltaBlue down to a tie with
Cog, no VM source changed — turned out to have almost nothing to do with
borrowing Google's compiler magic. It was [removing the tax the emulation was
paying twice](/posts/optimizing-smalltalk-on-dart): method caches, interned
symbols, a lookup that re-resolved a class by name on every send. The oldest ideas
in dynamic-language implementation, the very ones Smalltalk-80's authors were
fighting in 1983, rediscovered one layer at a time. You don't get speed by
copying a genius; you get it by stopping your own program from doing the same work
over and over.

## Two — or several

Then the borrowed engine did exactly what the built one had done: it followed my
machines. MACDART is Apple Silicon; the same Dart-hosted Smalltalk already ran on
Windows x64; and it now runs [native on Windows-on-ARM](/posts/windart-arm64), a
Snapdragon laptop where you build it and run it on the very same silicon. The
split is always the same two seams — the **CPU** (arm64 or x86-64) and the **OS**
(macOS or Windows) — because those are the only two things that actually change
underneath a language.

The Smalltalk reaches three of the four corners that grid describes. The fourth —
x86-64 *macOS*, the old Intel Mac — is the one port I have *scheduled* rather than
written, held back for the most English of reasons: the machine runs hot, the
summer runs hotter, and I am waiting for colder weather to sit beside it. A grid
with one corner pencilled in for the autumn is still, I think, fairly called
*several*.

So take the census. There is one Smalltalk world, in source. It runs on the VM I
**built** — one engine, two back halves, arm64 and x86-64. And it runs on the VM I
**borrowed** — one engine, its own set of back halves across the same corners.
Two virtual machines; several binaries. That is the "two — or several": two in the
sense that matters (the engine I wrote and the engine I took), several in the
sense you count on disk once you multiply each by the machines you own.

The plural is not sprawl, and it is not a hedge. Running the same Smalltalk on two
independent VMs is the single most useful piece of test equipment I have: when
one wins a benchmark the other loses it, and having something to lose to is what
made both of them faster. The built VM keeps the allocation-bound work on its
generational scavenger; the borrowed VM takes the compute-bound work on Google's
optimiser; and neither would have found its slow spots without the other standing
next to it running an identical workload.

## The through-line

I never set out to have two, let alone several. I set out to have a Smalltalk I
could write programs in, on my own machines — and *my own machines* is a moving,
plural target: an old Mac, a modern Mac, a Windows box, a Snapdragon laptop. A
language you genuinely use has to follow you onto every one of them, and the price
of that, paid in full, is a split along the CPU and a split along the OS. That
isn't the language fragmenting; it's the same language reaching each machine
natively instead of hiding behind a lowest-common-denominator runtime.

The two VMs are two different bets on the same idea. I built one to *understand*
how fast a Smalltalk can be made to go, owning every instruction; I borrowed one
to *see* how fast the idea goes when a decade of a great team is under it. They
turned out to be relatives, which is the deepest thing I learned here — that
"make a dynamic language fast" has essentially one good answer, and everyone who
takes it seriously ends up in the same place. What keeps two-or-several from being
a mess is that it is, underneath, exactly one Smalltalk: one world, kept as
[source and booted from text](/posts/not-image-based), not frozen into an image —
so it can be rebuilt on any machine I need it on, and none of it is trapped
anywhere.

I wanted a Smalltalk to write programs in. I have one. It just happens to run
everywhere I do.

## Related

- [MACVM](/posts/macvm) — the built engine, from a blank file (Apple Silicon)
- [WINVM](/posts/winvm) — the same Smalltalk, the x86-64 back half (Windows)
- [MACDART](/posts/macdart) — the borrowed engine: my Smalltalk hosted on Dart's VM
- [WINDART on Snapdragon](/posts/windart-arm64) — the borrowed engine, native on Windows-on-ARM
- [The tax below the flow graph](/posts/optimizing-smalltalk-on-dart) — what "making it faster" on the borrowed VM actually was
- [Isolates and VMs](/posts/isolates-and-vms) — the same conclusion, reached twice, from the concurrency side
- [Two things called JIT](/posts/two-jits) — the adaptive compilation Strongtalk and Dart share
- [Not image-based](/posts/not-image-based) — booting a Smalltalk from source, which is what lets it run everywhere
- [Why write compilers](/posts/why-write-compilers) — the general case of this specific want
