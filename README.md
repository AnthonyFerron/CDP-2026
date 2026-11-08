# CodeQuest

Jeu d'énigmes en 3D du Cercle de Projets 2026, développé avec Godot 4.7 en GDScript.

## Titre et équipe

- **Jeu** : CodeQuest
- **Équipe** : équipe 3, Ruminate Studio
- **Campus** : Lyon

| Membre | Rôle |
| --- | --- |
| FERRON Anthony | Lead dev |
| KHASHIMOV Sherzod | Chef de projet |
| MARCHESSE Clement | Assistant chef de projet |
| DALIGAND Dorian | Développeur back, responsable technique |
| ROBIN FAYET Mathéo | Développeur front, game designer |
| SMATTI Abdelaziz | Designer |

## Jouer en 2 minutes

1. Ouvrir <https://codequest.anthonyferron.com> : rien à installer.
2. Sur l'accueil, choisir « Jouer en tant qu'invité », puis « Commencer » après l'introduction.
3. Cliquer dans la page pour capturer la souris. F ou F11 passe en plein écran.

Il faut un ordinateur avec clavier et souris, et un navigateur récent compatible WebGL 2 : Chrome, Edge ou Firefox. Pour lancer le projet depuis les sources, voir « Lancer en développement ».

## Comment jouer

