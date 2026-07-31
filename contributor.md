# Contributing

This repo (`albanread/docs`) is the **compiler-portfolio blog** — a [Zola](https://www.getzola.org)
static site, one article per project, deployed to Cloudflare Pages on every push
to `main`. This guide is how to work on it without breaking the build or the
conventions. If you're adding or editing an article, read the two **⚠️ footguns**
below — both have already bitten us once.

## Setup

```bash
brew install zola          # needs 0.22.x (repo built against 0.22.1)
zola --version             # confirm
```

## Local development

```bash
./scripts/serve.sh         # live preview + reload at http://127.0.0.1:1111
zola build                 # production build → public/ (also a full validity check)
```

`zola build` is also your pre-flight check: it validates every internal link and
**anchor** and fails on any broken one. **Never push a red build** — Cloudflare
Pages runs the same `zola build`, so a local failure is a failed deploy.

## Adding an article

**⚠️ Footgun #1 — always scaffold with the script. Do not hand-copy an existing
article.** Hand-copying is what has twice reintroduced a broken-anchor build
failure.

```bash
./scripts/new-post.sh <slug> "Article Title"
```

That creates `content/posts/<slug>.md` from `scripts/post-template.md` (with the
slug, title, date and `repo` pre-filled) and the matching
`static/images/<slug>/` folder. Then:

1. Fill in the section skeleton the template provides.
2. Set the front-matter `[extra] repo` to the project's GitHub URL — the theme
   turns it into the **Source** and **Download from Releases** buttons
   automatically.
3. Add a row to [`PLAN.md`](PLAN.md) (status table) and an entry in
   [`content/timeline.md`](content/timeline.md).
4. `zola build` → confirm 0 errors/0 warnings before committing.

### Front-matter conventions

TOML, between `+++` fences. The body starts with the one-line *hook* — **no `#`
H1**; the theme renders the title from `title`. Custom fields live under
`[extra]`:

```toml
+++
title = "…"
date = 2026-07-31
description = "One sentence for previews and search."
[taxonomies]
tags = ["…"]
[extra]
repo = "https://github.com/albanread/<Repo>"   # drives the Source/Download buttons
language = "Rust + LLVM"                         # shown in the facts block
platform = "Apple Silicon (arm64-apple-darwin)"
status = "Working"                               # shown as a badge
period = "2026-06 → 2026-07"
+++
```

### ⚠️ Footgun #2 — in-page anchors must match Zola's slugs

Zola slugifies headings and **validates every `#anchor` at build time**. The
heading `## Download & run` becomes `#download-run` (the `&` is dropped and the
spaces collapse to a **single** hyphen — *not* `#download--run`). If you write an
in-page link by hand, build and confirm it resolves. The template already uses
the correct anchors; leaving them alone is the safe path.

## Screenshots

Put images in `static/images/<slug>/` and reference them site-relative:

```markdown
![caption](/images/<slug>/repl.png)
```

Keep them reasonably sized (they're committed to the repo and shipped to every
visitor). PNG for UI/screenshots.

## Downloads (binaries)

**Binaries are never committed here.** Each project ships its executables on its
own **GitHub Releases** page, and articles link there automatically via `repo`.
(Rationale: the release binaries run 50–90 MiB, over Cloudflare Pages' 25 MiB
per-file cap; Releases give 2 GiB/file and a free CDN next to the source.)

To cut a release with a checksummed download table for the article:

```bash
./scripts/prep-release.sh <owner/repo> <tag> <built-binary> [more…]
```

It prints a Markdown table (file · size · SHA-256) to paste in, and the
`gh release create …` command to upload the assets + `SHA256SUMS`. Sign +
notarize macOS binaries before releasing (the JITs need
`com.apple.security.cs.allow-jit`) and say so in the article's download section.

## Commits & pushing

- Conventional-commit-style subjects, e.g. `docs(posts): …`, `fix(build): …`.
- Keep changes buildable: run `zola build` and confirm it's green first.
- `public/` and build caches are git-ignored — don't commit them.
- `main` is the deploy branch. Pull before you push (others commit here too); a
  clean fast-forward is the normal case.

## What NOT to touch without discussion

- `config.toml` `base_url` (set once for the production domain) and the
  `[markdown.highlighting]` block (theme names are version-sensitive — see the
  0.22 notes in the repo history).
- The `templates/` theme layout, unless you're intentionally reworking the design.

## Editorial notes

- `superterminalmetal` (a terminal) and `raven` (design fiction) are flagged as
  optional/non-compiler in [`PLAN.md`](PLAN.md) — keep them clearly labelled or
  drop them; don't quietly mix them in with the compiler articles.
