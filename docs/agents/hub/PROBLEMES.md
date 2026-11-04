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
