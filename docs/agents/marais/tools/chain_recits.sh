#!/bin/bash
# Vérification des textes du récit : test des textes (captures), énigme, panneaux.
W=/home/ubuntu/cdp-dev/.claude/worktrees/marais/frontend
L=/home/ubuntu/cdp-work/marais/logs
G=/home/ubuntu/cdp-work/bin/godot
OUT="${1:?dossier de sortie}"
cd $W || exit 1
timeout 3600 xvfb-run -a -s "-screen 0 1920x1080x24" $G --audio-driver Dummy --path . --resolution 1280x720 --fixed-fps 60 --script /home/ubuntu/cdp-dev/.claude/worktrees/marais/docs/agents/marais/tools/lore_test.gd -- "$OUT" --api=http://127.0.0.1:9/api/v1 > $L/lore.log 2>&1
echo "lore_test exit=$? $(grep -a -E '^RESULTAT' $L/lore.log) $(grep -ac '^ECHEC' $L/lore.log) ECHEC $(grep -ac 'SCRIPT ERROR' $L/lore.log) erreurs"
grep -a "^ECHEC\|place perdue" $L/lore.log | head
for t in marais_puzzle_test signboard_test; do
	timeout 3600 $G --audio-driver Dummy --headless --path . --fixed-fps 60 --script res://tests/scenes/$t.gd -- --api=http://127.0.0.1:9/api/v1 > $L/$t.log 2>&1
	echo "$t exit=$? $(grep -E '^RESULTAT' $L/$t.log | tail -1) $(grep -c 'SCRIPT ERROR' $L/$t.log) erreur(s)"
done
echo CHAINE_FINIE
