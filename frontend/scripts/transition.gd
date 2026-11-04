extends CanvasLayer
## Transition entre les lieux : l'écran passe au noir, puis le chapitre, le nom du lieu et son énigme apparaissent
## ligne par ligne pendant que la scène suivante se charge. Elle ne se dévoile qu'une fois prête, après ses
## premières images : le chargement reste caché derrière le titre. La partie est en pause pendant la transition,
## chronomètre compris.
##
## Sans affichage (tests en ligne de commande), le changement de scène est immédiat.

## Durée du fondu au noir, du dévoilement, de l'apparition d'une ligne et du délai entre deux lignes.
const FADE_IN := 0.45
const FADE_OUT := 0.7
const LINE_FADE := 0.6
const LINE_DELAY := 0.55
## Temps minimal pendant lequel le titre complet reste affiché.
const HOLD := 1.3
## Images laissées à la nouvelle scène, encore cachée, pour se construire.
const SETTLE_FRAMES := 4

var _busy := false
var _shade: ColorRect
var _lines: VBoxContainer


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_shade = ColorRect.new()
	_shade.name = "Shade"
	_shade.color = Color(0.02, 0.01, 0.03)
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shade.modulate.a = 0.0
	_shade.visible = false
	add_child(_shade)
	_lines = VBoxContainer.new()
	_lines.name = "Lines"
	_lines.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lines.alignment = BoxContainer.ALIGNMENT_CENTER
	_lines.add_theme_constant_override("separation", 18)
	_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shade.add_child(_lines)


func is_busy() -> bool:
	return _busy


## Change de scène derrière la transition. Les lignes vont du chapitre au sous-titre : la deuxième, le nom
## du lieu, est la plus grande ; un trait doré la sépare de la troisième. Sans lignes, simple fondu au noir.
func change_scene(path: String, lines: Array = []) -> void:
	if _busy:
		return
	var tree := get_tree()
	if DisplayServer.get_name() == "headless":
		tree.paused = false
		tree.change_scene_to_file(path)
		return
	_busy = true
	tree.paused = true
	_shade.visible = true
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_clear_lines()
	await _tween(_shade, "modulate:a", 1.0, FADE_IN)
	for index in lines.size():
		_add_line(String(lines[index]), index)
		if index == 1 and lines.size() > 2:
			_add_divider()
		await tree.create_timer(LINE_DELAY, true).timeout
	# Le chargement part une fois le titre affiché : sans fil d'exécution (web), il bloque l'image, mais sur le titre.
	await tree.process_frame
	var started := Time.get_ticks_msec()
	var requested := ResourceLoader.load_threaded_request(path) == OK
	while requested and ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await tree.process_frame
	var scene: PackedScene = ResourceLoader.load_threaded_get(path) if requested else null
	var waited := (Time.get_ticks_msec() - started) / 1000.0
	if not lines.is_empty() and waited < HOLD:
		await tree.create_timer(HOLD - waited, true).timeout
	if scene:
		tree.change_scene_to_packed(scene)
	else:
		tree.change_scene_to_file(path)
	for frame in SETTLE_FRAMES:
		await tree.process_frame
	tree.paused = false
	await _tween(_lines, "modulate:a", 0.0, 0.35)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	await _tween(_shade, "modulate:a", 0.0, FADE_OUT)
	_shade.visible = false
	_clear_lines()
	_busy = false


func _clear_lines() -> void:
	for child in _lines.get_children():
		child.queue_free()
	_lines.modulate.a = 1.0


func _add_line(text: String, index: int) -> void:
	var size: int = [34, 92, 36][mini(index, 2)]
	var color: Color = [Ornate.GOLD, Ornate.CREAM, Ornate.MUTED][mini(index, 2)]
	var line := Ornate.label(text, size, color, index < 2)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if index == 1:
		line.add_theme_color_override("font_shadow_color", Ornate.GOLD_DARK)
		line.add_theme_constant_override("shadow_offset_y", 6)
	line.modulate.a = 0.0
	_lines.add_child(line)
	_tween(line, "modulate:a", 1.0, LINE_FADE)


func _add_divider() -> void:
	var divider := Divider.new()
	divider.custom_minimum_size = Vector2(0, 30)
	divider.modulate.a = 0.0
	_lines.add_child(divider)
	_tween(divider, "modulate:a", 1.0, LINE_FADE)


func _tween(target: Object, property: String, value: float, duration: float) -> void:
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(target, property, value, duration).set_trans(Tween.TRANS_SINE)
	await tween.finished


class Divider:
	extends Control
	## Trait doré sous le nom du lieu.

	func _draw() -> void:
		var y := size.y / 2.0
		Ornate.divider(self, Vector2(size.x / 2.0 - 260.0, y), Vector2(size.x / 2.0 + 260.0, y))
