---
name: shots
description: Render key GeoKuna screens (phone 390x844, small 320x640 with large text) to PNGs in the scratchpad for visual review, without Chrome
disable-model-invocation: true
---

# /shots — zrzuty ekranów GeoKuny

Renderuje ekrany prawdziwym silnikiem Fluttera (test złoty) z fontami Roboto i ikonami
z SDK, na bazie w pamięci. Nie dotyka repozytorium ani danych użytkownika.

## Kroki

1. Skopiuj szablon do scratchpada (nigdy do `test/`):
   ```bash
   OUT="<scratchpad>/shots"; mkdir -p "$OUT"
   cp .claude/skills/shots/shots_test.dart.tmpl "$OUT/shots_test.dart"
   ```
2. Opcjonalnie dopisz w kopii scenariusz dla zmienionego ekranu (wzór: istniejące
   `testWidgets`; stan buduj przez `SessionRepository` w `tester.runAsync`, nawigacja `go(tester, '/ścieżka')`).
3. Uruchom z katalogu projektu (ok. 1–2 min):
   ```bash
   export PATH="$HOME/.local/share/geokuna/flutter/bin:$PATH"
   timeout 600 flutter test --update-goldens "$OUT/shots_test.dart"
   ```
4. Obejrzyj `"$OUT/out/*.png"` narzędziem Read i opisz: viewport, sprawdzone stany, problemy.

## Zasady

- Zrzuty to materiał roboczy — nie dodawaj ich do repozytorium.
- Nie używaj `pumpAndSettle` w scenariuszach (wisi na animacjach ładowania); szablon ma `settle()`.
- To renderer testowy: wierny układ i kolory, ale bez gestów i animacji. Nie zastępuje
  sprawdzenia na telefonie (AGENTS.md).
- Przy porównaniu przed/po zapisz poprzedni katalog `out/` pod inną nazwą.
