# CDP-2026

Jeu 3D développé avec Godot 4.7 en GDScript.

## Installation

1. Installer [Godot 4.7.2](https://godotengine.org/download/archive/4.7.2-stable/) (version standard, pas .NET) et [Git LFS](https://git-lfs.com/).
2. Activer Git LFS, une seule fois par machine, **avant de cloner** :

   ```sh
   git lfs install
   ```

3. Cloner le dépôt, puis importer `frontend/project.godot` depuis le gestionnaire de projets de Godot.
4. Lancer le jeu avec `F5`.

## Commandes

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

## Menus

Le jeu s'ouvre sur l'accueil, `frontend/scenes/ui/menus/main_menu.tscn`, dessiné d'après les maquettes par `main_menu.gd` et les éléments communs de `ornate.gd` (cadres, boutons, champs, icônes, fond de nuit).

- **Accueil invité** : « Jouer en tant qu'invité », « Charger partie » (s'il existe une partie invitée en cours sur cet appareil), « Se connecter » et « Créer un compte » ; « Classement » est grisé.
- **Connexion** et **création de compte** mènent à la **vérification en deux étapes** : six cases, un chiffre par case, un code collé se répartit seul ; « Valider » reste grisé tant que le code n'est pas complet. « Retour » ramène à l'écran d'où l'on vient.
- **Accueil connecté** : portrait et pseudo, « Nouvelle partie », « Charger partie » (s'il existe une partie en cours, lue sur le serveur : elle se reprend sur n'importe quel appareil), « Classement » et « Se déconnecter ». Une nouvelle partie demande confirmation si une partie est en cours, puis abandonne celle-ci sur le serveur. Après la vérification du code, le menu propose de rattacher au compte la partie invitée de l'appareil ; elle ne comptera pas pour le classement.
- **Introduction** avant chaque nouvelle partie, puis le jeu commence dans le bunker.
- **Pause** (Échap ou P) : reprendre, ou sauvegarder et revenir au menu. Sur le web, elle s'ouvre aussi quand le navigateur libère la souris.
- **Indice** (H) : trois indices par zone, du plus vague au plus précis, un de plus à chaque ouverture ; au hub, l'indice dit où aller.
- **Classement** : général ou par énigme (onglets), les trois premiers en or, argent et bronze, vingt par page. Rangs et temps viennent de l'API : le temps d'une partie est mesuré par le serveur, jamais envoyé par le jeu.

