# Niveau 4 — Le Village détruit

Ouvrir `village.tscn` dans le projet `frontend/project.godot`, puis appuyer sur **F6**. Le portail violet du hub y mène aussi, une fois le Logiconomicon du Marais trouvé.

## Plan

| Lieu | Position | Contenu |
| --- | --- | --- |
| Portail | sud, z = 63 | Retour au hub, éteint tant que le Codonomicon n'est pas trouvé |
| Enceinte | z = 42 et x = ±34 | Rempart effondré, porte arrachée, engins de siège brisés devant |
| Grande rue | x = 0 | Maisons éventrées de part et d'autre, lanternes |
| Place du marché | (0, -2) | Fontaine, étals renversés, charrette couchée, provisions éparpillées |
| Mairie | (0, -26) | Sa porte mène à l'intérieur de l'énigme |
| Rue du pont | z = 6 | Mène au pont du ruisseau, à l'ouest |
| Moulin à eau | (-31, -14) | Maison du meunier et roue qui tourne dans le ruisseau |
| Moulin à vent | (30, -30) | Sur sa colline, ses ailes tournent lentement |

L'ambiance est celle d'une fin de journée : un soleil bas et doré perce les nuages, des fumées montent encore des toits et quelques feux couvent dans les ruines.

## Énigme : les cinq codes oubliés

L'intérieur de la mairie est posé sous la carte (nœud `Interior`, à y = -40). La porte fermée de la mairie y mène, avec un fondu, et la porte fermée de l'accueil ramène dehors. Les murs du bureau reposent sur ceux du rez-de-chaussée ; leur pied est caché sous le plancher de l'étage.

- **Rez-de-chaussée, l'accueil** : comptoir, armoires des archives, étagères, table d'attente, caisses et bancs. Un escalier monte le long du mur est.
- **Étage, le bureau du maire** : bureau, armoire, commode, étagère, et contre le mur nord le dispositif aux cinq sections.
- **Fragments** : dix fragments de papier, deux par code, sont posés sur les meubles ou rangés dans les tiroirs et les armoires. Ouvrir un meuble avec E montre ce qu'il contient ; certains sont vides. La touche **I** ouvre le carnet des fragments retrouvés.
- **Le dispositif** : il montre les cinq extraits de code, à résoudre dans l'ordre. Une bonne réponse allume la section en vert. Une mauvaise la fait rougir et coûte 5 minutes au chronomètre du volcan. Les majuscules, espaces et guillemets ne comptent pas.
- **Fin de l'énigme** : les cinq codes résolus, le dispositif bleuit, la bibliothèque du mur ouest glisse et révèle la salle secrète. Le Codonomicon y repose sur un pupitre de pierre, et le prendre rallume le portail.

| Code | Langage | Question | Réponse | Fragments |
| --- | --- | --- | --- | --- |
| 1 | HTML | Combien de lieux la liste affiche-t-elle ? (un `<li>` est en commentaire) | 3 | comptoir de l'accueil ; tiroir du bureau du maire |
| 2 | CSS | Couleur du texte visé par une balise, une classe et un identifiant | green (ou vert) | table d'attente ; tiroir de l'accueil |
| 3 | Python | Résultat d'un `if` / `else` puis d'un `print` | 10 | armoire des archives ; bureau du maire |
| 4 | PHP | Résultat de `+=` puis du reste `%` | 2 | armoire du maire ; étagère de l'accueil |
| 5 | TypeScript | Boucle sur un tableau, nombres pairs et impairs | 12 | derrière les caisses de l'accueil ; étagère du bureau |

Les extraits, les questions et les indices ont été écrits pour cette version, la note de conception ne les donnant pas : ils se modifient dans `code_puzzle.gd` (`CODES`) et `village.gd` (`FRAGMENTS`).

## Fichiers

| Fichier | Rôle |
| --- | --- |
| `village.tscn`, `village.gd` | Scène du niveau, moulins animés, mairie et déroulé de l'énigme |
| `village_terrain.gd` | Replat du bourg, rues pavées, ruisseau et colline du moulin |
| `village_scatter.gd` | Herbe folle, gravats, arbres et rochers |
| `village_props.tscn` | Enceinte, maisons, place, mairie et moulins, générés par `tools/build_village.py` |
| `village_hall.tscn` | Murs et meubles de l'intérieur de la mairie, générés par `tools/build_village.py` |
| `paper_fragment.gd`, `storage.gd` | Fragment de papier à ramasser, tiroir ou armoire à ouvrir |
| `code_puzzle.tscn`, `code_puzzle.gd` | Interface du dispositif des cinq codes |
| `paper_notebook.tscn`, `paper_notebook.gd` | Carnet des fragments, ouvert avec I |
