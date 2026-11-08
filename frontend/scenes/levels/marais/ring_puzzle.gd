class_name RingPuzzle
extends CanvasLayer
## Vue rapprochée du mécanisme aux cinq cercles, dans le style des menus (Ornate). Le cadran montre les cinq
## anneaux de pierre gravés de l'alphabet, chacun tournant sous le repère doré ; en dessous, une colonne par
## cercle, du centre vers le bord : la lettre choisie, grande et lisible, entre deux flèches. « Valider » vérifie
## le mot. À l'erreur, les lettres rougissent et le panneau tremble ; à la réussite, les cercles verdissent et le
## panneau s'efface pendant que le tombeau s'ouvre.

signal validated(correct: bool)
signal closed

const SOLUTION := "FLGFD"
## Lueur des lettres : or au repos, rouge à l'erreur, vert à la réussite.
const COLOR_IDLE := Color(1.0, 0.82, 0.45)
const COLOR_WRONG := Color(1.0, 0.25, 0.15)
const COLOR_RIGHT := Color(0.45, 1.0, 0.55)
## Panneau, en coordonnées de référence (1920 × 1080), à droite : le mécanisme en 3D reste visible à gauche.
const FRAME_RECT := Rect2(1010, 140, 860, 916)
const DIAL_CENTER := Vector2(430, 565)
const DIAL_INNER := 62.0
const DIAL_RING := 25.0
const NUMERALS := ["I", "II", "III", "IV", "V"]
const COLUMN_LEFT := 55.0
const COLUMN_STEP := 150.0

var _mechanism: RingMechanism
var _open := false
var _state := COLOR_IDLE
## Lettre affichée par chaque cercle du cadran, en fraction de lettre pendant qu'il tourne.
var _shown: Array[float] = []
var _turns: Array[Tween] = []
var _flash: Tween
## Énigme déjà résolue (livre trouvé) : le panneau montre le code, sans qu'on puisse le refaire.
var _solved := false

var _root: Control
var _frame: Ornate.Frame
var _glow: Glow
var _dial: Dial
var _tiles: Array[LetterTile] = []
var _feedback: Label
var _validate: Ornate.HexButton
var _close: Ornate.HexButton


