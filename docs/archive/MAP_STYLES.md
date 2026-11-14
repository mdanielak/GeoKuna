# Style map i ustawienia

## Wybór w aplikacji

Ustawienia → Wygląd mapy udostępniają trzy globalne style:

1. **Nowoczesny atlas:** spokojne pastelowe państwa, cienkie granice i jasny błękit wody.
2. **Papierowy atlas:** ciepłe wypełnienia, delikatna faktura i siatka geograficzna
   projektowana tą samą kamerą co państwa.
3. **Rzeźba terenu — domyślna:** prawdziwy lokalny raster pod czytelnymi granicami.

Styl jest wspólny dla atlasu i quizów. Zmiana zachowuje kadr oraz wybór użytkownika.
Prawidłowe/błędne odpowiedzi mają te same wyraźne kolory wektorowe w każdym stylu.
Geometria i hit-test nie pochodzą z obrazów koncepcyjnych imagegen.

Poziom nowych ręcznych quizów stolic i flag zapamiętujemy osobno dla każdego
kontynentu: Bardzo łatwy (A–D), Łatwy (pierwsza litera), Normalny (pełne
wpisywanie, domyślnie). Zaplanowane powtórki zachowują swój oryginalny format;
A–D nadal nie ocenia wiedzy. Ekran przygotowania quizu pokazuje zapisany poziom
z odnośnikiem do ustawień. Quiz flaga → mapa nie ma poziomu pisania.

Preferencje są trwale zapisane w osobnej tabeli `app_preference_entries`,
wprowadzonej migracją v5→v6. Reset nauki nie usuwa tych preferencji.
Z quizu mapy usunięto wybór kraju z listy; historyczne oznaczenia pomocy pozostają.
Wyszukiwarka atlasu oraz ręczne przesuwanie/przybliżanie mapy są dostępne.

## Warstwa „Rzeźba terenu”

Warstwa pokazuje rzeczywiste, uogólnione cieniowanie terenu ze źródła
[Natural Earth I with Shaded Relief, 1:50m, wersja 3.2.0](https://www.naturalearthdata.com/downloads/50m-raster-data/50m-natural-earth-1/).
Natural Earth deklaruje swoje rastry i wektory jako [domenę publiczną](https://www.naturalearthdata.com/about/terms-of-use/).
Oryginał to raster przedstawiający pokrycie lądu i relief, zapisany w WGS84.

Źródłowe archiwum: `https://naciscdn.org/naturalearth/50m/raster/NE1_50M_SR.zip`;
SHA-256 `ae930744c0cf3d10e73c292726b74c81a40490a75829f8299dec9069e5d0e934`.
Wersja i sumy wyników znajdują się w `assets/maps/styles/relief/manifest.json`.
Grafiki wygenerowano z rzeczywistych danych, nie z makiety ani przez model AI.

Generator przelicza każdy wiersz ze źródłowych współrzędnych WGS84 do Web Mercatora
(EPSG:3857), z interpolacją dwuliniową. Szerokość każdego PNG to 1536 pikseli;
wysokość wynika z proporcji regionu w tej projekcji. Pliki są ograniczone do
obszarów mapy quizowej:

| Region | Południowy zachód | Północny wschód | Wymiary PNG |
|---|---|---|---|
| Europa | 34°N, 32°W | 72°N, 65°E | 1536 × 1099 |
| Afryka | 36°S, 26°W | 38°N, 65°E | 1536 × 1346 |
| Azja | 12°S, 20°E | 82°N, 180°E | 1536 × 1579 |

Paleta jest lekko rozjaśniona i zgaszona, a jednolicie białe w źródle morze
przyjmuje spokojny błękit RGB `218, 238, 244`. Wskazanie i ocenianie państw
nadal wynikają z osobnych wektorów, a nie z tej grafiki. Natural Earth I 3.2.0
oraz wektory 5.1.2 mają różne wersje generalizacji: przy dużym powiększeniu
mogą pojawić się drobne różnice konturu wybrzeża oraz pikselizacja reliefu.
Warstwa reliefu nie rozstrzyga przynależności terytorialnej i nie zawiera nazw,
odpowiedzi ani wyróżnienia kraju, o który pyta quiz.

Łączny rozmiar trzech wynikowych PNG: około 2,6 MB; działają bez sieci i bez
nowej zależności aplikacji. Obrazy są indeksowane do 256 kolorów, aby zmniejszyć
rozmiar paczki. Pojedynczy obraz ma około 1,7–2,4 mln pikseli po rozwinięciu;
koszt pamięci i płynność na fizycznym Androidzie wymagają późniejszej próby.

## Odwzorowanie i walidacja

```bash
# Walidacja dołączonych plików: bez sieci
python3 tools/data_pipeline/build_relief.py --check

# Odzyskanie z już pobranego, przypiętego archiwum
python3 tools/data_pipeline/build_relief.py --build --source /ścieżka/NE1_50M_SR.zip

# Alternatywnie pobranie przypiętego archiwum przy budowie (~39 MB)
python3 tools/data_pipeline/build_relief.py --build
```

Budowanie wymaga Pythona i istniejącego Pillow; nie są to zależności runtime
aplikacji. Źródłowy ZIP nie jest dodany do repozytorium. Generator sprawdza SHA
archiwum, rozmiar źródła i metadane GeoTIFF oraz zapisuje wersję Pillow, kolory,
projekcję, zakresy i sumy. `--check` offline weryfikuje trzy zestawy zakresów,
wymiary, sumy SHA-256 oraz punkty kontrolne lądu i morza w każdym regionie.
Odtworzenie przy Pillow 10.2.0 zweryfikowano porównaniem sum wszystkich PNG.
