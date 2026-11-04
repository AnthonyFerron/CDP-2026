#!/bin/bash
# Grille de marche du Marais : dehors, crypte, maillages sans collision (headless), puis trous de la crypte.
T="/c/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/marais"
for mode in dehors crypte maillages; do
	echo "== $mode"
	bash "$T/tools/run_test.sh" "$T/marais_walkgrid_test.gd" "$T/walkgrid_run_$mode.log" "$mode"
	cat "$T/walkgrid_$mode.txt"
done
echo "== trous"
bash "$T/tools/run_test.sh" "$T/marais_holes_test.gd" "$T/holes.log"
