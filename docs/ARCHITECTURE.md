# Architektura

Modularny monolit Flutter; Material 3, Riverpod, GoRouter, flutter_map,
Drift/SQLite. Geometria GeoJSON w assets; bez warstwy kafelkowej.

`app/` — motyw, routing, dostawcy zależności.
`core/database/` — schemat Drift i transakcyjny zapis.
`features/atlas/` — katalog, parser GeoJSON, widget mapy.
`features/learning/` — model sesji, repozytorium, kontroler i ekran.
`features/home/` — ekran Dziś i atlas.
`features/progress/` — filtrowane postępy według umiejętności.

UI → kontroler → repozytorium → Drift. Odpowiedź ma klucz
`(session_id, question_index)`; zapis i postęp sesji są transakcją.
Zablokowany przycisk w UI oraz unikalność w bazie chronią przed podwójnym zapisem.
Stan po ocenie pozostaje zapisany, dopóki użytkownik nie wybierze „Dalej”.

Katalogi są ładowane asynchronicznie z assets. Błąd dziennej wyprawy
ma lokalny komunikat z ponowieniem i nie ukrywa niezależnej nawigacji. Repozytorium nie zastępuje uszkodzonej bazy pustą.

## Decyzje

- 0.4 obejmuje mapę, stolice i flagi 51 państw oraz niezależną pamięć FSRS.
- `memory.dart`: czysty adapter dart-fsrs i zapis dziennika. Repozytorium
  transakcyjnie łączy ocenę z harmonogramem, wybiera kolejkę i importuje historię.
  UI otrzymuje stan przez Riverpod; reguły nauki są niezależne od widgetów.
- Kolejność pytań losowana raz, następnie utrwalana w sesji.
- Natural Earth 1:50m v5.1.2; geometria przycięta do okna widoku
  32°W–65°E, 34°N–72°N. To wycinek renderowania, nie definicja granicy kontynentu.
  Poligony zachowują otwory. Reguły przypisania terytoriów: CONTENT_POLICY.md.
- Siedem małych państw ma znaczniki 48×48 px; bliskie znaczniki najpierw
  przybliżają mapę. `focusId` atlasu centruje wybrane państwo.
- `Country.plural` jest metadaną językową; `locationQuestion` dobiera
  „leży” / „leżą”. Nie wnioskujemy liczby gramatycznej z końcówki nazwy.
- Pytanie mapowe startuje w przybliżeniu regionu: środek przesunięty losowo
  o 1,5–3,5° szerokości i 2,5–5,5° długości w obu kierunkach;
  okno ±10° szerokości geograficznej i ±16° długości.
  Seed sesji i indeksu pytania utrzymuje kadr przy zaznaczaniu i wznowieniu. Nie zaznacza celu.
  Reset przywraca całą Europę, a atlas zachowuje ogólny widok początkowy.
- Stolice: trzy poziomy; migawka pytań w sesji; osobna aktywna sesja dla
  każdego poziomu. Ocenianie tekstu jest czystą funkcją z tolerancją jednego
  błędu edycyjnego. Próby przechowują poziom oraz zaakceptowanie literówki.
- SQLite v4: migracje zachowują dane mapowe i stolic. Szczegóły w DATA_MODEL.md.
- Wybrana maskotka: `assets/mascot/kuna-globe.png`; oryginał i prompty
  pozostają w `output/imagegen/kuna-options/`.
- Android jest celem wydania. Flutter Web w Chrome jest domyślnym środowiskiem
  bieżącego uruchamiania i kontroli wizualnej; jego dane są osobnym magazynem
  przeglądarki. Nie uruchamiamy emulatora. Fizyczny Android będzie sprawdzany
  później zgodnie z docs/TESTING.md.
- Role agentów i warunki użycia skilli: AGENTS.md oraz `.codex/agents/`.

## Kolejne etapy

Rozwijać postępy i słabe punkty na podstawie osobnych kart umiejętności.
Wersjonowane fakty, adapter FSRS i dziennik powtórek są już częścią aplikacji. Nie wyciągać ogólnego „opanowania państwa” z jednego trafienia.

Flagi są osobnym formatem pytań; obrazy PNG lokalne. Szczegóły: FLAGS.md.
Trzy próby mapy są transakcjami repozytorium, nie wyłącznie stanem widgetu.
