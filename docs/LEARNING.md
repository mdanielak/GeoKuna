# Zasady nauki

Jedno źródło prawdy o tym, jak GeoKuna pyta, ocenia, planuje powtórki
i pokazuje postęp. Cel: przypominanie i trwałość wiedzy; punkty, medale,
passy i kuna nigdy nie blokują powtórek ani nie zastępują feedbacku.

**Główna zasada:** nie pytaj niepotrzebnie o to, co użytkownik już zna;
skup się na trudnościach, ale okresowo sprawdzaj także wiedzę opanowaną.
Algorytm to hybryda: krótka kolejka w obrębie serii + FSRS długoterminowo.

## Umiejętności i karty

Każdy kraj ma **12 osobnych kart FSRS** o kluczu `topic:countryId:difficulty`:

| Kategoria | Bardzo łatwy | Łatwy | Normalny |
|---|---|---|---|
| Lokalizacja na mapie (`map`) | `mapVeryEasy` | `mapEasy` | `map` |
| Stolica (`capitals`) | `choice` (A–D) | `firstLetter` | `write` |
| Flaga → nazwa (`flags`) | `choice` | `firstLetter` | `write` |
| Flaga → mapa (`flags`) | `mapVeryEasy` | `mapEasy` | `map` |

- Karty nie aktualizują się wzajemnie. A–D (rozpoznawanie) ma własny FSRS
  i nie zalicza pierwszej litery ani pełnego pisania.
- Kraje wspólne Europie i Azji (np. Turcja) mają jedną kanoniczną kartę.
- Historyczny klucz `map` pozostał poziomem normalnym.

## Ocena i harmonogram

Adapter `fsrs` 2.0.1, domyślne parametry, docelowa retencja 0,9, bez rozrzutu
terminów, **maksymalny odstęp 60 dni** (`maxReviewIntervalDays`). Parametr
nie gwarantuje 90% pamięci.

| Odpowiedź | Ocena FSRS |
|---|---|
| błąd | Again (1) |
| nowa karta, od razu poprawnie, pełne pisanie lub mapa normalna | **Easy (4)** — „znane”: bez powtórki w minutach, następna za ok. 2 tygodnie |
| nowa karta, poprawnie w A–D, pierwszej literze lub na łatwej mapie | Good (3) — zwykłe kroki nauki |
| kolejna poprawna | Good (3) |
| poprawna z zaakceptowaną literówką | o stopień niżej (Easy → Good, Good → Hard) |

- Nie wyprowadzamy ocen z czasu odpowiedzi.
- Poprawna odpowiedź przed terminem nie przesuwa harmonogramu (`applied=false`);
  błąd przed terminem planuje kartę jako Again.
- Pytanie kontrolne (`origin=control`) jest oceniane także przed terminem —
  FSRS uwzględnia wtedy wysoką szansę przypomnienia, więc odstęp rośnie umiarkowanie.
- Odpowiedź, karta i dziennik zapisują się w jednej transakcji. Ponowne
  wysłanie tego samego pytania nie tworzy drugiej oceny.

### Błędy i trudne kraje

- Błąd w serii dziennej: to samo pytanie wraca **po 3–5 innych pytaniach**
  (nigdy zaraz), najwyżej 3 powtórki na serię, oznaczone „JESZCZE RAZ”.
  Powtórka to ćwiczenie (`origin=retry`, bez oceny FSRS) i nie wlicza się do wyniku.
  Gdy w serii brak miejsca na odstęp, kraj przejmuje kolejna runda lub dzień.
- **Trudny kraj:** karta z błędem pozostaje trudna, dopóki nie padną
  **3 ocenione trafienia z rzędu** — rozłożone w czasie przez FSRS (seria,
  kolejna runda, kolejne dni). Kolejny błąd zeruje licznik. Trudne karty mają
  pierwszeństwo wśród zaległych; feedback pokazuje „Trudny kraj: 2 z 3”.
- Zapisujemy wskazany błędny kraj. Gdy ten sam kraj ponownie zostanie wskazany
  zamiast celu, feedback podpowiada: „Ta para już się myliła: Norwegia i Szwecja”.
- Historyczne odpowiedzi z pomocą (lista usunięta z quizu) i dawne nieocenione
  A–D zostają w historii, ale nie są ocenami FSRS i nie są przepisywane.

### Mapa: trzy próby

Kliknięcie kraju jest zatwierdzeniem. Do trzech **różnych** państw; FSRS ocenia
tylko pierwsze wskazanie, kolejne są ćwiczeniem. Woda, zoom klastra mikropaństw
i ponowne kliknięcie tego samego kraju nie zużywają szansy.

- Po 1. i 2. błędzie: czerwony kraj z etykietą zawierającą **tylko jego nazwę**
  i licznik szans. Cel nie jest ujawniany ani kadrowany.
