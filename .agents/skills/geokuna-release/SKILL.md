---
name: geokuna-release
description: "Wydawanie i wdrażanie GeoKuny: bramka testów i analizy, podbicie wersji (pubspec.yaml + version.dart), scalenie do main, budowa Web PWA (--web-content-hash) i wdrożenie na gh-pages przez tymczasowy worktree oraz checklista Androida. Używaj przy release, wdrożeniu na GitHub Pages lub przygotowaniu nowej wersji."
---

# GeoKuna Release

Przeprowadzaj wydania i wdrożenia GeoKuny powtarzalnie i bez utraty danych roboczych.
Przeczytaj `AGENTS.md` oraz `docs/DEVELOPMENT.md` przed rozpoczęciem.

## 1. Zasady bezpieczeństwa

- Commity, tagi `vX.Y.Z` i `git push` wykonuj **wyłącznie** na wyraźne polecenie użytkownika.
- Bez `--force` / `--force-with-lease` na `main` i `gh-pages`, bez destrukcyjnego czyszczenia historii.
- Nie instaluj ani nie uruchamiaj emulatora Androida / AVD; klucze podpisywania APK/AAB pozostają zawsze poza repozytorium.
- Wydanie buduj wyłącznie z czystego stanu na `main` (lub gałęzi scalanej fast-forward do `main`).

## 2. Bramka przed wydaniem

Zawsze przed commitem wydania lub wdrożeniem uruchom:

```bash
export PATH="$HOME/.local/share/geokuna/flutter/bin:$PATH"
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

- Jeśli zmieniano tabele Drift (`lib/core/database/database.dart`): wygeneruj `database.g.dart` (`dart run build_runner build --delete-conflicting-outputs`), sprawdź eksport/import w `lib/features/settings/progress_backup.dart` oraz `test/database_migration_test.dart`.
- Jeśli zmieniano `assets/` lub `tools/data_pipeline/`: uruchom walidatory:

```bash
for s in map capitals capitals_en flags africa asia relief trivia context; do
  python3 tools/data_pipeline/build_$s.py --check
done
for r in north_america south_america oceania; do
  python3 tools/data_pipeline/build_region.py $r --check
done
for r in poland usa; do
  python3 tools/data_pipeline/build_subdivisions.py $r --check
  python3 tools/data_pipeline/build_subdivision_symbols.py $r --check
done
python3 tools/data_pipeline/build_relief_hd.py --check
python3 tools/build_icons.py --check
```

## 3. Podbicie wersji (gdy wydajesz nową wersję)

- Zaktualizuj `version: X.Y.Z+B` w `pubspec.yaml` oraz `appVersion` / `appBuild` w `lib/app/version.dart` (`test/version_test.dart` pilnuje zgodności).
- `MINOR` = większy przyrost funkcji, `PATCH` = poprawki, `BUILD` rośnie przy każdym wydaniu (Android odrzuca APK z niższym lub równym `versionCode`).
- Zaktualizuj `docs/ROADMAP.md` (nagłówek wersji i listę wdrożonych zmian).
- Opcjonalny tag: `git tag vX.Y.Z` na docelowym commicie `main` (wypchnij tylko na polecenie).

## 4. Scalenie i push na `main`

1. Sprawdź `git status --short` — upewnij się, że nie trafiają pliki tymczasowe ani zrzuty.
2. Zacommituj zmiany na gałęzi roboczej, następnie scal do `main` i wypchnij:

```bash
git checkout main
git merge --ff-only <branch>
git push origin main
```

## 5. Build i wdrożenie Web PWA na `gh-pages`

Zbuduj paczkę produkcyjną z `main` (`--web-content-hash` jest obowiązkowe przeciw staremu cache'owi PWA, zwłaszcza na iOS):

```bash
flutter build web --release --no-web-resources-cdn --web-content-hash --base-href /GeoKuna/
```

Zweryfikuj paczkę przed publikacją:

```bash
grep -q 'base href="/GeoKuna/"' build/web/index.html
grep -q 'https://brodacz.goatcounter.com/count' build/web/index.html
test -f build/web/precache_manifest.json
test -f build/web/sqlite3.wasm
test -f build/web/drift_worker.dart.js
test -f build/web/sw.js
```

Wdróż zawartość `build/web/` na `gh-pages` przez tymczasowy `git worktree` (bez ruszania katalogu roboczego `main`):

```bash
MAIN_SHA=$(git rev-parse --short main)
WT=$(mktemp -d)
(
  git worktree add "$WT" gh-pages &&
  git -C "$WT" rm -rf . &&
  cp -a build/web/. "$WT"/ &&
  touch "$WT/.nojekyll" &&
  git -C "$WT" add -A &&
  git -C "$WT" commit -m "deploy: GeoKuna PWA on GitHub Pages (<krótki opis>) — main $MAIN_SHA" &&
  git -C "$WT" push origin gh-pages &&
  git worktree remove "$WT"
) || { git worktree remove --force "$WT" 2>/dev/null || rm -rf "$WT"; exit 1; }
```

Po wdrożeniu zainstalowaną PWA (szczególnie iOS) warto zamknąć i uruchomić ponownie (czasem dwukrotnie), aby service worker podmienił wersję.

## 6. Wydanie Androida (później / na żądanie)

Przed publikacją APK/AAB sprawdź na fizycznym telefonie z Androidem:
- start i pełna sesja w trybie samolotowym (Android nie ma uprawnienia `INTERNET` w `AndroidManifest.xml`);
- klawiatura ekranowa i gest/przycisk Wstecz;
- czytelność i kontrast pasków systemowych (`GeoTheme.systemOverlayStyle`);
- TalkBack i cele dotyku min. 48×48 dp;
- płynność mapy z rzeźbą terenu oraz trwałość lokalnej bazy SQLite po restarcie i aktualizacji.

Podpisuj wydanie kluczami przechowywanymi poza repozytorium.

## 7. Raport po wydaniu

Podaj:
- dokładne SHA commitów na `main` i `gh-pages` (oraz ewentualny tag),
- wyniki bramek (`dart format`, `flutter analyze`, `flutter test`, walidatory, kontrola `build/web/`),
- ograniczenia środowiska (np. brak weryfikacji na fizycznym Androidzie).
