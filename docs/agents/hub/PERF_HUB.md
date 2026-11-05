# Hub : regroupement du décor pour le web (5 novembre)

Branche `perf/hub-batch`, partie de `dev` 0c8c89c. Reprend `hub_batch.gd` du commit c743d85 (méthode du Marais) et l'adapte au hub actuel.

## Ce qui est fait
- **`hub_batch.gd`** (racine de `hub_props.tscn`) : dans chaque groupe (`Fixed`, et `Ruins` / `Rebuilt` de chaque élément réparable) et chaque case de 32 m, les surfaces de même matériau sont fondues en un maillage. Les couleurs des matériaux sans texture passent dans les sommets. L'ombre de chaque case vient d'un seul maillage en ombre seule. Les petits objets (moins de 1 m) ont une portée de 40 m, avec un fondu.
  - **Jamais fondus :** les nœuds à script (panneaux, lampes, braises, textes, portes, roue du moulin), les nœuds `Collision`, les arbres, et tout modèle qui contient autre chose que des nœuds 3D vides et des maillages. Les personnages, portails, volcan, château et fin sont dans `hub.tscn`, que le regroupement ne touche pas.
  - **Paliers de livres :** chaque groupe reste séparé. Les réparations montrent, cachent ou font monter chacun d'un bloc, comme avant.
  - **Adaptations à c743d85 :**
    - la visibilité se lit dans le modèle, et non dans l'arbre : un groupe caché se regroupe aussi (sinon il perdait son contenu) ;
    - les modèles non inertes restent tels quels ;
    - rien ne se regroupe pendant le chargement. À partir de la première image, chaque image regroupe pendant au plus 8 ms, les groupes visibles d'abord. Un groupe caché qui apparaît avant son tour se regroupe aussitôt. Le rendu de ces premières images est le même, avec plus d'appels de dessin.
  - `batch_msec` donne le temps total passé à regrouper, et `is_done()` dit si tout est fait (pour les mesures).
- **`hub.gd`** :
  - `_set_location` : au bunker, le dehors n'est pas dessiné (`OUTSIDE` : terrain, dispersion, rivière, décor, feu, portails, château, panneaux, braseros, volcan). Dehors, l'abri n'est pas dessiné. Les personnages ne sont jamais cachés : le roi, Merlon et les survivants sont dans l'abri au début.
  - Chaque `SignBoard` du hub (ceux de `hub.tscn` et ceux de `hub_props.tscn`) est dessiné d'un seul maillage (`merge_sign`). Les planches, cadres, clous et poteaux sont fondus, avec leur couleur dans les sommets. Le panneau garde son texte, sa collision et ses morceaux, qui sont seulement cachés. Il les refait lui-même si une propriété change. `sign_board.gd` n'est pas modifié.

## Mesures
Appels de dessin, ombres comprises : visibles et ombres de `get_render_info`. Les mesures sont prises en natif, sous Xvfb (rendu logiciel), en 1280 x 720. L'outil est dans `.claude/captures/perf-hub/outils/perf_hub.gd`. « Dehors » regroupe les 8 directions depuis le point d'arrivée du joueur. La mesure est faite une fois le regroupement fini.

| État | Avant, moyenne | Avant, pire | Après, moyenne | Après, pire |
|---|---|---|---|---|
| 0 livre, dehors | 1 220 | 1 842 | **603** | 939 |
| 2 livres, dehors | 1 509 | 2 217 | 759 | 1 107 |
| 4 livres, dehors | 1 618 | 2 508 | 813 | 1 260 |
| Bunker (début) | 297 | 707 | **48** | 99 |
| Fin (4 livres), plan large du village | 2 567 | | 1 186 | |
| Fin (4 livres), plan du volcan | 88 | | 81 | |

Vues fixes (0 livre / 4 livres), avant puis après :

| Vue | Avant, 0 livre | Après, 0 livre | Avant, 4 livres | Après, 4 livres |
|---|---|---|---|---|
| Place | 1 951 | 947 | 2 702 | 1 316 |
| Village vu de haut | 2 271 | 1 051 | 2 936 | 1 293 |
| Château | 686 | 565 | 997 | 816 |
| Salle du trône | 502 | 447 | 788 | 715 |
| Maison 00 (dedans) | 1 406 | 692 | 1 969 | 1 009 |
| Taverne | 350 | 230 | 610 | 415 |
| Parc | 473 | 409 | 599 | 528 |
| Ferme | 292 | 228 | 540 | 432 |
| Lavoir | 681 | 396 | 949 | 572 |
| Forge | 505 | 382 | 731 | 563 |

**Chargement :**
- Avec la première version (les groupes visibles regroupés avant la première image), le regroupement prenait 495 ms au chargement à 0 livre et 870 ms à 4 livres. Le total, y compris le différé, était de 1,2 à 1,5 s, sur le serveur arm64.
- La version livrée ne regroupe plus rien au chargement (0 ms). Elle étale ces 1,2 à 1,5 s sur les premières images, par tranches de 8 ms.
- Le temps de chargement brut de l'outil (3,7 à 13 s) n'est pas comparable d'un lancement à l'autre : le serveur était chargé par les autres agents.

**Objectif de moins de 600 appels en moyenne dehors :**
- à 0 livre, il est presque atteint (603) ;
- à 2 et 4 livres, il ne l'est pas (759 et 813).

Une mesure par sous-arbre, prise sur une version encore cassée, a montré que l'essentiel du reste vient des ombres du soleil (4 tranches). Le décor reconstruit et les lampes allumées s'y ajoutent, ainsi que les passes de lumière du rendu Compatibility. La suite logique est le commit `perf/fluidite-web` d'Anthony (2 tranches d'ombre, portée de 50 m), à porter dans `dev`.

## Contrôles
- **Captures avant et après aux mêmes points :** 8 directions, place, village, château, salle du trône, maison 00, taverne, parc, ferme, lavoir, forge. Elles sont prises à 0, 2 et 4 livres, et au bunker. Les planches sont dans `.claude/captures/perf-hub/comparaison/` : avant, après, écart x4.
  - L'écart moyen est de 0 à 0,8 sur 255, avec moins de 0,45 % de pixels qui changent de plus de 40.
  - Ces écarts viennent seulement de ce qui bouge : feu, braises, faisceaux des piédestaux, chronomètre, pose du garde au bunker (2,7 %).
- **Fin :** les deux plans fixes de la cinématique de victoire (caméra libre aux mêmes points) sont identiques. Pendant la cinématique, en rendu logiciel, le regroupement différé n'a pas le temps de finir.
- **Tests (code final) :**
  - `hub_test` : 0 échec ;
  - `hub_walk_test -- 0` et `-- 4` : 2 échecs chacun, les limites voulues ;
  - `timer_test`, `signboard_test`, `tree_collision_test` : 0 échec ;
  - `run_tests` : 51 réussis.
  - `music_test` échoue sur « le thème du hub continue d'une porte du bunker à l'autre », dans 3 lancements sur 4. Il échoue aussi sur `dev` sans ces changements : la position de lecture ne bouge pas (0,096 s avant et après). Le test ne laisse qu'environ 0,1 s de son au fil audio Dummy, ce qui ne tient pas quand le serveur est chargé.
- **Apparats :** sur l'export Docker, le roi a sa couronne, son joyau, son col, sa cape et son sceptre. Merlon a son chapeau, sa barbe, son bâton et son orbe. Capture : `.claude/captures/perf-hub/export/apparats.png`.
