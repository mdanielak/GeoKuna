# GeoKuna — kontekst dla Claude Code

Zasady produktu i weryfikacji: `AGENTS.md` (wczytywany automatycznie). Jego role
Sol/Luna/Terra/Astra, modele GPT i skille `dart-flutter:*` dotyczą Codexa — Claude pracuje
sam; subagenci tylko na prośbę użytkownika. Odpowiadaj po polsku.
Testy i dokumentację utrzymuj zwięzłe: rozbudowuj istniejące `docs/*.md`, historia w `docs/archive/`.

## Komendy
- `export PATH="$HOME/.local/share/geokuna/flutter/bin:$PATH"` — SDK nie jest w PATH (Flutter 3.50)
- `flutter test 2>&1 | grep -E "^\s+/home.*_test.dart: |All tests passed" | sort -u` — wszystkie porażki (`tail -1` pokazuje tylko ostatnią)
- `for s in map capitals flags africa asia relief trivia; do python3 tools/data_pipeline/build_$s.py --check; done`
- `dart run build_runner build` — po zmianie tabel; `database.g.dart` jest w repo
- `/shots` — zrzuty kluczowych ekranów do przeglądu wyglądu (skill w `.claude/skills/shots/`)

## Kluczowe pliki
- `lib/features/learning/memory.dart` — adapter FSRS (oceny, Easy/Hard, limit 60 dni), `recoveringSkills`
- `lib/features/learning/session_repository.dart` — sesje, `_plan` (tryby Dziś: regular/extra/placement), powtórki w serii, ręczny dobór
- `lib/features/learning/achievements.dart` — zaliczenia i medale; `streaks.dart` — passa
- `lib/features/atlas/country_map.dart` + `quiz_map_frame.dart` — mapa quizu, kadr łatwych poziomów
- `test/adaptive_learning_test.dart` — symulacja ucznia; pierwszy test do uruchomienia po zmianie reguł

## Pułapki
- Testy widgetów: Drift i assety wymagają `tester.runAsync`; po `ensureVisible` wywołaj `pumpAndSettle`
- `pumpAndSettle` wisi przy `CircularProgressIndicator` — użyj pętli `pump(Duration)`
- W `session_repository.dart` `min` z Drift przesłania `dart:math` — używaj porównania
- Kadr quizu stosuj po `initialCameraFit` (post-frame po `onMapReady`)
- Zmiana reguł harmonogramu przesuwa terminy w testach — szukaj `Duration(days:` w `test/`
- Hook po edycji formatuje pliki `.dart` (`.claude/hooks/dart-format.sh`)

## Zrzuty ekranu bez Chrome
Skill `/shots`: test złoty w scratchpadzie z `--update-goldens`; fonty Roboto i MaterialIcons
z `$SDK/bin/cache/artifacts/material_fonts/`. Zrzutów nie dodawaj do repozytorium.
