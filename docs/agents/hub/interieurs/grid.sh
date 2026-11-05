#!/usr/bin/env bash
# Grille de marche des intérieurs : grid.sh <livres> <fichier des zones> <journal>
cd /home/ubuntu/cdp-dev/.claude/worktrees/hub/frontend || exit 1
GODOT=/home/ubuntu/cdp-work/bin/godot
timeout 4000 xvfb-run -a -s "-screen 0 1920x1080x24" "$GODOT" --audio-driver Dummy --path . --resolution 640x360 \
	--script /home/ubuntu/cdp-work/hub/tools/walk_grid.gd -- "$1" "$2" --api=http://127.0.0.1:9/api/v1 > "$3" 2>&1
echo "exit=$?"; grep -E "RESUME|SCRIPT ERROR|Parse Error" "$3"
