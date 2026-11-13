# Model danych — 0.4

Schemat SQLite w wersji 4. Stabilne identyfikatory państw nie uległy zmianie.

`sessions`: id (UUID), country_ids (JSON, ustalona kolejność), current_index,
created_at, completed_at (nullable), topic (`map` / `capitals` / `flags` / `daily`), difficulty
(`map` / `choice` / `firstLetter` / `write`), question_data (JSON), content_version.

`attempts`: session_id + question_index (złożony klucz główny), country_id,
answer, correct, answered_at, typo_accepted, topic, difficulty.
Dla mapy `answer` jest identyfikatorem wybranego państwa; dla stolic jest
złożoną odpowiedzią tekstową (w średnim trybie zawiera też zadaną literę).

Zapis odpowiedzi nie przesuwa pytania. Osobna operacja „Dalej” przesuwa
indeks i kończy sesję po ostatniej odpowiedzi. Restart odtwarza informację zwrotną.
Tworzenie/wznowienie i zapis odbywają się transakcyjnie. Jedna aktywna sesja
mapowa oraz po jednej dla każdego poziomu stolic i flag. Rozmiar sesji domyślnie 10.

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

## Ręczne zakończenie quizu

`completed_at` oznacza zamknięcie sesji, również przed ostatnim pytaniem.
Operacja `finish(id)` jest transakcyjna i idempotentna. Nie ocenia niewysłanej
odpowiedzi tekstowej ani pytań bez kliknięcia. Rozpoczęte błędne pytanie mapowe
zamyka jako błąd w `attempts`, bez ponownej oceny FSRS. Częściowe podsumowanie
opiera wynik na liczbie zatwierdzonych prób i podaje ją względem rozmiaru serii.
Zwykłe wyjście Wstecz pozostawia sesję do wznowienia; jawne zakończenie ją zamyka.

## Dostępne ćwiczenie z pomocą

Pomoc nie wymaga osobnej zmiany schematu. `memory_reviews.origin='assisted'` i `applied=false`
zachowują pochodzenie potwierdzonej próby; `LearningSession.assistedIndices`
odtwarza oznaczenia przy wznowieniu. Taki wpis nie zmienia stanu karty, liczby
ocenionych przeglądów ani terminu FSRS. Postępy uwzględniają wyłącznie wpisy
`applied=true`; historia prób nadal zawiera wybór użytkownika.

## Migracja 3 → 4 i trzy próby mapy

`map_guesses`: session_id + question_index + guess_index jako klucz,
selected_country_id, correct, assisted, guessed_at. Kliknięcie jest jawną
odpowiedzią; transakcja pierwszego kliknięcia zapisuje próbę i dziennik FSRS.
Druga/trzecia próba nie tworzą dodatkowego przeglądu. `attempts` zachowuje wynik
pytania po trafieniu, trzecim błędzie lub ręcznym zakończeniu rozpoczętego pytania.
Powtórne wysłanie tego samego indeksu nie konsumuje szansy. Stare próby i sesje
pozostają zgodne; migracja dodaje tylko tabelę.

`topic=flags`: difficulty choice/firstLetter/write/map. Migawka zawiera nazwę
państwa, wariant grafiki i SHA, ścieżkę assetu w wersjonowanym katalogu oraz opcje.
Nowe liczbowe ID FSRS flag są w oddzielnej przestrzeni od istniejących kart;
liczby i stany starych kart nie są zmieniane.
