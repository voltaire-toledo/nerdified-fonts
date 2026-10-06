#!/usr/bin/env python3
"""Set consistent family/style names after the Nerd Fonts patcher runs."""

import argparse
import re
from pathlib import Path

from fontTools.ttLib import TTFont


def best_name(font: TTFont, name_ids: tuple[int, ...]) -> str:
    records = [record for record in font["name"].names if record.nameID in name_ids]
    records.sort(
        key=lambda record: (
            record.platformID != 3,
            record.langID != 0x409,
            record.nameID not in name_ids[:1],
        )
    )
    for record in records:
        try:
            value = record.toUnicode().strip()
        except (UnicodeDecodeError, LookupError):
            continue
        if value:
            return value
    raise ValueError(f"font has no usable name record among IDs {name_ids}")


def derive_family(source: TTFont, mode: str) -> str:
    base = best_name(source, (16, 1))
    if mode in {"forced", "forced-mono"}:
        return f"{base}Forced Nerd Font"
    # The project deliberately gives each variant its own output directory;
    # JuliaMono's family name already identifies the monospaced design.
    return f"{base} Nerd Font"


def set_name(font: TTFont, family: str, style: str) -> None:
    name_table = font["name"]
    full = f"{family} {style}".strip()
    postscript_family = re.sub(r"[^A-Za-z0-9]", "", family)
    postscript_style = re.sub(r"[^A-Za-z0-9]", "", style)
    postscript = f"{postscript_family}-{postscript_style}"
    version = best_name(font, (5,)) if any(n.nameID == 5 for n in name_table.names) else "Version 1.0"
    unique = f"{postscript};{version}"

    replacements = {
        1: family,
        2: style,
        3: unique,
        4: full,
        6: postscript,
        16: family,
        17: style,
        18: full,
        21: family,
        22: style,
    }
    name_table.names = [record for record in name_table.names if record.nameID not in replacements]
    for name_id, value in replacements.items():
        name_table.setName(value, name_id, 3, 1, 0x409)
        name_table.setName(value, name_id, 1, 0, 0)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--font", required=True, type=Path, help="Patched TTF to rename in place")
    parser.add_argument("--source", required=True, type=Path, help="Clean source TTF for family and style")
    parser.add_argument("--mode", required=True, choices=("normal", "mono", "forced", "forced-mono"))
    parser.add_argument("--family-name", help="Explicit display family name; overrides the mode-derived name")
    args = parser.parse_args()

    patched = TTFont(args.font)
    source = TTFont(args.source)
    family = args.family_name or derive_family(source, args.mode)
    style = best_name(source, (17, 2))
    set_name(patched, family, style)
    patched.save(args.font)
    print(f"{args.font}: {family} | {style}")


if __name__ == "__main__":
    main()
