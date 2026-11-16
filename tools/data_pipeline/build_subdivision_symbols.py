#!/usr/bin/env python3
"""Stage 2 of the subdivision maps: capitals and symbols (coats of arms, flags).

Usage: build_subdivision_symbols.py REGION (--check | --build --src DIR)
DIR (pinned sources): du_1998_96_603.pdf (voivodeship seats, art. 3),
ne_10m_populated_places.geojson (US state capitals), ksng_swiat_2019.pdf
(no exonyms for US state capitals — checked), commons.json (Wikimedia Commons
file metadata) and the SVGs named after the area id (PL-14.svg, US-CA.svg).
Poland: coats of arms of the voivodeships (Polish official symbols are not
subject to copyright, art. 4 of the Copyright Act). USA: state flags.
The SVG copies kept in tools/data_pipeline/<region>_symbols_sources/ are the pin.
--check is offline.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path
import re
import subprocess

from PIL import Image

import build_region
import build_subdivisions as stage1

ROOT = Path(__file__).resolve().parents[2]
VERIFIED = '2026-11-16'
PLACES = ('ne_10m_populated_places.geojson',
          'https://raw.githubusercontent.com/nvkelso/natural-earth-vector/v5.1.2/geojson/ne_10m_populated_places.geojson',
          '9b8e3de09048ef00dfc70357dbb9fa324493f214b5e0ae4daf1aa79a8d10116b')
COMMONS = 'https://commons.wikimedia.org/wiki/'
# Art. 3 of the act: seat of the voivode (first) and of the regional assembly.
SEATS = {
    'PL-02': ['Wrocław'], 'PL-04': ['Bydgoszcz', 'Toruń'], 'PL-06': ['Lublin'],
    'PL-08': ['Gorzów Wielkopolski', 'Zielona Góra'], 'PL-10': ['Łódź'], 'PL-12': ['Kraków'],
    'PL-14': ['Warszawa'], 'PL-16': ['Opole'], 'PL-18': ['Rzeszów'], 'PL-20': ['Białystok'],
    'PL-22': ['Gdańsk'], 'PL-24': ['Katowice'], 'PL-26': ['Kielce'], 'PL-28': ['Olsztyn'],
    'PL-30': ['Poznań'], 'PL-32': ['Szczecin'],
}
# Free spellings that must still count as the right city.
EXTRA_ALIASES = {'PL-08': ['Gorzów', 'Gorzów Wlkp.'], 'US-MN': ['St. Paul']}


def paths(region):
    folder = ROOT / f'assets/content/{region}'
    return (folder / 'capitals.json', folder / 'flags.json', ROOT / f'assets/flags/{region}-0.1.0',
            ROOT / f'tools/data_pipeline/{region}_symbols_sources', folder / 'manifest_symbols.json')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def polish_capitals(act):
    text = re.sub(r'-\s*\n\s*', '', subprocess.check_output(['pdftotext', str(act), '-']).decode())
    text = re.sub(r'\s+', ' ', text)
    article = text[text.index('Art. 3.'):]
    facts = []
    for code, seats in SEATS.items():
        for city in seats:
            assert city in article, (code, city)
        fact = {'id': f'capital:{code}', 'country_id': code, 'name': seats[0],
                'aliases': seats[1:] + EXTRA_ALIASES.get(code, []), 'source_page': 1,
                'status': 'verified', 'verified_at': VERIFIED}
        if len(seats) == 2:
            fact['note'] = (f'Władze tego województwa dzielą dwa miasta: wojewoda urzęduje w mieście '
                            f'{seats[0]}, sejmik w mieście {seats[1]}. Obie odpowiedzi są poprawne.')
        facts.append(fact)
    return facts


def us_capitals(places, ksng, countries):
    rows = [f['properties'] for f in json.loads(places)['features']
            if f['properties']['FEATURECLA'] == 'Admin-1 capital'
            and f['properties']['ADM0NAME'] == 'United States of America']
    english = {f['properties']['iso_3166_2']: f['properties']['name']
               for f in json.loads((SRC / stage1.SOURCES['admin1'][0]).read_bytes())['features']
               if f['properties']['adm0_a3'] == 'USA'}
    pages = subprocess.check_output(['pdftotext', '-layout', str(ksng), '-']).decode().split('\f')
    usa = '\f'.join(p for p in pages if 'Stany Zjednoczone' in p or 'Miejscowości' in p)
    facts = []
    for c in countries:
        [row] = [r for r in rows if r['ADM1NAME'] == english[c['id']]]
        name = row['NAME_EN'] if row['NAME'].startswith('St. ') else row['NAME']
        # KSNG lists Polish exonyms only; none exists for these capitals.
        assert not re.search(r'^[^;\n]+; ' + re.escape(name) + r'[;,]', usa, re.M), name
        facts.append({'id': f"capital:{c['id']}", 'country_id': c['id'], 'name': name,
                      'aliases': EXTRA_ALIASES.get(c['id'], []), 'source_page': 0,
                      'status': 'verified', 'verified_at': VERIFIED})
    return facts


def build(region, src):
    global SRC
    SRC = src
    capitals_path, flags_path, png_dir, svg_dir, manifest_path = paths(region)
    countries = json.loads((ROOT / f'assets/content/{region}/countries.json').read_text())['countries']
    if region == 'poland':
        act = src / stage1.SOURCES['act'][0]
        assert sha(act.read_bytes()) == stage1.SOURCES['act'][2]
        capitals = polish_capitals(act)
        source = {'name': 'Dz.U. 1998 nr 96 poz. 603, art. 3', 'url': stage1.SOURCES['act'][1],
                  'sha256': stage1.SOURCES['act'][2]}
    else:
        places = (src / PLACES[0]).read_bytes()
        assert sha(places) == PLACES[2]
        ksng = src / stage1.SOURCES['ksng'][0]
        assert sha(ksng.read_bytes()) == stage1.SOURCES['ksng'][2]
        capitals = us_capitals(places, ksng, countries)
        source = {'name': 'Natural Earth 1:10m populated places (Admin-1 capital); KSNG 2019 bez egzonimów',
                  'url': PLACES[1], 'sha256': PLACES[2]}
    stage1.write(capitals_path, {'version': f'{region}-capitals-0.1.0', 'source': source, 'capitals': capitals})
    commons = json.loads((src / 'commons.json').read_text())
    render, versions = build_region.renderer()
    svg_dir.mkdir(parents=True, exist_ok=True)
    png_dir.mkdir(parents=True, exist_ok=True)
    flags = []
    for c in countries:
        meta = commons[c['id']]
        assert meta['license'] in ('Public domain', 'Copyrighted free use'), (c['id'], meta['license'])
        data = (src / f"{c['id']}.svg").read_bytes()
        assert hashlib.sha1(data).hexdigest() == meta['sha1'], c['id']  # the file Commons describes
        (svg_dir / f"{c['id']}.svg").write_bytes(data)
        png = png_dir / f"{c['id'].lower()}.png"
        render(data, png)
        flags.append({'country_id': c['id'], 'country_name': c['name'], 'aliases': [],
                      'asset_path': str(png.relative_to(ROOT)), 'source_url': COMMONS + meta['title'].replace(' ', '_'),
                      'source_license': meta['license'], 'source_timestamp': meta['timestamp'],
                      'source_sha256': sha(data), 'sha256': sha(png.read_bytes()),
                      'status': 'verified', 'verified_at': VERIFIED})
    kind = 'coats-of-arms' if region == 'poland' else 'flags'
    stage1.write(flags_path, {'version': f'{region}-{kind}-0.1.0', 'source': COMMONS, 'flags': flags})
    files = [capitals_path, flags_path, *sorted(svg_dir.glob('*.svg')), *sorted(png_dir.glob('*.png'))]
    stage1.write(manifest_path, {'renderer': versions, 'verified_at': VERIFIED,
                                 'files': {str(p.relative_to(ROOT)): sha(p.read_bytes()) for p in files}})
    check(region)


def check(region):
    capitals_path, flags_path, png_dir, svg_dir, manifest_path = paths(region)
    ids = {c['id'] for c in json.loads((ROOT / f'assets/content/{region}/countries.json').read_text())['countries']}
    manifest = json.loads(manifest_path.read_text())
    for path, digest in manifest['files'].items():
        assert sha((ROOT / path).read_bytes()) == digest, path
    capitals = json.loads(capitals_path.read_text())['capitals']
    flags = json.loads(flags_path.read_text())['flags']
    assert {c['country_id'] for c in capitals} == ids == {f['country_id'] for f in flags}
    assert len({c['name'].casefold() for c in capitals}) == len(capitals)
    for fact in capitals:
        assert fact['status'] == 'verified' and fact['id'] == 'capital:' + fact['country_id']
    if region == 'poland':
        by = {c['country_id']: c for c in capitals}
        assert by['PL-04']['aliases'][0] == 'Toruń' and by['PL-08']['aliases'][0] == 'Zielona Góra'
        assert by['PL-14']['name'] == 'Warszawa'
    for f in flags:
        assert f['source_license'] in ('Public domain', 'Copyrighted free use')
        assert sha((svg_dir / f"{f['country_id']}.svg").read_bytes()) == f['source_sha256']
        png = ROOT / f['asset_path']
        assert png.parent == png_dir and sha(png.read_bytes()) == f['sha256']
        with Image.open(io.BytesIO(png.read_bytes())) as im:
            assert im.format == 'PNG' and im.width == 500 and 0 < im.height <= 1000, f['country_id']
    expected = {str(p.relative_to(ROOT)) for p in [capitals_path, flags_path, *svg_dir.glob('*.svg'), *png_dir.glob('*.png')]}
    assert set(manifest['files']) == expected
    print(f'OK {region}: {len(capitals)} capitals, {len(flags)} symbols, licences, checksums')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('region', choices=['poland', 'usa'])
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--check', action='store_true')
    group.add_argument('--build', action='store_true')
    parser.add_argument('--src', type=Path)
    args = parser.parse_args()
    if args.check:
        check(args.region)
    else:
        if not args.src:
            parser.error('--build requires --src')
        build(args.region, args.src)
