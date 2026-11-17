# Stan i plan

## Stan — 2026-11-16 (wersja 0.7.0)

Wdrożone (szczegóły: [LEARNING.md](LEARNING.md), [CONTENT.md](CONTENT.md)):

- Europa 47, Afryka 54, Azja 50, Ameryka Północna 22, Południowa 13, Oceania 14;
  województwa (16) i stany USA (50) — mapa, miasta wojewódzkie / stolice stanów,
  herby / flagi, z ciekawostkami; wybór kontynentu na Dziś, wspólne karty krajów transkontynentalnych.
- Mapa, stolice, flaga → nazwa, flaga → mapa; trzy poziomy i 12 kart FSRS na kraj;
  A–D z własnym FSRS rozpoznawania.
- Dziś: zaległe najpierw, globalny limit 3 nowości, poziom per kontynent.
- Quiz mapy: trzy próby, etykieta błędnego kraju, przybliżenie rozwiązania po 3. błędzie,
  lekki kadr podpowiedzi na łatwych poziomach.
- Medale 50/80/100% z dziedziczeniem poziomów, passa per kontynent na Dziś,
  ciekawostki po trafieniu, pięć emocji kuny z trzema tekstami.
- Dolny pasek Dziś / Atlas / Moja nauka (Dziś: jedna karta wyprawy z kuną i passą,
  poziom kontynentu w arkuszu, postęp mapy do następnego medalu, trening w jednym
  rzędzie; Ameryki i Australia z Oceanią jako wyszarzone „wkrótce”); atlas z wyszukiwarką i klawiaturą, trzy style map, reset z potwierdzeniem.
- SQLite v9 (indeksy historii, żetony passy) z migracjami od v1.
- Nagrody za passę (3–90 dni) i żetony Nieprzykunowanie per kontynent; plan Dziś wydzielony do `daily_planner.dart`.
- Nauka adaptacyjna (2026-11-14): Easy przy znanym od razu, limit 60 dni,
  powtórka błędu po 3–5 pytaniach, trudny kraj 3/3, kolejna runda z kontrolą
  pewniaków, wstępny quiz (dawniej „Kuna sprawdzi, co już wiesz”), ciekawostka (karta z kuną z lupą) także po błędzie.
- Drabinka trudnych kart, szczebele 1–2 (2026-11-15), kopia postępu w Ustawieniach,
  tokeny kolorów i typografii (`GeoColors`): po 2 błędach łatwiejszy krok
  przed właściwym pytaniem. Ciekawostki o flagach (3 na flagę), Europa bez
  Kazachstanu i Kaukazu, ląd kontekstowy na mapach, relief z kafelków 1:10m z rzekami i jeziorami.

- **Wygląd v2** (branch `wyglad_v2`, grafiki z paczek GeoKuna v2.3–v2.5):
  paleta kremowo-zielona, logo, banner regionu z kuną (przesunięcie w lewo/prawo
  zmienia kontynent; na obrazku passa, postęp mapy i główny przycisk), kafelki
  Mapa/Stolice/Flagi przypięte u dołu, krajobraz w nagłówku quizu, „Wstępny
  quiz” (łatwy) przy pierwszej wizycie obszaru, rozwijane błędy w podsumowaniu,
  angielskie nazwy stolic; kafelki bez napisu dla każdego obszaru (mapa
  Polski/USA, flagi Europy/USA/świata, herby), medale i żeton w „Moja nauka”,
  kuna z lupą na karcie ciekawostki.

Ostatnie przyrosty sprawdzono zrzutami testowymi (`/shots`, 390×844 i 320×640/160%),
nie w Chrome ani na telefonie.

Ograniczenia: brak testu na fizycznym Androidzie (gesty, Wstecz, TalkBack,
cykl życia, wydajność reliefu, SQLite natywne), FSRS
nie dowodzi retencji w miesiącach.

## Najbliższe kroki

1. **Kontrola Chrome** przyrostu poziomów/medali/pass: Dziś z passą, mapa
   bardzo łatwa/łatwa/normalna, etykieta błędu, przybliżenie po 3. błędzie,
   ciekawostka, podsumowanie z kuną, Moja nauka z medalami; 390×844 i 320×640/200%.
2. **Sprawdzenie kopii postępu na urządzeniu**: zapis przez systemowy wybór pliku
   (Android SAF) i pobranie w Chrome; przeniesienie Web → telefon.
