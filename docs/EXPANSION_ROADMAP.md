# Rozwój GeoKuny — zakresy, flagi, Polska i świat

Status: propozycja do kolejnych przyrostów, nie funkcje wdrożone w 0.4.
Cel: poszerzać geografię bez rozbijania istniejących postępów i bez rozbudowanego
menu przed każdą krótką sesją. Rekomendację mechaniki nauki opisuje
[LEARNING_REVIEW.md](LEARNING_REVIEW.md).

## 1. Wybór obszaru na stronie głównej

Rekomendowany układ: u góry niewielki wybór **„Uczę się: Europa ▾”**, pod nim
niezmiennie karta Dziś z jednym głównym działaniem. Dotknięcie otwiera dolny
arkusz: Europa, Polska, Świat oraz pozostałe kontynenty, gdy będą gotowe.
Przy niegotowej paczce pokazać status, zamiast oferować pustą sesję.
Nie dodawać teraz sześciu wielkich kart konkurujących z codzienną powtórką.

Rozważone alternatywy: osobny ekran wyboru przed każdą sesją (za dużo kroków),
lista kontynentów jako główna treść (ukrywa powtórki), zapamiętany wybór na Dziś
(rekomendacja). Ostatni wybór jest lokalnym ustawieniem, nie nowym kontem.

- Liczby i nowa wyprawa dotyczą wybranego obszaru. Mały dodatkowy komunikat
  „W innych obszarach czeka …” zapobiega ukrywaniu zaległości.
- Zmiana obszaru nie usuwa ani nie zeruje kart. Państwo transkontynentalne
  może należeć do kilku zakresów; jego identyczna umiejętność ma jeden stan.
- Budżet nowych pozostaje globalny dla dziennych wypraw, aby przełączenie
  obszaru nie pozwalało przypadkowo wprowadzić kilkudziesięciu nowych kart.
- Aktywna sesja zachowuje własny zakres i migawkę. Przy zmianie obszaru użytkownik
  widzi, którą sesję wznawia; nie podmieniać rozpoczętej kolejki w tle.
- Świat jest zakresem zbiorczym; Polska osobnym pakietem geografii regionalnej,
  a nie kolejnym kontynentem. Kategorie pokazujemy dopiero wewnątrz zakresu.

Akceptacja: przełączenie obszaru, restart, wznowienie starej serii, wspólna karta
na dwóch kontynentach i wspólny limit nowych nie zmieniają lub nie dublują postępu.

## 2. Model danych: mała ewolucja

Dotychczasowe `map:POL:map` i `capitals:POL:write` pozostają ważne. Nie przenosić
historii przez odgadywanie nazw. Dodać katalog paczek i przynależności do zakresów,
a przed pierwszą kategorią inną niż państwa rozdzielić `entity_id` od `country_id`.
Typowane obiekty: państwo, województwo, miasto, park, rzeka, pasmo, szczyt.
Prosta tabela przynależności pozwala na wiele zakresów bez kopii faktów.

Przykłady nowych kluczy (konwencja do zatwierdzenia przy migracji):
`flag:POL:flagToCountry:choice`, `flag:POL:countryToFlag:choice`,
`location:pl-voiv:TERYT_CODE:map`, `location:river:SOURCE_ID:map`.
Nie zmieniać już zapisanych identyfikatorów państw. Każda paczka: wersja,
źródło, data obowiązywania, licencja, SHA-256 i walidator. Geometria oddzielnie
od faktów; obraz flagi również ma własny rekord źródłowy.

Kolejka Dziś filtruje katalog według zakresu, ale scheduler FSRS nadal operuje
na jednej karcie konkretnej umiejętności. Nie budować generycznego silnika
wszystkich możliwych quizów zanim drugi typ obiektu pokaże rzeczywistą potrzebę.

## 3. Flagi: oba kierunki

Pierwszy przyrost: tylko obecne państwa Europy i dwa osobne formaty:

| Kierunek | Ekran | Dowód wiedzy |
|---|---|---|
| flaga → państwo | duża flaga, cztery nazwy państw | rozpoznawanie nazwy z obrazu |
| państwo → flaga | duża nazwa, cztery flagi | rozpoznawanie obrazu z nazwy |
| flaga → wpisz państwo (później) | duża flaga, puste pole | samodzielne przypominanie nazwy |

