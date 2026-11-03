class_name CodePuzzle
extends CanvasLayer
## Dispositif des cinq codes, dans le bureau du maire : chaque épreuve montre un extrait de code et une question.
## Une épreuve ne s'ouvre qu'une fois la précédente résolue ; une bonne réponse la garde déverrouillée.

## Une réponse vient d'être validée pour l'épreuve donnée.
signal answered(index: int, correct: bool)
signal solved_all
signal closed

const CODES := [
	{
		"language": "HTML", "level": "Facile",
		"code": "<h1>Registre de Codia</h1>\n<ul>\n  <li>Forge</li>\n  <li>Moulin</li>\n  <!-- <li>Tour de garde</li> -->\n  <li>Puits</li>\n</ul>",
		"question": "Combien de lieux la liste affiche-t-elle à l'écran ?",
		"answers": ["3", "trois"],
	},
	{
		"language": "CSS", "level": "Facile",
		"code": "p { color: red; }\n.annonce { color: blue; }\n#maire { color: green; }\n\n<p id=\"maire\" class=\"annonce\">Bienvenue à la mairie</p>",
		"question": "De quelle couleur s'affiche le texte « Bienvenue à la mairie » ? Répondez comme dans le code.",
		"answers": ["green", "vert"],
	},
	{
		"language": "Python", "level": "Intermédiaire",
		"code": "recolte = 12\ngreniers = 3\nif recolte > 10:\n    greniers = greniers + 2\nelse:\n    greniers = greniers - 1\nprint(greniers * 2)",
		"question": "Quel nombre ce programme affiche-t-il ?",
		"answers": ["10", "dix"],
	},
	{
		"language": "PHP", "level": "Intermédiaire",
		"code": "<?php\n$pieces = 7;\n$pieces += 5;\n$reste = $pieces % 5;\necho \"Pièces restantes : \" . $reste;\n?>",
		"question": "Quel nombre le programme affiche-t-il après « Pièces restantes : » ?",
		"answers": ["2", "deux", "piècesrestantes:2", "piecesrestantes:2"],
	},
	{
		"language": "JavaScript / TypeScript", "level": "Difficile",
		"code": "function compterGardes(tours: number[]): number {\n  let total = 0;\n  for (const gardes of tours) {\n    if (gardes % 2 === 0) {\n      total += gardes;\n    } else {\n      total -= 1;\n    }\n  }\n  return total;\n}\nconsole.log(compterGardes([4, 3, 8, 5, 2]));",
		"question": "Quel nombre console.log affiche-t-il ?",
		"answers": ["12", "douze"],
	},
]
const COLOR_IDLE := Color(0.55, 0.6, 0.85)
const COLOR_SOLVED := Color(0.35, 0.9, 0.45)
const COLOR_WRONG := Color(0.95, 0.15, 0.1)

var solved: Array[bool] = [false, false, false, false, false]
var current := 0

var _tabs: Array[Button] = []
var _flash: Tween

@onready var _root: Control = %Root
@onready var _panel: PanelContainer = %Panel
@onready var _tab_list: VBoxContainer = %Tabs
@onready var _heading: Label = %Heading
@onready var _code: Label = %Code
@onready var _question: Label = %Question
@onready var _answer: LineEdit = %Answer
@onready var _validate: Button = %Validate
@onready var _feedback: Label = %Feedback
@onready var _fragments: Label = %Fragments
@onready var _close: Button = %Close


func _ready() -> void:
	_root.hide()
	_validate.pressed.connect(_on_validate_pressed)
	_answer.text_submitted.connect(func(_text: String) -> void: _on_validate_pressed())
	_close.pressed.connect(_on_close_pressed)
	for index in CODES.size():
		var tab := Button.new()
		tab.custom_minimum_size = Vector2(330, 64)
		tab.add_theme_font_size_override("font_size", 22)
		tab.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tab.toggle_mode = true
		tab.pressed.connect(select.bind(index))
		_tab_list.add_child(tab)
		_tabs.append(tab)


func _unhandled_input(event: InputEvent) -> void:
	if _root.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()


func is_open() -> bool:
	return _root.visible


func is_unlocked(index: int) -> bool:
	return index == 0 or solved[index - 1]


func all_solved() -> bool:
	return not solved.has(false)


## Ouvre le dispositif sur la première épreuve non résolue, avec les fragments déjà retrouvés.
func open(fragments: Array[String]) -> void:
	_fragments.text = "\n\n".join(fragments) if not fragments.is_empty() else "Aucun fragment pour l'instant. Fouillez la mairie."
	_feedback.text = ""
	_set_border(COLOR_IDLE)
	current = solved.find(false) if not all_solved() else CODES.size() - 1
	_root.show()
	select(current)


func select(index: int) -> void:
	if not is_unlocked(index):
		return
	current = index
	var code: Dictionary = CODES[index]
	_heading.text = "Code %d — %s · %s" % [index + 1, code.language, code.level]
	_code.text = code.code
	_question.text = code.question
	_answer.text = ""
	_answer.editable = not solved[index]
	_validate.disabled = solved[index]
	_feedback.text = "Épreuve résolue." if solved[index] else ""
	_feedback.add_theme_color_override("font_color", COLOR_SOLVED)
	_refresh_tabs()
	if not solved[index]:
		_answer.grab_focus.call_deferred()


## Vérifie une réponse pour l'épreuve en cours ; les majuscules, espaces et guillemets ne comptent pas.
func submit(answer: String) -> bool:
	if solved[current] or not is_unlocked(current):
		return false
	var correct: bool = _normalize(answer) in CODES[current].answers
	if correct:
		solved[current] = true
		_set_border(COLOR_SOLVED)
		_feedback.add_theme_color_override("font_color", COLOR_SOLVED)
		_feedback.text = "La section s'illumine de vert : l'épreuve est déverrouillée."
		_answer.editable = false
		_validate.disabled = true
	else:
		_feedback.add_theme_color_override("font_color", Color(1, 0.45, 0.35))
		_feedback.text = "La section s'illumine de rouge et un signal retentit : réponse erronée. Le volcan gronde…"
		_flash_wrong()
	_refresh_tabs()
	answered.emit(current, correct)
	if correct and all_solved():
		_root.hide()
		solved_all.emit()
	return correct


func _on_validate_pressed() -> void:
	if not _answer.text.strip_edges().is_empty():
		submit(_answer.text)


func _normalize(answer: String) -> String:
	var text := answer.strip_edges().to_lower()
	for character in [" ", "\"", "'", "«", "»", ".", ";"]:
		text = text.replace(character, "")
	return text


func _refresh_tabs() -> void:
	for index in _tabs.size():
		var tab := _tabs[index]
		var code: Dictionary = CODES[index]
		var state := "✔ résolu" if solved[index] else ("à résoudre" if is_unlocked(index) else "scellé")
		tab.text = "%d · %s — %s" % [index + 1, code.language, state]
		tab.disabled = not is_unlocked(index)
		tab.button_pressed = index == current
		tab.add_theme_color_override("font_color", COLOR_SOLVED if solved[index] else Color(0.92, 0.9, 0.85))


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
