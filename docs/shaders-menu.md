# Shaders préparés au menu d'accueil

## Le problème

« Sur un nouveau PC, c'est compliqué de jouer fluidement. »

Le rendu Compatibility (WebGL 2 sur le web) compile le shader d'un matériau la première fois qu'il le dessine, et une fois pour chaque variante :

- avec ou sans brouillard (les intérieurs le coupent) ;
- avec ou sans soleil, et la passe de son ombre (découpes PSSM) ;
- sous une lumière ponctuelle ou non ;
- en maillage simple ou en instances (MultiMesh, particules) ;
- la passe de profondeur, et la passe d'ombre projetée.

Le navigateur garde ensuite les programmes compilés dans son cache : la deuxième partie est plus fluide que la première. Un joueur qui découvre le jeu paie donc toutes ces compilations pendant ses premières minutes, au moment où chaque lieu apparaît.

Un premier essai (agent `perf-web`, voir `docs/web-threads.md`) dessinait tout le décor une fois, sous le noir de chaque transition. Il ajoutait 2 à 19 s par lieu, sans gain mesurable, et a été retiré.

## Ce qui a changé

### Inventaire des matériaux, calculé d'avance

`frontend/tools/bake_shaders.gd` écrit `frontend/assets/shader_warm_list.tres` (`ShaderWarmList`).

- Chaque lieu (hub, Plaine, Désert, Marais, Village) est chargé comme en jeu, puis laissé quelques images. Le décor dispersé, les effets, le joueur et les panneaux créés par les scripts y sont donc.
- Pour chaque nœud dessiné, l'outil relève ses matériaux et leur usage : maillage simple ou en instances, ombre projetée. Il relève aussi les particules, les `Label3D`, les soleils, les lumières ponctuelles et l'environnement du lieu.
- Un nœud sous `Interior` ou `BunkerInterior` va dans le groupe intérieur : sans brouillard ni soleil, comme le lieu le dessine.
- Un matériau n'est gardé qu'une fois par contexte de rendu (brouillard, soleils et leurs ombres, lumières ponctuelles). Deux lieux éclairés de la même façon compilent les mêmes programmes.
- Chaque matériau est réduit à ce qui choisit son shader : le même fichier `.gdshader` sans paramètres, ou un `StandardMaterial3D` neuf avec ses seuls réglages (énumérations et cases à cocher). Couleurs, nombres et textures ne changent pas le code d'un shader, et le menu n'a pas de texture à charger.
- Résultat : 10 groupes et 115 entrées pour les cinq lieux (113 avant les finitions de la Plaine, qui ajoutent les projections du volcan et la lumière de la brèche des archives : `docs/plaine-finitions.md`). Deux passages écrivent le même fichier, au calme comme sous charge (voir « Relevé stable d'un passage à l'autre »).

`run_all.sh` vérifie que l'inventaire est à jour (`bake_shaders_check`). Après l'ajout d'un matériau, d'un shader ou d'un lieu :

```
cd frontend && godot --headless --path . --import
godot --headless --fixed-fps 60 --path . --script res://tools/bake_shaders.gd
```

- **L'import d'abord**, après une fusion surtout. Il inscrit les nouvelles classes (`class_name`) dans le cache des classes. Sans lui, les scripts qui les nomment ne se compilent pas, et l'outil refuse le relevé.
- `--fixed-fps 60` fixe la durée des images. Chaque lieu est relevé à sa 12e image exactement, quelle que soit la vitesse de la machine.

Avec `-- --check`, rien n'est écrit : l'outil compare le fichier au calcul et sort en erreur s'ils diffèrent. Avec `-- --sources`, chaque entrée gardée est suivie du nœud qui l'a apportée.

Le fichier est ajouté à l'export par `include_filter` (`export_presets.cfg`, web et Windows) : aucune scène n'en dépend.

### Préparation au menu

`frontend/scripts/shader_warmup.gd` (`ShaderWarmup`) est ajouté par le menu d'accueil, et seulement là.

