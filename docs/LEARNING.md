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
  (nigdy zaraz), najwyżej 3 powtórki na serię, oznaczone „powtórka błędu”.
  Powtórka to ćwiczenie (`origin=retry`, bez oceny FSRS) i nie wlicza się do wyniku.
  Gdy w serii brak miejsca na odstęp, kraj przejmuje kolejna runda lub dzień.
- **Trudny kraj:** karta z błędem pozostaje trudna, dopóki nie padną
  **3 ocenione trafienia z rzędu** — rozłożone w czasie przez FSRS (seria,
  kolejna runda, kolejne dni). Kolejny błąd zeruje licznik. Trudne karty mają
  pierwszeństwo wśród zaległych; feedback pokazuje „Trudny kraj: 2 z 3”.
- **Poziom „Automatyczny” (domyślny):** działa per hasło (`kategoria × kraj`),
  zaczynając od poziomu normalnego. **3 błędy z rzędu** (pierwsze wskazanie
  pytania, także w powtórce błędu w serii; bez ćwiczeń kontrastowych i kolejnych
  prób na mapie) obniżają trudność o jeden poziom (`normalny → łatwy → bardzo
  łatwy`) i od razu ustawiają łatwiejszą kartę do powtórki bez zużywania limitu
  nowości. **2 trafienia z rzędu** podnoszą trudność z powrotem o jeden poziom
  (najwyżej do normalnego). Każde pytanie ocenia swoją kartę FSRS, a na
  ułatwionym pytaniu pojawia się etykieta „Łatwiej” (bez nazwy kraju przy fladze).
  Zastąpił dawny łatwiejszy krok drabinki (`origin=scaffold`).
- **Mylona para:** gdy ten sam kraj został **2 razy** podany zamiast
  celu (błędny kraj na mapie albo nazwa we fladze), zaraz po ocenianym pytaniu
  o cel pada to samo pytanie o drugi kraj pary, jako ćwiczenie „para do
  porównania” (`origin=contrast`). W A–D flag drugi kraj pary jest zawsze wśród
  odpowiedzi. Stolic nie łączymy w pary: wpisana stolica nie wskazuje kraju.
  Najwyżej 2 pary na serię; para nie trafia do serii, w której już jest.
- **„Nie wiem, pomóż”** (stolica i flaga → nazwa, poziomy pisane): błąd z pustą
  odpowiedzią — Again jak każdy błąd, z powtórką w serii. Potem na tym samym
  pytaniu 4 opcje A–D jako ćwiczenie: wybór nie jest zapisywany ani oceniany.
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
- Kadr normalny jest niezależny od celu: na szerokim ekranie niemal cały
  kontynent (padding 16 dp), na telefonie w pionie jego rdzeń (np. Europa
  11°W–50°E), a skrajne obszary są dostępne przesunięciem. Krawędź wycinka
  mapy przechodzi miękko w morze; mikropaństwa to małe kropki z polem dotyku 48 dp. Bardzo łatwy: zoom +0,9 i przesunięcie 70% nad pytany kraj,
  łatwy: +0,5 i 40%; plus stabilny losowy rozrzut (8% / 6% ekranu) z seeda
  pytania, więc cel nigdy nie jest idealnie wycentrowany. Kadr odtwarza się po wznowieniu.

### Odpowiedzi pisane

- Jedna operacja edycyjna jest literówką: zamiana, wstawienie, usunięcie
  lub przestawienie sąsiednich liter (Warszaqa → Warszawa). Dwie to błąd.
