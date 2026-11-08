class_name Hud
extends CanvasLayer
## Interface de jeu, dans l'habillage des menus (scenes/ui/menus/ornate.gd) : invite d'interaction et messages sur des
## cartouches dorés à coins coupés, touches du clavier dessinées en touches (Ornate.KeyCap), lecteur de textes dans un
## cadre doré à plaque de titre, fondu au noir, chronomètre du volcan sur une plaque et pénalités. Quand le volcan
## entre en éruption, le joueur est ramené au hub, où se joue la seule fin d'une partie perdue : la cinématique du
## Mont Sam Altan qui explose (HubEnding).
##
## Couches : le HUD est dessiné sous les panneaux d'énigme (couche 2 : tablette, runes, cercles, dispositif des codes,
## carnet), sauf le chronomètre, sur sa propre couche (Clock, couche 3) : le joueur voit le temps qui lui reste pendant
## qu'il résout une énigme. Sa plaque, en haut à droite, ne recouvre ni le titre, ni la croix, ni les boutons d'aucun
## panneau, ni le bandeau « Mauvaise réponse » (couche 35). Le menu pause (40), les indices (41) et la transition (60)
## passent par-dessus.
##
## Coût par image : le chronomètre ne réécrit son texte qu'une fois par seconde, et les cartouches ne se redessinent
## que quand leur texte change. Ils sont faits de quadrilatères (draw_primitive, draw_line épais) : le rendu
## Compatibility les regroupe en un appel de dessin par cartouche, là où chaque polygone (draw_polygon, draw_polyline,
## Ornate.diamond) en coûte un.

signal reader_closed

@export var message_duration := 4.0
@export var fade_duration := 0.35
## Sous ce temps restant, en secondes, le chronomètre passe au rouge.
@export var warning_time := 5.0 * 60.0

## Place du bandeau « Mauvaise réponse », en coordonnées de référence (1920 × 1080). En haut par défaut, sur le titre
## des panneaux d'énigme : il ne cache ni le cadran ni les boutons du Marais, ni les runes du Désert, ni la tablette
## de la Plaine. Le dispositif du Village, dont le cadre s'arrête au-dessus de y = 770, l'appelle en bas pendant
## qu'il est ouvert, puis le remet en haut. Centré, il s'arrête avant la plaque du chronomètre (x = 1442).
const WARNING_TOP := Vector2(490, 14)
const WARNING_BOTTOM := Vector2(490, 770)
const WARNING_SIZE := Vector2(940, 124)
static var warning_position := WARNING_TOP

## Cartouche d'un message : marges autour du texte et largeur de texte au-delà de laquelle il passe à la ligne.
const MESSAGE_PADDING := Vector2(44, 14)
const MESSAGE_MAX_WIDTH := 1160.0
## Cartouche de l'invite : hauteur, marge de chaque côté, touche et écart entre la touche et le texte.
const PROMPT_HEIGHT := 64.0
const PROMPT_PADDING := 24.0
const KEY_SIZE := Vector2(50, 44)
const KEY_GAP := 16.0
## Hauteur de la plaque du titre du lecteur, à cheval sur le bord haut du cadre.
const TITLE_HEIGHT := 76.0
## Touche entre crochets dans un message, comme « [I] » : la lettre est entourée d'une touche du clavier.
const KEY_PATTERN := "\\[([^\\[\\]\\s]{1,8})\\]"
## Action de chaque touche citée dans les messages : la manette en main, son bouton remplace la touche (Gamepad).
const KEY_ACTIONS := {"E": &"interact", "I": &"inventory", "H": &"hint", "Échap": &"pause", "Espace": &"jump"}
## Fond des cartouches : celui des cadres des menus (Ornate.PANEL), un peu translucide pour laisser voir le jeu.
const PLATE_FILL := Color(0.14, 0.08, 0.07, 0.86)
## Chronomètre au rouge : texte, bordure et dégradé de la plaque.
const ALERT := Color(1.0, 0.42, 0.32)
const ALERT_BORDER := Color(1.0, 0.42, 0.28)
const PLAQUE_TOP := Color(0.38, 0.22, 0.1, 0.94)
const PLAQUE_LOW := Color(0.22, 0.12, 0.07, 0.94)
const ALERT_TOP := Color(0.3, 0.08, 0.05, 0.94)
const ALERT_LOW := Color(0.16, 0.05, 0.04, 0.94)

