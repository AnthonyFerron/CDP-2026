# Plaine : trois finitions (9 novembre)

Branche `features/finitions-plaine`, partie de `dev` (9a9fedc). Tâche « Finitions libres : trois améliorations par lieu » de `docs/agents/BACKLOG.md`, pour les plaines d'Hexcole.

## Ce que montrait le parcours

Le parcours en captures, dehors et dans les archives, est dans `.claude/captures/finitions-plaine/avant/` (hors dépôt).

La Plaine était déjà vivante : corbeaux, bannières qui ondulent, feux et fumées du siège, braises de la lave, vent dans la tour, poussière et bougies des archives. Trois manques ressortaient :

- **La menace restait immobile.** Dès le portail, le Mont Sam Altan se dresse juste derrière la bibliothèque, mais sa fumée et sa lueur ne bougeaient jamais. Rien, dans le lieu, ne rappelait que le volcan se réveille et que l'heure tourne.
- **Les deux camps portaient les mêmes couleurs.** Toutes les bannières du champ de bataille étaient celles du kit Castle, au bleu de Codia, comme au château du hub. L'étendard planté devant les engins de siège de Vibelandia portait donc les couleurs de Codia.
- **L'intérieur ne disait rien du siège.** La stèle des défenseurs raconte que les catapultes ennemies ont mis le feu au toit, mais rien, dans les archives, n'en gardait la trace.

## 1. Le Mont Sam Altan gronde

**Pourquoi.** C'est le moment fort de l'arrivée. Le joueur sort du portail face à la bibliothèque, et le volcan est juste derrière. Le grondement rappelle l'enjeu du scénario : le volcan se réveille, et chaque minute compte.

**Ce qui se passe.**

- Quatre secondes après le dévoilement du lieu (fin de la transition), le volcan crache un panache de cendre et des projections incandescentes, et la lueur de son cratère s'embrase.
- Le brouillard de la plaine rougit un instant, puis reprend sa couleur en six secondes environ.
- Le grondement arrive 0,9 s après l'éclat, comme de loin. C'est le son de l'éruption du hub (`volcano_eruption.wav`), joué plus grave et plus lent (`pitch_scale` 0,6) à -14 dB.
- Au même moment, les corbeaux perchés s'envolent tous (`PlaineLife.startle()`).
- Ensuite, le volcan gronde de loin en loin : toutes les 80 à 110 s au début de la partie, puis de plus en plus souvent, jusqu'à toutes les 35 à 50 s quand il ne reste presque plus de temps (`GameState.time_left`).
- Il se tait pendant la transition, dans les archives et après l'éruption.

**Lisibilité de l'énigme.** La caméra ne tremble pas, et rien ne se passe dans les archives. Le tremblement et le grondement de pierre restent les signaux d'une erreur à la tablette.

**Comment.** `scenes/levels/plaine/plaine_rumble.gd` (`PlaineRumble`), nœud `Exterior/VolcanoRumble` de `plaine.tscn`, posé au bord du cratère du volcan de l'horizon (`Exterior/Volcano`, script du hub, inchangé).

- Le panache : 22 bouffées de 30 m, qui montent, ralentissent, grossissent et dérivent avec le vent.
- Les projections : 40 éclats additifs, lancés à 26-44 m/s, qui retombent en rougissant.
- La lueur : un halo additif tourné vers la caméra, par-dessus celui du volcan, dont l'intensité suit une enveloppe (montée en 0,5 s, retombée jusqu'à 6,5 s).
- Le brouillard : `fog_light_color` de l'environnement, mêlé à un rouge au plus fort de la lueur. L'environnement est une ressource de la scène : le script lui rend sa couleur en quittant l'arbre (`_exit_tree`).
- Les particules et la lueur sont cachées entre deux grondements : au repos, elles ne coûtent aucun appel de dessin.
- Le panache et les projections ignorent le brouillard, comme le volcan : à près de 300 m, il les effacerait.

