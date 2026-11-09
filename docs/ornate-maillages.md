# Ornate en maillages

Suite de « Ce qui reste » de `docs/accueil-anime.md` : les cadres, boutons, pastilles, touches, séparateurs et icônes des menus (`frontend/scenes/ui/menus/ornate.gd`) coûtaient à eux seuls environ 130 appels de dessin à l'accueil. Ils servent aussi à la pause, aux indices, au lecteur de textes, au HUD, aux cinq panneaux d'énigme et au clavier virtuel.

L'image ne change pas : les captures avant et après, dans tous les états (normal, survol, appuyé, désactivé, focus de la manette), sont identiques à un niveau de couleur près sur quelques pixels (voir « Vérifié »).

## Pourquoi c'était cher

Le rendu Compatibility (WebGL 2 dans le navigateur) regroupe les rectangles, les glyphes d'une même police et les petits quadrilatères (`draw_rect`, `draw_string`, `draw_line` épais, `draw_primitive`) en un appel de dessin, tant qu'ils se suivent. Il ne regroupe **jamais** deux polygones : chaque `draw_polygon`, `draw_colored_polygon`, `draw_polyline`, `draw_arc`, `draw_circle` et `draw_style_box` (StyleBoxFlat) coûte son propre appel (`rasterizer_canvas_gles3.cpp` : « Polygon's can't be batched »).

Un bouton hexagonal en faisait dix (fond, deux bords, deux losanges de trois polygones chacun, texte), un cadre une vingtaine, une icône de laurier treize, une ligne du podium du classement une trentaine. Dans le navigateur, chaque appel est vérifié par WebGL puis traduit par ANGLE ; dans le rendu logiciel (SwiftShader, llvmpipe), chacun relance aussi le traitement des sommets.

## Ce qui change

### Un maillage par élément : `Ornate.Sketch`

Chaque élément réunit toutes ses formes en un seul maillage (sommets et couleur par sommet), envoyé d'un bloc par `RenderingServer.canvas_item_add_triangle_array` : **un appel de dessin pour toutes ses formes**, puis un pour son texte. Le fond du menu (`MenuBackdrop.Shape`) fait déjà ainsi.

Pour que l'image reste la même, chaque forme reprend les sommets et les triangles que Godot 4.7.2 calcule pour la fonction de dessin qu'elle remplace (sources : `renderer_canvas_cull.cpp`, `canvas_item.cpp`, `style_box_flat.cpp`) :

| Forme de `Sketch` | Remplace | Ce que fait le moteur, refait à l'identique |
| --- | --- | --- |
| `polygon`, `polygon_colors` | `draw_colored_polygon`, `draw_polygon` | même triangulation (`Geometry2D.triangulate_polygon`) : les dégradés par sommet tombent sur les mêmes triangles |
| `polyline` | `draw_polyline` épais | bande de triangles, deux sommets par point, onglets aux coins bornés à trois fois la demi-largeur, ligne fermée sans rupture quand elle revient à son premier point |
| `line` | `draw_line` épais | un quadrilatère ; sa couleur est arrondie en demi-flottants (16 bits), comme le moteur l'envoie pour ses quadrilatères |
| `rect`, `rect_outline` | `draw_rect` plein ou vide | rectangle, ou contour fermé (ou rectangle agrandi si le trait est plus large que lui) |
| `circle` | `draw_circle` | 64 secteurs autour du centre |
| `arc` | `draw_arc` | les mêmes points sur l'arc, en ligne brisée |
| `style_box` | `draw_style_box` d'un `StyleBoxFlat` | ombre, bordure, fond et anticrénelage des coins arrondis, mêmes anneaux et mêmes triangles ; la largeur de l'anticrénelage suit le suréchantillonnage de la fenêtre, comme dans le moteur |
| `text` | `draw_string` | inchangé : le texte ferme le maillage en cours, le suivant reprend après lui |

L'ordre des formes et des textes est celui des appels. Quatre éléments dessinent une forme avant un texte qui la précédait, là où ils ne se touchent pas : le losange sous la plaque de titre (`Ornate.plaque`), le cadre doré de la manette autour des boutons (`HexButton`, `PillButton`), le livre en pied d'un cadre (`Frame`), le moyeu et le repère du cadran du Marais (au centre et au-delà des lettres). Le soulignement des liens (`TextLink`), qui passe sur les jambages, reste après le texte.

