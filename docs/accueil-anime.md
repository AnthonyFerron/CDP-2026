# Accueil animé

Tâche transversale « Accueil animé » (`docs/agents/BACKLOG.md`) : le fond des menus vit doucement, et les écrans du menu (accueil, connexion, création de compte, code de vérification, classement, introduction) s'enchaînent par de courtes transitions. Fichiers : `frontend/scenes/ui/menus/menu_backdrop.gd` (classe `MenuBackdrop`, qui remplace `Ornate.Backdrop`) et `frontend/scenes/ui/menus/main_menu.gd`.

## Ce qui bouge dans le fond

Le décor reste celui des maquettes : nuit violette, ciel à facettes, lune, collines, sapins et château. Tailles et positions sont en coordonnées de référence (1920 × 1080).

| Élément | Mouvement | Comment |
| --- | --- | --- |
| Étoiles (nouvelles) | 64 étoiles, dont une sur sept en étincelle à quatre branches, plus nombreuses en haut du ciel, jamais près de la lune, du château ou du volcan. Chacune scintille à son rythme (onde lente de 0,5 à 1,7 rad/s, phase propre) ; une étincelle allonge ses branches quand elle brille. | Un seul nœud (`Etoiles`), redessiné 20 fois par seconde : un maillage d'environ 80 petits losanges. |
| Lune | Son halo respire sur 8 s : opacité de 0,72 à 1, taille ± 3 %. | Teinte (`modulate`) et échelle du nœud `HaloDeLaLune` : rien n'est redessiné. |
| Fenêtres du château | Les quatre fenêtres, et un halo chaud ajouté autour, vacillent comme des chandelles : trois ondes sans rapport entre elles (5,3, 11,9 et 23,7 rad/s), chacune à sa phase. | Teinte de chaque nœud `Fenetre1` à `Fenetre4`. |
| Brume (nouvelle) | Six nappes allongées, trois entre les collines lointaines et moyennes, trois entre les moyennes et les proches. Elles dérivent vers la droite (5,5 à 15 px/s, plus vite au premier plan) et ondulent de 4 px ; une nappe sortie à droite revient par la gauche. | Chaque nappe est une bande opaque en son milieu et transparente sur ses bords (couleur par sommet, trois rangées de sommets partagés), dessinée une fois et déplacée par la position de son nœud. |
| Mont Sam Altan (nouveau) | Au loin à gauche, derrière les collines lointaines : un cône low-poly, une coulée qui rougeoie sur son flanc, une lueur au cratère qui monte et retombe (deux ondes lentes), et sept bouffées de fumée qui montent sur 18 s en grossissant, couchées vers la droite par le vent, chaudes près du cratère. | Le cône et la coulée sont dessinés une fois ; la lueur change de teinte, chaque bouffée de position, d'échelle, de rotation et de teinte. Sur l'accueil, le cadre des commandes le cache : il se voit sur les autres écrans. |
| Chauve-souris (nouvelle) | 4 s après l'ouverture du menu, puis toutes les 18 à 34 s : elle sort de derrière la tour du château, passe devant la lune et file vers la gauche, ou revient de la gauche et rentre derrière la tour. Vol de 8,5 à 12 s, ailes qui battent 5,5 fois par seconde, petite ondulation. | Silhouette de 15 petits triangles, redessinée seulement pendant son vol. |

Le volcan rappelle le scénario (`docs/agents/SCENARIO.md`) : c'est lui que les quatre livres doivent apaiser, et l'introduction le montre déjà en icône.

### En 2D légère

