class_name PadKeyboard
extends CanvasLayer
## Clavier virtuel, dans le style des menus (Ornate), pour écrire à la manette : réponses du dispositif des codes du
## Village, adresse, mot de passe et pseudo des menus, code de vérification. A sur un champ de saisie sélectionné à la
## manette l'ouvre (scripts/gamepad.gd) ; il écrit dans ce champ, comme le clavier.
##
## À la manette : la croix (ou le stick gauche) choisit une touche et A l'écrit ; X efface, Y met une espace, LB passe
## aux majuscules, RB aux accents et signes ; Menu valide (comme Entrée), B referme le clavier en gardant le texte.
## Il se referme aussi dès que le joueur reprend le clavier ou la souris : le champ retrouve alors la frappe.
##
## Placé en bas de l'écran (y = 612 à 1074) : l'extrait de code du dispositif (jusqu'à y = 582), les champs des menus et
## les cases du code de vérification (jusqu'à y = 608) restent visibles. La question du champ, que le clavier recouvre,
## est rappelée en tête (méta « pad_context » du champ, sinon son texte d'aide).

const LAYER := 45
const ORIGIN := Vector2(330, 612)
const SIZE := Vector2(1260, 462)
const KEY := Vector2(106, 48)
const GAP := 8.0
const ROWS_TOP := 128.0
const LETTERS: Array[String] = ["1234567890", "abcdefghij", "klmnopqrst", "uvwxyz-_.@"]
const SIGNS: Array[String] = ["1234567890", "éèêëàâçùîô", "!?#$%&*+=/", "()'\":;,<>~"]

static var _current: PadKeyboard

var _line: LineEdit
var _boxes: Ornate.CodeBoxes
var _upper := false
var _signs := false
var _keys: Array[KeyButton] = []
var _shift: KeyButton
var _page: KeyButton
var _preview: Label
var _root: Control


## Ouvre le clavier sur un champ ; `host` le porte (l'autoload de la manette, qui reste d'une scène à l'autre).
static func open(host: Node, line: LineEdit) -> void:
	close()
	var keyboard := PadKeyboard.new()
	keyboard._line = line
	keyboard._boxes = line.get_parent() as Ornate.CodeBoxes
	host.add_child(keyboard)
	_current = keyboard


static func is_open() -> bool:
	return is_instance_valid(_current) and not _current.is_queued_for_deletion()


## Referme le clavier ouvert, s'il y en a un, en gardant le texte.
static func close() -> void:
	if is_open():
		_current._finish(false)


## Le clavier ouvert, pour les tests.
static func current() -> PadKeyboard:
	return _current if is_open() else null


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_refresh()
	Gamepad.watch(_on_mode_changed)
	_line.tree_exiting.connect(_on_target_gone)
	_sound(&"open_panel")
	Gamepad.focus(_keys[0])


func _exit_tree() -> void:
	if is_instance_valid(_line) and _line.tree_exiting.is_connected(_on_target_gone):
		_line.tree_exiting.disconnect(_on_target_gone)


func _input(event: InputEvent) -> void:
	var button := event as InputEventJoypadButton
	if not button or not button.pressed or not visible:
		return
	var action := Callable()
	match button.button_index:
		JOY_BUTTON_B:
			action = _finish.bind(false)
		JOY_BUTTON_START:
			action = _finish.bind(true)
		JOY_BUTTON_X:
			action = _erase
		JOY_BUTTON_Y:
			action = _type.bind(" ")
		JOY_BUTTON_LEFT_SHOULDER:
			action = _toggle_upper
		JOY_BUTTON_RIGHT_SHOULDER:
			action = _toggle_signs
	if action.is_valid():
		get_viewport().set_input_as_handled()
		action.call()


func _on_mode_changed(pad: bool) -> void:
	if not pad:
		_finish(false)


func _on_target_gone() -> void:
	if _current == self:
		_current = null
	queue_free()


## Texte du champ : celui du LineEdit, ou les chiffres des six cases du code de vérification.
func text() -> String:
	if _boxes:
		return _boxes.code()
	return _line.text if is_instance_valid(_line) else ""


## Écrit un caractère au curseur du champ (au bout du code, pour les cases du code de vérification).
func type_text(value: String) -> void:
	_type(value)


