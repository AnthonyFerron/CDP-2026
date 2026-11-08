# HUD dans le style des menus

Fichiers : `frontend/scenes/ui/hud.tscn` et `hud.gd`. Le HUD reprend les éléments des menus (`scenes/ui/menus/ornate.gd`) : cadres sombres à bordure dorée et coins coupés, plaques hexagonales, touches du clavier (`Ornate.KeyCap`), losanges, Cinzel Bold pour les titres et Lora pour les textes, couleurs `Ornate.GOLD`, `CREAM`, `MUTED`, `PANEL`. Aucune police nouvelle : la version web n'a que les nôtres.

## Ce qui change à l'écran

Toutes les mesures sont en coordonnées de référence (1920 × 1080). Le projet étire l'interface en gardant ses proportions (`canvas_items`, `keep`) : à 1280 × 720 tout est aux deux tiers, et les textes de 30 px y font 20 px.

| Élément | Avant | Après |
| --- | --- | --- |
| Invite | texte détouré « [E] Parler au roi » | cartouche doré en bas au centre (y 924 à 988), touche E dessinée, texte Lora 30 crème ; la largeur suit le texte |
| Invite sans touche (`set_raw_prompt`) | texte seul | même cartouche, sans touche |
| Messages | texte détouré en haut, qui passait sous le chronomètre | cartouche doré en haut au centre (à partir de y 88), à la largeur du texte (1 160 px de texte au plus, puis à la ligne) ; un « [I] » devient la lettre dans une touche |
| Lecteur de textes | panneau brun à bord arrondi, « [E] Fermer » | cadre des menus (`Ornate.Frame`), titre sur une plaque hexagonale à cheval sur le bord haut, touche E et « Fermer » en pied |
| Chronomètre | texte détouré, sous les panneaux d'énigme | plaque hexagonale en haut à droite (x 1442 à 1902, y 12 à 66), chiffres à chasse fixe (`tnum` de Lora), au-dessus des panneaux d'énigme |
| Chronomètre au rouge (moins de 5 min) | texte rouge | texte rouge, bordure rouge, fond rouge sombre |
| Mire | point crème | petit losange doré bordé de sombre |
| Bandeau « Mauvaise réponse » | 1 000 px de large | 940 px (x 490 à 1430), pour laisser la place à la plaque du chronomètre |

Les cartouches sont translucides (`PLATE_FILL`, opacité 0,86) et ne s'affichent qu'avec un texte : la vue du jeu reste dégagée.

## Couches

| Couche | Contenu |
| --- | --- |
| 1 | HUD : invite, messages, lecteur, mire, fondu au noir |
| 2 | panneaux d'énigme (tablette, runes, cercles, dispositif des codes, carnet) |
| 3 | **chronomètre** (`Hud/Clock`) |
| 5 | cinématique de fin du hub (le HUD y est caché) |
| 35 | bandeau « Mauvaise réponse » (`Hud/Warning`) |
| 40, 41 | menu pause, indices |
| 60 | transition |

Le chronomètre a sa propre couche : le joueur voit le temps qui reste pendant qu'il résout une énigme. Sa plaque, en haut à droite, ne recouvre ni le titre, ni la croix de fermeture, ni les boutons d'aucun panneau ; elle passe seulement sur le coin du cadre de la tablette (bord haut à y = 60) et du dispositif des codes (bord haut à y = 44). Le menu pause et les indices passent par-dessus, avec leur voile.

Une couche fille d'un `CanvasLayer` ne suit pas sa visibilité : `Clock` et `Warning` suivent celle du HUD par `visibility_changed`. Le hub cache le HUD pendant ses cinématiques, et le chronomètre avec.

## Ce dont dépendent les scripts et les tests

Inchangés : `%Prompt`, `%Message`, `%Reader`, `%ReaderTitle`, `%ReaderBody`, `%Fade`, `%Crosshair`, `%Timer`, `%Penalty` (mêmes types : `Label`, `ColorRect`, `Control`), le chemin `Hud/Warning/Banner`, le signal `reader_closed`, les méthodes `set_prompt`, `set_raw_prompt`, `show_message`, `show_text`, `set_crosshair_visible`, `fade`, `show_penalty_warning`, et `Hud.WARNING_TOP` / `WARNING_BOTTOM` (dispositif du Village).