An 5814 : le Mont Sam Altan menace le royaume de Codia, ruiné par la guerre contre Vibelandia. Devlyn doit retrouver les quatre livres légendaires, le Projenomicon, l'Algonicon, le Logiconomicon et le Codonomicon, et les poser sur leurs piédestaux autour du cercle magique de la salle du trône du château, avant l'éruption. La partie commence dans le bunker des survivants : le roi Codeon V et Merlon y confient la mission. Les portails des quatre lieux s'ouvrent dans l'ordre (Plaines d'Hexcole, Désert de Pythania, Marais de Kernel Swamp, Village détruit), chacun une fois le livre du lieu précédent posé.

### Commandes

Les touches suivent la position physique sur le clavier : ZQSD en AZERTY, WASD en QWERTY.

| Action | Touche |
| --- | --- |
| Se déplacer | ZQSD / WASD |
| Sprinter | Maj gauche |
| Sauter | Espace |
| Interagir | E |
| Regarder autour | Souris ou flèches |
| Relire les fragments (Village) | I ou Tab |
| Pause (et libérer la souris) | Échap ou P |
| Indice | H |
| Reprendre la souris | Clic |
| Plein écran | F ou F11 |

### Indices

La touche H donne trois indices par lieu, du plus vague au plus précis, un de plus à chaque ouverture ; au village de Codia, l'indice dit où aller. Les lieux cachent aussi des textes à lire avec E (lettres, plaques, épitaphes) qui mettent sur la voie sans donner la réponse.

### Chronomètre

Le compte à rebours part de 60 minutes et s'affiche en haut à droite. Chaque mauvaise réponse à une énigme retire 5 minutes, annoncées par un bandeau. Il s'arrête dans les menus, la pause, les indices et les chargements. À zéro, le Mont Sam Altan entre en éruption et la partie est perdue. Le scénario prévoit 40 minutes : l'équipe a choisi une heure.

## Solution complète

| Zone | Énigme | Livre | Solution |
| --- | --- | --- | --- |
| Plaines d'Hexcole | Les fragments du passé : six fragments cachés dans les livres de la bibliothèque, à remettre dans l'ordre sur la tablette | Projenomicon | Ordre de la conversation : restauration à organiser, objectifs, inventaire, planning, suivi, vérification et clôture |
| Désert de Pythania | Les algorithmes oubliés : runes à ramasser ou à dégager du sable en maintenant E, à poser sur la table ronde de la cave | Algonicon | Jarre : TANT QUE, Puiser, Porter. Porte : SI, Ouvrir, SINON. « POUR » et « Fermer » sont des leurres |
| Marais de Kernel Swamp | Le tombeau du chiffrement : mécanisme à cinq cercles dans la crypte souterraine ; les épitaphes des rois Codeon I à IV, dans la chambre ouest, à l'opposé du tombeau du livre, redonnent la règle | Logiconomicon | CODIA décalé de +3, −3, +3, −3, +3 : **FLGFD** |
| Village détruit | Les cinq langages oubliés : dix fragments de papier cachés dans la mairie (touche I pour les relire), cinq extraits de code à résoudre dans l'ordre sur le dispositif du bureau du maire | Codonomicon | HTML : **3**. CSS : **green**. Python : **10**. PHP : **2**. TypeScript : **12** |

### Énigme 1 : Plaines d'Hexcole, « Les fragments du passé »

Les six fragments sont cachés entre les pages des livres de la bibliothèque en ruine : examiner les livres des rayonnages avec E. Un livre dont on a pris le fragment disparaît du rayonnage. Sur la tablette, choisir un fragment à droite, puis l'emplacement gravé à gauche ; cliquer un emplacement rempli rend son fragment. « Valider » une fois les six posés.

| Ordre | Locuteur | Fragment |
| --- | --- | --- |
| 1 | Bibliothécaire | « Nous devons organiser la restauration des archives avant la prochaine inspection. » |
| 2 | Employé | « Quels sont les objectifs prioritaires de cette restauration ? » |
| 3 | Bibliothécaire | « Nous devons d'abord inventorier les ouvrages endommagés et identifier les ressources nécessaires. » |
| 4 | Employé | « Une fois l'inventaire terminé, nous pourrons établir un planning et répartir les tâches. » |
| 5 | Bibliothécaire | « Exactement. Nous devrons également suivre l'avancement des travaux et anticiper les éventuels retards. » |
| 6 | Employé | « Lorsque les travaux seront terminés, nous vérifierons leur conformité avant de clôturer le projet. » |

### Énigme 2 : Désert de Pythania, « Les algorithmes oubliés »

Les runes sont dans les ruines : certaines se ramassent avec E, d'autres se dégagent du sable en maintenant E. Sur la table ronde de la cave, choisir une rune, puis la case où la poser ; cliquer une case remplie la libère. « Valider » s'active une fois toutes les cases remplies. Les cases marquées d'une rune ci-dessous sont celles à remplir ; « POUR » et « Fermer » sont des leurres.

| Ligne | Algorithme 1 : la jarre sacrée | Algorithme 2 : l'entrée du temple |
| --- | --- | --- |
| 1 | Prendre une jarre vide | Demander le mot de passe au voyageur |
| 2 | **TANT QUE la jarre n'est pas pleine** (rune) | **SI le mot de passe est « soleil »** (rune) |
| 3 | **Puiser de l'eau au puits** (rune) | **Ouvrir la porte du temple** (rune) |
| 4 | Verser l'eau dans la jarre | **SINON** (rune) |
| 5 | FIN TANT QUE | Sonner l'alarme |
| 6 | **Porter la jarre au temple** (rune) | FIN SI |

### Énigme 3 : Marais de Kernel Swamp, « Le tombeau du chiffrement »

Le mécanisme à cinq cercles est dans la crypte souterraine ; les épitaphes des rois Codeon I à IV, dans la chambre ouest, redonnent la règle : chaque lettre de CODIA est décalée de 3, alternativement vers l'avant et vers l'arrière. Tourner chaque cercle avec ses flèches, du cercle intérieur au cercle extérieur, pour placer la lettre sous le repère doré, puis « Valider ».

| Cercle | Lettre | Décalage | Résultat |
| --- | --- | --- | --- |
| I | C | +3 (C, D, E, F) | F |
| II | O | −3 (O, N, M, L) | L |
| III | D | +3 (D, E, F, G) | G |
| IV | I | −3 (I, H, G, F) | F |
| V | A | +3 (A, B, C, D) | D |

Code final : **FLGFD**.

### Énigme 4 : Village détruit, « Les cinq langages oubliés »

Dix fragments de papier sont cachés dans les meubles de la mairie (touche I pour les relire). Sur le dispositif du bureau du maire, les cinq épreuves s'ouvrent dans l'ordre : taper la réponse au clavier dans le champ, puis Entrée ou « Valider ». Les réponses en lettres sont aussi acceptées (« trois », « vert », « dix », « deux », « douze »).

| Épreuve | Langage | Réponse | Explication |
| --- | --- | --- | --- |
| 1 | HTML | **3** | « Tour de garde » est dans un commentaire `<!-- ... -->` : seuls Forge, Moulin et Puits s'affichent |
| 2 | CSS | **green** | Le sélecteur d'identifiant `#maire` est le plus spécifique : il l'emporte sur la classe et sur la balise |
| 3 | Python | **10** | `recolte = 12 > 10`, donc `greniers = 3 + 2 = 5`, et `print(greniers * 2)` affiche 10 |
| 4 | PHP | **2** | `$pieces = 7 + 5 = 12`, et `12 % 5` donne le reste 2 |
| 5 | JavaScript / TypeScript | **12** | Les nombres pairs s'ajoutent, chaque impair retire 1 : 4 − 1 + 8 − 1 + 2 = 12 |

Séquence de validation : 3, green, 10, 2, 12.

## Comptes de test

Aucun compte n'est nécessaire : « Jouer en tant qu'invité » donne accès à tout le jeu. Le classement demande un compte, à créer depuis l'accueil (« Créer un compte », puis le code reçu par e-mail). Aucun identifiant n'est publié ici.

## Technologies

| Partie | Technologies |
| --- | --- |
| Jeu | Godot 4.7.2, GDScript, rendu Compatibility, export web (WebAssembly et WebGL 2) |
| API | Python 3.14, FastAPI, Alembic pour les migrations, PostgreSQL 17 |
| Serveur | Docker Compose, Caddy 2 (HTTPS), déploiement par GitHub Actions |
| Ressources | Modèles 3D Kenney (CC0), polices Cinzel et Lora (SIL OFL 1.1), sons synthétisés par un script du projet |

Les bibliothèques et leurs versions sont dans `LICENCES.md` et `backend/requirements.txt`.

## Structure du dépôt

| Dossier | Contenu |
| --- | --- |
| `frontend/` | Projet Godot |
| `frontend/assets/` | Modèles, textures, matériaux, audio et polices |
| `frontend/assets/models/kenney/` | Kits de modèles Kenney, par kit (voir `docs/assets.md`) |
| `frontend/scenes/levels/` | Niveaux |
| `frontend/scenes/player/` | Personnage joueur (scène et script) |
| `frontend/scenes/ui/` | Interfaces |
| `frontend/scripts/` | Scripts partagés qui n'appartiennent à aucune scène |
| `backend/` | API Python |
| `docs/` | Documentation technique |
| `infrastructure/` | Base de données locale et production avec Docker |
| `livrables/` | Livrables du Cercle de Projets (cadrage, spécifications, journaux, registre IA, L4) |

Un script propre à une scène se range à côté de celle-ci. Les fichiers et dossiers sont nommés en `snake_case`.

## Lancer en développement

1. Installer [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/) (version standard, pas .NET) et [Git LFS](https://git-lfs.com/).
2. Activer Git LFS, une seule fois par machine, **avant de cloner** :

   ```sh
   git lfs install
   ```

3. Cloner le dépôt, puis importer `frontend/project.godot` depuis le gestionnaire de projets de Godot.
4. Lancer le jeu avec `F5`.

Les tests du jeu et de l'API sont décrits plus bas, dans « Tests du jeu » et « API ».

## Crédits et licences

`LICENCES.md` liste tout ce que le projet utilise. Ajouter une ligne pour chaque modèle, texture, son, police ou bibliothèque venant de l'extérieur, avant de le commiter.

## IA

Le registre de l'usage de l'IA dans le projet est dans [`livrables/Registre_IA_Ruminate.docx.pdf`](livrables/Registre_IA_Ruminate.docx.pdf).

## Limites connues

- La réinitialisation du mot de passe n'existe pas encore côté API : le lien « Mot de passe oublié » l'indique au joueur.
- Le site est exporté en version de debug : le menu de test (F1) y est accessible.
- Le jeu est prévu pour ordinateur, au clavier et à la souris : pas de version mobile ni de manette.
- Les tests fonctionnels du jeu demandent une API de test et un faux serveur SMTP locaux ; sans eux, seuls les tests statiques et unitaires tournent.