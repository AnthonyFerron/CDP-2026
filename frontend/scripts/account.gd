extends Node
## Compte du joueur : connexion, création de compte, vérification en deux étapes, mot de passe oublié,
## classement et envoi du temps réalisé. Les menus passent tous par ce fichier, et par lui seul.
##
## Les réponses sont pour l'instant simulées, sans serveur : chaque méthode attend un court délai puis répond
## comme le ferait l'API. Pour la brancher, remplacer le corps des méthodes marquées « Simulé » par les appels
## HTTP, en gardant leurs signatures et la forme des dictionnaires renvoyés ; les menus n'ont pas à changer.
##
## Chaque méthode est une coroutine : `var result := await Account.login(email, password)`.
## Un résultat contient toujours `ok` (bool) et, en cas d'échec, `error` (texte à afficher au joueur).

## La session vient de s'ouvrir ou de se fermer.
signal session_changed

## Session gardée d'une visite à l'autre, sur cet appareil.
const SESSION_PATH := "user://session.cfg"
## Délai des réponses simulées, en secondes.
const SIMULATED_DELAY := 0.35
const MIN_PASSWORD := 8
const PSEUDO_LENGTH := Vector2i(3, 20)

var pseudo := ""
var email := ""
## Jeton de session renvoyé par l'API ; vide tant qu'aucun joueur n'est connecté.
var token := ""

## Connexion ou inscription en attente de son code de vérification.
var _pending := {}


func _ready() -> void:
	_load_session()


func is_logged_in() -> bool:
	return not token.is_empty()


## Nom de la sauvegarde locale du joueur : vide pour un invité.
func profile_id() -> String:
	return ("compte_" + pseudo.to_lower()).validate_filename() if is_logged_in() else ""


## Vérifie l'adresse et le mot de passe. En cas de succès, un code est envoyé par e-mail :
## `needs_code` vaut vrai et la session ne s'ouvre qu'avec `verify_code`.
func login(address: String, password: String) -> Dictionary:
	var problem := _check_email(address)
	if problem.is_empty() and password.is_empty():
		problem = "Saisissez votre mot de passe."
	if not problem.is_empty():
		return {"ok": false, "error": problem}
	# Simulé : toute adresse valide est acceptée, le pseudo est tiré de l'adresse.
	await get_tree().create_timer(SIMULATED_DELAY).timeout
	_pending = {"pseudo": address.get_slice("@", 0).capitalize().replace(" ", ""), "email": address}
	return {"ok": true, "needs_code": true}


## Crée le compte, puis envoie un code de vérification à l'adresse donnée.
func register(new_pseudo: String, address: String, password: String) -> Dictionary:
	var problem := ""
	if new_pseudo.strip_edges().length() < PSEUDO_LENGTH.x or new_pseudo.strip_edges().length() > PSEUDO_LENGTH.y:
		problem = "Le pseudo doit compter de %d à %d caractères." % [PSEUDO_LENGTH.x, PSEUDO_LENGTH.y]
	if problem.is_empty():
		problem = _check_email(address)
	if problem.is_empty() and password.length() < MIN_PASSWORD:
		problem = "Le mot de passe doit compter au moins %d caractères." % MIN_PASSWORD
	if not problem.is_empty():
		return {"ok": false, "error": problem}
	# Simulé : le compte est accepté tel quel.
	await get_tree().create_timer(SIMULATED_DELAY).timeout
	_pending = {"pseudo": new_pseudo.strip_edges(), "email": address}
	return {"ok": true, "needs_code": true}


## Valide le code à six chiffres reçu par e-mail, et ouvre la session.
func verify_code(code: String) -> Dictionary:
	if _pending.is_empty():
		return {"ok": false, "error": "La demande a expiré : reconnectez-vous."}
	if code.length() != 6 or not code.is_valid_int():
		return {"ok": false, "error": "Le code compte six chiffres."}
	# Simulé : tout code de six chiffres est accepté.
	await get_tree().create_timer(SIMULATED_DELAY).timeout
	pseudo = _pending.pseudo
	email = _pending.email
	token = "session-simulee"
	_pending = {}
	_save_session()
	session_changed.emit()
	return {"ok": true}


## Renvoie le code de vérification de la demande en cours.
func resend_code() -> Dictionary:
	if _pending.is_empty():
		return {"ok": false, "error": "La demande a expiré : reconnectez-vous."}
	# Simulé.
	await get_tree().create_timer(SIMULATED_DELAY).timeout
	return {"ok": true}


## Demande un lien de réinitialisation du mot de passe. La réponse est la même que le compte existe ou non.
func request_password_reset(address: String) -> Dictionary:
	var problem := _check_email(address)
	if not problem.is_empty():
		return {"ok": false, "error": problem}
	# Simulé.
	await get_tree().create_timer(SIMULATED_DELAY).timeout
	return {"ok": true}


func logout() -> void:
	# Simulé : l'API devra aussi invalider le jeton côté serveur.
	pseudo = ""
	email = ""
	token = ""
	_pending = {}
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SESSION_PATH))
	session_changed.emit()


## Classement des meilleurs temps : `entries` est une liste de {"pseudo", "seconds"}, du meilleur au moins bon.
func fetch_leaderboard() -> Dictionary:
	# Simulé : aucun temps n'est encore enregistré sans serveur.
	await get_tree().create_timer(SIMULATED_DELAY).timeout
	return {"ok": true, "entries": []}


## Envoie le temps mis pour réunir les quatre livres, en secondes. Sans session, rien n'est envoyé.
func submit_run(seconds: float) -> Dictionary:
	if not is_logged_in():
		return {"ok": false, "error": "Connectez-vous pour enregistrer votre temps."}
	# Simulé : le temps n'est envoyé nulle part.
	await get_tree().create_timer(SIMULATED_DELAY).timeout
	return {"ok": true, "seconds": seconds}


func _check_email(address: String) -> String:
	var at := address.find("@")
	if address.strip_edges().is_empty():
		return "Saisissez votre adresse e-mail."
	if at < 1 or address.find(".", at) < at + 2 or address.ends_with(".") or address.contains(" "):
		return "Cette adresse e-mail n'est pas valide."
	return ""


func _save_session() -> void:
	var file := ConfigFile.new()
	file.set_value("session", "pseudo", pseudo)
	file.set_value("session", "email", email)
	file.set_value("session", "jeton", token)
	file.save(SESSION_PATH)


func _load_session() -> void:
	var file := ConfigFile.new()
	if file.load(SESSION_PATH) != OK:
		return
	pseudo = file.get_value("session", "pseudo", "")
	email = file.get_value("session", "email", "")
	token = file.get_value("session", "jeton", "")
