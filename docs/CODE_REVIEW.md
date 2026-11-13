# Przegląd kodu GeoKuny — 13 listopada 2026

Zakres: statyczny przegląd repozytorium ze szczególnym uwzględnieniem sesji,
FSRS, bazy, dostępności i kosztu odświeżania. Nie jest to dowód poprawności
całego produktu. Równolegle trwały zmiany UI; numery wierszy odnoszą się do
stanu podczas przeglądu. Kontrolę wizualną Chrome prowadzi osobno Luna/Sol.

## Historyczne ustalenia według priorytetu

Stan po poprawkach znajduje się w końcowych sekcjach. Numery wierszy poniżej
są historyczne i nie wskazują aktualnych lokalizacji kodu.

### Wysoki — mapa nie ma równoważnej obsługi czytnikiem ekranu

W `lib/features/atlas/country_map.dart:117` poligony są wybierane gestem,
bez osobnych nazwanych akcji semantycznych. Znaczniki małych państw mają
wszystkie ten sam opis „Małe państwo — znacznik” (`:146`), więc samą
semantyką nie da się ich odróżnić. W `learning_screen.dart` użytkownik przed
zatwierdzeniem otrzymuje tylko informację, że wybrano państwo, bez jego nazwy.
To bariera dla osób korzystających z czytnika i utrudnienie w kontroli
przypadkowego wyboru. Zaprojektować dostępną alternatywę wyboru i informację
o bieżącym wyborze, nie ujawniając celu pytania. Sprawdzić drzewo semantyki,
klawiaturę i faktyczny czytnik na fizycznym Androidzie; samo nazwanie znaczników
nie rozwiąże dostępności poligonów. Oddzielić wpływ ewentualnych wskazówek na
ocenę umiejętności.

### Średni — zakres zapisu migawki mapy nie odpowiada opisowi wznowienia

`session_repository.dart:88` zapisuje dla treningu mapy identyfikatory, ale nie
nazwy ani geometrię; dla dziennej mapy `:344` zapisuje temat, poziom i ID.
`learning_screen.dart` odczytuje pytanie i rysuje mapę z bieżącego katalogu.
Po zmianie katalogu aktywne pytanie mapowe może więc wyglądać inaczej, a
usunięcie ID może uniemożliwić wznowienie. Stolice zapisują fakty i opcje
(`session_repository.dart:134`), ale stwierdzenie w `docs/MEMORY.md` o
zachowaniu faktów wymaga doprecyzowania dla map. To ryzyko aktualizacji
zawartości, nie potwierdzona awaria obecnej paczki. Ustalić kontrakt wersji
mapy i zgodności ID oraz test aktualizacji zawartości z aktywną sesją; nie
usuwać ani nie przepisywać istniejącego postępu.

### Średni — pełna dostępność funkcji zależy od załadowania stolic

`home_screen.dart` pokazuje wszystkie wejścia dopiero po powodzeniu
`dailyOverviewProvider`; ten w `lib/app/providers.dart:46` wymaga zarówno
katalogu, jak i stolic. Błąd paczki stolic lub odczytu bazy ukrywa także wejście
do atlasu i treningu mapy. Scenariusz jest warunkowy, ale komunikat ponawiania
nie oferuje obejścia. Rozdzielić obsługę błędu dziennej wyprawy od niezależnej
nawigacji; testem zasymulować błąd providera i sprawdzić dostęp do atlasu.

### Średni — niezweryfikowany koszt cyklicznej pracy bazy

`lib/app/providers.dart:44` odświeża przegląd co minutę, a
`session_repository.dart:255` za każdym razem wykonuje kolejno `INSERT OR
IGNORE` dla czterech kart każdego państwa, obecnie 204 operacje, w transakcji.
Przegląd wykonywany jest również po odpowiedziach. To konkretny zbędny ruch
bazy, ale bez pomiaru nie przesądza o zacięciach. Zmierzyć czas i liczbę
operacji na istniejącej bazie; rozważyć jednorazowe lub zbiorcze zapewnienie
kart z zachowaniem poprawności po aktualizacji katalogu i istniejących ID.
Sprawdzić oddzielnie natywne SQLite i magazyn WASM przeglądarki.

### Niski — sprzeczna dokumentacja FSRS (poprawiono)

`docs/CAPITALS.md:36` twierdzi, że wyniki jeszcze nie wyznaczają terminów,
choć `lib/features/learning/memory.dart:95` zapisuje przeglądy i planuje karty,
a `docs/MEMORY.md` opisuje bieżącą wersję. W ramach integracji poprawiono opis
w CAPITALS.md i doprecyzowano migawkę mapy w MEMORY.md; zasady oceniania bez zmian.

## Co sprawdzono i czego nie stwierdzono

