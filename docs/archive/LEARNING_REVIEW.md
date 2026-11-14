# Rozpoznanie wiedzy i dobór nauki — propozycja

Stan obecny: sześć ocenianych umiejętności na państwo oraz trening A–D bez
oceny wiedzy, niezależne harmonogramy
FSRS; dzienna wyprawa wybiera zaległe karty, a następnie do trzech nowych,
z pominięciem powtórzeń tego samego państwa w serii. Nowe karty są mieszane
deterministycznie według dnia (`lib/features/learning/session_repository.dart`).
Nie ma oceny wiedzy wejściowej ani automatycznego przejścia między formatami.
To czytelny punkt wyjścia, ale doświadczony użytkownik musi spotkać wiele
łatwych pytań, zanim system zaobserwuje jego wiedzę; początkujący może dostać
trudne pytania bez wcześniejszego rozpoznania potrzeb.

## Możliwe podejścia

1. **Bez osobnej diagnozy:** obserwować zwykłe sesje i pozwolić wybrać poziom.
   Mały koszt i brak egzaminu, ale rozpoznanie obszaru wiedzy trwa długo.
2. **Krótka opcjonalna próbka w zwykłej nauce — rekomendacja:** kilka
   zróżnicowanych pytań, możliwość przerwania i pominięcia, następnie dalsze
   dopasowywanie na podstawie rzeczywistych prób. To przybliżenie z jawną
   niepewnością, a nie ocena całej geografii ani deklaracja opanowania.
3. **Duży test wejściowy:** więcej obserwacji przed pierwszą rekomendacją, ale
   duże obciążenie i ryzyko porzucenia. Nie proponować go jako warunku nauki.

Nie przypisywać z góry prawdopodobieństw, współczynników trudności ani
naukowej skuteczności bez walidacji. Użytkownik zawsze zachowuje ręczny wybór
formatu i dostęp do zwykłych powtórek.

## Kontrakt próbki

- Diagnoza jest dobrowolna; start bez niej, zakończenie po dowolnym pytaniu
  oraz powrót do nauki nie wiążą się z karą. Przed rozpoczęciem podać zakres
  i maksymalny rozmiar próbki. Pominięcie nie jest błędem i nie tworzy oceny.
- Próbka może mieszać mapę i stolice oraz formaty, według ustalonego i
  testowalnego planu; nie pokazywać tego samego państwa dwukrotnie w serii.
  Nie wyświetlać bezpośrednio przed pytaniem odpowiedzi jako podpowiedzi.
  Po odpowiedzi pokazać rozwiązanie i pozwolić spokojnie przeczytać feedback.
- Odpowiedź A–D to dowód rozpoznawania, pierwsza litera to przypominanie ze
  wskazówką, puste pole to przypominanie samodzielne; mapa ma własny dowód.
  Żaden sukces A–D nie aktualizuje karty pisania. Tryb mapy z regionalnym
  kadrowaniem również ma wskazówkę; nie traktować jej jako braku pomocy.
- Diagnoza zapisuje faktyczną próbę po zatwierdzeniu wraz z formatem i
  pochodzeniem; reguły wpływu na istniejącą kartę FSRS muszą być jawne przed
  implementacją. Powtórne wysłanie lub restart nie może jej policzyć drugi raz.
  Nie tworzyć licznych kart „znanych” na podstawie kilku odpowiedzi i nie
  dopisywać sztucznych przeglądów do historii.
- Dla karty, której użytkownik jeszcze nie widział w aplikacji, poprawna
  odpowiedź jest obserwacją w danym formacie, nie dowodem trwałości. Można
  założyć normalną kartę FSRS z rzeczywistej próby; odroczona powtórka dopiero
  dostarczy kolejnej obserwacji. Własna deklaracja „znam” może pomóc w wyborze,
  lecz sama nie jest pomiarem ani podstawą fałszywego stanu FSRS.
- Nie rozpoznawać słabych punktów z czasu pisania. Błąd mapy może wynikać z
  dotyku lub dostępności; wyraźnie oddzielić brak danych, wynik obserwowany
  i ocenę wymagającą kolejnych prób. Nie przedstawiać FSRS jako pewności ani
  gwarancji zapamiętania. Wczesny sukces w tym samym spotkaniu nie dowodzi
  utrwalenia; użyć danych odroczonych i jawnego poziomu pomocy.

## Zastosowanie wyniku

