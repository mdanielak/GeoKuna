# GeoKuna — zapis rozmowy

**Data:** 12 listopada 2026  
**Temat:** Pomysł na aplikację do nauki geografii, MVP, architektura i praca z Codexem.

> **Uwaga o formacie:** To tekstowy eksport odtworzony z treści dostępnej w tej rozmowie. Zachowuje kolejność wypowiedzi, pytania użytkownika i merytoryczną treść odpowiedzi. Interaktywne elementy interfejsu, ilustracje, wykresy i przyciski są zastąpione opisami lub zwykłym tekstem. Nie jest to natywny, bajt-w-bajt eksport danych konta ChatGPT.

---

## 1. Użytkownik

Będę przygotowywał się do udziału w programie VaBankue w dalekiej perspektywnie. Chciałbym stworzyć aplikację na telefon, która ułatwi mi naukę geografii. Może jakaś Geografia z Kuną czy coś. To byłoby coś typu Duolingo, ale pytania dotyczyłyby umiejscowienia krajów na mapie, stolic, języków urzędowych, walut, najdłuższych rzek. Pomóż mi obmyślić jak to zrobić z codexem. Wymyśl nazwę. Chciałbym żeby Sol albo może nawet Astra była "mózgiem operacji", a pracę wykonywał Terra albo Luna. Wymyśl nazwę. Kuna będzie maskotką

---

## 2. Asystent — pomysł na GeoKunę

Mam pomysł na aplikację, która mogłaby być naprawdę świetnym narzędziem do wieloletniego przygotowywania się do **Va Banque!**. Nie robiłbym jednak zwykłego quizu geograficznego. Zbudowałbym coś pomiędzy Duolingo, Anki i interaktywnym atlasem świata — z Kuną jako przewodnikiem.

A najważniejsze: **aplikacja powinna uczyć Cię tego, czego jeszcze nie wiesz, zamiast ciągle zadawać losowe pytania.**

# GeoKuna

*Kuna wie, gdzie!*

To moja propozycja nazwy. Krótka, sympatyczna, łatwa do zapamiętania i potencjalnie dobra również dla aplikacji udostępnionej innym osobom.

Alternatywy to *Kuna na mapie*, *Kuna dookoła świata*, *Kuna Tropicielka* i *Geografia z Kuną*. Jednak **GeoKuna** zdecydowanie wygrywa.

Wyobrażam sobie maskotkę jako sympatyczną, nieco przemądrzałą kunę leśną z małym plecakiem, kompasem i atlasem. Ma osobowość, komentuje postępy, cieszy się z odkryć i czasami żartuje z błędów.

### 2.1. Jak miałaby działać GeoKuna?

Najważniejsza byłaby jedna codzienna sesja, trwająca 5–15 minut. Z każdym dniem aplikacja coraz lepiej rozpoznawałaby Twoje mocne i słabe strony.

**Odkrywanie świata.** Poznajesz nowe państwa, stolice i fakty geograficzne na interaktywnej mapie.

**Inteligentne powtórki.** Algorytm sam decyduje, kiedy ponownie zapytać o coś, co sprawiało Ci trudność.

**Wyzwania i Va Banque!** Ćwiczysz szybkie przypominanie sobie faktów, odpowiadasz bez podpowiedzi i walczysz z czasem.

### 2.2. Kategorie nauki

| Kategoria | Przykładowa mechanika |
|---|---|
| Państwa | Wskaż na mapie Laos, Bhutan lub Surinam |
| Stolice | Jaka jest stolica Erytrei? |
| Języki | W których państwach urzędowym językiem jest portugalski? |
| Waluty | Gdzie obowiązuje ariary? |
| Rzeki | Dopasuj Dunaj do jego ujścia |
| Góry | Znajdź Andy, Karakorum lub Atlas |
| Flagi | Rozpoznaj państwo po fladze |
| Sąsiedzi | Które państwa graniczą z Boliwią? |
| Rekordy świata | Największe jeziora, najdłuższe rzeki, najwyższe szczyty |

Z czasem dodałbym jeszcze wyspy, cieśniny, morza, pustynie, regiony geograficzne, polską geografię oraz geografię historyczną.

W kontekście Va Banque! ważne byłoby też uczenie się *powiązań*. Nie tylko „stolica Mali to Bamako”, ale również gdzie leży Mali, jakie ma państwa sąsiednie, jaka rzeka przez nie przepływa i z jakiego regionu Afryki pochodzi.

### 2.3. Mechanika nauki — czyli Duolingo po kuniemu

Chciałbym, żeby GeoKuna miała trzy główne tryby.

**Odkrywaj.** Mapa podzielona na kontynenty, regiony i lekcje. Zaczynasz od Europy, następnie przechodzisz do Azji, Afryki itd. Odblokowujesz nowe zagadnienia, ale możesz też uczyć się we własnej kolejności.

**Powtarzaj.** Każdy fakt ma własną historię zapamiętywania. Jeżeli znasz stolicę Gruzji, zobaczysz ją znacznie rzadziej niż stolicę Kirgistanu, którą ciągle zapominasz.

**Sprawdź się.** Krótkie rundy z limitem czasu, pytaniami otwartymi i rosnącym poziomem trudności. Osobny tryb treningu teleturniejowego, bez podpowiedzi.

#### Co odróżniałoby ją od zwykłych quizów?

**System zapamiętywania FSRS**, podobny do tego, którego można używać w Anki. Jest już dostępna biblioteka FSRS dla języka Dart, więc nie musimy wymyślać algorytmu od zera.

