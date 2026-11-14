#!/usr/bin/env python3
"""Create regional offline shaded-relief overlays; --check works without network.

The pinned Natural Earth TIFF is WGS84/equirectangular. The app's map uses a
single Web Mercator world. Each output pixel row is mapped through the inverse
Mercator projection to the source raster, preserving alignment with map vectors.
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

ROOT = Path(__file__).resolve().parents[2]
DEST = ROOT / 'assets/maps/styles/relief'
SOURCE_URL = 'https://naciscdn.org/naturalearth/50m/raster/NE1_50M_SR.zip'
SOURCE_PAGE = 'https://www.naturalearthdata.com/downloads/50m-raster-data/50m-natural-earth-1/'
LICENSE_URL = 'https://www.naturalearthdata.com/about/terms-of-use/'
SOURCE_SHA = 'ae930744c0cf3d10e73c292726b74c81a40490a75829f8299dec9069e5d0e934'
MEMBER = 'NE1_50M_SR/NE1_50M_SR.tif'
SOURCE_WIDTH = 10800  # 1/30 degree per pixel
MAX_WIDTH = 3072  # native source resolution, capped for package size
QUALITY = 90  # lossy WebP: full colour without palette banding
# west, south, east, north in degrees WGS84. These match CountryMap._bounds.
REGIONS = {
    'europe': (-32.0, 34.0, 65.0, 72.0),
    'africa': (-26.0, -36.0, 65.0, 38.0),
    'asia': (20.0, -12.0, 180.0, 82.0),
}
OCEAN = (218, 238, 244)
LAND_TINT = (220, 233, 201)
TINT_STRENGTH = 0.20
# A land and an ocean control point per region, inside the output bounds.
# These catch projection inversion and incorrect geographic extent. They do not
# define borders or replace the separately verified interactive geometries.
CONTROL_POINTS = {
    'europe': [('land', 19.0, 52.0), ('water', -20.0, 50.0), ('land', 10.0, 46.0)],
    'africa': [('land', 20.0, 0.0), ('water', -20.0, 0.0), ('land', 47.0, -20.0), ('water', 37.0, 23.0)],
    'asia': [('land', 85.0, 28.0), ('water', 140.0, 30.0), ('land', 53.0, 33.0)],
}


def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def mercator_y(latitude):
    return math.asinh(math.tan(math.radians(latitude)))


def dimensions(bounds):
    west, south, east, north = bounds
    width = min(MAX_WIDTH, round((east - west) / 360.0 * SOURCE_WIDTH))
    height = round(width * (mercator_y(north) - mercator_y(south)) /
                   math.radians(east - west))
    return width, height


def render(source, bounds):
    west, south, east, north = bounds
    width, height = dimensions(bounds)
    src_width, src_height = source.size
    left = (west + 180.0) / 360.0 * src_width
    right = (east + 180.0) / 360.0 * src_width
    north_y, south_y = mercator_y(north), mercator_y(south)
    # One output row per quadrilateral: nonlinear inverse Mercator interpolation
    # is exact at row boundaries, with less than one-pixel interpolation error.
    rows = []
    for y in range(height):
        def source_y(boundary):
            projected = north_y - (north_y - south_y) * boundary / height
            latitude = math.degrees(math.atan(math.sinh(projected)))
            return (90.0 - latitude) / 180.0 * src_height
        top, bottom = source_y(y), source_y(y + 1)
        rows.append(((0, y, width, y + 1),
                     (left, top, left, bottom, right, bottom, right, top)))
    raster = source.transform((width, height), Image.Transform.MESH, rows,
                              Image.Resampling.BILINEAR).convert('RGB')
    # Original ocean is exactly (251,251,251). Replace it before tinting land;
    # natural snow and coast pixels retain their source color and are not masked
    # by a broad luminance threshold. Polygons remain the interactive layer.
    channels = raster.split()
    distances = [ImageChops.difference(channel, Image.new('L', raster.size, 251))
                 for channel in channels]
    distance = ImageChops.lighter(ImageChops.lighter(distances[0], distances[1]), distances[2])
    water_mask = distance.point([255] + [0] * 255)
    pastel = Image.blend(raster, Image.new('RGB', raster.size, LAND_TINT), TINT_STRENGTH)
    pastel.paste(Image.new('RGB', raster.size, OCEAN), mask=water_mask)
    return pastel


def check():
    manifest_path = DEST / 'manifest.json'
    manifest = json.loads(manifest_path.read_text())
    assert manifest['source']['url'] == SOURCE_URL
    assert manifest['source']['sha256'] == SOURCE_SHA
    assert manifest['source']['license'] == 'public-domain'
    assert manifest['projection'] == 'EPSG:3857'
    assert manifest['parameters']['max_width'] == MAX_WIDTH
    assert manifest['parameters']['ocean_rgb'] == list(OCEAN)
    assert set(manifest['regions']) == set(REGIONS)
    total = 0
    for region, bounds in REGIONS.items():
        item = manifest['regions'][region]
        path = DEST / f'{region}.webp'
        assert item['asset_path'] == str(path.relative_to(ROOT))
        assert item['bounds_wsen'] == list(bounds)
        assert item['sha256'] == digest(path), region
        with Image.open(path) as im:
            assert im.format == 'WEBP' and im.size == dimensions(bounds), region
            assert [item['width'], item['height']] == list(im.size), region
            im.verify()
        with Image.open(path) as im:
            raster = im.convert('RGB')
            west, south, east, north = bounds
            for kind, lon, lat in CONTROL_POINTS[region]:
                x = int((lon - west) / (east - west) * raster.width)
                y = int((mercator_y(north) - mercator_y(lat)) /
                        (mercator_y(north) - mercator_y(south)) * raster.height)
                assert 0 <= x < raster.width and 0 <= y < raster.height
                pixel = raster.getpixel((x, y))
                distance = sum(abs(a - b) for a, b in zip(pixel, OCEAN))
                assert (distance < 12) if kind == 'water' else (distance > 12), (region, lon, lat, pixel)
        total += path.stat().st_size
    actual = {p.name for p in DEST.iterdir() if p.name != 'manifest.json'}
    assert actual == {f'{r}.webp' for r in REGIONS}, 'Unexpected or missing image'
    print(f'OK: 3 offline Mercator relief overlays, control points, hashes/bounds/dimensions; {total:,} bytes')


def build(archive):
    assert digest(archive) == SOURCE_SHA, 'Natural Earth source SHA-256 mismatch'
    DEST.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='geokuna-relief-') as temp:
        raster_path = Path(temp) / 'source.tif'
        with zipfile.ZipFile(archive) as zf, zf.open(MEMBER) as src, raster_path.open('wb') as dst:
            shutil.copyfileobj(src, dst)
        with Image.open(raster_path) as source:
            assert source.size == (10800, 5400) and source.mode == 'RGB'
            # Verify GeoTIFF scale/tie point instead of silently assuming a projection.
            scale = source.tag_v2.get(33550)
            tie = source.tag_v2.get(33922)
            assert scale and tie and abs(scale[0] - 1/30) < 1e-9 and abs(scale[1] - 1/30) < 1e-9
            assert abs(tie[3] + 180) < 1e-8 and abs(tie[4] - 90) < 1e-8
            regions = {}
            for region, bounds in REGIONS.items():
                print(f'Rendering {region}…', flush=True)
                path = DEST / f'{region}.webp'
                image = render(source, bounds)
                image.save(path, format='WEBP', quality=QUALITY, method=6)
                regions[region] = {
                    'asset_path': str(path.relative_to(ROOT)),
                    'bounds_wsen': list(bounds),
                    'width': image.width,
                    'height': image.height,
                    'sha256': digest(path),
                }
                image.close()
    manifest = {
        'version': 'natural-earth-relief-0.2.0',
        'source': {'name': 'Natural Earth I with Shaded Relief 1:50m',
                   'version': '3.2.0', 'url': SOURCE_URL, 'page': SOURCE_PAGE,
                   'sha256': SOURCE_SHA, 'license': 'public-domain',
                   'license_url': LICENSE_URL, 'verified_at': '2026-11-13'},
        'projection': 'EPSG:3857',
        'parameters': {'max_width': MAX_WIDTH, 'resampling': 'bilinear', 'rows': 'inverse-mercator',
                       'format': 'webp', 'quality': QUALITY, 'land_tint_rgb': list(LAND_TINT),
                       'land_tint_strength': TINT_STRENGTH, 'ocean_rgb': list(OCEAN),
                       'pillow_version': Image.__version__},
        'regions': regions,
    }
    (DEST / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    check()


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
            with urllib.request.urlopen(SOURCE_URL, timeout=120) as src, archive.open('wb') as dst:
                shutil.copyfileobj(src, dst)
            build(archive)


if __name__ == '__main__':
    main()
