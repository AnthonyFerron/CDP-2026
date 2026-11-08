# Hub : le jardin, le parc et la rivière reprennent vie, et les villageois après la victoire

Branche `features/hub-renaissance`, partie de `dev` (f2920f8). Le hub est un village sinistré sous un volcan
(`docs/agents/SCENARIO.md`) : à chaque livre posé, le jardin du roi, ses pelouses, la rivière et l'étang montrent un
retour progressif de la vie, en suivant les paliers déjà en place (le jardin du roi reconstruit, les sons du hub). Après
la victoire, les survivants du bunker vivent dans le village.

## Ce qui change à chaque livre posé

La vie du hub (`Hub._apply_life`) vaut le nombre de livres posés sur quatre. Elle passe en quatre secondes pendant le
plan large de la réparation, et le joueur retrouve le palier atteint en revenant de chaque lieu.

| Livres | Jardin du roi | Rivière et étang | Vallée |
| --- | --- | --- | --- |
| 0 | Arbres du jardin roussis, parterres en friche, bancs brisés, statues renversées (déjà là). Larges plaques de cendres sur les pelouses | Eau trouble et grise, presque opaque, au courant lent ; un voile de cendres dérive par plaques à sa surface. Débris de bois flottant près des deux ponts, de la forge et dans l'étang. Roseaux secs, quelques nénuphars secs | Feuillage sec, gris et brun, de 88 % des arbres, de la forêt des montagnes et des buissons. Cendres sur tout le sol |
| 1 | L'herbe repousse sur les pelouses (46 touffes). Parterres fleuris et bancs (déjà là) | Eau plus claire, le voile se déchire ; les débris du grand pont et de l'étang sont emportés. Un quart des roseaux reverdit, d'abord au ras de l'eau | Un arbre sur quatre reverdit, d'abord au bord de l'eau ; les cendres reculent |
| 2 | Les arbres du jardin reverdissent, des buissons poussent au pied des haies. Allée des rois et passerelle (déjà là) ; les oiseaux chantent (`hub_sounds.gd`) | Plus de voile de cendres, le courant s'anime ; les derniers débris sont emportés. Roue du moulin (déjà là) | La moitié des arbres est verte ; peu de cendres |
| 3 | Une prairie de fleurs sauvages et de champignons couvre les pelouses (64). Kiosque (déjà là) | Eau claire et vive, l'écume revient ; des poissons sautent près du joueur, des libellules rasent l'eau | Trois arbres sur quatre ; les cendres ont presque disparu |
| 4 | Des papillons volent au-dessus des pelouses et des parterres. Statue de Devlyn (déjà là) | Toutes les libellules ; les poissons sautent toujours | Tout reverdit, plus aucune cendre |

## Comment c'est fait

- **Feuillage qui reverdit** (`scenes/levels/hub/hub_foliage.gd`, `HubFoliage`, et `hub_foliage.gdshader`). Les
  arbres, la forêt et les buissons du décor dispersé (`HubScatter`), les roseaux et les nénuphars des rives
  (`HubRiver`) gardent leur maillage Kenney : seules leurs surfaces de feuillage (matériaux `leafsGreen`,
  `leafsDark`, `grass`, et la texture `colormap` des sapins de mini_forest) passent par un shader qui reprend la
  couleur, la texture et le métal du matériau d'origine. Chaque copie d'un MultiMesh porte, dans ses données
  (`INSTANCE_CUSTOM`), le palier de vie où elle reverdit (`HubFoliage.revive_at`) : 12 % restent verts dès le début,
  les autres reverdissent d'un quart à chaque livre, un peu plus tôt près de l'eau. Aucun appel de dessin de plus : la
  copie sèche et la copie verte sont la même. À quatre livres, le rendu est celui des matériaux Kenney.
- **Cendres du sol** (`hub_ground.gdshader`) : de larges plaques grises, tirées d'un bruit (celui des rides de l'eau),
  dont le seuil monte avec la vie ; elles ont disparu à quatre livres, où le sol est celui d'avant.
