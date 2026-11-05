#!/usr/bin/env bash
# Captures rapprochées des six textes du récit : shots.sh <dossier>
cd /home/ubuntu/cdp-dev/.claude/worktrees/plaine/frontend || exit 1
OUT="$1"
mkdir -p "$OUT"
timeout 900 xvfb-run -a -s "-screen 0 1920x1080x24" /home/ubuntu/cdp-work/bin/godot --audio-driver Dummy --path . --resolution 1280x720 \
  --script res://tests/scenes/cam_shots.gd -- res://scenes/levels/plaine/plaine.tscn "$OUT" \
  "fete_close=2.2,1.6,49.7:3.3,1.4,47.8" "fete_side=5.07,0.6,49.74:3.3,0.4,47.8" "fete_far=0,1.65,53:2.4,1.1,44.5" \
  "arpenteur_close=-2.89,1.6,36.69:-4.3,1.3,35" "arpenteur_side=-1.87,0.6,34.0:-4.3,0.4,35" "arpenteur_far=0,1.65,43:-2.4,1.0,33" \
  "procl_close=-8.9,1.65,10.3:-8.9,1.55,8.27" "procl_side=-7.3,1.1,9.4:-8.9,1.3,8.3" "procl_far=-3,1.65,16:-8.9,1.4,8.3" \
  inside \
  "lettre_close=2.3,-38.25,-6.5:2.15,-39.0,-7.12" "lettre_far=3.3,-38.35,-8.9:1.9,-39,-6.6" \
  "greffier_close=2.95,-38.6,-15.35:2.48,-39.31,-15.95" "greffier_far=3.0,-38.35,-13.9:2.2,-39.3,-15.8" \
  "reglement_close=-0.95,-38.3,-9.9:-0.95,-38.35,-11.75" "reglement_side=0.35,-38.6,-10.95:-0.95,-38.4,-11.75" \
  "reglement_far=-3,-38.35,-5.5:-1.2,-38.5,-11.75" \
  --api=http://127.0.0.1:9/api/v1 > "$OUT/shots.log" 2>&1
echo "captures exit=$?"
