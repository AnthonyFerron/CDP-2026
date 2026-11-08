class_name RunePuzzle
extends CanvasLayer
## Table ronde des runes, dans le style des menus (Ornate) : les deux algorithmes incomplets se font face, leurs
## lignes manquantes sont des cases de pierre gravées, et les runes ramassées sont des tuiles à poser. On choisit
## une rune, puis la case où la poser ; cliquer une case remplie la libère. « Valider » ne s'active qu'une fois
## toutes les cases remplies. À l'erreur, les runes rougissent et le panneau tremble.

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
## Lueur des runes : bleue au repos, rouge à l'erreur.
const COLOR_IDLE := Color(0.45, 0.7, 1.0)
const COLOR_WRONG := Color(1.0, 0.2, 0.12)
## Panneau, en coordonnées de référence (1920 × 1080), sous le chronomètre du coin.
const FRAME_RECT := Rect2(130, 100, 1660, 920)
const COLUMN_X: Array[float] = [50.0, 860.0]
const COLUMN_WIDTH := 750.0
const LINE_TOP := 168.0
const INSTRUCTION := "Choisissez une rune, puis la case où la graver : les deux algorithmes doivent s'exécuter."
const LINE_STEP := 58.0
const INDENT := 48.0

var _runes: Array[StringName] = []
var _slots: Array[StringName] = []
var _selected: StringName = &""
var _flash: Tween
var _wrong := false
## Énigme déjà résolue (livre trouvé) : le panneau montre la solution, sans qu'on puisse la refaire.
var _solved := false

var _root: Control
var _frame: Ornate.Frame
var _glow: Glow
var _algorithms: Control
var _pool: Control
var _feedback: Label
var _validate: Ornate.HexButton
var _close: Ornate.HexButton


func _ready() -> void:
	_slots.resize(SOLUTION.size())
	_slots.fill(&"")
	_build()
	_root.hide()
	# Parchemin et clochette à l'ouverture, parchemin replié à la fermeture (scripts/ui_sounds.gd).
	UiSounds.watch(_root)
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
	_wrong = false
	if _runes.size() >= SOLUTION.size():
		_set_feedback("", Ornate.MUTED)
	else:
		_set_feedback("Runes ramassées : %d. D'autres sont cachées dans les salles du monument, parmi les débris et sous le sable." % _runes.size(), Ornate.MUTED)
	_set_border(COLOR_IDLE)
	_rebuild()
	_root.show()


## Livre déjà trouvé : la table montre les runes à leur place, en vert, et ne se manipule plus.
func open_solved() -> void:
	_solved = true
	_runes = SOLUTION.duplicate()
	_slots = SOLUTION.duplicate()
	_selected = &""
	_wrong = false
	_set_feedback("Énigme résolue : les deux algorithmes s'exécutent. Le livre a déjà été trouvé.", Ornate.SUCCESS)
	_set_border(Color(0.35, 0.9, 0.5))
	_rebuild()
	_root.show()


func is_solved() -> bool:
	return _solved


func place(rune: StringName, slot: int) -> void:
	if _solved or not rune in _runes:
		return
	var previous := _slots.find(rune)
	if previous >= 0:
		_slots[previous] = &""
	_slots[slot] = rune
	_selected = &""
	_rebuild()


func clear_slot(slot: int) -> void:
	if _solved:
		return
	_slots[slot] = &""
	_rebuild()


func is_complete() -> bool:
	return not _slots.has(&"")


func validate() -> void:
	if _solved or not is_complete():
		return
	var correct := _slots == SOLUTION
	if correct:
		_root.hide()
	else:
		# Le temps perdu s'affiche dans le bandeau « Mauvaise réponse » du HUD : ici, seulement ce que font les runes.
		_set_feedback("Les runes s'illuminent d'une lueur rouge : les algorithmes ne s'exécutent pas.", Ornate.ERROR)
		_flash_wrong()
	validated.emit(correct)


