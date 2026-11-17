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
| Europa | 32°W–65°E, 34°N–72°N | 47 |
| Afryka | 26°W–65°E, 36°S–38°N | 54 |
| Azja | 20°E–180°E, 12°S–82°N | 50 |
| Ameryka Północna | 170°W–50°W, 5°N–84°N | 22 |
| Ameryka Południowa | 95°W–30°W, 57°S–15°N | 13 |
| Australia i Oceania | 110°E–150°W, 50°S–22°N | 14 |

**Europa (47):** 44 państwa europejskie ONZ, Kosowo oraz Cypr i Turcja
(wspólne z Azją: Cypr jako członek UE, Turcja jako kraj transkontynentalny).
Kazachstan, Gruzja, Armenia i Azerbejdżan są celami tylko w Azji; na mapie
Europy widać je jako ląd kontekstowy. Terytoria
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

**Ameryki i Oceania (49):** państwa ONZ według przydziału kontynentów w KSNG
(Trynidad i Tobago w Ameryce Południowej); bez terytoriów zależnych (Grenlandia,
Portoryko, Gujana Francuska, Nowa Kaledonia — ląd kontekstowy) oraz bez Wysp
Cooka i Niue. Jeden generator: `build_region.py REGION --check`. Oceania leży po
obu stronach 180°, więc jej geometria, ląd kontekstowy i rzeźba mają długości
przesunięte o 180° (`build_map.shift_lon`; okno 70°W–30°E w układzie
przesuniętym). Małe państwa wyspiarskie mają znaczniki (7 w Ameryce Północnej,
1 w Południowej, 8 w Oceanii).

**Ląd kontekstowy:** pozostały ląd w oknie każdej mapy (kraje spoza quizu tego
kontynentu oraz obszary wycięte przez politykę, np. Krym na mapie Azji, Sahara
Zachodnia) jest jedną neutralną, nieklikalną warstwą (`assets/maps/context/`,
`build_context.py`). Krym nie jest Rosją także na mapie Azji (walidator to sprawdza).

## Województwa i stany USA (0.6.0 mapa, 0.7.0 stolice i symbole)

`Continent.poland` i `Continent.usa` — mapy „gdzie leży?” bez stolic i flag
(etap 2). Generator: `build_subdivisions.py poland|usa`.

- **Geometria:** Natural Earth 1:10m admin-1 v5.1.2 (SHA-256 `22d0e3ad…`),
  ląd kontekstowy z NE 1:10m admin-0 (`239eec57…`), żeby granice się zgadzały.
  Okna: Polska 13,5–24,5°E, 48,6–55,3°N; USA 128–64°W, 16–51°N.
- **ID:** ISO 3166-2 — `PL-02`…`PL-32` (kody TERYT, ISO od 2018), `US-AL`…`US-WY`.
  Karty FSRS dla ID dłuższych niż 3 znaki mają osobny zakres (`fsrsCardId`).
- **Nazwy województw:** art. 2 ust. 1 ustawy o trójstopniowym podziale
  (Dz.U. 1998 nr 96 poz. 603, PDF z dziennikustaw.gov.pl, SHA-256 `5a80569e…`);
  pytanie „Gdzie leży województwo mazowieckie?”.
- **Nazwy stanów:** polskie egzonimy z KSNG, *Urzędowy wykaz polskich nazw
  geograficznych świata*, wyd. 2, 2019, s. 595 (17 stanów, SHA-256 `8389e875…`);
  pozostałe — nazwa oryginalna. „stan Waszyngton” i „stan Nowy Jork” w pytaniu,
  bo to także nazwy miast. Dystrykt Kolumbii jest lądem kontekstowym.
- **Wstawki:** Alaska (skala 0,24) i Hawaje (1,47) przesunięte w Web Mercatorze
  do ramek w lewym dolnym rogu, z podpisem „inna skala”; wyspy NW Hawajów
  (na zachód od 161°W) pominięte. W stylu Rzeźba wstawki mają jasne wypełnienie.
- Znaczniki: Rhode Island i Delaware.
- **Miasta wojewódzkie** (`build_subdivision_symbols.py`): art. 3 tej samej ustawy.
  Kujawsko-pomorskie (wojewoda — Bydgoszcz, sejmik — Toruń) i lubuskie (Gorzów
  Wielkopolski, Zielona Góra): zaliczane oba miasta, wyjaśnienie w `note`.
  Natural Earth ma tu błędy (Elbląg, brak Torunia), więc nie jest źródłem.
- **Stolice stanów:** Natural Earth 1:10m populated places (`Admin-1 capital`,
  SHA-256 `9b8e3de0…`); KSNG nie podaje polskich nazw tych miast (sprawdzane).
