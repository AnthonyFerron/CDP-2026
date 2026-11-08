# Problèmes des plaines d'Hexcole (passe au centimètre)

Dossier des preuves : `agents/plaine/` (journaux `*.log`, captures dans `passe/`, `passe/avant/`, `passe/apres/`,
`lava_avant/`, `lava_apres/`, `books/`, `grille/`).

## Trouvés et corrigés

| # | Où (x, z) | Vu par | Cause | Correction (commit) |
| --- | --- | --- | --- | --- |
| 1 | Rayonnages, 6 livres à fragment | demande, `books_test` | Un livre fouillé restait sur l'étagère, toujours cliquable | Il disparaît, n'est plus interactif, l'état tient en ressortant (fc59d11) |
| 2 | Coulée, (21,0 ; 26,8) et (-22,0 ; 21,0) | demande, `lava_test`, `lava_avant/` | La coulée s'arrêtait avant les lacs ; zone qui brûle plus large que la lave | Lit prolongé dans les lacs, niveau fondu dans le leur ; zone en bandes courtes (0236001) |
| 3 | 3 passages intérieurs et la dalle | grille dedans | L'arche visible (± 0,80 m) plus étroite que le trou de collision (± 0,95 m) : on traversait ses montants | `arch_fill()` (673da60) |
| 4 | Inscription des archives (3,9 ; -35,75) | grille dedans | Panneau sans collision | Boîte à sa taille (673da60) |
| 5 | Gravats, lustre tombé, livres au sol, chaise renversée, caisse du coin | grille dedans | Boîtes plus hautes ou plus larges que l'objet ; caisse fermant un recoin | Objets bas sans collision, boîte orientée pour la chaise, caisse déplacée (673da60) |
| 6 | Toute la plaine | grille dehors : 1 897 cases de mur invisible, 357 maillages traversables | Boîtes droites autour d'objets couchés ou penchés, épaves, tentes et charrettes en boîte, troncs penchés en cylindre droit, rochers du pourtour sans collision, hampes, bannières, épées | Boîtes orientées (`furniture_fit`, `leaning_box`), enveloppes convexes des épaves/tentes/charrettes/tas de pierres (`plaine.gd`), cylindres qui suivent le tronc, collisions des rochers du pourtour, planches et gravats sous la cheville (2943f79) |
| 7 | Gros rochers, ex. (-19,7 ; -16,2), (32,3 ; 45,4) | grille dehors | Un gros rocher est un groupe de blocs : son enveloppe convexe comblait les creux (murs invisibles de 3 à 4 m) | Collision au maillage même (2943f79) |
| 8 | Lanternes couchées | grille dehors | Bougie au bout de la lanterne hors de sa boîte | Boîte allongée (2943f79) |
| 9 | Petite salle, urnes en (± 1,35 ; -39,0) | `walk_test` (bloqué en (± 0,9 ; -39,7)) | Avec le pupitre, elles fermaient les deux côtés : le fond de la salle était inaccessible | Urnes au fond, en (± 1,35 ; -42,3) (1694f1c) ; avant/après : `passe/avant/petite_salle_14_08.jpg`, `passe/apres/petite_salle_14_08.jpg` |
| 10 | Haut de l'escalier oublié (0 ; -36,5) | `walk_test` | Projenomicon à 3,1-3,5 m, rayon 3,0 : on ne pouvait pas le prendre du haut de l'escalier | Rayon 3,6 (1694f1c) |
| 11 | Trébuchet (-16,4 ; 41,2), fumée des ruines, volcan | planches 07-08 | Les `SmokeEffect` de la scène ne prennent pas leur préchauffage au chargement : pendant ~10 s, une boule sombre de 5 m au pied du feu | Relancées une fois la scène prête (ee1c0c2) ; `passe/avant/fumee_trebuchet.png`, `passe/apres/fumee_trebuchet_dehors_08.png` |
| 12 | Remparts, ex. vers (-55 ; -32), (-56 ; 16) | planches 28-29 | Rochers posés à la hauteur de leur centre : sur la pente, leur bord pendait dans le vide | Enfoncés pour que le dessous de leur maillage passe sous le sol en 25 points de l'emprise (4b5156b, 5af4add) ; `passe/avant/rochers_remparts_*.jpg`, `passe/apres/rochers_remparts_*.jpg` |

