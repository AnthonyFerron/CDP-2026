class_name TabletPuzzle
extends CanvasLayer
## Tablette des fragments du passé, dans le style des menus (scenes/ui/menus/ornate.gd) : six emplacements comme
## des cases de pierre gravées, et les fragments de parchemin retrouvés à y poser.
## On choisit un fragment, puis l'emplacement où le poser ; cliquer un emplacement rempli le libère.
## « Valider » ne s'active qu'une fois les six emplacements remplis, pour éviter une fausse erreur.
## Erreur : les cases rougissent. Réussite : elles passent au vert, puis le panneau s'efface.

signal validated(correct: bool)
signal closed

const SLOT_COUNT := 6
const NUMERALS: Array[String] = ["I", "II", "III", "IV", "V", "VI"]
const WRONG_TIME := 1.4
const RIGHT_TIME := 1.1
## Teinte des cases selon leur état.
const STONE := Color(0.42, 0.39, 0.37)
const STONE_DARK := Color(0.25, 0.23, 0.23)
const WRONG := Color(1.0, 0.28, 0.18)
const RIGHT := Color(0.42, 0.95, 0.5)

enum Mark { NONE, WRONG, RIGHT }

## Fragments retrouvés : numéro vers texte.
var _fragments := {}
## Fragment posé dans chaque emplacement, ou -1.
var _slots: Array[int] = []
var _selected := -1
var _mark := Mark.NONE
var _closing := false
var _flash: Tween

var _root: Control
var _panel: Ornate.Frame
var _glow: Glow
var _slot_list: VBoxContainer
var _pool: VBoxContainer
var _feedback: Label
var _validate: Ornate.HexButton
var _close: Ornate.PillButton


