#!/usr/bin/env bash
# Captures : shoot.sh <dossier> <livres> <fichier de vues> [colonnes] [worktree]
WT=${5:-/home/ubuntu/cdp-dev/.claude/worktrees/verif-hub}
cd "$WT/frontend" || exit 1
mkdir -p "$1"
timeout 5400 xvfb-run -a -s "-screen 0 1920x1080x24" /home/ubuntu/cdp-work/bin/godot --audio-driver Dummy --path . --resolution 1280x720 \
	--script /home/ubuntu/cdp-dev/.claude/captures/verif-hub/outils/shots.gd -- "$1" "$2" "$3" "${4:-2}" --api=http://127.0.0.1:9/api/v1 > "$1/shots.log" 2>&1
echo "exit=$? $(grep -c 'SCRIPT ERROR' "$1/shots.log") erreurs $(grep CAPTURES "$1/shots.log")"
