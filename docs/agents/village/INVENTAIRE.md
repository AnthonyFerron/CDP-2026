# Inventaire du Village détruit

Chaque ligne est vérifiée à l'étape 4 de la passe (colonne Vérification : test ou capture qui la couvre).

| # | Élément | Position | Contenu / rôle | Vérification |
| --- | --- | --- | --- | --- |
| 1 | Portail de retour | (0, 63) | éteint sans le livre, ramène au hub | audit, village_test, grille de marche |
| 2 | Panneau d'entrée « Codia » | (-4.5, 55) | SignBoard sur poteaux | captures entrée |
| 3 | Rempart sud | z = 42, x de -30 à 30 | murs étroits, demi-murs, éboulis aux x ±18, ±26… | grille de marche, captures |
| 4 | Tours de la porte | (±6, 42) | base, milieu, sommet ; passage x de -4 à 4 | portes et passages, captures |
| 5 | Vantail arraché | (2.5, 47) | couché devant la porte | captures |
| 6 | Tour de siège, bélier | (-16, 52), (14, 50) | engins de Vibelandia démolis | grille de marche, captures |
| 7 | Rempart ouest | x = -34 | pans, porte de l'ouest (z = 6), maison du meunier (z -18 à -10) | portes et passages |
| 8 | Rempart est | x = 34 | pans, brèche (z = -6), pans rehaussés sur la colline | grille de marche |
| 9 | Porte de l'ouest | (-34.6, 2.9) et (-34.6, 9.1) | deux piliers, rue du pont | portes et passages |
| 10 | Limite invisible | rayon 72 m | anneau de 72 murs invisibles | village_bounds_test |
| 11 | Maison 0 : home | (-10, 30), 2×2 cases | porte east en (-6, 32), stone, 1 étage(s) | portes et passages, grille de marche, captures |
| 12 | Maison 1 : inn | (-10, 20), 2×2 cases | porte east en (-6, 22), wood, 2 étage(s), enseigne « Auberge du Chaudron » | portes et passages, grille de marche, captures |
| 13 | Maison 2 : bakery | (10, 30), 2×2 cases | porte west en (6, 32), wood, 1 étage(s), enseigne « Boulangerie » | portes et passages, grille de marche, captures |
| 14 | Maison 3 : forge | (10, 20), 2×2 cases | porte west en (6, 22), stone, 2 étage(s), enseigne « Forge » | portes et passages, grille de marche, captures |
| 15 | Maison 4 : grocer | (-17, -6), 2×3 cases | porte east en (-13, -6), stone, 2 étage(s), enseigne « Épicerie » | portes et passages, grille de marche, captures |
| 16 | Maison 5 : herbalist | (17, -6), 2×3 cases | porte west en (13, -6), wood, 1 étage(s), enseigne « Herboristerie » | portes et passages, grille de marche, captures |
| 17 | Maison 6 : home | (-20, 14), 2×2 cases | porte south en (-18, 18), wood, 1 étage(s) | portes et passages, grille de marche, captures |
| 18 | Maison 7 : burnt | (-28, -2), 2×2 cases | porte south en (-26, 2), stone, 1 étage(s) | portes et passages, grille de marche, captures |
| 19 | Maison 8 : guard | (21, 12), 2×2 cases | porte west en (17, 14), stone, 1 étage(s), enseigne « Corps de garde » | portes et passages, grille de marche, captures |
| 20 | Maison 9 : family | (-12, -18), 2×2 cases | porte south en (-10, -14), wood, 1 étage(s) | portes et passages, grille de marche, captures |
| 21 | Maison 10 : cooper | (12, -18), 2×2 cases | porte west en (8, -16), stone, 2 étage(s), enseigne « Tonnelier » | portes et passages, grille de marche, captures |
| 22 | Maison 11 : miller | (-31, -14), 2×2 cases | porte east en (-27, -12), wood, 1 étage(s), enseigne « Moulin » | portes et passages, grille de marche, captures |
| 23 | Grande rue | x de -2.6 à 2.6, z de -20 à 64 | pavés, lanternes, traces de brûlure | grille de marche, captures |
| 24 | Place du marché | (0, -2), rayon 11 | fontaine, colonne brisée, statue du roi fondateur, étals, cratère | grille de marche, captures |
| 25 | Fontaine | (0, -2) | bassin rond, collision en 4 boîtes | grille de marche |
| 26 | Rue du pont | z = 6, x de -44 à 0 | jusqu'au pont du ruisseau | portes et passages |
| 27 | Ruisseau | x = -38, z de -85 à 85 | lit creusé au fond d'un vallon hors du bourg, eau à y = -0.45 jusqu'au talus aux deux bouts, sans collision d'eau | liquides |
| 28 | Pont de bois | (-38, 6) | traverse le ruisseau ; flancs et piles pleins jusqu'au lit | portes et passages, liquides, entrées dans les maillages, `passe/pont_flanc_apres.png` |
| 29 | Moulin à eau | (-31, -14), roue en (-36.5, 1, -14) | roue qui tourne (avec collision), éclaboussures | liquides, captures, entrées dans les maillages, `passe/roue_apres.png` |
| 30 | Moulin à vent | (30, 4, -30) | tour sur la colline, ailes, porte dans le mur ouest, sacs, meule | grille de marche, entrées dans les maillages, `passe/porte_moulin_apres.png` |
| 31 | Colline du moulin | (30, -30), rayon 12 | relief | grille de marche |
| 32 | Barricade de la porte | z = 35 à 39 | charrettes, tonneaux, caisses, pieux, armes, boucliers, flèches | grille de marche, captures |
| 33 | Mémorial des gardes | (12, 37.5) | stèle, plaque, lances, boucliers, bougies, fleurs ; Readable | audit |
| 34 | L'ordre du capitaine | (-4.2, 35.2) | Readable sur parchemin | audit |
| 35 | L'avis du maire | (-4.6, 13) | Readable, tableau d'affichage | audit |
| 36 | L'ardoise de la boulangère | (4.55, 28.6) | Readable | audit |
| 37 | Potagers | (-27.8, 25.5) et (-27.8, 35) | planches, clôture, épouvantail (bras avec collision), potager brûlé | grille de marche, entrées dans les maillages, `passe/epouvantail_apres.png` |
| 38 | Puits | (-20, 29) | margelle, toit, seau, chat gris | grille de marche, captures |
| 39 | Fils à linge | (-18.5, 36.4) et (-22.5, -3) | draps qui ondulent | captures |
| 40 | Écuries | x 20 à 28, z 24 à 36 | stalles, mangeoires, foin, charrette, toit à demi effondré | portes et passages, captures |
| 41 | Enclos | x 18 à 30, z 17.5 à 23.5 | clôture brisée, abreuvoir | grille de marche |
| 42 | Brèche de l'est et cratère | (27, -3.5) | boulet, charrette brûlée, poutres | grille de marche, captures |
| 43 | Champ de blé | (19.25, -17.4) | à moitié brûlé, bloc de collision | grille de marche |
| 44 | Tas de bois, billot, poulailler | (-22, -25), (-26.4, -29) | près du meunier | grille de marche |
| 45 | Feu | (4.6, 35.6) | taille 0.9, braises, lumière | captures |
| 46 | Feu | (-7.5, -0.7) | taille 0.7, braises, lumière | captures |
| 47 | Feu | (26, -2.2) | taille 1, braises, lumière | captures |
| 48 | Feu | (-27, -1) | taille 0.9, braises, lumière | captures |
| 49 | Feu | (21.4, 34.6) | taille 0.8, braises, lumière | captures |
| 50 | Fumées | 5 colonnes + 2 cheminées | ruines, boulangerie, forge | captures |
| 51 | Corbeaux | 13 | s'envolent à l'approche (village_crow.gd) | captures |
| 52 | Chats | 2 qui marchent + 2 immobiles | village_cat.gd | captures |
| 53 | Mairie (extérieur) | (0, -26), 3×3 cases | intacte, toit, enseigne, lanternes, fenêtres éclairées ; porte (HallDoor) | audit, portes, captures |
| 54 | Accueil (rez-de-chaussée) | Interior, x ±8, z ±6 | comptoir, bureau de l'archiviste, armoires, étagères, table d'attente, coffre, bancs | grille de marche intérieure, captures |
| 55 | Escalier | x 4.55 à 7.55, z 5 à -4 | 15 marches pleines, coin de collision sous la rampe, garde-corps | escaliers, entrées dans les maillages, `planches/dedans_03.png` |
| 56 | Bureau du maire (étage) | y +4.5 | bureau, tiroir, armoire, coffre, étagère, dispositif et inscription | grille de marche, captures |
| 57 | Plafonds | accueil y 4, bureau y 8 | dalles | plafonds |
| 58 | Salle secrète | x -16 à -8, z ±4 | pupitre de pierre, Codonomicon, bougies, bannières, urnes | passage secret, captures |
| 59 | Bibliothèque qui glisse | (-7.25, 4.5, 0) | devant le passage | village_test, passage secret |
| 60 | Sortie de la mairie | (-2, 1.2, 5.55) | porte de l'accueil | audit, portes |
| 61 | Fragment 0 | (-2.4, 1.075, -0.4) | posé | audit |
| 62 | Fragment 2 | (-4.3, 1, 3.1) | posé | audit |
| 63 | Fragment 3 | (0.4, 1, -0.8) | caché | audit |
| 64 | Fragment 4 | (-6.4, 0.03, -1) | caché | audit |
| 65 | Fragment 7 | (1.6, 1, -5.4) | posé | audit |
| 66 | Fragment 8 | (-4.6, 1.075, -3) | caché | audit |
| 67 | Fragment 5 | (-0.5, 5.575, -0.4) | posé | audit |
| 68 | Fragment 1 | (1.4, 5.5, -0.8) | caché | audit |
| 69 | Fragment 9 | (-6.4, 4.53, -4.2) | caché | audit |
| 70 | Fragment 6 | (1.6, 4.53, 4.45) | caché | audit |
| 71 | Meuble « le tiroir de l'accueil » | (0.4, 0.7, -0.15) | fragment 3 | audit |
| 72 | Meuble « l'armoire des archives » | (-6.72, 1.3, -1) | fragment 4 | audit |
| 73 | Meuble « l'armoire aux registres » | (-6.72, 1.3, -3.5) | vide | audit |
| 74 | Meuble « l'armoire aux actes » | (-6.72, 1.3, 1.5) | vide | audit |
| 75 | Meuble « le tiroir de l'archiviste » | (-3.8, 1.12, -4.35) | fragment 8 | audit |
| 76 | Meuble « le coffre de l'accueil » | (3.5, 0.4, -4.35) | vide | audit |
| 77 | Meuble « le tiroir du bureau » | (1.4, 5.2, -1.42) | fragment 1 | audit |
| 78 | Meuble « l'armoire du maire » | (1.6, 5.8, 4.75) | fragment 6 | audit |
| 79 | Meuble « le coffre du bureau » | (-5.43, 4.9, -5.1) | fragment 9 | audit |
| 80 | Dispositif des cinq codes | (-1, 4.5, -5.4) | panneau Ornate, sections, inscription | audit, village_test |
| 81 | Codonomicon | (-12.6, 5.7, 0) | sur le pupitre de pierre | audit, village_test |
| 82 | Arbres et rochers dispersés | hors du bourg, jusqu'à 64 m ; 60 arbres de bordure sur le talus | chênes, arbres grêles, arbres ronds, pins tordus ; rochers ; collision à l'emprise réelle (village_scatter.gd) | grille de marche, entrées dans les maillages, `passe/pin_apres.png` |
| 83 | Herbes et gravats | rues et abords | sans collision : herbes, gravats sous la cheville (0,3 m au plus) | village_scatter_test, grille de marche |
| 84 | La sommation de Vibelandia | (6, 51) | Readable, affiche sur poteaux, face au chemin du portail | grille de marche et sonde de saut (zone), captures `village-recit/apres1/sommation*.png` |
| 85 | La lettre de Mahaut | (-5.74, 29), mur est de la maison 0 | Readable, parchemin cloué | grille de marche et sonde de saut (zone), `apres2/lettre.png` |
| 86 | L'ardoise de l'écolier | (-10.9, -21.74), mur nord de la maison 9 | Readable, ardoise au mur | grille de marche et sonde de saut (zone), `apres2/ardoise.png` |
| 87 | La pierre de fondation | (4, -19.74), façade de la mairie | Readable, plaque de pierre sous la fenêtre droite | grille de marche et sonde de saut (zone), `apres1/pierre.png` |
| 88 | Le registre du sergent | (21.6, 0.68, 13.4), table du corps de garde | Readable, parchemin couché, sans collision (remplace la carte du sergent) | `apres3/registre.png` |
| 89 | Le carnet du meunier | (31, 4.38, -26.9), meule de rechange du moulin à vent | Readable, parchemin couché, sans collision | `apres3/carnet.png` |
| 90 | Poules | 2 autour du poulailler (x -26 à -20.6, z -31 à -25.9), 2 dans le potager (x -30 à -24.4, z 23.3 à 27.7) | village_hen.gd : vont d'un point à son voisin, picorent, détalent à 2,4 m, sans collision | `apres1/poules_*.png` |
| 91 | Girouette | (0, 11.6, -20.2), faîte de la mairie, échelle 1,6 | village_vane.gd : flèche et coq qui tournent au vent | `apres2/place_girouette.png` |
| 92 | Corbeaux du toit de la mairie | (0, 11.6, -21.4), (3.2, 11.9, -29) | village_crow.gd (Crow13, Crow14) | captures |
| 93 | Papillons de nuit | (±2.3, 2.75, -19.3), lanternes de la porte de la mairie | village_particles.gd (MOTHS), 6 chacun | `tmp/moth2.png` |
| 94 | Bougies allumées | mémorial (11.45, 37.1) et (11.45, 37.9) ; table du sergent (21.9, 0.68, 12.9) | flamme émissive (candle() de build_village.py), sans lumière | `apres1/bougies.png`, `apres3/registre.png` |
| 95 | Braises et filets de fumée du potager brûlé | (-28.6, 34.4), (-26, 36.6) | braises émissives, fumée pâle (Wisp0, Wisp1) | `apres3/potager_brule.png` |
| 96 | Sol | tout le lieu | village_ground.gdshader : mat, couleurs d'avant | grille de captures à 4 m, `apres3/lueur_nord2.png` |