Oba kierunki mają niezależny FSRS; poprawna odpowiedź w pierwszym nie zalicza
drugiego. Nie nazywać wyboru spośród czterech flag samodzielnym odtworzeniem.
Jeden kraj najwyżej raz w sesji, również między flagą, mapą i stolicą.

Assety lokalne, bez emoji flag: wygląd emoji zależy od platformy. Zachować
oryginalne proporcje, cienką neutralną ramkę dla białych flag, brak rozciągania.
Można przygotować PNG/WebP z przypiętego źródła SVG; nie dodawać nowego
renderera tylko dla kilkudziesięciu obrazów. Nazwa pliku/semantyka nie może
podpowiadać poprawnej opcji. Czytnik ekranu potrzebuje opisów wizualnych i jawnej
polityki dostępności — opis nie jest równoważnym zadaniem wzrokowym.

Paczka rozstrzyga: flaga państwowa czy cywilna, wariant z godłem, data zmiany,
awers/rewers i podobne flagi. Każdy obraz wymaga sprawdzenia licencji u źródła;
nie zakładać wspólnej licencji całego Wikimedia Commons. Dystraktory muszą
być jednoznaczne także po przeskalowaniu. Na start nie wymagać rozróżniania
niemal identycznych miniatur. Feedback: poprawna flaga + nazwa obok siebie.

Akceptacja: cztery różne opcje, poprawna proporcja, brak sieci w quizie,
oddzielne stany kierunków, wznowienie migawki oraz dostępny układ 2×2 na telefonie.

## 4. Polska: w oddzielnych małych paczkach

| Kolejność | Zakres | Format i pułapka do rozstrzygnięcia |
|---|---|---|
| PL-1 | województwa | wskaż województwo na mapie; stabilny kod TERYT |
| PL-2 | miasta wojewódzkie | województwo → miasto, miasto → mapa; jawna rola siedziby władz |
| PL-3 | parki narodowe | nazwa → obszar/znacznik, później obszar → nazwa |
| PL-4 | najważniejsze rzeki | nazwa → przebieg, później wyróżniona rzeka → nazwa |
| PL-5 | pasma i szczyty | osobno zasięg pasma i punkt szczytu; nie mieszać tych obiektów |

Miasta wojewódzkie nie zawsze dają relację jeden-do-jednego. Pytanie musi
określić siedzibę wojewody, sejmiku albo zaakceptować wszystkie właściwe miasta,
a nie wymuszać arbitralnie jednej „stolicy województwa”. Lista i reguły powstaną
z dokumentowanego źródła, nie z pamięci modelu.

Parki wymagają czytelnych celów także na małym ekranie; mały obszar może mieć
neutralny znacznik i przybliżenie. Quiz nie służy wyznaczaniu prawnej granicy
parku ani nawigacji terenowej. Rzeki są liniami, nie punktami: potrzebna tolerancja
dotyku w pikselach ekranu, wyróżnienie zaznaczenia i potwierdzenie. Przy nakładaniu
rzek należy przybliżyć/rozstrzygnąć wybór, zamiast oceniać niedokładność palca.
Nie wypełniać całej Polski setkami nazw i obiektów jednocześnie.

## 5. Świat: wyraźnie ograniczony katalog

Najpierw państwa i stolice kolejnego jednego kontynentu, dopiero później
geografia fizyczna. Dla rzek i gór start od małych list redakcyjnych, np. po
10–15 obiektów, do zatwierdzenia po weryfikacji źródeł.

„Największe” wymaga definicji przed zbudowaniem paczki:

- Rzeki: długość konkretnej rzeki czy całego systemu? Nie łączyć rankingu długości
  z przepływem lub powierzchnią dorzecza. Przypiąć definicję i źródło; nie zadawać
  spornych pytań o jedyne pierwsze miejsce bez podanego kryterium.
- Góry: rekomendacja to dwie kategorie **najwyższe szczyty** i **główne pasma**.
  „Największe pasmo” nie jest tym samym co najwyższy szczyt. Nie rysować pasma
  pojedynczym punktem i nie oceniać dotknięcia całego regionu jak trafienia szczytu.
