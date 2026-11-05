# Reste à faire après la nuit du 4 au 5 novembre

Le journal complet de la nuit est sur le serveur, dans `~/cdp-work/JOURNAL.md`.

## Livré cette nuit (dans `dev` et `main`, déployé)
- Lot du 4 novembre : passes au centimètre du Hub, de la Plaine et du Désert, PR #11 (livrable L4), PR #12 (intégration Godot ↔ API).
- Marais : performances web finies et vérifiées. Appels de dessin divisés par 4 à 7 dehors, nœuds de 3 561 à 1 788, objets qui projettent une ombre de 1 170 à 201 (`docs/agents/marais/PERFORMANCES.md`).
- Plaine : six textes à lire (fête des foins, relevé de l'arpenteur, proclamation du roi, lettre de la bibliothécaire, règlement, notes du greffier), indices mis à jour, dessus des tables mesuré sur leur maillage.
- Désert :
  - contournement des panneaux sur poteaux retiré ;
  - 4 marches de plus de 0,4 m réglées ;
  - congères des épaves avec leur collision ;
  - tourbillons de sable, caravane fantôme sur les crêtes, mirage de l'oasis.
- Corrections partagées :
  - fumées préchauffées aussi quand elles sont chargées avec une scène (`smoke_effect.gd`) ;
  - bandeau « Mauvaise réponse » en haut de l'écran, avec le « −5:00 » dedans (en bas pour le dispositif du Village) ;
  - croix du dispositif du Village sous le chronomètre ;
  - `check_overlaps.py` sans effet de bord.

## Travail des agents en cours à la clôture
Voir la dernière section du journal de la nuit : ce qui a été commité, vérifié et fusionné, ou laissé sur la branche `agents/<lieu>`.
- Village (`agents/village`) : passe au centimètre, reprise cette nuit.
- Hub (`agents/hub`) : intérieurs des nouveaux bâtiments, puis villageois qui vivent après la victoire, puis performances web.
- Marais (`agents/marais`) : textes à lire dans le décor.
- Plaine (`agents/plaine`) : performances web.
- Désert (`agents/desert`) : 310 contacts où une collision dépasse le visible de 0,5 à 1 m (rochers de la chambre du zénith en premier).

## Corrections relevées
- `arch_fill()` : `doorway()` laisse un trou de ± 0,95 m pour une arche visible de ± 0,80 m. Le Hub (2 appels) et le Village (`vdoorway`) doivent appeler `arch_fill()` ; le Désert et le Marais n'utilisent pas `doorway()`.
- Le chronomètre du HUD passe sous le cadre des panneaux d'énigme : le HUD est dessiné sous eux.
- Dos des panneaux et des rayonnages très sombres à contre-jour (Marais, Plaine) : dos plus clair ou `double_sided`.
- `tree_collision_test` ne voit plus les arbres morts du Marais, fondus dans le décor : la grille de marche du Marais les vérifie.
- Restes acceptés, à revoir si le temps le permet :
  - Plaine : 1 732 cases sur le dessus d'objets non atteintes ;
  - Hub : boîtes des engins de siège un peu larges.

## Backlog des lieux
- Récit environnemental : Village et Hub (la Plaine est faite, le Marais est en cours).
- Performances web : Village et Hub (Désert et Marais faits, Plaine en cours).
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
