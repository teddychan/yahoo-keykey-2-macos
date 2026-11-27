#!/bin/bash
# Build App/AppIcon.icns from the source artwork App/AppIcon.png.
#
# App/AppIcon.png (the traditional Yahoo! KeyKey logo, 512×512) is the source of truth for the
# app icon. The 倉頡 input-mode icon is one 16-point template glyph (black ink, alpha = coverage),
# drawn by tools/render-cangjie-icons.swift, the same size as ABC's "A" and Japanese "あ".
# 速成, 注音 and 拼音 use this logo downsampled, white tile included.
# This script downsamples the app icon with `sips` and assembles the icns with `iconutil`.
# Self-contained and reproducible: edit the PNG or the renderer and re-run.
#
# Requires: sips, iconutil, tiffutil and swift (all ship with Xcode / macOS).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/App/AppIcon.png"
WORK="$(mktemp -d)"
ICONSET="$WORK/AppIcon.iconset"
mkdir -p "$ICONSET"
trap 'rm -rf "$WORK"' EXIT

if [ ! -f "$SRC" ]; then
  echo "ERROR: source artwork missing: $SRC" >&2
  exit 1
fi

echo "==> Rendering iconset PNGs from $SRC"
# Standard macOS iconset sizes. The source master is 512×512, so we downsample only
# (no upscaling) — matching the size set of the original Yahoo icon.
for base in 16 32 128 256 512; do
  sips -z "$base" "$base" "$SRC" --out "$ICONSET/icon_${base}x${base}.png" >/dev/null
done

echo "==> Assembling AppIcon.icns"
iconutil -c icns "$ICONSET" -o "$ROOT/App/AppIcon.icns"
echo "==> Done: $ROOT/App/AppIcon.icns"

# The input-source picker / menu show a per-input-mode icon referenced from
# Info.plist (tsInputMode*IconFileKey). Without it macOS draws a generic gray
# placeholder. Emit a 16×16 (+@2x 32×32) TIFF from the same purple artwork so
# 速成/注音/拼音 show the Yahoo! KeyKey logo. (Matches McBopomofo's Bopomofo.tiff.)
echo "==> Rendering input-mode TIFFs (YahooKeyKey.tiff + @2x)"
sips -s format tiff -z 16 16 "$SRC" --out "$ROOT/App/YahooKeyKey.tiff" >/dev/null
sips -s format tiff -z 32 32 "$SRC" --out "$ROOT/App/YahooKeyKey@2x.tiff" >/dev/null
echo "==> Done: $ROOT/App/YahooKeyKey.tiff, $ROOT/App/YahooKeyKey@2x.tiff"

# 倉頡's mode icon is one template glyph. The 32-pixel page is 144 dpi: a 32-pixel page left
# at 72 dpi is 32 points and the whole icon draws at the wrong size. Gray+alpha, L = 0, alpha =
# glyph coverage, so the switcher and the menu bar tint the character.
echo "==> Rendering 倉頡 template glyph"
CANGJIE_DIR="$WORK/cangjie"
swift "$ROOT/tools/render-cangjie-icons.swift" "$CANGJIE_DIR"
python3 - "$CANGJIE_DIR" << 'PY'
import sys
from PIL import Image
root = sys.argv[1]
for name, dpi in (("template-1x.tiff", 72), ("template-2x.tiff", 144)):
    path = f"{root}/{name}"
    im = Image.open(path).convert("RGBA")
    out = Image.new("LA", im.size, (0, 0))
    src, dst = im.load(), out.load()
    for y in range(im.size[1]):
        for x in range(im.size[0]):
            _, _, _, a = src[x, y]
            dst[x, y] = (0, a)
    out.save(path, dpi=(dpi, dpi))
PY
# One TIFF with both pages, the format Apple's own input-menu icons use, so a Retina menu
# picks the sharp 32-pixel page instead of upscaling the 16-pixel one.
tiffutil -cat "$CANGJIE_DIR/template-1x.tiff" "$CANGJIE_DIR/template-2x.tiff" -out "$ROOT/App/CangjieGlyphTemplate.tiff" 2>/dev/null
cp "$CANGJIE_DIR/template-2x.tiff" "$ROOT/App/CangjieGlyphTemplate@2x.tiff"
echo "==> Done: CangjieGlyphTemplate.tiff (倉)"
