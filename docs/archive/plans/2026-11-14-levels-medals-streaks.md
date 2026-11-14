# Poziomy nauki, medale, passy i mapa — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Status: zatwierdzony do wdrożenia przez użytkownika, z poprawkami poniżej.

## Wiążące poprawki użytkownika i wykonanie

- A–D ma własny FSRS, postęp i ocenę rozpoznawania, osobno od wpisywania.
- Etykieta błędnego wskazania zawiera wyłącznie nazwę kraju, bez „To:”.
- Trzy wspierające teksty dla każdej emocji, wybierane stabilnie dla sesji.
- Passa widoczna na Dziś dla aktualnie wybranego kontynentu.
- Trzy ciekawostki na kraj, lokalna zweryfikowana paczka; losowana ciekawostka
  po poprawnej odpowiedzi mapowej, zachowana po wznowieniu przez stabilny seed.
- Poniższe wcześniejsze ograniczenia A–D należy czytać z powyższą poprawką.
- Wykonawcy: Sol — baza, harmonogram, poziomy, medale/passy i integracja;
  Luna — mapa i UI; Terra — komplet ciekawostek, loader i walidacja.
- Zachowujemy bieżący wspólny katalog roboczy i istniejące niezatwierdzone
  zmiany; nie przenosimy ich ani nie tworzymy automatycznego commita.

**Goal:** Osobne poziomy z uczciwą historią, dziedziczenie osiągnięć, medale, passy kontynentów i czytelny feedback mapy.

**Architecture:** Zachowujemy istniejące kanoniczne karty i formaty. Dodajemy
poziomy wsparcia mapy, lokalne osiągnięcia i dni aktywności; dziedziczenie jest
obliczaniem widoku, bez kopiowania FSRS. Logika poza widgetami, bez nowych warstw usług.

**Tech Stack:** Flutter, Riverpod, Drift/SQLite, flutter_map; istniejące narzędzia.

**Spec:** [LEVELS_MEDALS_STREAKS_PLAN.md](../../LEVELS_MEDALS_STREAKS_PLAN.md).

## Global Constraints

- Planowanie tylko: progi medali i definicja utrwalenia/pass pozostają propozycją.
- Bez nowych zależności, backendu, instalacji i emulatora; Chrome jest kontrolą wizualną.
- A–D bez oceny wiedzy/FSRS; globalnie najwyżej 3 nowe karty dziennie.
- Historia i FSRS trudniejszego poziomu nigdy nie są kopiowane na łatwiejszy.
- Normalny kadr mapy nie zależy od odpowiedzi; cel ujawniamy po trzecim błędzie.
- Zachować ustawienia niezależnie od resetu oraz obecne pięć progów emocji kuny.
- Sol integruje; Luna realizuje Flutter/UI, Terra dane/testy; pliki bazy mają jednego właściciela.
- Commity i push tylko według polecenia użytkownika, nie automatycznie z tego planu.

## Review Focus

1. Migracja starej mapy na normalny bez zmiany jej ID, historii i terminów.
2. Zaliczenie trudniejsze→łatwiejsze tylko w tej samej kategorii/kierunku, bez podwójnego liczenia.
3. Europa/Azja dzielą pamięć, lecz nie naliczają nawzajem pass.
4. Wznowienie po północy nie losuje kadru i nie duplikuje dni ani medali.
5. Kamera nie ujawnia celu po pierwszym/drugim błędzie; po trzecim odzyskuje go spoza widoku.

## Przyrost 1: poziomy i migracja

**Właściciel:** Sol: kontrakt, Terra: baza/repozytorium; Luna dopiero po integracji.
**Pliki:** `lib/core/database/database.dart` i `.g.dart`,
`lib/features/settings/app_preferences.dart`, `lib/features/learning/session_repository.dart`,
`lib/features/learning/memory.dart`, `lib/features/learning/learning_reset.dart`.
**Nowe:** `lib/features/learning/map_support.dart`, `test/learning_levels_test.dart`;
rozszerzyć `test/database_migration_test.dart`, `test/daily_memory_test.dart`.

**Interfejs:** `MapSupport { veryEasy, easy, normal }`; jawne mapowanie poziomu
na istniejący format/kartę. Normalna mapa zachowuje dawny klucz; nowe poziomy
dostają odrębne klucze. Snapshot pytania zawiera poziom oraz początkowy kadr.

- [ ] Zatwierdzić definicje z projektu, odczytać obecną wersję schematu (obecnie 6), ustalić jednego właściciela migracji.
- [ ] Test RED: stara mapa ma ten sam klucz i FSRS; trzy poziomy nie aktualizują się nawzajem; stara sesja wznawia się jako normalna.
- [ ] Test RED: wybór poziomu nie mnoży limitu 3 nowości; nie zmienia snapshotu; A–D pozostaje nieoceniane.
- [ ] Minimalna migracja i mapowanie bez ponownego importu historii; aktualizacja generatora istniejącym narzędziem projektu.
- [ ] Testy GREEN: `flutter test test/learning_levels_test.dart test/database_migration_test.dart test/daily_memory_test.dart`.
- [ ] Dodać wybór poziomu na Dziś, filtrowanie kart według specyfikacji i test wznowienia po zmianie preferencji; Luna jest właścicielem `home_screen.dart` i ekranów setup.

## Przyrost 2: mapa i feedback

