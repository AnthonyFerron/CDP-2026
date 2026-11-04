Tu reprends le développement de CodeQuest sur ce serveur, en orchestrateur de cinq agents (un par lieu : Hub, Plaine, Désert, Marais, Village). Tu travailles la nuit, sans personne pour répondre : avance seul, et considère que ce n'est jamais fini. L'objectif est d'aller le plus loin possible.

1. Prise en main
   - Lis dans l'ordre : `docs/agents/REPRISE.md`, `docs/agents/BRIEF.md`, `docs/agents/RESTE_A_FAIRE.md`, `docs/agents/PASSE_CENTIMETRE.md`, `docs/agents/SCENARIO.md`, `docs/agents/BACKLOG.md`, puis le `README.md` racine.
   - Copie `docs/agents/memoire/*.md` dans ta mémoire de projet, si elle est vide.
   - Vérifie l'outillage :
     - `$GODOT --version` donne 4.7.2 ;
     - `git lfs` est installé et les modèles ne sont pas des pointeurs ;
     - `xvfb-run` est présent ;
     - `git push` vers GitHub marche.
   - S'il manque quelque chose, installe-le si tu peux. Sinon, note-le dans `~/cdp-work/JOURNAL.md` et contourne-le.
   - Ne travaille jamais dans `/opt/cdp-2026`.

2. Livraison du lot en attente
   - Sur `livraison/lot-04-11`, lance la suite complète :
     `nice -n 10 env GODOT=$GODOT bash frontend/tests/scenes/run_all.sh ~/cdp-work/logs`
   - Si tout est conforme à l'attendu de REPRISE.md, avance `dev` sur ce lot, pousse `dev`, puis `main`.
   - Vérifie ensuite le déploiement : workflow « Déployer » réussi, `/api/v1/health/database`, site en 200, `index.pck` récent.
   - Sinon, corrige, puis recommence.

3. Lance les cinq agents
   - Chacun travaille dans sa propre worktree, en partant de sa branche `agents/<lieu>` fusionnée avec `dev`.
   - Donne-leur en entier `docs/agents/BRIEF.md`, plus leur tâche :
     - **Village** : terminer la passe au centimètre (PASSE_CENTIMETRE.md).
     - **Hub** : finir les intérieurs des neuf nouveaux bâtiments (commit « en cours » à vérifier), puis les villageois qui vivent après la victoire, puis les performances web.
     - **Marais** : vérifier et finir les performances web (commit « en cours »), puis les textes à lire dans le décor.
     - **Plaine** : textes à lire dans le décor, puis performances web.
     - **Désert** : retirer son contournement des panneaux sur poteaux (`sign_board.gd` est corrigé), puis les finitions libres du BACKLOG.
   - Une fois sa tâche finie, chaque agent prend la suivante dans BACKLOG.md.
   - Pendant ce temps, traite toi-même les corrections partagées de RESTE_A_FAIRE.md, les fichiers interdits aux agents :
     - `smoke_effect.gd` ;
     - le bandeau « Mauvaise réponse » et le « −5:00 » du HUD ;
     - `arch_fill()` dans les lieux ;
     - `check_overlaps.py` sans effet de bord.

4. À chaque fin d'agent
   - Lis son rapport et regarde ses captures.
   - Fusionne-le dans `dev` (dans une worktree à part si des tests tournent).
   - Relance tous les builders et les `write_*_tscn.py`, et vérifie qu'ils ne produisent aucune dérive.
   - Lance la suite complète, avec ses résultats attendus.
   - Pousse `dev` et `main`, et vérifie le déploiement.
   - Donne-lui sa tâche suivante.
   - Si un agent régresse ou casse un test, renvoie-lui le problème au lieu de fusionner.

5. Règles
   - Celles de `CLAUDE.md` et de REPRISE.md : jamais de `Co-Authored-By`, ni de mention de Claude dans les commits et les PR ; préfixes `features :`, `fix :`, `refactor :`, `docs :`.
   - Modèles Kenney seulement, et rien de moderne dans un décor médiéval.
   - Chronomètre à 60 minutes.
   - Ne jamais commiter `test_level.tscn`.
   - Ne supprimer aucune branche.
   - Chaque Godot de test ou de capture vise `--api=http://127.0.0.1:9/api/v1` : jamais la production.
   - Le serveur sert aussi le jeu en ligne : `nice -n 10` sur les Godot, et deux ou trois Godot en même temps au plus.

6. Limite d'usage et relance
   - Si la limite d'usage est atteinte, arrête-toi proprement : tout est commité, et l'état est noté dans `~/cdp-work/JOURNAL.md`.
   - Un cron envoie chaque nuit à 1 h 10 un message « Relance de 1 h 10 ». À ce message, reprends chaque agent arrêté là où il en était (par son identifiant s'il existe encore, sinon un nouvel agent sur sa branche `agents/<lieu>`), puis reprends l'orchestration.

7. Compte rendu
   - Tiens `~/cdp-work/JOURNAL.md` à jour : ce qui a été fusionné, testé, poussé et déployé, les problèmes rencontrés, ce qui reste. Anthony le lira le matin.
   - Mets aussi à jour `docs/agents/RESTE_A_FAIRE.md` dans `dev`.
   - Les PR des autres membres de l'équipe : relis-les, et fusionne-les si elles sont bonnes. Sinon, note pourquoi dans le journal sans les fusionner.
