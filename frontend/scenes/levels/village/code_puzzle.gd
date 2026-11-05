class_name CodePuzzle
extends CanvasLayer
## Dispositif des cinq codes, dans le bureau du maire, dans le style des menus (scenes/ui/menus/ornate.gd) : cinq
## onglets de langages, l'extrait de code présenté comme une page des archives, le champ de réponse. Une épreuve ne
## s'ouvre qu'une fois la précédente résolue ; une bonne réponse la garde déverrouillée. Une erreur fait rougir et
## trembler le dispositif ; les cinq codes résolus, il s'illumine d'une intense lumière bleutée.
## Le panneau est construit à l'exécution ; les nœuds Root, Answer, Validate, Feedback, Heading, Code, Question,
## Fragments et Close gardent leur nom unique (%Answer…), utilisé par les tests.

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
## Noms courts des onglets.
const TAB_NAMES := ["HTML", "CSS", "Python", "PHP", "JS / TS"]
const INSCRIPTION := "« Cinq langages, cinq épreuves, un seul savoir. Comprends les instructions des anciens bâtisseurs et le dernier secret du village te sera révélé. »"
const COLOR_IDLE := Color(0.55, 0.6, 0.85)
const COLOR_SOLVED := Color(0.35, 0.9, 0.45)
const COLOR_WRONG := Color(0.95, 0.15, 0.1)
const COLOR_BLUE := Color(0.4, 0.65, 1.0)
const HINTS_SCRIPT := preload("res://scripts/hints.gd")
## Place du cadre, en coordonnées de référence (1920 × 1080).
const FRAME_ORIGIN := Vector2(60, 44)
const FRAME_SIZE := Vector2(1800, 722)

var solved: Array[bool] = [false, false, false, false, false]
var current := 0

var _tabs: Array[LanguageTab] = []
var _flash: Tween
## Passage automatique à l'épreuve suivante après une réussite ; annulé si le joueur choisit lui-même un onglet.
var _advance: Tween
var _root: Control
var _frame: Control
var _glow: Glow
var _page: ArchivePage
var _heading: Label
var _level: Label
var _numbers: Label
var _code: Label
var _question: Label
var _answer: LineEdit
var _validate: Button
var _feedback: Label
var _fragments: VBoxContainer
var _close: Button
var _blue: ColorRect


func _ready() -> void:
	_build()
	_root.hide()
	_validate.pressed.connect(_on_validate_pressed)
	_answer.text_submitted.connect(func(_text: String) -> void: _on_validate_pressed())
	_close.pressed.connect(_on_close_pressed)


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
	_show_fragments(fragments)
	_feedback.text = ""
	_set_border(COLOR_IDLE)
	current = solved.find(false) if not all_solved() else CODES.size() - 1
	# Le cadre s'arrête au-dessus de y = 770 : le bandeau « Mauvaise réponse » du HUD se place dessous.
	Hud.warning_position = Hud.WARNING_BOTTOM
	_root.show()
	select(current)


func select(index: int) -> void:
	if not is_unlocked(index):
		return
	if _advance:
		_advance.kill()
	current = index
	var code: Dictionary = CODES[index]
	_heading.text = "Archive %d — %s" % [index + 1, code.language]
	_level.text = code.level
	_code.text = code.code
	var numbers := PackedStringArray()
	for line in code.code.split("\n").size():
		numbers.append(str(line + 1))
	_numbers.text = "\n".join(numbers)
	_question.text = code.question
	_answer.text = ""
	_answer.editable = not solved[index]
	_validate.disabled = solved[index]
	_feedback.text = "Épreuve résolue : la section brille en vert." if solved[index] else ""
	_feedback.add_theme_color_override("font_color", Ornate.SUCCESS)
	_page.solved = solved[index]
	_page.queue_redraw()
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
		_feedback.add_theme_color_override("font_color", Ornate.SUCCESS)
		_feedback.text = "La section s'illumine de vert : l'épreuve est réussie."
		_answer.editable = false
		_validate.disabled = true
		_page.solved = true
		_page.queue_redraw()
	else:
		# Le temps perdu est annoncé par le bandeau du HUD : ici, seulement l'effet sur le dispositif.
		_feedback.add_theme_color_override("font_color", Ornate.ERROR)
		_feedback.text = "La section s'illumine de rouge : réponse erronée. Les murs tremblent."
		_flash_wrong()
	_refresh_tabs()
	answered.emit(current, correct)
	if correct and all_solved():
		_root.hide()
		Hud.warning_position = Hud.WARNING_TOP
		_flash_blue()
		solved_all.emit()
	elif correct:
		_advance = create_tween()
		_advance.tween_interval(1.1)
		_advance.tween_callback(select.bind(current + 1))
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
		tab.state = "solved" if solved[index] else ("open" if is_unlocked(index) else "sealed")
		tab.disabled = not is_unlocked(index)
		tab.selected = index == current
		tab.queue_redraw()


