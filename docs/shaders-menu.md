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
- Résultat : 10 groupes et 111 entrées pour les cinq lieux. Deux passages écrivent le même fichier.

`run_all.sh` vérifie que l'inventaire est à jour (`bake_shaders_check`). Après l'ajout d'un matériau, d'un shader ou d'un lieu :

```
cd frontend && godot --headless --fixed-fps 60 --path . --script res://tools/bake_shaders.gd
```

`--fixed-fps 60` rend le relevé indépendant de la charge de la machine : le hub regroupe son décor au fil du temps, et le relevé se fait au bout de quelques images.

Avec `-- --check`, rien n'est écrit : l'outil compare le fichier au calcul et sort en erreur s'ils diffèrent.

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

## Bruit dans les journaux de tests

`GameState._isolate_test_saves` efface les dossiers de sauvegarde des tests arrêtés en route. Il testait chaque processus avec `OS.is_process_running`, qui ne connaît que les processus fils.

Pour le processus d'un autre test, la fonction affichait `ERROR: … _check_pid_is_running` et répondait « arrêté ». Le dossier d'un test encore en cours pouvait donc être effacé.

Sous Linux, l'existence du processus se lit maintenant dans `/proc/<pid>`. Ailleurs, rien ne change. Un dossier laissé par un ancien processus du même numéro que le test en cours est effacé, comme avant.

L'erreur `Couldn't open directory at path "user://tests/<pid>/"`, à la sortie d'un test, venait de là : un autre test avait effacé son dossier en cours de route. Elle disparaît quand tous les tests tournent avec cette version.
