class_name TabletPuzzle
extends CanvasLayer
## Tablette de la conversation oubliée : six emplacements où replacer les fragments retrouvés.
## On choisit un fragment, puis l'emplacement où le poser ; cliquer un emplacement rempli le libère.
## « Valider » ne s'active qu'une fois les six emplacements remplis, pour éviter une fausse erreur.

signal validated(correct: bool)
signal closed

const SLOT_COUNT := 6
const COLOR_IDLE := Color(0.85, 0.3, 0.1)
const COLOR_WRONG := Color(0.95, 0.12, 0.08)

## Fragments retrouvés : numéro vers texte.
var _fragments := {}
## Fragment posé dans chaque emplacement, ou -1.
var _slots: Array[int] = []
var _selected := -1
var _flash: Tween

@onready var _root: Control = %Root
@onready var _panel: PanelContainer = %Panel
@onready var _slot_list: VBoxContainer = %Slots
@onready var _pool: VBoxContainer = %Pool
@onready var _feedback: Label = %Feedback
@onready var _validate: Button = %Validate
@onready var _close: Button = %Close


func _ready() -> void:
	_slots.resize(SLOT_COUNT)
	_slots.fill(-1)
	_root.hide()
	_validate.pressed.connect(validate)
	_close.pressed.connect(_on_close_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if _root.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()


func is_open() -> bool:
	return _root.visible


func open(found: Dictionary) -> void:
	_fragments = found.duplicate()
	_selected = -1
	_feedback.text = "" if _fragments.size() == SLOT_COUNT else "Fragments retrouvés : %d / %d. Les autres sont cachés dans les livres de la bibliothèque." % [_fragments.size(), SLOT_COUNT]
	_set_border(COLOR_IDLE)
	_rebuild()
	_root.show()


func place(fragment: int, slot: int) -> void:
	if not _fragments.has(fragment):
		return
	var previous := _slots.find(fragment)
	if previous >= 0:
		_slots[previous] = -1
	_slots[slot] = fragment
	_selected = -1
	_rebuild()


func clear_slot(slot: int) -> void:
	_slots[slot] = -1
	_rebuild()


func is_complete() -> bool:
	return not _slots.has(-1)


func validate() -> void:
	if not is_complete():
		return
	var correct := true
	for index in SLOT_COUNT:
		correct = correct and _slots[index] == index
	if correct:
		_root.hide()
	else:
		_feedback.text = "Les inscriptions virent au rouge et le sol tremble : la conversation n'a pas de sens dans cet ordre. Le Mont Sam Altan gronde…"
		_flash_wrong()
	validated.emit(correct)


func _rebuild() -> void:
	for child in _slot_list.get_children() + _pool.get_children():
		child.queue_free()
	for slot in SLOT_COUNT:
		var fragment := _slots[slot]
		var button := _button("%d.  %s" % [slot + 1, _fragments[fragment] if fragment >= 0 else "— emplacement vide —"])
		button.pressed.connect(_on_slot_pressed.bind(slot))
		_slot_list.add_child(button)
	var free: Array = _fragments.keys().filter(func(key: int) -> bool: return not _slots.has(key))
	# Ordre fixe mais mélangé, pour que l'ordre de la liste ne donne pas la réponse.
	free.sort_custom(func(a: int, b: int) -> bool: return (a * 7 + 3) % 11 < (b * 7 + 3) % 11)
	for fragment: int in free:
		var button := _button(_fragments[fragment])
		button.toggle_mode = true
		button.button_pressed = fragment == _selected
		button.pressed.connect(_on_fragment_pressed.bind(fragment))
		_pool.add_child(button)
	_validate.disabled = not is_complete()


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Les fragments sont des phrases : ils s'écrivent en Lora, comme les textes longs.
	button.theme_type_variation = &"TextButton"
	button.custom_minimum_size = Vector2(0, 54)
	button.add_theme_font_size_override("font_size", 22)
	return button


func _on_fragment_pressed(fragment: int) -> void:
	_selected = -1 if _selected == fragment else fragment
	_rebuild()


func _on_slot_pressed(slot: int) -> void:
	if _selected >= 0:
		place(_selected, slot)
	elif _slots[slot] >= 0:
		clear_slot(slot)


func _set_border(color: Color) -> void:
	var style := _panel.get_theme_stylebox("panel") as StyleBoxFlat
	style.border_color = color


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
