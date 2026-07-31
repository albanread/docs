# The Compiler Portfolio — Blog

A blog documenting a series of from-scratch compilers, JITs, assemblers and
language runtimes for **Apple Silicon (macOS arm64)** and their Windows
predecessors. One article per project, a shared timeline, and download links to
the actual executables.

- **Engine:** [Zola](https://www.getzola.org) (single Rust binary, static output).
- **Repo / remote:** `https://github.com/albanread/docs.git`
- **Hosting:** Cloudflare Pages (builds this repo) — or any static host.
- **Downloads:** each project's **GitHub Releases** (linked automatically from
  every article's `repo` field).

---

## Quick start

```bash
brew install zola          # one-time
./scripts/serve.sh         # live preview at http://127.0.0.1:1111
zola build                 # production build → public/
```

## Layout

```
blog/  (= the albanread/docs repo root)
├── config.toml            ← Zola config (set base_url before publishing)
├── README.md  PLAN.md     ← this file; the editorial plan + status table
├── content/
│   ├── _index.md          ← landing page
│   ├── about.md  timeline.md
│   └── posts/<slug>.md    ← one article per project
├── templates/             ← Zola/Tera theme (base, index, section, page, post, tags)
├── static/
│   ├── css/style.css      ← the theme's styles (light/dark)
│   └── images/<slug>/     ← screenshots for each article
└── scripts/
    ├── serve.sh           ← local preview
    ├── new-post.sh        ← scaffold a new article from post-template.md
    ├── post-template.md
    └── prep-release.sh    ← checksums + a paste-ready download table for a Release
```

`static/` is copied to the site root, so `static/images/macdart/repl.png` is
served at `/images/macdart/repl.png`.

## Writing & extending

Add an article:

```bash
./scripts/new-post.sh my-project "My Project"
```

That creates `content/posts/my-project.md` (from `scripts/post-template.md`) and
`static/images/my-project/`. Then:

- Fill in the section skeleton the template provides.
- Set the front-matter `repo` — the theme turns it into the **Source** and
  **Download from Releases** buttons automatically.
- Drop screenshots into `static/images/<slug>/`, reference them as
  `![caption](/images/<slug>/shot.png)`.
- Add a row to [`PLAN.md`](PLAN.md) and an entry in
  [`content/timeline.md`](content/timeline.md).

Front-matter is TOML (`+++ … +++`); custom fields live under `[extra]`.

## Downloads (via GitHub Releases)

Binaries are **not** in this repo. Each project publishes its executables on its
own GitHub Releases page (2 GiB/file, free CDN, next to the source), and every
article links there via its `repo` field. To cut a release with a checksummed
download table for the article:

```bash
./scripts/prep-release.sh albanread/MACDART v1.24.3-macdart \
    ../MACDART/macdart/build-release/dart
```

It prints a Markdown table (file · size · SHA-256) to paste into the article and
the `gh release create …` command to upload the assets + `SHA256SUMS`.

> **Sign + notarize** macOS binaries before releasing (especially the JITs, which
> need `com.apple.security.cs.allow-jit`), or users must clear the quarantine bit
> by hand. Note the requirement in each article's download section.

## Deploying on Cloudflare Pages

1. Push this repo to `https://github.com/albanread/docs.git`.
2. Cloudflare dashboard → **Workers & Pages → Create → Pages → Connect to Git**,
   pick `albanread/docs`.
3. **Framework preset: Zola.** Build command `zola build`, output directory
   `public`.
4. **Add an environment variable `ZOLA_VERSION`** (e.g. the output of
   `zola --version`) — without it, Pages uses a very old default that will fail
   to build this theme.
5. Deploy. Every `git push` rebuilds.

Set `base_url` in `config.toml` to your Pages URL (`<project>.pages.dev`) or your
custom domain before the first production deploy. (For correct URLs on preview
deploys you can instead use build command `zola build --base-url $CF_PAGES_URL`.)

**Self-hosting alternative:** `zola build` emits a plain `public/` directory —
serve it from nginx/Caddy and you're done (Caddy gives automatic HTTPS in a
two-line config). Nothing about the content is Cloudflare-specific.
