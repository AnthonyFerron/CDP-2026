#!/bin/bash
# Vérification finale : tests du lieu, mesures et captures après puis avant, planches, relevé des collisions, grille.
T=/home/ubuntu/cdp-work/marais/tools
W=/home/ubuntu/cdp-dev/.claude/worktrees/marais/frontend
A=/home/ubuntu/cdp-work/marais/avant/frontend
L=/home/ubuntu/cdp-work/marais/logs
G=/home/ubuntu/cdp-work/bin/godot
cd $W
for t in marais_puzzle_test signboard_test; do
	timeout 3600 $G --audio-driver Dummy --headless --path . --fixed-fps 60 --script res://tests/scenes/$t.gd -- --api=http://127.0.0.1:9/api/v1 > $L/$t.log 2>&1
	echo "$t exit=$? $(grep -E '^RESULTAT' $L/$t.log | tail -1) $(grep -c 'SCRIPT ERROR' $L/$t.log) erreur(s)"
done
$T/perf.sh $W apres /home/ubuntu/cdp-work/marais/perf/apres3 --shots=$T/life.txt --shots=$T/views.txt --shots=$T/decor.txt | grep -v répartition | cut -c1-200
$T/perf.sh $A avant /home/ubuntu/cdp-work/marais/perf/avant3 --shots=$T/life.txt --shots=$T/views.txt --shots=$T/decor.txt | grep -v répartition | cut -c1-200
for set in views decor life; do
	timeout 3600 $G --audio-driver Dummy --headless --path . --script $T/diff_images.gd -- /home/ubuntu/cdp-work/marais/perf/avant3/$set /home/ubuntu/cdp-work/marais/perf/apres3/$set /home/ubuntu/cdp-work/marais/diff/final_$set > /home/ubuntu/cdp-work/marais/diff/final_$set.log 2>&1
	grep DIFF /home/ubuntu/cdp-work/marais/diff/final_$set.log
done
$T/report.sh $A /home/ubuntu/cdp-work/marais/report/collisions_avant.txt /home/ubuntu/cdp-work/marais/report/avant.log
$T/report.sh $W /home/ubuntu/cdp-work/marais/report/collisions_final.txt /home/ubuntu/cdp-work/marais/report/final.log
diff -q /home/ubuntu/cdp-work/marais/report/collisions_avant.txt /home/ubuntu/cdp-work/marais/report/collisions_final.txt && echo "COLLISIONS IDENTIQUES"
timeout 3600 $G --audio-driver Dummy --headless --path . --fixed-fps 60 --script $T/walkgrid.gd -- tout final --api=http://127.0.0.1:9/api/v1 > $L/walkgrid_final.log 2>&1
echo "walkgrid exit=$?"; grep -E "^PROBLEME|^RESULTAT|SCRIPT ERROR|points" $L/walkgrid_final.log | head -30
echo CHAINE_FINIE
