#!/bin/bash
# Lance un test headless : run_test.sh <script.gd> <log> [arguments...]
G="/c/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/godot/Godot_v4.7.2-stable_win64_console.exe"
cd /d/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-ac136eda77679f346/frontend || exit 1
SCRIPT="$1"
LOG="$2"
shift 2
HEAD="--headless"
if [ "$1" = "window" ]; then
	HEAD="--resolution 1280x720"
	shift
fi
timeout 900 "$G" $HEAD --path . --fixed-fps 60 --script "$SCRIPT" -- "$@" --api=http://127.0.0.1:9/api/v1 > "$LOG" 2>&1
grep -a -E "^(ECHEC|RESULTAT)|SCRIPT ERROR|Parse Error" "$LOG" | head -60