func _set_border(color: Color) -> void:
	_glow.color = color
	_glow.strength = 0.35 if color == COLOR_IDLE else 1.0
	_glow.queue_redraw()
	_page.border = color if color != COLOR_IDLE else Ornate.GOLD_DARK
	_page.queue_redraw()


## Erreur : le dispositif rougit et tremble un instant, puis reprend sa lueur.
func _flash_wrong() -> void:
	if _flash:
		_flash.kill()
	_set_border(COLOR_WRONG)
	_tabs[current].flash = COLOR_WRONG
	_tabs[current].queue_redraw()
	var origin := FRAME_ORIGIN
	_flash = create_tween()
	for step in 8:
		var offset := Vector2(randf_range(-1.0, 1.0), randf_range(-0.5, 0.5)) * 14.0 * (1.0 - step / 8.0)
		_flash.tween_property(_frame, "position", origin + offset, 0.04)
	_flash.tween_property(_frame, "position", origin, 0.04)
	_flash.tween_interval(0.9)
	_flash.tween_callback(func() -> void:
		_tabs[current].flash = Color.TRANSPARENT
		_tabs[current].queue_redraw()
		_set_border(COLOR_IDLE))


## Les cinq codes résolus : une intense lumière bleutée envahit l'écran, puis s'efface sur la scène.
func _flash_blue() -> void:
	_blue.show()
	_blue.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(_blue, "modulate:a", 0.0, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(_blue.hide)


func _on_close_pressed() -> void:
	_root.hide()
	Hud.warning_position = Hud.WARNING_TOP
	closed.emit()


func _show_fragments(fragments: Array[String]) -> void:
	for child in _fragments.get_children():
		child.queue_free()
	if fragments.is_empty():
		var empty := Ornate.label("Aucun fragment pour l'instant. Fouillez la mairie.", 22, Ornate.MUTED)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size = Vector2(440, 0)
		_fragments.add_child(empty)
		return
	for text in fragments:
		_fragments.add_child(PaperNotebook.card(text, 440, 19))


## Rend un nœud accessible par son nom unique (%Nom), comme s'il venait de la scène.
func _own(node: Node, node_name: String) -> void:
	node.name = node_name
	node.owner = self
	node.unique_name_in_owner = true


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_own(_root, "Root")
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.02, 0.06, 0.72)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)
	# Le panneau s'arrête au-dessus du bandeau « Mauvaise réponse » du HUD (y = 770 à 910, centré en bas) : une
	# erreur ne cache ni la question, ni le champ, ni les boutons.
	_glow = Ornate.place(_root, Glow.new(), FRAME_ORIGIN, FRAME_SIZE) as Glow
	_glow.color = COLOR_IDLE
	var frame := Ornate.place(_root, Ornate.Frame.new(), FRAME_ORIGIN, FRAME_SIZE) as Ornate.Frame
	_frame = frame
	frame.title = "Le dispositif des cinq codes"
	frame.title_size = 40
	frame.dividers = [102.0]
	var inscription := Ornate.label(INSCRIPTION, 20, Color(0.86, 0.8, 0.68))
	inscription.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inscription.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inscription.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Ornate.place(frame, inscription, Vector2(150, 40), Vector2(1500, 58))
	# Cinq onglets, un par langage, au-dessus de la page.
	for index in CODES.size():
		var tab := LanguageTab.new()
		tab.number = index + 1
		tab.language_name = TAB_NAMES[index]
		tab.level = CODES[index].level
		Ornate.place(frame, tab, Vector2(50 + index * 228, 112), Vector2(218, 74))
		tab.pressed.connect(select.bind(index))
		_tabs.append(tab)
	_page = Ornate.place(frame, ArchivePage.new(), Vector2(50, 186), Vector2(1130, 378)) as ArchivePage
	_heading = Ornate.label("", 25, Ornate.INK, true)
	Ornate.place(_page, _heading, Vector2(40, 12), Vector2(760, 40))
	_own(_heading, "Heading")
	_level = Ornate.label("", 20, Color(0.42, 0.26, 0.12))
	_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	Ornate.place(_page, _level, Vector2(800, 16), Vector2(290, 34))
	# Lignes serrées : les treize lignes de l'extrait le plus long tiennent dans la page.
	_numbers = Ornate.label("", 20, Color(0.55, 0.42, 0.28))
	_numbers.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_numbers.add_theme_constant_override("line_spacing", -1)
	Ornate.place(_page, _numbers, Vector2(20, 64), Vector2(44, 310))
	_code = Ornate.label("", 20, Color(0.16, 0.09, 0.05))
	_code.add_theme_constant_override("line_spacing", -1)
	Ornate.place(_page, _code, Vector2(86, 64), Vector2(1010, 310))
	_own(_code, "Code")
	_question = Ornate.label("", 22)
	_question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_question.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Ornate.place(frame, _question, Vector2(56, 566), Vector2(1120, 40))
	_own(_question, "Question")
	var field := Ornate.Field.new()
	field.icon_kind = "question_book"
	field.placeholder = "Votre réponse"
	Ornate.place(frame, field, Vector2(50, 610), Vector2(770, 62))
	_answer = field.line
	_own(_answer, "Answer")
	var validate := Ornate.HexButton.new()
	validate.caption = "Valider"
	validate.icon_kind = "check"
	validate.highlighted = true
	validate.font_size = 34
	Ornate.place(frame, validate, Vector2(846, 604), Vector2(334, 74))
	_validate = validate
	_own(_validate, "Validate")
	_feedback = Ornate.label("", 19)
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ornate.place(frame, _feedback, Vector2(50, 676), Vector2(1130, 26))
	_own(_feedback, "Feedback")
	# Les fragments déjà retrouvés, à relire sans quitter le dispositif.
	var notes := Ornate.place(frame, Ornate.Frame.new(), Vector2(1214, 130), Vector2(540, 560)) as Ornate.Frame
	notes.title = "Fragments"
	notes.title_size = 28
	notes.bottom_diamond = false
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	Ornate.place(notes, scroll, Vector2(30, 50), Vector2(486, 490))
	_fragments = VBoxContainer.new()
	_fragments.add_theme_constant_override("separation", 12)
	scroll.add_child(_fragments)
	_own(_fragments, "Fragments")
	# Touches rappelées sous le bandeau du HUD.
	var x := 720.0
	for key: Array in [["Entrée", "valider"], ["Échap", "fermer"]]:
		var cap := Ornate.KeyCap.new()
		cap.text = key[0]
		Ornate.place(_root, cap, Vector2(x, 950), Vector2(124, 56))
		var hint := Ornate.label(key[1], 24, Ornate.MUTED)
		Ornate.place(_root, hint, Vector2(x + 138, 960), Vector2(140, 40))
		x += 300.0
	var close := HINTS_SCRIPT.CloseButton.new() as Button
	Ornate.place(frame, close, Vector2(1690, -30), Vector2(80, 80))
	_close = close
	_own(_close, "Close")
	# Lumière bleutée de la réussite : hors du panneau, elle reste à l'écran quand il se ferme.
	_blue = ColorRect.new()
	_blue.set_anchors_preset(Control.PRESET_FULL_RECT)
	_blue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_blue.color = Color(COLOR_BLUE, 0.75)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_blue.material = additive
	_blue.hide()
	add_child(_blue)


