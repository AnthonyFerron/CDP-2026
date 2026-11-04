#!/bin/bash
S=/c/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad
G=$S/godot/Godot_v4.7.2-stable_win64_console.exe
W=/d/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-ae7f5448114299e0a/frontend
cd "$W" || exit 1
timeout 240 "$G" --path . --resolution 1280x720 --script "$S/agents/hub/gallery.gd" -- "$@" --api=http://127.0.0.1:9/api/v1 > "$S/agents/hub/gallery.log" 2>&1
echo "rc=$?"
