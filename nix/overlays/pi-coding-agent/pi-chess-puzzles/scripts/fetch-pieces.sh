#!/usr/bin/env bash
# Fetch the "fantasy" chess piece set (Maurizio Monge, MIT — see
# assets/LICENSE-fantasy) from lichess's repo and rasterize SVGs to raw
# 8-bit RGBA (64x64) for the extension's kitty image renderer.
#
# Requires: curl, ImageMagick (magick). Re-run to update the assets.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
SET="${PIECE_SET:-fantasy}"
BASE="https://raw.githubusercontent.com/lichess-org/lila/master/public/piece/$SET"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

for p in wK wQ wR wB wN wP bK bQ bR bB bN bP; do
  curl -sf --max-time 20 -o "$tmp/$p.svg" "$BASE/$p.svg"
  magick -background none "$tmp/$p.svg" -resize 64x64 -depth 8 "assets/pieces/$p.rgba"
done

echo "fetched $SET pieces into assets/pieces/"
