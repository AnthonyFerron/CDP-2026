. "$(dirname "$0")/env.sh"
cd "$F" && "$G" --headless --path . --import > "$D/import.log" 2>&1
tail -5 "$D/import.log"
