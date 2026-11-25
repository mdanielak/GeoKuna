# Architektura i model danych

Modularny monolit Flutter, feature-first. Material 3, Riverpod (stan
i zależności), GoRouter (nawigacja), Drift/SQLite (postęp), flutter_map
z lokalną geometrią GeoJSON — bez kafelków i bez backendu.

## Moduły

| Katalog | Odpowiedzialność |
|---|---|
| `app/` | motyw, tokeny i wspólny nagłówek regionalny (`theme.dart`: `GeoTheme`, `GeoColors`, `regionAppBar`), routing (`app.dart`), providery (`providers.dart`) |
| `core/database/` | schemat Drift, migracje; `database.g.dart` jest w repo |
| `features/atlas/` | katalogi (`Catalog` i lekkie `CatalogMeta` bez GeoJSON) oraz parser GeoJSON (`catalog.dart`), `Continent`, `ContinentChips`, `CountryMap`, granice regionów (`region_bounds.dart`), style map, `QuizMapFrame` (kadr łatwych poziomów) |
| `features/learning/` | sesje i zapis (`session_repository.dart`), model sesji z cache'owanym `questionData` (`learning_session.dart`), typy domenowe (`learning_types.dart`), plan Dziś z drabinką i parami (`daily_planner.dart`), logika ekranu quizu (`quiz_controller.dart`), adapter FSRS (`memory.dart`), stolice, flagi, ocena tekstu, poziomy, medale (`achievements.dart`), passa i nagrody za passę (`streaks.dart`), reset, reakcje kuny, ciekawostki, ekran quizu i wydzielone widoki (`widgets/`) |
| `features/home/` | Dziś i atlas (z przełącznikiem obszarów i wizytówką kraju) |
| `features/progress/` | Moja nauka (kontynent → kraje dla aktywnego poziomu z dziedziczeniem) i szczegóły umiejętności (`/progress?continent=...&country=...`) |
| `features/settings/` | preferencje (`app_preferences.dart`), arkusz wyboru poziomu (`difficulty_sheet.dart`), kopia postępu (`progress_backup.dart`), ekran ustawień z resetem |

Kolory: role Material z jednego ziarna (`GeoTheme.seed`) na papierowym tle;
role spoza Material (odpowiedź dobra/zła/literówka, ciekawostka, ramka flagi,
dymek kuny, passa, medale) tylko w `GeoColors`. Palety map są osobno w
`map_style.dart`. Typografia: Roboto z SDK (offline); pogrubione są nagłówki
z tematem pytania lub ekranu, pytania pomocnicze („Stolica?”) zostają zwykłe.

Kopia postępu: jeden plik JSON (`format: geokuna-progress`, `version`, `schema`)
ze wszystkimi tabelami; import sprawdza cały plik i zastępuje dane w jednej
transakcji. Zapis i odczyt pliku: `file_picker` (Android SAF, pobranie w Web).

Przepływ: UI → Riverpod → repozytorium → Drift. Reguły nauki są czystymi
funkcjami/klasami poza widgetami. `Continent` wybiera paczki, providery
i zakres repozytorium; ID krajów i kart są kanoniczne (bez prefiksu kontynentu).
`Continent.poland` i `Continent.usa` to obszary województw/stanów (ID ISO 3166-2);
`Continent` niesie też słownictwo pytań (herb/flaga, miasto wojewódzkie/stolica).

## Kluczowe decyzje

- Zapis próby, karty FSRS, dziennika i dnia aktywności to jedna transakcja.
  Klucz `(session_id, question_index)` + zablokowany przycisk chronią przed duplikatem.
  Stan po ocenie zostaje do „Następne pytanie”.
- Kolejność pytań losowana raz i utrwalana. Stolice i flagi zapisują migawkę
  faktów, aliasów i opcji; mapa zapisuje ID (geometria z bieżącej paczki —
  otwarte ryzyko przy przyszłej zmianie katalogu).
- Mapa regionalna: jeden świat Mercatora (`replicatesWorldLongitude=false`)
  omija pętlę powielania w flutter_map 8.3.2. Świat i geometria przez 180°
  wymagają ponownej oceny.
- Kadr quizu ustawiany po `initialCameraFit` (post-frame po `onMapReady`);
  zmiana stylu nie resetuje kamery; rozwiązanie po 3. błędzie dopasowuje kamerę raz.
- Etykiety błędnych krajów to `IgnorePointer` z jedną etykietą semantyczną.
- Dziś, Atlas i Moja nauka to gałęzie `StatefulShellRoute` z dolnym paskiem (Wstecz
  wraca do Dziś); quizy, ustawienia i szczegóły otwierają się nad paskiem.
