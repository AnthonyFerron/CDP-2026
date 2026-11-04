# Niveau 2 — Le désert de Pythania

Ouvrir `desert.tscn` dans le projet `frontend/project.godot`, puis appuyer sur **F6** pour jouer cette scène. En version de debug, **F1** ouvre aussi le menu des niveaux.

Énigme « Les algorithmes oubliés » : jadis traversé par les voyageurs et les marchands, le désert n'est plus que sable balayé de vents brûlants, quelques cactus, des ossements de bêtes et des crânes de vautours. Au centre se dressent les vestiges du monument des anciens bâtisseurs ; dans sa salle des colonnes, une trappe de pierre à demi recouverte de sable mène à la cave des archives, où deux algorithmes incomplets sont gravés dans la roche. Les runes qui les complètent sont dispersées dans les salles du monument, parmi les débris au-dehors et sous des tas de sable.

## Parcours

1. Le joueur arrive devant le portail éteint, au sud, et remonte l'allée des obélisques jusqu'à l'arche de la muraille.
2. Des runes sont posées dans les salles du monument (la chambre du levant à l'ouest), parmi les débris de l'avant-cour et dans la cave. D'autres sont enfouies sous des tas de sable : maintenir E devant un tas le dégage peu à peu, et la progression reste acquise si on relâche. Certains tas sont vides (avant-cour, chambre du zénith, cave).
3. La trappe de pierre, au centre de la salle des colonnes, mène par un escalier à la cave des archives, sombre et poussiéreuse. Les murs ouest et est portent chacun un algorithme gravé : remplir la jarre sacrée et garder l'entrée du temple. L'inscription est sur une plaque de la porte scellée, au fond. Deux runes sont posées sur les tables de part et d'autre de l'escalier, deux autres sont sous des tas de sable.
4. La table ronde de pierre ouvre l'écran des runes. « Valider » reste grisé tant que les six emplacements ne sont pas remplis.
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
| Chambres du levant et du zénith | Une stèle gravée dans chacune, jarres, tablettes brisées, une colonne tombée |
| Sanctuaire englouti | Façade à demi enfouie sous une dune, portique dont l'architrave de l'est a basculé |
| Caravane | Tentes, étals de marchandises, feu éteint, charrette renversée, le squelette du caravanier près de son carnet, celui de sa bête |
| Oasis asséchée | Bassin de boue craquelée, roseaux secs, palmiers dont un couché, puits et abreuvoir, la jarre sacrée sur son socle |
| Citerne | Fosse aux murs épais, colonnes de l'ancienne voûte, poutre tombée, jarres et squelette au fond |
| Dunes | Tête colossale à demi enfouie, poste de garde tombé au combat, colonnade engloutie, porte des vents, tombes des caravaniers, cage thoracique géante d'une bête des sables sous laquelle on passe, armes et ossements épars, crânes de vautours |
| Cave des archives | Table ronde de pierre à six emplacements, étagère de tablettes d'argile, casiers à rouleaux, coffres, pupitre de lecture, urnes, poutres, poussière en suspension |

Les textes du monde sont écrits sur des `SignBoard` (panneau d'entrée, plaque de l'inscription) ou gravés à fleur de pierre (noms des stèles, algorithmes) : aucun texte ne flotte.

## Fichiers

| Fichier | Rôle |
| --- | --- |
| `desert.tscn`, `desert.gd` | Scène du niveau et sa logique |
| `desert_terrain.gd` | Dunes, esplanade, chemin, replats du décor (`SITES`), bassin de l'oasis, fosse de la citerne, sables mouvants et limite invisible |
| `desert_scatter.gd` | Cactus, rochers, ruines, épaves, restes épars, ossements et crânes de vautours, sables mouvants |
| `desert_ruins.tscn`, `desert_cellar.tscn` | Surface et cave, générées par `tools/build_desert.py` |
| `rune.gd`, `sand_pile.gd` | Rune à ramasser, tas de sable à dégager en maintenant E |
| `rune_puzzle.tscn`, `rune_puzzle.gd` | Écran de la table ronde et vérification des algorithmes |
| `desert_sand.gdshader`, `quicksand.gdshader` | Sable (terrain et congères) et sables mouvants |

`tools/build_desert.py` pose tout à la hauteur 0, sur l'esplanade, le chemin et les replats que `desert_terrain.gd` aplanit : ses `REPLATS` doivent rester identiques aux `SITES` du terrain. Les formes simples (obélisques, ossements, congères, étagères…) y sont regroupées en MultiMesh dès qu'elles se répètent, et ne sont pas teintées en grès par `desert.gd`.
