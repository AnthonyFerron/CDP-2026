#!/usr/bin/env bash
# Lance le paquet exporté en natif et vérifie F3/F4 : en 1280 x 720 (auto = 100 %), puis en 3840 x 2160 (auto = 50 %).
set -u
D="$HOME/cdp-dev/.claude/captures/perf-ombres"
cd "$D" || exit 1
xvfb-run -a -s "-screen 0 1920x1080x24" ~/cdp-work/bin/godot --audio-driver Dummy --resolution 1280x720 \
	--main-pack "$D/pck/index.pck" --script "$D/outils/verif_rq.gd" -- "$D/pck/rq_720" --api=http://127.0.0.1:9/api/v1 > "$D/pck/rq_720.log" 2>&1
xvfb-run -a -s "-screen 0 3840x2160x24" ~/cdp-work/bin/godot --audio-driver Dummy --resolution 3840x2160 \
	--main-pack "$D/pck/index.pck" --script "$D/outils/verif_rq.gd" -- "$D/pck/rq_4k" --api=http://127.0.0.1:9/api/v1 > "$D/pck/rq_4k.log" 2>&1
grep -hE "^(OK|ECHEC|RESULTAT|fenêtre|compteur)|SCRIPT ERROR" "$D/pck/rq_720.log" "$D/pck/rq_4k.log"