- **Herby województw i flagi stanów:** SVG z Wikimedia Commons, licencja każdego
  pliku z API Commons: „Public domain” (Missisipi: „Copyrighted free use”);
  polskie herby to urzędowe symbole wyłączone z prawa autorskiego (art. 4).
  Kopie SVG w `tools/data_pipeline/{poland,usa}_symbols_sources/` są przypięciem
  (sha1 zgodne z Commons), PNG 500 px w `assets/flags/{poland,usa}-0.1.0/`.
- Słownictwo pytań (`Continent`): „Którego województwa to herb?”, „Stolica stanu?”,
  „Miasto wojewódzkie?”; kategorie „Herby”, „Miasta wojewódzkie”, „Stolice stanów”.

Mikropaństwa (7 w Europie) mają znaczniki 48×48 dp; nakładające się znaczniki
najpierw przybliżają mapę, dopiero potem wybierają kraj.

## Stolice

| Zakres | Źródło | Weryfikacja |
|---|---|---|
| Europa (paczka 0.3) | [KSNG, wyd. VIII zaktualizowane, 2025](https://www.gov.pl/attachment/2b559c83-4ef7-403b-9063-76a364994597) | `build_capitals.py` |
| Afryka, Azja, Ameryki, Oceania (0.1.0) | [KSNG 2025, aktualizacja 2026](https://www.gov.pl/attachment/1cde0699-e88f-4401-bca5-c9909d0fe526), SHA-256 `4645f3f84b46920b7e9bb480a265f70a52da5d429977eb650709d84dfabd08eb` | 2026-11-13 |

Każdy fakt ma stronę PDF, status, datę i jawne aliasy. Build sprawdza SHA PDF
i obecność stolicy (pozycja `stol.`) oraz aliasów na zapisanej stronie.
Angielskie aliasy stolic spoza Europy pochodzą wyłącznie z przypiętego
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
- Assety: `assets/flags/<kontynent>-0.1.0/`; źródłowe SVG w `tools/data_pipeline/*flags_sources/`.
- Nazwa kraju nie występuje w opisie semantycznym flagi ani w nagłówku pytania mapowego.
- Nazwy państw nie mają źródłowych aliasów: obowiązuje nazwa z katalogu
  (z normalizacją i jedną literówką). Kierunek państwo → flaga — nie wdrożony.
- Nowa wersja grafiki = nowa ścieżka wersji; stare assety zostają dla aktywnych sesji.

## Grafiki ekranu Dziś

`assets/home/`: ilustracje regionów (`hero_<region>.webp`), kafelki treningu
(`tile_<region>_{mapa,stolice,flagi}.webp`, przekonwertowane z PNG) i ikona gór —
z paczki projektowej GeoKuna Assets v1.1 (`assets_mockups/`, dostarczona przez
właściciela projektu). To dekoracje: nie są źródłem geometrii ani faktów; flagi
i herby na kafelkach są tylko ozdobą (pytania używają paczek z sekcji Flagi).

## Rzeźba terenu

[Natural Earth I with Shaded Relief, Water, and Drainages 1:10m, v2.0.0](https://www.naturalearthdata.com/downloads/10m-raster-data/10m-natural-earth-1/),
domena publiczna; archiwum `https://naciscdn.org/naturalearth/10m/raster/NE1_HR_LC_SR_W_DR.zip`
(324 MB, tylko do budowania), SHA-256 `8841d08155415f0556462846dcb845a4ccb8f12390b0e0ba36ffde55efadeb56`.
Raster ma już rzeki, jeziora i batymetrię.

Generator tnie raster na kafelki Web Mercator 256 px, zoom 2–6 (z6 ≈ natywna
rozdzielczość 1/60°; wyżej aplikacja powiększa), WebP jakość 80, rozjaśnione o 12%.
Jeden płaski katalog `assets/maps/styles/relief/tiles/<zestaw>_<z>_<x>_<y>.webp`:
zestaw `world` jest wspólny dla pięciu kontynentów, `oceania` powstaje z rastra
przesuniętego o 180°. Razem 3753 kafelki, ok. 12,6 MB (manifest: suma kontrolna
wszystkich kafelków, wersja 0.3.0). Poza oknem kontynentu mapa pokazuje gładkie
morze. Raster jest tylko tłem — wybór i ocenianie wynikają z wektorów.

**Wyższa jakość dla Polski i USA** (`build_relief_hd.py`, manifest
`manifest_hd.json`): kafelki z7–8 (Polska) i z7 (USA) łączą kolory NE 1:10m,
cieniowanie z modelu wysokości [ETOPO 2022 15″](https://www.ncei.noaa.gov/products/etopo-global-relief-model)
(NOAA, domena publiczna; przewyższenie 2,5×, dno morza bez cieniowania) i ostre
wektorowe rzeki i jeziora NE 1:10m. Dla kontynentów nie ma praktycznej drogi wyżej:
z7 wymagałby ok. 10 GB źródeł ETOPO i kilkudziesięciu MB kafelków.

**Style wektorowe:** nowoczesny i papierowy atlas mają po 5 wypełnień; sąsiednie
kraje (wspólne wierzchołki granicy) zawsze dostają różne kolory (kolorowanie grafu
w `countryColoring`). Granice 1,2–1,3 px, ciemniejsze niż wypełnienia.
Nowoczesny: nasycone, jasne kolory i miękki cień wzdłuż wybrzeży. Papierowy:
sepia, ziarno i włókna papieru, rytowane linie wody przy brzegach (`coastRings`),
siatka 15°/10°, podwójna ramka z podziałką co 5°, winieta i róża wiatrów.
Koszt pamięci na Androidzie wymaga sprawdzenia na telefonie.

## Ciekawostki

`assets/content/country_trivia.json` (wersja 0.5.0, 2026-11-16): po 3 fakty
o każdym ze 197 krajów oraz 16 województw i 50 stanów (789) — rekordy w skali świata lub kontynentu, wynalazki,
„pierwsze” i „jedyne”, przyroda i zabytki UNESCO. Rekord: trwałe `id`, tekst,
tytuł i URL źródła, data `checked`.

Źródło każdego faktu: artykuł Wikipedii o kraju (pl lub en) w przypiętej wersji
(`?oldid=`); tekst to parafraza tylko tego, co jest w tej wersji. Wersje 0.1–0.2
opierały się na CIA World Factbook i dawały głównie położenie i najwyższe szczyty.
Kandydatów wybierano skryptem, który punktuje zdania z rekordem i datą, a odrzuca
politykę i statystyki; wybór i parafrazę robi człowiek lub model według zasad
poniżej. Odtworzenie: te same artykuły w tych samych wersjach.

Obszary sporne opisujemy neutralnie, bez rozstrzygania granic; przy Palestynie
wybrano fakty kulturowe (haft, Betlejem, symbole przyrody). Walidator sprawdza
strukturę (pokrycie, 3 różne rekordy, ID, data, URL), nie prawdziwość treści —
ta wymaga przeglądu człowieka. `--allow-incomplete` służy tylko roboczej kontroli.

### Ciekawostki o flagach

`assets/content/flag_trivia.json` (wersja 0.4.0): po 3 fakty o fladze każdego
ze 197 krajów oraz o herbie województwa i fladze stanu (789), według zasad poniżej — geneza barw i symboli, pierwsze
użycie i rok przyjęcia, co przedstawia godło, nietypowości. Źródło każdego
faktu: artykuł Wikipedii o fladze (polski lub angielski) w przypiętej wersji
(`?oldid=`), pobrany 2026-11-15 (Ameryki i Oceania: 2026-11-16) przez API MediaWiki; tekst to polska parafraza
wyłącznie tego, co jest w tej wersji. Wersja 0.1.0 (CIA Factbook) dawała głównie
znaczenia barw. Pokazywane po pytaniach o flagę (także flaga → mapa); aplikacja
pomija fakt, który wspomina kraj pytany dalej w tej samej serii. Walidator:
`build_trivia.py --check` (trzy paczki). Fakty sprawdza się z linkiem do wersji.

### Ciekawostki o stolicach

`assets/content/capital_trivia.json` (0.3.0, 2026-11-16): po 3 fakty o stolicy
każdego ze 197 krajów oraz o mieście wojewódzkim i stolicy stanu (789) — założenie i dawne nazwy, „pierwsze” i rekordy,
wydarzenia z datą. Źródła jak przy flagach: artykuł Wikipedii o mieście (pl lub
en) w przypiętej wersji (`?oldid=`), tekst to parafraza tylko tego, co w niej
jest. Klucz to kraj (jak w innych paczkach), więc kraj z dwoma stolicami ma
fakty o tej z `capitals.json`. Pokazywane po pytaniach o stolicę.

### Jaka ma być ciekawostka (zasady redakcyjne)

Ciekawostka ma dać „aha!”, a nie powtórzyć oczywistość. Obowiązuje obie paczki;
nowe i poprawiane fakty przechodzą przez tę listę.

- **Konkret, nie ogólnik.** Liczba, rok, nazwa, miejsce lub rekord. „Godło
  symbolizuje robotników i chłopów” — za mało; „Czerwień oznacza wolność” — samo
  w sobie banalne.
- **Pełny kontekst.** Wynalazek lub „pierwszy raz” zawsze z rokiem i miejscem;
  przy rekordzie powiedz, w jakiej skali: „pierwsze na świecie miękkie soczewki
  kontaktowe (Otto Wichterle, Praga, 1961)”, a nie „w Czechach wynaleziono
  soczewki”. Superlatyw („pierwszy”, „największy”, „najstarszy”) tylko wtedy,
  gdy źródło go potwierdza; inaczej „jeden z pierwszych” albo bez rekordu.
- **Legenda jako legenda.** „Według legendy…” przy podaniach (np. Dannebrog
  spadający z nieba w 1219 r.), osobno udokumentowana data.
- **Wyjaśnia „dlaczego”.** Najlepsze fakty łączą dwie rzeczy, które uczeń zna
  albo zapamięta: barwy z herbu, nazwę z rzeki, datę z wydarzeniem.
- **Samodzielna i krótka.** 1–2 zdania (walidator: 20–250 znaków), zrozumiała
  bez pytania; bez „ten kraj”, gdy nazwa jest potrzebna.
- **Trzy różne fakty na kraj** — różne tematy, nie trzy warianty tego samego.
- **Bez zdradzania.** Nie podaje odpowiedzi przyszłych pytań (aplikacja i tak
  pomija fakt z krajem pytanym dalej w serii).
- **Źródło do konkretu.** Każda liczba i data musi być w podanym źródle.
  Kolejność: urzędowe (konstytucja, ustawa o symbolach, strona rządu lub
  parlamentu), encyklopedie (Britannica), CIA Factbook, artykuł Wikipedii
  o fladze z **przypiętą wersją** (`?oldid=`), tak by tekst źródła się nie
  zmienił; Flags of the World (FOTW) pomocniczo. Spory — „według…”.

**Flagi — tematy w kolejności ważności** (każdy kraj: zwykle geneza + dwa inne):

1. **Geneza barw i symboli** — skąd te kolory: herb, dynastia, ruch
   niepodległościowy, barwy panafrykańskie lub panarabskie, flaga wzorcowa.
   Np. Polska: biel i czerwień z herbu — biały orzeł na czerwonym polu
   — z podanym źródłem urzędowym lub encyklopedycznym.
2. **Pierwsze użycie i przyjęcie** — rok i okoliczność: powstanie, niepodległość,
   rewolucja; czy wzór się zmieniał.
3. **Co jest na fladze** — zwierzę lub postać: jaki gatunek i dlaczego (np.
   żuraw koroniasty Ugandy, amazonka cesarska Dominiki); budowla, broń, napis
   z przekładem.
4. **Nietypowość** — kształt lub proporcje (Nepal), najstarsza w użyciu,
   rekord liczby zmian, jak odróżnić od bliźniaczej (Czad / Rumunia).

Unikaj samego „barwa X oznacza Y” bez genezy — dopuszczalne raz, gdy znaczenie
jest urzędowe i zaskakujące.

## Odtwarzanie paczek

Wszystkie `--check` działają offline i nie odtwarzają plików.

```bash
python3 tools/data_pipeline/build_map.py                 # Europa: geometria
python3 tools/data_pipeline/build_capitals.py --source /ścieżka/KSNG-2025.pdf
python3 tools/data_pipeline/build_flags.py               # Europa: pobiera przypięte SVG
python3 tools/data_pipeline/build_africa.py --build --pdf /ścieżka/KSNG-2026.pdf
python3 tools/data_pipeline/build_asia.py   --build --pdf /ścieżka/KSNG-2026.pdf
python3 tools/data_pipeline/build_relief.py --build [--source /ścieżka/NE1_HR_LC_SR_W_DR.zip]
python3 tools/data_pipeline/build_relief_hd.py --build --ne NE1_HR_LC_SR_W_DR.zip --dem ETOPO/ --water NE10m/
python3 tools/data_pipeline/build_subdivisions.py poland --build --src ŹRÓDŁA/   # też: usa
python3 tools/data_pipeline/build_subdivision_symbols.py poland --build --src ŹRÓDŁA/   # stolice i symbole
python3 tools/data_pipeline/build_trivia.py --check
```

Build wymaga Pythona/Pillow, `pdftotext`, systemowego librsvg/Cairo oraz sieci
albo wcześniej pobranych plików (`--source`, `--places`). To narzędzia budowania,
nie zależności aplikacji.
