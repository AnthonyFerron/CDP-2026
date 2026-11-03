# Niveau 2 — Le Désert

Ouvrir `desert_level.tscn` dans le projet `frontend/project.godot`, puis appuyer sur **F6** pour jouer cette scène. La scène principale du projet et les autres niveaux ne sont pas modifiés.

Décor 3D autonome inspiré de l'illustration du désert du document de référence : dunes, sanctuaire en grès, arches, colonnes brisées, bannières, cactus, crânes et trappe en bois ferré. La cave est placée sous le décor, avec des tables, des tablettes et un coffre en bois à ferrures et serrure en laiton, sans équipement moderne. Les éléments sont des nœuds éditables dans la scène ; aucun téléchargement de modèle ni texture externe n'est nécessaire.

## Jouer

- ZQSD / WASD, souris, Maj et Espace : personnage existant du projet.
- E près de la trappe : entrer dans la cave.
- E près des tablettes : activer Initialiser, Transformer, puis Transmettre. Une erreur remet la séquence à zéro.
- E près du coffre ouvert : récupérer le livre.
- E près de l'inscription de retour : remonter à la surface.

Cette première version propose une énigme simple et autonome. Le raccord au hub, les portails et l'inventaire global restent à intégrer quand ces systèmes seront disponibles. Les dunes et petits détails visuels sont décoratifs ; le sol, les ruines, les tables et les murs ont des collisions. Des limites invisibles encadrent la zone jouable.

## Vérification

Scène chargée et exécutée avec Godot 4.7.2 en mode headless. Vérification automatique des collisions des sols, des téléportations, du mauvais ordre des tablettes, de l'ouverture du coffre et de la récupération du livre. Le rendu visuel n'a pas été vérifié dans une fenêtre graphique.
