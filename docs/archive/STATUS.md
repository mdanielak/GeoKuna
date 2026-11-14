# Stan implementacji — Europa, Afryka i Azja — 2026-11-13

## Wdrożone

- Mapa, stolice, flagi i atlas: Europa 51, Afryka 54, Azja 50 krajów/obszarów
  edukacyjnych. Wybór na Dziś, osobne sesje, wspólne karty krajów transkontynentalnych.
  Geometria lokalna,
  odmiana „leży/leżą”, kadry kontynentów i znaczniki mikropaństw.
- Kadr quizu jest niemal pełnym widokiem kontynentu, niezależnym od celu
  pytania; minimalna korekta skali względem atlasu. Bez automatycznego
  przybliżania regionu kraju. Ręczny zoom i klastry mikropaństw zachowane.
- Mapa: do trzech różnych wyborów bez „Potwierdź”. Po błędzie 1/2 zostaje
  licznik szans; rozwiązanie pojawia się po trafieniu lub trzecim błędzie.
  Woda, zoom klastra i ponowienie tego samego wyboru nie zużywają szansy.
- Stolice wszystkich zakresów: Europa ze źródłem KSNG 2025, Afryka i Azja
  z aktualizacją KSNG 2026. Format: A–D, pierwsza litera, pełne pisanie.
  Duża nazwa państwa i krótkie „Stolica?”; jawne wyjątki dla nietypowych stolic.
- Flagi wszystkich trzech zakresów: A–D, pierwsza litera, pełne pisanie oraz flaga → mapa.
  Lokalne PNG w oryginalnych proporcjach, źródła i manifest SHA-256.
- Jedna literówka w trybach pisanych. Feedback: błąd czerwony, rozwiązanie
  zielone, literówka żółta; tekst i ikony uzupełniają kolor.
- **Pamięć Kuny:** sześć ocenianych umiejętności na kraj, adapter `fsrs` 2.0.1,
  Again/Good. A–D to trening bez wyniku wiedzy i bez harmonogramu; domyślny
  sugerowany tryb stolic i flag to pełne wpisywanie.
  Pierwsza próba mapy ocenia pamięć raz; późniejsze trafienie jest ćwiczeniem.
  Sukces rozpoznawania nie aktualizuje karty samodzielnego przypominania.
- Dziś: liczba powtórek, rozpoczęcie/wznowienie, spokojny stan bez pytań
  i najbliższy termin. Do 10 pytań: zaległe najpierw, do 3 nowych kart na
  lokalny dzień w dziennych wyprawach, bez powtarzania kraju w jednej serii.
  Ręczny trening mapy, stolic i flag pozostaje dostępny.
- Atlas: wyszukiwarka bez wymogu polskich znaków, nazwane wiersze min. 56 dp.
  Moja nauka: procent umiejętności na bieżąco, kontynent → kraje → formaty.
  Szczegóły: sześć formatów, filtry, wyszukiwanie i trzy stany nauki.
- Quiz mapy obsługuje przesuwanie/przybliżanie klawiaturą. Wybór kraju z listy
  pomocy usunięto; historyczne oznaczenia wspomaganych prób są zachowane.
- Błąd/ładowanie Dziś nie ukrywa nawigacji. Szczegóły literówek pod pomocą.
- „Zakończ quiz” zachowuje zapisane próby i pokazuje częściowy wynik.
  Pytania bez odpowiedzi nie są błędami; Wstecz pozwala wznowić serię.
- SQLite v6: migracje v1/v2/v3/v4/v5 zachowują próby i aktywne sesje. Idempotentne
  transakcje, jednorazowy import historii, migawki pytań stolic/flag i opcji,
  trwałe częściowe próby mapy. Geometria mapy pozostaje z bieżącej paczki.
- Ustawienia: trzy lokalne style mapy (domyślnie relief), osobny poziom stolic
  i flag dla kontynentów: bardzo łatwy / łatwy / normalny. Preferencje trwałe
  i niezależne od postępu. Reset wybranego kontynentu lub całej nauki: jawne potwierdzenie
  i ostrzeżenie o krajach wspólnych; brak niejawnego odtwarzania skasowanej pamięci.
- Wybrana maskotka: kuna z globusem; pięć emocji w podsumowaniu serii:
  smutna, zamyślona, zachęcająca, wesoła i z serduszkiem tylko za 100%.
  Zachęcająca i wesoła według wariantu 2B. Przerwana seria jest neutralna.
  Progi i wyjątki: [MASCOT_FEEDBACK.md](MASCOT_FEEDBACK.md).

### Weryfikacja pięciu emocji — 2026-11-14

Pełny zestaw: 82 testy poprawne; analiza Dart MCP bez uwag, format 63 pliki
bez zmian, sześć walidatorów danych poprawnych. Sprawdzono wszystkie wyniki
dla 5 i 10 pytań, granice progów, 99,6% bez serduszka oraz układ 320×640
z tekstem 200%. Cztery nowe grafiki RGBA z przezroczystością obejrzano osobno.
Kontrola wizualna w przeglądarce pozostała nieukończona: web debug pokazywał
tylko pasek ładowania, a bezpośrednie uruchomienie Chrome nie połączyło się
z portem debugowania. Nie potwierdzono więc wyglądu nowych grafik w Chrome.
Tymczasowy podgląd usunięto, uruchomione do tej kontroli procesy zatrzymano.

