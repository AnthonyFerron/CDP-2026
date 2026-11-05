# Problèmes trouvés dans le désert de Pythania (passe au centimètre)

| # | Où | Constat (test ou capture) | Cause | Correction |
| --- | --- | --- | --- | --- |
| 1 | Caravane (-38.1, -27.4) | Deux tonneaux qui se chevauchent (vérificateur du builder) | Caps tirés au hasard, trop proches | Tonneaux droits, écartés (83e3fdb) |
| 2 | Cave, coffre ouest | Hauteur de collision d'après l'ancienne boîte | Boîtes MODEL_BOXES corrigées par la Plaine | Collision à la nouvelle hauteur ; rouleaux rangés dans le coffre ouvert |
| 3 | Escalier de la cave | On ne pouvait ni monter ni descendre : bloc plein, sortie seulement en bas | Collision en boîte, plafond trop bas | 9 marches de 30 cm sur une rampe à 41°, cage haute de 5,4 m (linteau, plafond, murs), sortie au milieu de l'escalier, utilisable en bas et en haut (6bf5daa) |
| 4 | Allée, x ±9..10 | Marches de 0,41 à 0,48 m entre deux points voisins | Talus des dunes trop raides au bord du chemin | Replat du chemin prolongé en pente douce jusqu'à 16 m de l'axe |
| 5 | Obélisques | Mur invisible autour des fûts | Une seule boîte de 1,9 m jusqu'en haut | Socle, degré et fût séparés |
| 6 | Panneaux sur poteaux (entrée, Joran, apprenti) | Mur invisible entre les poteaux, sous la planche | La collision du SignBoard couvre tout le dessous | Contournement d'abord (collision coupée, PostsBody à la main), retiré le 5 novembre : `sign_board.gd` (e094f56) donne lui-même les deux poteaux et la planche. Revérifié par `sign_grid_test.gd` (grille de 0,5 m, 8 directions, 1 s de marche) : 0 mur invisible, captures des deux faces |
| 7 | Colonnes (salle, portique, colonnade, cave) | Mur invisible autour des fûts | Boîtes carrées plus larges que les fûts | Socle carré bas et fût cylindrique |
| 8 | Rochers et cactus épars | Mur invisible au-dessus des petits rochers (cylindres de 2,5 m) | Cylindre de hauteur fixe | Enveloppe convexe de chaque modèle, à son échelle |
| 9 | Restes épars (jarres, tonneaux) | Cylindres de 1,6 m au-dessus de jarres de 0,7 m | Hauteur fixe | Hauteur du modèle |
| 10 | Épaves de siège | Boîte pleine autour de planches éparses | Boîte du modèle | Enveloppe convexe |
| 11 | Braseros, roues couchées, côtes de la bête, cairns, chaise, gravats, colonne couchée, tête colossale | Collisions débordant de 0,5 à 2 m | Boîtes alignées | Cylindres, boîtes resserrées au cœur des objets |
| 12 | Angles de la muraille (x ±15) | Mur invisible de 2,5 × 2,5 m dans l'angle | L'angle du kit est un L creux ; la boîte le remplissait | Deux bras de 1 m, mesurés sur une carte des triangles visibles |
| 13 | Coin de l'arche (6, 19) et puits de l'oasis (33, 4) | Joueur coincé (8 directions bloquées) | Brasero et jarres trop près des gravats et de l'abreuvoir | Brasero et jarres déplacés |
| 14 | Avant-cour et dunes | Voiles de sable vus comme des rectangles clairs | Quads de couleur unie | Tache dégradée radiale |
| 15 | Passages nord du monument | Bloc et jarres en travers (vu au parcours à pied) | Placement | Écartés (tour précédent, rappel) |
| 16 | Jarre debout (-43, -9.6), pente d'une dune | Marche de 0,52 m entre son dessus et le sable en contrebas (grille, 5 nov.) | Jarre de 0,44 m posée sur la pente : on y arrive de plain-pied par le haut | Enfoncée de 0,42 m au lieu de 0,25 (à demi enfouie), collision resserrée sur son col (0,46 m) |
| 17 | Jarre debout (-6.5, -55), pente d'une dune | Marche de 0,40 m | Même cause | Enfoncée de 0,32 m au lieu de 0,2, collision de 0,5 m |
| 18 | Épaves de siège (-52, -6) et (-14, -38) | Marches de 0,45 et 0,46 m sur leurs planches. Enfoncer toutes les épaves (essai à 56 % de leur hauteur) en créait d'autres, jusqu'à 0,61 m, et 2 points coincés | Planches hautes au-dessus du sable, d'autres de plain-pied | Sonde par épave (`wreck_probe.gd`, 8 décalages) : avec les congères ci-dessous, décalage propre à chaque épave (`WRECK_LIFT` : +0,25 m pour la baliste (-46, 14), -0,12 m pour le trébuchet (-52, -6)) |
| 20 | Congères des 6 épaves | Tas de sable visible jusqu'à 1,1 m de haut (baliste), sans collision : le joueur le traversait (lu dans `_add_wrecks`, vu en capture) | Ellipsoïde décoratif | Congère basse (0,55 m au plus, pente de 42° au plus au pied) avec sa collision convexe, prise sur le même ellipsoïde |
| 19 | Panneaux sur poteaux (entrée, Joran, apprenti) | Contournement (PostsBody à la main) devenu inutile | `sign_board.gd` corrigé (e094f56) | Retiré, revérifié (voir n° 6) |

## Restants signalés

- Grille de marche : 422 points de contact où un collisionneur dépasse le modèle visible de 0,5 à 1 m (rochers, gravats, faces creusées des murs du kit, piles de pierres). Tous ont un triangle visible à moins de 1 m ; je les juge acceptables, mais ils restent comptés par le test.
- 3 contacts sur le mur est de la salle (12, 1.3, 3) sans triangle visible à moins de 1 m : à revoir (un creux du modèle étiré, ou l'arrondi de la congère voisine).
- Le test de grille doit tourner avec une fenêtre et l'argument « sans_regroupement » : en mode sans affichage, Godot ne garde pas les positions des MultiMesh, et le regroupement des maillages fixes empêche le test triangle par triangle de voir certains modèles.
