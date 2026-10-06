#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
repo_dir=$(cd "$script_dir/.." && pwd)
version=${1:-3.5.1}
requested_mode=${2:-all}
source_dir="$repo_dir/fontsrc/JuliaMono-0.63.2"
output_root="$repo_dir/build/v$version/JuliaMono"
case "$requested_mode" in
  all) modes=(normal mono forced forced-mono) ;;
  normal|mono|forced|forced-mono) modes=("$requested_mode") ;;
  *) echo "mode must be all, normal, mono, forced, or forced-mono" >&2; exit 2 ;;
esac
for mode in "${modes[@]}"; do
  "$script_dir/build_family.sh" --input-dir "$source_dir" --output-dir "$output_root/$mode" --mode "$mode" --version "$version"
done
echo "JuliaMono Nerd Font variant(s) are in $output_root"
