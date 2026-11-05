#!/usr/bin/env bash
# Essai du repli de la Plaine quand le précalcul est périmé, sans rien commiter : repli.sh <worktree> <sortie>
# 1. un réglage change (profondeur du cratère 6, 2,0 -> 2,2) sans relancer le bake : avertissements, recalcul,
#    lave, empreinte « repli » ; puis bake relancé avec ce réglage : empreinte « rebake », qui doit être la même ;
# 2. le code du relief change (bruit x 0,8 -> x 0,9) sans toucher aux réglages : détecté par les hauteurs témoins ?
# 3. le code de la zone qui brûle change (bas des bandes - 0,4 -> - 0,5) : détecté au chargement ? par --check ?
# Tout est remis comme avant à la fin (git checkout des trois fichiers).
WT="$1"; OUT="$2"
API="--api=http://127.0.0.1:9/api/v1"
GODOT=/home/ubuntu/cdp-work/bin/godot
OUTILS="$(cd "$(dirname "$0")" && pwd)"
X=(xvfb-run -a -s "-screen 0 1920x1080x24")
TERRAIN=scenes/levels/plaine/plaine_terrain.gd
SCATTER=scenes/levels/plaine/plaine_scatter.gd
BAKE=scenes/levels/plaine/plaine_bake.res
mkdir -p "$OUT"
cd "$WT/frontend" || exit 1
restore() { git checkout -- "$TERRAIN" "$SCATTER" "$BAKE"; }
trap restore EXIT
warn() { grep -E "périmé|TEMPS essai 1" "$1" | sed 's/^/    /'; }
check() { "$GODOT" --headless --audio-driver Dummy --path . --script res://tools/bake_plaine.gd -- --check "$API" > "$OUT/$1.log" 2>&1; echo "  --check exit=$? : $(grep -E 'à jour|PÉRIMÉES' "$OUT/$1.log")"; }

echo "== 1. réglage changé : cratère 6 plus profond"
sed -i 's/Vector4(-50.0, 28.0, 7.0, 2.0)/Vector4(-50.0, 28.0, 7.0, 2.2)/' "$TERRAIN"
git diff --stat -- "$TERRAIN"
check check_reglage
"$GODOT" --headless --audio-driver Dummy --path . --script "$OUTILS/profile_load.gd" -- 1 "$API" > "$OUT/profile_reglage.log" 2>&1
echo "  chargement sans bake relancé :"; warn "$OUT/profile_reglage.log"
"$GODOT" --headless --audio-driver Dummy --path . --fixed-fps 60 --script "$OUTILS/lave_test.gd" -- "$API" > "$OUT/lave_reglage.log" 2>&1
echo "  lave : $(grep -E '^RESULTAT' "$OUT/lave_reglage.log") ($(grep -m1 'bandes' "$OUT/lave_reglage.log"))"
"${X[@]}" "$GODOT" --audio-driver Dummy --path . --resolution 1280x720 --fixed-fps 60 --script "$OUTILS/fingerprint.gd" -- "$OUT/empreinte_repli" "$API" > "$OUT/fp_repli.log" 2>&1
grep EMPREINTE "$OUT/fp_repli.log" | sed 's/^/  repli  : /'
"$GODOT" --headless --audio-driver Dummy --path . --script res://tools/bake_plaine.gd -- "$API" > "$OUT/bake_reglage.log" 2>&1
echo "  bake relancé : $(grep -E 'écrit|impossible' "$OUT/bake_reglage.log")"
check check_reglage_apres
"$GODOT" --headless --audio-driver Dummy --path . --script "$OUTILS/profile_load.gd" -- 1 "$API" > "$OUT/profile_rebake.log" 2>&1
echo "  chargement avec le bake relancé :"; warn "$OUT/profile_rebake.log"
"${X[@]}" "$GODOT" --audio-driver Dummy --path . --resolution 1280x720 --fixed-fps 60 --script "$OUTILS/fingerprint.gd" -- "$OUT/empreinte_rebake" "$API" > "$OUT/fp_rebake.log" 2>&1
grep EMPREINTE "$OUT/fp_rebake.log" | sed 's/^/  rebake : /'
cmp "$OUT/empreinte_repli/collisions.txt" "$OUT/empreinte_rebake/collisions.txt" && cmp "$OUT/empreinte_repli/dessin.txt" "$OUT/empreinte_rebake/dessin.txt" && echo "  repli = rebake : fichiers d'empreinte identiques"
restore

echo "== 2. code du relief changé (bruit x 0,9)"
sed -i 's/_relief.get_noise_2d(x, z) \* 0.8/_relief.get_noise_2d(x, z) * 0.9/' "$TERRAIN"
git diff --stat -- "$TERRAIN"
"$GODOT" --headless --audio-driver Dummy --path . --script "$OUTILS/profile_load.gd" -- 1 "$API" > "$OUT/profile_relief.log" 2>&1
echo "  chargement :"; warn "$OUT/profile_relief.log"
check check_relief
restore

echo "== 3. code de la zone qui brûle changé (bas des bandes - 0,5)"
sed -i 's/_hazard_strip(start, x, z, bottom - 0.4, top + 0.3)/_hazard_strip(start, x, z, bottom - 0.5, top + 0.3)/g' "$SCATTER"
git diff --stat -- "$SCATTER"
"$GODOT" --headless --audio-driver Dummy --path . --script "$OUTILS/profile_load.gd" -- 1 "$API" > "$OUT/profile_zone.log" 2>&1
echo "  chargement :"; warn "$OUT/profile_zone.log"
check check_zone
restore

echo "== remis comme avant"
git status --short -- "$TERRAIN" "$SCATTER" "$BAKE"
check check_final