func _ready() -> void:
	_shown.resize(RingMechanism.RING_COUNT)
	_shown.fill(0.0)
	_turns.resize(RingMechanism.RING_COUNT)
	_build()
	_root.hide()
	# Parchemin et clochette à l'ouverture, parchemin replié à la fermeture (scripts/ui_sounds.gd).
	UiSounds.watch(_root)
	_validate.pressed.connect(validate)
	_close.pressed.connect(_on_close_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if _open and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_close_pressed()


func is_open() -> bool:
	return _open


func open(mechanism: RingMechanism) -> void:
	_mechanism = mechanism
	_open = true
	if _flash:
		_flash.kill()
	_root.modulate.a = 1.0
	_root.position = Vector2.ZERO
	_validate.disabled = false
	_close.disabled = false
	for ring in RingMechanism.RING_COUNT:
		_shown[ring] = _mechanism.letters[ring]
	_set_state(COLOR_IDLE)
	_set_feedback("", Ornate.MUTED)
	_refresh()
	_root.show()


## Livre déjà trouvé : les cercles montrent le code, en vert ; on ne peut plus les tourner ni valider, seulement quitter.
func open_solved(mechanism: RingMechanism) -> void:
	open(mechanism)
	_solved = true
	_mechanism.set_letters(SOLUTION)
	for ring in RingMechanism.RING_COUNT:
		_shown[ring] = _mechanism.letters[ring]
	_validate.disabled = true
	_set_state(COLOR_RIGHT)
	_set_feedback("Énigme résolue : le tombeau est ouvert. Le livre a déjà été trouvé.", Ornate.SUCCESS)


func is_solved() -> bool:
	return _solved


func turn(ring: int, step: int) -> void:
	if _solved:
		return
	_mechanism.rotate_ring(ring, step)
	# Le cadran tourne par le plus court chemin jusqu'à la nouvelle lettre.
	var count := RingMechanism.LETTERS.length()
	var target: float = _mechanism.letters[ring]
	var start := _shown[ring]
	var delta := wrapf(target - start, -count * 0.5, count * 0.5)
	if _turns[ring]:
		_turns[ring].kill()
	_turns[ring] = create_tween()
	_turns[ring].tween_method(_turn_step.bind(ring), start, start + delta, 0.22).set_trans(Tween.TRANS_SINE)
	if _state != COLOR_IDLE:
		_set_state(COLOR_IDLE)
		_set_feedback("", Ornate.MUTED)
	_refresh()


func validate() -> void:
	if not _open or _solved:
		return
	var correct := _mechanism.code() == SOLUTION
	if correct:
		_succeed()
	else:
		# Le temps perdu est annoncé par le bandeau « Mauvaise réponse » du HUD : ici, seulement ce que l'on voit.
		_set_feedback("Les inscriptions rougissent et un grondement roule dans la crypte.", Ornate.ERROR)
		_flash_wrong()
	validated.emit(correct)


## Construit le panneau : cadre doré, cadran des cinq anneaux, colonnes des lettres, message et boutons.
func _build() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_own(_root)
	_frame = Ornate.place(_root, Ornate.Frame.new(), FRAME_RECT.position, FRAME_RECT.size) as Ornate.Frame
	_frame.name = "Panel"
	_own(_frame)
	_frame.title = "Le tombeau du chiffrement"
	_frame.title_size = 40
	_frame.bottom_diamond = false
	_frame.dividers = [334.0]
	_glow = Ornate.place(_frame, Glow.new(), Vector2.ZERO, FRAME_RECT.size) as Glow
	var instruction := Ornate.label("Tournez chaque cercle pour placer une lettre sous le repère doré, du cercle intérieur au cercle extérieur.", 22, Ornate.MUTED)
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Ornate.place(_frame, instruction, Vector2(60, 50), Vector2(FRAME_RECT.size.x - 120, 64))
	_dial = Ornate.place(_frame, Dial.new(), Vector2.ZERO, FRAME_RECT.size) as Dial
	_dial.puzzle = self
	for ring in RingMechanism.RING_COUNT:
		var x := COLUMN_LEFT + ring * COLUMN_STEP
		var numeral := Ornate.label("Cercle " + NUMERALS[ring], 22, Ornate.GOLD, true)
		numeral.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		Ornate.place(_frame, numeral, Vector2(x - 10, 120), Vector2(COLUMN_STEP, 32))
		var tile := LetterTile.new()
		Ornate.place(_frame, tile, Vector2(x + 25, 154), Vector2(80, 92))
		_tiles.append(tile)
		var left := ArrowButton.new()
		left.direction = -1
		Ornate.place(_frame, left, Vector2(x + 2, 256), Vector2(60, 50))
		left.pressed.connect(turn.bind(ring, -1))
		var right := ArrowButton.new()
		right.direction = 1
		Ornate.place(_frame, right, Vector2(x + 68, 256), Vector2(60, 50))
		right.pressed.connect(turn.bind(ring, 1))
	_feedback = Ornate.label("", 23, Ornate.MUTED)
	_feedback.name = "Feedback"
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Ornate.place(_frame, _feedback, Vector2(50, 782), Vector2(FRAME_RECT.size.x - 100, 38))
	_own(_feedback)
	_validate = Ornate.HexButton.new()
	_validate.name = "Validate"
	_validate.caption = "Valider"
	_validate.highlighted = true
	_validate.font_size = 38
	Ornate.place(_frame, _validate, Vector2(70, 822), Vector2(340, 80))
	_own(_validate)
	_close = Ornate.HexButton.new()
	_close.name = "Close"
	_close.caption = "Se relever"
	_close.font_size = 34
	Ornate.place(_frame, _close, Vector2(450, 822), Vector2(340, 80))
	_own(_close)


## Rend un nœud construit ici accessible par son nom unique (%Validate, %Feedback…), comme dans une scène.
func _own(node: Node) -> void:
	node.owner = self
	node.unique_name_in_owner = true


func _turn_step(value: float, ring: int) -> void:
	_shown[ring] = value
	_dial.queue_redraw()


func _refresh() -> void:
	for ring in _tiles.size():
		_tiles[ring].letter = RingMechanism.LETTERS[_mechanism.letters[ring]] if _mechanism else "A"
		_tiles[ring].color = _state
		_tiles[ring].queue_redraw()
	_dial.queue_redraw()


func _set_state(color: Color) -> void:
	_state = color
	_glow.color = color
	_glow.queue_redraw()
	_refresh()


func _set_feedback(text: String, color: Color) -> void:
	_feedback.text = text
	_feedback.add_theme_color_override("font_color", color)


func _flash_wrong() -> void:
	if _flash:
		_flash.kill()
	_set_state(COLOR_WRONG)
	_flash = create_tween()
	# Le sol de la crypte gronde : le panneau tremble, puis les lettres reprennent leur éclat d'or.
	_flash.tween_method(_shake_step, 0.0, 1.0, 0.6)
	_flash.tween_callback(_shake_step.bind(1.0))
	_flash.tween_interval(0.9)
	_flash.tween_callback(_set_state.bind(COLOR_IDLE))


func _shake_step(progress: float) -> void:
	var amount := 14.0 * (1.0 - progress)
	_root.position = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))


