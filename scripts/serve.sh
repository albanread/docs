#!/usr/bin/env bash
# Local preview with live reload → http://127.0.0.1:1111
# Requires Zola: brew install zola
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v zola >/dev/null 2>&1; then
  echo "zola not found. Install it with:  brew install zola" >&2
  exit 1
fi
exec zola serve "$@"
