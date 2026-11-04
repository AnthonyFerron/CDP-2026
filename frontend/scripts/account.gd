extends Node
## Compte du joueur : connexion, création de compte, vérification en deux étapes, déconnexion et classements.
## Les menus passent tous par ce fichier, et par lui seul ; les requêtes HTTP passent par l'autoload Api.
##
## Chaque méthode est une coroutine : `var result := await Account.login(email, password)`.
## Un résultat contient toujours `ok` (bool) et, en cas d'échec, `error` (texte à afficher au joueur).
##
## Connexion en deux étapes, comme l'API : le mot de passe déclenche l'envoi d'un code par e-mail
## (POST /auth-challenges), puis le code ouvre la session (POST /auth-sessions), qui renvoie le jeton.
## Le mot de passe n'est jamais gardé : il ne sert qu'à la requête en cours.
##
## Mode simulé (`simulated`) : réservé au menu de debug, il répond sans serveur, comme avant l'API.

## La session vient de s'ouvrir ou de se fermer.
signal session_changed
## Le serveur a refusé le jeton (expiré ou révoqué) : le joueur doit se reconnecter.
signal session_expired

## Session gardée d'une visite à l'autre, sur cet appareil (IndexedDB du site sur le web).
const SESSION_PATH := "user://session.cfg"
## Délai des réponses simulées, en secondes.
const SIMULATED_DELAY := 0.35
## Règles du serveur (backend/app/schemas/users.py) ; le pseudo est limité à 20 caractères pour l'affichage.
const MIN_PASSWORD := 8
const MAX_PASSWORD := 128
const PSEUDO_LENGTH := Vector2i(3, 20)

var pseudo := ""
var email := ""
var user_id := 0
## Jeton de session renvoyé par l'API ; vide tant qu'aucun joueur n'est connecté.
var token := ""
## Vrai pour le compte de test du menu de debug : aucune requête n'est envoyée au serveur.
var simulated := false

## Connexion ou inscription en attente de son code de vérification : adresse et date de renvoi possible.
var _pending := {}
var _pseudo_pattern := RegEx.create_from_string("^[\\p{L}\\p{N}_ .'-]+$")


func _ready() -> void:
	_load_session()
	Api.unauthorized.connect(_on_unauthorized)


func is_logged_in() -> bool:
	return not token.is_empty()


## Connecté avec un vrai compte du serveur (et non le compte simulé du debug).
func is_online() -> bool:
	return is_logged_in() and not simulated


## Nom de la sauvegarde locale du joueur : vide pour un invité. Un compte du serveur est désigné par son
## identifiant, unique, plutôt que par son pseudo, qui ne l'est pas.
func profile_id() -> String:
	if not is_logged_in():
		return ""
	if simulated:
		return ("compte_" + pseudo.to_lower()).validate_filename()
	return "compte_%d" % user_id


## Vérifie l'adresse et le mot de passe. En cas de succès, un code est envoyé par e-mail :
## `needs_code` vaut vrai et la session ne s'ouvre qu'avec `verify_code`.
func login(address: String, password: String) -> Dictionary:
	var problem := _check_email(address)
	if problem.is_empty() and password.is_empty():
		problem = "Saisissez votre mot de passe."
	if not problem.is_empty():
		return {"ok": false, "error": problem}
	if simulated:
		return await _simulated_challenge(address.get_slice("@", 0).capitalize().replace(" ", ""), address)
	return await _request_code(address.strip_edges().to_lower(), password)


