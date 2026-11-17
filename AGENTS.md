# GeoKuna — zasady pracy agentów

## Produkt i architektura

- Android, Flutter/Dart, język polski, offline-first, bez konta i backendu.
- „Kuna wie, gdzie!”; maskotka: `assets/mascot/kuna-globe.png` (wybrany wariant 1).
- Nauka ma rozwijać przypominanie i trwałość wiedzy. Animacje, punkty i serie
  nie mogą blokować powtórek, zasłaniać feedbacku ani zastępować nauki.
- Zachowaj leśną zieleń/ciepły krem, Material 3 i prostą architekturę feature-first.
- Riverpod: stan/zależności; GoRouter: nawigacja; Drift/SQLite: lokalny postęp;
  flutter_map + lokalna geometria. Nie dodawaj warstwy lub biblioteki bez konkretnej korzyści.

## Role i delegowanie

| Agent | Model | Zakres |
|---|---|---|
| Sol | `gpt-6.1-sol` | Architektura, plan, delegowanie, integracja i końcowa weryfikacja. |
| Luna | `gpt-6-luna` | Flutter, ekrany, interakcje i wykonanie ustaleń UI/UX. |
| Terra | `gpt-6.1-terra` | Prostsze zamknięte zadania, testy, dane, walidatory i dokumentacja. |
| Astra | `gpt-6-astra` | Doradca na żądanie przy trudnych decyzjach; domyślnie bez edycji. |

Sol deleguje zamknięte zadania Lunie/Terrze, gdy daje to realną korzyść.
Drobne pojedyncze poprawki może wykonać sam. Zwykle najwyżej dwóch wykonawców
naraz; Astra w osobnej fazie, gdy jest potrzebna. Wykonawcy nie delegują dalej
bez polecenia Sola. Nie uruchamiaj całego zespołu do każdej zmiany.

Zadanie zawiera cel użytkownika, pliki do edycji, istotne decyzje, właściwe
skille, kryteria akceptacji i oczekiwany raport. Raport: zmiany, dowody/testy,
ograniczenia i otwarte kwestie. Sol sprawdza wynik, nie tylko deklarację agenta.
Wspólne pliki (`pubspec*`, routing, schemat Drift i generator) mają jednego
właściciela w danej fazie; nie nadpisuj równoległych zmian innych osób.

Role są w `.codex/agents/`. Sprawdzaj faktyczny interfejs narzędzia. Jeśli
obsługuje nazwane role, użyj ich. Jeśli udostępnia tylko `model` i `fork_turns`,
użyj `fork_turns="none"`, jawnego modelu z tabeli i przekaż instrukcje roli
w zadaniu. Sama nazwa „Luna” nie zmienia modelu. Nie kopiuj nieobsługiwanych
parametrów ze starszych adapterów lub przykładów.

## Kiedy aktywować skille

| Sytuacja | Skill | Prowadzący |
|---|---|---|
| Większa funkcja / istotna zmiana zachowania | `superpowers:brainstorming`, potem `superpowers:writing-plans` | Sol; Astra przy trudnym wyborze. |
| Plan z niezależnymi zadaniami | `superpowers:subagent-driven-development`; `dispatching-parallel-agents` tylko dla rozłącznej pracy | Sol. |
| Własna realizacja planu | `superpowers:executing-plans` | Właściciel zadania. |
| Błąd / regresja | `superpowers:systematic-debugging`, TDD dla zmienianej logiki | Luna/Terra, Sol weryfikuje. |
| Koniec przyrostu / istotny przegląd | `superpowers:verification-before-completion`, odpowiednio `requesting-code-review` / `receiving-code-review` | Sol. |
| Projekt ekranu, formularza, mapy, dostępności | `ui-ux-pro-max`: konkretna domena UX i `--stack flutter` | Luna; Sol/Astra przy decyzjach. |
| Architektura/refaktoryzacja Fluttera | `dart-flutter:flutter-apply-architecture-best-practices` | Sol projektuje, Luna wykonuje. |
| Responsywność / problemy layoutu | `dart-flutter:flutter-build-responsive-layout`, `flutter-fix-layout-issues` | Luna. |
| Logika / testy widgetów | `dart-flutter:dart-add-unit-test`, `flutter-add-widget-test`; integracyjne dla kluczowych przepływów | Luna/Terra. |
| Analiza / błędy uruchomionej aplikacji | `dart-flutter:dart-run-static-analysis`, odpowiednio `dart-fix-runtime-errors` | Luna/Terra. |
| JSON, routing, lokalizacja, konflikty pakietów | Odpowiedni wąski skill oficjalnego `dart-flutter` | Właściciel zadania. |
| Quizy, poziomy, podpowiedzi, feedback, dobór sesji i FSRS | `geokuna-learning-design` | Sol: mechanika; Luna: UI; Terra: testy. |
| Faktycznie potrzebna ilustracja / edycja bitmapy | `imagegen` | Właściciel zadania graficznego. |

