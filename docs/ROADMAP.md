# Stan i plan

## Stan — 2026-11-15 (wersja 0.4)

Wdrożone (szczegóły: [LEARNING.md](LEARNING.md), [CONTENT.md](CONTENT.md)):

- Europa 47, Afryka 54, Azja 50; wybór kontynentu na Dziś, wspólne karty krajów transkontynentalnych.
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
- SQLite v8 (indeksy historii) z migracjami od v1.
- Nauka adaptacyjna (2026-11-14): Easy przy znanym od razu, limit 60 dni,
  powtórka błędu po 3–5 pytaniach, trudny kraj 3/3, kolejna runda z kontrolą
  pewniaków, „Kuna sprawdzi, co już wiesz”, ciekawostka z żarówką także po błędzie.
- Drabinka trudnych kart, szczebele 1–2 (2026-11-15), kopia postępu w Ustawieniach,
  tokeny kolorów i typografii (`GeoColors`): po 2 błędach łatwiejszy krok
  przed właściwym pytaniem. Ciekawostki o flagach (3 na flagę), Europa bez
  Kazachstanu i Kaukazu, ląd kontekstowy na mapach, relief WebP.

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
   **Kuna z lupą** zamiast żarówki na karcie ciekawostki (grafika w stylu maskotek).
4. **Fizyczny Android** po uzgodnieniu toolchainu: tryb samolotowy, Wstecz,
   klawiatura, TalkBack, trwałość bazy, płynność; potem podpisywanie APK/AAB
   (klucze poza repo).
5. **Obserwacja powtórek w praktyce** przez kilka dni, zanim zmienimy budżet nowości
   lub parametry FSRS.

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

## Dalsze przyrosty

| ID | Zakres | Uwagi |
|---|---|---|
| GK-003b | waluty i języki urzędowe | źródła pierwotne, wiele wartości, daty obowiązywania |
| GK-010 | typowane encje + Polska: województwa (TERYT) | rozdzielić `entity_id` od `country_id`; nowy przydział liczbowych ID FSRS |
| GK-012b | pozostałe kontynenty | osobne paczki ze źródłami |
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