- Il attend que le menu soit affiché, puis charge l'inventaire en arrière-plan.
- Il dessine chaque entrée hors de l'écran, dans un `SubViewport` de 64 × 64 qui n'est affiché nulle part, avec les lumières et l'environnement de son lieu.
- Une entrée prend deux images : une hors de la lumière ponctuelle avec son ombre projetée, une sous la lumière ponctuelle. Chaque image ne compile ainsi que quelques programmes.
- Après une image qui a compilé, le menu souffle autant d'images qu'elle a duré : la préparation prend au plus la moitié du temps.
- La préparation s'arrête dès qu'une transition commence, donc dès que le joueur lance une partie. Ce qui n'est pas fait sera compilé en jeu, comme avant. Un retour au menu reprend où elle s'était arrêtée.
- Les matériaux de l'inventaire restent en mémoire toute la session. Un `StandardMaterial3D` partage son shader avec tous ceux qui ont les mêmes réglages. Si ces copies étaient libérées, le shader le serait aussi, avec ce qu'il a compilé.
- La préparation ne tourne que dans un jeu exporté (web, Windows) avec un affichage. Dans l'éditeur et les tests, l'option `--prechauffage` l'active et `--sans-prechauffage` la coupe.

### Ombres : deux variantes

Un soleil avec ou sans ombre ne compile pas les mêmes programmes. La préparation fait donc deux passes :

1. d'abord avec les ombres du cran de qualité courant (`RenderQuality`) : soleil sans ombre à partir du cran 5, une seule découpe à partir du cran 4 ;
2. puis avec l'état inverse : sans ombres si le cran en a, avec sinon. La qualité adaptative peut couper les ombres en cours de partie, ou les rendre entre deux lieux.

La seconde passe ne reprend que les groupes dont un soleil a une ombre (les extérieurs).

## Mesures

Chromium sans écran (Playwright), rendu WebGL logiciel (SwiftShader), sur le serveur arm64 de 4 cœurs, chargé par d'autres travaux (charge de 11 à 14 pendant les mesures). Le jeu est servi par le vrai Caddyfile, dans un conteneur jetable sur un réseau Docker interne, avec une API morte. Les outils sont dans `.claude/captures/shaders/outils/` (hors dépôt).

Chaque mesure part d'un navigateur neuf, donc sans cache de shaders, comme un nouveau PC :

1. Le menu s'ouvre. Avec préparation, le pilote y reste jusqu'à la fin de la préparation. Sans préparation, il y reste 20 s.
2. Le pilote va directement dans le lieu, par la vraie transition.
3. Il relève 20 s à partir de l'apparition de la scène (`scene_changed`).

Les appels WebGL de compilation sont chronométrés dans la page (`compileShader`, `linkProgram`, et les lectures d'état qui attendent la fin d'une compilation). Les deux variantes viennent du même export : sans préparation, le pilote retire le nœud du menu.

Ici, une image ordinaire d'un lieu prend déjà 1 à 1,4 s. Compter les images de plus de 50 ms ne dit donc rien : toutes le sont. Les colonnes utiles sont :

- le nombre de programmes compilés ;
- le temps bloqué dans les compilations ;
- la durée de la première image, qui compile presque tout ;
- pour le hub, le moment où le lieu se dévoile (fin de la transition). Les autres lieux ne se dévoilent pas en 20 s dans ce rendu logiciel.

| Lieu | Préparation | Programmes compilés, 20 premières s | Temps bloqué dans les compilations | Première image | Images en 20 s | Lieu dévoilé après |
| --- | --- | --- | --- | --- | --- | --- |
| Hub | sans | 36 | 1,59 s | 5,8 s | 16 | 17,6 s |
| Hub | avec | 3 | 0,03 s | 3,5 s | 22 | 11,0 s |
| Plaine | sans | 122 | 7,51 s | 11,7 s | 10 | > 20 s |
| Plaine | avec | 38 | 1,75 s | 5,3 s | 10 | > 20 s |
| Désert | sans | 126 | 9,47 s | 14,3 s | 10 | > 20 s |
| Désert | avec | 27 | 1,15 s | 3,9 s | 12 | > 20 s |
| Marais | sans | 142 | 8,22 s | 14,7 s | 10 | > 20 s |
| Marais | avec | 36 | 1,86 s | 8,0 s | 10 | > 20 s |
| Village | sans | 121 | 7,83 s | 12,2 s | 10 | > 20 s |
| Village | avec | 36 | 1,42 s | 4,2 s | 10 | > 20 s |

Dans chaque lieu, la première image est suivie d'une dizaine d'images courtes sous le titre, puis d'une très longue image quand le lieu se dévoile. Dans le hub, cette image passe de 6,7 s à 3,2 s avec la préparation. Dans les autres lieux, elle dépasse la fenêtre de 20 s, sauf pour le Désert avec préparation (15,2 s), dont la première image a été la plus courte.

Au menu, pendant la préparation (première passe seulement, celle des mesures ci-dessus) :