W pierwszej wersji rekomendować formaty lub tematy na podstawie ostatnich
obserwacji i ich liczby, bez ukrywania wyboru. Dla niewielu danych pokazywać
„za mało odpowiedzi”, nie ranking państw. Nieznane karty pozostają nieznane;
nie przenosić wyniku ze stolica → państwo na kierunek odwrotny ani na mapę.
Mieszanie trudności ma dawać zarówno okazję do sukcesu, jak i próbę samodzielną,
ale nie wymuszać trudnego pytania po każdym łatwym. Pytania i odpowiedzi muszą
pochodzić z istniejącej zweryfikowanej paczki, bez dopisywania faktów.

Limit nowych w zwykłej wyprawie i pierwszeństwo zaległych powtórek należy
utrzymać. Jeśli diagnoza ma osobny budżet lub wpływa na dzienny limit, trzeba
tę decyzję jawnie ustalić i przedstawić przed jej implementacją; nie tworzyć
ukrytej drogi do nieograniczonego obciążenia. Aktywna wyprawa zachowuje
migawkę i może zostać wznowiona, również po zmianie daty. Nie resetować starych
stanów, ID ani historii podczas dodawania diagnozy.

## Przyrosty i kryteria akceptacji

1. **Obserwacje bez diagnozy.** Pokazać format i liczbę faktycznych prób oraz
   brak wystarczających danych; użytkownik nadal wybiera trening. Testy oddzielają
   rozpoznawanie, podpowiedź i pisanie, a także poprawną literówkę od błędu.
2. **Opcjonalna krótka próbka.** Podany maksymalny rozmiar, pomijanie i
   przerwanie; po wznowieniu ta sama kolejność i feedback. Test transakcji,
   idempotencji, pustej odpowiedzi, pominięcia oraz braku transferu sukcesu A–D
   do pisania; kontrola UI z klawiaturą i dużym tekstem.
3. **Ostrożne rekomendacje.** Przykłady testowe obejmują początkującego,
   użytkownika znającego materiał przed instalacją, sprzeczne odpowiedzi,
   mało danych, wiele zaległości i powrót po przerwie. Zaległości nie znikają,
   nowości przestrzegają uzgodnionego limitu, a ręczny wybór zawsze pozostaje.
4. **Ocena po użyciu.** Oddzielnie mierzyć trafność odpowiedzi według formatu,
   liczbę pominięć i odroczone powtórki; nie obiecywać poprawy retencji bez
   porównania. Zbieranie czegokolwiek poza urządzeniem wymaga osobnej decyzji.

To propozycja projektowa, bez nowych twierdzeń geograficznych i bez deklaracji
empirycznej skuteczności. Szczegóły liczby pytań, polityki limitu i wpływu na
FSRS wymagają decyzji właściciela mechaniki przed implementacją.

## Rekomendacja Sola po przeglądzie Astry

Do przyszłej implementacji przyjmujemy opcjonalną próbkę do 6 pytań, ograniczoną
pozostałym globalnym budżetem automatycznie wprowadzanych kart. Przy pustej
historii i budżecie 3 oznacza to najwyżej 3 nowe pytania, nie ukryte 6 nowości.
Wprowadzone wcześniej karty mogą dopełnić próbkę; nie przedłużać interwału za
wczesny poprawny wynik. Zaległe powtórki nadal mają pierwszeństwo. Pominięcie
nie jest Again; „nie wiem” po jawnym zatwierdzeniu jest błędem i pokazuje rozwiązanie.
Jedna aktywna automatyczna seria pozwala wznowić diagnozę bez równoległej
rezerwacji nowości. W interfejsie podać rzeczywistą liczbę dostępnych pytań.

Wynik: „zaobserwowano poprawne odpowiedzi” oraz „warto powtórzyć”, z liczbą
obserwacji i formatem. „Utrwalanie” wymaga poprawnej odpowiedzi po terminie,
a nie tej samej minuty po pokazaniu rozwiązania. Wyliczona retencja FSRS jest
estymacją modelu, nie procentem faktycznie opanowanej geografii.

Przed rozwojem rekomendacji sprawdzić przykłady i testy z kontrolowanym zegarem;
nie dopisywać sztucznych ocen ani ustawiać długich interwałów za deklarację „znam”.

## Wdrożony fundament postępów

Ekran Postępy jest dostępny z Dziś. Pokazuje każdą umiejętność oddzielnie,
trzy proste stany, termin i liczbę ocenionych prób. Nie wdrożono jeszcze
opcjonalnej diagnozy ani automatycznej rekomendacji poziomu. Pomoc z nazwanej
listy nie jest oceną lokalizacji i jest wyłączona z aktualizacji pamięci.
