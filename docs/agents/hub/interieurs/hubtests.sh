#!/usr/bin/env bash
# Tests du hub : hub_test, hub_walk_test 0 et 4, à la suite (un seul Godot à la fois).
cd /home/ubuntu/cdp-dev/.claude/worktrees/hub/frontend || exit 1
GODOT=/home/ubuntu/cdp-work/bin/godot
LOGS=${1:-/home/ubuntu/cdp-work/hub/logs}
mkdir -p "$LOGS"
API="--api=http://127.0.0.1:9/api/v1"
run() {
	local name="$1"; shift
	timeout 3000 "$GODOT" --audio-driver Dummy --headless --path . --fixed-fps 60 --script "res://tests/scenes/$1.gd" "${@:2}" > "$LOGS/$name.log" 2>&1
	local code=$?
	echo "$name exit=$code $(grep -E '^RESULTAT' "$LOGS/$name.log" | tail -1) $(grep -cE '^(ECHEC|ÉCHEC)' "$LOGS/$name.log") ECHEC $(grep -c 'SCRIPT ERROR' "$LOGS/$name.log") erreurs"
}
run hub_test hub_test -- "$API"
run hub_walk_0 hub_walk_test -- 0 "$API"
run hub_walk_4 hub_walk_test -- 4 "$API"
