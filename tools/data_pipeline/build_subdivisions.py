#!/usr/bin/env python3
"""Build/validate the subdivision maps: Polish voivodeships and US states.

Usage: build_subdivisions.py REGION (--check | --build --src DIR)
DIR holds the pinned sources: ne_10m_admin_1_states_provinces.geojson,
ne_10m_admin_0_countries.geojson, du_1998_96_603.pdf (Polish act creating the
voivodeships) and ksng_swiat_2019.pdf (KSNG world names, US states p. 595).
--check is offline. Location quiz only (stage 1): no capitals or flags yet.
US insets: Alaska and Hawaii are moved and scaled in Web Mercator into framed
boxes in the lower-left of the map window (an atlas convention, not geography).
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import re
import subprocess

import build_map

ROOT = Path(__file__).resolve().parents[2]
NE_BASE = 'https://raw.githubusercontent.com/nvkelso/natural-earth-vector/v5.1.2/geojson/'
SOURCES = {
    'admin1': ('ne_10m_admin_1_states_provinces.geojson', NE_BASE + 'ne_10m_admin_1_states_provinces.geojson',
               '22d0e3ad85eb3e27f17cabf8ba2d50e554fbc27a87796ff891d958185da62fb5'),
    'admin0': ('ne_10m_admin_0_countries.geojson', NE_BASE + 'ne_10m_admin_0_countries.geojson',
               '239eec57ac17f100a11e2536cffc56752c318b50ae765b0918ff7aab4ce8f255'),
    'act': ('du_1998_96_603.pdf', 'https://dziennikustaw.gov.pl/D1998096060301.pdf',
            '5a80569eec3fd45f76ec5701e562dc33c927be23a0cfbb88ea8c391850ace1f3'),
    'ksng': ('ksng_swiat_2019.pdf', 'https://www.gov.pl/attachment/19fa85f9-65de-4bb0-8cc4-7dc552229b7d',
             '8389e875749ee78ec018be8356e91c055171deff728d0ee7877d83afb242cb74'),
}
VERIFIED = '2026-11-16'
# ISO 3166-2:PL since 2018 uses the TERYT voivodeship codes.
TERYT = {'DS': '02', 'KP': '04', 'LU': '06', 'LB': '08', 'LD': '10', 'MA': '12', 'MZ': '14',
         'OP': '16', 'PK': '18', 'PD': '20', 'PM': '22', 'SL': '24', 'SK': '26', 'WN': '28',
         'WP': '30', 'ZP': '32'}
REGIONS = {
    'poland': dict(adm0='POL', window=(13.5, 48.6, 24.5, 55.3), count=16, small=set()),
    'usa': dict(adm0='USA', window=(-128.0, 16.0, -64.0, 51.0), count=50, small={'US-RI', 'US-DE'},
                context_admin1={'US-DC'},
                # Inset frames (W, S, E, N) in map coordinates and source parts kept.
                insets={'US-AK': ('Alaska — inna skala', (-128.0, 16.5, -111.5, 28.0)),
                        'US-HI': ('Hawaje — inna skala', (-110.5, 16.5, -101.0, 22.5))}),
}
# The cities sharing a state name need the word "stan" in the question.
CITY_NAMES = {'US-WA', 'US-NY'}
# Land / water control points per map (lon, lat) in map coordinates.
CONTROL = {
    'poland': [('PL-14', (21.0, 52.23)), ('PL-24', (19.02, 50.26)), ('PL-22', (18.65, 54.35))],
    'usa': [('US-CA', (-120.0, 37.0)), ('US-TX', (-99.0, 31.0)), ('US-NY', (-75.5, 42.75)),
            ('US-CO', (-105.5, 39.0))],
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(build_map.encoded(value))


def merc(lon, lat):
    return math.radians(lon), math.asinh(math.tan(math.radians(lat)))


def unmerc(x, y):
    return math.degrees(x), math.degrees(math.atan(math.sinh(y)))


def simplify(ring, tolerance):
    """Douglas–Peucker on a closed ring (inset parts only: no shared borders)."""
    if len(ring) < 8:
        return ring
    def rdp(points):
        (x1, y1), (x2, y2) = points[0], points[-1]
        dx, dy = x2 - x1, y2 - y1
        norm = math.hypot(dx, dy) or 1e-12
        far, index = 0.0, 0
        for i, (x, y) in enumerate(points[1:-1], 1):
            d = abs(dy * x - dx * y + x2 * y1 - y2 * x1) / norm
            if d > far:
                far, index = d, i
        if far <= tolerance:
            return [points[0], points[-1]]
        return rdp(points[:index + 1])[:-1] + rdp(points[index:])
    half = len(ring) // 2
    out = rdp(ring[:half + 1])[:-1] + rdp(ring[half:])
    return out if len(out) >= 4 else ring


def inset(polygons, frame, keep_west):
    """Move/scale polygons into frame, fitted in Web Mercator with padding."""
    parts = []
    for polygon in polygons:
        # Aleutians west of 180° are +lon in the source; unwrap to one side.
        unwrapped = [[[x - 360 if x > 0 else x, y] for x, y in ring] for ring in polygon]
        if min(x for x, _ in unwrapped[0]) < keep_west:
            continue
        parts.append(unwrapped)
    xs = [merc(x, y) for p in parts for x, y in p[0]]
    minx, maxx = min(x for x, _ in xs), max(x for x, _ in xs)
    miny, maxy = min(y for _, y in xs), max(y for _, y in xs)
    fx0, fy0 = merc(frame[0], frame[1]); fx1, fy1 = merc(frame[2], frame[3])
    pad, label = .08, .2  # the top band keeps the frame's caption readable
    fy1 -= (fy1 - fy0) * label
    scale = min((fx1 - fx0) * (1 - 2 * pad) / (maxx - minx), (fy1 - fy0) * (1 - 2 * pad) / (maxy - miny))
    ox = (fx0 + fx1) / 2 - (minx + maxx) / 2 * scale
    oy = (fy0 + fy1) / 2 - (miny + maxy) / 2 * scale
    out = []
    for polygon in parts:
        rings = []
        for ring in polygon:
            moved = [list(unmerc(ox + mx * scale, oy + my * scale))
                     for mx, my in (merc(x, y) for x, y in ring)]
            # About 2 km on the inset's screen: plenty for a framed overview.
            moved = [[round(x, 5), round(y, 5)] for x, y in simplify(moved, .02)]
            if len(moved) >= 4:
                moved[-1] = moved[0]
                rings.append(moved)
        if rings:
            out.append(rings)
    return out, scale


def clipped(polygons, window):
    build_map.WINDOW = window
    out = []
    for polygon in polygons:
        outer = build_map.clip_ring(polygon[0])
        if outer:
            out.append([outer] + [r for hole in polygon[1:] if (r := build_map.clip_ring(hole))])
    return [[[[round(x, 5), round(y, 5)] for x, y in ring] for ring in p] for p in out]


def interior(feature, suggested):
    if build_map.contains_country(feature, suggested):
        return suggested
    best = max(feature['geometry']['coordinates'],
               key=lambda p: abs(sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(p[0], p[0][1:]))))
    ring = best[0]
    low, high = min(p[1] for p in ring), max(p[1] for p in ring)
    for f in (.5, .4, .6, .3, .7):
        y = low + f * (high - low)
        xs = sorted(a[0] + (y - a[1]) * (b[0] - a[0]) / (b[1] - a[1])
                    for a, b in zip(ring, ring[1:]) if (a[1] > y) != (b[1] > y))
        for left, right in sorted(zip(xs[::2], xs[1::2]), key=lambda v: v[1] - v[0], reverse=True):
            point = [round((left + right) / 2, 5), round(y, 5)]
            if build_map.contains_country(feature, point):
                return point
    raise ValueError(feature['id'])


def pdf_text(path):
    return subprocess.check_output(['pdftotext', '-layout', str(path), '-']).decode()


def polish_names(act):
    """Names from art. 2 ust. 1 of Dz.U. 1998 nr 96 poz. 603 (OCR layer)."""
    text = pdf_text(act)
    names = {}
    for number, name in re.findall(r'^\s*(\d{1,2})\) ([a-ząćęłńóśźż-]+kie)[,.]', text, re.M):
        names.setdefault(int(number), name)
    assert sorted(names) == list(range(1, 17)), sorted(names)
    return names


def ksng_states(pdf):
    """Polish exonyms of US states, KSNG world list 2019, p. 595."""
    pages = pdf_text(pdf).split('\f')
    # Printed page 595 (the PDF has front matter, so find it by its footer).
    [page] = [p for p in pages if 'Kalifornia; California; ofic.' in p]
    assert re.search(r'^\s+595\s*$', page, re.M) and 'Jednostki administracyjne' in page
    section = page.split('Jednostki administracyjne', 1)[1]
    out = {}
    for polish, english in re.findall(r'^([^;\n]+); ([^;\n]+);', section, re.M):
        out[english.strip()] = polish.strip()
    assert 'California' in out and len(out) >= 17, out
    return out


def setup(region):
    r = REGIONS[region]
    return (r, ROOT / f'assets/content/{region}', ROOT / f'assets/maps/{region}.geojson',
            ROOT / f'assets/maps/context/{region}.geojson')


def build(region, src):
    r, content, geometry, context_path = setup(region)
    data = {}
    for key, (name, _, digest) in SOURCES.items():
        raw = (src / name).read_bytes()
        assert sha(raw) == digest, f'{name} checksum mismatch'
        data[key] = raw
    admin1 = [f for f in json.loads(data['admin1'])['features'] if f['properties']['adm0_a3'] == r['adm0']]
    names = {}
    if region == 'poland':
        legal = polish_names(src / SOURCES['act'][0])
        order = sorted(TERYT, key=lambda k: TERYT[k])  # the act lists them in TERYT order
        for i, letters in enumerate(order, 1):
            names[f'PL-{TERYT[letters]}'] = (legal[i], f'województwo {legal[i]}')
        for f in admin1:  # Natural Earth agrees with the act
            p = f['properties']
            assert p['name_pl'] == names[f"PL-{TERYT[p['iso_3166_2'].split('-')[1]]}"][1], p['name_pl']
        code_of = lambda p: f"PL-{TERYT[p['iso_3166_2'].split('-')[1]]}"
    else:
        exonyms = ksng_states(src / SOURCES['ksng'][0])
        for f in admin1:
            p = f['properties']
            if p['iso_3166_2'] in r['context_admin1']:
                continue
            name = exonyms.get(p['name'], p['name'])
            names[p['iso_3166_2']] = (name, f'stan {name}' if p['iso_3166_2'] in CITY_NAMES else name)
        code_of = lambda p: p['iso_3166_2']
    countries, shapes, context, frames = [], [], [], []
    for f in admin1:
        code = code_of(f['properties'])
        polygons = build_map.polygons(f)
        if code in r.get('context_admin1', ()):
            context.append({'type': 'Feature', 'id': code, 'properties': {'id': code},
                            'geometry': {'type': 'MultiPolygon', 'coordinates': clipped(polygons, r['window'])}})
            continue
        if code in r.get('insets', {}):
            label, frame = r['insets'][code]
            coords, scale = inset(polygons, frame, -161.0 if code == 'US-HI' else -200.0)
            frames.append({'id': code, 'label': label, 'bounds_wsen': list(frame), 'scale': round(scale, 4)})
        else:
            coords = clipped(polygons, r['window'])
        shape = {'type': 'Feature', 'id': code, 'properties': {'id': code},
                 'geometry': {'type': 'MultiPolygon', 'coordinates': coords}}
        name, question = names[code]
        p = f['properties']
        suggested = [p['longitude'], p['latitude']] if code not in r.get('insets', {}) else \
            [round((frames[-1]['bounds_wsen'][0] + frames[-1]['bounds_wsen'][2]) / 2, 5),
             round((frames[-1]['bounds_wsen'][1] + frames[-1]['bounds_wsen'][3]) / 2, 5)]
        lon, lat = interior(shape, suggested)
        countries.append({'id': code, 'name': name, 'question_name': question,
                          'latitude': lat, 'longitude': lon,
                          'small': code in r['small'], 'plural': False})
        shapes.append(shape)
    countries.sort(key=lambda c: c['id'])
    shapes.sort(key=lambda s: s['id'])
    for f in json.loads(data['admin0'])['features']:
        code = f['properties']['ADM0_A3']
        if code == r['adm0']:
            continue
        coords = clipped(build_map.polygons(f), r['window'])
        if coords:
            context.append({'type': 'Feature', 'id': code, 'properties': {'id': code},
                            'geometry': {'type': 'MultiPolygon', 'coordinates': coords}})
    write(content / 'countries.json', {'version': f'{region}-location-0.1.0', 'source': SOURCES['admin1'][1],
                                       'license': 'Public domain', 'countries': countries,
                                       'inset_frames': frames})
    write(geometry, {'type': 'FeatureCollection', 'features': shapes})
    write(context_path, {'type': 'FeatureCollection', 'features': context})
    files = {str(p.relative_to(ROOT)): sha(p.read_bytes()) for p in (content / 'countries.json', geometry, context_path)}
    write(content / 'manifest.json', {
        'sources': {k: {'url': url, 'sha256': digest} for k, (_, url, digest) in SOURCES.items()
                    if region == 'usa' or k != 'ksng'},
        'names': 'Dz.U. 1998 nr 96 poz. 603, art. 2 ust. 1' if region == 'poland' else
                 'KSNG, Urzędowy wykaz polskich nazw geograficznych świata, wyd. 2, 2019, s. 595; pozostałe stany — nazwa oryginalna',
        'verified_at': VERIFIED, 'files': files})
    check(region)


def check(region):
    r, content, geometry, context_path = setup(region)
    manifest = json.loads((content / 'manifest.json').read_text())
    for path, digest in manifest['files'].items():
        assert sha((ROOT / path).read_bytes()) == digest, path
    catalog = json.loads((content / 'countries.json').read_text())
    countries = catalog['countries']
    shapes = {f['id']: f for f in json.loads(geometry.read_text())['features']}
    context = json.loads(context_path.read_text())['features']
    ids = [c['id'] for c in countries]
    assert len(ids) == len(set(ids)) == r['count'] == len(shapes) and set(ids) == set(shapes)
    pattern = r'PL-(0[2468]|[12][02468]|3[02])' if region == 'poland' else r'US-[A-Z]{2}'
    assert all(re.fullmatch(pattern, i) for i in ids)
    assert {c['id'] for c in countries if c['small']} == r['small']
    west, south, east, north = r['window']
    for c in countries:
        shape = shapes[c['id']]
        assert build_map.contains_country(shape, [c['longitude'], c['latitude']]), c['id']
        assert c['question_name'].endswith(c['name'])
        for polygon in shape['geometry']['coordinates']:
            for ring in polygon:
                assert len(ring) >= 4 and ring[0] == ring[-1], c['id']
                assert all(west <= x <= east and south <= y <= north for x, y in ring), c['id']
    if region == 'poland':
        assert all(c['question_name'] == f"województwo {c['name']}" for c in countries)
    else:
        by = {c['id']: c for c in countries}
        assert by['US-WA']['question_name'] == 'stan Waszyngton' and by['US-NY']['question_name'] == 'stan Nowy Jork'
        assert by['US-CA']['name'] == 'Kalifornia' and by['US-OH']['name'] == 'Ohio'
        frames = {f['id']: f for f in catalog['inset_frames']}
        assert set(frames) == set(r['insets'])
        for code, frame in frames.items():
            fw, fs, fe, fn = frame['bounds_wsen']
            for polygon in shapes[code]['geometry']['coordinates']:
                assert all(fw <= x <= fe and fs <= y <= fn for x, y in polygon[0]), code
            # No other state may reach into an inset frame.
            for other, shape in shapes.items():
                if other not in frames:
                    assert not any(fw < x < fe and fs < y < fn for p in shape['geometry']['coordinates']
                                   for x, y in p[0]), (other, code)
    for code, point in CONTROL[region]:
        assert build_map.contains_country(shapes[code], list(point)), code
    assert not {f['id'] for f in context} & set(ids)
    print(f'OK {region}: {len(ids)} areas, names, geometry, context ({len(context)}), checksums')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('region', choices=sorted(REGIONS))
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--check', action='store_true')
    group.add_argument('--build', action='store_true')
    parser.add_argument('--src', type=Path, help='Directory with the pinned sources (see docstring)')
    args = parser.parse_args()
    if args.check:
        check(args.region)
    else:
        if not args.src:
            parser.error('--build requires --src')
        build(args.region, args.src)
