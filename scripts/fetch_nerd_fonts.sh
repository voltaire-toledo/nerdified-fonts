#!/usr/bin/env bash
set -euo pipefail

version="${1:-3.5.1}"
script_dir=$(cd "$(dirname "$0")" && pwd)
repo_dir=$(cd "$script_dir/.." && pwd)
destination="${2:-$repo_dir/.cache/nerd-fonts-$version}"
mkdir -p "$destination"
if [[ -x "$destination/font-patcher" && -d "$destination/src/glyphs" ]]; then
  echo "$destination"
  exit 0
fi

archive="$destination/FontPatcher.zip"
url="https://github.com/ryanoasis/nerd-fonts/releases/download/v$version/FontPatcher.zip"
curl --fail --location --retry 3 --output "$archive" "$url"
unzip -q -o "$archive" -d "$destination"
echo "$destination"