- Po trafieniu lub 3. błędzie: rozwiązanie na zielono. Po 3. błędzie mapa
  jednorazowo przybliża poprawny kraj; ręczny zoom i przesuwanie działają dalej.
- Po 3. błędzie przybliżenie rozwiązania wynosi najwyżej +1,5 poziomu zoomu
  względem widoku kontynentu — kraj widać w jego regionie, nie z bliska.
- Kadr normalny: niemal cały kontynent (padding 16 dp zamiast 24 dp atlasu),
  niezależny od celu. Bardzo łatwy: zoom +0,9 i przesunięcie 70% nad pytany kraj,
  łatwy: +0,5 i 40%; plus stabilny losowy rozrzut (8% / 6% ekranu) z seeda
  pytania, więc cel nigdy nie jest idealnie wycentrowany. Kadr odtwarza się po wznowieniu.

### Odpowiedzi pisane

- Jedna operacja edycyjna jest literówką: zamiana, wstawienie, usunięcie
  lub przestawienie sąsiednich liter (Warszaqa → Warszawa). Dwie to błąd.
- Wielkość liter, diakrytyka (także znaki złożone Unicode) i spacje nie wpływają
  na ocenę. Jawne endonimy z paczki (Bern, Andorra la Vella) są poprawne.
- Zaakceptowana literówka liczy się jako poprawna; zawsze pokazujemy poprawną pisownię.
- Pierwsza litera: widoczna, nieedytowalna; użytkownik dopisuje resztę.
- A–D: wybór innej opcji jest zawsze błędem; tolerancja pisowni go nie dotyczy.
- Pusta odpowiedź nie może zostać zatwierdzona.

Feedback: błąd czerwony, rozwiązanie zielone, literówka żółta — zawsze z tekstem
i ikoną, nie tylko kolorem.

## Dzisiejsza wyprawa

- Na Dziś wybieramy kontynent; poziom pochodzi z ustawień kontynentu
  (domyślnie i sugerowany: normalny). Wyprawa planuje karty tego poziomu.
- Do 10 pytań: najpierw zaległe (trudne, potem według najniższej szansy
  przypomnienia FSRS), potem **najwyżej 3 nowe karty na lokalny dzień, wspólnie
  dla wszystkich kontynentów i poziomów**, z rezerwacją rozpoczętych wypraw.
  Przy 10+ zaległościach seria ma 9 powtórek i 1 nową kartę, by nauka nie stanęła.
- Seria nie jest dopychana: gdy niewiele jest do zrobienia, jest krótsza.
- **Kolejna runda** (ten sam dzień, gdy plan Dziś jest pusty lub po podsumowaniu):
  zaległe i trudne, do 3 nowych, a resztę do 10 wypełniają **pytania kontrolne**
  — najsłabsze opanowane karty, każda najwyżej raz na ~20 h. To okresowa
  kontrola pewniaków i sposób na utrzymanie passy, gdy wszystko jest opanowane.
- **Kuna sprawdzi, co już wiesz:** seria do 10 niewidzianych kart poziomu.
  Trafienia od razu dostają Easy i **nie zużywają limitu nowości**; zużywają
  go tylko błędy. Znawca może więc odkryć znany kontynent w jeden wieczór.
- Kraj pojawia się w serii najwyżej raz, aby pytania nie podpowiadały odpowiedzi.
- Zaliczony normalny poziom nie wprowadza zbędnej nowej karty łatwiejszego poziomu.
- Rozpoczęta seria zachowuje swój format, kolejność i migawkę pytań, także po
  zmianie ustawień lub po północy.
- Ręczny trening mapy, stolic i flag jest zawsze dostępny i nie zużywa limitu
  nowości. Dobór: trudne zaległe, inne zaległe, niewidziane, a znane wypełniają
  tylko resztę miejsc, od najsłabszych.
- Terminy w UTC, limit dobowy według lokalnego dnia, bez synchronizacji zegara.

Zakończenie: „Zakończ quiz” zamyka serię z częściowym wynikiem (pytania bez
odpowiedzi nie są błędami); Wstecz zostawia serię do wznowienia.

## Postęp „na bieżąco”

„Na bieżąco X%” = karty w stanie **Ćwiczysz** / wszystkie karty kontynentu
(Europa 612, Afryka 648, Azja 600; wspólne kraje liczone kanonicznie).

- **Ćwiczysz:** jest zastosowana ocena FSRS, ostatnia odpowiedź poprawna,
  termin w przyszłości.
- **Do powtórki:** termin minął lub ostatnia odpowiedź była błędna.
- **Za mało danych:** brak ocenionego przeglądu (wlicza się do mianownika).

