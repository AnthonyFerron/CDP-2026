class_name Gamepad
extends Node
## Manette, en disposition standard (celle de l'API Gamepad des navigateurs, d'une manette Xbox) : le jeu se joue en
## entier sans clavier ni souris. Les commandes sont dans docs/manette.md.
##
## Ce script est chargé en autoload sous le nom GamepadInput. Le reste du jeu passe par ses fonctions statiques
## (Gamepad.active, Gamepad.setup…), qui ne nomment aucun autoload : Ornate et le clavier virtuel s'en servent, et un
## test lancé avec --script les compile avant que les autoloads n'existent.
##
## Bascule automatique : un bouton de la manette, ou un stick poussé à plus de moitié, passe en mode manette ; une touche
## du clavier, un clic ou un vrai mouvement de la souris revient au clavier. En mode manette :
## - les invites et les rappels de commandes montrent les boutons de la manette (Ornate.KeyCap, Ornate.pad_glyph) ;
## - les boutons des menus et des panneaux prennent le focus, la croix et le stick gauche le déplacent, A valide et
##   B revient en arrière ; le bouton qui a le focus porte un cadre doré (Ornate.focus_ring) ;
## - le survol de la souris ne s'affiche plus ;
## - A sur un champ de saisie ouvre le clavier virtuel (PadKeyboard) ;
## - le stick droit fait défiler les listes (carnet, fragments, classement).
## Au clavier et à la souris, rien ne change : les boutons ne prennent jamais le focus (FOCUS_NONE), comme avant.

## Le joueur vient de se servir de la manette.
static var active := false
static var _node: Gamepad
static var _no_focus := StyleBoxEmpty.new()
## Abonnements pris avant que l'autoload ne soit prêt (PauseMenu et Hints sont chargés avant lui).
static var _pending: Array[Callable] = []

signal mode_changed(pad: bool)

## Boutons et panneaux qui prennent le focus en mode manette (Gamepad.setup).
const FOCUS_GROUP := &"pad_focus"
## Champs de saisie : ils gardent toujours leur focus clavier, la manette les atteint aussi.
const TEXT_GROUP := &"pad_text"
## Dessins qui changent avec le mode (touche du clavier ou bouton de la manette) : redessinés à chaque bascule.
const GLYPH_GROUP := &"pad_glyph"
## Nœuds visibles dans un seul mode (méta « pad » : vrai pour la manette, faux pour le clavier).
const SWAP_GROUP := &"pad_swap"
## Listes que le stick droit fait défiler (ScrollContainer). Avec la méta « pad_dpad », la croix aussi, quand rien
## n'a le focus (carnet des fragments).
const SCROLL_GROUP := &"pad_scroll"
## Fenêtre modale (confirmation) : le focus reste sur ses boutons tant qu'elle est ouverte.
const MODAL_GROUP := &"pad_modal"
## Contrôle à sélectionner en premier à l'ouverture de son panneau.
const DEFAULT_META := &"pad_default"
## Couche d'un nœud dont le CanvasLayer est caché : il ne compte pas.
const HIDDEN := -(1 << 30)

## Un stick passe en mode manette au-delà de cette inclinaison : la dérive d'un stick au repos n'y suffit pas.
const STICK_SWITCH := 0.5
## Distance de souris, en pixels, qui ramène au clavier : un frôlement du bureau ne compte pas.
const MOUSE_SWITCH := 24.0
## Défilement des listes au stick droit, en pixels de référence par seconde, stick à fond.
const SCROLL_SPEED := 1300.0

## Nom de chaque bouton, tel que l'écrivent les invites et les textes (disposition Xbox, la plus répandue sur ordinateur).
const BUTTON_NAMES := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Affichage", JOY_BUTTON_START: "Menu",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "Croix", JOY_BUTTON_DPAD_DOWN: "Croix", JOY_BUTTON_DPAD_LEFT: "Croix", JOY_BUTTON_DPAD_RIGHT: "Croix",
}
const AXIS_NAMES := {
	JOY_AXIS_LEFT_X: "Stick gauche", JOY_AXIS_LEFT_Y: "Stick gauche", JOY_AXIS_RIGHT_X: "Stick droit",
	JOY_AXIS_RIGHT_Y: "Stick droit", JOY_AXIS_TRIGGER_LEFT: "LT", JOY_AXIS_TRIGGER_RIGHT: "RT",
}

