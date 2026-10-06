#!/usr/bin/env python3
"""Create a GitHub or Forgejo release and upload the local family ZIPs."""
import json
import os
from pathlib import Path
import sys
import urllib.error
import urllib.parse
import urllib.request

version = sys.argv[1]
provider = os.environ.get('RELEASE_PROVIDER', 'github').lower()
repo = os.environ.get('RELEASE_REPOSITORY') or os.environ.get('GITHUB_REPOSITORY') or os.environ.get('FORGEJO_REPOSITORY')
token = os.environ.get('RELEASE_TOKEN') or os.environ.get('GITHUB_TOKEN') or os.environ.get('FORGEJO_TOKEN')
if not repo or not token or '/' not in repo:
    raise SystemExit('Set RELEASE_REPOSITORY and RELEASE_TOKEN (or CI equivalents)')
api = os.environ.get('RELEASE_API_URL') or ('https://api.github.com' if provider == 'github' else os.environ.get('FORGEJO_API_URL', ''))
if not api:
    raise SystemExit('Set RELEASE_API_URL for Forgejo, e.g. https://forge.example/api/v1')
base = f'{api.rstrip("/")}/repos/{repo}/releases'
tag = f'v{version}'
headers = {'Authorization': f'Bearer {token}', 'Accept': 'application/json', 'User-Agent': 'VT-NerdFonts'}

def request(url, method='GET', payload=None, content_type='application/json'):
    h = dict(headers)
    if payload is not None:
        h['Content-Type'] = content_type
    with urllib.request.urlopen(urllib.request.Request(url, data=payload, headers=h, method=method), timeout=120) as response:
        return json.load(response)

try:
    release = request(f'{base}/tags/{tag}')
except urllib.error.HTTPError as error:
    if error.code != 404:
        raise
    body = json.dumps({'tag_name': tag, 'name': tag, 'body': f'Patched with Nerd Fonts {tag}. Source font licenses are included in each archive.'}).encode()
    release = request(base, 'POST', body)
assets = {asset['name'] for asset in release.get('assets', [])}
files = sorted(Path('releases').glob(f'*-{tag}.zip'))
if not files:
    raise SystemExit(f'No release archives for {tag}')
for file in files:
    if file.name in assets:
        print(f'Already uploaded: {file.name}')
        continue
    if provider == 'github':
        upload = release['upload_url'].split('{', 1)[0] + '?name=' + urllib.parse.quote(file.name)
    elif provider == 'forgejo':
        upload = f'{base}/{release["id"]}/assets?name={urllib.parse.quote(file.name)}'
    else:
        raise SystemExit(f'Unknown provider: {provider}')
    if provider == 'forgejo':
        boundary = 'VTNerdFontsUploadBoundary'
        content = (f'--{boundary}\r\nContent-Disposition: form-data; name="attachment"; filename="{file.name}"\r\nContent-Type: application/zip\r\n\r\n').encode() + file.read_bytes() + f'\r\n--{boundary}--\r\n'.encode()
        request(upload, 'POST', content, f'multipart/form-data; boundary={boundary}')
    else:
        request(upload, 'POST', file.read_bytes(), 'application/zip')
    print(f'Uploaded: {file.name}')
