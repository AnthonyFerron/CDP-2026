#!/bin/bash
# Planches avant / après de la passe au centimètre (grid1 = avant, grid5 = après).
G="/c/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/godot/Godot_v4.7.2-stable_win64_console.exe"
M="C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/marais"
cd /d/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-ac136eda77679f346/frontend || exit 1
mkdir -p "$M/avant_apres"
API="--api=http://127.0.0.1:9/api/v1"
timeout 60 "$G" --headless --path . --script "$M/tools/board.gd" -- "$M/avant_apres/1_escalier.png" \
	"$M/grid1/crypte_30_0_6.png" "$M/grid5/crypte_30_0_6.png" "$M/grid1/crypte_29_0_0.png" "$M/grid5/crypte_29_0_0.png" "$API" 2>&1 | grep -a PLANCHE
timeout 60 "$G" --headless --path . --script "$M/tools/board.gd" -- "$M/avant_apres/2_chambres.png" \
	"$M/grid1/crypte_14_-27_-12.png" "$M/grid5/crypte_14_-27_-12.png" "$M/grid1/crypte_17_21_-12.png" "$M/grid5/crypte_17_21_-12.png" "$API" 2>&1 | grep -a PLANCHE
timeout 60 "$G" --headless --path . --script "$M/tools/board.gd" -- "$M/avant_apres/3_cage_et_epees.png" \
	"$M/cm/up2/g.png" "$M/cm/up3/g.png" "$M/grid1/crypte_13_-21_-12.png" "$M/grid5/crypte_13_-21_-12.png" "$API" 2>&1 | grep -a PLANCHE
