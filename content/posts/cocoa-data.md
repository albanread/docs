+++
title = "cocoa_data — one SQLite mirror of the macOS SDK, for every compiler"
date = 2026-06-28
description = "The compilers kept re-deriving lossy projections of the Objective-C SDK metadata. cocoa_data mirrors the whole surface into one SQLite database they can all query."
[taxonomies]
tags = ["cocoa", "objc", "sqlite", "python", "metadata", "abi"]
[extra]
repo = "https://github.com/albanread/cocoa_data"
language = "Python + SQLite"
platform = "macOS SDK metadata (consumed by arm64 compilers)"
status = "Working — shared infrastructure"
period = "2026-06 → 2026-07"
downloads = []
+++

_Every compiler in the portfolio needs to know the shape of Cocoa. So they stopped
each re-deriving it and share one database instead._

## TL;DR

- **What:** a shared **SQLite mirror of the macOS Objective-C surface** —
  classes, selectors, `@encode` type encodings, struct layouts, POSIX — for
  every data-driven compiler in the portfolio.
- **Why:** the compilers kept re-deriving narrow, lossy projections of the same
  SDK metadata, each a new extraction pass, file format and consumer. The source
  had all of it the whole time.
- **Consumers:** MacModula2, MacNCL, MacBCPL, MF66, and the runtime bridges in
  MACVM / MACDART.
- **Get it:** [Downloads](#download-run) · [Source](https://github.com/albanread/cocoa_data)

## Where it sits

cocoa_data is the connective tissue of the **Cocoa-bridge** thread. It
generalises the per-language selector tables that started in
[MacModula2](/posts/macmodula2) into one canonical store. See the
[timeline](/timeline).

## What it is

> _From the README —_ "A shared SQLite mirror of the macOS Objective-C surface,
> for every data-driven compiler in the portfolio (MacModula2, MacNCL, MacBCPL,
> MF66, …). The compilers kept re-deriving narrow, lossy projections of the SDK
> metadata… The source had all of it the whole time."

## Why I built it

- _Deduplicating N brittle extraction passes into one authoritative schema._
- _One place to get `@encode` right (HFAs, int-pairs, struct returns) for AAPCS64._

## How it works

- **Ingest:** `ingest_bridgesupport.py`, `ingest_runtime.py`, `ingest_posix.py`
  pull from BridgeSupport, the live Objective-C runtime, and the POSIX headers.
- **Schema:** `schema.sql` defines the tables; `cocoa.sqlite` is the built
  artifact.
- **Derivation:** `encoding.py`, `derive_method_abi.py`, `derive_posix_abi.py`
  turn raw `@encode` strings into AAPCS64 classification tokens (GPR / FPR / HFA
  / int-pair / …) that a code generator can consume directly.
- **Two consumption modes:** compile-time queries (MacModula2/MacBCPL/MF66 emit a
  typed `objc_msgSend` per call site) vs. offline generation (MACVM's `ffi_gen`).
  The runtime bridges (MACVM, MACDART) instead classify from **live `@encode`**,
  using cocoa_data's classifier logic ported into the VM.

## What works today

The mirror is big enough to stop counting by hand — on the order of
**482,000 methods** with their `@encode` shapes and derived ABI tokens
(it's the store [MF67](/posts/mf67) synthesises its message-send thunks
from). There is deliberately no pinned "SDK version": `build.py` rebuilds
`cocoa.sqlite` from the SDK on the machine that runs it, so the database
mirrors *your* Mac by construction rather than a snapshot of mine. The
consumers listed above are wired and live — compile-time queriers
(MacModula2, MacBCPL, MF66/MF67) and the runtime classifiers in MACVM and
MACDART using the same logic ported in-VM.

## Download & run

The built database and tools: the [GitHub Releases page](https://github.com/albanread/cocoa_data/releases).

```bash
git clone https://github.com/albanread/cocoa_data
cd cocoa_data
python3 build.py           # rebuild cocoa.sqlite from the SDK
sqlite3 cocoa.sqlite '.tables'
```

## Notes, dead-ends, lessons

- **"The source had all of it the whole time."** Each compiler's private
  extraction pass was a lossy projection — it kept what that language
  needed that week and threw the rest away, so the next need meant a new
  pass, a new format, a new bug surface. Mirroring the *whole* surface once,
  into a queryable store, ended the archaeology: a new consumer writes a
  SQL query, not an ingest pipeline. The general lesson: when N tools each
  keep a partial copy of the same truth, the fix is one full copy, not a
  better partial one.
- **The ABI corners are exactly the thing to solve once.** AAPCS64's hard
  cases — HFAs, int-pairs, small-struct returns — are where hand-written
  bridges quietly go wrong, per language, per year. `derive_method_abi.py`
  classifies them once, the classification is testable in one place, and
  every compiler consumes tokens instead of re-reading the ABI supplement.
  One correct implementation of the fiddly bit, amortised across the whole
  portfolio: the entire economics of shared infrastructure in a single
  file.

## Links

- Source: https://github.com/albanread/cocoa_data
- Origin of the idea: [MacModula2](/posts/macmodula2)
- Runtime consumers: [MACVM](/posts/macvm), [MACDART](/posts/macdart)
