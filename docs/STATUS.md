# Stan implementacji — Europa 0.4 — 2026-11-13

## Wdrożone

- Mapa i atlas 51 państw w edukacyjnym zakresie Europy; lokalna geometria,
  odmiana „leży/leżą”, łagodne przybliżenie regionu i znaczniki mikropaństw.
- Kadrowanie quizu ma stabilne losowe przesunięcie względem celu. Mapa zajmuje
  obszar pod paskiem aplikacji; pytanie pozostaje krótką nakładką.
- Mapa: do trzech różnych wyborów bez „Potwierdź”. Po błędzie 1/2 zostaje
  licznik szans; rozwiązanie pojawia się po trafieniu lub trzecim błędzie.
  Woda, zoom klastra i ponowienie tego samego wyboru nie zużywają szansy.
- Stolice 51 państw ze źródłami KSNG 2025: A–D, pierwsza litera, pełne pisanie.
  Duża nazwa państwa i krótkie „Stolica?”; jawne wyjątki dla nietypowych stolic.
- Flagi 51 państw: A–D, pierwsza litera, pełne pisanie oraz flaga → mapa.
  Lokalne PNG w oryginalnych proporcjach, źródła i manifest SHA-256.
- Jedna literówka w trybach pisanych. Feedback: błąd czerwony, rozwiązanie
  zielone, literówka żółta; tekst i ikony uzupełniają kolor.
- **Pamięć Kuny:** 408 niezależnych kart, adapter `fsrs` 2.0.1, Again/Good.
  Pierwsza próba mapy ocenia pamięć raz; późniejsze trafienie jest ćwiczeniem.
  Sukces rozpoznawania nie aktualizuje karty samodzielnego przypominania.
- Dziś: liczba powtórek, rozpoczęcie/wznowienie, spokojny stan bez pytań
  i najbliższy termin. Do 10 pytań: zaległe najpierw, do 3 nowych kart na
  lokalny dzień w dziennych wyprawach, bez powtarzania kraju w jednej serii.
  Ręczny trening mapy, stolic i flag pozostaje dostępny.
- Atlas: wyszukiwarka bez wymogu polskich znaków, nazwane wiersze min. 56 dp.
  Postępy: osiem formatów osobno, filtry, wyszukiwanie i trzy stany wiedzy.
- Quiz mapy obsługuje klawiaturę i nazwany wybór z pomocą. Pomoc ma jawne
  oznaczenie i nie aktualizuje FSRS. Nie jest równoważnym testem przestrzennym.
- Błąd/ładowanie Dziś nie ukrywa nawigacji. Szczegóły literówek pod pomocą.
- „Zakończ quiz” zachowuje zapisane próby i pokazuje częściowy wynik.
  Pytania bez odpowiedzi nie są błędami; Wstecz pozwala wznowić serię.
- SQLite v4: migracje v1/v2/v3 zachowują próby i aktywne sesje. Idempotentne
  transakcje, jednorazowy import historii, migawki pytań stolic/flag i opcji,
  trwałe częściowe próby mapy. Geometria mapy pozostaje z bieżącej paczki.
- Wybrana maskotka: kuna z globusem (wariant 1).

## Weryfikacja

- `dart format --output=none --set-exit-if-changed lib test`: 44 pliki, bez zmian.
- `flutter analyze`: bez uwag.
- `flutter test`: **58 testów zaliczonych**. FSRS, niezależność formatów,
  idempotencja, import, wczesne odpowiedzi, dzienny limit, kolejka, wznowienie,
  migracje v1/v2/v3, trzy próby mapy, pomoc, flagi i przepływy widgetów.
- Trzy walidatory offline: 51 państw, 51 stolic i 51 flag; sumy, metadane,
  źródła i kompletność paczek poprawne.
- Chrome debug 390×844: atlas z wyszukiwaniem, niezależne postępy, pomoc,
  zakończenie quizu, wszystkie cztery formaty flag, czerwony/zielony feedback,
  trzy błędne wybory i ujawnienie celu dopiero na końcu, żółta literówka stolicy.
  Setup flag także 320×640; wcześniejszy audyt Dziś obejmował 800×900.
- Testy widgetów przy 320×640 i tekście 200%: Dziś, Postępy oraz pisanie nazwy
  państwa; przyciski dostępne po przewinięciu, bez wyjątków układu.
- Dart MCP: połączenie DTD i hot reload udane. Jedna sesja Chrome zakończona
  po kontroli. Zrzuty w `/tmp/geokuna-flags-ux/` i wcześniejszych katalogach
  audytu są artefaktami tymczasowymi, poza repozytorium.
- Wcześniejszy build Web bez CDN zakończył się sukcesem; bieżący przyrost
  sprawdzono przez `flutter run -d chrome`, bez ponownego builda release.

## Ograniczenia i dalsze prace

Flutter 3.50.0 / Dart 3.14.0. Chrome jest środowiskiem bieżącego rozwoju.
Przy zmianie viewportu przez CDP silnik Web zgłosił `_viewInsets.isNonNegative`;
dalsze przepływy działały. Nie traktujemy tego jako weryfikacji klawiatury
Androida. Nie instalowano Android SDK/JDK ani emulatora, nie sprawdzono APK.
Gesty, systemowe Wstecz, TalkBack, cykl życia, SQLite i płynność wymagają później
fizycznego telefonu. Web i Android mają oddzielne bazy; bez PWA nie zakładamy
ponownego uruchomienia Web offline.

FSRS planuje terminy, lecz testy nie dowodzą retencji przez miesiące. Nadal
planowane: opcjonalna diagnoza, eksport/import postępu, wybór zakresu,
odwrotny quiz państwo → flaga, Polska i kolejne kontynenty, waluty i języki.
Nie wdrożono personalizacji parametrów FSRS ani powiadomień.

Repozytorium: prywatne [mdanielak/GeoKuna](https://github.com/mdanielak/GeoKuna),
gałąź `main`. Uruchamianie i przyszłe ADB Wireless: [RUNNING.md](RUNNING.md).
Zasady nauki: [MEMORY.md](MEMORY.md). Źródła flag: [FLAGS.md](FLAGS.md).
Kolejność prac: [NEXT_STEPS.md](NEXT_STEPS.md) i [BACKLOG.md](BACKLOG.md).
Przeglądy: [CODE_REVIEW.md](CODE_REVIEW.md), [UI_UX_REVIEW.md](UI_UX_REVIEW.md).
Plany: [LEARNING_REVIEW.md](LEARNING_REVIEW.md),
[EXPANSION_ROADMAP.md](EXPANSION_ROADMAP.md).
