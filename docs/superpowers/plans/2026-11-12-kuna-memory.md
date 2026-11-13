# Pamięć Kuny — pierwszy przyrost

Cel: osobne karty lokalizacji i trzech formatów stolic; terminy FSRS offline,
krótka dzisiejsza wyprawa i zachowanie ręcznego treningu. Android-first UI
sprawdzamy w Chrome na telefonicznym viewportcie, bez emulatora.

## Krótki brainstorming i decyzja

1. Sama kolejka błędów byłaby prosta, ale nie zapewnia terminów zapamiętywania.
2. Pełna przebudowa nauki i statystyk byłaby zbyt szeroka.
3. Wybrany przyrost: adapter istniejącego pakietu `fsrs`, karty i logi w Drift,
   dzisiejsza kolejka oraz niewielkie rozszerzenie obecnego ekranu sesji.

Użytkownik zatwierdził zakres i polecił implementację; dalsze pytania nie są
potrzebne do poniższych decyzji. Źródło API: https://pub.dev/packages/fsrs

## Kontrakt edukacyjny

- 204 niezależne karty: 51 krajów × mapa / A–D / pierwsza litera / pełne wpisanie.
- Klucz `topic:countryId:difficulty`, np. `capitals:POL:write` i `map:POL:map`.
- Zła odpowiedź → Again; poprawna, również z zaakceptowaną literówką → Good.
  Nie wnioskujemy Hard/Easy z czasu. Ręczna zmiana pewności jest poza tym przyrostem.
- Poprawne ćwiczenie przed terminem nie wydłuża interwału; błędne może uruchomić
  ponowną naukę. Historia prób pozostaje zachowana w obu przypadkach.
- Stara historia jest importowana raz, chronologicznie, z zachowaniem formatów;
  nie uznajemy dawnych A–D za dowód pełnego przypominania.
- Wyprawa: zaległe najpierw, do 10 pytań, najwyżej 3 nowe dziennie lokalnego dnia.
  Przy >=10 zaległych kartach nie dodajemy nowości. Jeden kraj najwyżej raz
  w sesji, aby formaty tego samego faktu nie zdradzały kolejnej odpowiedzi.
- Sesja może być krótsza niż 10 pytań. Bez kart do nauki wyjaśniamy, kiedy wrócić;
  ręczny trening nadal dostępny. Każdy termin FSRS przechowujemy w UTC.
- Zapis próby, stanu FSRS i logu jest jedną transakcją. Wznowienie zachowuje pytania.

## Podział pracy i plików

Sol: pubspec/lock, core/database, memory.dart, session_repository.dart, providers.dart,
routing w app.dart, migracje i dokumentacja. Luna: home_screen.dart, learning_screen.dart,
przegląd UI/UX Pro Max i kontrola mobilnego UI w Chrome. Terra: testy pamięci,
kolejki, idempotencji i migracji w osobnych plikach testowych.

## API dla UI i testów

- `SessionRepository(db, {DateTime Function()? clock})` pozostaje zgodny z poprzednim.
- `memoryOverview(Catalog, CapitalCatalog) -> Future<MemoryOverview>`:
  `dueCount`, `newAvailable`, `newRemainingToday`, `reviewedToday`, `nextDue`,
  `plannedCount`, `plannedNewCount`, `activeSession` (LearningSession?).
- `startDaily(Catalog, CapitalCatalog) -> Future<LearningSession?>`: null, gdy brak kart.
- `LearningSession.isDaily`, `isCapitalAt(int)`, `difficultyAt(int)`,
  `capitalQuestionAt(int)`; bieżące isCapital/difficulty/capitalQuestion działają
  także w mieszanej sesji dziennej. Attempt.topic/difficulty nadal opisują realny format.
- `dailyOverviewProvider` udostępnia Future<MemoryOverview>, aktualizowany po zapisach
  oraz co minutę tylko gdy jest obserwowany. `/daily` otwiera LearningScreen(daily: true).
- `MemoryScheduler.review({required String skillId, String? previousState,
  required bool correct, required DateTime now}) -> ScheduledMemory`:
  `state` (JSON), `due`, `rating` (1 lub 3), `reviewLog` (JSON).
- Logi mają klucz sesja+pytanie; zapamiętują origin/manual/daily, wasNew i applied.

## Weryfikacja

- [x] Adapter FSRS: Again/Good, round-trip, terminy i kontrolowany zegar.
- [x] Oddzielność czterech umiejętności, idempotentny zapis, import starej historii.
- [x] Zaległe przed nowymi, dzienny limit, brak powtórzenia kraju i wznowienie.
- [x] Migracje v1/v2 → v3 zachowują dane i umożliwiają nową sesję.
- [x] Telefoniczny ekran Dziś: jedno główne działanie, liczby rzeczywiste,
      ręczny trening wtórny; domknięcie mieszanej sesji i powrót.
- [x] Analyze, testy, walidatory danych i build Web; jeden przegląd Chrome.
