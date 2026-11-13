# GeoKuna

**Kuna wie, gdzie!** Aplikacja Android do nauki geografii, po polsku i offline.
Aktualna wersja 0.4: mapa i stolice 51 państw w szerokim zakresie Europy,
trwały zapis sesji w SQLite i kuna z globusem w nagłówku.
Stolice mają trzy poziomy: odpowiedzi A–D, pierwsza litera z dopisywaniem
reszty oraz samodzielne wpisanie całej nazwy. Tryby pisane dopuszczają jedną
literówkę, a poprawna pisownia jest wyświetlana po zatwierdzeniu.
Pytania mapowe zaczynają się od łagodnego przybliżenia regionu. Mapa wypełnia
obszar quizu, a przycisk „Potwierdź” pojawia się po zaznaczeniu państwa.
W stolicach najważniejsza jest duża nazwa państwa i krótkie pytanie „Stolica?”.
Powtórki planuje lokalnie FSRS: osobne karty obejmują mapę oraz trzy formaty stolic. Dzisiejsza wyprawa wybiera najpierw zaległe karty, a ręczny trening pozostaje dostępny.

Repozytorium prywatne: [mdanielak/GeoKuna](https://github.com/mdanielak/GeoKuna).

## Uruchomienie

Szczegółowa instrukcja, w tym późniejszy opcjonalny Android i ADB Wireless: [uruchamianie](docs/RUNNING.md).

Wymagany Flutter 3.50.0 / Dart 3.14 (wersje użyte do weryfikacji).
SDK zainstalowany w tym środowisku: `/home/danim/.local/share/geokuna/flutter`.

```bash
export PATH="$HOME/.local/share/geokuna/flutter/bin:$PATH"
flutter pub get
flutter run -d chrome
```

Flutter Web w Chrome jest domyślnym środowiskiem uruchamiania i kontroli
wizualnej na ThinkPadzie T460s z Linux Mint. Luna sprawdza ekrany i interakcje;
screenshoty są potrzebne przy większych zmianach, nie przy każdej korekcie.
Nie instalujemy ani nie uruchamiamy emulatora Androida. Testy na fizycznym
telefonie i potrzebny do nich toolchain przygotujemy później. Aplikacja nadal
jest projektowana przede wszystkim dla Androida. Zasady: [testowanie](docs/TESTING.md).

Internet jest potrzebny przy pobieraniu narzędzi i zależności. Aplikacja nie pobiera
kafelków, geometrii ani pytań w czasie nauki. Wersja web jest bieżącym środowiskiem rozwoju;
nie zapewnia instalacji/offline po zamknięciu przeglądarki. Dane web i Androida są osobne.

## Weryfikacja

```bash
dart run build_runner build
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
python3 tools/data_pipeline/build_map.py --check
python3 tools/data_pipeline/build_capitals.py --check
flutter build web --no-web-resources-cdn
```

Generowany `database.g.dart` należy do repozytorium. Po zmianie tabel ponów generator.
`flutter test` sprawdza SQLite w pamięci i na dysku, utrwalenie odpowiedzi po zamknięciu
bazy, migrację ze starego schematu, trzy tryby stolic, literówki, sesję 10 pytań
oraz przepływy ekranów na rozmiarze telefonu.

## Dane mapowe

Natural Earth v5.1.2, 1:50m, domena publiczna. Import ma przypiętą sumę źródła:

```bash
python3 tools/data_pipeline/build_map.py
```

Walidacja `--check` nie używa sieci. Szczegóły w [polityce treści](docs/CONTENT_POLICY.md).
Dodatkowe komponenty przeglądarkowej bazy pochodzą z
[wydania Drift 2.35.4](https://github.com/simolus3/drift/releases/tag/drift-2.35.4).
Aktualizuj `web/sqlite3.wasm` i `web/drift_worker.dart.js` razem z Drift.

## Stolice i maskotka

Fakty stolic zweryfikowano względem KSNG 2025. Każdy ma stronę źródła,
status i datę weryfikacji. Odtworzenie paczki: [polityka treści](docs/CONTENT_POLICY.md).
Reguły poziomów i literówek: [stolice](docs/CAPITALS.md).

Wybrano wariant 1: [kuna z globusem](assets/mascot/kuna-globe.png).
Wygenerowano wbudowanym image_gen; oryginały czterech propozycji i dokładne
prompty zachowano w [katalogu wariantów](output/imagegen/kuna-options/PROMPTS.md).

## Dokumentacja

- [Wymagania i kryteria akceptacji](docs/PRD.md)
- [Architektura](docs/ARCHITECTURE.md)
- [Model danych](docs/DATA_MODEL.md)
- [Pamięć Kuny i zasady FSRS](docs/MEMORY.md)
- [Backlog](docs/BACKLOG.md)
- [Stan implementacji i ograniczenia](docs/STATUS.md)
- [Kolejne kroki](docs/NEXT_STEPS.md)
- [Plan kontynentów, flag, Polski i świata](docs/EXPANSION_ROADMAP.md)
- [Diagnoza wiedzy i dobór nauki](docs/LEARNING_REVIEW.md)
- [Audyt użyteczności](docs/UI_UX_REVIEW.md)
- [Przegląd kodu i ograniczenia](docs/CODE_REVIEW.md)

Dalsze prace i odłożoną weryfikację na fizycznym Androidzie opisują [kolejne kroki](docs/NEXT_STEPS.md).
