+++
title = "About"
description = "The thesis behind a portfolio of from-scratch compilers — who builds them, why, and how."
path = "about"
+++

# About this portfolio

I build compilers and language runtimes from scratch, for the pleasure and
the education of it, and increasingly as a serious attempt to make older and
under-served languages **first-class citizens of the machines I actually
own** — Apple Silicon first, and lately Windows-on-ARM as well.

A few convictions run through all of it:

- **Native, not portable-that-happens-to-run-here.** These target
  `arm64-apple-darwin` (and now `aarch64-pc-windows`) specifically and use
  the platform to the hilt — the Objective-C runtime, Cocoa, AppKit, Metal,
  Core Text on one side; Win32, COM, Direct2D, D3D11 on the other — rather
  than hiding behind a lowest-common-denominator layer.
- **Own the pipeline.** Where the early projects lean on LLVM, the later ones
  emit machine code directly through my own assembler and JIT. Fewer
  dependencies, faster builds, and nothing hidden between the source and the
  bytes.
- **Small tools that compound.** An assembler makes a JIT possible; a JIT
  makes a language runtime possible; a shared SDK-metadata mirror makes every
  language speak Cocoa. Each project is a component the next one reuses.
- **Real, runnable artifacts.** Every project here produces something you can
  run. Where the binary is ready, you can [download it](/posts) and try it.

## Software as culture

These languages — BCPL, Modula-2, Smalltalk, Forth, Lisp, Component Pascal —
are not nostalgia. They are a tradition: fifty years of ideas about how
programs should be written, argued out in working systems by people who were
usually right about more than they get credit for. A tradition stays alive
the same way any craft does — by being *practised*, on current machines,
against current standards. So the Smalltalk here JITs on a Snapdragon; the
Forth ships double-clickable Mac apps; the BCPL has a garbage collector and
an IDE. Museum pieces are what you get when you stop maintaining the
argument.

And it should be said plainly: this is done because it is **fun**.
Programming at its best is an interactive, live, slightly theatrical
activity — you type into a workspace, the system answers, a game pane starts
animating. The projects lean hard toward that: live IDEs, hot reload,
Do-It evaluation, little pixel-art games as compiler tests. If a toolchain
can't entertain its own author, something has gone wrong somewhere.

## The engineer

I'm Alban Read — a British engineer, sixty-one this year, programming since
I was a teenager, which puts my first programs somewhere in the late 1970s.
Enough machines have come and gone since then that I no longer confuse the
current one for the last one; hence the portfolio's habit of porting.

Code and releases live on GitHub: [albanread](https://github.com/albanread)
— which is also the best way to reach me.

## How the work happens

Much of the recent work is done **with Claude** (Anthropic's coding agent),
and I am open about that because the method matters more than the fashion.
This is not "vibe coding" — prompting until something plausible compiles and
hoping. It is engineering with a very fast collaborator: the agent writes
probes, runs builds, dumps compiler IR, and holds hypotheses *until the
measurements disagree* — and the surrounding discipline is what makes that
safe. Differential oracles gate every native encoder byte-for-byte against
LLVM-MC. Test batteries run the IDEs headless over a TCL control plane.
Claims in these articles trace to numbers in the repositories. When the
agent is wrong — it frequently is — the tests say so before I have to.

The result is a curious inversion worth noticing: the practices this trade
has preached for fifty years — tests first, oracles, honest logs,
reproducible builds — turn out to be exactly what makes agents effective.
Good engineering was always the point; the agents just made it
non-negotiable.

## Licensing & reuse

The writing here is mine; quote it with attribution. The code is licensed
per repository: my own projects carry their licenses in-repo, and the ports
keep their upstream terms — the Dart VM ports, for instance, remain
BSD-3-Clause (Copyright the Dart project authors, with their patent grant),
with the port layers separately owned. Third-party components a project
bundles (QBE, LLVM, Factor, SQLite and friends) keep their own licenses,
noted in each article's download section. Binaries come from each project's
GitHub Releases page, checksummed.