- **Aucun shader, aucune texture.** Le menu ne compile aucun programme de plus que le rendu 2D habituel, et ne touche pas à l'inventaire des shaders préparés au menu (`docs/shaders-menu.md`).
- **Chaque plan du décor est un nœud**, dessiné une seule fois, dans l'ordre du plus lointain au plus proche : ciel (dessiné par `MenuBackdrop` lui-même), `Etoiles`, `Volcan`, `LueurDuCratere`, `Fumee1` à `Fumee7`, `HaloDeLaLune`, `Lune`, `ChauveSouris`, `Chateau`, `Fenetre1` à `Fenetre4`, `Collines1`, `Brume1` à `Brume3`, `Collines2`, `Brume4` à `Brume6`, `Collines3`, `Sapins`. La brume passe ainsi entre les collines.
- **L'animation ne change que la position, l'échelle, la rotation ou la teinte** de quelques petits nœuds : le moteur garde leur dessin et ne fait que le replacer. Seules les étoiles (20 fois par seconde) et la chauve-souris en vol refont leurs formes, toutes petites. Le grand décor n'est jamais redessiné.
- **Un maillage par plan.** Chaque plan est un seul maillage indexé (sommets, couleur par sommet, triangles), envoyé d'un bloc (`RenderingServer.canvas_item_add_triangle_array`, classe `MenuBackdrop.Shape`) : un appel de dessin par plan, et chaque sommet n'est traité qu'une fois. L'ancien fond dessinait chaque facette, chaque étage de sapin, chaque cercle et chaque colline à part (`draw_colored_polygon`, `draw_circle`) : 65 appels de dessin, immobile. Le nouveau, animé, en coûte 28 (19 au cran 6) : les plans fixes, plus un par nœud animé (bouffées, nappes, fenêtres, lueurs).
- **Pas d'instances.** Une première version faisait tout en quadrilatères (`draw_primitive`), que le moteur regroupe en très peu d'appels (16 pour tout le fond) : le moteur les dessine en instances, six sommets chacune. llvmpipe (Mesa, le rendu logiciel natif du serveur) s'en accommode très bien, mais SwiftShader, le rendu logiciel de Chromium sans carte graphique, traite les instances presque une par une : dans le navigateur, le menu était alors plus lent qu'avant (voir les mesures). Le moteur ne regroupe d'ailleurs que des primitives au même nombre de points, et sort du lot chaque nœud dont la teinte (`modulate`) n'est pas blanche.
- **Moins de pixels à remplir qu'avant.** Chaque plan de collines descendait jusqu'en bas de l'écran, sous les plans plus proches qui le recouvrent. Il s'arrête maintenant à la crête la plus basse du plan suivant, et le dégradé du ciel à la crête la plus basse des collines lointaines, avec la couleur qu'il avait à cette hauteur : environ 1,8 million de pixels de moins à remplir par image en 1080p. Les halos (lune, cratère) étaient six disques empilés : chaque couronne est maintenant dessinée une seule fois, avec l'opacité de l'empilement qu'elle remplace, et le centre caché par la lune n'est plus rempli (environ 0,45 million de pixels de moins). La même image, à quelques pixels de bord près. Le rendu logiciel (navigateur sans carte graphique, SwiftShader ou llvmpipe) y est sensible : il paie chaque pixel.
- **Le temps de l'animation** est la somme des `delta` du jeu : les captures prises à `--fixed-fps` sont reproductibles. Les tirages (étoiles, chauve-souris) ont des graines fixes.
- Le fond tourne aussi pendant le fondu au noir d'une transition, qui met le jeu en pause (`PROCESS_MODE_ALWAYS`).

### Qualité

Au cran de qualité le plus bas (`RenderQuality`, cran 6, « décor fin visible moins loin, moitié moins de particules »), l'animation est réduite : plus de brume (cachée), plus de scintillement (les étoiles restent fixes, sans redessin), quatre bouffées de fumée au lieu de sept. La lune, les fenêtres, la lueur du volcan et la chauve-souris restent : elles ne coûtent qu'un changement de teinte ou quelques triangles. Le fond suit le signal `tier_changed`. `--qualite-cran=6` l'impose pour vérifier.

## Transitions entre les écrans

`MainMenu.show_screen` construit l'écran suivant tout de suite, comme avant : ses boutons, ses champs et son focus répondent dès la première image, au clavier, à la souris et à la manette. Seul son affichage passe par une transition.

