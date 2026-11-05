# Niveau 4 — Le Village détruit

Ouvrir `village.tscn` dans le projet `frontend/project.godot`, puis appuyer sur **F6**. Le portail violet du hub y mène aussi, une fois le Logiconomicon du Marais trouvé.

Le lieu le plus marqué par la guerre : les attaques de Vibelandia ont forcé la porte, éventré les maisons et jonché les rues de débris. Au centre, la mairie est le dernier bâtiment encore intact.

## Plan

| Lieu | Position | Contenu |
| --- | --- | --- |
| Portail | sud, z = 63 | Retour au hub, éteint tant que le Codonomicon n'est pas trouvé ; panneau d'entrée « Codia » |
| Enceinte | z = 42 et x = ±34 | Rempart effondré, porte arrachée, tour et bélier de siège de Vibelandia devant ; porte de l'ouest sur la rue du pont ; brèche de l'est |
| Porte du village | (0, 37) | Barricade de charrettes renversées, pieux, armes et boucliers des gardes, flèches fichées dans le sol, l'ordre du capitaine et le mémorial des gardes |
| Grande rue | x = 0 | Maisons éventrées de part et d'autre, enseignes des boutiques, lanternes, traces de brûlure |
| Place du marché | (0, -2) | Fontaine et statue du roi fondateur renversée, étals renversés, vivres piétinés, cratère d'un boulet de catapulte, l'avis du maire |
| Mairie | (0, -26) | Intacte, toit et murs entiers ; sa porte mène à l'intérieur de l'énigme |
| Potagers | (-27, 30) | Planches de légumes piétinées, épouvantail, potager brûlé, puits, linge étendu |
| Écuries | (24, 30) | Stalles, foin, charrette, enclos à la clôture brisée, toit à moitié effondré |
| Brèche de l'est | (27, -4) | Cratère, boulet, charrette brûlée, poutres calcinées |
| Champ de blé | (19, -17) | À moitié brûlé, au pied de la colline du moulin |
| Rue du pont | z = 6 | Mène au pont du ruisseau, à l'ouest, par la porte de l'ouest ; le pont, en travers du ruisseau, prolonge la rue sans marche |
| Moulin à eau | (-31, -14) | Maison du meunier sur son soubassement de pierre, roue qui tourne dans le ruisseau, tas de bois et poulailler |
| Moulin à vent | (30, -30) | Sur sa colline, ses ailes tournent lentement ; sacs de grain et meule à son pied |

Chaque maison a son métier, meublé et pillé : auberge du Chaudron, boulangerie et son four de briques, forge et son foyer, épicerie, herboristerie, corps de garde, tonnellerie, maison du meunier, logis (dont celui d'une famille, avec la poupée et la charrette de bois de l'enfant), et une maison brûlée de fond en comble. Les boutiques ont leur enseigne pendue à une potence (`SignBoard`). Corbeaux et chats sont restés au village.

L'ambiance est celle d'une fin de journée : un soleil bas et doré perce les nuages, une lumière froide du ciel éclaire le côté des murs à l'ombre, le sol renvoie un peu de lueur chaude sous les planchers effondrés et les auvents, des fumées montent encore des ruines et des cheminées de la boulangerie et de la forge, quelques feux couvent et lâchent leurs braises (barricade, cratères, maison brûlée, écuries). Les fenêtres de la mairie luisent dans le soir. On entend le ruisseau, la roue du moulin qui éclabousse, le vent dans la brèche, la porte et le moulin à vent, le four et la forge qui crépitent ; dans la mairie, la poussière flotte dans la lumière.

Le village vit encore un peu : les corbeaux picorent ou guettent et s'envolent quand on approche, puis reviennent quand on est loin ; deux chats se promènent devant la mairie et autour du puits ; le linge et les bannières ondulent au vent.

Une limite invisible (`village_terrain.gd`, `LIMIT_RADIUS`, 72 m) ferme la zone au milieu du talus qui l'entoure : on ne la franchit ni en marchant, ni en sautant d'un mur, d'une tour ou d'une charrette.

## Textes à lire

| Panneau | Position | Texte |
| --- | --- | --- |
| L'avis du maire | (-4.6, 13), au bord de la place | La mairie garde les registres et les savoirs des anciens bâtisseurs |
| L'ordre du capitaine | (-4.2, 35), à la porte | Tenir la porte, puis rejoindre le bunker du roi au signal |
| L'ardoise de la boulangère | (4.9, 28.6), devant la boulangerie | Les prix du pain, la dernière fournée pour les gardes |
| Le mémorial des gardes | (12, 37.5), près de la porte | Les gardes ont tenu trois jours face aux guerriers de Vibelandia |

Chaque texte est un `Readable` (lu avec E) qui porte son panneau `SignBoard` : le panneau n'affiche que le titre.

## Énigme : les cinq langages oubliés

L'intérieur de la mairie est posé sous la carte (nœud `Interior`, à y = -40). La porte fermée de la mairie y mène, avec un fondu, et la porte fermée de l'accueil ramène dehors. Les murs du bureau reposent sur ceux du rez-de-chaussée ; leur pied est caché sous le plancher de l'étage.

