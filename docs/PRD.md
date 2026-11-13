# GeoKuna — wymagania

Cel: codzienna nauka geografii przez mapę, aktywne przypominanie i powtórki.
Android, język polski, bez konta i backendu. Maskotka: kuna leśna.

## Aktualny przyrost (0.4)

51 państw w szerokim zakresie edukacyjnym Europy. Pełna lista i reguły
państw transkontynentalnych: `CONTENT_POLICY.md`. Poprzedni przyrost obejmował
15 państw; ich identyfikatory, postępy i rozpoczęte sesje pozostają zgodne.

- Dziś: rozpoczęcie/wznowienie mieszanej serii, liczba powtórek i nowych pytań.
- Pamięć Kuny: 408 niezależnych umiejętności, FSRS, zaległe najpierw, do 3 nowych
  w dziennych wyprawach na lokalny dzień. Do 10 pytań, bez powtórzenia państwa.
  Ręczny trening mapy, stolic i flag pozostaje dostępny. Zasady: MEMORY.md.
- Atlas: mapa, przybliżanie/przesuwanie, wyszukiwanie i nazwana lista państw.
- Postępy: osiem formatów osobno, wyszukiwanie i filtry; stany „Za mało danych”,
  „Ćwiczysz” i „Do powtórki”, bez deklaracji trwałego opanowania.
- Trening mapy: 10 różnych pytań „Gdzie leży Polska?” / „Gdzie leżą Niemcy?”.
  Kliknięcie państwa od razu zapisuje próbę; do trzech różnych państw bez
  przycisku potwierdzenia. Rozwiązanie po trafieniu lub trzecim błędzie.
  FSRS ocenia pierwszą próbę raz; późniejsze trafienie pozostaje ćwiczeniem.
- Małe państwa: siedem neutralnych znaczników; przy nakładaniu najpierw
  przybliżenie, dopiero potem wybór państwa jako odpowiedź. Nazwy na mapie
  ukryte podczas quizu. Wybór z listy atlasu przybliża państwo.
- SQLite: rozpoczęta sesja, kolejność pytań, odpowiedzi, czas zatwierdzenia.
- Błąd zapisu jest widoczny i pozwala ponowić zapis bez duplikatu.

Akceptacja: 10 pytań można ukończyć offline; restart przywraca pozycję
sesji, częściowe próby mapy i już ocenioną odpowiedź; ponowne wysłanie
tej samej próby nie zużywa szansy ani nie dubluje oceny FSRS. Postępy liczone z zapisanych odpowiedzi.

## Stolice i wygoda mapy

- Trzy wybierane poziomy: A–D / pierwsza litera i dopisywanie reszty /
  puste pole do wpisania całej nazwy. Każdy poziom ma osobną sesję do wznowienia.
- Jedna literówka dozwolona w trybach pisanych. Poprawna pisownia widoczna
  w informacji zwrotnej. Wielkość liter i diakrytyka nie wpływają na ocenę.
- Dane 51 stolic ze źródłami; jawne pytania o Szwajcarię i Holandię.
- Stan pytań i opcji A–D nie zmienia się po restarcie. Historia przechowuje poziom.
- Kuna z globusem (wybrany wariant 1) po prawej stronie „Kuna wie, gdzie!”.
- Pytanie mapowe lekko przybliża region celu, np. Bałkany dla Kosowa.
  Widać wiele państw; cel nie jest automatycznie zaznaczany. Reset przywraca Europę.

## Flagi i informacja zwrotna

- 51 lokalnych flag w oryginalnych proporcjach, bez pobierania podczas quizu.
- Flaga → państwo: A–D, pierwsza litera, pełne wpisanie. Flaga → mapa:
  trzy próby jak w zwykłym quizie mapy. Każdy format ma osobną kartę FSRS.
- Nazwa kraju nie może występować w opisie semantycznym flagi ani nagłówku
  pytania o jej lokalizację. Źródła i kontrola paczki: FLAGS.md.
- W stolicach i nazwach państw błędna odpowiedź jest czerwona, rozwiązanie
  zielone, zaakceptowana literówka żółta. Kolor uzupełniają tekst i ikona.
- Jawne zakończenie quizu zachowuje zapisane próby i pokazuje częściowy wynik.
  Zwykły powrót pozostawia serię do wznowienia.

## MVP docelowe

Europa; lokalizacje, stolice, flagi, waluty, języki urzędowe; mapa, wybór i wpisywanie.
FSRS per umiejętność i kierunek, adaptacyjne sesje, cztery zakładki:
Dziś / Atlas / Powtórki / Postępy. Kontrola wieloznacznych odpowiedzi.
Nie ma generowania odpowiedzi przez AI w działającej aplikacji.

Poza bieżącym przyrostem: opcjonalna diagnoza, eksport postępu, wybór zakresu,
państwo → flaga, Polska i kolejne kontynenty, waluty i języki. Konta, chmura,
rankingi i rozbudowane animacje nie są bieżącymi priorytetami.
