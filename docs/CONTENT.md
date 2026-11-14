# Treści, źródła i polityka

Wszystkie pytania, geometrie, flagi i ciekawostki są lokalnymi, wersjonowanymi
paczkami w `assets/`. Każdy fakt ma źródło, datę, status i wersję. AI nie jest
źródłem faktów i nie rozstrzyga odpowiedzi w runtime. Flag nie generujemy przez AI.

## Zasady ogólne

- Katalog państw jest oddzielony od geometrii; ID krajów są stabilne
  (`KOS` to ID Natural Earth, nie ISO). Kraje wspólne kontynentów mają jedno ID.
- Mapa to zgeneralizowany materiał do ćwiczeń, nie mapa prawnych granic ani
  kontroli wojskowej. Natural Earth stosuje [politykę de facto](https://www.naturalearthdata.com/about/disputed-boundaries-policy/);
  odstępstwa poniżej są jawne i sprawdzane walidatorami.
- Polskie nazwy: krótkie nazwy z [wykazu KSNG](https://www.gov.pl/web/ksng/Urzedowy-wykaz-nazw-panstw-i-terytoriow-niesamodzielnych);
  „Holandia” zgodnie ze [stanowiskiem RJP](https://rjp.pan.pl/holandia-a-niderlandy/).
  Metadana `plural` steruje „leży/leżą” (Niemcy, Czechy, Węgry, Włochy).
- Nietypowe stolice mają jawne pytanie (np. „siedziba władz”) i wyjaśnienie.
- Nowa kategoria (waluty, języki itd.) wymaga źródeł pierwotnych, dat
  weryfikacji, wariantów nazw i walidatora. Wikidata może być źródłem importu,
  nie automatycznym zatwierdzeniem.
- Zmiana źródła lub faktu = ponowna weryfikacja i nowa wersja paczki; migawki
  aktywnych sesji i stare assety zostają.

## Geometria

[Natural Earth 1:50m v5.1.2](https://github.com/nvkelso/natural-earth-vector/tree/v5.1.2/geojson),
`ne_50m_admin_0_countries.geojson`, [domena publiczna](https://www.naturalearthdata.com/about/terms-of-use/),
SHA-256 `3e458fc036ad0a66411f2c1e6cac49c5d7bfb81cb1123bc513b22511a2b7fdeb`.
Jeden świat Mercatora, geometria przycięta do okna kontynentu (krawędź okna nie
jest granicą). Państwa transkontynentalne można wskazać w każdym widocznym fragmencie.

| Zakres | Okno | Obiekty |
|---|---|---|
| Europa | 32°W–65°E, 34°N–72°N | 51 |
| Afryka | 26°W–65°E, 36°S–38°N | 54 |
| Azja | 20°E–180°E, 12°S–82°N | 50 |

**Europa (51):** typowe 44 państwa, Kosowo oraz Cypr, Turcja, Gruzja, Armenia,
Azerbejdżan i Kazachstan — świadomie szeroki zakres edukacyjny. Terytoria
zależne nie są osobnymi pytaniami; Wyspy Alandzkie należą do Finlandii.
Okno zachowuje Azory, Islandię i Kaukaz, pomija północne archipelagi.

- Kosowo — osobne państwo (uznawane przez Polskę).
- Krym — Ukraina, zgodnie z [polityką MSZ](https://www.gov.pl/web/dyplomacja/oswiadczenie-msz-dot-wyborow-w-rosji);
  skrypt przenosi dokładnie jeden poligon z RUS do UKR.
- Cypr Północny (`CYN`) — Cypr, zgodnie z [MSZ/KSNG](https://www.gov.pl/attachment/6e834bae-1a81-4728-94c5-916a43eb8827).
- Abchazja i Osetia Południowa — Gruzja.
- Walidator ma punkty kontrolne: Krym, północ Cypru, Abchazja, Osetia
  Południowa, Karabach, obwód królewiecki, Wyspy Alandzkie.

**Afryka (54):** państwa członkowskie ONZ; bez terytoriów zależnych i Sahary
Zachodniej jako celu. Egipt obejmuje Synaj, Somalia — Somaliland. Poligon Maroka
przycinamy do obszaru na północ od 27°40′N, aby sporna Sahara Zachodnia nie była
poprawnym wskazaniem Maroka (uproszczenie edukacyjne, nie rozstrzygnięcie; por.
[materiały MTS](https://icj-web.leman.un-icc.cloud/sites/default/files/case-related/61/9470.pdf)).
Pięć małych państw wyspiarskich ma znaczniki obok oryginalnej geometrii.

**Azja (50):** 48 państw ONZ (z Rosją, Cyprem, Kaukazem, Kazachstanem) oraz
Palestyna i Tajwan jako obszary o szczególnym statusie opisanym przez KSNG —
ujęcie w quizie nie rozstrzyga statusu. Cypr Północny → Cypr; Hongkong i Makau →
Chiny; Gaza i Zachodni Brzeg tworzą Palestynę. Pominięto fragmenty Rosji za
południkiem 180°.

Mikropaństwa (7 w Europie) mają znaczniki 48×48 dp; nakładające się znaczniki
najpierw przybliżają mapę, dopiero potem wybierają kraj.

## Stolice

| Zakres | Źródło | Weryfikacja |
|---|---|---|
| Europa (paczka 0.3) | [KSNG, wyd. VIII zaktualizowane, 2025](https://www.gov.pl/attachment/2b559c83-4ef7-403b-9063-76a364994597) | `build_capitals.py` |
| Afryka, Azja (0.1.0) | [KSNG 2025, aktualizacja 2026](https://www.gov.pl/attachment/1cde0699-e88f-4401-bca5-c9909d0fe526), SHA-256 `4645f3f84b46920b7e9bb480a265f70a52da5d429977eb650709d84dfabd08eb` | 2026-11-13 |

Każdy fakt ma stronę PDF, status, datę i jawne aliasy. Build sprawdza SHA PDF
i obecność stolicy (pozycja `stol.`) oraz aliasów na zapisanej stronie.
Angielskie aliasy stolic Afryki i Azji pochodzą wyłącznie z przypiętego
[Natural Earth populated places 1:50m](https://github.com/nvkelso/natural-earth-vector/blob/v5.1.2/geojson/ne_50m_populated_places.geojson)
(SHA-256 `da4662b7bbfeb897d02f228c5839131dce27acff5717630f91ccff4f67828ee7`),
przy zgodnym państwie i polskiej nazwie.

Przypadki szczególne:

- **Szwajcaria** — pytanie o siedzibę władz federalnych: Berno ([EDA](https://www.aboutswitzerland.eda.admin.ch/en/political-system)).
- **Holandia** — stolica konstytucyjna: Amsterdam; Haga nie jest aliasem
  ([profil UE](https://european-union.europa.eu/principles-countries-history/eu-countries/netherlands_en)).
- **Gwinea Równikowa** — Ciudad de la Paz od stycznia 2026; Malabo to poprzednia
  stolica ([dekret](https://www.guineaecuatorialpress.com/index.php/noticias/decreto_ley_por_el_que_se_declara_la_ciudad_de_la_paz_djibloho_capital_de_la_republica_de_guinea_ecuatorial)).
  Starsze dane NE nie nadpisują tej zmiany.
- **RPA** — siedziba władzy wykonawczej: Pretoria. **Eswatini** — siedziba administracji: Mbabane.
- **Benin** — Porto-Novo (rząd: Kotonu). **Wybrzeże Kości Słoniowej** — Jamusukro (rząd: Abidżan).
- **Izrael** — siedziba władz: Jerozolima, z wyjaśnieniem spornego statusu.
  **Palestyna** — tymczasowa siedziba władz: Ramallah. **Tajwan** — siedziba władz: Tajpej.
- **Sri Lanka** — Sri Dźajawardanapura Kotte (rząd: Kolombo).
- **Indonezja** — Dżakarta zgodnie z KSNG; przeniesienie do Nusantary wymaga
  ponownej weryfikacji ([MK, X 2026](https://en.mkri.id/news/details/2026-10-29/Court_Declares_IKN_Law_Petition_Inadmissible): dekret nie wydany).
- **Jemen** — Sana (stolica konstytucyjna).

## Flagi

SVG z [country-flags](https://github.com/hampusborgos/country-flags/tree/c09927e63705529bbf59ca6684cd9b23225dddad),
commit `c09927e63705529bbf59ca6684cd9b23225dddad`. README źródła deklaruje domenę
publiczną flag i pochodzenie z Wikimedia Commons; repozytorium nie ma pliku
LICENSE, więc nie przypisujemy mu innej licencji. Używamy opublikowanych
wariantów bez dorysowywania symboli (Afganistan: wariant źródłowy
czarno-czerwono-zielony; to nie stanowisko polityczne).

- PNG 500 px szerokości w oryginalnych proporcjach (Nepal 500×610),
  renderowane systemowym librsvg/Cairo; manifest zapisuje SHA źródeł i PNG.
- Mapowanie ADM0_A3 → ISO z Natural Earth; Kosowo: kod roboczy XK.
- Assety: `assets/flags/{europe,africa,asia}-0.1.0/`; źródłowe SVG w `tools/data_pipeline/*flags_sources/`.
- Nazwa kraju nie występuje w opisie semantycznym flagi ani w nagłówku pytania mapowego.
- Nazwy państw nie mają źródłowych aliasów: obowiązuje nazwa z katalogu
  (z normalizacją i jedną literówką). Kierunek państwo → flaga — nie wdrożony.
- Nowa wersja grafiki = nowa ścieżka wersji; stare assety zostają dla aktywnych sesji.

## Rzeźba terenu

[Natural Earth I with Shaded Relief 1:50m, v3.2.0](https://www.naturalearthdata.com/downloads/50m-raster-data/50m-natural-earth-1/),
domena publiczna; archiwum `https://naciscdn.org/naturalearth/50m/raster/NE1_50M_SR.zip`,
SHA-256 `ae930744c0cf3d10e73c292726b74c81a40490a75829f8299dec9069e5d0e934`.

Generator przelicza raster z WGS84 do EPSG:3857 (interpolacja dwuliniowa),
rozjaśnia paletę, ustawia morze na RGB `218, 238, 244` i indeksuje do 256 kolorów.
PNG 1536 px szerokości: Europa 1536×1099, Afryka 1536×1346, Azja 1536×1579
(łącznie ok. 2,6 MB; manifest w `assets/maps/styles/relief/`). Raster jest tylko
tłem — wybór i ocenianie wynikają z wektorów. Przy dużym zoomie możliwe drobne
różnice wybrzeży (różne wersje generalizacji) i pikselizacja.
Koszt pamięci na Androidzie wymaga sprawdzenia na telefonie.

## Ciekawostki

`assets/content/country_trivia.json`: po 3 krótkie polskie parafrazy dla każdego
z 148 kanonicznych krajów/obszarów (444 fakty). Rekord: trwałe `id`, tekst, tytuł
i URL źródła, data `checked`. Nie zmieniać istniejących ID bez powodu.

Źródła:

- CIA World Factbook — archiwum [factbook/factbook.json](https://github.com/factbook/factbook.json)
  przypięte do `144d6977b2b01ac1cbd220de754c0a005616760b` (CIA: domena publiczna,
  archiwum: CC0). To archiwum, nie bieżące dane — wysokości i klasyfikacje
  wymagają okresowego przeglądu.
- [UNESCO World Heritage Centre](https://whc.unesco.org/en/list/) (opisy CC BY-SA IGO 3.0),
  adres obiektu przy każdym fakcie.
- [Narodowe Muzeum Techniki w Czechach](https://plasy.ntm.cz/en/about-our-museum/ntm-museums/museum-of-industry/history-of-contact-lenses)
  — miękkie soczewki Ottona Wichterlego.
- Źródła urzędowe: rząd Cypru, Akademia Wojskowa w Belgradzie (w odnośnikach).

Obszary sporne opisujemy geograficznie, bez rozstrzygania granic; Palestyna ma
osobne informacje o Zachodnim Brzegu i Strefie Gazy. Walidator sprawdza
strukturę (pokrycie, 3 różne rekordy, ID, data, URL), nie prawdziwość treści —
ta wymaga przeglądu człowieka. `--allow-incomplete` służy tylko roboczej kontroli.

## Odtwarzanie paczek

Wszystkie `--check` działają offline i nie odtwarzają plików.

```bash
python3 tools/data_pipeline/build_map.py                 # Europa: geometria
python3 tools/data_pipeline/build_capitals.py --source /ścieżka/KSNG-2025.pdf
python3 tools/data_pipeline/build_flags.py               # Europa: pobiera przypięte SVG
python3 tools/data_pipeline/build_africa.py --build --pdf /ścieżka/KSNG-2026.pdf
python3 tools/data_pipeline/build_asia.py   --build --pdf /ścieżka/KSNG-2026.pdf
python3 tools/data_pipeline/build_relief.py --build [--source /ścieżka/NE1_50M_SR.zip]
python3 tools/data_pipeline/build_trivia.py --check
```

Build wymaga Pythona/Pillow, `pdftotext`, systemowego librsvg/Cairo oraz sieci
albo wcześniej pobranych plików (`--source`, `--places`). To narzędzia budowania,
nie zależności aplikacji.
