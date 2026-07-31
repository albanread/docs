+++
title = "About"
description = "The thesis behind a portfolio of from-scratch compilers for Apple Silicon."
path = "about"
+++

# About this portfolio

> _TODO: make this yours — bio, motivation, contact, licensing stance. The draft
> below is a starting point drawn from the project READMEs._

I build compilers and language runtimes from scratch, for the pleasure and the
education of it, and increasingly as a serious attempt to make older and
under-served languages **first-class citizens of Apple Silicon**.

A few convictions run through all of it:

- **Native, not portable-that-happens-to-run-here.** These target
  `arm64-apple-darwin` specifically and use the platform to the hilt — the
  Objective-C runtime, Cocoa, AppKit, Metal, Core Text — rather than hiding
  behind a lowest-common-denominator layer.
- **Own the pipeline.** Where the early projects lean on LLVM, the later ones
  emit arm64 directly through my own assembler and JIT. Fewer dependencies,
  faster builds, and nothing hidden between the source and the bytes.
- **Small tools that compound.** An assembler makes a JIT possible; a JIT makes
  a language runtime possible; a shared SDK-metadata mirror makes every language
  speak Cocoa. Each project is a component the next one reuses.
- **Real, runnable artifacts.** Every project here produces something you can
  run. Where the binary is ready, you can [download it](/posts) and try it.

## The engineer

_TODO: name, background, links (GitHub: `albanread`), and how to get in touch._

## Licensing & reuse

_TODO: state the license for the writing and for the binaries. Several projects
bundle third-party components (QBE, LLVM, etc.) under their own licenses — note
those in each article's download section._
