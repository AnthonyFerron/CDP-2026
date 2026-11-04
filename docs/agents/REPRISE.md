# Reprise du travail sur le serveur

À lire en premier par la session Claude Code qui reprend le projet. Tout le travail s'est arrêté le 4 novembre 2026 au soir sur le PC Windows d'Anthony. Il continue la nuit sur le serveur de production, qui n'a rien de sensible d'après Anthony.

## Où en est le projet

| Branche sur GitHub | Contenu | État |
| --- | --- | --- |
| `main` | Version déployée (run 30 de « Déployer », réussi) : PR #12 (intégration Godot ↔ API) et première manche des cinq lieux | En production |
| `dev` | `main`, plus la passe au centimètre du Marais, la collision des panneaux sur poteaux, et les tests et outils déplacés dans le dépôt | Suite de tests verte, sauf les outils ajoutés en dernier |
| `livraison/lot-04-11` | `dev`, plus les passes au centimètre du Hub, de la Plaine et du Désert, et la PR #11 (livrable L4, README au format du L4) | **Vérification complète interrompue** : à finir avant tout |
| `agents/hub` | Passe du Hub (déjà dans le lot), puis un commit « en cours » sur les intérieurs des nouveaux bâtiments | Non vérifié |
| `agents/plaine` | Passe de la Plaine | Déjà dans le lot |
| `agents/desert` | Passe du Désert | Déjà dans le lot |
| `agents/marais` | Passe du Marais (déjà dans dev), puis un commit « en cours » sur les performances web | Non vérifié |
| `agents/village` | Passe au centimètre du Village, interrompue pendant ses tests | Non fusionnée, non vérifiée |

La PR #11 est fusionnée dans `livraison/lot-04-11`. GitHub la marquera fusionnée quand ce lot arrivera dans `dev`.

## Premières tâches, dans l'ordre

1. **Finir la vérification du lot :** sur `livraison/lot-04-11`, lancer `GODOT=$GODOT bash frontend/tests/scenes/run_all.sh ~/cdp-work/logs`.
   - Attendu : 0 échec partout, sauf `hub_walk_0` et `hub_walk_4`, avec 2 échecs voulus chacun (« limite infranchissable (doit echouer) »).
   - Attendu aussi : `run_tests` à 49 réussis et 0 échec.
2. **Livrer le lot :** avancer `dev` sur le lot (fast-forward), pousser `dev`, puis `main` (`git push origin dev:main` si `main` est un ancêtre de `dev`).
   - Vérifier le déploiement : page GitHub Actions, workflow « Déployer ».
   - Vérifier la santé : `curl https://codequest.anthonyferron.com/api/v1/health/database` doit répondre `{"status":"ok","database":"connected"}`.
   - Vérifier le site : il répond en 200, et `index.pck` a un `Last-Modified` récent.
3. **Reprendre le Village :** passe au centimètre (branche `agents/village`), puis fusion et vérification.
4. **Reprendre la liste** de `docs/agents/RESTE_A_FAIRE.md`.

## Installer le serveur (une fois)

Ne jamais travailler dans `/opt/cdp-2026`, le dossier que `cdp-deploy` déploie. Travailler dans une copie à part, par exemple `~/cdp-dev`.

```sh
# Paquets (Debian ou Ubuntu ; sur Ubuntu 24.04, libasound2 s'appelle libasound2t64)
sudo apt-get install -y git git-lfs python3 tmux unzip curl xvfb libgl1-mesa-dri libglu1-mesa fontconfig \
	libxcursor1 libxinerama1 libxrandr2 libxi6 libxkbcommon0 libasound2

# Godot 4.7.2 pour Linux (vérifier le nom exact du fichier sur la page de la version)
mkdir -p ~/godot && cd ~/godot
curl -LO https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
unzip Godot_v4.7.2-stable_linux.x86_64.zip
echo 'export GODOT=~/godot/Godot_v4.7.2-stable_linux.x86_64' >> ~/.bashrc

# Le dépôt, avec ses modèles 3D (Git LFS avant le clone)
git lfs install
git clone https://github.com/AnthonyFerron/CDP-2026.git ~/cdp-dev
mkdir -p ~/cdp-work

# Claude Code, dans tmux pour survivre à la déconnexion SSH
curl -fsSL https://claude.ai/install.sh | bash
tmux new -s cdp
cd ~/cdp-dev && claude
```

