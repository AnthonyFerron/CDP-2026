#!/bin/bash
# Déploie la version du dépôt : sauvegarde de la base, migrations Alembic, puis mise à jour des conteneurs.
# Lancé par cdp-deploy depuis /opt/cdp-2026/app, après la récupération de main (voir docs/deploiement.md).
#
# Tant que la sauvegarde et les migrations n'ont pas réussi, aucun conteneur en service n'est modifié :
# l'API en place continue de répondre. La moindre erreur arrête le déploiement.
set -euo pipefail

BASE=${CDP_BASE:-/opt/cdp-2026}
ENV_FILE=$BASE/.env
BACKUP_DIR=$BASE/backups

cd "$(dirname "$(readlink -f "$0")")/.."

export COMPOSE_FILE=${COMPOSE_FILE:-infrastructure/docker-compose.prod.yml}
# Exigé par docker-compose.prod.yml : un cdp-deploy trop ancien, qui lancerait les conteneurs sans
# appliquer les migrations, échoue ainsi avant de toucher à quoi que ce soit.
export CDP_DEPLOY=deploy.sh

compose() {
  docker compose --env-file "$ENV_FILE" "$@"
}

step() {
  echo "==> $*"
}

# Un seul déploiement à la fois, y compris lancé à la main
exec 8>"$BASE/.deploy-migrations.lock"
if ! flock --nonblock 8; then
  echo "Un autre déploiement est en cours : abandon." >&2
  exit 1
fi

step "Construction des images (les conteneurs en service ne sont pas touchés)"
compose build

step "Démarrage de la base si elle n'existe pas encore (une base en service est laissée telle quelle)"
compose up --detach --wait --no-recreate db

step "Sauvegarde de la base"
install -d -m 700 "$BACKUP_DIR"
revision=$(git rev-parse --short HEAD 2>/dev/null || echo inconnue)
backup="$BACKUP_DIR/escape_game_$(date -u +%Y%m%dT%H%M%SZ)_$revision.dump"
trap 'rm -f "$backup.partial"' EXIT
umask 077
# pg_dump tourne dans le conteneur de la base : aucun mot de passe ne passe en ligne de commande.
# shellcheck disable=SC2016 # variables développées dans le conteneur, pas ici
compose exec -T db sh -c 'pg_dump --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --format=custom' \
  > "$backup.partial"
# Une sauvegarde illisible arrête le déploiement avant toute migration.
compose exec -T db pg_restore --list < "$backup.partial" > /dev/null
mv "$backup.partial" "$backup"
echo "Sauvegarde : $backup ($(du -h "$backup" | cut -f1))"

step "Migrations Alembic, avec la nouvelle image, dans un conteneur jetable"
# Toutes les migrations en attente passent dans une seule transaction : en cas d'échec, la base revient
# à son état de départ. env.py prend aussi un verrou PostgreSQL contre les migrations simultanées.
compose run --rm --no-deps -T api alembic upgrade head

step "Mise à jour des conteneurs"
compose up --detach --wait --wait-timeout 120 --remove-orphans

echo "Déploiement terminé ($revision)."
