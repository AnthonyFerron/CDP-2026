# Sons du jeu

Tous les bruitages du jeu sont **synthétisés** par `frontend/tools/generate_sounds.py`, en Python seul, sans aucun enregistrement ni son téléchargé. Seules les musiques viennent de l'extérieur (`LICENCES.md`).

Pour changer un son, modifier sa fonction dans le script, puis le relancer depuis `frontend` :

```
python3 tools/generate_sounds.py
```

- Le script est déterministe : chaque son a sa graine. Relancé sans changement, il réécrit les mêmes fichiers, octet pour octet.
- Les fichiers sont des WAV mono 16 bits à 22 050 Hz. Godot les importe en Quite OK Audio (`compress/mode=2`), environ 8,9 Ko par seconde dans le paquet du jeu.
- Une ambiance en boucle porte un bloc `smpl` : Godot l'importe en boucle (`edit/loop_mode=0`, détection depuis le fichier). Sa fin est fondue dans son début (`seamless`), et les événements courts (bulles, oiseaux) qui dépassent la fin reprennent au début (`add_event`). La boucle ne claque pas.

## Sons ajoutés en novembre

| Fichier | Durée | Où il joue |
| --- | --- | --- |
| `ui_click.wav` | 0,09 s | Clic d'un bouton actif, partout : menu d'accueil, pause, indices, panneaux d'énigme. Un petit coup sec sur du bois |
| `ui_open.wav` | 1,0 s | Ouverture d'un panneau : énigme, carnet, texte lu, indices, pause. Un parchemin qui se déroule, puis une clochette en sol (1 568 Hz), dans l'accord des tablettes (do, mi, sol de `tablet_chime_*`) |
| `ui_close.wav` | 0,45 s | Fermeture d'un panneau. Le parchemin replié, puis un coup de bois sourd, comme un coffret qu'on referme |
| `footstep_wood_1..3.wav` | 0,24 s | Pas sur un plancher, un pont, un ponton ou une estrade de bois. Le talon frappe une planche qui sonne creux, puis la semelle frotte |
| `footstep_stone_1..3.wav` | 0,23 s | Pas sur la pierre : château, crypte, cave, dallages, pavés. Un claquement net, quelques grains qui crissent, un écho très court. Plus sec que le pas feutré sur la cendre (`footstep_ash_*`) |
| `river.wav` | boucle de 6 s | Rivière du hub. Un courant sourd, des remous et un léger chuintement : plus grave et plus plein que le ruisseau (`stream.wav`) |
| `park_leaves.wav` | boucle de 8 s | Feuillage du jardin du roi, au hub. Des feuilles froissées par vagues de brise |
| `bird_1..3.wav` | 0,7 à 0,9 s | Oiseaux du jardin du roi, une fois le jardin reconstruit : une phrase de rouge-gorge, l'appel « ti-tu » d'une mésange, le trille d'un pinson |

Le moulin du hub réutilise `stream.wav`, plus grave (`pitch_scale` 0,72), comme la roue du moulin du Village.

## Interface : `scripts/ui_sounds.gd` (autoload `UiSounds`)

- **Bus « Interface »**, à -8 dB, vers Master. Il est créé au démarrage, comme le bus « Music » : le projet n'a pas de disposition de bus enregistrée.
- **Clic.** Aucun bouton n'a de code à ajouter. Au clic gauche de la souris, `UiSounds` regarde le contrôle survolé (`Viewport.gui_get_hovered_control`, ou son parent s'il s'agit d'un texte ou d'une icône du bouton). Un `BaseButton` actif et visible sonne ; un bouton grisé, non. Le clic part à l'appui, pour répondre tout de suite, alors que le bouton agit au relâchement.
- **Panneaux.** Un panneau se déclare une fois, caché, à sa construction : `UiSounds.watch(racine)`. Son apparition joue `ui_open`, sa disparition `ui_close`, quelle que soit la façon : bouton, Échap, réussite de l'énigme, ou fin de partie qui cache les calques. Panneaux suivis :
  - la pause (`scripts/pause_menu.gd`) et les indices (`scripts/hints.gd`) ;
  - les énigmes : tablette de la Plaine, runes du Désert, cercles du Marais, dispositif des codes et carnet du Village ;
  - le lecteur de textes du HUD : `UiSounds` le retrouve à chaque changement de scène (`Hud`, nœud unique `%Reader`). Le HUD (`scenes/ui/hud.*`) n'a pas été modifié.
