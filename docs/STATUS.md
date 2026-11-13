# Stan implementacji — Europa 0.4 — 2026-11-13

## Wdrożone

- Mapa i atlas 51 państw w edukacyjnym zakresie Europy; lokalna geometria,
  odmiana „leży/leżą”, łagodne przybliżenie regionu i znaczniki mikropaństw.
- Stolice 51 państw ze źródłami KSNG 2025 i walidatorem. Trzy poziomy:
  A–D, pierwsza litera, pełne wpisanie. Jedna literówka w trybach pisanych.
- Wybrana maskotka: kuna z globusem (wariant 1).
- **Pamięć Kuny:** 204 niezależne karty umiejętności, adapter `fsrs` 2.0.1,
  Again/Good, osobny stan rozpoznawania i przypominania.
- Mobilny quiz mapy: mapa wypełnia obszar ekranu, pytanie w nakładce,
  „Potwierdź” dopiero po wyborze. Stolice: duża nazwa państwa, krótkie „Stolica?”.
- Ekran Dziś: rzeczywiste liczby, główna dzisiejsza wyprawa, wznowienie,
  spokojny stan bez pytań i termin następnej powtórki. Ręczny trening zachowany.
- Seria do 10 pytań: zaległe najpierw, do 3 nowych kart na lokalny dzień
  w dziennych wyprawach; bez powtarzania państwa w jednej serii.
- Transakcyjny zapis odpowiedzi, pamięci i dziennika; idempotencja; wczesny
  poprawny ręczny trening nie wydłuża terminu. Błąd ponownie planuje kartę.
- SQLite v3: migracje v1/v2 zachowują próby i aktywne sesje. Historia jest
  jednorazowo importowana z zachowaniem pierwotnych formatów.
- Migawki pytań/opcji oraz oceniony feedback przetrwają restart.

## Weryfikacja

- `dart format --output=none --set-exit-if-changed lib test`: 26 plików, bez zmian.
- `flutter analyze`: bez uwag.
- `flutter test`: **32 testy pełnego zestawu + test regresji nawigacji zaliczone**. Logika FSRS, niezależne umiejętności,
  idempotencja, import historii, wczesne odpowiedzi, kolejka, dzienny limit,
  wznowienie i migracje v1/v2; mapa i stolice, przepływy widgetów.
- Dziś na 320×640 z tekstem 200%: główny przycisk dostępny po przewinięciu,
  seria uruchamia się, bez wyjątków układu.
- Oba walidatory paczek: 51 państw i 51 faktów, sumy i źródła poprawne.
- `flutter build web --no-web-resources-cdn --no-wasm-dry-run`: sukces.
- Dart MCP po udostępnieniu: połączenie DTD i hot reload UI zakończone sukcesem.
  Przy końcowej zmianie routingu otwarta sesja Chrome przestała odpowiadać;
  weryfikacja końcowego UI korzystała z osobnego krótkiego profilu testowego.
- Chrome 154: audyt 11 kroków na 390×844, Dziś także 320×640/800×900;
  zatwierdzenie mapy, stolice i odświeżenie feedbacku, brak wyjątków JS.
- UI/UX Pro Max: przegląd mobilnej hierarchii i interakcji; konkretne wyniki
  oraz zakres screenshotów opisano w [UI_UX_REVIEW.md](UI_UX_REVIEW.md).

## Środowisko i ograniczenia

Flutter 3.50.0 / Dart 3.14.0. Chrome pozostaje środowiskiem bieżącego rozwoju.
Nie instalowano Android SDK/JDK ani emulatora; nie zbudowano i nie sprawdzono APK.
Fizyczny Android, klawiatura systemowa, gesty, cykl życia i natywna wydajność
wymagają późniejszej weryfikacji. Web i Android mają osobne bazy.
Web bez PWA nie gwarantuje ponownego otwarcia aplikacji offline.

FSRS planuje terminy, ale testy nie dowodzą skuteczności zapamiętywania przez
miesiące. Indywidualna optymalizacja FSRS, postępy, słabe punkty, eksport
oraz flagi/waluty/języki są kolejnymi przyrostami. Zasady: [MEMORY.md](MEMORY.md).

Na jawne polecenie użytkownika przygotowano śledzenie projektu na gałęzi `main`
i prywatne repozytorium [mdanielak/GeoKuna](https://github.com/mdanielak/GeoKuna).
Uruchamianie i przyszłe ADB Wireless: [RUNNING.md](RUNNING.md).
Priorytety: [NEXT_STEPS.md](NEXT_STEPS.md).

Audyt kodu: [CODE_REVIEW.md](CODE_REVIEW.md). Diagnoza i rozszerzenia
pozostają planem: [LEARNING_REVIEW.md](LEARNING_REVIEW.md),
[EXPANSION_ROADMAP.md](EXPANSION_ROADMAP.md).
