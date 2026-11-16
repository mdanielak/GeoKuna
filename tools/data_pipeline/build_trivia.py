#!/usr/bin/env python3
"""Validate the source-backed, offline trivia packs: countries, flags, capitals."""
import argparse
import json
import re
from datetime import date
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[2]
CONTENT = ROOT / 'assets/content'
PACKS = {
    'country-trivia': CONTENT / 'country_trivia.json',
    'flag-trivia': CONTENT / 'flag_trivia.json',
    'capital-trivia': CONTENT / 'capital_trivia.json',
}


def validate(prefix, path, require_complete=True):
    data = json.loads(path.read_text(encoding='utf-8'))
    assert re.fullmatch(prefix + r'-\d+\.\d+\.\d+(?:-draft)?', data['version'])
    expected = set()
    folders = ['africa', 'asia', 'northAmerica', 'southAmerica', 'oceania', 'poland', 'usa']
    for path in ['countries.json'] + [f'{f}/countries.json' for f in folders]:
        expected.update(c['id'] for c in json.loads((CONTENT / path).read_text())['countries'])
    countries = data['countries']
    missing = expected - countries.keys()
    unexpected = countries.keys() - expected
    assert not unexpected, f'Unknown country IDs: {sorted(unexpected)}'
    seen_ids = set()
    for country, facts in countries.items():
        assert len(facts) == 3, f'{country}: expected exactly three facts'
        assert len({fact['text'] for fact in facts}) == 3, f'{country}: duplicate text'
        for fact in facts:
            assert re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)+', fact['id']), fact
            assert fact['id'] not in seen_ids, f"Duplicate fact ID: {fact['id']}"
            seen_ids.add(fact['id'])
            assert 20 <= len(fact['text']) <= 250, fact
            parsed = urlparse(fact['source_url'])
            assert parsed.scheme == 'https' and parsed.netloc, fact
            assert fact['source_title'].strip(), fact
            assert date.fromisoformat(fact['checked']) <= date.today(), fact
    if require_complete:
        assert not missing, f'Missing countries ({len(missing)}): {", ".join(sorted(missing))}'
        assert data['status'] == 'verified', 'A complete production package must be verified'
    print(f'OK {prefix}: {len(countries)}/{len(expected)} countries, {len(seen_ids)} facts, {len(missing)} missing')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true', help='validate all countries (default)')
    parser.add_argument('--allow-incomplete', action='store_true', help='validate a draft only')
    args = parser.parse_args()
    for prefix, path in PACKS.items():
        validate(prefix, path, not args.allow_incomplete)