| | Sans préparation | Avec préparation |
| --- | --- | --- |
| Durée | 20 s | 162 à 211 s, 222 images de préparation |
| Programmes compilés | 0 | 325 |
| Plus longue image | 0,29 à 0,87 s | 1,8 à 3,0 s |
| Son sans données (quanta de 128 échantillons) | 0 à 1,4 % | 0 à 0,07 % |
| Capture du menu | normale | identique : rien ne se voit |

Vérification de la version finale, avec les deux variantes d'ombre (hub) :

- au menu, 382 images de préparation en 192 s, et 393 programmes compilés (68 de plus que la première passe seule : la variante sans ombres a bien ses propres programmes) ;
- aucun quantum de son sans données ;
- dans le hub, 3 programmes compilés en 20 s, une première image de 2,6 s, et le lieu dévoilé après 8,6 s.

Ce qu'on en retient :

- **Le gain est net.** En arrivant dans un lieu, les programmes compilés baissent de 69 à 92 %, et le temps bloqué dans les compilations de 77 à 98 %. La première image est 1,6 à 3,7 fois plus courte, et le hub se dévoile 6,6 s plus tôt.
- **Ces mesures sont bruitées** par la charge du serveur : une seule mesure par cas. Les nombres de programmes compilés, eux, ne dépendent pas de la charge.
- **Il reste une trentaine de programmes par lieu.** Ce sont sans doute des objets créés plus tard (décor qui apparaît en approchant, effets), ou des variantes que la scène de préparation ne reproduit pas. Une piste : relever le texte de ces programmes avec le même banc.
- **Le menu.** En rendu logiciel, une image de préparation peut durer 1 à 3 s. Sur une vraie carte graphique, une compilation prend quelques millisecondes à quelques dizaines. Le son ne décroche pas : il est mixé sur son propre fil (`docs/web-threads.md`). Le menu reste utilisable entre deux images de préparation.
- **La préparation dure environ 3 minutes ici.** Un joueur qui lance la partie plus tôt garde ce qui est déjà fait. La liste commence par le hub, là où commence une partie.

## Relevé stable d'un passage à l'autre

### Le symptôme

Après la fusion du récit du Village dans `dev`, l'inventaire régénéré comptait 112 entrées, et son contrôle passait. Dans la suite complète, le contrôle en relevait 113. L'entrée en plus était un « nouveau » `StandardMaterial3D` peint par sommets (`vertex_color_use_as_albedo`), sans ombre (`usage=0`), au Village, dehors. La suite tournait sous charge : on soupçonnait la vitesse de la machine.

### La cause : le cache des classes, pas la charge

- **Ce matériau est celui de `VillageMesh`.** Les corbeaux, les chats, les poules et la girouette du Village sont faits de formes fondues, peintes par sommets. `-- --sources` montre l'entrée apportée par `/root/Village/Crows/Crow0/…/MeshInstance3D`.
- **Ces classes étaient nouvelles.** `VillageMesh`, `VillageHen` et `VillageVane` arrivent avec le récit du Village. Godot ne connaît une classe (`class_name`) que par le cache des classes (`.godot/global_script_class_cache.cfg`), et seul l'import le met à jour.
- **L'inventaire de la fusion a été régénéré avant tout import.** Dans `~/cdp-dev`, la fusion est datée de 04:12:14, le cache des classes de 04:12:29 : c'est l'import par lequel commence `run_all.sh`.
  - Avant cet import, les scripts du Village qui nomment ces classes ne se compilaient pas : 107 erreurs `Parse Error: Identifier "VillageMesh" not declared`. Le relevé, lui, continuait.
  - Les bêtes n'avaient donc pas de maillage, et leur matériau manquait.
  - Le contrôle lancé juste après, avec le même cache, relevait la même chose : « à jour ».
- **Dans la suite**, l'import passe d'abord. Les bêtes sont là, et le contrôle trouve la 113e entrée.
- **Preuve.** Le cache des classes de la worktree, privé de ces trois classes, rejoue la fusion. L'ancien outil y relève exactement les 112 entrées de la fusion, et dit « inventaire à jour ». Avec le cache à jour, il en relève 113 à chaque passage : 4 au calme, et 3 sous charge, de 8 boucles de calcul à côté jusqu'à une charge de 6,5. Ce sont les entrées de la branche du récit du Village.
- **La charge n'y est pour rien.** Le relevé est le même sous charge. Le hub n'a rien regroupé pendant les 12 images (`batch_msec` à 0).

### Ce qui dépendait encore de l'horloge