## Construit le panneau : voile, cadre doré, les deux algorithmes en vis-à-vis, les runes en main, les boutons.
func _build() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_own(_root)
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.02, 0.05, 0.66)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)
	_frame = Ornate.place(_root, Ornate.Frame.new(), FRAME_RECT.position, FRAME_RECT.size) as Ornate.Frame
	_frame.name = "Panel"
	_own(_frame)
	_frame.title = "La table des runes"
	_frame.title_size = 46
	_frame.bottom_diamond = false
	_frame.dividers = [540.0]
	_glow = Ornate.place(_frame, Glow.new(), Vector2.ZERO, FRAME_RECT.size) as Glow
	var column_rule := ColumnRule.new()
	Ornate.place(_frame, column_rule, Vector2(820, 100), Vector2(20, 420))
	_algorithms = Ornate.place(_frame, Control.new(), Vector2.ZERO, FRAME_RECT.size)
	_algorithms.name = "Algorithms"
	_algorithms.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_own(_algorithms)
	var hand := Ornate.label("Runes en main", 28, Ornate.GOLD, true)
	hand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ornate.place(_frame, hand, Vector2(0, 556), Vector2(FRAME_RECT.size.x, 40))
	_pool = Ornate.place(_frame, Control.new(), Vector2.ZERO, FRAME_RECT.size)
	_pool.name = "Pool"
	_pool.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_own(_pool)
	# La ligne du haut donne la consigne, ou ce qui vient de se passer : le bas du panneau reste libre pour le
	# bandeau « Mauvaise réponse » du HUD.
	_feedback = Ornate.label("", 23, Ornate.MUTED)
	_feedback.name = "Feedback"
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Ornate.place(_frame, _feedback, Vector2(60, 50), Vector2(FRAME_RECT.size.x - 120, 48))
	_own(_feedback)
	_validate = Ornate.HexButton.new()
	_validate.name = "Validate"
	_validate.caption = "Valider"
	_validate.highlighted = true
	_validate.font_size = 42
	Ornate.place(_frame, _validate, Vector2(400, 852), Vector2(400, 92))
	_own(_validate)
	_close = Ornate.HexButton.new()
	_close.name = "Close"
	_close.caption = "Quitter la table"
	_close.font_size = 36
	Ornate.place(_frame, _close, Vector2(860, 852), Vector2(400, 92))
	_own(_close)


## Rend un nœud construit ici accessible par son nom unique (%Validate, %Feedback…), comme dans une scène.
func _own(node: Node) -> void:
	node.owner = self
	node.unique_name_in_owner = true


func _rebuild() -> void:
	for child in _algorithms.get_children() + _pool.get_children():
		child.queue_free()
	for column in ALGORITHMS.size():
		var algorithm: Array = ALGORITHMS[column]
		var x0 := COLUMN_X[column]
		var title := Ornate.label(algorithm[0], 27, Ornate.GOLD_LIGHT, true)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Ornate.place(_algorithms, title, Vector2(x0, 108), Vector2(COLUMN_WIDTH, 40))
		var lines: Array = algorithm[1]
		for row in lines.size():
			var line: Variant = lines[row]
			var y := LINE_TOP + row * LINE_STEP
			var text: String = line if line is String else SLOT_LINES[line]
			var number := text.get_slice(" ", 0)
			var indent := 1 if text.substr(number.length()).begins_with("     ") else 0
			var numeral := Ornate.label(number, 24, Ornate.GOLD, true)
			numeral.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			numeral.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			Ornate.place(_algorithms, numeral, Vector2(x0, y), Vector2(34, 50))
			var x := x0 + 52.0 + indent * INDENT
			var width := COLUMN_WIDTH - 52.0 - indent * INDENT
			if line is String:
				var label := Ornate.label(text.substr(number.length()).strip_edges(), 23, Ornate.CREAM)
				label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				label.clip_text = true
				Ornate.place(_algorithms, label, Vector2(x + 14, y), Vector2(width - 14, 50))
			else:
				var slot: int = line
				var button := StoneSlot.new()
				button.rune = _slots[slot]
				button.caption = RUNES[_slots[slot]] if _slots[slot] != &"" else ""
				button.wrong = _wrong
				button.inviting = _selected != &"" and _slots[slot] == &""
				Ornate.place(_algorithms, button, Vector2(x, y), Vector2(width, 50))
				button.pressed.connect(_on_slot_pressed.bind(slot))
	var free: Array[StringName] = []
	for rune in _runes:
		if not rune in _slots:
			free.append(rune)
	for index in free.size():
		var rune := free[index]
		var tile := RuneTile.new()
		tile.rune = rune
		tile.caption = RUNES[rune]
		tile.selected = rune == _selected
		var column := index % 3
		var row := index / 3
		Ornate.place(_pool, tile, Vector2(70 + column * 515, 604 + row * 64), Vector2(490, 56))
		tile.pressed.connect(_on_rune_pressed.bind(rune))
	_validate.disabled = _solved or not is_complete()
	_validate.queue_redraw()


func _on_rune_pressed(rune: StringName) -> void:
	_selected = &"" if _selected == rune else rune
	_rebuild()


func _on_slot_pressed(slot: int) -> void:
	if _selected != &"":
		place(_selected, slot)
	elif _slots[slot] != &"":
		clear_slot(slot)


func _set_feedback(text: String, color: Color) -> void:
	_feedback.text = text if text != "" else INSTRUCTION
	_feedback.add_theme_color_override("font_color", color)


func _set_border(color: Color) -> void:
	_glow.color = color
	_glow.queue_redraw()


