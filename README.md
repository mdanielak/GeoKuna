# GeoKuna

**Kuna wie, gdzie!** Aplikacja Android do nauki geografii — po polsku,
offline, bez konta i backendu. Zamiast losowych quizów uczy tego, czego jeszcze
nie wiesz: każda umiejętność ma własną kartę powtórek FSRS.

<img src="assets/mascot/kuna-globe.png" width="220" alt="Ikona aplikacji GeoKuna">

## Co potrafi

- **Zakres:** Europa (47), Afryka (54), Azja (50), Ameryka Północna (22),
  Ameryka Południowa (13), Australia i Oceania (14) — mapa, stolice, flagi;
  dodatkowo Polska (16 województw) oraz Stany Zjednoczone (50 stanów) — mapa,
  miasta wojewódzkie / stolice stanów, herby i flagi.
- **Quizy:** wskaż miejsce na mapie (do 3 prób), stolica/miasto i flaga/herb → nazwa
  (A–D, pierwsza litera, pełne wpisanie z tolerancją jednej literówki oraz pomocą
  „Nie wiem, pomóż”), flaga/herb → mapa.
- **Dziś:** codzienna wyprawa do 10 pytań — zaległe powtórki, potem najwyżej
  3 nowe karty dziennie; błąd wraca w tej samej serii, mylone pary pojawiają
  się do porównania jedna po drugiej; ręczny trening zawsze dostępny.
- **Poziomy:** domyślny **Automatyczny** (start od Normalnego, 3 błędy z rzędu
  w jednym haśle schodzą niżej, 2 trafienia wracają wyżej) albo stały poziom
  bardzo łatwy / łatwy / normalny ustawiany osobno dla każdego obszaru.
- **Motywacja, która nie przeszkadza w nauce:** medale za 50/80/100% utrwalonych
  faktów, passa dni nauki per obszar (z nagrodami i żetonami Nieprzykunowanie),
  ciekawostki po odpowiedzi, pięć reakcji kuny.
- Dolny pasek **Dziś / Atlas / Moja nauka**: wbudowany przewodnik *Jak działa GeoKuna?*,
  atlas z wyszukiwarką, postęp obszarów, trzy style map (domyślnie prawdziwa rzeźba
  terenu Natural Earth), kopia postępu do pliku JSON i reset z potwierdzeniem.
- Działa także jako instalowalna aplikacja **Web PWA** pod adresem
  [mdanielak.github.io/GeoKuna](https://mdanielak.github.io/GeoKuna/).

## Uruchomienie

```bash
export PATH="$HOME/.local/share/geokuna/flutter/bin:$PATH"   # Flutter 3.50.0
flutter pub get
flutter run -d chrome
```

Chrome to bieżące środowisko rozwoju; docelową platformą jest Android.
Weryfikacja, testy i telefon: [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

## Dokumentacja

| Dokument | Zawartość |
|---|---|
| [LEARNING.md](docs/LEARNING.md) | zasady nauki: karty, FSRS, ocena, Dziś, postęp, medale, passa, kuna, reset |
| [CONTENT.md](docs/CONTENT.md) | źródła, polityka granic, wyjątki stolic, flagi, relief, ciekawostki, odtwarzanie paczek |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | moduły, decyzje, schemat SQLite v10 i migracje |
| [DEVELOPMENT.md](docs/DEVELOPMENT.md) | uruchamianie, weryfikacja, zasady testów, Chrome vs Android, agenci |
| [ROADMAP.md](docs/ROADMAP.md) | stan, najbliższe kroki, przyszłe przyrosty, otwarte ryzyka |
| [AGENTS.md](AGENTS.md) | zasady pracy agentów |

Historyczne plany i przeglądy: [docs/archive/](docs/archive/).
Licencje i źródła zewnętrzne: [THIRD_PARTY.md](THIRD_PARTY.md).

Repozytorium prywatne: [mdanielak/GeoKuna](https://github.com/mdanielak/GeoKuna).
