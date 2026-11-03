# Niveau 2 — Le Désert

Ouvrir `desert.tscn` dans le projet `frontend/project.godot`, puis appuyer sur **F6** pour jouer cette scène. En version de debug, **F1** ouvre aussi le menu des niveaux.

La conception vient de l'ébauche du niveau 2 : une arche en grès devant un sanctuaire, une trappe en bois qui mène à une cave, trois tablettes à éveiller dans l'ordre Initialiser, Transformer, Transmettre, et un coffre qui garde le livre. Cette version la reprend avec les outils communs aux autres niveaux : joueur en première personne, HUD, interactions, portail, modèles Kenney et sons générés.

## Parcours

1. Le joueur arrive devant le portail éteint, au sud, et suit le chemin jusqu'à l'arche.
2. Des runes sont posées à la surface et dans la cave. D'autres sont enfouies sous des tas de sable : maintenir E devant un tas le dégage peu à peu, et la progression reste acquise si on relâche. Certains tas sont vides.
3. La trappe au centre de l'esplanade mène à la cave des archives. Le mur ouest montre les deux algorithmes incomplets : remplir la jarre sacrée et garder l'entrée du temple.
4. La table ronde ouvre l'écran des runes. « Valider » reste grisé tant que les six emplacements ne sont pas remplis. Une mauvaise réponse coûte 5 minutes au chronomètre du volcan.
5. Solution : TANT QUE, Puiser, Porter pour la jarre ; SI, Ouvrir, SINON pour la porte. Les runes « POUR » et « Fermer » sont des leurres.
6. Le sable s'écarte devant la table, un coffre enfoui apparaît et l'Algonicon en sort. Le prendre rallume le portail.

Les sables mouvants ralentissent le joueur, puis le ramènent à son dernier point sûr.

## Fichiers

| Fichier | Rôle |
| --- | --- |
| `desert.tscn`, `desert.gd` | Scène du niveau et sa logique |
| `desert_terrain.gd` | Dunes, esplanade, chemin et sables mouvants |
| `desert_scatter.gd` | Cactus, rochers, ruines, épaves et sables mouvants |
| `desert_ruins.tscn`, `desert_cellar.tscn` | Arche, sanctuaire et cave, générés par `tools/build_desert.py` |
| `rune.gd`, `sand_pile.gd` | Rune à ramasser, tas de sable à dégager en maintenant E |
| `rune_puzzle.tscn`, `rune_puzzle.gd` | Écran de la table ronde et vérification des algorithmes |
| `desert_sand.gdshader`, `quicksand.gdshader` | Sable et sables mouvants |

Le raccord au hub se fait par la propriété `hub_scene` de la scène, une fois le hub disponible.