Zaokrąglamy w dół, więc 100% wymaga kompletu. To stan treningu, nie
prawdopodobieństwo zapamiętania.

## Medale

Brąz / srebro / złoto = **50 / 80 / 100%** zaliczonych krajów całego katalogu
kontynentu w danej kategorii i poziomie (nie wynik jednego quizu).

- **Zaliczenie** karty: dwie poprawne pierwsze odpowiedzi z zastosowaną oceną
  FSRS, w różne lokalne dni i co najmniej 24 h od siebie, bez błędu pomiędzy.
  Błąd wymaga ponownego utrwalenia.
- Dziedziczenie: normalny zalicza łatwy i bardzo łatwy tej samej kategorii,
  łatwy zalicza bardzo łatwy. To obliczenie widoku — karty FSRS nie są kopiowane.
  Kategorie (mapa, stolica, flaga → nazwa, flaga → mapa) nie zaliczają się wzajemnie.
- Medal jest historyczny: zapisujemy datę i wersję katalogu; późniejszy błąd go
  nie odbiera. Medal nie jest gwarancją trwałej pamięci.

## Passa

Osobna dla każdego kontynentu, widoczna na Dziś dla wybranego kontynentu
(aktualna i rekordowa).

- Dzień liczy się po **pierwszej zapisanej odpowiedzi**, także błędnej i A–D.
  Samo otwarcie aplikacji nie zalicza dnia; kolejne próby go nie dublują.
- Liczy się kontynent sesji: Turcja w sesji Europy zwiększa tylko passę Europy.
- Zapis: lokalna data i offset z chwili odpowiedzi oraz czas UTC; zmiana strefy
  nie przelicza dawnych dni. Przerwa nie usuwa rekordu ani medali.

## Kuna po quizie

Emocja jest wyłącznie wspierającym feedbackiem: nie zmienia wyniku, FSRS ani
dostępu do powtórek, nie opóźnia kolejnego kroku.

| Wynik ocenianych pierwszych odpowiedzi | Kuna | na 10 | na 5 |
|---|---|---:|---:|
| 0–30% | smutna | 0–3 | 0–1 |
| >30–45% | zamyślona | 4 | 2 |
| >45–60% | zachęcająca | 5–6 | 3 |
| >60%, <100% | wesoła | 7–9 | 4 |
| dokładnie 100% | z serduszkiem | 10 | 5 |

- Bez zaokrąglania (249/250 = wesoła). Literówka liczy się jako poprawna.
- Przerwana seria: neutralna kuna z globusem. Seria bez ocenianych odpowiedzi:
  ogólna zachęta, bez serduszka.
- Każda emocja ma trzy miłe, dopingujące teksty; wariant zależy od ID sesji,
  więc wznowienie go nie zmienia.
- Grafiki: `assets/mascot/kuna-{sad,thoughtful,encouraging,happy-v2,heart}.png`,
  neutralna `kuna-globe.png`. Prompty: `output/imagegen/`.

## Ciekawostki

Po trafieniu **lub po trzecim błędzie** (razem z ujawnionym krajem) pokazujemy
jedną z trzech lokalnych, źródłowych ciekawostek na kremowo-bursztynowej karcie
z żarówką i podpisem „Ciekawostka” (sam kolor nie jest sygnałem — żółty oznacza
literówkę). Docelowo w miejscu żarówki kuna z lupą. Wybór jest deterministyczny dla sesji i pytania, nie
wpływa na FSRS i nie zdradza odpowiedzi przyszłych pytań. Źródła: [CONTENT.md](CONTENT.md#ciekawostki).

## Reset

Ustawienia → Zresetuj naukę, z potwierdzeniem i ostrzeżeniem o nieodwracalności.

- **Kontynent:** usuwa sesje, próby, karty, medale i passę tego kontynentu.
  Wspólne kraje mają wspólne karty, więc ich pamięć czyści się także dla drugiego
  regionu (passa drugiego regionu zostaje). Historia innego kontynentu nie
  odtwarza usuniętej pamięci.
- **Cała nauka:** usuwa wszystko powyżej i metadane importu.
- Ustawienia (styl mapy, poziomy) zawsze zostają. Web i Android mają osobne bazy.

## Ustawienia

- Styl mapy (globalny): nowoczesny atlas, papierowy atlas, rzeźba terenu (domyślny).
  Zmiana stylu zachowuje kadr i kolory odpowiedzi.
- Poziom osobno dla każdego kontynentu: bardzo łatwy / łatwy / normalny.
  Dotyczy nowych quizów mapy, stolic i flag; zaplanowane powtórki zachowują format.
- W quizie mapy odpowiedź wybiera się wyłącznie na mapie; lista krajów jest
  narzędziem atlasu. Nie przywracamy przycisku „wybierz z listy”.
