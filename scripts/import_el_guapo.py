#!/usr/bin/env python3
"""Download archived ANSI originals and generate browser cell runs (stdlib only)."""
import json
import re
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'site/samples/el-guapo'
PALETTE = ['#000000','#aa0000','#00aa00','#aa5500','#0000aa','#aa00aa','#00aaaa','#aaaaaa', '#555555','#ff5555','#55ff55','#ffff55','#5555ff','#ff55ff','#55ffff','#ffffff']
PIECES = [('acdu1195','EO-DEM1.ANS'), ('int-0995','EO-VOS.ANS'), ('int-0895','EO-CHEM1.ANS')]

def decode(data, width):
    # Remove SAUCE metadata and its optional comment block before interpreting art.
    if data[-128:-121] == b'SAUCE00':
        sauce = data[-128:]
        count = sauce[104]
        data = data[:-(128 + (5 + 64 * count if count else 0))]
    data = data.rstrip(b'\x1a')
    rows = {}
    x = y = 0
    fg, bg, bright = 7, 0, False
    saved = (0, 0)
    unsupported = set()
    def cell(ch):
        nonlocal x, y
        if x >= width:
            x = 0
            y += 1
        if y > 2000:
            raise ValueError('Artwork exceeds safe row bound')
        rows.setdefault(y, {})[x] = (ch, fg + (8 if bright and fg < 8 else 0), bg)
        x += 1
    i = 0
    while i < len(data):
        b = data[i]
        if b == 27:
            match = re.match(rb'\x1b\[([0-9;?]*)([A-Za-z])', data[i:])
            if not match:
                raise ValueError(f'Unsupported escape at byte {i}')
            args, op = match.groups()
            values = [int(n or 0) for n in args.replace(b'?', b'').split(b';')]
            n = values[0] or 1
            if op == b'm':
                for v in values:
                    if v == 0: fg, bg, bright = 7, 0, False
                    elif v == 1: bright = True
                    elif v == 22: bright = False
                    elif 30 <= v <= 37: fg = v - 30
                    elif 40 <= v <= 47: bg = v - 40
                    elif 90 <= v <= 97: fg = v - 90 + 8
                    elif 100 <= v <= 107: bg = v - 100 + 8
                    elif v == 5: bg = bg % 8 + 8 # iCE colors: blink bit is bright background
                    elif v == 25: bg %= 8
                    elif v == 39: fg = 7
                    elif v == 49: bg = 0
                    else: unsupported.add(f'SGR {v}')
            elif op in (b'H', b'f'):
                y = max(0, n - 1); x = max(0, (values[1] or 1) - 1) if len(values) > 1 else 0
            elif op == b'A': y = max(0, y - n)
            elif op == b'B': y += n
            elif op == b'C': x = min(width - 1, x + n)
            elif op == b'D': x = max(0, x - n)
            elif op == b's': saved = (x, y)
            elif op == b'u': x, y = saved
            elif op == b'J' and values[0] == 2: rows.clear(); x = y = 0
            elif op == b'K':
                for col in range(x, width): rows.setdefault(y, {})[col] = (' ', fg, bg)
            else: unsupported.add(match.group().decode('ascii'))
            i += len(match.group()); continue
        if b == 13: x = 0
        elif b == 10: y += 1
        elif b == 9: x = min(width, (x // 8 + 1) * 8)
        elif b == 8: x = max(0, x - 1)
        elif b in (0, 7, 26): pass
        else: cell(bytes([b]).decode('cp437'))
        i += 1
    if unsupported: raise ValueError(f'Unimplemented ANSI controls: {sorted(unsupported)}')
    result = []
    for row in range(max(rows, default=0) + 1):
        runs = []
        for col in range(width):
            ch, f, b = rows.get(row, {}).get(col, (' ', 7, 0))
            if runs and runs[-1][1:] == [PALETTE[f], PALETTE[b]]: runs[-1][0] += ch
            else: runs.append([ch, PALETTE[f], PALETTE[b]])
        result.append(runs)
    return result

def main():
    DEST.mkdir(parents=True, exist_ok=True)
    gallery = []
    for pack, name in PIECES:
        base = f'https://16colo.rs/pack/{pack}'
        for suffix, url in [(name, f'{base}/raw/{name}'), (name + '.json', f'{base}/data/{name}'), (name + '.png', f'{base}/x1/{name}.png')]:
            path = DEST / suffix
            if not path.exists():
                with urllib.request.urlopen(url, timeout=45) as response: path.write_bytes(response.read())
        metadata = json.loads((DEST / (name + '.json')).read_text())
        width = int(metadata['sauce']['tinfo1'])
        rows = decode((DEST / name).read_bytes(), width)
        item = dict(id=name, title=metadata['sauce']['title'].strip(), author=metadata['sauce']['author'].strip(), width=width, height=len(rows), source=f'{base}/{name}', file=f'samples/el-guapo/{name}', reference=f'samples/el-guapo/{name}.png', rows=rows)
        gallery.append(item)
        print(f'{name}: {width} columns, {len(rows)} rows; original and reference saved')
    (ROOT / 'site/ansi-gallery.js').write_text('window.ansiGallery = ' + json.dumps(gallery, ensure_ascii=False, separators=(',', ':')) + ';\n')

if __name__ == '__main__': main()
