#!/usr/bin/env bash
# Outil avec fenêtre : run.sh <script> <journal> [arguments...]
WT=${WT:-/home/ubuntu/cdp-dev/.claude/worktrees/verif-hub}
cd "$WT/frontend" || exit 1
script=$1; log=$2; shift 2
timeout 5400 xvfb-run -a -s "-screen 0 1920x1080x24" /home/ubuntu/cdp-work/bin/godot --audio-driver Dummy --path . --resolution 640x360 \
	--script "$script" -- "$@" --api=http://127.0.0.1:9/api/v1 > "$log" 2>&1
echo "exit=$? $(grep -c 'SCRIPT ERROR' "$log") erreurs"
