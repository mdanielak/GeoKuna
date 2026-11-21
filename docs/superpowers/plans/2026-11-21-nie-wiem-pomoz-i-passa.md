# „Nie wiem, pomóż” i passa po quizie — plan wdrożenia

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** W pytaniach pisanych (stolica, flaga → nazwa; `write`/`firstLetter`) przycisk „Nie wiem, pomóż” zapisuje błąd i pokazuje nieoceniane A–D; podsumowanie każdej serii pokazuje passę.

**Architecture:** „Nie wiem” to zwykła błędna odpowiedź zapisana przez istniejące `answerCapital`/`answerFlag` z flagą `gaveUp` (pusty `answer`, Again w FSRS, powtórka błędu). Widok rozpoznaje to po pustym `attempt.answer` i zamiast `AnswerFeedback` pokazuje 4 opcje z `question.options` (już istnieją dla każdego poziomu). Wybór A–D żyje tylko w stanie widoku. Passa to nowa karta na podsumowaniu z `streakProvider`.

**Tech Stack:** Flutter 3.50, Riverpod 3, Drift, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-11-21-nie-wiem-pomoz-i-passa-design.md`

## Global Constraints

- Komendy: `export PATH="$HOME/.local/share/geokuna/flutter/bin:$PATH"`; porażki: `flutter test 2>&1 | grep -E "^\s+/home.*_test.dart: |All tests passed" | sort -u`.
- Etykieta przycisku dokładnie: `Nie wiem, pomóż`.
- Przycisk pod „Sprawdź odpowiedź”, ten sam styl (`FilledButton`), tło `GeoColors.of(context).wrong`, tekst biały (`Colors.white`); widoczny tylko przed odpowiedzią i tylko gdy poziom ≠ `choice` i pytanie nie jest mapowe.
- Bez `Color(0x…)` w UI — tylko tokeny `GeoColors`/`Theme`.
- Wybór A–D po „nie wiem” nie zapisuje nic do bazy (ani karty `write`, ani `choice`) i nie liczy się do wyniku.
- Testy zwięzłe: rozszerzaj istniejące pliki, bez nowych plików testów.
- W `session_repository.dart` `min` z Drift przesłania `dart:math`.

## Review Focus

1. Poziom `firstLetter`: „nie wiem” nie może zapisać samej pierwszej litery jako odpowiedzi (`answer` ma być `''`) — test w Task 1.
2. Powtórka błędu w serii dziennej (`origin=retry`) z „nie wiem”: zapis bez oceny, pytanie nadal ma przycisk — pokryte, bo ścieżka zapisu jest wspólna; test Task 1 sprawdza `_queueRetry` przez `countryIds.length`.
3. Wznowienie serii po wyjściu z aplikacji na pytaniu z „nie wiem”: widok musi znów pokazać A–D, nie „Twoja odpowiedź: ” z pustym tekstem — wynika z wyprowadzenia stanu z `attempt.answer`; test Task 2 (ponowne `pumpWidget`).
4. Poziom `choice` i mapa: brak przycisku — asercja w Task 2.
5. Passa 1 dzień: poprawna odmiana „1 dzień” (`daysLabel`) — asercja w Task 3.

---

### Task 1: Zapis „nie wiem” w repozytorium

**Files:**
- Modify: `lib/features/learning/session_repository.dart` (`answerFlag` ~478, `answerCapital` ~654, klasa `LearningSession`)
- Test: `test/learning_levels_test.dart`

**Interfaces:**
- Produces:
  - `Future<LearningSession> answerCapital(String id, int index, String input, {bool gaveUp = false})`
  - `Future<LearningSession> answerFlag(String id, int index, String input, {bool gaveUp = false})`
  - `bool get LearningSession.gaveUpCurrent` — `currentAttempt != null && currentAttempt!.answer.isEmpty`

- [ ] **Step 1: Napisz test** `'giving up on a written answer is a graded error without the first letter'` w `test/learning_levels_test.dart`: dla `CapitalDifficulty.write` i `CapitalDifficulty.firstLetter` (`startCapitals` na `SessionRepository(db)`) oraz `FlagDifficulty.firstLetter` (`startFlags`) wołaj `answerCapital/answerFlag(id, index, '', gaveUp: true)` i sprawdź:
  ```dart
  expect(answered.currentAttempt!.correct, isFalse);
  expect(answered.currentAttempt!.answer, '');
  expect(answered.gaveUpCurrent, isTrue);
  final review = await (db.select(db.memoryReviews)
        ..where((r) => r.sessionId.equals(answered.row.id))).getSingle();
  expect(review.rating, 1);
  expect(review.applied, isTrue);
  ```
  oraz że dla poziomu `choice` `gaveUp: true` rzuca `ArgumentError`.
- [ ] **Step 2: Uruchom** `flutter test test/learning_levels_test.dart` — FAIL (brak parametru `gaveUp`).
- [ ] **Step 3: Zaimplementuj.** Przy `gaveUp`: odrzuć poziom `choice` (`ArgumentError`), pomiń walidację pustego `input`, zapisz `answer: ''`, `correct: false`, `typoAccepted: false`; reszta ścieżki (`_memory.record`, `_queueRetry`) bez zmian. Dodaj getter `gaveUpCurrent`.
- [ ] **Step 4: Uruchom** test — PASS; potem pełne `flutter test` (sprawdź `test/adaptive_learning_test.dart`).
- [ ] **Step 5: Commit** `feat(learning): record "don't know" as a graded error`

### Task 2: Przycisk i ćwiczenie A–D w quizie

**Files:**
- Modify: `lib/features/learning/quiz_controller.dart` (`submit`)
- Modify: `lib/features/learning/learning_screen.dart` (`_capitalQuestion` ~520, przypięty przycisk ~620)
- Modify: `docs/LEARNING.md` (sekcja „Błędy i trudne kraje”: jeden punkt o „Nie wiem, pomóż”)
- Test: `test/capital_flow_test.dart`

**Interfaces:**
- Consumes: `answerCapital/answerFlag(..., gaveUp:)`, `LearningSession.gaveUpCurrent` (Task 1)
- Produces: `QuizController.submit(..., {bool gaveUp = false})` przekazuje `gaveUp` do repozytorium.

- [ ] **Step 1: Napisz test** w `test/capital_flow_test.dart`: osobny `testWidgets('capitals write: "Nie wiem, pomóż" shows A–D practice')` z tą samą konfiguracją co istniejący przepływ (sesja `POL`, poziom `write`; wydziel wspólny setup do lokalnej funkcji pliku). Asercje:
  - przed odpowiedzią `find.text('Nie wiem, pomóż')` → `findsOneWidget`; tap;
  - `find.byType(TextFormField)` → `findsNothing`, `find.byType(RadioListTile<String>)` → `findsNWidgets(4)`;
  - tap błędnej opcji (`question.options.firstWhere((o) => o != 'Warszawa')`) → `find.text('To była Warszawa.')` → `findsOneWidget`;
  - po ponownym `pumpWidget` tej samej aplikacji (wznowienie) znów 4 opcje;
  - w istniejącym teście dla `choice`: `find.text('Nie wiem, pomóż')` → `findsNothing`.
- [ ] **Step 2: Uruchom** `flutter test test/capital_flow_test.dart` — FAIL.
- [ ] **Step 3: Zaimplementuj.**
  - Pod przypiętym `FilledButton` „Sprawdź odpowiedź”, gdy `attempt == null` i poziom pisany: drugi `FilledButton` „Nie wiem, pomóż” (`FilledButton.styleFrom(backgroundColor: GeoColors.of(context).wrong, foregroundColor: Colors.white)`), odstęp 8; wywołuje `_quiz.submit(..., typed: '', gaveUp: true)` tą samą obsługą błędu co `_submit`.
  - Gdy `session.gaveUpCurrent`: zamiast `AnswerFeedback` tekst „Wybierz poprawną odpowiedź:” i 4 opcje `question.options` w tym samym stylu kart co poziom `choice`; stan `String? _practicePick` (zerowany razem z `_typed` przy przejściu dalej). Po wyborze opcje nieaktywne, wybrana obramowana, pod spodem blok `'Dobrze! ${subject}: $solution.'` albo `'To była $solution.'` (kolory `correctContainer`/`wrongContainer`).
  - „Następne pytanie” / „Zobacz wynik” aktywne od razu (wybór A–D nieobowiązkowy).
- [ ] **Step 4: Uruchom** test — PASS; pełne `flutter test`.
- [ ] **Step 5: Commit** `feat(quiz): "Nie wiem, pomóż" turns a written question into A–D practice`

### Task 3: Passa na podsumowaniu serii

**Files:**
- Modify: `lib/features/learning/learning_screen.dart` (podsumowanie ~893, nowy widget `_StreakDays` obok `_StreakReward` ~1281)
- Modify: `docs/LEARNING.md` (sekcja „Passa”: podsumowanie zawsze pokazuje passę)
- Test: `test/capital_flow_test.dart`

**Interfaces:**
- Consumes: `streakProvider` (`StreakSummary.current`, `.rewardToday`), `daysLabel(int)` z `streaks.dart`, `Continent.label`.

- [ ] **Step 1: Rozszerz istniejący test przepływu** w `capital_flow_test.dart` (po „Zobacz wynik”): `expect(find.text('Passa: 1 dzień z rzędu · Europa'), findsOneWidget);`
- [ ] **Step 2: Uruchom** — FAIL.
- [ ] **Step 3: Zaimplementuj `_StreakDays({required int days, required Continent continent})`** — `Card.filled` w stylu `_StreakReward` (ikona `Icons.local_fire_department`, `colors.streak`, `Semantics(liveRegion: true)`), tytuł `'Passa: ${daysLabel(days)} z rzędu · ${continent.label}'`. Pokazuj, gdy `rewardToday == null && current > 0`; w dniu nagrody tylko `_StreakReward`. Karta żetonu bez zmian.
- [ ] **Step 4: Uruchom** — PASS; pełne `flutter test`, `flutter analyze`, `dart format --output=none --set-exit-if-changed lib test`.
- [ ] **Step 5: Commit** `feat(summary): show the streak after every series`
