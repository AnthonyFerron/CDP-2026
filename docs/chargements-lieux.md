# Chargement des lieux : calculs faits d'avance

## Le problème

Un joueur qui découvre le jeu attend à chaque entrée dans un lieu. Le relevé de `docs/web-threads.md` (Chromium, rendu logiciel) donnait 69 s pour le Village, 56 s pour le Désert, 47 s pour le Marais, 18 s pour le hub.

Les shaders sont déjà préparés au menu (`docs/shaders-menu.md`). Restait le travail du processeur : lire la scène, l'instancier, puis le `_ready` de chaque nœud, dont plusieurs calculent leur sol et leur décor à chaque chargement.

## Où part le temps

### En natif

Outil : `frontend/tools/profile_load.gd`. Un lieu par lancement, à froid, sans écran :

```
cd frontend && godot --headless --path . --script res://tools/profile_load.gd -- <lieu> [--images N] --api=http://127.0.0.1:9/api/v1
```

Il donne la lecture de la ressource, l'instanciation, le `_ready` de chaque nœud (les plus chers d'abord) et les premières images. Avant ce changement (serveur arm64, mesures à froid) :

| Lieu | Poste | Temps |
| --- | --- | --- |
| Hub | `_ready` du sol (`HubTerrain`) | 790 ms |
| Hub | lecture de la scène et de ses ressources | 660 ms |
| Hub | `_ready` du décor dispersé (`HubScatter`) | 175 ms |
| Hub | `_ready` de la rivière | 68 ms |
| Désert | lecture de la scène | 527 ms |
| Désert | `_ready` du décor dispersé (`DesertScatter`) : cactus et rochers surtout | 344 ms |
| Désert | `_ready` du sol (`DesertTerrain`) | 285 ms |
| Désert | `_ready` de la racine : teinte, collisions des ruines, regroupement | 92 ms |
| Village | lecture de la scène | 519 ms |
| Village | `_ready` du décor dispersé (`VillageScatter`) : collisions des arbres et des rochers surtout | 320 ms |
| Village | `_ready` du sol (`VillageTerrain`) | 216 ms |
| Marais | lecture de la scène | 472 ms |
| Marais | `_ready` de la racine : regroupement du décor (`MaraisBatch`), 218 ms dehors et 87 ms dans la crypte | 288 ms |
| Marais | `_ready` du sol (`MaraisTerrain`) | 177 ms |
| Marais | `_ready` de la vie (`MaraisLife`) : 127 ms pour les grenouilles | 145 ms |
| Marais | `_ready` du mécanisme gravé | 59 ms |
| Plaine | lecture de la scène | 594 ms |
| Plaine | `_ready` de la racine : regroupement du décor | 174 ms |
| Plaine | `_ready` du décor dispersé | 112 ms |

La lecture de la scène est surestimée ici : à froid, elle compte aussi le joueur, l'interface et leurs scripts. En jeu, le joueur vient du hub, et ces ressources sont déjà en mémoire. Lu depuis le paquet exporté (`index.pck`) après le hub, un lieu se lit en 130 à 200 ms.

### Dans Chromium

Banc : un export de mesure (le `Dockerfile` du jeu, plus un pilote jamais livré), servi par le vrai Caddyfile, et Chromium sans écran, une mesure à la fois. Le pilote va du menu au lieu par la vraie transition, et relève chaque image de la demande à l'arrivée : physique, traitement, appels différés, dessin. Les outils sont dans `.claude/captures/perf-chargements/outils/` (hors dépôt).

Village, avant (préparation des shaders retirée) :

| Étape | Temps |
| --- | --- |
| Écran noir et titre | 2,5 s |
| Lecture de la scène (`ResourceLoader.load`) | 1,9 s |
| Instanciation | 0,24 s |
| Ajout à l'arbre et `_ready` | 2,3 s |
| Première image, sous le titre : dessin, dont 7,8 s de compilation de shaders | 8,9 s |
| Image où la pause se lève : tout dans le dessin, aucune compilation relevée | 41,9 s |
| Fondu de sortie, 5 images | 10 s |

L'image où la pause se lève est la « très longue image » déjà vue par l'agent des shaders. Elle se passe entièrement dans le dessin, sans compilation de shader côté WebGL : c'est SwiftShader, le rendu logiciel de Chromium, qui rattrape le travail des images précédentes et compile ses propres programmes au premier dessin. Une vraie carte graphique ne fait pas ce travail. Le temps du processeur côté jeu (lecture, instanciation, `_ready`) pèse ici 4,4 s.

## Ce qui a changé

### Calculs d'avance (`LevelBake`)

Ce que les lieux calculaient à chaque chargement, de façon déterministe, est calculé une fois par `frontend/tools/bake_lieux.gd`, et rangé dans `scenes/levels/<lieu>/<lieu>_bake.res` (`LevelBake`, `frontend/scripts/level_bake.gd`) :

| Lieu | Partie | Contenu |
| --- | --- | --- |
| Village | `village/sol` | hauteurs de la grille, couleur de chaque case |
| Village | `village/decor` | herbes, gravats, arbres, rochers, arbres de la bordure : positions, et points de chaque collision |
| Désert | `desert/sol` | hauteurs, couleur de chaque triangle |
| Désert | `desert/decor` | cactus, rochers, ruines : positions, collisions, état du tirage pour la suite |
| Hub | `hub/sol` | hauteurs (rivière et étangs creusés), distance au bord de l'eau, couleur de chaque case |
| Hub | `hub/decor` | arbres, forêt, buissons, rochers, fleurs : positions et cylindres de collision |
| Marais | `marais/sol` | hauteurs, couleur de chaque case |
| Marais | `marais/decor` | jeu des planches des pontons, arbres (et leurs cylindres de collision), roseaux, nénuphars, fleurs, buissons, champignons, troncs noyés : positions |
| Plaine | `plaine/decor` | herbes, cailloux, gros rochers, arbres morts, rochers des remparts : positions ; état du tirage pour les arbres morts et les lanternes (fichier `plaine_decor_bake.res`) |

Les fichiers pèsent 1 344 Ko (Village, dont 1 127 Ko pour les points des collisions des arbres et des rochers), 323 Ko
(Désert), 410 Ko (hub) et 117 Ko (Marais). Ils sont enregistrés sans compression : le paquet du jeu est compressé en
entier pour le web, et brotli les ramène à 731 Ko pour les quatre lieux (845 Ko s'ils étaient déjà compressés par
Godot). Le décor du Marais (`marais/decor`, 37 Ko) est venu ensuite : son fichier passe à 154 Ko, et le paquet du jeu
grossit de 26 Ko en brotli (10 366 143 à 10 392 106 octets, export de mesure).

Au chargement, chaque nœud lit sa partie, puis pose ses nœuds exactement comme avant : le maillage du sol, sa collision, les MultiMesh et les formes de collision du décor. Le calcul en direct est gardé : il sert si la partie manque ou ne correspond plus, et c'est lui que l'outil relève.

- **Le sol** (`TerrainGrid`, `frontend/scripts/terrain_grid.gd`). Les hauteurs et les couleurs sont la partie lente (bruit, masques, rivière). Le maillage est ensuite assemblé par une boucle commune, déroulée, deux fois plus rapide que l'ancienne et qui donne les mêmes tableaux. Les couleurs sont rangées en octets RGBA8 : le moteur range de toute façon les couleurs de sommets ainsi, en tronquant (vérifié sur 30 000 couleurs), et b / 255 redonne l'octet b. Le maillage ne change pas d'un bit, et les données du sol du Village pèsent 149 Ko, contre 2,7 Mo pour son maillage entier.
- **Le décor dispersé.** Chaque script de décor dispersé (`*_scatter.gd`) sépare désormais le calcul (`_plan`, qui rend positions et collisions) de la pose des nœuds (`_build`). Le Désert garde l'état de son tirage au hasard après les cactus, rochers et ruines : les épaves, objets et ossements, posés en direct, tombent aux mêmes places.

### Périmé ou à jour

Chaque partie porte deux empreintes :

- celle des réglages : les constantes du script, ses propriétés exportées (modèles, nombres, matériaux par leur fichier), et celles du sol pour le décor. Elle est vérifiée partout, jeu exporté compris ;
- celle du code des scripts qui la calculent. Elle est vérifiée quand le code est lisible : éditeur, tests, outils. Le jeu exporté n'a plus le texte des scripts.

