#!/bin/bash
# profile.sh <dossier frontend> <journal>
cd "$1" || exit 1
timeout 3600 xvfb-run -a -s "-screen 0 1920x1080x24" /home/ubuntu/cdp-work/bin/godot --audio-driver Dummy --resolution 1280x720 --path . --script /home/ubuntu/cdp-work/marais/tools/profile_load.gd -- --api=http://127.0.0.1:9/api/v1 > "$2" 2>&1
echo "exit=$?"
grep -a -E "^TEMPS|SCRIPT ERROR|Parse Error" "$2"
