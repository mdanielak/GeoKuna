# Flagi Europy — paczka 0.1.0

51 państw odpowiada istniejącemu katalogowi Europy. Nazwy polskie pochodzą
z `countries.json`; mapowanie ADM0_A3 → ISO_A2/ISO_A2_EH z Natural Earth v5.1.2.
Kosowo: kod roboczy XK zgodny z countries.json i README źródła flag.

Grafiki SVG: [country-flags](https://github.com/hampusborgos/country-flags/tree/c09927e63705529bbf59ca6684cd9b23225dddad),
commit `c09927e63705529bbf59ca6684cd9b23225dddad`. Źródłowy README deklaruje
public domain flag i wskazuje pochodzenie z Wikimedia Commons. Repozytorium
nie zawiera osobnego pliku LICENSE; nie przypisujemy mu fikcyjnej licencji MIT.
Używamy opublikowanych tam wariantów, bez samodzielnego dorysowywania symboli.

SVG w `tools/data_pipeline/flags_sources/` zachowują źródło. PNG w
`assets/flags/europe-0.1.0/` są eksportem w szerokości 500 px z zachowaniem
proporcji, przez istniejące systemowe librsvg/Cairo. Nie instalowano pakietów.
Wersję rendererów oraz SHA-256 źródeł/PNG/katalogu zapisuje manifest.

```bash
python3 tools/data_pipeline/build_flags.py          # pobiera przypięte SVG i odtwarza PNG
python3 tools/data_pipeline/build_flags.py --check  # offline: pokrycie, nazwy, PNG, sumy źródeł
```

Budowanie wymaga istniejących bibliotek systemowych librsvg, Cairo oraz Pillow;
sprawdzenie używa tylko Python/Pillow i plików lokalnych. Nie jest to zależność
aplikacji Android/Web. Generator nie wymaga GI typelibs ani narzędzi NPM.

## Quizy i postępy

- Flaga → państwo: cztery opcje A–D, pierwsza litera z resztą do wpisania,
  pełna nazwa do wpisania. Jeden błąd pisowni akceptowany jak w stolicach.
- Flaga → mapa: trzy bezpośrednie kliknięcia. Pierwsze stanowi ocenę FSRS,
  kolejne są ćwiczeniem. Woda, zoom klastra i powtórzenie tego samego błędnego
  kraju nie zużywają dodatkowej szansy.
- Każdy oceniany kierunek/format ma oddzielną kartę `flags:COUNTRY:FORMAT`.
  A–D pozostaje treningiem bez oceny wiedzy i harmonogramu FSRS; pełne pisanie
  jest domyślnym sugerowanym trybem.
  Nazwa kraju nie występuje w alt flagi ani nagłówku pytania mapowego.
- Obrazy, nazwy i kolejność opcji są utrwalone w migawce. Kolejna wersja
  grafiki wymaga nowej ścieżki wersji; zachować assety aktywnych sesji.
- Dziś może mieszać mapę, stolice i flagi: sześć ocenianych umiejętności na kraj,
  nadal do 3 nowych dziennie oraz jeden kraj najwyżej raz w serii.

Nie wdrożono w tym przyroście odwrotnego kierunku „państwo → wybierz flagę”.
Nie ma źródłowych aliasów nazw państw: obowiązuje nazwa widoczna w katalogu,
z normalizacją wielkości liter, diakrytyki i pojedynczej literówki.