var _message_tween: Tween
var _warning_tween: Tween
## Avertissement d'une mauvaise réponse, au-dessus des panneaux d'énigme.
var _warning_layer: CanvasLayer
var _warning: Control
var _warning_text: Label
## Touches dessinées : celle de l'invite, et celles des messages (une par « [X] », réutilisées d'un message à l'autre).
var _prompt_key: Ornate.KeyCap
var _message_keys: Array[Ornate.KeyCap] = []
var _key_regex := RegEx.create_from_string(KEY_PATTERN)
## Texte du message affiché, tel qu'il a été donné : il est remis en page quand le joueur change de manette à clavier.
var _message_source := ""
var _reader_frame: Ornate.Frame
var _reader_plaque: Control
## Dernier état affiché du chronomètre : il ne change qu'une fois par seconde.
var _shown_seconds := -1
var _alert := false

@onready var _prompt: Label = %Prompt
@onready var _prompt_plate: Control = $PromptPlate
@onready var _message: Label = %Message
@onready var _message_plate: Control = $MessagePlate
@onready var _reader: Control = %Reader
@onready var _reader_panel: Control = $Reader/Panel
@onready var _reader_title: Label = %ReaderTitle
@onready var _reader_body: Label = %ReaderBody
@onready var _fade: ColorRect = %Fade
@onready var _crosshair: ColorRect = %Crosshair
@onready var _clock: CanvasLayer = $Clock
@onready var _timer_plate: Control = $Clock/TimerPlate
@onready var _timer: Label = %Timer
@onready var _penalty: Label = %Penalty


func _ready() -> void:
	warning_position = WARNING_TOP
	_build_frames()
	set_prompt("")
	_set_message_shown(false)
	_reader.hide()
	_penalty.hide()
	_fade.modulate.a = 0.0
	GameState.time_penalized.connect(_on_time_penalized)
	_build_warning()
	# Le chronomètre et le bandeau sont sur leurs propres couches : elles suivent la visibilité du HUD (cinématiques).
	visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()
	GameState.erupted.connect(_on_erupted)
	# Avis de la synchronisation avec le serveur : connexion perdue ou rétablie, refus.
	GameSync.notice.connect(show_message)
	# Touches du clavier ou boutons de la manette, selon ce que le joueur vient de toucher.
	Gamepad.watch(_on_pad_mode)
	_refresh_timer()
	# Partie perdue pendant un changement de lieu : la fin suit dès l'arrivée. Le hub la joue lui-même.
	if GameState.has_erupted and not get_parent() is Hub:
		_on_erupted.call_deferred()


func _process(_delta: float) -> void:
	_refresh_timer()


func _unhandled_input(event: InputEvent) -> void:
	if not _reader.visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_reader.hide()
		_crosshair.show()
		reader_closed.emit()


## Invite d'interaction, précédée de la touche E.
func set_prompt(text: String) -> void:
	_show_prompt(text, true)


## Invite affichée telle quelle, sans touche devant : pour « Maintenir E… » par exemple.
func set_raw_prompt(text: String) -> void:
	_show_prompt(text, false)


func show_message(text: String) -> void:
	if _message_tween:
		_message_tween.kill()
	_layout_message(text)
	_message_plate.modulate.a = 1.0
	_set_message_shown(true)
	_message_tween = create_tween()
	_message_tween.tween_interval(message_duration)
	_message_tween.tween_property(_message_plate, "modulate:a", 0.0, 0.6)
	_message_tween.tween_callback(_set_message_shown.bind(false))


