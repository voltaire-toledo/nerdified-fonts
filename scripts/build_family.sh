#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 --input-dir DIR --output-dir DIR --mode normal|mono|forced|forced-mono [--version 3.5.1] [--family-name NAME] [--fontforge CMD]" >&2
  exit 2
}

input_dir= output_dir= mode= version=3.5.1 family_name=
fontforge_bin="${FONTFORGE_BIN:-fontforge}"
while (($#)); do
  case "$1" in
    --input-dir) input_dir=$2; shift 2 ;;
    --output-dir) output_dir=$2; shift 2 ;;
    --mode) mode=$2; shift 2 ;;
    --version) version=$2; shift 2 ;;
    --family-name) family_name=$2; shift 2 ;;
    --fontforge) fontforge_bin=$2; shift 2 ;;
    *) usage ;;
  esac
done
[[ -d "$input_dir" && -n "$output_dir" && -n "$mode" ]] || usage
script_dir=$(cd "$(dirname "$0")" && pwd)
repo_dir=$(cd "$script_dir/.." && pwd)
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT
nerd_dir=$("$script_dir/fetch_nerd_fonts.sh" "$version" "$repo_dir/.cache/nerd-fonts-$version")
build_args=(--input-dir "$input_dir" --output-dir "$temp_dir/patched" --font-patcher "$nerd_dir/font-patcher" --glyphdir "$nerd_dir/src/glyphs" --mode "$mode" --fontforge "$fontforge_bin")
[[ -z "$family_name" ]] || build_args+=(--family-name "$family_name")
"$script_dir/build_fonts.sh" "${build_args[@]}"
mkdir -p "$output_dir"
for patched in "$temp_dir/patched"/*.ttf; do
  source_name=$(basename "$patched")
  source_family=${source_name%%-*}
  style=${source_name#*-}
  case "$mode" in
    normal) prefix="${source_family}NerdFont" ;;
    mono) prefix="${source_family}NerdFontMono" ;;
    forced) prefix="${source_family}ForcedNerdFont" ;;
    forced-mono) prefix="${source_family}ForcedNerdFont" ;;
  esac
  cp "$patched" "$output_dir/$prefix-$style"
done
echo "Built ${mode} set in $output_dir"
