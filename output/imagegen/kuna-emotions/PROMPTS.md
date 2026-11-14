# GeoKuna — emocje wybranej kuny

Wykonano 2026-11-13 wbudowanym narzędziem `image_gen.imagegen` (bez CLI/API key).
Tryb: edycja istniejącego obrazu; tło przezroczyste (`transparent_background=true`).
Referencja obu edycji: `assets/mascot/kuna-globe.png` (wybrany wariant 1).
Wyniki skopiowano do projektu bez zastępowania oryginału i bez obróbki obrazu.
Oba pliki: RGBA 1278×1230, kanał alpha od 0 do 255. W aplikacji skalowane
z zachowaniem proporcji, z ograniczeniem rozmiaru dekodowania.

## Wesoła

Plik: [assets/mascot/kuna-happy.png](../../../assets/mascot/kuna-happy.png)

Dokładny prompt:

> Use case: identity-preserve. Edit this existing GeoKuna mascot into ONE happy variant for an educational mobile geography quiz results screen. Preserve the exact same adorable chest-up brown pine marten character, large ears, yellow cream throat, fluffy illustrated fur, original illustration style and holding the same blue-green globe with both paws. Change the facial expression only to visibly delighted, cheerful, warm proud smile, bright friendly eyes and subtly raised happy eyebrows, no teeth needed. Keep same framing, same relative size and original pose, entire ears and globe in frame. Clean small UI asset silhouette, genuinely transparent background including around fur, no scene, no shadow backdrop, no text, no badges, no other objects. Single character, one image, not a sheet. Maintain consistency with reference.

## Smutna

Plik: [assets/mascot/kuna-sad.png](../../../assets/mascot/kuna-sad.png)

Dokładny prompt:

> Use case: identity-preserve. Edit this existing GeoKuna mascot into ONE mildly SAD variant for an educational mobile geography quiz results screen. Preserve the exact same adorable chest-up brown pine marten character, large ears, yellow cream throat, fluffy illustrated fur, original illustration style, original pose, holding the same blue-green globe with both paws. Change facial expression only: clearly sad but gentle and endearing, inner eyebrows lifted in concern, slightly downturned mouth (not smiling), soft downcast friendly eyes looking toward viewer, no tears or crying, no anger, no guilt or scolding. We want a supportive companion who also feels a little sad after a difficult adventure. Same framing and relative size, complete ears and globe visible. Genuinely transparent background including around fur, no scene, no shadow backdrop, no text, no badge, no other objects. Single character one image not a sheet.

Teksty motywacyjne są osobnymi tekstami Fluttera — nie są częścią bitmap.
