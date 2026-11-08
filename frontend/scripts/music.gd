extends Node
## Musique du jeu : un seul lecteur, commun à toutes les scènes, qui joue sur le bus « Music ». Il passe d'une piste à
## l'autre par un fondu enchaîné, et ne relance jamais la piste déjà en cours : d'un lieu au même lieu, d'une porte du
## bunker à l'autre, la musique continue.
##
## Le menu principal et les quatre lieux ont chacun leur piste, choisie ici à chaque changement de scène. Le hub choisit
## la sienne (hub.gd) : l'introduction au bunker, le village, puis la victoire, de la bonne fin jusqu'à l'épilogue, et la
## défaite pendant l'éruption, jouée une seule fois, sans autre musique jusqu'au retour au menu.
##
## Sur le web, le navigateur bloque le son jusqu'au premier geste du joueur : la piste demandée attend le premier clic,
## la première touche ou le premier toucher pour partir, en fondu.
##
## Sur le web encore, le paquet du jeu (index.pck) ne contient que les pistes du menu, de l'introduction et du hub : les
## autres (lieux, victoire, défaite) sont dans un second paquet, musique.pck (préréglage d'export « Web musique »),
## téléchargé en arrière-plan une fois le menu affiché, puis monté. Une piste demandée avant qu'il soit là attend en
## silence, et part dès qu'il est monté. Un téléchargement raté est retenté, de plus en plus espacé ; le jeu reste
## jouable sans ces pistes. Le jeu natif a toutes ses pistes dans son paquet et ne télécharge rien.
## Voir docs/musique-differee.md.

## Émis quand le second paquet de musique est monté.
signal pack_loaded

const DIR := "res://assets/audio/music/"
## Gain propre à chaque piste, en dB : il ramène les pistes à un même niveau moyen (RMS d'environ -22 dBFS, -18 pour le
## menu, où rien d'autre ne joue). Les fichiers bouclent à l'import, sauf la défaite.
const TRACKS := {
	&"menu": -4.0,
	&"intro": 6.0,
	&"hub": 6.0,
	&"plaine": -7.0,
	&"desert": -4.0,
	&"marais": -1.0,
	&"village": -10.0,
	&"victoire": -9.0,
	&"defaite": -5.0,
}
const BUS := &"Music"
## Volume du bus : la musique reste sous l'ambiance des lieux (vent, marais, foule, autour de -29 dBFS) et sous les
## effets (pas, feu, mécanismes).
const BUS_VOLUME_DB := -10.0
## Durée du fondu enchaîné, en secondes.
const FADE := 1.5
## Second paquet de musique du web, à côté de index.html.
const PACK_FILE := "musique.pck"
## Attente avant chaque nouvelle tentative de téléchargement, en secondes ; la dernière se répète.
const PACK_RETRY := [5.0, 15.0, 30.0, 60.0]
## Un téléchargement qui ne reçoit plus rien pendant ce temps (secondes de jeu) est abandonné, puis retenté.
const PACK_STALL := 60.0

var _players: Array[AudioStreamPlayer] = []
var _active: AudioStreamPlayer
var _track: StringName = &""
var _tweens := {}
## Faux sur le web jusqu'au premier geste du joueur : la piste demandée est mise de côté jusque-là.
var _unlocked := true
## Fichiers de pistes dont le chargement en arrière-plan est demandé (prefetch), pas encore repris.
var _pending := {}
## Dossier des pistes. music_test le change pour simuler des pistes absentes du paquet du jeu.
var dir := DIR
var _http: HTTPRequest
var _pack_started := false
var _pack_url := ""
var _pack_path := ""
var _pack_tries := 0
var _pack_loaded := false
var _pack_bytes := 0
var _pack_idle := 0.0


