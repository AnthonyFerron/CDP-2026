# Niveau 4 — Le Village détruit

Ouvrir `village.tscn` dans le projet `frontend/project.godot`, puis appuyer sur **F6**. Le portail violet du hub y mène aussi.

Le décor est en place ; l'histoire, l'énigme et le livre de cette zone restent à écrire. Le marqueur `PuzzleSite`, dans l'hôtel de ville, leur réserve la place.

## Plan

| Lieu | Position | Contenu |
| --- | --- | --- |
| Portail | sud, z = 63 | Retour au hub |
| Enceinte | z = 42 et x = ±34 | Rempart effondré, porte arrachée, engins de siège brisés devant |
| Grande rue | x = 0 | Maisons éventrées de part et d'autre, lanternes |
| Place du marché | (0, -2) | Fontaine, étals renversés, charrette couchée, provisions éparpillées |
| Hôtel de ville | (0, -26) | Façade à étage, bannières, bibliothèques et table : emplacement de l'énigme |
| Rue du pont | z = 6 | Mène au pont du ruisseau, à l'ouest |
| Moulin à eau | (-31, -14) | Maison du meunier et roue qui tourne dans le ruisseau |
| Moulin à vent | (30, -30) | Sur sa colline, ses ailes tournent lentement |

L'ambiance est celle d'une fin de journée : un soleil bas et doré perce les nuages, des fumées montent encore des toits et quelques feux couvent dans les ruines.

## Fichiers

| Fichier | Rôle |
| --- | --- |
| `village.tscn`, `village.gd` | Scène du niveau, moulins animés et portail |
| `village_terrain.gd` | Replat du bourg, rues pavées, ruisseau et colline du moulin |
| `village_scatter.gd` | Herbe folle, gravats, arbres et rochers |
| `village_props.tscn` | Enceinte, maisons, place, hôtel de ville et moulins, générés par `tools/build_village.py` |
