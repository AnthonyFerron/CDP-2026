# Consigne commune aux agents CodeQuest

Tu travailles sur **CodeQuest**, un jeu Godot 4.7.2 (GDScript, rendu Compatibility, export web), dans **ta propre copie git (worktree)**. Plusieurs agents travaillent en parallèle, chacun sur **un lieu** du jeu. Un orchestrateur fusionne vos branches : respecte strictement les fichiers qui te sont réservés pour éviter les conflits.

Tout le texte du jeu, les commentaires et les messages de commit sont **en français**. Le jeu est low-poly, nocturne ou crépusculaire, dans l'univers médiéval-fantastique de « Codia ». **Le scénario officiel fait foi pour tous les textes : lis `docs/agents/SCENARIO.md`.**

En bref :
- En 5814, après dix ans de guerre contre le royaume voisin de **Vibelandia**, le Mont Sam Altan se réveille. Les Quatre Dragons du Chaos sont une victoire plus ancienne de Devlyn, pas la cause des destructions.
- Devlyn a une heure pour retrouver quatre livres : Projenomicon, Algonicon, Logiconomicon, Codonomicon. C'est un choix de l'équipe : le scénario dit quarante minutes.
- Le roi est Codeon V, le mage est Merlon.

Le `README.md` à la racine et le README de chaque lieu décrivent tout le reste : **lis-les d'abord**.

## Outils

- **Variables utilisées ci-dessous :**
  - `$GODOT` : le binaire de Godot 4.7.2 (sur le serveur, la version Linux arm64) ;
  - `$WORK` : ton dossier de travail, **hors du dépôt**, par exemple `~/cdp-work/<ton-lieu>/`. Tes scripts, captures et journaux y vont.
- **Première chose à faire dans ta worktree :** `git lfs pull` si les modèles sont des pointeurs, puis `cd frontend && "$GODOT" --headless --path . --import`. Copier le dossier `frontend/.godot` d'une autre worktree fait gagner du temps.
- **Lancer un test :** `cd <ta-worktree>/frontend && "$GODOT" --headless --path . --fixed-fps 60 --script res://tests/scenes/<test>.gd -- --api=http://127.0.0.1:9/api/v1`. `--path .` doit pointer sur **ta** worktree.
- **Sans écran (serveur) :**
  - pour toute capture, et pour les tests qui lisent les MultiMesh, préfixe la commande avec `xvfb-run -a -s "-screen 0 1920x1080x24"` et enlève `--headless` ;
  - ajoute `--audio-driver Dummy` à chaque lancement.
- **Captures :** sans `--headless`, avec `--resolution 1280x720`. `res://tests/scenes/cam_shots.gd` prend des captures depuis des caméras libres :
  `"$GODOT" --path . --resolution 1280x720 --script res://tests/scenes/cam_shots.gd -- res://scenes/levels/<lieu>/<lieu>.tscn "$WORK/shots" "nom=x,y,z:cx,cy,cz" ... --api=http://127.0.0.1:9/api/v1`
  - Un dossier relatif va sous `user://captures/`.
  - `inside` bascule le niveau sur son intérieur sous la carte, et `noshadow` coupe les ombres.
  - `x,y,z:cx,cy,cz:taille` donne une vue orthographique, pratique en vue de dessus.
  - **Regarde vraiment tes captures** (outil Read sur le PNG) : c'est ta seule façon de juger le rendu.
- **Tests partagés**, à lancer sans les modifier : copie-les dans `$WORK` si tu dois les adapter, et signale-le.
  - La suite complète, avec Xvfb automatique sans écran : `GODOT=$GODOT bash frontend/tests/scenes/run_all.sh "$WORK/logs"`.
  - Base commune : `frontend/tests/scenes/common_test.gd`.
  - Hub : `hub_test` et `hub_walk_test` (argument `0` ou `4`).
  - Énigmes : `plaine_puzzle_test`, `desert_puzzle_test`, `marais_puzzle_test`, `village_test`.
  - Interface et réglages : `timer_test`, `menu_test`, `login_test`, `debug_test`, `fullscreen_test`.
  - Avec fenêtre : `tree_collision_test`. Panneaux : `signboard_test`.
  - Tests de l'intégration API : `res://tests/run_tests.tscn`.
  - Échecs voulus de `hub_walk_test` : « limite infranchissable (doit echouer) ».