Les fonctions de dessin d'Ornate (`diamond`, `divider`, `plaque`, `icon`, `focus_ring`, `pad_glyph`, `centered_text`) prennent maintenant un nœud **ou** un `Sketch` : sur un nœud, elles envoient leurs formes d'un bloc (un appel au lieu de trois à treize) ; sur un `Sketch`, elles s'y ajoutent sans appel de plus. Les panneaux qui les appellent sur eux-mêmes gagnent donc sans changer. Pour tracer ailleurs : `var pen := Ornate.Sketch.new(self)`, les formes, puis `pen.draw(self)` dans `_draw` ; ou `Ornate.Sketch.of(item)` et `pen.done(item)` dans une fonction qui accepte les deux (`RunePuzzle.draw_glyph`).

### Des touches dessinées d'un bloc : `Ornate.KeySheet`

Un panneau de commandes alternait une touche (cadre, puis lettre en Cinzel) et sa légende (Lora) : trois appels par ligne, vingt-quatre pour l'accueil. Le calque qui porte les touches (`Ornate.KeySheet`) les dessine maintenant toutes : un maillage pour leurs cadres, puis leurs lettres, rangées par police et par taille (`texts_last`). Les touches (`KeyCap`) restent des nœuds, mais ne dessinent plus rien ; les légendes, qui se suivent alors, ne coûtent qu'un appel ensemble. Une touche qui doit se redessiner (bascule de la manette) le demande à son calque.

Le calque peut aussi dessiner des voisins qu'il adopte (`adopt`) : les 45 touches du clavier virtuel (`PadKeyboard.KeyButton`, qui restent des boutons, avec leur focus et leur survol) et les boutons de la manette rappelés en pied. Les rappels de touches du dispositif des codes et du carnet du Village sont aussi des `KeySheet`.

### Des formes calculées une fois

Construire les maillages en GDScript coûte plus cher que les fonctions du moteur, écrites en C++ : un cadre arrondi de `StyleBoxFlat` refait en GDScript prenait 0,7 ms, un arc de 96 points 0,26 ms. Les formes qui ne dépendent que de leur taille (cadres arrondis, arcs, disques, icônes, losanges) sont donc calculées une fois, autour de l'origine, et gardées (`Sketch.shape`) ; les suivantes, identiques à une translation près, sont recopiées et déplacées d'un bloc (`Transform2D * PackedVector2Array`, en C++). Les triangles sont rangés sommet par sommet, sans indices : recopier une forme ne demande pas de renuméroter ses sommets. Une touche du clavier coûte alors 37 µs au lieu de 700, un arc 8 µs, un laurier 18 µs au lieu de 134 (`sketch_bench.gd`, natif).

### Où

| Fichier | Éléments |
| --- | --- |
| `scenes/ui/menus/ornate.gd` | `Sketch`, `KeySheet` ; `Frame`, `KeyCap`, `HexButton`, `PillButton`, `TextLink`, `Field`, `IconView`, `Logo` ; `diamond`, `divider`, `plaque`, `icon`, `focus_ring`, `pad_glyph` |
| `scenes/ui/menus/main_menu.gd` | en-tête et lignes du classement, ornement vertical, titre et cadre du but de l'introduction |
| `scenes/ui/menus/pad_keyboard.gd` | touches du clavier virtuel, dessinées par son `KeySheet` |
| `scripts/hints.gd` | croix et flèches des indices |
| `scenes/levels/desert/rune_puzzle.gd` | runes, pierres gravées, tuiles, lueur, trait central |
| `scenes/levels/marais/ring_puzzle.gd` | cadran, tuiles des lettres, flèches, lueur |
| `scenes/levels/village/code_puzzle.gd`, `paper_notebook.gd` | onglets, page d'archives, lueur ; rappels de touches en `KeySheet` |

## Ce dont dépendent les scripts et les tests

