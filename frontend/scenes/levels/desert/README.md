# Niveau 2 — Le Désert

Ouvrir `desert.tscn` dans le projet `frontend/project.godot`, puis appuyer sur **F6** pour jouer cette scène. En version de debug, **F1** ouvre aussi le menu des niveaux.

La conception vient de l'ébauche du niveau 2 : une arche en grès devant un sanctuaire, une trappe en bois qui mène à une cave, trois tablettes à éveiller dans l'ordre Initialiser, Transformer, Transmettre, et un coffre qui garde le livre. Cette version la reprend avec les outils communs aux autres niveaux : joueur en première personne, HUD, interactions, portail, modèles Kenney et sons générés.

## Parcours

1. Le joueur arrive devant le portail éteint, au sud, et suit le chemin jusqu'à l'arche.
2. Sur l'esplanade du sanctuaire, trois stèles décrivent chacune une fonction, sans dire leur ordre.
3. La trappe au centre mène à la cave des archives. L'inscription du fond rappelle la règle : « Du premier souffle au dernier mot ».
4. Les tablettes ne sont pas rangées dans l'ordre. Une erreur les éteint toutes.
5. Une fois les trois éveillées, le livre sort du coffre. Le prendre rallume le portail.

Les sables mouvants ralentissent le joueur, puis le ramènent à son dernier point sûr.

## Fichiers

| Fichier | Rôle |
| --- | --- |
| `desert.tscn`, `desert.gd` | Scène du niveau et sa logique |
| `desert_terrain.gd` | Dunes, esplanade, chemin et sables mouvants |
| `desert_scatter.gd` | Cactus, rochers, ruines, épaves et sables mouvants |
| `desert_ruins.tscn`, `desert_cellar.tscn` | Arche, sanctuaire et cave, générés par `tools/build_desert.py` |
| `desert_sand.gdshader`, `quicksand.gdshader` | Sable et sables mouvants |

Le raccord au hub se fait par la propriété `hub_scene` de la scène, une fois le hub disponible.