- Wielkość liter, diakrytyka (także znaki złożone Unicode) i spacje nie wpływają
  na ocenę. Jawne endonimy z paczki (Bern, Andorra la Vella) i nazwy angielskie
  (Vienna, Warsaw; [CONTENT.md](CONTENT.md#stolice)) są poprawne — wszędzie,
  także z jedną literówką.
- Zaakceptowana literówka liczy się jako poprawna; zawsze pokazujemy poprawną pisownię.
- Pierwsza litera: widoczna, nieedytowalna; użytkownik dopisuje resztę (ponowne wpisanie pierwszej litery też jest tolerowane).
- A–D: wybór innej opcji jest zawsze błędem; tolerancja pisowni go nie dotyczy.
- Pusta odpowiedź nie może zostać zatwierdzona.

Feedback: błąd czerwony, rozwiązanie zielone, literówka żółta — zawsze z tekstem
i ikoną, nie tylko kolorem.

Podsumowanie serii: kuna mówi w dymku (duży tekst), pod nią lista pytań. Wiersz
z błędem lub literówką rozwija się po dotknięciu i pokazuje, co wpisano,
wybrano lub wskazano na mapie (np. „Wpisano: Makozia”).

## Dzisiejsza wyprawa

- Na Dziś wybieramy kontynent; poziom pochodzi z ustawień kontynentu
  (domyślnie: Automatyczny). Wyprawa planuje aktywną kartę dla każdego hasła.
- Do 10 pytań: najpierw zaległe (najpierw świeżo ułatwione w trybie
  Automatycznym, potem trudne, potem według najniższej szansy przypomnienia
  FSRS), potem **najwyżej 3 nowe karty na lokalny dzień, wspólnie
  dla wszystkich kontynentów i poziomów**, z rezerwacją rozpoczętych wypraw.
  Przy 10+ zaległościach seria ma 9 powtórek i 1 nową kartę, by nauka nie stanęła.
- Seria nie jest dopychana: gdy niewiele jest do zrobienia, jest krótsza.
- **Kolejna runda** (ten sam dzień, gdy plan Dziś jest pusty lub po podsumowaniu):
  zaległe i trudne, do 3 nowych, a resztę do 10 wypełniają **pytania kontrolne**
  — najsłabsze opanowane karty, każda najwyżej raz na ~20 h. To okresowa
  kontrola pewniaków i sposób na utrzymanie passy, gdy wszystko jest opanowane.
- **Wstępny quiz:** główny przycisk Dziś przy pierwszej wizycie obszaru (żadna
  seria jeszcze nie ruszyła). Działa na aktywnym poziomie obszaru (domyślnie
  normalnym przy starcie w trybie Automatycznym): seria do 10 niewidzianych kart. Trafienia od razu dostają Easy
  i **nie zużywają limitu nowości**; zużywają go tylko błędy. Znawca może więc
  odkryć znany kontynent w jeden wieczór.
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

„Na bieżąco X%” = kategorie w stanie **Ćwiczysz** dla wybranego poziomu obszaru
(z dziedziczeniem z wyższego poziomu w dół: normalny zalicza łatwy i bardzo
łatwy tej samej kategorii, analogicznie do medali).

- **Ćwiczysz:** jest zastosowana ocena FSRS, ostatnia odpowiedź poprawna,
  termin w przyszłości.
- **Do powtórki:** termin minął lub ostatnia odpowiedź była błędna.
- **Za mało danych:** brak ocenionego przeglądu (wlicza się do mianownika).

Plakietka na *Dziś* pokazuje liczbę krajów zaliczonych na mapie oraz licznik
**W nauce** (kraje odpowiedziane na tym poziomie, które czekają jeszcze na
drugą ocenę po ≥ 24 h), więc postęp widać już od pierwszego dnia.

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
- **Nagrody za passę:** 3, 7, 10, 14, 20, 30, 40, 50, 60 i 90 dni z rzędu, osobno
  dla kontynentu (`streakRewards` w `streaks.dart`). Zdobyta, gdy rekord dojdzie
  do progu, więc przerwa jej nie odbiera. Liczone z dni nauki, bez osobnej tabeli.
  Dziś pokazuje, ile dni brakuje do następnej; podsumowanie serii zawsze
  pokazuje passę („Passa: 5 dni z rzędu · Europa”), a w dniu zdobycia gratuluje
  zamiast tego (tylko gdy wcześniejsza passa nie dotarła do progu);
  Moja nauka → kontynent ma listę zdobytych i brakujących.
- **Przerwa przerywa passę**, chyba że użyjesz żetonu **Nieprzykunowanie**
  (na razie złota ikona monety; emoji wymagałoby czcionki z sieci w wersji web).
  Żeton za każde 7 dni passy (7., 14., 21. dzień), najwyżej 3 na kontynent;
  przy komplecie licznik stoi, po zużyciu nowy po kolejnych 7 dniach. Dzień po
  przerwie Dziś pokazuje smutną kunę: „Wczoraj Cię tu nie było!” z wyborem
  „Użyj żetonu” / „Nie, zacznę passę od nowa”. Jeden żeton ratuje jeden
  opuszczony dzień; uratowany dzień nie wydłuża passy, tylko jej nie przerywa.
  Propozycja trwa do końca dnia, także po odpowiedzi; odmowa jest ostateczna.
  Gdy żetonów brakuje na wszystkie dni przerwy, passa przepada. Stan żetonów
  liczy się z dni nauki i decyzji (`streak_saves`), więc przejście po historii
  zawsze daje ten sam wynik.

## Kuna po quizie

Emocja jest wyłącznie wspierającym feedbackiem: nie zmienia wyniku, FSRS ani
dostępu do powtórek, nie opóźnia kolejnego kroku.

| Wynik ocenianych pierwszych odpowiedzi | Kuna | na 10 | na 5 |
|---|---|---:|---:|
| 0–30% | smutna | 0–3 | 0–1 |
| >30–45% | zamyślona | 4 | 2 |
| >45–60% | mrugająca | 5–6 | 3 |
| >60%, <100% | wesoła, z pięścią | 7–9 | 4 |
| dokładnie 100% | z serduszkiem | 10 | 5 |

- Bez zaokrąglania (249/250 = wesoła). Literówka liczy się jako poprawna.
- Przerwana seria: neutralna kuna z globusem. Seria bez ocenianych odpowiedzi:
  ogólna zachęta, bez serduszka.
- Każda emocja ma trzy miłe, dopingujące teksty; wariant zależy od ID sesji,
  więc wznowienie go nie zmienia.
- Grafiki: `assets/v2/kuna_{sad,thinking,wink,determined,love}.webp`, neutralna
  `kuna_neutral.webp`, wesoła (seria A–D) `kuna_happy.webp` — z paczek wyglądu v2
  ([CONTENT.md](CONTENT.md#grafiki-wygląd-v2)). Tekst w dużym dymku obok kuny.

## Ciekawostki

Po trafieniu **lub po trzecim błędzie** (razem z ujawnionym krajem) pokazujemy
jedną z trzech lokalnych, źródłowych ciekawostek na kremowo-bursztynowej karcie
z kuną z lupą i podpisem „Ciekawostka” (sam kolor nie jest sygnałem — żółty oznacza
literówkę).
Po pytaniach o stolicę ciekawostka dotyczy stolicy, po pytaniach o flagę — flagi (geneza barw, pierwsze
użycie, godło), po pozostałych — kraju. Fakt wspominający kraj pytany dalej w serii jest pomijany. Wybór jest deterministyczny dla sesji i pytania, nie
wpływa na FSRS i nie zdradza odpowiedzi przyszłych pytań. Źródła: [CONTENT.md](CONTENT.md#ciekawostki).

## Reset

Ustawienia → Zresetuj naukę, z potwierdzeniem i ostrzeżeniem o nieodwracalności.

- **Kontynent:** usuwa sesje, próby, karty, medale i passę tego kontynentu.
  Wspólne kraje mają wspólne karty, więc ich pamięć czyści się także dla drugiego
  regionu (passa drugiego regionu zostaje). Historia innego kontynentu nie
  odtwarza usuniętej pamięci.
- **Cała nauka:** usuwa wszystko powyżej i metadane importu.
- Ustawienia (styl mapy, poziomy) zawsze zostają. Web i Android mają osobne bazy.
- **Kopia zapasowa** (Ustawienia): „Zapisz kopię” zapisuje całą naukę i ustawienia
  do pliku JSON; „Wczytaj kopię” po potwierdzeniu zastępuje nią obecny stan.
  Plik z nowszej wersji aplikacji lub uszkodzony jest odrzucany bez zmian w bazie.

## Ustawienia

- Styl mapy (globalny): nowoczesny atlas, papierowy atlas, rzeźba terenu (domyślny).
  Zmiana stylu zachowuje kadr i kolory odpowiedzi.
- Poziom osobno dla każdego kontynentu: bardzo łatwy / łatwy / normalny.
  Dotyczy nowych quizów mapy, stolic i flag; zaplanowane powtórki zachowują format.
- W quizie mapy odpowiedź wybiera się wyłącznie na mapie; lista krajów jest
  narzędziem atlasu. Nie przywracamy przycisku „wybierz z listy”.
