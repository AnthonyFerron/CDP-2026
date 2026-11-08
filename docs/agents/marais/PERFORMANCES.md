# Performances web des marais de Kernel Swamp (BACKLOG n° 5)

Mesures du 5 novembre 2026, sur le serveur (Linux arm64, 4 cœurs, rendu logiciel llvmpipe sous Xvfb, 1280 × 720,
rendu Compatibility, sans synchronisation verticale, 30 images par vue après 15 images de mise en route). Les temps
d'image ne valent que pour comparer avant et après, à la même vue sur la même machine : d'autres Godot tournaient en
même temps, l'écart d'un passage à l'autre atteint 20 à 35 %. Les appels de dessin, eux, sont exacts et identiques d'un
passage à l'autre (`Viewport.get_render_info`, comme `Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME`).

« Avant » : la branche sans le commit 8851bd1 (copie de travail à part, `git worktree add`, fichiers du marais repris
de 8851bd1^). « Après » : commit 59b5c47.

Outils (copiés dans `tools/`) : `perf_views.gd` (comptes, mesure des vues, captures figées), `batch_report.gd` (lots
fondus, lumières par lot, relevé trié des formes de collision), `profile_load.gd` (temps de chargement),
`diff_images.gd` (planches avant | après | écart ×4), `walkgrid_serveur.gd` (grille de marche, modes dehors, crypte et
maillages), `chain_final.sh` (toute la vérification à la suite), listes de vues `views.txt`, `decor.txt`, `life.txt`.

## Ce qui a été fait

