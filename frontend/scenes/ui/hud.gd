class_name Hud
extends CanvasLayer
## Interface de jeu : invite d'interaction, messages, lecture de textes, fondu au noir,
## chronomètre du volcan et pénalités. Quand le volcan entre en éruption, le joueur est ramené au hub, où se joue
## la seule fin d'une partie perdue : la cinématique du Mont Sam Altan qui explose (HubEnding).

signal reader_closed

@export var message_duration := 4.0
@export var fade_duration := 0.35
## Sous ce temps restant, en secondes, le chronomètre passe au rouge.
@export var warning_time := 5.0 * 60.0

## Place du bandeau « Mauvaise réponse », en coordonnées de référence (1920 × 1080). En haut par défaut, sur le titre
## des panneaux d'énigme : il ne cache ni le cadran ni les boutons du Marais, ni les runes du Désert, ni la tablette
## de la Plaine. Le dispositif du Village, dont le cadre s'arrête au-dessus de y = 770, l'appelle en bas pendant
## qu'il est ouvert, puis le remet en haut.
const WARNING_TOP := Vector2(460, 14)
const WARNING_BOTTOM := Vector2(460, 770)
const WARNING_SIZE := Vector2(1000, 124)
static var warning_position := WARNING_TOP

var _message_tween: Tween
var _warning_tween: Tween
## Avertissement d'une mauvaise réponse, au-dessus des panneaux d'énigme.
var _warning: Control
var _warning_text: Label

@onready var _prompt: Label = %Prompt
@onready var _message: Label = %Message
@onready var _reader: Control = %Reader
@onready var _reader_title: Label = %ReaderTitle
@onready var _reader_body: Label = %ReaderBody
@onready var _fade: ColorRect = %Fade
@onready var _crosshair: ColorRect = %Crosshair
@onready var _timer: Label = %Timer
@onready var _penalty: Label = %Penalty


func _ready() -> void:
	warning_position = WARNING_TOP
	set_prompt("")
	_message.hide()
	_reader.hide()
	_penalty.hide()
	_fade.modulate.a = 0.0
	GameState.time_penalized.connect(_on_time_penalized)
	_build_warning()
	GameState.erupted.connect(_on_erupted)
	# Avis de la synchronisation avec le serveur : connexion perdue ou rétablie, refus.
	GameSync.notice.connect(show_message)
	_refresh_timer()
	# Partie perdue pendant un changement de lieu : la fin suit dès l'arrivée. Le hub la joue lui-même.
	if GameState.has_erupted and not get_parent() is Hub:
		_on_erupted.call_deferred()


func _process(_delta: float) -> void:
	_refresh_timer()


func _unhandled_input(event: InputEvent) -> void:
	if not _reader.visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_reader.hide()
		_crosshair.show()
		reader_closed.emit()


func set_prompt(text: String) -> void:
	_prompt.text = "[E] %s" % text
	_prompt.visible = not text.is_empty()


## Invite affichée telle quelle, sans touche devant : pour « Maintenir E… » par exemple.
func set_raw_prompt(text: String) -> void:
	_prompt.text = text
	_prompt.visible = not text.is_empty()


func show_message(text: String) -> void:
	if _message_tween:
		_message_tween.kill()
	_message.text = text
	_message.modulate.a = 1.0
	_message.show()
	_message_tween = create_tween()
	_message_tween.tween_interval(message_duration)
	_message_tween.tween_property(_message, "modulate:a", 0.0, 0.6)
	_message_tween.tween_callback(_message.hide)


func show_text(title: String, body: String) -> void:
	_reader_title.text = title
	_reader_body.text = body
	_reader.show()
	_crosshair.hide()


func set_crosshair_visible(value: bool) -> void:
	_crosshair.visible = value


func fade(to_black: bool) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 1.0 if to_black else 0.0, fade_duration)
	await tween.finished


