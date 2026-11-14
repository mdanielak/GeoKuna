# Poziomy nauki, medale, passy i pomoc mapy — projekt

Data: 2026-11-14. **Status: zakres zaakceptowany i w trakcie implementacji.**
Użytkownik zmienił pierwotną propozycję: A–D ma własny FSRS, a etykieta
błędnego kraju zawiera tylko jego nazwę. Weryfikację ukończonego przyrostu
opisuje STATUS.md; ten dokument nie stanowi dowodu przejścia testów.

## Cel i wybrane podejście

Rozdzielić naukę według poziomu wsparcia, nagradzać poznanie całego zakresu
i regularny powrót, zachowując uczciwe dowody wiedzy oraz prosty interfejs telefonu.

Rozważono trzy podejścia:

1. Kopiowanie historii i FSRS z trudniejszego poziomu na łatwiejszy — tworzy
   fikcyjne odpowiedzi i komplikuje reset; odrzucone.
2. Osobne rzeczywiste postępy i harmonogramy, z dziedziczeniem zaliczeń
   w prezentacji i osiągnięciach — rekomendowane.
3. Jedna pamięć z wagami trudności — miesza przypominanie i rozpoznawanie,
   wymaga większej przebudowy; odrzucone.

## Trzy poziomy

| Kategoria | Bardzo łatwy | Łatwy | Normalny |
|---|---|---|---|
| Stolice | A–D | Pierwsza litera | Cała odpowiedź |
| Flaga → państwo | A–D | Pierwsza litera | Cała odpowiedź |
| Państwo → mapa | Silniejsza delikatna pomoc kadrem | Słabsza pomoc kadrem | Obecny szeroki kadr |
| Flaga → mapa | Silniejsza delikatna pomoc kadrem | Słabsza pomoc kadrem | Obecny szeroki kadr |

Normalny pozostaje sugerowany. Poziom zapisujemy przy tworzeniu pytania;
zmiana ustawień nie zmienia rozpoczętej sesji ani formatu zaplanowanej karty.
Trzy różne poziomy mapy stają się osobnymi umiejętnościami. Zachowujemy
dotychczasowe klucze mapy normalnej oraz istniejące karty stolic i flag.
Poziom wsparcia i format odpowiedzi to różne pojęcia — `map` nie jest `write`.

**A–D:** osobny harmonogram FSRS rozpoznawania i osobna ocena, bez przenoszenia
oceny na pierwszą literę ani wpisywanie całości. Dziś może dobrać kartę A–D
po wybraniu bardzo łatwego poziomu. Bardzo łatwa mapa również ma osobną kartę.

## Dziedziczenie zaliczeń

- Normalny zalicza łatwy i bardzo łatwy; łatwy zalicza bardzo łatwy.
- Reguła działa dla tego samego faktu, kategorii i kierunku pytania.
  Lokalizacja Polski nie zalicza Warszawy ani rozpoznania polskiej flagi.
- Zaliczenie wymaga dowodu utrwalenia opisanego poniżej, nie jednego trafienia.
- Stan efektywny faktu jest sumą zbiorów faktów zaliczonych bezpośrednio
  i na trudniejszych poziomach. Każdy kraj jest liczony najwyżej raz.
- Etykieta: „Zaliczone na poziomie normalnym”. Nie tworzymy syntetycznych prób,
  dat odpowiedzi ani skopiowanych parametrów FSRS.
- 100% mapy Europy na normalnym daje 100% zaliczenia łatwiejszych map Europy.
  Nie zalicza innych kategorii. Dziesięć trafień w quizie nie zastępuje całego
  katalogu 51 państw.
- Kraje wspólne Europie/Azji zachowują kanoniczną pamięć; osiągnięcie kontynentu
  zależy od pełnego katalogu danego kontynentu.

## Medale — proponowane progi

Osobne medale dla **kontynentu × kategorii/kierunku × poziomu**:

| Medal | Udział zaliczonych faktów w całym katalogu |
|---|---|
| Brązowy | Co najmniej 50% |
| Srebrny | Co najmniej 80% |
| Złoty | Dokładnie 100% |

Procent liczymy bez zaokrąglania przed porównaniem progu. Nieznane kraje są
w mianowniku. Wynik quizu, procent zaliczonego materiału i bieżące terminy
powtórek to trzy różne wskaźniki.

