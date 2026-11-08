# Intégration Godot ↔ API

Comment le jeu Godot utilise l'API FastAPI : architecture, parcours du joueur, règles de synchronisation, erreurs et tests. Les routes et les règles du serveur sont dans [api-contract.md](api-contract.md) ; chaque route est décrite dans Swagger, sur `/api/docs`.

## Architecture

| Autoload | Fichier | Rôle |
| --- | --- | --- |
| `Api` | `frontend/scripts/api.gd` | Seul point d'envoi des requêtes : adresse du serveur, jeton, JSON, délai de 15 s, messages d'erreur en français |
| `Account` | `frontend/scripts/account.gd` | Compte pour les menus : inscription, connexion en deux étapes, renvoi du code, mot de passe oublié, déconnexion, classements |
| `GameSync` | `frontend/scripts/game_sync.gd` | Partie d'un joueur connecté : création, reprise, énigmes, livres, fragments, pénalités, pauses, position, victoire, import |
| `GameState` | `frontend/scripts/game_state.gd` | Modèle local lu par les scènes, et sauvegarde sur l'appareil |

Les scènes ne font aucune requête. Elles appellent `GameState` comme avant, et `GameState` prévient `GameSync`, qui ne fait rien pour un invité. Toutes les requêtes sont asynchrones (`await`) : le jeu n'est jamais bloqué.

## Adresse de l'API

`Api.base_url` est choisie dans cet ordre :

1. l'argument `--api=URL` (tests) ;
2. le réglage du projet `cdp/api/base_url` (développement), vide par défaut ;
3. sur le web, l'origine de la page suivie de `/api/v1` : en production, le jeu et l'API partagent le domaine de Caddy, donc **HTTPS et aucun CORS** ;
4. sinon `https://codequest.anthonyferron.com/api/v1`, l'adresse de production donnée dans le README.