- **Garde-fou.** Deux sons du même genre à moins de 60 ms n'en font qu'un (double clic, panneau rouvert aussitôt). Trois lecteurs jouent à tour de rôle : un clic qui ferme un panneau laisse finir les deux sons.
- **Pause.** `UiSounds` tourne aussi quand l'arbre est en pause (`PROCESS_MODE_ALWAYS`) : la pause et les indices figent la partie.

## Pas sur le bois et sur la pierre : `scripts/footstep_surfaces.gd`

- Le joueur (`scenes/player/player.gd`) choisit le son **à chaque pas**, environ deux à trois fois par seconde, jamais à chaque image. Il demande la surface à `FootstepSurfaces.at(position, livres posés)` : quelques dizaines de tests de boîtes, de disques et de bandes, sans requête physique.
- Sur le bois ou la pierre, `Player.SURFACE_STEPS` remplace les pas du lieu. Ailleurs, le lieu garde les siens (`footstep_sounds`) : herbe au hub, cendre à la Plaine et au Village, sable au Désert, boue et éclaboussures au Marais. Le lieu peut toujours les changer, comme le Marais dans l'eau.
- `Player.footstep_surface` donne la surface du dernier pas (`&"wood"`, `&"stone"` ou `&""`).
- **Le Désert et le Marais n'avaient aucun pas.** Leur scène ne donne pas de pas au joueur : le lieu les lui donne depuis son `_ready`, qui passe après celui du joueur. Or le joueur ne créait son lecteur de pas que s'il en avait déjà. Il le crée maintenant toujours, et se tait tant qu'il n'a aucun son à jouer. On entend donc le sable, la boue, l'eau, puis la pierre de la cave et de la crypte.
- **Zones de chaque lieu.** Elles reprennent les constantes des lieux quand elles existent (`HubTerrain`, `MaraisTerrain`, `VillageTerrain`). Sinon, elles reprennent les valeurs des générateurs, citées à côté de chaque zone. La première zone qui contient le point l'emporte. En dessous de y = -20, dans l'intérieur posé sous la carte, l'intérieur a sa propre surface.

| Lieu | Bois | Pierre | Intérieur |
| --- | --- | --- | --- |
| Hub | planchers de toutes les maisons et bâtiments (`HubTerrain.BUILDING_FLOORS`, étage compris), salle de l'observatoire, passerelle du jardin, grand pont de fortune avant le premier livre | château (cour pavée, donjon, salle du trône, `CASTLE_AREA`), grand pont reconstruit au premier livre, dallage du lavoir, estrade du kiosque | bois (abri du bunker) |
| Plaine | | pont de pierre sur la coulée de lave | pierre (archives, escalier, salle du livre) |
| Désert | | salle des colonnes dallée, escalier et margelle de la citerne | pierre (cave des archives) |
| Marais | pontons (`MaraisTerrain.BOARDWALKS`), débarcadère de l'arrivée, au-dessus de l'eau seulement | allée dallée du cimetière, chemin de dalles de la crypte, nef de la chapelle | pierre (escalier et crypte) |
| Village | planchers des maisons (`VILLAGE_HOUSES`, comme `HOUSES` de `tools/build_village.py`), pont du ruisseau et ses rampes | place, grande rue et rue du pont pavées (`cobble_mask`) | bois (mairie), pierre dans la salle secrète |

- **Ajouter une zone.** Dans la fonction du lieu (`_hub`, `_plaine`…) : `Zone.box(surface, x, z, largeur, profondeur, bas, haut, cap)`, `Zone.rect(…)`, `Zone.disc(…)` ou `Zone.lane(surface, début, fin, demi-largeur, bas, haut)`. `bas` et `haut` bornent la hauteur des pieds. `before_books(n)` ou `after_books(n)` la limitent à un palier de livres posés, au hub.
- `sound_test` vérifie un point de chaque zone, et que les maisons du Village sont bien celles de `build_village.py`.

## Hub : rivière, jardin du roi et moulin, `scenes/levels/hub/hub_sounds.gd`

Le nœud `Sounds` du hub est écrit par `tools/write_hub_tscn.py`. Il ne compte que quatre sources 3D, et chacune se tait hors de sa portée :

