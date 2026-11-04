#!/bin/bash
# Boîtes des maillages de plusieurs modèles : parts_many.sh kit/modele ...
G="/c/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/godot/Godot_v4.7.2-stable_win64_console.exe"
P="C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/marais/tools/parts.gd"
cd /d/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-ac136eda77679f346/frontend || exit 1
for m in "$@"; do
	echo "$m"
	timeout 60 "$G" --headless --path . --script "$P" -- "$m" --api=http://127.0.0.1:9/api/v1 2>&1 | grep -a " pos "
done
