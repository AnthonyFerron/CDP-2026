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
| Regarder autour | Souris |
| Libérer la souris | Échap |
| Reprendre la souris | Clic |

## Organisation du projet

| Dossier | Contenu |
| --- | --- |
| `frontend/` | Projet Godot |
| `frontend/assets/` | Modèles, textures, matériaux, audio et polices |
| `frontend/scenes/levels/` | Niveaux |
| `frontend/scenes/player/` | Personnage joueur (scène et script) |
| `frontend/scenes/ui/` | Interfaces |
| `frontend/scripts/` | Scripts partagés qui n'appartiennent à aucune scène |
| `backend/` | API Python |
| `docs/` | Documentation technique |
| `infrastructure/` | Base de données locale avec Docker |

Un script propre à une scène se range à côté de celle-ci. Les fichiers et dossiers sont nommés en `snake_case`.

## Hébergement

Le jeu est publié sur <https://anthonyferron.github.io/CDP-2026/> à chaque push sur `main`, par le workflow `.github/workflows/deploy-web.yml`. Il exporte le préréglage `Web` de `frontend/export_presets.cfg`, à versionner sans jamais y laisser de mot de passe ou de chemin local.

Pour une mise à jour de Godot, changer `GODOT_VERSION` dans le workflow.

## Licences

`LICENCES.md` liste tout ce que le projet utilise. Ajouter une ligne pour chaque modèle, texture, son, police ou bibliothèque venant de l'extérieur, avant de le commiter.

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