**Proponowane zaliczenie faktu:** dwie poprawne pierwsze odpowiedzi oddalone
o co najmniej 24 godziny i przypadające w różne lokalne dni, bez błędnej
pierwszej odpowiedzi między nimi. Druga odpowiedź w ocenianym formacie musi
przypadać na termin powtórki lub później; wczesne nabijanie quizów nie wystarcza.
Dla A–D analogiczna zasada oznacza utrwalone rozpoznawanie według jego
osobnych ocen FSRS. Pierwsze poprawne trafienie rozpoczyna historię karty.
Próg 24 h to decyzja produktowa pierwszego przyrostu, nie gwarancja trwałej pamięci.

Zdobyty medal zapisujemy z datą, zakresem i wersją katalogu. Zwykły późniejszy
błąd albo nadejście terminu go nie odbiera. Stan „Do powtórki” aktualizuje się
niezależnie; historyczny medal nie oznacza aktualnych 100% wiedzy. Nowa wersja
katalogu nie odbiera starego osiągnięcia, lecz pokazuje aktualny stan zakresu.
Reset usuwa odpowiednie osiągnięcia po jawnym potwierdzeniu.

## Dziś i wybór poziomu

Na stronie głównej pod kontynentem mały wybór poziomu; domyślnie zapamiętany
poziom kontynentu. Ustawienia zachowują tę samą preferencję. Nie dodajemy
trzech dużych przycisków rozpoczęcia nauki.

Dziś wybiera rzeczywiste karty wybranego poziomu; pokazuje także, ile powtórek
czeka na innych poziomach, bez blokowania rozpoczęcia. A–D ma osobny harmonogram
rozpoznawania. Medal nie usuwa rzeczywistych zaległych kart; ręczny trening
pozostaje dostępny. Unikanie dokładania słabszych nowych kart po mocniejszym
zaliczeniu należy zweryfikować w integracji.

Globalny limit 3 nowych kart i rezerwacje rozpoczętych wypraw pozostają wspólne
dla poziomów i kontynentów. Jedno państwo nadal najwyżej raz w serii.
Nie wolno po cichu zastępować pytania łatwego normalnym w rozpoczętej sesji.

## Passa każdego kontynentu

Propozycja startowa: dzień kontynentu zalicza **jedna zapisana odpowiedź**
w jego sesji; poprawna lub błędna. To miernik powrotu do nauki, nie wynik wiedzy.
Samo otwarcie aplikacji, oglądanie mapy i kolejne strzały na to samo pytanie
nie naliczają kolejnych dni. Ręczny trening i A–D mogą podtrzymywać passę.

- Europa, Afryka i Azja mają osobną aktualną i najdłuższą passę.
- Poziomy i kategorie w obrębie kontynentu współdzielą passę.
- Próba Turcji w sesji Europy zalicza wyłącznie dzień Europy, nie także Azji.
- Dziś liczy się lokalny dzień kalendarzowy, nie przesuwne 24 godziny.
  Zapis zawiera datę lokalną i offset w momencie odpowiedzi oraz czas UTC.
  Zmiana strefy nie przelicza historycznych dat.
- Unikalność kontynent–dzień i transakcja próby zapobiegają duplikatom przy
  wznowieniu. Dzień przypada na faktyczny zapis, nie start sesji przed północą.
- Przerwa zeruje aktualną serię po pominięciu pełnego dnia; rekord zostaje.
  Bez kar, utraty medali, blokady powtórek i kupowanych „ochron passy”.
- Offline nie gwarantujemy odporności na ręczne manipulowanie zegarem.
  Nie dopisujemy automatycznie historycznych pass ze starych niepełnych danych.
- Reset kontynentu usuwa jego passę; wspólna karta nie kasuje passy innego
  kontynentu. Reset globalny usuwa wszystkie. Preferencje zostają.

## Mapa: pomoc i informacja po błędzie

Poniższe wartości są **wartościami startowymi do wizualnego sprawdzenia**:

