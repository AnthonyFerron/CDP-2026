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

## Musiques

Les musiques sont dans `frontend/assets/audio/music/`, en OGG Vorbis réencodé en qualité 4 (`oggdec`, puis `oggenc -q 4`), à leur fréquence d'échantillonnage et avec leurs canaux d'origine. Leurs auteurs et leurs licences sont dans `LICENCES.md`. Elles bouclent à l'import (`loop=true` dans leur `.import`), sauf `defaite.ogg`.

| Fichier | Où elle joue |
| --- | --- |
| `menu.ogg` | Menu principal |
| `intro.ogg` | Bunker en début de partie, jusqu'à la première sortie, une fois la mission confiée |
| `hub.ogg` | Hub, dehors comme au bunker, une fois sorti |
| `plaine.ogg`, `desert.ogg`, `marais.ogg`, `village.ogg` | Chaque lieu |
| `victoire.ogg` | Rituel et bonne fin, puis en boucle pendant l'épilogue au hub |
| `defaite.ogg` | Éruption, une seule fois, sans autre musique jusqu'au retour au menu |

Un seul lecteur les joue, l'autoload `Music` (`frontend/scripts/music.gd`), sur le bus « Music » qu'il crée, sous l'ambiance et les effets. Il passe d'une piste à l'autre par un fondu enchaîné de 1,5 s et ne relance pas la piste en cours. Le menu et les lieux ont leur piste dans `music.gd`. Le hub choisit la sienne (`Hub._music()` et les fins).

Sur le web :

- la musique attend le premier clic ou la première touche du joueur, car le navigateur bloque le son avant ;
- elle passe par le mélangeur de Godot (`PLAYBACK_TYPE_STREAM`), et non par le mode « sample » du web, qui décoderait chaque piste en entier en mémoire ;
- l'export web a des fils d'exécution : le mélangeur tourne sur son propre fil, et une image lente ne coupe plus la musique (`docs/web-threads.md`) ;
- `audio/driver/output_latency.web` vaut 200 ms. Cette réserve sert surtout à l'export sans fils, utilisé en repli et sur GitHub Pages ;
- la piste du lieu de destination se charge en arrière-plan sous le titre de la transition (`Music.prefetch`) ;
- seules `menu.ogg`, `intro.ogg` et `hub.ogg` sont dans le paquet du jeu (`index.pck`). Les autres sont dans un second paquet, `musique.pck`, que le jeu télécharge une fois le menu affiché. Une piste demandée avant son arrivée part dès qu'il est là (`docs/musique-differee.md`).

Pour ajouter une piste :

1. Pose le fichier dans `frontend/assets/audio/music/`.
2. Ajoute son gain dans `Music.TRACKS`.
3. Appelle `Music.play(&"<nom>")`.

4. Range-la dans un paquet web (`frontend/export_presets.cfg`) :
   - dans le filtre d'inclusion du préréglage « Web » si elle doit jouer dès le menu ou dès « Nouvelle partie » ;
   - sinon, dans la liste de fichiers du préréglage « Web musique » (le second paquet, téléchargé après le menu).

Le préréglage « Windows Desktop » garde le motif `assets/audio/music/*.ogg` : toutes les pistes y sont, dans l'exécutable. `frontend/tests/scenes/music_test.gd` vérifie la piste de chaque scène, et l'attente d'une piste du second paquet.