Défauts des outils de test, corrigés (ils cachaient des problèmes) :
- grille : les triangles du terrain remplissaient les résultats des requêtes de la couche visuelle (des maillages visibles passaient pour absents) ; le terrain n'est plus dans cette couche et les requêtes rendent 32 résultats ;
- grille : le rayon qui cherche le sol partait au-dessus du plafond du passage : l'escalier et la petite salle n'étaient pas parcourus (c'est ainsi que l'urne du n° 9 avait échappé à la grille) ;
- planches : la caméra se posait sur le dessus des meubles ; le menu de pause, ouvert par la perte du focus, couvrait les vues ; sans `--fixed-fps`, le temps des particules ne suivait pas.

## Résultat après corrections

- Grille dehors (0,5 m, 46 499 cases) : 0 problème ; grille dedans (0,25 m, escalier et petite salle compris) : 0 problème.
- `walk_test` : 159 vérifications, 0 échec (escalier du bas, du haut, de chaque côté et le long des murs, chaque marche ; passages dans les deux sens ; pont dans les deux sens et parapets ; portes, tablette, portail, Projenomicon de chaque place).
- `audit_test` 93 OK, `lava_test` 7 OK, `limit_test` 24 OK, `books_test` 31 OK, copie de `plaine_puzzle_test` 34 OK : 0 échec.
- Planches : 18 dedans (27 points tous les 4 m environ, 8 directions, coins, plafonds), 35 dehors (140 points : tous les 4 m sur les lieux garnis, tous les 16 m ailleurs, 4 vues de 96° ; raccords du pont, des ruines, du portail, des rives), toutes regardées.

## Récit environnemental (nuit du 4 au 5 novembre 2026)

Six textes à lire ajoutés (trois dehors, trois dans les archives), écrits par `tools/lore.py` dans `plaine.tscn` et
contrôlés par `lore_test.gd` (archivés dans ce dossier) : pose au sol, au mur ou sur le meuble, collision sans
chevauchement, texte dans la planche, sol accessible à portée, ligne de vue, invite, lecteur entier dans l'écran ; en
mode `all`, l'invite de chacun des autres interactables du lieu, pour vérifier qu'aucun texte ne la leur vole.

| # | Où (x, z) | Vu par | Cause | Correction |
| --- | --- | --- | --- | --- |
| 13 | Pupitres du scriptorium, table du capitaine au camp (`mini_dungeon/table`) | capture rapprochée des notes du greffier | Dessus pris à 0,31 x 2,2 = 0,682 m, le maillage monte à 0,693 m : feuillets et parchemin enfoncés dans le plateau (invisibles), bougies et encriers enfoncés d'un centimètre | `DUNGEON_TABLE_TOP = 0,315`, mesuré sur les sommets du maillage |
| 14 | Table de lecture (`furniture_kit/table`) | mesure des sommets | Dessus pris à 0,33 x 3 = 0,99 m pour 0,981 m : livres, livre ouvert, feuillets et chandelier flottaient de 9 mm | `TABLE_TOP = 0,327` |
| 15 | Affiche de la fête (3,7 ; 47,2) | captures `fete_side`, `fete_far` | Une touffe d'herbe brûlée poussait entre les poteaux | Panneau avancé au bord du chemin, en (3,3 ; 47,8) |
| 16 | Proclamation (-8,0 ; 8,27) | capture `procl_far` | Depuis le chemin, la colonne de la façade la cachait | Décalée sur le mur, en (-8,9 ; 8,27) ; titre en trois lignes avec un « V » seul, remplacé par une vraie affiche (titre, ordre, signature) |
| 17 | Lettre de la bibliothécaire | `lore_test` (cadre du lecteur) | 18 lignes : le lecteur prenait presque tout l'écran (50 à 1030 px sur 1080) | Texte resserré |
| 18 | Notes du greffier | `lore_test` | Rayon 1,8 : 5 places seulement d'où lire | Rayon 2,2 |

