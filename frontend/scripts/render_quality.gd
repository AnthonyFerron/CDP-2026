extends CanvasLayer
## Qualité du rendu et compteur d'images.
##
## Sur un écran haute densité (Retina, 4K, portable à 150 %), le navigateur fournit au jeu
## 2 à 4 fois plus de pixels qu'en 1080p. En mode automatique, la 3D est alors calculée
## dans une résolution plus petite puis agrandie ; l'interface et le texte restent nets.
##
## Qualité adaptative (version web) : à chaque arrivée dans un lieu, une fois le fondu fini, le temps d'image
## moyen est mesuré pendant 3 s. Au-delà de 22 ms (moins de 45 i/s), la qualité baisse d'un cran, puis se
## remesure. Elle ne remonte d'un cran qu'entre deux lieux, et seulement si le lieu précédent était très fluide
## (moins de 12 ms) sans avoir baissé. Le cran est retenu dans user://qualite.cfg : les lieux suivants et les
## prochaines visites démarrent directement au bon cran. Les crans, dans l'ordre :
##   1 à 3 : 3D à 85, 70 puis 55 % (l'interface reste nette) ;
##   4 : ombres du soleil allégées (30 m, une découpe, carte de 2048) ;
##   5 : ombres du soleil et des lumières ponctuelles coupées ;
##   6 : décor fin visible moins loin, moitié moins de particules.
## En natif, hors web, rien ne change, sauf avec l'option --qualite-auto (tests). --qualite-cran=N impose un cran.
##
## F3 affiche ou masque le compteur et le cran. F4 change la résolution 3D : auto, 100 %, 75 %, 50 % ; une
## résolution fixe met de côté les crans d'échelle et suspend l'adaptation, jusqu'au retour en auto.
## Le texte du compteur reste en caractères simples : la version web n'a pas de police de secours.

## Nombre de pixels 3D au-delà duquel le mode automatique réduit la résolution.
const PIXEL_BUDGET := 1920 * 1080
const MIN_SCALE := 0.5
## 0 signifie automatique.
const SCALES: Array[float] = [0.0, 1.0, 0.75, 0.5]
## Le compteur est caché au lancement : F3 l'affiche.
const SHOW_BY_DEFAULT := false

## Le cran vient de changer (mesure, changement de lieu ou set_tier).
signal tier_changed(value: int)

const SETTINGS_PATH := "user://qualite.cfg"
## Échelle 3D maximale de chaque cran (1.0 : celle du mode auto, sans plafond).
const TIER_SCALES: Array[float] = [1.0, 0.85, 0.7, 0.55, 0.55, 0.55, 0.55]
const MAX_TIER := 6
const TIER_LIGHT_SHADOWS := 4
const TIER_NO_SHADOWS := 5
const TIER_LESS_DETAIL := 6
## Seuils de la mesure, en millisecondes : au-dessus, un cran de moins ; en dessous, un cran de plus au lieu suivant.
const SLOW_MS := 22.0
const SMOOTH_MS := 12.0
## Images ignorées au début de chaque mesure (shaders compilés, premiers affichages).
const SKIP_FRAMES := 20
## Part des images les plus lentes écartées de la moyenne (à-coups isolés, onglet masqué).
const TRIM := 0.05
const LIGHT_SHADOW_DISTANCE := 30.0
const LIGHT_SHADOW_ATLAS := 2048
const DETAIL_RANGE := 0.6
const PARTICLE_RATIO := 0.5

## Adaptation active : par défaut sur le web seulement.
var adaptive := false
## Durée d'une mesure, en secondes.
var window := 3.0
## Temps d'image imposé, en millisecondes, à la place du temps mesuré (tests). 0 : temps réel.
var forced_ms := 0.0
## Cran courant, de 0 (qualité pleine) à MAX_TIER.
var tier := 0
## Dernière moyenne mesurée, en millisecondes (0 : aucune).
var last_ms := 0.0
## Nombre de mesures terminées depuis le lancement.
var measures := 0