Skrócone nazwy testów/layoutu w wierszach Dart oznaczają prefiks `dart-flutter:`.
Czytaj tylko skille pasujące do zadania. `brand`/`design-system` są pomocnicze
przy zmianie identyfikacji; `ui-styling` (Tailwind/shadcn) nie jest stosem Fluttera.
Sites, Slides, Product Design i konektory kont nie są codzienną ścieżką implementacji Androida.

UI/UX Pro Max daje rekomendacje, nie gotową specyfikację. Preferuj wyszukiwanie
Flutter/UX. Nie zastępuj zaakceptowanego stylu automatycznym landing page,
dziecięcym motywem ani zdalnymi fontami. Rekomendacje API dla starszego Fluttera
sprawdzaj z aktualnym SDK/dokumentacją; nie uruchamiaj `--persist` bez potrzeby.

## Planowanie i przyrosty

Przed większą funkcją zrób krótki brainstorming: problem nauki/użytkownika,
2–3 podejścia, rekomendacja i kryteria akceptacji. Uwzględnij wcześniejsze
ustalenia; pytaj tylko o istotne nierozstrzygnięte kwestie. Nie ponawiaj
zatwierdzania tego samego zakresu. Drobna korekta tekstu nie wymaga nowego procesu.

Pracuj według `docs/ROADMAP.md`; większe plany zapisuj w `docs/superpowers/plans/`.
Polecenia użytkownika i AGENTS mają pierwszeństwo przed domyślnymi procesami
skilli. Nie wykonuj automatycznych commitów, instalacji ani globalnych zmian
środowiska tylko dlatego, że występują w przykładzie skilla.

## UI/UX, jedna ręka i płynność

- Material 3, minimum 48×48 dp dla celów Androida, czytelny kontrast i semantyka.
  Kolor nie może być jedynym sygnałem poprawności.
- Główne działanie łatwo dostępne jedną ręką; uwzględnij klawiaturę, paski systemu,
  powrót i przerwanie sesji. Przycisk nie może znikać pod klawiaturą.
- Sprawdź mały ekran i powiększony tekst dla zmienianego układu; nie maskuj
  problemów drobnym fontem lub stałą wysokością ukrywającą treść.
- Ogranicz koszt przebudowy i obliczeń na wątku UI. Profiluj konkretny objaw
  albo ryzykowną zmianę; nie twórz rozbudowanej infrastruktury na zapas.
- Animacje krótkie i opcjonalne; respektuj systemowe ograniczenie animacji.
  Nie opóźniaj odpowiedzi ani kolejnego pytania dla dekoracji.

## Uruchamianie i kontrola wizualna — Flutter Web

Domyślne środowisko bieżącego rozwoju na ThinkPadzie T460s / Linux Mint:
`flutter run -d chrome`. Nadal projektujemy przede wszystkim dla Androida:
Material 3, dostępność, ergonomia dotyku i obsługa jedną ręką pozostają wymagane.

Nie instaluj ani nie uruchamiaj emulatora Androida, AVD lub obrazów systemu.
Nie instaluj teraz Android SDK/JDK ani dodatkowych narzędzi bez uzasadnionej
potrzeby i uzgodnienia zakresu. Nie uzależniaj ukończenia bieżącej zmiany od
emulatora. Testy na fizycznym Androidzie zaplanuj na późniejszy etap, kiedy
będą potrzebne do sprawdzenia zachowania platformowego lub wydania.

Luna odpowiada za kontrolę wyglądu, nawigacji, responsywności i interakcji
w Chrome. Przy nowym ważnym ekranie, większej zmianie układu/przepływu lub
naprawie błędu wizualnego użyj dostępnych narzędzi przeglądarki/screenshotów
oraz adekwatnych wskazówek UI/UX Pro Max. Sol określa zakres i ocenia wynik;
Terra wspiera testy funkcjonalne. Drobne poprawki bez wpływu na układ nie
wymagają zrzutów ani pełnego przechodzenia produktu.

Wystarczy jedna sesja Chrome: telefoniczny viewport, stany dotknięte zmianą
(np. start, wybór/wpisywanie, feedback, powrót). Przy zmianie layoutu sprawdź
też większą szerokość lub tekst. Raportuj przeglądarkę/viewport, sprawdzone
stany, wynik i ewentualny screenshot; nie dodawaj obrazów do repo automatycznie.
Gdy brak narzędzia do zrzutów, zgłoś ograniczenie — nie instaluj go na zapas.
Oszczędzaj sprzęt: bez kilku równoległych przeglądarek i powtarzania testów bez powodu.

Chrome jest wystarczający dla bieżącej kontroli wizualnej, ale nie dowodzi
poprawności Androida. Drift/SQLite native i WASM/przechowywanie przeglądarki
mają osobne magazyny i ograniczenia. Mysz/emulacja dotyku nie zastępuje gestów
telefonu; płynność web debug nie dowodzi wydajności Androida. Klawiatura
systemowa, przycisk Wstecz, cykl życia, uprawnienia i API platformowe wymagają
późniejszych sprawdzeń na fizycznym telefonie. Szczegóły: `docs/DEVELOPMENT.md`.

## Dane i skuteczność nauki

