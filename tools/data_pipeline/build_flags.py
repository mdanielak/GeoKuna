#!/usr/bin/env python3
"""Build pinned offline flag assets; --check validates the bundled package offline."""
import argparse
import hashlib
import io
import ctypes
import ctypes.util
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path
import urllib.request
from concurrent.futures import ThreadPoolExecutor

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
COMMIT = 'c09927e63705529bbf59ca6684cd9b23225dddad'
BASE = f'https://raw.githubusercontent.com/hampusborgos/country-flags/{COMMIT}'
NE = 'https://raw.githubusercontent.com/nvkelso/natural-earth-vector/v5.1.2/geojson/ne_50m_admin_0_countries.geojson'
NE_SHA = '3e458fc036ad0a66411f2c1e6cac49c5d7bfb81cb1123bc513b22511a2b7fdeb'
VERSION = 'europe-flags-0.1.0'
CONTENT = ROOT / 'assets/content/flags.json'
MANIFEST = ROOT / 'assets/content/flags_manifest.json'
DIR = 'assets/flags/europe-0.1.0'
SOURCES = 'tools/data_pipeline/flags_sources'


def digest(data):
    return hashlib.sha256(data).hexdigest()


def fetch(url):
    with urllib.request.urlopen(url, timeout=30) as response:
        return response.read()


def check():
    content = json.loads(CONTENT.read_text())
    manifest = json.loads(MANIFEST.read_text())
    countries = json.loads((ROOT / 'assets/content/countries.json').read_text())['countries']
    flags = content['flags']
    assert content['version'] == VERSION and content['source'] == BASE
    assert manifest['source'] == BASE and manifest['natural_earth_sha256'] == NE_SHA
    assert manifest['files']['assets/content/flags.json'] == digest(CONTENT.read_bytes())
    assert len(flags) == len(countries) == 51
    assert {f['country_id']: f['country_name'] for f in flags} == {c['id']: c['name'] for c in countries}
    assert len({f['country_id'] for f in flags}) == len({f['source_iso2'] for f in flags}) == len(flags)
    paths = set()
    for f in flags:
        assert f['status'] == 'verified' and f['verified_at'] and f['aliases'] == []
        iso = f['source_iso2']
        assert len(iso) == 2 and iso.isascii() and iso.isupper()
        assert f['asset_path'] == f'{DIR}/{iso.lower()}.png'
        path = ROOT / f['asset_path']
        data = path.read_bytes()
        assert digest(data) == f['sha256'] == manifest['files'][f['asset_path']]
        with Image.open(io.BytesIO(data)) as image:
            image.verify()
        with Image.open(io.BytesIO(data)) as image:
            assert image.format == 'PNG' and image.width == 500 and 0 < image.height <= 500
        source_path = f'{SOURCES}/{iso.lower()}.svg'
        assert digest((ROOT / source_path).read_bytes()) == f['source_sha256'] == manifest['files'][source_path]
        paths.add(source_path)
        paths.add(f['asset_path'])
    assert set(manifest['files']) == paths | {'assets/content/flags.json'}
    assert {str(p.relative_to(ROOT)) for p in (ROOT / DIR).glob('*.png')} == {p for p in paths if p.endswith('.png')}
    assert next(f for f in flags if f['country_id'] == 'KOS')['source_iso2'] == 'XK'
    print(f'Validated {len(flags)} flags, hashes and PNG dimensions offline')