func _flash_wrong() -> void:
	if _flash:
		_flash.kill()
	_wrong = true
	_set_border(COLOR_WRONG)
	_rebuild()
	_flash = create_tween()
	# Une violente secousse ébranle le panneau, comme la cave.
	_flash.tween_method(_shake_step, 0.0, 1.0, 0.6)
	_flash.tween_callback(_shake_step.bind(1.0))
	_flash.tween_interval(2.4)
	_flash.tween_callback(_end_flash)


func _end_flash() -> void:
	_wrong = false
	_set_border(COLOR_IDLE)
	_set_feedback("", Ornate.MUTED)
	_rebuild()


func _shake_step(progress: float) -> void:
	var amount := 18.0 * (1.0 - progress)
	_root.position = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))


func _on_close_pressed() -> void:
	_root.hide()
	closed.emit()


## Trace le symbole d'une rune, au trait, dans un carré de demi-côté s : boucle, seau, jarre, losange de la
## question, embranchement, porte ouverte, cadenas ou grains de sable.
static func draw_glyph(item: CanvasItem, rune: StringName, c: Vector2, s: float, color: Color, w := 3.0) -> void:
	match rune:
		&"tant_que":
			item.draw_arc(c, 0.62 * s, -0.4 * PI, 1.25 * PI, 24, color, w)
			var tip := c + Vector2.from_angle(-0.4 * PI) * 0.62 * s
			item.draw_colored_polygon(PackedVector2Array([tip + Vector2(-0.3 * s, -0.12 * s), tip + Vector2(0.18 * s, -0.3 * s), tip + Vector2(0.12 * s, 0.22 * s)]), color)
		&"puiser":
			item.draw_polyline(PackedVector2Array([c + Vector2(-0.55, -0.35) * s, c + Vector2(-0.38, 0.55) * s, c + Vector2(0.38, 0.55) * s, c + Vector2(0.55, -0.35) * s]), color, w)
			item.draw_arc(c + Vector2(0, -0.35 * s), 0.55 * s, PI, TAU, 16, color, w * 0.8)
			item.draw_line(c + Vector2(-0.45, 0.1) * s, c + Vector2(0.45, 0.1) * s, color, w * 0.8)
		&"porter":
			item.draw_arc(c + Vector2(-0.12 * s, 0.2 * s), 0.42 * s, 0.0, TAU, 20, color, w)
			item.draw_line(c + Vector2(-0.3, -0.25) * s, c + Vector2(-0.3, -0.6) * s, color, w)
			item.draw_line(c + Vector2(0.06, -0.25) * s, c + Vector2(0.06, -0.6) * s, color, w)
			item.draw_line(c + Vector2(0.45, 0.2) * s, c + Vector2(0.9, 0.2) * s, color, w)
			item.draw_colored_polygon(PackedVector2Array([c + Vector2(0.95, 0.2) * s, c + Vector2(0.72, 0.02) * s, c + Vector2(0.72, 0.38) * s]), color)
		&"si":
			item.draw_polyline(PackedVector2Array([c + Vector2(0, -0.75) * s, c + Vector2(0.75, 0) * s, c + Vector2(0, 0.75) * s, c + Vector2(-0.75, 0) * s, c + Vector2(0, -0.75) * s]), color, w)
			item.draw_circle(c, 0.14 * s, color)
		&"sinon":
			item.draw_line(c + Vector2(-0.75, 0) * s, c + Vector2(-0.05, 0) * s, color, w)
			item.draw_line(c + Vector2(-0.05, 0) * s, c + Vector2(0.65, -0.55) * s, color, w)
			item.draw_line(c + Vector2(-0.05, 0) * s, c + Vector2(0.65, 0.55) * s, color, w)
			item.draw_circle(c + Vector2(0.65, -0.55) * s, 0.12 * s, color)
			item.draw_circle(c + Vector2(0.65, 0.55) * s, 0.12 * s, color)
		&"ouvrir":
			item.draw_polyline(PackedVector2Array([c + Vector2(-0.5, 0.7) * s, c + Vector2(-0.5, -0.7) * s, c + Vector2(0.5, -0.7) * s, c + Vector2(0.5, 0.7) * s]), color, w)
			item.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.5, -0.7) * s, c + Vector2(0.05, -0.45) * s, c + Vector2(0.05, 0.95) * s, c + Vector2(-0.5, 0.7) * s]), Color(color, 0.55))
		&"fermer":
			item.draw_arc(c + Vector2(0, -0.15 * s), 0.36 * s, PI, TAU, 14, color, w)
			item.draw_rect(Rect2(c + Vector2(-0.55, -0.15) * s, Vector2(1.1, 0.85) * s), color)
			item.draw_circle(c + Vector2(0, 0.25 * s), 0.12 * s, Color(0.08, 0.06, 0.06))
		&"pour":
			for k in 3:
				item.draw_circle(c + Vector2((k - 1) * 0.5 * s, 0.1 * s), 0.15 * s, color)
			item.draw_line(c + Vector2(-0.85, -0.45) * s, c + Vector2(0.85, -0.45) * s, color, w * 0.8)
		_:
			Ornate.diamond(item, c, 0.6 * s)


