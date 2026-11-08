# Niveau 2 — Le désert de Pythania

Ouvrir `desert.tscn` dans le projet `frontend/project.godot`, puis appuyer sur **F6** pour jouer cette scène. En version de debug, **F1** ouvre aussi le menu des niveaux.

Énigme « Les algorithmes oubliés » : jadis traversé par les voyageurs et les marchands, le désert n'est plus que sable balayé de vents brûlants, quelques cactus, des ossements de bêtes et des crânes de vautours. Au centre se dressent les vestiges du monument des anciens bâtisseurs ; dans sa salle des colonnes, une trappe de pierre à demi recouverte de sable mène à la cave des archives, où deux algorithmes incomplets sont gravés dans la roche. Les runes qui les complètent sont dispersées dans les salles du monument, parmi les débris au-dehors et sous des tas de sable.

## Parcours

1. Le joueur arrive devant le portail éteint, au sud, et remonte l'allée des obélisques jusqu'à l'arche de la muraille.
2. Des runes sont posées dans les salles du monument (la chambre du couchant à l'ouest), parmi les débris de l'avant-cour et dans la cave. D'autres sont enfouies sous des tas de sable : maintenir E devant un tas le dégage peu à peu, et la progression reste acquise si on relâche. Certains tas sont vides (avant-cour, chambre du levant, cave).
3. La trappe de pierre, au centre de la salle des colonnes, mène par un escalier à la cave des archives, sombre et poussiéreuse. Les murs ouest et est portent chacun un algorithme gravé : remplir la jarre sacrée et garder l'entrée du temple. L'inscription est sur une plaque de la porte scellée, au fond. Deux runes sont posées sur les tables de part et d'autre de l'escalier, deux autres sont sous des tas de sable.
4. La table ronde de pierre ouvre l'écran des runes, dans le style des menus : les deux algorithmes se font face, leurs lignes manquantes sont des cases de pierre gravées, et les runes en main des tuiles marquées chacune de son symbole (boucle, seau, jarre, question, embranchement, porte, cadenas, grains). On choisit une tuile, puis la case où la graver. « Valider » reste grisé tant que les six cases ne sont pas remplies.
5. Erreur : les runes et les six emplacements de la table rougissent, une violente secousse ébranle la cave et le panneau, et le chronomètre du volcan perd 5 minutes.
6. Solution : TANT QUE, Puiser, Porter pour la jarre ; SI, Ouvrir, SINON pour la porte. Les runes « POUR » et « Fermer » sont des leurres.
7. Réussite : les emplacements s'embrasent d'une intense lumière bleutée, un grondement mécanique monte, et dans le coin nord-est de la cave le tas de sable se disperse seul : le coffre de pierre apparaît, son couvercle se soulève et l'Algonicon en sort. Le prendre rallume le portail.

Les sables mouvants ralentissent le joueur, puis le ramènent à son dernier point sûr. Une limite invisible, au pied des crêtes (`DesertTerrain.LIMIT_RADIUS`), empêche de sortir de la zone, même en sautant d'un rocher.

## Décor

| Lieu | Ce qu'on y trouve |
| --- | --- |
| Allée des obélisques | Six obélisques couverts de symboles en relief, coiffés d'or, l'un brisé ; le panneau d'entrée et un crâne de vautour sur un pieu |
| Muraille et arche | Bannières, braseros éteints, sable amassé contre les pans de mur |
| Salle des colonnes | Dallage, colonnes, statue et autel des offrandes, braseros, la trappe de pierre et son cadre, des jarres, des brèches comblées de gravats |
| Chambres du couchant (ouest) et du levant (est) | Une stèle gravée dans chacune (socle, cadre, soleil et nom sur ses deux faces, fronton), jarres, tablettes brisées, une colonne tombée |
| Sanctuaire englouti | Façade à demi enfouie sous une dune, portique dont l'architrave de l'est a basculé |
| Caravane | Tentes, étals de marchandises, feu éteint, charrette renversée, le squelette du caravanier près de son carnet, celui de sa bête |
| Oasis asséchée | Bassin de boue craquelée, roseaux secs, palmiers dont un couché, puits et abreuvoir, la jarre sacrée sur son socle ; de loin, le mirage d'une nappe d'eau qui scintille au fond du bassin et s'efface quand on approche |
| Citerne | Fosse aux pans de muraille épais et piliers d'angle à chapiteau, colonnes de l'ancienne voûte, poutre tombée cerclée de bronze, jarres et squelette au fond |
| Crêtes | La caravane fantôme : les silhouettes tremblantes de marchands d'autrefois et de leurs chameaux, montés ou chargés de ballots, qui marchent sans fin sur les crêtes autour du désert et se dissolvent dès qu'on s'en approche |
| Dunes | Trois tourbillons de sable qui errent loin du chemin, en sifflant ; tête colossale à demi enfouie, poste de garde tombé au combat, colonnade engloutie, porte des vents, tombes des caravaniers, cage thoracique géante d'une bête des sables sous laquelle on passe, armes et ossements épars, crânes de vautours |
| Cave des archives | Table ronde de pierre à six emplacements, étagère de tablettes d'argile, casiers à rouleaux, coffres, pupitre de lecture, urnes, poutres, poussière en suspension |

## Récit du lieu

Outre les stèles, le carnet du caravanier, l'inscription et les algorithmes, cinq textes se lisent avec E : la plaque du monument (mur sud de la salle des colonnes), le journal d'Elias, marchand qui a fui Vibelandia (posé sur l'abreuvoir de l'oasis), la lettre de Joran (sous la planche des tombes des caravaniers), la tablette d'un apprenti bâtisseur (chambre du levant) et le rouleau de l'archiviste (pupitre de la cave). Ils aident à comprendre les boucles, les conditions et les leurres sans donner la solution.

## Performances

Au chargement, `desert.gd` regroupe les maillages fixes des ruines par matériau et par case de 32 m (`_merge_static`) : environ 430 appels de dessin en moyenne sur le parcours de mesure au lieu de 1 030. Les petits objets n'ont pas d'ombre et s'effacent au-delà de 70 m ; le soleil projette ses ombres sur 55 m en deux cascades.

## Ambiance et vie

Lumière chaude et dure ; la lumière ambiante est surtout chaude (le ciel n'en donne que 30 %), les ombres restent brunes au lieu de virer au vert-gris ; horizon voilé de chaleur et brume au ras des dunes ; des voiles de sable passent autour du joueur. Le vent siffle dans les ruines (sources sonores posées sur le sanctuaire, l'arche, la porte des vents, la colonnade, la bête des sables et la tête colossale). Dans la cave, la poussière flotte et tombe en filets du plafond. Les vents brûlants se voient : trois tourbillons de sable (`desert_whirlwinds.gd`, `whirlwind.gdshader`) errent dans les dunes, à l'est de l'allée, à l'ouest près de la citerne et au sud derrière le sanctuaire, chacun avec son entonnoir de sable qui tourne, ses grains à son pied et son sifflement ; ils n'ont pas de collision. La chaleur fait naître des mirages (`desert_mirages.gd`) : une nappe d'eau au fond de l'oasis asséchée (`mirage_pool.gdshader`), entière au-delà de 30 m et effacée à 14 m, et la caravane fantôme des crêtes (`mirage_caravan.gdshader`), qui fait le tour du désert en sept minutes, à 77 m du centre, et disparaît à moins de 30 m. Des vautours tournent haut au-dessus des ossements, des lézards et des scorpions filent entre les pierres et fuient le joueur, et les toiles claquent au vent : fanions de la caravane et du poste de garde, chiffons des pieux, bannières du sanctuaire (`desert_life.gd`, `desert_cloth.gdshader`).

Les textes du monde sont écrits sur des `SignBoard` (panneau d'entrée, plaque de l'inscription) ou gravés à fleur de pierre (noms des stèles, algorithmes) : aucun texte ne flotte. Les panneaux sur poteaux sont lisibles des deux côtés et les stèles n'ont pas de dos nu.

Les collisions suivent les modèles au plus près : boîtes, cylindres et enveloppes taillés à la main dans `tools/build_desert.py`, et pour les formes ouvertes (étals sous leur auvent, charrette renversée, bannières sur pied, épaves de siège) leurs propres triangles (`EXACT_MODELS` dans `desert.gd`, `_add_wrecks` dans `desert_scatter.gd`). La congère amassée contre chaque épave se gravit à pied, avec sa collision ; la hauteur de chaque épave (`WRECK_LIFT`) est réglée pour qu'aucune planche ne fasse une marche de plus de 0,4 m.

## Fichiers

| Fichier | Rôle |
| --- | --- |
| `desert.tscn`, `desert.gd` | Scène du niveau et sa logique |
| `desert_terrain.gd` | Dunes, esplanade, chemin, replats du décor (`SITES`), bassin de l'oasis, fosse de la citerne, sables mouvants et limite invisible |
| `desert_scatter.gd` | Cactus, rochers, ruines, épaves de siège ensablées, restes épars, ossements et crânes de vautours, sables mouvants ; les détails sont découpés en cases de 32 m pour s'effacer au loin case par case |
| `desert_life.gd`, `desert_cloth.gdshader` | Vautours, lézards et scorpions, toiles qui claquent au vent |
| `desert_mirages.gd`, `mirage_pool.gdshader`, `mirage_caravan.gdshader` | Mirages : la nappe d'eau de l'oasis et la caravane fantôme des crêtes |
| `desert_whirlwinds.gd`, `whirlwind.gdshader` | Tourbillons de sable qui errent dans les dunes |
| `desert_ruins.tscn`, `desert_cellar.tscn` | Surface et cave, générées par `tools/build_desert.py` |
| `rune.gd`, `sand_pile.gd` | Rune à ramasser, tas de sable à dégager en maintenant E |
| `rune_puzzle.tscn`, `rune_puzzle.gd` | Écran de la table ronde et vérification des algorithmes |
| `desert_sand.gdshader`, `quicksand.gdshader` | Sable (terrain et congères) et sables mouvants |

`tools/build_desert.py` pose tout à la hauteur 0, sur l'esplanade, le chemin et les replats que `desert_terrain.gd` aplanit : ses `REPLATS` doivent rester identiques aux `SITES` du terrain. Les formes simples (obélisques, ossements, congères, étagères…) y sont regroupées en MultiMesh dès qu'elles se répètent, et ne sont pas teintées en grès par `desert.gd`.