var _mouse_travel := 0.0
## Dernier contrôle sélectionné dans chaque couche : il retrouve le focus quand la couche du dessus se ferme.
var _last_focus := {}
var _scroll_rest := 0.0


func _ready() -> void:
	_node = self
	for callable in _pending:
		if callable.is_valid():
			mode_changed.connect(callable)
	_pending.clear()
	# Les menus pause et indices figent la partie : la manette doit y répondre.
	process_mode = Node.PROCESS_MODE_ALWAYS
	# A valide et B revient en arrière dans tous les panneaux. Les actions ui_accept et ui_cancel de Godot 4.7 n'ont
	# que des touches du clavier : on leur ajoute ces boutons ici, sans réécrire leurs touches dans project.godot.
	_add_button(&"ui_accept", JOY_BUTTON_A)
	_add_button(&"ui_cancel", JOY_BUTTON_B)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _add_button(action: StringName, button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.device = -1
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		if event.pressed:
			# Premier bouton dans un menu : il sélectionne le bouton mis en avant, sans encore le presser ni bouger.
			if _set_active(true):
				get_viewport().set_input_as_handled()
				return
			_on_pad_button(event as InputEventJoypadButton)
	elif event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		var stick := motion.axis <= JOY_AXIS_RIGHT_Y and absf(motion.axis_value) > STICK_SWITCH
		var trigger := motion.axis >= JOY_AXIS_TRIGGER_LEFT and motion.axis_value > STICK_SWITCH
		if (stick or trigger) and _set_active(true):
			get_viewport().set_input_as_handled()
			return
		if active:
			_mouse_travel = 0.0
			_on_pad_motion(motion)
	elif event is InputEventKey:
		if event.pressed:
			_set_active(false)
	elif event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.is_pressed():
			_set_active(false)
	elif event is InputEventMouseMotion and active:
		_mouse_travel += (event as InputEventMouseMotion).relative.length()
		if _mouse_travel > MOUSE_SWITCH:
			_set_active(false)


func _process(delta: float) -> void:
	if not active:
		return
	_ensure_focus()
	_scroll(delta)


func _on_joy_connection_changed(_device: int, connected: bool) -> void:
	if not connected and Input.get_connected_joypads().is_empty():
		_set_active(false)


## Bascule entre la manette et le clavier : focus, invites, rappels de commandes. Vrai si la bascule vers la manette
## vient de sélectionner un bouton (un menu ou un panneau est ouvert).
func _set_active(value: bool) -> bool:
	_mouse_travel = 0.0
	if value == active:
		return false
	active = value
	var owner := get_viewport().gui_get_focus_owner()
	for node in get_tree().get_nodes_in_group(FOCUS_GROUP):
		var control := node as Control
		if not value and control == owner:
			control.release_focus()
		control.focus_mode = Control.FOCUS_ALL if value else Control.FOCUS_NONE
		control.queue_redraw()
	for group in [TEXT_GROUP, GLYPH_GROUP]:
		for node in get_tree().get_nodes_in_group(group):
			(node as CanvasItem).queue_redraw()
	for node in get_tree().get_nodes_in_group(SWAP_GROUP):
		(node as CanvasItem).visible = bool(node.get_meta(&"pad", false)) == value
	mode_changed.emit(value)
	if not value:
		return false
	_ensure_focus()
	var focused_now := get_viewport().gui_get_focus_owner()
	return focused_now != null and focused_now != owner


## Bouton de la manette, avant les menus : sur un champ de saisie, A ouvre le clavier virtuel, B le quitte pour que le
## panneau revienne en arrière, et la croix change de champ (un champ garderait la croix pour son curseur).
func _on_pad_button(event: InputEventJoypadButton) -> void:
	var owner := get_viewport().gui_get_focus_owner()
	if owner is LineEdit and owner.is_visible_in_tree() and not PadKeyboard.is_open():
		var line := owner as LineEdit
		if event.button_index == JOY_BUTTON_A:
			get_viewport().set_input_as_handled()
			if line.editable:
				PadKeyboard.open(self, line)
			return
		if event.button_index == JOY_BUTTON_B:
			# Le champ ne garde pas B pour lui : le panneau (ou le menu) reçoit le retour.
			line.release_focus()
			return
		if _leave_field(line, event):
			return
	elif event.button_index == JOY_BUTTON_A and owner is BaseButton and owner.is_visible_in_tree() and not owner.disabled:
		# Le clic des boutons (scripts/ui_sounds.gd), comme à la souris.
		var sounds := get_node_or_null(^"/root/UiSounds")
		if sounds:
			sounds.click()


func _on_pad_motion(event: InputEventJoypadMotion) -> void:
	var line := get_viewport().gui_get_focus_owner() as LineEdit
	if line and line.is_visible_in_tree() and not PadKeyboard.is_open():
		_leave_field(line, event)


func _leave_field(line: LineEdit, event: InputEvent) -> bool:
	for pair: Array in [[&"ui_left", SIDE_LEFT], [&"ui_right", SIDE_RIGHT], [&"ui_up", SIDE_TOP], [&"ui_down", SIDE_BOTTOM]]:
		if event.is_action_pressed(pair[0]):
			var next := line.find_valid_focus_neighbor(pair[1])
			if next:
				next.grab_focus()
			get_viewport().set_input_as_handled()
			return true
	return false


## En mode manette, un contrôle de la couche la plus haute a toujours le focus : le menu pause par-dessus une énigme,
## le clavier virtuel par-dessus le dispositif des codes. Quand la couche du dessus se ferme, celle du dessous retrouve
## son dernier contrôle sélectionné.
func _ensure_focus() -> void:
	var best_layer := HIDDEN
	var candidates: Array[Control] = []
	for group in [FOCUS_GROUP, TEXT_GROUP]:
		for node in get_tree().get_nodes_in_group(group):
			var control := node as Control
			if not _usable(control):
				continue
			var layer := layer_of(control)
			if layer == HIDDEN:
				continue
			if layer > best_layer:
				best_layer = layer
				candidates.clear()
			if layer == best_layer:
				candidates.append(control)
	if candidates.is_empty():
		return
	for node in get_tree().get_nodes_in_group(MODAL_GROUP):
		var modal := node as Control
		if modal.is_visible_in_tree() and layer_of(modal) == best_layer:
			var inside: Array[Control] = []
			for control in candidates:
				if modal.is_ancestor_of(control):
					inside.append(control)
			candidates = inside
			break
	if candidates.is_empty():
		return
	var owner := get_viewport().gui_get_focus_owner()
	if owner in candidates:
		_last_focus[best_layer] = owner
		return
	# Le dernier sélectionné de la couche a pu être libéré (panneau reconstruit) : il n'est lu qu'une fois vérifié.
	var remembered: Variant = _last_focus.get(best_layer)
	if is_instance_valid(remembered) and remembered in candidates:
		(remembered as Control).grab_focus()
		return
	var chosen := pick_default(candidates)
	if chosen:
		chosen.grab_focus()
		_last_focus[best_layer] = chosen


static func _usable(control: Control) -> bool:
	if not control or control.is_queued_for_deletion() or not control.is_visible_in_tree():
		return false
	if control.focus_mode == Control.FOCUS_NONE:
		return false
	if control is LineEdit and not (control as LineEdit).editable:
		return false
	return true


## Contrôle sélectionné d'office : celui que son panneau désigne (DEFAULT_META), sinon le bouton mis en avant
## (« Reprendre », « Commencer »…), sinon le premier en lisant de haut en bas et de gauche à droite.
static func pick_default(candidates: Array[Control]) -> Control:
	var best: Control = null
	var best_rank := Vector3.INF
	for control in candidates:
		if control is BaseButton and (control as BaseButton).disabled:
			continue
		var tier := 2.0
		if control.get_meta(DEFAULT_META, false):
			tier = 0.0
		elif control.get(&"highlighted") == true:
			tier = 1.0
		var rank := Vector3(tier, control.global_position.y, control.global_position.x)
		if rank < best_rank:
			best_rank = rank
			best = control
	return best if best else (candidates[0] if not candidates.is_empty() else null)


## Couche d'affichage d'un nœud : celle de son CanvasLayer, 0 pour l'écran principal ; très basse si sa couche est cachée.
static func layer_of(node: Node) -> int:
	var parent := node.get_parent()
	while parent:
		if parent is CanvasLayer:
			var canvas := parent as CanvasLayer
			return canvas.layer if canvas.visible else HIDDEN
		parent = parent.get_parent()
	return 0


## Stick droit : la liste visible de la couche la plus haute défile.
func _scroll(delta: float) -> void:
	var axis := Input.get_axis(&"look_up", &"look_down")
	var with_dpad := absf(Input.get_axis(&"ui_up", &"ui_down")) > 0.0
	if absf(axis) < 0.01 and not with_dpad:
		_scroll_rest = 0.0
		return
	var target: ScrollContainer
	var best_layer := HIDDEN
	for node in get_tree().get_nodes_in_group(SCROLL_GROUP):
		var scroll := node as ScrollContainer
		if scroll.is_visible_in_tree() and layer_of(scroll) > best_layer:
			best_layer = layer_of(scroll)
			target = scroll
	if not target:
		return
	if target.get_meta(&"pad_dpad", false) and get_viewport().gui_get_focus_owner() == null:
		axis += Input.get_axis(&"ui_up", &"ui_down")
	_scroll_rest += clampf(axis, -1.0, 1.0) * SCROLL_SPEED * delta
	var step := int(_scroll_rest)
	_scroll_rest -= step
	target.scroll_vertical += step


# --- Fonctions pour les menus et les panneaux ---------------------------------------------------------------

## Bouton des menus ou d'un panneau : il prend le focus en mode manette, jamais au clavier et à la souris.
static func setup(control: Control) -> void:
	control.add_to_group(FOCUS_GROUP)
	control.focus_mode = Control.FOCUS_ALL if active else Control.FOCUS_NONE
	# Le bouton dessine lui-même son cadre de sélection (Ornate.focus_ring) : pas le rectangle du thème par défaut.
	control.add_theme_stylebox_override(&"focus", _no_focus)
	control.focus_entered.connect(control.queue_redraw)
	control.focus_exited.connect(control.queue_redraw)


## Champ de saisie atteignable à la manette (son focus clavier ne change pas).
static func track_text(line: LineEdit) -> void:
	line.add_to_group(TEXT_GROUP)


## Nœud affiché seulement à la manette (pad vrai) ou seulement au clavier (pad faux).
static func swap(node: CanvasItem, pad: bool) -> void:
	node.add_to_group(SWAP_GROUP)
	node.set_meta(&"pad", pad)
	node.visible = pad == active


## Liste que le stick droit fait défiler ; la croix aussi avec dpad, quand rien n'a le focus.
static func scrollable(scroll: ScrollContainer, dpad := false) -> void:
	scroll.add_to_group(SCROLL_GROUP)
	scroll.set_meta(&"pad_dpad", dpad)


## Donne le focus à un contrôle, en mode manette seulement.
static func focus(control: Control) -> void:
	if active and control and control.is_inside_tree() and control.is_visible_in_tree() and control.focus_mode != Control.FOCUS_NONE:
		control.grab_focus()


## Le contrôle a le focus et la manette est en main : il porte le cadre doré.
static func focused(control: Control) -> bool:
	return active and control.has_focus()


## Survol de la souris, qui ne s'affiche plus quand la manette est en main.
static func hovered(control: Control) -> bool:
	return not active and (control as BaseButton).is_hovered() if control is BaseButton else false


## Éclairé : survolé à la souris, ou sélectionné à la manette.
static func lit(control: Control) -> bool:
	return hovered(control) or focused(control)


## Appelle `callable(pad: bool)` à chaque bascule entre la manette et le clavier.
static func watch(callable: Callable) -> void:
	if not _node:
		_pending.append(callable)
	elif not _node.mode_changed.is_connected(callable):
		_node.mode_changed.connect(callable)


## Bouton (ou stick) de la manette lié à une action, tel que l'écrivent les invites : « A », « Menu », « Stick droit »…
static func button_name(action: StringName) -> String:
	if not InputMap.has_action(action):
		return ""
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			return BUTTON_NAMES.get((event as InputEventJoypadButton).button_index, "")
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion:
			return AXIS_NAMES.get((event as InputEventJoypadMotion).axis, "")
	return ""


## Texte qui cite une touche du clavier, récrit pour la manette quand elle est en main : « maintenez E » devient
## « maintenez A », « avec I » devient « avec le bouton Affichage ».
static func adapt(text: String) -> String:
	if not active:
		return text
	var interact := button_name(&"interact")
	for pair: Array in [
		["maintenez E ", "maintenez %s " % interact], ["Maintenez E ", "Maintenez %s " % interact],
		["maintenir E ", "maintenir %s " % interact], ["Maintenir E ", "Maintenir %s " % interact],
		["avec I", "avec le bouton %s" % button_name(&"inventory")], ["avec H", "avec le bouton %s" % button_name(&"hint")],
	]:
		text = text.replace(pair[0], pair[1])
	return text
