#!/usr/bin/env python3
"""Generate the terminal and browser samples from editable UTF-8 artwork."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "site/samples/font-workbench.txt"
WIDTH = 26
COLORS = ((117, 218, 159), (144, 172, 189), (240, 204, 112))


def main() -> None:
    lines = SOURCE.read_text(encoding="utf-8").splitlines()
    if not lines:
        raise SystemExit("Artwork is empty; outputs were not changed.")
    for number, line in enumerate(lines, 1):
        if any(ord(char) < 32 or ord(char) == 127 for char in line):
            raise SystemExit(f"Line {number}: remove tabs/control codes; outputs were not changed.")
        if len(line) > WIDTH:
            raise SystemExit(f"Line {number}: {len(line)} characters exceeds {WIDTH}; outputs were not changed.")
    rows = []
    for index, line in enumerate(lines):
        rgb = ";".join(map(str, COLORS[index % len(COLORS)]))
        rows.append(f"\x1b[48;2;16;28;33m\x1b[38;2;{rgb}m{line.ljust(WIDTH)}\x1b[0m")
    ansi = "\n".join(rows) + "\n"
    (SOURCE.parent / "font-workbench.ans").write_text(ansi, encoding="utf-8")
    (ROOT / "site/ansi-sample.js").write_text(
        "window.fontWorkbenchAnsi = " + json.dumps(ansi, ensure_ascii=False) + ";\n",
        encoding="utf-8",
    )
    print(f"Generated both samples from {SOURCE.relative_to(ROOT)} ({len(lines)} rows, {WIDTH} columns)")


if __name__ == "__main__":
    main()