func _ready() -> void:
	# La musique continue pendant les transitions et le menu de pause, qui mettent l'arbre en pause.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus()
	for index in 2:
		var player := AudioStreamPlayer.new()
		player.name = "Piste%d" % (index + 1)
		player.bus = BUS
		# Lecture par le mélangeur de Godot. En mode « sample », celui du web par défaut, chaque piste serait décodée
		# en entier au premier lancement : plus de 300 Mo de mémoire pour les sept minutes de la Plaine. L'export web a
		# des fils d'exécution : ce mélangeur y tourne sur son propre fil, une image lente ne coupe plus la musique
		# (docs/web-threads.md). Sans fils (repli, GitHub Pages), il tourne sur le fil principal, et project.godot
		# allonge sa réserve (audio/driver/output_latency.web, 200 ms). Les effets, en mode « sample », n'en dépendent pas.
		player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		player.volume_linear = 0.0
		add_child(player)
		_players.append(player)
	_active = _players[0]
	_unlocked = not OS.has_feature("web")
	set_process_input(not _unlocked)
	set_process(false)
	get_tree().scene_changed.connect(_on_scene_changed)
	GameState.erupted.connect(stop)
	_on_scene_changed.call_deferred()


## Joue la piste (clé de TRACKS) en fondu enchaîné avec la précédente. Rien ne change si elle est déjà en cours, ou si
## elle vient de finir (la défaite ne joue qu'une fois).
func play(track: StringName) -> void:
	if track == _track:
		return
	if not TRACKS.has(track):
		push_error("Musique inconnue : %s" % track)
		return
	_track = track
	_fade(_active, 0.0, true)
	_active = _players[1] if _active == _players[0] else _players[0]
	_active.stream = _load_track(track)
	_start()


## Charge en arrière-plan la piste de la scène qui va s'ouvrir : Transition l'appelle sous le titre, en même temps
## qu'elle charge la scène, et play() la trouve prête au lieu de bloquer l'image où le lieu apparaît. Sans fil
## d'exécution (web sans threads), elle se charge sur place, sous le noir de la transition.
func prefetch(scene_path: String) -> void:
	var track := _track_for(scene_path)
	if track == &"" or track == _track:
		return
	var path := _path(track)
	if _pending.has(path) or ResourceLoader.has_cached(path) or not ResourceLoader.exists(path):
		return
	if ResourceLoader.load_threaded_request(path) == OK:
		_pending[path] = true


## Piste préchargée si elle l'a été (attendue si elle se charge encore), sinon chargée sur place. Les autres pistes
## préchargées et déjà prêtes sont lâchées : le hub a pu en choisir une autre que celle prévue. Rien (null) si la piste
## est dans le second paquet de musique, pas encore monté : elle attend load_pack.
func _load_track(track: StringName) -> AudioStream:
	var path := _path(track)
	var stream: AudioStream = null
	if _pending.has(path):
		_pending.erase(path)
		stream = ResourceLoader.load_threaded_get(path) as AudioStream
	for other: String in _pending.keys():
		if ResourceLoader.load_threaded_get_status(other) != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			ResourceLoader.load_threaded_get(other)
			_pending.erase(other)
	if stream:
		return stream
	return load(path) if ResourceLoader.exists(path) else null


func _path(track: StringName) -> String:
	return dir + String(track) + ".ogg"


## Coupe la musique en fondu (éruption) : rien ne joue jusqu'à la piste suivante.
func stop() -> void:
	_track = &""
	_fade(_active, 0.0, true)


## Piste demandée en dernier, même si elle attend le premier geste du joueur ou si elle est finie ; rien après stop().
func current_track() -> StringName:
	return _track


## Vrai si la piste demandée joue vraiment (lancée, pas encore finie).
func is_playing() -> bool:
	return _track != &"" and _active.playing


## Vrai si la piste demandée attend le second paquet de musique.
func is_waiting_for_pack() -> bool:
	return _track != &"" and _active.stream == null


## Vrai une fois le second paquet de musique monté.
func is_pack_loaded() -> bool:
	return _pack_loaded


## Nombre de téléchargements du second paquet ratés jusqu'ici.
func pack_failures() -> int:
	return _pack_tries


