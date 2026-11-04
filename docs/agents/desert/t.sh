# Lance un test Godot headless dans la worktree : t.sh <script.gd> [nom du log] [args...]
. "$(dirname "$0")/env.sh"
SCRIPT="$1"; shift
LOG="${1:-test}"; shift
cd "$F" && "$G" --headless --path . --fixed-fps 60 --script "$SCRIPT" "$@" > "$D/$LOG.log" 2>&1
echo "exit $?"
grep -E "ECHEC|RESULTAT|SCRIPT ERROR|Parse Error|ERROR" "$D/$LOG.log" | head -60
