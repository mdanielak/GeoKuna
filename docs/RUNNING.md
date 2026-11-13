# Uruchamianie GeoKuny

## Bieżący rozwój: Chrome

Projekt wymaga Fluttera i Chrome. Na bieżącym komputerze SDK Fluttera jest w
`/home/danim/.local/share/geokuna/flutter`. W nowym terminalu:

```bash
export PATH="$HOME/.local/share/geokuna/flutter/bin:$PATH"
flutter pub get
flutter run -d chrome
```

`flutter pub get` pobiera zależności, jeśli nie ma ich lokalnie. W czasie nauki
aplikacja korzysta z lokalnych pytań, geometrii i harmonogramu. Chrome służy
bieżącemu rozwojowi; jego baza jest oddzielna od bazy Androida i może podlegać
ograniczeniom magazynu przeglądarki. Nie zakładaj uruchomienia Web offline po
zamknięciu przeglądarki. Zakres kontroli: [TESTING.md](TESTING.md).

## Codzienna praca

Na Dziś rozpocznij lub wznów dzienną wyprawę. Niżej wybierz ręczny trening
mapy, stolic lub flag, atlas i postępy. Na mapie dotknięcie państwa od razu
zapisuje próbę; w quizach tekstowych użyj „Sprawdź odpowiedź” lub Enter.
Przycisk X kończy quiz po potwierdzeniu, Wstecz pozostawia go do wznowienia.

Po zmianie kodu w terminalu `flutter run`: `r` wykonuje hot reload, `R` pełny
restart, `q` kończy uruchomienie. Nie czyść danych przeglądarki, jeśli chcesz
zachować postęp. Dla stałego adresu podczas rozwoju możesz użyć:

```bash
flutter run -d chrome --web-port=8766
```

Baza Web należy do profilu i adresu przeglądarki; inny port lub profil może
pokazać osobny magazyn. Nie ma jeszcze eksportu/importu ani synchronizacji
z telefonem. Kontrole przed commitem: komendy z [TESTING.md](TESTING.md)
i [AGENTS.md](../AGENTS.md).

## Później: fizyczny telefon Android

To opcjonalny przyszły etap. Nie wymaga emulatora. Do zbudowania i uruchomienia
aplikacji na telefonie potrzebny będzie działający toolchain Flutter/Android,
w tym odpowiedni Android SDK, JDK i platform-tools; ich instalacja wymaga
osobnego uzgodnienia. `flutter doctor -v` pokaże brakujące składniki. Sama
obecność `adb` nie wystarcza do kompilacji aplikacji.

### ADB Wireless (Android 11 lub nowszy)

Na zaufanej sieci Wi-Fi połącz komputer i telefon z tą samą siecią. W telefonie
włącz opcje programisty i debugowanie bezprzewodowe. Wybierz parowanie kodem;
ekran pokaże adres IP, **port parowania** i kod. W terminalu z dostępnym `adb`:

```bash
adb pair ADRES_IP:PORT_PAROWANIA
```

Podaj kod dopiero po wyświetleniu prośby. Sprawdź połączenie `adb devices`.
Jeśli telefon nie połączy się automatycznie, użyj adresu IP i **portu debugowania**
z głównego ekranu debugowania bezprzewodowego:

```bash
adb connect ADRES_IP:PORT_DEBUGOWANIA
adb devices
flutter devices
flutter run -d IDENTYFIKATOR_URZADZENIA
```

Port parowania i port debugowania mogą się różnić oraz zmienić; odczytuj je
z odpowiednich ekranów telefonu, nie zakładaj stałego numeru. Jeśli wykrywanie
nie działa, sprawdź wspólną sieć i izolację klientów Wi-Fi; szczegóły zawiera
[oficjalna dokumentacja ADB](https://developer.android.com/tools/adb).
Debugowanie włączaj tylko w zaufanej sieci, nie udostępniaj kodu parowania;
po pracy wyłącz debugowanie bezprzewodowe, a w razie potrzeby usuń sparowany
komputer z ustawień telefonu. Nie używaj publicznej sieci do tej operacji.
