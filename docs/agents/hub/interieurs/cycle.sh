#!/usr/bin/env bash
# Un tour de vérification : régénère les scènes, importe, tests du hub, entrées et sorties des bâtiments, grilles de
# marche des intérieurs (0 et 4 livres), plans, puis captures (4 et 0 livres). cycle.sh <nom du tour> [quick|full]
set -u
NAME=$1; SET=${2:-quick}
W=/home/ubuntu/cdp-work/hub
F=/home/ubuntu/cdp-dev/.claude/worktrees/hub/frontend
G=/home/ubuntu/cdp-work/bin/godot
API=--api=http://127.0.0.1:9/api/v1
cd "$F" || exit 1
export PYTHONIOENCODING=utf-8
mkdir -p "$W/logs/$NAME"
python3 tools/build_hub.py > /dev/null && python3 tools/write_hub_tscn.py . > /dev/null
timeout 3000 "$G" --audio-driver Dummy --headless --path . --import > "$W/logs/$NAME/import.log" 2>&1
echo "import exit=$?"
"$W/tools/hubtests.sh" "$W/logs/$NAME"
for books in 0 4; do
	timeout 3000 "$G" --audio-driver Dummy --headless --path . --fixed-fps 60 --script "$W/tools/rooms_walk.gd" -- $books "$W/rooms.txt" "$API" > "$W/logs/$NAME/rooms_$books.log" 2>&1
	echo "rooms_$books $(grep -E '^RESULTAT' "$W/logs/$NAME/rooms_$books.log") $(grep -c '^ECHEC' "$W/logs/$NAME/rooms_$books.log") ECHEC $(grep -c 'SCRIPT ERROR' "$W/logs/$NAME/rooms_$books.log") erreurs"
done
python3 "$W/tools/gen_zones.py" "$W/zones.txt" > /dev/null
for books in 0 4; do
	"$W/tools/grid.sh" $books "$W/zones.txt" "$W/logs/$NAME/grid_$books.log"
done
for books in 4 0; do
	python3 "$W/tools/plan.py" "$W/plans" $books > "$W/logs/$NAME/plan_$books.txt"
	python3 "$W/tools/gen_views.py" "$W/views_${NAME}_$books.txt" --set=$SET --books=$books > /dev/null
	"$W/tools/shoot.sh" "$W/shots/${NAME}_$books" $books "$W/views_${NAME}_$books.txt"
done
echo "tour $NAME fini"