Przykładowo: wiesz, gdzie leżą Niemcy — aplikacja sprawdza tę wiedzę dopiero po dłuższej przerwie. Nie pamiętasz, gdzie jest Tadżykistan — wraca do niego wcześniej.

Co więcej, każda informacja o państwie będzie ćwiczona niezależnie. Możesz znakomicie znać jego lokalizację, ale nie pamiętać waluty.

W ten sposób GeoKuna stanie się czymś w rodzaju **Twojego osobistego trenera wiedzy geograficznej**.

### 2.4. Najważniejsze ekrany

Przykładowa wizja ekranu głównego:

- Powitanie: „Cześć, odkrywco! Kuna przygotowała Ci dzisiejszą wyprawę”.
- Poznane państwa: przykładowo 67 / 195.
- Do powtórzenia: przykładowo 12 faktów.
- Dzisiejsza wyprawa: 10 pytań / 5 minut.
- Przykładowa lekcja: Azja Środkowa — państwa i stolice.
- Dolna nawigacja: Dziś, Atlas, Powtórki, Wyzwania.

To poglądowy układ i przykładowe dane, nie działająca jeszcze aplikacja.

Wizualnie widziałbym tu połączenie estetycznej mapy, zieleni leśnej, ciepłych beżów i subtelnego humoru. Raczej aplikacja dla dorosłego pasjonata wiedzy niż przesadnie dziecinna gra.

Dodałbym również **Paszport Kuny** — kolekcję pieczątek za opanowane regiony świata oraz osiągnięcia takie jak „Mistrz stolic Afryki”.

### 2.5. Jak to technicznie zbudować?

Polecam **Flutter + Dart**, przede wszystkim z myślą o Androidzie. Flutter obsługuje rozwój aplikacji na Linuksie i Androidzie z jednego projektu, więc dobrze pasuje do Twojego środowiska.

| Element | Technologia |
|---|---|
| Aplikacja mobilna | Flutter / Dart |
| Mapa | GeoJSON + własny interaktywny renderer |
| Dane państw i granic | Natural Earth |
| Dane encyklopedyczne | Wikidata + zweryfikowana lokalna baza |
| Przechowywanie postępów | SQLite / Drift |
| Algorytm powtórek | FSRS |
| Backend | Na początku zbędny |
| Internet | Aplikacja powinna działać offline |

#### Skąd wziąć dane?

**Natural Earth** — https://www.naturalearthdata.com/downloads/

Darmowe dane wektorowe o granicach państw, rzekach, jeziorach i wielu innych obiektach. Dostępne w różnych poziomach szczegółowości, na licencji public domain. Idealny fundament interaktywnego atlasu.

**Wikidata** — https://www.wikidata.org/

Ustrukturyzowana wiedza o państwach, stolicach, językach i walutach. Dane strukturalne Wikidata są udostępniane na licencji CC0.

Kluczowa decyzja: **AI nie powinno wymyślać odpowiedzi podczas quizów**.

Zamiast tego Codex przygotuje sprawdzoną bazę wiedzy, a GeoKuna będzie z niej generować zadania. AI może pomagać w przygotowywaniu pytań i ciekawostek, ale nie będzie arbitrem ich poprawności.

Trzeba też uwzględnić nietypowe przypadki: państwa z kilkoma stolicami, wieloma językami urzędowymi, terytoria zależne oraz sporne granice. Rankingi najdłuższych rzek również wymagają ustalonej metodologii.

### 2.6. Sol, Astra, Terra i Luna — podział pracy

Proponuję wykorzystać prawdziwy system agentów.

- **Astra:** architekt strategiczny — decyzje projektowe, wizja produktu, krytyczny przegląd architektury.
- **Sol:** główny koordynator — planuje zadania, deleguje, integruje i zatwierdza rezultaty.
- **Luna:** UI, ekrany, logika gry, implementacja funkcji.
- **Terra:** import danych, testy, powtarzalne zadania, poprawki.

Wyniki wracają do Sol do przeglądu.

**Moja preferowana konfiguracja:** Astra tylko do początkowego zaprojektowania produktu i trudnych decyzji, Sol jako stały koordynator oraz Luna i Terra jako wykonawcy.

Nie uruchamiałbym Astry do każdej zmiany koloru przycisku. To byłoby niepotrzebne zużycie zasobów.

Codex wspiera subagentów i własne konfiguracje agentów w plikach TOML, z osobnymi modelami oraz instrukcjami. Dostępność konkretnych modeli zależy jednak od Twojego konta i providera.

Przykład agenta implementującego:

`.codex/agents/implementer.toml`

```toml
name = "implementer"
description = "Implementuje funkcje aplikacji GeoKuna"
model = "gpt-6-luna"
model_reasoning_effort = "high"

developer_instructions = """
Realizuj wyłącznie przydzielone zadania.
Stosuj architekturę i konwencje projektu.
Pisz testy do nowych funkcji.
Nie zmieniaj niezwiązanych modułów.
Po pracy raportuj zmiany i wyniki testów.
"""
```

Analogicznie można utworzyć agenta `data_worker`, z modelem Terra, o ile Twój provider go udostępnia. Sol kieruje pracą agentów, a ich instrukcje dodatkowo ograniczają zakres zmian.

### 2.7. Od czego zacząć? MVP

Nie budowałbym od razu całej geografii świata. Na początek stworzyłbym niewielką, ale w pełni działającą wersję.

**Etap 1 — Działająca mapa Europy.** Klikalne państwa, przybliżanie i przesuwanie mapy, podświetlanie odpowiedzi oraz ćwiczenia lokalizacji. Obsługa małych państw.

