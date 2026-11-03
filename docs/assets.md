# Assets

Les modèles 3D viennent des kits de [Kenney](https://kenney.nl/assets), tous sous licence CC0.

- `frontend/assets/models/kenney/<kit>/` contient les modèles, au format GLB ou glTF, et la licence du kit.
- `docs/assets/kenney/<kit>/` contient les aperçus, pour choisir un modèle sans ouvrir Godot.

Un kit sert à plusieurs zones : il n'existe qu'en un seul exemplaire, et une zone utilise directement les modèles de `frontend/assets/models/kenney/`.

## Kits par zone

| Kit | Version | Modèles | HUB | Plaine | Désert | Marais | Village |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `3d_road_tiles` | | 302 | X | X | | X | X |
| `castle_kit` | 2.0 | 76 | X | | X | | X |
| `fantasy_town_kit` | 2.0 | 167 | | X | | | X |
| `food_kit` | 2.0 | 200 | | | | | X |
| `furniture_kit` | 2.0 | 140 | | X | X | | X |
| `graveyard_kit` | 5.0 | 91 | | | | X | |
| `mini_arena` | 1.1 | 22 | | | X | | |
| `mini_dungeon` | 2.0 | 30 | X | | X | X | |
| `mini_forest` | 1.0 | 22 | X | X | | X | X |
| `modular_dungeon_kit` | 2.1 | 39 | | | X | X | X |
| `nature_kit` | 2.1 | 329 | X | X | X | X | X |
| `survival_kit` | 2.0 | 80 | X | X | X | X | X |

## Textures

Le dossier `Textures/` d'un kit garde sa majuscule et sa place à côté des modèles : les fichiers GLB pointent vers `Textures/colormap.png` par chemin relatif. Le renommer ou le déplacer ferait perdre leurs couleurs aux modèles.

Les fichiers `variation-*.png` sont les variantes de couleur fournies par certains kits.

Les noms des modèles restent ceux de Kenney, pour les retrouver facilement dans les aperçus et les kits d'origine.
