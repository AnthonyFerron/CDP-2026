# Performances web des plaines d'Hexcole (BACKLOG n° 5)

Mesures de la nuit du 4 au 5 novembre 2026, sur le serveur : Linux arm64, rendu logiciel llvmpipe sous Xvfb,
1280 x 720, rendu Compatibility, sans synchronisation verticale, 30 images par vue après 15 de mise en route.

Les appels de dessin sont exacts : `Viewport.get_render_info`, identiques d'un passage à l'autre. Les temps d'image ne
valent que pour comparer, et encore : pendant la mesure « avant », d'autres Godot tournaient sur le serveur ; pendant
la mesure « après », ce Godot était presque seul. Une part de leur baisse vient de là.

- « Avant » : commit 18decd9 (69a21ae avec dev fusionné), regroupement absent.
- « Après » : le regroupement du décor (`PlaineBatch`, `_batch_decor()` dans `plaine.gd`).

Méthode et outils : ceux du Marais (`docs/agents/marais/PERFORMANCES.md`), adaptés dans `perf/` :
- `perf_plaine.gd` et `perf.sh` : comptes, 10 vues mesurées, captures figées ;
- `shots.txt` : 16 points de capture, dehors et dedans ;
- `diff_images.gd` : planches avant | après | écart (x 4) ;
- `collisions.gd` : relevé trié des formes de collision et grille de marche rapide par remplissage, dehors à 0,6 m et
  dans les archives à 0,3 m.

## Ce qui a été fait

`PlaineBatch` (`scenes/levels/plaine/plaine_batch.gd`) est une copie de `MaraisBatch`, avec une liste de modèles
laissés à part. `_batch_decor()` l'appelle au chargement, une fois la suie posée et les enveloppes de collision tirées
des modèles :
- ruines et champ de bataille : fondus par matériau et par case de 32 m ;
- archives : fondues par matériau et par case de 12 m (une salle) ;
- deux matériaux identiques de modèles différents d'un même kit comptent pour un, et les matériaux sans texture passent
  leur couleur dans les sommets ;
- rien ne s'efface au loin et chaque objet garde son ombre : l'écran ne change pas ;
- restent à part :
  - les bannières (`flag_*`), que `plaine_life.gd` fait onduler ;
  - ce que porte un nœud scripté : livres à fouiller, panneaux, textes, tablette, dalle, livre ;
  - les MultiMesh (livres des rayonnages, feuillets, dispersion) ;
- les collisions ne bougent pas.

La suie (`soot.gdshader`) suit la position dans le monde : elle tombe au même endroit sur un maillage fondu.

## Comptes (tout le niveau)

| | Avant | Après |
| --- | --- | --- |
| Nœuds | 4 721 | 4 145 |
| Maillages | 758 | 400 |
| Qui projettent une ombre | 839 | 481 |
| MultiMesh (instances) | 162 (2 319) | 162 (2 319), inchangés |
| Lumières (ombres) | 19 (1, le soleil) | 19 (1), inchangées |
| Formes de collision | 3 265 | 3 265, identiques une à une |
| Chargement (premières images comprises) | 6 949 ms | 8 765 ms |

## Vues : appels de dessin et temps d'image médian (llvmpipe)

| Vue | Appels avant | Appels après | Image avant | Image après | Primitives avant | Primitives après |
| --- | --- | --- | --- | --- | --- | --- |
| o1 arrivée (0 ; 54) | 1 308 | 902 | 636 ms | 465 ms | 127 754 | 132 810 |
| o2 pont | 878 | 584 | 633 ms | 482 ms | 109 227 | 113 746 |
| o3 façade | 1 047 | 725 | 645 ms | 483 ms | 87 890 | 90 458 |
| o4 campement | 458 | 358 | 562 ms | 392 ms | 78 520 | 85 029 |
| o5 engins de siège | 956 | 708 | 640 ms | 352 ms | 74 916 | 81 276 |
| o6 batterie | 292 | 274 | 613 ms | 314 ms | 57 962 | 58 194 |
| o7 vue haute | 949 | 639 | 580 ms | 351 ms | 132 664 | 135 965 |
| i1 salle de lecture | 460 | 169 | 312 ms | 172 ms | 59 120 | 62 288 |
| i2 scriptorium | 310 | 117 | 285 ms | 166 ms | 46 350 | 48 366 |
| i3 archives | 159 | 68 | 196 ms | 150 ms | 32 146 | 34 714 |

