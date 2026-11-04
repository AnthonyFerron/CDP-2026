# Reste à faire après la livraison du 4 novembre

## Travail des agents interrompu le 4 novembre au soir (voir REPRISE.md)
- Village (`agents/village`) : passe au centimètre interrompue pendant ses tests. À terminer, puis fusionner.
- Hub (`agents/hub`) : intérieurs des neuf nouveaux bâtiments commencés, non vérifiés. Restent les villageois qui vivent après la victoire et les performances web.
- Marais (`agents/marais`) : performances web commencées, non vérifiées. Restent les textes à lire dans le décor.

## Corrections relevées par les agents
- Désert : retirer le contournement des panneaux sur poteaux (`collision = false` et `PostsBody`) maintenant que `sign_board.gd` est corrigé (e094f56), puis revérifier les panneaux.
- `scripts/smoke_effect.gd` : le préchauffage ne s'applique pas quand la fumée est chargée avec une scène (Village, volcan du hub). Il faut un `restart()` différé ; la Plaine le contourne déjà.
- `doorway()` dans build_plaine.py laisse un trou de ± 0,95 m pour une arche visible de ± 0,80 m : le Hub, le Village, le Désert et le Marais doivent appeler `arch_fill()`.
- `check_overlaps.py` régénère les scènes des autres lieux quand il importe les builders : le rendre sans effet de bord.
- HUD :
  - le bandeau « Mauvaise réponse » (y 770 à 910) couvre une partie des panneaux d'énigme latéraux, par exemple le cadran du Marais ;
  - le « −5:00 » flottant sous le chronomètre chevauche le haut des panneaux.
- Dos des panneaux et des rayonnages très sombres à contre-jour (Marais, Plaine) : dos plus clair ou `double_sided`.
- Restes acceptés, à revoir si le temps le permet :
  - Désert : 4 marches de plus de 0,4 m sur des jarres et des débris ;
  - Plaine : 1 732 cases sur le dessus d'objets non atteintes ;
  - Hub : boîtes des engins de siège un peu larges.

## Backlog des lieux
- Récit environnemental : Plaine, Village, Hub.
- Performances web : Plaine et Village (Désert fait, Hub et Marais en cours).
- Finitions libres : trois améliorations par lieu.
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
