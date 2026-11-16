#!/usr/bin/env python3
"""Offline shaded-relief tiles with rivers and lakes; --check works without network.

Source: Natural Earth I with Shaded Relief, Water and Drainages, 1:10m (WGS84,
1/60° per pixel). Output: Web Mercator XYZ tiles (256 px, zoom 2–6) in one flat
folder, `<set>_<z>_<x>_<y>.webp`, read by flutter_map's AssetTileProvider.
Set `world` covers every unshifted region window (tiles are shared); set
`oceania` is rendered from the source rolled by 180°, like its geometry
(build_map.shift_lon). Each output row maps through inverse Mercator.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import shutil
import tempfile
import urllib.request
import zipfile

from PIL import Image, ImageChops

Image.MAX_IMAGE_PIXELS = None
ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'assets/maps/styles/relief'
TILES = DEST / 'tiles'
SOURCE_URL = 'https://naciscdn.org/naturalearth/10m/raster/NE1_HR_LC_SR_W_DR.zip'
SOURCE_PAGE = 'https://www.naturalearthdata.com/downloads/10m-raster-data/10m-natural-earth-1/'
LICENSE_URL = 'https://www.naturalearthdata.com/about/terms-of-use/'
SOURCE_SHA = '8841d08155415f0556462846dcb845a4ccb8f12390b0e0ba36ffde55efadeb56'
MEMBER = 'NE1_HR_LC_SR_W_DR.tif'
SOURCE_SIZE = (21600, 10800)  # 1/60 degree per pixel
ZOOMS = range(2, 7)  # z6 ≈ native source resolution; the app upscales above it
QUALITY = 80
LIGHTEN = 0.12  # blend towards white so borders and answer colours stay legible
# west, south, east, north in degrees WGS84. These match CountryMap._bounds.
REGIONS = {
    'europe': (-32.0, 34.0, 65.0, 72.0),
    'africa': (-26.0, -36.0, 65.0, 38.0),
    'asia': (20.0, -12.0, 180.0, 82.0),
    'northAmerica': (-170.0, 5.0, -50.0, 84.0),
    'southAmerica': (-95.0, -57.0, -30.0, 15.0),
    # In coordinates shifted by 180° (build_map.shift_lon), like its geometry.
    'oceania': (-70.0, -50.0, 30.0, 22.0),
}
SHIFT = {'oceania': 180}


def tile_set(region):
    return 'oceania' if region in SHIFT else 'world'


# A land and a water control point per region, checked in its z4 tile.
CONTROL_POINTS = {
    'europe': [('land', 19.0, 52.0), ('water', -20.0, 50.0), ('land', 10.0, 46.0)],
    'africa': [('land', 20.0, 0.0), ('water', -20.0, 0.0), ('land', 47.0, -20.0)],
    'asia': [('land', 85.0, 28.0), ('water', 140.0, 30.0), ('land', 53.0, 33.0)],
    'northAmerica': [('land', -100.0, 40.0), ('water', -140.0, 30.0), ('land', -75.0, 45.0)],
    'southAmerica': [('land', -60.0, -10.0), ('water', -40.0, -30.0), ('land', -65.0, -25.0)],
    # Shifted: Australia 134°E → -46, Tasman Sea 160°E → -20, New Zealand 175.5°E → -4.5.
    'oceania': [('land', -46.0, -25.0), ('water', -20.0, -35.0), ('land', -4.5, -39.5)],
}


def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def tile_x(lon, z):
    return (lon + 180.0) / 360.0 * 2 ** z


def tile_y(lat, z):
    return (1 - math.asinh(math.tan(math.radians(lat))) / math.pi) / 2 * 2 ** z


def tile_range(bounds, z):
    """Tiles touching the window plus a one-tile margin (no missing edge tiles)."""
    west, south, east, north = bounds
    last = 2 ** z - 1
    xs = range(max(0, int(tile_x(west, z)) - 1), min(last, int(tile_x(east, z))) + 2)
    ys = range(max(0, int(tile_y(north, z)) - 1), min(last, int(tile_y(south, z))) + 2)
    return [(x, y) for x in xs if x <= last for y in ys if y <= last]


def wanted_tiles():
    tiles = {}
    for region, bounds in REGIONS.items():
        for z in ZOOMS:
            for x, y in tile_range(bounds, z):
                tiles[(tile_set(region), z, x, y)] = True
    return sorted(tiles)


def name(key):
    return '{}_{}_{}_{}.webp'.format(*key)


def render(level, z, x, y):
    width, height = level.size
    lat = lambda row: math.degrees(math.atan(math.sinh(math.pi * (1 - 2 * row / 2 ** z))))
    left = x / 2 ** z * width
    right = (x + 1) / 2 ** z * width
    rows = []
    for r in range(256):
        top = (90 - lat(y + r / 256)) / 180 * height
        bottom = (90 - lat(y + (r + 1) / 256)) / 180 * height
        rows.append(((0, r, 256, r + 1), (left, top, left, bottom, right, bottom, right, top)))
    tile = level.transform((256, 256), Image.Transform.MESH, rows, Image.Resampling.BILINEAR)
    return Image.blend(tile, Image.new('RGB', tile.size, (255, 255, 255)), LIGHTEN)


def build(archive):
    assert digest(archive) == SOURCE_SHA, 'Natural Earth source SHA-256 mismatch'
    with tempfile.TemporaryDirectory(prefix='geokuna-relief-') as temp:
        raster_path = Path(temp) / 'source.tif'
        with zipfile.ZipFile(archive) as zf, zf.open(MEMBER) as src, raster_path.open('wb') as dst:
            shutil.copyfileobj(src, dst)
        with Image.open(raster_path) as source:
            assert source.size == SOURCE_SIZE and source.mode == 'RGB'
            source.load()
            if TILES.exists():
                shutil.rmtree(TILES)
            TILES.mkdir(parents=True)
            for old in DEST.glob('*.webp'):
                old.unlink()
            wanted = wanted_tiles()
            for set_ in ('world', 'oceania'):
                base = ImageChops.offset(source, -180 * 60, 0) if set_ == 'oceania' else source
                for z in ZOOMS:
                    # Downsample once per zoom so low zooms are not aliased.
                    size = (256 * 2 ** z, 128 * 2 ** z)
                    level = base.resize(size, Image.Resampling.LANCZOS) if size[0] < base.width else base
                    keys = [k for k in wanted if k[0] == set_ and k[1] == z]
                    print(f'Rendering {set_} z{z}: {len(keys)} tiles', flush=True)
                    for key in keys:
                        render(level, *key[1:]).save(TILES / name(key), format='WEBP', quality=QUALITY, method=6)
    manifest = {
        'version': 'natural-earth-relief-0.3.0',
        'source': {'name': 'Natural Earth I with Shaded Relief, Water, and Drainages 1:10m',
                   'version': '2.0.0', 'url': SOURCE_URL, 'page': SOURCE_PAGE,
                   'sha256': SOURCE_SHA, 'license': 'public-domain',
                   'license_url': LICENSE_URL, 'verified_at': '2026-11-16'},
        'projection': 'EPSG:3857',
        'parameters': {'tile_size': 256, 'zooms': [ZOOMS.start, ZOOMS.stop - 1],
                       'resampling': 'lanczos per zoom, bilinear inverse-mercator rows',
                       'format': 'webp', 'quality': QUALITY, 'lighten': LIGHTEN,
                       'pillow_version': Image.__version__},
        'regions': {r: {'tile_set': tile_set(r), 'bounds_wsen': list(b)} for r, b in REGIONS.items()},
        'tiles_sha256': tiles_digest(),
    }
    (DEST / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    check()


def tiles_digest():
    h = hashlib.sha256()
    for key in wanted_tiles():
        h.update(name(key).encode() + b'\0' + digest(TILES / name(key)).encode() + b'\n')
    return h.hexdigest()


def check():
    manifest = json.loads((DEST / 'manifest.json').read_text())
    assert manifest['source']['url'] == SOURCE_URL
    assert manifest['source']['sha256'] == SOURCE_SHA
    assert manifest['source']['license'] == 'public-domain'
    assert manifest['projection'] == 'EPSG:3857'
    assert manifest['parameters']['zooms'] == [ZOOMS.start, ZOOMS.stop - 1]
    assert manifest['regions'] == {r: {'tile_set': tile_set(r), 'bounds_wsen': list(b)}
                                   for r, b in REGIONS.items()}
    wanted = {name(k) for k in wanted_tiles()}
    actual = {p.name for p in TILES.iterdir()}
    assert actual == wanted, f'Unexpected {sorted(actual - wanted)[:3]} / missing {sorted(wanted - actual)[:3]}'
    assert not list(DEST.glob('*.webp')), 'Old single-image overlays left behind'
    assert manifest['tiles_sha256'] == tiles_digest(), 'Tile checksum mismatch'
    for region, points in CONTROL_POINTS.items():
        for kind, lon, lat in points:
            fx, fy = tile_x(lon, 4), tile_y(lat, 4)
            with Image.open(TILES / name((tile_set(region), 4, int(fx), int(fy)))) as im:
                assert im.size == (256, 256)
                r, g, b = im.convert('RGB').getpixel((int(fx % 1 * 256), int(fy % 1 * 256)))
                water = b > r + 25 and b > g  # Natural Earth water is blue; land is not
                assert water == (kind == 'water'), (region, lon, lat, (r, g, b))
    total = sum(p.stat().st_size for p in TILES.iterdir())
    print(f'OK: {len(wanted)} offline relief tiles (z{ZOOMS.start}–{ZOOMS.stop - 1}, '
          f'{len(REGIONS)} regions), control points, checksums; {total:,} bytes')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--check', action='store_true', help='Validate existing output offline')
    mode.add_argument('--build', action='store_true', help='Regenerate from pinned source')
    parser.add_argument('--source', type=Path, help='Existing pinned Natural Earth source ZIP')
    args = parser.parse_args()
    if args.check:
        check()
    elif args.source:
        build(args.source)
    else:
        with tempfile.TemporaryDirectory(prefix='geokuna-relief-download-') as temp:
            archive = Path(temp) / 'source.zip'
            print('Downloading pinned Natural Earth source…', flush=True)
            with urllib.request.urlopen(SOURCE_URL, timeout=600) as src, archive.open('wb') as dst:
                shutil.copyfileobj(src, dst)
            build(archive)


if __name__ == '__main__':
    main()
