extends Node
## Sons de l'interface (autoload UiSounds), dans l'esprit médiéval des menus : un petit coup de bois au clic d'un
## bouton, un parchemin qui se déroule et une clochette à l'ouverture d'un panneau, le parchemin replié et un coup
## sourd à sa fermeture. Ils jouent sur le bus « Interface », à part de la musique et des bruits des lieux.
##
## Le clic vaut pour tous les boutons du jeu (menu d'accueil, pause, indices, énigmes) sans rien leur ajouter : au
## clic de la souris, le contrôle survolé est-il un bouton actif ? Les panneaux se déclarent avec watch(), qui suit leur
## affichage : chaque façon de les ouvrir ou de les fermer (bouton, touche, réussite, fin de partie) a son son. Le
## lecteur de textes du HUD est suivi depuis ici, à chaque changement de scène. Voir docs/sons.md.

const BUS := &"Interface"
## Volume du bus : les sons d'interface restent sous les effets des lieux (pas, mécanismes) et ne couvrent pas la
## musique (bus « Music », -10 dB).
const BUS_VOLUME_DB := -8.0
const CLICK: AudioStream = preload("res://assets/audio/ui_click.wav")
const OPEN: AudioStream = preload("res://assets/audio/ui_open.wav")
const CLOSE: AudioStream = preload("res://assets/audio/ui_close.wav")
## Volume propre à chaque son, en dB.
const VOLUMES := {CLICK: -1.0, OPEN: -4.0, CLOSE: -4.0}
## Deux sons du même genre à moins de cet intervalle, en secondes, n'en font qu'un (double clic, panneau rouvert
## aussitôt fermé).
const REPEAT := 0.06

## Nombre de sons joués de chaque genre (clic, ouverture, fermeture), pour les tests.
var played := {&"click": 0, &"open": 0, &"close": 0}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _last := {}


func _ready() -> void:
	# Les panneaux s'ouvrent pendant la pause (menu pause, indices) : les sons jouent quand même.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus()
	# Trois lecteurs à tour de rôle : un clic qui ferme un panneau laisse finir l'un et l'autre.
	for index in 3:
		var player := AudioStreamPlayer.new()
		player.name = "Son%d" % (index + 1)
		player.bus = BUS
		add_child(player)
		_players.append(player)
	get_tree().scene_changed.connect(_on_scene_changed)


func _input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if not button or not button.pressed or button.button_index != MOUSE_BUTTON_LEFT:
		return
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return
	var hovered := get_viewport().gui_get_hovered_control()
	# Le survol peut tomber sur un enfant du bouton (texte, icône) qui laisse passer la souris.
	for _depth in 3:
		if not hovered or hovered is BaseButton:
			break
		hovered = hovered.get_parent() as Control
	var target := hovered as BaseButton
	if target and not target.disabled and target.is_visible_in_tree():
		click()


func click() -> void:
	_play(CLICK, &"click", randf_range(0.96, 1.04))


func open_panel() -> void:
	_play(OPEN, &"open")


func close_panel() -> void:
	_play(CLOSE, &"close")


## Suit l'affichage d'un panneau : il sonne quand il apparaît et quand il disparaît, par lui-même ou avec son calque.
## À appeler une fois le panneau caché, à sa construction.
func watch(panel: CanvasItem) -> void:
	panel.visibility_changed.connect(_on_panel_visibility.bind(panel))


func _on_panel_visibility(panel: CanvasItem) -> void:
	if not panel.is_inside_tree() or panel.is_queued_for_deletion():
		return
	if panel.is_visible_in_tree():
		open_panel()
	else:
		close_panel()


## Lecteur de textes du HUD (scenes/ui/hud.tscn, nœud unique Reader) : suivi à l'arrivée de chaque scène qui a un HUD.
func _on_scene_changed() -> void:
	var scene := get_tree().current_scene
	var hud := scene.get_node_or_null(^"Hud") if scene else null
	var reader := hud.get_node_or_null(^"%Reader") as CanvasItem if hud else null
	if reader and not reader.visibility_changed.is_connected(_on_panel_visibility):
		watch(reader)


func _play(stream: AudioStream, kind: StringName, pitch := 1.0) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last.get(kind, -1.0)) < REPEAT:
		return
	_last[kind] = now
	played[kind] += 1
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = stream
	player.volume_db = VOLUMES[stream]
	player.pitch_scale = pitch
	player.play()


## Le bus « Interface » est créé ici, comme « Music » (scripts/music.gd) : le projet n'a pas de disposition de bus.
func _ensure_bus() -> void:
	if AudioServer.get_bus_index(BUS) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, BUS)
	AudioServer.set_bus_send(index, &"Master")
	AudioServer.set_bus_volume_db(index, BUS_VOLUME_DB)
