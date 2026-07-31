+++
title = "{{TITLE}}"
date = {{DATE}}
description = "TODO: one-sentence summary for previews and search."
[taxonomies]
tags = ["TODO"]
[extra]
repo = "https://github.com/albanread/{{SLUG}}"
language = "TODO"
platform = "Apple Silicon (arm64-apple-darwin)"
status = "TODO: e.g. under development / working / released"
period = "TODO: e.g. 2026-06 → 2026-07"
downloads = []
+++

<!--
  ARTICLE STUB — expand each section. Delete these comments as you go.
  Screenshots → static/images/{{SLUG}}/  →  reference as /images/{{SLUG}}/name.png
  Binaries    → static/downloads/{{SLUG}}/ (see scripts/collect-downloads.sh)
-->

_TODO: a one-line hook that makes someone want to read on._

## TL;DR

- **What:** …
- **Stack:** …
- **Platform:** …
- **Status:** …
- **Get it:** [Downloads](#download-run) · [Source]({{REPO}})

## Where it sits

_Lineage / what came before and after. Link the [timeline](/timeline)._

## What it is

_The honest description. What problem it solves, what it is and isn't._

## Why I built it

_The motivation — the itch, the constraint, the language you wanted on the Mac._

## How it works

_Architecture. Front-end → IR → back-end → runtime. The interesting decisions,
the hard parts, the diagram if you have one._

## What works today

_A concrete, checkable list of what runs. Be specific; link tests/benchmarks._

## Screenshots

> _Add screenshots to `static/images/{{SLUG}}/`._

![caption](/images/{{SLUG}}/01.png)

## Download & run

Prebuilt binaries are on the [GitHub Releases page]({{REPO}}/releases). (The
"Download from Releases" button above links here too, straight from this
article's `repo` field.) Use `scripts/prep-release.sh` to generate a
checksummed download table to paste in.

```bash
# TODO: exact run instructions, e.g.
# xattr -d com.apple.quarantine ./{{SLUG}} 2>/dev/null || true
# ./{{SLUG}} --help
```

Build from source:

```bash
git clone {{REPO}}
cd {{SLUG}}
# TODO: build command
```

## Notes, dead-ends, lessons

_The war stories. What surprised you, what you'd do differently._

## Links

- Source: {{REPO}}
- Related: …
