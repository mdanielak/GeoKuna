# Backlog

- GK-001: szkielet Flutter, nawigacja, motyw, SQLite, dokumentacja.
- GK-002: mapa offline 51 państw Europy, zoom/pan, wybór i małe państwa — wdrożone.
- GK-004a: 10 pytań o lokalizację, ocena, zapis/wznowienie, podsumowanie.
- GK-007a: analiza statyczna, testy logiki/widgetów/bazy, walidator geometrii.
- GK-007b (później, gdy potrzebne): toolchain/APK i test na fizycznym telefonie Android w trybie samolotowym; bez emulatora.
- GK-003a: zweryfikowane stolice 51 państw, źródła, aliasy i walidator — wdrożone.
- GK-003b: zweryfikowane waluty i języki urzędowe — do realizacji.
- GK-004b: stolice: A–D, pierwsza litera, samodzielne pisanie i jedna literówka — wdrożone.
- GK-005a: adapter FSRS, niezależne karty, Dziś, dobór sesji i migracja — wdrożone.
- GK-005b: czytelne postępy i filtry — wdrożone; walidacja długoterminowego harmonogramu — później.
- GK-006: pełne Dziś/Atlas/Powtórki/Postępy oraz ustawienia.
- GK-007: stabilizacja, pełne testy offline, wydanie MVP.

Status i wyniki bieżącego przyrostu: `docs/STATUS.md`.

## Planowane po 0.4 — osobne przyrosty

- GK-008: postępy i opcjonalna diagnoza, bez przenoszenia sukcesu A–D na pisanie.
- GK-009: wybór Europy/Afryki/Azji na Dziś, globalny budżet i zakres sesji — wdrożone.
- GK-010: typowane encje i bezpieczny adapter ID, paczka województw Polski.
- GK-011a: flaga → państwo w trzech poziomach oraz flaga → mapa, lokalne assety i niezależne karty — wdrożone.
- GK-011b: państwo → wybierz flagę — kolejny przyrost.
- GK-012a: Afryka i Azja, mapy/stolice/flagi ze źródłami — wdrożone.
- GK-012b: pozostałe kontynenty w osobnych paczkach.
- GK-013: miasta wojewódzkie, parki, rzeki i góry Polski — osobne paczki.
- GK-014: mały zweryfikowany katalog głównych rzek i gór świata.
- GK-AUDIT: dostępna alternatywa mapy, zgodność aktualizacji paczek,
  niezależna nawigacja przy błędzie Dziś i pomiar kosztu planowania.

Szczegóły, źródła do paczek i kryteria: `EXPANSION_ROADMAP.md`, `LEARNING_REVIEW.md`, `CODE_REVIEW.md`.

- GK-015: Moja nauka kontynent → kraje → formaty, jawny wskaźnik i reset — wdrożone.
- GK-016: eksport/import postępu przed kolejnymi zmianami magazynu.
- GK-017: dopracowanie stylu/projekcji mapy i wspierające reakcje kuny — propozycje w MAP_AND_MASCOT_NEXT.md.

- GK-018: trzy style mapy (realny relief domyślnie), trwałe poziomy per kontynent,
  uproszczony quiz bez listy pomocy — wdrożone.
- GK-019: osobne poziomy nauki/mapy i dziedziczenie zaliczeń, medale,
  passy kontynentów oraz etykiety błędów/kadr rozwiązania — **plan, bez implementacji**.
  Projekt i proponowane progi: [LEVELS_MEDALS_STREAKS_PLAN.md](LEVELS_MEDALS_STREAKS_PLAN.md).
