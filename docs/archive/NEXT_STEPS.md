# Kolejne kroki

Bieżące priorytety i szczegółowe zadania znajdują się w [backlogu](BACKLOG.md).

- Rozwijać dzisiejszą wyprawę i ręczny trening według obserwacji nauki: osobno
  oceniać rozpoznawanie, odpowiedź z podpowiedzią i samodzielne przypominanie.
  FSRS planuje terminy; pierwszeństwo mają zaległe karty, a nowe są ograniczane.
- Przy kolejnych zmianach sprawdzać zapis, wznowienie sesji i migrację historii
  bez utraty postępu. Źródła oraz zasady odpowiedzi pozostają wersjonowane.
- Przy odpowiednim etapie przygotować uzgodniony toolchain Androida i sprawdzić
  aplikację na fizycznym telefonie: dotyk mapy, klawiaturę, systemowy Wstecz,
  cykl życia, trwałość bazy, wydajność i uruchomienie offline. Procedura
  połączenia: [RUNNING.md](RUNNING.md). Nie uruchamiać emulatora.
- Przed wydaniem rozstrzygnąć kwestie dystrybucji i przeprowadzić kontrole
  właściwe dla urządzenia oraz wydania; wynik Chrome nie zastępuje Androida.

## Proponowana kolejność przyrostów

1. **Postępy bez złudnego „opanowania”.** Liczba zaległych i przerobionych
   umiejętności, osobno rozpoznawanie i przypominanie. Widok słabych punktów
   powinien opierać się na błędach oraz historii, nie na jednym poprawnym quizie.
2. **Sprawdzenie powtórek w praktyce.** Krótkie sesje przez kilka dni, informacja
   o najbliższym terminie i obserwacja obciążenia. Dopiero z dłuższą historią
   rozważyć ocenę pewności, zmianę budżetu nowych i personalizację parametrów.
3. **Bezpieczeństwo postępu.** Eksport/import lokalnej kopii i testy migracji;
   Android i przeglądarka nie współdzielą bazy. Kopia ma poprzedzać większe
   zmiany magazynu lub algorytmu.
4. **Mapa i dostępność.** Dopracować małe państwa, gesty jedną ręką i czytelność
   przy dużej czcionce. Zweryfikować TalkBack na fizycznym Androidzie.
5. **Nowe kategorie.** Odwrotny quiz państwo → flaga, później waluty i języki: dla każdej osobny
   wersjonowany zestaw źródeł, walidator, zasady wyjątków i stabilne ID kart.
   Nie rozszerzać katalogu na podstawie faktów z pamięci modelu.
6. **Wydanie Android.** Po uzgodnieniu toolchaina: podpisywanie APK/AAB,
   test uruchomienia w trybie samolotowym, trwałość SQLite, pauza/wznowienie
   oraz rzeczywista płynność na telefonie. Klucze podpisu poza repozytorium.

Nie dodawać kont, synchronizacji, backendu, powiadomień ani rozbudowanej
analityki na zapas. Każdy większy przyrost zaczyna się od krótkiego brainstormingu
z konkretnym problemem edukacyjnym i kryteriami akceptacji.

## Rozwinięte plany po audycie

- [Diagnoza wiedzy](LEARNING_REVIEW.md): opcjonalna próbka, formaty osobno, wspólny budżet.
- [Kontynenty, flagi, Polska i świat](EXPANSION_ROADMAP.md): etapy, dane, migracje i akceptacja.
- [Ustalenia przeglądu kodu](CODE_REVIEW.md): dostępność mapy, zgodność paczek, odporność na błędy.

## Po przyroście flag i trzech prób mapy

Flaga → państwo (A–D, pierwsza litera, pisanie) i flaga → mapa są gotowe.
Następnie warto dodać odwrotny kierunek z czterema obrazami, osobną kartą
pamięci i opcjami o podobnych flagach; po nim wybór zakresu na Dziś oraz
Polskę od województw. Eksport postępu warto ukończyć przed rozszerzeniem
magazynu na nowe typy obiektów.

## Po rozszerzeniu Europy, Afryki i Azji

Wybór trzech regionów, przegląd nauki, szczegóły krajów i reset są wdrożone.
Najbliżej: eksport kopii postępu, państwo → flaga, a następnie Polska
od województw. Nowe kierunki wizualne map i końcowych reakcji kuny opisuje
[MAP_AND_MASCOT_NEXT.md](MAP_AND_MASCOT_NEXT.md); to propozycje, bez nowych bitmap.