class Glow:
	extends Control
	## Halo autour du dispositif : doux au repos, vif à la réussite ou à l'erreur.

	var color := Color.WHITE
	var strength := 0.35

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		for ring in 4:
			var grow := 6.0 + ring * 9.0
			var shape := Ornate.chamfered(Rect2(Vector2.ZERO, size).grow(grow), 30 + grow)
			draw_polyline(Ornate.closed(shape), Color(color, strength * (0.5 - ring * 0.11)), 10.0)


class LanguageTab:
	extends Button
	## Onglet d'un langage : son numéro dans un losange, son nom, sa difficulté ; vert et coché une fois résolu,
	## sombre et cadenassé tant que l'épreuve précédente ne l'est pas.

	var number := 1
	var language_name := ""
	var level := ""
	var state := "sealed"
	var selected := false
	var flash := Color.TRANSPARENT

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)

	func _draw() -> void:
		var cut := 22.0
		var shape := PackedVector2Array([Vector2(0, size.y), Vector2(0, cut), Vector2(cut, 0), Vector2(size.x - cut, 0),
			Vector2(size.x, cut), Vector2(size.x, size.y)])
		var fill := Color(0.17, 0.09, 0.07)
		var border := Ornate.GOLD
		var text := Ornate.CREAM
		if state == "sealed":
			fill = Color(0.13, 0.11, 0.12)
			border = Color(0.45, 0.44, 0.46)
			text = Color(0.55, 0.53, 0.53)
		elif state == "solved":
			fill = Color(0.12, 0.22, 0.12)
			border = Ornate.SUCCESS
		if selected:
			fill = Color(0.86, 0.78, 0.6) if state != "solved" else Color(0.72, 0.86, 0.66)
			text = Ornate.INK
		elif is_hovered() and state != "sealed":
			fill = fill.lightened(0.12)
		if flash.a > 0.0:
			border = flash
			fill = fill.lerp(flash, 0.35)
		draw_colored_polygon(shape, fill)
		draw_polyline(shape, border, 4.0)
		var badge := Vector2(34, size.y / 2)
		Ornate.diamond(self, badge, 22, border if state != "sealed" else Color(0.4, 0.4, 0.42))
		Ornate.centered_text(self, Ornate.SERIF, badge, str(number), 22, Ornate.INK)
		Ornate.centered_text(self, Ornate.SERIF, Vector2(size.x / 2 + 18, size.y * 0.38), language_name, 24, text)
		Ornate.centered_text(self, Ornate.TEXT, Vector2(size.x / 2 + 18, size.y * 0.72), level, 17, text.lerp(Ornate.MUTED, 0.35))
		if state == "solved":
			Ornate.icon(self, "check", Vector2(size.x - 24, 26), 12, Ornate.SUCCESS if not selected else Color(0.1, 0.4, 0.15), 3.5)
		elif state == "sealed":
			Ornate.icon(self, "lock", Vector2(size.x - 24, 28), 12, text, 2.5)


