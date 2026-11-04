# Déploiement

Comment le code passe en production, ce que fait chaque étape, et les règles à respecter pour que les migrations de la base ne cassent pas l'API en service.

## Ce qui se déclenche, et quand

| Événement | Workflow | Effet |
| --- | --- | --- |
| Pull request vers `dev` ou `main` (ouverture, nouveau commit) | `tests.yml` | Tests du backend sur PostgreSQL 17. Aucun secret, aucun déploiement |
| Fusion ou push sur `dev` | aucun | Rien |
| Push sur `main` touchant `backend/`, `frontend/`, `infrastructure/`, `LICENCES.md` ou `deploy.yml` | `deploy.yml` | Tests, puis déploiement si tous réussissent |
| Lancement manuel de `deploy.yml` | `deploy.yml` | Déploiement seulement s'il est lancé sur `main` |
| Lancement manuel de `deploy-web.yml` | `deploy-web.yml` | Publication du jeu sur GitHub Pages, sans toucher au serveur |

Le job de déploiement se connecte au serveur avec une clé SSH qui ne peut lancer qu'une commande : `/usr/local/bin/cdp-deploy`. Ce script récupère toujours `main`, quelle que soit la branche qui a déclenché le workflow.

## Ce que fait un déploiement

`cdp-deploy` (fichier `infrastructure/cdp-deploy`) :

1. prend le verrou `/opt/cdp-2026/.deploy.lock` : un seul déploiement à la fois ;
2. récupère `main` dans `/opt/cdp-2026/app` ;
3. lance `infrastructure/deploy.sh`, versionné avec le code ;
4. supprime les images Docker devenues inutiles.

`infrastructure/deploy.sh` :

| Étape | Ce qui est touché | En cas d'échec |
| --- | --- | --- |
| 1. Construction des images (API et jeu) | Rien en service | Arrêt. L'ancienne version continue de tourner |
| 2. Démarrage de la base si elle n'existe pas | Rien si la base tourne déjà (`--no-recreate`) | Arrêt |
| 3. Sauvegarde `pg_dump`, relue avec `pg_restore --list` | Un fichier dans `/opt/cdp-2026/backups` | Arrêt avant toute migration |
| 4. `alembic upgrade head`, avec la nouvelle image, dans un conteneur jetable | Le schéma de la base | Arrêt. Toutes les migrations passent dans une seule transaction : la base revient à son état de départ |
| 5. Mise à jour des conteneurs (`docker compose up --wait`) | Les conteneurs dont l'image ou la configuration a changé | Arrêt, base déjà migrée : voir « Si l'étape 5 échoue » |

Jusqu'à la fin de l'étape 4, l'API en service n'est pas touchée et continue de répondre. Mesures faites sur un environnement isolé :

- déploiement sans changement de l'API : aucune coupure ;
- API remplacée : environ 2,5 secondes sans réponse, pendant l'étape 5 uniquement.

Deux verrous empêchent les migrations simultanées :

- `flock` sur `/opt/cdp-2026/.deploy-migrations.lock` : un second `deploy.sh` s'arrête aussitôt ;
- `pg_advisory_lock` dans `backend/alembic/env.py` : une seconde migration, lancée d'où que ce soit, attend la fin de la première puis constate que la base est à jour.

Les secrets restent dans `/opt/cdp-2026/.env`. `pg_dump` tourne dans le conteneur de la base et `alembic` dans un conteneur de l'API : aucun mot de passe ne passe en ligne de commande.

## Mise en place sur le serveur

**État au 4 novembre 2026 : le serveur utilise encore l'ancien `cdp-deploy`**, qui ne sauvegarde pas la base et n'applique pas les migrations. Le nouveau est prêt dans le dépôt mais n'est pas installé.

Le compose de production exige la variable `CDP_DEPLOY`, que seul `deploy.sh` définit. Tant que l'ancien `cdp-deploy` est en place, un déploiement de cette version échoue donc dès la lecture de `docker-compose.prod.yml`, avant de toucher aux conteneurs. La production reste telle quelle, et le workflow apparaît en échec.

Installation, une seule fois, depuis un dépôt à jour :

```sh
sudo install -m 755 infrastructure/cdp-deploy /usr/local/bin/cdp-deploy
sudo install -d -o deploy -g deploy -m 700 /opt/cdp-2026/backups
```

Le nouveau `cdp-deploy` peut être installé avant ou après la fusion dans `main` : avec un `main` qui n'a pas encore `deploy.sh`, il déploie comme l'ancien. Relancer `sudo bash infrastructure/setup-server.sh` fait la même chose, sans régénérer la clé SSH si elle existe déjà.

Pour valider le mécanisme après l'installation, lancer un déploiement à la main (`sudo -u deploy cdp-deploy`) et vérifier :

- la nouvelle sauvegarde dans `/opt/cdp-2026/backups` ;
- la sortie d'`alembic upgrade head` ;
- `/api/v1/health/database`.

## Sauvegardes