var _scale_index := 0
var _label: Label
var _adapter := ""
var _refresh := 0.0
var _settings_path := SETTINGS_PATH
## Mesure en cours : images restant à ignorer, temps d'image relevés et temps écoulé.
var _measuring := false
var _skip := 0
var _samples: PackedFloat32Array = []
var _elapsed := 0.0
## Ce lieu a été très fluide sans baisser de cran : le prochain lieu remonte d'un cran.
var _rise_next := false
var _lowered_here := false


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
	var args := OS.get_cmdline_user_args()
	adaptive = OS.has_feature("web") or args.has("--qualite-auto")
	# Un test lancé en script garde ses réglages à part, effacés à la fin.
	if get_tree().get_script() != null:
		_settings_path = "user://tests/qualite_%d.cfg" % OS.get_process_id()
	if adaptive:
		tier = _load_tier()
	for arg in args:
		if arg.begins_with("--qualite-cran="):
			tier = clampi(arg.get_slice("=", 1).to_int(), 0, MAX_TIER)
	get_tree().root.size_changed.connect(_apply_scale)
	get_tree().scene_changed.connect(_on_scene_changed)
	_apply_scale()
	print("Rendu : ", _adapter)


func _exit_tree() -> void:
	if _settings_path != SETTINGS_PATH:
		DirAccess.remove_absolute(_settings_path)


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
	if _measuring:
		_measure(delta)
	if not _label.visible:
		return
	_refresh -= delta
	if _refresh > 0.0:
		return
	_refresh = 0.5
	var window_size := DisplayServer.window_get_size()
	var ratio := get_tree().root.scaling_3d_scale
	_label.text = "%d i/s | 3D %d %% (%s) | %dx%d -> %dx%d\ncran %d/%d (%s%s) | %s" % [
		Engine.get_frames_per_second(),
		roundi(ratio * 100.0),
		"auto" if SCALES[_scale_index] == 0.0 else "F4",
		window_size.x, window_size.y,
		roundi(window_size.x * ratio), roundi(window_size.y * ratio),
		tier, MAX_TIER,
		"auto" if adaptive else "fixe",
		" %.1f ms" % last_ms if last_ms > 0.0 else "",
		_adapter,
	]


## Change de cran, l'applique au lieu courant et le retient.
func set_tier(value: int) -> void:
	tier = clampi(value, 0, MAX_TIER)
	_apply_scale()
	_apply_scene()
	_save_tier()
	tier_changed.emit(tier)


## Remet la qualité pleine et l'adaptation à zéro (tests).
func reset_tier() -> void:
	_rise_next = false
	_lowered_here = false
	_measuring = false
	set_tier(0)


func is_measuring() -> bool:
	return _measuring


func _on_scene_changed() -> void:
	# Remontée d'un cran, décidée par le lieu précédent : seulement entre deux lieux.
	if adaptive and _rise_next and tier > 0:
		tier -= 1
		_save_tier()
		_apply_scale()
		tier_changed.emit(tier)
	_rise_next = false
	_lowered_here = false
	_measuring = false
	if not adaptive and tier == 0:
		return
	_apply_scene()
	# Lumières et particules créées à la première image de la scène.
	_apply_scene.call_deferred()
	if adaptive and _has_3d():
		_start_after_transition()


func _start_after_transition() -> void:
	var scene := get_tree().current_scene
	var transition := get_node_or_null("/root/Transition")
	while transition and transition.call("is_busy"):
		await get_tree().process_frame
	if get_tree().current_scene == scene:
		_start_measure()


func _start_measure() -> void:
	_measuring = true
	_skip = SKIP_FRAMES
	_samples.clear()
	_elapsed = 0.0


func _measure(delta: float) -> void:
	# Adaptation suspendue tant qu'une résolution fixe est choisie (F4).
	if SCALES[_scale_index] != 0.0:
		return
	if _skip > 0:
		_skip -= 1
		return
	_elapsed += delta
	_samples.append(forced_ms if forced_ms > 0.0 else delta * 1000.0)
	if _elapsed < window:
		return
	_measuring = false
	measures += 1
	last_ms = _trimmed_mean(_samples)
	if last_ms > SLOW_MS and tier < MAX_TIER:
		_lowered_here = true
		_rise_next = false
		set_tier(tier + 1)
		print("Qualité : %.1f ms, cran %d" % [last_ms, tier])
		_start_measure()
	elif last_ms < SMOOTH_MS and not _lowered_here:
		_rise_next = true


