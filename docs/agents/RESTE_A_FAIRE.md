# Reste à faire après la nuit du 4 au 5 novembre

Le journal complet de la nuit est sur le serveur, dans `~/cdp-work/JOURNAL.md`. Chaque livraison ci-dessous a passé la suite complète des tests de scène et `run_tests` (49 sur 49), et a été déployée.

## Livré cette nuit (dans `dev` et `main`)
- **Lot du 4 novembre :** passes au centimètre du Hub, de la Plaine et du Désert, PR #11 (livrable L4), PR #12 (intégration Godot ↔ API).
- **Hub :**
  - intérieurs des 12 bâtiments et des 16 maisons, meublés en bois, avec âtres, lampes chaudes et plafonds solides ;
  - porte de l'observatoire qu'on passe avec E, et 13 textes à lire ;
  - collisions des engins de siège à leur emprise réelle.
- **Plaine :**
  - six textes à lire ;
  - décor fixe fondu par matériau : 25 à 35 % d'appels de dessin en moins dehors, 2,3 à 2,7 fois moins dans les archives ;
  - dos des panneaux écrits des deux côtés, et lueurs derrière les dos sombres.
- **Désert :**
  - contournement des panneaux sur poteaux retiré, et 4 marches réglées ;
  - tourbillons de sable, caravane fantôme, mirage de l'oasis ;
  - collisions au plus près du visible : de 310 contacts légers à 60.
- **Marais :**
  - performances web : appels de dessin divisés par 4 à 7 dehors ;
  - 5 textes à lire (dont l'ardoise d'Ada, qui montre la méthode sur un autre mot), et fond des niches éclairci.
- **Village :**
  - passe au centimètre : grilles de marche à 0 problème, salle secrète, fumées au-dessus de la tête ;
  - `arch_fill()` aux portes voûtées ;
  - porte du tonnelier tournée vers la place ;
  - ruisseau en eau jusqu'au talus aux deux bouts.
- **Corrections partagées :**
  - fumées préchauffées au chargement ;
  - bandeau « Mauvaise réponse » en haut de l'écran, avec le « −5:00 » dedans ;
  - croix du dispositif du Village sous le chronomètre ;
  - `check_overlaps.py` sans effet de bord ;
  - changement de scène attendu après la physique quand un portail le déclenche.

## Vérifié et corrigé le 8 novembre au soir (`fix/verif-marche`)
- **Village, grille de marche complète :** fixe (0 problème) et en marchant depuis chacune des 41 932 cases du dehors, maisons comprises, et des 983 de la mairie. Deux chutes libres relevées, sur une pente continue de la colline du moulin et sur le talus de bordure : artefacts de l'essai, corrigé (`agents/village/village_walk_grid.gd`), rien dans le jeu. Les chutes du bout nord du ruisseau ne reviennent plus. Une flèche fichée dans la rue, dans l'axe de la porte de la boulangerie, reculée. Sondes de saut repassées sur le bourg et ses maisons, la mairie (énigme résolue ou non), les archives de la Plaine et tout le dehors du Désert : 0 point coincé. Détail : `agents/village/PROBLEMES.md` n° 44 à 50.
- **Désert :** 73 relevés de la grille (70 contacts légers) à 17 (14 contacts), sans marche ni point coincé de plus : tas de briques, crâne de la grande bête, pointes d'obélisques et jarres couchées au plus près du visible (`agents/desert/PROBLEMES.md` n° 27 à 29).
- **`arch_fill()` :** ses marches suivent l'intrados relevé du mur voûté à 4 cm près (22 cm de mur invisible et 10 cm d'entrée avant), dans les archives de la Plaine, les 12 maisons et le bureau de la mairie du Village.
- **Ruisseau du Village :** plafonné comme les sources du hub ; sur le pont, de -6,3 à -9,8 dBFS de crête (`docs/sons.md`).

