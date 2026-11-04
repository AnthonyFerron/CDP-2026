# Captures : shots.sh <dossier de sortie sous agents/desert> "nom=x,y,z:cx,cy,cz" ...
. "$(dirname "$0")/env.sh"
OUT="$1"; shift
cd "$F" && "$G" --path . --resolution 1280x720 --script "$S/cam_shots.gd" -- res://scenes/levels/desert/desert.tscn "agents/desert/$OUT" "$@" > "$D/shots.log" 2>&1
echo "exit $?"
grep -E "ERROR|error" "$D/shots.log" | head -20
ls "$D/$OUT"
