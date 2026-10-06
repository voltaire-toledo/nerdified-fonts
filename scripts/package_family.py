#!/usr/bin/env python3
"""Package one patched family with its available license files."""
import sys
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

patched, source, destination = map(Path, sys.argv[1:])
fonts = sorted(p for p in patched.iterdir() if p.suffix.lower() in {'.ttf', '.otf'})
if not fonts:
    raise SystemExit(f'No patched fonts in {patched}')
with ZipFile(destination, 'w', ZIP_DEFLATED) as archive:
    for font in fonts:
        archive.write(font, font.name)
    for license_file in source.rglob('*'):
        if license_file.is_file() and (license_file.name.lower().startswith(('license', 'licence', 'ofl', 'copying'))):
            archive.write(license_file, f'licenses/{license_file.relative_to(source)}')
print(destination)