## Corrections relevées, non faites
- **Village :** grille de captures à 4 m du bourg (357 points prêts sur le serveur). Les chutes du bout nord du ruisseau et la marche au bout sud sont vérifiées (8 novembre, plus haut).
- **Désert :** 14 contacts légers restants, chacun avec un triangle visible à moins de 1 m (rochers de la bordure, deux tas de briques, colonne tombée, linteau de la porte en ruine, deux enveloppes de ruines, deux collisions à la forme exacte), acceptés : liste dans `agents/desert/PROBLEMES.md`.
- **`hub_props.tscn` à régénérer après fusion :** `arch_fill()` a changé dans `build_plaine.py` (8 novembre, `fix/verif-marche`). `build_hub.py` l'appelle pour les 54 portes voûtées du hub : relancé, il ajoute leurs marches (648 boîtes de plus, et la renumérotation des autres). Non fait sur cette branche, l'agent du hub travaillant sur ces scènes.
- **Roue du moulin du Village :** à 3,5 m, -19,5 dBFS RMS et -7 dBFS de crête. C'est son volume (-2 dB), pas un effet de proximité ; à juger à l'oreille avant d'y toucher.
- **Bandeau « Mauvaise réponse » :** il couvre quelques secondes le titre et la première ligne de la tablette de la Plaine (déjà le cas avant le HUD habillé).
- **Dos des panneaux (`sign_board.gd`) :** il n'est éclairé que par la lumière ambiante. Les lieux le compensent par des lueurs ou par `double_sided`.
- **Ombres de la Plaine :** le soleil en 2 tranches d'ombre réduirait les appels de dessin de 30 à 45 % dehors, mais fait du moiré au sol. Piste : adoucir le filtrage des ombres dans les réglages du projet.
- **Regroupement :** fait le 9 novembre (`perf/regroupements`) : `MaraisBatch` et `PlaineBatch` sont devenus un seul outil, `DecorBatch` (`frontend/scripts/decor_batch.gd`), dont le hub prend la signature des matériaux (`docs/chargements-lieux.md`, « Regroupements : un seul outil »).
- **Tests sous charge (8 novembre, `fix/tests-instables`) :** une attente `wait(n)` en images physiques suit bien les fondus et les minuteries (le temps de `_process` reste à une image physique du temps physique). Elle ne suffit pas pour :
  - lire ce qu'un `_process` calcule juste après une action du test : sous charge, une image enchaîne jusqu'à 8 images physiques sans `_process` (hub_test « invite : » vide). `settle()` de `common_test.gd` est appelé par `face()`, `press()` et `use()` ;
  - une entrée d'`Input.parse_input_event`, vidée seulement au début de l'image suivante (menu_test « pause ouverte », « indice ferme » ; hub_test « sortie refusee ») ;
  - ce qui suit l'horloge : fil du mélangeur audio (music_test), limites en `Time.get_ticks_msec`.
  - Reste à surveiller, sans échec relevé : `quality_test` (limites de 20 s à l'horloge, larges). `timer_test` lit le chronomètre après `settle()` depuis `features/hud-menus`.
- **`tree_collision_test` :** il ne voit plus les arbres morts du Marais, fondus dans le décor ; la grille de marche du Marais les vérifie.
- **Reste accepté :** Plaine, 1 732 cases sur le dessus d'objets non atteintes.

## Backlog des lieux
- Hub : villageois qui vivent après la victoire, performances web (chaque intérieur ajoute ses MultiMesh), parc et rivière qui reprennent vie par paliers.
- Village : récit environnemental, performances web.
- Finitions libres : trois améliorations par lieu (Désert fait).
- Tâches transversales :
  - HUD dans le style des menus ;
  - sons d'interface, pas sur bois et sur pierre, rivière et parc ;
  - accueil animé.

## Vérifications et décisions
- Tests fonctionnels de la PR #12 (`res://tests/run_tests.tscn --api=… --mail-dir=…`) : il faut une API de test locale (Docker) et `tests/mailsink.py`. Jamais contre la production.
- Le site est exporté en version de debug (`--export-debug`), avec le menu F1 accessible : passer en release avant le jury ?
- Tag `L4` : d'après le PDF, il fige la version évaluée, à livrer vendredi à 16 h. À poser quand l'équipe le décide.
- PDF L4 (livrables/L4_Produit.pdf) : la date et l'heure de dépôt sont vides, et « cerlces » doit devenir « cercles ». À corriger par ses auteurs.
- Scénario : le roi et Merlon attendent dans la salle du trône, alors que la règle actuelle garde tous les PNJ au bunker jusqu'à la victoire.
- Éditeur Godot de l'utilisateur à rouvrir après la PR #12.
- Serveur, à décider par Anthony :
  - le conteneur de test `sweet_shaw` tourne encore, avec une connexion sur la base de production (`sudo docker stop sweet_shaw`) ;
  - l'ancien clone `~/CDP-2026` garde du travail absent de GitHub (`perf/fluidite-web`, 2 commits de `feature/api-routes`).
