# Pięć usprawnień UX — zaakceptowany zakres

> Plan historyczny: przepływ potwierdzania mapy zastąpiono trzema bezpośrednimi
> próbami. Aktualny kontrakt: [plan prób i flag](2026-11-13-map-retries-flags.md).


Użytkownik polecił wdrożyć pięć rekomendacji audytu. UI/UX Pro Max i
geokuna-learning-design prowadzą decyzje. Nie dodajemy zależności ani backendu.

## Decyzje i kontrakt

1. Atlas: wyszukiwarka bez rozróżniania diakrytyki/wielkości liter i lista
   nazwanych wierszy minimum 48 dp. Reużywalny CountryPicker obsługuje listę.
2. Postępy: osobno mapa/A–D/pierwsza litera/pisanie. Trzy stany: brak ocenianej
   próby = „Za mało danych”; zaległy termin lub ostatnie Again = „Do powtórki”;
   inne rozpoczęte = „Ćwiczysz”. Nie ma procentu opanowania ani gwarancji retencji.
3. Mapa: klawiatura do kadrowania i powiększania, dostępna nazwana lista jako
   jawna pomoc. Pomoc zapisuje próbę i dziennik `origin=assisted, applied=false`;
   nie aktualizuje FSRS i nie zużywa budżetu nowych. Nie udajemy, że wybór nazwy
   kraju z listy mierzy jego położenie. Zaznaczenie nadal wymaga potwierdzenia.
4. Dziś: stan ładowania/błędu tylko w karcie powtórek. Menu atlas/trening/postępy
   pozostaje widoczne i niezależne od dziennego providera. Atlas nie wymaga bazy.
5. Tekst: jedna krótka reguła literówki i szczegóły pod przyciskiem pomocy.

Bez migracji schematu: pamięć pomocy jest jawna w istniejącym dzienniku.
LearningSession otrzymuje assistedIndices; repo.answer ma named assisted=false.
Postępy korzystają tylko z ocenionych przeglądów, nigdy z pomocy jako wiedzy.

## Właściciele

- Luna: atlas/picker, mapowe wejście z pomocą i klawiatura, instrukcje stolic.
- Terra: HomeScreen i testy odporności.
- Sol: model/providery/ekran postępów, repozytorium pomocy, testy integracji,
  przegląd i jedna końcowa sesja Chrome na telefonicznym viewportcie.

## Weryfikacja

TDD oceniania pomocy i stanów postępu; niezależne awarie providerów; wyszukiwanie
bez diakrytyki, semantyka i obsługa klawiatury; brak zapisu przed potwierdzeniem.
Format, analyze, flutter test i oba walidatory. Wizualnie ważne ekrany w Chrome,
mała szerokość/duży tekst; bez emulatora, SDK Androida i globalnych zmian.

## Wynik integracji

Wdrożono pięć punktów. 45 testów przeszło, analyze i oba walidatory bez błędów.
Chrome: wyszukiwanie atlasu, oddzielność formatów w Postępach, wybór z pomocą
oraz okno reguł; Dziś 320 px. Test dużego tekstu Postępów 200% przeszedł.
TalkBack i klawiatura systemowa Androida wymagają późniejszej próby na telefonie.
