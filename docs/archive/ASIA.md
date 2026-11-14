# Azja — paczki 0.1.0

Zakres edukacyjny obejmuje 50 obiektów: 48 państw członkowskich ONZ z Rosją,
Cypr, Kaukaz i Kazachstan włącznie oraz Palestynę i Tajwan jako odrębne obszary
o szczególnym statusie opisane przez KSNG. Ujęcie obiektu w quizie nie oznacza
rozstrzygnięcia statusu. Dokładna lista i stabilne ID Natural Earth są w
`tools/data_pipeline/asia_curated.json`; ID krajów wspólnych z Europą pozostają
te same, żeby nie kopiować ani nie utracić ich postępów.

Nazwy i stolice: [wykaz KSNG z aktualizacją 2026](https://www.gov.pl/attachment/1cde0699-e88f-4401-bca5-c9909d0fe526),
SHA-256 `4645f3f84b46920b7e9bb480a265f70a52da5d429977eb650709d84dfabd08eb`.
Każdy fakt ma stronę PDF, status i datę kontroli 2026-11-13. Pytanie o Izrael
dotyczy siedziby władz w Jerozolimie, z wyjaśnieniem spornego statusu; pytanie
o Palestynę dotyczy tymczasowej siedziby władz w Ramallah. Tajpej jest siedzibą
władz Tajwanu. Sri Dźajawardanapura Kotte to oficjalna stolica Sri Lanki,
zaś Kolombo jest siedzibą rządu. Pytanie o Indonezję wskazuje zakres źródła
KSNG: Dżakarta; trwające przenoszenie stolicy do Nusantary wymaga ponownej
weryfikacji przed aktualizacją danych. [Sąd Konstytucyjny Indonezji](https://en.mkri.id/news/details/2026-10-29/Court_Declares_IKN_Law_Petition_Inadmissible)
potwierdzał w październiku 2026 r., że dekret przenoszący stolicę nie został
wydany. Sana jest konstytucyjną stolicą Jemenu.

## Geometria i flagi

Użyto [Natural Earth 1:50m v5.1.2](https://github.com/nvkelso/natural-earth-vector/tree/v5.1.2/geojson),
SHA-256 `3e458fc036ad0a66411f2c1e6cac49c5d7bfb81cb1123bc513b22511a2b7fdeb`.
Dla jednego świata Mercatora geometria jest przycięta do 20°E–180°E i 12°S–82°N;
obejmuje m.in. Japonię i archipelag Indonezji, ale pomija fragmenty Rosji poza
południkiem 180° oraz odległe obszary poza oknem. Cypr Północny połączono z
Cyprem, Hongkong i Makau z Chinami; Gaza i Zachodni Brzeg tworzą obiekt Palestyny.
Nie jest to mapa prawnych granic, a Natural Earth używa [polityki de facto](https://www.naturalearthdata.com/about/disputed-boundaries-policy/).

Flagi pochodzą z przypiętego [country-flags](https://github.com/hampusborgos/country-flags/tree/c09927e63705529bbf59ca6684cd9b23225dddad);
źródło deklaruje domenę publiczną. PNG mają szerokość 500 px i zachowują
proporcje, w tym nieprostokątną flagę Nepalu (500×610). Angielskie aliasy
państw i części stolic pochodzą z Natural Earth; dopasowanie stolicy wymaga
zgodnego państwa i polskiej nazwy z KSNG. Manifest podaje sumy plików. Dla
Afganistanu paczka stosuje wariant źródłowy czarno-czerwono-zielony;
przedstawienie symboli jest odrębne od aktualnej kontroli politycznej.

```bash
python3 tools/data_pipeline/build_asia.py --check
python3 tools/data_pipeline/build_asia.py --build --pdf /ścieżka/KSNG-2026.pdf
```

`--check` jest offline, sprawdza kompletność, centrum geometrii, punkty kontrolne,
proporcje flag i SHA wszystkich plików. `--build` dodatkowo weryfikuje przypięty
PDF, kraj i stronę stolicy oraz przypięte Natural Earth i wymaga `pdftotext`,
Python/Pillow, systemowych librsvg/Cairo i sieci albo pobranych wcześniej plików
`--source` i `--places`. Flagi i pytania po spakowaniu nie wymagają sieci.
