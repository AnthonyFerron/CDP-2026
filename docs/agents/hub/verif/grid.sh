#!/usr/bin/env bash
# Grille de marche : grid.sh <livres> <fichier des zones> <journal> [dossier de sortie]
cd /home/ubuntu/cdp-dev/.claude/worktrees/verif-hub/frontend || exit 1
OUT=${4:-/home/ubuntu/cdp-dev/.claude/captures/verif-hub/grille}
timeout 5400 xvfb-run -a -s "-screen 0 1920x1080x24" /home/ubuntu/cdp-work/bin/godot --audio-driver Dummy --path . --resolution 640x360 \
	--script /home/ubuntu/cdp-dev/.claude/captures/verif-hub/outils/grille.gd -- "$1" "$2" "$OUT" --api=http://127.0.0.1:9/api/v1 > "$3" 2>&1
echo "exit=$?"; grep -E "RESUME|SCRIPT ERROR|Parse Error|BOITES" "$3"
