+++
title = "Not image-based: source in, running system"
date = 2026-07-31
description = "Lisp, Smalltalk, and Forth are the three language families most married to the memory image — and this portfolio has one of each, none of them image-based. NCL recompiles from source; the Forths boot from source; MACVM commits to no heap image and always boots by compiling its .mst world. We pay a startup tax, especially the Lisp, and we pay it gladly, because an image is opaque and locks people out. The one thing I kept from the image — its in-process organization — I got by packing source into SQLite, rebuilt from disk."
[taxonomies]
tags = ["image", "source", "smalltalk", "lisp", "forth", "transparency", "sqlite"]
+++

_The three language families most in love with the memory image are Lisp,
Smalltalk, and Forth. This portfolio has one of each — [NCL](/posts/newcl),
[MACVM](/posts/macvm), the [Forths](/posts/wf66) — and not one of them is
image-based. That is a stance, and it cost us startup time to hold it. I'll say it
plainly: I don't like images. But I do like one thing an image gives you, and I
found a way to keep it without the rest._

## TL;DR

- **No memory image.** NCL doesn't run `.img`/`.fasl` — it recompiles from source.
  The Forths boot by loading source. MACVM's spec commits to *"no heap/memory
  image — always boots by compiling `world/*.mst` source text."*
- **The price is startup**, worst for the Lisp, which recompiles its whole stdlib
  every launch. Worth it.
- **The payoff is transparency**: source is reviewable, editable, greppable,
  diffable, versioned in Git, and rebuildable — by a person *or* an agent.
- **Images lock people out**: opaque, special-purpose, un-collaborable, a knowledge
  prison openable by exactly one tool.
- **The one image benefit I kept** — in-process organization — I got by storing
  *source* in a versioned SQLite database, **rebuilt from disk**. The container got
  better; the content stayed text.

## What an image is, and why those languages love it

A memory image is a serialized snapshot of a running system's entire live object
heap. You don't build the world from source at startup; you *thaw* a world that was
frozen earlier. Smalltalk has its `.image`; Lisp has `save-lisp-and-die` producing
a `.img`, plus `.fasl` files; Forth has the turnkey saved dictionary. And the appeal
is real and seductive: startup is instant because nothing is compiled; the world is
*live and persistent*, sculpted over months or years and carried forward; and you
get glorious in-process organization — the class browser, the workspace, a whole
system you navigate from inside itself.

It is a beautiful model. It is also a walled garden with a single gate, and only
the tool that built the image holds the key.

## The commitment: boot from source

Every one of these systems refuses the image and rebuilds the world from source
text instead.

- **[NCL](/posts/newcl) — the Lisp.** It deliberately "does not run the original's
  compiled artifacts (`.img`, `.fasl`) — recompile from source," and it self-hosts
  its ~800-form standard library by *compiling it, from source, at boot.* There is
  no image to save.
