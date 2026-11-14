# Model danych

Schemat SQLite w wersji 7. Stabilne identyfikatory państw nie uległy zmianie.

`sessions`: id (UUID), country_ids (JSON, ustalona kolejność), current_index,
created_at, completed_at (nullable), continent (`europe` / `africa` / `asia`), topic (`map` / `capitals` / `flags` / `daily`), difficulty
(`map` / `mapEasy` / `mapVeryEasy` / `choice` / `firstLetter` / `write` / `mixed`),
question_data (JSON), content_version.

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
reviewed_at, was_new, applied, origin (`daily` / `manual` / `assisted` /
historyczne `recognition`), review_log (JSON).
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

## Migracja 4 → 5 i zakresy

Nowe pole `sessions.continent` ma domyślne `europe`, co zachowuje stare sesje.
Wznowienie i historia są filtrowane regionem; `byId` odrzuca sesję innego regionu.
ID kart FSRS nadal są kanoniczne i nie dostają prefiksu kontynentu.
Historyczne A–D mogło tworzyć dziennik `origin=recognition`, `rating=0`,
`applied=false`. Takie rekordy pozostają w bazie bez dopisywania ocen wstecz.
Nowe rozpoznawanie A–D ma własny harmonogram FSRS, osobny od wpisywania.
Reset: [LEARNING_OVERVIEW.md](LEARNING_OVERVIEW.md).

## Migracja 5 → 6 i preferencje

`app_preference_entries`: klucz/wartość. Klucze `map_appearance` oraz
`difficulty_europe`, `difficulty_africa`, `difficulty_asia`; wartości enumów
serializowane nazwami. Nieznane/brakujące wartości wracają do relief/normal.
Zmiana poziomu kontynentu nie zmienia ustawień innych regionów i nie
przepisuje istniejących sesji. Reset nauki zachowuje tabelę preferencji.

## Migracja 6 → 7, aktywność i medale

`activity_days`: klucz `(continent, local_date)`, czas pierwszej zapisanej
odpowiedzi `recorded_at` (UTC) oraz ówczesny `offset_minutes`. Zapis pierwszej
odpowiedzi i dnia aktywności odbywa się transakcyjnie i idempotentnie.
Liczy się kontynent sesji, także przy wspólnym kraju; historia wcześniejszych dni
nie jest automatycznie wypełniana. Data lokalna nie jest później przeliczana.

`awarded_medals`: klucz `(continent, topic, level, medal)`, `earned_at` i
`catalog_version`; poziomy medali 1/2/3 odpowiadają 50/80/100% zakresu.
Osiągnięcie jest historyczne. Fakty zaliczone na trudniejszym poziomie są
uwzględniane w efektywnym wyniku łatwiejszego bez kopiowania karty FSRS.
Migracja dodaje tabele bez usuwania prób, kart ani preferencji.

Istniejąca normalna mapa zachowuje `difficulty=map` i dawny klucz; dwa nowe
poziomy mapy to `mapEasy` i `mapVeryEasy`. Dla flagi → mapa używa się tych
samych formatów pod `topic=flags`. Migawka pytań i obecne sesje zachowują
rzeczywisty format, a wybór poziomu Dziś filtruje planowane karty.

## Paczka ciekawostek

`assets/content/country_trivia.json` to lokalny katalog po trzy rekordy na każdy
kanoniczny kraj/obszar w Europie, Afryce i Azji. Rekord ma identyfikator, tekst,
adres i tytuł źródła oraz datę weryfikacji. Katalog ma wersję i status. Fakty nie
są kartami pamięci i nie zmieniają ocen FSRS; wybór według seeda sesji i pytania
jest odtwarzalny. Format, źródła i walidacja: [COUNTRY_TRIVIA.md](COUNTRY_TRIVIA.md).