class ArchivePage:
	extends Control
	## Page des archives de la mairie : un parchemin aux coins coupés, son en-tête, une marge pour les numéros de
	## ligne, et le sceau vert des épreuves réussies.

	var border := Ornate.GOLD_DARK
	var solved := false

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var shape := Ornate.chamfered(rect, 18)
		draw_colored_polygon(shape, Color(0.88, 0.8, 0.63))
		var inner := Ornate.chamfered(rect.grow(-10), 12)
		draw_colored_polygon(inner, Color(0.92, 0.85, 0.69))
		draw_polyline(Ornate.closed(shape), border, 5.0)
		draw_polyline(Ornate.closed(inner), Color(border, 0.45), 2.0)
		draw_line(Vector2(30, 56), Vector2(size.x - 30, 56), Color(0.5, 0.33, 0.16, 0.7), 2.0)
		draw_line(Vector2(74, 64), Vector2(74, size.y - 16), Color(0.7, 0.3, 0.2, 0.45), 2.0)
		# Taches d'encre et d'humidité, pour l'usure.
		for spot: Vector3 in [Vector3(size.x - 120, size.y - 70, 34), Vector3(150, size.y - 40, 18), Vector3(size.x - 260, 120, 12)]:
			draw_circle(Vector2(spot.x, spot.y), spot.z, Color(0.62, 0.5, 0.32, 0.18))
		if solved:
			var seal := Vector2(size.x - 100, size.y - 86)
			draw_circle(seal, 62, Color(0.25, 0.55, 0.3, 0.2))
			draw_arc(seal, 62, 0.0, TAU, 40, Color(0.2, 0.5, 0.25, 0.85), 4.0)
			draw_arc(seal, 52, 0.0, TAU, 40, Color(0.2, 0.5, 0.25, 0.6), 2.0)
			Ornate.centered_text(self, Ornate.SERIF, seal, "Résolu", 24, Color(0.15, 0.42, 0.2))
