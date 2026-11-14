# Stały kadr kontynentu i reakcje kuny

Zakres zlecony: usunięcie silnego automatycznego przybliżania celu, dwa wyrazy
maskotki i motywacyjne teksty. Bez ponownego zatwierdzania tego samego zakresu.

## Decyzje

- Kadr zależy tylko od kontynentu, nie od odpowiedzi ani seeda pytania.
  Domyślnie pełny zakres; najwyżej minimalna korekta skali, bez celowania w kraj.
  Wybieramy pełny zakres jako najprostszy test tej mechaniki i najlepszy brak podpowiedzi.
  Ręczne przybliżanie i zoom klastra mikropaństw pozostają świadomymi gestami.
- Imagegen: dwa przezroczyste warianty istniejącej kuny, uśmiech i łagodny smutek.
  Globus, proporcje, styl i tożsamość maskotki zachowane; bez tekstu w bitmapie.
- Podsumowanie zakończonej serii: wesoła po samych poprawnych ocenianych próbach
  lub treningu bez oceny; smutna przy błędach, z tekstem wsparcia. Brak progu punktowego.
  Wcześniejsze przerwanie i zero odpowiedzi: neutralna oryginalna kuna.
- Copy docenia wysiłek, wskazuje sens powtórek, bez zawstydzania, kar i deklaracji
  opanowania. Obraz nie blokuje CTA ani feedbacku; bez nowych animacji.

## Zadania i kontrola

- [x] Sol: test kadrów różnych celów i seedów, następnie wspólny kadr kontynentu.
- [x] Sol: wygenerować/obejrzeć/zapisać dwa PNG i prompty źródłowe.
- [x] Luna: komponent reakcji, integracja podsumowania i test małego ekranu/tekstu.
- [x] Sol: Chrome telefonu, kontrola mapy i zakończenia serii; hot reload/restart.
- [x] Format/analyze/test, pięć walidatorów danych, aktualizacja bieżących instrukcji.

Nie zmieniamy historii, ocen FSRS, danych geograficznych ani globalnej konfiguracji.
Nie uruchamiamy emulatora i nie wykonujemy automatycznego commita.

Wynik: 75 testów, analiza i pięć walidatorów bez błędów. Chrome 390×844:
stały szeroki kadr przy pytaniu o Cypr, przerwana seria z neutralną kuną,
ukończona seria 0/10 ze smutną oraz 10/10 z wesołą. Źródłowe prompty i
pliki: output/imagegen/kuna-emotions/PROMPTS.md.