## 2. Les étendards des deux camps

**Pourquoi.** C'est le récit visuel du champ de bataille. Dès le portail, on lit qui était où :

- à gauche, le vert de Vibelandia flotte sur ses engins de siège brisés ;
- au fond, derrière la bibliothèque, il flotte sur la batterie de balistes ;
- au centre, le bleu de Codia est sur la barricade, la tour de guet et les tombes des défenseurs.

**Couleurs.** Le bleu des bannières du kit Castle est celui de Codia, comme au château du hub. Le vert de Vibelandia vient du même kit : `castle_kit/Textures/variation-b.png` est sa variante de couleurs où ce bleu devient vert. Ce sont les mêmes modèles Kenney, avec une autre planche de couleurs, et rien n'est téléchargé.

**Ce qui change.**

- Les bannières plantées dans les positions de Vibelandia (`VIBELANDIA_CAMPS` : engins de siège, batterie de balistes) passent au vert. Au chargement, `plaine_life.gd` leur donne un double de leur matériau, avec cette planche de couleurs.
- C'est le cas de l'étendard qui existait déjà devant le trébuchet.
- Quatre étendards sont ajoutés par `tools/build_plaine.py` (`standards`) :
  - Vibelandia : un grand étendard planté au bord du chemin, devant les engins de siège, tourné vers le portail ;
  - Vibelandia : un étendard piétiné, à plat dans la cendre, à 7 cm du sol, qu'on enjambe sans collision ;
  - Vibelandia : un étendard sur la batterie de balistes, tourné vers la bibliothèque ;
  - Codia : l'étendard des défenseurs, encore debout au-dessus de leurs tombes, tourné vers le chemin et éclairé par le soleil.
- Le journal du soldat nomme les couleurs : « Jour douze. À l'aube, les troupes de Vibelandia ont planté leurs étendards verts devant nos barricades et mis le feu à la bibliothèque. » La suite du texte, qui met sur la piste de l'énigme, ne change pas.

**Comment.**

- Les étendards plantés ont la collision de leur hampe et de leur étoffe (`banner_pole`, `leaning_box`), comme les autres.
- Une bannière couchée ne flotte plus : `plaine_life.gd` ne fait onduler que celles qui sont debout.
- Les nouveaux modèles sont ajoutés après tout le reste du champ de bataille, avec leur propre tirage. Les noms et les places du décor existant ne bougent pas : le générateur relancé ne change `plaine_battlefield.tscn` que par ajouts.
- `VIBELANDIA_CAMPS` est décrit deux fois, dans `tools/build_plaine.py` et dans `plaine_life.gd`, et doit rester identique (comme `SITES`). Le générateur vérifie que chaque étendard ajouté est du bon côté.

## 3. La voûte percée de la salle de lecture

**Pourquoi.** C'est le détail de la bibliothèque qui relie l'intérieur au siège : une pierre des catapultes de Vibelandia a crevé la voûte des archives. C'est aussi le premier tableau qu'on voit en entrant.

**Ce qu'on voit.**

- Entre deux poutres de la salle de lecture, au-dessus des gravats bas qui étaient déjà là, s'ouvre un trou aux bords arrachés.
- Par ce trou, on voit le ciel de cendre, bordé de braises qui rougeoient.
- Un rai de lumière rose pâle en tombe jusqu'au tas, et pose une tache de lumière au sol. Il tranche sur la lumière orangée des bougies.
- La poussière flotte dans le rai, et la cendre y descend lentement, avec quelques braises.
- Le vent siffle dans la brèche (`plaine_wind.wav`, source 3D à -15 dB, coupée à 13 m).
- Sous le trou gisent la pierre de catapulte (le même modèle que les boulets des engins de siège), deux éclats de pierre et une solive calcinée, couchée de la pierre au sol.

**Lisibilité de l'énigme.**