## Les cercles verdissent ; le panneau ne répond plus et s'efface pendant que le couvercle glisse.
func _succeed() -> void:
	_open = false
	if _flash:
		_flash.kill()
	_root.position = Vector2.ZERO
	_validate.disabled = true
	_close.disabled = true
	_set_state(COLOR_RIGHT)
	_set_feedback("Les cercles s'illuminent de vert : le mécanisme s'active.", Ornate.SUCCESS)
	_flash = create_tween()
	_flash.tween_interval(0.7)
	_flash.tween_property(_root, "modulate:a", 0.0, 0.8)
	_flash.tween_callback(_root.hide)


func _on_close_pressed() -> void:
	if not _open:
		return
	_open = false
	_root.hide()
	closed.emit()


## Liseré de lueur autour du cadre, de la couleur des lettres.
class Glow:
	extends Control

	var color := RingPuzzle.COLOR_IDLE

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var outline := Ornate.chamfered(Rect2(Vector2.ZERO, size).grow(7), 34)
		draw_polyline(Ornate.closed(outline), Color(color, 0.45), 5.0)
		draw_polyline(Ornate.closed(Ornate.chamfered(Rect2(Vector2.ZERO, size).grow(13), 38)), Color(color, 0.18), 6.0)


## Le cadran : cinq anneaux de pierre gravés de l'alphabet, qui tournent chacun sous le repère doré du haut.
## La lettre sous le repère brille ; les autres sont gravées en creux.
class Dial:
	extends Control

	var puzzle: RingPuzzle

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center := RingPuzzle.DIAL_CENTER
		var count := RingMechanism.LETTERS.length()
		var step := TAU / count
		var outer := RingPuzzle.DIAL_INNER + RingMechanism.RING_COUNT * RingPuzzle.DIAL_RING
		# Socle de pierre sombre et son anneau doré.
		draw_circle(center, outer + 22, Color(0.12, 0.1, 0.09))
		draw_arc(center, outer + 22, 0.0, TAU, 96, Ornate.GOLD, 4.0)
		draw_arc(center, outer + 13, 0.0, TAU, 96, Ornate.GOLD_DARK, 2.0)
		# Fenêtre du repère : une bande claire du centre au bord, sous les lettres choisies.
		var window := PackedVector2Array([center + Vector2(-16, -RingPuzzle.DIAL_INNER + 4), center + Vector2(16, -RingPuzzle.DIAL_INNER + 4),
			center + Vector2(30, -outer), center + Vector2(-30, -outer)])
		for ring in RingMechanism.RING_COUNT:
			var inner := RingPuzzle.DIAL_INNER + ring * RingPuzzle.DIAL_RING
			var middle := inner + RingPuzzle.DIAL_RING * 0.5
			var stone := Color(0.4, 0.37, 0.34) if ring % 2 == 0 else Color(0.3, 0.28, 0.26)
			draw_arc(center, middle, 0.0, TAU, 96, stone, RingPuzzle.DIAL_RING - 3.0)
			draw_arc(center, inner + 0.5, 0.0, TAU, 96, Color(0.08, 0.07, 0.06), 2.0)
		draw_colored_polygon(window, Color(puzzle._state, 0.13))
		for ring in RingMechanism.RING_COUNT:
			var inner := RingPuzzle.DIAL_INNER + ring * RingPuzzle.DIAL_RING
			var middle := inner + RingPuzzle.DIAL_RING * 0.5
			var shown: float = puzzle._shown[ring]
			var chosen := wrapi(roundi(shown), 0, count)
			var font_size := int(clampf(middle * 0.13, 15.0, 24.0))
			for index in count:
				var angle := -PI * 0.5 + (index - shown) * step
				var point := center + Vector2.from_angle(angle) * middle
				var lit := index == chosen
				var color: Color = puzzle._state if lit else Color(0.14, 0.12, 0.11)
				var letter_size := font_size + (6 if lit else 0)
				# Lettre gravée dans le sens de l'anneau, son pied tourné vers le centre.
				draw_set_transform(point, angle + PI * 0.5)
				if not lit:
					# Liseré clair sous le creux de la gravure.
					Ornate.centered_text(self, Ornate.SERIF, Vector2(0.8, 1.2), RingMechanism.LETTERS[index], letter_size, Color(0.55, 0.52, 0.48, 0.55))
				Ornate.centered_text(self, Ornate.SERIF, Vector2.ZERO, RingMechanism.LETTERS[index], letter_size, color)
				draw_set_transform(Vector2.ZERO)
		# Moyeu et repère doré, pointé vers le centre, au-dessus de l'anneau extérieur.
		draw_circle(center, RingPuzzle.DIAL_INNER - 4, Color(0.34, 0.31, 0.29))
		draw_arc(center, RingPuzzle.DIAL_INNER - 4, 0.0, TAU, 48, Ornate.GOLD_DARK, 3.0)
		Ornate.diamond(self, center, 18, puzzle._state)
		var tip := center + Vector2(0, -outer - 4)
		var marker := PackedVector2Array([tip, tip + Vector2(-20, -30), tip + Vector2(20, -30)])
		draw_colored_polygon(marker, Ornate.GOLD)
		draw_polyline(Ornate.closed(marker), Ornate.GOLD_LIGHT, 2.0)