- Błąd ładowania Dziś dotyczy tylko karty wyprawy; nawigacja pozostaje dostępna.
- Odświeżanie danych w `GeoKunaApp` reaguje na wznowienie aplikacji (`AppLifecycleState.resumed`) oraz zakończenie serii zamiast cyklicznych timerów w tle.
- Repozytorium nie zastępuje uszkodzonej bazy pustą.
- Preferencje: osobna tabela klucz/wartość; `AsyncNotifier` serializuje zapisy.
- Relief to lokalne kafelki XYZ (`TileLayer` + `AssetTileProvider`, z2–6; Polska do z8, USA do z7; `reliefTileTemplate`) pod interaktywnymi poligonami; poza oknem kontynentu maska morza.
- Papierowy atlas: `coastRings` (linie wody), `MapGraticule`, `PaperAtlasFrame`, `CompassRose` (lewy górny róg) — wszystko w `map_style.dart`, bez gestów.

## Schemat SQLite (wersja 9)

| Tabela | Klucz | Zawartość |
|---|---|---|
| `sessions` | `id` (UUID) | `country_ids` (JSON, kolejność), `current_index`, `created_at`, `completed_at`, `continent`, `topic` (`map`/`capitals`/`flags`/`daily`), `difficulty` (format lub `mixed`), `question_data` (migawka JSON), `content_version` |
| `attempts` | `(session_id, question_index)` | `country_id`, `answer`, `correct`, `typo_accepted`, `topic`, `difficulty`, `answered_at` |
| `map_guesses` | `(session_id, question_index, guess_index)` | do 3 wyborów: `selected_country_id`, `correct`, `assisted`, `guessed_at` |
| `memory_cards` | `id` = `topic:country:difficulty` | `state` (JSON FSRS lub null), `due` (UTC), `introduced_at`, `review_count` |
| `memory_reviews` | `(session_id, question_index)` | `skill_id`, `rating`, `reviewed_at`, `was_new`, `applied`, `origin` (`daily`/`manual`/`retry`/`scaffold`/`control`/`placement`/historyczne `assisted`, `recognition`), `review_log` |
| `memory_meta` | `key` | m.in. znacznik jednorazowego importu historii |
| `app_preference_entries` | `key` | `map_appearance`, `difficulty_<kontynent>`; nieznane wartości → relief/normal |
| `activity_days` | `(continent, local_date)` | `recorded_at` (UTC), `offset_minutes` |
| `awarded_medals` | `(continent, topic, level, medal)` | `earned_at`, `catalog_version`; medal 1/2/3 = 50/80/100% |
| `streak_saves` | `(continent, local_date)` | `kept` (żeton użyty / odmowa), `decided_at`; saldo żetonów liczone z dni nauki |

Indeksy (v8): `memory_reviews(skill_id, reviewed_at)`, `memory_reviews(reviewed_at)`,
`memory_cards(country_id)`, `attempts(country_id)`, `map_guesses(selected_country_id)`,
`sessions(topic, completed_at)`.

Uwagi:

- Otwarcie Dziś tylko czyta: medale liczy bez zapisu (`refresh(persist: false)`),
  a karty wstawia jedynie, gdy paczka dodała nowe. Medale zapisuje Moja nauka.

- Jedna aktywna sesja mapy, po jednej na każdy poziom stolic i flag, jedna `daily`
  na kontynent. `byId` odrzuca sesję innego kontynentu.
- `finish(id)` jest idempotentne; nie ocenia niewysłanego tekstu; rozpoczęte
  błędne pytanie mapy zamyka jako błąd bez ponownej oceny FSRS.
- Liczbowe ID kart FSRS: stolice/mapa i flagi mają rozłączne przestrzenie,
  `mapEasy`/`mapVeryEasy` osobny zakres (`memory.dart`). Nowe kategorie
  (np. Polska) wymagają nowego, trwałego przydziału ID — obecny parser zna
  tylko trzy segmenty i bieżące formaty.

## Migracje

Żadna migracja nie usuwa prób, sesji, kart ani preferencji.

| Wersja | Zmiana |
|---|---|
| 1→2 | pola topic/difficulty/question_data; `selected_country_id` → `answer` |
| 2→3 | `memory_cards`, `memory_reviews`, `memory_meta`; jednorazowy idempotentny import historii |
| 3→4 | `map_guesses` (trzy próby mapy) |
| 4→5 | `sessions.continent` (domyślnie `europe`) |
| 5→6 | `app_preference_entries` |
| 6→7 | `activity_days`, `awarded_medals`; poziomy mapy `mapEasy`/`mapVeryEasy`, stary `map` = normalny |
| 7→8 | indeksy historii (bez zmian danych) |
| 8→9 | `streak_saves` (żetony Nieprzykunowanie); kopia z v8 wczytuje się bez tej tabeli |

`test/database_migration_test.dart` otwiera prawdziwe pliki schematu 1 i 2
i sprawdza przejście do bieżącej wersji.

## Paczki

`assets/content/` (katalogi, stolice, ciekawostki; podkatalog na kontynent spoza Europy, np. `oceania/`),
`assets/maps/*.geojson`, `assets/maps/styles/relief/`, `assets/flags/*-0.1.0/`.
Manifesty SHA-256 paczek są niezależne od wersji schematu. Komponenty bazy
Web (`web/sqlite3.wasm`, `web/drift_worker.dart.js`) pochodzą z
[wydania Drift 2.35.4](https://github.com/simolus3/drift/releases/tag/drift-2.35.4)
i aktualizuje się je razem z Drift.
