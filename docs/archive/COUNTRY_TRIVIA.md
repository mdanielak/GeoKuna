# Ciekawostki o krajach

Lokalna paczka `assets/content/country_trivia.json` zawiera po trzy krótkie
fakty dla każdego kanonicznego identyfikatora w katalogach Europy, Afryki i Azji:
148 państw/obszarów edukacyjnych, 444 fakty. Wspólny kraj korzysta z jednej
paczki. To dodatkowa informacja po odpowiedzi, bez wpływu na ocenę, FSRS,
terminy powtórek i wynik quizu. Nie jest zewnętrznym źródłem danych w runtime.

Każdy rekord ma trwałe `id`, polski tekst, tytuł i adres źródła oraz datę
sprawdzenia `checked`. Zmiany merytoryczne należy ocenić i zaktualizować wersję
paczki; nie usuwać ani nie zmieniać istniejących identyfikatorów bez powodu.
Zapisane rekordy są krótkimi parafrazami, z różnorodnymi danymi geograficznymi
i wybranymi faktami o dziedzictwie oraz nauce; większość dotyczy geografii.

## Pochodzenie i ograniczenia

- CIA World Factbook, historyczne profile udostępnione w archiwum
  [factbook/factbook.json](https://github.com/factbook/factbook.json), przypięte
  do `144d6977b2b01ac1cbd220de754c0a005616760b`. Podstawowy zbiór CIA jest
  w domenie publicznej; archiwum oznaczono CC0. Dane geograficzne pochodzą ze
  wskazanych w rekordach profili. To archiwum, nie bieżąca aktualizacja; wysokości
  i klasyfikacje mogą się różnić między pomiarami i wymagają okresowego przeglądu.
- [UNESCO World Heritage Centre](https://whc.unesco.org/en/list/): opisy
  obiektów dziedzictwa. Ich opisy są udostępniane na licencji CC BY-SA IGO 3.0;
  każdy użyty obiekt ma własny adres w rekordzie. Wybrane dane ustalono na podstawie
  oficjalnego katalogu UNESCO; teksty w paczce są krótkimi polskimi parafrazami.
- [National Technical Museum w Czechach](https://plasy.ntm.cz/en/about-our-museum/ntm-museums/museum-of-industry/history-of-contact-lenses):
  informacja o miękkich soczewkach Ottona Wichterlego.
- Lokalne źródła urzędowe: rząd Cypru oraz Akademia Wojskowa w Belgradzie,
  podane w odnośnikach przy odpowiednich faktach.

Obszary sporne opisujemy geograficznie, bez rozstrzygania granic lub uznania.
Dla Palestyny podajemy osobno informacje o Zachodnim Brzegu i Strefie Gazy.
W razie późniejszych zmian nazw, granic albo wątpliwych wysokości należy
zweryfikować źródło przed publikacją nowej wersji. Kontrola automatyczna nie
zastępuje sprawdzenia znaczenia twierdzeń przez człowieka.

## Kontrola i wybór

`python3 tools/data_pipeline/build_trivia.py --check` offline sprawdza pełne
pokrycie trzech katalogów, po trzy różne rekordy na kraj, unikalność identyfikatorów,
wersję, datę, tytuł i poprawną postać adresu źródłowego. Pole `--allow-incomplete`
służy tylko do roboczej kontroli niedokończonej paczki; nie oznacza gotowości.
Walidator nie pobiera stron i nie potwierdza prawdziwości tekstów.

`CountryTriviaCatalog.load()` wczytuje dane z paczki aplikacji. `factsFor(id)`
zwraca listę, a `pick(id, seed: ...)` wybiera deterministycznie jedną z trzech
ciekawostek za pomocą ograniczonego hasha. Stabilny identyfikator sesji i pytania
jako seed zachowuje ten sam wybór po wznowieniu; różne sesje mogą dać inne fakty.
Nieznany identyfikator zwraca `null`, aby brak danych nie blokował quizu.
