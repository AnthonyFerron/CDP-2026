class_name Hud
extends CanvasLayer
## Interface de jeu : invite d'interaction, messages, lecture de textes et fondu au noir.

signal reader_closed

@export var message_duration := 4.0
@export var fade_duration := 0.35

var _message_tween: Tween

@onready var _prompt: Label = %Prompt
@onready var _message: Label = %Message
@onready var _reader: Control = %Reader
@onready var _reader_title: Label = %ReaderTitle
@onready var _reader_body: Label = %ReaderBody
@onready var _fade: ColorRect = %Fade


func _ready() -> void:
	set_prompt("")
	_message.hide()
	_reader.hide()
	_fade.modulate.a = 0.0


func _unhandled_input(event: InputEvent) -> void:
	if not _reader.visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_reader.hide()
		reader_closed.emit()


func set_prompt(text: String) -> void:
	_prompt.text = "[E] %s" % text
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


func fade(to_black: bool) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 1.0 if to_black else 0.0, fade_duration)
	await tween.finished
