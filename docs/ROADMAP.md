# Stan i plan

## Stan — 2026-11-14 (wersja 0.4)

Wdrożone (szczegóły: [LEARNING.md](LEARNING.md), [CONTENT.md](CONTENT.md)):

- Europa 51, Afryka 54, Azja 50; wybór kontynentu na Dziś, wspólne karty krajów transkontynentalnych.
- Mapa, stolice, flaga → nazwa, flaga → mapa; trzy poziomy i 12 kart FSRS na kraj;
  A–D z własnym FSRS rozpoznawania.
- Dziś: zaległe najpierw, globalny limit 3 nowości, poziom per kontynent.
- Quiz mapy: trzy próby, etykieta błędnego kraju, przybliżenie rozwiązania po 3. błędzie,
  lekki kadr podpowiedzi na łatwych poziomach.
- Medale 50/80/100% z dziedziczeniem poziomów, passa per kontynent na Dziś,
  ciekawostki po trafieniu, pięć emocji kuny z trzema tekstami.
- Atlas z wyszukiwarką i klawiaturą, Moja nauka, trzy style map, reset z potwierdzeniem.
- SQLite v7 z migracjami od v1.
- Nauka adaptacyjna (2026-11-14): Easy przy znanym od razu, limit 60 dni,
  powtórka błędu po 3–5 pytaniach, trudny kraj 3/3, kolejna runda z kontrolą
  pewniaków, „Kuna sprawdzi, co już wiesz”, ciekawostka z żarówką także po błędzie.

Ostatnie przyrosty (poziomy, medale, passa, nauka adaptacyjna) nie przeszły
jeszcze kontroli wizualnej w Chrome.

Ograniczenia: brak testu na fizycznym Androidzie (gesty, Wstecz, TalkBack,
cykl życia, wydajność reliefu, SQLite natywne), brak eksportu postępu, FSRS
nie dowodzi retencji w miesiącach.

## Najbliższe kroki

1. **Kontrola Chrome** przyrostu poziomów/medali/pass: Dziś z passą, mapa
   bardzo łatwa/łatwa/normalna, etykieta błędu, przybliżenie po 3. błędzie,
   ciekawostka, podsumowanie z kuną, Moja nauka z medalami; 390×844 i 320×640/200%.
2. **Eksport/import postępu** (plik lokalny) — przed kolejnymi zmianami magazynu.
3. **Państwo → flaga**: cztery obrazy, osobna karta, jednoznaczne dystraktory.
   **Kuna z lupą** zamiast żarówki na karcie ciekawostki (grafika w stylu maskotek).
4. **Fizyczny Android** po uzgodnieniu toolchainu: tryb samolotowy, Wstecz,
   klawiatura, TalkBack, trwałość bazy, płynność; potem podpisywanie APK/AAB
   (klucze poza repo).
5. **Obserwacja powtórek w praktyce** przez kilka dni, zanim zmienimy budżet nowości
   lub parametry FSRS.

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
