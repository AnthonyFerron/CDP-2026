class_name RunePuzzle
extends CanvasLayer
## Table ronde des runes : deux algorithmes incomplets, dont on remplit les lignes manquantes
## avec les runes ramassées. On choisit une rune, puis la ligne où la poser ; cliquer une ligne remplie
## la libère. « Valider » ne s'active qu'une fois toutes les lignes remplies.

signal validated(correct: bool)
signal closed

## Texte de chaque rune.
const RUNES := {
	&"tant_que": "TANT QUE la jarre n'est pas pleine",
	&"puiser": "Puiser de l'eau au puits",
	&"porter": "Porter la jarre au temple",
	&"si": "SI le mot de passe est « soleil »",
	&"ouvrir": "Ouvrir la porte du temple",
	&"sinon": "SINON",
	&"pour": "POUR chaque grain de sable",
	&"fermer": "Fermer la porte à clé",
}
## Lignes de chaque algorithme : un texte est déjà gravé, un nombre est l'emplacement d'une rune.
const ALGORITHMS := [
	["Algorithme 1 — Remplir la jarre sacrée", [
		"1   Prendre une jarre vide", 0, 1, "4         Verser l'eau dans la jarre", "5   FIN TANT QUE", 2,
	]],
	["Algorithme 2 — Garder l'entrée du temple", [
		"1   Demander le mot de passe au voyageur", 3, 4, 5, "5         Sonner l'alarme", "6   FIN SI",
	]],
]
## Numéro de ligne et retrait de chaque emplacement, pour l'afficher à sa place.
const SLOT_LINES := ["2   ", "3         ", "6   ", "2   ", "3         ", "4   "]
const SOLUTION: Array[StringName] = [&"tant_que", &"puiser", &"porter", &"si", &"ouvrir", &"sinon"]
const COLOR_IDLE := Color(0.45, 0.65, 0.95)
const COLOR_WRONG := Color(0.95, 0.15, 0.1)

var _runes: Array[StringName] = []
var _slots: Array[StringName] = []
var _selected: StringName = &""
var _flash: Tween

@onready var _root: Control = %Root
@onready var _panel: PanelContainer = %Panel
@onready var _algorithms: VBoxContainer = %Algorithms
@onready var _pool: VBoxContainer = %Pool
@onready var _feedback: Label = %Feedback
@onready var _validate: Button = %Validate
@onready var _close: Button = %Close


func _ready() -> void:
	_slots.resize(SOLUTION.size())
	_slots.fill(&"")
	_root.hide()
	_validate.pressed.connect(validate)
	_close.pressed.connect(_on_close_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if _root.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()


func is_open() -> bool:
	return _root.visible


func open(runes: Array[StringName]) -> void:
	_runes = runes.duplicate()
	_selected = &""
	_feedback.text = "" if _runes.size() >= SOLUTION.size() else "Runes ramassées : %d. D'autres sont cachées dans les salles du monument, parmi les débris et sous le sable." % _runes.size()
	_set_border(COLOR_IDLE)
	_rebuild()
	_root.show()


func place(rune: StringName, slot: int) -> void:
	if not rune in _runes:
		return
	var previous := _slots.find(rune)
	if previous >= 0:
		_slots[previous] = &""
	_slots[slot] = rune
	_selected = &""
	_rebuild()


func clear_slot(slot: int) -> void:
	_slots[slot] = &""
	_rebuild()


func is_complete() -> bool:
	return not _slots.has(&"")


func validate() -> void:
	if not is_complete():
		return
	var correct := _slots == SOLUTION
	if correct:
		_root.hide()
	else:
		_feedback.text = "Les runes s'illuminent d'une lueur rouge : les algorithmes ne s'exécutent pas. Le volcan gronde…"
		_flash_wrong()
	validated.emit(correct)


func _rebuild() -> void:
	for child in _algorithms.get_children() + _pool.get_children():
		child.queue_free()
	for algorithm: Array in ALGORITHMS:
		var title := Label.new()
		title.text = algorithm[0]
		title.add_theme_font_size_override("font_size", 26)
		title.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
		_algorithms.add_child(title)
		for line: Variant in algorithm[1]:
			if line is String:
				var label := Label.new()
				label.text = line
				label.add_theme_font_size_override("font_size", 22)
				_algorithms.add_child(label)
			else:
				var slot: int = line
				var rune := _slots[slot]
				var button := _button(SLOT_LINES[slot] + (RUNES[rune] if rune != &"" else "[ emplacement vide ]"))
				button.pressed.connect(_on_slot_pressed.bind(slot))
				_algorithms.add_child(button)
	for rune in _runes:
		if rune in _slots:
			continue
		var button := _button(RUNES[rune])
		button.toggle_mode = true
		button.button_pressed = rune == _selected
		button.pressed.connect(_on_rune_pressed.bind(rune))
		_pool.add_child(button)
	_validate.disabled = not is_complete()


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 46)
	button.add_theme_font_size_override("font_size", 22)
	return button


func _on_rune_pressed(rune: StringName) -> void:
	_selected = &"" if _selected == rune else rune
	_rebuild()


func _on_slot_pressed(slot: int) -> void:
	if _selected != &"":
		place(_selected, slot)
	elif _slots[slot] != &"":
		clear_slot(slot)


func _set_border(color: Color) -> void:
	(_panel.get_theme_stylebox("panel") as StyleBoxFlat).border_color = color


func _flash_wrong() -> void:
	if _flash:
		_flash.kill()
	_set_border(COLOR_WRONG)
	_flash = create_tween()
	# Une violente secousse ébranle le panneau, comme la cave.
	_flash.tween_method(_shake_step, 0.0, 1.0, 0.6)
	_flash.tween_callback(_shake_step.bind(1.0))
	_flash.tween_interval(0.6)
	_flash.tween_callback(_set_border.bind(COLOR_IDLE))


func _shake_step(progress: float) -> void:
	var amount := 18.0 * (1.0 - progress)
	_root.position = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))


func _on_close_pressed() -> void:
	_root.hide()
	closed.emit()
