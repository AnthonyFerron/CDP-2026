#!/usr/bin/env bash
set -u
cd /home/ubuntu/cdp-dev/.claude/worktrees/desert/frontend
GODOT=/home/ubuntu/cdp-work/bin/godot
WORK=/home/ubuntu/cdp-work/desert
API=--api=http://127.0.0.1:9/api/v1
X=(xvfb-run -a -s "-screen 0 1920x1080x24")
TAG="${1:-3}"
mapfile -t V1 < $WORK/views2.txt
mapfile -t V2 < $WORK/views_marches.txt
mapfile -t V3 < $WORK/views_epaves.txt
timeout 1500 "${X[@]}" "$GODOT" --audio-driver Dummy --path . --resolution 1280x720 --script $WORK/tools/shots.gd -- res://scenes/levels/desert/desert.tscn $WORK/apres$TAG "${V1[@]}" "${V2[@]}" "${V3[@]}" $API > $WORK/logs/shots_apres$TAG.log 2>&1
echo "captures exit=$?"
timeout 3000 "${X[@]}" "$GODOT" --audio-driver Dummy --path . --resolution 1280x720 --fixed-fps 60 --script $WORK/tools/desert_grid_test.gd -- sans_regroupement $API > $WORK/logs/grid$TAG.log 2>&1
echo "grille exit=$?"
timeout 1800 "$GODOT" --audio-driver Dummy --headless --path . --fixed-fps 60 --script $WORK/tools/desert_walk_test.gd -- $API > $WORK/logs/walk$TAG.log 2>&1
echo "marche exit=$?"
timeout 900 "$GODOT" --audio-driver Dummy --headless --path . --fixed-fps 60 --script res://tests/scenes/desert_puzzle_test.gd -- $API > $WORK/logs/puzzle$TAG.log 2>&1
echo "enigme exit=$?"
timeout 900 "$GODOT" --audio-driver Dummy --headless --path . --fixed-fps 60 --script res://tests/scenes/signboard_test.gd -- $API > $WORK/logs/signboard$TAG.log 2>&1
echo "panneaux exit=$?"