- **The [Forths](/posts/wf66).** The world comes up from its `.masm` kernel and a
  loaded `lib/core.f`, not a restored binary dictionary. (There's a boot snapshot to
  make startup quick, but it's a derived optimization — the *creating source* is
  kept, and it's the source of truth.)
- **[MACVM](/posts/macvm) — the Smalltalk, and the hard case.** Smalltalk *is* the
  image; the entire tradition is a persistent live heap you save and reopen. MACVM
  breaks the deepest convention of its own family, and its spec says so outright:

> "no heap/memory image — MACVM always boots by compiling `world/*.mst` source
> text." — MACVM `IMAGE.md`, quoting `SPEC.md` §3.2

A Smalltalk that boots from a directory of source files is almost a contradiction
in terms. That's the point.

## The price, and why it's worth it

The bill comes due at startup. Compiling a language's whole standard library from
source on every launch is *slow* — the Lisp feels it most, paying a real
recompile-the-world cost each time it starts. An image would make that instant.

We pay it anyway, because what the price buys is **transparency**, and transparency
outlasts a few seconds of boot. Source you can *read* — audit it, understand it,
learn from it. Source you can *edit* — change it, rebuild, run. Source you can
*diff and version* — it lives in Git with history, blame, review, and pull
requests. Source is *text* — the one medium a human and an [agent](/posts/text-at-every-stage)
can both read, and a tool can grep. And source is *reconstructible* — "source in,
running system," the whole thing rebuildable from files you can see. None of that
survives contact with an opaque blob.

## Why I don't like images

The case against the image is the case for everyone who is not the person sitting in
front of the live session:

- **Opaque.** You cannot see what's in an image without the tool that made it. It's
  a heap of pointers, not something you can read.
- **Special-purpose, and perishable.** Only that VM — often that *version* — can
  open it. An image bit-rots: when the runtime moves on, the image becomes an
  unbootable brick, and everything in it is gone.
- **A knowledge prison.** Decades of a Smalltalk image's evolution can be trapped in
  a blob no current tool can extract or review. The history of computing is littered
  with brilliant systems locked inside images nobody can open anymore. When the VM
  dies, the knowledge dies with it.
- **Un-collaborable.** You cannot send a pull request against an image, cannot review
  its diff, cannot merge two people's changes. It is a single-owner artifact by
  construction.

An image optimizes ruthlessly for the live session and charges the cost to everyone
outside it — the reviewer, the future maintainer, the collaborator, the agent, the
version-control system. Source optimizes for exactly those people. That's the whole
disagreement, and I know which side I want to be on.

## The one thing I kept: organization without the prison

Here's the honest part, and the nuance that matters. The flat-file source model
gives up *one* genuinely good thing the image had: **in-process organization** — the
class browser, the query surface, the smooth interactive edit that never touches a
text editor. That's worth having, and MACVM takes it back — without taking back the
image.

It packs the *same source* into a **versioned SQLite database**. And the trick is
what the database stores:

> "it stores **text** (class/method source, as Strings) plus small metadata … **no
> oops, no heap pointers, no compiled-code-as-the-source-of-truth.** Booting from it
> is still 'boot from source' … just from SQLite rows instead of flat files." —
> MACVM `IMAGE.md`

So the SQLite "image" is not a memory image at all — it's `world/*.mst`
"reimplemented as a queryable, versioned database … **a change of container, not a
change of what's stored or how MACVM boots.**" You get the Smalltalk-browser
experience — browse classes, list a package, reorder with a sparse index, keep the
last hundred edits with undo, save from the GUI per keystroke — over content that is
still transparent source text. It's better than flat files for interactive editing
(a text file means shelling out to git and re-scanning on every click; a table has
indexes and versions), and it gives up none of the transparency, because it's text,
it's diffable back out, and **the world is rebuilt from disk.** The container got
smarter; the content stayed source. That is how you get the image's ergonomics
without its walls.

## The through-line

An image is seductive and it is a lock-out at once: instant, alive, richly
organized — and openable by exactly one tool, on exactly one bad day away from being
an unreadable brick. I took the three languages most bound to that model and made
them boot from source instead, paid the startup tax to do it, and got back
everything an image quietly confiscates: review, edit, Git, text, reconstruction,
collaboration, and a system a person or an agent can read all the way down. The one
gift of the image I actually wanted — organized, browsable, editable code, live in
the process — I kept, by storing *source* in a queryable database and rebuilding the
world from disk rather than freezing a heap. "Source in, running system" isn't a
slogan; it's the guarantee that nothing about the system is hidden from the people
who didn't happen to be in the room when it was running. That's why I don't like
images — and why I didn't need one.

## Screenshots

> _Add to `static/images/not-image-based/`: NCL recompiling its stdlib from source
> at boot (with the startup time); a `.mst` world directory diffing cleanly in Git;
> MACVM's SQLite source browser next to the same class as flat text; a boot log that
> reads "compiling world" not "loading image."_

![Left: an opaque memory image, one tool can open it. Right: source files + a SQLite source DB, both text, both rebuildable, both in Git.](/images/not-image-based/01.png)

## Related

- [Text at every stage](/posts/text-at-every-stage) — the same value: text is legible to humans and agents; opaque forms lock everyone out
- [Test, test, test](/posts/test-test-test) — you can only measure against a standard what you rebuild from source
- [MACVM](/posts/macvm) — a Smalltalk that boots from `.mst` source, browsable via a SQLite source DB
- [NCL](/posts/newcl) — a Lisp that recompiles its world instead of thawing an `.img`