- La brèche est à 4 m de la lettre de la bibliothécaire, loin des rayonnages où sont les livres à fouiller.
- Elle ne cache ni le règlement, ni le passage vers le scriptorium.
- Elle ne porte aucun texte.

**Comment.** `scenes/levels/plaine/library_breach.gd` (`LibraryBreach`), nœud `Interior/Breach` de `plaine.tscn`, posé au sol sous le centre du trou (`BREACH` dans `tools/build_plaine.py`).

- **Le plafond.** Le plafond des archives (`Interior/Ceiling`, une `BoxMesh`) reçoit à sa place un maillage percé, du même matériau. Il comprend la dalle autour du trou, le puits au-dessus avec son couvercle, douze pierres arrachées qui mordent sur l'ouverture, et deux solives. Le tout reste en une seule surface : un seul appel de dessin, comme avant.
- **Hauteur.** Les pierres pendent au plus de 40 cm sous la voûte, à plus de 3,6 m du sol.
- **Collision.** La collision du plafond ne change pas : le trou est hors d'atteinte.
- **Le ciel, le rai et la tache au sol.** Ce sont trois quadrilatères d'un même shader, `breach_light.gdshader` : additif, sans ombrage ni profondeur écrite.
  - Le rai est tourné vers la caméra autour de la verticale. Il est plus étroit en haut, s'efface vers le sol et est traversé de stries lentes.
  - Sa boîte de visibilité est élargie (`custom_aabb`) : sa boîte plate d'origine le faisait disparaître de biais.
  - Le ciel et les braises respirent lentement (`pulse`).
- **Aucune lumière dynamique, aucune ombre.**
- **Les gravats** sont posés par `tools/build_plaine.py` (`breach_rubble`), avec leurs collisions, et sont fondus avec le reste des archives (`DecorBatch`). Ils sont ajoutés après tout le reste, sans tirage : `library_interior.tscn` ne change que par ajouts.

## Inventaire des shaders

Il est régénéré, et passe de 113 à 115 entrées. Les deux entrées nouvelles :

- les projections du volcan, additives et sans brouillard ;
- le shader de la brèche, dans les archives.

Les autres matériaux nouveaux reprennent des réglages déjà relevés :

- le panache du volcan reprend ceux de la fumée du volcan, au même endroit, ombre comprise : à près de 300 m, bien au-delà des 50 m des ombres du soleil, elle n'est jamais dessinée ;
- la poussière du rai reprend ceux de la poussière des archives ;
- la cendre qui tombe de la brèche reprend ceux des lueurs du Projenomicon ;
- le vert de Vibelandia est un double du matériau du kit, avec les mêmes réglages.

Aucune ressource n'est chargée par `preload()` : `plaine.tscn` référence les scripts, le shader, le son et la planche de couleurs. L'export les suit, et `include_filter` n'a rien à ajouter.

## Performances

Mesures sur le serveur : rendu logiciel llvmpipe sous Xvfb, 1280 x 720, 30 images par vue après 15 de mise en route (`.claude/captures/finitions-plaine/tools/perf_plaine.gd`, copie de `docs/agents/plaine/perf/perf_plaine.gd`). Les appels de dessin sont exacts. Les temps d'image ne valent que pour comparer : le serveur faisait tourner d'autres agents.

Le grondement est coupé pour les vues au repos. La vue « arrivée, pendant un grondement » le lance juste avant sa mesure.

Deux passages dos à dos, dans la même worktree : `dev` (9a9fedc), puis la branche, deux fois. La charge du serveur est montée de 6,5 à 15 pendant ces passages.