- **Chevauchements de meubles :** `cd <worktree>/frontend && PYTHONIOENCODING=utf-8 python3 tools/check_overlaps.py tools`. Attention : il régénère les scènes en important les builders.
- **Taille d'un modèle Kenney :** copie `res://tests/scenes/aabb.gd` dans `$WORK`, change sa liste `MODELS`, puis lance-le avec `--script`.
- **Apostrophes :** les heredocs bash cassent sur les apostrophes françaises. Écris tes scripts Python de patch dans des fichiers.
- **Exemples :** les outils et notes des agents précédents sont archivés dans `docs/agents/<lieu>/`. Ils ne s'exécutent pas tels quels, car leurs chemins datent du PC Windows.

## Comment les scènes sont faites

- **Objets fixes :** ils sont générés par `frontend/tools/build_<lieu>.py` (Python, sans dépendance), qui écrit `scenes/levels/<lieu>/<lieu>_*.tscn`. Les aides partagées sont dans `tools/build_plaine.py` :
  - `Scene`, avec `add(model, position, degrés, échelle, tilt, roll)` et `add_box(centre, taille, degrés)` ;
  - `wall` et `doorway`. `doorway` laisse un trou de ± 0,95 m : appelle `arch_fill()` pour le caler sur l'arche visible.
  - `furniture(scene, model, centre, degrés, échelle, height=…, tilt, roll)`, qui pose un modèle **au sol par sa boîte englobante**, avec sa collision. Les boîtes sont dans `MODEL_BOXES`, en coin et taille à l'échelle 1.
  - `furniture_fit`, `camp` et `against_wall`.
- **Scène principale de chaque lieu :** `<lieu>.tscn` est écrite par `frontend/tools/write_<lieu>_tscn.py` pour le hub, le désert, le marais et le village. L'argument est le chemin du dossier `frontend` de ta worktree. La Plaine n'en a pas : `plaine.tscn` s'édite directement.
- **Terrain :** il est maillé (`<lieu>_terrain.gd`).
  - `GridHeight` donne la hauteur exacte du sol maillé (`surface_height`, `footing_height`).
  - Un replat (`flat_mask`) aplanit le sol sous les bâtiments.
  - `<lieu>_scatter.gd` disperse arbres, rochers et herbes en évitant les zones réservées, par cases de 32 m (portée de visibilité par case).
- **Intérieurs :** ils sont posés sous la carte (nœud `Interior`, y = -40), et le niveau bascule entre extérieur et intérieur avec un fondu.
- **Modèles :** **uniquement les kits Kenney déjà présents** dans `frontend/assets/models/kenney/` : castle_kit, fantasy_town_kit, food_kit, furniture_kit, graveyard_kit, mini_arena, mini_dungeon, mini_forest, modular_dungeon_kit, nature_kit, survival_kit, 3d_road_tiles.
  - **Aucun téléchargement**, aucune autre source.
  - Tu peux aussi construire des formes simples (BoxMesh, CylinderMesh…) avec des matériaux.
  - Rien de moderne : pas de four, cuisinière ou évier modernes. `MEDIEVAL` dans `build_plaine.py` remplace ces meubles.

## Textes dans le monde : plus aucun texte flottant

- **Interdits :** un `Label3D` en `billboard`, avec `outline_size` ou `no_depth_test`, ou suspendu dans le vide au-dessus d'un objet.
- **Utilise `SignBoard`** (`frontend/scripts/sign_board.gd`, `class_name SignBoard`) :
  - une planche (`style` : WOOD, STONE, PARCHMENT, IRON) avec sa monture (`mount` : POSTS, WALL, HANGING), et le texte écrit sur la face ;
  - propriétés : `text`, `board_size`, `board_height`, `line_height`, `serif`, `double_sided`, `roof`, `collision` ;
  - la face regarde vers **+Z** du nœud ;
  - collision : sur poteaux, les deux poteaux et la planche, sans rien dessous ; suspendu, seulement le montant.
- **Texte lisible avec E :** place le SignBoard **sous** un nœud `Readable` (titre et texte complet). Le panneau ne montre qu'un titre ou un court extrait.
- **Inscription gravée** sur un mur, une stèle ou un tombeau : elle peut rester un `Label3D` **collé à la surface** :
  - à 1 ou 2 cm, orienté comme la face ;
  - `billboard = 0`, `shaded = true`, `outline_size = 0`, `alpha_cut = 1` ;
  - encre sombre ou dorée ;
  - jamais à travers un autre objet.