- **Accès GitHub en écriture :** `dev` et `main` ont une règle « Changes must be made through a pull request », que le compte d'Anthony contourne en tant que propriétaire. Pour pousser depuis le serveur, il faut donc ses identifiants : `gh auth login`, un jeton personnel avec les droits Contents en écriture, ou une clé SSH ajoutée à son compte. La clé de déploiement de `cdp-deploy` ne suffit pas, elle ne sert qu'à lire.
- **Mémoire :** copier `docs/agents/memoire/*.md` dans le dossier de mémoire de Claude Code pour ce projet, sous `~/.claude/projects/`. Le nom du sous-dossier est le chemin du dépôt, encodé : les `/` deviennent des `-`.
- **Ressources :** le serveur sert aussi le jeu, l'API et PostgreSQL. Lancer les Godot de test avec `nice -n 10`, et limiter le nombre de Godot simultanés (deux ou trois). Le rendu logiciel sous Xvfb occupe plusieurs cœurs.
- **API de test locale** (facultatif, pour les tests fonctionnels de la PR #12) :
  - une base PostgreSQL de test, l'API lancée en local et `frontend/tests/mailsink.py` (voir `docs/api-godot.md` et la section Tests de `docs/api-contract.md`) ;
  - puis `$GODOT --headless --path frontend res://tests/run_tests.tscn -- --api=http://localhost:8000/api/v1 --mail-dir=<dossier>`.
  - **Jamais contre la production.**

## Outils dans le dépôt

| Chemin | Rôle |
| --- | --- |
| `frontend/tests/scenes/` | Tests de scène (hub, marche, énigmes, chronomètre, menus, connexion simulée, debug, plein écran, arbres, panneaux), `run_all.sh`, `cam_shots.gd` (captures), `aabb.gd` (taille des modèles) |
| `frontend/tests/run_tests.tscn` | Tests de l'intégration API (statiques et unitaires sans réseau, fonctionnels avec une API de test) |
| `frontend/tools/build_<lieu>.py` | Décor généré de chaque lieu |
| `frontend/tools/write_<lieu>_tscn.py` | Scène principale du hub, du désert, du marais et du village (argument : le dossier `frontend`) |
| `frontend/tools/check_overlaps.py` | Chevauchements de meubles (régénère les scènes au passage) |
| `docs/agents/BRIEF.md` | Consigne commune à donner à chaque agent |
| `docs/agents/SCENARIO.md` | Résumé du scénario officiel (le chronomètre reste à 60 minutes) |
| `docs/agents/PASSE_CENTIMETRE.md` | Méthode de vérification exhaustive d'un lieu |
| `docs/agents/BACKLOG.md` | Tâches suivantes de chaque lieu et tâches transversales |
| `docs/agents/RESTE_A_FAIRE.md` | Ce qui reste à faire, relevé au moment de l'arrêt |
| `docs/agents/<lieu>/` | Outils, inventaires et listes de problèmes des agents précédents : exemples, avec des chemins Windows à adapter |
| `docs/agents/memoire/` | Mémoire de la session précédente (conventions, contexte du jeu, exigences) |

## Méthode de travail

- **Rôle :** la session principale orchestre. Elle lance un agent par lieu, en worktree isolée, avec `docs/agents/BRIEF.md` et sa tâche.
- **Quand un agent finit :**
  1. lire son rapport et **regarder ses captures** ;
  2. le fusionner dans `dev`, dans une worktree à part si des tests tournent ;
  3. relancer tous les builders et les `write_*_tscn.py`, puis vérifier que `git status` reste propre (aucune dérive) ;
  4. lancer la suite complète ;
  5. pousser `dev`, puis `main`, et vérifier le déploiement ;
  6. donner à l'agent la tâche suivante.
- **Signaux d'alerte :**
  - un « −5:00 » ou un bandeau qui cache un panneau d'énigme ;
  - un texte qui déborde ;
  - un objet qui flotte, un mur invisible, un escalier qui ne se monte pas jusqu'en haut ;
  - un objet moderne dans un décor médiéval.
- **Règles d'Anthony :**
  - jamais de ligne `Co-Authored-By` ni de mention de Claude dans les commits et les PR ;
  - préfixes `features :`, `fix :`, `refactor :`, `docs :` ;
  - modèles uniquement des kits Kenney ;
  - chronomètre à 60 minutes ;
  - ne jamais committer `frontend/scenes/levels/test_level.tscn` ;
  - ne supprimer que les branches qu'il demande de supprimer ;
  - aucun test ni capture ne doit joindre l'API de production : `--api=http://127.0.0.1:9/api/v1` partout.
- **PR des autres membres de l'équipe :** les relire, puis les approuver ou les fusionner si elles sont bonnes. Si une PR casse quelque chose, comme la PR #11 qui écrasait LICENCES.md, le signaler à Anthony avant de fusionner.
