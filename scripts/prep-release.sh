#!/usr/bin/env bash
# Prepare binaries for a GitHub Release: compute checksums and print a ready-to-
# paste Markdown snippet + a `gh release` command. Does NOT copy anything into the
# site — binaries are hosted on the project's GitHub Releases, not the blog.
#
# Usage: ./scripts/prep-release.sh <owner/repo> <tag> <file> [<file> ...]
# Example:
#   ./scripts/prep-release.sh albanread/MACDART v1.24.3-macdart \
#       ../MACDART/macdart/build-release/dart
#
# Output:
#   - SHA256SUMS written next to the first file's directory (attach it to the release)
#   - a Markdown table of files + sizes + checksums (paste into the article)
#   - the gh command to create the release and upload the assets
set -euo pipefail

repo="${1:-}"; tag="${2:-}"; shift 2 || true
if [[ -z "$repo" || -z "$tag" || "$#" -eq 0 ]]; then
  echo "usage: $0 <owner/repo> <tag> <file> [<file> ...]" >&2
  exit 2
fi

sums_dir="$(cd "$(dirname "$1")" && pwd)"
sums="$sums_dir/SHA256SUMS"
: > "$sums"

echo
echo "### Downloads"
echo
echo "Binaries are on the [Releases page](https://github.com/$repo/releases/tag/$tag). Verify with \`shasum -a 256\`:"
echo
echo "| File | Size | SHA-256 |"
echo "|------|------|---------|"
files=()
for f in "$@"; do
  [[ -f "$f" ]] || { echo "skip (not a file): $f" >&2; continue; }
  b="$(basename "$f")"
  sum="$(shasum -a 256 "$f" | awk '{print $1}')"
  size="$(du -h "$f" | awk '{print $1}')"
  echo "$sum  $b" >> "$sums"
  echo "| [\`$b\`](https://github.com/$repo/releases/download/$tag/$b) | $size | \`$sum\` |"
  files+=( "$f" )
done

echo
echo "---"
echo "Wrote checksums → $sums"
echo
echo "Create the release and upload assets with:"
echo "  gh release create $tag --repo $repo --title \"$tag\" --notes \"…\" \\"
printf '    %q \\\n' "$sums"
for f in "${files[@]}"; do printf '    %q \\\n' "$f"; done
echo
echo "Reminder: sign + notarize macOS binaries before release, and note it in the article."
