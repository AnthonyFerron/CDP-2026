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

## Reste à faire

- Soleil en 2 tranches d'ombre au lieu de 4 (le Marais l'a fait) : à mesurer à part, avec des planches avant et
  après, car le grain des ombres change.
- `MaraisBatch` et `PlaineBatch` gagneraient à devenir un seul outil partagé dans `scripts/`, interdit aux agents de
  lieu.
