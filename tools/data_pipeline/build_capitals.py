#!/usr/bin/env python3
"""Validate curated capital facts against the pinned KSNG PDF and bundle them."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
CURATED = ROOT / 'tools/data_pipeline/capitals_curated.json'
OUTPUT = ROOT / 'assets/content/capitals.json'
MANIFEST = ROOT / 'assets/content/capitals_manifest.json'


def validate(data):
    countries = json.loads((ROOT / 'assets/content/countries.json').read_text())['countries']
    facts = data['capitals']
    assert len(facts) == len({f['id'] for f in facts}) == len(countries)
    assert {f['country_id'] for f in facts} == {c['id'] for c in countries}
    names = set()
    for fact in facts:
        assert fact['id'] == 'capital:' + fact['country_id']
        assert fact['name'].strip() == fact['name'] and len(fact['name']) >= 3
        assert fact['name'].casefold() not in names, 'Ambiguous multiple-choice answer'
        names.add(fact['name'].casefold())
        assert fact['status'] == 'verified' and fact['verified_at']
        assert 18 <= fact['source_page'] <= 64
        assert len(fact['aliases']) == len(set(fact['aliases']))
        assert all(isinstance(a, str) and a.strip() for a in fact['aliases'])
    by_id = {f['country_id']: f for f in facts}
    assert by_id['POL']['name'] == 'Warszawa'
    assert by_id['TUR']['name'] == 'Ankara'
    assert by_id['NLD']['name'] == 'Amsterdam' and by_id['NLD']['prompt']
    assert by_id['CHE']['name'] == 'Berno' and by_id['CHE']['prompt']


def check():
    data = json.loads(OUTPUT.read_text())
    validate(data)
    assert data == json.loads(CURATED.read_text()), 'Curated and bundled facts differ'
    manifest = json.loads(MANIFEST.read_text())
    assert manifest['source_sha256'] == data['source']['sha256']
    for path, digest in manifest['files'].items():
        assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == digest, path
    print(f"OK: {len(data['capitals'])} verified capital facts, provenance, checksums")


def build(pdf):
    data = json.loads(CURATED.read_text())
    validate(data)
    assert hashlib.sha256(Path(pdf).read_bytes()).hexdigest() == data['source']['sha256']
    text = subprocess.check_output(['pdftotext', '-layout', str(pdf), '-']).decode()
    pages = text.split('\f')
    for fact in data['capitals']:
        page = pages[fact['source_page'] - 1]
        assert re.search(r'^stol\. ' + re.escape(fact['name']) + r'(?:,| ndm\.|;)', page, re.M), fact['id']
        for alias in fact['aliases']:
            assert alias in page, (fact['id'], alias)
    OUTPUT.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
    files = [OUTPUT, CURATED]
    manifest = {'source_sha256': data['source']['sha256'], 'files': {
        str(path.relative_to(ROOT)): hashlib.sha256(path.read_bytes()).hexdigest() for path in files}}
    MANIFEST.write_text(json.dumps(manifest, indent=2) + '\n')
    check()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--source', type=Path, help='Pinned KSNG 2025 PDF')
    args = parser.parse_args()
    if args.check:
        check()
    elif args.source:
        build(args.source)
    else:
        parser.error('Use --source PDF or --check')
