# Inventaire des marais de Kernel Swamp

Chaque ligne a sa vérification (V) : G = grille de marche (`marais_walkgrid_test.gd`), C = grille de captures (`marais_capture_grid.gd`), A = audit des interactables (`marais_audit_test.gd`), E = escalier et parcours (`marais_stairs_test.gd`), L = limites (`marais_limit_test.gd`), P = énigme (`marais_puzzle_test.gd`).

## Dehors

| Élément | Où | V |
| --- | --- | --- |
| Portail (arrivée, retour au hub) | (0, 63) | A, G, C |
| Îlot de l'arrivée, sol, berges, eau peu profonde | (0, 56) r 13 | G, C |
| Panneau d'accueil « Les marais de Kernel Swamp » et sa lanterne | (-4.4, 52.9) | A, G, C |
| Débarcadère : planches, pieux, barque amarrée, rame, poteau d'amarrage | (7.6, 53.2) → (14.2, 51.2) | G, C, E |
| Tonneau, coffre, barque renversée, deux arbres morts, potence et lanterne | îlot de l'arrivée | G, C |
| Ponton 1 et ses lanternes (4) | (-3, 48) → (-18, 27) | G, C, E |
| Îlot du campement : tente, feu, grill à poissons, table et journal, tonneau, seau, coffre et lanterne, sac de couchage, bûches, pelle, potence | (-20, 22) r 9 | A, G, C |
| Ponton 2 et ses lanternes (4) | (-16, 19) → (6, 4) | G, C, E |
| Cimetière : grilles, entrées ouest et nord-ouest, réverbères, allée dallée, rangées de tombes, monticules, bougies, fleurs, tombe fraîche, banc, caveau, pins, tombe d'Ada, tombe d'Aldric et sa plaque, fantôme | (16, 0) r 19 | A, G, C |
| Ponton 3 et ses lanternes (3) | (8.5, -10) → (3, -28) | G, C, E |
| Îlot de la crypte : crypte et porte, obélisques, murets, pins, lanternes sur piliers, cierges, mousse, buissons, arbre tombé, dalles du chemin, tombes des gardiens, deux arbres morts, plaque, potence | (0, -36) r 16 | A, G, C |
| Village englouti de Brumeval : cinq maisons, moulin et roue, cheminée, toit glissé, pieux du ponton, épaves | lagune est (10..32, 20..42) | C |
| Dernière maison : murs, toit, cheminée, lanterne, barque, tonneau, grill | îlot (36, 32) | C |
| Chapelle en ruine : murs, porte, fronton, autel, cierges, bancs, colonne couchée, gravats, rocher, pin, croix tombée, tombes, arbre mort, lumière | îlot (-36, -4) | C |
| Bosquet mort : arbres morts, souche, tronc couché, champignons | îlot (34, -30) | C |
| Pierres levées : sept menhirs, autel, champignons | îlot (-30, -44) | C |
| Vieux débarcadère : barques, pieux, planche, feu froid, grill, tonneau, coffre, arbre mort | îlot (-40, 40) | C |
| Arbres morts des berges (6) | autour du parcours | G, C |
| Arbres, roseaux, nénuphars en fleur, buissons, champignons, troncs noyés (dispersion) | partout | G, C |
| Eau stagnante, brume au ras de l'eau, nappes de brume, lune, feux follets, lucioles | partout | C |
| Grenouilles (berges et nénuphars), poissons, corbeaux, lanternes pendues | partout | C |
| Berge et limite invisible | rayon 68,5 m | L |
| Sons posés (clapotis, grenouilles, vent, gouttes) | voir write_marais_tscn.py, SOUNDS | — |

## Crypte (sous la carte, y = -40)

| Élément | Où (local) | V |
| --- | --- | --- |
| Palier sous la trappe, trappe, sortie du haut « Remonter à la surface » | (0, 4.05, 10.4..14.4) | A, E, G, C |
| Long escalier de pierre : marches, murs et murs de doublure, plafond en pente, rampe, lanterne pendue à mi-hauteur | z 2..10.4 | E, G, C, trous |
| Entrée, cierges, sortie du bas « Remonter l'escalier » | (0, 0) | A, E, G, C |
| Salle du mécanisme : colonnes, mécanisme et socle, inscription gravée, bannières, braseros, cierges, sarcophages, niches de l'ossuaire (4) | x -10..10, z -22..-2 | A, P, G, C |
| Couloir ouest, bannière | x -18..-10, z -14..-10 | G, C |
| Chambre ouest : tombeaux des rois I à IV, épitaphes, noms, épées et couronnes, bannières royales, autel des offrandes, hommage gravé, urnes | x -30..-18, z -18..-6 | A, G, C |
| Couloir est, bannière | x 10..18 | G, C |
| Chambre est : tombeau du livre, couvercle, livre, devise, statue, lanternes, cierges, bannières | x 18..30, z -18..-6 | A, P, G, C |
| Couloir sud-ouest et ossuaire : cercueils, débris, ossements, urne, cierges, niche | x -22..-10, z -6..6 | G, C |
| Couloir sud-est et chambre des gardiens : cercueils, boucliers, lance, cercueil, cierges, niche | x 10..22, z -6..6 | G, C |
| Chauves-souris (7), gouttes, lumières | — | C |
| Murs, sol, plafond de chaque case | — | G, L, C |