| Quoi | Avant | Après |
| --- | --- | --- |
| Décor fixe (Props, Grounded, pontons, lanternes, crypte, tombeaux des rois, niches de l'ossuaire) | un nœud par modèle, un appel de dessin par surface | fondu au chargement par `MaraisBatch` : par case de 32 m dehors, 12 m dans la crypte, une surface par matériau. Les matériaux identiques de modèles différents d'un même kit comptent pour un ; les matériaux sans texture du kit Nature passent leur couleur dans les sommets. Ce que porte un nœud scripté (textes à lire, panneaux, énigme, tombeau du livre) reste à part |
| Petits objets (moins de 1 m : cierges, fleurs, urnes, os, champignons, seaux) | ombre, toujours dessinés | sans ombre, effacés au-delà de 40 m ; la portée est allongée du rayon de leur lot, donc aucun ne disparaît plus près de 40 m. Ce qui luit (flammes des lanternes) et tout ce qui dépasse 1 m restent dessinés comme avant |
| Bêtes | 6 à 10 pièces chacune | une grenouille = un maillage ; corbeau : corps, tête et deux ailes ; chauve-souris : corps et deux ailes ; potence : montant, puis chaîne et lanterne qui se balancent |
| Lettres du mécanisme | 130 `Label3D` | un maillage gravé par cercle ; les 26 lettres sont taillées une fois et chaque cercle les reprend à sa taille |
| Côté caché | la crypte, sous la carte, dessinée dehors (339 surfaces à l'arrivée) ; le dehors dessiné dans la crypte | seul le côté où l'on est est dessiné (`OUTSIDE_NODES` dans `marais.gd`), lumières comprises |
| Lune | ombres en 4 tranches jusqu'à 60 m | 2 tranches jusqu'à 50 m |
| Lumières du dehors | toujours allumées | les 5 lumières fixes et le feu de camp s'éteignent entre 38 et 46 m |
| Lumières de la crypte | 12 m | 12 m (inchangées, voir plus bas) |

## Comptes (tout le niveau)

| | Avant | Après |
| --- | --- | --- |
| Nœuds | 3 561 | 1 788 |
| Maillages | 1 387 | 572 |
| Qui projettent une ombre | 1 170 | 201 |
| MultiMesh (dispersion, inchangée) | 100 (642 instances) | 100 (642 instances) |
| Lumières (qui projettent une ombre) | 21 (1, la lune) | 21 (1, la lune) |
| Formes de collision | 613 | 613, identiques une à une |
| Lots fondus (décor) | — | 191, plus les tombeaux des rois et les niches |

## Vues : appels de dessin et temps d'image médian (llvmpipe)

Mesures du même passage (avant, puis après, l'un derrière l'autre) ; entre parenthèses, l'écart sur les autres passages.

| Vue | Appels avant | Appels après | Image avant | Image après |
| --- | --- | --- | --- | --- |
| Arrivée (0, 2.2, 60) vers le nord | 2 820 | 380 | 603 ms (592 à 749) | 411 ms (411 à 418) |
| Village englouti, depuis le ponton 1 | 1 320 | 277 | 545 ms (540 à 628) | 434 ms (434 à 462) |
| Campement vers le cimetière | 1 879 | 359 | 563 ms (563 à 730) | 436 ms (436 à 450) |
| Cimetière | 1 339 | 264 | 542 ms (542 à 718) | 393 ms (391 à 395) |
| Îlot de la crypte | 651 | 197 | 445 ms (445 à 594) | 335 ms (335 à 340) |
| Crypte, salle du mécanisme | 328 | 65 | 190 ms (190 à 249) | 211 ms (196 à 219) |
| Crypte, tombeaux des rois | 102 | 47 | 178 ms (178 à 241) | 176 ms (171 à 176) |
| Crypte, haut de l'escalier | 622 | 178 | 258 ms (255 à 337) | 375 ms (276 à 375) |

- Dehors : 5 à 7 fois moins d'appels de dessin, un quart à un tiers de temps d'image en moins même sous llvmpipe.
- Dans la crypte : 2 à 5 fois moins d'appels. llvmpipe y est limité par le remplissage des pixels : le temps d'image
  bouge peu, et en haut de l'escalier il monte (276 ms sur trois passages, 375 ms sur le dernier, très chargé) : les
  lots de 12 m dessinent derrière les murs plus de triangles cachés (99 000 au lieu de 63 000). Sur une vraie carte
  graphique (WebGL), le test de profondeur les rejette à bas prix, et c'est le nombre d'appels qui coûte au processeur.

## Lumières de la crypte

Le travail interrompu avait raccourci leur portée (7 à 9,5 m au lieu de 12) en croyant qu'une lumière qui touche un
objet le redessine. Mesure faite, à portée réduite comme à 12 m : mêmes appels de dessin (65, 28 et 178 dans la salle,
la chambre est et l'escalier), même temps d'image. Une lumière sans ombre se calcule dans la même passe. Les portées
courtes assombrissaient en revanche les murs (chambre est, escalier) : elles sont rendues à 12 m. Chaque lot de la
crypte reçoit 7 lumières au plus, sous la limite de 8 par objet du rendu Compatibility.

## Chargement

`profile_load.gd`, avec fenêtre : la scène entière est prête en 280 ms avant, 780 à 816 ms après. Le regroupement des
trois décors prend 243 ms (Props 96, Grounded 81, crypte 66), le mécanisme gravé 66 ms, le reste va aux pontons, aux
lanternes et aux bêtes. Le niveau se charge pendant la transition du portail.

Depuis le 8 novembre (agent perf-marais, `docs/chargements-lieux.md`, « Marais : la crypte après l'arrivée ») : les
signatures des matériaux ne sont plus calculées qu'une fois par état (le regroupement du dehors passe d'environ 215 à
115 ms, serveur chargé), la crypte (teinte, regroupement, lettres du mécanisme) se prépare après l'arrivée, 8 ms par image, et les
positions du décor dispersé sont calculées d'avance (`marais/decor`). Le rendu et les collisions sont les mêmes
(empreintes identiques).

## Vérifications

- Captures figées (particules, feux follets, bêtes et scintillement arrêtés) aux mêmes 32 points avant et après :
  - crypte : écart moyen de 0 à 0,11 sur 255, image identique ;
  - mécanisme : seules les lettres changent (police Cinzel au lieu de Lora, déjà dans le travail interrompu) ;
  - dehors : l'eau et la brume au ras de l'eau, dont le shader suit le temps, puis le grain des ombres de la lune
    (deux tranches au lieu de quatre) et l'ombre des petits objets ; aucun objet disparu, déplacé ni éclairé autrement ;
  - vue haute (0, 40, 75) sur tout le marais : 0,14 % de pixels changés, rien ne manque au loin.
- Bêtes en gros plan (grenouille sur son nénuphar, corbeaux des pierres levées et du bosquet, potence) : formes et
  couleurs conservées.
- Collisions : 613 formes avant et après ; le relevé trié est identique, sauf la capsule du joueur, posée 5 cm plus
  bas au moment du relevé.
- Grille de marche (`walkgrid_serveur.gd`, grille de 0,5 m, marche réelle dans 8 directions sur une grille de 4 m
  dehors et 2 m dans la crypte) : dehors 10 753 points, crypte 2 819 points, aucun mur invisible, piège, marche, chute
  ni glissade ; seul le bord de ponton attendu en (6.0, 0.3, -12.5), comme avant. Chaque modèle fondu de plus de
  0,3 m posé là où l'on marche garde sa collision (0 sans collision).
- Tests : `marais_puzzle_test` et `signboard_test` à 0 échec ; `tree_collision_test` : marais, 72 arbres, 0 sans
  collision. Ce test ne voit plus les arbres morts posés à la main, fondus avec le décor : la grille de marche, mode
  maillages, les vérifie pièce par pièce (métadonnée « pieces » des lots).

## Problèmes trouvés dans le travail interrompu (8851bd1) et corrigés

| N° | Problème | Correction |
| --- | --- | --- |
| 1 | `write_marais_tscn.py` sans les réglages de lumière de `marais.tscn` : relancé, il les effaçait (dérive) | Réglages reportés dans le script (761281f) |
| 2 | Lots formés par instance de matériau : chaque modèle Kenney a la sienne, d'où 358 lots de 1 ou 2 pièces | Matériaux comparés par leurs réglages et leur texture, couleurs dans les sommets : 191 lots |
| 3 | Portée de 40 m mesurée du centre d'un lot de 32 m : un petit objet pouvait disparaître à 18 m | Portée allongée du rayon du lot |
| 4 | Flammes des lanternes des pontons effacées à 40 m comme de petits objets | Ce qui luit n'est jamais effacé |
| 5 | Portées des lumières de la crypte raccourcies : murs plus sombres, sans gain mesurable | Rendues à 12 m |
| 6 | Trois tailles d'objets (petits, moyens, grands) : trois fois plus de lots, et les objets moyens effacés à 80 m | Deux classes : petits (effacés à 40 m) et les autres, dessinés comme avant |
| 7 | 130 `TextMesh` générés au chargement pour les lettres du mécanisme | 26 lettres taillées une fois |
| 8 | Un maillage porté par un nœud scripté pouvait être fondu | Ces maillages restent à leur place |
