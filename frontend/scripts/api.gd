extends Node
## Client HTTP de l'API CDP-2026 : adresse du serveur, jeton de session, JSON, délais et erreurs.
## Toutes les requêtes du jeu passent par ici, via Account et GameSync.
##
## `var result := await Api.request(HTTPClient.METHOD_GET, "/puzzles")` renvoie toujours un dictionnaire :
## - `ok` : vrai pour une réponse 2xx ;
## - `status` : code HTTP, ou 0 si le serveur n'a pas répondu ;
## - `data` : corps JSON décodé (ou null) ;
## - `error` : message à afficher au joueur en cas d'échec ;
## - `kind` : "network", "timeout", "http" ou "json" en cas d'échec ;
## - `retry_after` : secondes à attendre, pour une réponse 429.
## Les requêtes ne bloquent jamais le jeu : chacune utilise son propre HTTPRequest.

## Une requête authentifiée a été refusée (401) : le jeton est expiré ou révoqué.
signal unauthorized

## Adresse de production, d'après le README : le jeu et l'API sont servis par le même domaine.
const DEFAULT_BASE_URL := "https://codequest.anthonyferron.com/api/v1"
## Réglage du projet pour viser une autre API (développement) ; vide pour le choix automatique.
const BASE_URL_SETTING := "cdp/api/base_url"
const TIMEOUT := 15.0

var base_url := ""
## Jeton Bearer, fourni par Account. Il n'est jamais écrit dans les logs.
var token := ""


func _ready() -> void:
	# Les requêtes (HTTPRequest, enfants de ce nœud) doivent avancer même quand le jeu est figé : menu pause,
	# indices, transitions, écran de fin. Sinon la pause du chronomètre n'atteindrait le serveur qu'à la reprise.
	process_mode = Node.PROCESS_MODE_ALWAYS
	base_url = _resolve_base_url()
	print("[API] serveur : %s" % base_url)


## 1. argument `--api=URL` (tests), 2. réglage du projet, 3. sur le web, l'origine de la page (même domaine,
## même protocole : HTTPS en production, sans CORS), 4. l'adresse de production.
func _resolve_base_url() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--api="):
			return argument.trim_prefix("--api=").trim_suffix("/")
	var configured := str(ProjectSettings.get_setting(BASE_URL_SETTING, "")).strip_edges()
	if not configured.is_empty():
		return configured.trim_suffix("/")
	if OS.has_feature("web"):
		var origin: Variant = JavaScriptBridge.eval("window.location.origin", true)
		if typeof(origin) == TYPE_STRING and String(origin).begins_with("http"):
			return String(origin) + "/api/v1"
	return DEFAULT_BASE_URL


func request(method: HTTPClient.Method, path: String, body: Variant = null, authenticated := true) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = TIMEOUT
	add_child(http)
	var headers := PackedStringArray(["Accept: application/json"])
	var payload := ""
	if body != null:
		headers.append("Content-Type: application/json")
		payload = JSON.stringify(body)
	if authenticated and not token.is_empty():
		headers.append("Authorization: Bearer " + token)
	var error := http.request(base_url + path, headers, method, payload)
	if error != OK:
		http.queue_free()
		return _failure(path, method, 0, "network", "Impossible de joindre le serveur. Vérifiez votre connexion.")
	var response: Array = await http.request_completed
	http.queue_free()
	return _interpret(response, method, path, authenticated)


func get_json(path: String, authenticated := true) -> Dictionary:
	return await request(HTTPClient.METHOD_GET, path, null, authenticated)


func post_json(path: String, body: Variant = null, authenticated := true) -> Dictionary:
	return await request(HTTPClient.METHOD_POST, path, body, authenticated)


func _interpret(response: Array, method: HTTPClient.Method, path: String, authenticated: bool) -> Dictionary:
	var result: int = response[0]
	var status: int = response[1]
	var headers: PackedStringArray = response[2]
	var raw: PackedByteArray = response[3]
	if result == HTTPRequest.RESULT_TIMEOUT:
		return _failure(path, method, 0, "timeout", "Le serveur ne répond pas. Réessayez dans un instant.")
	if result != HTTPRequest.RESULT_SUCCESS:
		return _failure(path, method, 0, "network", "Impossible de joindre le serveur. Vérifiez votre connexion.")

	var data: Variant = null
	var text := raw.get_string_from_utf8()
	if not text.is_empty():
		var json := JSON.new()
		if json.parse(text) != OK:
			return _failure(path, method, status, "json", "Réponse inattendue du serveur.")
		data = json.data

	if status >= 200 and status < 300:
		return {"ok": true, "status": status, "data": data, "error": "", "kind": ""}

	var detail: Variant = data.get("detail") if data is Dictionary else null
	var failure := _failure(path, method, status, "http", _message(status, detail))
	failure["data"] = data
	if status == 429:
		failure["retry_after"] = _retry_after(headers)
	if status == 401 and authenticated and not token.is_empty():
		unauthorized.emit()
	return failure


## Message pour le joueur : celui du serveur quand il en donne un (ils sont rédigés en français), sinon un
## message générique selon le code.
func _message(status: int, detail: Variant) -> String:
	if detail is String and not String(detail).is_empty():
		return detail
	match status:
		401:
			return "Votre session a expiré : reconnectez-vous."
		403:
			return "Accès refusé."
		404:
			return "Élément introuvable sur le serveur."
		409:
			return "Action impossible dans l'état actuel de la partie."
		422:
			return _validation_message(detail)
		429:
			return "Trop de tentatives : patientez un peu avant de réessayer."
		503:
			return "Service momentanément indisponible. Réessayez plus tard."
	if status >= 500:
		return "Erreur du serveur. Réessayez plus tard."
	return "Requête refusée par le serveur (code %d)." % status


## Erreur de validation de FastAPI : une liste d'erreurs par champ, en anglais. Le champ est traduit.
func _validation_message(detail: Variant) -> String:
	const FIELDS := {
		"username": "le pseudo", "email": "l'adresse e-mail", "password": "le mot de passe", "code": "le code",
	}
	if detail is Array and not detail.is_empty() and detail[0] is Dictionary:
		var location: Array = detail[0].get("loc", [])
		var field := String(location.back()) if not location.is_empty() else ""
		if FIELDS.has(field):
			return "Vérifiez %s : il n'est pas valide." % FIELDS[field]
	return "Certaines informations envoyées ne sont pas valides."


func _retry_after(headers: PackedStringArray) -> float:
	for header in headers:
		if header.to_lower().begins_with("retry-after:"):
			return maxf(1.0, float(header.get_slice(":", 1).strip_edges()))
	return 5.0


## Journal technique : méthode, chemin et code, jamais de jeton, de mot de passe ni de code.
func _failure(path: String, method: HTTPClient.Method, status: int, kind: String, message: String) -> Dictionary:
	const METHODS := {
		HTTPClient.METHOD_GET: "GET", HTTPClient.METHOD_POST: "POST",
		HTTPClient.METHOD_PATCH: "PATCH", HTTPClient.METHOD_DELETE: "DELETE",
	}
	push_warning("[API] %s %s : %s %s" % [METHODS.get(method, "?"), path, kind, str(status) if status else ""])
	return {"ok": false, "status": status, "data": null, "error": message, "kind": kind}


## Le serveur n'a pas répondu, ou il est saturé : la même requête pourra être retentée.
static func is_transient(result: Dictionary) -> bool:
	var status: int = result.get("status", 0)
	return status == 0 or status == 429 or status == 502 or status == 503 or status == 504