| Source | Où | Portée | Volume | Quand |
| --- | --- | --- | --- | --- |
| Rivière (`river.wav`) | Au point du tracé de la rivière le plus proche de l'auditeur (`HubTerrain.RIVER`), au ras de l'eau | `unit_size` 6 m, coupée à 38 m | -16 dB avant les livres, jusqu'à -13 dB avec les quatre ; 1 dB de plus au plus près | Toujours, dehors |
| Feuillage (`park_leaves.wav`) | Au point du jardin du roi le plus proche (`HubTerrain.PARK_AREA`), à 3 m de haut : dans le jardin, il est au-dessus de l'auditeur | 7 m, coupé à 30 m | -16 dB, jusqu'à -11 dB ; 1 dB de plus au plus près | Toujours, dehors : des feuilles mortes avant les livres |
| Oiseaux (`bird_1..3.wav`) | Une branche au hasard du jardin, de 3,5 à 6 m de haut | 5 m, coupés à 40 m | -15 à -10 dB, 3 dB de plus au plus près ; hauteur ±8 % | Jardin reconstruit (deuxième livre) : un chant toutes les 9 à 20 s, puis toutes les 2,5 à 7 s après la victoire. Jamais pendant l'éruption |
| Roue du moulin (`stream.wav`, plus grave) | Roue réparée, au bord de la rivière | 4 m, coupée à 24 m | -9 dB, 3 dB de plus au plus près | À partir du deuxième livre, quand la roue tourne |

- Les sources sont replacées dix fois par seconde. Le tracé de la rivière compte 22 points.
- Dans le bunker, sous la carte, toutes se taisent.
- **Le village reste sobre.** Les portées s'arrêtent avant la place : à 60 m de la rivière et à plus de 40 m du jardin, la musique y reste seule avec l'ambiance générale (`hub_ambience.wav`).
- **Le Hub est un village sinistré** (`docs/agents/SCENARIO.md`). Avant les livres, on n'entend que l'eau lente et des feuilles mortes. Le jardin reconstruit retrouve ses oiseaux, de plus en plus nombreux jusqu'à la victoire.

## Plaine : grondement du volcan et vent de la brèche

Deux sources de plus, avec des sons existants (`docs/plaine-finitions.md`) :

| Source | Où | Portée | Volume | Quand |
| --- | --- | --- | --- | --- |
| Grondement du Mont Sam Altan (`volcano_eruption.wav`, `pitch_scale` 0,6) | Non positionnel : le volcan est à près de 300 m | Tout le lieu, dehors | -14 dB | 0,9 s après l'éclat du cratère : 4 s après l'arrivée, puis toutes les 80 à 110 s, jusqu'à 35 à 50 s quand l'heure tourne. Jamais dans les archives, pendant une transition ni après l'éruption |
| Vent dans la brèche de la voûte (`plaine_wind.wav`) | Au trou du plafond de la salle de lecture, à 4,3 m de haut | `unit_size` 2,5 m, coupée à 13 m | -15 dB, `max_db` -11 dB | Toujours, dans les archives (à 40 m sous la carte, elle se tait dehors) |

Joué plus grave et plus lent, le son de l'éruption du hub devient un grondement lointain. Le grondement de pierre de la tablette (`stone_door.wav`, `pitch_scale` 0,55, avec la secousse de la caméra) reste le seul signal d'une erreur.

## Mixage

Repères du jeu : la musique est sur le bus « Music » à -10 dB, et chaque piste est ramenée à environ -22 dBFS RMS avant ce bus (`scripts/music.gd`). Les ambiances des lieux tournent autour de -29 dBFS. Les pas jouent à -13 dB (`Player.footstep_volume_db`).

Mesures du 8 novembre, dans le jeu natif : le mélange du bus Master enregistré (`AudioEffectRecord`), crête et RMS sur toute la durée, en dBFS. « Sans musique » : le bus Music est coupé, pour entendre les pas et l'eau ; l'ambiance des lieux reste.