**Etap 2 — Nauka pięciu kategorii.** Państwa, stolice, flagi, języki urzędowe i waluty. Pytania wielokrotnego wyboru i wskazywanie na mapie.

**Etap 3 — Pamięć Kuny.** FSRS, lokalny zapis postępów, powtórki i codzienny trening. Rozróżnianie zapamiętania stolicy od zapamiętania lokalizacji państwa.

**Etap 4 — Cały świat.** Kolejne kontynenty, rzeki, góry, jeziora, cieśniny, rekordy geograficzne, szczegółowe statystyki oraz bardziej wymagający tryb Va Banque!

Pierwszy etap powinien być grywalny nawet bez gotowej maskotki i całej gamifikacji. To pozwoli wcześnie przetestować najtrudniejszy element: korzystanie z mapy na telefonie.

### 2.8. Pierwszy prompt do Codexa

Tak rozpocząłbym projekt, najlepiej z Solem jako głównym agentem:

```text
Projekt: GeoKuna
Hasło: Kuna wie, gdzie!

Chcę stworzyć aplikację mobilną na Androida do nauki geografii. Inspiracja: Duolingo + Anki + interaktywny atlas. Docelowo aplikacja ma wspierać przygotowania do teleturnieju Va Banque!.

Technologia:
- Flutter / Dart
- lokalna baza SQLite
- mapy wektorowe Natural Earth
- algorytm powtórek FSRS
- offline-first, bez obowiązkowego logowania

Podstawowe funkcje:
- interaktywna mapa z klikalnymi państwami;
- lekcje i quizy dotyczące państw, stolic, flag, walut i języków;
- inteligentne powtórki;
- historia odpowiedzi i statystyki;
- w przyszłości rzeki, góry, jeziora i rekordy geograficzne.

Kuna leśna będzie maskotką i przewodnikiem. Styl ma być nowoczesny, estetyczny, lekko zabawny, ale nie dziecinny. Interfejs w języku polskim.

Twoja rola: główny architekt i koordynator.

Wykorzystaj subagentów do oddzielnych zadań implementacyjnych, testowania i przygotowania danych.

Na początek:
1. Przygotuj PRD z wymaganiami i kryteriami akceptacji.
2. Zaproponuj architekturę i strukturę repozytorium.
3. Zdefiniuj schemat bazy wiedzy i postępów.
4. Rozpisz MVP na małe zadania.
5. Utwórz AGENTS.md i dokumentację projektu.

Zwróć szczególną uwagę na poprawność danych geograficznych, obsługę nietypowych państw i możliwość działania offline.

Nie implementuj jeszcze całej aplikacji. Najpierw przygotuj plan, sprawdź ryzyka i zaproponuj pierwszy mały, działający fragment do wdrożenia.
```

### 2.9. Co zostawiłbym na przyszłość?

Moim zdaniem GeoKuna mogłaby ostatecznie wyrosnąć poza samą geografię. Jeżeli za kilka lat nadal będziesz przygotowywał się do Va Banque!, ten sam system nauki można rozszerzyć o historię, literaturę, sztukę, naukę czy muzykę.

Wtedy **GeoKuna** byłaby pierwszym modułem większego projektu — na przykład *Kuna Wie!*.

To jednak pomysł na znacznie dalszą perspektywę. Na razie najważniejsze byłoby stworzenie aplikacji, do której rzeczywiście będziesz chciał wracać codziennie.

#### Jedna ważna decyzja projektowa

Asystent zaproponował trzy opcje:
- Przede wszystkim nauka przez mapę.
- Przede wszystkim quizy.
- Połączenie obu metod, dobierane inteligentnie przez aplikację.

Asystent preferował wariant trzeci: **GeoKuna powinna przede wszystkim wiedzieć, czego Kuna jeszcze nie wie.**

---

## 3. Użytkownik

Dla projektu GeoKuna wybieram podejście: inteligentne połączenie mapy i quizów. Rozwiń teraz szczegółowy plan MVP, ekranów, mechanik i architektury z myślą o implementacji przez Codex.

---


## 4. Asystent — szczegółowy plan MVP i architektury

# GeoKuna — szczegółowy plan MVP i architektury

*Wersja koncepcji 1.0 · Android · Flutter · Codex*

**GeoKuna — Kuna wie, gdzie!**

Proponuję zbudować GeoKunę jako pełnoprawną aplikację edukacyjną, a nie zbiór niezależnych quizów. Jej główną zaletą będzie połączenie trzech rzeczy: interaktywnego atlasu, systemu długoterminowego zapamiętywania i inteligentnego dobierania kolejnych pytań.

**Kluczowe założenie: Kuna powinna prowadzić Cię od rozpoznawania faktów do ich samodzielnego przypominania sobie.** To ważne w kontekście Va Banque!, gdzie nie wystarczy rozpoznać poprawną odpowiedź spośród czterech możliwości.

### Decyzje projektowe

| Obszar | Wybór |
|---|---|
| Platforma | Android, offline-first |
| Technologia | Flutter + SQLite |
| Nauka | FSRS + adaptacyjne quizy |
| AI w aplikacji | Niepotrzebne w MVP |
| Orkiestracja Codexa | Sol |
| Implementacja | Luna + Terra |

### 4.1. Co dokładnie powinno znaleźć się w MVP?

Podzieliłbym rozwój na trzy wydania.