| Vue | Appels avant | Appels après | Image avant, 1er passage | Image après, 1er passage | Image avant, 2e passage | Image après, 2e passage |
| --- | --- | --- | --- | --- | --- | --- |
| o1 arrivée (0 ; 54) | 539 | 548 | 766 ms | 760 ms | 998 ms | 671 ms |
| o1 arrivée, pendant un grondement | 539 | 561 | 766 ms | 750 ms | 998 ms | 561 ms |
| o2 pont | 340 | 342 | 794 ms | 743 ms | 1 053 ms | 585 ms |
| o3 façade | 284 | 289 | 744 ms | 749 ms | 894 ms | 550 ms |
| o4 campement | 256 | 259 | 616 ms | 702 ms | 466 ms | 452 ms |
| o5 engins de siège | 311 | 318 | 711 ms | 683 ms | 509 ms | 363 ms |
| o6 batterie | 105 | 108 | 632 ms | 643 ms | 543 ms | 596 ms |
| o7 vue haute | 453 | 462 | 775 ms | 744 ms | 1 520 ms | 684 ms |
| o8 tombes | 114 | 117 | 415 ms | 554 ms | 1 141 ms | 300 ms |
| i1 salle de lecture | 170 | 179 | 424 ms | 404 ms | 688 ms | 226 ms |
| i2 scriptorium | 118 | 118 | 410 ms | 436 ms | 1 014 ms | 222 ms |
| i3 salle des archives | 69 | 69 | 370 ms | 396 ms | 979 ms | 277 ms |
| i4 brèche | 165 | 174 | 421 ms | 438 ms | 448 ms | 343 ms |

- **Appels de dessin.** Ils sont identiques d'un passage à l'autre : de 0 à 9 de plus au repos, 22 de plus pendant un grondement.
  - Dehors : chaque étendard ajouté reste à part du regroupement, comme toutes les bannières qui ondulent, avec sa suie.
  - Dans la salle de lecture : le ciel, le rai, la tache au sol, la poussière, la cendre, et les gravats fondus avec le reste.
  - Le plafond percé reste un seul appel.
  - Le scriptorium et la salle des archives n'en ont aucun de plus.
- **Temps d'image.** Au premier passage, à charge voisine (6,5 puis 9,5), les écarts restent dans le bruit, dans les deux sens. Au second, la charge a doublé pendant la mesure « avant ». Rien ne montre de régression mesurable.
- **Comptes de tout le lieu.** 4 204 nœuds avant, 4 232 après ; 408 maillages avant, 418 après ; 29 particules avant, 33 après. Il n'y a ni lumière ni ombre de plus : 20 lumières, dont 1 avec ombre, le soleil.
- **Chargement.** Il varie trop avec la charge (de 3,8 à 9,1 s selon le passage) pour qu'on y lise un écart. Ce qui s'ajoute au `_ready` : le plafond percé (une vingtaine de boîtes fondues) et la création de six systèmes de particules.
- **Captures figées** (particules cachées, temps arrêté), avant | après | écart (x 4), regardées : `.claude/captures/finitions-plaine/planches/`.
  - Les écarts sont aux étendards, aux étendards devenus verts et à la brèche.
  - Hors de ces endroits, rien ne change, sauf la lave, qui suit le temps de son shader.
  - Le scriptorium, la salle des archives, la tablette et la tour n'ont aucun pixel qui change de plus de 24 (sur 255).

## Contrôles

- **Générateur sans dérive.** `tools/build_plaine.py` relancé ne change les scènes générées que par ajouts : 4 étendards, 3 collisions et leurs formes dans `plaine_battlefield.tscn` ; la pierre, trois éclats, la solive, 3 collisions dans `library_interior.tscn`. Avant les changements, il rendait les fichiers à l'identique.
- **Précalculs** (après `--import`) :
  - `bake_plaine_check` : « données d'avance à jour » ;
  - `bake_lieux_check` : « à jour » (sol, lave et décor dispersé ne sont pas touchés) ;
  - `bake_shaders_check` : « inventaire à jour », 115 entrées.
