# GeoKuna

**Kuna wie, gdzie!** Aplikacja Android do nauki geografii — po polsku,
offline, bez konta i backendu. Zamiast losowych quizów uczy tego, czego jeszcze
nie wiesz: każda umiejętność ma własną kartę powtórek FSRS.

![Kuna z globusem](assets/mascot/kuna-globe.png)

## Co potrafi

- **Zakres:** Europa (47), Afryka (54), Azja (50) — mapa, stolice, flagi.
- **Quizy:** wskaż kraj na mapie (do 3 prób), stolica i flaga → nazwa
  (A–D, pierwsza litera, pełne wpisanie z tolerancją jednej literówki),
  flaga → mapa.
- **Dziś:** codzienna wyprawa do 10 pytań — zaległe powtórki, potem najwyżej
  3 nowe karty dziennie; błąd wraca w tej samej serii, uparcie mylony kraj
  najpierw w łatwiejszej formie; ręczny trening zawsze dostępny.
- **Poziomy** bardzo łatwy / łatwy / normalny ustawiane osobno dla kontynentu.
- **Motywacja, która nie przeszkadza w nauce:** medale za 50/80/100% utrwalonych
  faktów, passa dni nauki per kontynent, ciekawostki po trafieniu, pięć reakcji kuny.
- Dolny pasek **Dziś / Atlas / Moja nauka**: atlas z wyszukiwarką, postęp kontynentów, trzy style map
  (domyślnie prawdziwa rzeźba terenu Natural Earth), kopia postępu do pliku,
  reset z potwierdzeniem.

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
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | moduły, decyzje, schemat SQLite v8 i migracje |
| [DEVELOPMENT.md](docs/DEVELOPMENT.md) | uruchamianie, weryfikacja, zasady testów, Chrome vs Android, agenci |
| [ROADMAP.md](docs/ROADMAP.md) | stan, najbliższe kroki, przyszłe przyrosty, otwarte ryzyka |
| [AGENTS.md](AGENTS.md) | zasady pracy agentów |

Historyczne plany i przeglądy: [docs/archive/](docs/archive/).
Licencje i źródła zewnętrzne: [THIRD_PARTY.md](THIRD_PARTY.md).

Repozytorium prywatne: [mdanielak/GeoKuna](https://github.com/mdanielak/GeoKuna).
