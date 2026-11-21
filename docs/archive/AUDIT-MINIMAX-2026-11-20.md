# Audyt GeoKuna — 2026-11-20

Przegląd kodu, warstwy technicznej, danych i interfejsu. Dokument jest **wyłącznie
opisowy**: w trakcie audytu nie zmieniono żadnego pliku w repozytorium.
Oceny dotyczą stanu gałęzi `main` na commit `90b73b6` („chore: add author credit
in settings"), wersja aplikacji 0.7.0+8.

## Podsumowanie

| Wymiar | Ocena | Uzasadnienie w skrócie |
|---|---|---|
| UI/UX | **7/10** | Spójny system wizualny i maskotka, ale: ucięty rząd kontynentów, ucięty tekst przy 160%, dwie sprzeczne miary postępu, martwa ścieżka „podpowiedzi" |
| Użyteczność | **7/10** | Pętla nauki jest naprawdę dobra; brakuje wyjścia z impasu w quizie i zrozumiałego pokazu postępu dnia pierwszego |
| Warstwa techniczna | **8/10** | Czysta architektura, transakcyjne zapisy, migracje z indeksami, pipeline z proweniencją; minus pełne skany tabel po każdej odpowiedzi |
| Kod | **8/10** | Czytelny, udokumentowany, reguły nauki jako czyste funkcje; minus trzy przegrube pliki, ciche `catch`, magic strings |
| Testy | **8/10** | Prawdziwa symulacja ucznia, test migracji, testy przepływów; brak testu na urządzeniu i brak CI |
| Dane / pipeline | **9/10** | Najlepsza część projektu — źródła, statusy, sumy kontrolne, flagi bez generowania AI |
| Higiena repo | **6/10** | 20 MB PNG-ów w gicie, 3,9 MB sesji Codex i 21 MB zip w korzeniu, brak `.github` |
| **Ogólnie** | **8/10** | Materiał na beta; do wydania publicznego brakuje testu na fizycznym Androidzie |

Rekomendowany porządek pracy: **P0 → P1 → P2 → P3** (listy poniżej).

## Wyniki weryfikacji

| Sprawdzenie | Wynik |
|---|---|
| `flutter analyze lib test` | **No issues found** (strict-casts, strict-inference, strict-raw-types) |
| `flutter analyze` (cały pakiet) | **16 issues** — wszystkie spoza `lib/`, z katalogów-sziców w korzeniu |
| `flutter test` | **90/90 passed** (88 deklaracji, ok. 2 min) |
| `dart format --output=none --set-exit-if-changed lib test` | **exit 1** — `settings_screen.dart` niesformatowany |
| 16 walidatorów `build_*.py --check` | **wszystkie OK** (checksumy, proweniencja, geometria, licencje) |
| Rozmiar | lib 10 446 LOC, test 4 342 LOC, assety 34,8 MB / 4 638 plików |

Walidatory danych przeszły kompletnie: 47 krajów Europy, 54 Afryki, 50 Azji,
22 Ameryki Północnej, 13 Południowej, 14 Oceanii, 16 województw, 50 stanów USA;
3 753 kafelki reliefu (z2–6) + 514 kafelków HD, 789 faktów o stolicach,
591 faktów trivia, 174 obiekty lądu kontekstowego.

## Co jest mocne

1. **Model nauki to najlepsza część projektu.** `lib/features/learning/memory.dart`
   — adapter FSRS z własnym `maximumInterval: 60`, oceną Easy dla „znane od razu"
   (`memory.dart:51-60`), literówką obniżoną o stopień, osobnym FSRS dla A–D,
   drabinką (scaffold → contrast) i parami mylonych krajów. Reguły są czystymi
   funkcjami poza widgetami — testowalne i czytelne.
2. **Reguły egzekwowane w jednym miejscu.** Limit 3 nowości dziennie jest globalny
   i rezerwowany przez serie z innych kontynentów (`daily_planner.dart:140-181`),
   powtórka błędu wchodzi po 3–5 pytaniach i jest nieoceniana
   (`session_repository.dart:441`), trudny kraj wraca dopiero po 3 trafieniach.
3. **Zapis jest atomowy.** Próba, karta FSRS, dziennik i dzień aktywności w jednej
   transakcji; klucz `(session_id, question_index)` chroni przed duplikatem;
   migawka pytania w `question_data` pozwala wznowić serię po wyjściu z aplikacji.
4. **Pipeline danych jest wzorowy.** Walidatory z sumami SHA-256, kontrolnymi
   punktami, statusami faktów, licencjami i pochodzeniem; flagi wyłącznie
   z paczki sprawdzonej, relief z Natural Earth, brak generowania AI.
5. **Design system traktowany poważnie.** `GeoTheme` + `GeoColors` jako
   `ThemeExtension`, zero `Color(0x…)` poza `theme.dart` i `map_style.dart`
   (dokładnie tam, gdzie `AGENTS.md` zezwala), `Semantics` opisują stan mapy,
   `liveRegion` na feedbacku, sterowanie klawiaturą na mapie, cele ≥ 48 dp.
6. **Testy symulują realnego ucznia**, nie tylko funkcje —
   `test/adaptive_learning_test.dart` (30 dni nauki: odstępy ≥ 7 dni i ≤ 60 dni,
   powtórki, drabinka, pary mylonych krajów).

## P0 — przed wydaniem

### P0-1. Aplikacja nigdy nie była sprawdzona na fizycznym Androidzie

Jedyne potwierdzenie UI pochodzi z renderera testowego Fluttera
(`flutter test --update-goldens`), nie z Chrome, tym bardziej nie z telefonu.
Brakuje: gestów (przeciąganie mapy to nie to samo co dotyk), przycisku Wstecz
w trakcie serii, klawiatury systemowej na ekranie stolicy, TalkBacka, cyklu życia,
trwałości bazy po ubiciu procesu oraz realnej wydajności reliefu (3 753 kafelki,
12,6 MB) na słabym GPU. Wszystkie oceny mobilne w tym audycie to ekstrapolacja.

### P0-2. `flutter analyze` w repo nie jest czysty — 16 błędów z katalogów-sziców

`GeoKuna_Assets_v1/`, `GeoKuna_MapQuiz_Themes_v2/`, `assets_mockups/` leżą
w korzeniu, są nieśledzone, ale **nieignorowane** i **nie wykluczone**
w `analysis_options.yaml`. `flutter analyze` zgłasza w nich `uri_does_not_exist`
i `undefined_identifier` dla `flutter_svg`. Komenda weryfikacyjna z `AGENTS.md`
zawsze brzmi „nieczysto", więc zespół uczy się ignorować jej wyjście.

## P1 — ważne, przed szerszym wydaniem

### P1-3. Ścieżka „z pomocą" jest nieosiągalna — model obiecuje funkcję, której UI nie ma

`learning_screen.dart:47` deklaruje `_assisted`, ale **nigdzie w `lib/` nie
ustawia się ono na `true`** — nie ma przycisku „podpowiedz" ani „pokaż mi".
Cały łańcuch `origin == 'assisted'` (`memory.dart:141`,
`session_repository.dart:471`, `learning_screen.dart:496`, `:795`, `:915`),
tekst „Z pomocą — bez oceny pamięci mapy" i pole `map_guesses.assisted` są martwe.
Konsekwencja produktowa: użytkownik, który nie zna odpowiedzi, ma tylko 3 próby
i zgadywanie — brak legalnego sposobu, by poprosić o pomoc bez psucia statystyk.
Model FSRS jest na tę funkcję przygotowany.

### P1-4. Dwie sprzeczne miary „postępu" w jednej aplikacji

Plakietka na Dziś (`home_screen.dart:552`) pokazuje `qualifiedCount/totalCount`
z `AchievementStore`, a tam kwalifikacja wymaga **dwóch poprawnych ocen
w różne dni, ≥ 24 h** (`achievements.dart:183-189`). Po pierwszym udanym dniu
użytkownik widzi więc **„Europa: 0/47 państw"** mimo właśnie zrobionego quizu.
„Moja nauka" liczy inaczej (status „Ćwiczysz"). Na zrzutach widać obie liczby
naraz i wyglądają sprzecznie. Mierzą dni nauki, nie wiedzę, a etykieta obiecuje
wiedzę — najbardziej szkodliwy pojedynczy błąd UX w projekcie.