func show_text(title: String, body: String) -> void:
	_reader_title.text = title
	_reader_body.text = body
	_fit_reader_plaque()
	_reader.show()
	_crosshair.hide()


func set_crosshair_visible(value: bool) -> void:
	_crosshair.visible = value


func fade(to_black: bool) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 1.0 if to_black else 0.0, fade_duration)
	await tween.finished


## Chronomètre : le texte change une fois par seconde, la couleur au passage sous warning_time, et la plaque disparaît
## une fois les quatre livres posés. Rien n'est refait d'une image à l'autre si rien n'a changé.
func _refresh_timer() -> void:
	var remaining := int(ceil(GameState.time_left))
	if remaining != _shown_seconds:
		_shown_seconds = remaining
		_timer.text = "Éruption du volcan : %d:%02d" % [remaining / 60, remaining % 60]
	var running := GameState.placed_books.size() < GameState.BOOK_COUNT
	if running != _timer.visible or running != _timer_plate.visible:
		_timer.visible = running
		_timer_plate.visible = running
	var alert := GameState.time_left < warning_time
	if alert != _alert:
		_alert = alert
		_timer.modulate = ALERT if alert else Color.WHITE
		_timer_plate.queue_redraw()


func _on_visibility_changed() -> void:
	_clock.visible = visible
	if _warning_layer:
		_warning_layer.visible = visible


## Cartouches, touches et cadre du lecteur, dessinés avec les éléments des menus.
func _build_frames() -> void:
	_message_plate.draw.connect(_draw_plate.bind(_message_plate))
	_prompt_plate.draw.connect(_draw_plate.bind(_prompt_plate))
	_timer_plate.draw.connect(_draw_timer_plate)
	_prompt_key = Ornate.KeyCap.new()
	_prompt_key.text = "E"
	_prompt_key.action = &"interact"
	_prompt_key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Ornate.place(_prompt_plate, _prompt_key, Vector2(PROMPT_PADDING, (PROMPT_HEIGHT - KEY_SIZE.y) / 2.0), KEY_SIZE)
	# Lecteur : le cadre doré des menus, posé 38 px sous le haut du panneau ; la plaque du titre est à cheval sur son
	# bord, sous le titre (%ReaderTitle), qui reste un texte du panneau.
	_reader_frame = Ornate.Frame.new()
	_reader_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Reader/Panel/Backing.add_child(_reader_frame)
	_reader_plaque = Control.new()
	_reader_plaque.name = "TitlePlaque"
	_reader_plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reader_plaque.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_reader_frame.add_child(_reader_plaque)
	_reader_plaque.draw.connect(_draw_reader_plaque)
	var close_key := Ornate.KeyCap.new()
	close_key.text = "E"
	close_key.action = &"interact"
	close_key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	close_key.custom_minimum_size = KEY_SIZE
	var hint: Control = $Reader/Panel/Margin/Content/Hint
	hint.add_child(close_key)
	hint.move_child(close_key, 0)


func _show_prompt(text: String, with_key: bool) -> void:
	_prompt.text = text
	var shown := not text.is_empty()
	_prompt.visible = shown
	_prompt_plate.visible = shown
	if not shown:
		return
	_prompt_key.visible = with_key
	var font := _prompt.get_theme_font(&"font")
	var font_size := _prompt.get_theme_font_size(&"font_size")
	var text_width := ceilf(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x) + 4.0
	var left := PROMPT_PADDING + (KEY_SIZE.x + KEY_GAP if with_key else 6.0)
	var width := left + text_width + PROMPT_PADDING + 6.0
	_prompt.position = Vector2(left, 0.0)
	_prompt.size = Vector2(text_width, PROMPT_HEIGHT)
	_prompt_plate.offset_left = -width / 2.0
	_prompt_plate.offset_right = width / 2.0


func _set_message_shown(value: bool) -> void:
	_message.visible = value
	_message_plate.visible = value