## Lecteur de la piste en cours, pour les tests.
func active_player() -> AudioStreamPlayer:
	return _active


func _start() -> void:
	if not _unlocked or _active.stream == null:
		return
	_active.volume_linear = 0.0
	_active.play()
	_fade(_active, db_to_linear(TRACKS[_track]))


func _fade(player: AudioStreamPlayer, volume: float, stop_after := false) -> void:
	var previous: Tween = _tweens.get(player)
	if previous and previous.is_valid():
		previous.kill()
	if not player.playing:
		if stop_after:
			player.stop()
		return
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(player, "volume_linear", volume, FADE).set_trans(Tween.TRANS_SINE)
	if stop_after:
		tween.tween_callback(player.stop)
	_tweens[player] = tween


## Le menu principal et chaque lieu (piste du même nom que la zone) ont leur piste ; le hub choisit la sienne.
func _on_scene_changed() -> void:
	if not _pack_started and OS.has_feature("web"):
		_pack_started = true
		_fetch_web_pack()
	var scene := get_tree().current_scene
	if not scene or scene.scene_file_path == GameState.HUB_SCENE:
		return
	var track := _track_for(scene.scene_file_path)
	if track != &"":
		play(track)


## Piste qu'aura la scène : celle du menu, du lieu, ou pour le hub celle qu'il choisit le plus souvent (hub.gd).
func _track_for(scene_path: String) -> StringName:
	if scene_path == MainMenu.SCENE:
		return &"menu"
	if scene_path == GameState.HUB_SCENE:
		return &"hub" if GameState.intro_done else &"intro"
	for zone: StringName in GameState.ZONE_SCENES:
		if GameState.ZONE_SCENES[zone] == scene_path:
			return zone
	return &""


## Premier geste du joueur sur le web : le navigateur rouvre le son (Godot reprend son contexte audio à chaque clic ou
## touche), la piste en attente part. Échap ne compte pas comme un geste pour le navigateur : on attend le suivant.
func _input(event: InputEvent) -> void:
	if _unlocked:
		return
	var gesture := (event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventKey) \
		and event.is_pressed() and not event.is_echo()
	if not gesture:
		return
	var active: Variant = JavaScriptBridge.eval("!navigator.userActivation || navigator.userActivation.hasBeenActive", true)
	if active != null and not bool(active):
		return
	_unlocked = true
	set_process_input(false)
	if _track != &"":
		_start()


## Sur le web, une fois la première scène (le menu) affichée : télécharge le second paquet de musique, à côté de la
## page, si des pistes manquent au paquet du jeu.
func _fetch_web_pack() -> void:
	if _missing_tracks().is_empty():
		return
	for frame in 2:
		await get_tree().process_frame
	var url: Variant = JavaScriptBridge.eval("new URL('%s', document.baseURI).href" % PACK_FILE, true)
	if url is String and not String(url).is_empty():
		fetch_pack(url)