Chaque changement de lieu passe par l'autoload `Transition` (`frontend/scripts/transition.gd`) : l'écran passe au noir, puis le chapitre, le nom du lieu et son énigme (d'après le scénario, `GameState.ZONE_TITLES` et `GameState.hub_title()`) apparaissent ligne par ligne pendant que la scène suivante se charge ; elle ne se dévoile qu'une fois construite, et le chronomètre est arrêté pendant ce temps. Utiliser `Transition.change_scene(chemin, lignes)` plutôt que `change_scene_to_file`.

Chaque compte a sa propre sauvegarde (`user://sauvegarde_compte_<identifiant>.cfg`), l'invité garde `user://sauvegarde.cfg`. Elles gardent les livres trouvés et posés, les fragments de papier du Village, le temps, le niveau et la position.

Le jeu est branché sur l'API (voir `docs/api-godot.md`) par trois autoloads : `Api` (`frontend/scripts/api.gd`) envoie les requêtes, `Account` (`frontend/scripts/account.gd`) gère le compte et les classements pour les menus, et `GameSync` (`frontend/scripts/game_sync.gd`) synchronise la partie d'un joueur connecté. Pour un joueur connecté, le serveur fait foi : un livre n'est posé et la victoire n'est jouée qu'après sa confirmation. La réinitialisation du mot de passe n'existe pas encore côté API : le lien l'indique au joueur.

## Debug

En version de debug, `F1` ouvre un menu de test sur toute la page : aller dans chaque niveau ou au menu principal ; trouver ou **poser chaque livre** (« Poser » amène au château, met le livre en main et joue la vraie pose, avec le plan large sur la reconstruction et le rituel au quatrième livre ; « Tout poser d'un coup » saute les animations) ; régler le chronomètre, passer l'introduction du bunker, lancer les deux fins ; se connecter avec un compte de test simulé, sans serveur (`Account.simulated`). Avec un vrai compte, ces réglages ne changent que la partie locale : le serveur garde son propre temps. Le site est pour l'instant exporté en version de debug (`--export-debug` dans `frontend/Dockerfile`), le menu y est donc disponible ; repasser à `--export-release` pour le retirer. Il liste les scènes de `frontend/scenes/levels/`, et les sous-dossiers qui contiennent une scène du même nom, comme `plaine/plaine.tscn` : nommer ainsi la scène principale de chaque niveau pour qu'elle y apparaisse. Le bouton « Réinitialiser la partie » efface la sauvegarde.

## Progression

Le jeu démarre dans le hub, `frontend/scenes/levels/hub/hub.tscn`, à l'intérieur du bunker où vivent les survivants, à l'est du village de Codia. Le roi Codeon V et Merlon y confient la mission : la porte ne s'ouvre qu'une fois les deux écoutés, et le chronomètre du volcan part de là. Dehors, le château du roi est au nord. Le joueur revient devant le portail de la zone qu'il quitte.

- Les portails s'ouvrent dans l'ordre Plaine, Désert, Marais, Village : chacun attend que le livre de la zone précédente soit posé au château.
- Un livre trouvé vole jusqu'à la main du joueur, qui le tient en bas de l'écran. Il faut le rapporter soi-même dans la salle des livres, au cœur du donjon du château, et le poser sur son piédestal, devant le trône du roi : il quitte alors la main pour s'y poser.
- Chaque livre posé répare une partie du village : quatre maisons par livre, en commençant par les plus proches du camp, puis le marché, la cour du château, la fontaine, les drapeaux et les toits des tours du donjon. Un plan large montre le village qui se relève, et le ciel s'éclaircit.
- Autour du cœur du village : la taverne et la forge (premier livre), l'école et la ferme avec ses champs (deuxième), la chapelle et le cimetière des soldats (troisième), et la mine d'argent effondrée au pied des montagnes, au nord-est. Chaque lieu a son panneau à lire, qui raconte un peu de l'histoire de Codia.
- Tous les habitants, le roi, Merlon et le garde compris, restent au bunker pendant la partie. Le dernier livre posé, ils en sortent : Merlon et le roi rejoignent la salle du château, où Merlon accomplit le rituel, et les autres se rassemblent autour du feu de la place, puis la bonne fin se joue. Après la cinématique, le joueur reprend la main devant le château : tous les portails restent ouverts pour revisiter les zones.

L'autoload `GameState` (`frontend/scripts/game_state.gd`) garde les livres trouvés, les livres posés et la dernière zone, et les sauvegarde dans `user://sauvegarde.cfg` à chaque changement. Pour ajouter une zone, renseigner sa scène dans `ZONE_SCENES`, sa place dans `ZONE_ORDER` et son livre dans `ZONE_BOOKS`, puis appeler `GameState.collect_book()` quand le livre est pris.

Le décor du hub est généré par `frontend/tools/build_hub.py`. Chaque élément réparable y est écrit deux fois, en ruine et reconstruit, sous `Repairs/<nom>`, avec le nombre de livres qui le répare dans sa métadonnée `stage`.

## Chronomètre du volcan

Le Mont Sam Altan entre en éruption au bout de 60 minutes (`GameState.TOTAL_TIME`) : le scénario en annonce quarante, l'équipe a choisi une heure. Le temps restant s'affiche en haut à droite, passe au rouge sous 5 minutes, et il est sauvegardé avec la partie. Chaque mauvaise validation d'une énigme retire 5 minutes (`GameState.penalize()`). À zéro, le jeu se fige sur l'écran de fin, et « Recommencer » relance une partie depuis le hub. Le temps s'arrête une fois les quatre livres réunis.

Il ne court que dans un niveau, hors pause : il s'arrête dans les menus, la pause, les indices et les chargements. Pour un joueur connecté, le serveur fait foi : le temps affiché est recalé sur le sien, son chronomètre s'arrête quand le jeu reste figé plus d'une seconde, et c'est lui qui déclare l'éruption.

## Énigmes

| Zone | Énigme | Livre | Solution |
| --- | --- | --- | --- |
| Plaines d'Hexcole | Les fragments du passé : six fragments cachés dans les livres de la bibliothèque, à remettre dans l'ordre sur la tablette | Projenomicon | Ordre de la conversation : restauration à organiser, objectifs, inventaire, planning, suivi, vérification et clôture |
| Désert de Pythania | Les algorithmes oubliés : runes à ramasser ou à dégager du sable en maintenant E, à poser sur la table ronde de la cave | Algonicon | Jarre : TANT QUE, Puiser, Porter. Porte : SI, Ouvrir, SINON. « POUR » et « Fermer » sont des leurres |
| Marais de Kernel Swamp | Le tombeau du chiffrement : mécanisme à cinq cercles dans la crypte souterraine ; les épitaphes des rois Codeon I à IV, dans la chambre ouest, à l'opposé du tombeau du livre, redonnent la règle | Logiconomicon | CODIA décalé de +3, −3, +3, −3, +3 : **FLGFD** |
| Village détruit | Les cinq langages oubliés : dix fragments de papier cachés dans la mairie (touche I pour les relire), cinq extraits de code à résoudre dans l'ordre sur le dispositif du bureau du maire | Codonomicon | HTML : **3**. CSS : **green**. Python : **10**. PHP : **2**. TypeScript : **12** |

## Tests du jeu

`frontend/tests/run_tests.tscn` vérifie sans affichage que tous les scripts compilent et que toutes les scènes se chargent, puis teste la sauvegarde, le chronomètre, les fragments, les livres et l'import invité :

```sh
godot --headless --path frontend res://tests/run_tests.tscn
```

Avec une API de test et un faux serveur SMTP, il joue aussi de vrais parcours : inscription et code par e-mail, partie complète, reprise sur un autre appareil, défaite, classements, import invité, coupure réseau (voir `docs/api-godot.md`). Jamais contre la production : le script refuse. Le dossier `tests/` n'est pas exporté.

## Organisation du projet

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

Un script propre à une scène se range à côté de celle-ci. Les fichiers et dossiers sont nommés en `snake_case`.

## API

L'API FastAPI de `backend/` gère les comptes avec double authentification par e-mail, les parties et leur chronomètre, les énigmes et les classements. Sa documentation interactive est servie sur `/api/docs`. Les routes et les règles sont dans `docs/api-contract.md`, et le branchement côté Godot dans `docs/api-godot.md`.

Les tests de l'API demandent une base PostgreSQL dédiée, indiquée par `TEST_DATABASE_URL` (voir la section Tests de `docs/api-contract.md`). Ils tournent sur chaque pull request vers `dev` ou `main`. Une migration Alembic doit rester compatible avec la version précédente de l'API : voir `docs/deploiement.md`.

## Hébergement

Le jeu est publié sur <https://codequest.anthonyferron.com>, avec l'API sous `/api/` sur le même domaine. Le serveur exporte le préréglage `Web` de `frontend/export_presets.cfg`, à versionner sans jamais y laisser de mot de passe ou de chemin local.

Pour une mise à jour de Godot, changer `GODOT_VERSION` dans `frontend/Dockerfile`, ainsi que dans `.github/workflows/deploy-web.yml`, qui publie sur GitHub Pages et ne se lance plus que manuellement.

## Sons

Les sons du jeu (vent, lave, marais, désert, cave, hub, village, ruisseau, pas, feu, porte, tablettes) sont synthétisés par `frontend/tools/generate_sounds.py`, sans dépendance externe. Pour en modifier un, changer sa fonction dans le script puis le relancer depuis `frontend` avec `python tools/generate_sounds.py`.

Les symboles de l'interface (flèches du mécanisme, coche des codes résolus) sont dessinés par `frontend/scripts/ui_icons.gd`, et ceux des scènes (runes, soleils des stèles, repère du mécanisme) sont des maillages : Cinzel et Lora n'ont pas ces caractères, et la version web n'a pas de police système pour les remplacer. Ne pas écrire de symbole hors de l'alphabet latin dans un texte affiché.

Les textures Kenney enregistrées en palette de 256 couleurs (château, arène, survie, nourriture) ont été réécrites en couleurs vraies par `frontend/tools/smooth_colormaps.py`, qui lisse leurs dégradés : en palette, chaque marche du dégradé devenait une raie horizontale sur les murs agrandis. Relancer ce script après avoir remplacé l'un de ces kits.

En vue à la première personne, le corps de Devlyn ne se voit pas mais projette son ombre : `frontend/scenes/player/devlyn.gd` balance ses jambes et ses bras à chaque pas, pour que l'ombre marche avec le joueur.

## Licences

`LICENCES.md` liste tout ce que le projet utilise. Ajouter une ligne pour chaque modèle, texture, son, police ou bibliothèque venant de l'extérieur, avant de le commiter.

## Déploiement

Chaque push sur `main` qui modifie `backend/`, `frontend/` ou `infrastructure/` lance les tests de l'API, puis déploie le jeu et l'API sur le serveur de production (voir `.github/workflows/deploy.yml`). Si les tests échouent, rien n'est déployé. Une pull request ne déploie jamais rien : elle lance seulement les tests (`.github/workflows/tests.yml`).

Sur le serveur, `cdp-deploy` récupère `main` et lance `infrastructure/deploy.sh`, qui sauvegarde la base dans `/opt/cdp-2026/backups`, applique les migrations Alembic, puis met les conteneurs à jour. Si la sauvegarde ou une migration échoue, le déploiement s'arrête et l'API en service n'est pas touchée. Le détail, la restauration d'une sauvegarde et les règles d'écriture des migrations sont dans `docs/deploiement.md`.

Le serveur se prépare une seule fois avec `sudo bash infrastructure/setup-server.sh`, qui installe `cdp-deploy` et affiche les secrets à créer dans GitHub. Le relancer met `cdp-deploy` à jour sans changer la clé de déploiement. Les secrets de production se trouvent dans `/opt/cdp-2026/.env` et ne sont jamais versionnés. Après avoir modifié ce fichier, relancer `cdp-deploy` en tant qu'utilisateur `deploy`.

Le domaine est défini par `SITE_ADDRESS` dans ce fichier. Il pointe vers le serveur avec un enregistrement DNS sans proxy Cloudflare, et Caddy obtient le certificat HTTPS tout seul.

## Travailler avec Git

| Branche | Rôle |
| --- | --- |
| `main` | Version stable : le jeu s'y lance toujours sans erreur |
| `dev` | Intégration du travail en cours |
| `feature/<sujet>` | Une tâche, créée depuis `dev` |

Pour commencer une tâche :

```sh
git switch dev
git pull
git switch -c feature/inventaire
```

Une fois la tâche finie, pousser la branche et ouvrir une pull request vers `dev`. Quand `dev` est stable, on la fusionne dans `main` par une pull request.

### Éviter les conflits

Les fichiers `.tscn` se fusionnent mal, surtout quand deux personnes modifient la même scène.

- Prévenir l'autre avant de modifier une scène partagée, comme un niveau.
- Découper les éléments en petites scènes indépendantes.
- Récupérer `dev` régulièrement dans sa branche de travail.
- Toujours versionner les fichiers `.import` et `.uid`, jamais le dossier `.godot/`.
