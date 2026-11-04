# Inventaire des plaines d'Hexcole

Chaque ligne est vérifiée par la grille de marche (`grid_test.gd`), les parcours (`walk_test.gd`), l'audit des
interactables (`audit_test.gd`), la lave (`lava_test.gd`), la limite (`limit_test.gd`), les livres (`books_test.gd`)
et les planches de captures (`sheets.gd`). Résultat dans `PROBLEMES.md`.

## Dehors

| Élément | Où (x, z) | Vérification |
| --- | --- | --- |
| Terrain brûlé, relief, remparts | toute la carte, r < 66,5 | grille : trous, marches, pentes glissantes, zones fermées |
| Limite invisible | r = 66,5 | limit_test (24 directions, marche, course, sauts) |
| Portail (sortie) | (0, 56) | invite des deux côtés, franchissable |
| Panneau d'entrée « Les plaines d'Hexcole » | (-4,6, 46) | collision, texte dans la planche |
| Chemin de cendre | x ≈ 0, z 9 à 54 | grille, rien ne le barre |
| Lanternes du chemin (6) | x ± 3, z 16 à 48 | collision debout et couchées |
| Pont de pierre et coulée de lave | (0, 29,5) | traversée dans les deux sens, parapets, rien ne brûle sur le tablier |
| Coulée et ses raccords aux lacs | (21,0 ; 26,8) et (-22,0 ; 21,0) | lava_test, captures rapprochées |
| 7 cratères de lave, leurs lacs | voir CRATERS | lava_test, zone qui brûle, rives |
| 14 trous d'obus | voir IMPACTS | grille : pentes, rien n'y flotte |
| Arbres morts (38), rochers, cailloux, herbes | dispersés | grille : collisions des troncs et des rochers |
| Ruines de la bibliothèque (murs, façade, colonnes, brèches) | x ± 10, z -12 à 8 | grille : jours, murs sans collision, passages |
| Porte de la bibliothèque (entrée) | (0, 8,6) | invite depuis le chemin |
| Obélisque et stèle de la bibliothèque | (-8,6, 15,5) | lisible, collision |
| Barricade, charrette renversée, bélier, tonneaux | z 13 à 22 | grille, rien ne bouche le chemin |
| Charrettes de livres (brèche ouest, route) | (-13, -2), (-4, 41,5) | collisions, posées au sol |
| Campement des soldats, journal, ordre d'évacuation | (14, 42) | journal lisible, affiche lisible |
| Tombes et stèle des défenseurs | (22,5, 50,5) | stèle lisible, croix et épées |
| Tour de guet effondrée | (-23, 52) | collisions, rien ne flotte |
| Engins de siège brisés | (-14, 39) | collisions, feu |
| Batterie de balistes | (17, -22) | collisions |
| Feux, fumées, vent | trébuchet, charrette, camp | rien ne brûle le joueur |
| Corbeaux, bannières | au-dessus du siège et des tombes | sans collision |

## Dedans (sous la carte, y = -40)

| Élément | Où (x, z) | Vérification |
| --- | --- | --- |
| Porte de sortie | (0, -0,8) | invite depuis l'intérieur |
| Salle de lecture : rayonnages, table, chaises, pupitres, lustre, tapis | z 0 à -12 | grille, captures tous les 4 m |
| Passage vers le scriptorium | (-4, -12) | franchi dans les deux sens |
| Scriptorium : pupitres de scribes, carte, rayonnage tombé | z -12 à -24 | grille, captures |
| Passage vers les archives | (4, -24) | franchi dans les deux sens |
| Archives : coffres, lustre tombé, rayonnage tombé, tablette, inscription | z -24 à -36 | grille, captures |
| 12 livres à fouiller | rayonnages ouest et est | audit, books_test |
| Tablette à six emplacements | (0, -33) | invite, énigme |
| Dalle de pierre | (0, -36,1) | glisse à la réussite, passage libre ensuite |
| Escalier oublié | z -36,7 à -38,5 | montée et descente, du bas, du haut et des côtés |
| Petite salle et pupitre de pierre, Projenomicon | (0, -39,8) | livre pris du haut de l'escalier et de la salle |
| Plafonds | partout | aucun saut ne les traverse |
