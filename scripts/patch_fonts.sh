#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd "$(dirname "$0")" && pwd)
repo_dir=$(cd "$script_dir/.." && pwd)
version= families=() mode=auto install_deps=1 yes=0
usage() {
  echo "Usage: $0 [--version VERSION] [--font FAMILY ... | --all] [--mode auto|normal|mono|forced|forced-mono] [--no-install] [--yes]" >&2
  exit 2
}
while (($#)); do
  case "$1" in
    --version) version=$2; shift 2 ;;
    --font) families+=("$2"); shift 2 ;;
    --all) families=(ALL); shift ;;
    --mode) mode=$2; shift 2 ;;
    --no-install) install_deps=0; shift ;;
    --yes) yes=1; shift ;;
    -h|--help) usage ;;
    *) usage ;;
  esac
done
case "$mode" in auto|normal|mono|forced|forced-mono) ;; *) usage ;; esac
if ((install_deps)); then
  if command -v apt-get >/dev/null; then
    if [[ $(id -u) -eq 0 ]]; then sudo_cmd=(); else sudo_cmd=(sudo); fi
    "${sudo_cmd[@]}" apt-get update
    "${sudo_cmd[@]}" apt-get install -y fontforge python3-fontforge python3-fonttools curl unzip
  elif command -v brew >/dev/null; then
    brew install fontforge python curl unzip
    python3 -m pip install --user fonttools
  else
    echo 'Automatic dependency installation supports Debian/Ubuntu and Homebrew. Install FontForge, Python 3 fontTools, curl, and unzip, then use --no-install.' >&2
    exit 1
  fi
fi
for tool in fontforge python3 curl unzip; do command -v "$tool" >/dev/null || { echo "Missing $tool" >&2; exit 1; }; done
python3 -c 'import fontTools' || { echo 'Missing Python fontTools' >&2; exit 1; }
if [[ -z "$version" ]]; then version=$(python3 "$script_dir/latest_version.py"); fi
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Invalid version: $version" >&2; exit 2; }
mapfile -d '' -t available < <(find "$repo_dir/fontsrc" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
((${#available[@]})) || { echo 'No families in fontsrc/' >&2; exit 1; }
if ((${#families[@]} == 0)); then
  if [[ ! -t 0 ]]; then echo 'Use --all or --font FAMILY in noninteractive mode' >&2; exit 2; fi
  echo 'Available font families:'
  for i in "${!available[@]}"; do echo "$((i+1))) $(basename "${available[i]}")"; done
  read -r -p 'Select numbers separated by spaces, or all: ' selection
  if [[ "$selection" == all ]]; then families=(ALL); else
    for number in $selection; do
      [[ "$number" =~ ^[0-9]+$ ]] && ((number >= 1 && number <= ${#available[@]})) || { echo "Invalid selection: $number" >&2; exit 2; }
      families+=("$(basename "${available[number-1]}")")
    done
  fi
fi
if [[ ${families[0]:-} == ALL ]]; then
  families=()
  for dir in "${available[@]}"; do families+=("$(basename "$dir")"); done
fi
((${#families[@]})) || { echo 'No fonts selected' >&2; exit 2; }
for family in "${families[@]}"; do
  [[ "$family" != */* && "$family" != .* && -d "$repo_dir/fontsrc/$family" ]] || { echo "Invalid family: $family" >&2; exit 2; }
  find "$repo_dir/fontsrc/$family" -type f \( -iname '*.ttf' -o -iname '*.otf' \) -print -quit | grep -q . || { echo "No TTF or OTF in $family" >&2; exit 1; }
done
echo "Nerd Fonts version: v$version"
echo "Selected families: ${families[*]}"
echo "Patching mode: $mode"
if (( ! yes )); then
  if [[ ! -t 0 ]]; then echo 'Use --yes in noninteractive mode' >&2; exit 2; fi
  read -r -p 'Proceed? [y/N] ' answer
  [[ "$answer" == y || "$answer" == Y ]] || exit 0
fi
nerd_dir=$("$script_dir/fetch_nerd_fonts.sh" "$version" "$repo_dir/.cache/nerd-fonts-$version")
for family in "${families[@]}"; do
  output="$repo_dir/patched/$family"
  mkdir -p "$output" "$repo_dir/releases"
  find "$output" -maxdepth 1 -type f \( -iname '*.ttf' -o -iname '*.otf' \) -delete
  "$script_dir/build_fonts.sh" --input-dir "$repo_dir/fontsrc/$family" --output-dir "$output" --font-patcher "$nerd_dir/font-patcher" --glyphdir "$nerd_dir/src/glyphs" --mode "$mode"
  "$script_dir/validate_fonts.sh" "$output"
  python3 "$script_dir/package_family.py" "$output" "$repo_dir/fontsrc/$family" "$repo_dir/releases/$family-v$version.zip" "$nerd_dir/src/glyphs"
done

echo "Build complete. Retained paths:"
echo "  Patcher archive and extracted assets: $nerd_dir"
echo "  Patched fonts: $repo_dir/patched/"
echo "  Family ZIP archives: $repo_dir/releases/"
echo "FontForge logs and .work.* directories are normally removed after each face."
mapfile -d '' -t leftover_work < <(find "$repo_dir/patched" -mindepth 2 -maxdepth 2 -type d -name '.work.*' -print0)
if ((${#leftover_work[@]})); then
  echo "Leftover work directories (for example after interruption):" >&2
  printf '  %s\n' "${leftover_work[@]}" >&2
fi
