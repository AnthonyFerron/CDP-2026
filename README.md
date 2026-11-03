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
| Regarder autour | Souris |
| Libérer la souris | Échap |
| Reprendre la souris | Clic |

## Debug

En version de debug, `F1` ouvre un menu temporaire qui permet de passer d'un niveau à l'autre. Il n'apparaît pas dans le jeu publié. Il liste les scènes de `frontend/scenes/levels/`, et les sous-dossiers qui contiennent une scène du même nom, comme `plaine/plaine.tscn` : nommer ainsi la scène principale de chaque niveau pour qu'elle y apparaisse. Le bouton « Réinitialiser la partie » efface la sauvegarde.

## Progression

Le jeu démarre dans le hub, `frontend/scenes/levels/hub/hub.tscn`. Chaque portail en arche mène à une zone ; le livre d'une zone, une fois pris, est posé sur l'autel du hub, et le plateau reverdit à chaque livre rapporté. Le joueur revient devant le portail de la zone qu'il quitte.

L'autoload `GameState` (`frontend/scripts/game_state.gd`) garde les livres et la dernière zone, et les sauvegarde dans `user://sauvegarde.cfg` à chaque changement. Pour ajouter une zone, renseigner sa scène dans `ZONE_SCENES` et appeler `GameState.collect_book()` quand le livre est pris.

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

## Hébergement

Le jeu est publié sur <https://codequest.anthonyferron.com>, avec l'API sous `/api/` sur le même domaine. Le serveur exporte le préréglage `Web` de `frontend/export_presets.cfg`, à versionner sans jamais y laisser de mot de passe ou de chemin local.

Pour une mise à jour de Godot, changer `GODOT_VERSION` dans `frontend/Dockerfile`, ainsi que dans `.github/workflows/deploy-web.yml`, qui publie sur GitHub Pages et ne se lance plus que manuellement.

## Sons

Les sons du jeu (vent, lave, marais, désert, cave, hub, pas, feu, porte, tablettes) sont synthétisés par `frontend/tools/generate_sounds.py`, sans dépendance externe. Pour en modifier un, changer sa fonction dans le script puis le relancer depuis `frontend` avec `python tools/generate_sounds.py`.

## Licences

`LICENCES.md` liste tout ce que le projet utilise. Ajouter une ligne pour chaque modèle, texture, son, police ou bibliothèque venant de l'extérieur, avant de le commiter.

## Déploiement

Chaque push sur `main` qui modifie `backend/`, `frontend/` ou `infrastructure/` lance les tests de l'API, puis déploie le jeu et l'API sur le serveur de production avec Docker Compose (voir `.github/workflows/deploy.yml`). Si les tests échouent, rien n'est déployé.

Le serveur se prépare une seule fois avec `sudo bash infrastructure/setup-server.sh`, qui affiche les secrets à créer dans GitHub. Les secrets de production se trouvent dans `/opt/cdp-2026/.env` et ne sont jamais versionnés. Après avoir modifié ce fichier, relancer `cdp-deploy` en tant qu'utilisateur `deploy`.

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