- **Sonde de saut** (copie de l'outil de l'agent `sauts`, pas de 0,5 m, 16 directions), sur les zones touchées :

  | Zone | Sauts | Points coincés |
  | --- | --- | --- |
  | Salle de lecture (x -6,5 à 6,5, z -12,5 à 0,5) | 4 624 | 0 |
  | Engins de siège, étendard planté et étendard piétiné (x -25 à -3, z 28 à 49) | 23 440 | 0 |
  | Batterie de balistes (x 9 à 26, z -31 à -14) | 16 800 | 0 |
  | Tombes et campement (x 15 à 30, z 39 à 52) | 10 320 | 0 |

  Un premier essai de la brèche couchait la solive en pente, de la pierre au sol. Avec la pierre et le rayonnage du mur du fond, elle fermait une poche de 1 m, d'où l'on ne ressortait pas : un point coincé en (0,64 ; -10,55). La pierre a reculé de 20 cm, et la solive est couchée à plat contre elle, sans collision (20 cm, on l'enjambe). Le passage le long du rayonnage garde 1,2 m.
- **Grille de marche** (copie de `grid_plaine.gd`) : 0 problème dehors et dans les archives.
  - Dehors : 43 619 cases accessibles sur 46 626 marchables. L'écart avec les relevés précédents (une vingtaine de cases) correspond aux hampes des nouveaux étendards.
  - Dedans : 3 485 cases accessibles sur 4 042. Les cases marchables qu'on n'atteint pas sont le dessus de la pierre et des éclats, hors de portée à pied : aucune zone fermée d'au moins 1 m².
- **Énigme** : `plaine_puzzle_test` à 0 échec.

- **Suite complète** (`frontend/tests/scenes/run_all.sh`, depuis la branche, après `--import`, charge du serveur de 10 à 15) :
  - `bake_plaine_check`, `bake_lieux_check` et `bake_shaders_check` : à jour ;
  - 0 échec partout (`hub_test`, `music_test`, `sound_test`, `gamepad_test`, `plaine_puzzle_test` compris), sauf `hub_walk_0` et `hub_walk_4`, qui ont chacun leurs 2 échecs voulus (« limite infranchissable (doit echouer) ») ;
  - `tree_collision_test` : mêmes comptes (Plaine : 38 arbres, tous avec leur collision) ;
  - `run_tests` : 52 réussis, 0 échec ;
  - aucune erreur de script.
- **Captures avant et après**, regardées (hors dépôt, dans `.claude/captures/finitions-plaine/`) :
  - `avant/` : le parcours d'origine ;
  - `apres/vues/` : le grondement à l'arrivée (0 ; 0,6 ; 2,2 ; 4,7 s, puis après), les étendards (ouest, engins de siège, piétiné, batterie, tombes, barricade) et la brèche (entrée, de face, de côté, d'en dessous, de dos, de dessus sans le plafond) ;
  - `planches/` : avant | après | écart des vues figées.

## Fichiers

| Fichier | Rôle |
| --- | --- |
| `scenes/levels/plaine/plaine_rumble.gd` | Grondement du volcan : panache, projections, lueur, brouillard, son, corbeaux |
| `scenes/levels/plaine/library_breach.gd` | Voûte percée : plafond percé, ciel, rai, tache au sol, poussière, cendre, vent |
| `scenes/levels/plaine/breach_light.gdshader` | Lumière de la brèche, additive (rai, tache au sol, ciel et braises) |
| `scenes/levels/plaine/plaine_life.gd` | Couleurs de Vibelandia sur ses bannières, corbeaux effarouchés par le volcan, bannières couchées immobiles |
| `scenes/levels/plaine/plaine.tscn` | Nœuds `Exterior/VolcanoRumble` et `Interior/Breach`, planche de couleurs de Vibelandia, journal du soldat |
| `tools/build_plaine.py` | `standards` (étendards), `breach_rubble` (gravats de la brèche), `VIBELANDIA_CAMPS`, `BREACH` |
| `assets/shader_warm_list.tres` | Inventaire des shaders, régénéré |

Le README de la Plaine n'est pas modifié (consigne : aucun README). Sa liste de fichiers ne cite donc pas encore ces trois nouveaux fichiers.
