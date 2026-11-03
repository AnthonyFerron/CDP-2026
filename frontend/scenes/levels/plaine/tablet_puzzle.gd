class_name TabletPuzzle
extends CanvasLayer
## Énigme de la tablette : remettre les phases d'un projet dans le bon ordre.

signal solved
signal closed

const PHASES: Array[String] = ["Cadrage", "Planification", "Réalisation", "Suivi", "Clôture"]

var _attempt: Array[String] = []

@onready var _root: Control = %Root
@onready var _buttons: Container = %Buttons
@onready var _sequence: Label = %Sequence
@onready var _feedback: Label = %Feedback
@onready var _close: Button = %Close


func _ready() -> void:
	_root.hide()
	_close.pressed.connect(_on_close_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if _root.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()


func open() -> void:
	_feedback.text = ""
	_reset()
	_root.show()


func _reset() -> void:
	_attempt.clear()
	_refresh_sequence()
	for child in _buttons.get_children():
		child.queue_free()
	var shuffled := PHASES.duplicate()
	shuffled.shuffle()
	for phase in shuffled:
		var button := Button.new()
		button.text = phase
		button.custom_minimum_size = Vector2(0, 66)
		button.add_theme_font_size_override("font_size", 30)
		button.pressed.connect(_on_phase_pressed.bind(button))
		_buttons.add_child(button)


func _on_phase_pressed(button: Button) -> void:
	button.disabled = true
	_attempt.append(button.text)
	_refresh_sequence()
	if _attempt.size() == PHASES.size():
		_check_attempt()


func _check_attempt() -> void:
	if _attempt == PHASES:
		_root.hide()
		solved.emit()
	else:
		_feedback.text = "La tablette s'éteint : l'ordre est faux."
		_reset()


func _refresh_sequence() -> void:
	var slots: Array[String] = []
	for index in PHASES.size():
		slots.append(_attempt[index] if index < _attempt.size() else "…")
	_sequence.text = "  >  ".join(slots)


func _on_close_pressed() -> void:
	_root.hide()
	closed.emit()