- **Fondu traversant.** L'ancien écran s'efface en 0,11 s en glissant de 16 px ; le nouveau apparaît 0,06 s plus tard, en 0,24 s, en glissant de 40 px jusqu'à sa place. Les deux ne se superposent presque pas : un fondu enchaîné classique mêlait les deux écrans à moitié pendant plusieurs images, et les rendait illisibles.
- **Sens.** Un écran plus loin dans le parcours (`ORDER` : accueil, connexion, création de compte, code, classement, introduction) arrive par la droite ; un retour arrive par la gauche, et l'ancien écran part de l'autre côté.
- **Premier écran du menu** (lancement du jeu, retour depuis une partie) : fondu de 0,5 s. Au retour d'une partie, il se fait sous le noir de la transition entre lieux.
- **Même écran redessiné** (lecture de la partie sur le serveur, message, déconnexion) : aucune transition, le nouvel écran prend la place de l'ancien ; s'il apparaissait encore, il reprend où en était l'apparition.
- **Fenêtre de confirmation** (« Nouvelle partie » avec une partie en cours) : fondu d'ouverture de 0,16 s. Elle se ferme d'un coup, comme avant.
- **Entre le menu et les lieux** (« Commencer », « Charger partie », retour au menu) : la transition des lieux (`scripts/transition.gd`, fondu au noir et titre) ne change pas.

### L'écran qui s'efface

Il n'est plus qu'une image :

- `_retire` : la souris le traverse (`MOUSE_FILTER_IGNORE`), il ne prend plus le focus (`FOCUS_NONE`), le champ qui avait le focus clavier le rend, et il sort des groupes de la manette (`Gamepad` : boutons, champs, dessins des touches, défilement, fenêtre modale). La manette choisit donc tout de suite le bouton du nouvel écran, et le clavier virtuel ouvert sur un de ses champs se referme, comme avant.
- Il est déplacé dans un calque (`CanvasLayer` « MenuEcranSortant », couche 1) placé sous la racine, hors de la scène du menu : une recherche de nœud dans la scène (`current_scene.find_child`, utilisée par les tests) ne trouve que l'écran affiché.
- Il est libéré à la fin de son fondu, ou tout de suite si une autre transition commence. Le calque est libéré avec le menu.
- Les réponses du serveur qu'il attendait (connexion, création de compte, code, nouveau code, mot de passe oublié, classement) ne font plus rien (`_alive`) : avant, l'écran quitté était libéré à la fin de l'image, et `is_instance_valid` suffisait à les arrêter.

## Mesures

Serveur arm64 de 4 cœurs, partagé avec d'autres agents : charge de 7 à 18 pendant les mesures. D'un lancement à l'autre, les temps varient du simple au double ; les comparaisons qui comptent sont faites dans le même processus, en alternance. Outils hors dépôt, dans `.claude/captures/accueil/outils/`.

### Dans le navigateur (export identique à la production)

Export du `frontend/Dockerfile`, servi par le vrai Caddyfile dans un conteneur jetable sur un réseau Docker interne, sans API ; Chromium sans écran, rendu WebGL logiciel (SwiftShader), fenêtre de 1280 × 720. Un pilote de mesure (`accueil_driver.gd`) est ajouté à l'image de mesure seulement, jamais livré.

**Fonds en alternance dans le même onglet** (`--ab`) : le pilote remplace le fond de l'accueil toutes les 6 s, trois tours, la première seconde après chaque échange n'étant pas comptée. Préparation des shaders retirée, pour ne mesurer que le menu.

