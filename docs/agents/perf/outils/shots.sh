#!/usr/bin/env bash
# Captures seules des 5 lieux : shots.sh <worktree frontend> <étiquette> [réglages exp_shots, par exemple atlas=2048]
set -u
FRONT="$1"; TAG="$2"; shift 2
OUT="$HOME/cdp-dev/.claude/captures/perf-ombres/$TAG"
TOOLS="$HOME/cdp-dev/.claude/captures/perf-ombres/outils"
mkdir -p "$OUT/logs"
cd "$FRONT" || exit 1
for lieu in hub desert marais village plaine; do
	# shellcheck disable=SC2046
	xvfb-run -a -s "-screen 0 1920x1080x24" ~/cdp-work/bin/godot --audio-driver Dummy --path . --resolution 1280x720 \
		--script "$TOOLS/exp_shots.gd" -- "res://scenes/levels/$lieu/$lieu.tscn" "$OUT/shots/$lieu" \
		"$@" $(python3 "$TOOLS/views.py" "$lieu") --api=http://127.0.0.1:9/api/v1 > "$OUT/logs/shots_$lieu.log" 2>&1
	echo "captures $lieu : $(ls "$OUT/shots/$lieu" 2>/dev/null | wc -l)"
done
