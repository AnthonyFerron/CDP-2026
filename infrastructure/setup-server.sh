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

cat > /usr/local/bin/cdp-deploy <<'EOF'
#!/bin/bash
set -euo pipefail

BASE=/opt/cdp-2026

exec 9>"$BASE/.deploy.lock"
flock 9

if [ ! -d "$BASE/app/.git" ]; then
  git clone --depth 1 --branch main https://github.com/AnthonyFerron/CDP-2026.git "$BASE/app"
fi

cd "$BASE/app"
git fetch --depth 1 origin main
git reset --hard FETCH_HEAD
git lfs install --local >/dev/null
git lfs pull
echo "Déploiement de $(git rev-parse --short HEAD)"

docker compose -f infrastructure/docker-compose.prod.yml --env-file "$BASE/.env" \
  up --detach --build --wait --wait-timeout 120 --remove-orphans
docker image prune --force
EOF
chmod 755 /usr/local/bin/cdp-deploy

# Clé SSH limitée à cdp-deploy : elle ne peut lancer aucune autre commande
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
