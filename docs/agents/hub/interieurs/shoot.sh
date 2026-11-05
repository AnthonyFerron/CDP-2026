#!/usr/bin/env bash
# Captures : shoot.sh <dossier> <livres> <fichier de vues>
cd /home/ubuntu/cdp-dev/.claude/worktrees/hub/frontend || exit 1
GODOT=/home/ubuntu/cdp-work/bin/godot
mkdir -p "$1"
timeout 4000 xvfb-run -a -s "-screen 0 1920x1080x24" "$GODOT" --audio-driver Dummy --path . --resolution 1280x720 \
	--script /home/ubuntu/cdp-work/hub/tools/shots.gd -- "$1" "$2" "$3" --api=http://127.0.0.1:9/api/v1 > "$1/shots.log" 2>&1
echo "exit=$? $(grep -c 'SCRIPT ERROR' "$1/shots.log") erreurs $(grep CAPTURES "$1/shots.log")"
