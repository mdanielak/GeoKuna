#!/usr/bin/env python3
"""Reproducible Natural Earth subset; --check uses only bundled files."""
import argparse
import hashlib
import json
from pathlib import Path
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
URL = ('https://raw.githubusercontent.com/nvkelso/natural-earth-vector/'
       'v5.1.2/geojson/ne_50m_admin_0_countries.geojson')
SHA256 = '3e458fc036ad0a66411f2c1e6cac49c5d7bfb81cb1123bc513b22511a2b7fdeb'
# Educational scope: 44 UN-Europe states + Kosovo + Cyprus and Turkey (shared with Asia).
# Kazakhstan and the South Caucasus are Asia-only quiz targets (context land here).
COUNTRIES = [
    ('ALB', 'Albania'), ('AND', 'Andora'), ('AUT', 'Austria'),
    ('BEL', 'Belgia'), ('BLR', 'Białoruś'),
    ('BIH', 'Bośnia i Hercegowina'), ('BGR', 'Bułgaria'), ('HRV', 'Chorwacja'),
    ('CYP', 'Cypr'), ('MNE', 'Czarnogóra'), ('CZE', 'Czechy'), ('DNK', 'Dania'),
    ('EST', 'Estonia'), ('FIN', 'Finlandia'), ('FRA', 'Francja'), ('GRC', 'Grecja'),
    ('ESP', 'Hiszpania'), ('NLD', 'Holandia'), ('IRL', 'Irlandia'),
    ('ISL', 'Islandia'), ('KOS', 'Kosowo'), ('LIE', 'Liechtenstein'),
    ('LTU', 'Litwa'), ('LUX', 'Luksemburg'), ('LVA', 'Łotwa'), ('MKD', 'Macedonia Północna'),
    ('MLT', 'Malta'), ('MDA', 'Mołdawia'), ('MCO', 'Monako'), ('DEU', 'Niemcy'),
    ('NOR', 'Norwegia'), ('POL', 'Polska'), ('PRT', 'Portugalia'), ('RUS', 'Rosja'),
    ('ROU', 'Rumunia'), ('SMR', 'San Marino'), ('SRB', 'Serbia'), ('SVK', 'Słowacja'),
    ('SVN', 'Słowenia'), ('CHE', 'Szwajcaria'), ('SWE', 'Szwecja'), ('TUR', 'Turcja'),
    ('UKR', 'Ukraina'), ('VAT', 'Watykan'), ('HUN', 'Węgry'),
    ('GBR', 'Wielka Brytania'), ('ITA', 'Włochy'),
]
PLURAL_IDS = {'CZE', 'DEU', 'HUN', 'ITA'}
SMALL_IDS = {'AND', 'LIE', 'LUX', 'MLT', 'MCO', 'SMR', 'VAT'}
# Rendering window, NOT a claimed border between Europe and Asia.
WINDOW = (-32, 34, 65, 72)


def polygons(feature):
    geom = feature['geometry']
    return [geom['coordinates']] if geom['type'] == 'Polygon' else geom['coordinates']


def shift_lon(lon, shift):
    """Longitude moved east by `shift` degrees and wrapped to [-180, 180).

    Oceania straddles the 180° meridian; shifted by 180° it becomes one
    continuous map. Mercator x is linear in longitude, so shapes are unchanged."""
    return ((lon + shift + 180) % 360) - 180 if shift else lon


def shift_polygons(polygons, shift):
    """Shifted polygons; rings that would wrap across the new seam (i.e. cross
    the 0° meridian before shifting) are dropped — they lie far outside."""
    if not shift:
        return polygons
    out = []
    for polygon in polygons:
        rings = [[[round(shift_lon(x, shift), 6), y] for x, y in ring] for ring in polygon]
        if any(abs(a[0] - b[0]) > 180 for ring in rings for a, b in zip(ring, ring[1:])):
            continue
        out.append(rings)
    return out


def clip_ring(ring):
    """Sutherland-Hodgman clipping to the rectangular rendering window."""
    points = ring[:-1]
    west, south, east, north = WINDOW
    for axis, bound, sign in [(0, west, 1), (0, east, -1), (1, south, 1), (1, north, -1)]:
        output = []
        if not points:
            break
        previous = points[-1]
        for current in points:
            previous_inside = sign * (previous[axis] - bound) >= 0
            current_inside = sign * (current[axis] - bound) >= 0
            if previous_inside != current_inside:
                ratio = (bound - previous[axis]) / (current[axis] - previous[axis])
                crossing = [previous[i] + ratio * (current[i] - previous[i]) for i in (0, 1)]
                crossing[axis] = bound
                output.append([round(v, 6) for v in crossing])
            if current_inside:
                output.append(current)
            previous = current
        points = output
    unique = []
    for point in points:
        if not unique or point != unique[-1]:
            unique.append(point)
    if len(unique) > 1 and unique[0] == unique[-1]:
        unique.pop()
    return unique + [unique[0]] if len(unique) >= 3 else []


def contains_ring(point, ring):
    x, y = point
    inside = False
    for (ax, ay), (bx, by) in zip(ring, ring[1:]):
        if (ay > y) != (by > y) and x < (bx - ax) * (y - ay) / (by - ay) + ax:
            inside = not inside
    return inside


def contains_country(feature, point):
    return any(contains_ring(point, poly[0]) and not any(
        contains_ring(point, hole) for hole in poly[1:]) for poly in polygons(feature))