- **Symboles :** aucun en dehors de l'alphabet latin dans un texte affiché. La version web n'a pas de police de secours.

## Fichiers : ce que tu peux toucher

- **À toi :**
  - tout ce qui est dans `frontend/scenes/levels/<ton-lieu>/` ;
  - `frontend/tools/build_<ton-lieu>.py` et `frontend/tools/write_<ton-lieu>_tscn.py` ;
  - l'entrée de ton lieu dans `ZONE_HINTS` de `frontend/scripts/hints.gd`, seulement si tu déplaces des indices ;
  - le README de ton lieu.
- **Interdits** (signale le besoin dans ton rapport) :
  - `tools/build_plaine.py`, sauf pour l'agent de la Plaine, et seulement pour **ajouter** des entrées ou des fonctions ;
  - `scripts/*` (sauf l'entrée de `hints.gd` citée plus haut), `scenes/player/*`, `scenes/ui/*` ;
  - `project.godot`, `export_presets.cfg`, le `README.md` racine, `frontend/tests/*` ;
  - les scènes et outils des autres lieux, les textures Kenney.
- **Boîtes de modèles :** les autres agents ajoutent les leurs dans **leur propre** builder : `from build_plaine import MODEL_BOXES`, puis `MODEL_BOXES.update({...})` en tête du fichier.
- **Builder :** ne lance que celui de **ton** lieu.
- **`test_level.tscn` :** `frontend/scenes/levels/test_level.tscn` est recréé par l'éditeur. Ne le committe jamais.

## Qualité attendue

- **Méthode :** la méthode de vérification est dans `docs/agents/PASSE_CENTIMETRE.md`. On vérifie chaque centimètre carré, pas seulement des points choisis.
- **Chaque objet de ton lieu :**
  - posé au sol, ni flottant ni enterré ;
  - sans traverser un mur ou un autre objet ;
  - avec une collision à sa forme s'il est plus haut que la cheville ;
  - sans bloquer un passage, une porte ou un chemin.
- **Chaque indice ou interaction** doit être visible, atteignable à pied, et ni caché derrière un modèle ni dedans. L'invite apparaît quand on le regarde depuis une position atteignable. Chaque sortie marche de chaque endroit où le joueur l'attend, par exemple en haut et en bas d'un escalier.
- **Énigme :** le test de ton lieu doit toujours passer.
- **Décor :** sois créatif et raconte l'histoire du lieu, tout en gardant le chemin et les indices lisibles et des performances correctes pour le web. Pour les éléments répétés, utilise des MultiMesh par cases.
- **Logique de jeu :** ne casse ni les énigmes, ni la progression, ni le chronomètre, ni la synchronisation avec le serveur (`GameState.request_place_book()`, `request_victory()`).

## API du serveur (intégration Godot ↔ API)

- `Account` et `GameSync` parlent au vrai serveur. Sur ordinateur, l'adresse par défaut est la **production**.
- **Chaque lancement de Godot** pour un test ou une capture vise une adresse locale morte, en arguments utilisateur :
  - `-- --api=http://127.0.0.1:9/api/v1` ;
  - ou à la suite des arguments du test : `-- 0 --api=http://127.0.0.1:9/api/v1`.
- Ne jamais se connecter, créer de compte ou envoyer de partie vers codequest.anthonyferron.com. Le compte simulé du menu de debug (`Account.simulated`) reste utilisable.
- **Tests fonctionnels :** ils demandent une API de test locale et `frontend/tests/mailsink.py` (voir `docs/api-godot.md`).

## Git

- Committe dans ta worktree, par étapes logiques, avec le préfixe `features : ` ou `fix : ` et un message en français.
- **Jamais** de ligne `Co-Authored-By`, ni aucune mention de Claude ou de Claude Code dans les commits.
- Ne pousse rien et ne fusionne rien : l'orchestrateur s'en charge.

## Rapport final (ton dernier message)

En français et concis :
- ce que tu as vérifié et corrigé, avec le nombre de problèmes trouvés et corrigés ;
- ce que tu as ajouté au décor, et les textes remplacés ;
- le résultat de chaque test, avec les échecs éventuels ;
- le chemin de 4 à 6 captures représentatives ;
- le nom de ta branche et de tes commits ;
- tout besoin sur un fichier interdit.
