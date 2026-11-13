# Model danych — 0.4

Schemat SQLite w wersji 3. Stabilne identyfikatory państw nie uległy zmianie.

`sessions`: id (UUID), country_ids (JSON, ustalona kolejność), current_index,
created_at, completed_at (nullable), topic (`map` / `capitals` / `daily`), difficulty
(`map` / `choice` / `firstLetter` / `write`), question_data (JSON), content_version.

`attempts`: session_id + question_index (złożony klucz główny), country_id,
answer, correct, answered_at, typo_accepted, topic, difficulty.
Dla mapy `answer` jest identyfikatorem wybranego państwa; dla stolic jest
złożoną odpowiedzią tekstową (w średnim trybie zawiera też zadaną literę).

Zapis odpowiedzi nie przesuwa pytania. Osobna operacja „Dalej” przesuwa
indeks i kończy sesję po ostatniej odpowiedzi. Restart odtwarza informację zwrotną.
Tworzenie/wznowienie i zapis odbywają się transakcyjnie. Jedna aktywna sesja
mapowa oraz po jednej dla każdego poziomu stolic. Rozmiar sesji domyślnie 10.

`question_data` dla stolic zawiera migawkę faktów, aliasów, pytań, uwag,
stron źródła i opcji odpowiedzi w ustalonej kolejności. Ocenianie rozpoczętej
sesji nie zależy od późniejszych zmian paczki treści.

## Migracja 1 → 2

Dodanie pól sesji i prób z domyślnym `map`; zmiana nazwy
`selected_country_id` na `answer`. Bez usuwania tabel ani rekordów.
Test tworzy prawdziwy plik ze starym schematem, aktywną sesją i odpowiedzią,
otwiera go nową aplikacją, wznawia naukę oraz zapisuje nową próbę i sesję stolic.

## Paczki

- `assets/content/countries.json`: 51 nazw, środki mapy, znaczniki i metadane odmiany.
- `assets/maps/europe.geojson`: geometria o tych samych identyfikatorach.
- `assets/content/capitals.json`: wersja, źródło i 51 zweryfikowanych faktów
  (id, country_id, name, aliases, source_page, verified_at, status, opcjonalne prompt/note).
- Manifesty SHA-256 mapy i stolic są niezależne od wersji schematu bazy.

## Pamięć i migracja 2 → 3

`memory_cards`: id (stabilny klucz umiejętności), country_id, topic, difficulty,
state (JSON FSRS lub null dla nowej karty), due (UTC), introduced_at, review_count.

`memory_reviews`: session_id + question_index (klucz), skill_id, rating,
reviewed_at, was_new, applied, origin (`daily` / `manual`), review_log (JSON).
`memory_meta`: key/value, w tym znacznik jednorazowego importu historii.
Migracja dodaje tabele bez zmiany istniejących prób i sesji. Import historii
następuje przy pierwszym użyciu pamięci, w transakcji i tylko raz.

Jedna aktywna sesja `daily` ma `difficulty=mixed`. Migawka każdego pytania
zawiera topic, difficulty i skill_id; próby zachowują rzeczywisty format.
Szczegóły oceny i budżetu: [MEMORY.md](MEMORY.md).

## Docelowo

regions, country_regions; szerszy katalog facts i answer_aliases;
app_settings. Rozpoznawanie, podpowiedź i samodzielne przypominanie wymagają
niezależnych kart. Nie usuwać historii przy zmianie treści lub algorytmu.
