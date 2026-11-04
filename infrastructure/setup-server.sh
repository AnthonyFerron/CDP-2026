#!/bin/bash
# Prépare le serveur de production. À lancer une fois avec sudo, après avoir installé Docker.
# La clé privée n'est écrite nulle part : elle s'affiche à la fin, à copier dans GitHub.
set -euo pipefail

PUBLIC_IP=145.241.175.16
BASE=/opt/cdp-2026

[ "$(id -u)" -eq 0 ] || { echo "À lancer avec sudo" >&2; exit 1; }
command -v docker >/dev/null || { echo "Docker n'est pas installé" >&2; exit 1; }

# Pare-feu : 80 et 443 avant le REJECT, à chaud et après redémarrage
if ! iptables -C INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT 2>/dev/null; then
  iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
  iptables -I INPUT 6 -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
  iptables -I INPUT 7 -p udp -m udp --dport 443 -j ACCEPT
  sed -i '/-A INPUT .*--dport 22 -j ACCEPT/a -A INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT\n-A INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT\n-A INPUT -p udp -m udp --dport 443 -j ACCEPT' /etc/iptables/rules.v4
  iptables-restore --test /etc/iptables/rules.v4
fi

# Utilisateur sans mot de passe, dédié au déploiement
id deploy >/dev/null 2>&1 || useradd --create-home --shell /bin/bash --groups docker deploy
passwd --lock deploy >/dev/null
install -d -o deploy -g deploy -m 750 "$BASE"

# Secrets de production, stockés uniquement sur le serveur
if [ ! -f "$BASE/.env" ]; then
  (umask 077; printf 'POSTGRES_PASSWORD=%s\nSITE_ADDRESS=:80\n' "$(openssl rand -hex 32)" > "$BASE/.env")
  chown deploy:deploy "$BASE/.env"
fi

# Sauvegardes prises avant chaque migration, hors du dépôt cloné
install -d -o deploy -g deploy -m 700 "$BASE/backups"

# Script de déploiement versionné : relancer ce script après l'avoir modifié
install -m 755 "$(dirname "$(readlink -f "$0")")/cdp-deploy" /usr/local/bin/cdp-deploy

# Clé SSH limitée à cdp-deploy : elle ne peut lancer aucune autre commande.
# Une clé déjà installée est conservée, pour que relancer ce script n'invalide pas les secrets GitHub.
if [ -s /home/deploy/.ssh/authorized_keys ]; then
  echo "Clé de déploiement existante conservée : les secrets GitHub restent valables."
  exit 0
fi

KEYDIR=$(mktemp -d)
trap 'rm -rf "$KEYDIR"' EXIT
ssh-keygen -q -t ed25519 -N '' -C github-actions-deploy@cdp-2026 -f "$KEYDIR/key"
install -d -o deploy -g deploy -m 700 /home/deploy/.ssh
printf 'restrict,command="/usr/local/bin/cdp-deploy" %s\n' "$(cat "$KEYDIR/key.pub")" > /home/deploy/.ssh/authorized_keys
chown deploy:deploy /home/deploy/.ssh/authorized_keys
chmod 600 /home/deploy/.ssh/authorized_keys

echo
echo "=== Secrets à créer dans GitHub : Settings > Secrets and variables > Actions ==="
echo
echo "DEPLOY_HOST"
echo "$PUBLIC_IP"
echo
echo "DEPLOY_KNOWN_HOSTS"
echo "$PUBLIC_IP $(cut -d' ' -f1,2 /etc/ssh/ssh_host_ed25519_key.pub)"
echo
echo "DEPLOY_SSH_KEY"
cat "$KEYDIR/key"