**Właściciel:** Luna: `lib/features/atlas/country_map.dart`,
`lib/features/learning/learning_screen.dart`; Terra: testy po ustaleniu interfejsu.
**Nowe:** `lib/features/atlas/quiz_map_frame.dart`, `test/quiz_map_frame_test.dart`.
Rozszerzyć `test/map_guesses_flow_test.dart`, `test/country_map_test.dart`.

**Interfejs:** `QuizMapFrame` przechowuje środek i zoom w snapshotcie pytania;
czysta funkcja wylicza kadr z poziomu, geometrii i utrwalonego losowania.
CountryMap otrzymuje gotowy kadr i osobny jednorazowy sygnał ujawnienia rozwiązania.
Nie używać atlasowego `focusId` jako podpowiedzi w pierwszych dwóch próbach.

- [ ] Test RED: zoom +0,35/+0,15/0; przesunięcia 20%/10%/0 i limit odchyłu 4%/2%/0; cel z marginesem oraz Azja przy 180°.
- [ ] Test RED: ponowne otwarcie pytania odtwarza kadr; zmiana stylu nie cofa ręcznej kamery.
- [ ] Test RED: pierwszy/drugi błąd pokazuje nazwę wybranego kraju, bez nazwy celu i bez przesunięcia na cel.
- [ ] Test RED: trzeci błąd spoza aktualnego widoku pokazuje rozwiązanie i dopasowuje kamerę raz; ręczny ruch po ujawnieniu działa.
- [ ] Implementacja etykiet, semantyki i kamery z ograniczeniem zoomu mikropaństw oraz obsługą ograniczenia animacji.
- [ ] Testy GREEN: `flutter test test/quiz_map_frame_test.dart test/map_guesses_flow_test.dart test/country_map_test.dart`.
- [ ] Jedna sesja Chrome: Europa/Afryka/Azja, 390×844 i mały ekran/tekst 200%; UI/UX Pro Max, screenshoty, bez pełnego zbędnego audytu.

## Przyrost 3: zaliczenia i medale

**Właściciel:** Sol: mechanika; Terra: `lib/features/learning/achievements.dart`
(nowy), tabele osiągnięć i testy; Luna: `lib/features/progress/learning_overview_screen.dart`
i podsumowanie w `learning_screen.dart`, po zwolnieniu wspólnych plików.
**Testy:** nowe `test/achievements_test.dart`; rozszerzyć `test/learning_reset_test.dart`.

**Interfejs:** agregat identyfikowany przez kontynent/kategorię/kierunek/poziom;
osobne zbiory faktów zaliczonych bezpośrednio i przez trudniejszy poziom,
data uzyskania i wersja katalogu przy przyznaniu medalu. FSRS pozostaje źródłem
rzeczywistych powtórek, nie magazynem fikcyjnych awansów.

- [ ] Test RED: 2 pierwsze trafienia, różne dni, >=24 h, druga próba po terminie; pośredni błąd zeruje serię kwalifikującą.
- [ ] Test RED: A–D nalicza wyłącznie rozpoznawanie; nie dopisuje FSRS ani wyniku wiedzy.
- [ ] Test RED: 50/80/100% pełnego katalogu, 99,6% bez złota; mapa nie zalicza stolic/flag; normalny zalicza niższe poziomy.
- [ ] Test RED: brak sumowania tego samego faktu, idempotentny medal, zwykły błąd nie odbiera zdobytego medalu, aktualizacja katalogu zachowuje jego wersję.
- [ ] Test RED: reset zakresu usuwa odpowiednie osiągnięcia, pozostawia preferencje; wspólne karty traktowane zgodnie z obecnym ostrzeżeniem resetu.
- [ ] Minimalny agregator i transakcyjne przyznanie; widok odróżnia medal od bieżących powtórek i etykietuje dziedziczenie.
- [ ] Testy GREEN: `flutter test test/achievements_test.dart test/learning_reset_test.dart`; kontrola Chrome widoku kontynent→kategoria→poziom.

## Przyrost 4: passy i integracja

**Właściciel:** Terra: `lib/features/learning/streaks.dart` (nowy), transakcja
zapisu próby i baza; Luna: mały wskaźnik w `home_screen.dart` i podsumowaniu.
**Testy:** nowe `test/streaks_test.dart`; rozszerzyć testy resetu.

**Interfejs:** dzienny wpis aktywności unikalny dla `(continent, localDate)`;
czas UTC i offset pochodzą z zapisu pierwszej odpowiedzi, nie startu sesji.
Odczyt wylicza aktualną/najdłuższą serię z zapisanych dat bez zmiany ich strefy.

- [ ] Test RED: jedna odpowiedź niezależnie od poprawności/A–D zalicza dzień, samo otwarcie i kolejne strzały nie powielają go.
- [ ] Test RED: wznowienie i powtórny zapis idempotentne, północ/DST/zmiana strefy, dzień przerwy, dzisiaj przed pierwszą odpowiedzią.
- [ ] Test RED: Turcja w Europie zwiększa tylko passę Europy; regionalny reset nie usuwa passy Azji.
- [ ] Implementacja lokalnych dni w tej samej transakcji co próba, bez odtwarzania historycznych pass i bez zdalnego zegara.
- [ ] Testy GREEN: `flutter test test/streaks_test.dart test/learning_reset_test.dart`.
- [ ] Aktualizacja MEMORY.md, LEARNING_OVERVIEW.md, DATA_MODEL.md, AGENTS.md i STATUS.md dopiero według faktycznie wdrożonych reguł.
- [ ] Integracja: format, `flutter analyze`, pełny `flutter test`, sześć walidatorów danych; jeden końcowy przegląd Sola i adekwatna kontrola Chrome.
