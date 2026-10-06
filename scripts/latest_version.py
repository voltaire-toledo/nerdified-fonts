#!/usr/bin/env python3
"""Print the latest stable Nerd Fonts release version from GitHub."""
import json
import os
import re
import urllib.request

url = 'https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest'
headers = {'Accept': 'application/vnd.github+json', 'User-Agent': 'VT-NerdFonts'}
if os.environ.get('GITHUB_TOKEN'):
    headers['Authorization'] = 'Bearer ' + os.environ['GITHUB_TOKEN']
with urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=30) as response:
    release = json.load(response)
tag = release['tag_name']
if not re.fullmatch(r'v[0-9]+\.[0-9]+\.[0-9]+', tag):
    raise SystemExit(f'Unexpected Nerd Fonts release tag: {tag}')
print(tag[1:])
