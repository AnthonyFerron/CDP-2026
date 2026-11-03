class_name Hud
extends CanvasLayer
## Interface de jeu : invite d'interaction, messages, lecture de textes, fondu au noir,
## chronomètre du volcan, pénalités et écran de fin quand le volcan entre en éruption.

signal reader_closed

@export var message_duration := 4.0
@export var fade_duration := 0.35
## Sous ce temps restant, en secondes, le chronomètre passe au rouge.
@export var warning_time := 5.0 * 60.0

var _message_tween: Tween
var _penalty_tween: Tween

@onready var _prompt: Label = %Prompt
@onready var _message: Label = %Message
@onready var _reader: Control = %Reader
@onready var _reader_title: Label = %ReaderTitle
@onready var _reader_body: Label = %ReaderBody
@onready var _fade: ColorRect = %Fade
@onready var _crosshair: ColorRect = %Crosshair
@onready var _timer: Label = %Timer
@onready var _penalty: Label = %Penalty
@onready var _game_over: Control = %GameOver


func _ready() -> void:
	set_prompt("")
	_message.hide()
	_reader.hide()
	_penalty.hide()
	_game_over.hide()
	_fade.modulate.a = 0.0
	GameState.time_penalized.connect(_on_time_penalized)
	GameState.erupted.connect(_on_erupted)
	%Restart.pressed.connect(_on_restart_pressed)
	_refresh_timer()
	if GameState.has_erupted:
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


func _on_time_penalized(seconds: float) -> void:
	_penalty.text = "−%d:%02d" % [int(seconds) / 60, int(seconds) % 60]
	_penalty.modulate.a = 1.0
	_penalty.show()
	if _penalty_tween:
		_penalty_tween.kill()
	_penalty_tween = create_tween()
	_penalty_tween.tween_interval(1.5)
	_penalty_tween.tween_property(_penalty, "modulate:a", 0.0, 0.8)
	_penalty_tween.tween_callback(_penalty.hide)


func _on_erupted() -> void:
	_game_over.show()
	_crosshair.hide()
	set_prompt("")
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_restart_pressed() -> void:
	GameState.reset()
	get_tree().paused = false
	get_tree().change_scene_to_file(GameState.HUB_SCENE)
