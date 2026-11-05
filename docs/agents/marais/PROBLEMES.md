# Passe au centimètre : problèmes des marais de Kernel Swamp

Captures : `agents/marais/grid1/` (avant : 44 planches dehors, 32 dans la crypte), `grid5/` (après, mêmes points),
`cm/` (vues rapprochées), `puzzle/` (panneau du mécanisme), planches avant/après dans `avant_apres/`.
Tests : `marais_walkgrid_test.gd` (dehors, crypte, maillages), `marais_holes_test.gd`, `tools/suite.sh`
(énigme commune, limites, audit, escalier). Coordonnées : monde ; la crypte est à y = -40.

## Trouvés et corrigés

| N° | Où | Vu par | Cause | Correction | Commit |
| --- | --- | --- | --- | --- | --- |
| 1 | Long escalier de la crypte, haut de la cage (0, -36, 2..6) | grid1/crypte_30, crypte_29 ; test des trous : 8 rayons perdus | Le sol du modèle d'escalier commence 30 cm après l'entrée, sa dernière marche finit 10 cm avant le palier ; ses murs, bas à leur pied, laissaient un jour au-dessus des murs de l'entrée ; plafond plus étroit que les murs | Bandes de dalles aux deux raccords, murs de doublure, plafonds élargis à 4 m | 586e6eb |
| 2 | Même cage, dalles orange qui flottent au-dessus de l'entrée | grid2/crypte_30, cm/up/e.png, cm/up2/g.png | Le mur ordinaire du kit (template-wall) porte une bande de sol de 2 m à son pied : posé en doublure à 4,15 m, elle flottait au milieu de la cage | Pans simples (template-wall-top), montés depuis le sol, en retrait à 2,25 m de l'axe, derrière les murs de l'escalier | e722f34 |
| 3 | Plafond de l'escalier tout noir, lu comme un trou | grid1/crypte_30 (vue haute), cm/up/a.png | Aucune lumière entre l'entrée et le palier | Lanterne pendue à une chaîne à mi-escalier (0, -34.6, 6.4) et lumière chaude (LightStairsMid) | e722f34 |
| 4 | Tombeaux des rois, chambre ouest (-24, -40, -12) | grid1/crypte_14 | Couronnes réduites à des boules orange | Couronne : bandeau d'or ouvert et cinq fleurons, sur un coussin de velours | 586e6eb |
| 4 bis | Épées des rois, vues de l'allée | grid4/crypte_13, cm/sword/side.png | Épée couchée en travers du regard, poignée vers l'allée : de loin, une boule orange | Épée le long du gisant, pommeau vers la tête, lame vers l'allée ; vérifié : cm/sword2/kings.png, grid5/crypte_13 | 0ab6a48 |
| 5 | Autel des offrandes (-28, -39, -12) | grid1/crypte_14 | Calice plus haut que les cierges | Échelle 1,3 | 586e6eb |
| 6 | Tombeau du livre, chambre est (24, -40, -12) | grid1/crypte_17 | Faces du tombeau noires : la lumière était juste au-dessus | Lumière basse devant la devise (LightEastTomb) ; la lumière de la chambre reste au centre | e722f34 |
| 7 | Faces d'un noir d'encre partout dans la crypte (dos du tombeau, retours de murs) | cm/east/w.png, grid3/crypte_17 | Lumière d'ambiance prise au ciel de nuit, nulle sous terre | Dans la crypte, ambiance de couleur chaude et faible (CRYPT_AMBIENT) ; dehors, le ciel comme avant | e722f34 |
| 8 | Panneau du mécanisme, titre sous le minuteur et sous « −5:00 » | puzzle/1_ouvert (1re prise), puzzle/3_erreur | Cadre en haut à y = 96 : le bandeau du titre passait sur le minuteur du HUD | Cadre descendu à y = 140, anneaux du cadran de 25 px, message et boutons remontés | e722f34 |
| 9 | Panneau, réussite : message du HUD sur le titre du panneau | puzzle/4_reussite (1re prise) | Le message s'affichait pendant que le panneau s'efface (1,5 s) | Message affiché 1,5 s plus tard, une fois le panneau effacé | e722f34 |
| 10 | Panneau : légende « du centre vers le bord » barrée par le trait | retour du coordinateur | Légende sous le trait de séparation | Légende retirée (la consigne en haut dit déjà « du cercle intérieur au cercle extérieur ») ; vérifié : puzzle/1_ouvert | afe7ac8 |
| 11 | Grenouilles cachées dans les roseaux | retour du coordinateur | Trop petites, au pied des roseaux | Taille 1,9, sur la berge au-dessus des roseaux et sur des nénuphars au bord des pontons | 1cc718e |
| 12 | Ronds dans l'eau invisibles | retour du coordinateur | Dessinés sous la brume au ras de l'eau | Priorité de rendu 3, opacité 0,75 | 1cc718e |
| 13 | Palier sous la trappe, orangé | retour du coordinateur | Dalles « template » orange, lumière chaude | Teinte de pierre sur les dalles, lumière froide du palier | 1cc718e |
| 14 | Lanterne du campement dans le coffre (-19.4, 0.4, 21) | capture du camp | Hauteur du coffre mal connue | Lanterne posée sur le dessus mesuré du coffre | 1cc718e |
| 15 | 29 modèles mal posés (enfoncés ou flottants de 5 cm à 30 cm) | check_boxes.py (boîtes mesurées par aabb_true.gd) | Les boîtes de MODEL_BOXES ignoraient les maillages imbriqués : kit Nature 5 cm sous l'origine, couvercle du cercueil, bras du squelette, col des urnes | Boîtes exactes ; objets reposés (dalles du chemin, bûches, pierres, coffres, tonneaux, cierges des cercueils) | 64ca2d5, 5d2b02d |
| 16 | Couvercles de cercueil sans collision : (-4.3, -39.2, -3.9), (4.3, -39.2, -3.9), (18.6, -39.3, 0.3) | grille de marche (maillages) | Couvercle hors de la boîte de collision (cercueil compté 0,2 m au lieu de 0,32) | Boîte du cercueil exacte : la collision couvre le couvercle | 5d2b02d |
| 17 | Recoin piégeant au campement, entre la tente, le tonneau et la pelle | grille de marche (point bloqué de tous côtés) | Pelle plantée dans le passage | Pelle déplacée en (-19.4, 17.9) | 5d2b02d |
| 18 | Barque renversée : marche de 0,47 m en (-11.0, -0.2, 62.0) | grille de marche (dehors) | Barque posée sur la pente de la berge | Barque sur le replat, en (-6.4, 60.6) | 5d2b02d |
| 19 | Remonter seulement depuis le bas de l'escalier | retour d'un testeur | Ressaut de 8 cm près du haut, sortie du haut trop petite | Rampe sur le nez des marches, marche du haut alignée, sortie du haut recentrée (rayon 2,9) | afe7ac8 |

