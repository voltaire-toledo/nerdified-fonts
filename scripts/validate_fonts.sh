#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 FONT_DIR [EXPECTED_FAMILY]" >&2
  exit 2
}
[[ $# -ge 1 && $# -le 2 && -d "$1" ]] || usage
font_dir=$1
expected_family=${2:-}
shopt -s nullglob
fonts=("$font_dir"/*.ttf "$font_dir"/*.otf)
((${#fonts[@]})) || { echo "no TTF or OTF files in $font_dir" >&2; exit 1; }
for font in "${fonts[@]}"; do
  python3 - "$font" "$expected_family" <<'PY'
import sys
from fontTools.ttLib import TTFont

path, expected = sys.argv[1:]
font = TTFont(path, lazy=True)
names = font["name"]
family = names.getDebugName(16) or names.getDebugName(1) or ""
style = names.getDebugName(17) or names.getDebugName(2) or ""
codepoints = set().union(*(set(table.cmap) for table in font["cmap"].tables))
pua = sum(0xE000 <= cp <= 0xF8FF or 0xF0000 <= cp <= 0xFFFFD or 0x100000 <= cp <= 0x10FFFD for cp in codepoints)
if expected and family != expected:
    raise SystemExit(f"FAIL {path}: family is {family!r}, expected {expected!r}")
if pua < 5000:
    raise SystemExit(f"FAIL {path}: only {pua} Private Use Area codepoints; expected at least 5000")
print(f"OK   {path}: {family} / {style}; {len(codepoints)} mapped codepoints; {pua} PUA")
PY
done