- Dehors : 25 à 35 % d'appels en moins (6 % à la batterie, peu garnie). Il en reste beaucoup, car le soleil redessine
  chaque objet qui projette une ombre dans ses 4 tranches.
- Dans les archives : 2,3 à 2,7 fois moins d'appels. La suie, qui doublait chaque surface, ne se dessine plus qu'une
  fois par lot.
- Les primitives montent de 2 à 8 % : un lot se dessine en entier dès qu'une partie est dans le champ. Sur une vraie
  carte graphique (WebGL), c'est le nombre d'appels qui coûte au processeur.

## Vérifications

- Captures figées aux mêmes 16 points avant et après (particules, scintillement des bougies, corbeaux et bannières
  arrêtés) :
  - dedans (5 points) et 7 des 11 points du dehors : écart moyen de 0 à 0,04 sur 255, au plus 0,04 % de pixels changés ;
  - pont (3,47 %), vue haute (1,10 %), engins de siège (0,59 %), batterie (0,03 %) : les planches montrent que seules
    la lave et la lueur des fissures du sol changent ; leurs shaders suivent le temps (`TIME`), que la capture
    n'arrête pas ;
  - aucun objet disparu, déplacé ni éclairé autrement.
- Sous les pieds (`collisions.gd`), avant et après identiques :
  - 3 265 formes de collision, empreinte du relevé trié `100d7f9e10f417cca8391282535a7030` ;
  - grille de marche : 30 962 cases dehors et 2 348 dans les archives, empreinte `35c814a6936278a221bdbb5db1d9569d`.
- Tests : `plaine_puzzle_test` et `signboard_test` à 0 échec.

## Essai : soleil en 2 tranches d'ombre (non retenu)

Le Marais est passé de 4 à 2 tranches. Pour la Plaine, j'ai mesuré plusieurs réglages sans toucher à la scène, avec
`perf.sh … --sun=mode,distance[,tranche1[,biais,biais normal]]`, sur le décor déjà regroupé (commit 339ce57).
Les passages ont été faits l'un derrière l'autre, sur un serveur presque libre.

| Vue | 4 tranches, 70 m (actuel) | 2 tranches, 50 m | 2 tranches, 70 m | 2 tranches, 70 m, 1re tranche 0,25 |
| --- | --- | --- | --- | --- |
| o1 arrivée | 902 (371 ms) | 558 (309 ms) | 588 (302 ms) | 665 (315 ms) |
| o2 pont | 583 (384 ms) | 388 (316 ms) | 400 (308 ms) | 421 (322 ms) |
| o3 façade | 725 (378 ms) | 398 (314 ms) | 429 (296 ms) | 482 (311 ms) |
| o4 campement | 358 (312 ms) | 283 (255 ms) | 282 (254 ms) | 293 (260 ms) |
| o5 engins de siège | 708 (352 ms) | 382 (279 ms) | 414 (276 ms) | 467 (289 ms) |
| o6 batterie | 274 (312 ms) | 162 (241 ms) | 166 (244 ms) | 192 (255 ms) |
| o7 vue haute | 639 (359 ms) | 509 (413 ms) | 545 (307 ms) | 548 (312 ms) |

Chaque case donne les appels de dessin, puis l'image médiane entre parenthèses. Dans les archives, rien ne change
(aucune ombre) : 169, 117 et 68 appels.

Le gain est net : 30 à 45 % d'appels en moins dehors, et environ 20 % de temps d'image en moins.

Le réglage n'est pas retenu, car le rendu se dégrade à hauteur d'yeux :
- avec 2 tranches, le sol proche du joueur se couvre de fines bandes et d'anneaux de moiré (crénelage de l'ombre),
  bien visibles devant la façade et devant les engins de siège ;
- avec 4 tranches, ce même sol reste lisse ;
- à 50 m, les ombres lointaines s'arrêtent aussi plus tôt : écart plus fort aux tombes (1,49 sur 255) et vers le loin.

J'ai essayé trois corrections, sans succès :

| Réglage essayé, en plus de 2 tranches à 70 m | Appels à l'arrivée | Bandes |
| --- | --- | --- |
| 1re tranche à 0,25 | 665 | atténuées, toujours visibles |
| biais normal 2,0 (au lieu de 1,0) | 588 | toujours là |
| biais 0,3 (au lieu de 0,1) | 588 | toujours là |

