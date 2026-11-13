# GeoKuna — wymagania

Cel: codzienna nauka geografii przez mapę, aktywne przypominanie i powtórki.
Android, język polski, bez konta i backendu. Maskotka: kuna leśna.

## Aktualny przyrost (0.4)

51 państw w szerokim zakresie edukacyjnym Europy. Pełna lista i reguły
państw transkontynentalnych: `CONTENT_POLICY.md`. Poprzedni przyrost obejmował
15 państw; ich identyfikatory, postępy i rozpoczęte sesje pozostają zgodne.

- Dziś: rozpoczęcie/wznowienie mieszanej serii, liczba powtórek i nowych pytań.
- Pamięć Kuny: 204 niezależne umiejętności, FSRS, zaległe najpierw, do 3 nowych
  w dziennych wyprawach na lokalny dzień. Do 10 pytań, bez powtórzenia państwa.
  Ręczny trening mapy i stolic pozostaje dostępny. Zasady: MEMORY.md.
- Atlas: mapa, przybliżanie/przesuwanie, wybór i nazwa państwa.
- Trening: 10 różnych pytań „Gdzie leży Polska?” / „Gdzie leżą Niemcy?”, wybór na mapie, zatwierdzenie,
  poprawna/błędna odpowiedź, wskazanie rozwiązania i podsumowanie.
- Małe państwa: siedem neutralnych znaczników; przy nakładaniu najpierw
  przybliżenie, dopiero potem zaznaczenie i zatwierdzenie. Nazwy na mapie
  ukryte podczas quizu. Wybór z listy atlasu przybliża państwo.
- SQLite: rozpoczęta sesja, kolejność pytań, odpowiedzi, czas zatwierdzenia.
- Błąd zapisu jest widoczny i pozwala ponowić zapis bez duplikatu.

Akceptacja: 10 pytań można ukończyć offline; restart przywraca pozycję
sesji i już ocenioną odpowiedź; kolejny zapis tego samego pytania nie
tworzy drugiej próby. Postępy liczone z zapisanych odpowiedzi.

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

## MVP docelowe

Europa; lokalizacje, stolice, waluty, języki urzędowe; mapa, wybór i wpisywanie.
FSRS per umiejętność i kierunek, adaptacyjne sesje, cztery zakładki:
Dziś / Atlas / Powtórki / Postępy. Kontrola wieloznacznych odpowiedzi.
Nie ma generowania odpowiedzi przez AI w działającej aplikacji.

Poza 0.4: pełne postępy i słabe punkty, waluty i języki, konta, chmura,
rankingi, powiadomienia, rozbudowane animacje, trening teleturniejowy.
