# Inventaire du hub (village de Codia)

Chaque ligne se vérifie : marche (grille `walk_grid.gd`, audit `hub_audit.gd`), captures (`shots.gd`, `audit_shots.gd`), et états 0 à 4 livres posés (les éléments réparables ont une ruine et une reconstruction, `Props/Repairs/<nom>`, palier entre parenthèses).

## Vallée et reliefs
- Plateau du village (rayon 46 m, replat), chemins radiaux vers les 4 portails, le château, le bunker, l'école et la taverne ; rue circulaire (r = 31 m).
- 14 ruelles vers les lieux du pourtour, allées gravillonnées du jardin.
- Vallée élargie à l'est (limite 106 m à l'ouest, 126 m à l'est), montagnes au-delà (30 m), forêt sur leurs pentes, mur invisible au pied (96 pans).
- Mont Sam Altan (volcan) au nord, au-delà des montagnes : pied, coulées, fumée.
- Dispersion : arbres et rochers (avec collision), buissons et fleurs (sans collision, par cases de 32 m).

## Liquides
- Rivière : gorge au nord-est, traverse la vallée à l'est (x ≈ 60 à 78), sort au sud-est ; eau animée, berges, murs invisibles sur les berges hors des ponts, roseaux, pierres, nénuphars.
- Étang du jardin du roi (48, -84,5), anneau de collision.
- Bassin du lavoir, fontaine de la place est (30, 4,2), fontaine de la cour du château.

## Ponts et passages
- Grand pont du chemin du bunker (63,25 ; 0), pont de fortune (0 livre) puis pierre (1).
- Passerelle du jardin du roi (63 ; -66), pont de fortune puis bois (2).
- Porterie du château (arche), portail voûté du donjon, portes des maisons et bâtiments (murs voûtés).