Inchangés : les noms des nœuds (`NewGame`, `Submit`, `Key00`, `Clavier`, `Manette`, `PadKeys`…), leurs types (`Ornate.Frame`, `KeyCap`, `HexButton`… ; les calques `Clavier` et `Manette` sont des `KeySheet`, qui héritent de `Control`), les signaux, les propriétés (`caption`, `highlighted`, `glyph()`, `pad`, `bare`, `title`, `title_size`…) et les méthodes publiques. Le seul changement de signature : les fonctions de dessin d'Ornate et `RunePuzzle.draw_glyph` acceptent un `Object` (nœud ou `Sketch`) au lieu d'un `CanvasItem` ; les appels existants ne changent pas.

Le calque `KeySheet` du clavier virtuel ne prend ni la souris ni le focus : les touches restent des boutons ordinaires, à la souris comme à la manette.

## Mesures

Serveur arm64 de 4 cœurs, partagé avec d'autres agents (charge de 7 à 18 pendant les mesures) : les temps varient d'un passage à l'autre, les appels de dessin non. Chaque écran est construit seul (`ornate_bench.gd`, ou son pilote web), sans lieu ni 3D, et mesuré immobile.

### Appels de dessin 2D par image

Natif, rendu Compatibility, 1280 × 720 (les mêmes dans Chromium). Le fond animé du menu en coûte 28 à lui seul, inchangé.

| Écran | Avant | Après |
| --- | --- | --- |
| Fond du menu seul | 27 | 28 |
| Accueil | 159 | 53 |
| Accueil, à la manette | 190 | 54 |
| Accueil, confirmation « Nouvelle partie » | 196 | 59 |
| Connexion | 87 | 44 |
| Création de compte | 85 | 43 |
| Code de vérification | 105 | 49 |
| Classement (huit lignes) | 240 | 75 |
| Introduction | 89 | 42 |
| Pause | 79 | 13 |
| Pause, à la manette | 109 | 14 |
| Indices | 48 | 11 |
| HUD (chronomètre, message, invite) | 10 | 10 |
| Lecteur de textes | 15 | 9 |
| Tablette de la Plaine | 93 | 64 |
| Table des runes du Désert | 134 | 51 |
| Cercles du Marais | 129 | 43 |
| Dispositif des codes du Village | 147 | 56 |
| Clavier virtuel (sur le dispositif) | 339 | 67 |
| Carnet des fragments | 45 | 16 |

Sans le fond, les éléments d'Ornate de l'accueil passent d'environ 132 appels à 25.

### Temps d'image

Le serveur n'a pas de carte graphique : le navigateur dessine en logiciel (SwiftShader), le natif aussi (llvmpipe). Ces deux rendus passent l'essentiel de l'image à remplir des pixels, que ce chantier ne change pas : le temps d'image y bouge peu. Le gain attendu est ailleurs : sur une vraie carte graphique, chaque appel de dessin coûte du temps au fil principal du navigateur (vérification par WebGL, traduction par ANGLE, envoi au processus GPU), quel que soit le nombre de pixels.

**Même processus, en alternance** (`ab_ornate.gd`, natif, llvmpipe, 1280 × 720, sur fond noir) : l'accueil (cadre des commandes, logo, trois boutons, carte du joueur et ses pastilles) construit avec l'ancien Ornate (copie renommée) puis avec le nouveau, six tours, 150 images chacun. 129 appels de dessin avant, 22 après ; image médiane 67,7 ms avant, 67,1 ms après (rendu GPU 38,5 et 38,3 ms) : égalité, llvmpipe est limité par les pixels.

**Dans Chromium** (export de mesure, SwiftShader, 1280 × 720, `ornate_driver.gd`), trois passages de chaque version, en alternance ; temps d'image médian de chaque passage (un quatrième passage, fait pendant une construction Docker et la suite de tests, est écarté) :

