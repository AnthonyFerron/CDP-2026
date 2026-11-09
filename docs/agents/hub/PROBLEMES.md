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
| 30 | Forge et caserne (ruines) | `float_check` : râteliers couchés à 0,36-0,39 m du sol | Boîte du modèle plus profonde que lui | Abaissés de 0,15 m par unité d'échelle (`RACK_SINK`) |
| 31 | Chapelle et herboristerie (ruines) | `float_check` : chandelier et fioles enfoncés de 0,16 à 0,27 m | Posés par leur origine, couchés | Posés au sol par leur boîte, à l'écart des meubles |
| 32 | Lits | `float_check` : traversins à 4 cm au-dessus de la collision du lit | Collision plus basse que la paillasse | Collision jusqu'au dessus de la paillasse |
| 33 | Observatoire | `rooms_4.log` : au point d'arrivée, E proposait de ressortir au lieu de lire le registre | Arrivée à moins d'un mètre de la porte (invite sans regard) | Arrivée à 1,1 m de la porte |
| 34 | École, ferme, forge, scriptorium | grille au quart de mètre : coins et allées de 0,85 à 1 m sans une case libre | Passages tout juste plus larges que le joueur | Rangées, établi, marmite et pupitres décalés : passages d'un mètre au moins |
| 35 | Ferme | grille au quart de mètre après le recul de la marmite (80a9351) | — | Contrôlée : 1 case de 25 cm au pied de l'arche de la porte (artefact), 0 trou, 0 mur invisible ; rien à corriger |
| 36 | Cour du château (reconstruite) | grille de la cour : 3 à 4 murs invisibles derrière la catapulte | La boîte de la catapulte montait à 2,6 m sur toute sa longueur, au-dessus de son bras qui traîne bas ; celle de la baliste débordait de 0,86 m d'un côté | Boîtes à l'emprise des sommets mesurés (`ENGINE_FOOTPRINTS`, `engine_box`) : bâti haut, bras bas sous la hauteur d'un pas, baliste à sa taille ; grille de la cour à 0 mur invisible et 0 objet sans collision |

