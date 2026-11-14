#!/usr/bin/env python3
"""Neutral context land around each continent quiz; --check works offline.

Context is land inside a continent's rendering window that is not a quiz
target there (e.g. Kazakhstan and the Caucasus on the Europe map, Ukraine on
the Asia map, Western Sahara on the Africa map). It is drawn under the quiz
countries in one neutral colour and is never selectable. Russia and Morocco
are always included because the quiz layers cut policy areas out of them
(Crimea, the Morocco/Western Sahara split); the cut-out parts then read as
neutral land instead of sea.
"""
import argparse
import hashlib
import json
from pathlib import Path
import urllib.request

import build_map

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'assets/maps/context'
SOURCE_URL = build_map.URL
SOURCE_SHA = build_map.SHA256
# Same windows as the quiz geometries and CountryMap._bounds (W, S, E, N).
REGIONS = {
    'europe': ((-32, 34, 65, 72), 'assets/content/countries.json'),
    'africa': ((-26, -36, 65, 38), 'assets/content/africa/countries.json'),
    'asia': ((20, -12, 180, 82), 'assets/content/asia/countries.json'),
}
ALWAYS = {'RUS', 'MAR'}
# Points that must be covered by neutral context land on each map (lon, lat).
CONTROL = {
    'europe': [('KAZ', (60.0, 48.0)), ('GEO', (43.97, 42.23)), ('AZE', (46.75, 39.75)),
               ('DZA', (3.0, 35.0))],
    'africa': [('SAH', (-13.2, 25.0)), ('ESP', (-4.0, 37.5))],
    'asia': [('UKR', (30.5, 50.45)), ('RUS', (34.1, 44.95))],
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def quiz_ids(content):
    return {c['id'] for c in json.loads((ROOT / content).read_text())['countries']}


def build(source):
    data = Path(source).read_bytes() if source else urllib.request.urlopen(SOURCE_URL).read()
    assert hashlib.sha256(data).hexdigest() == SOURCE_SHA, 'Source checksum mismatch'
    features = json.loads(data)['features']
    DEST.mkdir(parents=True, exist_ok=True)
    files = {}
    for region, (window, content) in REGIONS.items():
        build_map.WINDOW = window
        targets = quiz_ids(content)
        selected = []
        for feature in features:
            code = feature['properties']['ADM0_A3']
            if code == 'ATA' or (code in targets and code not in ALWAYS):
                continue
            clipped = []
            for polygon in build_map.polygons(feature):
                outer = build_map.clip_ring(polygon[0])
                if outer:
                    clipped.append([outer] + [r for hole in polygon[1:] if (r := build_map.clip_ring(hole))])
            if clipped:
                selected.append({'type': 'Feature', 'id': code, 'properties': {'id': code},
                                 'geometry': {'type': 'MultiPolygon', 'coordinates': clipped}})
        path = DEST / f'{region}.geojson'
        path.write_bytes(build_map.encoded({'type': 'FeatureCollection', 'features': selected}))
        files[str(path.relative_to(ROOT))] = digest(path)
    manifest = {'source': SOURCE_URL, 'source_sha256': SOURCE_SHA, 'files': files}
    (DEST / 'manifest.json').write_bytes(build_map.encoded(manifest))
    check()


def check():
    manifest = json.loads((DEST / 'manifest.json').read_text())
    assert manifest['source_sha256'] == SOURCE_SHA
    total = 0
    for region, (window, content) in REGIONS.items():
        path = DEST / f'{region}.geojson'
        assert manifest['files'][str(path.relative_to(ROOT))] == digest(path), region
        features = json.loads(path.read_text())['features']
        ids = {f['id'] for f in features}
        assert not (ids & quiz_ids(content)) - ALWAYS, (region, 'quiz target in context')
        west, south, east, north = window
        for feature in features:
            for polygon in feature['geometry']['coordinates']:
                for ring in polygon:
                    assert len(ring) >= 4 and ring[0] == ring[-1], (region, feature['id'])
                    assert all(west <= x <= east and south <= y <= north for x, y in ring)
        for label, point in CONTROL[region]:
            # Labels name the area; any context feature may cover it (NE is de facto).
            assert any(build_map.contains_country(f, point) for f in features), (region, label)
        total += len(features)
    assert {p.name for p in DEST.iterdir()} == {f'{r}.geojson' for r in REGIONS} | {'manifest.json'}
    print(f'OK: context land for 3 maps ({total} features), windows, control points, checksums')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--source', help='Previously downloaded pinned Natural Earth GeoJSON')
    args = parser.parse_args()
    check() if args.check else build(args.source)
