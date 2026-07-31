#!/usr/bin/env bash
# Scaffold a new article from scripts/post-template.md.
#
# Usage: ./scripts/new-post.sh <slug> "<Title>" [YYYY-MM-DD]
#   slug   lowercase, hyphenated, no spaces (also used for asset folders)
#   title  human-readable article title
#   date   optional; defaults to today
#
# Creates:
#   content/posts/<slug>.md
#   static/downloads/<slug>/.gitkeep
#   static/images/<slug>/.gitkeep
set -euo pipefail

here="$(cd "$(dirname "$0")/.." && pwd)"
slug="${1:-}"
title="${2:-}"
date="${3:-$(date +%F)}"

if [[ -z "$slug" || -z "$title" ]]; then
  echo "usage: $0 <slug> \"<Title>\" [YYYY-MM-DD]" >&2
  exit 2
fi
if [[ ! "$slug" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "error: slug must be lowercase letters, digits and hyphens" >&2
  exit 2
fi

post="$here/content/posts/$slug.md"
if [[ -e "$post" ]]; then
  echo "error: $post already exists — refusing to overwrite" >&2
  exit 1
fi

repo="https://github.com/albanread/$slug"
sed \
  -e "s|{{SLUG}}|$slug|g" \
  -e "s|{{TITLE}}|$title|g" \
  -e "s|{{DATE}}|$date|g" \
  -e "s|{{REPO}}|$repo|g" \
  "$here/scripts/post-template.md" > "$post"

mkdir -p "$here/static/downloads/$slug" "$here/static/images/$slug"
touch "$here/static/downloads/$slug/.gitkeep" "$here/static/images/$slug/.gitkeep"

echo "created $post"
echo "        static/downloads/$slug/  static/images/$slug/"
echo "next:   edit the article, then add it to PLAN.md and content/timeline.md"
