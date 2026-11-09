class_name PaperNotebook
extends CanvasLayer
## Carnet des fragments de papier retrouvés, consultable à tout moment avec la touche I, dans le style des menus
## (scenes/ui/menus/ornate.gd) : chaque fragment est une petite feuille de papier jauni, épinglée dans le carnet.
## Le panneau est construit à l'exécution ; Root, Title et List gardent leur nom unique (%Title…), utilisé par les tests.
## À la manette : Affichage l'ouvre et le referme (comme I), A ou B aussi ; la croix et le stick droit le font défiler.

signal closed

var _root: Control
var _title: Label
var _list: VBoxContainer


## Feuille de papier jauni portant le texte d'un fragment, à la largeur donnée.
static func card(text: String, width: float, font_size := 22) -> PanelContainer:
	var sheet := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.9, 0.83, 0.66)
	box.border_color = Color(0.55, 0.38, 0.18)
	box.set_border_width_all(2)
	box.set_corner_radius_all(3)
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = 5
	box.shadow_offset = Vector2(2, 3)
	box.content_margin_left = 20
	box.content_margin_right = 20
	box.content_margin_top = 14
	box.content_margin_bottom = 14
	sheet.add_theme_stylebox_override("panel", box)
	var label := Ornate.label(text, font_size, Color(0.18, 0.1, 0.05))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(width - 44, 0)
	sheet.add_child(label)
	sheet.custom_minimum_size = Vector2(width, 0)
	return sheet


func _ready() -> void:
	_build()
	_root.hide()
	# Parchemin et clochette à l'ouverture, parchemin replié à la fermeture (scripts/ui_sounds.gd).
	UiSounds.watch(_root)


func _unhandled_input(event: InputEvent) -> void:
	if not _root.visible:
		return
	for action in ["inventory", "interact", "ui_cancel"]:
		if event.is_action_pressed(action):
			get_viewport().set_input_as_handled()
			_root.hide()
			closed.emit()
			return


func is_open() -> bool:
	return _root.visible


func open(fragments: Array[String], total: int) -> void:
	_title.text = "Fragments de papier : %d / %d" % [fragments.size(), total]
	for child in _list.get_children():
		child.queue_free()
	if fragments.is_empty():
		var empty := Ornate.label("Aucun fragment pour l'instant. Fouillez les bureaux, les tiroirs, les armoires, les coffres et les étagères de la mairie.", 26, Ornate.MUTED)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size = Vector2(1060, 0)
		_list.add_child(empty)
	else:
		for text in fragments:
			_list.add_child(card(text, 1060))
	_root.show()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	_own(_root, "Root")
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.02, 0.06, 0.66)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)
	var frame := Ornate.place(_root, Ornate.Frame.new(), Vector2(330, 90), Vector2(1260, 900)) as Ornate.Frame
	frame.title = "Carnet des fragments"
	frame.title_size = 46
	frame.dividers = [124.0, 806.0]
	var book := Ornate.IconView.new()
	book.kind = "book"
	book.color = Ornate.GOLD
	Ornate.place(frame, book, Vector2(80, 44), Vector2(80, 70))
	_title = Ornate.label("", 30, Ornate.GOLD_LIGHT, true)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ornate.place(frame, _title, Vector2(180, 56), Vector2(900, 48))
	_own(_title, "Title")
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	Ornate.place(frame, scroll, Vector2(80, 150), Vector2(1100, 636))
	scroll.name = "Scroll"
	Gamepad.scrollable(scroll, true)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 16)
	scroll.add_child(_list)
	_own(_list, "List")
	# Touches pour refermer le carnet ; à la manette, ses boutons.
	var keys := Ornate.place(frame, Control.new(), Vector2.ZERO, frame.size)
	keys.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Gamepad.swap(keys, false)
	var x := 400.0
	for key in ["I", "E", "Échap"]:
		var cap := Ornate.KeyCap.new()
		cap.text = key
		var width := 64.0 if key.length() == 1 else 118.0
		Ornate.place(keys, cap, Vector2(x, 826), Vector2(width, 56))
		x += width + 16.0
	var hint := Ornate.label("refermer le carnet", 24, Ornate.MUTED)
	Ornate.place(keys, hint, Vector2(x + 8, 836), Vector2(340, 40))
	var buttons := Ornate.place(frame, Control.new(), Vector2.ZERO, frame.size)
	buttons.name = "PadKeys"
	buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Gamepad.swap(buttons, true)
	x = 250.0
	for key in [Gamepad.button_name(&"inventory"), "A", "B"]:
		var cap := Ornate.KeyCap.new()
		cap.pad = key
		Ornate.place(buttons, cap, Vector2(x, 826), Vector2(56, 56))
		x += 72.0
	var pad_hint := Ornate.label("refermer le carnet", 24, Ornate.MUTED)
	Ornate.place(buttons, pad_hint, Vector2(x + 8, 836), Vector2(230, 40))
	var stick := Ornate.KeyCap.new()
	stick.pad = "Stick droit"
	Ornate.place(buttons, stick, Vector2(x + 260, 826), Vector2(56, 56))
	var scroll_hint := Ornate.label("faire défiler", 24, Ornate.MUTED)
	Ornate.place(buttons, scroll_hint, Vector2(x + 330, 836), Vector2(200, 40))


## Rend un nœud accessible par son nom unique (%Nom), comme s'il venait de la scène.
func _own(node: Node, node_name: String) -> void:
	node.name = node_name
	node.owner = self
	node.unique_name_in_owner = true
