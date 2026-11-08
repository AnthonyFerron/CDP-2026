#!/usr/bin/env bash
# Tests de scène du jeu (niveaux, menus, debug, chronomètre), sans réseau :
#
#   GODOT=/chemin/vers/godot bash frontend/tests/scenes/run_all.sh [dossier des journaux]
#
# Chaque test vise une API locale morte (--api=http://127.0.0.1:9/api/v1) : aucun ne joint la production.
# Les tests qui lisent l'image (captures, MultiMesh) ont besoin d'un écran ; sans DISPLAY, ils passent par
# xvfb-run (paquets xvfb et libgl1-mesa-dri). Résultat attendu : 0 échec partout, sauf hub_walk_0 et hub_walk_4
# qui comptent chacun 2 échecs voulus (« limite infranchissable (doit echouer) »).
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
FRONTEND="$(cd "$HERE/../.." && pwd)"
GODOT="${GODOT:-godot}"
LOGS="${1:-${TMPDIR:-/tmp}/cdp-tests}"
API="--api=http://127.0.0.1:9/api/v1"
mkdir -p "$LOGS"
cd "$FRONTEND" || exit 1

WINDOW=()
if [ -z "${DISPLAY:-}" ] && command -v xvfb-run >/dev/null 2>&1; then
	WINDOW=(xvfb-run -a -s "-screen 0 1920x1080x24")
fi
AUDIO=()
case "$(uname -s)" in
	Linux*) AUDIO=(--audio-driver Dummy) ;;
esac

"$GODOT" --headless --path . --import >/dev/null 2>&1

# Le sol et la zone de lave de la Plaine sont calculés d'avance (tools/bake_plaine.gd, plaine_bake.res) : le fichier
# doit correspondre au calcul. Sinon : godot --headless --path frontend --script res://tools/bake_plaine.gd
timeout 900 "$GODOT" "${AUDIO[@]}" --headless --path . --script res://tools/bake_plaine.gd -- --check "$API" > "$LOGS/bake_plaine_check.log" 2>&1
echo "bake_plaine_check exit=$? $(tail -n 3 "$LOGS/bake_plaine_check.log" | grep -v '^\s*$' | tail -1)"

# Sol et décor dispersé des autres lieux, calculés d'avance (tools/bake_lieux.gd, scenes/levels/<lieu>/<lieu>_bake.res) :
# chaque fichier doit correspondre au calcul. Sinon : godot --headless --path frontend --script res://tools/bake_lieux.gd
timeout 900 "$GODOT" "${AUDIO[@]}" --headless --path . --script res://tools/bake_lieux.gd -- --check "$API" > "$LOGS/bake_lieux_check.log" 2>&1
echo "bake_lieux_check exit=$? $(grep '^Lieux : ' "$LOGS/bake_lieux_check.log" | tail -1)"

# Inventaire des matériaux préparés au menu (tools/bake_shaders.gd, assets/shader_warm_list.tres) : il doit
# correspondre aux lieux. Sinon : godot --headless --fixed-fps 60 --path frontend --script res://tools/bake_shaders.gd
timeout 900 "$GODOT" "${AUDIO[@]}" --headless --fixed-fps 60 --path . --script res://tools/bake_shaders.gd -- --check "$API" > "$LOGS/bake_shaders_check.log" 2>&1
echo "bake_shaders_check exit=$? $(grep '^Shaders : ' "$LOGS/bake_shaders_check.log" | tail -1)"

# run <nom> <headless|window> <script> [arguments du test...]
run() {
	local name="$1" mode="$2" script="$3"; shift 3
	local log="$LOGS/$name.log"
	local args=("$@"); [ ${#args[@]} -eq 0 ] && args=(--); args+=("$API")
	if [ "$mode" = window ]; then
		timeout 900 "${WINDOW[@]}" "$GODOT" "${AUDIO[@]}" --path . --script "res://tests/scenes/$script.gd" "${args[@]}" > "$log" 2>&1
	else
		timeout 900 "$GODOT" "${AUDIO[@]}" --headless --path . --script "res://tests/scenes/$script.gd" "${args[@]}" > "$log" 2>&1
	fi
	local code=$?
	echo "$name exit=$code $(grep -E '^RESULTAT' "$log" | tail -1) $(grep -cE '^(ECHEC|ÉCHEC)' "$log") ligne(s) ECHEC $(grep -c 'SCRIPT ERROR' "$log") erreur(s) de script"
}

run hub_test headless hub_test
run hub_walk_0 headless hub_walk_test -- 0
run hub_walk_4 headless hub_walk_test -- 4
run plaine_puzzle_test headless plaine_puzzle_test
run desert_puzzle_test headless desert_puzzle_test
run marais_puzzle_test headless marais_puzzle_test
run village_test headless village_test
run timer_test headless timer_test
run menu_test headless menu_test
run signboard_test headless signboard_test
run login_test window login_test
run debug_test headless debug_test
run music_test headless music_test
run fullscreen_test headless fullscreen_test
run quality_test headless quality_test -- --qualite-auto
run tree_collision_test window tree_collision_test

# Tests statiques et unitaires de l'intégration API (PR #12), sans réseau.
timeout 900 "$GODOT" "${AUDIO[@]}" --headless --path . res://tests/run_tests.tscn > "$LOGS/run_tests.log" 2>&1
echo "run_tests exit=$? $(grep 'RÉSULTAT' "$LOGS/run_tests.log")"
echo "FINI (journaux dans $LOGS)"
