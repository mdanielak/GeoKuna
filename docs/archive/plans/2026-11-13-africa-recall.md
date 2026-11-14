# Afryka i samodzielne przypominanie — plan

Cel: wybór Europy/Afryki na Dziś; pełny zestaw mapy, stolic i flag, zachowany postęp.
Zakres polecony przez użytkownika. AGENTS ma pierwszeństwo przed ponowną akceptacją procesu.

## Kontrakt

- Domyślny i sugerowany poziom: pełne wpisywanie. Pierwsza litera ma wyłączoną
  automatyczną kapitalizację dopisywanej części; podana litera nadal rozpoczyna nazwę.
- A–D to trening: poprawność i historia zostają, bez wyniku wiedzy, ocenionych
  przeglądów FSRS i propozycji takich kart w Dziś. Historycznych prób nie usuwamy.
  Historyczne karty rozpoznawania pozostają w bazie, ale poza oceną/postępami/kolejką.
- Nowe karty Dziś preferują pełne pisanie, następnie mapę i formaty z pierwszą literą.
  Zaległe oceniane karty nadal pierwsze; wspólny limit trzech nowych na dzień.
- Europa/Afryka: 54 suwerenne państwa Afryki, oddzielne paczki i źródła, bez
  osobnego quizu o Saharze Zachodniej; jawna polityka spornych geometrii i stolic.
- Sesja ma region, migracja v4→v5 nadaje istniejącym europe. Stabilne ID kart
  nie zmieniają się; aktualizacje nie usuwają historii i stanu FSRS.
- Jedna aktywna sesja danego tematu/poziomu na kontynent. Przełączenie
  zakresu nie wznawia pytań innego regionu. Budżet globalny, kolejka regionalna.

## Podział i kroki

- [ ] Terra: narzędzie build_africa --check, zweryfikowane mapy, stolice i flagi, dokument źródeł.
- [ ] Luna: selektor na Dziś, dynamiczne etykiety i bounds, sugerowane pisanie, mała litera.
- [ ] Sol: enum/catalog/provider regionalne, migracja sesji i repo, polityka FSRS A–D,
  preferencja nowych kart, default routing, integracja assets i walidatorów.
- [ ] Testy RED/GREEN: A–D bez FSRS/wyniku, dotychczasowe dane zachowane,
  wznowienie dwóch regionów, regionalne kolejki, wspólny limit, nowe pisanie.
- [ ] Kontrola Chrome telefonu selektora, mapy Afryki, flag/stolic i feedbacku;
  mała szerokość/duży tekst. Bez emulatora i nowych zależności.
- [ ] Format/analyze/test oraz wszystkie walidatory raz przy integracji,
  aktualizacja dokumentacji. Bez automatycznego commita.

Ryzyka: stary trening A–D ma nadal ślad w bazie, ale nie jest dowodem wiedzy;
wybór regionu w pamięci aplikacji (domyślnie Europa), sesje trwałe; migawka mapy
wciąż bazuje na geometrii wersji aplikacji. Nie dowodzi działania natywnego Androida.

## Rozszerzenie zlecone podczas pracy

Dołączono Azję (50), przegląd nauki kontynent → kraje → formaty oraz reset
wybranego regionu/całości z potwierdzeniem. Reakcje kuny i ładniejsze mapy
rozważono w MAP_AND_MASCOT_NEXT.md; nie generowano nowych bitmap.
Wskaźnik „na bieżąco” = oceniane umiejętności z poprawną ostatnią odpowiedzią
i przyszłym terminem / wszystkie oceniane umiejętności; zaokrąglenie w dół.
Rezerwacje nowych pytań w innych aktywnych sesjach zapobiegają mnożeniu limitu.
