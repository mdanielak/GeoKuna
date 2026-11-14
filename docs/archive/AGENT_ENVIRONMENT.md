# GeoKuna — środowisko pracy agentów

Stan sprawdzony 12 listopada 2026. Konfiguracja dotyczy tylko tego projektu.

## Gotowe elementy

- Sol: `gpt-6.1-sol`, medium; Luna: `gpt-6-luna`, high;
  Terra: `gpt-6.1-terra`, medium; Astra: `gpt-6-astra`, low, tylko do trudnych decyzji.
  Wszystkie identyfikatory i poziomy rozumowania są w lokalnym katalogu modeli.
- Role: `.codex/agents/{luna,terra,astra}.toml`; koordynator i limit dwóch
  jednoczesnych wykonawców w `.codex/config.toml`.
- AGENTS.md ustala delegowanie, aktywację skilli, jakość UI i kontrolę Androida.
- `.agents/skills/geokuna-learning-design/` to lokalny skill mechanik nauki,
  poprawnego oceniania, aktywnego przypominania i przyszłego FSRS.

## Narzędzia i kompatybilność

| Element | Wynik kontroli | Zastosowanie |
|---|---|---|
| Superpowers 7.0.1 | Plugin zainstalowany/włączony; 15 skilli, brak wymaganych konektorów | Brainstorming większej funkcji, plan, ograniczona delegacja, debugging, weryfikacja. |
| Oficjalny Dart & Flutter 1.0.7 (Google) | 25 skilli, plugin włączony w konfiguracji | Implementacja, analiza, testy i narzędzia Flutter/Dart. |
| Dart MCP 1.2.2 | Osobny lokalny test stdio: initialize, tools/list (14 narzędzi), analyze_files → No errors | LSP/analiza oraz po połączeniu DTD diagnostyka aplikacji, hot reload i inspekcja widgetów. |
| Flutter 3.50.0 / Dart 3.14.0 | SDK działa na Linuksie; ścieżka poniżej | Wykonanie projektu i CLI jako fallback MCP. |
| UI/UX Pro Max | Walidator: 12 domen, 22 stosy i ui-reasoning.csv OK; wyszukiwanie Flutter/UX działa | Dostępność, dotyk, formularze, responsywność, układ natywny. |
| Android SDK / adb / emulator / JDK | Nie znaleziono w sprawdzonym środowisku | Kompilacja APK i wizualne kontrole Androida pozostają niewykonane. |
| Linux/KVM | `/dev/kvm` istnieje i jest dostępne do odczytu/zapisu | Niewykorzystywane w bieżącym workflow; nie uruchamiamy emulatora. |
| Chrome | Flutter doctor wykrywa Chrome | Domyślne uruchamianie i wizualne testy; nie dowodzi działania Androida. |
| Linux desktop toolchain | Brak clang/cmake/ninja/GTK dev | Nie instalujemy go, bo docelową platformą jest Android. |

MCP nie jest tym samym co skill: skill to instrukcje, MCP to wykonywalne narzędzia.
Superpowers i UI/UX Pro Max nie potrzebują własnego MCP, aby ich instrukcje/skrypty działały.

## Dlaczego zmieniono lokalną konfigurację MCP

Manifest oficjalnego pluginu uruchamia `dart mcp-server`, ale `dart` i `flutter`
nie są w PATH procesu. SDK już istnieje:

`/home/danim/.local/share/geokuna/flutter`

Projektowy `.codex/config.toml` wskazuje absolutne `bin/dart` i `--flutter-sdk`,
zachowując nazwę `dart-mcp-server` i `AGENT_PLUGIN=codex`. Efektywne
`codex mcp list --json` pokazuje jeden serwer z tą ścieżką, bez duplikatu.
Nie zmieniono globalnego config.toml, PATH, instalacji pluginów ani polityki uprawnień.
Po przeniesieniu projektu na inną maszynę trzeba dostosować dwie ścieżki SDK.

Nowy plik konfiguracyjny/role/skille są odczytywane przy uruchomieniu lub
przeładowaniu sesji klienta. Bieżąca rozmowa może nadal mieć poprzedni katalog
narzędzi: nie utożsamiaj poprawnego `mcp list` z podłączeniem narzędzi do już
trwającego czatu. Po ponownym otwarciu GeoKuny sprawdź `/mcp` i narzędzia Dart.
Narzędzia runtime potrzebują także uruchomionej aplikacji i połączenia DTD.

Tymczasowy PATH wyłącznie dla jednego terminala (bez edycji plików powłoki):

```bash
export PATH="$HOME/.local/share/geokuna/flutter/bin:$PATH"
flutter doctor -v
codex mcp list --json
```

## Katalog skilli i MCP — zakres audytu

W katalogu rozmowy przed dodaniem lokalnego skilla były 67 skille:
25 Dart/Flutter, 15 Superpowers, 7 lokalnych projektowych, 5 Google Drive,
5 Product Design, 3 Pets, 2 Sites, 4 systemowe i 1 Plugin Management.
Nowy skill daje 8 lokalnych projektowych; jego pojawienie się w katalogu
konkretnej sesji wymaga odświeżenia odkrywania skilli.

