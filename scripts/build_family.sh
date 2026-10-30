#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 --input-dir DIR --output-dir DIR --mode normal|mono|forced|forced-mono [--version X.Y.Z] [--family-name NAME] [--fontforge CMD]" >&2
  exit 2
}

input_dir= output_dir= mode= version= family_name=
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
version=${version:-$(python3 "$script_dir/latest_version.py")}
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT
nerd_dir=$("$script_dir/fetch_nerd_fonts.sh" "$version" "$repo_dir/.cache/nerd-fonts-$version")
build_args=(--input-dir "$input_dir" --output-dir "$temp_dir/patched" --font-patcher "$nerd_dir/font-patcher" --glyphdir "$nerd_dir/src/glyphs" --mode "$mode" --fontforge "$fontforge_bin")
[[ -z "$family_name" ]] || build_args+=(--family-name "$family_name")
"$script_dir/build_fonts.sh" "${build_args[@]}"
mkdir -p "$output_dir"
shopt -s nullglob
for patched in "$temp_dir/patched"/*.ttf "$temp_dir/patched"/*.otf; do
  cp "$patched" "$output_dir/$(basename "$patched")"
done
echo "Built ${mode} set in $output_dir"
