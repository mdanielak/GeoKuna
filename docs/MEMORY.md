# Pamięć Kuny — pierwszy przyrost

Każde z 51 państw ma cztery niezależne umiejętności: mapa, stolica A–D,
stolica z pierwszą literą oraz samodzielne pisanie. Stabilny klucz to
`topic:countryId:difficulty`, np. `capitals:POL:write`. Sukces w A–D nie
aktualizuje pamięci samodzielnego przypominania.

## Ocena i harmonogram

Adapter używa [dart-fsrs 2.0.1](https://pub.dev/packages/fsrs), domyślnych
parametrów i docelowej retencji 0,9. Losowy rozrzut terminów wyłączono,
aby harmonogram dało się odtworzyć. Nie oznacza to gwarancji zapamiętania 90%.

- Błędna odpowiedź: Again (1).
- Poprawna odpowiedź, także zaakceptowana pojedyncza literówka: Good (3).
- Podpowiedź pierwszej litery jest osobnym formatem, nie karą dla innej karty.
- Nie wyprowadzamy Hard/Easy z czasu odpowiedzi ani szybkości pisania.
- Poprawny ręczny trening przed terminem pozostawia harmonogram bez zmian.
  Błąd przed terminem ponownie planuje kartę jako Again.

Wczesny poprawny trening nadal trafia do historii i dziennika z `applied=false`.
Odpowiedź, stan FSRS i dziennik zapisują się w jednej transakcji dopiero po
zatwierdzeniu. Ponowne wysłanie tej samej odpowiedzi nie aktualizuje karty drugi raz.

FSRS zaczyna od krótkich kroków nauki: pierwsze terminy mogą przypadać za kilka
minut. Powrót w ciągu dnia jest więc naturalny; „Dziś” nie oznacza jednej sesji
na dobę. System nie ocenia jeszcze pewności użytkownika ani nie optymalizuje
parametrów na podstawie indywidualnej historii.

## Dzisiejsza wyprawa

Do 10 pytań: najpierw karty z terminem <= teraz, najstarsze najpierw.
Następnie najwyżej 3 nowe karty na lokalny dzień kalendarzowy. Gdy czeka co
najmniej 10 kart, nowe nie są dodawane. W pierwszym dniu seria może mieć tylko
3 pytania. Kolejne serie tego samego dnia nie odnawiają limitu nowych.
Ręczne treningi są dostępne niezależnie i nie zużywają tego limitu.

Państwo pojawia się najwyżej raz w serii, by jedna odpowiedź nie podpowiadała
następnej. Z tego powodu seria może być krótsza od 10, nawet gdy licznik
wszystkich zaległych umiejętności jest większy. Niewybrane pozostają w kolejce.
Wybór nowych jest deterministycznie mieszany według daty; nie ma obowiązkowej
kolejności formatów ani automatycznego awansowania z A–D do pisania.

Aktywna wyprawa zachowuje kolejność i ID. Dla stolic zapisuje również fakty
i opcje odpowiedzi. Mapa korzysta z bieżącej geometrii i nazw; aktualizacja
paczki musi zachować zgodność ID (ograniczenie opisane w CODE_REVIEW.md).
Może zostać wznowiona następnego dnia. Nie tworzymy kolejnej aktywnej wyprawy.
Termin przechowywany jest w UTC, a budżet nowych liczony według lokalnej daty.
Nie ma synchronizacji zegara przez sieć; poprawny czas urządzenia ma znaczenie.

## Migracja i ograniczenia

Schemat 3 dodaje karty, dziennik oraz znacznik jednorazowego importu historii.
Stare próby są odtwarzane chronologicznie w ich oryginalnych formatach; nie są
usuwane ani przekształcane w dowód pełnego przypominania. Import i znaczniki są
transakcyjne. Dzisiejsze próby zaczynają historię od bieżącego stanu bez duplikacji.

Po jednym ukończonym treningu nie pokazujemy „opanowane na zawsze”. Statystyki
trwałego zapamiętania, eksport, optymalizacja FSRS i przypomnienia systemowe
pozostają kolejnymi przyrostami. Dalsze decyzje: [NEXT_STEPS.md](NEXT_STEPS.md).