W udostępnionym katalogu narzędzi były 167 pozycji: 13 wbudowanych oraz
154 MCP (142 konektory aplikacji i 12 Codex TUI). Nie obejmowały jeszcze
podłączonego Dart MCP. Widoczne rodziny aplikacji: Google Drive/Docs/Sheets/Slides,
Gmail, Calendar, Contacts, Sites, Pets, Allegro, Stoic Library, Document Control,
Plugin Management, wyszukiwanie, pomoc lokalna i ustawienia bezpieczeństwa.
To inwentarz dostępności, nie test logowania wszystkich kont: nie czytano
prywatnych maili/dokumentów ani nie wykonywano akcji zapisujących w usługach.

Do codziennego GeoKuna wystarczą Superpowers, UI/UX Pro Max, oficjalny
Dart/Flutter, skill nauki i opcjonalnie imagegen. Innych konektorów nie trzeba
aktywować. Nie instalowano nowych zależności ani kolejnych pluginów.

## Ograniczenia zgodności

- UI/UX Pro Max zawiera wskazówki Flutter 3.44.x, a projekt używa 3.50.0.
  Ogólne UX nadal są użyteczne, ale API i przykłady sprawdza się z aktualnym SDK.
- Dwie próbne generacje całego design systemu dały wzorce landing page,
  dziecięce lub wellness oraz importy Google Fonts. Nie przyjęto ich jako
  specyfikacji GeoKuny. Preferujemy konkretne wyszukiwanie UX/Flutter,
  zachowując zaakceptowaną markę i fonty offline.
- Adapter Codex w Superpowers opisuje parametry, których bieżące narzędzie
  `spawn_agent` może nie mieć (np. agent_type). Faktyczne API ma pierwszeństwo.
  W tej sesji jawny model wymaga izolowanego `fork_turns="none"`.
- `.agents/hooks.json` w cache Dart pluginu wskazuje nieobecne skrypty hooków;
  manifest Codex nie włącza ich jako hooków. Nie opieramy kontroli jakości
  na domniemanym automatycznym formatowaniu — obowiązują jawne komendy z AGENTS.
- Lokalne skille web/design zawierają opcjonalne odwołania do `~/.claude/skills`
  i nieobecnych helperów (ai-artist, ai-multimodal, chrome-devtools).
  Nie są potrzebne do przyjętej ścieżki Flutter; nie instalowano ich na zapas.
- Stan podczas audytu: Git był zainicjalizowany bez pierwszego commita.
  Następnie użytkownik jawnie zlecił pierwszy commit i push do prywatnego
  `mdanielak/GeoKuna`; nie zmienia to zakazu samoczynnych commitów w przyszłości.

## Bieżący rozwój — Flutter Web w Chrome

Decyzja użytkownika: na ThinkPadzie T460s / Linux Mint używamy domyślnie
`flutter run -d chrome`. Luna kontroluje wygląd, nawigację, responsywność i interakcje.
Dla większych zmian korzysta z dostępnych screenshotów i UI/UX Pro Max;
drobne poprawki nie wymagają obrazów ani pełnego scenariusza.

Nie instaluj ani nie uruchamiaj emulatora Androida, AVD ani obrazu systemu.
Nie instalujemy teraz Android SDK/JDK ani dodatkowych narzędzi bez uzasadnienia.
Testy na fizycznym telefonie Android odbędą się później, gdy będą rzeczywiście
potrzebne. Brak Androida nie blokuje bieżącej kontroli wizualnej i rozwoju.

Zachowujemy Android-first Material 3, dostępność i ergonomię dotyku.
SQLite/Drift w przeglądarce to WASM i magazyn przeglądarki, odrębny od bazy
natywnej. Gesty, wydajność, klawiatura i API platformowe muszą być raportowane
z uwzględnieniem środowiska. Pełna procedura: [TESTING.md](TESTING.md).

## Weryfikacja przygotowanych plików

TOML wszystkich ról/configu parsuje się poprawnie; modele i poziomy odpowiadają
katalogowi. Walidator skill-creator potwierdza poprawny SKILL.md; metadane UI
mają poprawną długość i odwołanie `$geokuna-learning-design`. Efektywna
konfiguracja CLI zawiera pojedynczy Dart MCP z istniejącym SDK.
Zmiany tego przyrostu dotyczą instrukcji/konfiguracji, więc nie uruchamiano
z ich powodu pełnej aplikacji ani emulatora i nie zmieniano lib/ lub danych.

Źródła konfiguracji: [subagenci](https://learn.chatgpt.com/docs/agent-configuration/subagents),
[referencja](https://learn.chatgpt.com/docs/config-file/config-reference),
[MCP](https://learn.chatgpt.com/docs/extend/mcp).


## Przeglądy i odkrywanie

Testowe uruchomienia z jawnymi modelami `gpt-6-luna` / `gpt-6.1-terra`
przyjęły zadania; obaj wykonawcy zakończyli krótkie przeglądy read-only bez
istotnych uwag. Jest to potwierdzenie wykonania delegacji z zadanymi ustawieniami,
a nie niezależny pomiar tożsamości modelu backendu. Astry nie uruchamiano:
przy tym przyroście nie było trudnej decyzji wymagającej takiej konsultacji.

`codex debug prompt-input` zakończył się kodem 0; nowy skill jest obecny
w kontekście generowanym przez lokalny klient. Składnia konfiguracji została
sprawdzona parserem, a działanie projektowego nadpisania MCP — efektywnym
`codex mcp list`. Nie twierdzimy, że narzędzia Dart zostały wstecznie dodane
do już trwającej rozmowy.
