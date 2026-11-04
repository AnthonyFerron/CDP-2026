# Passe au centimètre (consigne de l'utilisateur, prioritaire sur le BACKLOG)

L'utilisateur voit encore beaucoup de problèmes : « Il faut vraiment que les agents regardent chaque centimètre carré pour en voir tous les problèmes. »
Exemples qu'il a relevés : dans la Plaine, la lave de la coulée ne va pas jusqu'aux lacs des cratères ; dans le Marais, on ne peut remonter de la crypte que depuis le bas des escaliers.
Ces deux exemples sont des symptômes : chercher toute la famille de problèmes qu'ils représentent (raccords entre deux éléments, passages qui ne marchent que dans un sens ou d'un seul endroit).

Avant de commencer : `git merge dev`, réimport, tests de ton lieu au vert.

## 1. Inventaire exhaustif

Lister dans `agents/<lieu>/INVENTAIRE.md` chaque élément du lieu, intérieur compris : bâtiments, pièces, escaliers, portes, passages, ponts, liquides (lave, eau, marais), reliefs, meubles, objets d'énigme, panneaux, PNJ, sorties et portails. Chaque ligne aura sa vérification à l'étape 4.

## 2. Grille de marche automatique (test GDScript, avec fenêtre si des MultiMesh sont lus)

- Couvrir toute la surface accessible, dehors et dans chaque pièce, par une grille de 0,5 m. En chaque point : rayon vers le bas pour trouver le sol, puis le joueur posé là marche 1 s dans 8 directions.
- Relever, avec les coordonnées :
  - points où le joueur reste coincé ou glisse sans fin ;
  - chutes à travers le sol, trous, marches de plus de 0,4 m hors escalier ;
  - murs invisibles (blocage sans maillage visible à moins de 0,5 m) ;
  - maillages visibles sans collision qui devraient en avoir : murs, poteaux, lanternes, arbres, clôtures, meubles de plus de 0,3 m ;
  - sorties de carte ;
  - plafonds traversables par un saut.
- Chaque escalier : le monter et le descendre en entier, en partant du bas, du haut et de chaque côté ; chaque marche doit porter le joueur.
- Chaque porte et chaque passage : le franchir dans les deux sens.
- Chaque interactable (sortie, porte, livre, énigme, panneau) : atteignable à pied et utilisable de chaque endroit où le joueur s'attend à l'utiliser. Une sortie en haut d'un escalier doit marcher en haut.

## 3. Grille de captures, toutes regardées une par une

- Captures à hauteur d'yeux tous les 4 m dehors et dans chaque pièce, dans 8 directions ; coins de chaque pièce ; vue vers le haut sous chaque plafond ; plans rapprochés des raccords.
- Regarder **chaque** capture et noter :
  - objets qui flottent ou s'enfoncent, modèles qui se traversent ;
  - jours entre deux pièces de mur, de sol ou de toit, ciel visible par un plafond ;
  - textures étirées ou en bandes, z-fighting, fuites de lumière ;
  - textes qui débordent de leur panneau ou de l'écran ;
  - portes manquantes, escaliers qui ne rejoignent pas l'étage ;
  - placements laids ou illogiques, objets modernes.
- Liquides : chaque coulée, rivière ou mare rejoint son bassin sans marche, sans bord ni trou au raccord. La surface est au niveau des berges, et la zone qui brûle ou repousse le joueur colle à la surface visible.

## 4. Correction et preuve

- Noter chaque problème dans `agents/<lieu>/PROBLEMES.md` : coordonnées, capture, cause, correction.
- Tout corriger, puis relancer les étapes 2 et 3 jusqu'à zéro problème.
- Rapport final : nombre de problèmes trouvés et corrigés, échecs restants (avec la raison), et planches de captures avant et après sur les zones touchées.
- Ne rien cacher : un problème vu et non corrigé se signale.