## Met le message dans son cartouche, à la largeur du texte (au plus MESSAGE_MAX_WIDTH, au-delà il passe à la ligne).
## Chaque « [X] » devient la lettre X dans une touche du clavier, avec un peu d'espace autour.
##
## La manette en main, la touche devient le bouton lié à son action (KEY_ACTIONS) : une lettre (« Y ») s'écrit dans un
## bouton rond ; un bouton dessiné (Affichage, Menu) prend la place de trois espaces insécables.
func _layout_message(text: String) -> void:
	_message_source = text
	var keys: Array[Vector2i] = []
	var glyphs: Array[String] = []
	var shown := ""
	var last := 0
	for found in _key_regex.search_all(text):
		shown += text.substr(last, found.get_start() - last) + "  "
		var start := shown.length()
		var key := found.get_string(1)
		var glyph := Gamepad.button_name(KEY_ACTIONS[key]) if Gamepad.active and KEY_ACTIONS.has(key) else ""
		if glyph.is_empty():
			shown += key
		elif Ornate.pad_glyph_has_letter(glyph):
			shown += glyph
		else:
			shown += "\u00a0\u00a0\u00a0"
		keys.append(Vector2i(start, shown.length()))
		glyphs.append(glyph)
		shown += "  "
		last = found.get_end()
	shown += text.substr(last)
	_message.text = shown
	var font := _message.get_theme_font(&"font")
	var font_size := _message.get_theme_font_size(&"font_size")
	var width := minf(ceilf(font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x) + 6.0, MESSAGE_MAX_WIDTH)
	_message.position = MESSAGE_PADDING
	_message.size = Vector2(width, 0.0)
	var height := _message.get_minimum_size().y
	_message.size = Vector2(width, height)
	var plate := Vector2(width, height) + MESSAGE_PADDING * 2.0
	_message_plate.offset_left = -plate.x / 2.0
	_message_plate.offset_right = plate.x / 2.0
	_message_plate.offset_bottom = _message_plate.offset_top + plate.y
	for index in _message_keys.size():
		_message_keys[index].visible = index < keys.size()
	for index in keys.size():
		if index >= _message_keys.size():
			var cap := Ornate.KeyCap.new()
			cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_message_plate.add_child(cap)
			# Derrière le texte : la lettre du message est écrite dans la touche.
			_message_plate.move_child(cap, 0)
			_message_keys.append(cap)
		var bounds := _message.get_character_bounds(keys[index].x).merge(_message.get_character_bounds(keys[index].y - 1))
		var size := Vector2(maxf(bounds.size.x + 24.0, KEY_SIZE.x - 6.0), KEY_SIZE.y)
		var cap := _message_keys[index]
		cap.position = _message.position + bounds.get_center() - size / 2.0
		cap.size = size
		cap.pad = glyphs[index]
		cap.bare = Ornate.pad_glyph_has_letter(glyphs[index])
		cap.queue_redraw()


func _on_pad_mode(_pad: bool) -> void:
	if _message.visible:
		_layout_message(_message_source)