## Crée le compte, puis envoie un code de vérification à l'adresse donnée.
func register(new_pseudo: String, address: String, password: String) -> Dictionary:
	var name := " ".join(new_pseudo.split(" ", false))
	var problem := ""
	if name.length() < PSEUDO_LENGTH.x or name.length() > PSEUDO_LENGTH.y:
		problem = "Le pseudo doit compter de %d à %d caractères." % [PSEUDO_LENGTH.x, PSEUDO_LENGTH.y]
	elif not _pseudo_pattern.search(name):
		problem = "Le pseudo ne peut contenir que des lettres, des chiffres, des espaces et _ - . '"
	if problem.is_empty():
		problem = _check_email(address)
	if problem.is_empty():
		problem = _check_password(password)
	if not problem.is_empty():
		return {"ok": false, "error": problem}
	if simulated:
		return await _simulated_challenge(name, address)
	var normalized := address.strip_edges().to_lower()
	var created := await Api.post_json("/users", {"username": name, "email": normalized, "password": password}, false)
	if not created.ok:
		return {"ok": false, "error": created.error}
	# Le compte existe : la connexion envoie le premier code.
	var sent := await _request_code(normalized, password)
	if not sent.ok:
		sent.error = "Votre compte est créé, mais le code n'a pas pu être envoyé : %s Connectez-vous plus tard." % sent.error
	return sent


## Valide le code à six chiffres reçu par e-mail, et ouvre la session.
func verify_code(code: String) -> Dictionary:
	if _pending.is_empty():
		return {"ok": false, "error": "La demande a expiré : reconnectez-vous."}
	if code.length() != 6 or not code.is_valid_int():
		return {"ok": false, "error": "Le code compte six chiffres."}
	if simulated:
		await get_tree().create_timer(SIMULATED_DELAY).timeout
		_open_session("session-simulee", 0, _pending.pseudo, _pending.email, 0)
		return {"ok": true}
	var result := await Api.post_json("/auth-sessions", {"email": _pending.email, "code": code}, false)
	if not result.ok:
		return {"ok": false, "error": result.error}
	var user: Dictionary = result.data.get("user", {})
	_open_session(result.data.token, int(user.get("id_users", 0)), str(user.get("username", "")),
		str(user.get("email", _pending.email)), _unix_time(str(result.data.get("expires_at", ""))))
	return {"ok": true}


## Renvoie le code de vérification de la demande en cours.
func resend_code() -> Dictionary:
	if _pending.is_empty():
		return {"ok": false, "error": "La demande a expiré : reconnectez-vous."}
	if simulated:
		await get_tree().create_timer(SIMULATED_DELAY).timeout
		return {"ok": true}
	var result := await Api.post_json("/auth-challenges/resends", {"email": _pending.email}, false)
	if not result.ok:
		return {"ok": false, "error": result.error}
	_pending["masked"] = str(result.data.get("email_masked", _pending.get("masked", "")))
	return {"ok": true}


## Adresse masquée (« d***@example.com ») à laquelle le dernier code a été envoyé.
func pending_address() -> String:
	return str(_pending.get("masked", ""))


## L'API ne propose pas encore de réinitialisation du mot de passe : aucune requête n'est envoyée.
func request_password_reset(address: String) -> Dictionary:
	var problem := _check_email(address)
	if not problem.is_empty():
		return {"ok": false, "error": problem}
	return {"ok": false, "error": "La réinitialisation du mot de passe n'est pas encore disponible."}


## Ferme la session : le serveur révoque le jeton (sans attendre sa réponse), puis il est oublié ici.
func logout() -> void:
	if is_online():
		Api.request(HTTPClient.METHOD_DELETE, "/auth-sessions/current")
	_clear_session()
	session_changed.emit()


## Classement public. `puzzle_id` à 0 : classement général ; sinon celui d'une énigme.
## `entries` : liste de {"rank", "pseudo", "seconds", "time"} ; `total` : nombre de joueurs classés.
func fetch_leaderboard(puzzle_id := 0, offset := 0, limit := 20) -> Dictionary:
	if simulated:
		await get_tree().create_timer(SIMULATED_DELAY).timeout
		return {"ok": true, "entries": [], "total": 0}
	var path := "/leaderboards" if puzzle_id == 0 else "/puzzles/%d/leaderboards" % puzzle_id
	var result := await Api.get_json("%s?limit=%d&offset=%d" % [path, limit, offset], false)
	if not result.ok:
		return {"ok": false, "error": "Le classement est indisponible pour l'instant. %s" % result.error}
	var entries: Array = []
	for item: Dictionary in result.data.get("items", []):
		var seconds := float(item.get("elapsed_seconds", 0.0))
		if item.has("completion_time_ms"):
			seconds = float(item.completion_time_ms) / 1000.0
		entries.append({
			"rank": int(item.get("rank", entries.size() + 1)),
			"pseudo": str(item.get("username", "?")),
			"seconds": seconds,
			"time": str(item.get("time_formatted", "")),
		})
	return {"ok": true, "entries": entries, "total": int(result.data.get("total", entries.size()))}


