#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 --input FONT.ttf --output PATCHED.ttf [--mode normal|mono|forced|forced-mono] [--version 3.5.1] [--family-name NAME] [--fontforge CMD]" >&2
  exit 2
}

input= output= mode=normal version=3.5.1 family_name=
fontforge_bin="${FONTFORGE_BIN:-fontforge}"
while (($#)); do
  case "$1" in
    --input) input=$2; shift 2 ;;
    --output) output=$2; shift 2 ;;
    --mode) mode=$2; shift 2 ;;
    --version) version=$2; shift 2 ;;
    --family-name) family_name=$2; shift 2 ;;
    --fontforge) fontforge_bin=$2; shift 2 ;;
    -h|--help) usage ;;
    *) usage ;;
  esac
done
[[ -f "$input" && -n "$output" ]] || usage
script_dir=$(cd "$(dirname "$0")" && pwd)
repo_dir=$(cd "$script_dir/.." && pwd)
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT
nerd_dir=$("$script_dir/fetch_nerd_fonts.sh" "$version" "$repo_dir/.cache/nerd-fonts-$version")
mkdir -p "$temp_dir/input" "$(dirname "$output")"
cp "$input" "$temp_dir/input/$(basename "$input")"
args=(--input-dir "$temp_dir/input" --output-dir "$temp_dir/output" --font-patcher "$nerd_dir/font-patcher" --glyphdir "$nerd_dir/src/glyphs" --mode "$mode" --fontforge "$fontforge_bin")
[[ -z "$family_name" ]] || args+=(--family-name "$family_name")
"$script_dir/build_fonts.sh" "${args[@]}"
cp "$temp_dir/output/$(basename "$input")" "$output"
echo "$output"
