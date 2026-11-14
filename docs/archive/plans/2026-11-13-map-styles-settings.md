# Trzy style mapy i ustawienia poziomu

Użytkownik wybrał wszystkie trzy koncepcje, z domyślną rzeźbą terenu. Zakres
zlecony do implementacji; bez ponownego zatwierdzania tego samego planu.

## Kontrakt

- Globalny styl: atlas / papier / relief. Wygląd zmienia się w atlasie i quizie,
  bez zmiany geometrii, kadru, hit-testu, stanu odpowiedzi i oceny FSRS.
- Relief to prawdziwe lokalne dane kartograficzne z licencją i źródłem;
  podglądy imagegen nie są geometrią ani warstwą danych aplikacji.
- Poziom osobny dla Europy/Afryki/Azji: bardzo łatwy=choice, łatwy=firstLetter,
  normalny=write (domyślny). Wspólny dla treningu stolic i nazw państw z flag.
- Ustawienie wybiera poziom nowych ręcznych treningów. Zaplanowane powtórki
  zachowują format i pamięć; A–D nadal bez punktacji wiedzy i FSRS.
- Preferencje trwale w lokalnej bazie, osobna tabela; migracja v5→v6 bez utraty
  danych. Reset nauki nie usuwa wyglądu ani preferencji poziomów.
- Usuwamy nazwany wybór z pomocą z quizu, pozostaje wyszukiwarka atlasu,
  klawiatura mapy i historyczne oznaczenia pomocy.

## Wykonanie

- [x] Sol: test trwałości/per-kontynent/defaultów/resetu, model/store/provider,
  migracja, routing domyślnych poziomów, renderer stylów i integracja mapy.
- [x] Terra: realny public-domain relief, reprojekcja regionalna do EPSG3857,
  lokalne obrazy i manifest, walidator bez sieci, licencja/źródła.
- [x] Luna: ustawienia stylów i poziomów, uproszczone setupy quizów, usunięcie
  listy pomocy, testy małego ekranu i niezależnych poziomów.
- [x] Sol: Chrome jednej sesji telefonu — trzy style i ustawienia; testy i
  analiza przy integracji, walidatory, dokumentacja.

Brak nowej zależności Fluttera, globalnej konfiguracji, emulatora i automatycznego commita.