func _request_code(address: String, password: String) -> Dictionary:
	var result := await Api.post_json("/auth-challenges", {"email": address, "password": password}, false)
	if not result.ok:
		return {"ok": false, "error": result.error}
	_pending = {"email": address, "masked": str(result.data.get("email_masked", ""))}
	return {"ok": true, "needs_code": true, "email_masked": _pending.masked}


func _simulated_challenge(name: String, address: String) -> Dictionary:
	await get_tree().create_timer(SIMULATED_DELAY).timeout
	_pending = {"pseudo": name, "email": address, "masked": address}
	return {"ok": true, "needs_code": true}


func _open_session(new_token: String, id: int, name: String, address: String, expires_at: int) -> void:
	token = new_token
	user_id = id
	pseudo = name
	email = address
	_pending = {}
	Api.token = "" if simulated else token
	_save_session(expires_at)
	session_changed.emit()


func _on_unauthorized() -> void:
	if not is_online():
		return
	push_warning("[Compte] session refusée par le serveur : déconnexion locale")
	_clear_session()
	session_changed.emit()
	session_expired.emit()


func _check_email(address: String) -> String:
	var at := address.find("@")
	if address.strip_edges().is_empty():
		return "Saisissez votre adresse e-mail."
	if at < 1 or address.find(".", at) < at + 2 or address.ends_with(".") or address.contains(" "):
		return "Cette adresse e-mail n'est pas valide."
	return ""


func _check_password(password: String) -> String:
	if password.length() < MIN_PASSWORD or password.length() > MAX_PASSWORD:
		return "Le mot de passe doit compter de %d à %d caractères." % [MIN_PASSWORD, MAX_PASSWORD]
	var letter := false
	var digit := false
	for character in password:
		digit = digit or character.is_valid_int()
		letter = letter or character.to_lower() != character.to_upper()
	if not letter or not digit:
		return "Le mot de passe doit contenir au moins une lettre et un chiffre."
	return ""


## Date ISO 8601 de l'API (« 2026-11-11T10:00:00Z ») en secondes Unix, 0 si elle est illisible.
static func _unix_time(iso: String) -> int:
	if iso.is_empty():
		return 0
	return int(Time.get_unix_time_from_datetime_string(iso.get_slice(".", 0).trim_suffix("Z")))


func _clear_session() -> void:
	pseudo = ""
	email = ""
	user_id = 0
	token = ""
	simulated = false
	_pending = {}
	Api.token = ""
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SESSION_PATH))


func _save_session(expires_at: int) -> void:
	var file := ConfigFile.new()
	file.set_value("session", "pseudo", pseudo)
	file.set_value("session", "email", email)
	file.set_value("session", "identifiant", user_id)
	file.set_value("session", "jeton", token)
	file.set_value("session", "expiration", expires_at)
	file.set_value("session", "simulee", simulated)
	file.save(SESSION_PATH)


func _load_session() -> void:
	var file := ConfigFile.new()
	if file.load(SESSION_PATH) != OK:
		return
	var expires_at := int(file.get_value("session", "expiration", 0))
	if expires_at > 0 and expires_at <= int(Time.get_unix_time_from_system()):
		_clear_session()
		return
	pseudo = file.get_value("session", "pseudo", "")
	email = file.get_value("session", "email", "")
	user_id = int(file.get_value("session", "identifiant", 0))
	token = file.get_value("session", "jeton", "")
	simulated = bool(file.get_value("session", "simulee", token == "session-simulee"))
	# Ancienne session simulée, ou session réelle sans identifiant : on repart déconnecté.
	if not simulated and user_id == 0:
		_clear_session()
		return
	Api.token = "" if simulated else token
