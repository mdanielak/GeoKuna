# „Nie wiem, pomóż” i passa po quizie — projekt

## Po co

Kto nie zna stolicy albo nazwy kraju z flagi, musi dziś wpisać byle co
(„blabla”), bo „Sprawdź odpowiedź” jest nieaktywne przy pustym polu. Chcemy
uczciwego wyjścia: przyznać się do niewiedzy i od razu spróbować rozpoznać
odpowiedź wśród opcji. Osobno: po każdym quizie użytkownik ma widzieć swoją passę.

## Cele / nie-cele

- Cel: przycisk „Nie wiem, pomóż” w pytaniach pisanych (stolica, flaga → nazwa;
  poziomy `write` i `firstLetter`).
- Cel: karta z passą na podsumowaniu każdej serii.
- Nie-cel: pytania mapowe, poziom A–D, powiadomienia systemowe.
- Anty-cel: podpowiedź, która poprawia statystyki — „nie wiem” to zawsze błąd.

## Podejścia

- **A (wybrane): na tym samym pytaniu.** Kliknięcie zapisuje błąd, pole tekstowe
  zastępują 4 opcje A–D dla tej samej flagi/stolicy jako nieoceniane ćwiczenie.
  Natychmiastowe, nie zmienia długości serii ani limitów drabinki.
- B: osobne pytanie A–D wstawione do serii (jak krok drabinki). Odrzucone:
  wydłuża serię, limit 2 kroków, pomoc przychodzi jako „kolejne pytanie”.

## Zachowanie (ustalone)

1. Przycisk „Nie wiem, pomóż” **pod** przyciskiem „Sprawdź odpowiedź”, w tym
   samym stylu (`FilledButton`), w czerwonawym kolorze (`GeoColors.wrong`);
   widoczny tylko przed odpowiedzią.
2. Kliknięcie = odpowiedź błędna: ocena FSRS Again karty tego poziomu, ta sama
   ścieżka zapisu co błędna odpowiedź wpisana (transakcja, powtórka błędu po
   3–5 pytaniach, „trudny kraj”, drabinka).
3. Potem na tym samym ekranie 4 opcje A–D. Wybór pokazuje „Dobrze!” albo
   „To była X”; następnie zwykłe „Następne pytanie” / „Zobacz wynik”.
4. Wybór A–D nie jest oceną FSRS (ani karty `write`, ani `choice`) i nie liczy
   się do wyniku.

## Passa po quizie (moja decyzja)

Na podsumowaniu serii, pod reakcją kuny: karta z płomieniem
„Passa: N dni z rzędu · <kontynent>”. W dniu nagrody za passę zostaje obecna
karta gratulacyjna zamiast nowej (bez dwóch kart naraz); karta żetonu bez zmian.

## Dla wykonawcy

- Czy wybór A–D zapisywać (np. `origin=assisted`, `applied=false`), czy trzymać
  tylko w stanie widoku. Wymóg: po wyjściu z aplikacji błąd zostaje; krok A–D
  może przepaść.
- Skąd opcje A–D dla pytań pisanych (czy pytanie ma już `options`).
- Feedback błędu po „nie wiem” — bez komunikatu o literówce/porównaniu wpisu.
- Testy zwięzłe: jeden test repozytorium (Again, brak oceny za A–D) i jeden
  test widgetu przepływu; aktualizacja `docs/LEARNING.md`.