| Poziom | Zoom ponad kadr kontynentu | Przesunięcie od środka kontynentu w stronę celu |
|---|---|---|
| Bardzo łatwy | +0,35 poziomu zoomu (około 27% większa skala) | 20% drogi + niewielki losowy odchył |
| Łatwy | +0,15 (około 11% większa skala) | 10% drogi + mniejszy odchył |
| Normalny | 0 | 0; obecny szeroki kadr |

Nie centrujemy na środku kraju. Odchył ograniczony odpowiednio do 4%/2%
rozmiaru widoku, ze zmianą kierunku; cel musi pozostać widoczny z marginesem.
Jeśli to niemożliwe, zmniejszamy pomoc/zoom, zamiast wypychać kraj za ekran.
Obliczenia w projekcji mapy, nie przez prostą średnią długości geograficznych;
szczególnie ważne dla Azji i południka 180°.
Kadr jest wybierany deterministycznie na podstawie sesji i pytania, również
po wznowieniu; przebudowa widgetu lub zmiana stylu nie powinna losować nowej
wskazówki ani cofać ręcznego ruchu.

Po błędnym kliknięciu od razu pojawia się etykieta **„Niemcy”** przy
klikniętym miejscu/kraju, oprócz czerwonego zaznaczenia. Etykieta ma odpowiednik
semantyczny dla czytnika, nie zasłania małych sąsiadów i nie przechwytuje kliknięć.
Pierwszy i drugi błąd nie ujawniają celu ani nie przesuwają na niego kamery.

Po trzecim błędzie pokazujemy właściwy kraj, etykietę **„Poprawna odpowiedź: …”**
i jednorazowo dopasowujemy kadr do jego geometrii z marginesem. Rozmiar kraju
wyznacza zoom; mikropaństwa mają ograniczenie przybliżenia i marker.
Przeniesienie działa także, gdy użytkownik wcześniej odsunął mapę daleko od celu.
Po nim można ręcznie poruszać mapą; kolejne przebudowy nie cofają użytkownika.
Szanujemy ograniczenie animacji. Brak oczekiwania na dekorację i brak zmiany FSRS.

## Interfejs na telefonie

- Dziś: kontynent, poziom, jedno główne działanie, liczba powtórek; mała passa.
- Moja nauka: kategorie i trzy poziomy, procent całego zakresu, zdobyty medal,
  oznaczenia dziedziczenia; wejście w kraje nadal pokazuje fakty do powtórki.
- Medal otrzymuje krótkie, pomijalne potwierdzenie w podsumowaniu. Bez modala
  zasłaniającego poprawną odpowiedź, bez dodatkowego kliknięcia i oczekiwania.
- Emocje kuny pozostają zależne od wyniku bieżącej sesji według
  [MASCOT_FEEDBACK.md](MASCOT_FEEDBACK.md), niezależnie od medali i pass.
  Każda z pięciu emocji ma trzy miłe, zachęcające warianty tekstu; wybór
  jest powtarzalny dla tej samej sesji.
- Po poprawnym wskazaniu pokazujemy jedną z trzech lokalnych, źródłowych
  ciekawostek kraju, dobraną dla sesji i pytania. Paczka obejmuje 148
  kanonicznych krajów/obszarów; szczegóły: [COUNTRY_TRIVIA.md](COUNTRY_TRIVIA.md).
- Minimum 48 dp, tekst 200%, kolor plus etykieta, ergonomia jednej ręki.

## Kolejność i decyzje przed wdrożeniem

1. Osobne poziomy mapy i bezpieczna migracja; snapshot poziomu pytania.
2. Etykiety błędów, kadr rozwiązania, delikatna pomoc poziomów; Chrome na telefonicznym viewport.
3. Zaliczenia, dziedziczenie i medale; widok postępu i reset.
4. Passy kontynentów; niewielki dodatek do Dziś i podsumowania.

Przyjęte progi: 50/80/100%; definicja utrwalenia: 24 h i dwa różne lokalne dni;
minimalna aktywność passy: jedna odpowiedź. Dziedziczenie dotyczy osiągnięć,
a A–D ma osobny harmonogram rozpoznawania.
Nie instalujemy bibliotek ani narzędzi. Bez backendu, emulatora i powiadomień.
Plan wykonawczy: [2026-11-14-levels-medals-streaks.md](superpowers/plans/2026-11-14-levels-medals-streaks.md).
