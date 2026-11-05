extends CanvasLayer
## Qualité du rendu et compteur d'images.
##
## Sur un écran haute densité (Retina, 4K, portable à 150 %), le navigateur fournit au jeu
## 2 à 4 fois plus de pixels qu'en 1080p. En mode automatique, la 3D est alors calculée
## dans une résolution plus petite puis agrandie ; l'interface et le texte restent nets.
##
## F3 affiche ou masque le compteur. F4 change la résolution 3D : auto, 100 %, 75 %, 50 %.
## Le texte du compteur reste en caractères simples : la version web n'a pas de police de secours.

## Nombre de pixels 3D au-delà duquel le mode automatique réduit la résolution.
const PIXEL_BUDGET := 1920 * 1080
const MIN_SCALE := 0.5
## 0 signifie automatique.
const SCALES: Array[float] = [0.0, 1.0, 0.75, 0.5]
## Le compteur est caché au lancement : F3 l'affiche.
const SHOW_BY_DEFAULT := false

var _scale_index := 0
var _label: Label
var _adapter := ""
var _refresh := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 99
	_adapter = "%s (%s)" % [RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_vendor()]
	_label = Label.new()
	_label.position = Vector2(16.0, 12.0)
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_constant_override("outline_size", 6)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.visible = SHOW_BY_DEFAULT
	add_child(_label)
	get_tree().root.size_changed.connect(_apply_scale)
	_apply_scale()
	print("Rendu : ", _adapter)


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not key or not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_F3:
		_label.visible = not _label.visible
		get_viewport().set_input_as_handled()
	elif key.physical_keycode == KEY_F4:
		_scale_index = (_scale_index + 1) % SCALES.size()
		_apply_scale()
		_refresh = 0.0
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _label.visible:
		return
	_refresh -= delta
	if _refresh > 0.0:
		return
	_refresh = 0.5
	var window := DisplayServer.window_get_size()
	var ratio := get_tree().root.scaling_3d_scale
	_label.text = "%d i/s | 3D %d %% (%s) | %dx%d -> %dx%d\n%s" % [
		Engine.get_frames_per_second(),
		roundi(ratio * 100.0),
		"auto" if SCALES[_scale_index] == 0.0 else "F4",
		window.x, window.y,
		roundi(window.x * ratio), roundi(window.y * ratio),
		_adapter,
	]


func _apply_scale() -> void:
	var root := get_tree().root
	var ratio := SCALES[_scale_index]
	if ratio == 0.0:
		var window := DisplayServer.window_get_size()
		var pixels := maxf(1.0, float(window.x) * float(window.y))
		ratio = clampf(sqrt(PIXEL_BUDGET / pixels), MIN_SCALE, 1.0)
	root.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	root.scaling_3d_scale = ratio