def build():
    ne_data = fetch(NE)
    assert digest(ne_data) == NE_SHA
    geo = json.loads(ne_data)
    names_data = fetch(f'{BASE}/countries.json')
    names = json.loads(names_data)
    countries = json.loads((ROOT / 'assets/content/countries.json').read_text())['countries']
    mapping = {}
    for feature in geo['features']:
        p = feature['properties']
        code = p['ISO_A2'] if p['ISO_A2'] != '-99' else p['ISO_A2_EH']
        if p['ADM0_A3'] in {c['id'] for c in countries}:
            mapping[p['ADM0_A3']] = code
    mapping['KOS'] = 'XK'  # Documented by the pinned source README and countries.json.
    assert set(mapping) == {c['id'] for c in countries}
    assert len(set(mapping.values())) == len(mapping) and all(v in names for v in mapping.values())
    with ThreadPoolExecutor(max_workers=8) as pool:
        images = dict(zip(mapping.values(), pool.map(lambda iso: fetch(f'{BASE}/svg/{iso.lower()}.svg'), mapping.values())))
    rsvg = ctypes.CDLL(ctypes.util.find_library('rsvg-2'))
    cairo = ctypes.CDLL(ctypes.util.find_library('cairo'))
    gobject = ctypes.CDLL(ctypes.util.find_library('gobject-2.0'))
    class Rectangle(ctypes.Structure):
        _fields_ = [('x',ctypes.c_double),('y',ctypes.c_double),('width',ctypes.c_double),('height',ctypes.c_double)]
    rsvg.rsvg_handle_new_from_data.argtypes = [ctypes.c_char_p,ctypes.c_size_t,ctypes.POINTER(ctypes.c_void_p)]
    rsvg.rsvg_handle_new_from_data.restype = ctypes.c_void_p
    rsvg.rsvg_handle_render_document.argtypes = [ctypes.c_void_p,ctypes.c_void_p,ctypes.POINTER(Rectangle),ctypes.POINTER(ctypes.c_void_p)]
    rsvg.rsvg_handle_render_document.restype = ctypes.c_int
    cairo.cairo_image_surface_create.argtypes = [ctypes.c_int,ctypes.c_int,ctypes.c_int]
    cairo.cairo_image_surface_create.restype = ctypes.c_void_p
    cairo.cairo_create.argtypes = [ctypes.c_void_p]
    cairo.cairo_create.restype = ctypes.c_void_p
    cairo.cairo_surface_write_to_png.argtypes = [ctypes.c_void_p,ctypes.c_char_p]
    cairo.cairo_surface_write_to_png.restype = ctypes.c_int
    cairo.cairo_destroy.argtypes = [ctypes.c_void_p]
    cairo.cairo_surface_destroy.argtypes = [ctypes.c_void_p]
    cairo.cairo_version_string.restype = ctypes.c_char_p
    gobject.g_object_unref.argtypes = [ctypes.c_void_p]
    (ROOT / SOURCES).mkdir(parents=True, exist_ok=True)
    (ROOT / DIR).mkdir(parents=True, exist_ok=True)
    flags = []
    files = {}
    for c in countries:
        iso = mapping[c['id']]
        path = f'{DIR}/{iso.lower()}.png'
        source = images[iso]
        source_path = f'{SOURCES}/{iso.lower()}.svg'
        (ROOT / source_path).write_bytes(source)
        files[source_path] = digest(source)
        svg = ET.fromstring(source)
        vb = svg.attrib.get('viewBox')
        if vb:
            _, _, width, height = map(float, re.split(r'[,\s]+', vb.strip()))
        else:
            width = float(re.sub(r'px$', '', svg.attrib['width']))
            height = float(re.sub(r'px$', '', svg.attrib['height']))
        width_px, height_px = 500, round(500 * height / width)
        surface = cairo.cairo_image_surface_create(0, width_px, height_px)
        context = cairo.cairo_create(surface)
        error = ctypes.c_void_p()
        handle = rsvg.rsvg_handle_new_from_data(source,len(source),ctypes.byref(error))
        assert handle, f'Invalid SVG for {iso}'
        try:
            viewport = Rectangle(0,0,width_px,height_px)
            assert rsvg.rsvg_handle_render_document(handle,context,ctypes.byref(viewport),ctypes.byref(error)), f'Cannot render {iso}'
            assert cairo.cairo_surface_write_to_png(surface,str(ROOT/path).encode()) == 0
        finally:
            gobject.g_object_unref(handle)
            cairo.cairo_destroy(context)
            cairo.cairo_surface_destroy(surface)
        data = (ROOT/path).read_bytes()
        files[path] = digest(data)
        flags.append({'country_id': c['id'], 'country_name': c['name'], 'aliases': [],
                      'asset_path': path, 'source_iso2': iso, 'source_sha256': digest(source), 'sha256': digest(data),
                      'status': 'verified', 'verified_at': '2026-11-13'})
    CONTENT.write_text(json.dumps({'version': VERSION, 'source': BASE, 'flags': flags}, ensure_ascii=False, separators=(',', ':')) + '\n')
    files['assets/content/flags.json'] = digest(CONTENT.read_bytes())
    MANIFEST.write_text(json.dumps({'source': BASE, 'source_commit': COMMIT, 'countries_sha256': digest(names_data),
                                    'renderer': {'librsvg': '.'.join(str(ctypes.c_uint.in_dll(rsvg, key).value) for key in ['rsvg_major_version','rsvg_minor_version','rsvg_micro_version']), 'cairo': cairo.cairo_version_string().decode()},
                                    'natural_earth_source': NE, 'natural_earth_sha256': NE_SHA,
                                    'files': files}, ensure_ascii=False, indent=2) + '\n')
    check()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    check() if args.check else build()