3. **Państwo → flaga**: cztery obrazy, osobna karta, jednoznaczne dystraktory.
4. **Fizyczny Android** po uzgodnieniu toolchainu: tryb samolotowy, Wstecz,
   klawiatura, TalkBack, trwałość bazy, płynność; potem podpisywanie APK/AAB
   (klucze poza repo).
5. **Ciekawostki według nowych zasad** (po 3 o kraju, stolicy i fladze):
   gotowe 2026-11-16: kraje (0.4.0), stolice (0.2.0) i flagi (0.3.0), po 591
   faktów z przypiętych wersji Wikipedii (wszystkie 6 kontynentów). Dalej: przegląd człowieka i sprawdzenie
   na urządzeniu, jak czyta się karta ciekawostki — zasady w
   [CONTENT.md](CONTENT.md#jaka-ma-być-ciekawostka-zasady-redakcyjne).
6. **Obserwacja powtórek w praktyce** przez kilka dni, zanim zmienimy budżet nowości
   lub parametry FSRS.

## Plan: województwa i stany USA — etap 1, mapa (wersja 0.6.0) — wykonany; etap 2 (stolice, herby/flagi) wykonany w 0.7.0

**Cel.** Dwie nowe mapy do nauki: 16 województw Polski i 50 stanów USA, pytanie
„gdzie leży?” na mapie, po odpowiedzi jedna z 3 ciekawostek. Etap 2 (osobno):
miasta wojewódzkie i stolice stanów, flagi i herby.

**Nie robimy teraz:** stolic, flag, herbów, powiatów, miast, Dystryktu Kolumbii
jako celu, poziomu „Automatyczny”, zmian kafelków rzeźby.
**Porażka mimo działania:** pomieszany postęp istniejących kart; wstawki
Alaski i Hawajów czytane jako prawdziwe położenie; pusty ekran stolic/flag.

**Podejście (wybrane: A).** Polska i USA to dwa nowe obszary w `Continent`
(kod nadal mówi „kontynent”), z tym samym przepływem co państwa: Dziś, FSRS,
poziomy mapy, medale, passa, atlas, ciekawostki.
Odrzucone: B — osobny typ obiektu (GK-010, migracja bazy i większości zapytań,
kilka razy więcej pracy przed pierwszą mapą; wrócimy przy rzekach i górach);
C — osobny tryb bez powtórek (bez sedna aplikacji).

**Dane**
- Identyfikatory: ISO 3166-2 — `PL-02`…`PL-32` (kody TERYT), `US-AL`…`US-WY`.
  Trafiają do kolumn `countryId` bez migracji.
- Geometria: Natural Earth 1:10m admin-1 (states/provinces), wersja i SHA-256
  przypięte jak przy państwach; nowe okna `poland` i `usa`; walidator: liczba
  obiektów, punkty kontrolne, sumy kontrolne. Ląd kontekstowy: sąsiednie państwa
  (Polska: DEU, CZE, SVK, UKR, BLR, LTU, RUS-Kaliningrad; USA: CAN, MEX).
- Nazwy: województwa — urzędowe nazwy z TERYT (GUS); stany — polskie nazwy
  z urzędowego wykazu KSNG nazw geograficznych świata (np. Kalifornia, Nowy Jork,
  Karolina Północna); każdy wpis z odnośnikiem i stroną źródła.
- Pytanie: „Gdzie leży województwo mazowieckie?”, „Gdzie leży Kalifornia?” —
  pole `question_name` w katalogu (nazwa w atlasie: „mazowieckie”).
- Znaczniki małych obszarów: Rhode Island, Delaware (jak mikropaństwa).
- **Wstawki USA:** Alaska i Hawaje przesunięte i przeskalowane w danych
  (`build_region.py`) do lewego dolnego rogu okna USA, każda w ramce z podpisem
  „Alaska — inna skala”; w stylu Rzeźba wstawki mają jasne wypełnienie, bo kafelki
  pod nimi pokazują ocean. Trafienie liczy się po przesuniętej geometrii.

**Aplikacja**
- `Continent`: `poland('Polska', 'Polski', 'Polsce')`,
  `usa('Stany Zjednoczone', 'Stanów Zjednoczonych', 'Stanach Zjednoczonych')`;
  okna i kadry pionowe w `country_map.dart`; rzeźba z istniejącego zestawu `world`.
- Rzeczownik obszaru w napisach („państw” → „województw”/„stanów”): pole w
  katalogu, nie `if` w widokach.
- Stolice i flagi: brak pliku = pusty katalog; ekrany i wybór trybu na Dziś
  pokazują tylko mapę dla tych obszarów.
- **ID kart FSRS:** dzisiejszy wzór pakuje 3 znaki; kody 5-znakowe dostają
  osobny zakres (od 10¹³, w granicy 2⁵³ dla Web), bez zmiany istniejących ID —
  test na kolizje i stabilność starych ID.
- Ciekawostki: 3 na obszar (198), w `country_trivia.json` (wersja 0.5.0),
  źródło — artykuł Wikipedii o województwie/stanie w przypiętej wersji, zasady
  z [CONTENT.md](CONTENT.md#jaka-ma-być-ciekawostka-zasady-redakcyjne);
  losowanie 1 z 3 już działa. Walidator obejmuje nowe foldery.
- Kopia postępu, reset, medale i passa działają bez zmian (klucz obszaru).

**Weryfikacja:** `build_region.py poland|usa --check`, `build_trivia.py --check`,
testy: katalog (16/50, unikalne ID), ID kart bez kolizji, przepływ quizu mapy dla
Polski i USA (w tym wstawka), ekran Dziś bez stolic/flag dla tych obszarów;
zrzuty `/shots` trzech stylów; telefon: dotyk małych województw i wstawek.

**Decyzje budującego (moje):** ISO 3166-2 zamiast własnych kodów; DC jako ląd
kontekstowy; nazwa w atlasie bez słowa „województwo”; wstawki w lewym dolnym rogu;
jedna paczka ciekawostek zamiast osobnej.

## Plan: poziom „Automatyczny” (projekt, wstrzymany 2026-11-16)

Cel: trudność dopasowuje się do jednego hasła, nie do całego kontynentu — kto
myli Gwatemalę, dostaje ją łatwiej, a reszta zostaje na normalnym. Zastępuje
pierwszy szczebel drabinki (łatwiejszy krok po 2 błędach); jeden mechanizm, nie dwa.

- **Gdzie:** czwarta opcja poziomu kontynentu, domyślna, gdy użytkownik nic nie
  wybrał. Zapisane wybory (bardzo łatwy/łatwy/normalny) zostają i działają jak dziś.
- **Hasło** = kraj × kategoria (mapa, stolica, flaga → nazwa, flaga → mapa).
  Start: normalny.
- **W dół:** 3 błędne odpowiedzi z rzędu na tym haśle → poziom niżej
  (normalny → łatwy → bardzo łatwy). Liczy się pierwsza odpowiedź każdego pytania,
  także powtórki błędu w serii; kolejne kliknięcia na mapie w tym samym pytaniu nie.
- **W górę:** 2 trafienia z rzędu → poziom wyżej (najwyżej normalny).
  Zmiana poziomu zeruje oba liczniki.
- **Ocena:** odpowiedź ocenia kartę poziomu, na którym padło pytanie; FSRS
  i medale bez zmian (trafienie na bardzo łatwym nie daje medalu za normalny).
- **Planowanie:** w trybie automatycznym z każdego hasła pytamy tylko o kartę
  jego bieżącego poziomu. Karta łatwiejsza po zejściu jest od razu do powtórki
  i nie zużywa budżetu nowości; karty innych poziomów zachowują terminy.
- **Stan:** tabela `auto_levels` (hasło, poziom, licznik), zapis w tej samej
  transakcji co odpowiedź; schemat v10, kopia postępu ją obejmuje.
- **Widoczność:** chip w pytaniu „Łatwiej: Gwatemala” i w feedbacku
  „Jeszcze 1 trafienie — wrócisz do normalnego”; po zejściu „Następnym razem łatwiej”.
- **Usuwamy** łatwiejszy krok drabinki (`origin=scaffold`) we wszystkich trybach;
  mylone pary (szczebel 2), 3 próby na mapie i przybliżenie po 3. błędzie zostają.
- **Testy:** maszyna stanów poziomu, planer (zejście, powrót, budżet),
  symulacja ucznia w `adaptive_learning_test`.

Odrzucone: poziom wyliczany z historii odpowiedzi (wolny przy każdym planie,
powtórki w serii nie są ocenami FSRS); osobny „automat” obok drabinki (dwa mechanizmy).

## Plan: drabinka trudnych kart (dalsze szczeble)

Cel: kraj mylony uparcie nie wraca codziennie w tej samej formie, tylko zmienia
się sposób nauki. Pierwszy szczebel działa (LEARNING.md → „Drabinka”). Dalej:

| Szczebel | Kiedy | Co widzi użytkownik |
|---|---|---|
| 1 ✓ | 2 błędy od opanowania | łatwiejszy format jako ćwiczenie, potem właściwe pytanie |
| 2 ✓ | mylona para (ten sam błędny kraj 2×) | pytanie o parę kolejno: „Słowacja” i „Słowenia”, z różnicą na mapie lub we flagach; w A–D drugi kraj pary zawsze wśród odpowiedzi |
| 3 | 4+ błędy | karta przypomnienia przed pytaniem: kraj, sąsiedzi, ciekawostka; potem łatwiejszy krok i pytanie |
| 4 | opanowanie po drabince | krótsze odstępy przez pierwsze 2 powtórki (np. limit 7 dni), zanim FSRS wróci do pełnych odstępów |

Rozstrzygnięte: szczebel 2 obejmuje mapę i flagi (stolice nie, bo wpisana stolica
nie wskazuje kraju); ćwiczenia drabinki liczą się do passy jak każda odpowiedź.
Otwarte: jak liczyć „opanowanie” przy zmianie poziomu.

## Do poprawy później (wygląd v2, przegląd 2026-11-17)

1. Podpowiedź „Przesuń, aby zobaczyć więcej kontynentów” jest niejednoznaczna,
   odkąd przesuwa się też banner — usunąć lub przeredagować.
2. Długi podtytuł „Na dziś wszystko!” (godzina powtórki + „Możesz jeszcze
   poćwiczyć”) — skrócić.
3. „Moja nauka” i „Ustawienia” w starym stylu Material (szare karty) — przenieść
   na styl v2.
4. Pierwsza wizyta zawsze proponuje Wstępny quiz; kto chce od razu zwykłej
   wyprawy, ma tylko kafelki treningu — rozważyć drugi, mniejszy przycisk.
5. Pozy przygodowe kuny (lornetka, aparat…) są w paczce, ale aplikacja ich
   nie używa (nagrody, puste stany?).

## Dalsze przyrosty

| ID | Zakres | Uwagi |
|---|---|---|
| GK-003b | waluty i języki urzędowe | źródła pierwotne, wiele wartości, daty obowiązywania |
| GK-010 | typowane encje (rzeki, góry, miasta) | rozdzielić `entity_id` od `country_id`; województwa i stany działają jako obszary `Continent` (0.6.0) |
| GK-013 | miasta wojewódzkie, parki, rzeki, góry Polski | jawna rola siedziby władz; rzeki jako linie z tolerancją dotyku |
| GK-014 | mały katalog rzek i gór świata | zdefiniować „największe” przed budową paczki |
| GK-017 | mapa: projekcje regionalne, warstwa kontekstu dla pominiętych obszarów (np. Sahara Zachodnia) | najpierw prototyp z hit-testem |

Źródła do przyszłych paczek Polski: [PRG/Geoportal](https://www.geoportal.gov.pl/pl/dane/panstwowy-rejestr-granic-prg/),
[GUS/TERYT](https://stat.gov.pl/statystyka-regionalna/jednostki-terytorialne/podzial-administracyjny-polski/),
[GDOŚ](https://www.gov.pl/web/gdos/dostep-do-danych-geoprzestrzennych);
geometria rzek świata: [Natural Earth physical 1:50m](https://www.naturalearthdata.com/downloads/50m-physical-vectors/).

## Otwarte ryzyka techniczne

- Migawka mapy przechowuje tylko ID — zmiana geometrii/katalogu przy aktywnej
  sesji nie ma kontraktu wersji.
- Dostępność mapy dla czytnika ekranu: poligony nie mają nazwanych akcji,
  znaczniki mikropaństw mają wspólny opis. Wymaga projektu i testu TalkBack.
- Koszt odświeżania przeglądu co minutę nie był mierzony na telefonie.
- Strategia powielania świata w flutter_map do ponownej oceny przed mapą świata.

Nie planujemy kont, synchronizacji, backendu, powiadomień ani analityki.
Każdy większy przyrost zaczyna się od krótkiego brainstormingu; plany
zapisujemy w `superpowers/plans/`.