| Écran | Appels, avant | après | Image médiane, avant (3 passages) | après (3 passages) |
| --- | --- | --- | --- | --- |
| Accueil | 160 | 53 | 94,3 / 87,6 / 88,2 ms | 87,0 / 85,7 / 92,5 ms |
| Connexion | 86 | 43 | 78,8 / 70,8 / 77,2 ms | 79,1 / 70,1 / 77,4 ms |
| Création de compte | 86 | 43 | 78,5 / 67,0 / 79,9 ms | 77,9 / 64,7 / 81,0 ms |
| Code de vérification | 106 | 49 | 75,2 / 78,6 / 78,8 ms | 75,9 / 69,5 / 79,3 ms |
| Classement | 240 | 75 | 94,4 / 83,8 / 92,6 ms | 89,3 / 80,8 / 87,3 ms |
| Introduction | 90 | 42 | 91,2 / 90,8 / 92,0 ms | 88,5 / 78,2 / 89,5 ms |
| Fond du menu seul | 28 | 28 | 63,3 / 56,0 / 63,3 ms | 60,3 / 50,0 / 61,6 ms |
| Pause | 79 | 13 | 62,4 / 65,6 / 72,5 ms | 68,3 / 64,1 / 66,2 ms |
| Indices | 48 | 11 | 62,4 / 59,4 / 62,1 ms | 58,9 / 61,9 / 58,7 ms |
| Lecteur de textes | 15 | 9 | 42,3 / 41,8 / 42,9 ms | 42,2 / 43,4 / 43,0 ms |
| Tablette de la Plaine | 96 | 67 | 80,1 / 73,0 / 81,0 ms | 84,9 / 80,6 / 80,2 ms |
| Table des runes | 140 | 53 | 87,0 / 79,1 / 85,2 ms | 80,7 / 82,4 / 83,3 ms |
| Cercles du Marais | 129 | 43 | 61,5 / 61,3 / 61,4 ms | 57,2 / 60,7 / 61,4 ms |
| Dispositif des codes | 147 | 56 | 110,6 / 105,4 / 109,7 ms | 107,7 / 108,1 / 112,7 ms |
| Clavier virtuel | 327 | 67 | 133,4 / 131,2 / 136,4 ms | 129,4 / 128,4 / 127,1 ms |
| Carnet des fragments | 45 | 16 | 82,7 / 85,5 / 87,2 ms | 87,2 / 86,1 / 85,8 ms |

Les écarts suivent la charge du serveur plus que la version, sauf là où le nombre d'appels chute le plus : clavier virtuel (environ 4 ms de moins à chaque passage), classement (3 à 5 ms), table des runes et cercles (0 à 6 ms).

**Appels WebGL et temps du fil principal** (Chromium, mêmes écrans) : la page compte chaque appel WebGL 2 du jeu et chronomètre ceux qui ne font qu'envoyer une commande (moins d'une milliseconde ; les rares appels qui attendent la fin du dessin logiciel sont comptés à part). C'est le coût qui reste sur une vraie carte graphique, pour chaque image, quel que soit le nombre de pixels : un appel de dessin de Godot en demande une trentaine (programme, tampons, attributs, uniformes). Deux passages de chaque version, en alternance :

| Écran | Appels de dessin, avant / après | Appels WebGL par image, avant → après | Fil principal dans WebGL, par image, avant → après |
| --- | --- | --- | --- |
| Accueil | 160 / 53 | 5 561 → 2 050 | 5,9 et 5,5 → 2,7 et 2,5 ms |
| Connexion | 87 / 44 | 3 103 → 1 745 | 3,2 et 3,3 → 2,0 et 2,3 ms |
| Création de compte | 85 / 42 | 3 037 → 1 684 | 3,2 et 3,2 → 2,2 et 2,1 ms |
| Code de vérification | 106 / 49 | 3 710 → 1 869 | 4,2 et 4,0 → 2,2 et 2,4 ms |
| Classement | 240 / 75 | 8 268 → 2 881 | 8,7 et 7,9 → 3,3 et 3,2 ms |
| Introduction | 89 / 41 | 3 216 → 1 677 | 3,6 et 3,5 → 2,1 et 2,1 ms |
| Fond du menu seul | 29 / 29 | 1 214 → 1 216 | 1,7 et 1,6 → 1,7 et 1,5 ms |
| Pause | 79 / 13 | 2 902 → 690 | 3,1 et 3,3 → 1,1 et 1,0 ms |
| Indices | 48 / 11 | 1 777 → 604 | 2,0 et 2,2 → 1,0 et 0,9 ms |
| Lecteur de textes | 15 / 9 | 851 → 660 | 1,3 et 1,3 → 1,1 et 1,2 ms |
| Tablette de la Plaine | 96 / 67 | 3 497 → 2 566 | 3,7 et 3,5 → 3,1 et 2,7 ms |
| Table des runes | 140 / 53 | 4 993 → 2 218 | 4,6 et 5,1 → 2,5 et 2,6 ms |
| Cercles du Marais | 129 / 43 | 4 553 → 1 806 | 4,6 et 4,8 → 2,3 et 2,3 ms |
| Dispositif des codes | 147 / 56 | 5 182 → 2 266 | 5,3 et 5,1 → 2,5 et 2,6 ms |
| Clavier virtuel | 327 / 67 | 11 530 → 2 721 | 10,4 et 10,8 → 3,3 et 3,2 ms |
| Carnet des fragments | 45 / 16 | 1 782 → 840 | 2,1 et 2,3 → 1,2 et 1,4 ms |

