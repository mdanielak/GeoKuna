# Audyt UI/UX GeoKuny — 2026-11-13

## Zakres i metoda

Aktualna aplikacja Flutter Web, cel projektu: telefon Android. UI/UX Pro Max
użyto do mobilnej hierarchii, dotyku, responsywności i układu Flutter; audyt
Product Design do powiązania ustaleń z rzeczywistymi ekranami. Nie projektowano
nowej marki. Zachowano Material 3, krem/zieleń i wybraną kunę.

Wersja Web zbudowana bez zdalnego CDN. Chrome 154, viewport 390×844, dodatkowo
Dziś 320×640 i 800×900. Osobny tymczasowy profil nie dotykał danych użytkownika.
Sterowanie CDP z istniejących narzędzi Python; nie instalowano narzędzi.
Pierwotne połączenie z uruchomionym debug Chrome przestało odpowiadać, więc
końcowy audyt wykonano w krótkiej sesji headless Chrome i zakończono ją.

Zrzuty zapisano i otwarto przed przyjęciem jako dowodu w
`/tmp/geokuna-audit-04/`. Są lokalnymi artefaktami audytu, nie częścią repozytorium.
Odrzucono pierwsze błędnie opisane zrzuty mapy: ujawniły zachowanie starego
pytania po zmianie URL. Po poprawce routingu przechwycono mapę ponownie.

## Przebieg i ocena

| Krok | Ekran / dowód | Ocena i ustalenie |
|---|---|---|
| 1 | Dziś — `01-today.png` | Czytelne główne działanie, rzeczywista seria 3 nowych; ręczne tryby niżej. |
| 2 | Poziom stolic — `02-capital-setup.png` | Trzy zrozumiałe wybory; opis literówek jest długi, ale poza właściwym quizem. |
| 3 | Stolica A–D — `03-capital-question.png` | Duża nazwa państwa i krótkie „Stolica?” poprawiają hierarchię; cztery pełne opcje. |
| 4 | Ocena stolicy — `04-capital-feedback.png` | Poprawna odpowiedź i własna próba czytelne; użytkownik sam wybiera następne pytanie. |
| 5 | Odświeżenie — `05-capital-resume.png` | Zachowany oceniony feedback; restart nie nadpisuje próby ani nie losuje opcji. |
| 6 | Mapa przed wyborem — `06-map-question.png` | Mapa wypełnia obszar pod paskiem; krótki nagłówek, kontrolki odsunięte od pytania, brak przycisku potwierdzenia. |
| 7 | Zaznaczenie — `07-map-selection.png` | Wybrane państwo wyróżnione; „Potwierdź” dostępne na dole. Sam wybór nie jest zapisem. |
| 8 | Ocena mapy — `08-map-feedback.png` | Widoczne poprawne miejsce i tekst rozwiązania, a więc informacja nie opiera się wyłącznie na kolorze. |
| 9 | Atlas — `09-atlas.png` | Widoczna mapa, zoom/reset i przewijalna lista państw; lista jest dość gęsta. |
| 10 | Dziś 320×640 — `10-small.png` | Przycisk i pozostałe wejścia mieszczą się; długa etykieta poprawnie przechodzi do dwóch wierszy. |
| 11 | Dziś 800×900 — `11-wide.png` | Treść ma ograniczoną szerokość; zachowana ta sama hierarchia. |

Po potwierdzeniu stolicy sprawdzono odświeżenie i zachowanie feedbacku.
Po przejściu do mapy sprawdzono wybór oraz jawne potwierdzenie błędnego państwa.
Końcowy przebieg pozostałych ekranów: brak zarejestrowanych wyjątków JavaScript.
Test widgetu dodatkowo sprawdza Dziś na 320×640 z tekstem 200%, a test mapy:
ponad 90% dostępnej wysokości, zoom klastra bez potwierdzenia i zapis po przycisku.

## Najważniejsze poprawki wykonane w tym przyroście

- Mapa zamiast okna o wysokości 43% ma cały obszar quizu. Usunięto rozbudowane
  instrukcje i przycisk bez wybranej odpowiedzi. Nagłówek nie zasłania zoomu.
- W stolicach kraj jest najważniejszą informacją. Usunięto mały wiersz
  „Cypr · Łatwy” i powtarzanie ogólnego pytania. Pytania szczególne pozostają
  zgodne z faktem: siedziba władz Szwajcarii i stolica konstytucyjna Holandii.
- Dziś rozróżnia nową serię, wznowienie i brak pytań. Aktywna seria pokazuje
  pozostałe pytania; termin następnej powtórki zawiera lokalną godzinę.
- Poprawiono błąd zmiany parametrów `/learn`: nowy format nie zachowuje
  starego pytania. Osobny test regresji miał potwierdzone RED i GREEN.

## Priorytety przed rozszerzaniem treści

1. **Dostępność mapy — wysoki.** Powtarzający się opis znaczników i brak
   równoważnego wyboru poligonu czytnikiem ekranu. Potrzebna dostępna alternatywa,
   jawna polityka podpowiedzi i próba na TalkBack. Sam screenshot nie dowodzi
   dostępności. Szczegóły i ścieżki: CODE_REVIEW.md.
2. **Odporność Dziś — średni.** Błąd bazy/stolic może ukryć wejście do niezależnego
   atlasu. Zostawić tę nawigację dostępną obok lokalnego komunikatu błędu.
3. **Informacja o postępie — średni.** Nie ma jeszcze czytelnego widoku słabych
   punktów ani diagnozy; nie zastępować ich punktami lub procentem „opanowania”.
4. **Gęstość atlasu — do pomiaru.** Sprawdzić rzeczywiste obszary dotyku chipów,
   większy tekst i wyszukiwanie po dodaniu większej liczby obiektów. Nie wnioskować
   rozmiaru celu wyłącznie z widocznej ramki.
5. **Opis wyboru poziomu — niski.** Skrócić do jednej informacji o literówce,
   szczegóły przenieść pod „Jak sprawdzamy odpowiedzi”, jeśli obserwacja użycia
   potwierdzi, że tekst przeszkadza.

## Granice weryfikacji

To audyt bieżących ekranów, nie badanie z użytkownikami ani certyfikat WCAG.
Klawiatura ekranowa Androida, gest Wstecz, TalkBack, natywne SQLite i wydajność
na fizycznym telefonie pozostają niesprawdzone. Podsumowania i wszystkie
formaty pisania objęto testami widgetów, ale nie odtwarzano każdego z nich
wizualnie w końcowej sesji Chrome. Nie sprawdzano długoterminowej retencji.
Przegląd źródeł i ryzyk implementacji: [CODE_REVIEW.md](CODE_REVIEW.md).