- Mapa w quizie pokazuje tylko właściwą warstwę oraz niezbędny kontekst.
  Geometria offline, uproszczona do ekranu telefonu i z kontrolą małych obiektów.

## 6. Źródła do przygotowania paczek

Poniżej źródła sprawdzone w czasie planowania; nie oznacza to, że nowe fakty
lub geometrie są już pobrane i zwalidowane.

- [PRG / Geoportal GUGiK](https://www.geoportal.gov.pl/pl/dane/panstwowy-rejestr-granic-prg/):
  granice administracyjne. Przed importem przypiąć datę i warunki użycia pobranej paczki.
- [GUS: podział administracyjny i TERYT](https://stat.gov.pl/statystyka-regionalna/jednostki-terytorialne/podzial-administracyjny-polski/):
  nazwy/kody i aktualny podział; źródło wskazuje coroczne korekty granic.
- [GDOŚ: dane geoprzestrzenne](https://www.gov.pl/web/gdos/dostep-do-danych-geoprzestrzennych):
  formy ochrony przyrody. Dane poglądowe nie są prawnym ustaleniem granic.
- [Natural Earth: warstwy fizyczne 1:50m](https://www.naturalearthdata.com/downloads/50m-physical-vectors/):
  kandydat na ogólną geometrię rzek świata, nie samodzielne źródło rankingu długości.

Źródło flag i dokładnych danych rzek/pasm Polski wymaga osobnego krótkiego
spike'u: dostępność plików, licencja, dokładność i koszt pipeline. Nie dobierać
zależności ani ściągać dużych baz na zapas.

## Kolejność wdrażania i kryterium końca

1. Domknąć obecny FSRS, ergonomię quizów i znalezione błędy; test telefonu później.
2. Dodać diagnozę/podstawowe postępy i bezpieczny eksport historii.
3. Dodać wybór zakresu i paczkę PL-1; to sprawdzi model dla obiektów innych niż państwa.
4. Flagi Europy w dwóch kierunkach; osobna migracja i walidator obrazów.
5. Jeden kolejny kontynent; następnie PL-2/PL-3 i dopiero linie rzek oraz góry.
6. Mała paczka geografii fizycznej świata po ustaleniu kryteriów „największe”.

Każdy etap: krótki brainstorming, wersjonowana paczka, test oceniania i migracji,
jeden ważny przepływ mobilny w Chrome. Żadna nowa kategoria nie zeruje starych kart.

## Decyzje po przeglądzie Astry

Przyjmujemy typowane encje przy PL-1, bez uniwersalnego silnika quizów.
Zakres pozostaje filtrem, nie fragmentem tożsamości karty. Nowe pola encji,
kierunku i formatu są jawne; nie odtwarzać ich przez rozcinanie dowolnego ID.

**Warunek przed flagami/PL-1:** obecny `MemoryScheduler._cardId` rozpoznaje
wyłącznie trzy segmenty oraz cztery obecne formaty. Nowe przykładowe klucze
nie są zgodne z tym adapterem. Migracja musi zachować już zapisane `cardId`
i dodać trwałe unikalne przypisanie liczbowe dla nowych kart; nie wstawiać
nowych kategorii do obecnego parsera bez tej zmiany.

Dziś i przyszła diagnoza współdzielą limit automatycznych nowości. Ręczny
trening pozostaje jawnym wyjątkiem. Próg zaległości blokujący nowości liczymy
globalnie, a nie tylko w aktualnym kontynencie. W pierwszej wersji nadal jedna
aktywna automatyczna seria, aby uniknąć podwójnej rezerwacji tych samych kart.
Po północy wznowienie zalicza wprowadzenie w dniu rzeczywistej odpowiedzi;
nowego planu nie tworzymy równolegle z aktywną serią.

Dla relacji województwo–miasto lub rzeka–region zapobiegać podpowiedziom
przez wspólną grupę ekspozycji faktu, nie tylko identyczne ID encji. Na razie
reguła jednego państwa w serii wystarcza dla istniejącej paczki.
