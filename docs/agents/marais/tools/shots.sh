#!/bin/bash
# Captures du Marais : shots.sh <dossier relatif au scratchpad> <vues...>
G="/c/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/godot/Godot_v4.7.2-stable_win64_console.exe"
cd /d/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-ac136eda77679f346/frontend || exit 1
OUT="$1"
shift
timeout 300 "$G" --path . --resolution 1280x720 --script "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/marais/tools/shots.gd" -- res://scenes/levels/marais/marais.tscn "$OUT" "$@" --api=http://127.0.0.1:9/api/v1 > "/c/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/marais/shots_last.log" 2>&1
grep -a -E "SCRIPT ERROR|Parse Error|ERROR: .*(marais|scatter|wisp|grounded)" "/c/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/marais/shots_last.log" | head -20
echo "captures faites"
