# Testowanie GeoKuny

## Domyślne środowisko

Na ThinkPadzie T460s z Linux Mint domyślnie uruchamiaj:

```bash
flutter run -d chrome
```

Flutter Web w Chrome jest środowiskiem bieżącego rozwoju i weryfikacji wizualnej.
Android pozostaje platformą docelową: Material 3, dostępność, cele dotykowe,
klawiatura i obsługa jedną ręką nadal wyznaczają projekt interfejsu.

Nie instaluj ani nie uruchamiaj emulatora Androida, AVD ani obrazów systemu.
Nie instaluj teraz Android SDK/JDK lub dodatkowych narzędzi bez uzasadnionej
potrzeby i uzgodnienia zakresu. Testy na fizycznym Androidzie przeprowadzimy
później, gdy zmiany platformowe lub przygotowanie wydania będą tego wymagały.

## Kto i kiedy sprawdza UI

Luna odpowiada za wygląd ekranów, nawigację, responsywność i interakcje w Chrome.
Sol dobiera zakres i ocenia dowody; Terra wspiera testy funkcjonalne. Astra doradza
tylko przy trudnych decyzjach. Pozostałe role i reguły skilli z AGENTS.md obowiązują.

- Nowy ważny ekran, większa zmiana układu/nawigacji lub błąd wizualny: przejdź
  krótki scenariusz i wykonaj celowane screenshoty dostępnym narzędziem.
- Drobna poprawka bez wpływu na układ: bez obowiązku screenshotu i pełnego przeglądu.
- Sprawdź telefoniczny viewport oraz większy rozmiar/tekst, jeśli dotyczy zmiany.
  Obserwuj także wpisywanie, feedback, powrót i wznowienie — tylko objęte zmianą stany.
- Korzystaj z ukierunkowanych wyszukiwań UX/Flutter w UI/UX Pro Max, zachowując
  zaakceptowaną markę. Nie generuj od nowa design systemu przy każdej kontroli.
- Ogranicz obciążenie: jedna przeglądarka/sesja aplikacji, bez zbędnych procesów,
  pełnych nagrań i wielokrotnego powtarzania tych samych sprawdzeń.
- Jeśli brakuje narzędzia screenshotów, zgłoś ograniczenie; nie instaluj nowego
  tylko po to, by wykonać małą zmianę. Nie dodawaj screenshotów do repo automatycznie.

Raportuj Chrome/viewport, sprawdzone stany, wynik, istotne ograniczenia i w razie
potrzeby lokalizację obrazów. Nie opisuj kontroli w Chrome jako testu Androida.

## Różnice Web ↔ Android

| Obszar | Bieżąca weryfikacja | Późniejsze sprawdzenie na fizycznym Androidzie |
|---|---|---|
| SQLite/Drift | WASM/worker i magazyn przeglądarki; zapis, odświeżenie i migracje. Dane profilu prywatnego mogą znikać, magazyn może mieć limity. Testy natywnego SQLite nadal sprawdzają logikę i migracje. | Natywny plik SQLite, restart procesu aplikacji, aktualizacja i trwałość danych. Magazyny Web i Androida są osobne; nie zakładaj synchronizacji. |
| Gesty | Dotyk emulowany, kliknięcia, pan/zoom, znaczniki i przewijanie. | Rzeczywisty dotyk, wielodotyk, konflikty gestów, systemowy Wstecz. |
| Wydajność | Obserwacja konkretnego problemu; rozróżnij web debug i build web. | Płynność i pamięć na docelowym urządzeniu; web debug nie dowodzi wydajności Androida. |
| Funkcje platformowe | Wspólna logika i jawny fallback dla niedostępnych API. | Klawiatura ekranowa/insets, cykl życia, uprawnienia, pliki i inne użyte API natywne. |
| Offline | Załadowana aplikacja może działać bez sieci. Bez PWA nie zakładaj ponownego otwarcia offline. | Pełny start i sesja w trybie samolotowym. |

Nie dodawaj zależności ani abstrakcji platformowych na zapas. Zapisz konkretne
ryzyko lub odłożony test, gdy zmiana rzeczywiście zależy od platformy.

## Testy automatyczne

`flutter analyze`, właściwe testy jednostkowe/widgetów i integracyjne pozostają
obowiązkowe tam, gdzie mają zastosowanie. Istotny przepływ lub regresja wymaga
odpowiedniego sprawdzenia integracyjnego w obsługiwanym środowisku. Nie instaluj
nowego drivera ani nie uruchamiaj emulatora tylko po to, by spełnić przykład skilla.

W toku pracy uruchamiaj testy związane ze zmianą; pełny zestaw raz przy integracji.
Po samych instrukcjach/TOML/YAML sprawdź składnię, odwołania i spójność reguł;
nie uruchamiaj pełnej aplikacji bez potrzeby. Komendy kontrolne są w AGENTS.md.

Ta polityka zastępuje wcześniejsze wymaganie kontroli wizualnych na emulatorze.
Historyczny zapis rozmowy nie jest aktualną instrukcją uruchamiania narzędzi.

## Kontrola paczek przed commitem

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
python3 tools/data_pipeline/build_map.py --check
python3 tools/data_pipeline/build_capitals.py --check
python3 tools/data_pipeline/build_flags.py --check
```

Walidatory `--check` działają bez sieci i nie odtwarzają paczek. Flagi oraz
źródłowe SVG są lokalne; instrukcja generatora: [FLAGS.md](FLAGS.md).
Po samych zmianach dokumentacji wystarcza kontrola odwołań i spójności.
Przed integracją niezatwierdzonego przyrostu kodu wykonaj pełny zestaw.
