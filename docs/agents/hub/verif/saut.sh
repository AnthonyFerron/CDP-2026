#!/usr/bin/env bash
# Sonde de saut : saut.sh <journal> x0 z0 x1 z1 pas distance livres  (SONDE_DEPART, SONDE_SOL facultatifs)
WT=${WT:-/home/ubuntu/cdp-dev/.claude/worktrees/verif-hub}
cd "$WT/frontend" || exit 1
log=$1; shift
timeout 20000 /home/ubuntu/cdp-work/bin/godot --audio-driver Dummy --headless --path . --fixed-fps 60 \
	--script /home/ubuntu/cdp-dev/.claude/captures/verif-hub/outils/saut.gd -- "$@" --api=http://127.0.0.1:9/api/v1 > "$log" 2>&1
echo "exit=$? $(grep -E '^SAUT' "$log" | tr '\n' ' ') $(grep -c 'SCRIPT ERROR' "$log") erreurs"
