#!/usr/bin/env python3
"""English names of capitals (and voivodeship seats) as extra accepted answers.

Usage: build_capitals_en.py (--check | --build --src DIR)
DIR holds the pinned Natural Earth 1:10m populated places (the same file as
build_subdivision_symbols.py). A capital gets NAME_EN of the one Natural Earth
Admin-0 capital of its country whose Polish, local or English name equals the
bundled name or an alias (Poland: the Admin-0/1 capital with that Polish
name). Only names not yet accepted are written. The bundled capitals stay
untouched; the app adds these names to the aliases. --check is offline.
"""
import argparse
import hashlib
import json
from pathlib import Path
import unicodedata

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / 'assets/content/capitals_en.json'
PLACES = ('ne_10m_populated_places.geojson',
          'https://raw.githubusercontent.com/nvkelso/natural-earth-vector/v5.1.2/geojson/ne_10m_populated_places.geojson',
          '9b8e3de09048ef00dfc70357dbb9fa324493f214b5e0ae4daf1aa79a8d10116b')
# Area (Continent enum name) -> bundled capitals.
AREAS = {
    'europe': 'capitals.json', 'africa': 'africa/capitals.json', 'asia': 'asia/capitals.json',
    'northAmerica': 'northAmerica/capitals.json', 'southAmerica': 'southAmerica/capitals.json',
    'oceania': 'oceania/capitals.json', 'poland': 'poland/capitals.json',
}
# Natural Earth 5.1.2 still calls Astana „Nur-Sultan” (renamed back in 2022).
SKIP = {'KAZ'}


def norm(text):
    text = unicodedata.normalize('NFKD', (text or '').casefold())
    return ' '.join(''.join(c for c in text if not unicodedata.combining(c))
                    .replace('-', ' ').replace('’', "'").split())


def capitals(area):
    return json.loads((ROOT / 'assets/content' / AREAS[area]).read_text())['capitals']


def build(src):
    data = (src / PLACES[0]).read_bytes()
    assert hashlib.sha256(data).hexdigest() == PLACES[2]
    places = [f['properties'] for f in json.loads(data)['features']]
    names = {}
    for area in AREAS:
        found = {}
        for fact in capitals(area):
            if fact['country_id'] in SKIP:
                continue
            accepted = {norm(n) for n in [fact['name'], *fact['aliases']]}
            if area == 'poland':
                hits = [p for p in places if p['ADM0_A3'] == 'POL'
                        and p['FEATURECLA'] in ('Admin-0 capital', 'Admin-1 capital')
                        and norm(p['NAME_PL']) == norm(fact['name'])]
            else:
                hits = [p for p in places if p['ADM0_A3'] == fact['country_id']
                        and p['FEATURECLA'] == 'Admin-0 capital'
                        and accepted & {norm(p[k]) for k in ('NAME_PL', 'NAME', 'NAME_EN', 'NAMEASCII')}]
            if len(hits) == 1 and norm(hits[0]['NAME_EN']) not in accepted:
                found[fact['country_id']] = [hits[0]['NAME_EN']]
        if found:
            names[area] = found
    OUTPUT.write_text(json.dumps({
        'version': 'capitals-en-0.1.0',
        'source': {'name': 'Natural Earth 1:10m populated places, NAME_EN', 'url': PLACES[1],
                   'sha256': PLACES[2]},
        'names': names,
    }, ensure_ascii=False, indent=2) + '\n')
    check()


def check():
    data = json.loads(OUTPUT.read_text())
    assert data['source']['sha256'] == PLACES[2]
    count = 0
    for area, by_id in data['names'].items():
        facts = {f['country_id']: f for f in capitals(area)}
        taken = {norm(n) for f in facts.values() for n in [f['name'], *f['aliases']]}
        for country_id, extra in by_id.items():
            assert country_id in facts and country_id not in SKIP, (area, country_id)
            for name in extra:
                # A new name never repeats a name already accepted in the area.
                assert name.strip() == name and norm(name) not in taken, (area, name)
                count += 1
    assert data['names']['europe']['POL'] == ['Warsaw']
    print(f'OK: {count} English capital names, provenance')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--check', action='store_true')
    group.add_argument('--build', action='store_true')
    parser.add_argument('--src', type=Path)
    args = parser.parse_args()
    if args.check:
        check()
    else:
        if not args.src:
            parser.error('--build requires --src')
        build(args.src)