Le sol vérifie aussi quelques hauteurs recalculées (comme la Plaine), et le décor ne lit sa partie que si son sol a lu la sienne.

Une partie périmée ou absente est recalculée au chargement, comme avant, avec un avertissement (« Calcul d'avance … périmé, relancer tools/bake_lieux.gd »). Un test lancé après un changement de code calcule donc en direct : il voit le nouveau code, jamais une donnée périmée.

### Régénérer

```
cd frontend && godot --headless --path . --script res://tools/bake_lieux.gd [-- <lieu> ...]
```

Sans lieu, il refait les cinq (la Plaine pour son décor dispersé seulement). Deux passages écrivent le même fichier. Avec `-- --check`, rien n'est écrit : l'outil compare chaque fichier au calcul et sort en erreur s'ils diffèrent. C'est le contrôle `bake_lieux_check` de `frontend/tests/scenes/run_all.sh`.

À relancer après tout changement :

- du relief ou des couleurs d'un sol (`*_terrain.gd`) ;
- du décor dispersé (`*_scatter.gd`), de ses modèles ou de ses nombres dans la scène (`write_<lieu>_tscn.py`) ;
- d'une collision posée par ces scripts.

Les collisions écrites par les générateurs (`build_<lieu>.py`, les `*_props.tscn`) ne sont pas dans ces fichiers : les changer ne demande rien.

### Marais : les bêtes

`MaraisLife` taillait chaque grenouille, chaque corbeau et chaque chauve-souris pièce par pièce (sphères, boîtes, matériaux), puis les fondait en un maillage (`MaraisBatch`) : 6 ms par grenouille. La première de chaque espèce est toujours taillée ainsi ; les suivantes sont des copies de ce modèle, prises avant qu'il soit placé, qui partagent ses maillages et ses matériaux. Chaque copie garde ses propres ailes et sa tête (vérifié : 6 corbeaux, 7 chauves-souris, 12 ailes distinctes).

### Marais : la crypte après l'arrivée

Le `_ready` de la racine du Marais (`marais.gd`) fondait tout le décor fixe (`MaraisBatch`) : 292 ms en natif, dont
77 ms pour la crypte. Le mécanisme gravé (`ring_mechanism.gd`), lui aussi dans la crypte, taillait ses 26 lettres et
gravait ses 5 cercles : 62 ms. Deux changements, au même résultat (empreintes identiques, plus bas) :

- **Les signatures des matériaux.** Pour ranger chaque surface dans son lot, `MaraisBatch` décrit son matériau par ses
  réglages : la liste de ses propriétés stockées (`get_property_list`), chacune avec sa valeur. Cette description
  coûtait l'essentiel du regroupement (133 ms sur 285 ms) : 129 matériaux distincts dans le Marais (chaque modèle
  Kenney a le sien), pour 12 descriptions distinctes. Elle n'est plus faite qu'une fois par état de matériau : l'état
  est la valeur de chaque propriété de sa classe (lue directement), avec son script et ses métadonnées. Deux matériaux
  dans le même état ont la même liste de propriétés stockées et les mêmes valeurs, donc la même description. Vérifié
  sur les 129 matériaux : mêmes groupes. Le regroupement des bêtes (`MaraisLife`) en profite aussi (36 à 18 ms).
- **La crypte se prépare après l'arrivée.** Cachée tant qu'on est dehors (`Interior` invisible), elle n'est plus
  préparée au chargement. À partir de la première image où la partie n'est plus en pause (la transition se lève),
  `marais.gd` la prépare par tranches : à chaque image, il enchaîne les pas jusqu'à dépasser 8 ms
  (`CRYPT_BUDGET_MSEC`, comme le hub), dans l'ordre : la teinte des dalles, le regroupement du décor de la crypte,
  des tombeaux des rois et des niches (`MaraisBatch.step`, un modèle examiné puis un lot bâti à la fois), puis les
  lettres du mécanisme (`RingMechanism.engrave`, une lettre taillée puis un cercle gravé à la fois). Les collisions de la crypte ne sont pas touchées : celles du décor sont dans la scène, et le cône
  du mécanisme est posé à son `_ready`, comme le socle et les cercles. En natif, la préparation tient en 8 à 18
  images. Si le joueur descend avant (il lui faut traverser le marais), elle finit d'un coup sous le noir du fondu
  (`_apply_location`), de même quand on ouvre le mécanisme. `is_done()` dit si elle est finie : l'outil d'empreinte et
  l'inventaire des shaders (`bake_shaders.gd`) l'attendent.

Le dehors, vu à l'arrivée, est toujours fondu au chargement.

### Regroupements : un seul outil (`DecorBatch`)

Branche `perf/regroupements` (9 novembre), partie de `dev` 7488297.

- **Un outil commun.** `MaraisBatch` (Marais : dehors, crypte, bêtes) et `PlaineBatch` (sa copie, avec des modèles
  laissés à part) deviennent un seul outil, `DecorBatch` (`frontend/scripts/decor_batch.gd`). Ce qui est propre à
  chaque lieu se passe à l'appel : taille des cases, ombres, profondeur, effacement au loin, et préfixes des modèles
  laissés à part (`skip` : les bannières de la Plaine, que `plaine_life.gd` fait onduler). Le regroupement par étapes
  (`step`) de la crypte du Marais est le même. Les deux anciens scripts sont retirés.
- **Le hub** garde ses propres règles (`hub_batch.gd` : groupes réparables, modèles posés seulement, ombres fondues
  par case, MultiMesh à part, panneaux) et prend à l'outil commun la signature des matériaux et leur peinture dans
  les sommets (`DecorBatch.signature`, `painted_material`, `painted_mesh`, `paintable`, `glows`).
- **Les signatures une fois par état de matériau**, comme dans le Marais (plus haut), servent désormais au hub et à
  la Plaine : `hub_batch.gd` et `plaine_batch.gd` décrivaient chaque matériau par sa liste de propriétés. Le décor du
  hub en a 227 distincts pour 11 signatures (11 états), la Plaine 85 pour 11. Un matériau qui porte un script est
  décrit à chaque fois, les variables de son script n'étant pas dans l'état ; il n'y en a aucun aujourd'hui.
- **Mémoire vidée** quand le lieu se ferme : le Marais comme avant, le hub à la sortie de son décor (`_exit_tree` de
  `hub_batch.gd`), la Plaine après ses trois regroupements (faits à son `_ready`, rien d'autre ne se regroupe).

### Plaine : le décor dispersé d'avance

Branche `perf/hub-plaine` (9 novembre), partie de `dev` 6821059.

Le décor dispersé de la Plaine (`plaine_scatter.gd`) tirait au hasard, à chaque chargement, ses 1 500 herbes, 219
cailloux, 24 gros rochers, 38 arbres morts et 46 rochers des remparts, sur une dizaine d'étapes entremêlées (le même
tirage sert aux places, aux tailles, à la forme des arbres morts et aux lanternes renversées). Il est découpé comme les
autres : `_plan` tire tout dans le même ordre qu'avant et rend les places (les rochers déjà enfoncés dans la pente),
l'état du tirage avant les arbres morts (leurs trois maillages sont refaits à la pose depuis cet état, comme avant) et
l'état du tirage avant les lanternes ; `_build` pose les nœuds. Le plan est rangé dans `plaine/decor`, calculé par
`tools/bake_lieux.gd` comme les quatre autres lieux, dans son propre fichier
(`scenes/levels/plaine/plaine_decor_bake.res`, 95 636 octets) : `plaine_bake.res` est déjà celui du sol et de la zone
de lave (`PlaineBake`, `tools/bake_plaine.gd`). Il ne sert que si le sol de la Plaine a lu le sien (`is_baked`).

Au passage, chaque corps des rochers et des arbres morts reçoit ses collisions avant d'entrer dans le monde, comme la
zone de lave : ajoutées une à une à un corps déjà dans le monde, chacune lui faisait refaire sa forme (8 ms pour les
150 cailloux qui en ont une). L'ordre des nœuds et leurs noms ne changent pas.

Ne sont pas dans le plan : la zone de lave (déjà dans `plaine_bake.res`, mais ses 2 634 bandes restent des nœuds à
poser, environ 20 ms), les braises, fumées et lueurs des cratères, la coulée et les lanternes, qui ne tirent rien de
coûteux.

### Hub : le regroupement par pas, et seulement ce qui peut se voir