## Château
- Enceinte : pans pleins et 8 pans éventrés (2), 4 tours d'angle décapitées (3), porterie et mur au-dessus de l'arche (1), drapeaux (3).
- Cour : fontaine, enclos et foin, charrette, tonneaux, coffre, caisse, râtelier de lances, 4 braseros, arbre ; engins brisés puis catapulte et baliste (2).
- Donjon : murs épais à deux rangs, 4 tours d'angle (toits au 4e livre), portail.
- Salle du trône : dallage, plafond à poutres, 8 colonnes, bannières, boucliers, trône sur estrade, cercle magique (3 anneaux, 4 rayons, 45 lettres qui s'illuminent), 4 piédestaux et leurs livres, inscription gravée (Readable), caméra du rituel.

## Bunker
- Extérieur : casemate de pierre, porte de fer, plaques, tertre de rochers, enseigne de fer (au-dessus de la porte), interactable « Descendre ».
- Intérieur (y = -40) : murs, plafond plein, plancher, dortoir (lits superposés, couchages), table commune et bancs, bibliothèques, cuisine (brasero, coffres), établi, tonneaux, caisses, tapis, 3 lumières, sortie « Remonter ».

## Village (16 maisons, paliers 1 à 4)
- House00 à House15 : murs, porte voûtée, piliers d'angle, plancher, étage (7 maisons), toit, cheminée ; meubles (lit, coffres, brasero, tonneau, table, chaises, étagère, tapis, plante) ; ruines : murs brisés, éboulis, poutres tombées, meubles renversés.
- Place : feu de camp, rondins, 4 tentes, établi, tonneaux, caisses, pain, panneau d'avis (Readable).
- Marché : étals (2), charrette renversée et roue (ruine).
- Lanternes le long des chemins.

## Lieux du pourtour (meublés, enseigne SignBoard sous un Readable)
- École (2), taverne (1), chapelle (3) et cimetière, mémorial (Readable, inscription sur l'obélisque), forge (1), ferme (2) et champ, enclos, foin.
- Mine d'argent, refaite le 8 novembre : façade de pierre taillée percée de l'entrée (nature_kit cliff_cave_stone) dans un tertre de rochers posés au sol, boisage de la galerie, planches clouées en travers avec l'écriteau « Fermée par ordre du roi Codeon V », éboulis au fond ; wagonnet, outils, caisses et déblais devant ; panneau.
- Boulangerie (1), moulin (2) et sa roue dans le courant (2), lavoir (1), écuries royales et enclos (2), caserne et cour d'entraînement (3), herboristerie et jardin des simples (3), scriptorium (4), observatoire du Mont Sam Altan (4), halle du marché (2), verger du roi (2).

## Jardin du roi
- Haies du pourtour (entrées sud-ouest, sud, est), allées, rond-point, 5 parterres (1), 6 bancs (1), 7 lanternes, arbres, allée des rois (4 statues sur socles, 2), statue de Devlyn et 4 trophées, inscription gravée (4), kiosque (3), étang et barque.
- Panneaux : jardin du roi, allée des rois, statue de Devlyn.

## Personnages
- Merlon, Codeon V, Mira, Bran, Elda, Tom, Aldric : au bunker pendant la partie, sortis à la victoire (salle du trône pour Merlon et le roi, autour du feu pour les autres). Poses animées, accessoires accrochés aux os.

## Interactables
- 4 portails (et leurs panneaux de pierre), 4 piédestaux, inscription du trône, 7 personnages, 20 panneaux de lore, mémorial, statue, bunker (descendre), sortie du bunker.

## Sorties
- Portails vers les 4 zones ; bunker (dans les deux sens) ; point de reprise après la victoire (0, -60).

## Intérieurs (rez-de-chaussée de chaque bâtiment, en ruine puis reconstruit à son palier)
Chaque intérieur reconstruit a sa lumière chaude (`hub_lamp.gd`, allumée à l'approche, dans `Repairs/<lieu>/Rebuilt/Lamp`), ses braises s'il a un âtre (`Embers`), et ses textes à lire (Readable sous `Repairs/<lieu>/Rebuilt`). La cheminée du toit sort au-dessus de l'âtre ; sans âtre, pas de cheminée. Les étages ont une échelle appuyée jusqu'au plafond (étage fermé). Dans les ruines : meubles renversés, poutres tombées à l'écart des meubles, ni lumière ni texte.
- Maisons House00 à House15 : lit de bois et coffre, âtre et marmite au fond à droite, table et deux chaises, étagère de vaisselle, tapis, panier ; les grandes maisons ont un second lit, un tonneau et un sac, les profondes un banc et un tonneau ; dehors, tonneau et caisse.
- École (2) : chaire et chaise du maître, tableau au mur du fond (Readable « Le tableau de la classe »), deux rangs de tables et de bancs, deux étagères de livres, tapis, échelle de l'étage.
- Taverne (1) : âtre au fond, marmite, comptoir et quatre tonneaux, trois tabourets, tonneau réservé, deux tables et huit chaises, table et deux bancs devant, coupe des dragons, chopes, assiettes, chandelles, ardoise au mur (Readable « L'ardoise de la Chope du Dragon »), échelle.
- Chapelle (3) : autel de pierre, chandeliers, quatre lutrins de pierre, prière gravée au mur du fond (Readable « La prière des Quatre Livres »), deux rangs de bancs, deux urnes.
- Forge (1) : foyer, bois, enclume, baquet, meule, établi et outils, carnet de commandes (Readable), râtelier d'armes, deux boucliers au mur, tonneau, coffre.
- Ferme (2) : âtre et marmite, table et deux bancs, deux lits de bois, coffre, sacs de grain, panier de légumes, baratte, houe et pelle, almanach (Readable) ; dehors, champ, enclos, foin.
- Boulangerie (1) : four de pierre, bois, table à pain (miches, planche, rouleau), trois sacs de farine, tonneau, pétrin (jatte, farine), tabouret, livre de comptes (Readable), étagère à pain ; dehors, étal.
- Moulin (2) : meule contre le mur où entre l'axe de la roue, axe intérieur, quatre sacs, deux caisses, échelle du grenier, tonneau, table du meunier (jatte, sac, chandelle), cahier du meunier (Readable), pelle et houe ; dehors, charrette de sacs.
- Écuries (2) : quatre stalles (trois cloisons, foin, seau), noms des chevaux au mur (quatre panneaux), Readable « Les stalles des chevaux de la garde », réserve de foin, abreuvoir, roue, coffre et lanterne, banc, houe et pelle ; dehors, enclos.
- Caserne (3) : âtre, six lits de camp et leurs coffres, râtelier au milieu sous la liste des volontaires (trois panneaux, Readable), table, deux bancs, registre (Readable), chopes, assiette, chandelle, deux râteliers d'armes, tonneau, échelle ; dehors, cour d'entraînement.
- Herboristerie (3) : âtre et chaudron, étagère de fioles, étagère de livres, table (fioles, mortier, miel, jatte), carnet de l'herboriste (Readable), tabouret, lit des blessés, tonneau, deux caisses d'herbes ; dehors, jardin des simples.
- Scriptorium (4) : deux rayonnages de livres, quatre pupitres et leurs tabourets, livres, chandelles, lutrin du maître copiste (page, chandelier, Readable « La page du maître copiste »), coffre, tapis, échelle.
- Observatoire (4) : porte fermée de la tour, qu'on passe avec E dans les deux sens (« Entrer dans l'observatoire », « Sortir de l'observatoire ») ; salle des veilleurs au pied de la tour (plancher, plafond solide), table, registre des veilleurs (Readable), chandelle, chaise, paillasse, coffre et lanterne, échelle vers la chambre de guet.