Les ombres des ruines et des engins restent lisibles et rien ne flotte dans ces essais ; seul le sol se dégrade.

Piste pour reprendre :
- adoucir le filtrage des ombres (`soft_shadow_filter_quality` du projet, fichier interdit aux agents de lieu) ;
- ou essayer `directional_shadow_blend_splits` et une première tranche plus courte, puis regarder les mêmes vues au
  sol, de près.

## Chargement : sol et zone de lave calculés d'avance (5 novembre)

### Principe (commit 2debc5e)

Avant, chaque chargement recalculait le sol et la zone de lave, soit environ 4 s rien que dans les `_ready`.

`frontend/tools/bake_plaine.gd` fait ces calculs une fois, avec les fonctions mêmes du chargement. Il écrit
`scenes/levels/plaine/plaine_bake.res` (`PlaineBake`, 799 901 octets compressés), qui contient :
- les hauteurs de la grille du sol ;
- le niveau de la lave de chacun des 7 cratères ;
- le maillage du sol, soit 110 976 sommets, sans matériau ;
- les 2 634 bandes de la zone qui brûle (centre et taille de chaque boîte).

Au chargement :
- **Le sol (`PlaineTerrain`)** est lu tel quel si `is_baked()` est vrai, c'est-à-dire si trois conditions sont
  remplies :
  - même empreinte des réglages (`settings_signature()`, md5 des constantes : cratères, trous d'obus, coulée,
    chemin, replats, couleurs, graine et fréquence du bruit) ;
  - même niveau de lave dans chaque cratère ;
  - mêmes hauteurs, à 1 mm près, en 6 points témoins de la grille.

  Sinon, il est recalculé comme avant, avec l'avertissement « sol calculé d'avance périmé ». Sa collision vient
  des sommets du maillage lu.
- **La zone qui brûle (`PlaineScatter`)** est lue si le sol est à jour et si `hazard_signature()` correspond (sol,
  plus `HAZARD_STEP`, `HAZARD_DEPTH` et `HAZARD_LENGTH`). Sinon, elle est recalculée, avec l'avertissement « zone de
  lave calculée d'avance périmée ».
- **L'`Area3D` de la lave** n'entre dans le monde qu'une fois ses 2 634 bandes posées. Avant, chaque bande ajoutée
  à une zone déjà dans le monde faisait recalculer toutes les autres, soit 2 s à elle seule.

### Contrôle sur `dev` 0c8c89c

Depuis le matin, `dev` a reconstruit la bibliothèque, donné une collision aux lanternes et ajouté le volcan
« distant ». Le relief et la zone qui brûle n'en dépendent pas :
- `git diff 2debc5e 0c8c89c` ne touche pas `plaine_terrain.gd` ;
- dans `plaine_scatter.gd`, il ne touche que `_add_lanterns()`.

Résultat du précalcul :
- relancé deux fois, `bake_plaine.gd` écrit un fichier identique octet pour octet à celui de 2debc5e (md5
  `0b608a5863bf90eb2b5f412798bc530f`) ;
- `-- --check` répond « données d'avance à jour », avec le code de sortie 0 ;
- la ressource n'avait donc pas à changer.

Avec ce précalcul, aucun chargement n'affiche d'avertissement « périmé » : ni les mesures, ni les tests, ni le paquet
exporté comme la production (`docker build`, puis `--main-pack`).

### Temps de chargement, `dev` seul contre la branche

Les mesures viennent du serveur (arm64, 4 cœurs), avec `perf/profile_load.gd` (`-- 3` : trois chargements de
suite, sans écran) et `~/cdp-dev/.claude/captures/outils/perf_web.gd` (fenêtre sous Xvfb). Pour `dev`, une worktree
détachée sur 0c8c89c a servi de référence.