Pour un export Web servi sur une autre origine (le serveur de l'éditeur, `http://localhost:8060`) qui vise une API locale, renseigner `cdp/api/base_url` et ajouter l'origine à `CORS_ALLOWED_ORIGINS` côté API. Le client HTTP de Godot refuse les noms d'hôte de moins de 4 caractères : `http://api:8000` ne fonctionne pas, `http://localhost:8000` oui.

## Compte

| Action dans les menus | Appels |
| --- | --- |
| Créer un compte | `POST /users`, puis `POST /auth-challenges` avec le même mot de passe : le premier code part par e-mail |
| Se connecter | `POST /auth-challenges` |
| Valider le code | `POST /auth-sessions` : vérifie le code et ouvre la session dans la même requête |
| Renvoyer le code | `POST /auth-challenges/resends` (un toutes les 60 s) |
| Se déconnecter | `DELETE /auth-sessions/current`, sans attendre la réponse, puis oubli local |
| Mot de passe oublié | `POST /password-resets` avec l'adresse saisie : le serveur envoie un lien vers la page web `/reinitialisation`, où le joueur choisit son nouveau mot de passe |

- Les règles de saisie sont vérifiées avant l'envoi, comme sur le serveur : pseudo de 3 à 20 caractères (lettres, chiffres, espaces, `_ - . '`), mot de passe de 8 à 128 caractères avec au moins une lettre et un chiffre.
- Les messages du serveur, rédigés en français, s'affichent tels quels : code incorrect avec le nombre d'essais restants, code expiré, trop d'essais, adresse déjà utilisée, envoi d'e-mail impossible (503 tant que le SMTP n'est pas configuré).
- Le mot de passe n'est jamais gardé : il ne sert qu'à la requête en cours.
- **Mot de passe oublié** : le lien « Mot de passe oublié ? » de l'écran de connexion envoie l'adresse saisie (`Account.request_password_reset`). Le serveur répond de la même façon que le compte existe ou non, et le jeu affiche « Si le compte existe, un e-mail vient de partir : lien valable 30 minutes. ». Le nouveau mot de passe se choisit hors du jeu, sur la page web `https://codequest.anthonyferron.com/reinitialisation`, ouverte par le lien : elle appelle `POST /password-resets/confirmations`. Une seconde demande dans la minute répond 429, affiché tel quel. Après le changement, le serveur ferme toutes les sessions du compte : un appareil encore connecté reçoit un 401 et revient à l'écran de connexion.
- Le jeton, l'identifiant et le pseudo sont gardés dans `user://session.cfg`, avec l'expiration de la session (7 jours). Sur le web, `user://` est l'IndexedDB du site : tout script de la page peut le lire. Le jeu n'en charge aucun d'un autre domaine, mais une faille XSS exposerait le jeton jusqu'à son expiration ou à la déconnexion. Le jeton n'est jamais écrit dans les logs.
- Un 401 sur une requête authentifiée ferme la session. Pendant une partie, le jeu revient à l'écran de connexion avec le message « Votre session a expiré » ; dans le menu, l'écran de connexion s'ouvre aussitôt.

## Partie connectée

### Ce que relaie GameState

| Dans le jeu | Fonction | Appel |
| --- | --- | --- |
| Le roi et Merlon confient la mission | `begin_mission()` | `POST /game-sessions` : le chronomètre du serveur démarre |
| Entrée dans une zone | `enter_zone(zone)` | `POST /puzzle-progress` (idempotent), puis sauvegarde du niveau |
| Retour au hub | `return_to_hub(zone)` | `PATCH /game-sessions/{id}` (niveau, position) |
| Livre trouvé | `collect_book(book)` | `PATCH /puzzle-progress/{id}` avec `{"solved": true}` |
| Livre posé sur son piédestal | `request_place_book(book)` | `POST /puzzle-progress/{id}/placements`, **attendu** |
| Fragment de papier ramassé | `collect_fragment(index)` | `POST /paper-fragments` avec `{"fragment_index": index}` |
| Mauvaise validation | `penalize()` | `POST /penalties` |
| Quatrième livre posé, rituel | `request_victory()` | `POST /completions`, **attendu** |
| Toutes les 30 s dans un niveau, et en revenant au menu | `GameSync.save_position()` | `PATCH /game-sessions/{id}` |

Les actions partent dans **une seule file**, une requête à la fois, dans l'ordre : une énigme est commencée avant d'être résolue, résolue avant que son livre soit posé, et les quatre livres sont posés avant la victoire. Les sauvegardes de position en attente sont fusionnées : seule la plus récente part, si bien qu'une ancienne sauvegarde ne peut pas en écraser une nouvelle. Les identifiants des énigmes sont lus dans `GET /puzzles` (par `order_index`) : ils ne sont jamais écrits en dur.

### Livres et victoire

- Au piédestal, le hub attend la réponse du serveur avant de jouer l'animation de pose. En cas de refus (partie en pause, temps écoulé, livre non enregistré), le livre reste en main et le refus s'affiche : un livre n'est jamais montré posé sans que le serveur l'ait enregistré.
- Au quatrième livre, le rituel attend la validation de `POST /completions`. La fin heureuse ne se joue qu'une fois la victoire confirmée. Si elle échoue, le joueur reprend la main et réessaie en revenant à un piédestal ; si le temps est écoulé, c'est l'éruption.
- Le menu de debug pose les livres sans attendre (`place_book`) : le dépôt part quand même au serveur.

### Chronomètre

- Le temps local ne court que dans un niveau, hors pause. Il s'arrête dans les menus, la pause, les indices et les chargements.
- Pour une partie connectée, le temps affiché est celui du serveur (`GameSync.official_remaining()`) : son dernier `remaining_seconds`, décompté avec l'horloge tant que le serveur ne l'a pas mis en pause. L'affichage ne s'arrête donc qu'une fois la pause enregistrée par le serveur.
- `GameSync` met le chronomètre du serveur en pause dès l'arrivée dans un menu, ou quand le jeu reste figé plus d'une seconde dans un niveau (pause, indices, transition), et le relance dès que le joueur reprend la main. Un gel plus court ne déclenche aucune requête, et le temps continue alors à l'écran comme sur le serveur.
- Les requêtes avancent même jeu figé (`Api` tourne en `PROCESS_MODE_ALWAYS`) : la pause atteint le serveur pendant le menu pause ou une transition.
- Une pénalité est déduite tout de suite de l'affichage. La déconnexion attend que la pause soit enregistrée, avant la révocation du jeton.
- Fermer le navigateur n'est pas une pause : le temps continue de courir sur le serveur, comme prévu par le contrat.
- À zéro, le jeu demande l'état de la partie au serveur et n'affiche l'éruption que s'il la confirme. Hors connexion, l'éruption a lieu tout de suite.
- Une pénalité retire 5 minutes localement et sur le serveur, qui déclare la défaite si elle épuise le temps.

### Reprise sur un autre appareil

À l'accueil, un joueur connecté lit sa partie sur le serveur (`GET /game-sessions?status=in_progress`, puis `GET /progress`) :

- **partie en cours** : elle remplace la sauvegarde locale. Les livres trouvés et posés, les fragments, le temps, le niveau et la position sont restaurés, et « Charger partie » ramène au hub, devant le portail de la dernière zone visitée ;
- **aucune partie en cours** : la sauvegarde locale n'est gardée que pour une partie gagnée (exploration après la victoire) ;
- **partie commencée sans que le serveur l'ait jamais vue** (création restée sans réponse) : elle est importée, temps et progression conservés, et ne compte donc pas pour le classement.

« Nouvelle partie » abandonne d'abord sur le serveur la partie en cours, comme l'annonce la confirmation : le serveur n'accepte qu'une partie en cours par compte.

La position est sauvegardée, sur le serveur comme sur l'appareil, mais la reprise ramène toujours au hub. Les zones ne gardent pas l'état intermédiaire de leurs énigmes, et le hub distingue l'intérieur du bunker de l'extérieur : réapparaître au milieu d'un niveau les casserait.

### Fragments de papier

- Chaque fragment de la mairie (`PaperFragment.fragment`, de 0 à 9) est gardé dans `GameState.fragments`, sauvegardé sur l'appareil et, pour un joueur connecté, envoyé au serveur.
- En entrant dans le Village, les fragments déjà ramassés sont retirés de la mairie et remis dans le carnet. Ouvrir le meuble qui en cachait un ne le fait pas réapparaître.

## Invité

- L'invité joue sans compte. Sa partie est gardée dans `user://sauvegarde.cfg` (livres trouvés et posés, fragments, temps, niveau, position), et « Charger partie » la reprend sur le même appareil.
- Elle n'existe que sur cet appareil : aucune synchronisation n'est promise tant qu'elle n'est pas rattachée à un compte.
- Un test garde ses sauvegardes **et sa session** (`Account.session_path()`) dans `user://tests/<pid>/` (`GameState.data_dir()`), effacé à sa sortie : un test lancé en script (`godot --script res://tests/…`, et les outils de `tools/`), comme une scène de `res://tests/` lancée directement (`run_tests.tscn`). Le dossier `user://` est commun à toutes les copies du projet sur une machine : sans cela, deux tests lancés en même temps écrivaient la même sauvegarde (`timer_test` relisait celle d'un autre test, « sauvegarde effacee » échouait sur le serveur chargé), et `run_tests` lisait au démarrage la session simulée qu'un `menu_test` ou un `debug_test` lancé à côté venait d'ouvrir dans `user://session.cfg` (« démarrage en invité » en échec). Le jeu, lui, garde `user://sauvegarde.cfg` et `user://session.cfg` : le dossier `tests/` n'est pas exporté.
- Après l'éruption, la partie remise à zéro ne peut plus être réécrite : une réponse tardive du serveur pour une partie oubliée (`GameSync`, génération de la partie suivie) n'applique plus rien, et une partie dont la mission n'a pas commencé ne peut plus entrer en éruption.
- Après la vérification du code, si une partie invitée est en cours (ou gagnée) sur l'appareil et que le compte n'en a pas, le menu propose de la rattacher (`POST /game-sessions/imports`). Seules les énigmes résolues dans l'ordre partent, et les fragments seulement si le Village est ouvert, comme l'exige le serveur.
- Une partie rattachée n'entre jamais dans les classements. Elle arrive en pause, repart quand le joueur reprend la main, et la sauvegarde invitée est vidée.

## Classements

- L'écran du menu affiche le classement général et celui de chaque énigme (onglets), 20 lignes par page, avec « Afficher plus ».
- Rang (deux temps égaux partagent le même rang), pseudo et temps viennent de l'API, sans aucune donnée personnelle.
- Le classement reste réservé aux joueurs connectés, comme sur les maquettes, même si l'API le sert sans session.
- Une partie n'est classée que si chacune de ses énigmes a pris au moins 30 secondes, règle appliquée par le serveur.

## Erreurs et réseau

| Situation | Comportement |
| --- | --- |
| Pas de réseau, serveur arrêté, délai de 15 s dépassé | Message clair ; une action de partie est retentée (1, 2, 4, 8 puis 15 s) dans l'ordre, et le HUD affiche « Connexion au serveur perdue », puis « rétablie » |
| 429 | Nouvel essai après le délai `Retry-After` |
| 500 | Deux nouveaux essais, puis abandon de l'action |
| 401 | Session fermée, retour à l'écran de connexion |
| 403, 404, 422 | Message du serveur, ou message générique en français ; une erreur de validation est traduite en nom de champ |
| 409 | L'état du serveur est relu : une action déjà faite (livre déjà posé, fragment déjà ramassé) compte comme réussie, sinon le refus s'affiche |
| 503 (SMTP non configuré) | Message du serveur : le code n'a pas pu être envoyé. Une demande de lien de réinitialisation répond toujours 202 : un échec d'envoi n'est que journalisé côté serveur |
| JSON invalide | « Réponse inattendue du serveur. » |

Les avertissements techniques (`[API]`, `[Partie]`, `[Compte]`) indiquent la méthode, le chemin et le code HTTP, jamais de jeton, de mot de passe ni de code.

## Tests

`frontend/tests/run_tests.tscn`, exclu de l'export Web :

```sh
# Statique et unitaire, sans réseau
godot --headless --path frontend res://tests/run_tests.tscn

# Avec une API de test et un faux serveur SMTP qui écrit les codes dans <dossier>/<adresse>.log
godot --headless --path frontend res://tests/run_tests.tscn -- --api=http://localhost:8000/api/v1 --mail-dir=<dossier>
```

- **Statique** : tous les scripts compilent, toutes les scènes se chargent, autoloads et signaux présents, plus aucune référence aux routes ou champs abandonnés.
- **Unitaire** : sauvegarde et lecture des anciennes sauvegardes, chronomètre, fragments, dépôt et victoire en invité, pénalités, validation des formulaires, mot de passe oublié (adresse refusée avant envoi, route branchée, réponse simulée), messages d'erreur, corps de l'import, restauration des fragments dans le Village et des livres dans le hub.
- **Fonctionnel** :
  - inscription et code reçu par SMTP ;
  - code faux, renvoi trop tôt, adresse déjà utilisée, mauvais mot de passe ;
  - partie complète : énigmes, livres posés, dix fragments, pénalité, pause, reprise sur un autre appareil et victoire ;
  - défaite et abandon ;
  - partie classée et classements, écran compris ;
  - import invité, coupure réseau, jeton refusé.

  Le script refuse de viser la production. L'API de test doit tourner avec `EMAIL_BACKEND=smtp` vers le faux serveur SMTP. Comptez environ 2 min 30 : une partie classée exige des énigmes de plus de 30 secondes.