- **Rez-de-chaussée, l'accueil des habitants** : le comptoir, le bureau de l'archiviste, les armoires des archives, étagères, table d'attente, coffre, caisses et bancs. Un escalier monte le long du mur est ; son garde-corps empêche de sauter dans la cage d'escalier.
- **Étage, le bureau du maire** : bureau, armoire, coffre, étagère, et contre le mur nord le dispositif aux cinq sections, avec au-dessus l'inscription des anciens bâtisseurs : « Cinq langages, cinq épreuves, un seul savoir. Comprends les instructions des anciens bâtisseurs et le dernier secret du village te sera révélé. »
- **Fragments** : dix fragments de papier, deux par langage, sont posés sur les meubles ou rangés dans les tiroirs, les armoires et les coffres. Ouvrir un meuble avec E montre ce qu'il contient ; certains sont vides. La touche **I** ouvre le carnet des fragments retrouvés.
- **Le dispositif** : son panneau, dans le style des menus, a un onglet par langage ; chaque extrait est une page des archives de la mairie, avec ses numéros de ligne, et les fragments retrouvés sont à relire à côté. Les épreuves se résolvent dans l'ordre (les suivantes restent cadenassées) ; une bonne réponse allume la section en vert, scelle la page « Résolu » et passe à l'épreuve suivante. Une mauvaise fait rougir et trembler le dispositif et les murs, et coûte 5 minutes au chronomètre du volcan (le bandeau du HUD l'annonce sous le panneau). Les majuscules, espaces et guillemets ne comptent pas.
- **Fin de l'énigme** : les cinq codes résolus, le dispositif s'illumine d'une intense lumière bleutée, un bruit mécanique résonne, la bibliothèque du mur ouest glisse et révèle la petite salle secrète, intacte. Le Codonomicon y repose sur un pupitre de pierre, et le prendre rallume le portail.

| Code | Langage | Question | Réponse | Fragments |
| --- | --- | --- | --- | --- |
| 1 | HTML | Combien de lieux la liste affiche-t-elle ? (un `<li>` est en commentaire) | 3 | comptoir de l'accueil ; tiroir du bureau du maire |
| 2 | CSS | Couleur du texte visé par une balise, une classe et un identifiant | green (ou vert) | table d'attente ; tiroir de l'accueil |
| 3 | Python | Résultat d'un `if` / `else` puis d'un `print` | 10 | armoire des archives ; bureau du maire |
| 4 | PHP | Résultat de `+=` puis du reste `%` | 2 | armoire du maire ; table d'appoint de l'accueil |
| 5 | TypeScript | Boucle sur un tableau, nombres pairs et impairs | 12 | tiroir de l'archiviste ; coffre du bureau du maire |

Les extraits, les questions et les indices ont été écrits pour cette version, la note de conception ne les donnant pas : ils se modifient dans `code_puzzle.gd` (`CODES`) et `village.gd` (`FRAGMENTS`).

## Fichiers

| Fichier | Rôle |
| --- | --- |
| `village.tscn`, `village.gd` | Scène du niveau, moulins animés, panneaux de lore, mairie et déroulé de l'énigme |
| `village_terrain.gd` | Replat du bourg, rues pavées, ruisseau, colline du moulin et limite invisible |
| `village_scatter.gd` | Herbe folle, gravats, arbres et rochers ; la collision des arbres et des rochers suit leur emprise réelle (branches basses des pins, feuillage des arbres grêles) |
| `village_props.tscn` | Enceinte, maisons et leur mobilier, place, mairie, moulins, abords, générés par `tools/build_village.py` |
| `village_hall.tscn` | Murs et meubles de l'intérieur de la mairie, générés par `tools/build_village.py` |
| `village_instances.gd` | Copies répétées d'un même modèle dessinées en une fois (MultiMesh), pour la version web |
| `paper_fragment.gd`, `storage.gd` | Fragment de papier à ramasser, tiroir, armoire ou coffre à ouvrir |
| `code_puzzle.tscn`, `code_puzzle.gd` | Panneau du dispositif des cinq codes, construit avec `scenes/ui/menus/ornate.gd` |
| `paper_notebook.tscn`, `paper_notebook.gd` | Carnet des fragments, ouvert avec I, dans le même style |
| `village_particles.gd` | Braises des feux, poussière de la mairie, éclaboussures de la roue |
| `village_crow.gd`, `village_cat.gd` | Corbeaux qui s'envolent à l'approche, chats qui se promènent |
| `village_life.gd`, `village_cloth.gdshader` | Linge et bannières qui ondulent au vent |

`tools/build_village.py` contrôle le décor qu'il pose : il signale tout objet solide qui en traverse un autre, et tout objet posé sur un passage à garder libre (grande rue, portes, chemins de l'énigme). Les formes simples (traces de brûlure, corbeaux, chats, linge, four, épouvantail) y sont regroupées en MultiMesh, et les modèles répétés passent par `village_instances.gd`.