Résultat : `lore_test all` 160 OK, 0 échec (les 6 textes et les 20 autres interactables du lieu gardent leur invite) ; `plaine_puzzle_test` 34 OK ; `signboard_test` 8 OK ; les trois indices (fenêtre H) tiennent dans leur cadre ; captures rapprochées de chaque texte (face, profil, depuis le chemin), toutes regardées.

## Dos sombres à contre-jour (nuit du 4 au 5 novembre 2026, relevé dans RESTE_A_FAIRE.md)

| # | Où (x, z) | Vu par | Cause | Correction |
| --- | --- | --- | --- | --- |
| 19 | Panneaux sur poteaux : entrée (-4,6 ; 46), fête des foins (3,3 ; 47,8), arpenteur (-4,3 ; 35), ordre d'évacuation (7,7 ; 44,5) | captures de dos, depuis le chemin du retour et le camp | Planche nue et sombre au dos, face au soleil de l'autre côté | `double_sided` (texte et cadre au dos) ; faible lueur chaude derrière l'entrée et l'affiche de la fête, vues de dos en revenant au portail (0,6, portée 2,5 m, éteinte entre 38 et 46 m), comme au Marais |
| 20 | Rayonnages debout des ruines (-7 ; -7) et (7 ; -4) | captures de dos, côté brèches | Dos presque noir, tourné vers le mur, à l'ombre | Faible lueur chaude entre chaque dos et son mur (0,6, portée 2,6 m, éteinte entre 38 et 46 m) |

Les rayonnages des archives sous la carte sont tous adossés à un mur : leur dos ne se voit pas.
Captures avant et après aux mêmes points : `dos/avant`, `dos/apres`, `dos/apres2` du dossier de travail.
`plaine_puzzle_test` (34 OK) et `signboard_test` (8 OK) : 0 échec.

## Restent, signalés