Trois changements dans `hub_batch.gd` et `decor_batch.gd`, au même résultat (empreintes plus bas) :

- **Les surfaces lues une fois, d'un coup.** Pour fondre un lot, `SurfaceTool.append_from` relisait la surface de
  chaque morceau (`surface_get_arrays`), et l'ombre de chaque case relisait chaque lot fondu. Sur le web, chaque
  lecture recopie un tampon de la carte graphique (`getBufferSubData`), et la première lecture d'une image attend en
  plus que la carte ait fini l'image précédente : dans Chromium, au hub, 23 579 lectures prenaient 58 des 60 s de
  travail du regroupement (plus bas, « Mesures »). Désormais :
  - chaque surface de modèle n'est lue qu'une fois (260 surfaces pour 5 064 morceaux au hub), et rendue telle quelle
    à l'outil par un petit maillage écrit en GDScript (`DecorBatch.Surface`, `DecorBatch.source`), qui lui rend les
    mêmes tableaux : les sommets fondus sont les mêmes, à l'octet près. Les copies peintes (94) sont relues une fois
    elles aussi : le moteur range leurs couleurs en octets, et c'est ce qu'il en rend que le lot doit prendre ;
  - le hub regroupe en deux vagues : les groupes qu'on voit, puis les autres. Dans une vague, tous les modèles sont
    examinés (rien n'y est lu), puis toutes leurs surfaces sont lues dans une même image (`DecorBatch.prefetch`),
    puis tous les lots sont assemblés, puis tous les lots sont relus dans une même image pour les ombres, puis les
    ombres sont assemblées et chaque groupe changé : deux attentes de la carte graphique par vague, au lieu d'une
    par image. L'ombre doit relire ses lots : reprendre leurs tableaux d'avant le rangement (sans relire) donne des
    normales et des tangentes compressées autrement, et les 376 ombres du hub changeaient (essayé, empreinte
    différente, abandonné).

  Le Marais et la Plaine, qui fondent par `DecorBatch`, lisent aussi chaque surface une fois, et la crypte du Marais,
  regroupée par étapes après l'arrivée, lit toutes les siennes dans une même image.
- **Par pas, et d'un coup.** Le hub regroupait un groupe entier par image (le décor fixe : 80 ms d'un bloc en natif).
  Il avance maintenant par pas, comme `DecorBatch.step` : un modèle examiné, un morceau ajouté à un lot, un lot fini,
  un lot ajouté à l'ombre d'une case, une ombre finie (et, deux fois par vague, une lecture groupée) ; chaque image
  enchaîne les pas pendant 8 ms (`BUDGET_MSEC`, inchangé) quand les images sont courtes. Quand elles sont longues de
  toute façon (le web en rendu logiciel : plus d'une seconde par image au hub), il prend jusqu'au quart de la plus
  courte des 4 dernières images, 250 ms au plus (`FRAME_SHARE`, `MAX_BUDGET_MSEC`) : il finit en bien moins
  d'images, sans les rallonger de plus d'un quart. Une image longue isolée (l'arrivée) n'y suffit pas, et à
  `--fixed-fps` (tests, outils) la part reste de 8 ms. Un groupe ne change qu'au dernier pas : ses maillages
  fondus y entrent quand ses modèles en sortent, dans la même image. On ne le voit jamais à moitié regroupé, et les
  collisions, qui sont dans ses nœuds `Collision`, ne sont jamais touchées. Ses règles ne changent pas (modèles posés
  seulement, ombres fondues par case, MultiMesh à part, pièces en coordonnées du monde) : elles restent dans
  `hub_batch.gd`, qui ne prend à l'outil commun que ce qui est commun.
- **Seulement ce qui peut se voir pendant la visite.** Chaque élément réparable a sa ruine et sa reconstruction, et
  le hub regroupait les deux à chaque chargement, donc à chaque palier de livres, alors qu'une seule se montre : à 0
  livre, les reconstructions cachées faisaient 63 % du travail, à 4 livres les ruines 39 %. Le hub dit au regroupement
  (`leave_aside`, depuis `Hub._unseen_repairs`) ce qui ne peut pas paraître pendant la visite : la ruine d'un élément
  déjà réparé (un livre posé le reste), la reconstruction d'un élément dont le palier dépasse les livres trouvés (on
  n'en trouve pas au hub). Ces groupes ne sont pas regroupés : ils restent cachés, tels quels, rien ne les dessine.
  S'ils paraissent quand même (l'aperçu d'une fin depuis le menu de debug), ils se regroupent aussitôt, d'un bloc,
  comme tout groupe caché qui paraît avant son tour. Les reconstructions qu'on peut encore voir (un livre en main, pas
  encore posé) sont regroupées comme avant, après ce qu'on voit.

La mémoire du regroupement (signatures, surfaces lues, copies peintes) est vidée quand tout ce qui est prévu est fait,
au lieu d'être gardée jusqu'à la sortie du hub.

### Ce qui n'a pas été précalculé

- **Les regroupements du décor** (Marais, Plaine, ruines du Désert). Ils fondent des centaines de modèles en maillages : précalculés, ils copieraient toute leur géométrie dans le paquet, plusieurs mégaoctets de plus à télécharger avant le menu. Mesuré pour le Marais : les 103 maillages fondus du dehors font 237 401 sommets, 7,9 Mo enregistrés (2,5 Mo en gzip), ceux de la crypte 3,2 Mo (0,75 Mo en gzip).
- **Les collisions des ruines du Désert** (enveloppes et triangles des modèles). Elles coûtent 18 ms, et elles dépendent de `desert_ruins.tscn`, que l'agent des sauts modifie.
- **Le décor de la Plaine**, au tirage au hasard entremêlé sur une dizaine d'étapes : précalculé depuis (plus haut,
  « Plaine : le décor dispersé d'avance »). Son sol et sa zone de lave l'étaient déjà (`bake_plaine.gd`).

## Vérifications

### Empreintes

`frontend/tools/fingerprint_level.gd` relève tout ce qui se dessine (maillages et leurs tableaux, MultiMesh et leur tampon, particules, textes, matériaux), tout ce qui arrête le joueur (chaque forme de collision et ses données exactes) et chaque lumière, avec leur place dans le monde, une ligne par objet, triée. Le tirage au hasard des bêtes est fixé, et le hub attend la fin de son regroupement :

```
cd frontend && godot --fixed-fps 60 --path . --script res://tools/fingerprint_level.gd -- <lieu> <fichier> --api=http://127.0.0.1:9/api/v1
```

Avec un écran (Xvfb sur le serveur) : sans écran, les tampons des MultiMesh ne sont pas lisibles.

| Lieu | Lignes | Avant | Après |
| --- | --- | --- | --- |
| Village | 2 143 | `4f43a4bd…` | identique |
| Désert | 1 556 | `3bb35f04…` | identique |
| Marais | 1 438 | `ae84ae8f…` | identique |
| Hub | 5 274 | dessin `e9abfc57…`, collisions `97acb2d2…` | identiques |

Pour le hub, seules changent l'intensité de deux lampes qui vacillent, comme entre deux relevés du même code : le regroupement du décor ne finit pas toujours à la même image.

### Captures

`.claude/captures/perf-chargements/outils/captures.sh` prend les mêmes vues de chaque lieu (vue haute, hauteur d'yeux,
bords) avant et après, et `diff_images.py` en fait des planches avant | après | écart (x 4). 17 vues, regardées une à
une :

| Lieu | Vues | Écart moyen (sur 255) | Pixels changés de plus de 24 |
| --- | --- | --- | --- |
| Village | haut, rue, moulin, ruisseau, bordure | 0 à 0,11 | 0 à 0,031 % |
| Désert | haut, arrivée, dunes, crêtes | 0 à 0,074 | 0 à 0,024 % |
| Marais | haut, arrivée, île, berge | 0,06 à 0,71 | 0,06 à 0,25 % |
| Hub | haut, place, rivière, montagnes | 0 à 0,022 | 0 à 0,008 % |

Les seuls écarts sont ce qui bouge avec le temps : fumées, braises, lucioles, feux follets, et dans le Marais l'eau et
la brume dont le shader suit l'horloge. Aucun objet, sol ou arbre ne bouge ni ne manque. Planches :
`.claude/captures/perf-chargements/captures/planches/` (hors dépôt).

### Tests

Suite complète (`frontend/tests/scenes/run_all.sh`), sur la branche à jour de `dev` :

- `bake_plaine_check`, `bake_lieux_check` et `bake_shaders_check` : à jour ;
- 0 échec partout, sauf `hub_walk_0` et `hub_walk_4` : 2 échecs chacun, les limites voulues
  (« limite infranchissable (doit echouer) ») ;
- `tree_collision_test` : mêmes comptes qu'avant (hub 670 arbres, dont 301 dans la forêt des montagnes, hors
  d'atteinte et sans collision ; Plaine 38, Désert 41, Marais 72, Village 130, tous avec leur collision) ;
- `run_tests` : 51 réussis, 0 échec ;
- aucun avertissement « Calcul d'avance … périmé » dans les journaux : chaque lieu a lu ses données.

Fusion d'essai avec `fix/sondes-saut` (agent des sauts), avant qu'elle n'entre dans `dev` : aucun conflit,
`bake_lieux_check` reste à jour (ses changements portent sur les scènes générées, pas sur les sols ni le décor
dispersé) et les générateurs ne produisent aucune dérive. La branche a ensuite reçu `dev` (83e4482 : sauts, sons,
interface) : un seul conflit, dans `write_hub_tscn.py` (une ressource ajoutée de chaque côté), résolu en gardant les
deux ; `hub.tscn` régénéré est celui de `dev` plus les trois lignes du calcul d'avance, et `bake_lieux_check` reste à
jour. Sur la branche fusionnée :

- empreintes de `dev` (83e4482) et de la branche identiques pour les quatre lieux, lignes comprises (Village
  `8c4132c6…`, Désert `de52a41c…`, Marais `ae84ae8f…`, hub `df6a632c…`) ;
- suite complète : les trois contrôles à jour, 0 échec partout (`music_test`, `hub_test` et le nouveau `sound_test`
  compris) sauf les 2 échecs voulus de `hub_walk_0` et `hub_walk_4`, `run_tests` à 51 réussis, aucun avertissement
  de calcul d'avance ;
- export de production refait : en-têtes identiques à l'image en service, `index.wasm` garde son ETag, revalidation
  en `304`.

### Marais : la crypte après l'arrivée

- **Empreintes** (`fingerprint_level.gd`, qui attend désormais aussi `is_done()` à la racine du lieu) : `dev` et la
  branche donnent la même, ligne pour ligne (`9f9b00b9…`, 1 438 lignes : 764 de dessin, 629 collisions, 23
  lumières), après chaque étape (crypte différée et signatures, décor calculé d'avance, nettoyage).
- **Captures** (`cam_shots.gd`, mêmes 18 vues avant et après : dehors l'arrivée, le débarcadère, le campement, le
  cimetière et son sud, l'îlot et la porte de la crypte, la vue haute ; dans la crypte l'escalier, l'entrée, la salle
  du mécanisme et son sud, les tombeaux des rois, la chambre est, l'ossuaire, les gardiens, le mécanisme et ses
  lettres), regardées une à une. Dans la crypte, aucun pixel ne change de plus de 24 (écart moyen de 0,1 à 1,3 sur
  255 : le vacillement des cierges) ; les lettres du mécanisme sont les mêmes. Dehors, écart moyen de 0,07 à 3,5 :
  lucioles (l'une passe devant la caméra à la porte de la crypte), feu de camp, feux follets, fumée du volcan, eau.
- **Pendant la préparation** : la vue d'arrivée prise à la 2e image (crypte pas prête) et 18 images plus tard (prête)
  ne diffère que par ce qui bouge (roseaux, lucioles, eau, fumée) : la préparation ne touche que la crypte, cachée.
- **Sonde de saut** (`docs/agents/marais/marais_jump_probe.gd`, crypte, pas de 0,5 m) : énigme résolue, 1 904 cases,
  30 464 sauts, 5 233 arrivées hors du sol accessible, 0 point coincé ; non résolue, 1 864 cases, 29 824 sauts, 5 275
  arrivées, 0 point coincé. Les mêmes chiffres que la sonde du 8 novembre.
- **Inventaire des shaders** (`bake_shaders.gd`, qui attend la crypte prête) : à jour, sans être régénéré.
- **Générateurs** : `build_marais.py` ne change rien ; `write_marais_tscn.py` ajoute seulement la ligne du calcul
  d'avance au décor dispersé, et relancé ne produit aucune dérive.
- **Suite complète** (`frontend/tests/scenes/run_all.sh`, depuis la branche) : `bake_plaine_check`,
  `bake_lieux_check` et `bake_shaders_check` à jour ; 0 échec partout, sauf `hub_walk_0` (les 2 échecs voulus,
  « limite infranchissable (doit echouer) ») ; `marais_puzzle_test` à 0 échec ; `tree_collision_test` : Marais,
  72 arbres, 0 sans collision ; `sound_test` à 0 ; `run_tests` à 52 réussis ; aucun avertissement de calcul d'avance.
  `hub_walk_4` n'avait pas démarré dans son délai (les trois places Godot étaient prises par les autres agents) :
  relancé seul, il a ses 2 échecs voulus, ni plus ni moins.

### Regroupements : un seul outil

- **Signatures, matériau par matériau** (`sig_bench.gd`, plus bas) : pour chacun des 227 matériaux du hub (à 0 et 4
  livres) et des 85 de la Plaine, `DecorBatch.signature` rend la même chaîne que l'ancienne description : 0
  différence. Les clés des lots sont donc les mêmes, et les lots aussi.
- **Empreintes** (`fingerprint_level.gd`, qui prend désormais `--livres N` : les N premiers livres trouvés et posés),
  `dev` (7488297) contre la branche :

  | Lieu | Lignes | Dessin | Collisions | Ensemble |
  | --- | --- | --- | --- | --- |
  | Hub, 0 livre | 6 017 | `31e77c57…` identique | `9a8fb697…` identique | 5 lumières qui vacillent |
  | Hub, 4 livres | 6 017 | voir plus bas | voir plus bas | 21 lignes, voir plus bas |
  | Plaine | 3 963 | `177450c3…` identique | `60a23d47…` identique | `b2041b36…` identique |
  | Marais | 1 438 | `571439cb…` identique | `dca801ca…` identique | `9f9b00b9…` identique |

  Au hub reconstruit (4 livres), 21 lignes du relevé diffèrent : 5 lumières qui vacillent, et 16 lignes d'objets qui
  ne diffèrent que par leur rotation, à la même place, avec le même maillage, le même matériau et la même forme : les
  villageois qui se tournent (`hub_villagers.gd`, maillage et cylindre de collision) et la roue du moulin. L'outil
  relève l'empreinte quand le regroupement a fini, qui finit maintenant quelques images plus tôt. Deux relevés de
  `dev` lui-même diffèrent de la même façon (20 lignes : 15 rotations, 5 lumières). Comparaison :
  `.claude/captures/perf-batch/outils/compare.py`.
- **Captures** (`captures.sh` : 6 vues du hub à 0 et à 4 livres, 11 de la Plaine dont 4 dans les archives, 11 du
  Marais dont 5 dans la crypte), avant | après | écart (x 4), regardées. Les appels de dessin relevés à chaque vue du
  hub sont les mêmes, au nombre près (de 95 à 631 à 0 livre, de 127 à 705 à 4 livres). Écart moyen de 0 à 0,4 sur
  255 au hub, de 0,05 à 0,76 dans la Plaine, de 0,05 à 1,5 dans le Marais ; au plus 0,9 % de pixels changés de plus
  de 24 (la porte de la crypte du Marais, où passent des lucioles). Les seuls écarts sont ce qui bouge : l'eau de la
  rivière, le feu, les villageois, la fumée du volcan, les braises et la lave de la Plaine, les lucioles et le feu de
  camp du Marais, la lueur des chandelles. Aucun objet ne bouge ni ne manque.
- **Générateurs et précalculs** : aucune scène générée ne change (`hub_props.tscn` garde `hub_batch.gd`), et
  `bake_plaine_check`, `bake_lieux_check` et `bake_shaders_check` restent à jour sans rien régénérer.
- **Suite complète** (`frontend/tests/scenes/run_all.sh`, depuis la branche, serveur chargé par les autres agents) :
  les trois précalculs à jour ; 0 échec partout (`hub_test`, `music_test`, `sound_test`, `gamepad_test`,
  `plaine_puzzle_test`, `marais_puzzle_test` compris), sauf `hub_walk_0` et `hub_walk_4` : 2 échecs chacun, les
  limites voulues (« limite infranchissable (doit echouer) ») ; `tree_collision_test` : mêmes comptes (hub 670 arbres
  dont 301 sans collision, Plaine 38, Désert 41, Marais 72, Village 130) ; `run_tests` : 52 réussis, 0 échec ; aucune
  erreur de script, aucun avertissement de calcul d'avance périmé.

### Plaine et hub : décor dispersé d'avance, regroupement par pas

« Avant » est `dev` (6821059), « après » la branche `perf/hub-plaine`.

- **Empreintes** (`fingerprint_level.gd`, sous Xvfb). Pour le hub, l'outil fait désormais regrouper aussi les groupes
  laissés de côté (`finish_all`) avant de relever : il compare tout le décor regroupé.

  | Lieu | Lignes | Dessin | Collisions | Ensemble |
  | --- | --- | --- | --- | --- |
  | Plaine | 3 963 | `177450c3…` identique | `60a23d47…` identique | `b2041b36…` identique |
  | Hub, 0 livre | 6 017 | `31e77c57…` identique | `9a8fb697…` identique | 5 lumières qui vacillent |
  | Hub, 2 livres | 6 017 | 1 ligne : la roue du moulin, tournée | `9a8fb697…` identique | 6 lignes |
  | Hub, 4 livres | 6 017 | voir plus bas | voir plus bas | 21 lignes |
  | Marais, relevé à la 90e image | 1 438 | `a24abd9b…` identique | `dca801ca…` identique | `2db0838d…` identique |

  La Plaine est identique avec le décor lu d'avance, puis avec les surfaces lues une fois. À 2 livres, la seule ligne
  de dessin qui change est la roue du moulin (`wheel.glb`, qui tourne) : même place, même maillage, même matériau,
  autre angle. À 4 livres, les 21 lignes sont celles qui diffèrent aussi entre deux relevés de `dev` (plus haut,
  « Regroupements : un seul outil ») : 5 lumières qui vacillent, et 16 lignes d'objets qui ne diffèrent que par leur
  rotation (les villageois qui se tournent, leur cylindre de collision, la roue du moulin) ; aucune autre
  (`compare.py`). Le Marais, relevé comme d'habitude (20 images), différait par ses bêtes animées et ses lumières :
  sa crypte se prépare plus vite, l'outil relevait donc plus tôt. Relevés tous deux à la 90e image, quand tout est
  prêt des deux côtés, ils sont identiques, ligne pour ligne.
- **Le hub tel qu'en jeu** (`--etat-jeu` : les groupes laissés de côté restent tels quels).
  Tout ce qui se dessine (`visible=true`), toutes les collisions et toutes les lumières sont ceux de `dev` : à 0 livre,
  4 905 lignes identiques sur 4 905, à part les 5 lumières qui vacillent ; à 4 livres, 5 148 lignes, dont les mêmes
  21 écarts de rotation et de vacillement que plus haut. Ne diffèrent que des lignes cachées (`visible=false`) : à 0
  livre, les 586 maillages fondus des reconstructions (avant) contre les 2 569 maillages de leurs modèles, laissés tels
  quels (après) ; à 4 livres, 414 contre 1 235 pour les ruines. Rien ne les dessine. Comparaison :
  `.claude/captures/perf-hub-plaine/outils/visibles.py`.
- **Captures** (`captures.sh` de `perf-batch`, mêmes vues avant et après : 6 vues du hub à 0, 2 et 4 livres, 11 de
  la Plaine dont 4 dans les archives), avant | après | écart (x 4), regardées. Les appels de dessin relevés à chaque
  vue du hub sont les mêmes (de 95 à 631 à 0 livre, de 127 à 705 à 4 livres ; un de plus sur la place à 4 livres,
  où passe un villageois). Écart moyen de 0 à 0,19 sur 255 au hub, sauf la vue vers les montagnes à 2 et 4 livres
  (0,85 : 1,3 % des pixels, tous dans l'eau de la rivière, dont les rides suivent l'horloge) ; de 0,05 à 1,2 dans la
  Plaine, au plus 0,07 % de pixels changés de plus de 24 (fumées, braises, lueur de la lave, chandelles des
  archives). Aucun objet ne bouge ni ne manque.
- **Pendant le regroupement** (`shots_pendant.gd`, hors dépôt : une vue fixe du hub à 4 livres, prise à la 1re,
  3e, 6e, 10e, 15e, 25e, 40e et 60e image, puis à la fin) : les appels de dessin passent de 3 031 à 567 (village vu
  de haut) et de 3 362 à 700 (place), et chaque capture ne diffère de la finale que de 0,1 à 0,3 % des pixels :
  l'eau, le feu, et, sur la place, un liseré posé au même plan qu'un mur, que le mur recouvre une fois fondu. `dev`
  montre le même passage (première image contre finale : 0,176 % des pixels ; sa première image est celle de la
  branche, sa finale aussi, à 0,002 % près) : il vient du regroupement d'origine. On ne voit jamais un groupe à
  moitié changé.
- **Chaque surface lue une fois** : sur 5 surfaces de modèles Kenney, fondues 40 fois chacune à des places, rotations
  et échelles tirées au hasard, `append_from` donne les mêmes tableaux, octet pour octet, depuis le maillage et depuis
  sa surface déjà lue. Relu, un lot fondu ne redonne pas ses normales et ses tangentes à l'identique, et des ombres
  bâties sans relire les lots changeaient (les 376 lignes d'ombre de l'empreinte du hub) : les ombres relisent donc
  toujours leurs lots, tous dans une même image.
- **Précalculs** : `bake_lieux_check` à jour pour les cinq lieux (la Plaine comprise : deux passages de
  `bake_lieux.gd -- plaine` écrivent le même fichier) ; `bake_plaine_check` à jour sans être régénéré. Aucun
  avertissement « Calcul d'avance … périmé ».
- **Inventaire des shaders** (`bake_shaders.gd`) : il relevait le hub au bout de 12 images, à demi regroupé (combien,
  selon la vitesse de la machine). Avec les vagues, aucun groupe n'y est encore changé : les matériaux des lots
  fondus (couleur dans les sommets), des ombres seules et des MultiMesh transparents en sortaient, et ne seraient plus
  préparés au menu. L'outil retient maintenant le regroupement pendant les 12 images, relève le hub tel qu'à
  l'arrivée, puis le fait regrouper en entier (`finish_all`) et relève à nouveau : il garde les deux états, qui se
  dessinent l'un après l'autre en jeu. `shader_warm_list.tres` régénéré : les mêmes 114 entrées que `dev`, dans un
  autre ordre ; le menu prépare les mêmes shaders. Deux passages donnent le même fichier.
- **Jeu exporté** (export de mesure du banc, plus bas) : aucun avertissement dans la console, la Plaine lit son décor
  d'avance (`plaine_decor_bake.res` est référencé par `plaine.tscn` : rien à ajouter à `include_filter`).
- **Suite complète** (`frontend/tests/scenes/run_all.sh`, depuis la branche, serveur chargé par les autres agents) :
  `bake_plaine_check`, `bake_lieux_check` et `bake_shaders_check` à jour ; 0 échec partout (`hub_test`,
  `music_test`, `sound_test`, `gamepad_test`, `plaine_puzzle_test`, `marais_puzzle_test` compris), sauf `hub_walk_0`
  et `hub_walk_4` : 2 échecs chacun, les limites voulues (« limite infranchissable (doit echouer) ») ;
  `tree_collision_test` : mêmes comptes (hub 670 arbres dont 301 sans collision, Plaine 38, Désert 41, Marais 72,
  Village 130) ; `run_tests` : 52 réussis, 0 échec ; aucune erreur de script, aucun avertissement de calcul d'avance
  périmé.

## Mesures

### En natif

`profile_load.gd`, sans écran, avant et après en alternance, trois passages chacun ; médianes, en millisecondes. Le
serveur était chargé par d'autres travaux (charge de 4 à 15) : les écarts d'un passage à l'autre atteignent 30 %, et
jusqu'au double pour le hub.

| Lieu | `_ready`, avant | `_ready`, après | Lecture, avant | Lecture, après | Total jusqu'au rythme stable, avant | après |
| --- | --- | --- | --- | --- | --- | --- |
| Village | 569 | 192 (-66 %) | 488 | 523 | 1 128 | 759 |
| Désert | 638 | 263 (-59 %) | 594 | 547 | 1 309 | 884 |
| Marais | 807 | 654 (-19 %) | 580 | 550 | 1 477 | 1 316 |
| Hub | 1 919 | 417 (-78 %) | 1 017 | 997 | 3 282 | 1 785 |

Sur un serveur plus calme, le `_ready` du hub passait de 1 184 à 386 ms. Ce qui reste, par lieu :

- Village : le sol 81 ms (assemblage du maillage 22 ms, collision du sol 49 ms : Jolt bâtit sa structure), le décor
  64 ms (les enveloppes convexes des arbres) ;
- Désert : le sol 87 ms, la racine 71 ms (teinte, collisions et regroupement des ruines), le décor 65 ms ;
- Marais : la racine 300 ms (regroupement du décor), le décor 77 ms, le mécanisme 66 ms, le sol 63 ms, la vie 38 ms
  (152 ms avant) ;
- Hub : le sol 99 ms, la rivière 79 ms, la racine 45 ms, le décor 33 ms.

Depuis le paquet exporté (`--main-pack`), le Désert passe de 760 à 263 ms de `_ready`, sans aucun avertissement : le
jeu exporté lit bien ses données d'avance. La lecture du Village prend environ 35 ms de plus : son fichier de données
pèse 1,3 Mo.

### Dans Chromium

Le banc décrit plus haut, une mesure à la fois, avant puis après, préparation des shaders retirée (comme plus haut :
la première image compile alors ses shaders, la même chose avant et après). Les durées sont celles du jeu, de la
demande au dévoilement. « Ajout et `_ready` » va de la fin de l'instanciation à l'apparition de la scène
(`scene_changed`) : c'est la partie que ce changement allège. Une ligne par paire de mesures, chaque paire prise
l'une après l'autre ; le serveur était chargé par d'autres travaux, d'où les écarts d'une paire à l'autre.

| Lieu | Ajout et `_ready`, avant | après | Plus longue tâche, avant | après | Total, avant | après |
| --- | --- | --- | --- | --- | --- | --- |
| Village | 2,11 s | 1,60 s | 41,3 s | 41,6 s | 64,6 s | 65,8 s |
| Village | 2,23 s | 1,13 s | 40,0 s | 39,0 s | 61,5 s | 59,8 s |
| Désert | 2,57 s | 1,92 s | 25,7 s | 26,7 s | 45,4 s | 45,9 s |
| Hub | 3,33 s | 2,21 s | 7,7 s | 6,6 s | 24,5 s | 23,1 s |
| Hub | 5,25 s | 2,40 s | 12,6 s | 7,5 s | 40,0 s | 29,8 s |
| Marais | 5,73 s | 4,43 s | 27,4 s | 28,6 s | 60,1 s | 59,2 s |
| Marais | 3,50 s | 2,62 s | 30,9 s | 30,4 s | 54,3 s | 46,4 s |

Deux autres paires du Désert ne sont pas retenues : l'export « après » y tournait en même temps que mes propres
captures puis mes profils natifs (images du menu 2 à 3 fois plus lentes).

Ce qu'on en retient :

- **Le travail du jeu au chargement baisse nettement** : de 23 à 54 % selon le lieu et la paire pour l'ajout
  et les `_ready`, soit 0,5 à 2,9 s de moins par lieu dans ce rendu logiciel.
- **La durée totale bouge peu dans Chromium** : elle est faite, ici, de la très longue image où la pause se lève (26
  à 42 s, 7 à 13 s au hub), que SwiftShader passe à dessiner, et d'images de 1 à 2 s. Ces deux postes viennent du
  rendu logiciel. Sur une vraie carte graphique, ils fondent, et ce qui reste est surtout le travail du jeu : la
  lecture de la scène et les `_ready`, que mesurent les relevés natifs ci-dessus.
- Au hub, où cette image est plus courte, la plus longue tâche baisse de 1 à 5 s.

Relevés et outils : `.claude/captures/perf-chargements/` (hors dépôt) : `mesures/` (JSON de chaque mesure),
`outils/perf_lieu.py`, `outils/driver/perf_driver.gd`, `outils/resume.py`, `outils/trace.py`.

### Marais : la crypte après l'arrivée

Mêmes outils, sur le travail décrit plus haut (« Marais : la crypte après l'arrivée » et `marais/decor`). « Avant » est
`dev` (f2920f8) ; « après », la branche `perf/marais-etale`.

**En natif**, `profile_load.gd` sans écran, avant et après en alternance, trois passages chacun ; médianes, en
millisecondes. Le serveur était chargé par les autres agents (charge 8,5) ; au calme (charge 0,7), le `_ready` d'avant
était de 542 à 546 ms.

| Poste | Avant | Après |
| --- | --- | --- |
| `_ready` de toute la scène | 563 | 279 (-50 %) |
| racine (`marais.gd`) : regroupements, particules | 317 | 134 |
| dont regroupement du dehors (mesuré à part, en alternance, deux passages, charge 6 à 7) | 210 et 220 | 118 et 111 |
| dont regroupement de la crypte (de même) | 80 et 86 | 0 (après l'arrivée ; 56 et 55 d'un bloc) |
| mécanisme gravé | 61 | 0,8 (les lettres après l'arrivée) |
| décor dispersé | 54 | 17 (calcul d'avance) |
| vie (`MaraisLife`) | 35 | 18 (signatures) |
| sol | 65 | 66 |
| lecture de la scène | 527 | 564 (écart dû à la charge : le calcul d'avance n'a que 37 Ko de plus) |
| total jusqu'au rythme stable | 1 164 | 892 |

Après l'arrivée, la crypte demande 121 à 134 ms en tout au premier chargement (polices et matériaux à lire), 65 à 79
ms quand ils sont déjà en mémoire. Par tranches, elle tient en 8 images (18 sous Xvfb, avec le dessin), la plus longue
de 12 à 17 ms : une tranche s'arrête au premier pas qui dépasse 8 ms.

**Dans Chromium**, le banc décrit plus haut, une mesure à la fois, préparation des shaders retirée, avant puis après,
trois paires ; le serveur était chargé par les autres agents (charge 12 à 15).

| Paire | Ajout et `_ready`, avant | après | Plus longue tâche, avant | après | Total, avant | après |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 4,47 s | 3,44 s | 32,2 s | 33,2 s | 60,9 s | 62,4 s |
| 2 | 4,65 s | 4,02 s | 32,8 s | 33,0 s | 64,8 s | 59,8 s |
| 3 | 4,66 s | 3,43 s | 30,6 s | 31,3 s | 63,8 s | 56,9 s |

L'ajout et les `_ready` baissent de 0,6 à 1,2 s (médiane 4,65 à 3,44 s, -26 %). Comme pour les autres lieux, le total
reste fait de la très longue image où la pause se lève (31 à 33 s, rendu logiciel) : ses écarts d'une mesure à l'autre
couvrent le gain. La lecture de la scène (3,6 à 4,8 s ici) ne change pas. Dans la console du jeu exporté, aucun
avertissement : le décor dispersé est bien lu dans le calcul d'avance.

Relevés : `.claude/captures/perf-marais/` (hors dépôt) : `profils/`, `mesures/` (JSON de chaque mesure), `outils/`
(copies des outils de `perf-chargements`, et `gd/` : détail des regroupements, des signatures, du travail de la
crypte).

### Regroupements : signatures une fois par état

« Avant » est `dev` (7488297), « après » la branche `perf/regroupements`. En natif, sans écran, avant et après en
alternance, trois passages chacun ; médianes, en millisecondes. Le serveur était chargé par les autres agents (charge
5,5 à 7,5).

- **En place**, chargé comme en jeu (`batch_cost.gd`) : pour le hub, le temps total passé à regrouper
  (`batch_msec`, étalé par tranches de 8 ms après l'arrivée) et le nombre d'images jusqu'à la fin ; pour la Plaine,
  le `_ready` de sa racine (suie, enveloppes de collision, regroupement du décor).
- **Signatures seules** (`sig_bench.gd`) : les matériaux que le regroupement décrit, dans son ordre, décrits à
  l'ancienne (liste des propriétés de chaque matériau) puis par l'outil du dépôt.

| Poste | Avant | Après |
| --- | --- | --- |
| Hub, 0 livre : regroupement, en tout (passages : 978, 917, 1 019 / 777, 814, 737) | 978 | 777 (-21 %) |
| Hub, 0 livre : images jusqu'à la fin du regroupement | 64 | 59 |
| Hub, 4 livres : regroupement, en tout (passages : 923, 980, 904 / 722, 799, 704) | 923 | 722 (-22 %) |
| Hub, 4 livres : images jusqu'à la fin du regroupement | 63 | 59 |
| Hub : signatures seules (227 matériaux, 6 476 appels) | 211 (0 livre), 201 (4 livres) | 32, 33 |
| Plaine : `_ready` de la racine (passages : 162, 176, 156 / 114, 94, 91) | 162 | 94 (-42 %) |
| Plaine : signatures seules (85 matériaux, 733 appels) | 74 | 17 |

Au hub, le regroupement ne se fait pas au chargement : il est étalé sur les premières images, au plus 8 ms par image.
Il finit 4 à 5 images plus tôt, et ces images sont plus courtes. Dans la Plaine, il se fait au `_ready` : c'est
autant de moins avant que le lieu s'affiche. Les gains en place (200 ms au hub, 68 ms dans la Plaine) suivent ceux
des signatures seules (environ 175 et 57 ms). Ce qui reste du regroupement est surtout l'assemblage des maillages
(`SurfaceTool`).

Relevés : `.claude/captures/perf-batch/` (hors dépôt) : `mesures/` (séries), `outils/` (`mesure.sh`, `serie.sh`,
`gd/batch_cost.gd`, `gd/sig_bench.gd`, `empreintes.sh`, `compare.py`, `captures.sh`, `diff_images.py`).

### Plaine et hub : décor dispersé d'avance, regroupement par pas

« Avant » est `dev` (6821059), « après » la branche `perf/hub-plaine`.

**En natif**, sans écran, avant et après en alternance, trois passages chacun ; médianes, en millisecondes. Le
serveur était chargé par les autres agents (charge 7,5 à 10) : d'un passage à l'autre, les écarts atteignent 30 %.
Pour le hub, `hub_prof.gd` (hors dépôt) charge le lieu comme en jeu et relève le temps passé à regrouper
(`batch_msec`), les images jusqu'à la fin, et la plus longue de ces images. La part adaptative n'y change rien :
sans écran, les images durent 7 ms, et la part reste de 8 ms.

| Poste | Avant | Après |
| --- | --- | --- |
| Hub, 0 livre : regroupement, en tout (passages : 698, 919, 980 / 327, 341, 428) | 919 | 341 (-63 %) |
| Hub, 0 livre : images jusqu'à la fin ; la plus longue | 58 ; 115 | 38 ; 29 |
| Hub, 2 livres : regroupement (768, 776, 918 / 464, 475, 406) | 776 | 464 (-40 %) |
| Hub, 2 livres : images ; la plus longue | 57 ; 86 | 51 ; 40 |
| Hub, 4 livres : regroupement (863, 964, 1 021 / 569, 552, 596) | 964 | 569 (-41 %) |
| Hub, 4 livres : images ; la plus longue | 59 ; 103 | 60 ; 45 |
| Plaine : `_ready` du décor dispersé (passages : 99, 110, 104 / 67, 60, 69) | 104 | 67 (-35 %) |
| Plaine : `_ready` de toute la scène (286, 307, 327 / 291, 245, 303) | 307 | 291 |
| Plaine, cinq passages, serveur plus chargé (charge 16) : décor | 138 | 78 (-43 %) |
| Plaine, cinq passages, charge 16 : `_ready` de toute la scène ; première image | 552 ; 212 | 408 ; 223 |
| Marais : `_ready` de la racine (regroupement du dehors) | 125 | 127 |

Dans la Plaine, ce qui reste du décor dispersé est la pose des nœuds : la zone de lave (environ 20 ms), les
cratères, les collisions des rochers. La première image ne bouge pas : le corps de chaque groupe de rochers, qui
entre dans le monde avec toutes ses collisions, n'y reporte pas de travail. Le Marais ne change pas en natif : sans
écran, une lecture ne fait que recopier et décoder des tableaux ; c'est sur le web, où elle attend la carte graphique,
que ces lectures pèsent (plus bas).

Au hub, le gain vient pour moitié des groupes laissés de côté (à 0 livre, les reconstructions faisaient 63 % du
travail), pour le reste de l'examen allégé (ce qui ne dépend que du maillage, gardé par maillage) et des surfaces lues
une fois. La plus longue image n'est plus celle d'un groupe entier (le décor fixe, 80 à 150 ms d'un bloc) : c'est
celle où toutes les surfaces, ou tous les lots, sont relus d'un coup (28 à 56 ms ici).

**Dans Chromium**, le banc de `perf-chargements` (une mesure à la fois, préparation des shaders retirée), avec un
pilote qui relève aussi, au hub, le regroupement après l'arrivée (travail, images, durée, plus longue image) et
chaque `getBufferSubData` (lecture d'un tampon de la carte graphique). Le hub part du menu ; à 0 livre, la partie
commence au bunker.

Trois versions « après » ont été mesurées. La première, par pas fins mais sans lectures groupées, a montré le
piège : 3 246 lectures au lieu de 23 579, mais 70 s d'attente sur 298 images, chaque image qui lit attendant la carte
graphique. La deuxième groupe les lectures, à 8 ms par image (« après, 8 ms » ci-dessous). La version livrée
(« après ») y ajoute la part adaptative : 8 ms aux images courtes, jusqu'au quart des images longues, 250 ms au plus.

| Mesure | Travail du regroupement | Lectures (`getBufferSubData`) | Leur temps | Images jusqu'à la fin | Durée jusqu'à la fin | Plus longue image |
| --- | --- | --- | --- | --- | --- | --- |
| Hub, 0 livre, avant (deux passages) | 59,9 s ; 52,1 s | 23 579 | 58,4 s ; 50,8 s | 86 ; 86 | 89,6 s ; 91,8 s | 2,32 s ; 2,10 s |
| Hub, 0 livre, après, 8 ms | 2,7 s | 3 246 | 2,1 s | 95 | 101,5 s | 1,71 s |
| Hub, 0 livre, après | 2,0 s | 3 246 | 1,4 s | 28 | 40,9 s | 2,56 s |
| Hub, 4 livres, avant | 92,0 s | 23 579 | 90,7 s | 85 | 163,7 s | 3,58 s |
| Hub, 4 livres, après, 8 ms | 4,4 s | 4 102 | 3,4 s | 131 | 240,3 s | 2,88 s |
| Hub, 4 livres, après | 6,0 s | 4 102 | 4,9 s | 35 | 115,5 s | 4,49 s |

| Plaine | Ajout et `_ready` | Lectures | Leur temps | Total jusqu'au dévoilement |
| --- | --- | --- | --- | --- |
| Avant | 3,17 s | 2 077 | 0,9 s | 65,6 s |
| Après | 2,29 s (-28 %) | 894 | 0,3 s | 67,9 s |

Ce qu'on en retient :

- **Les lectures de la carte graphique faisaient presque tout le regroupement du hub sur le web** : 23 579 lectures,
  51 à 91 s sur 52 à 92 s de travail (en natif, le même regroupement prend moins d'une seconde). Une lecture coûte
  environ 0,6 ms d'aller-retour, et la première de chaque image attend en plus que la carte ait fini l'image
  précédente (près d'une seconde sous SwiftShader). Après : 3 246 à 4 102 lectures, groupées dans quatre images,
  1,4 à 4,9 s ; le travail du regroupement passe de 52 à 92 s à 2 à 6 s.
- **Sous SwiftShader, l'image reste dominée par le dessin** (environ 1 s par image au hub) : l'attente des lectures
  s'y recouvrait en partie avec le dessin de l'image précédente. Dans un même passage, les images pendant le
  regroupement étaient, avant, 30 % plus longues que celles d'après (1,02 et 1,07 s contre 0,77 et 0,80 s) ; après,
  elles ne le sont plus (1,07 s contre 1,13 s, à 8 ms). D'un passage à l'autre, en revanche, la charge du serveur
  (11 à 17, les autres agents) fait varier le temps d'image de 0,5 à 1,9 s pour la même scène regroupée, autant que
  ce qu'on cherche : la plus longue image et le rythme ne se comparent pas d'un passage à l'autre.
- **La part adaptative** : à 8 ms par image, le travail du hub, désormais petit, s'étalait sur plus d'images (95 et
  131) quand chacune dure plus d'une seconde, et le hub restait plus longtemps à 3 000 appels de dessin. En prenant
  jusqu'au quart des images longues, il finit en 28 et 35 images (41 et 116 s, contre 92 et 164 s avant). En natif
  et aux images courtes, rien ne change (8 ms).
- **La Plaine** : l'ajout et les `_ready` baissent de 0,9 s (décor dispersé d'avance, surfaces lues une fois). Le
  total reste fait de la très longue image où la pause se lève (39 s, rendu logiciel), comme pour les autres lieux.

Relevés : `.claude/captures/perf-hub-plaine/` (hors dépôt) : `banc/mesures/` (JSON de chaque mesure), `banc/`
(copies des outils de `perf-chargements`, avec `resume_hub.py` et le relevé du regroupement et des lectures),
`mesures/` (séries natives), `outils/` (`hub_prof.gd`, `serie.sh`, `empreintes.sh`, `captures.sh`,
`shots_pendant.gd`, `visibles.py`).

**Poids** : le décor de la Plaine d'avance (`plaine_decor_bake.res`, 95 636 octets) et le code ajoutent au paquet du
jeu 103 796 octets, 66 315 en brotli (`index.pck.br` : 10 530 777 à 10 597 092 octets, export de mesure) : les
places des herbes et des rochers, des nombres à virgule, se compressent mal.

## Téléchargement

Trois gains relevés par l'agent de la musique (`docs/musique-differee.md`, « autres gains possibles ») :

- **Le moteur au plus fort.** `index.wasm` vient tel quel du modèle d'export de Godot. Le `Dockerfile` le compresse
  désormais dans une couche gardée en cache tant que Godot ne change pas : brotli 11 au lieu de 9, et gzip 9. Après
  l'export, cette compression n'est reprise que si `index.wasm` est identique au fichier du modèle, octet pour octet ;
  sinon, il est compressé comme les autres fichiers. `index.wasm.br` passe de 7 896 845 à 6 890 455 octets
  (1,0 Mo de moins avant le menu). La première construction après un changement de Godot prend environ 100 s de plus ;
  les suivantes, rien.
- **Des ETag stables.** Caddy calcule l'ETag de la date et de la taille du fichier, et chaque construction donnait une
  date neuve : après un déploiement, un joueur qui revenait retéléchargeait le moteur (7,9 Mo) et la musique (10,5 Mo),
  même inchangés. Chaque fichier servi prend maintenant une date tirée de son contenu (les 28 premiers bits de son
  SHA-256, comptés en secondes depuis le 1er janvier 2000). Un fichier inchangé garde son ETag d'une version à
  l'autre. `gzip -n` n'écrit plus ni nom ni date dans les `.gz`, qui restent donc identiques eux aussi. Un navigateur
  qui a un ETag le présente (`If-None-Match`), et la date (`If-Modified-Since`) n'est alors pas regardée : qu'elle
  recule d'une version à l'autre ne gêne pas. Vérifié sur deux constructions de suite, dont seul le paquet du jeu
  changeait : `index.wasm`, `musique.pck`, `index.js` et l'icône gardent leur ETag, en brotli comme sans compression ;
  `index.pck` et `index.html` (qui porte la taille du paquet) en changent. Une revalidation reçoit `304 Not Modified`.
  `musique.pck` change dès que `project.godot` change : Godot met les réglages du projet dans chaque paquet.
- **Une icône plus légère.** L'icône du projet (`assets/ui/codequest_icon.png`) passe de 512 à 256 pixels de côté
  (65 Ko au lieu de 225 Ko). Elle n'est affichée qu'en favicon, en icône d'écran d'accueil (180 pixels) et en icône de
  l'exécutable Windows (256 pixels au plus) : rien ne change à l'écran. Godot la copie brute dans chaque paquet et en
  favicon (`index.icon.png`) : la favicon passe de 237 196 à 67 707 octets, `musique.pck` perd 160 Ko, l'icône
  d'écran d'accueil 2 Ko.
- **Bilan, export de production** (même `Dockerfile`, même Caddyfile, comparé à l'image en service le 8 novembre) :

  | Fichier, en brotli | Avant | Après |
  | --- | --- | --- |
  | `index.wasm` | 7 896 845 | 6 890 455 |
  | `index.pck` (calculs d'avance compris) | 9 720 844 | 10 179 330 |
  | `index.icon.png` (sans compression) | 237 196 | 67 707 |
  | autres fichiers avant le menu | 128 496 | 126 540 |
  | **Total avant le menu** | **17 983 381** | **17 264 032** |
  | `musique.pck`, après le menu | 10 493 476 | 10 333 159 |

  Le joueur reçoit 0,72 Mo de moins avant le menu, calculs d'avance compris (0,46 Mo de plus dans le paquet du jeu).
  Les en-têtes (COOP, COEP, `Cache-Control: no-cache`, `Content-Encoding`, `Vary`, et ceux de `/reinitialisation`)
  sont identiques à ceux de l'image en service, fichier par fichier et encodage par encodage.
- **Non fait :** les images de l'interface (`ruminate_studio.png`, `devlyn_portrait.png`) restent importées sans
  perte : un import avec perte change l'image, et ce sont les seules images du menu. Leur réencodage sans perte
  ne gagne que 2 à 5 %.

## Ce qui reste

- **Le regroupement du dehors du Marais** (environ 115 ms en natif, serveur chargé) reste le plus gros poste de sa
  racine : surtout l'assemblage des maillages (`SurfaceTool`, 237 401 sommets), que seul un précalcul de toute la
  géométrie (7,9 Mo) supprimerait. Piste : les cases à plus de 50 m de l'arrivée, dans la brume et hors de portée des
  ombres de la lune, portent 44 % de ces sommets (22 % au-delà de 60 m). Elles pourraient être fondues après
  l'arrivée, comme la crypte, mais un petit objet n'y suit pas la même règle avant et après (ombre, portée de 40 m
  comptée depuis le centre de son lot) : il faudrait ne différer que les lots de grands objets, ou prouver qu'aucun
  petit lot ne se voit depuis l'arrivée, et le vérifier par des captures prises pendant ce travail.
- **Le sol du Marais** (environ 65 ms : assemblage du maillage et collision bâtie par Jolt), à son `_ready`.
- **La Plaine** : son décor dispersé est précalculé. Restent à son `_ready` : la zone de lave (2 634 bandes, des
  nœuds à poser, environ 20 ms, déjà lues d'avance), les cratères (braises, fumées, lueurs), les collisions des rochers
  que Jolt bâtit (enveloppes des cailloux, triangles des gros rochers), et le regroupement de sa racine
  (`DecorBatch`).
- **Le regroupement du hub** : ce qui reste est l'assemblage des lots et des ombres (`SurfaceTool`) des groupes qu'on
  peut voir (environ 340 à 570 ms en natif, 2 à 6 s dans Chromium), et les quatre images de lectures groupées (28 à
  56 ms en natif). Les ombres doivent relire leurs lots (une ombre bâtie sans les relire change ses normales, donc
  son empreinte) : une ombre sans normales ni tangentes (elle n'en a pas besoin) éviterait ces lectures, au prix
  d'une empreinte d'ombre différente, à vérifier par des captures. Autre piste : garder les lots fondus d'une visite
  du hub à l'autre (le résultat d'un groupe ne dépend pas du palier) ; ils resteraient alors en mémoire, sur la carte
  graphique, pendant les autres lieux.
- **Le rythme des images dans Chromium** : sur ce serveur, chargé par les autres agents, il varie d'un passage à
  l'autre autant que les gains cherchés. La part adaptative du hub (plus haut) se juge mieux sur une vraie carte
  graphique, où les lectures évitées devraient compter davantage (l'attente de la carte n'y est plus masquée par un
  dessin d'une seconde).
- **Les collisions des arbres du Village** : Jolt bâtit chaque enveloppe convexe depuis tous les points de son emprise
  (94 000 points, environ 60 ms en natif). Ne garder que les sommets de l'enveloppe (6 655 points) irait plus vite et
  pèserait moins, mais les données des formes ne seraient plus identiques octet pour octet : il faudrait alors
  vérifier les collisions autrement (sondes de marche).
- **La lecture des scènes** : 130 à 200 ms en natif depuis le hub, environ 1,4 s dans Chromium.
- **La très longue image où la pause se lève**, dans Chromium : elle vient du rendu logiciel (SwiftShader). À mesurer
  sur une vraie carte graphique avant d'y chercher un remède dans le jeu.
