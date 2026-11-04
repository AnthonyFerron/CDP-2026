#!/usr/bin/env bash
# Relance de la nuit : envoie un message à la session Claude Code ouverte dans tmux, ou la recrée si elle a disparu.
#
# Installation (crontab -e), à 1 h 10 à l'heure du serveur :
#   10 1 * * * CLAUDE_FLAGS="--permission-mode auto" bash $HOME/cdp-dev/docs/agents/relance.sh >> $HOME/cdp-work/relance.log 2>&1
#
# Variables : CDP_TMUX (session tmux, « cdp » par défaut), CDP_REPO (dépôt, ~/cdp-dev par défaut),
# CLAUDE_FLAGS (options de claude si la session doit être recréée).
set -u
SESSION="${CDP_TMUX:-cdp}"
REPO="${CDP_REPO:-$HOME/cdp-dev}"
FLAGS="${CLAUDE_FLAGS:-}"
MESSAGE="Relance de 1 h 10 : relance tous les agents arrêtés (limite d'usage atteinte ou tâche finie) et reprends l'orchestration selon docs/agents/PROMPT_SERVEUR.md, là où tu t'étais arrêté."
# cron a un PATH minimal : claude est installé dans ~/.local/bin.
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

echo "$(date '+%F %T') relance de la session $SESSION"
if tmux has-session -t "$SESSION" 2>/dev/null; then
	# Le texte est tapé tel quel (-l), puis validé.
	tmux send-keys -t "$SESSION:0" -l "$MESSAGE"
	sleep 1
	tmux send-keys -t "$SESSION:0" Enter
	echo "message envoyé à la session existante"
else
	# Session disparue : nouvelle session tmux, avec claude lancé sur le prompt du serveur.
	tmux new-session -d -s "$SESSION" -c "$REPO" \
		"claude $FLAGS \"Lis docs/agents/PROMPT_SERVEUR.md et suis ses consignes : relance les agents et reprends le travail.\""
	echo "session recréée"
fi
