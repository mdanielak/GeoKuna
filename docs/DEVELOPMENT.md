# Uruchamianie, testy i środowisko

## Uruchomienie (Chrome)

Flutter 3.50.0 / Dart 3.14. SDK na tym komputerze: `~/.local/share/geokuna/flutter`.

```bash
export PATH="$HOME/.local/share/geokuna/flutter/bin:$PATH"
flutter pub get
flutter run -d chrome                 # opcjonalnie --web-port=8766 dla stałego adresu
```

W `flutter run`: `r` hot reload, `R` restart, `q` koniec. Baza Web należy do
profilu i adresu przeglądarki (inny port = osobny magazyn); nie czyść danych
przeglądarki, jeśli chcesz zachować postęp. Web nie działa offline po zamknięciu
karty (brak PWA). Postęp przenosi się kopią z Ustawień (plik JSON); synchronizacji nie ma.

Po zmianie tabel: `dart run build_runner build` (wynik `database.g.dart` jest w repo).
Ikony Androida i Web: `python3 tools/build_icons.py` (z `assets/mascot/kuna-globe.png`,
Pillow; `--check` sprawdza rozmiary).

## Weryfikacja przed integracją

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
for s in map capitals flags africa asia relief trivia context; do
  python3 tools/data_pipeline/build_$s.py --check
done
for r in north_america south_america oceania; do
  python3 tools/data_pipeline/build_region.py $r --check
done
flutter build web --no-web-resources-cdn   # przy wydaniu
```

W trakcie pracy uruchamiaj testy związane ze zmianą; pełny zestaw raz przy
integracji. `dart_test.yaml` przerywa każdy test po 60 s — zawieszony test
pada z nazwą zamiast blokować przebieg. Po zmianach samej dokumentacji wystarczy kontrola odwołań.

## Zasady testów

Testy mają chronić reguły nauki i dane, nie każdy piksel. Pokrywamy:

- logikę (FSRS, ocena tekstu, kolejka Dziś, limit nowości, medale, passa,
  kadr mapy, kuna) — szybkie testy jednostkowe z kontrolowanym zegarem;
- bazę (idempotencja, wznowienie, reset, migracje z prawdziwych plików starych schematów);
- po jednym przepływie widgetów na kluczowy ekran, na telefonie 390×844
  lub 320×640 z tekstem 200%, gdy zmienia się układ.

Nie dubluj tego, co sprawdzają walidatory Pythona (kompletność paczek, sumy,
pliki PNG). Nie dodawaj testu na usuniętą funkcję ani osobnego testu dla każdego
wariantu, jeśli wspólny kod pokrywa już jeden przypadek.

## Kontrola wizualna

Chrome jest środowiskiem bieżącej kontroli, ale projektujemy dla Androida
(Material 3, cele ≥48 dp, jedna ręka, kontrast, semantyka).

- Nowy ekran, większa zmiana układu lub błąd wizualny: jedna sesja Chrome,
  telefoniczny viewport, stany objęte zmianą, przy layoutach też większa
  szerokość lub tekst 200%. Drobne poprawki nie wymagają zrzutów.
- Raport: viewport, sprawdzone stany, wynik, ograniczenia. Zrzutów nie dodajemy do repo.
- Bez emulatora Androida, AVD i instalacji SDK/JDK bez uzgodnienia.

| Obszar | Chrome sprawdza | Później na fizycznym Androidzie |
|---|---|---|
| SQLite | WASM i magazyn przeglądarki; testy sprawdzają natywną logikę i migracje | natywny plik, restart procesu, aktualizacja |
| Gesty | emulowany dotyk, pan/zoom, znaczniki | wielodotyk, konflikty gestów, Wstecz |
| Wydajność | konkretny objaw (web debug ≠ release) | płynność i pamięć (relief) na urządzeniu |
| Platforma | wspólna logika | klawiatura/insets, cykl życia, TalkBack |
| Offline | załadowana aplikacja | start i sesja w trybie samolotowym |

## Telefon Android (później)

Wymaga uzgodnionego toolchainu (Android SDK, JDK, platform-tools); `flutter doctor -v`
pokaże braki. ADB Wireless (Android 11+), tylko w zaufanej sieci:

```bash
adb pair ADRES_IP:PORT_PAROWANIA      # port i kod z ekranu parowania
adb connect ADRES_IP:PORT_DEBUGOWANIA # port z głównego ekranu debugowania
flutter devices
flutter run -d IDENTYFIKATOR
```

Porty parowania i debugowania różnią się i zmieniają. Po pracy wyłącz debugowanie
bezprzewodowe. Szczegóły: [dokumentacja ADB](https://developer.android.com/tools/adb).

## Wersje

`version:` w `pubspec.yaml` ma postać `MAJOR.MINOR.PATCH+BUILD` i musi zgadzać się
z `lib/app/version.dart` (pilnuje `test/version_test.dart`); Ustawienia → na dole
pokazują wersję aplikacji i paczek treści.

- MINOR — większa paczka funkcji; PATCH — same poprawki;
- BUILD rośnie przy każdym wydaniu (Android odrzuca APK z niższym lub równym numerem);
- wydanie = tag gita `vX.Y.Z` na commicie z podbitą wersją;
- paczki treści (`assets/content/*.json`) mają osobne wersje w polu `version`.

## Agenci i narzędzia

Claude Code: `CLAUDE.md` (komendy, pułapki), Dart MCP w `.mcp.json`, hook formatowania
`.claude/hooks/dart-format.sh`, skille w `.claude/skills/` (`/shots` — zrzuty bez
Chrome; oficjalne `flutter/skills` i `flutter-ui`, źródła w `CLAUDE.md`).

Codex:

Role i delegowanie: `AGENTS.md`, `.codex/agents/*.toml`, `.codex/config.toml`
(limit dwóch wykonawców). Lokalny skill mechanik nauki:
`.agents/skills/geokuna-learning-design/`.

- Dart MCP: `.codex/config.toml` wskazuje absolutne `bin/dart` z SDK powyżej
  (`dart` nie jest w PATH procesu). Na innej maszynie popraw dwie ścieżki SDK.
  Nowa konfiguracja działa dopiero w nowej sesji klienta.
- UI/UX Pro Max ma wskazówki dla Fluttera 3.44 — API sprawdzaj z bieżącym SDK.
  Nie przyjmujemy generowanych design systemów (landing page, zdalne fonty).
- Brak w środowisku: Android SDK, adb, JDK, toolchain Linux desktop (nie instalujemy).
- Commity i push tylko na polecenie użytkownika.
