# Hub : passe au centimètre, problèmes relevés

Méthode :
- grille de marche à 0,5 m dans 8 directions (`walk_grid.gd`, `grid_all.sh`), dans les 5 états (0 à 4 livres posés) ;
- objets qui flottent ou s'enfoncent, modèle par modèle (`float_check.gd`), à 0, 2 et 4 livres ;
- 522 vues de captures (`gen_views.py`, `caps.sh`), planches dans `cap/` : maisons, plafonds, chemins, château, rivière, ponts, lieux (0 à 4 livres), bunker, montagnes ;
- portes, interactables, ponts et gué (`hub_audit.gd`).

Les chemins des captures sont relatifs à `$S/agents/hub/`.

## Corrigés

| # | Où (x, z) | Capture | Cause | Correction |
|---|-----------|---------|-------|------------|
| 1 | Maisons, quartiers et salle du château | grille de marche (sans collision) | Les chaises, tabourets, bancs, plantes en pot, la roue et le banc abîmé n'avaient pas de collision. | Liste `SOLID` dans `furniture()` : boîte à la hauteur du modèle. |
| 2 | Coins des 27 bâtiments | grille | Les piliers d'angle n'avaient pas de collision. | Boîte de 0,6 m, en ruine comme reconstruits. |
| 3 | Portes des maisons ; étal ; échelle du moulin ; statues des rois ; bordures des parterres | grille | Sans collision. | Boîtes à leur forme. |
| 4 | Trône et estrade (0, -86) | grille | Une seule boîte pour les deux. | Deux collisions séparées (`write_hub_tscn.py`). |
| 5 | Barrière de l'enclos (18, -66) | grille | Sa boîte était décalée du modèle. | Boîte replacée à (18, -68). |
| 6 | Maisons en ruine | `cap/maisons_0_*.png` | Les poutres tombées étaient debout. | Couchées (roll 90°). |
| 7 | Rochers de la vallée | grille (murs invisibles) | Leur collision montait à 3 m. | Collision à la hauteur du modèle. |
| 8 | Foin, sacs, râtelier, banc abîmé, tonneau du lavoir, colonnes du kiosque, panneaux du bunker | `float_check` | Ils flottaient ou s'enfonçaient. | Reposés au sol. |
| 9 | Haies est du jardin (52, -80) | `cap/lieux_*` | La berge de l'étang creusait le sol sous les haies. | Étang réduit, `POND_BANK` à 1,5 m, rivière décalée vers l'est au nord. |
| 10 | Débris du grand pont (64,7, -3,8) | `fl/pierre_pont.png`, `float_check` | Ils étaient enfoncés ou flottaient. | Posés à la hauteur du lit. |
| 11 | Toutes les maisons à un étage | `fl/plafond.png` | Il n'y avait pas de plafond : vu d'en dessous, le toit laissait voir le ciel. | Plafond de planches. |
| 12 | Planchers de toutes les maisons | `fl/plancher.png` | On voyait de l'herbe verte entre les lattes. | Sous-plancher croisé d'une pièce, et terre sombre sous l'emprise des bâtiments (`BUILDING_FLOORS`). |
| 13 | Tous les toits : maisons, quartiers, lavoir, halle | `aa/1_toit_avant.png`, `aa/2_toit_apres.png` | Les toits étaient montés à l'envers, en V (« papillon »). La tuile « roof » est basse du côté de son x négatif, et elle était tournée vers l'intérieur. | `roof()` tourne le côté bas vers la gouttière. Le faîte suit le côté pair, et le toit plat du milieu des côtés impairs passe au faîte. |
| 14 | Plafonds des maisons à un étage | `aa/3_plafond_avant.png`, `aa/4_plafond_apres.png` | Deux fentes turquoise : le creux du toit en V touchait le plafond, et on voyait les tuiles entre les lattes. | Toit corrigé (n° 13), plus un panneau de bois plein au-dessus du plafond (un mur de planches couché, d'une seule pièce). |
| 15 | Plafond de l'abri (bunker) | `cap/bunker_1.png` | Fentes vertes : la dalle au-dessus était une tuile de toit verte. | Panneau de bois plein. |
| 16 | Arbres du jardin (50, -56), (50, -61) et (35, -75,6) ; verger ; arbres épars | `aa/5_jardin_avant.png`, `aa/6_jardin_apres.png` | Le feuillage descendait à hauteur des yeux. | Échelles relevées : jardin 4,2 à 4,4 ; verger 3,6 ; arbres épars 4,0 à 5,4 (au lieu de 3,2 à 5,0). |
| 17 | Sapins de mini_forest et `tree_fat` | mesure des modèles (`glb_canopy.py`) | Leurs branches basses descendent sous 1 m : la caméra entrait dans le feuillage en touchant le tronc. | Collision à la largeur des branches basses (0,27 et 0,36 à l'échelle 1). |
| 18 | Pierres des murs écroulés (59, 16) | `float_check` | Elles flottaient à 4 cm du sol. | Posées à -0,08. |
| 19 | Outil `check_overlaps_hub.py` | — | Il réécrivait `hub_bunker.tscn` avec une ancienne règle de boîte. | Il n'écrit plus rien. |

## Restants, acceptés

- **Pierres dans les bassins** de la fontaine (30, 4,2) et du lavoir (55, 6). `float_check` les signale, mais elles reposent dans l'eau du bassin, dont le modèle n'a pas de collision (`fl/fontaine.png`, `fl/lavoir.png`).
- **Murs invisibles voulus** :
  - `River/Banks` : on ne traverse pas la rivière à gué ;
  - `Terrain` : la limite au pied des montagnes.
- **Sans collision, accepté** :
  - les portails ouverts, où l'on entre ;
  - les blocs extérieurs du bunker, inaccessibles ;
  - le bâton de Merlon ;
  - un sac plat de 30 cm à la boulangerie en ruine (51,5, 33,5).
- **Engins de siège de la cour reconstruite** : leurs boîtes sont un peu plus grandes que le modèle, et le joueur s'y arrête quelques centimètres avant.
- **Source de la rivière** (vue `montagnes_*/nord_est`) : la rivière sort de sous un gros rocher, au fond de la gorge.
- **Escaliers** : il n'y en a aucun dans le hub.

## Résultats finaux

- **Grille de marche**, dans les 5 états : 0 trou, 0 ressaut, 0 chute, 0 glissade, 0 sortie de vallée. Les seuls objets sans collision sont ceux de la liste ci-dessus.
- **`float_check`** : 0 objet flottant et 0 enfoncé à 4 livres. À 0 et 2 livres, ne restent que les pierres des bassins, qui sont de faux positifs.
- **`hub_audit`** à 0 et 4 livres : seuls échouent les deux contrôles « traverser la rivière à gué », qui doivent échouer.

## Intérieurs des nouveaux bâtiments (nuit du 4 au 5 novembre 2026)

Méthode : `overlaps.py` (meuble contre mur et meuble contre meuble, polygones au sol, dans chaque ruine et chaque
reconstruction), grille de marche à 0,5 m de chaque intérieur depuis le dehors de sa porte (`walk_grid.gd`, avec
poches inaccessibles et plafond au-dessus de chaque case), captures à hauteur d'yeux (porte vue du dehors, entrée,
fond, quatre coins, huit directions depuis le centre, plafond) à 0 et 4 livres, regardées une par une.
Outils et captures : `~/cdp-work/hub/` (`tools/`, `shots/`, `grid/`).

| # | Où | Constat (capture) | Cause | Correction |
|---|----|-------------------|-------|------------|
| 1 | Boulangerie (49, 32) | `q4/Bakery_fond.png` : un réverbère au milieu de la boulangerie | Lanterne de ruelle (`build_quarter_paths`) posée dans l'emprise du bâtiment | Retirée : la lanterne de la porte suffit |
| 2 | Herboristerie (-56, 28) | `q4/Apothecary_dehors.png` : pied et tête d'un réverbère qui sortent du mur | Lanterne de ruelle dans le mur est | Déplacée au coin du jardin des simples (-55,2, 24,6) |
| 3 | Boulangerie, herboristerie, 16 maisons | `q4/Bakery_entree.png` : flammes vertes au pied du four | Le brasero du kit cimetière (remplaçant médiéval du fourneau) a des flammes vertes | Âtres de pierre (manteau `chimney-base`) avec bûches et braises orangées (`Embers`) |
| 4 | Tous les bâtiments | `q4/*_dehors.png` : cheminée du toit au-dessus d'un mur sans foyer | Cheminée toujours posée au même endroit du toit | La cheminée sort au-dessus de l'âtre (`HEARTHS`) ; sans âtre (école, chapelle, moulin, écuries, scriptorium), pas de cheminée |
| 5 | École, taverne, ferme, caserne, scriptorium, 16 maisons | `q4/School_entree.png`, `q4/Farm_*.png`, `q4/Barracks_*.png` : bureaux, tables rondes, chaises, étagères et lits superposés blancs et roses, plante en pot | Meubles du kit mobilier moderne | Tables, chaises et coffres de bois (mini_dungeon, survival_kit), étagères de planches sur montants (`shelf`), lits de bois à paillasse (`bed`) |
| 6 | Tous les intérieurs | `q4/*` : intérieurs bleutés, éclairés par le ciel seul | Aucune lumière dans les bâtiments | Lumières chaudes (`hub_lamp.gd`), allumées en fondu à l'approche, portée arrêtée avant le sol du dehors (`lamps.py` : 0 fuite) |
| 7 | 27 ruines | `check_overlaps.py`, `overlaps.py` : 8 poutres dans les murs, une quarantaine dans les meubles | Poutres tombées posées au hasard | `fallen_beams` cherche une place libre, à l'écart des murs et des meubles |
| 8 | Portes des 27 bâtiments | — | `doorway()` laisse ±0,95 m pour une arche visible de ±0,80 m | `arch_fill()` après chaque porte |
| 9 | Plafonds des bâtiments reconstruits | — | Plafond sans collision : depuis un coffre ou une table, un saut passait la tête dans l'étage | Collision du plafond (3,8 à 4,1 m) ; plafond solide aussi dans l'observatoire |
| 10 | Boulangerie, caserne, scriptorium, observatoire | — | Textes annoncés dans les commentaires (livre de comptes, registre, page, carnet), jamais posés | Readables posés sur les meubles, et de nouveaux textes dans les autres bâtiments |
| 11 | Taverne | `q4/Tavern_*.png` : deux tables et quelques chaises dans une salle de 12 m | Intérieur commencé | Âtre, comptoir et tonneaux, tabourets, trois tables, ardoise, tonneau réservé, échelle |
| 12 | Chapelle | `q4/Chapel_entree.png` : une croix au fond | Le panneau parle de quatre lutrins et d'une prière gravée | Quatre lutrins de pierre, prière gravée au mur, Readable, deux rangs de bancs |
| 13 | Forge | `q4/Forge_*.png` : pas de foyer | — | Foyer, baquet, boucliers, outils, carnet de commandes |
| 14 | Étages (école, taverne, caserne, scriptorium) | `q4/*_dehors.png` : fenêtres à l'étage, rien dedans | Pas d'accès à l'étage | Échelle appuyée jusqu'au plafond (l'étage reste fermé) |
| 15 | Moulin | `q4/Mill_*.png` : meule au milieu, l'axe de la roue s'arrête au mur | — | Meule contre le mur est, axe prolongé dedans jusqu'à elle |
| 16 | Taverne, école, chapelle, ferme | `plans/*_4.png` (plans de marche) : allées de 0,6 à 0,76 m, zones de la salle inaccessibles | Tables, bancs et rangs trop serrés | Allées d'au moins 0,85 m ; plus aucune zone libre inaccessible dans ces salles |
| 17 | Observatoire | `v1_4/Observatory_*.png` : herbe entre les planches, coins du plafond ouverts | Plancher et plafond plus petits que la salle, une seule couche | Deux couches croisées, jusque sous les murs |
| 18 | Écuries, observatoire | `v1_4/Stables_coin2.png` : lanterne vert-bleu | Lanterne du kit cimetière | Chandeliers |
| 19 | Lits | `v1_4/Farm_coin2.png` : le « lit » est un tréteau en X | `bedroll-frame` n'est qu'un cadre | Lit de bois : cadre de planches, pieds, paillasse, traversin |
| 20 | Observatoire | `gallery_tower.png`, `v1_4/Observatory_fond.png` : on passait à travers une porte de bois fermée | La porte du modèle de tour est pleine ; la collision lui laissait un trou | Mur plein, et la porte se passe avec E dans les deux sens (`tower_doors`, `hub.gd`), avec un fondu |
| 21 | Moulin | `gen_reads.py` : le cahier du meunier hors de portée (coincé entre la table, l'échelle et la façade) | Cahier au bord de la table, côté façade | Posé au milieu du bord arrière de la table |
| 22 | Grandes maisons (3 cases) | `plans/House08_4.png` : grande salle vide | Meubles des maisons de 2 cases | Second lit, tonneau et sac ; banc et tonneau dans les maisons profondes |
| 23 | Chapelle | `v1_4/Chapel_entree.png` : la prière gravée n'apparaît pas au mur | L'inscription et son Readable portaient le même nom : l'un écrasait l'autre | Nœud `PrayerText` ; `pivot()` refuse désormais deux nœuds au même chemin |
| 24 | Forge | — | Les armes forgées pour l'armée n'apparaissaient nulle part | Trois épées dans le tonneau du coin, la lame dedans |
| 25 | Herboristerie, boulangerie, école, scriptorium, maisons | `c2_4/Apothecary_coin1.png`, `c2_4/Bakery_fond.png` : étagère plaquée devant une fenêtre | Fenêtres tirées au hasard sur chaque case de mur | Murs pleins derrière les étagères (`PLAIN_WALLS`) |
| 26 | Observatoire | `c2_4/Observatory_entree.png` : lignes d'herbe entre les lattes | Le sol du terrain affleure sous le plancher de la tour | Terre sombre sous la salle (`BUILDING_FLOORS` de `hub_terrain.gd`) |
| 27 | Tous les intérieurs | `c2_4/Tavern_plafond.png` : taches éblouissantes au plafond | Lampes à 0,5 m sous le plafond | Lampes à 3 m, énergie 1,45 |
| 28 | Écuries (ruine) | `rooms_0.log` : entrée bloquée à 1 m de la porte | Roue tombée à plat dans le passage de la porte | Roue tombée au milieu de l'allée |
| 29 | Taverne, chapelle, écuries (ruines) | grille : coupe des dragons, lutrins couchés et foin tombé sans collision | — | Collisions à leur taille |

### Outils de la nuit (`docs/agents/hub/interieurs/`, chemins du serveur)
- `overlaps.py` : meuble contre mur et meuble contre meuble, dans chaque ruine et chaque reconstruction ; `lamps.py` : portée de chaque lumière contre la distance au sol du dehors ; `plan.py` : plans de marche au décimètre (collisions, cases atteintes depuis le dehors de la porte, poches), sans Godot.
- `walk_grid.gd` (grilles à 0,5 et 0,25 m, poches, plafond au-dessus de chaque case), `rooms_walk.gd` (entrer et sortir de chaque bâtiment, porte de l'observatoire avec E, lecture de chaque texte), `float_check.gd` (objets qui flottent ou s'enfoncent, petits objets compris), `shots.gd` (captures et planches), `gen_views.py` (caméras posées sur des cases atteintes), `cycle2.sh` (tout le tour).