**MVP 1.0 — Europa.** Pełna mapa Europy, lokalizacja państw, stolice, waluty, języki urzędowe, codzienne sesje, inteligentne powtórki oraz statystyki.

**Wersja 1.1 — Świat.** Wszystkie kontynenty, flagi, stolice, sąsiedzi, znacznie większa baza faktów i poziomy trudności.

**Wersja 2.0 — Trening teleturniejowy.** Rzeki, góry, jeziora, pustynie, cieśniny, rekordy geograficzne, pytania otwarte, limity czasu i rozbudowane wyzwania.

W MVP ograniczamy obszar geograficzny, ale **nie upraszczamy najważniejszego mechanizmu nauki**. Od początku działać muszą: zapamiętywanie postępów, inteligentne powtórki i interaktywna mapa.

### 4.2. Ekrany aplikacji

Wybrałbym cztery główne zakładki w dolnej nawigacji. Ekrany lekcji, pytań i podsumowań byłyby otwierane na pełnym ekranie.

**Dziś.** Najważniejszy ekran. Codzienna wyprawa, liczba faktów do powtórzenia, rekomendowana lekcja, postępy oraz Kuna witająca użytkownika. Jedno główne działanie: *Rozpocznij naukę*.

**Atlas.** Mapa Europy i lista krajów. Wybór państwa otwiera jego profil z położeniem, stolicą, walutą, językami i poziomem opanowania tych informacji. Możliwość uruchomienia lekcji z wybranego regionu.

**Powtórki.** Pytania przygotowane przez algorytm FSRS. Najpierw zaległe i trudne fakty, potem nowe. Możliwość wyboru konkretnej kategorii albo pełnego miksu.

**Postępy.** Opanowane państwa, wiedza według kategorii, historia odpowiedzi, prognoza zapamiętania, najtrudniejsze zagadnienia i dzienna regularność nauki.

*W oryginalnej odpowiedzi pokazano cztery ilustracje poglądowe inspiracji wizualnych: dashboard, mapę, fiszki i statystyki. Nie były gotowymi makietami GeoKuny.*

#### Dodatkowe ekrany

| Ekran | Funkcje |
|---|---|
| Start / onboarding | Wybór poziomu i celu nauki, bez rejestracji |
| Lekcja | Kolejne pytania, pasek postępu, sprawdzanie odpowiedzi |
| Wynik lekcji | Trafność, nowe fakty, popełnione błędy |
| Profil państwa | Fakty, mapa, historia opanowania wiedzy |
| Ustawienia | Dzienny cel, kategorie, wyciszanie animacji, eksport danych |

Nie chciałbym rozbudowanego onboardingu. Najlepiej, żebyś po uruchomieniu aplikacji mógł rozpocząć naukę praktycznie natychmiast.

### 4.3. Rodzaje pytań

W MVP proponuję sześć mechanik.

| Mechanika | Przykładowe pytanie | Odpowiedź |
|---|---|---|
| Lokalizacja | Gdzie leży Słowenia? | Dotknięcie mapy |
| Rozpoznawanie | Jakie państwo jest zaznaczone? | 4 odpowiedzi |
| Stolica | Jaka jest stolica Estonii? | Wpisanie lub wybór |
| Waluta | Jakiej waluty używa Polska? | 4 odpowiedzi |
| Język | Jaki jest język urzędowy Węgier? | 4 odpowiedzi |
| Sąsiedzi | Z którym państwem graniczy Austria? | 4 odpowiedzi |

Ostatnia mechanika wymaga dodatkowych danych o granicach, ale można je wyliczyć podczas przygotowania atlasu i zweryfikować przed wydaniem.

**Każdy fakt powinien mieć kilka sposobów sprawdzania.** Na przykład znajomość Estonii można weryfikować przez wskazanie jej na mapie, rozpoznanie konturu, podanie stolicy albo wskazanie sąsiadów.

Co istotne, aplikacja musi pamiętać je jako oddzielne umiejętności.

### 4.4. Inteligentny silnik nauki — serce GeoKuny

To najważniejsza część projektu. Proponuję, aby GeoKuna korzystała z dwóch współpracujących algorytmów:

- **FSRS** odpowiada za to, kiedy należy powtórzyć konkretny fakt.
- **Adaptive Session Engine** decyduje, jakie pytania znajdą się w dzisiejszej lekcji i w jaki sposób zostaną zadane.

FSRS ma już implementację w Darcie, dostępną na pub.dev.

#### Każda umiejętność jest niezależna

Dla Estonii zapamiętywalibyśmy przykładowo:

| Umiejętność | Stan |
|---|---|
| Lokalizacja Estonii | Opanowana |
| Rozpoznawanie kształtu | Opanowana |
| Stolica Estonii | W trakcie nauki |
| Waluta Estonii | Opanowana |
| Języki urzędowe | Nowa |
| Państwa sąsiednie | W trakcie nauki |

To ważniejsze niż jeden ogólny wskaźnik „znajomość Estonii”.

Aplikacja powinna również rozróżniać **rozpoznawanie** od **przypominania sobie z pamięci**. Wybór stolicy z czterech odpowiedzi nie daje takiej samej pewności jak jej samodzielne wpisanie.

#### Przykładowa inteligentna sesja

10 pytań: 5 powtórek, 3 nowe, 2 trudne. Przykładowy przebieg:

1. Wskaż na mapie Słowenię — powtórka.
2. Jaka jest stolica Łotwy? — trudny fakt.
3. Rozpoznaj zaznaczone państwo — nowe.
4. Jaka jest waluta Czech? — powtórka.
5. Wskaż Estonię — nowa umiejętność.