- **Eau** (`hub_water.gdshader`) : deux couches de rides, l'une lente, l'autre vive, chacune à vitesse fixe ; la vie
  passe de l'une à l'autre (changer la vitesse d'une seule couche ferait courir les rides pendant les quatre secondes où
  la vie monte). L'eau trouble est presque opaque, l'eau claire laisse voir le lit. Un voile de cendres, plus mat et
  sans rides, dérive par plaques jusqu'au deuxième livre.
- **Jardin du roi** (`tools/build_hub.py`, `build_park`) : les trois arbres du jardin deviennent un élément réparable
  comme le reste du hub (`Repairs/ParkTrees`, métadonnée `stage` = 2) : roussis (modèles `_fall` du kit Nature), puis
  verts, avec la même collision. L'herbe (46 touffes), les buissons au pied des haies (9) et la prairie de fleurs et de
  champignons (64) sont posés sur les pelouses, à l'écart des allées, des parterres, des statues, des bancs, des
  lanternes, du kiosque et de l'étang (`lawn`), sans collision (tout reste sous le genou, les buissons sont contre les
  haies). Chacun va dans un élément du jardin reconstruit au même palier : l'herbe avec les parterres (`ParkBeds`, 1),
  les buissons avec l'allée des rois (`ParkKings`, 2), la prairie avec le kiosque (`ParkKiosk`, 3). Le regroupement du
  décor (`hub_batch.gd`) les fond ainsi dans les lots de ces éléments, sans lot ni ombre de plus ; ils poussent du sol
  pendant le plan large, comme les maisons. `RiverDebris1` et `RiverDebris2` : les débris dans l'eau, en ruine
  seulement, emportés au premier et au deuxième livre (loin des berges, sans collision).
