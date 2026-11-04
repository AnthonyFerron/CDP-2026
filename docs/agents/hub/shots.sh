#!/bin/bash
# Captures du hub : shots.sh <sous-dossier de agents/hub> <entrées de shots.gd...>
S=/c/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad
G=$S/godot/Godot_v4.7.2-stable_win64_console.exe
W=/d/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-ae7f5448114299e0a/frontend
dir=$1; shift
cd "$W" || exit 1
timeout 240 "$G" --path . --resolution 1280x720 --script "$S/agents/hub/shots.gd" -- "agents/hub/$dir" "$@" --api=http://127.0.0.1:9/api/v1 > "$S/agents/hub/shots.log" 2>&1
echo "rc=$?"
grep -E "SCRIPT ERROR|Parse Error" "$S/agents/hub/shots.log" | head -20
ls "$S/agents/hub/$dir" | head -80
