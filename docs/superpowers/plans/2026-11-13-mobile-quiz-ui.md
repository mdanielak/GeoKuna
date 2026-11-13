# Quizy na telefonie — korekta po opinii użytkownika

> Plan historyczny: przepływ potwierdzania mapy zastąpiono trzema bezpośrednimi
> próbami. Aktualny kontrakt: [plan prób i flag](2026-11-13-map-retries-flags.md).


## Problem i krótki brainstorming

Mapa zajmuje około 43% wysokości, a długie instrukcje i przycisk bez wybranej
odpowiedzi zabierają miejsce. W stolicach nazwa państwa jest mniejsza niż
ogólne pytanie i konkuruje z etykietą trudności.

Opcje: (1) większa mapa pod zwykłym nagłówkiem w kolumnie, (2) mapa na cały
obszar ekranu z krótkim nagłówkiem i dolnym panelem nakładanym na mapę.
Wybrano (2), zgodnie z konkretnym żądaniem użytkownika. Pozostawiamy
Material 3, istniejący motyw i jawne zatwierdzanie.

## Zakres

- Mapa wypełnia viewport; krótki nagłówek pytania i powrót.
- „Potwierdź” pojawia się dopiero po zaznaczeniu państwa. Sam zoom klastra
  nie jest wyborem ani zapisem odpowiedzi.
- Informacja zwrotna i następne pytanie w dolnym panelu z SafeArea.
- Stolice: duża nazwa państwa + krótkie „Stolica?”. Bez etykiety trudności
  w samym quizie. Wyjątkowe pytania Szwajcarii/Holandii zachowują znaczenie.
- Nie zmieniamy ocen, danych edukacyjnych, FSRS ani zasad zapisu.

Luna: ekran i wskazówki UI/UX Pro Max. Terra: przepływy i test wymiarów mapy
oraz potwierdzania. Sol: integracja, kontrola wizualna Chrome i dokumentacja.

## Weryfikacja

Przepływ mapy z mikropaństwami; brak zapisu przed potwierdzeniem; stolice
w trzech trybach; dzienna sesja mieszana. Telefoniczny viewport i duży tekst.
Format, analyze, adekwatne testy, jedna końcowa kontrola Web i hot reload.
Android pozostaje celem, bez emulatora i instalacji SDK.