| Situation | Musique | Crête | RMS |
| --- | --- | --- | --- |
| Menu d'accueil, trois clics sur « Jouer » | oui | -15,6 | -32,6 |
| Hub, au feu de camp : pause, indices et texte lu, ouverts puis fermés | oui | -13,7 | -29,6 |
| Hub, sur la berge de la rivière | oui | -13,5 | -28,7 |
| Hub, jardin reconstruit, avec un oiseau | oui | -15,3 | -30,9 |
| Hub, pas sur l'herbe du chemin | non | -17,7 | -33,6 |
| Hub, pas sur le grand pont de fortune (bois), la rivière dessous | non | -13,8 | -28,4 |
| Hub, pas dans la cour du château (pierre) | non | -15,5 | -34,8 |
| Hub, pas dans l'abri du bunker (bois) | non | -19,9 | -39,7 |
| Hub, berge de la rivière, puis vers le village | non | -14,1 | -30,2 |
| Hub, jardin avant les livres (feuilles mortes) | non | -14,0 | -32,1 |
| Hub, jardin reconstruit (feuillage et oiseaux) | non | -13,7 | -30,5 |
| Hub, roue du moulin réparée | non | -15,3 | -30,9 |
| Village, de la terre aux pavés de la grande rue | non | -13,3 | -28,8 |
| Village, rue du pont (pavés), pont (bois), autre rive (cendre) : avant le plafond du ruisseau | non | -6,8 | -21,9 |
| Village, même trajet, ruisseau plafonné (`max_db`) | non | -9,8 | -23,8 |
| Village, arrêté au milieu du pont, au-dessus du ruisseau : avant, puis après | non | -4,9, puis -7,6 | -17,0, puis -22,4 |
| Village, accueil de la mairie (bois) | non | -12,8 | -28,1 |
| Village, salle secrète (pierre) | non | -14,2 | -28,3 |
| Marais, de la boue au ponton (bois) | non | -11,8 | -27,2 |
| Marais, allée dallée du cimetière | non | -13,6 | -26,8 |
| Marais, crypte | non | -17,2 | -31,5 |
| Désert, du sable au dallage de la salle des colonnes | non | -14,8 | -31,1 |
| Désert, cave des archives | non | -16,9 | -31,4 |
| Plaine, de la cendre au pont de pierre | non | -14,3 | -31,2 |
| Plaine, archives | non | -16,4 | -39,0 |

- **Aucun écrêtage.** La plus haute crête des situations des nouveaux sons est à -11,8 dBFS. Celle du pont du Village (-6,8 dBFS) venait des sources du ruisseau, posées avant ces changements, qui montaient de 7 dB au-dessus de leur volume sous le pont : elles sont plafonnées depuis (voir plus bas), et le pont passe à -9,8 dBFS de crête.
- **Clic.** Il dépasse la musique du menu de 7 à 10 dB en crête, pendant 90 ms. Il s'entend sans couvrir la musique.
- **Panneaux.** Le parchemin dépasse de 8 à 10 dB en crête le fond du hub (musique et ambiance) pendant un tiers de seconde. La clochette reste sous lui.
- **Rivière et jardin.** Le fond est entre -28 et -32 dBFS RMS au bord de l'eau ou dans le jardin, comme la musique après son bus et l'ambiance générale du hub (environ -31 dBFS). Il retombe vers -37 dBFS loin de la rivière et ne joue plus du tout sur la place.
- **Pas.** Les pas sur le bois et la pierre ont la même crête que les autres (-14 à -20 dBFS dans le jeu). Le claquement de la pierre s'entend net ; le bois sonne plus grave et plus sourd.
- **Godot et les sources proches.** `AudioStreamPlayer3D` ajoute le gain de la distance (`unit_size`) au volume avant de plafonner à `max_db`. Une source à 1 ou 2 m monte donc de 10 à 14 dB. Les sources du hub ont un `max_db` à 1 dB (rivière, feuillage) ou 3 dB (oiseaux, roue) au-dessus de leur volume. Avant cela, le feuillage, au-dessus de l'auditeur, montait à -6 dBFS en crête.
- **Village, ruisseau et roue** (8 novembre). Même règle, dans `tools/write_village_tscn.py` : les deux sources du ruisseau (`StreamSound0` sous le pont, `StreamSound1` en amont, volume -4 dB) ont un `max_db` à 1 dB au-dessus de leur volume (`STREAM_NEAR_GAIN`), la roue du moulin à 3 dB (`NEAR_GAIN`). Le niveau ne change qu'à moins de 5,4 m du ruisseau (6 dB de moins sur le pont), pas plus loin. Enregistrements du mélange, musique coupée, avec leur courbe de niveau : `.claude/captures/verif-marche/sons/avant/` et `apres/` (hors dépôt) :
  - pont, en marchant de la rue à l'autre rive : de -6,3 à -9,8 dBFS de crête, de -20,7 à -23,8 dBFS RMS ; le niveau est plat sur le pont (la bosse de 6 dB au-dessus de la source a disparu) et les pas sur le bois s'entendent dans le ruisseau ;
  - arrêté au milieu du pont : de -4,9 à -7,6 dBFS de crête, de -17,0 à -22,4 dBFS RMS ;
  - berge est, à 5 m du pont : inchangée (-10 dBFS de crête, -25 dBFS RMS) ;
  - berge, à 3,5 m de la roue : -6,9 dBFS de crête et -19,5 dBFS RMS (-6,5 et -18,8 avant, d'un passage à l'autre) : la roue y était déjà sous son plafond, son niveau vient de son volume (-2 dB), resté tel quel ;
  - four de la boulangère et forge, à 1,5 m des crépitements : -10 à -14 dBFS de crête, -28 à -30 dBFS RMS, inchangés.