Kolejność i proporcje to propozycja startowa, później będą dostosowywane do wyników.

Algorytm powinien kierować się następującymi zasadami:

1. Najpierw bierze pod uwagę fakty, których termin powtórki już nadszedł.
2. Dodaje niewielką liczbę nowych faktów, aby zapewnić postęp.
3. Uzupełnia sesję najtrudniejszymi zagadnieniami.
4. Miesza rodzaje pytań, żeby nie pojawiało się dziesięć kolejnych pytań o stolice.
5. Nie ujawnia odpowiedzi w jednym pytaniu, jeśli za chwilę będzie o nią pytać w innym.

Gdy liczba zaległych powtórek będzie duża, aplikacja powinna ograniczyć wprowadzanie nowych faktów.

#### Jak oceniana jest odpowiedź?

Po sprawdzeniu odpowiedzi:

- Błędna odpowiedź oznacza `Again` w FSRS.
- Poprawna odpowiedź domyślnie oznacza `Good`.
- Po poprawnej odpowiedzi możesz zmienić ocenę na `Hard` albo `Easy`.
- Podpowiedź i zgadywanie powinny być jawnie oznaczane, żeby algorytm nie przeceniał wiedzy.

Nie używałbym samego czasu odpowiedzi jako automatycznej miary pewności. Szybkie zgadywanie nadal może być zgadywaniem.

#### Inteligentne przełączanie między mapą i quizem

Proponuję prostą zasadę na początek: **format pytania dobieramy na podstawie umiejętności, która wymaga powtórki**.

Jeśli słabo znasz lokalizacje państw, częściej dostajesz zadania na mapie. Jeśli doskonale znasz mapę, ale mylisz stolice, częściej ćwiczysz odpowiedzi tekstowe.

Ważne: silnik nie powinien całkowicie wyłączać już opanowanych kategorii. FSRS nadal będzie planować ich okresowe sprawdzanie.

### 4.5. Projekt interaktywnej mapy

To najtrudniejszy technicznie element pierwszego wydania, dlatego warto potraktować go jako osobny moduł.

Przykładowy ekran pytania:

> PYTANIE 3/10 — Mapa  
> **Gdzie znajduje się Słowenia?**  
> [Interaktywna mapa Europy Środkowej]  
> Dotknij właściwego kraju.  
> Kontrolki przybliżania i przesuwania.

*W oryginalnej odpowiedzi była ilustracja poglądowa mapy, a nie działająca mapa.*

Do Fluttera polecam bibliotekę https://docs.fleaflet.dev/ (`flutter_map`). Obsługuje warstwy wielokątów i wykrywanie dotknięcia konkretnego obiektu mapy. Możemy więc przypisać każdemu państwu stabilny identyfikator.

Geometrię pobierzemy z https://www.naturalearthdata.com/ (Natural Earth). To dane mapowe należące do domeny publicznej.

#### Wymagania wobec mapy

| Wymaganie | Rozwiązanie |
|---|---|
| Pełna praca offline | GeoJSON zapisany w zasobach aplikacji |
| Płynna nawigacja | Przygotowana i uproszczona geometria |
| Rozpoznawanie dotknięcia | Hit testing wielokątów |
| Małe państwa | Powiększenie, większy obszar trafienia lub dodatkowy znacznik |
| Odpowiedź błędna | Podświetlenie wybranego i prawidłowego państwa |
| Nauka bez podpowiedzi | Możliwość ukrycia nazw |
| Nauka z pomocą | Opcjonalne podpisy i wskazówki |

Szczególnie trzeba zadbać o Watykan, San Marino, Monako, Andorę i Liechtenstein. Dotknięcie ich na mapie telefonu nie może być loterią.

Nie korzystałbym w MVP z internetowych kafelków OpenStreetMap. Chcemy własny, kontrolowany atlas, który będzie identycznie działał z internetem i bez niego.

**Dodatkowa ważna decyzja:** granice polityczne i lista państw muszą być przygotowane jako osobne, świadomie zweryfikowane dane. Natural Earth prezentuje granice z perspektywy faktycznej kontroli, a w danych zawiera również terytoria i obszary sporne. Nie można po prostu uznać każdego wielokąta za jedno państwo uczestniczące w quizie.

### 4.6. Architektura techniczna

Polecam **modularny monolit Fluttera** z podejściem feature-first. Czytelna struktura, bez zbędnej liczby warstw i abstrakcji.

Przepływ zależności:

```text
Interfejs Flutter
├── Session Engine
│   ├── Question Generator → Content Repository → Baza faktów
│   ├── Answer Evaluator → Content Repository
│   └── FSRS Scheduler → Progress Repository → SQLite: postępy
└── Atlas / Mapa → Offline GeoJSON
```

#### Wybór technologii

| Warstwa | Rekomendacja | Uzasadnienie |
|---|---|---|
| UI | Flutter + Material 3 | Spójny, natywnie działający interfejs |
| Stan aplikacji | Riverpod | Zarządzanie stanem i zależnościami |
| Nawigacja | GoRouter | Przewidywalne przechodzenie między ekranami |
| Mapa | flutter_map | Obsługa wielokątów i dotyku |
| Baza lokalna | Drift / SQLite | Typowane zapytania i migracje |
| Powtórki | fsrs (Dart) | Gotowy scheduler |
| Dane map | Natural Earth | Brak zależności od serwera |
| Import faktów | Python, skrypty offline | Walidacja i generowanie paczek danych |
| Testy | flutter_test + integration_test | Logika, widgety i przepływy |