func _trimmed_mean(samples: PackedFloat32Array) -> float:
	if samples.is_empty():
		return 0.0
	var sorted := samples.duplicate()
	sorted.sort()
	var count := maxi(1, sorted.size() - int(sorted.size() * TRIM))
	var total := 0.0
	for index in count:
		total += sorted[index]
	return total / count


func _has_3d() -> bool:
	var scene := get_tree().current_scene
	return scene != null and not scene.find_children("*", "DirectionalLight3D", true, false).is_empty()


func _apply_scale() -> void:
	var root := get_tree().root
	var ratio := SCALES[_scale_index]
	if ratio == 0.0:
		var window_size := DisplayServer.window_get_size()
		var pixels := maxf(1.0, float(window_size.x) * float(window_size.y))
		ratio = clampf(sqrt(PIXEL_BUDGET / pixels), MIN_SCALE, 1.0)
		ratio = minf(ratio, TIER_SCALES[tier])
	root.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	root.scaling_3d_scale = ratio


## Ombres, décor fin et particules du lieu courant, selon le cran. Les valeurs d'origine sont gardées sur chaque
## nœud (méta « rq ») : remonter d'un cran les rend telles que la scène les a.
func _apply_scene() -> void:
	var size: int = ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/size", 4096)
	if tier >= TIER_LIGHT_SHADOWS:
		size = mini(size, LIGHT_SHADOW_ATLAS)
	RenderingServer.directional_shadow_atlas_set_size(size,
			ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/16_bits", true))
	var scene := get_tree().current_scene
	if scene == null:
		return
	for node in scene.find_children("*", "Light3D", true, false):
		var light := node as Light3D
		var base: Dictionary = _original(light, {"shadow": light.shadow_enabled})
		light.shadow_enabled = base.shadow and tier < TIER_NO_SHADOWS
		var sun := light as DirectionalLight3D
		if sun:
			base = _original(sun, {"shadow": base.shadow, "distance": sun.directional_shadow_max_distance,
					"mode": sun.directional_shadow_mode})
			var light_shadows := tier >= TIER_LIGHT_SHADOWS
			sun.directional_shadow_max_distance = minf(base.distance, LIGHT_SHADOW_DISTANCE) if light_shadows else base.distance
			sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL if light_shadows else base.mode
	var less := tier >= TIER_LESS_DETAIL
	for node in scene.find_children("*", "GeometryInstance3D", true, false):
		var mesh := node as GeometryInstance3D
		if mesh.visibility_range_end > 0.0 or mesh.has_meta(&"rq"):
			var range_end: float = _original(mesh, {"end": mesh.visibility_range_end}).end
			mesh.visibility_range_end = range_end * DETAIL_RANGE if less else range_end
	for node in scene.find_children("*", "GPUParticles3D", true, false):
		(node as GPUParticles3D).amount_ratio = PARTICLE_RATIO if less else 1.0
	for node in scene.find_children("*", "CPUParticles3D", true, false):
		var particles := node as CPUParticles3D
		var amount: int = _original(particles, {"amount": particles.amount}).amount
		var wanted := maxi(1, roundi(amount * PARTICLE_RATIO)) if less else amount
		if particles.amount != wanted:
			particles.amount = wanted


func _original(node: Node, values: Dictionary) -> Dictionary:
	if not node.has_meta(&"rq"):
		node.set_meta(&"rq", values)
	var saved: Dictionary = node.get_meta(&"rq")
	# Le soleil passe d'abord par la partie commune aux lumières : on complète ses valeurs.
	for key in values:
		if not saved.has(key):
			saved[key] = values[key]
	return saved


func _load_tier() -> int:
	var config := ConfigFile.new()
	if config.load(_settings_path) != OK:
		return 0
	return clampi(int(config.get_value("qualite", "cran", 0)), 0, MAX_TIER)


func _save_tier() -> void:
	if not adaptive:
		return
	var config := ConfigFile.new()
	config.set_value("qualite", "cran", tier)
	DirAccess.make_dir_recursive_absolute(_settings_path.get_base_dir())
	config.save(_settings_path)
