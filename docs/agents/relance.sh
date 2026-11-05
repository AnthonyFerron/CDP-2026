#!/usr/bin/env bash
# Relance de la nuit : envoie un message à la session Claude Code ouverte dans tmux, ou relance Claude si elle a disparu.
# Version testée sur le serveur le 4 novembre 2026. En garder une copie hors du dépôt (~/cdp-work/relance.sh), pour ne pas
# dépendre de la branche extraite dans ~/cdp-dev.
#
# Installation (crontab -e), à 1 h 10 à l'heure du serveur (UTC, donc 2 h 10 à Paris en hiver) :
#   10 1 * * * CLAUDE_FLAGS="--permission-mode auto" bash $HOME/cdp-work/relance.sh >> $HOME/cdp-work/relance.log 2>&1
#
# Variables : CDP_TMUX (session tmux, « cdp » par défaut), CDP_REPO (dépôt, ~/cdp-dev par défaut),
# CLAUDE_FLAGS (options de claude s'il faut le relancer), CLAUDE_BIN (claude par défaut), GODOT.
set -u
SESSION="${CDP_TMUX:-cdp}"
REPO="${CDP_REPO:-$HOME/cdp-dev}"
FLAGS="${CLAUDE_FLAGS:-}"
CLAUDE="${CLAUDE_BIN:-claude}"
GODOT="${GODOT:-$HOME/godot/Godot_v4.7.2-stable_linux.arm64}"
MESSAGE="Relance de 1 h 10 : relance tous les agents arrêtés (limite d'usage atteinte ou tâche finie) et reprends l'orchestration selon docs/agents/PROMPT_SERVEUR.md, là où tu t'étais arrêté."
START="Lis ~/cdp-work/JOURNAL.md pour savoir où en est la nuit, puis docs/agents/PROMPT_SERVEUR.md, et suis ses consignes : relance les agents et reprends le travail là où il s'est arrêté."
# cron a un PATH minimal : claude est installé dans ~/.local/bin.
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
export GODOT

# Commande qui lance Claude dans le dépôt, avec GODOT et PATH explicites (un shell tmux ne lit pas forcément ~/.bashrc).
launch="cd $(printf '%q' "$REPO") && env GODOT=$(printf '%q' "$GODOT") PATH=$(printf '%q' "$PATH") $CLAUDE $FLAGS $(printf '%q' "$START")"

# Claude tourne-t-il dans le panneau ? On cherche, parmi les descendants du processus du panneau, un programme
# nommé comme $CLAUDE (argv[0], ou argv[1] pour un script). #{pane_current_command} ne suffit pas : sous un
# « bash -c » sans contrôle des tâches, il affiche bash même quand Claude tourne.
claude_in_pane() {
	local root
	root="$(tmux display-message -p -t "$SESSION:0" '#{pane_pid}')" || return 1
	ps -eo pid=,ppid=,args= | awk -v root="$root" -v name="$(basename "$CLAUDE")" '
		{ parent[$1] = $2; a0 = $3; a1 = $4; sub(/.*\//, "", a0); sub(/.*\//, "", a1); hit[$1] = (a0 == name || a1 == name) }
		END {
			for (p in parent) if (hit[p]) for (q = p; q != "" && q > 1; q = parent[q]) if (q == root) found = 1
			exit !found
		}'
}

echo "$(date '+%F %T %Z') relance de la session $SESSION"
if tmux has-session -t "$SESSION" 2>/dev/null; then
	if claude_in_pane; then
		# Claude tourne : le texte est tapé tel quel (-l), puis validé.
		tmux send-keys -t "$SESSION:0" -l "$MESSAGE"
		sleep 1
		tmux send-keys -t "$SESSION:0" Enter
		echo "message envoyé à la session existante"
	else
		# La session existe, mais Claude n'y tourne plus : on le relance dans le même panneau (un shell l'attend).
		tmux send-keys -t "$SESSION:0" -l "$launch"
		sleep 1
		tmux send-keys -t "$SESSION:0" Enter
		echo "claude ne tournait plus : relancé dans la session existante"
	fi
else
	# Session disparue : nouvelle session tmux, avec claude lancé sur le prompt du serveur.
	tmux new-session -d -s "$SESSION" -c "$REPO" "$launch; exec bash"
	echo "session recréée"
fi