- Une sauvegarde par déploiement : `/opt/cdp-2026/backups/escape_game_<date UTC>_<commit>.dump`, au format custom de `pg_dump`.
- Fichiers en `600`, dossier en `700`, propriétaire `deploy`. Ils contiennent les e-mails et les empreintes de mots de passe des joueurs : ne pas les copier hors du serveur sans précaution.
- Aucune suppression automatique. Supprimer à la main les plus anciennes quand la place manque, en gardant au moins celle qui précède la dernière migration.
- Elles restent sur le même disque que la base : elles protègent d'une migration ratée, pas d'une perte du serveur.

Vérifier qu'une sauvegarde se relit :

```sh
docker exec -i cdp2026-db-1 pg_restore --list < /opt/cdp-2026/backups/<fichier>.dump
```

La restaurer dans une base séparée, pour l'examiner sans toucher à la production :

```sh
docker exec cdp2026-db-1 createdb -U escape_user restauration
docker exec -i cdp2026-db-1 pg_restore -U escape_user --dbname restauration < /opt/cdp-2026/backups/<fichier>.dump
# … vérifications, puis :
docker exec cdp2026-db-1 dropdb -U escape_user restauration
```

Remplacer la base de production par une sauvegarde efface tout ce qui a été écrit depuis : à ne faire qu'en dernier recours, API arrêtée, après en avoir pris une nouvelle sauvegarde.

## Écrire une migration

**Toute migration doit rester compatible avec la version précédente de l'API.** Pendant un déploiement, l'ancienne API tourne sur le nouveau schéma entre les étapes 4 et 5. Après un retour au code précédent, elle y tourne aussi durablement.

Compatibles, en un seul déploiement :

- ajouter une table ;
- ajouter une colonne nullable, ou avec une valeur par défaut ;
- ajouter un index ;
- insérer des données de référence (avec `ON CONFLICT`) ;
- ajouter une contrainte que les données existantes et l'ancien code respectent.

Incompatibles en un seul déploiement : l'ancienne API planterait.

- supprimer ou renommer une colonne ou une table ;
- changer le type d'une colonne ;
- rendre obligatoire (`NOT NULL`) une colonne que l'ancien code laisse vide ;
- ajouter une contrainte que l'ancien code peut enfreindre.

Pour ces changements, procéder en deux déploiements :

1. ajouter la nouvelle structure, et livrer un code qui sait utiliser l'ancienne comme la nouvelle ;
2. une fois ce code en production, retirer l'ancienne structure.

Autres précautions :

- Les migrations d'un déploiement passent dans une seule transaction, qui verrouille les tables modifiées : sur une grosse table, une réécriture complète bloque l'API pendant toute sa durée.
- Avant de proposer une migration : `alembic check` (modèles et migrations cohérents), les tests, et un aller-retour `downgrade` puis `upgrade` sur une base de test.
- Ne jamais modifier une migration déjà appliquée en production : en écrire une nouvelle.

## Si l'étape 5 échoue

La base est migrée, mais l'API peut être arrêtée ou ne pas répondre : `docker compose up` a déjà remplacé l'ancien conteneur. Dans l'ordre :

1. Lire les journaux : `docker logs cdp2026-api-1`.
2. Corriger et pousser sur `main`, ou revenir au commit précédent (`git revert`) : comme les migrations sont compatibles avec l'ancienne API, elle redémarre sur le schéma migré.
3. Ne restaurer la sauvegarde que si les données elles-mêmes sont abîmées.

## Commandes manuelles

`docker-compose.prod.yml` exige `CDP_DEPLOY`. Pour une commande lancée à la main, depuis `/opt/cdp-2026/app` :

```sh
CDP_DEPLOY=manuel docker compose -f infrastructure/docker-compose.prod.yml --env-file /opt/cdp-2026/.env ps
```

Appliquer les migrations sans redéployer, dans l'API en service (procédure du 4 novembre 2026) :

```sh
docker exec cdp2026-db-1 sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc' > /opt/cdp-2026/backups/<nom>.dump
docker exec -i cdp2026-db-1 pg_restore --list < /opt/cdp-2026/backups/<nom>.dump > /dev/null
docker exec cdp2026-api-1 alembic upgrade 28803cd8c266:head --sql   # relire le SQL, sans rien exécuter
docker exec -e PGOPTIONS=-clock_timeout=10s cdp2026-api-1 alembic upgrade head
```

## Limites

- Pendant l'étape 5, l'API est coupée quelques secondes si son image change : il n'y a qu'un conteneur.
- Si l'étape 5 échoue après les migrations, l'API peut rester arrêtée jusqu'à une correction.
- Les sauvegardes sont sur le même serveur que la base.
- `deploy.sh` s'exécute depuis `main` avec les droits de l'utilisateur `deploy`, membre du groupe `docker`. Pousser sur `main`, c'est donc déjà pouvoir agir sur le serveur, comme avec les fichiers compose et les Dockerfile. Protéger `main` et `dev` sur GitHub (pull request obligatoire, réussite de « Tests du backend » exigée) limite ce risque.
- Les tests ne tournent que sur les pull requests vers `dev` et `main`, et avant chaque déploiement : un push direct sur `dev` n'est pas testé.