## Télécharge le second paquet de musique depuis url, puis le monte (load_pack). En cas d'échec, nouvelle tentative
## plus tard (PACK_RETRY). Le web l'appelle seul ; music_test, avec une adresse morte.
##
## Le paquet est écrit dans le dossier de cache, pas dans user:// : sur le web, seul user:// (/userfs) est recopié
## dans IndexedDB. Le cache (/home/web_user/.cache) y reste en mémoire (MEMFS), comme index.pck. Dans user://, ses
## 10 Mo seraient recopiés dans IndexedDB à chaque téléchargement, et relus en entier à chaque lancement, avant le
## menu. Le navigateur garde de toute façon sa copie (cache HTTP, revalidée par ETag) : la visite suivante ne le
## retélécharge que s'il a changé.
func fetch_pack(url: String) -> void:
	_pack_url = url
	if not _http:
		_http = HTTPRequest.new()
		_http.name = "PaquetMusique"
		# Le navigateur décode déjà la réponse (brotli, gzip) : avec accept_gzip, HTTPRequest décoderait une seconde fois
		# un corps marqué gzip, et échouerait.
		_http.accept_gzip = false
		# Jusqu'à 1 Mo lu par image (64 Ko par défaut) : le téléchargement suit le réseau, même à faible cadence.
		_http.download_chunk_size = 1 << 20
		# Le corps arrive en mémoire, et _on_pack_downloaded l'écrit : pas de download_file. Sur le web, la réponse n'a
		# jamais de longueur connue, et HTTPRequest efface alors le fichier reçu juste avant de signaler la fin (Godot
		# 4.7, scene/main/http_request.cpp : download_complete n'est posé que si la longueur est connue).
		_http.request_completed.connect(_on_pack_downloaded)
		add_child(_http)
	# Hors du web (tests seulement), dans user://.
	var folder := OS.get_cache_dir() if OS.has_feature("web") else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(folder)
	_pack_path = folder.path_join(PACK_FILE)
	_pack_bytes = 0
	_pack_idle = 0.0
	if _http.request(url) == OK:
		set_process(true)
	else:
		_retry_pack()


## Monte un paquet de musique, sans remplacer aucun fichier du jeu, puis lance la piste qui l'attendait.
func load_pack(path: String) -> bool:
	if not ProjectSettings.load_resource_pack(path, false):
		push_warning("Musique : paquet %s illisible" % path)
		return false
	_pack_loaded = true
	var missing := _missing_tracks()
	if not missing.is_empty():
		push_warning("Musique : pistes absentes du paquet %s : %s" % [path, missing])
	if is_waiting_for_pack():
		_active.stream = _load_track(_track)
		_start()
	pack_loaded.emit()
	return true


func _on_pack_downloaded(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	set_process(false)
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		push_warning("Musique : %s non reçu (résultat %d, code HTTP %d)" % [_pack_url, result, code])
		_retry_pack()
		return
	var file := FileAccess.open(_pack_path, FileAccess.WRITE)
	if not file:
		push_warning("Musique : impossible d'écrire %s (%s)" % [_pack_path, error_string(FileAccess.get_open_error())])
		_retry_pack()
		return
	file.store_buffer(body)
	var written := file.get_error() == OK
	file.close()
	if not written or not load_pack(_pack_path):
		_retry_pack()


func _retry_pack() -> void:
	set_process(false)
	_pack_tries += 1
	var delay: float = PACK_RETRY[mini(_pack_tries, PACK_RETRY.size()) - 1]
	push_warning("Musique : nouvelle tentative dans %d s" % delay)
	get_tree().create_timer(delay, true).timeout.connect(fetch_pack.bind(_pack_url))


## Surveille le téléchargement en cours : sans un octet reçu pendant PACK_STALL secondes, il est relancé. Une image
## compte au plus une demi-seconde : le chargement d'un lieu, qui bloque l'image, ne passe pas pour un blocage.
func _process(delta: float) -> void:
	var bytes := _http.get_downloaded_bytes()
	if bytes != _pack_bytes:
		_pack_bytes = bytes
		_pack_idle = 0.0
		return
	_pack_idle += minf(delta, 0.5)
	if _pack_idle >= PACK_STALL:
		push_warning("Musique : %s ne reçoit plus rien" % _pack_url)
		_http.cancel_request()
		_retry_pack()


func _missing_tracks() -> Array[StringName]:
	var missing: Array[StringName] = []
	for track: StringName in TRACKS:
		if not ResourceLoader.exists(_path(track)):
			missing.append(track)
	return missing


## Le bus « Music » est créé ici s'il n'existe pas : le projet n'a pas de disposition de bus enregistrée.
func _ensure_bus() -> void:
	if AudioServer.get_bus_index(BUS) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, BUS)
	AudioServer.set_bus_send(index, &"Master")
	AudioServer.set_bus_volume_db(index, BUS_VOLUME_DB)
