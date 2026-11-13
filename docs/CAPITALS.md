# Stolice Europy — 0.3

51 państw z katalogu Europy, 10 pytań w sesji. Użytkownik wybiera:

1. Łatwy: cztery odpowiedzi A–D, jeden wybór i jawne zatwierdzenie.
2. Średni: widoczna i nieedytowalna pierwsza litera; użytkownik dopisuje resztę.
3. Trudny: puste pole, bez pierwszej litery i bez podpowiedzi długości.

Każdy poziom ma osobną sesję do wznowienia. Sesja mapowa również jest osobna.
Kolejność pytań, poprawne odpowiedzi, warianty A–D, aliasy, uwagi i wersja
paczki są zapisywane przy rozpoczęciu. Restart nie zmienia tych danych.
Nie przesuwamy pytania przed wybraniem „Następne pytanie”.

## Ocenianie

W trybach pisanych tolerujemy jedną operację: zamianę litery, wstawienie,
usunięcie lub przestawienie dwóch sąsiednich liter. Przykład: Warszaqa → Warszawa.
Dwie operacje oznaczają błąd. Odpowiedzi puste i samych spacji nie można zatwierdzić.
Wielkość liter, diakrytyka (również znaki złożone Unicode), zewnętrzne spacje
oraz wielokrotne spacje nie wpływają na ocenę. Jawnie wymienione endonimy,
np. Bern i Andorra la Vella, są dopuszczonymi odpowiedziami.

Po zaakceptowaniu literówki pokazujemy komunikat i poprawną polską pisownię.
Wynik próby zapamiętuje, czy została zaakceptowana literówka. W trybie A–D
wskazanie innego miasta jest zawsze błędne; tolerancja pisowni go nie dotyczy.

## Dane i akceptacja

Źródła i odtwarzalny proces: `CONTENT_POLICY.md` oraz
`tools/data_pipeline/build_capitals.py`. Uwzględniamy szczególne pytania
Szwajcarii (siedziba władz federalnych) i Holandii (stolica konstytucyjna).

Testy obejmują trzy przepływy UI na ekranie 390×844, poprawny zapis poziomu,
przykład Warszaqa, błędy dwuliterowe, podpowiedź pierwszej litery, pusty
początkowy input, cztery jednoznaczne odpowiedzi oraz migrację bazy z 0.2.
Od wersji 0.4 formaty mają niezależne karty FSRS i terminy powtórek.
Zasady ocen i wczesnego treningu: `MEMORY.md`.
