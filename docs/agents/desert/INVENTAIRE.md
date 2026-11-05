# Inventaire du désert de Pythania (passe au centimètre)

Chaque ligne : élément, position, vérification (étape 4 de PASSE_CENTIMETRE.md). Tests :
grille = desert_grid_test.gd, marche = desert_walk_test.gd, audit = desert_audit_test.gd, bornes = desert_bounds_test.gd,
énigme = desert_puzzle_test.gd, fondu = desert_fade_test.gd, planches = captures planches*/.

## Surface

| Élément | Position | Vérification |
| --- | --- | --- |
| Portail (sortie vers le hub) | (0, 54) | audit (invite « Portail éteint »), planche allee1 |
| Point d'arrivée | (0, 48) | grille (départ du parcours) |
| Panneau d'entrée (SignBoard sur poteaux) | (-4.4, 45.5) | grille (poteaux et planche seuls en collision), planche allee1 |
| Pieu au crâne de vautour + chiffon | (4.6, 46) | planche allee1 |
| Allée : 6 obélisques (un brisé) | x ±6.2, z 24/32/40 | grille (socle + fût), planche allee2 |
| Talus de l'allée | x ±7.5 à ±16 | grille (marches > 0,4 m : 0), adoucis |
| Muraille et arche | z 16, x -17.5..17.5 | marche (aller et retour par l'arche), grille, planche arche |
| Angles en L de la muraille | x ±15 | grille (bras mesurés, plus de mur invisible) |
| Bannières, braseros, gravats de l'arche | z 17.8..20.8 | grille, planche arche |
| Avant-cour : rune Pour, rune Porter, colonne couchée, tas PileGate, stèle du couchant, plaque du monument | z 6..13 | audit, marche, planches avantcour |
| Salle des colonnes : dallage, 6 colonnes, statue, autel, bannières, 4 braseros, jarres, trappe de pierre ensablée | z -19..5 | audit, marche, grille, planches salle1..5 |
| Brèches de la salle (gravats), portes nord, ouverture sud | x ±12.6, z -19.8, z 5.4 | marche (franchies dans les deux sens), grille |
| Chambre du levant : stèle, rune TANT QUE, jarres, colonne couchée | x -19..-12.6 | audit, marche, planche levant |
| Chambre du zénith : stèle, tas vide, tablette de l'apprenti, tablettes brisées | x 12.6..19 | audit, marche, planche zenith |
| Sanctuaire englouti : façade, portique, architrave basculée, bannières qui claquent, congères | z -21..-35 | marche (allée du portique), planches portique |
| Caravane : tentes, étals garnis, caisse au carnet, coffre, tonneaux, sacs, charrette renversée, roue, squelettes, chameau, fanion | (-36, -30) | audit (carnet), marche, grille, planches caravane, capture boites/coffre_caravane |
| Oasis asséchée : bassin craquelé, roseaux, palmiers (un couché), puits, abreuvoir et journal d'Elias, jarre sacrée, joug | (40, -2) | audit, marche, planches oasis |
| Citerne : fosse, murs hauts, colonnes, poutre, jarres et squelette au fond | (-30, -2.5) | bornes du parcours (murs infranchissables), planche citerne |
| Tête colossale, obélisque brisé, pioche, squelette | (-34, 30) | grille, planche tete |
| Poste de garde, colonnade, porte des vents, tombes (lettre de Joran), bête des sables | sites des dunes | audit (lettre), marche (tombes), grille (on passe sous les côtes), planches |
| 6 épaves de siège (catapulte, baliste, trébuchet) ensablées | voir WRECKS | grille (enveloppes convexes), planches epave1..3 |
| Rochers, cactus, ruines éparses, restes, ossements, crânes | dispersion | grille, fondu (cases de 32 m) |
| 4 sables mouvants | QUICKSANDS | planche sables ; zone qui happe (0,85 r) = centre sombre visible |
| Limite de la carte | rayon 66,5 | bornes (32 directions × 3) |
| Vautours, lézards, scorpions | vie | capture life/* (sans collision) |
| Mirage de l'oasis (nappe d'eau qui s'efface à moins de 14 m) | (41, -3), au ras du bassin | captures oasis_* avant/après (loin, moyen, près), sans collision |
| Caravane fantôme (2 marcheurs, 2 chameaux montés, 3 de bât) | crêtes, rayon 77 m, fait le tour en 7 min | captures caravane_* avant/après, effacée à moins de 30 m, sans collision |
| 3 tourbillons de sable (entonnoir, grains, sifflement) | boucles autour de (32, 24), (-41, 9), (6, -50) | captures tourbillon_* avant/après, grille et marche (rien ne bloque), sans collision |

## Cave des archives (sous la carte, y = -40)

| Élément | Position | Vérification |
| --- | --- | --- |
| Escalier (9 marches, rampe à 41°) | x -1.4..1.4, z 0.2..3.3 | marche : monté, descendu et remonté en entier |
| Sortie « Remonter à la surface » | (0, 1.6, 1.7), rayon 2,8 | marche : utilisable en bas et en haut de l'escalier |
| Cage de l'escalier (plafond à 5,4 m, linteau) | z 0..4 | planche escalier (aucun jour), bornes (tête sous le plafond) |
| Salle : plafond, poutres, murs, porte scellée et plaque de l'inscription | 20 × 12 m | bornes (16 directions × 3, sauts depuis les tables), planches cave1..5 (vues vers le haut) |
| Table ronde de pierre et ses six emplacements | (0, -6) | audit, énigme |
| Algorithmes gravés (murs ouest et est) | x ±9 | audit, marche |
| Tables des runes SI et Fermer | (±7, -1.9) | audit, marche |
| Tas PileCaveWest, PileCaveEast, PileCaveNorth | voir desert.tscn | audit, marche |
| Coffre de pierre et livre | coin nord-est (7.6, -9.8) | énigme (s'ouvre, livre pris), audit |
| Étagères, casiers à rouleaux, coffre ouvert, pupitre et rouleau de l'archiviste, urnes | murs | audit (rouleau), grille (cave : 0 mur invisible au-delà de 1 m), capture boites/coffre_cave |