func _ready() -> void:
	_slots.resize(SLOT_COUNT)
	_slots.fill(-1)
	_build()
	_root.hide()
	_validate.pressed.connect(validate)
	_close.pressed.connect(_on_close_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if is_open() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()


## Ouvert et en attente du joueur : pendant le fondu de la réussite, la tablette compte déjà comme fermée.
func is_open() -> bool:
	return _root.visible and not _closing


func open(found: Dictionary) -> void:
	_fragments = found.duplicate()
	_selected = -1
	_closing = false
	_mark = Mark.NONE
	_root.modulate = Color.WHITE
	_feedback.text = "" if _fragments.size() == SLOT_COUNT else "Fragments retrouvés : %d / %d. Les autres sont cachés dans les livres de la bibliothèque." % [_fragments.size(), SLOT_COUNT]
	_glow.color = Color.TRANSPARENT
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
	_mark = Mark.NONE
	_rebuild()


func clear_slot(slot: int) -> void:
	_slots[slot] = -1
	_mark = Mark.NONE
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
		_show_right()
	else:
		_feedback.text = "Les inscriptions virent au rouge et le sol tremble : la conversation n'a pas de sens dans cet ordre."
		_flash_wrong()
	validated.emit(correct)


func _rebuild() -> void:
	for child in _slot_list.get_children() + _pool.get_children():
		child.queue_free()
	for slot in SLOT_COUNT:
		var fragment := _slots[slot]
		var cell := StoneSlot.new()
		cell.numeral = NUMERALS[slot]
		cell.text_value = _fragments[fragment] if fragment >= 0 else ""
		cell.mark = _mark if fragment >= 0 else Mark.NONE
		cell.armed = _selected >= 0
		cell.custom_minimum_size = Vector2(0, 88)
		cell.pressed.connect(_on_slot_pressed.bind(slot))
		_slot_list.add_child(cell)
	var free: Array = _fragments.keys().filter(func(key: int) -> bool: return not _slots.has(key))
	# Ordre fixe mais mélangé, pour que l'ordre de la liste ne donne pas la réponse.
	free.sort_custom(func(a: int, b: int) -> bool: return (a * 7 + 3) % 11 < (b * 7 + 3) % 11)
	for fragment: int in free:
		var card := ParchmentCard.new()
		card.text_value = _fragments[fragment]
		card.seed = fragment
		card.toggle_mode = true
		card.button_pressed = fragment == _selected
		card.custom_minimum_size = Vector2(0, 88)
		card.pressed.connect(_on_fragment_pressed.bind(fragment))
		_pool.add_child(card)
	if free.is_empty() and _fragments.size() == SLOT_COUNT:
		var done := Ornate.label("Les six fragments sont posés : relisez la discussion, puis validez.", 22, Ornate.MUTED)
		done.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_pool.add_child(done)
	_validate.disabled = not is_complete()
	_validate.queue_redraw()


func _on_fragment_pressed(fragment: int) -> void:
	_selected = -1 if _selected == fragment else fragment
	_rebuild()


func _on_slot_pressed(slot: int) -> void:
	if _selected >= 0:
		place(_selected, slot)
	elif _slots[slot] >= 0:
		clear_slot(slot)


func _flash_wrong() -> void:
	if _flash:
		_flash.kill()
	_mark = Mark.WRONG
	_glow.color = WRONG
	_rebuild()
	_flash = create_tween()
	_flash.tween_interval(WRONG_TIME)
	_flash.tween_callback(_end_wrong)


## Réussite : les inscriptions passent au vert, puis le panneau s'efface de lui-même.
func _show_right() -> void:
	if _flash:
		_flash.kill()
	_closing = true
	_mark = Mark.RIGHT
	_glow.color = RIGHT
	_feedback.text = ""
	_rebuild()
	_flash = create_tween()
	_flash.tween_interval(RIGHT_TIME)
	_flash.tween_property(_root, "modulate:a", 0.0, 0.4)
	_flash.tween_callback(_end_right)


func _end_wrong() -> void:
	_mark = Mark.NONE
	_glow.color = Color.TRANSPARENT
	_rebuild()


func _end_right() -> void:
	_root.hide()
	_closing = false


func _on_close_pressed() -> void:
	_root.hide()
	closed.emit()


## Construit le panneau, en coordonnées de référence 1920 x 1080 comme les menus.
func _build() -> void:
	layer = 2
	_root = Control.new()
	_add_unique(self, _root, "Root")
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.06, 0.02, 0.05, 0.66)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)
	_glow = Glow.new()
	Ornate.place(_root, _glow, Vector2(96, 46), Vector2(1728, 988))
	_panel = Ornate.Frame.new()
	_panel.title = "Les fragments du passé"
	_panel.title_size = 44
	_panel.bottom_diamond = false
	_panel.dividers = [150.0, 806.0]
	_panel.vertical_dividers = [890.0]
	Ornate.place(_root, _panel, Vector2(110, 60), Vector2(1700, 960))
	_panel.unique_name_in_owner = true
	_panel.name = "Panel"
	_panel.owner = self
	var instruction := Ornate.label("Six emplacements gravés attendent les fragments d'une conversation entre la bibliothécaire, cheffe de projet, et l'un de ses employés. Choisissez un fragment, puis l'emplacement où le poser, en suivant les étapes du projet.", 23)
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ornate.place(_panel, instruction, Vector2(80, 66), Vector2(1540, 72))
	for spec: Array in [["La tablette", Vector2(60, 168), Vector2(800, 36)], ["Fragments retrouvés", Vector2(920, 168), Vector2(720, 36)]]:
		var heading := Ornate.label(spec[0], 28, Ornate.GOLD, true)
		heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Ornate.place(_panel, heading, spec[1], spec[2])
	_slot_list = VBoxContainer.new()
	_slot_list.add_theme_constant_override("separation", 9)
	Ornate.place(_panel, _slot_list, Vector2(60, 214), Vector2(800, 576))
	_add_unique(_panel, _slot_list, "Slots", false)
	_pool = VBoxContainer.new()
	_pool.add_theme_constant_override("separation", 9)
	Ornate.place(_panel, _pool, Vector2(920, 214), Vector2(720, 576))
	_add_unique(_panel, _pool, "Pool", false)
	_feedback = Ornate.label("", 23, Ornate.ERROR)
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ornate.place(_panel, _feedback, Vector2(60, 816), Vector2(1580, 44))
	_add_unique(_panel, _feedback, "Feedback", false)
	_validate = Ornate.HexButton.new()
	_validate.caption = "Valider"
	_validate.highlighted = true
	_validate.font_size = 40
	Ornate.place(_panel, _validate, Vector2(450, 868), Vector2(380, 82))
	_add_unique(_panel, _validate, "Validate", false)
	_close = Ornate.PillButton.new()
	_close.caption = "Quitter la tablette"
	_close.font_size = 26
	Ornate.place(_panel, _close, Vector2(900, 878), Vector2(360, 62))
	_add_unique(_panel, _close, "Close", false)
	var cross := CloseCross.new()
	Ornate.place(_panel, cross, Vector2(1592, 26), Vector2(70, 70))
	cross.pressed.connect(_on_close_pressed)


## Donne un nom unique au nœud (%Nom), comme dans une scène, pour les tests et les autres scripts.
func _add_unique(parent: Node, node: Node, unique: String, attach := true) -> void:
	if attach:
		parent.add_child(node)
	node.name = unique
	node.owner = self
	node.unique_name_in_owner = true


