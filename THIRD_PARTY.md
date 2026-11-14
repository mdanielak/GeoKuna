# Dane i komponenty dołączone bezpośrednio

Natural Earth 1:50m v5.1.2 — geometria 51 państw w assets/maps.
Domena publiczna: https://www.naturalearthdata.com/about/terms-of-use/
Źródło i sumy: assets/content/manifest.json.

Web: `drift_worker.dart.js`, wydanie Drift 2.35.4, MIT.
Copyright (c) 2019 Simon Binder.
https://github.com/simolus3/drift/blob/drift-2.35.4/LICENSE
`sqlite3.wasm` z tego samego wydania; SQLite w domenie publicznej.
https://sqlite.org/copyright.html

SHA-256:

```text
e7451780e78c56ff864fe9317a0fbcd6aeb2e8de3beba7f5efd963202f7ec3d9  web/sqlite3.wasm
48c950cd8e3bc3cddb34816c860e228be8832bef07a297c27e9907c057ff8162  web/drift_worker.dart.js
```

## MIT (Drift)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Pozostałe zależności Dart/Flutter są wymienione w pubspec.lock, a ich licencje
dołączane przez Flutter do zbudowanej aplikacji.

FSRS: pakiet Dart `fsrs` 2.0.1, MIT, Open Spaced Repetition.
https://github.com/open-spaced-repetition/dart-fsrs

Flagi: hampusborgos/country-flags, commit c09927e63705529bbf59ca6684cd9b23225dddad.
Deklaracja public domain w przypiętym README; źródłowe SVG i manifest w repo.
Szczegóły: docs/CONTENT.md.

### Paczki Afryki i Azji

Lokalne flagi SVG i PNG korzystają z tego samego przypiętego źródła country-flags
oraz deklaracji domeny publicznej wskazanej wyżej. Geometria i angielskie nazwy
pochodzą z Natural Earth v5.1.2. Zakres, przycięcie geometrii, polityka obszarów
spornych oraz sumy źródeł: [Afryka](docs/CONTENT.md), [Azja](docs/CONTENT.md).

Warianty maskotki `assets/mascot/kuna-happy.png` i `kuna-sad.png` wygenerowano
wbudowanym imagegen na podstawie wybranej kuny, zachowując przezroczystość.
Prompty i ścieżki: `output/imagegen/kuna-emotions/PROMPTS.md`.
Kolejne cztery warianty emocji wybrano na podstawie plansz 2 i 2B; pliki
produkcyjne i pełne prompty: [katalog promptów](output/imagegen/kuna-production-2b/PROMPTS.md).

### Ciekawostki o krajach

Część faktów opracowano na podstawie historycznych profili CIA World Factbook,
opracowania rządu USA w domenie publicznej, dostępnych w archiwum
[factbook/factbook.json](https://github.com/factbook/factbook.json) (CC0),
commit `144d6977b2b01ac1cbd220de754c0a005616760b`.

Źródłem części krótkich polskich parafraz jest UNESCO World Heritage Centre,
[World Heritage List](https://whc.unesco.org/en/list/); oryginalne opisy
obiektów są oznaczone licencją [CC BY-SA IGO 3.0](https://creativecommons.org/licenses/by-sa/3.0/igo/).
Parafrazy i odsyłacze do konkretnych obiektów zawiera
`assets/content/country_trivia.json`. Wymienione źródła nie oznaczają wsparcia
ani zatwierdzenia aplikacji przez UNESCO. Dodatkowy fakt o soczewkach oparto na
National Technical Museum w Czechach. Adresy wszystkich źródeł są przy rekordach;
zakres, data sprawdzenia i ograniczenia: [CONTENT.md](docs/CONTENT.md).

### Rzeźba terenu offline

Natural Earth I with Shaded Relief 1:50m v3.2.0, dane w domenie publicznej:
https://www.naturalearthdata.com/downloads/50m-raster-data/50m-natural-earth-1/
https://www.naturalearthdata.com/about/terms-of-use/
Trzy regiony, projekcja, przypięty SHA i odtwarzanie: [style map](docs/CONTENT.md).
