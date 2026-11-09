# Hub : la mine d'argent refaite (retour des testeurs du 8 novembre)

Branche `features/hub-mine`. Retour : « Refaire la mine que claude a refait, en se basant sur le modèle des mines dans
Clash of Clans ». Image jointe : `.claude/captures/retours/hub/mine_reference_retour_0811.png` (hors du dépôt). On y lit
une entrée de galerie trapue, faite de grosses planches posées en arc et cerclées de fer, sur un socle de grosses
pierres ; un wagonnet chargé sort sur des rails ; une caisse de minerai, des gravats, une lueur chaude au fond.

La mine reprend cette silhouette et cette lisibilité avec les modèles Kenney du dépôt, sans copier le dessin d'un jeu
existant. Elle est générée par `build_mine()` de `frontend/tools/build_hub.py` (bloc « Mine d'argent », seul changé).

## Ce qui est construit
Repère de l'entrée : `MINE_MOUTH` (82,6 ; -39,6), `MINE_YAW` -60 degrés, l'entrée tournée vers le bout des deux
ruelles de la mine. Tout tient dans le replat de la mine (`LANDMARKS` de `hub_terrain.gd`, rayon 13 m).

| Partie | Modèles | Détail |
| --- | --- | --- |
| Voûte | `fantasy_town_kit/wall-wood-block` (11) | Madriers de 0,55 m sur un arc de 2,4 m de rayon intérieur, de -10 à 190 degrés, sur 6 m de long. Faîte à 3,55 m, 5,9 m de large. |
| Arc de tête | `wall-wood-block` (11) | Voussoirs plus épais (0,92 m), un sur deux avance de 6 cm. |
| Cercles de fer | `fantasy_town_kit/wall-block` (22) | Deux cercles. Les faces gris pâle du bloc font le fer, comme les cerclages du kit (tonneaux, roues). |
| Socle | `nature_kit/stone_largeB`, `D`, `F` (8) | Grosses pierres arrondies, deux plus grosses qui encadrent l'entrée. |
| Tertre | `castle_kit/rocks-large` (5) | La galerie s'y enfonce derrière les cercles de fer. Il monte un peu plus haut que la voûte. |
| Fermeture | `fantasy_town_kit/planks` (4), SignBoard `MineOrder` | Une croix et deux traverses de planches, avec l'écriteau « Fermée par ordre du roi Codeon V ». |
| Fond | `mini_dungeon/rocks`, `stones` | Éboulis qu'on devine entre les planches. |
| Rails | `wall-wood-block`, `wall-block` | Deux longrines de bois coiffées de fer, sur des traverses. Elles sortent de la galerie vers la ruelle du sud (10 degrés). |
| Wagonnet | `planks` (5), `wall-block` (8), `fantasy_town_kit/wheel` (4), `graveyard_kit/rocks` (2) | Caisse évasée cerclée de fer sur quatre roues, chargée de minerai d'argent (pierres gris pâle). Il est calé par un coin de bois devant la roue. |
| Abords | `planks` (5), `graveyard_kit/rocks`, `nature_kit/log_stack`, `survival_kit/tool-pickaxe`, `tool-shovel`, `graveyard_kit/debris` (4), `castle_kit/rocks-small` (2) | Caisse de minerai, pile de bois de soutènement, pic et pelle laissés là, gravats. |

En tout, 119 modèles et 54 collisions (l'ancienne mine en avait 24 et 16). Le bois, le fer, les planches et les roues
viennent du même kit : une fois le décor regroupé (`hub_batch.gd`), ils ne font qu'un matériau.

Pour poser des pièces tournées autour de l'axe de la galerie, `mine_piece()` écrit la transformée complète de chaque
modèle (`transform_text`). Un modèle est étiré à une taille donnée le long de ses axes. `mine_solid()` fait de même pour
les collisions.

## Comment la fermeture se montre
- **Une croix et deux traverses de planches clouées sur l'arc de tête.** C'est le signe d'une entrée condamnée qu'on lit
  de loin. Il ne cache rien de la silhouette demandée : l'arc de madriers, les cercles de fer et le socle restent
  entiers autour.
- **L'écriteau de l'ordre**, sur la traverse haute, à 1,85 m, face au chemin. Il est lisible de près, comme le dit le
  panneau à lire « La mine d'argent » (`write_hub_tscn.py`, inchangé) : « Un écriteau est cloué au boisage ».
- **Le wagonnet arrêté.** Il est encore chargé, calé sur ses rails à 4,6 m de l'entrée. Les outils sont restés à terre.
  On a quitté la mine sur ordre, sans finir le travail.
- **Pas de lueur chaude au fond.** La lueur de l'image de référence dit une mine en activité. Celle-ci est fermée et
  sa galerie s'est effondrée pendant la guerre (panneau à lire). La galerie reste donc sombre derrière les planches, et
  on y devine l'éboulis. La lecture « mine » tient à la voûte boisée, aux rails et au wagonnet chargé. Ne pas ajouter de
  lumière évite aussi des passes de rendu de plus en Compatibility.

## Collisions
- Chaque madrier et chaque voussoir a sa collision, tournée comme lui sur l'arc.
- Derrière les planches, la galerie est pleine jusqu'à leur face avant, en trois gradins inscrits sous la voûte : rien
  n'y mène, et rien ne dépasse de la voûte.
- Le socle, les gravats hauts, la caisse, le wagonnet et la pile de bois ont une boîte à leur emprise.
- Chaque amas du tertre a trois gradins qui suivent ses colonnes (`MINE_ROCK_TIERS`), et non une boîte englobante.
- Les rails, les traverses et les gravats bas sont sous la cheville : ils n'ont pas de collision.
- Capture des collisions en rouge : `.claude/captures/hub-mine/final/collisions/`.
- On peut monter sur la voûte et le tertre en sautant depuis les pierres du socle ou le wagonnet, puis en redescendre.
  La sonde de saut ne trouve aucun point où l'on reste coincé.

## Contrôles
- **Sonde de saut du Hub** (`hub_jump_probe.gd`), de x 70 à 98 et de z -56 à -22, pas de 0,5 m : 42 352 sauts en
  courant à 0 livre comme à 4 livres, **0 point coincé**. Un premier passage au pas de 0,75 m sur une version
  précédente donnait aussi 0.
- **Grille de marche locale** (`walk_grid.gd` des archives, décor non regroupé pour garder la boîte de chaque modèle),
  de x 62 à 102 et de z -60 à -20, cases de 0,5 m, depuis les deux ruelles et la passerelle, à 0 livre : 4 068 cases,
  0 trou, 0 ressaut, 0 chute, 0 glissade, **0 maillage visible sans collision**. Les 25 « murs invisibles » relevés sont
  tous sur les berges fermées de la rivière (`River/Banks`) ou au bord de l'eau : aucun à la mine. On bute sur la mine
  466 fois, toujours contre une pièce visible.
- **Calculs d'avance** : `bake_lieux_check` et `bake_shaders_check` à jour après la fusion de `dev`. La dispersion ne
  bouge pas, la mine reste dans son replat.
- **Générateurs sans dérive** : `build_hub.py` régénère exactement le `hub_props.tscn` commité, et `write_hub_tscn.py`
  exactement le `hub.tscn` de `dev`. Le générateur de `dev` reproduit lui aussi son propre `hub_props.tscn`.

- **Suite complète** (`run_all.sh`, après la fusion de `dev` 57660f8) :
  - `bake_plaine_check`, `bake_lieux_check` et `bake_shaders_check` : à jour ;
  - 0 échec partout, sauf `hub_walk_0` et `hub_walk_4` : 2 échecs chacun, les deux « limite infranchissable (doit
    echouer) » ;
  - `hub_test`, `music_test` et `sound_test` à 0 échec du premier coup ;
  - `run_tests` : 52 réussis, 0 échec.
- **Export** : rien de chargé par `preload()`. Les modèles suivent `hub_props.tscn` (`export_filter="scenes"`).

### Appels de dessin, dehors, en regardant la mine
Visibles et ombres, natif sous Xvfb, 1280 x 720, une fois le décor regroupé. Outil : `docs/agents/hub/mine_shots.gd`.

| Vue | 0 livre, avant | 0 livre, après | 4 livres, avant | 4 livres, après |
| --- | --- | --- | --- | --- |
| Face (13 m) | 91 | 95 | 123 | 127 |
| Trois quarts, gauche | 227 | 230 | 288 | 291 |
| Trois quarts, droite | 96 | 100 | 140 | 144 |
| De près | 88 | 90 | 126 | 128 |
| Ruelle du sud | 239 | 241 | 302 | 304 |
| Ruelle du nord | 317 | 321 | 397 | 401 |
| Passerelle du jardin | 400 | 404 | 444 | 448 |
| Route du bunker, de l'autre rive | 274 | 277 | 373 | 376 |
| De haut | 248 | 251 | 339 | 340 |
| Vue de dessus | 209 | 209 | 214 | 214 |

L'écart est de 0 à 4 appels à 0 livre et de 0 à 4 à 4 livres. Il vient des matériaux ajoutés dans la case de la mine :
les pierres du socle, et le minerai et les gravats (`graveyard_kit`).

## Captures (hors du dépôt)
- Avant et après, à 0 et 4 livres, mêmes vues : `.claude/captures/hub-mine/final/avant_0`, `apres_0`, `avant_4`,
  `apres_4`. Planches : `final/planches/avant_apres_0.png` et `avant_apres_4.png`.
- Référence des testeurs à côté de la mine : `final/planches/reference_et_mine.png` et `reference_vue_haute.png`.
- Étapes de travail : `.claude/captures/hub-mine/v1` à `v5`.
