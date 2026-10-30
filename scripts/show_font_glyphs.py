#!/usr/bin/env python3
"""Print a terminal glyph sheet and optionally check a Nerd Fonts release map."""

import argparse
import json
import re
import sys
import unicodedata
from pathlib import Path

from fontTools.ttLib import TTFont


def in_private_use(codepoint: int) -> bool:
    return (
        0xE000 <= codepoint <= 0xF8FF
        or 0xF0000 <= codepoint <= 0xFFFFD
        or 0x100000 <= codepoint <= 0x10FFFD
    )


def family_name(font: TTFont) -> str:
    names = font["name"]
    return names.getDebugName(16) or names.getDebugName(1) or "(unknown family)"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("font", type=Path, help="Patched TTF or OTF file to inspect")
    parser.add_argument(
        "--glyphnames",
        type=Path,
        help="glyphnames.json from the exact Nerd Fonts release used to patch this font",
    )
    parser.add_argument(
        "--check-text",
        type=Path,
        help="also check visible characters in a UTF-8 text/ANSI-art file against this font",
    )
    args = parser.parse_args()
    if not args.font.is_file():
        parser.error(f"font file does not exist: {args.font}")

    font = TTFont(args.font, lazy=True)
    cmap = font.getBestCmap() or {}
    codepoints = set(cmap)
    private_use = sorted(cp for cp in codepoints if in_private_use(cp))
    box_drawing = set(range(0x2500, 0x2580))
    block_elements = set(range(0x2580, 0x25A0))
    missing_box = sorted(box_drawing - codepoints)
    missing_blocks = sorted(block_elements - codepoints)
    missing_text: list[int] = []
    text_advance_count = 0
    text_codepoints: set[int] = set()
    if args.check_text:
        if not args.check_text.is_file():
            parser.error(f"text file does not exist: {args.check_text}")
        content = args.check_text.read_text(encoding="utf-8", errors="replace")
        # Remove ANSI CSI controls (including color and cursor controls) before
        # treating the remaining visible characters as glyphs.
        content = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", content)
        text_codepoints = {
            ord(character)
            for character in content
            if ord(character) >= 0x20 and ord(character) != 0x7F
        }
        missing_text = sorted(text_codepoints - codepoints)
        advances = {
            font["hmtx"].metrics[cmap[cp]][0]
            for cp in text_codepoints
            if cp in cmap and cmap[cp] in font["hmtx"].metrics
        }
        text_advance_count = len(advances)

    expected_names: dict[int, list[str]] = {}
    missing_icons: list[int] = []
    if args.glyphnames:
        if not args.glyphnames.is_file():
            parser.error(f"glyph map does not exist: {args.glyphnames}")
        glyph_data = json.loads(args.glyphnames.read_text(encoding="utf-8"))
        for name, entry in glyph_data.items():
            if name == "METADATA":
                continue
            codepoint = int(entry["code"], 16)
            if in_private_use(codepoint):
                expected_names.setdefault(codepoint, []).append(name)
        missing_icons = sorted(set(expected_names) - codepoints)

    print(f"Font: {args.font}", file=sys.stderr)
    print(f"Family: {family_name(font)}", file=sys.stderr)
    print(f"Mapped codepoints: {len(codepoints)}", file=sys.stderr)
    print(f"Mapped private-use codepoints: {len(private_use)}", file=sys.stderr)
    print(
        f"Box Drawing: {len(box_drawing - set(missing_box))}/128 present; "
        f"Block Elements: {len(block_elements - set(missing_blocks))}/32 present",
        file=sys.stderr,
    )
    if args.glyphnames:
        print(
            f"Nerd Fonts map coverage: {len(expected_names) - len(missing_icons)}"
            f"/{len(expected_names)} mapped codepoints present",
            file=sys.stderr,
        )
        if missing_icons:
            print("Missing Nerd Fonts codepoints:", file=sys.stderr)
            for codepoint in missing_icons:
                names = ", ".join(expected_names[codepoint])
                print(f"  U+{codepoint:04X}  {names}", file=sys.stderr)
    else:
        print(
            "Nerd Fonts completeness: not checked (pass the matching glyphnames.json)",
            file=sys.stderr,
        )
    if args.check_text:
        print(
            f"Text file coverage: {len(text_codepoints) - len(missing_text)}"
            f"/{len(text_codepoints)} visible codepoints present; "
            f"{text_advance_count} distinct font advances",
            file=sys.stderr,
        )
        if missing_text:
            print("Missing text-file codepoints:", file=sys.stderr)
            for codepoint in missing_text:
                print(f"  U+{codepoint:04X}  {chr(codepoint)}", file=sys.stderr)

    print("\nBOX DRAWING AND BLOCK ELEMENTS")
    for start, end in ((0x2500, 0x257F), (0x2580, 0x259F)):
        for codepoint in range(start, end + 1):
            glyph = chr(codepoint) if codepoint in codepoints else "□"
            print(f"U+{codepoint:04X}  {glyph}")

    print("\nMAPPED PRIVATE-USE GLYPHS")
    for codepoint in private_use:
        names = ", ".join(expected_names.get(codepoint, []))
        label = f"  {names}" if names else ""
        print(f"U+{codepoint:04X}  {chr(codepoint)}{label}")

    print("\nMAPPED SUPPLEMENTAL BLOCK / SEXTANT / OCTANT GLYPHS")
    supplemental = [
        cp
        for cp in sorted(codepoints)
        if (0x1CD00 <= cp <= 0x1CEFF or 0x1FB00 <= cp <= 0x1FBFF)
        and any(word in unicodedata.name(chr(cp), "") for word in ("BLOCK", "SEXTANT", "OCTANT"))
    ]
    if supplemental:
        for codepoint in supplemental:
            print(f"U+{codepoint:05X}  {chr(codepoint)}  {unicodedata.name(chr(codepoint), 'UNNAMED')}")
    else:
        print("(none mapped)")

    font.close()
    return int(bool(missing_box or missing_blocks or missing_icons or missing_text))


if __name__ == "__main__":
    raise SystemExit(main())