### Résultats (tour c4, puis c5 pour la ferme)
- Tests : `hub_test` 0 échec ; `hub_walk_test` 0 et 4 : seuls les 2 échecs voulus « limite infranchissable (doit echouer) » ; `rooms_walk` 0 et 4 livres : 0 échec (12 bâtiments entrés et quittés, porte de l'observatoire dans les deux sens, 13 textes lus).
- `overlaps.py` : plus aucun chevauchement, sauf les contacts voulus (sac dans la charrette du moulin, linge dans la caisse du lavoir, échelle contre l'arbre du verger, épées dans le tonneau de la forge, tapis sous les tables).
- `lamps.py` : 0 fuite (chaque lumière s'arrête avant le sol du dehors).
- `float_check` : 0 enfoncé ; restent des faux positifs, les paillasses posées sur le cadre de planches du lit (le rayon part du dedans de la collision du lit) et le rouleau posé sur la planche à pain (sans collision).
- Grilles (0,5 et 0,25 m) : 0 trou, 0 ressaut, 0 chute, 0 glissade, 0 sortie, 0 plafond ouvert dans les bâtiments reconstruits, 0 plafond bas ; murs invisibles : seulement les berges de la rivière (voulus), dans les zones de la forge et du moulin ; « sans collision » : un sac aplati de la boulangerie (0,3 m). Poches restantes : coins derrière un meuble (caserne 0,7 m², moulin 0,8 m²) et, dans les ruines, des recoins encombrés de meubles renversés (taverne).
- Captures : `~/cdp-work/hub/shots/` (`c2_4`, `c2_0`, `c3_4` en vues complètes, `c4_4`, `c4_0`), copies regardées dans `/home/ubuntu/cdp-dev/.claude/captures/hub/`.

### Outils de la nuit (`docs/agents/hub/interieurs/`, chemins du serveur)
- `overlaps.py` : meuble contre mur et meuble contre meuble, dans chaque ruine et chaque reconstruction ; `lamps.py` : portée de chaque lumière contre la distance au sol du dehors ; `plan.py` : plans de marche au décimètre (collisions, cases atteintes depuis le dehors de la porte, poches), sans Godot.
- `walk_grid.gd` (grilles à 0,5 et 0,25 m, poches, plafond au-dessus de chaque case), `rooms_walk.gd` (entrer et sortir de chaque bâtiment, porte de l'observatoire avec E, lecture de chaque texte), `float_check.gd` (objets qui flottent ou s'enfoncent, petits objets compris), `shots.gd` (captures et planches), `gen_views.py` (caméras posées sur des cases atteintes), `cycle2.sh` (tout le tour).

## Passe du 9 novembre (`fix/verif-hub`) : portes voûtées, jardin, parc, rivière, villageois, mine refaite

Méthode et outils (copies dans `docs/agents/hub/verif/`, chemins du serveur) :
- **Grille de marche** (`grille.gd`, `zones.py`, `rapport.py`, `grid.sh`) : décor regroupé d'un bloc (`finish_all`),
  boîtes visibles prises des « pieces » des lots fondus (les ombres seules ignorées), abri souterrain compté. Dehors en
  9 régions de 80 m et l'abri au demi-mètre ; chacun des 28 bâtiments, la salle de l'observatoire et l'abri au quart
  de mètre (poches, plafond au-dessus de chaque case). À 0, 2 et 4 livres. À 4 livres, le hub est celui de l'épilogue
  (victoire validée : les villageois sont à leur première pause, leur corps actif).
- **Sonde de saut** (`saut.gd`, `saut.sh`, la sonde du hub avec un départ et un sol imposés pour l'abri et
  l'observatoire) : tout le hub au pas d'1 m dans 16 directions, l'abri au pas de 0,5 m, la salle de l'observatoire.
- **Captures** (`vues.py`, `shots.gd`, `shoot.sh`, planches `planches.py`) : à hauteur d'yeux tous les 4 m dans 4
  directions sur le jardin du roi et le parc (étang compris), la place et la mine ; les deux rives de la rivière tous
  les 4 m (en travers et le long) ; les deux ponts (bouts, milieu, rives) ; les 27 portes voûtées de dehors et de
  dedans ; vues de dessus du jardin, de la mine, de la place et de la rivière. 898 vues par palier, à 0 et 4 livres.
- **Végétation** (`pelouse.gd`) : chaque touffe, fleur, champignon et buisson posé contre les cases gravillonnées ou
  de terre battue du sol (une couleur par case de 2 m) et contre les collisions.
- **Villageois** (`villageois.gd`, `suivi.gd`) : tournées jouées image par image (`--fixed-fps 60`), départ du feu
  (après la cinématique) et départ à la première pause (retour au hub), jusqu'à 4 tournées complètes de chacun ; à
  chaque pas : cylindre du corps contre les collisions, sol sous les pieds, immobilité ; puis, à chaque pause, grille
  de marche (0,25 m) autour du villageois avec et sans son corps.

Captures et journaux : `.claude/captures/verif-hub/` (hors dépôt) : `grille4m_4/`, `grille4m_0/` (vues et planches
`p_*`), `planches/` (avant et après), `suivi/` (villageois), `logs/`, `grille/` et `grille2/` (grilles avant et après).

### Corrigés

| # | Où | Constat (outil, capture) | Cause | Correction |
|---|----|--------------------------|-------|------------|
| 37 | Maisons en ruine (16), dont House04 à 07 et 12 à 14 | Grille : « sans collision » `rocks_small` 2 x 0,7 x 2 m dans chaque ruine ; `planches/eboulis_avant_apres.png` : un tas de pierres juste derrière la porte | L'éboulis du coin de devant (castle_kit rocks-small, 0,7 m) n'avait pas de collision, et dans les 7 maisons ouvertes à gauche il tombait devant la porte : on le traversait en entrant | Éboulis dans le coin de devant opposé à la porte, avec une collision à sa taille (`furnish`, `build_hub.py`) |
| 38 | Jardin du roi, pelouses (4 livres) | `pelouse.gd` : 47 pousses sur les cases gravillonnées ; `planches/jardin_dessus_avant_apres.png` | Le semis des pelouses gardait 1,9 m de l'axe des allées sans compter la taille des pousses, alors que le sol gravillonne des cases entières de 2 m (jusqu'à 2 m de l'axe, plus en biais) ; les parterres, carrés, étaient exclus par un cercle (une fleur et un champignon dans le coin du parterre (47,6 ; -76,4), une touffe dans celui de (36 ; -58)) | Semis à l'emprise de chaque pousse (`PLANT_FOOT`), hors des cases gravillonnées (`park_gravel`) et des parterres en carré ; 46 touffes et 64 pousses de la prairie toujours placées. Reste : 4 pousses qui mordent de 3 à 5 cm sur une case (la boîte tournée que mesure l'outil, plus grande que la pousse) |
| 39 | Jardin du roi, prairie (4 livres) | Grille : 15 touffes de champignons « sans collision », 0,55 à 0,75 m de haut | Échelle 2,2 à 3,0 : au-dessus du genou, alors que la prairie se traverse | Échelle 1,6 à 2,0 (0,4 à 0,5 m), sous le genou comme le reste de la prairie (`PLANT_SCALES`) |
| 40 | Étang du jardin, rive ouest (43,7 ; -84,8) | `pelouse.gd` : 2 touffes de roseaux sur l'allée gravillonnée | L'anneau de roseaux de l'étang passe sur l'allée qui longe l'étang | Rien sur les cases gravillonnées (`_on_gravel`, `hub_river.gd`), mêmes tirages : le reste des rives ne bouge pas |
| 41 | Parterres (36 ; -64), (48 ; -64), (47,6 ; -76,4) | Vue de dessus : un coin de gravier dans le parterre, sous les fleurs | Le gravier du rond-point teinte la case de 2 m qui porte le coin du parterre | Le sol reste de pelouse sous les parterres (`PARK_BEDS`, `gravel_mask` de `hub_terrain.gd`) ; précalcul du sol régénéré (`bake_lieux.gd -- hub`) |
| 42 | Rivière au moulin (73 ; 40 à 50) | Grille de captures, rives 043 à 047 ; `planches/eau_moulin_avant_apres.png` : les rides cassent en bandes en travers du courant | Le lit fait un S serré (rayon de 9 m) : les travers de la nappe, perpendiculaires au cours, la pinçaient côté intérieur (un bord de maille de 0,2 m en face de 3,2 m), et les rides, tirées le long du cours, cassaient à chaque travers | Travers de la nappe orientés sur le cours moyenné sur 9 m (`_smoothed_normals`, `WATER_SMOOTHING`) : pire maille 1,5 au lieu de 16,6, nappe toujours 1,8 m au-delà du bord de l'eau ; berges, murs et roseaux gardent les travers exacts |
| 43 | Les 54 portes voûtées (27 par palier) | Captures des portes de dedans ; `planches/seuil_avant_apres.png`, `planches/porte_dehors_avant_apres.png` : trois fentes noires ou une bande noire au seuil | Sous l'arche, les bouts entaillés des lattes du plancher laissaient voir la terre sombre sous le bâtiment | Seuil de planches dans l'épaisseur du mur (`door_sill` : 1,9 x 0,38 m, dessus à 3,5 cm), lattes le long du mur, bouts dans les jambages ; sans collision (sous le pas), même matériau que le plancher. Un premier essai (sous-plancher élargi jusqu'à la face du mur) dépassait de la façade à l'étage : abandonné |

### Vérifiés sans défaut, ou acceptés

- **Grille de marche, après corrections** (`grille2/`) :

  | Livres | Dehors (0,5 m) | Abri (0,5 et 0,25 m) | 28 bâtiments et observatoire (0,25 m) |
  |---|---|---|---|
  | 0 | 116 383 cases | 2 616 | 64 682 |
  | 2 | 115 892 | 2 616 | 62 878 |
  | 4 (épilogue) | 115 086 | 3 044 | 61 844 |

  À chaque palier : 0 trou, 0 ressaut, 0 chute, 0 glissade, 0 sortie de la vallée, 0 plafond bas ; « murs
  invisibles » : seulement les berges fermées de la rivière et l'anneau de l'étang (`River/Banks`, voulus : on ne
  traverse pas à gué ; 227 ou 228 dehors, 25 dans les grilles de la forge et du moulin, au bord de l'eau), la limite au
  pied des montagnes (170) et 10 butées sur des pentes du terrain visibles (berges creusées au bord du grand pont, de la
  forge et du moulin, (45,1 ; -48,5), (67,6 ; -33)). Avant corrections : mêmes chiffres, plus les 16 éboulis.
- **Sans collision, acceptés** : les surfaces des portails ouverts ; les blocs de la casemate du bunker (leur collision
  est celle du mur, à la face extérieure : la boîte visible du bloc déborde vers l'intérieur plein) ; l'enseigne
  suspendue de la forge et de la taverne (la planche est au-dessus de la tête, entre deux poteaux qui ont leur
  collision) ; le bâton de Merlon ; une jatte sur la table de la boulangerie ; le sac plat de la boulangerie en ruine ;
  une bûche dans le lit de la rivière (0 livre) ; les touffes de champignons de la prairie, sous le genou (n° 39).
- **Poches** (cases libres où l'on n'entre pas, au quart de mètre) : des recoins d'une à quelques cases derrière un lit,
  une étagère ou l'éboulis (une case de plus dans 5 ruines depuis le n° 37), dans la caserne (15 cases), le moulin (13),
  la grande maison House04 et House12 (10), les écuries (7) et l'école (8) : aucun passage fermé.
- **Sonde de saut** : tout le hub au pas d'1 m, 16 directions : 0 livre 469 424 sauts, 4 livres 466 528 sauts : 0 point
  où l'on reste coincé ; abri souterrain (pas de 0,5 m) 8 016 et 9 488 sauts : 0 ; salle de l'observatoire : 0.
- **Villageois** : départ du feu, 4 tournées complètes de chacun (856 s de jeu) ; départ à la première pause, 4
  tournées (777 s) : 0 traversée, 0 villageois qui en traverse un autre, 0 écart au sol de plus de 8 cm, 0 blocage,
  à la première tournée comme à la quatrième. Pauses (14) : de 47 à 52 cases perdues sous chacun, 0 hors de son
  emprise : aucun passage fermé. Aucune tournée ne passe un pont ; à leurs pauses, ils sont à plus de 2,5 m des
  portes. Un premier relevé de sol « vide » à (46,6 ; 8,0) venait du rayon tiré pile sur une arête du sol maillé
  (point de passage rond) : décalé de quelques millimètres, plus rien. Planches : `suivi/p__00.png` à `p__02.png`.
- **Captures à 0 livre** (mêmes vues, avec les corrections) : ruines, cendres, eau trouble, nénuphars secs et débris ;
  les 10 débris de la rivière et de l'étang sont dans l'eau, à 2,5 m au moins des berges (calcul sur le cours), et
  rien d'autre ne flotte, ne traverse ou ne se pose hors de l'eau.
- **Captures à 4 livres** (898 vues, toutes regardées en planches) : jardin, parc, étang, ponts, rives, mine, place,
  portes : en dehors des n° 38 à 43, rien qui flotte, se chevauche, traverse un mur ou se pose hors de l'eau. Les
  grandes formes vertes ou blanches au premier plan de quelques vues sont des papillons qui passent devant la caméra.
  Rives : 30 vues sautées (gorge du sud-est, pentes sans sol où se tenir), vues de dessus faites à la place.
- **Arbustes de la cour du château** (±8 ; -61, reconstruits) : sur le pavé de la cour ; décor voulu, laissé.
- **Buissons du décor dispersé** contre les troncs et les rochers (83, hors des zones changées) : la touffe enveloppe
  le pied du tronc ou du rocher ; laissés.

### Contrôles finaux
- Générateurs : `build_hub.py` et `write_hub_tscn.py` relancés après chaque correction, sans dérive. Précalculs :
  `bake_lieux.gd -- hub` régénéré après le n° 41 (couleur du sol) ; l'inventaire des shaders ne change pas (aucun
  matériau nouveau : le seuil prend celui du plancher).
- Suite complète (`run_all.sh`, depuis la branche) : `bake_plaine_check`, `bake_lieux_check`, `bake_shaders_check` à
  jour ; 0 échec partout (`hub_test`, `music_test`, `sound_test`, `gamepad_test` compris, du premier coup), sauf
  `hub_walk_0` et `hub_walk_4` : les 2 échecs voulus « limite infranchissable (doit echouer) » ; `tree_collision_test` :
  hub 670 arbres, dont 301 dans la forêt des montagnes, hors d'atteinte (comme avant) ; `run_tests` : 52 réussis,
  0 échec.