Drift ma wbudowane narzędzia do migracji schematu i reaktywnego odczytywania danych, co będzie przydatne przy rozbudowie katalogu geografii.

#### Struktura repozytorium

```text
geokuna/
├── AGENTS.md
├── README.md
├── pubspec.yaml
├── .codex/
│   ├── config.toml
│   └── agents/
│       ├── flutter_worker.toml
│       ├── data_worker.toml
│       └── reviewer.toml
├── docs/
│   ├── PRD.md
│   ├── ARCHITECTURE.md
│   ├── CONTENT_POLICY.md
│   ├── DATA_MODEL.md
│   └── BACKLOG.md
├── lib/
│   ├── app/
│   ├── core/
│   │   ├── database/
│   │   ├── design_system/
│   │   └── navigation/
│   └── features/
│       ├── home/
│       ├── atlas/
│       ├── learning/
│       ├── reviews/
│       ├── statistics/
│       └── settings/
├── assets/
│   ├── maps/
│   ├── content/
│   └── mascot/
├── tools/
│   └── data_pipeline/
├── test/
└── integration_test/
```

Ta struktura pozwoli Lunie pracować nad interfejsem, a Terrze równolegle przygotowywać dane, bez ciągłego edytowania tych samych plików.

### 4.7. Model danych — bardzo ważna decyzja

Zaprojektowałbym dane w taki sposób, aby w przyszłości można było dodać nowe dziedziny bez przebudowy aplikacji.

| Encja / tabela | Przechowywane informacje |
|---|---|
| `countries` | ID, nazwa PL, kod ISO, identyfikator Wikidata, kontynenty |
| `regions` | Europa, Bałkany, Skandynawia i inne regiony |
| `country_regions` | Przynależność państwa do regionów |
| `geo_features` | Powiązanie państwa z obiektem mapy |
| `facts` | Typ faktu, podmiot, wartość, źródło, status weryfikacji |
| `answer_aliases` | Akceptowane warianty nazw i pisowni |
| `learning_cards` | Umiejętność, kierunek pytania, stan FSRS, termin powtórki |
| `review_logs` | Historia ocen i aktualizacji pamięci |
| `question_attempts` | Odpowiedzi, czas, poprawność, podpowiedzi |
| `learning_sessions` | Historia i stan rozpoczętych lekcji |
| `app_settings` | Preferencje i dzienny cel |

Warto od początku uwzględnić:

- Osobne identyfikatory faktów i pytań. Jeden fakt może być testowany na kilka sposobów.
- Kilka poprawnych odpowiedzi, tam gdzie jest to uzasadnione.
- Alternatywne nazwy polskie i międzynarodowe.
- Źródło i datę weryfikacji faktu.
- Wersję paczki danych, niezależną od wersji aplikacji.
- Migracje, które nigdy nie usuwają postępów użytkownika.

Przykładowo stolica może być reprezentowana tak:

```json
{
  "id": "capital:EST",
  "subject": "country:EST",
  "predicate": "capital",
  "answers": ["Tallinn"],
  "aliases": ["Tallin"],
  "source": {
    "name": "curated-geography-dataset",
    "verified_at": "2026-11-12"
  },
  "status": "verified"
}
```

To ilustracja schematu, nie wpis przygotowany na podstawie ukończonej weryfikacji źródeł.

W przyszłości ten sam mechanizm obsłuży np. `river:length`, `mountain:elevation` czy `lake:area`.

#### Jak przygotowywać wiedzę?

Ważne, żeby **Codex nie generował całej bazy pytań przez zgadywanie**.

Wolałbym taki proces:

1. Terra pobiera dane ze wskazanych źródeł.
2. Normalizuje nazwy, identyfikatory i wielokrotne wartości.
3. Walidator wykrywa braki, konflikty i niejednoznaczności.
4. Problematyczne fakty trafiają na listę do ręcznej weryfikacji.
5. Powstaje wersjonowana, zatwierdzona paczka danych.
6. GeoKuna generuje zadania tylko ze sprawdzonych faktów.

Na przykład pytanie o „jedyny język urzędowy” musi być odrzucone, jeśli państwo ma kilka języków urzędowych. To samo dotyczy państw posiadających więcej niż jedną stolicę lub szczególny status polityczny.

### 4.8. Orkiestracja Codexa — Sol, Astra, Luna i Terra

Nie uruchamiałbym czterech modeli jednocześnie do każdego zadania. Lepiej rozdzielić role według rodzaju pracy i kosztu.

| Model | Rola | Kiedy używać |
|---|---|---|
| **Astra** | Architekt i audytor | Początkowy projekt, trudne decyzje, przegląd dużych zmian |
| **Sol** | Główny orchestrator | Planowanie, delegowanie, integrowanie, kontrola jakości |
| **Luna** | Programista | Flutter, UI, logika biznesowa, integracje |
| **Terra** | Worker | Przygotowanie danych, testy, migracje, proste poprawki |

Moja propozycja: **Sol jako główny model w Codexie, Astra na żądanie, Luna i Terra jako subagenci.**

W aktualnej dokumentacji Codexa opisano możliwość tworzenia agentów przez pliki `.codex/agents/*.toml` i przypisywania im modeli oraz instrukcji. Trzeba jednak sprawdzić identyfikatory dostępne w Twoim providerze — nie zakładam, że Terra albo Astra będą obsługiwane w każdej konfiguracji CLI.

#### Przykładowa konfiguracja

`.codex/config.toml`