Z kodu wynika, że zatwierdzenie, zapis karty i dziennika odbywają się w jednej
transakcji repozytorium; klucz `(session_id, question_index)` i sprawdzenie
istniejącej próby chronią ponowne wysłanie. Import historii wywoływany jest
w transakcjach repozytorium i zachowuje format próby. Wybór dzienny liczy
budżet od lokalnej północy i najpierw dobiera zaległe karty; osobne formaty
mają osobne ID. To obserwacje z kodu, nie niezależny dowód braku błędów.

Warto uzupełnić testy o zmianę dnia i strefy/DST, wznowienie sesji przez
północ, częściowo zakończony import po wymuszonym błędzie, równoczesne próby,
oraz aktualizację paczki przy aktywnej sesji. Weryfikować wymagany kontrakt,
nie kopiować algorytmu FSRS. Nie uruchamiano testów ani analizy w ramach tego
przeglądu; wcześniejsze wyniki nie są tu przedstawiane jako własny dowód.
Nie testowano przeglądarkowego WASM ani fizycznego Androida; migracja natywnego
SQLite nie dowodzi działania magazynu przeglądarki. Brak pomiaru wydajności i
brak pełnego audytu źródeł geograficznych.

## Błąd potwierdzony w audycie przeglądarki — poprawiono

Bezpośrednia zmiana `/learn?topic=capitals&level=...` na `/learn` zachowywała
stan poprzedniego `LearningScreen`: nagłówek wskazywał mapę, ale pozostawało
pytanie o stolicę. Powód: router ponownie używał stanowego widgetu z innymi
parametrami, a `_initial` był inicjalizowany wyłącznie w `initState`.
W `lib/app/app.dart` nadano klucz zależny od URI, aby zmiana formatu tworzyła
nowy stan ekranu i wznawiała właściwą sesję z repozytorium. Test regresji
`test/learning_route_test.dart` najpierw odtworzył błąd, następnie sprawdza
przejścia pisanie → mapa → A–D bez zapisywania jakiejkolwiek odpowiedzi.

## Korekta mapy podczas testu zakończenia quizu

Chrome debug zgłosił `Infinite loop going beyond 30` z
`flutter_map` 8.3.2 (`FeatureLayerUtils.workAcrossWorlds`), a następnie błędy
MouseTracker. Na ekranie zostały znaczniki bez poligonów. Ustawienie mapy
regionalnej na pojedynczy świat Mercatora (`replicatesWorldLongitude=false`)
omija powtarzanie kopii regionu, zachowując dotychczasową projekcję. Nie
modyfikowano cache pakietu, zależności ani globalnej konfiguracji.

Mechanizm zapętlonego powielania potwierdza log i kod biblioteki; przyczyny
różnicy pomiędzy debug i wcześniejszym release nie rozstrzygnięto. Przed
prawdziwą mapą świata i geometrią przekraczającą południk 180° trzeba ponownie
ocenić strategię powielania i kadrowania. Regionalne obejście nie zastępuje
rozwiązania tego przyszłego wymagania.

## Aktualizacja po wdrożeniu rekomendacji UX

Zależność całej nawigacji od Dziś usunięto: stan async dotyczy tylko karty.
Dostępne wejście do mapy uzupełniono o klawiaturę oraz nazwaną listę jako pomoc,
która nie aktualizuje FSRS. Nie oznacza to pełnej dostępności poligonów ani
równoważnego testu przestrzennego dla czytnika ekranu; potrzebne są późniejsze
próby na TalkBack. Ograniczenie migawki mapy pozostaje otwarte. Zapewnianie kart zmieniono
na zbiorczy zapis opisany poniżej.

## Stan po przyroście flag i trzech prób mapy

- Produkcyjny katalog zawiera 408 kart. Zapewnianie kart korzysta z jednego
  `db.batch` z `insertAll`/`insertOrIgnore`, zamiast kolejnych wywołań async
  dla każdej karty. Nie jest to pomiar wydajności na Androidzie.
- `map_guesses` przechowuje do trzech różnych wyborów i odtwarza częściowe
  pytanie. Pierwszy wybór zapisuje ocenę FSRS, kolejne jej nie nadpisują.
  Wynik końcowy jest osobnym wpisem `attempts`; migracja v3 → v4 zachowuje dane.
- Flagi mają własne ID kart i migawki; testy sprawdzają brak kolizji
  z dotychczasowymi ID oraz zachowanie rozdzielności formatów.
- Wyniki testów, kontroli paczek i ograniczenia runtime: [STATUS.md](STATUS.md).
  Nadal otwarte: wersjonowanie geometrii aktywnej sesji, pomiary na telefonie,
  TalkBack, eksport postępu oraz długoterminowa obserwacja harmonogramu.