class StoneSlot:
	extends Button
	## Case de pierre gravée : un chiffre romain dans un médaillon, et le fragment posé écrit à l'encre ;
	## rouge à l'erreur, verte à la réussite.

	var numeral := ""
	var text_value := ""
	var mark := 0
	## Un fragment est choisi : la case s'éclaire au survol pour inviter à l'y poser.
	var armed := false

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)

	func _draw() -> void:
		if size.x < 40.0 or size.y < 30.0:
			return
		var rect := Rect2(Vector2.ZERO, size)
		var shape := Ornate.chamfered(rect, 14)
		var tint := TabletPuzzle.STONE
		var line := Ornate.GOLD_DARK
		if mark == TabletPuzzle.Mark.WRONG:
			tint = tint.lerp(TabletPuzzle.WRONG, 0.35)
			line = TabletPuzzle.WRONG
		elif mark == TabletPuzzle.Mark.RIGHT:
			tint = tint.lerp(TabletPuzzle.RIGHT, 0.3)
			line = TabletPuzzle.RIGHT
		elif armed and is_hovered():
			tint = tint.lightened(0.12)
			line = Ornate.GOLD_LIGHT
		var low := tint.darkened(0.35)
		draw_polygon(shape, PackedColorArray([tint, tint, tint.lerp(low, 0.5), low, low, low, tint.lerp(low, 0.5), tint]))
		draw_polyline(Ornate.closed(shape), line, 3.0)
		# Bordure gravée en creux, puis le médaillon du chiffre.
		var inner := Ornate.chamfered(rect.grow(-7), 9)
		draw_polyline(Ornate.closed(inner), TabletPuzzle.STONE_DARK, 2.0)
		var medal := Vector2(50, size.y / 2)
		draw_circle(medal, 30, TabletPuzzle.STONE_DARK)
		draw_arc(medal, 30, 0, TAU, 32, line, 2.5)
		var digits := Ornate.GOLD if mark == TabletPuzzle.Mark.NONE else line
		Ornate.centered_text(self, Ornate.SERIF, medal, numeral, 24, digits)
		var left := 96.0
		var width := size.x - left - 22.0
		if text_value.is_empty():
			Ornate.centered_text(self, Ornate.TEXT, Vector2(left + width / 2, size.y / 2), "emplacement vide", 22,
				Color(0.2, 0.18, 0.18))
			return
		var font := Ornate.TEXT
		var font_size := 21
		var block := font.get_multiline_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, width, font_size)
		var top := (size.y - block.y) / 2.0 + font.get_ascent(font_size)
		draw_multiline_string(font, Vector2(left, top), text_value, HORIZONTAL_ALIGNMENT_LEFT, width, font_size,
			3, Color(0.09, 0.06, 0.05))


class ParchmentCard:
	extends Button
	## Fragment de parchemin : bords irréguliers, encre brune ; doré une fois choisi.

	var text_value := ""
	var seed := 0

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		toggled.connect(func(_on: bool) -> void: queue_redraw())

	func _draw() -> void:
		# Contour déchiré, toujours le même pour un même fragment.
		var random := RandomNumberGenerator.new()
		random.seed = 4021 + seed * 97
		if size.x < 40.0 or size.y < 20.0:
			return
		var points := PackedVector2Array()
		var steps := 14
		for i in steps:
			points.append(Vector2(lerpf(8, size.x - 8, float(i) / steps), random.randf_range(2, 7)))
		for i in 3:
			points.append(Vector2(size.x - random.randf_range(2, 6), lerpf(8, size.y - 8, float(i) / 3)))
		for i in steps:
			points.append(Vector2(lerpf(size.x - 8, 8, float(i) / steps), size.y - random.randf_range(2, 7)))
		for i in 3:
			points.append(Vector2(random.randf_range(2, 6), lerpf(size.y - 8, 8, float(i) / 3)))
		var chosen := button_pressed
		var paper := Color(0.93, 0.85, 0.66) if not is_hovered() else Color(0.97, 0.9, 0.72)
		if chosen:
			draw_colored_polygon(points, Color(Ornate.GOLD, 0.35))
		draw_colored_polygon(points, paper)
		draw_polyline(Ornate.closed(points), Ornate.GOLD_LIGHT if chosen else Color(0.55, 0.38, 0.2), 3.0 if chosen else 1.5)
		var font := Ornate.TEXT
		var font_size := 21
		var width := size.x - 56.0
		var block := font.get_multiline_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, width, font_size)
		var top := (size.y - block.y) / 2.0 + font.get_ascent(font_size)
		draw_multiline_string(font, Vector2(28, top), text_value, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, 3,
			Color(0.24, 0.13, 0.06))


class Glow:
	extends Control
	## Halo du cadre : rouge à l'erreur, vert à la réussite, invisible au repos.

	var color := Color.TRANSPARENT:
		set(value):
			color = value
			queue_redraw()

	func _draw() -> void:
		if color.a <= 0.0:
			return
		for i in 4:
			var shape := Ornate.chamfered(Rect2(Vector2.ONE * i * 4.0, size - Vector2.ONE * i * 8.0), 34)
			draw_polyline(Ornate.closed(shape), Color(color, 0.22 + i * 0.12), 6.0)


class CloseCross:
	extends Button
	## Bouton de fermeture : un octogone doré et une croix, comme celui des indices.

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)

	func _draw() -> void:
		var shape := Ornate.chamfered(Rect2(Vector2.ZERO, size), size.x * 0.28)
		draw_colored_polygon(shape, Color(0.36, 0.2, 0.09) if is_hovered() else Color(0.22, 0.12, 0.08))
		draw_polyline(Ornate.closed(shape), Ornate.GOLD_LIGHT if is_hovered() else Ornate.GOLD, 5.0)
		Ornate.icon(self, "close", size / 2, size.x * 0.3, Ornate.CREAM, 3.5)