```toml
[agents]
enabled = true
max_concurrent_threads_per_session = 3
default_subagent_model = "gpt-6-luna"
default_subagent_reasoning_effort = "medium"
```

`.codex/agents/flutter_worker.toml`

```toml
name = "flutter_worker"
description = "Implementacja aplikacji Flutter GeoKuna"
model = "gpt-6-luna"
model_reasoning_effort = "high"

developer_instructions = """
Implementuj małe, niezależne zadania.
Przestrzegaj architektury opisanej w docs/.
Każda nowa funkcja wymaga testów.
Nie modyfikuj plików data_pipeline bez potrzeby.
Nie wykonuj destrukcyjnych operacji Git.
Raportuj wykonane zmiany i wyniki testów.
"""
```

Analogicznie zdefiniujemy `data_worker` i `reviewer`. Do `data_worker` można przypisać Terrę, jeśli Codex zaakceptuje identyfikator tego modelu. Jeżeli nie, Luna będzie rozsądnym zamiennikiem.

Warto również wprowadzić zasadę, że agent odpowiedzialny za zatwierdzenie zmiany nie powinien być jedynym agentem, który ją testuje.

### 4.9. Backlog implementacji

Poniższe zadania powinny znaleźć się w `docs/BACKLOG.md`. Zaplanowałem je jako kolejne, możliwe do samodzielnego przetestowania przyrosty produktu.

**GK-001 — Fundament projektu (Sol + Luna)**

Utworzenie projektu Flutter, motywu, nawigacji, struktury modułów, lokalnej bazy, automatycznych testów i plików dokumentacji.

*Gotowe, gdy: aplikacja uruchamia się na Androidzie, a `flutter analyze` i testy przechodzą.*

**GK-002 — Pierwsza działająca mapa (Luna + Terra)**

Import geometrii wybranych 15 państw Europy, mapa offline, zoom, pan, identyfikacja dotkniętego państwa i podświetlenie.

*Gotowe, gdy: można na telefonie wskazać państwo bez dostępu do internetu, a małe obiekty mają alternatywny sposób wyboru.*

**GK-003 — Baza geografii (Terra + Sol)**

Przygotowanie danych o państwach Europy, stolicach, walutach i językach urzędowych, razem z walidatorami i źródłami.

*Gotowe, gdy: automatyczne testy wykrywają duplikaty, brakujące dane i niejednoznaczne pytania.*

**GK-004 — Silnik quizów (Luna)**

Pytania mapowe, wielokrotny wybór, proste odpowiedzi tekstowe, ocena odpowiedzi, wskazówki i podsumowanie lekcji.

*Gotowe, gdy: pełną 10-pytaniową sesję można ukończyć od początku do końca bez błędów nawigacji.*

**GK-005 — Pamięć Kuny (Sol + Luna)**

FSRS, historia odpowiedzi, dobór pytań, rozróżnienie umiejętności i przechowywanie terminów powtórek.

*Gotowe, gdy: nieznany fakt wraca wcześniej niż dobrze opanowany, a dane przetrwają restart aplikacji.*

**GK-006 — Ekrany produktu i statystyki (Luna)**

Dziś, Atlas, Powtórki, Postępy, profile państw, ustawienia oraz podstawowe reakcje maskotki.

*Gotowe, gdy: wszystkie ekrany mają realne dane i nie zawierają martwych przycisków.*

**GK-007 — Stabilizacja i wydanie MVP (Sol + reviewer)**

Testy integracyjne, test offline, obsługa małych państw, weryfikacja danych, optymalizacja mapy i zbudowanie instalacyjnego APK.

*Gotowe, gdy: aplikacja przechodzi pełny scenariusz nauki na fizycznym Androidzie.*

### 4.10. Kryteria ukończenia MVP

W oryginalnej odpowiedzi znajdowała się interaktywna checklista. Oto jej pełna treść:

- [ ] Mapa Europy działa offline, można ją przybliżać i wskazywać państwa.
- [ ] Wszystkie państwa objęte zakresem MVP mają zweryfikowane dane.
- [ ] Quiz obsługuje mapę, wybór odpowiedzi i wpisywanie stolic.
- [ ] Nie są generowane pytania z kilkoma nieoznaczonymi poprawnymi odpowiedziami.
- [ ] FSRS zapisuje stan powtórek każdej umiejętności.
- [ ] Dzienne sesje mieszają pytania mapowe i faktograficzne.
- [ ] Postępy i rozpoczęta sesja przetrwają ponowne uruchomienie aplikacji.
- [ ] Ekran statystyk pokazuje faktyczne postępy nauki.
- [ ] Da się przejść pełną sesję w trybie samolotowym.
- [ ] Testy i analiza statyczna przechodzą bez błędów.

### 4.11. Co świadomie pomijamy w MVP?

Nie implementowałbym jeszcze kont użytkowników, chmury, rankingów społecznościowych, subskrypcji, sklepu z nagrodami, generowania pytań przez LLM na żywo ani rozbudowanych animacji.

Powstrzymałbym się także od budowania skomplikowanego systemu osiągnięć. Wystarczą podstawowe komunikaty Kuny, pasek postępu oraz informacje o opanowanych faktach.

Te funkcje nie decydują o tym, czy będziesz skuteczniej zapamiętywać geografię.

Na później pozostawiłbym też codzienne powiadomienia i eksport postępów, choć architektura bazy powinna od początku umożliwiać ich dodanie.

### 4.12. Gotowy prompt startowy dla Sol w Codexie

Ten prompt jest już nastawiony na rozpoczęcie realnej pracy, a nie ponowne wymyślanie całej koncepcji.

