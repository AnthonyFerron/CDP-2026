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

var _players: Array[AudioStreamPlayer] = []
var _active: AudioStreamPlayer
var _track: StringName = &""
var _tweens := {}
## Faux sur le web jusqu'au premier geste du joueur : la piste demandée est mise de côté jusque-là.
var _unlocked := true
## Fichiers de pistes dont le chargement en arrière-plan est demandé (prefetch), pas encore repris.
var _pending := {}


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
	var path := DIR + String(track) + ".ogg"
	if _pending.has(path) or ResourceLoader.has_cached(path):
		return
	if ResourceLoader.load_threaded_request(path) == OK:
		_pending[path] = true


## Piste préchargée si elle l'a été (attendue si elle se charge encore), sinon chargée sur place. Les autres pistes
## préchargées et déjà prêtes sont lâchées : le hub a pu en choisir une autre que celle prévue.
func _load_track(track: StringName) -> AudioStream:
	var path := DIR + String(track) + ".ogg"
	var stream: AudioStream = null
	if _pending.has(path):
		_pending.erase(path)
		stream = ResourceLoader.load_threaded_get(path) as AudioStream
	for other: String in _pending.keys():
		if ResourceLoader.load_threaded_get_status(other) != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			ResourceLoader.load_threaded_get(other)
			_pending.erase(other)
	return stream if stream else load(path)


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


## Lecteur de la piste en cours, pour les tests.
func active_player() -> AudioStreamPlayer:
	return _active


func _start() -> void:
	if not _unlocked:
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


## Le bus « Music » est créé ici s'il n'existe pas : le projet n'a pas de disposition de bus enregistrée.
func _ensure_bus() -> void:
	if AudioServer.get_bus_index(BUS) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, BUS)
	AudioServer.set_bus_send(index, &"Master")
	AudioServer.set_bus_volume_db(index, BUS_VOLUME_DB)
