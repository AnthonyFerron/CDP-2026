#!/bin/sh
# Lance Godot dans la worktree de la Plaine : godot.sh <arguments de Godot...>
cd /d/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-ac34b1fd3f91b5f89/frontend || exit 1
exec /c/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/godot/Godot_v4.7.2-stable_win64_console.exe --path . "$@"