Le fil principal du navigateur passe deux à trois fois moins de temps à envoyer ses commandes : 3 ms de moins par image à l'accueil, 5 ms au classement, 7 ms au clavier virtuel, ici, sur un processeur de serveur. Sur SwiftShader, ce temps se recouvre avec le dessin logiciel, fait par le processus GPU du navigateur, d'où des temps d'image presque inchangés ; avec une carte graphique, le dessin ne coûte presque plus rien et ce temps-là pèse davantage (non mesuré ici, faute de carte graphique).

### Redessins

Les maillages sont construits en GDScript, plus lent que les fonctions de dessin du moteur (C++). Un élément ne se redessine qu'à sa construction et quand son état change (survol, appui, focus, bascule de la manette) ; le cadran du Marais à chaque image pendant qu'un cercle tourne. Temps des `_draw` (`redraw_cost.gd`, natif) :

| Redessin | Avant | Maillages, sans formes gardées | Après |
| --- | --- | --- | --- |
| Accueil entier (construction de l'écran) | 1,7 ms | 14,0 ms | 2,1 ms |
| Connexion entière | 0,9 ms | 5,4 ms | 0,9 ms |
| Classement entier | 1,6 ms | 6,0 ms | 1,1 ms |
| Un bouton de l'accueil (survol) | 0,20 ms | 0,26 ms | 0,22 ms |
| Cadran du Marais (par image, quand un cercle tourne) | 3,0 ms | 5,8 ms | 2,5 à 3,1 ms |
| Clavier virtuel entier | 2,2 ms | 5,5 ms | 2,0 ms |
| Clavier virtuel, une touche choisie | 0,1 ms par touche (deux par déplacement) | 2,2 ms (tout le calque) | 1,4 ms (tout le calque) |

Sans les formes gardées, construire l'accueil coûtait 14 ms : c'est ce qui les a fait ajouter. Restent deux surcoûts, ponctuels : la construction de l'accueil (2,1 ms au lieu de 1,7) et le déplacement dans le clavier virtuel (1,4 ms au lieu de 0,2), le calque redessinant toutes ses touches ; en échange, l'accueil coûte 107 appels de dessin de moins à chaque image, le clavier 270.

## Vérifié

- **Captures, avant et après, différence pixel par pixel** (`ornate_bench.gd`, `diff.py`) : 57 captures à 1280 × 720 et 36 à 1920 × 1080, à 30 images par seconde fixes (le fond animé est le même d'une version à l'autre). Chaque écran du menu, la confirmation « Nouvelle partie », la pause, les indices, le lecteur, le HUD, les cinq panneaux d'énigme et le clavier virtuel, dans leurs états : normal ; survol d'une pastille, d'un bouton, d'un lien, d'un onglet, de la croix des indices, de « Retour » ; bouton appuyé (accueil, connexion, pause) ; boutons désactivés (« Charger partie », « Classement », « Valider » sans code) ; focus de la manette (boutons, champs, onglets, cases, flèches, touches du clavier virtuel) ; mot de passe affiché ; code rempli ; dispositif résolu (onglets et sceau verts) ; boutons de la manette dans les commandes (A, B, X, Y, Menu, Affichage, sticks, LB, RB).
  - 1280 × 720 : au plus 46 pixels différents par capture, sur 921 600, d'un seul niveau de couleur sur 255 ; aucune différence dans 25 captures sur 57. Ce sont des arrondis : l'anticrénelage des coins arrondis et les couleurs des traits, calculés en GDScript (nombres de 64 bits) au lieu de C++ (32 bits).
  - 1920 × 1080 (sans mise à l'échelle) : au plus 3 pixels, d'un niveau.
  - Les planches (avant, après, différence amplifiée seize fois) sont dans `.claude/captures/perf-ornate/diff/` : la différence est noire à l'œil.
- **Export identique à la production** (`frontend/Dockerfile`), lancé en natif avec `--main-pack` (`ornate_bench_pck.gd`, copie autonome du banc : les tests ne sont pas dans le paquet) : les 57 captures, aucune erreur ; 8 pixels différents en tout avec la worktree, et les mêmes écarts d'un niveau avec `dev`.
- **Chromium** (SwiftShader), la page de cet export servie par le vrai Caddyfile : accueil identique à celui de `dev` (seules les étoiles qui scintillent changent d'une capture à l'autre), console sans erreur. Une première version y écrivait une erreur à chaque touche dessinée seule (`get_meta` d'une méta absente, sans valeur par défaut) : corrigé (`KeySheet.of`).
- **Tests** : la suite complète (`run_all.sh`) depuis la worktree : 0 échec, sauf les 2 voulus de `hub_walk_0` et de `hub_walk_4` ; les trois précalculs à jour ; `run_tests` à 52 réussis. `hub_test` et `hub_walk_0`, passés avant la correction de `KeySheet.of`, relancés seuls ensuite : mêmes résultats, sans l'erreur dans leur journal.

## Ce qui reste

- La tablette de la Plaine (`scenes/levels/plaine/tablet_puzzle.gd` : cases de pierre, cartes de parchemin, lueur, croix) dessine encore ses propres formes une à une (64 appels, dont environ 35 pour elle seule) : elle était en travaux chez un autre agent pendant ce chantier. Elle se convertit comme le Désert et le Marais (`Ornate.Sketch.new(self)`, mêmes appels, `pen.draw(self)`).
- Les cartouches du HUD sont déjà regroupés en quadrilatères (`docs/hud.md`) : rien à gagner.
- Chaque bouton reste un nœud à part : un maillage et un texte chacun. Les dessiner tous d'un bloc, comme les touches, demanderait de redessiner tout l'écran au moindre survol.

## Vérifier

Outils hors dépôt, dans `.claude/captures/perf-ornate/outils/` :

- `ornate_bench.gd` : chaque écran du menu, la pause, les indices, le lecteur, le HUD, les cinq panneaux d'énigme et le clavier virtuel, construits seuls ; mode `captures` (tous les états) ou `mesure` (appels de dessin, temps d'image) ; `bench.sh avant|apres <mode> <dossier>` le lance sur une copie de `dev` ou sur la worktree.
- `diff.py <avant> <après> <sortie>` : différences d'image, pixel par pixel, et planches avant, après, différence amplifiée seize fois.
- `probe_calls.gd` : appels de dessin de chaque nœud d'un écran du menu.
- `redraw_cost.gd`, `sketch_bench.gd` : coût des redessins et des formes, en GDScript.
- `ab_ornate.gd` : l'accueil construit avec l'ancien Ornate (copie renommée `OrnateAvant`, dans une copie du projet) et le nouveau, en alternance dans le même processus.
- `build_mesure.sh`, `run_web.sh`, `web/ornate_driver.gd`, `web/ornate_web.py`, `web/analyse.py`, `web/analyse_gl.py` : mêmes écrans dans Chromium, export identique à la production plus un pilote de mesure ; temps d'image, appels de dessin, appels WebGL et leur durée.
- `ornate_bench_pck.gd` (le banc sans les tests, pour `--main-pack`), `page_prod.sh` et `web/page_shot.py` (la page de l'export de production dans Chromium).