## Liseré de lueur autour du cadre : bleu au repos, rouge à l'erreur.
class Glow:
	extends Control

	var color := Color(0.45, 0.7, 1.0)

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var outline := Ornate.chamfered(Rect2(Vector2.ZERO, size).grow(7), 34)
		draw_polyline(Ornate.closed(outline), Color(color, 0.5), 5.0)
		draw_polyline(Ornate.closed(Ornate.chamfered(Rect2(Vector2.ZERO, size).grow(13), 38)), Color(color, 0.2), 6.0)


## Trait vertical doré entre les deux algorithmes.
class ColumnRule:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var x := size.x / 2
		draw_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 1.5, size.y / 2), Vector2(x, size.y), Vector2(x - 1.5, size.y / 2)]),
			PackedColorArray([Color(Ornate.GOLD, 0.0), Ornate.GOLD, Color(Ornate.GOLD, 0.0), Ornate.GOLD]))
		Ornate.diamond(self, Vector2(x, size.y / 2), 10)


## Case de pierre gravée d'un algorithme : vide, elle montre une empreinte en creux ; remplie, la rune posée.
class StoneSlot:
	extends Button

	var rune: StringName = &""
	var caption := ""
	var wrong := false
	## Une rune est choisie : les cases vides invitent à la recevoir.
	var inviting := false

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var shape := Ornate.chamfered(rect, 12)
		var top := Color(0.36, 0.31, 0.27)
		var low := Color(0.22, 0.19, 0.17)
		draw_polygon(shape, PackedColorArray([top, top, top, low, low, low, low, top]))
		var inset := Ornate.chamfered(rect.grow(-6), 8)
		draw_polyline(Ornate.closed(inset), Color(0.12, 0.1, 0.09), 2.0)
		var border := Ornate.GOLD_DARK
		if is_hovered() or inviting:
			border = Ornate.GOLD_LIGHT
		var glow := RunePuzzle.COLOR_WRONG if wrong else RunePuzzle.COLOR_IDLE
		if rune != &"":
			border = glow
		draw_polyline(Ornate.closed(shape), border, 3.0)
		var middle := Vector2(30, size.y / 2)
		if rune == &"":
			# Empreinte en creux : le losange de la rune absente, et une invite discrète.
			Ornate.diamond(self, middle, 10, Color(0.16, 0.13, 0.12))
			var hint := "graver une rune ici" if inviting else "emplacement vide"
			draw_string(Ornate.TEXT, Vector2(58, size.y / 2 + 8), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color(Ornate.MUTED, 0.75))
			return
		draw_circle(middle, 17, Color(glow, 0.22))
		RunePuzzle.draw_glyph(self, rune, middle, 14, glow, 2.5)
		draw_string(Ornate.TEXT, Vector2(58, size.y / 2 + 8), caption, HORIZONTAL_ALIGNMENT_LEFT, size.x - 70, 22, Ornate.CREAM)


## Rune en main : une tuile de pierre gravée de son symbole lumineux et de son instruction.
class RuneTile:
	extends Button

	var rune: StringName = &""
	var caption := ""
	var selected := false

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var shape := Ornate.hexagon(rect, size.y * 0.32)
		var lit := selected or is_hovered()
		var top := Color(0.4, 0.34, 0.29) if not selected else Color(0.62, 0.42, 0.18)
		var low := Color(0.24, 0.2, 0.18) if not selected else Color(0.38, 0.24, 0.1)
		draw_polygon(shape, PackedColorArray([top, top, top.lerp(low, 0.5), low, low, top.lerp(low, 0.5)]))
		draw_polyline(Ornate.closed(shape), Ornate.GOLD_LIGHT if lit else Ornate.GOLD_DARK, 3.0 if lit else 2.0)
		var middle := Vector2(size.y * 0.32 + 24, size.y / 2)
		draw_circle(middle, 19, Color(RunePuzzle.COLOR_IDLE, 0.25))
		RunePuzzle.draw_glyph(self, rune, middle, 15, RunePuzzle.COLOR_IDLE, 2.6)
		draw_string(Ornate.TEXT, Vector2(middle.x + 32, size.y / 2 + 8), caption, HORIZONTAL_ALIGNMENT_LEFT, size.x - middle.x - 52, 22, Ornate.CREAM)
