# Pamięć Kuny — zasady FSRS

Każdy kraj ma dwanaście osobnych kart: trzy poziomy lokalizacji na mapie,
trzy tryby stolicy, trzy tryby rozpoznania państwa po fladze oraz trzy poziomy
wskazania kraju na mapie po fladze. Klucz karty ma postać
`topic:countryId:difficulty`; kraje wspólne Europie i Azji dzielą kanoniczną pamięć.
Mapa używa `mapVeryEasy`, `mapEasy`, `map` (normalny); nazwy stolic i państw
`choice`, `firstLetter`, `write`. Stary klucz mapy `map` pozostał normalnym.

## Ocena i harmonogram

Adapter używa `dart-fsrs` 2.0.1 z domyślnymi parametrami i docelową retencją
0,9. Losowy rozrzut terminów jest wyłączony. Parametr nie gwarantuje 90% pamięci.

- Błąd → Again (1); poprawna pierwsza odpowiedź → Good (3).
- W trybie pisanym jedna zaakceptowana literówka jest poprawną odpowiedzią;
  poprawna pisownia pozostaje widoczna.
- A–D ma własną kartę FSRS rozpoznawania. Nie aktualizuje karty pierwszej litery
  ani pełnego pisania. Wcześniejsza historia A–D bez ocenionych przeglądów
  pozostaje zachowana i nie jest automatycznie przepisywana na oceny FSRS.
- Każdy poziom pomocy mapowej ma osobną kartę. Kliknięcie jest zatwierdzeniem;
  po błędzie dostępne są do dwóch dalszych różnych prób. FSRS ocenia wyłącznie
  pierwsze wskazanie, dalsze służą ćwiczeniu. Woda i zoom klastra nie są próbą.
- Nie wyprowadzamy Hard/Easy z czasu odpowiedzi. Poprawny trening przed terminem
  nie przesuwa harmonogramu; błąd przed terminem ponownie planuje kartę jako Again.
- Wczesna poprawna próba i historyczny wybór z pomocą mogą pozostać w historii
  jako `applied=false`. Historyczna pomoc nie stanowi oceny FSRS.

Odpowiedź, karta i dziennik są zapisywane transakcyjnie; ponowne wysłanie tego
samego indeksu nie tworzy drugiej oceny. Niekompletne pytanie mapowe można
wznowić albo zakończyć ręcznie bez ponownej oceny pierwszego kliknięcia.

## Dzisiejsza wyprawa

Na Dziś wybieramy kontynent i poziom. Normalny, czyli pełne wpisywanie i mapa
bez ukierunkowania na cel, pozostaje sugerowany. Wyprawa planuje karty
wybranego poziomu; licznik może informować o zaległościach na innych poziomach.
Rozpoczęta seria zachowuje format i kolejność nawet po zmianie preferencji.
Ręczny wybór kategorii i poziomu nadal jest dostępny.

W serii jest do 10 pytań: najpierw zaległe, najstarsze powtórki, potem najwyżej
3 nowe karty na lokalny dzień. Limit nowości i rezerwacje rozpoczętych wypraw
są wspólne dla kontynentów i poziomów. Co najmniej 10 zaległości wstrzymuje
nowości. Jedno państwo występuje w serii najwyżej raz, aby pytania nie
podpowiadały sobie odpowiedzi. Ręczny trening nie zużywa budżetu nowości.
Terminy przechowywane są w UTC, a limit dobowy korzysta z lokalnego dnia;
zegara urządzenia nie synchronizujemy z siecią.

## Zaliczenia, medale i passa

Zaliczenie umiejętności wymaga dwóch poprawnych zastosowanych ocen pierwszej
odpowiedzi w różne dni i w odstępie co najmniej 24 godzin, bez błędu pomiędzy.
Zbyt wczesna poprawna próba ma `applied=false`, więc nie wystarcza do zaliczenia.
Zaliczenie normalnego poziomu obejmuje łatwy i bardzo łatwy tej samej kategorii;
łatwy obejmuje bardzo łatwy. To widok osiągnięć, nie syntetyczna ocena FSRS.
Rozpoznanie, stolica, mapa i flaga → mapa nie zaliczają się wzajemnie.

Medale za 50%, 80% i 100% dotyczą całego katalogu danej kategorii, poziomu
oraz kontynentu. Wcześniej zdobyty medal pozostaje po błędzie i po nadejściu
powtórki; bieżący stan może się zmienić. Medal nie jest gwarancją pamięci
przez miesiące. Szczegóły: [LEARNING_OVERVIEW.md](LEARNING_OVERVIEW.md).

Passę liczymy osobno dla każdego kontynentu. Jedna zapisana odpowiedź w danym
lokalnym dniu zalicza dzień także przy błędzie lub w A–D. Kraje wspólne
zwiększają passę wyłącznie kontynentu sesji. Otwarcie aplikacji bez odpowiedzi
nie zalicza dnia, a ponowne wysłanie próby nie tworzy dodatkowej aktywności.
Passa jest wspólna dla poziomów danego kontynentu i nie blokuje nauki.

## Mapa, ciekawostki i treść

Na normalnym poziomie kadr obejmuje niemal cały kontynent. Dwa łatwiejsze
poziomy korzystają z odpowiednio silniejszej i słabszej wskazówki kadrem,
z lekkim przesunięciem; cel nie jest idealnie centrowany. Pierwszy i drugi
błąd pokazują nazwę wskazanego państwa, bez ujawniania celu. Po trzecim
błędzie mapa może jednorazowo przybliżyć poprawną odpowiedź. Użytkownik
zachowuje ręczny zoom i przesuwanie.

Po poprawnym wskazaniu kraju może pojawić się jedna z trzech lokalnych,
źródłowych ciekawostek, bez wpływu na FSRS. Ta sama sesja i pytanie odtwarzają
ten sam wybór. Pokrycie, źródła i ograniczenia: [COUNTRY_TRIVIA.md](COUNTRY_TRIVIA.md).

## Zgodność historii

Starsze próby, migawki pytań, klucze i zaplanowane terminy pozostają zachowane.
Jednorazowy import starej historii jest idempotentny; nie tworzy nowej oceny A–D
z wcześniej nieocenionych prób. Regionalny reset usuwa wskazane dane nauki
oraz medale i passę tego kontynentu; wspólna pamięć krajów może dotknąć innego
regionu. Reset całej nauki usuwa wszystkie te dane. Preferencje zachowujemy.
Szczegóły: [LEARNING_OVERVIEW.md](LEARNING_OVERVIEW.md) i [DATA_MODEL.md](DATA_MODEL.md).
