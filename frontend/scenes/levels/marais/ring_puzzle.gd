class_name RingPuzzle
extends CanvasLayer
## Vue rapprochée du mécanisme aux cinq cercles : chaque cercle pivote vers la gauche ou la droite,
## puis « Valider » vérifie les cinq lettres alignées sous le repère.

signal validated(correct: bool)
signal closed

const SOLUTION := "FLGFD"
const COLOR_IDLE := Color(0.5, 0.75, 0.6)
const COLOR_WRONG := Color(0.95, 0.15, 0.1)

var _mechanism: RingMechanism
var _labels: Array[Label] = []
var _flash: Tween

@onready var _root: Control = %Root
@onready var _panel: PanelContainer = %Panel
@onready var _rows: VBoxContainer = %Rows
@onready var _feedback: Label = %Feedback
@onready var _validate: Button = %Validate
@onready var _close: Button = %Close


func _ready() -> void:
	_root.hide()
	_validate.pressed.connect(validate)
	_close.pressed.connect(_on_close_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if _root.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()


func is_open() -> bool:
	return _root.visible


func open(mechanism: RingMechanism) -> void:
	_mechanism = mechanism
	_feedback.text = ""
	_set_border(COLOR_IDLE)
	_build_rows()
	_root.show()


func turn(ring: int, step: int) -> void:
	_mechanism.rotate_ring(ring, step)
	_labels[ring].text = RingMechanism.LETTERS[_mechanism.letters[ring]]


func validate() -> void:
	var correct := _mechanism.code() == SOLUTION
	if correct:
		_root.hide()
	else:
		_feedback.text = "Les inscriptions s'illuminent de rouge et un bruit sourd résonne : le mécanisme rejette cette combinaison."
		_flash_wrong()
	validated.emit(correct)


func _build_rows() -> void:
	for child in _rows.get_children():
		child.queue_free()
	_labels.clear()
	for ring in RingMechanism.RING_COUNT:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 24)
		var name := Label.new()
		name.text = "Cercle %d" % (ring + 1)
		name.custom_minimum_size = Vector2(180, 0)
		name.add_theme_font_size_override("font_size", 28)
		row.add_child(name)
		var left := _arrow(Vector2.LEFT)
		left.pressed.connect(turn.bind(ring, -1))
		row.add_child(left)
		var letter := Label.new()
		letter.text = RingMechanism.LETTERS[_mechanism.letters[ring]]
		letter.custom_minimum_size = Vector2(80, 0)
		letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letter.add_theme_font_size_override("font_size", 44)
		letter.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
		row.add_child(letter)
		_labels.append(letter)
		var right := _arrow(Vector2.RIGHT)
		right.pressed.connect(turn.bind(ring, 1))
		row.add_child(right)
		_rows.add_child(row)


## Bouton fléché : l'icône est dessinée, la police n'a pas de flèches.
func _arrow(direction: Vector2) -> Button:
	var button := Button.new()
	button.icon = UiIcons.arrow(direction, 28)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.custom_minimum_size = Vector2(72, 60)
	return button


func _set_border(color: Color) -> void:
	(_panel.get_theme_stylebox("panel") as StyleBoxFlat).border_color = color


func _flash_wrong() -> void:
	if _flash:
		_flash.kill()
	_set_border(COLOR_WRONG)
	_flash = create_tween()
	_flash.tween_interval(1.2)
	_flash.tween_callback(_set_border.bind(COLOR_IDLE))


func _on_close_pressed() -> void:
	_root.hide()
	closed.emit()