## Export : les sons préchargés

L'export du jeu (`export_presets.cfg`, préréglages « Web » et « Windows Desktop ») part des scènes des lieux et du menu (`export_filter="scenes"`), avec leurs dépendances. Il **ne suit pas les `preload()` des scripts**. Un son préchargé par un script, et qu'aucune scène exportée n'utilise, n'est pas dans le paquet. Le script ne se compile pas dans le jeu exporté, et ceux qui en dépendent non plus.

Vérifié sur un premier export : `Preload file "res://assets/audio/ui_click.wav" does not exist`. Ni `UiSounds`, ni le joueur, ni `GameState` ne se chargeaient.

Les sons préchargés sont donc ajoutés à `include_filter`, comme les pistes de musique : `assets/audio/ui_*.wav`, `assets/audio/footstep_*.wav`, `assets/audio/river.wav`, `assets/audio/park_leaves.wav`, `assets/audio/bird_*.wav`, `assets/audio/stream.wav`.

`sound_test` relit chaque `preload("res://assets/audio/…")` des scripts et vérifie qu'il est bien couvert par ces deux préréglages.

## Poids

Export de production (`frontend/Dockerfile`), avant (303c3ea) et après ces changements, en octets :

| Fichier | Avant | Après | Écart |
| --- | --- | --- | --- |
| `index.pck` | 11 837 968 | 12 036 560 | +198 592 (194 Kio) |
| `index.pck.br`, ce que le navigateur télécharge | 9 721 641 | 9 897 360 | +175 719 |
| `index.pck.gz` | 9 938 028 | 10 113 180 | +175 152 |
| `musique.pck` | 11 007 288 | 11 007 352 | +64 (index du paquet) |

- Les quinze nouveaux sons pèsent 178 610 octets dans le paquet, en Quite OK Audio. Le feuillage en prend 72 Ko, la rivière 54 Ko, les oiseaux 23 Ko, l'interface 15 Ko et les six pas 15 Ko.
- Le reste vient des scripts compilés (`ui_sounds`, `footstep_surfaces`, `hub_sounds`, 14 Ko) et des fichiers d'import.
- `stream.wav`, déjà dans le paquet par le Village, ne coûte rien de plus.
- Les ambiances en boucle sont courtes (6 et 8 s) : leurs événements (bulles, rafales, crépitements) sont tirés pour ne pas se répéter à l'oreille. Les oiseaux sont trois chants courts, rejoués au hasard des branches, avec une hauteur variée, plutôt qu'une longue boucle.

## Contrôles

- `frontend/tests/scenes/sound_test.gd`, dans `run_all.sh` :
  - le bus Interface ;
  - les fichiers, avec la boucle des ambiances ;
  - les sons préchargés par les scripts, tous couverts par l'export (voir plus haut) ;
  - un point de chaque zone de surface, et les maisons du Village recopiées de `build_village.py` ;
  - le lecteur de pas du joueur, même sans pas donnés dans sa scène ;
  - le clic à la souris, et l'absence de clic sur un bouton grisé ;
  - l'ouverture et la fermeture des cinq panneaux d'énigme, de la pause, des indices et du texte lu ;
  - les pas sur le bois et la pierre au hub ;
  - les sources du hub : aucune au village ni dans le bunker, au plus trois à la fois.
- Écoutes et planches de contrôle (hors dépôt) : `.claude/captures/sons/`.
  - `planches/` : forme d'onde, crête, spectrogramme et jointure de boucle de chaque son généré.
  - `generes/` : les sons générés, à écouter seuls.
  - `ecoutes/` : enregistrements du mélange du jeu (bus Master), avec leur courbe de niveau et leur spectrogramme (`<situation>.png`).
    - `outils/record.gd` enregistre le hub : menu et clics, panneaux, rivière, jardin avant et après, moulin, pas sur chaque surface.
    - `outils/record_lieux.gd` enregistre les pas des quatre lieux, et note la surface et le son de chaque pas (`journal_lieux_*.txt`).
    - L'enregistrement se fait avec `AudioEffectRecord` sur Master : le pilote audio Dummy mixe en temps réel.
  - `export/` : tailles de l'export avant et après, et contrôle du paquet exporté (`outils/pck_check.gd`, lancé avec `--main-pack`) : les sons y sont, et `UiSounds`, le joueur et les sons du hub se chargent.
