# GeoKuna — kontekst dla Claude Code

Zasady produktu i weryfikacji: `AGENTS.md` (wczytywany automatycznie). Jego role
Sol/Luna/Terra/Astra, modele GPT i skille `dart-flutter:*` dotyczą Codexa — Claude pracuje
sam; subagenci tylko na prośbę użytkownika. Odpowiadaj po polsku.
Testy i dokumentację utrzymuj zwięzłe: rozbudowuj istniejące `docs/*.md`, historia w `docs/archive/`.

## Komendy
- `export PATH="$HOME/.local/share/geokuna/flutter/bin:$PATH"` — SDK nie jest w PATH (Flutter 3.50)
- `flutter test 2>&1 | grep -E "^\s+/home.*_test.dart: |All tests passed" | sort -u` — wszystkie porażki (`tail -1` pokazuje tylko ostatnią)
- `for s in map capitals flags africa asia relief trivia context; do python3 tools/data_pipeline/build_$s.py --check; done`
- `for r in north_america south_america oceania; do python3 tools/data_pipeline/build_region.py $r --check; done; for r in poland usa; do python3 tools/data_pipeline/build_subdivisions.py $r --check; done; python3 tools/data_pipeline/build_relief_hd.py --check`
- `dart run build_runner build` — po zmianie tabel; `database.g.dart` jest w repo
- `/shots` — zrzuty kluczowych ekranów do przeglądu wyglądu (skill w `.claude/skills/shots/`)

## Kluczowe pliki
- `lib/features/learning/memory.dart` — adapter FSRS (oceny, Easy/Hard, limit 60 dni), `recoveringSkills`
- `lib/features/learning/session_repository.dart` — sesje i odpowiedzi, powtórki w serii, ręczny dobór
- `lib/features/learning/daily_planner.dart` — `plan` Dziś (regular/extra/placement), drabinka, mylone pary, stałe serii
- `lib/features/learning/quiz_controller.dart` — otwarcie/odpowiedź/koniec serii; drogie widoki (plan, medale) odświeża dopiero na końcu serii
- `lib/features/learning/achievements.dart` — zaliczenia i medale; `streaks.dart` — passa
- `lib/app/theme.dart` — tokeny: role Material + `GeoColors` (nie wpisuj `Color(0x…)` w UI; mapy: `map_style.dart`)
- `lib/features/atlas/country_map.dart` + `quiz_map_frame.dart` — mapa quizu, kadr łatwych poziomów
- `test/adaptive_learning_test.dart` — symulacja ucznia; pierwszy test do uruchomienia po zmianie reguł

## Pułapki
- Testy widgetów: Drift i assety wymagają `tester.runAsync`; po `ensureVisible` wywołaj `pumpAndSettle`
- `pumpAndSettle` wisi przy `CircularProgressIndicator` — użyj pętli `pump(Duration)`
- Provider widoczny na Dziś nie może wczytywać assetów sam (`Catalog.load`) — użyj
  `catalogProvider`; inaczej transakcja Drift blokuje bazę i testy przepływów wiszą
  (`dart_test.yaml` przerywa test po 60 s)
- Dziś ma dwa Scrollable (rząd kontynentów) — `scrollUntilVisible(..., scrollable: find.byType(Scrollable).first)`
- W `session_repository.dart` i `daily_planner.dart` `min` z Drift przesłania `dart:math` — używaj porównania
- Kadr quizu stosuj po `initialCameraFit` (post-frame po `onMapReady`)
- Zmiana reguł harmonogramu przesuwa terminy w testach — szukaj `Duration(days:` w `test/`
- Wielokąt flutter_map szerszy niż 180° długości jest „rozwijany” jak przez antypołudnik — dziel na pasy (`_outsideWindow`)
- Zrzuty z kafelkami rzeźby: najpierw `precacheImage` kafelków w `runAsync` i większy `imageCache`, inaczej mapa pusta
- Hook po edycji formatuje pliki `.dart` (`.claude/hooks/dart-format.sh`)

## Skille zewnętrzne (`.claude/skills/`)
14 oficjalnych z `flutter/skills` @e5a88d2 (BSD, `LICENSE-flutter-skills`) i `flutter-ui` z
`Naimehossein77/claude-flutter-ui-skills` @da647c4 (MIT). Kopie, nie submoduły; aktualizacja =
ponowne skopiowanie. Zasady projektu mają pierwszeństwo: offline (bez `http`), zwięzłe testy
(skille testowe proponują więcej), kolory jako tokeny dopiero w etapie motywu.

## Zrzuty ekranu bez Chrome
Skill `/shots`: test złoty w scratchpadzie z `--update-goldens`; fonty Roboto i MaterialIcons
z `$SDK/bin/cache/artifacts/material_fonts/`. Zrzutów nie dodawaj do repozytorium.
