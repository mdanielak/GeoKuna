#!/usr/bin/env python3
"""Build/validate offline data for the newer continents (Americas, Oceania)
from pinned Natural Earth, KSNG and flag sources — same pipeline as Asia.

Usage: build_region.py REGION (--check | --build --pdf KSNG.pdf [--source NE] [--places NE])
--check is offline. --build verifies the KSNG PDF and Natural Earth downloads
by SHA-256, downloads pinned SVGs and renders local PNGs.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
import ctypes
import ctypes.util
import hashlib
import io
import json
from pathlib import Path
import re
import subprocess
import urllib.request
import xml.etree.ElementTree as ET

from PIL import Image
import build_map
import build_asia

ROOT = Path(__file__).resolve().parents[2]
NE_URL = build_map.URL
NE_SHA = build_map.SHA256
FLAG_COMMIT = build_asia.FLAG_COMMIT
FLAG_BASE = build_asia.FLAG_BASE
PLACES_URL = build_asia.PLACES_URL
PLACES_SHA = build_asia.PLACES_SHA
PDF_URL = build_asia.PDF_URL
PDF_SHA = build_asia.PDF_SHA
VERIFIED = '2026-11-16'

# Region: asset folder name (= Dart Continent.name), KSNG continent label,
# rendering window (W, S, E, N) and the expected educational areas.
REGIONS = {
    'north_america': dict(
        folder='northAmerica', ksng='Ameryka Północna', window=(-170, 5, -50, 84),
        ids='ATG BHS BRB BLZ DMA DOM GRD GTM HTI HND JAM CAN CRI CUB MEX NIC PAN KNA LCA VCT SLV USA',
        small='ATG BRB DMA GRD KNA LCA VCT', plural='BHS USA'),
    'south_america': dict(
        folder='southAmerica', ksng='Ameryka Południowa', window=(-95, -57, -30, 15),
        ids='ARG BOL BRA CHL ECU GUY COL PRY PER SUR TTO URY VEN',
        small='TTO', plural=''),
    # Window in coordinates shifted by 180° (see build_map.shift_lon):
    # 110°E → -70, 180° → 0, 150°W → 30.
    'oceania': dict(
        folder='oceania', ksng='Australia i Oceania', window=(-70, -50, 30, 22), shift=180,
        ids='AUS FJI KIR FSM NRU NZL PLW PNG WSM TON TUV VUT MHL SLB',
        small='NRU TUV PLW MHL FSM KIR TON WSM', plural='MHL SLB'),
}


def setup(region):
    global R, CURATED, CONTENT, GEOMETRY, SOURCES, FLAGDIR, MANIFEST, EXPECTED_IDS, SMALL_IDS, PLURAL_IDS
    R = REGIONS[region]
    folder = R['folder']
    CURATED = ROOT / f'tools/data_pipeline/{region}_curated.json'
    CONTENT = ROOT / f'assets/content/{folder}'
    GEOMETRY = ROOT / f'assets/maps/{folder}.geojson'
    SOURCES = ROOT / f'tools/data_pipeline/{region}_flags_sources'
    FLAGDIR = ROOT / f'assets/flags/{folder}-0.1.0'
    MANIFEST = CONTENT / 'manifest.json'
    EXPECTED_IDS = set(R['ids'].split())
    SMALL_IDS = set(R['small'].split())
    PLURAL_IDS = set(R['plural'].split())


def sha(data):
    return hashlib.sha256(data).hexdigest()


def fetch(url):
    with urllib.request.urlopen(url, timeout=45) as response:
        return response.read()


def write_json(path, value, compact=False):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, separators=(',', ':') if compact else None, indent=None if compact else 2) + '\n')


def polygon_contains(feature, point):
    return build_map.contains_country(feature, point)


def interior_point(feature, suggested):
    if polygon_contains(feature, suggested):
        return suggested
    # Find an interior point on scan lines through the largest polygon. This
    # works for narrow islands and concave coastlines without external geometry libraries.
    candidates = []
    for polygon in feature['geometry']['coordinates']:
        ring = polygon[0]
        area = abs(sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(ring, ring[1:])))
        candidates.append((area, polygon))
    for _, polygon in sorted(candidates, key=lambda p: p[0], reverse=True):
        ring = polygon[0]
        low, high = min(p[1] for p in ring), max(p[1] for p in ring)
        for fraction in (.5, .4, .6, .3, .7, .2, .8):
            y = low + fraction * (high - low)
            xs = sorted(a[0] + (y - a[1]) * (b[0] - a[0]) / (b[1] - a[1])
                        for a, b in zip(ring, ring[1:]) if (a[1] > y) != (b[1] > y))
            for left, right in sorted(zip(xs[::2], xs[1::2]), key=lambda v: v[1] - v[0], reverse=True):
                point = [round((left + right) / 2, 6), round(y, 6)]
                if polygon_contains(feature, point):
                    return point
    raise ValueError(f'No interior point for {feature["id"]}')


def verify_pdf(pdf, curated):
    assert sha(pdf.read_bytes()) == PDF_SHA, 'KSNG PDF checksum mismatch'
    pages = subprocess.check_output(['pdftotext', '-layout', str(pdf), '-']).decode().split('\f')
    text = '\f'.join(pages)
    for fact in curated['capitals']:
        name = next(c['name'] for c in curated['countries'] if c['id'] == fact['country_id'])
        headings = list(re.finditer(r'^' + re.escape(name) + r'(?:\*)?\s{2,}.*' + re.escape(R['ksng']) + r'.*$', text, re.M))
        assert headings, (fact['country_id'], 'missing country heading')
        # In the KSNG update a later corrected entry supersedes an earlier entry.
        heading = headings[-1]
        capital_line = re.search(r'^stol\. (.*)', text[heading.end():], re.M)
        assert capital_line, (fact['country_id'], 'missing capital')
        assert re.match(re.escape(fact['name']) + r'(?:,| ndm\.|;|\*| \()', capital_line.group(1)), (fact['country_id'], 'capital mismatch')
        assert text[:heading.end() + capital_line.start()].count('\f') + 1 == fact['source_page'], (fact['country_id'], 'page mismatch')


def renderer():
    rsvg = ctypes.CDLL(ctypes.util.find_library('rsvg-2'))
    cairo = ctypes.CDLL(ctypes.util.find_library('cairo'))
    gobj = ctypes.CDLL(ctypes.util.find_library('gobject-2.0'))
    class Rectangle(ctypes.Structure):
        _fields_ = [('x', ctypes.c_double), ('y', ctypes.c_double), ('width', ctypes.c_double), ('height', ctypes.c_double)]
    rsvg.rsvg_handle_new_from_data.argtypes = [ctypes.c_char_p, ctypes.c_size_t, ctypes.POINTER(ctypes.c_void_p)]
    rsvg.rsvg_handle_new_from_data.restype = ctypes.c_void_p
    rsvg.rsvg_handle_render_document.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.POINTER(Rectangle), ctypes.POINTER(ctypes.c_void_p)]
    rsvg.rsvg_handle_render_document.restype = ctypes.c_int
    cairo.cairo_image_surface_create.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.c_int]
    cairo.cairo_image_surface_create.restype = ctypes.c_void_p
    cairo.cairo_create.argtypes = [ctypes.c_void_p]
    cairo.cairo_create.restype = ctypes.c_void_p
    cairo.cairo_surface_write_to_png.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
    cairo.cairo_surface_write_to_png.restype = ctypes.c_int
    cairo.cairo_destroy.argtypes = [ctypes.c_void_p]
    cairo.cairo_surface_destroy.argtypes = [ctypes.c_void_p]
    cairo.cairo_version_string.restype = ctypes.c_char_p
    gobj.g_object_unref.argtypes = [ctypes.c_void_p]
    def render(data, path):
        svg = ET.fromstring(data)
        vb = svg.attrib.get('viewBox')
        if vb:
            _, _, width, height = map(float, re.split(r'[,\s]+', vb.strip()))
        else:
            width = float(re.sub(r'(px|pt|mm)$', '', svg.attrib['width']))
            height = float(re.sub(r'(px|pt|mm)$', '', svg.attrib['height']))
        w, h = 500, round(500 * height / width)
        surface = cairo.cairo_image_surface_create(0, w, h)
        ctx = cairo.cairo_create(surface)
        err = ctypes.c_void_p()
        handle = rsvg.rsvg_handle_new_from_data(data, len(data), ctypes.byref(err))
        assert handle
        try:
            assert rsvg.rsvg_handle_render_document(handle, ctx, ctypes.byref(Rectangle(0, 0, w, h)), ctypes.byref(err))
            assert cairo.cairo_surface_write_to_png(surface, str(path).encode()) == 0
        finally:
            gobj.g_object_unref(handle)
            cairo.cairo_destroy(ctx)
            cairo.cairo_surface_destroy(surface)
    versions = {'librsvg': '.'.join(str(ctypes.c_uint.in_dll(rsvg, k).value) for k in ('rsvg_major_version', 'rsvg_minor_version', 'rsvg_micro_version')), 'cairo': cairo.cairo_version_string().decode()}
    return render, versions


def build(pdf, source, places):
    curated = json.loads(CURATED.read_text())
    verify_pdf(pdf, curated)
    ne_bytes = source.read_bytes() if source else fetch(NE_URL)
    assert sha(ne_bytes) == NE_SHA, 'Natural Earth checksum mismatch'
    places_bytes = places.read_bytes() if places else fetch(PLACES_URL)
    assert sha(places_bytes) == PLACES_SHA, 'Natural Earth populated places checksum mismatch'
    places_rows = [f['properties'] for f in json.loads(places_bytes)['features']]
    for fact in curated['capitals']:
        for alias in fact['aliases']:
            assert any(p['ADM0_A3'] == fact['country_id'] and (p.get('NAME_PL') or '').casefold() == fact['name'].casefold() and (p.get('NAME_EN') or '').casefold() == alias.casefold() for p in places_rows), (fact['country_id'], alias)
    features = json.loads(ne_bytes)['features']
    by_id = {f['properties']['ADM0_A3']: f for f in features}
    countries, shapes = [], []
    for raw in curated['countries']:
        code = raw['id']
        source_feature = by_id[code]
        assert all(alias == source_feature['properties']['NAME_EN'] for alias in raw['aliases'])
        polygons = build_map.shift_polygons(list(build_map.polygons(source_feature)), R.get('shift', 0))
        # The single-world map is clipped at the antimeridian and to the
        # continental educational viewing window; no east/west wrapping.
        build_map.WINDOW = R['window']
        clipped = []
        for polygon in polygons:
            outer = build_map.clip_ring(polygon[0])
            if outer:
                clipped.append([outer] + [part for hole in polygon[1:] if (part := build_map.clip_ring(hole))])
        polygons = clipped
        assert polygons, code
        shape = {'type': 'Feature', 'id': code, 'properties': {'id': code},
                 'geometry': {'type': 'MultiPolygon', 'coordinates': polygons}}
        props = source_feature['properties']
        lon, lat = interior_point(shape, [build_map.shift_lon(props['LABEL_X'], R.get('shift', 0)), props['LABEL_Y']])
        countries.append({'id': code, 'name': raw['name'], 'latitude': lat, 'longitude': lon,
                          'small': raw['small'], 'plural': raw['plural']})
        shapes.append(shape)
    write_json(CONTENT / 'countries.json', {'version':f"{R['folder']}-location-0.1.0", 'source': NE_URL, 'license':'Public domain', 'countries':countries}, compact=True)
    write_json(GEOMETRY, {'type':'FeatureCollection', 'features': shapes}, compact=True)
    write_json(CONTENT / 'capitals.json', {'version':f"{R['folder']}-capitals-0.1.0", 'source': curated['source'], 'capitals':curated['capitals']})
    iso_mapping = {c['id']: c['iso2'] for c in curated['countries']}
    for code, iso in iso_mapping.items():
        p = by_id[code]['properties']
        assert iso == (p['ISO_A2'] if p['ISO_A2'] != '-99' else p['ISO_A2_EH']), code
    with ThreadPoolExecutor(max_workers=6) as pool:
        images = dict(zip(iso_mapping.values(), pool.map(lambda iso: fetch(f'{FLAG_BASE}/svg/{iso.lower()}.svg'), iso_mapping.values())))
    SOURCES.mkdir(parents=True, exist_ok=True)
    FLAGDIR.mkdir(parents=True, exist_ok=True)
    render, versions = renderer()
    flags = []
    for c in curated['countries']:
        iso = c['iso2']; data = images[iso]
        source_path = SOURCES / (iso.lower() + '.svg')
        source_path.write_bytes(data)
        image_path = FLAGDIR / (iso.lower() + '.png')
        render(data, image_path)
        flags.append({'country_id':c['id'], 'country_name':c['name'], 'aliases':c['aliases'],
                      'asset_path':str(image_path.relative_to(ROOT)), 'source_iso2':iso,
                      'source_sha256':sha(data), 'sha256':sha(image_path.read_bytes()),
                      'status':'verified', 'verified_at':VERIFIED})
    write_json(CONTENT / 'flags.json', {'version':f"{R['folder']}-flags-0.1.0",'source':FLAG_BASE,'flags':flags}, compact=True)
    paths = [CURATED, GEOMETRY, CONTENT / 'countries.json', CONTENT / 'capitals.json', CONTENT / 'flags.json', *sorted(SOURCES.glob('*.svg')), *sorted(FLAGDIR.glob('*.png'))]
    files = {str(p.relative_to(ROOT)):sha(p.read_bytes()) for p in paths}
    write_json(MANIFEST, {'natural_earth_source':NE_URL,'natural_earth_sha256':NE_SHA,'populated_places_source':PLACES_URL, 'populated_places_sha256':PLACES_SHA,
                          'ksng_source':PDF_URL,'ksng_sha256':PDF_SHA,
                          'flags_source':FLAG_BASE,'flags_commit':FLAG_COMMIT,
                          'renderer':versions,'files':files})
    check()


def check():
    curated = json.loads(CURATED.read_text())
    countries = json.loads((CONTENT / 'countries.json').read_text())['countries']
    capitals = json.loads((CONTENT / 'capitals.json').read_text())['capitals']
    flags = json.loads((CONTENT / 'flags.json').read_text())['flags']
    shapes = json.loads(GEOMETRY.read_text())['features']
    manifest = json.loads(MANIFEST.read_text())
    n = len(EXPECTED_IDS)
    for rows, key in [(curated['countries'], 'id'), (countries, 'id'), (capitals, 'country_id'), (flags, 'country_id'), (shapes, 'id')]:
        ids = [row[key] for row in rows]
        assert len(ids) == len(set(ids)) == n and set(ids) == EXPECTED_IDS, key
    assert capitals == curated['capitals']
    assert curated['source']['url'] == PDF_URL and curated['source']['sha256'] == PDF_SHA
    assert manifest['natural_earth_sha256'] == NE_SHA and manifest['ksng_sha256'] == PDF_SHA and manifest['flags_commit'] == FLAG_COMMIT
    by_id = {f['id']:f for f in shapes}
    expected_names = {c['id']:c['name'] for c in curated['countries']}
    assert {c['id']:c['name'] for c in countries} == expected_names
    assert {c['country_id']:c['country_name'] for c in flags} == expected_names
    assert len({f['name'].casefold() for f in capitals}) == n
    assert {c['id'] for c in countries if c['plural']} == PLURAL_IDS
    assert {c['id'] for c in countries if c['small']} == SMALL_IDS
    for c in countries:
        assert polygon_contains(by_id[c['id']], [c['longitude'], c['latitude']]), (c['id'], 'center outside polygon')
        shape = by_id[c['id']]
        assert shape['geometry']['type'] == 'MultiPolygon'
        for polygon in shape['geometry']['coordinates']:
            for ring in polygon:
                assert len(ring) >= 4 and ring[0] == ring[-1], (c['id'], 'unclosed ring')
    for code in SMALL_IDS:
        assert by_id[code]['geometry']['coordinates']
    for fact in capitals:
        assert fact['status'] == 'verified' and fact['verified_at'] == VERIFIED
        assert fact['source_page'] > 0 and fact['id'] == 'capital:' + fact['country_id']
    all_assets = set()
    for f in flags:
        iso = f['source_iso2'].lower()
        expected = f"assets/flags/{R['folder']}-0.1.0/{iso}.png"
        assert f['asset_path'] == expected and f['status'] == 'verified' and f['verified_at']
        path = ROOT / expected; source_path = SOURCES / f'{iso}.svg'
        assert sha(path.read_bytes()) == f['sha256'] and sha(source_path.read_bytes()) == f['source_sha256']
        svg = ET.fromstring(source_path.read_bytes())
        vb = svg.attrib.get('viewBox')
        if vb:
            _, _, source_width, source_height = map(float, re.split(r'[,\s]+', vb.strip()))
        else:
            source_width = float(re.sub(r'px$', '', svg.attrib['width']))
            source_height = float(re.sub(r'px$', '', svg.attrib['height']))
        with Image.open(io.BytesIO(path.read_bytes())) as im:
            assert im.height == round(500 * source_height / source_width), f['country_id']
            assert im.format == 'PNG' and im.width == 500 and 0 < im.height <= 1000
            im.verify()
        all_assets.update([str(path.relative_to(ROOT)), str(source_path.relative_to(ROOT))])
    expected_paths = all_assets | {str(p.relative_to(ROOT)) for p in [CURATED, GEOMETRY, CONTENT / 'countries.json', CONTENT / 'capitals.json', CONTENT / 'flags.json']}
    assert set(manifest['files']) == expected_paths
    assert {str(p.relative_to(ROOT)) for p in SOURCES.glob('*.svg')} == {p for p in all_assets if p.endswith('.svg')}
    assert {str(p.relative_to(ROOT)) for p in FLAGDIR.glob('*.png')} == {p for p in all_assets if p.endswith('.png')}
    for path, digest in manifest['files'].items():
        assert sha((ROOT / path).read_bytes()) == digest, path
    print(f"OK {R['folder']}: {n} areas, capital facts, offline flags, geometry and checksums")


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('region', choices=sorted(REGIONS))
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--check', action='store_true')
    group.add_argument('--build', action='store_true')
    parser.add_argument('--pdf', type=Path, help='Pinned KSNG PDF including 2026 update (required for --build)')
    parser.add_argument('--source', type=Path, help='Previously downloaded pinned Natural Earth GeoJSON')
    parser.add_argument('--places', type=Path, help='Previously downloaded pinned Natural Earth populated places')
    args = parser.parse_args()
    setup(args.region)
    if args.check:
        check()
    else:
        if not args.pdf:
            parser.error('--build requires --pdf')
        build(args.pdf, args.source, args.places)