### P1-5. Pełne skany tabel po każdej odpowiedzi

`quiz_controller.dart:158-163` invaliduje `learningProgressProvider` po każdym
pytaniu, a `SessionRepository.learningProgress` (`session_repository.dart:737-792`)
czyta **całą tabelę `memoryCards` i całą `memory_reviews` z sortowaniem**. To kłóci
się z komentarzem kilka linij wyżej w tym samym pliku („drogie widoki odświeża
dopiero na końcu serii"). Przy 8 obszarach i 12 kartach na kraj to ~3 200 kart,
a historia rośnie o ~10 wierszy na serię — koszt rośnie liniowo z czasem użycia.

### P1-6. `dashboardProvider.history` liczy pełny skan prób, a wynik nigdzie nie jest czytany

`providers.dart:85` → `repository.history()` (wszystkie sesje i wszystkie próby
kontynentu), a `history` nie ma konsumenta w `lib/`. Provider jest invalidowany
po każdej odpowiedzi, czyli pełny skan bazy przy każdym pytaniu i wyrzucany wynik.

### P1-7. Podwójne parsowanie GeoJSON przy każdej zmianie kontynentu

`continentAchievementsProvider` (`providers.dart:118`) i `continentProgressProvider`
(`providers.dart:163-164`) wołają `Catalog.load` niezależnie od `catalogProvider`.
Dla USA to dwa razy (0,7 MB + 0,4 MB) JSON w jednym przełączeniu, na wątku UI.

### P1-8. Higiena repo

`output/` (20 MB, 17 PNG-ów z generowania) jest **śledzone w gicie**. W korzeniu
leżą nieśledzone, ale nieignorowane: `codex-session-01a1d12e….md` (3,9 MB)
i `GeoKuna_Concept_Assets_Pack.zip` (21 MB) — jeden przypadkowy `git add .`
trafi je do historii.

## P2 — polityka i utrzymanie

| # | Problem | Miejsce |
|---|---|---|
| P2-9 | `dart format` pada — `settings_screen.dart` niesformatowany (hook `.claude/hooks/dart-format.sh` nie objął tej ścieżki) | `settings_screen.dart:533` |
| P2-10 | Magic strings zamiast enums: `'assisted'`×13, `'daily'`×8, `'retry'`×6, `'scaffold'`, `'contrast'`, `'control'`, `'placement'`, `'manual'`, `'recognition'` — rozsiane po 3 plikach. Literówka w `origin` cicho zmienia bucketing FSRS | `memory.dart`, `session_repository.dart`, `daily_planner.dart` |
| P2-11 | Ciche `catch (_)`×8 — wyjątki gaszone bez śladu; `home_screen.dart:207` łapie wyjątek z `ref.read(databaseProvider)` | `settings_screen.dart:51`, `:116`, `:138`, `:196`; `learning_screen.dart:119`, `:152`, `:200` |
| P2-12 | `Continent.ofArea` upada do `europe` dla każdego kraju spoza PL-/US- — dziś bezobjawowe (etykiety wychodzą identyczne), ale to krucha umowa zależąca od szczegółów klasy | `continent.dart:81` |
| P2-13 | Trzy przegrube pliki: `learning_screen.dart` 1 342, `session_repository.dart` 925, `home_screen.dart` 894 | — |
| P2-14 | Brak CI — 90 testów, 16 walidatorów danych i `flutter analyze` chodzą ręcznie; brak `.github/` | — |
| P2-15 | `session_repository.dart` re-eksportuje symbole z `daily_planner.dart` (barrel) — dwa moduły o jednej odpowiedzialności | `session_repository.dart:18-29` |
| P2-16 | `SessionRepository.start()` używa literału `10` zamiast stałej `seriesSize` | `session_repository.dart:295` |

## P3 — drobiazgi UX

Poniższe obserwacje pochodzą z renderu testowego (`/shots`, 390×844 oraz
320×640 przy 160% tekstu).

- **Rząd kontynentów jest ucinany bez wskazówki.** 8 obszarów w poziomym
  `SingleChildScrollView` (Europa, Afryka, Azja, Am. Północna, Am. Południowa,
  Australia i Oceania, Polska, Stany Zjednoczone) — „Ameryka Północna" urywana
  w połowie słowa, bez gradientu ani strzałki. Dotyczy Dziś i Atlasu
  (`continent_chips.dart:45`).
- **Przy 160% tekstu na 320×640 „Zacznij zwykłą wyprawę" jest ucięte w połowie
  linii** na krawędzi viewportu — wygląda jak nachodzące na pasek nawigacji.
  Scroll działa, ale brak sygnału, że jest coś dalej (`home_screen.dart:94-143`).
- **Duży pusty obszar na ekranach stolicy i flagi** — między ostatnią opcją
  a przyciskiem „Sprawdź odpowiedź" jest ok. 1/3 ekranu pustki.
- **Podsumowanie po zerowej odpowiedzi mówi „Odpocznij chwilę. Czeka nas jeszcze
  wiele ciekawych miejsc!"** — przy przerwaniu bez odpowiedzi ton jest nieadekwatny
  do sytuacji (`mascot_feedback.dart:27-37`).
- **Plakietka „Kolejna runda"** — kremowe tło na ilustracji, kontrast na granicy
  czytelności.
- **Nazwy państw i przymiotniki kolidują** w pakiecie flag Europy („Włochy" jako
  kraj i przymiotnik) — przy pytaniu „Jakie to państwo?" jest to niejednoznaczne;
  `continent.dart:56-58` rozróżnia herb od flagi, ale `symbolsLabel` Europy to
  „Flagi".

## Kolejność pracy

1. **Test na fizycznym Androidzie** (gest, Wstecz, klawiatura, TalkBack, ubicie
   procesu, płynność reliefu) — jedyna luka wiedzy blokująca wydanie.
2. **Posprzątać korzeń repo i wykluczyć szice z analizy:** `.gitignore` dla
   `GeoKuna_*_v*`, `assets_mockups/`, `output/`, `*.zip`, `codex-session-*.md`;
   `output/` wywalić z indeksu git; `analysis_options.yaml` → `exclude` dla tych
   katalogów.
3. **Naprawić miarę postępu** — plakietka na Dziś powinna pokazywać to samo,
   co „Moja nauka" (najlepiej liczbę *faktów*, nie *umiejętności*), z jasnym
   podpisem „medal" / „w nauce".
4. **Przywrócić przycisk podpowiedzi** na mapie i w pytaniach pisanych, spinając
   go z gotową ścieżką `assisted`.
5. **Przenieść odświeżanie `learningProgressProvider` na koniec serii** (zgodnie
   z zamiarem z komentarza) i **wyrzucić `history` z `dashboardProvider`** —
   dwie linijki, duży zysk.
6. **Wprowadzić enum `origin`/`topic`/`difficulty`** zamiast ~40 literałów;
   usunąć ciche `catch` na ścieżce zapisu (zostawić komunikat, dodać log).
7. **CI**: `flutter analyze lib test` + `flutter test` +
   `dart format --set-exit-if-changed` + 16 walidatorów `--check`. Wszystko gotowe
   do uruchomienia w YAML — brakuje tylko pliku.
8. **Podzielić `learning_screen.dart`** na mapę / stolice-flagi / podsumowanie —
   plik ma 1 342 linie i trzy odrębne tryby pytania.

## Ograniczenia audytu

- Aplikacji nie uruchamiano w Chrome ani na Androidzie — ocena UI opiera się na
  rendererze testowym Fluttera, który wiernie oddaje układ i kolory, ale nie
  odtwarza gestów, animacji ani zachowania klawiatury systemowej.
- Kafelki reliefu nie renderują się w środowisku testowym (znany limit harnessu
  opisany w `AGENTS.md`), więc na zrzutach mapa jest płaska — oceniano układ,
  kadrowanie, kontrast i hierarchię, nie wygląd kartografii.
- Nie mierzono wydajności na urządzeniu; punkty o skanach tabel (P1-5, P1-6,
  P1-7) wynikają z analizy kodu i zliczenia wierszy, nie z profilu.
- Audyt jest statyczny i testowy: nie sprawdzano poprawności merytorycznej
  591 faktów (trivia), 263 stolic ani geometrii — tu opieram się na walidatorach,
  które przechodzą.
