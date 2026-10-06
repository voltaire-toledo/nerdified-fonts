#!/usr/bin/env python3
"""Package one patched family with its available license files."""
import sys
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

patched, source, destination, glyph_source = map(Path, sys.argv[1:])
fonts = sorted(p for p in patched.iterdir() if p.suffix.lower() in {'.ttf', '.otf'})
if not fonts:
    raise SystemExit(f'No patched fonts in {patched}')
with ZipFile(destination, 'w', ZIP_DEFLATED) as archive:
    for font in fonts:
        archive.write(font, font.name)
    for license_file in source.rglob('*'):
        if license_file.is_file() and (license_file.name.lower().startswith(('license', 'licence', 'ofl', 'copying'))):
            archive.write(license_file, f'licenses/{license_file.relative_to(source)}')
    notice_prefixes = ('license', 'licence', 'ofl', 'copying', 'notice', 'copyright')
    for notice_file in glyph_source.rglob('*'):
        if notice_file.is_file() and notice_file.name.lower().startswith(notice_prefixes):
            relative = notice_file.relative_to(glyph_source)
            archive.write(notice_file, f'licenses/nerd-fonts/glyphs/{relative}')
print(destination)
