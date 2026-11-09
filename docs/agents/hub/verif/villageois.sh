#!/usr/bin/env bash
# Tournées des villageois : villageois.sh <journal> <tournées> <feu|pause>
WT=${WT:-/home/ubuntu/cdp-dev/.claude/worktrees/verif-hub}
cd "$WT/frontend" || exit 1
log=$1; shift
timeout 7200 /home/ubuntu/cdp-work/bin/godot --audio-driver Dummy --headless --path . --fixed-fps 60 \
	--script /home/ubuntu/cdp-dev/.claude/captures/verif-hub/outils/villageois.gd -- "$@" --api=http://127.0.0.1:9/api/v1 > "$log" 2>&1
echo "exit=$? $(grep -c 'SCRIPT ERROR' "$log") erreurs"; grep -E "^(BILAN|APRES|FAITES|PAUSES)" "$log"
