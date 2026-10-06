#!/usr/bin/env bash
set -euo pipefail

# Prefer an installed FontForge. If absent, allow use of an unpacked package
# bundle without modifying the system. Set FONTFORGE_BUNDLE to its root.
if command -v fontforge >/dev/null 2>&1; then
  exec fontforge "$@"
fi

bundle="${FONTFORGE_BUNDLE:-}"
binary="$bundle/usr/bin/fontforge"
library_dir="$bundle/usr/lib/x86_64-linux-gnu"
if [[ -n "$bundle" && -x "$binary" && -d "$library_dir" ]]; then
  export LD_LIBRARY_PATH="$library_dir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  exec "$binary" "$@"
fi

echo "fontforge is not installed; install it or set FONTFORGE_BUNDLE to an unpacked package root" >&2
exit 127
