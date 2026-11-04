#!/bin/bash
# Lance un test Godot du hub dans la worktree de l'agent hub.
# Usage : run.sh <script.gd (chemin absolu ou nom dans le scratchpad)> <log> [args...]
S=/c/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad
G=$S/godot/Godot_v4.7.2-stable_win64_console.exe
W=/d/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-ae7f5448114299e0a/frontend
script=$1; shift
log=$1; shift
case "$script" in
  /*|C:*) ;;
  *) script=$S/$script ;;
esac
cd "$W" || exit 1
if [ "$HEADFUL" = "1" ]; then
  timeout 240 "$G" --path . --resolution 1280x720 --script "$script" -- "$@" --api=http://127.0.0.1:9/api/v1 > "$S/agents/hub/$log" 2>&1
else
  timeout 240 "$G" --headless --path . --fixed-fps 60 --script "$script" -- "$@" --api=http://127.0.0.1:9/api/v1 > "$S/agents/hub/$log" 2>&1
fi
echo "rc=$?"
grep -E "ECHEC|RESULTAT|SCRIPT ERROR|Parse Error" "$S/agents/hub/$log" | head -60
