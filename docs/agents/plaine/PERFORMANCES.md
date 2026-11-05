# Performances web des plaines d'Hexcole (BACKLOG n° 5) : en cours

Nuit du 4 au 5 novembre 2026, interrompue par la clôture avancée (03 h 05 UTC). Seules les mesures « avant » sont
faites ; le regroupement du décor est écrit mais pas vérifié, donc pas commité.

Méthode et outils : ceux du Marais (`docs/agents/marais/PERFORMANCES.md`), adaptés dans `perf/` :
`perf_plaine.gd` (comptes, 10 vues mesurées, captures figées), `shots.txt` (16 points de capture, dehors et dedans),
`perf.sh` (lanceur), `diff_images.gd` (planches avant | après | écart), `collisions.gd` (relevé trié des formes de
collision et grille de marche rapide par remplissage, dehors à 0,6 m et dans les archives à 0,3 m).

Serveur Linux arm64, rendu logiciel llvmpipe sous Xvfb, 1280 x 720, rendu Compatibility, sans synchronisation
verticale, 30 images par vue après 15 de mise en route. Les temps d'image ne valent que pour comparer, d'autres Godot
tournaient en même temps. Les appels de dessin sont exacts.

## Avant (commit 69a21ae + fusion de dev d2f0fca)

Tout le niveau : 4 721 nœuds, 758 maillages, 162 MultiMesh (2 319 instances), 839 objets qui projettent une ombre,
19 lumières (une seule ombre : le soleil, 4 tranches jusqu'à 70 m), 30 émetteurs de particules, 3 266 formes de
collision, 144 objets à distance de visibilité. Chargement mesuré : 6 949 ms (premières images et shaders compris).

| Vue | Appels de dessin | Image médiane | Primitives | Lumières ponctuelles proches |
| --- | --- | --- | --- | --- |
| o1 arrivée (0 ; 54) vers la bibliothèque | 1 308 | 636 ms | 127 754 | 6 |
| o2 pont | 878 | 633 ms | 109 227 | 9 |
| o3 façade | 1 047 | 645 ms | 87 890 | 10 |
| o4 campement | 458 | 562 ms | 78 520 | 9 |
| o5 engins de siège | 956 | 640 ms | 74 916 | 9 |
| o6 batterie | 292 | 613 ms | 57 962 | 5 |
| o7 vue haute | 949 | 580 ms | 132 664 | 0 |
| i1 salle de lecture | 460 | 312 ms | 59 120 | 3 |
| i2 scriptorium | 310 | 285 ms | 46 350 | 5 |
| i3 archives | 159 | 196 ms | 32 146 | 5 |

Lecture des comptes :
- dehors, les appels de dessin dépassent de loin les surfaces visibles comptées par branche (environ 320 à l'arrivée) :
  le soleil redessine chaque objet qui projette une ombre dans ses 4 tranches, et la suie des ruines et du champ de
  bataille (`material_overlay`) double chaque surface ;
- dedans, aucune ombre, mais la suie des archives double aussi les surfaces : 281 surfaces de la bibliothèque pour 460
  appels dans la salle de lecture.

Sous les pieds, avant (`collisions.gd`, regroupement désactivé) : 3 265 formes de collision, empreinte du relevé
trié `100d7f9e10f417cca8391282535a7030` ; grille de marche : 30 962 cases dehors, 2 348 dans les archives,
empreinte `35c814a6936278a221bdbb5db1d9569d`. Après le regroupement, les deux empreintes doivent rester les mêmes.

## Prochaine étape (non commitée, dans la copie de travail de la branche)

- `PlaineBatch` (`scenes/levels/plaine/plaine_batch.gd`, copie de `MaraisBatch` avec une liste de modèles laissés à
  part) et `_batch_decor()` dans `plaine.gd` : ruines et champ de bataille fondus par matériau et par case de 32 m,
  archives par case de 12 m, une fois la suie posée et les enveloppes de collision tirées des modèles. Rien ne
  s'efface au loin et chaque objet garde son ombre ; les bannières (`flag_*`, animées par `plaine_life.gd`) restent
  à part.
- À faire avant de commiter : mesures « après » (`perf.sh … apres …`), planches de captures avant et après aux 16
  points (`diff_images.gd`), relevé des collisions et grille de marche identiques (`collisions.gd`), puis
  `plaine_puzzle_test`.
- Piste suivante, à mesurer à part : soleil en 2 tranches au lieu de 4 (le Marais l'a fait), à condition que les
  planches ne montrent qu'un grain d'ombre différent.