## Vérifiés sans défaut

- Dehors, 44 planches (8 directions et vue haute, à hauteur d'yeux) : îlot de l'arrivée, débarcadère, pontons, campement,
  cimetière, îlot de la crypte. Objets recalés par les boîtes (coffre et lanterne du campement, coffre et tonneau du
  débarcadère, coffre et tonneau de l'arrivée, barque renversée) : posés au sol, ni enfoncés ni flottants.
- Quatre planches dont l'œil tombe dans un objet (dehors_19 dans un caveau, dehors_25 contre la crypte, dehors_28 sur son
  toit, dehors_31 contre son flanc) : points du quadrillage que le joueur ne peut pas atteindre (grille de marche).
- Grille de marche : dehors 0 problème hors le bord du ponton attendu (6.0, 0.3, -12.5), une descente de 0,51 m vers
  l'eau peu profonde ; crypte 0 ; maillages sans collision 0. Test des trous : 0 rayon perdu sur 4 200.

## Restants, acceptés

| Où | Ce qu'on voit | Pourquoi on le garde |
| --- | --- | --- |
| Dos du panneau d'accueil (-4.4, 1.3, 53.25) et de la plaque de la crypte | Bois très sombre, vu de près à contre-jour | Face à l'ombre de la lune et dos à la lanterne ; le panneau vient de sign_board.gd (interdit) |
| Panneau du mécanisme, après une erreur | Le bandeau « Mauvaise réponse » du HUD (y 770 à 910) couvre le bas gauche du cadran pendant 4 s | Le HUD le place au-dessus des panneaux d'énigme ; la consigne, les lettres choisies, les flèches, le message et les boutons restent visibles |

## Après les textes du récit (nuit du 5 novembre)

- Grille de marche du dehors relancée après les cinq textes, la lanterne d'Ada et les lueurs des panneaux
  (`tools/walkgrid_serveur.gd`, mode dehors) : 10 465 points, 9 327 où le joueur tient (27 de moins qu'avant, l'emprise
  des trois panneaux et de la lanterne) ; aucun mur invisible, piège, marche, chute ni glissade ; seul le bord de ponton
  attendu en (6.0, 0.3, -12.5).
- Dos des niches de l'ossuaire (le fond des rayonnages, derrière les urnes) : presque noir (albedo 0,07), lu comme un
  trou à contre-jour. Éclairci en pierre sombre (0,18), plus foncé que le cadre (0,40) et la tablette (0,27) : la niche
  garde sa profondeur.


## Retours des testeurs (5 novembre)

Captures avant et après : `.claude/captures/marais-retours/avant/` et `apres/` (outil `tools/shots.gd` de la nuit).

| Retour | Constat sur place | Correction |
| --- | --- | --- |
| Arbre dans le passage du cimetière à la crypte | Déjà retiré le 4 novembre (8d36e24) : ponton et îlot dégagés (o11_ponton3, c_haut), le test de l'énigme passe du cimetière à la porte | Aucune |
| Quatre petits tombeaux, textes des rois, hommage au mur | Déjà fait le 4 novembre (8d36e24, ca2dcf7) : quatre tombeaux de 2,2 × 3,4 m, nom gravé « Roi Codeon I » à « IV », épitaphe à lire, dalle « Nos bons rois et protecteurs du Royaume de Codia ! » au mur du fond, au-dessus de l'autel (i05_rois) | Aucune |
| Échelle ou escalier qui manque | Le long escalier existe ; il manquait l'échelle de la trappe : on arrive au palier sous une trappe à 4 m, sans rien pour y monter | Échelle de fer (deux montants, treize barreaux d'un mètre) scellée devant le panneau central du mur du fond du palier, avec sa collision, trappe au-dessus ; de la pierre sombre de la trappe et rangées sous `Interior/Niches`, elles sont fondues en un seul maillage : aucun appel de dessin de plus (l'échelle du kit Mini Forest en ajoutait un) (i17_palier_trappe, i19_echelle_face) |
| On voit l'extérieur depuis la crypte | Les murs du kit font 4,15 m, la hauteur exacte du plafond : leur haut affleurait le plafond | Murs (pièces et palier) montés de 40 cm dans l'épaisseur du plafond (`WALL_RISE`) |
| Rocher et tombe détruite sans collision (crypte) | Ossuaire : stèle brisée (0,7 m), tas de pierres (0,8 m) et urne couchée (0,6 m) posés sans collision | Collision à leur boîte, tournée avec eux |
| Collision bizarre, 1re île, près d'un arbre, à gauche du portail | Barque renversée (-6.4, 60.6), près du grand sapin : retournée (roll 180), elle recevait la boîte alignée sur les axes de sa boîte tournée de 25°, 2,65 × 4,09 m pour une barque de 1,05 × 4,0 m | Boîte tournée avec le modèle quand il est seulement retourné (`upright_or_flipped`) ; même correction pour la barque du vieux débarcadère |
| Un tombeau pas au bon endroit | Interprétation : à l'entrée de la chambre des rois, Codeon I faisait face à Codeon III, Codeon II était au fond | Tombeaux dans l'ordre de la visite : I et II à l'entrée, III et IV au fond (i18_rois_entree) |