Deux textes changent de forme :

- `%Prompt` ne contient plus « [E] » : la touche est dessinée à côté. Les tests cherchent l'action (« Parler », « tablette »…), pas la touche.
- dans `%Message`, « [I] » devient « I » entouré d'espaces, et une touche est dessinée dessous (`Label.get_character_bounds`).

## Coût par image

- Le texte du chronomètre n'est refait que quand la seconde affichée change ; sa couleur et sa visibilité, seulement quand elles changent. Avant, il était reformaté à chaque image.
- Les cartouches et plaques sont dessinés par `draw` et ne se redessinent que quand leur taille ou leur texte change. Aucun shader, aucune texture.
- Ils sont faits de quadrilatères (`draw_primitive`, `draw_line` épais), que le rendu Compatibility regroupe en un appel de dessin par cartouche. Chaque polygone (`draw_polygon`, `draw_polyline`, `Ornate.diamond`) en coûte un : la première version en polygones montait à 27 appels.

### Mesures

Profilage natif (`frontend/tests/scenes/hud_perf.gd`, avec `sans-hub`), 1920 × 1080, rendu Compatibility sur llvmpipe (rendu logiciel du serveur, chargé : les temps varient d'un passage à l'autre). Le HUD seul sur fond noir, avec le chronomètre, un message de deux lignes et une invite ; deux passages alternés de chaque version, 240 images chacun.

| | Avant | Après |
| --- | --- | --- |
| `_process` du HUD, par image | 2,7 à 3,3 µs | 1,0 à 1,3 µs |
| Appels de dessin, HUD affiché | 9 | 9 (27 en polygones) |
| Appels de dessin, lecteur ouvert | 12 | 21 (le cadre `Ornate.Frame` des menus, en polygones) |
| Rendu CPU, HUD affiché | 8,7 à 10,4 ms | 1,7 à 3,1 ms |
| Rendu « GPU » (llvmpipe), HUD affiché, minimum | 4,8 à 5,9 ms | 6,5 à 7,9 ms |

Le seul surcoût est la surface des cartouches à mélanger, sensible en rendu logiciel (environ 2 ms à 1080p sur llvmpipe) et négligeable sur une carte graphique. Le lecteur n'est ouvert que joueur arrêté. Au hub, la mesure est noyée dans le rendu 3D (plus d'une seconde par image sur llvmpipe chargé).

## Version web

Le HUD n'ajoute aucun fichier de police : le chronomètre utilise une variation de Lora (`FontVariation` dans `hud.tscn`, fonction OpenType `tnum`, chiffres à chasse fixe), les titres Cinzel Bold (`ui/cinzel_bold.tres`). Les modèles web officiels ont le serveur de texte avancé (HarfBuzz), qui applique `tnum`. Vérifié sur le paquet exporté comme en production (`frontend/Dockerfile`), lancé en natif avec `--main-pack` : chiffres de 20 px chacun à 30 px, touches, cartouches et lecteur identiques aux captures. Aucun glyphe hors de Lora et Cinzel (lettres, chiffres, « É », « : », et le « − » du bandeau, déjà là avant).

## Vérifier

- `frontend/tests/scenes/hud_shots.gd` prend les captures du HUD dans chaque lieu (invite devant le roi et devant un panneau, message, lecteur, chronomètre normal et au rouge, chaque panneau d'énigme ouvert avec et sans le bandeau, pause, indices), et vérifie pour chaque panneau que le chronomètre est au-dessus sans en cacher le titre ni les boutons :

  ```
  xvfb-run -a -s "-screen 0 1920x1080x24" godot --audio-driver Dummy --path frontend --resolution 1280x720 \
    --script res://tests/scenes/hud_shots.gd -- <dossier> [hub|plaine|desert|marais|village…] --api=http://127.0.0.1:9/api/v1
  ```

- `timer_test` fait la même vérification sur la tablette de la Plaine, et vérifie que le chronomètre est caché pendant la fin.
- `timer_test` lit le texte et la couleur du chronomètre après `settle()` (`common_test.gd`) : ils sont posés dans le `_process` du HUD, et sous charge, `wait()` peut finir sur une suite d'images physiques sans `_process`.