| Fond | Temps d'image moyen, 1er passage | 2e passage |
| --- | --- | --- |
| Ancien (dev, immobile) | 108,5 ms | 111,6 ms |
| Première version animée, en quadrilatères instanciés | 117,0 ms | 124,0 ms |
| **Version finale, animée, un maillage par plan** | **93,0 ms** | **102,1 ms** |
| Aucun fond (écran de l'accueil seul) | 63,2 ms | 69,0 ms |

Le fond animé coûte environ 30 ms par image dans ce rendu, l'ancien fond immobile environ 45 ms. La première version, en quadrilatères instanciés, était plus lente que l'ancien fond : c'est ce qui a fait passer aux maillages. Aucun programme de shader n'est compilé pendant ces mesures : le fond et les transitions n'en ajoutent aucun.

**Préparation des shaders au menu** (`docs/shaders-menu.md`), d'un navigateur neuf, jusqu'à sa fin :

| Lancement | Avant | Après (version finale) | Conditions |
| --- | --- | --- | --- |
| 1re paire | 219,8 s, 577 images | 279,0 s, 527 images | après mesuré sous une charge de 18, avec le navigateur d'un autre agent ; avant pendant que la charge retombait de 17 à 7 |
| 2e paire | 235,6 s, 550 images | **219,5 s**, 501 images | l'un après l'autre, charge de 13 à 15, sans autre navigateur |
| Première version (quadrilatères) | | 256,9 s, 606 images | charge 12 |

Dans tous les cas, les 394 entrées de l'inventaire sont préparées et le navigateur compile les mêmes programmes. La seconde paire, la seule mesurée dans les mêmes conditions, donne la préparation un peu plus rapide après qu'avant : chaque image de préparation dessine aussi le menu, et le fond animé coûte moins que l'ancien. La première paire ne dit rien de plus que la charge du serveur.

**Changements d'écran** (20 s, un écran toutes les 1,5 s) : 136 à 147 ms par image en médiane avec les transitions, contre 100 à 172 ms avant sur les autres lancements : dans le bruit de la charge.

### En natif (llvmpipe)

Rendu Compatibility sur llvmpipe (Mesa), le rendu logiciel du serveur, sous Xvfb.

**Fond seul, en alternance dans le même processus** (`backdrop_ab.gd`, 1920 × 1080, 150 images par fond, deux tours) :

| | Ancien (immobile) | Version finale (animée) | Finale, cran 6 |
| --- | --- | --- | --- |
| Appels de dessin 2D | 65 | 28 | 19 |
| Rendu GPU médian, 1er tour | 264,9 ms | 122,8 ms | 109,7 ms |
| Rendu GPU médian, 2e tour | 73,5 ms | 62,1 ms | 137,1 ms |
| `_process` du fond | aucun | 18 à 50 µs par image | |

D'un tour à l'autre, les temps suivent la charge du serveur ; les appels de dessin ne bougent pas. La première version en quadrilatères tombait à 16 appels, avec un rendu GPU médian de 59 à 75 ms contre 107 à 112 ms pour l'ancien fond : llvmpipe, lui, traite bien les instances.

**Menu complet** (`menu_perf.gd`, accueil immobile, 1920 × 1080, 600 images), l'un après l'autre, charge de 13 à 15 :

| | Avant | Après |
| --- | --- | --- |
| Temps d'image moyen | 285,6 ms | 267,7 ms |
| Rendu GPU médian | 207,3 ms | 185,2 ms |
| Appels de dessin 2D (fond et écran d'accueil) | 197 | 160 |

**Préparation des shaders** (`menu_perf.gd`, `--prechauffage`, 1280 × 720), avant et après en alternance, cache de shaders de Mesa coupé (`MESA_SHADER_CACHE_DISABLE`) : chaque lancement compile vraiment.

| Tour | Avant | Après | Charge |
| --- | --- | --- | --- |
| 1 | 259,8 s, 1 321 images | 185,1 s, 2 265 images | retombée de 12 à 5 pendant le tour |
| 2 | 172,4 s, 2 168 images | 175,3 s, 2 211 images | 4 à 6, stable |

Au calme (2e tour), l'écart est de 1,7 %, dans le bruit de la mesure ; le 1er tour suit la charge. Les 394 entrées sont préparées à chaque fois.

## Ce qui reste

- Fait : les cadres et boutons du menu (`ornate.gd`), qui coûtaient à eux seuls environ 130 appels de dessin sur l'accueil, sont dessinés en maillages, comme le fond : l'accueil passe de 160 à 53 appels (fond compris). Voir `docs/ornate-maillages.md`.

## Vérifier

- Tests : `menu_test`, `gamepad_test`, `login_test` (et la suite complète, `frontend/tests/scenes/run_all.sh`).
- Captures du fond et des transitions, image par image : `.claude/captures/accueil/outils/menu_shots.gd` (hors dépôt), lancé avec `--fixed-fps 30` :

  ```
  xvfb-run -a -s "-screen 0 1920x1080x24" godot --audio-driver Dummy --path frontend --resolution 1280x720 --fixed-fps 30 \
    --script <menu_shots.gd> -- <dossier> [ecrans] [fond=<écran>=<nombre>=<pas>] [transitions] --api=http://127.0.0.1:9/api/v1
  ```

- Mode réduit : la même commande avec `--qualite-cran=6`.
- Mesures : `backdrop_ab.gd` (fond seul en natif, ancien et nouveau en alternance), `menu_perf.gd` (menu complet et préparation des shaders en natif), `build_mesure.sh`, `run_web.sh`, `menu_web.py` et le pilote `driver/accueil_driver.gd` (navigateur), dans `.claude/captures/accueil/outils/`.
