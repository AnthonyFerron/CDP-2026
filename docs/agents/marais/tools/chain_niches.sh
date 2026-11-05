#!/bin/bash
# Après la grille : captures des niches de l'ossuaire (dos éclairci), puis le test de l'énigme.
W=/home/ubuntu/cdp-dev/.claude/worktrees/marais/frontend
L=/home/ubuntu/cdp-work/marais/logs
G=/home/ubuntu/cdp-work/bin/godot
until grep -q "walkgrid exit" /tmp/claude-1001/-home-ubuntu-cdp-dev/a36c36a4-49c2-4108-a145-ff0c598f84a0/tasks/bhofxt34k.output 2>/dev/null; do sleep 5; done
cd $W || exit 1
timeout 900 xvfb-run -a -s "-screen 0 1920x1080x24" $G --audio-driver Dummy --path . --resolution 1280x720 --script /home/ubuntu/cdp-dev/.claude/worktrees/marais/docs/agents/marais/tools/shots_fixes.gd -- /home/ubuntu/cdp-work/marais/niches freeze "n1=in:-4,-38.35,-8:-9.6,-38.8,-8" "n2=in:4,-38.35,-16:9.6,-38.8,-16" "n3=in:-18,-38.35,1.6:-18,-38.8,5.5" "n4=in:0,-38.35,-3:0,-39.3,-12" --api=http://127.0.0.1:9/api/v1 > $L/niches.log 2>&1
echo "captures exit=$?"
timeout 900 $G --audio-driver Dummy --headless --path . --fixed-fps 60 --script res://tests/scenes/marais_puzzle_test.gd -- --api=http://127.0.0.1:9/api/v1 > $L/marais_puzzle_test.log 2>&1
echo "marais_puzzle_test exit=$? $(grep -E '^RESULTAT' $L/marais_puzzle_test.log | tail -1) $(grep -c 'SCRIPT ERROR' $L/marais_puzzle_test.log) erreur(s)"
echo CHAINE_FINIE