## Weryfikacja

- `dart format --output=none --set-exit-if-changed lib test`: 63 pliki, bez zmian.
- `flutter analyze`: bez uwag.
- `flutter test`: **79 testów zaliczonych**. FSRS, niezależność formatów,
  idempotencja, import, wczesne odpowiedzi, dzienny limit, kolejka, wznowienie,
  migracje v1/v2/v3/v4/v5, trzy próby mapy, pomoc, regionalne kolejki, globalny
  limit/rezerwacje nowych, A–D bez oceny, reset i wskaźnik postępu.
- Sześć walidatorów offline: Europa, Afryka i Azja; sumy, metadane,
  źródła i kompletność paczek poprawne.
- Chrome debug 390×844: atlas z wyszukiwaniem, niezależne postępy, pomoc,
  zakończenie quizu, wszystkie cztery formaty flag, czerwony/zielony feedback,
  trzy błędne wybory i ujawnienie celu dopiero na końcu, żółta literówka stolicy.
  Setup flag także 320×640; wcześniejszy audyt Dziś obejmował 800×900.
- Bieżący Chrome 390×844: przełączenie Europy/Afryki/Azji, atlasy nowych zakresów,
  sugerowane pisanie, lokalne flagi i stolice, Moja nauka, lista krajów,
  ustawienia i anulowanie resetu. 320×640: kontrolki wyboru w całości czytelne.
  Dodatkowo test całego kadru Azji na telefonie i wyboru przy tekście 200%.
- Testy widgetów przy 320×640 i tekście 200%: Dziś, Postępy oraz pisanie nazwy
  państwa; przyciski dostępne po przewinięciu, bez wyjątków układu.
- Dart MCP: połączenie DTD i hot reload udane. Jedna sesja Chrome zakończona
  po kontroli. Zrzuty w `/tmp/geokuna-continents-ux/`, `/tmp/geokuna-flags-ux/` i wcześniejszych katalogach
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
planowane: opcjonalna diagnoza, eksport/import postępu, odwrotny quiz
państwo → flaga, Polska i pozostałe kontynenty, waluty i języki.
Dalszy styl/projekcje mapy: MAP_AND_MASCOT_NEXT.md. Pięć reakcji kuny jest już wdrożonych.
Nowe poziomy nauki, medale i passy pozostają wyłącznie planem:
[LEVELS_MEDALS_STREAKS_PLAN.md](LEVELS_MEDALS_STREAKS_PLAN.md).
Nie wdrożono personalizacji parametrów FSRS ani powiadomień.

Repozytorium: prywatne [mdanielak/GeoKuna](https://github.com/mdanielak/GeoKuna),
gałąź `main`. Uruchamianie i przyszłe ADB Wireless: [RUNNING.md](RUNNING.md).
Zasady nauki: [MEMORY.md](MEMORY.md). Źródła flag: [FLAGS.md](FLAGS.md).
Kolejność prac: [NEXT_STEPS.md](NEXT_STEPS.md) i [BACKLOG.md](BACKLOG.md).
Przeglądy: [CODE_REVIEW.md](CODE_REVIEW.md), [UI_UX_REVIEW.md](UI_UX_REVIEW.md).
Plany: [LEARNING_REVIEW.md](LEARNING_REVIEW.md),
[EXPANSION_ROADMAP.md](EXPANSION_ROADMAP.md).

Przegląd nauki i reset: [LEARNING_OVERVIEW.md](LEARNING_OVERVIEW.md).
Źródła nowych zakresów: [AFRICA.md](AFRICA.md), [ASIA.md](ASIA.md).

Końcowa kontrola bieżącej sesji przez Dart MCP: brak błędów runtime.
Hot reload zastosował zmiany, po nim ponownie otwarto i oceniono końcowy
kadr Azji, etykietę sugerowanego poziomu i wybór regionu na 320 px.

Ostatni przyrost: 75 testów, cztery testy mapy (stały kadr i zoom ręczny),
pięć testów reakcji kuny; format 63 pliki, analiza i pięć walidatorów poprawne.
Chrome 390×844: szeroki quiz mapy, neutralna przerwa, smutna kuna przy 0/10
i wesoła przy 10/10. Artefakty tymczasowe: `/tmp/geokuna-mascots-ux/`.

Przyrost ustawień: trzy style sprawdzone w Chrome 390×844, ustawienia także
320×640; przełączenie poziomu Europy na Bardzo łatwy zachowuje Normalny
w pozostałych regionach i trafia do ekranu stolic. Usunięty przycisk listy
i pusty panel mapy. Migracja v5→v6 zachowuje aktywną naukę; reset zachowuje
preferencje. Lokalny relief 2,58 MB ze źródłem i walidatorem w MAP_STYLES.md.

Końcowa kontrola ustawień: 79 testów, format 63 plików, analiza i sześć
walidatorów. Dart MCP nie zgłosił błędów runtime; po hot reload sprawdzono
quiz z reliefem bez przycisku listy i bez pustego dolnego panelu.
Zrzuty tymczasowe: `/tmp/geokuna-settings-styles/`.
