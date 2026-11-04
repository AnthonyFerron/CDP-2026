# Problèmes trouvés dans le désert de Pythania (passe au centimètre)

| # | Où | Constat (test ou capture) | Cause | Correction |
| --- | --- | --- | --- | --- |
| 1 | Caravane (-38.1, -27.4) | Deux tonneaux qui se chevauchent (vérificateur du builder) | Caps tirés au hasard, trop proches | Tonneaux droits, écartés (83e3fdb) |
| 2 | Cave, coffre ouest | Hauteur de collision d'après l'ancienne boîte | Boîtes MODEL_BOXES corrigées par la Plaine | Collision à la nouvelle hauteur ; rouleaux rangés dans le coffre ouvert |
| 3 | Escalier de la cave | On ne pouvait ni monter ni descendre : bloc plein, sortie seulement en bas | Collision en boîte, plafond trop bas | 9 marches de 30 cm sur une rampe à 41°, cage haute de 5,4 m (linteau, plafond, murs), sortie au milieu de l'escalier, utilisable en bas et en haut (6bf5daa) |
| 4 | Allée, x ±9..10 | Marches de 0,41 à 0,48 m entre deux points voisins | Talus des dunes trop raides au bord du chemin | Replat du chemin prolongé en pente douce jusqu'à 16 m de l'axe |
| 5 | Obélisques | Mur invisible autour des fûts | Une seule boîte de 1,9 m jusqu'en haut | Socle, degré et fût séparés |
| 6 | Panneaux sur poteaux (entrée, Joran, apprenti) | Mur invisible entre les poteaux, sous la planche | La collision du SignBoard couvre tout le dessous | Collision du SignBoard coupée, deux poteaux et la planche à la place |
| 7 | Colonnes (salle, portique, colonnade, cave) | Mur invisible autour des fûts | Boîtes carrées plus larges que les fûts | Socle carré bas et fût cylindrique |
| 8 | Rochers et cactus épars | Mur invisible au-dessus des petits rochers (cylindres de 2,5 m) | Cylindre de hauteur fixe | Enveloppe convexe de chaque modèle, à son échelle |
| 9 | Restes épars (jarres, tonneaux) | Cylindres de 1,6 m au-dessus de jarres de 0,7 m | Hauteur fixe | Hauteur du modèle |
| 10 | Épaves de siège | Boîte pleine autour de planches éparses | Boîte du modèle | Enveloppe convexe |
| 11 | Braseros, roues couchées, côtes de la bête, cairns, chaise, gravats, colonne couchée, tête colossale | Collisions débordant de 0,5 à 2 m | Boîtes alignées | Cylindres, boîtes resserrées au cœur des objets |
| 12 | Angles de la muraille (x ±15) | Mur invisible de 2,5 × 2,5 m dans l'angle | L'angle du kit est un L creux ; la boîte le remplissait | Deux bras de 1 m, mesurés sur une carte des triangles visibles |
| 13 | Coin de l'arche (6, 19) et puits de l'oasis (33, 4) | Joueur coincé (8 directions bloquées) | Brasero et jarres trop près des gravats et de l'abreuvoir | Brasero et jarres déplacés |
| 14 | Avant-cour et dunes | Voiles de sable vus comme des rectangles clairs | Quads de couleur unie | Tache dégradée radiale |
| 15 | Passages nord du monument | Bloc et jarres en travers (vu au parcours à pied) | Placement | Écartés (tour précédent, rappel) |

## Restants signalés

- Grille de marche : 422 points de contact où un collisionneur dépasse le modèle visible de 0,5 à 1 m (rochers, gravats, faces creusées des murs du kit, piles de pierres). Tous ont un triangle visible à moins de 1 m ; je les juge acceptables, mais ils restent comptés par le test.
- 3 contacts sur le mur est de la salle (12, 1.3, 3) sans triangle visible à moins de 1 m : à revoir (un creux du modèle étiré, ou l'arrondi de la congère voisine).
- 2 « marches » de 0,4 à 0,52 m sur le dessus de jarres épaves (-44, -9) et (-6, -56) : on peut y monter en sautant, ce n'est pas un trou.
- Le test de grille doit tourner avec une fenêtre et l'argument « sans_regroupement » : en mode sans affichage, Godot ne garde pas les positions des MultiMesh, et le regroupement des maillages fixes empêche le test triangle par triangle de voir certains modèles.