def encoded(value):
    return (json.dumps(value, ensure_ascii=False, separators=(',', ':')) + '\n').encode()


def check():
    content = json.loads((ROOT / 'assets/content/countries.json').read_text())
    geo = json.loads((ROOT / 'assets/maps/europe.geojson').read_text())
    manifest = json.loads((ROOT / 'assets/content/manifest.json').read_text())
    expected = {row[0] for row in COUNTRIES}
    for rows in (content['countries'], geo['features']):
        ids = [row['id'] for row in rows]
        assert len(ids) == len(set(ids)) == len(COUNTRIES), 'Duplicate or missing ID'
        assert set(ids) == expected, 'Unexpected country IDs'
    assert content['source'] == URL
    for feature in geo['features']:
        geom = feature['geometry']
        assert geom['type'] == 'MultiPolygon'
        assert geom['coordinates']
        for polygon in geom['coordinates']:
            assert polygon
            for ring in polygon:
                assert len(ring) >= 4 and ring[0] == ring[-1], 'Unclosed ring'
                for lon, lat in ring:
                    assert WINDOW[0] <= lon <= WINDOW[2] and WINDOW[1] <= lat <= WINDOW[3]
    names = dict(COUNTRIES)
    for country in content['countries']:
        assert country['name'] == names[country['id']]
        assert isinstance(country['plural'], bool)
        assert country['plural'] == (country['id'] in PLURAL_IDS)
        assert country['small'] == (country['id'] in SMALL_IDS)
        feature = next(f for f in geo['features'] if f['id'] == country['id'])
        assert contains_country(feature, (country['longitude'], country['latitude'])), country['id']
    ukraine = next(f for f in geo['features'] if f['id'] == 'UKR')
    russia = next(f for f in geo['features'] if f['id'] == 'RUS')
    assert contains_country(ukraine, (34.1, 44.95)), 'Crimea must select Ukraine'
    assert not contains_country(russia, (34.1, 44.95)), 'Crimea cannot select Russia'
    cyprus = next(f for f in geo['features'] if f['id'] == 'CYP')
    assert contains_country(cyprus, (33.9, 35.3)), 'Northern Cyprus must select Cyprus'
    for code, point in [('RUS', (20.5, 54.7)), ('FIN', (19.94, 60.1))]:
        feature = next(f for f in geo['features'] if f['id'] == code)
        assert contains_country(feature, point), (code, point)
    for path, digest in manifest['files'].items():
        assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == digest, path
    assert manifest['source_sha256'] == SHA256
    print(f'OK: {len(COUNTRIES)} countries, grammar, geometry, policy control points, SHA-256 checksums')


def build(source):
    data = Path(source).read_bytes() if source else urllib.request.urlopen(URL).read()
    assert hashlib.sha256(data).hexdigest() == SHA256, 'Source checksum mismatch'
    original = json.loads(data)
    by_code = {f['properties']['ADM0_A3']: f for f in original['features']}
    # v5.1.2 represents Crimea as one separate Russian polygon. Reassign that
    # exact polygon without inventing a boundary; checksum pins the source.
    russian = polygons(by_code['RUS'])
    crimea = [p for p in russian if all(32 <= x <= 37 and 44 <= y <= 47 for x, y in p[0])]
    assert len(crimea) == 1, 'Review Crimea mapping after changing source'
    selected, countries = [], []
    for code, name in COUNTRIES:
        feature = by_code[code]
        source_polygons = list(polygons(feature))
        if code == 'RUS':
            source_polygons = [p for p in source_polygons if p not in crimea]
        if code == 'UKR':
            source_polygons += crimea
        if code == 'CYP':
            source_polygons += polygons(by_code['CYN'])
        if code == 'FIN':
            source_polygons += polygons(by_code['ALD'])
        clipped = []
        for polygon in source_polygons:
            outer = clip_ring(polygon[0])
            if outer:
                clipped.append([outer] + [ring for hole in polygon[1:] if (ring := clip_ring(hole))])
        selected.append({'type': 'Feature', 'id': code, 'properties': {'id': code},
                         'geometry': {'type': 'MultiPolygon', 'coordinates': clipped}})
        props = feature['properties']
        longitude, latitude = props['LABEL_X'], props['LABEL_Y']
        if code == 'VAT':
            ring = clipped[0][0][:-1]
            longitude = round(sum(p[0] for p in ring) / len(ring), 6)
            latitude = round(sum(p[1] for p in ring) / len(ring), 6)
        countries.append(dict(id=code, name=name, latitude=latitude, longitude=longitude,
                              small=code in SMALL_IDS, plural=code in PLURAL_IDS))
    outputs = {
        'assets/content/countries.json': {
            'version': 'europe-location-0.3.0', 'source': URL, 'license': 'Public domain',
            'countries': countries},
        'assets/maps/europe.geojson': {'type': 'FeatureCollection', 'features': selected},
    }
    manifest = {'source': URL, 'source_sha256': SHA256, 'files': {}}
    for path, value in outputs.items():
        target = ROOT / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(encoded(value))
        manifest['files'][path] = hashlib.sha256(target.read_bytes()).hexdigest()
    (ROOT / 'assets/content/manifest.json').write_bytes(encoded(manifest))
    check()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--source', help='Previously downloaded upstream GeoJSON')
    args = parser.parse_args()
    check() if args.check else build(args.source)
