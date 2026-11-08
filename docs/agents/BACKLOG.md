# Tâches suivantes des agents (l'orchestrateur en tire une à chaque fin de tour)

Avant chaque nouvelle tâche, l'agent fusionne `dev` dans sa branche (`git merge dev`) pour repartir du travail de tous, réimporte (`--import`), et relance ses tests.

## Pour chaque lieu (à donner dans l'ordre)

1. **Énigme habillée** : refaire le panneau de l'énigme du lieu (tablet_puzzle, rune_puzzle, ring_puzzle, code_puzzle, paper_notebook) dans le style des menus, avec les éléments de `scenes/ui/menus/ornate.gd` (lecture seule : Frame, HexButton, PillButton, KeyCap, icônes, couleurs). Garder exactement la logique, les signaux et les noms de nœuds utilisés par les tests.
2. **Lumière et ambiance** : éclairage soigné (sources chaudes, ombres utiles, couleurs du ciel et de la brume), particules propres au lieu (cendres, poussière, lucioles, feuilles, fumée), sources sonores 3D posées sur les objets (feu, eau, vent dans une ruine) avec les sons existants.
3. **Vie** : animaux et mouvements simples (corbeaux, chauves-souris, poissons, papillons, drapeaux et bannières qui ondulent, roues qui tournent), animés par script léger, sans collision gênante.
4. **Récit environnemental** : 4 à 6 nouveaux textes à lire (lettres, journaux, plaques) sur `SignBoard` ou parchemins posés, cohérents avec le lore et qui aident à comprendre l'énigme sans la donner. Mettre à jour l'entrée du lieu dans `ZONE_HINTS`.
5. **Performances web** : compter les nœuds, les lumières et les draw calls ; regrouper en MultiMesh, limiter les ombres et les lumières dynamiques, distances de visibilité ; mesurer le temps d'image avant/après.
6. **Deuxième passe de vérification** : refaire l'audit complet (collisions, positions, indices accessibles, textes), parcourir le lieu à pied par un test qui visite chaque zone et chaque interactable, captures de partout, et corriger tout ce qui accroche.
7. **Finitions libres** : propose et réalise trois améliorations qui rendent le lieu plus mémorable (innovation bienvenue), en gardant lisibilité et performances.

## Pour le Hub en plus

- Villageois qui sortent et vivent dans le village après la victoire (déplacements simples entre des points, sans gêner le joueur).
- Le parc et la rivière qui reprennent vie par paliers de livres posés.
- Intérieurs des nouveaux bâtiments meublés et cohérents.

## Tâches transversales (à confier à un agent libre, une à la fois, fichiers réservés indiqués)

- **HUD** (`scenes/ui/hud.*`) : invite, messages, lecteur de textes et chronomètre dans le style des menus.
- **Sons** (`tools/generate_sounds.py`) : sons d'interface (clic, ouverture de panneau), pas sur bois et sur pierre, eau de rivière, ambiance de parc ; toujours synthétisés. Fait le 8 novembre : voir `docs/sons.md`.
- **Accueil animé** (`scenes/ui/menus/*`) : légère animation du fond (lune, étoiles, brume), transitions entre écrans.