func _type(value: String) -> void:
	var keep := get_viewport().gui_get_focus_owner()
	if _boxes:
		_boxes.fill(_boxes.code() + value)
	else:
		if _line.max_length > 0 and _line.text.length() + value.length() > _line.max_length:
			return
		var caret := _line.caret_column
		_line.text = _line.text.substr(0, caret) + value + _line.text.substr(caret)
		_line.caret_column = caret + value.length()
	_after_edit(keep)


func _erase() -> void:
	var keep := get_viewport().gui_get_focus_owner()
	if _boxes:
		var code := _boxes.code()
		_boxes.fill(code.substr(0, maxi(code.length() - 1, 0)))
	else:
		var caret := _line.caret_column
		if caret > 0:
			_line.text = _line.text.substr(0, caret - 1) + _line.text.substr(caret)
			_line.caret_column = caret - 1
	_after_edit(keep)


## Les cases du code reprennent le focus quand on les remplit : il revient à la touche pressée.
func _after_edit(keep: Control) -> void:
	if keep and is_ancestor_of(keep) and keep.is_visible_in_tree():
		keep.grab_focus()
	_refresh()


func _toggle_upper() -> void:
	_upper = not _upper
	_refresh()


func _toggle_signs() -> void:
	_signs = not _signs
	_refresh()


func _finish(submit: bool) -> void:
	if is_queued_for_deletion():
		return
	if _current == self:
		_current = null
	hide()
	queue_free()
	_sound(&"close_panel")
	if not is_instance_valid(_line) or not _line.is_inside_tree():
		return
	if _boxes:
		var next := mini(_boxes.code().length(), Ornate.CodeBoxes.COUNT - 1)
		_boxes.boxes[next].grab_focus()
		if submit:
			_boxes.submitted.emit()
	else:
		_line.grab_focus()
		if submit:
			_line.text_submitted.emit(_line.text)


func _sound(method: StringName) -> void:
	var sounds := get_node_or_null(^"/root/UiSounds")
	if sounds:
		sounds.call(method)


func _refresh() -> void:
	var rows := SIGNS if _signs else LETTERS
	for index in _keys.size():
		var character := rows[index / 10][index % 10]
		_keys[index].value = character.to_upper() if _upper else character
		_keys[index].caption = _keys[index].value
		_keys[index].queue_redraw()
	_shift.on = _upper
	_shift.queue_redraw()
	_page.caption = "abc" if _signs else "é ! ?"
	_page.queue_redraw()
	var value := text()
	if not _boxes and is_instance_valid(_line) and _line.secret:
		value = "*".repeat(value.length())
	if value.is_empty():
		_preview.text = "|"
	elif _boxes or not is_instance_valid(_line):
		_preview.text = value + "|"
	else:
		var caret := clampi(_line.caret_column, 0, value.length())
		_preview.text = value.substr(0, caret) + "|" + value.substr(caret)