## La plaque du titre suit la largeur du titre, comme Ornate.plaque.
func _fit_reader_plaque() -> void:
	var font := _reader_title.get_theme_font(&"font")
	var font_size := _reader_title.get_theme_font_size(&"font_size")
	var width := 0.0
	if not _reader_title.text.is_empty():
		width = font.get_string_size(_reader_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + font_size * 2.6
	_reader_plaque.offset_left = -width / 2.0
	_reader_plaque.offset_right = width / 2.0
	_reader_plaque.offset_top = -TITLE_HEIGHT / 2.0
	_reader_plaque.offset_bottom = TITLE_HEIGHT / 2.0
	_reader_plaque.visible = width > 0.0


## Cartouche de l'invite et des messages : un petit cadre des menus, double bordure dorée, coins coupés et losanges.
func _draw_plate(plate: Control) -> void:
	var rect := Rect2(Vector2.ZERO, plate.size)
	_fill_chamfered(plate, rect, 14.0, PLATE_FILL)
	_outline(plate, Ornate.chamfered(rect, 14.0), Ornate.GOLD, 3.0)
	_outline(plate, Ornate.chamfered(rect.grow(-7.0), 9.0), Ornate.GOLD_DARK, 1.5)
	_diamond(plate, Vector2(0.0, rect.size.y / 2.0), 9.0)
	_diamond(plate, Vector2(rect.size.x, rect.size.y / 2.0), 9.0)


## Plaque hexagonale des titres des menus (Ornate.plaque), sans son texte : celui-ci est un Label posé dessus.
func _draw_plaque(item: Control, top: Color, low: Color, border: Color, with_diamond: bool) -> void:
	var rect := Rect2(Vector2.ZERO, item.size)
	var center := rect.get_center()
	var shape := Ornate.hexagon(rect, rect.size.y * 0.42)
	# Points : haut gauche, haut droite, droite, bas droite, bas gauche, gauche. Deux trapèzes, en dégradé.
	var middle := top.lerp(low, 0.5)
	item.draw_primitive(PackedVector2Array([shape[5], shape[0], shape[1], shape[2]]), PackedColorArray([middle, top, top, middle]), PackedVector2Array())
	item.draw_primitive(PackedVector2Array([shape[5], shape[2], shape[3], shape[4]]), PackedColorArray([middle, middle, low, low]), PackedVector2Array())
	_outline(item, shape, border, 4.0)
	var inset := PackedVector2Array()
	for point in shape:
		inset.append(center + (point - center) * Vector2(0.97, 0.8))
	_outline(item, inset, Ornate.GOLD_DARK, 2.0)
	if with_diamond:
		_diamond(item, Vector2(center.x, rect.end.y), 11.0)


## Fond d'un rectangle à coins coupés, en trois quadrilatères.
func _fill_chamfered(item: CanvasItem, rect: Rect2, cut: float, color: Color) -> void:
	var a := rect.position
	var b := rect.end
	var colors := PackedColorArray([color])
	var none := PackedVector2Array()
	item.draw_primitive(PackedVector2Array([Vector2(a.x + cut, a.y), Vector2(b.x - cut, a.y), Vector2(b.x, a.y + cut), Vector2(a.x, a.y + cut)]), colors, none)
	item.draw_primitive(PackedVector2Array([Vector2(a.x, a.y + cut), Vector2(b.x, a.y + cut), Vector2(b.x, b.y - cut), Vector2(a.x, b.y - cut)]), colors, none)
	item.draw_primitive(PackedVector2Array([Vector2(a.x, b.y - cut), Vector2(b.x, b.y - cut), Vector2(b.x - cut, b.y), Vector2(a.x + cut, b.y)]), colors, none)


## Contour fermé, un trait épais par côté, prolongé aux coins pour qu'ils se rejoignent.
func _outline(item: CanvasItem, points: PackedVector2Array, color: Color, width: float) -> void:
	for index in points.size():
		var a := points[index]
		var b := points[(index + 1) % points.size()]
		var along := (b - a).normalized() * width * 0.3
		item.draw_line(a - along, b + along, color, width)


## Losange des menus (Ornate.diamond) : bord clair, fond sombre et cœur doré.
func _diamond(item: CanvasItem, center: Vector2, radius: float) -> void:
	for layer: Array in [[radius + 1.5, Ornate.GOLD_LIGHT], [radius - 0.5, Ornate.GOLD_DARK], [radius * 0.62, Ornate.GOLD]]:
		var r: float = layer[0]
		item.draw_primitive(PackedVector2Array([center + Vector2(0, -r), center + Vector2(r, 0), center + Vector2(0, r), center + Vector2(-r, 0)]),
			PackedColorArray([layer[1]]), PackedVector2Array())


func _draw_reader_plaque() -> void:
	_draw_plaque(_reader_plaque, Color(0.38, 0.22, 0.1), Color(0.22, 0.12, 0.07), Ornate.GOLD, true)


func _draw_timer_plate() -> void:
	if _alert:
		_draw_plaque(_timer_plate, ALERT_TOP, ALERT_LOW, ALERT_BORDER, false)
	else:
		_draw_plaque(_timer_plate, PLAQUE_TOP, PLAQUE_LOW, Ornate.GOLD, false)


## Bandeau « Mauvaise réponse » : une couche à part, au-dessus des panneaux d'énigme où la réponse est validée,
## et sous le menu pause.
func _build_warning() -> void:
	_warning_layer = CanvasLayer.new()
	_warning_layer.name = "Warning"
	_warning_layer.layer = 35
	add_child(_warning_layer)
	_warning = Ornate.Frame.new()
	_warning.name = "Banner"
	_warning.bottom_diamond = false
	_warning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Ornate.place(_warning_layer, _warning, WARNING_TOP, WARNING_SIZE)
	var title := Ornate.label("Mauvaise réponse", 40, Color(1.0, 0.45, 0.3), true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ornate.place(_warning, title, Vector2(0, 10), Vector2(WARNING_SIZE.x, 56))
	_warning_text = Ornate.label("", 25)
	_warning_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_warning_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Ornate.place(_warning, _warning_text, Vector2(40, 66), Vector2(WARNING_SIZE.x - 80, 44))
	# Le « −5:00 » rejoint le bandeau, à droite du titre : sous le chronomètre, il chevauchait le haut des panneaux
	# d'énigme et la croix de fermeture de la tablette.
	_penalty.reparent(_warning, false)
	_penalty.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_penalty.position = Vector2(WARNING_SIZE.x - 240, 10)
	_penalty.size = Vector2(200, 56)
	_warning.modulate.a = 0.0
	_warning.hide()


func show_penalty_warning(seconds: float) -> void:
	var minutes := int(round(seconds / 60.0))
	var remaining := int(ceil(GameState.time_left))
	_warning_text.text = "Le Mont Sam Altan gronde : %d minute%s perdue%s, il reste %d:%02d." % [
		minutes, "s" if minutes > 1 else "", "s" if minutes > 1 else "", remaining / 60, remaining % 60]
	_warning.position = warning_position
	_warning.show()
	if _warning_tween:
		_warning_tween.kill()
	_warning_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_warning_tween.tween_property(_warning, "modulate:a", 1.0, 0.2)
	_warning_tween.tween_interval(3.5)
	_warning_tween.tween_property(_warning, "modulate:a", 0.0, 0.6)
	_warning_tween.tween_callback(_warning.hide)


func _on_time_penalized(seconds: float) -> void:
	if not GameState.has_erupted:
		show_penalty_warning(seconds)
	# Le « −5:00 » est dans le bandeau : il apparaît et s'efface avec lui.
	_penalty.text = "−%d:%02d" % [int(seconds) / 60, int(seconds) % 60]
	_penalty.modulate.a = 1.0
	_penalty.show()


## Le chronomètre est à zéro, dans un lieu comme au hub : retour au hub, qui joue l'éruption du volcan. Une transition
## déjà en cours ignore celle-ci ; le HUD du lieu d'arrivée la relance (_ready).
func _on_erupted() -> void:
	_close_panels()
	_crosshair.hide()
	set_prompt("")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Transition.change_scene(GameState.HUB_SCENE)


## Partie perdue : tout ce qui est ouvert se ferme avant la fin, quel que soit le lieu. Les panneaux d'énigme et le
## carnet sont des CanvasLayer du niveau (tablette, runes, cercles, dispositif des codes…) ; s'y ajoutent le texte en
## lecture, le bandeau « Mauvaise réponse » et l'indice. Le joueur ne reprend pas la main : la fin suit.
func _close_panels() -> void:
	_reader.hide()
	_set_message_shown(false)
	if _warning_tween:
		_warning_tween.kill()
	_warning.hide()
	for layer: CanvasLayer in get_parent().find_children("*", "CanvasLayer", true, false):
		if layer != self and not is_ancestor_of(layer):
			layer.hide()
	if Hints.is_open():
		Hints.close()
