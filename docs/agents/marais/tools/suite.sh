#!/bin/bash
# Suite de tests du Marais (headless) : énigme commune, limites, audit, escalier.
G="/c/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/godot/Godot_v4.7.2-stable_win64_console.exe"
S="/c/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad"
cd /d/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-ac136eda77679f346/frontend || exit 1
for test in "$S/marais_puzzle_test.gd" "$S/agents/marais/marais_limit_test.gd" "$S/agents/marais/marais_audit_test.gd" "$S/agents/marais/marais_stairs_test.gd"; do
	log="$S/agents/marais/suite_$(basename "$test" .gd).log"
	timeout 300 "$G" --headless --path . --fixed-fps 60 --script "$test" -- --api=http://127.0.0.1:9/api/v1 > "$log" 2>&1
	echo "$(basename "$test") : $(grep -a -E '^RESULTAT|SCRIPT ERROR' "$log" | head -1)"
	grep -a '^ECHEC' "$log" | head -5
done