- **La crypte du Marais** se prépare par tranches de 8 ms de temps réel, et le relevé l'attendait : il se faisait à la 15e image au calme, à la 23e sous charge.
  - Le résultat ne changeait pas : il est le même au bout de 4, 12 ou 120 images.
  - Mais l'instant du relevé dépendait de la machine. Un effet du Marais créé entre ces deux images n'aurait été relevé que sous charge.
  - Maintenant, l'outil finit la crypte d'un coup après les 12 images (`finish_preparation()`, comme en jeu quand on y descend). Chaque lieu est relevé à sa 12e image exactement.
- **Le hub** lance son regroupement par un appel différé de son `_ready` (`_batch_shown`).
  - Le `set_process(false)` de chaque image passait après lui, mais seulement parce qu'un pas de physique les séparait.
  - Un `set_process(false)` différé, demandé à l'arrivée, passe après lui à coup sûr : la file des appels différés garde l'ordre.
- **Le hasard des bêtes** (`randf()` des corbeaux et des chats) ne choisit que la phase et la direction de leurs mouvements. Il ne touche ni leurs maillages, ni leurs matériaux.

Rien à corriger dans le jeu :

- un jeu exporté est toujours importé à neuf (l'image Docker) ;
- dans le hub, chaque groupe change d'un coup, et l'inventaire a ses deux états, à l'arrivée et tout regroupé.

### Garde-fou

- **Erreurs de script.** L'outil écoute les erreurs de script pendant tout le passage (un `Logger`, `OS.add_logger`). À la moindre, il n'écrit rien et sort en erreur, contrôle compris :
  `Shaders : RELEVÉ INCOMPLET, 107 erreurs de script : leurs nœuds manquent. Cache des classes périmé ? Lancer d'abord godot --headless --path . --import`
  Les trois premières erreurs sont affichées avant ce message.
- **`-- --sources`** affiche le nœud qui apporte chaque entrée.

### Vérification

- **Le garde-fou.** Avec le cache des classes privé de `VillageMesh`, `VillageHen` et `VillageVane`, l'outil refuse le relevé et n'écrit rien. Il sort en erreur, en contrôle comme en écriture, et affiche la première erreur, `village.gd:130 … Identifier "VillageMesh" not declared`.
- **L'inventaire régénéré** après import : 10 groupes, 113 entrées. C'est l'inventaire de la fusion plus l'entrée de `VillageMesh`, soit les mêmes entrées que la branche du récit du Village.
- **10 relevés `--check` consécutifs**, tous « inventaire à jour » à 113 entrées, sans erreur de script :
  - relevés 1, 2, 9 et 10 au calme, en 13,3 s chacun ;
  - relevés 3 à 5 sous 8 boucles de calcul (`nice -n 10`, autant que l'enveloppe de Godot) : charge de 4,6 à 8,0, en 30 à 32 s ;
  - relevés 6 à 8 sous ces boucles, avec un autre relevé lancé en même temps par l'enveloppe : charge de 9,0 à 9,9, en 33 à 36 s. Les trois relevés parallèles sont « à jour » eux aussi.
  - Journaux : `.claude/captures/shaders-stable/serie/` (hors dépôt).
- **Suite complète** (`run_all.sh`, depuis la branche) :
  - `bake_plaine_check`, `bake_lieux_check` et `bake_shaders_check` : à jour ;
  - 0 échec partout (`hub_test`, `music_test`, `sound_test`, `gamepad_test`, `menu_test`, `marais_puzzle_test` et `village_test` compris), sauf `hub_walk_0` et `hub_walk_4`, qui ont leurs 2 échecs voulus ;
  - `run_tests` : 52 réussis.

## Bruit dans les journaux de tests

`GameState._isolate_test_saves` efface les dossiers de sauvegarde des tests arrêtés en route. Il testait chaque processus avec `OS.is_process_running`, qui ne connaît que les processus fils.

Pour le processus d'un autre test, la fonction affichait `ERROR: … _check_pid_is_running` et répondait « arrêté ». Le dossier d'un test encore en cours pouvait donc être effacé.

Sous Linux, l'existence du processus se lit maintenant dans `/proc/<pid>`. Ailleurs, rien ne change. Un dossier laissé par un ancien processus du même numéro que le test en cours est effacé, comme avant.

L'erreur `Couldn't open directory at path "user://tests/<pid>/"`, à la sortie d'un test, venait de là : un autre test avait effacé son dossier en cours de route. Elle disparaît quand tous les tests tournent avec cette version.
