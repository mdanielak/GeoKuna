# Afryka — paczki 0.1.0

Paczka obejmuje 54 państwa afrykańskie członkowskie ONZ. Nie są osobnymi
pytaniami terytoria zależne ani Sahara Zachodnia. Lista i stabilne identyfikatory
znajdują się w `tools/data_pipeline/africa_curated.json`. Nazwy polskie oraz
stolice sprawdzono z [wykazem KSNG 2025 z aktualizacją 2026](https://www.gov.pl/attachment/1cde0699-e88f-4401-bca5-c9909d0fe526),
przypiętym SHA-256 `4645f3f84b46920b7e9bb480a265f70a52da5d429977eb650709d84dfabd08eb`.
Każdy fakt ma stronę pliku PDF, status oraz datę weryfikacji 2026-11-13.

Gwinea Równikowa: Ciudad de la Paz jest stolicą od stycznia 2026; Malabo jest
poprzednią stolicą. Zmianę potwierdza także [dekret rządowy](https://www.guineaecuatorialpress.com/index.php/noticias/decreto_ley_por_el_que_se_declara_la_ciudad_de_la_paz_djibloho_capital_de_la_republica_de_guinea_ecuatorial).
Dla Południowej Afryki pytamy o siedzibę władzy wykonawczej w Pretorii; dla
Eswatini o siedzibę administracji Mbabane. Pytania o Benin i Wybrzeże Kości
Słoniowej dotyczą oficjalnych stolic Porto-Novo i Jamusukro; wyjaśnienia
wskazują odpowiednio Kotonu i Abidżan jako siedziby władz/rządu.

## Geometria i polityka granic

Źródłem jest [Natural Earth 1:50m v5.1.2](https://github.com/nvkelso/natural-earth-vector/tree/v5.1.2/geojson)
o SHA-256 `3e458fc036ad0a66411f2c1e6cac49c5d7bfb81cb1123bc513b22511a2b7fdeb`.
Katalog zawiera wszystkie 54 ID. Znaczniki służą łatwiejszemu dotknięciu pięciu
małych państw wyspiarskich; każde ma też oryginalną geometrię i punkt wewnątrz
niej. Egipt obejmuje Synaj; Somalia obejmuje także Somaliland, który w źródle
Natural Earth stanowi osobny poligon.

Natural Earth stosuje mapowanie de facto. Jego poligon Maroka obejmuje część
Sahary Zachodniej, która jest terytorium spornym. Aby nie zaliczyć tego terenu
jako poprawnego wskazania Maroka, quiz przycina poligon Maroka do obszaru na
północ od 27°40′N. To jawne, uproszczone przybliżenie edukacyjne, a nie
rozstrzygnięcie ani mapa prawnych granic. Pozostała geometria Sahary Zachodniej
nie jest w paczce osobnym celem. Por. [polityka Natural Earth](https://www.naturalearthdata.com/about/disputed-boundaries-policy/)
i [materiały MTS](https://icj-web.leman.un-icc.cloud/sites/default/files/case-related/61/9470.pdf).

## Flagi, aliasy i weryfikacja

Źródłowe SVG pochodzą z repozytorium [country-flags](https://github.com/hampusborgos/country-flags/tree/c09927e63705529bbf59ca6684cd9b23225dddad),
którego README deklaruje domenę publiczną. PNG mają szerokość 500 px i oryginalne
proporcje. Angielskie aliasy krajów pochodzą z Natural Earth; angielskie nazwy
stolic tylko z przypiętego [Natural Earth populated places 1:50m](https://github.com/nvkelso/natural-earth-vector/blob/v5.1.2/geojson/ne_50m_populated_places.geojson)
(SHA-256 `da4662b7bbfeb897d02f228c5839131dce27acff5717630f91ccff4f67828ee7`),
przy zgodności polskiej nazwy i identyfikatora państwa. Starsze dane źródła
nie nadpisują aktualnej stolicy Gwinei Równikowej. Wszystkie grafiki i pytania
są lokalne; odczyt w quizie nie wymaga sieci.

```bash
python3 tools/data_pipeline/build_africa.py --check
python3 tools/data_pipeline/build_africa.py --build --pdf /ścieżka/KSNG-2026.pdf
```

`--check` działa offline: pokrycie 54 ID, centra w poligonach, geometrię,
wybrane punkty polityki, proporcje i sumy źródeł/grafik. `--build` wymaga
przypiętego PDF, `pdftotext`, Pythona/Pillow, systemowego librsvg/Cairo i sieci
lub parametrów `--source`/`--places` do odpowiednich pobranych GeoJSON. Build
sprawdza SHA PDF i relację nazwa państwa → stolica → strona w źródle. Manifest
przechowuje sumy wyników i wersje rendererów. Przyszłe zmiany źródeł wymagają
ponownej kontroli faktów, granic i wersjonowania paczki.