- **Faune** (`hub_wildlife.gd`, `HubWildlife`, et `hub_insect.gdshader`) : papillons (60, surtout au-dessus des
  parterres) et libellules (56, du jardin du roi au moulin) volent dans leur shader, en boucle autour de leur place,
  ailes battantes, sans calcul du processeur ; un MultiMesh par case de 64 m et par espèce (le jardin du roi en tient
  dans deux), effacé au-delà de 50 m, sans ombre. Ils sont plus grands que nature (45 et 30 cm d'envergure) pour se voir
  à hauteur d'homme. Le poisson (`food_kit/fish`) est un seul modèle, montré le temps d'un saut, dans la rivière ou
  l'étang, devant l'auditeur, toutes les 2,5 à 6 s ; il ne calcule rien avant le troisième livre. Dans le bunker, la
  faune n'est pas dessinée (`Hub.OUTSIDE`).

## Les villageois après la victoire

`scenes/levels/hub/hub_villagers.gd` (`HubVillagers`, nœud `Villagers` de `hub.tscn`). Mira, Bran, Elda, Tom et Aldric
font chacun leur tournée, en boucle, entre des pauses :

| Villageois | Tournée | Pauses |
| --- | --- | --- |
| Mira, l'éclaireuse | Chemin du château, ruelle du jardin du roi | Devant la statue de Devlyn (9 s), au bord de l'étang (8 s), au feu |
| Bran, le forgeron | Chemin du bunker | À sa forge, au bord de la rivière, où il travaille (`interact-right`, 12 s), au feu |
| Tom, l'apprenti | Chemin du désert, puis chemin du bunker | Devant le portail du désert (9 s), à la fontaine de la place est, où il boit (`interact-left`, 7 s) |
| Elda, la tisserande | Rue de l'ouest | À l'étal du marché (`interact-left`, 10 s), devant une maison (8 s), au feu |
| Aldric, le garde | Chemin du château | À la porte du donjon, où reposent les livres (14 s), devant la porterie (10 s) : il ne revient plus au feu |

- **Départ.** À la fin de la cinématique, ils sont autour du feu (comme avant : `hub_test` le vérifie pendant la
  cinématique) et partent l'un après l'autre, de 2 à 12 s après la reprise en main. Au retour au hub après la victoire,
  chacun est déjà à sa première pause. Le roi et Merlon restent dans la salle du trône. Les textes et les répliques ne
  changent pas.
- **Ils ne gênent pas le joueur.** En chemin, leur corps est coupé : on ne bute jamais sur un villageois qui marche. Si
  le joueur est devant lui à moins de 3,2 m (ou n'importe où à moins de 1,6 m), le villageois s'arrête et se tourne vers
  lui, le temps de lui parler (on lit un personnage à 3 m) ; il repart quand le joueur s'est éloigné de 4 m. À ses
  pauses, il reprend son corps, comme dans le bunker : elles sont à plus de 2,3 m du milieu des chemins (ceux que
  parcourt `hub_walk_test`) et à plus de 2,5 m des portes.
- **Animations** : celles des modèles Kenney (`walk`, `idle`, `interact-right`, `interact-left`), en fondu de 0,25 s.
- **Coût** : cinq nœuds déplacés par image, sans requête physique ; leur hauteur vient du sol maillé.
- **Sonde des tournées** (hors dépôt, `.claude/captures/hub-renaissance/outils/routes_check.gd`) : au hub
  reconstruit, chaque tronçon est balayé par un cylindre (rayon 0,35 m, de 0,25 à 1,75 m au-dessus du sol), chaque
  pause par le corps du villageois (rayon 0,6 m), et la carte des obstacles est dessinée avec les tournées.

## Mesures

Outil : copie de `perf_hub.gd` (`.claude/captures/perf-hub/outils/`) qui relève aussi le temps d'image
(`.claude/captures/hub-renaissance/outils/perf_hub2.gd` et `mesure.sh`, hors dépôt). En natif, sous Xvfb (rendu
logiciel llvmpipe), en 1280 x 720, une fois le regroupement du décor fini. Appels de dessin : visibles et ombres
(`get_render_info`). « Arrivée » : les 8 directions depuis le point d'arrivée du joueur. Avant : `dev` (f2920f8),
remesuré dans la worktree juste après l'après (`avant.sh`) ; les appels de dessin sont les mêmes d'un passage à
l'autre.

| Vue | 0 livre, avant | 0 livre, après | 4 livres, avant | 4 livres, après |
| --- | --- | --- | --- | --- |
| Arrivée, moyenne | 377 | 383 | 493 | 493 |
| Arrivée, pire direction | 531 | 542 | 706 | 703 |
| Jardin du roi, à hauteur d'homme | 261 | 266 | 302 | 325 |
| Jardin du roi, vu de haut | 278 | 285 | 347 | 368 |
| Étang | 174 | 178 | 204 | 219 |
| Rivière au grand pont | 305 | 318 | 413 | 421 |
| Rivière au jardin | 270 | 277 | 327 | 349 |
| Berge | 488 | 500 | 637 | 633 |
| Place | 480 | 480 | 649 | 640 |
| Village vu de haut | 647 | 657 | 748 | 751 |

- **À 0 livre**, les quelques appels de plus viennent des débris dans la rivière (deux groupes, un lot et son ombre
  par case). Le feuillage sec et les cendres n'en ajoutent aucun.
- **À 4 livres**, au jardin : la prairie, l'herbe et les buissons sont fondus dans les lots des éléments du jardin (une
  première version, en trois groupes à part, en ajoutait le double : 333 appels au lieu de 325) ; les papillons et les
  libellules ajoutent un appel par essaim visible, le poisson un ou deux pendant son saut. Le reste vient des
  villageois, désormais dans le village au lieu d'être tous au feu : Mira devant la statue, le garde à la porte du
  donjon (chaque personnage coûte ses surfaces et leurs ombres, comme quand il était au feu). La moyenne à l'arrivée
  ne bouge pas.
- **Lumières et particules** : aucune ajoutée (aucune lumière, aucun système de particules).
- **Temps d'image** (même outil, moyenne des 16 vues, trois passages avant et deux après, en alternance) : avant
  473, 392 ms (0 livre) et 687, 474 ms (4 livres) ; après 392, 613 ms (0 livre) et 435, 506 ms (4 livres). Les écarts
  d'un passage à l'autre (jusqu'à 50 %) viennent de la charge du serveur, partagé avec d'autres travaux : aucune
  différence ne ressort entre avant et après. À l'arrivée : avant 443 et 392 ms (0 livre), 683 et 434 ms (4 livres) ;
  après 378 et 434 ms (0 livre), 425 et 533 ms (4 livres).
- **Tournées des villageois** : 19,8 µs par image pour les cinq (mille images appelées à la suite, dans le jeu natif).
- **Chargement** : les nœuds du hub passent de 6 037 à 6 101 (faune, villageois) ; le chargement mesuré par l'outil
  reste entre 3,8 et 4,1 s, avant comme après.

## Contrôles

- **Calcul d'avance** (`docs/chargements-lieux.md`) : `hub_scatter.gd` a changé (feuillage), donc la signature du
  décor dispersé ; `hub_bake.res` est régénéré (`tools/bake_lieux.gd -- hub`), ses données sont les mêmes. Empreinte
  du hub (`tools/fingerprint_level.gd`) avec le calcul d'avance, puis en calcul direct (script du décor modifié le
  temps de la mesure) : dessin `174d31f5…` et collisions `91448397…` identiques, 5 341 lignes ; seules changent
  l'intensité des braseros et du feu, qui vacillent (comme entre deux relevés du même code).
- **Inventaire des shaders** (`tools/bake_shaders.gd`) régénéré : trois entrées du hub de plus (feuillage, en copies
  avec et sans ombre ; insectes), et le matériau des sapins de mini_forest passe du hub à la Plaine, qui l'utilise
  encore (au hub, leur feuillage passe désormais par le shader).
- **Générateurs** : `build_hub.py` et `write_hub_tscn.py` relancés après la fusion de `dev` (88217ce, portes voûtées
  d'`arch_fill()`) : aucune dérive.
- **Sonde de saut** (`docs/agents/hub/hub_jump_probe.gd`) : rivière et berges (pas 1, à 12 m de l'eau) et jardin du
  roi (pas 1, x de 26 à 56, z de -94 à -44), à 0 et 4 livres : 0 point où l'on reste coincé.
- **Tournées des villageois** (sonde hors dépôt, `routes_check.gd`, après la fusion) : 0 obstacle sur les tronçons,
  pauses libres, à 3,3 m au moins du milieu des chemins et à 4 m au moins des portes. Carte :
  `.claude/captures/hub-renaissance/routes_final.png`.
- **Épilogue** (`epilogue.gd`, hors dépôt) : après la cinématique, ils quittent le feu de 2 à 12 s ; Mira qui marche
  s'arrête devant le joueur et se tourne vers lui, puis repart quand il s'éloigne.
- **Export de production** (`frontend/Dockerfile`, paquet lancé en natif avec `--main-pack`, `pck_hub.gd` hors dépôt) :
  à 0, 2 et 4 livres, le feuillage passe par son shader (75 surfaces), la faune, les éléments du jardin, les débris, les
  cendres du sol et les villageois sont là ; à 4 livres, les tournées tournent. Aucun avertissement de calcul d'avance
  périmé. Rien n'est préchargé hors des scènes : `include_filter` ne change pas.
- **Captures** (hors dépôt, `.claude/captures/hub-renaissance/`) : `final/livres0` à `livres4` (jardin du roi de haut et
  à hauteur d'homme, allée, étang, rivière au grand pont, au jardin, berge, rivière de haut, vallée) ; `epilogue2/`
  (place, marché, portail, jardin, est, à 3, 12, 30, 60 et 100 s), `epilogue1/mira_salue.png` ; `faune4/` et `faune4b/`
  (papillons, libellules, poisson).
- **Suite complète** (`frontend/tests/scenes/run_all.sh`, branche fusionnée avec `dev`) : `bake_plaine_check`,
  `bake_lieux_check` et `bake_shaders_check` à jour ; 0 échec partout (`hub_test`, `music_test` et `sound_test`
  compris), sauf les 2 échecs voulus de `hub_walk_0` et `hub_walk_4` (« limite infranchissable (doit echouer) ») ;
  `tree_collision_test` : hub 670 arbres, dont 301 dans la forêt des montagnes, hors d'atteinte (comme avant) ;
  `run_tests` : 52 réussis, 0 échec ; aucun avertissement de calcul d'avance périmé.
