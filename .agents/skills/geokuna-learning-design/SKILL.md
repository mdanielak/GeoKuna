---
name: geokuna-learning-design
description: "Projektuj i oceniaj mechaniki nauki GeoKuny: quizy geograficzne, poziomy podpowiedzi, aktywne przypominanie, feedback, dobór sesji i powtórki FSRS. Używaj przy zmianie zachowania edukacyjnego, nie przy samych kolorach, routingu ani konfiguracji środowiska."
---

# GeoKuna Learning Design

Projektuj naukę poprawiającą samodzielne przypominanie, nie tylko wynik quizu.
Przeczytaj AGENTS.md oraz dokument zmienianej mechaniki: `docs/CAPITALS.md`,
`docs/DATA_MODEL.md` lub `docs/CONTENT_POLICY.md` w repo. Skill nie implementuje
sam FSRS i nie rozszerza przydzielonego zakresu funkcji.

## Kontrakt mechaniki przed implementacją

Opisz krótko: fakt/umiejętność i kierunek pytania; format i podpowiedzi;
dopuszczone odpowiedzi; ocenianie/feedback; zapis zdarzenia i wpływ na powtórki;
kilka przypadków granicznych i kryteria ukończenia. Dla drobnej zmiany wystarczy
kilka zdań w zadaniu, bez nowego frameworka, backendu czy rozbudowanej analityki.

## Dowód wiedzy

- Lokalizacja, stolica i waluta państwa to osobne umiejętności.
- A–D = rozpoznawanie, pierwsza litera = przypominanie z podpowiedzią,
  puste pole = samodzielne przypominanie. Zachowaj ten rodzaj dowodu w historii
  i przyszłym ID karty; nie przenoś sukcesu z A–D na pełne przypominanie.
- Użytkownik może wybrać trudność. Zachęcaj do odpowiedzi bez podpowiedzi,
  ale nie blokuj nauki poziomem, serią, energią ani „życiami”.
- Czas odpowiedzi nie dowodzi opanowania; wolne pisanie nie oznacza zapomnienia.
  Trening teleturniejowy z limitem czasu to osobny świadomie wybrany tryb.

## Pytania i feedback

- Tylko zweryfikowana, wersjonowana paczka. Dla nietypowych stolic, wielu
  wartości i spornych granic pytanie musi mieć jawny zakres.
- Dystraktory A–D: różne, sensowne, jednoznacznie niepoprawne; alias poprawnego
  miasta nie może stać się „złą” opcją.
- Nie ujawniaj odpowiedzi na kolejną kartę bez uwzględnienia tego jako ekspozycji.
  Świeże pokazanie rozwiązania nie jest dowodem utrwalenia.
- Mapa może przybliżać region i powiększać cele mikropaństw. Nie zaznaczaj celu
  automatycznie i nie utożsamiaj trudności dotknięcia z niewiedzą.
- Zapis po zatwierdzeniu. Feedback pokazuje rozwiązanie, poprawną pisownię
  i krótkie istotne wyjaśnienie; użytkownik ma czas przeczytać je przed „Dalej”.
- Stosuj CAPITALS.md: normalizacja wielkości liter/diakrytyki/spacji, jawne aliasy,
  najwyżej jedna operacja literówki w trybach pisanych. Zachowaj `correct`
  i `typo_accepted` osobno. „Warszaqa” dla Polski to poprawna wiedza z literówką:
  pokaż „Warszawa”. Puste pole nie jest odpowiedzią; zła opcja A–D jest błędem.

## FSRS i dobór sesji

- FSRS planuje termin karty; silnik sesji dobiera zestaw i format. Użyj sprawdzonej
  biblioteki, nie wymyślaj współczynników lub interwałów.
- Stabilne ID: fakt + umiejętność/kierunek + rodzaj przypominania. Aktualizacja
  treści/schedulera zachowuje historię i stan pamięci.
- Błąd → Again; poprawna samodzielna odpowiedź → domyślnie Good testowanej karty.
  Hard/Easy wynikają z jawnej oceny pewności, nie tylko z szybkości. Podpowiedź
  i zgadywanie zapisuj; nie aktualizuj nimi karty pełnego przypominania jak
  odpowiedzią samodzielną. Karta rozpoznawania ma własne oceny i stan.
- Zaakceptowana literówka nie oznacza automatycznie braku wiedzy. Przy integracji
  FSRS jawnie opisz i przetestuj mapowanie takiej próby.
- Preferuj zaległe powtórki; ogranicz nowości przy zaleganiu. Nie narzucaj stałego
  procentu bez oceny obciążenia. Obecny format startowy to 10 pytań.
- Ponowienie błędów w tej samej sesji jest ćwiczeniem. Długoterminową retencję
  sprawdza się po odroczeniu, nie sumą punktów w tej samej rundzie.

## Weryfikacja

Luna/Terra dobierają testy oceniania, niejednoznaczności i podpowiedzi,
zapisu/wznowienia oraz migracji. Dla FSRS: kontrolowany zegar, zapis stanu
oraz terminy zgodne z kontraktem biblioteki; bez testów kopiujących algorytm.
Sol ocenia, czy zachowanie rzeczywiście ćwiczy deklarowaną umiejętność.
Kontrola wizualna ważnego przepływu według AGENTS.md; czysta zmiana schedulera
nie wymaga dodatkowej kontroli wizualnej. Raportuj trafność, korzystanie z pomocy i retencję osobno.
