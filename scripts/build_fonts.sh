#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 --input-dir DIR --output-dir DIR --font-patcher FILE --glyphdir DIR --mode normal|mono|forced|forced-mono [--family-name NAME] [--fontforge CMD]" >&2
  exit 2
}

input_dir= output_dir= font_patcher= glyphdir= mode= family_name=
fontforge_bin="${FONTFORGE_BIN:-fontforge}"
while (($#)); do
  case "$1" in
    --input-dir) input_dir=$2; shift 2 ;;
    --output-dir) output_dir=$2; shift 2 ;;
    --font-patcher) font_patcher=$2; shift 2 ;;
    --glyphdir) glyphdir=$2; shift 2 ;;
    --mode) mode=$2; shift 2 ;;
    --family-name) family_name=$2; shift 2 ;;
    --fontforge) fontforge_bin=$2; shift 2 ;;
    *) usage ;;
  esac
done
[[ -d "$input_dir" && -n "$output_dir" && -f "$font_patcher" && -d "$glyphdir" ]] || usage
case "$mode" in normal|mono|forced|forced-mono) ;; *) usage ;; esac
shopt -s nullglob
mapfile -d '' -t inputs < <(find "$input_dir" -type f \( -iname '*.ttf' -o -iname '*.otf' \) -print0 | sort -z)
((${#inputs[@]})) || { echo "no TTFs in $input_dir" >&2; exit 1; }
seen_names=()
for input in "${inputs[@]}"; do
  name=$(basename "$input")
  for seen_name in "${seen_names[@]}"; do
    if [[ "$seen_name" == "$name" ]]; then
      echo "duplicate TTF basename '$name' under $input_dir; flatten/rename inputs first" >&2
      exit 1
    fi
  done
  seen_names+=("$name")
done
mkdir -p "$output_dir"
script_dir=$(cd "$(dirname "$0")" && pwd)
max_jobs=${JOBS:-4}
((max_jobs > 0)) || { echo "JOBS must be a positive integer" >&2; exit 2; }

build_one() {
  local input=$1 name work_dir log_file output
  local -a patch_args normalize_args generated
  name=$(basename "$input")
  work_dir=$(mktemp -d "$output_dir/.work.XXXXXX")
  log_file="$work_dir/fontforge.log"
  patch_args=(--complete --no-progressbars --glyphdir "$glyphdir" --outputdir "$work_dir")
  case "$mode" in
    normal) patch_args+=(--careful) ;;
    mono) patch_args+=(--careful --mono) ;;
    forced) patch_args+=(--makegroups 4) ;;
    forced-mono) patch_args+=(--makegroups 4 --mono) ;;
  esac
  if ! "$fontforge_bin" -script "$font_patcher" "${patch_args[@]}" "$input" >"$log_file" 2>&1; then
    cat "$log_file" >&2
    echo "FontForge failed while patching $name" >&2
    rm -rf "$work_dir"
    exit 1
  fi
  mapfile -t generated < <(find "$work_dir" -maxdepth 1 -type f \( -iname '*.ttf' -o -iname '*.otf' \) -print)
  if ((${#generated[@]} != 1)); then
    echo "expected one patched TTF for $name; got ${#generated[@]}" >&2
    rm -rf "$work_dir"
    exit 1
  fi
  output="$output_dir/${name%.*}.${generated[0]##*.}"
  mv "${generated[0]}" "$output"
  rm -rf "$work_dir"
  normalize_args=(--font "$output" --source "$input" --mode "$mode")
  [[ -z "$family_name" ]] || normalize_args+=(--family-name "$family_name")
  python3 "$script_dir/normalize_font_names.py" "${normalize_args[@]}"
}

pids=()
failed=0
for input in "${inputs[@]}"; do
  build_one "$input" &
  pids+=("$!")
  if ((${#pids[@]} >= max_jobs)); then
    if ! wait "${pids[0]}"; then failed=1; fi
    pids=("${pids[@]:1}")
  fi
done
for pid in "${pids[@]}"; do
  if ! wait "$pid"; then failed=1; fi
done
((failed == 0)) || exit 1