- `scripts/smoke_effect.gd` (interdit) : le préchauffage ne prend pas quand la fumée est chargée avec une scène. Contourné dans la Plaine ; le Village et le volcan du hub ont le même défaut.
- Grille : 1 732 cases marchables dehors ne sont pas atteintes : dessus d'objets et de rochers, et creux sous les épaves ; aucune zone fermée d'1 m² ou plus.
- La comparaison collisions/maillages commence à 0,3 m du sol : un objet de moins de 22 cm se traverse, par choix (on l'enjambe).
- Les vignettes font 320 x 180 (vues entières en 640 x 360 dans `passe/dedans/` et `passe/dehors/`) : un défaut très fin a pu passer.
- Le dos des rayonnages isolés du scriptorium paraît noir de tout près (ombre, pas de lumière derrière) : laissé.
- `plaine_puzzle_test.gd` partagé attend « Relire » après la lecture d'un livre ; le livre disparaissant, il échoue : ma copie est adaptée.
- `res://tests/run_tests.tscn` (PR #12) : 49 réussis, 1 échec « --mail-dir est requis pour lire les codes de connexion » (il faut le serveur de courrier `tests/mailsink.py`, sans lien avec la Plaine).

## Retours des testeurs (5 novembre 2026)

Les testeurs jouaient la production (`main`), qui n'avait pas encore les corrections de collisions de la nuit (2943f79 : rochers du pourtour, enveloppes des épaves et des tas de pierres, gros rochers au maillage ; 673da60 : arches et objets bas des archives). Captures avant et après : `.claude/captures/plaine-retours/avant` et `apres`.

| # | Retour | Cause | Correction |
| --- | --- | --- | --- |
| 21 | Lanternes du chemin et lampadaires de la façade sans collision | Seul le poteau avait une boîte ; la potence et la lanterne qui pend (1,9 à 2,5 m) se traversaient en sautant | Boîte de la potence et de la lanterne, de 1,7 m (sous le haut du joueur) au haut du poteau (`LANTERN_HEAD`, `plaine_scatter.gd` et `lantern_post`) |
| 22 | Bibliothèque extérieure sans collision, « texture mal placée » | Murs brisés : collision en boîte pleine jusqu'à 3 m, alors que le maillage monte à 4 m par endroits et s'ouvre ailleurs (grille : mur invisible en (-4 ; 1,5 ; -12), mur du fond) | Murs refaits (n° 23) |
| 23 | Vue extérieure sans lien avec l'intérieur | Ruine ouverte de 20 x 20 m, sans toit, vide derrière ses brèches, alors que les archives sont des salles entières | Bâtiment entier de 12 m de large (comme les archives) sur 28 m, mêmes murs `wall`, porte au centre, étage de façade à fenêtres, long toit à deux pans en croupe, plafond de collision ; gravats et deux rayonnages jetés dehors ; carreaux plantés devant le nouveau mur du fond ; proclamation déplacée sur la façade (-4,3 ; 8,57) ; fumée sur le toit ; lumières des dos des anciens rayonnages retirées |
| 24 | Livres au sol à travers un anneau (archives) | Le lustre tombé (-1,6 ; -29) était dans les livres répandus par le rayonnage renversé du mur ouest | Lustre tombé en (2,7 ; -29,6), à l'écart |
| 25 | Tablette qui ne « tient » pas | Plaque penchée : son bord arrière flottait à 20 cm au-dessus du socle | Cale de pierre sous la plaque (`Interior/Tablet/Top/Support`) |
| 26 | Sortir de la carte | Aucune sortie retrouvée sur `dev`, ni dehors ni dans les archives (`border_test.gd`, `limit_test`) ; la production n'avait pas encore les collisions des rochers du pourtour (2943f79) | Rien à fermer en plus ; l'outil reste ici pour la suite |
| 27 | Portes voûtées des archives (3 passages), relevé de l'orchestrateur (8 novembre) : au-dessus de 2,3 m, `arch_fill()` arrête la tête avant l'arche visible | Trois marches (±0,8 m jusqu'à 2,3 m, ±0,5 m jusqu'à 2,7 m, puis ±0,15 m) pour un intrados en quatre pans : 0,22 m de mur invisible à 2,71 m et 0,10 m d'entrée dans l'arche à 2,69 m (`arch_profile.gd`, archivé ici : rayons du milieu de l'ouverture vers les montants tous les 2,5 cm, contre la collision et contre l'arche visible recopiée) | `ARCH_PROFILE` (intrados relevé sur les sommets du modèle) et `ARCH_TOLERANCE` (4 cm) dans `build_plaine.py` : 8 marches, chacune au milieu de ce que l'arche gagne sur sa hauteur ; 0,040 m au plus de mur invisible et d'entrée aux 3 arches (et aux 13 du Village). Captures des collisions avant et après : `.claude/captures/verif-marche/arches/planche_archives.png`, profil : `arches/profil_arche.png`. Sonde de saut des archives repassée (`plaine_jump_probe.gd`, 960 cases) : énigme résolue, 15 360 sauts, 3 446 arrivées hors du sol accessible (178 calées en l'air entre deux meubles, toutes avec une issue), 0 point coincé ; dalle fermée, 14 512 sauts, 3 142 arrivées, 0 point coincé. `build_plaine.py` relancé deux fois : aucune dérive. |

`border_test.gd` (archivé ici) longe chaque bord en marchant puis en courant et sautant, appuyé à 25° contre lui, dans les deux sens : dehors tous les 7,5° du cercle de la limite (192 parcours), dedans le long de chaque mur des salles, du passage et de la petite salle, dalle ouverte (34 parcours).

Résultats après corrections : `plaine_puzzle_test` 34 OK, 0 échec ; `tree_collision_test` (fenêtre) : Plaine 38 arbres, 0 sans collision ; grille dehors 0 problème (avant : 1 mur invisible, mur brisé du fond), grille dedans 0 problème ; `limit_test` 24 OK ; `border_test` dehors 192 parcours et dedans 34 parcours, 0 sortie. `build_plaine.py` relancé deux fois : aucune dérive.