```text
Jesteś głównym architektem i koordynatorem projektu GeoKuna.

Cel:
Stwórz wysokiej jakości aplikację mobilną Android do nauki geografii. GeoKuna łączy interaktywny atlas, quizy i inteligentne powtórki FSRS. Docelowo ma pomagać w przygotowaniu do teleturniejów wiedzy, takich jak Va Banque!.

Język aplikacji: polski.
Maskotka: sympatyczna kuna leśna.
Hasło: "Kuna wie, gdzie!"

STOS TECHNOLOGICZNY:
- Flutter / Dart
- Riverpod
- GoRouter
- Drift / SQLite
- flutter_map + offline GeoJSON
- FSRS (Dart)
- Python do przygotowywania danych

ZAŁOŻENIA:
1. Offline-first, bez logowania i backendu.
2. Pierwsze MVP obejmuje geografię Europy.
3. Nauka obejmuje lokalizacje krajów, stolice, języki urzędowe, waluty i podstawowe relacje geograficzne.
4. Każda umiejętność ma osobny stan zapamiętania.
5. Quizy są adaptacyjne, a kolejność powtórek oparta na FSRS.
6. Dane geograficzne muszą być weryfikowalne, wersjonowane i walidowane.
7. AI nie generuje odpowiedzi quizowych w czasie działania aplikacji.
8. Architektura ma umożliwiać rozbudowę na cały świat i kolejne kategorie.

TWOJA ROLA:
- Pracuj jako architekt i orchestrator.
- Deleguj zamknięte zadania implementacyjne subagentom.
- Wykorzystuj Lunę do Fluttera i logiki.
- Wykorzystuj Terrę do danych, testów i prostych zadań, jeżeli model jest dostępny w obecnym providerze.
- Krytyczne decyzje samodzielnie weryfikuj.
- Unikaj nadmiernej równoległości i konfliktów w plikach.

ZASADY:
- Pracuj przyrostowo.
- Nie implementuj wszystkiego w jednej wielkiej zmianie.
- Każdy etap musi mieć kryteria akceptacji.
- Testuj kod i naprawiaj wykryte błędy.
- Nie usuwaj istniejących danych bez zgody.
- Nie wykonuj git clean, reset --hard ani innych destrukcyjnych operacji.
- Dokumentuj decyzje, ograniczenia i otwarte problemy.

ZADANIE POCZĄTKOWE:
1. Sprawdź środowisko: Flutter, Dart, Android SDK, Git.
2. Przygotuj dokumentację PRD.md, ARCHITECTURE.md, DATA_MODEL.md, CONTENT_POLICY.md i BACKLOG.md.
3. Utwórz AGENTS.md i konfigurację subagentów.
4. Zdefiniuj schemat wiedzy i postępów.
5. Przygotuj projekt Flutter z minimalną nawigacją.
6. Zaimplementuj pierwszy działający vertical slice:
   - offline mapa 15 wybranych państw Europy,
   - możliwość wskazania państwa,
   - pytanie o jego lokalizację,
   - ocena poprawności,
   - lokalny zapis odpowiedzi,
   - podstawowe testy.

Nie przechodź jeszcze do wszystkich funkcji MVP.

Na końcu przedstaw:
- wykonane zadania,
- wyniki testów,
- strukturę projektu,
- napotkane problemy,
- rekomendowany następny krok.

Priorytet: poprawność, prostota, dobra architektura i grywalny rezultat.
```

### 4.13. Moje trzy dodatkowe rekomendacje

**Po pierwsze — zacząłbym od mapy, nie od wyglądu aplikacji.** Interaktywny atlas jest największą niewiadomą techniczną. Gdy będzie działał bezbłędnie, dodawanie pytań o kolejne zagadnienia stanie się znacznie prostsze.

**Po drugie — postawiłbym na naukę aktywnego przypominania.** Pytania z czterema odpowiedziami są wygodne, ale z biegiem czasu GeoKuna powinna częściej wymagać wpisania odpowiedzi bez podpowiedzi. To szczególnie ważne przy przygotowaniach do teleturnieju.

**Po trzecie — nie chciałbym, żeby Kuna była tylko dekoracją.** Powinna reagować na realne wyniki: zauważać, że w końcu zapamiętałeś stolice Bałkanów, proponować powtórkę Skandynawii i wyjaśniać, dlaczego dzisiaj uczysz się właśnie tych zagadnień. Wszystko może działać lokalnie, na podstawie statystyk, bez kosztów API.

A w dalszej perspektywie widzę bardzo fajny tryb **„Wyprawa Kuny”**: wybierasz np. Azję Południowo-Wschodnią, a aplikacja prowadzi Cię przez kolejne państwa, pokazuje mapę, opowiada ciekawostki i stopniowo przechodzi od nauki do samodzielnego sprawdzania wiedzy.

**Docelowo GeoKuna nie powinna być aplikacją, w której tylko zdobywasz punkty. Powinna być aplikacją, dzięki której po dwóch latach rzeczywiście wiesz więcej niż dziś — i nadal to pamiętasz.**

---

## 5. Użytkownik

Możesz mi wyeksportować całą tę naszą rozmowę?

---

*Konsekwencja decyzji projektowych z rozmowy: nazwa GeoKuna, hasło „Kuna wie, gdzie!”, kuna jako maskotka, inteligentne połączenie map i quizów, Flutter/Android/offline-first, FSRS oraz Sol jako koordynator pracy Luny i Terry. Astrę warto uruchamiać do architektury i przeglądów.*