## La lettre choisie sur un cercle : une tuile de pierre, sa lettre grande, de la couleur de l'état.
class LetterTile:
	extends Control

	var letter := "A"
	var color := RingPuzzle.COLOR_IDLE

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var shape := Ornate.chamfered(rect, 14)
		var top := Color(0.38, 0.34, 0.3)
		var low := Color(0.2, 0.18, 0.16)
		draw_polygon(shape, PackedColorArray([top, top, top, low, low, low, low, top]))
		draw_polyline(Ornate.closed(Ornate.chamfered(rect.grow(-6), 9)), Color(0.1, 0.08, 0.07), 2.0)
		draw_polyline(Ornate.closed(shape), color, 3.0)
		draw_circle(size / 2, size.x * 0.36, Color(color, 0.16))
		Ornate.centered_text(self, Ornate.SERIF, size / 2 + Vector2(1.5, 2.0), letter, 62, Color(0.05, 0.04, 0.03, 0.8))
		Ornate.centered_text(self, Ornate.SERIF, size / 2, letter, 62, color)


## Flèche dessinée (les polices du jeu n'ont pas de flèches) sur un petit bouton de pierre à bord doré.
class ArrowButton:
	extends Button

	var direction := 1

	func _ready() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		button_down.connect(queue_redraw)
		button_up.connect(queue_redraw)

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var shape := Ornate.hexagon(rect, size.y * 0.3)
		var lit := is_hovered()
		var top := Color(0.5, 0.31, 0.13) if lit else Color(0.27, 0.16, 0.1)
		var low := Color(0.3, 0.17, 0.07) if lit else Color(0.16, 0.09, 0.06)
		if is_pressed():
			top = top.darkened(0.2)
			low = low.darkened(0.2)
		draw_polygon(shape, PackedColorArray([top, top, top.lerp(low, 0.5), low, low, top.lerp(low, 0.5)]))
		draw_polyline(Ornate.closed(shape), Ornate.GOLD_LIGHT if lit else Ornate.GOLD, 3.0)
		var c := size / 2
		var d := float(direction)
		var arrow := PackedVector2Array([c + Vector2(13 * d, 0), c + Vector2(-9 * d, -13), c + Vector2(-9 * d, 13)])
		draw_colored_polygon(arrow, Ornate.CREAM if lit else Ornate.GOLD_LIGHT)
