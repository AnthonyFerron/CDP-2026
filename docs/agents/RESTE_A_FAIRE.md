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

## Corrections relevées, non faites
- **Village :**
  - 12 chutes libres de 1,2 à 1,9 m au bout nord du ruisseau, vers (-37 à -40, -46 à -50,5) : sans doute un rocher ou le pied d'un arbre à l'entrée du talus, à confirmer sur captures ;
  - grille de captures à 4 m du bourg (357 points prêts sur le serveur) ;
  - marche du joueur au bout sud du ruisseau après la correction.
- **Désert :** 60 contacts légers restants, surtout les bords hauts des prismes des tas de briques épars.
- **`arch_fill()` :** au-dessus de 2,3 m, ses marches arrêtent la collision 0,21 m avant l'arche visible. Ça ne se sent qu'en sautant ; il faudrait une marche de plus dans `build_plaine.py`.
- **Chronomètre :** il passe sous le cadre des panneaux d'énigme, car le HUD est dessiné sous eux.
- **Dos des panneaux (`sign_board.gd`) :** il n'est éclairé que par la lumière ambiante. Les lieux le compensent par des lueurs ou par `double_sided`.
- **Ombres de la Plaine :** le soleil en 2 tranches d'ombre réduirait les appels de dessin de 30 à 45 % dehors, mais fait du moiré au sol. Piste : adoucir le filtrage des ombres dans les réglages du projet.
- **Regroupement :** `MaraisBatch` et `PlaineBatch` gagneraient à devenir un seul outil dans `scripts/`.
- **`tests/scenes/hub_houses.json` :** il ne couvre pas les 6 nouveaux bâtiments ni l'observatoire, que vérifie aujourd'hui le `rooms_walk.gd` de l'agent du Hub (`docs/agents/hub/interieurs/`).
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
