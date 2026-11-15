#!/usr/bin/env python3
"""App icons from the menu mascot (assets/mascot/kuna-globe.png); offline.

Android: legacy launcher PNGs plus an adaptive icon (mint background colour,
kuna foreground inside the 66 dp safe zone). Web: favicon, PWA icons and
maskable icons (kuna inside the 80% safe circle). --check verifies sizes.
"""
import argparse
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/mascot/kuna-globe.png'
BACKGROUND = (0xD6, 0xEE, 0xDC, 255)  # light mint, from the app's green seed
RES = ROOT / 'android/app/src/main/res'
DENSITIES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
WEB = {
    'web/favicon.png': (32, .86, True),
    'web/icons/Icon-192.png': (192, .80, True),
    'web/icons/Icon-512.png': (512, .80, True),
    'web/icons/Icon-maskable-192.png': (192, .62, True),
    'web/icons/Icon-maskable-512.png': (512, .62, True),
}
ADAPTIVE_XML = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
'''
COLOR_XML = '''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#D6EEDC</color>
</resources>
'''


def mascot():
    image = Image.open(SOURCE).convert('RGBA')
    return image.crop(image.getbbox())


def icon(size, scale, background):
    canvas = Image.new('RGBA', (size, size), BACKGROUND if background else (0, 0, 0, 0))
    kuna = mascot()
    box = int(size * scale)
    ratio = min(box / kuna.width, box / kuna.height)
    kuna = kuna.resize((max(1, round(kuna.width * ratio)), max(1, round(kuna.height * ratio))),
                       Image.LANCZOS)
    canvas.alpha_composite(kuna, ((size - kuna.width) // 2, (size - kuna.height) // 2))
    return canvas


def outputs():
    for density, factor in DENSITIES.items():
        folder = RES / f'mipmap-{density}'
        yield folder / 'ic_launcher.png', (round(48 * factor), .80, True)
        # 108 dp canvas; the kuna stays inside the 66 dp safe zone.
        yield folder / 'ic_launcher_foreground.png', (round(108 * factor), .58, False)
    for path, spec in WEB.items():
        yield ROOT / path, spec


def build():
    for path, (size, scale, background) in outputs():
        path.parent.mkdir(parents=True, exist_ok=True)
        icon(size, scale, background).save(path, optimize=True)
    (RES / 'mipmap-anydpi-v26').mkdir(exist_ok=True)
    (RES / 'mipmap-anydpi-v26/ic_launcher.xml').write_text(ADAPTIVE_XML)
    (RES / 'values/ic_launcher_background.xml').write_text(COLOR_XML)
    check()


def check():
    for path, (size, _, _) in outputs():
        assert Image.open(path).size == (size, size), path
    assert (RES / 'mipmap-anydpi-v26/ic_launcher.xml').read_text() == ADAPTIVE_XML
    print(f'OK: {len(list(outputs()))} icons from {SOURCE.name}, adaptive Android icon')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    check() if parser.parse_args().check else build()
