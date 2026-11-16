#!/usr/bin/env python3
"""High-zoom relief tiles for the subdivision maps; --check works offline.

Above zoom 6 Natural Earth has no more detail. For Poland (z7–8) and the USA
(z7) each tile combines: Natural Earth 1:10m colours, a hillshade computed
from the ETOPO 2022 15″ elevation model (NOAA, public domain; sea floor not
shaded) and crisp Natural Earth 1:10m rivers and lakes drawn as vectors.
Tiles join the `world` set of build_relief.py (run that first: it rebuilds
the folder) and are listed in manifest_hd.json.

Usage: build_relief_hd.py (--check | --build --ne NE.zip --dem DIR --water DIR)
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import shutil
import tempfile
import zipfile

from PIL import Image, ImageChops, ImageDraw

import build_relief as base

Image.MAX_IMAGE_PIXELS = None
MANIFEST = base.DEST / 'manifest_hd.json'
ETOPO = 'https://www.ngdc.noaa.gov/mgg/global/relief/ETOPO2022/data/15s/15s_surface_elev_gtif/'
NE_GEOJSON = 'https://raw.githubusercontent.com/nvkelso/natural-earth-vector/v5.1.2/geojson/'
# Must match CountryMap._bounds (W, S, E, N) and maxNativeZoom per area.
REGIONS = {
    'poland': ((13.5, 48.6, 24.5, 55.3), (7, 8)),
    'usa': ((-128.0, 16.0, -64.0, 51.0), (7,)),
}
DEM_SHA = {
    'N60E000': 'd69dbf93dcf2f11fb008a57223da41092921ea2f81ef6eeb1807d50609586557',
    'N60E015': '70f4cc2bb28724db6616182f449ac33b649cc137539d6913a78b8128b4c4eb9c',
    'N60W135': 'e0eec4056fac1c612cd35fb729f91f535b6e8f50f017d7b9337b976086a8ccb9',
    'N60W120': '69dd0125ca26daa71b4a067cfb65d2042606b940f25fe715309cf02daf71e3ae',
    'N60W105': '91fef4481560ba09c6f83989aac53e4e50deedcb79066230f80cfb61b1b5bf3b',
    'N60W090': 'b2f8916e109f311616725fa00c44cb47eb70111705618382bfb31c03ddbc659a',
    'N60W075': '7d9e06e9d53d4421cad2074a50882d56630bf1c6d568246ea8d37d6e5e31d333',
    'N45W135': '4ff26df2ad67546a8c6d94e54c31f7080c80f87f1bf16f2f07e64624ec373432',
    'N45W120': '806d5dbc40838e1b89c6afb7836fd62c92c47485bfc9a3aa453c3efa05b01a43',
    'N45W105': 'dd4f28c910c29c296f6078bd514c630efff2f469a9812e741d439b9552d39364',
    'N45W090': '7132212ec84a2c0382802940622ea383fece86f5808e56a9d641100bac9319fb',
    'N45W075': '34b0423dea21ae03073459c9012378b597093c0ce83ddcf242840e45dba86384',
    'N30W135': '0c8426a7ad059649277b4aadfbb4dc8b6897044152fec9682bbf7e31f7d39234',
    'N30W120': 'a721d683f987ea7c210138a33523983c38c526a9abbfbe34ad332a5e15222a58',
    'N30W105': '0f56a422be03cfb55b3629c72f373a6d2da858f1e3a4954afe7d17cfa298fff7',
    'N30W090': '7dec8b97564d9cb940c864843f87b7ec364987a6bf9b0315cf575ad8f55c5925',
    'N30W075': 'c259b483cbb01be468395046784da8f7968320175c53006d9661b2bd4d79e7f5',
}
WATER = ['ne_10m_rivers_lake_centerlines', 'ne_10m_rivers_europe', 'ne_10m_rivers_north_america',
         'ne_10m_lakes', 'ne_10m_lakes_europe', 'ne_10m_lakes_north_america']
WATER_RGB = (106, 160, 205)
EXAGGERATION = 2.5  # vertical, so lowland relief shows at all
STRENGTH = .7       # how far the hillshade moves colours from flat ground
VERIFIED = '2026-11-16'


def hd_tiles():
    keys = set()
    for bounds, zooms in REGIONS.values():
        west, south, east, north = bounds
        for z in zooms:
            for x in range(int(base.tile_x(west, z)), int(base.tile_x(east, z)) + 1):
                for y in range(int(base.tile_y(north, z)), int(base.tile_y(south, z)) + 1):
                    keys.add(('world', z, x, y))
    return sorted(keys)


def dem_names(bounds):
    west, south, east, north = bounds
    names = []
    for top in range(15 * math.ceil(north / 15), int(south // 15) * 15, -15):
        for left in range(int(west // 15) * 15, int(math.ceil(east / 15)) * 15, 15):
            ns = f"{'N' if top >= 0 else 'S'}{abs(top):02d}"
            ew = f"{'E' if left >= 0 else 'W'}{abs(left):03d}"
            names.append(ns + ew)
    return names


def hillshade(dem_dir, bounds, step):
    """Hillshade (L, 0–255, 0 = no data) on a lon/lat grid at 240/step px per degree."""
    west, south, east, north = bounds
    ppd = 240 // step
    w, h = round((east - west) * ppd), round((north - south) * ppd)
    elev = Image.new('F', (w, h), float('nan'))
    for name in dem_names(bounds):
        path = dem_dir / f'ETOPO_2022_v1_15s_{name}_surface.tif'
        if not path.exists():
            continue  # outside every tile we render with relief (far ocean)
        lat0 = int(name[1:3]) * (1 if name[0] == 'N' else -1)
        lon0 = int(name[4:7]) * (1 if name[3] == 'E' else -1)
        with Image.open(path) as tile:
            box = (max(0, round((west - lon0) * 240)), max(0, round((lat0 - north) * 240)),
                   min(3600, round((east - lon0) * 240)), min(3600, round((lat0 - south) * 240)))
            if box[0] >= box[2] or box[1] >= box[3]:
                continue
            part = tile.crop(box)
            if step > 1:
                part = part.resize((part.width // step, part.height // step), Image.Resampling.BOX)
            elev.paste(part, (round((lon0 + box[0] / 240 - west) * ppd), round((north - lat0 + box[1] / 240) * ppd)))
    px = elev.load()
    shade = Image.new('L', (w, h), 0)
    sp = shade.load()
    az, alt = math.radians(315), math.radians(45)
    sin_alt, cos_alt = math.sin(alt), math.cos(alt)
    for y in range(1, h - 1):
        lat = math.radians(north - y / ppd)
        dx = 111320 * math.cos(lat) / ppd / EXAGGERATION
        dy = 111320 / ppd / EXAGGERATION
        for x in range(1, w - 1):
            a, b, c = px[x - 1, y - 1], px[x, y - 1], px[x + 1, y - 1]
            d, f = px[x - 1, y], px[x + 1, y]
            g, i, j = px[x - 1, y + 1], px[x, y + 1], px[x + 1, y + 1]
            if a != a or c != c or g != g or j != j or b != b or i != i:
                continue  # missing elevation stays 0 = neutral
            gx = ((c + 2 * f + j) - (a + 2 * d + g)) / (8 * dx)
            gy = ((g + 2 * i + j) - (a + 2 * b + c)) / (8 * dy)
            slope = math.atan(math.hypot(gx, gy))
            aspect = math.atan2(gy, -gx)
            v = sin_alt * math.cos(slope) + cos_alt * math.sin(slope) * math.cos(az - aspect)
            sp[x, y] = max(1, min(255, int(255 * v)))
    return shade


def sample(image, bounds, z, x, y, resample):
    """Equirectangular image with geographic bounds → one Web Mercator tile."""
    west, south, east, north = bounds
    w, h = image.size
    lon = lambda col: col / 2 ** z * 360 - 180
    lat = lambda row: math.degrees(math.atan(math.sinh(math.pi * (1 - 2 * row / 2 ** z))))
    left = (lon(x) - west) / (east - west) * w
    right = (lon(x + 1) - west) / (east - west) * w
    rows = []
    for r in range(256):
        top = (north - lat(y + r / 256)) / (north - south) * h
        bottom = (north - lat(y + (r + 1) / 256)) / (north - south) * h
        rows.append(((0, r, 256, r + 1), (left, top, left, bottom, right, bottom, right, top)))
    return image.transform((256, 256), Image.Transform.MESH, rows, resample)


def water_features(water_dir):
    lines, polygons = [], []
    for name in WATER:
        for f in json.loads((water_dir / f'{name}.geojson').read_text())['features']:
            g = f['geometry']
            if not g:
                continue
            if 'lakes' in name:
                for poly in (g['coordinates'] if g['type'] == 'MultiPolygon' else [g['coordinates']]):
                    polygons.append(poly[0])
            else:
                min_zoom = f['properties'].get('min_zoom') or 9
                for line in (g['coordinates'] if g['type'] == 'MultiLineString' else [g['coordinates']]):
                    lines.append((min_zoom, line))
    return lines, polygons


def draw_water(tile, z, x, y, lines, polygons):
    k = 2  # supersampled, then reduced: anti-aliased lines
    layer = Image.new('RGBA', (256 * k, 256 * k), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    def project(point):
        px = (base.tile_x(point[0], z) - x) * 256 * k
        py = (base.tile_y(point[1], z) - y) * 256 * k
        return px, py
    lon_w, lon_e = x / 2 ** z * 360 - 180, (x + 1) / 2 ** z * 360 - 180
    lat_n = math.degrees(math.atan(math.sinh(math.pi * (1 - 2 * y / 2 ** z))))
    lat_s = math.degrees(math.atan(math.sinh(math.pi * (1 - 2 * (y + 1) / 2 ** z))))
    pad = (lon_e - lon_w) * .05
    def near(points):
        xs = [p[0] for p in points]; ys = [p[1] for p in points]
        return max(xs) > lon_w - pad and min(xs) < lon_e + pad and max(ys) > lat_s - pad and min(ys) < lat_n + pad
    fill = WATER_RGB + (255,)
    for ring in polygons:
        if near(ring):
            draw.polygon([project(p) for p in ring], fill=fill)
    for min_zoom, line in lines:
        if min_zoom <= z and near(line):
            width = (3.0 if min_zoom <= 4 else 2.2 if min_zoom <= 6 else 1.5) * (1.25 if z >= 8 else 1)
            draw.line([project(p) for p in line], fill=fill, width=round(width * k), joint='curve')
    layer = layer.resize((256, 256), Image.Resampling.LANCZOS)
    tile.paste(layer, (0, 0), layer)
    return tile


def build(ne_zip, dem_dir, water_dir):
    assert base.digest(ne_zip) == base.SOURCE_SHA
    for name, digest in DEM_SHA.items():
        assert base.digest(dem_dir / f'ETOPO_2022_v1_15s_{name}_surface.tif') == digest, name
    lines, polygons = water_features(water_dir)
    with tempfile.TemporaryDirectory(prefix='geokuna-relief-hd-') as temp:
        raster = Path(temp) / 'ne.tif'
        with zipfile.ZipFile(ne_zip) as zf, zf.open(base.MEMBER) as src, raster.open('wb') as dst:
            shutil.copyfileobj(src, dst)
        with Image.open(raster) as ne:
            ne.load()
            for region, (bounds, zooms) in REGIONS.items():
                west, south, east, north = bounds
                margin = (west - 1.5, south - 1.5, east + 1.5, north + 1.5)
                step = 1 if max(zooms) >= 8 else 2
                print(f'Hillshade {region} at {240 // step} px/°…', flush=True)
                shade = hillshade(dem_dir, margin, step)
                for z in zooms:
                    keys = [k for k in hd_tiles() if k[1] == z and
                            base.tile_x(west, z) - 1 <= k[2] <= base.tile_x(east, z) and
                            base.tile_y(north, z) - 1 <= k[3] <= base.tile_y(south, z)]
                    print(f'  z{z}: {len(keys)} tiles', flush=True)
                    for key in keys:
                        _, _, x, y = key
                        colour = base.render(ne, z, x, y)  # NE colours, lightened like z≤6
                        hs = sample(shade, margin, z, x, y, Image.Resampling.BICUBIC)
                        # Flat ground (~180) stays 1.0×; no data (0) and water stay neutral.
                        factor = hs.point([128] + [max(0, min(255, round(128 * (1 + STRENGTH * (v / 180 - 1)))))
                                                   for v in range(1, 256)])
                        r, g, b = colour.split()
                        water = ImageChops.subtract(b, r).point(lambda v: 255 if v > 25 else 0)
                        factor.paste(128, mask=water)
                        lit = ImageChops.multiply(colour, Image.merge('RGB', (factor,) * 3)).point(lambda v: min(255, v * 2))
                        draw_water(lit, z, x, y, lines, polygons).save(
                            base.TILES / base.name(key), format='WEBP', quality=base.QUALITY, method=6)
    manifest = {
        'version': 'relief-hd-0.1.0',
        'sources': {
            'natural_earth_raster': {'url': base.SOURCE_URL, 'sha256': base.SOURCE_SHA},
            'etopo_2022_15s': {'url': ETOPO, 'license': 'public-domain (NOAA NCEI)',
                               'sha256': {k: DEM_SHA[k] for k in sorted(DEM_SHA)}},
            'natural_earth_water': {'url': NE_GEOJSON, 'files': {n: base.digest(water_dir / f'{n}.geojson') for n in WATER}},
        },
        'parameters': {'exaggeration': EXAGGERATION, 'strength': STRENGTH, 'water_rgb': list(WATER_RGB),
                       'quality': base.QUALITY, 'pillow_version': Image.__version__},
        'regions': {r: {'bounds_wsen': list(b), 'zooms': list(z)} for r, (b, z) in REGIONS.items()},
        'verified_at': VERIFIED,
        'tiles_sha256': tiles_digest(),
    }
    MANIFEST.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    check()


def tiles_digest():
    h = hashlib.sha256()
    for key in hd_tiles():
        h.update(base.name(key).encode() + b'\0' + base.digest(base.TILES / base.name(key)).encode() + b'\n')
    return h.hexdigest()


def check():
    manifest = json.loads(MANIFEST.read_text())
    assert manifest['regions'] == {r: {'bounds_wsen': list(b), 'zooms': list(z)} for r, (b, z) in REGIONS.items()}
    assert manifest['sources']['natural_earth_raster']['sha256'] == base.SOURCE_SHA
    assert all(manifest['sources']['etopo_2022_15s']['sha256'][k] == v for k, v in DEM_SHA.items())
    missing = [base.name(k) for k in hd_tiles() if not (base.TILES / base.name(k)).exists()]
    assert not missing, missing[:3]
    assert manifest['tiles_sha256'] == tiles_digest(), 'HD tile checksum mismatch'
    size = sum((base.TILES / base.name(k)).stat().st_size for k in hd_tiles())
    print(f'OK: {len(hd_tiles())} high-zoom relief tiles (Poland z7–8, USA z7), checksums; {size:,} bytes')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--check', action='store_true')
    group.add_argument('--build', action='store_true')
    parser.add_argument('--ne', type=Path, help='Pinned NE1_HR_LC_SR_W_DR.zip')
    parser.add_argument('--dem', type=Path, help='Folder with ETOPO 2022 15″ surface GeoTIFF tiles')
    parser.add_argument('--water', type=Path, help='Folder with the Natural Earth 1:10m water GeoJSONs')
    args = parser.parse_args()
    if args.check:
        check()
    else:
        if not (args.ne and args.dem and args.water):
            parser.error('--build needs --ne, --dem and --water')
        build(args.ne, args.dem, args.water)