func _refresh_timer() -> void:
	var remaining := int(ceil(GameState.time_left))
	_timer.text = "Éruption du volcan : %d:%02d" % [remaining / 60, remaining % 60]
	_timer.visible = GameState.placed_books.size() < GameState.BOOK_COUNT
	_timer.modulate = Color(1.0, 0.35, 0.25) if GameState.time_left < warning_time else Color.WHITE


## Bandeau « Mauvaise réponse » : une couche à part, au-dessus des panneaux d'énigme où la réponse est validée,
## et sous le menu pause.
func _build_warning() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Warning"
	layer.layer = 35
	add_child(layer)
	_warning = Ornate.Frame.new()
	_warning.name = "Banner"
	_warning.bottom_diamond = false
	_warning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Ornate.place(layer, _warning, WARNING_TOP, WARNING_SIZE)
	var title := Ornate.label("Mauvaise réponse", 40, Color(1.0, 0.45, 0.3), true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ornate.place(_warning, title, Vector2(0, 10), Vector2(WARNING_SIZE.x, 56))
	_warning_text = Ornate.label("", 25)
	_warning_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_warning_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Ornate.place(_warning, _warning_text, Vector2(40, 66), Vector2(WARNING_SIZE.x - 80, 44))
	# Le « −5:00 » rejoint le bandeau, à droite du titre : sous le chronomètre, il chevauchait le haut des panneaux
	# d'énigme et la croix de fermeture de la tablette.
	_penalty.reparent(_warning, false)
	_penalty.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_penalty.position = Vector2(WARNING_SIZE.x - 240, 10)
	_penalty.size = Vector2(200, 56)
	_warning.modulate.a = 0.0
	_warning.hide()


func show_penalty_warning(seconds: float) -> void:
	var minutes := int(round(seconds / 60.0))
	var remaining := int(ceil(GameState.time_left))
	_warning_text.text = "Le Mont Sam Altan gronde : %d minute%s perdue%s, il reste %d:%02d." % [
		minutes, "s" if minutes > 1 else "", "s" if minutes > 1 else "", remaining / 60, remaining % 60]
	_warning.position = warning_position
	_warning.show()
	if _warning_tween:
		_warning_tween.kill()
	_warning_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_warning_tween.tween_property(_warning, "modulate:a", 1.0, 0.2)
	_warning_tween.tween_interval(3.5)
	_warning_tween.tween_property(_warning, "modulate:a", 0.0, 0.6)
	_warning_tween.tween_callback(_warning.hide)


func _on_time_penalized(seconds: float) -> void:
	if not GameState.has_erupted:
		show_penalty_warning(seconds)
	# Le « −5:00 » est dans le bandeau : il apparaît et s'efface avec lui.
	_penalty.text = "−%d:%02d" % [int(seconds) / 60, int(seconds) % 60]
	_penalty.modulate.a = 1.0
	_penalty.show()


## Le chronomètre est à zéro, dans un lieu comme au hub : retour au hub, qui joue l'éruption du volcan. Une transition
## déjà en cours ignore celle-ci ; le HUD du lieu d'arrivée la relance (_ready).
func _on_erupted() -> void:
	_close_panels()
	_crosshair.hide()
	set_prompt("")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Transition.change_scene(GameState.HUB_SCENE)


## Partie perdue : tout ce qui est ouvert se ferme avant la fin, quel que soit le lieu. Les panneaux d'énigme et le
## carnet sont des CanvasLayer du niveau (tablette, runes, cercles, dispositif des codes…) ; s'y ajoutent le texte en
## lecture, le bandeau « Mauvaise réponse » et l'indice. Le joueur ne reprend pas la main : la fin suit.
func _close_panels() -> void:
	_reader.hide()
	_message.hide()
	if _warning_tween:
		_warning_tween.kill()
	_warning.hide()
	for layer: CanvasLayer in get_parent().find_children("*", "CanvasLayer", true, false):
		if layer != self and not is_ancestor_of(layer):
			layer.hide()
	if Hints.is_open():
		Hints.close()
