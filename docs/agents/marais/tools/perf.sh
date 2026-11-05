#!/bin/bash
# perf.sh <dossier frontend> <étiquette> <dossier de sortie> [vues...]
FRONT="$1"; LABEL="$2"; OUT="$3"; shift 3
mkdir -p "$OUT"
cd "$FRONT" || exit 1
timeout 3600 xvfb-run -a -s "-screen 0 1920x1080x24" /home/ubuntu/cdp-work/bin/godot --audio-driver Dummy --path . --resolution 1280x720 --script /home/ubuntu/cdp-work/marais/tools/perf_views.gd -- "$LABEL" "$OUT" "$@" --api=http://127.0.0.1:9/api/v1 > "$OUT/perf.log" 2>&1
echo "exit=$?"
grep -a -E "^PERF|SCRIPT ERROR|Parse Error" "$OUT/perf.log"