func _build() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	var frame := Ornate.place(_root, Ornate.Frame.new(), ORIGIN, SIZE) as Ornate.Frame
	frame.name = "Frame"
	frame.title = "Clavier"
	frame.title_size = 30
	frame.bottom_diamond = false
	var context := Ornate.label(_context_text(), 22, Ornate.MUTED)
	context.name = "Context"
	context.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	context.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Ornate.place(frame, context, Vector2(40, 38), Vector2(SIZE.x - 80, 30))
	var box := PreviewBox.new()
	Ornate.place(frame, box, Vector2(64, 70), Vector2(10 * KEY.x + 9 * GAP, 50))
	_preview = Ornate.label("", 30, Ornate.CREAM)
	_preview.name = "Preview"
	_preview.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_preview.text_overrun_behavior = TextServer.OVERRUN_TRIM_CHAR
	Ornate.place(box, _preview, Vector2(24, 0), Vector2(box.size.x - 48, 50))
	# Toutes les touches, et les boutons de la manette du pied, sont dessinés d'un bloc par ce calque (Ornate.KeySheet) :
	# un maillage et leurs lettres, au lieu de deux ou trois appels de dessin par touche.
	var sheet := Ornate.KeySheet.new()
	sheet.name = "KeySheet"
	Ornate.place(frame, sheet, Vector2.ZERO, SIZE)
	var left := (SIZE.x - (10 * KEY.x + 9 * GAP)) / 2.0
	for row in 4:
		for column in 10:
			var key := KeyButton.new()
			key.name = "Key%d%d" % [row, column]
			Ornate.place(frame, key, Vector2(left + column * (KEY.x + GAP), ROWS_TOP + row * (KEY.y + GAP)), KEY)
			sheet.adopt(key)
			key.pressed.connect(func() -> void: _type(key.value))
			_keys.append(key)
	var bottom := ROWS_TOP + 4 * (KEY.y + GAP)
	var wide := Vector2(KEY.x * 2 + GAP, KEY.y)
	var specials: Array = [["Shift", "Maj", _toggle_upper], ["Page", "", _toggle_signs], ["Space", "Espace", _type.bind(" ")],
		["Erase", "Effacer", _erase], ["Submit", "Valider", _finish.bind(true)]]
	for index in specials.size():
		var spec: Array = specials[index]
		var key := KeyButton.new()
		key.name = spec[0]
		key.caption = spec[1]
		key.small = true
		key.special = true
		Ornate.place(frame, key, Vector2(left + index * (wide.x + GAP), bottom), wide)
		sheet.adopt(key)
		key.pressed.connect(spec[2])
		if spec[0] == "Shift":
			_shift = key
		elif spec[0] == "Page":
			_page = key
	# Boutons de la manette, rappelés en pied du clavier.
	var x := 58.0
	for item: Array in [["A", "écrire"], ["X", "effacer"], ["Y", "espace"], ["LB", "majuscules"], ["RB", "signes"],
			["Menu", "valider"], ["B", "fermer"]]:
		var cap := Ornate.KeyCap.new()
		cap.pad = item[0]
		cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var width := 40.0 if String(item[0]).length() == 1 else 54.0
		Ornate.place(frame, cap, Vector2(x, 408), Vector2(width, 36))
		sheet.adopt(cap)
		var hint := Ornate.label(item[1], 20, Ornate.MUTED)
		Ornate.place(frame, hint, Vector2(x + width + 8, 411), Vector2(120, 30))
		x += width + 8 + Ornate.TEXT.get_string_size(item[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 34


func _context_text() -> String:
	if not is_instance_valid(_line):
		return ""
	var context := String(_line.get_meta(&"pad_context", ""))
	if context.is_empty() and _boxes:
		context = "Code de vérification"
	return context if not context.is_empty() else _line.placeholder_text


## Une touche du clavier virtuel : un cadre sombre à coins coupés et bordure dorée, sa lettre en Lora (les minuscules
## de Cinzel ressemblent à ses majuscules).
class KeyButton:
	extends Button

	var caption := ""
	var value := ""
	var small := false
	var special := false
	## Majuscules en cours (touche Maj).
	var on := false

	func _ready() -> void:
		flat = true
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		Gamepad.setup(self)
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		button_down.connect(queue_redraw)
		button_up.connect(queue_redraw)

	func _draw() -> void:
		var sheet := Ornate.KeySheet.of(self)
		if sheet:
			# Dessinée par le calque du clavier, avec les autres touches.
			sheet.queue_redraw()
			return
		var pen := Ornate.Sketch.new(self)
		paint(pen, Rect2(Vector2.ZERO, size))
		pen.draw(self)

	## La touche dans un maillage (Ornate.Sketch), à sa place `rect`.
	func paint(pen: Ornate.Sketch, rect: Rect2) -> void:
		var shape := Ornate.chamfered(rect, 10)
		var lit := Gamepad.lit(self) or on
		var top := Color(0.27, 0.16, 0.1) if not special else Color(0.22, 0.12, 0.08)
		var low := Color(0.16, 0.09, 0.06)
		if lit:
			top = Color(0.62, 0.4, 0.16)
			low = Color(0.4, 0.23, 0.09)
		if is_pressed():
			top = top.darkened(0.2)
			low = low.darkened(0.2)
		pen.polygon_colors(shape, PackedColorArray([top, top, top, low, low, low, low, top]))
		pen.polyline(Ornate.closed(shape), Ornate.GOLD_LIGHT if lit else Ornate.GOLD, 3.0)
		Ornate.centered_text(pen, Ornate.TEXT if not small else Ornate.SERIF, rect.position + size / 2, caption, 30 if not small else 22, Ornate.CREAM)
		if Gamepad.focused(self):
			Ornate.focus_ring(pen, rect, &"chamfer", 10.0)


class PreviewBox:
	extends Control
	## Le texte en cours d'écriture, dans un champ des menus.

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.17, 0.1, 0.08)
		box.border_color = Ornate.GOLD_LIGHT
		box.set_border_width_all(3)
		box.set_corner_radius_all(14)
		draw_style_box(box, Rect2(Vector2.ZERO, size))
