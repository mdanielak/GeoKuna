# Przegląd nauki, osiągnięcia i reset

## Wskaźnik kontynentu

„Na bieżąco X%” to liczba kart w stanie „Ćwiczysz” podzielona przez wszystkie
oceniane karty danego kontynentu. Stan wymaga zapisanej zastosowanej oceny
FSRS, ostatniej poprawnej odpowiedzi i terminu następnej powtórki w przyszłości.
„Do powtórki” oznacza zaległy termin lub ostatni błąd; „Za mało danych” — brak
ocenionego przeglądu. Wynik zaokrąglamy w dół; 100% nie pojawia się, jeśli choć
jedna karta nie spełnia warunków. To stan treningu, nie prawdopodobieństwo
zapamiętania ani wynik testu wejściowego.

Liczymy 12 oddzielnych umiejętności na kraj: po trzy poziomy lokalizacji,
stolicy, flagi → nazwa oraz flagi → mapa. A–D jest ocenianym rozpoznawaniem
z własną kartą FSRS i nie uzupełnia karty samodzielnego pisania.
Europa ma 612 kart, Afryka 648, Azja 600; wspólne kraje Europy i Azji mają
kanoniczną pamięć, więc sum kontynentów nie należy dodawać jako niezależnych kart.
W Dziś wybrany poziom ogranicza wybór pytań; przegląd kontynentu pokazuje
wszystkie poziomy. Na mapie liczy się pierwsza próba; dalsze służą ćwiczeniu.

Moja nauka → kontynent pokazuje kraje wymagające nauki, a szczegóły — formaty,
poziomy i terminy. Nierozpoczęte karty znajdują się w mianowniku.

## Medale

Brąz, srebro i złoto oznaczają osiągnięcie odpowiednio **50%, 80% i 100%**
zaliczonych krajów w całym katalogu kontynentu dla tej samej kategorii, kierunku
i poziomu. Rozpoznawanie w A–D ma osobną ocenę. Nie jest to procent poprawnych
odpowiedzi w jednym quizie. Warunkiem zaliczenia jest dwukrotna poprawna pierwsza
odpowiedź z zastosowaną oceną FSRS w różne lokalne dni, co najmniej 24 godziny
od siebie, bez błędu pomiędzy. Pomyłka wymaga ponownego utrwalenia; zbyt
wczesna poprawna próba bez zastosowania FSRS nie wystarczy.

Zaliczenie normalnego poziomu liczy się także w dwóch łatwiejszych poziomach
tej samej kategorii; łatwy zalicza bardzo łatwy. To stan osiągnięcia, a nie
kopiowanie ocen lub terminów FSRS. Każdy kraj liczymy tylko raz w mianowniku.
Medal zdobyty przy danym progu pozostaje historycznym osiągnięciem; osobny
bieżący stan może pogorszyć się po błędzie lub gdy nadejdzie powtórka. Data
medalu i wersja katalogu są zapisane. Medale nie są gwarancją trwałej pamięci.

## Passa

Na stronie głównej widnieje passa wybranego kontynentu. Każdy kontynent ma
osobne dni aktywności, aktualną i najdłuższą serię; jej poziomy i kategorie są
wspólne. Dzień liczy się po pierwszej zapisanej odpowiedzi, także błędnej lub
A–D. Otworzenie aplikacji nie zalicza dnia. Ta sama próba i kolejne strzały w to
samo pytanie nie naliczają dnia ponownie. Kontynent wybierany jest według sesji,
a nie na podstawie kraju współdzielonego z innym regionem.

Zapis zawiera lokalną datę i offset z chwili odpowiedzi oraz czas UTC. Zmiana
strefy nie przelicza dawnych wpisów. Przerwanie serii nie usuwa rekordu ani
medali i nie utrudnia powtórek. Urządzenie offline korzysta z własnego zegara.

## Reset

Ustawienia → Zresetuj naukę: aplikacja wymaga potwierdzenia i ostrzega, że
operacji nie można cofnąć. Regionalny reset usuwa sesje, próby, karty pamięci,
medale i passę wybranego kontynentu. Kraje wspólne z innym regionem mają wspólne
karty, więc ich pamięć też się wyczyści; nie kasuje to passy drugiego regionu.
Historia sesji innego kontynentu nie odbudowuje automatycznie usuniętej pamięci.

Reset całej nauki usuwa wszystkie powyższe dane oraz metadane importu. Operacje
są transakcyjne. Ustawienia wyglądu i poziomów pozostają zachowane. Web i Android
mają osobne magazyny; reset w przeglądarce nie resetuje telefonu.
