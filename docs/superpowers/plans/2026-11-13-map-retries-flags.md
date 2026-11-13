# Trzy próby mapy, kolorowy feedback i flagi

Użytkownik zlecił trzy bezpośrednie próby mapowe bez potwierdzania, semantyczne
kolory feedbacku oraz flagi w trzech poziomach i na mapie. Zakres zaakceptowany.

## Decyzje edukacyjne

- Kliknięcie państwa jest jawną odpowiedzią. Woda/zoom klastra nie są próbą.
- Do trzech różnych państw na pytanie. Po błędzie 1/2 pokazujemy pozostałe
  szanse bez rozwiązania. Trafienie lub trzeci błąd zamyka pytanie i ujawnia cel.
- Pierwsza próba aktualizuje FSRS raz: Good/Again. Późniejsze trafienie jest
  ćwiczeniem, a nie samodzielnym sukcesem. Wynik pokazuje numer trafionej próby.
- Zapis kliknięć jest transakcyjny, idempotentny według indeksu próby i trwały.
  Zakończenie quizu po błędzie zapisuje go bez oceniania pozostałych pytań.
- Nazwana lista nadal oznacza pomoc i nie aktualizuje FSRS; nie można usunąć
  oznaczenia pomocy późniejszym dotknięciem mapy.
- Flaga → kraj: A–D / pierwsza litera / pełna nazwa; osobno flaga → mapa.
  Cztery nowe niezależne umiejętności. Normalizacja i jedna literówka jak dotąd.
- Błąd czerwony, rozwiązanie zielone, literówka żółta; ikony i tekst uzupełniają
  kolor. Brak automatycznego przejścia blokującego spokojne czytanie.

## Dane i architektura

Terra: lokalne PNG w oryginalnych proporcjach z przypiętej wersji country-flags,
manifest SHA, źródłowe mapowanie ISO z Natural Earth, walidator bez sieci.
Luna: UI mapy i flag, setup, współdzielony feedback; brak nazw kraju w alt flagi.
Sol: schemat v4 MapGuesses, repo/scheduler, seed nowych kart, routing/providery,
postępy i testy integracji. Stare identyfikatory i stany FSRS zachowane; nowe
flagowe liczbowe ID w oddzielnej przestrzeni. Bez nowych zależności.

## API

- MapGuess: sessionId, questionIndex, guessIndex, selectedCountryId, correct,
  assisted, guessedAt. PK sesja+pytanie+próba.
- LearningSession.mapGuesses/currentMapGuesses; isMapAt/isFlagAt/flagQuestionAt;
  flagDifficulty; assistedIndices uwzględnia pomoc w próbach.
- repo.guessMap(...,{required int expectedGuessIndex,bool assisted=false}).
  currentAttempt powstaje dopiero przy trafieniu lub trzecim błędzie.
- repo.startFlags(FlagCatalog,FlagDifficulty), answerFlag(id,index,input).
- memoryOverview/startDaily/learningProgress mają opcjonalny FlagCatalog flags.
  Produkcyjne providery przekazują paczkę; stare wywołania zachowują zakres 204.
- flagsProvider, dashboard.flagsSessions; /flags i /learn?topic=flags&level=….

## Weryfikacja

Pierwszy błąd/2./3. próba, brak ujawnienia, wznowienie, zdublowane kliknięcie,
koniec po błędzie, pierwsza ocena FSRS, pomoc i osobne karty flag; migracje.
Paczka 51 flag i opcje bez duplikatów; brak sieci w quizie. Format/analyze/test,
trzy walidatory; jeden przegląd Chrome telefonu i hot reload. Android później.
