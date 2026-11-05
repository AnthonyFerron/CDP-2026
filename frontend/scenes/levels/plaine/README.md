# Les plaines d'Hexcole — énigme « Les fragments du passé »

Ouvrir `plaine.tscn` dans le projet `frontend/project.godot`, puis appuyer sur **F6** pour jouer cette scène. En version de debug, **F1** ouvre aussi le menu des niveaux.

Jadis des prairies, les plaines ne sont plus qu'un champ de bataille de la guerre contre Vibelandia : herbe brûlée, cratères de lave et trous d'obus, arbres morts. Au centre, les ruines de l'ancienne bibliothèque d'Hexcole ; ses archives, sous la carte, cachent le Projenomicon.

## Parcours

1. Le joueur arrive devant le portail, au sud. Le panneau « Les plaines d'Hexcole » et l'affiche de la fête des foins de 5804, du temps des prairies, l'accueillent. Le chemin mène tout droit à la bibliothèque et franchit sur un pont de pierre la coulée de lave qui relie deux cratères ; à la tête du pont, le relevé de l'arpenteur royal (5811) raconte les cratères et met en garde contre la lave.
2. Autour du chemin, le décor raconte le siège : le camp des défenseurs (journal du soldat sur le coffre, ordre d'évacuation affiché), leurs tombes et leur stèle, la tour de guet effondrée, les engins de siège brisés de Vibelandia, une batterie de balistes derrière la bibliothèque, des charrettes de livres abandonnées, la barricade devant la façade, le bélier qui a enfoncé la porte. La stèle de la bibliothèque, devant l'obélisque, porte sa devise. Sur le mur ouest de la façade, la proclamation du roi Codeon V (5812) envoie les habitants au bunker ; on y a ajouté que la bibliothécaire est restée pour sceller ses archives.
3. La porte mène aux archives : salle de lecture, scriptorium, salle des archives. Des rayonnages sont renversés, des livres et des documents jonchent le sol. Sur la table de lecture, la lettre de la bibliothécaire explique la tablette et la conversation découpée ; au mur de la salle, le règlement de la bibliothèque (livres à signet, chantiers menés pas à pas) ; sur un pupitre du scriptorium, les notes du greffier rappellent que chacun parle à son tour.
4. Six fragments de la conversation entre la bibliothécaire et son employé sont cachés dans douze livres à fouiller (`searchable_book.gd`) : chacun dépasse de sa rangée, avec des nervures dorées qui luisent quand on le regarde et un signet qui pend ; lu, il rentre dans le rang.
5. Au fond des archives, l'imposante dalle de pierre ferme le passage. À côté, l'inscription gravée et la tablette à six emplacements. « Valider » reste grisé tant que les six ne sont pas remplis.
6. Mauvais ordre : les inscriptions virent au rouge, le sol tremble et le chronomètre perd 5 minutes. Bon ordre : elles passent au vert, un grondement, la dalle glisse ; un escalier oublié descend vers une petite salle où le Projenomicon repose sur un pupitre de pierre, dans sa lueur. Le prendre rallume le portail.

Solution : la bibliothécaire ouvre la discussion (organiser la restauration), puis objectifs, inventaire, planning, suivi, vérification et clôture.

Des feux couvent encore sur le trébuchet, la charrette de livres de la barricade et le camp ; une fumée monte des ruines, le vent siffle dans la tour et la brèche. Dans les archives, la lumière du ciel baisse, la poussière flotte et les bougies crépitent.

La lave des cratères et de la coulée renvoie le joueur à son dernier point sûr. Un mur invisible au pied des remparts (`LIMIT_RADIUS`, dans `plaine_terrain.gd`) empêche de sortir de la carte.

## Fichiers

| Fichier | Rôle |
| --- | --- |
| `plaine.tscn`, `plaine.gd` | Scène du niveau (éditée directement) et sa logique : déplacements dehors et dedans, fouille des livres, tablette, dalle, livre |
| `plaine_terrain.gd` | Relief, cratères de lave, trous d'obus, lit de la coulée, replats du champ de bataille (`SITES`), limite de la carte |
| `plaine_scatter.gd` | Herbe, rochers, arbres morts, lanternes du chemin, lave des cratères et de la coulée, fumées |
| `plaine_ruins.tscn`, `plaine_battlefield.tscn`, `library_interior.tscn` | Ruines, champ de bataille et archives, générés par `tools/build_plaine.py` |
| `model_multimesh.gd` | Répète un modèle (livres des rayonnages, feuillets) en un seul MultiMesh |
| `searchable_book.gd` | Livre à fouiller, et sa mise en valeur |
| `tablet_puzzle.tscn`, `tablet_puzzle.gd` | Écran de la tablette, dans le style des menus (`Ornate`) : cases de pierre gravées, fragments de parchemin, rouge à l'erreur, vert à la réussite ; vérification de l'ordre |
| `plaine_life.gd` | Corbeaux qui tournent au-dessus des engins de siège ou guettent sur la tour, les croix et la stèle (ils s'envolent à l'approche), bannières qui ondulent |
| `lava.gdshader`, `plaine_ground.gdshader`, `soot.gdshader`, `library_floor.gdshader` | Lave, sol brûlé, suie, dallage des archives |

Pour changer le décor fixe, modifier `tools/build_plaine.py` puis le relancer depuis `frontend` : `python tools/build_plaine.py`. Il imprime la place des livres à fouiller, à reporter dans `plaine.tscn` (nœuds `Interior/Books`). Les replats du champ de bataille sont décrits deux fois, dans `SITES` du script et de `plaine_terrain.gd`, et doivent rester identiques.
