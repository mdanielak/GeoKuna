# Polityka treści — Europa 0.2

Paczka dotyczy lokalizacji, a nie faktów encyklopedycznych. Źródło geometrii:
[Natural Earth v5.1.2](https://github.com/nvkelso/natural-earth-vector/tree/v5.1.2/geojson),
`ne_50m_admin_0_countries.geojson`, [domena publiczna](https://www.naturalearthdata.com/about/terms-of-use/).
Import sprawdza przypięte SHA-256. Manifest zawiera sumy wyników. `--check` działa offline.

## Zakres

To świadomie szeroki zakres edukacyjny, nie twierdzenie, że istnieje jedna
obowiązująca definicja „51 państw Europy”. Obejmuje typowe 44 państwa Europy,
Kosowo oraz Cypr, Turcję, Gruzję, Armenię, Azerbejdżan i Kazachstan. Każde ma
jeden stabilny identyfikator. `KOS` jest identyfikatorem Natural Earth, nie kodem ISO.

Albania, Andora, Armenia, Austria, Azerbejdżan, Belgia, Białoruś,
Bośnia i Hercegowina, Bułgaria, Chorwacja, Cypr, Czarnogóra, Czechy, Dania,
Estonia, Finlandia, Francja, Grecja, Gruzja, Hiszpania, Holandia, Irlandia,
Islandia, Kazachstan, Kosowo, Liechtenstein, Litwa, Luksemburg, Łotwa,
Macedonia Północna, Malta, Mołdawia, Monako, Niemcy, Norwegia, Polska,
Portugalia, Rosja, Rumunia, San Marino, Serbia, Słowacja, Słowenia,
Szwajcaria, Szwecja, Turcja, Ukraina, Watykan, Węgry, Wielka Brytania, Włochy.

Terytoria zależne nie są osobnymi państwami w quizie. Wyspy Alandzkie,
wydzielone w źródle kartograficznym, są przypisane do Finlandii.
Geometria jest przycięta do prostokąta 32°W–65°E, 34°N–72°N. Pozostawia m.in.
Azory, Islandię, kontynentalną Skandynawię i Kaukaz; pomija odległe części
państw i północne archipelagi. Pionowa krawędź na wschodzie to krawędź
wycinka mapy, nie granica Europy ani państwa. Państwa transkontynentalne
można wskazywać w każdym ich fragmencie obecnym na mapie.

## Nazwy i granice

Polskie etykiety odpowiadają tradycyjnym krótkim nazwom z
[wykazu KSNG](https://www.gov.pl/web/ksng/Urzedowy-wykaz-nazw-panstw-i-terytoriow-niesamodzielnych).
Zostawiamy nazwę „Holandia”, zgodnie ze [stanowiskiem RJP](https://rjp.pan.pl/holandia-a-niderlandy/).
Jawna metadana `plural` oznacza Niemcy, Czechy, Węgry i Włochy.

Natural Earth stosuje [politykę de facto](https://www.naturalearthdata.com/about/disputed-boundaries-policy/).
Katalog aplikacji nie jest prostą kopią listy poligonów. W tej paczce:

- Kosowo jest osobnym państwem, zgodnie z wykazem państw uznawanych przez Polskę.
- Krym przypisujemy Ukrainie, zgodnie z [polityką MSZ](https://www.gov.pl/web/dyplomacja/oswiadczenie-msz-dot-wyborow-w-rosji).
  Skrypt przenosi jeden dokładny poligon Krymu ze zbioru RUS do UKR.
  Sprawdza, że w przypiętej wersji źródła istnieje dokładnie jeden taki poligon.
- Północ Cypru (`CYN`) przypisujemy do Cypru. Nie tworzymy z niej osobnego
  państwa, zgodnie z [informacją MSZ/KSNG](https://www.gov.pl/attachment/6e834bae-1a81-4728-94c5-916a43eb8827).
- Abchazja i Osetia Południowa pozostają częścią Gruzji w użytej geometrii.

Walidator sprawdza punkty kontrolne na Krymie, północy Cypru, w Abchazji,
Osetii Południowej, Karabachu, obwodzie królewieckim i na Wyspach Alandzkich.
To zgeneralizowana mapa do ćwiczenia lokalizacji, a nie aktualna mapa kontroli
wojskowej. Kolejna wersja źródła wymaga ponownej kontroli tych przypisań.

## Kolejne kategorie

Przed dodaniem stolic, walut i języków: zebrać źródła pierwotne, daty
weryfikacji, warianty nazw, wiele wartości i zakres ich obowiązywania.
Wikidata może być źródłem importu, ale nie automatycznym zatwierdzeniem.
Stan „verified” wymaga udokumentowanej weryfikacji. Model językowy nie jest źródłem.

## Stolice — paczka 0.3

`capitals_curated.json` zawiera 51 faktów, sprawdzonych z
[KSNG, wydanie VIII zaktualizowane, 2025](https://www.gov.pl/attachment/2b559c83-4ef7-403b-9063-76a364994597).
Każdy rekord ma numer strony PDF (liczony od 1), status, datę weryfikacji
względem tego wydania oraz jawne aliasy. Skrypt sprawdza SHA-256 źródłowego
PDF, obecność nazwy stolicy w pozycji `stol.` na zapisanej stronie i obecność
każdego aliasu na tej samej stronie. Nie eksportujemy całego dokumentu.
Paczka zawiera fakty i nazwy, a nie reprodukcję opisów źródłowych.

Berno: pytanie o siedzibę władz federalnych, z uwagą o szczególnym statusie,
na podstawie [szwajcarskiego MSZ](https://www.aboutswitzerland.eda.admin.ch/en/political-system).
Amsterdam: pytanie o stolicę konstytucyjną; Haga nie jest aliasem odpowiedzi.
Rozróżnienie stolicy i siedziby rządu potwierdza również
[profil kraju UE](https://european-union.europa.eu/principles-countries-history/eu-countries/netherlands_en).

Odtworzenie paczki wymaga przypiętego PDF i `pdftotext`:

```bash
python3 tools/data_pipeline/build_capitals.py --source /ścieżka/do/KSNG-2025.pdf
python3 tools/data_pipeline/build_capitals.py --check
```

Drugie polecenie nie wymaga sieci ani narzędzi PDF. Sprawdza kompletność,
jednoznaczność nazw, metadane, zgodność pliku redakcyjnego z paczką i sumy.
Zmiany nazw/stolic po wydaniu źródła wymagają nowej weryfikacji i wersji treści.