- Fakty mają źródła, datę, status i wersję. AI nie rozstrzyga odpowiedzi w runtime.
- Zachowaj stabilne ID, migawki pytań, postępy i migracje. Katalog państw jest
  oddzielony od geometrii. Nietypowe stolice/granice wymagają jawnej polityki.
- Próba jest zapisywana po zatwierdzeniu; zapis i wznowienie są idempotentne.
- A–D, pierwsza litera i samodzielne pisanie to różne dowody wiedzy. Sukces
  rozpoznawania nie aktualizuje automatycznie pamięci pełnego przypominania.
- Jedna literówka w trybie pisanym według `docs/LEARNING.md`; pokazuj poprawną
  pisownię. Fuzzy match nie usprawiedliwia wybrania złej opcji A–D.
- Bez internetowych kafelków/fontów/pytań podczas nauki. Nowa zależność wymaga
  konkretnej korzyści, kontroli licencji/offline i decyzji Sola w zakresie zadania.

## Weryfikacja i bezpieczeństwo pracy

Używaj Dart MCP, gdy jest podłączony i ma odpowiednie narzędzie; inaczej
istniejącego SDK opisanego w `docs/DEVELOPMENT.md`. Po zmianach Dart/Flutter:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
python3 tools/data_pipeline/build_map.py --check
python3 tools/data_pipeline/build_capitals.py --check
python3 tools/data_pipeline/build_flags.py --check
python3 tools/data_pipeline/build_africa.py --check
python3 tools/data_pipeline/build_asia.py --check
python3 tools/data_pipeline/build_relief.py --check
python3 tools/data_pipeline/build_trivia.py --check
python3 tools/data_pipeline/build_context.py --check
```

Testy jednostkowe, widgetów, odpowiednie integracyjne oraz `flutter analyze`
pozostają obowiązkowe tam, gdzie dotyczą zmiany. W toku pracy dobieraj testy
do zakresu; pełny zestaw raz przy integracji przyrostu.
Po samych instrukcjach/TOML/YAML waliduj te pliki i odwołania — bez uruchamiania
całej aplikacji. Emulatora nie uruchamiaj. Po zmianie uruchomionej aplikacji użyj hot reload/
restart, jeśli MCP/DTD jest dostępny. Nie stosuj `dart fix --apply` podczas audytu.
Raport rozdziela wykonane sprawdzenia, wyniki oraz ograniczenia środowiska.

Bez destrukcyjnych operacji Git i usuwania danych użytkownika. Worktree wymaga
istniejącego commita: brak HEAD nie uzasadnia automatycznego commita lub utraty
nieśledzonych plików. Stan narzędzi i aktywacja: `docs/DEVELOPMENT.md`.

## Niezmienniki nauki

Pełne reguły: `docs/LEARNING.md` (nauka) i `docs/CONTENT.md` (źródła). Nie łam bez decyzji użytkownika:

- 12 kart FSRS na kraj (mapa, stolica, flaga → nazwa, flaga → mapa × 3 poziomy);
  A–D ma własny FSRS i nie zalicza pisania. Wspólne kraje kontynentów mają jedną kartę.
- Główna zasada: nie pytaj o to, co użytkownik zna; skup się na trudnościach;
  okresowo sprawdzaj opanowane. Trafienie przy pierwszym kontakcie (pisanie,
  mapa normalna) = Easy; odstęp maks. 60 dni; literówka o stopień niżej.
- Mapa: kliknięcie = odpowiedź, do 3 różnych prób, FSRS ocenia pierwszą. Po 1./2.
  błędzie etykieta tylko z nazwą wskazanego kraju, bez ujawniania i kadrowania celu;
  po 3. jednorazowe przybliżenie rozwiązania (≤ +1,5 zoomu). Ręczny zoom/pan
  i zoom klastra zachowane. Nie przywracaj wyboru z listy w quizie.
- Kadr normalny nie zależy od celu: szeroki ekran — cały kontynent, telefon w pionie —
  rdzeń kontynentu (reszta przesunięciem); łatwe poziomy przybliżają nad pytany kraj
  z losowym przesunięciem, nigdy idealnie na środku.
- Błąd w serii wraca po 3–5 pytaniach jako nieoceniane ćwiczenie; trudny kraj
  wymaga 3 trafień z rzędu rozłożonych w czasie.
- Limit 3 nowości dziennie jest globalny (trafienia we „Wstępnym quizie” go nie zużywają);
  kolejna runda i pytania kontrolne nie są dopychane na siłę; rozpoczęta seria
  zachowuje format i migawkę.
- Medale 50/80/100%, zaliczenie: dwie poprawne oceny w różne dni, ≥24 h, bez błędu
  pomiędzy; dziedziczenie poziomów bez kopiowania FSRS. Passa per kontynent sesji.
- Kuna, medale, passy i ciekawostki nie zmieniają wyniku, FSRS ani dostępu do powtórek;
  ciekawostka (także po 3. błędzie) nie zdradza przyszłych pytań.
- Flagi tylko z paczki sprawdzonej `build_flags.py --check`, bez generowania AI.
- Relief z danych Natural Earth, nie z makiet. Preferencje są oddzielne od postępu
  i przetrwają reset.