| Mesure | `dev` seul | Branche |
| --- | --- | --- |
| `profile_load`, sans écran, 1er essai (lecture + instance + `_ready` + 2 images) | 4 971 ms | 898 ms |
| `profile_load`, essais 2 et 3 (`_ready` seul) | 4 318 et 4 303 ms (4 271 et 4 255 ms) | 392 et 383 ms (343 et 332 ms) |
| `perf_web.gd`, Xvfb, llvmpipe, Compatibility (jusqu'à la 2e image) | 6 636 ms | 4 309 ms |
| `perf_plaine.gd`, même mesure, serveur chargé (charge 12 sur 4 cœurs) | 11 336 ms | 5 092 ms |
| Paquet exporté (`docker build`), `profile_load` sans écran, serveur chargé | non mesuré | 1 233 ms, puis 632 et 554 ms |

Lecture des chiffres :
- les `_ready` de la Plaine passent de 4,3 s à 0,34 s, soit 12 fois moins ;
- le chargement complet sans écran passe de 5,0 s à 0,9 s ;
- avec une fenêtre, environ 3,9 s ne bougent pas. Elles viennent de la mise en route du rendu logiciel et de la
  compilation des shaders par llvmpipe, que le précalcul ne touche pas. Le gain y reste de 2,3 s, soit 35 %.

Le dessin ne change pas :
- `perf_web` donne 454 appels en moyenne des deux côtés ;
- dans la pire direction, il donne 981 appels contre 980, en moyenne sur 20 images. L'empreinte est identique (plus
  bas), donc cet écart d'une unité vient de ce qui bouge pendant la mesure : particules, corbeaux, bannières ;
- `perf_plaine` donne 966 appels à l'arrivée des deux côtés.

### Rendu et collisions : empreinte exacte

`perf/fingerprint.gd` a été lancé sous Xvfb pour lire les tampons des MultiMesh. Il relève toutes les formes de
collision et tous les objets dessinés :
- pour chaque forme, sa transformation exacte et ses données ;
- pour chaque objet, sa transformation, ses ombres, sa portée, ses matériaux, les tableaux de chaque maillage et les
  tampons des MultiMesh.

| | `dev` seul | Branche |
| --- | --- | --- |
| Collisions | 3 272 lignes, `e09a35cd3d261f2f1f68f5b29bf2446c` | identiques |
| Dessin | 570 lignes, `efe66460e8bc0acf3c8d9f9d6096c5f7` | identiques |

Les fichiers sont identiques octet pour octet. Ils comprennent en particulier :
- les 2 634 bandes de `LavaHazard` ;
- la forme concave du sol (`7d099f563095787e061d70d07fa64dd4`) ;
- les tableaux du maillage du sol.

Les empreintes du matin (3 264 et 583 lignes) ne servent plus de référence, car `dev` a changé entre-temps. La
comparaison porte sur le même état.

### Captures

Elles ont été prises aux 9 mêmes points avant et après, figées : `perf/shots_bake.txt`, avec `perf_plaine.gd` et
`--shots`. Les points sont l'arrivée, trois cratères et la coulée, la vue haute, la bibliothèque dehors, la salle de
lecture, le scriptorium et les archives.

Les écarts ont été mesurés avec `perf/diff_images.gd` :

| Point | Écart moyen (sur 255) | Pixels changés |
| --- | --- | --- |
| Arrivée | 0,02 | 0,02 % |
| Bibliothèque dehors | 0,00 | 0,00 % |
| Salle de lecture | 0,00 | 0,00 % |
| Scriptorium | 0,00 | 0,00 % |
| Archives | 0,00 | 0,00 % |
| Cratère ouest et coulée | 5,60 | 6,40 % |
| Cratère est et coulée | 5,23 | 6,56 % |
| Cratère sud | 1,64 | 2,25 % |
| Vue haute | 0,78 | 0,95 % |

Les écarts des cratères ne viennent que de la lave. Les planches montrent que seules la surface de la lave et la lueur
des fissures changent : leurs shaders suivent `TIME`, que la capture n'arrête pas. Aucun objet n'a disparu, bougé ni
changé d'éclairage. La bibliothèque, dehors comme dedans, est identique au pixel près.

### Tests (branche)

- `plaine_puzzle_test` : 0 échec.
- `timer_test` : 0 échec.
- `music_test` : 0 échec.
- `tree_collision_test` en mode fenêtre : Plaine, 38 arbres, 0 sans collision.
- `run_tests.tscn` : 51 réussis, 0 échec.
- `perf/lave_test.gd` : 0 échec, en 18 contrôles.
  - La zone qui brûle compte 2 634 bandes et elle est dans le monde.
  - Le sol sec de l'arrivée ne brûle pas.
  - Le joueur est posé au-dessus de chacun des 7 lacs, puis de la coulée. Il brûle, reçoit le message « La lave
    vous brûle », puis revient à son dernier endroit sûr.
