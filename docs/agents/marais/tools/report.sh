#!/bin/bash
# report.sh <dossier frontend> <fichier des collisions> <journal>
FRONT="$1"; OUTC="$2"; LOG="$3"
cd "$FRONT" || exit 1
timeout 3600 /home/ubuntu/cdp-work/bin/godot --audio-driver Dummy --headless --path . --script /home/ubuntu/cdp-work/marais/tools/batch_report.gd -- "$OUTC" "${@:4}" --api=http://127.0.0.1:9/api/v1 > "$LOG" 2>&1
echo "exit=$?"
grep -a -E "^RACINE|^LOTS|^COLLISIONS|SCRIPT ERROR|Parse Error" "$LOG"