- Aucun de ces tests n'affiche d'avertissement « périmé ».

## Garde-fou : quand le précalcul est périmé

### Commande à relancer

Il faut la relancer après tout changement de `plaine_terrain.gd`, par exemple le relief, les cratères, les trous
d'obus, la coulée, le chemin, les replats, les couleurs ou le maillage. Il faut aussi la relancer après tout
changement de la zone qui brûle dans `plaine_scatter.gd` : `lava_hazard_strips()`, `_hazard_strip()`,
`lava_surface_at()` ou `HAZARD_*`.

```
cd frontend
~/cdp-work/bin/godot --headless --path . --audio-driver Dummy --script res://tools/bake_plaine.gd -- --api=http://127.0.0.1:9/api/v1
~/cdp-work/bin/godot --headless --path . --audio-driver Dummy --script res://tools/bake_plaine.gd -- --check --api=http://127.0.0.1:9/api/v1
```

Le premier appel écrit `scenes/levels/plaine/plaine_bake.res`, en 2 s environ. Le second doit répondre « données
d'avance à jour », avec le code de sortie 0. Il faut ensuite commiter `plaine_bake.res` avec le changement.

Deux passages écrivent le même fichier. Si `git status` ne montre pas `plaine_bake.res`, c'est qu'il était déjà à
jour.

### Essai du repli, sans rien commiter

Le script `perf/repli.sh <worktree> <sortie>` remet les fichiers en place à la fin, avec `git checkout`.
Ensuite, `--check` répond de nouveau « à jour ».

1. **Un réglage change sans que le bake soit relancé.** Le cratère 6 passe de 2,0 à 2,2 m de profondeur.
   - `--check` sort en erreur : « DONNÉES D'AVANCE PÉRIMÉES ».
   - Au chargement, deux avertissements s'affichent : « sol calculé d'avance périmé » et « zone de lave calculée
     d'avance périmée ».
   - Tout est recalculé. Les `_ready` prennent 2,4 s, contre 4,3 s sur `dev`, car l'`Area3D` posée d'un coup reste
     un gain.
   - Le jeu reste correct :
     - `lave_test` passe à 0 échec, avec 2 645 bandes au lieu de 2 634, puisque le lac est plus profond ;
     - l'empreinte du repli (3 283 collisions, `e404aaab…` ; 570 objets dessinés, `2a6bf333…`) est identique, fichier
       pour fichier, à celle obtenue après avoir relancé le bake avec ce réglage.
   - Une fois le bake relancé, le chargement ne montre plus d'avertissement et les `_ready` retombent à 0,7 s, sur un
     serveur chargé.
2. **Le code du relief change, sans toucher aux réglages.** Le bruit passe de × 0,8 à × 0,9.
   - L'empreinte des réglages ne voit rien.
   - Les niveaux de lave ou les points témoins, eux, s'écartent : les deux avertissements s'affichent et tout est
     recalculé.
   - `--check` sort en erreur.
3. **Le code de la zone qui brûle change.** Le bas des bandes passe de - 0,4 à - 0,5 m.
   - **Au chargement, rien ne le voit** : aucune vérification ne porte sur le code des bandes, et les anciennes
     bandes sont utilisées.
   - Seul `--check` le voit et sort en erreur.

Conclusion :
- le repli fonctionne, et il donne exactement le résultat d'un bake relancé ;
- il se déclenche quand un réglage change ou quand le relief change ;
- il ne se déclenche pas quand seul le code des bandes de lave change (cas 3). Dans ce cas, seul `--check`
  protège, et il faut le lancer avant de livrer.

## Reste à faire

- Soleil en 2 tranches : voir l'essai plus haut, il faut d'abord se débarrasser des bandes au sol.
- Faire lancer `tools/bake_plaine.gd -- --check` par `tests/scenes/run_all.sh`, ou relancer le bake dans
  `frontend/Dockerfile` avant l'export. Ces fichiers sont interdits aux agents de lieu. Sans cela, un changement du
  seul code des bandes de lave (cas 3 du garde-fou) passerait en production avec des bandes périmées.
- `MaraisBatch` et `PlaineBatch` gagneraient à devenir un seul outil partagé dans `scripts/`, interdit aux agents de
  lieu.
