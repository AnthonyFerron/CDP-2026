class_name ShaderWarmup
extends Node
## Préparation des shaders au menu d'accueil. Le rendu Compatibility compile le shader d'un matériau la première fois
## qu'il le dessine, pour chaque variante (brouillard, soleil et ses ombres, lumières ponctuelles, instances, ombre
## projetée) : sur un nouvel ordinateur, cela donnait des saccades pendant les premières minutes de jeu.
##
## Pendant que le joueur est au menu, ce nœud dessine hors de l'écran, dans un SubViewport minuscule qui n'est affiché
## nulle part, chaque matériau de l'inventaire (ShaderWarmList, assets/shader_warm_list.tres, fait par
## tools/bake_shaders.gd), un par image, dans les conditions de son lieu. Après une image qui a compilé, le menu
## souffle autant d'images qu'il le faut pour que la préparation prenne au plus la moitié du temps. Elle s'arrête dès
## qu'une transition commence (le joueur lance une partie) : ce qui reste sera compilé en jeu, comme avant. Un retour
## au menu reprend où elle s'était arrêtée.
##
## Seulement dans un jeu exporté (web, Windows), avec un affichage. Ailleurs (éditeur, tests), --prechauffage l'active.

const LIST_PATH := "res://assets/shader_warm_list.tres"
const VIEW_SIZE := Vector2i(64, 64)
## Images laissées au menu pour s'afficher avant de commencer.
const START_FRAMES := 20
## Au plus tant d'images de repos après une image qui a compilé.
const MAX_REST := 30
## Repères de la scène de préparation : la caméra regarde vers -Z ; à gauche, sous une lumière ponctuelle ; à
## droite, hors de sa portée (le shader n'a pas la même variante).
const LIT := Vector3(-0.6, 0.0, -3.0)
const UNLIT := Vector3(0.6, 0.0, -3.0)
const OMNI_RANGE := 0.8
## Crans de qualité (les autoloads ne sont pas encore connus quand ce script est compilé avec un test).
const Quality := preload("res://scripts/render_quality.gd")

## Liste gardée pour toute la session : ses matériaux tiennent en vie les shaders générés qu'ils partagent avec ceux
## des lieux (un StandardMaterial3D de mêmes réglages a le même shader). Sans eux, ce qui a été compilé serait libéré.
static var _kept: ShaderWarmList
## Où reprendre : groupe, entrée et passage suivants. Chaque entrée est dessinée en deux images : hors de la lumière
## ponctuelle avec son ombre projetée, puis sous la lumière ponctuelle (moins de programmes compilés par image).
static var _group_index := 0
static var _entry_index := 0
static var _lit_pass := false
static var _finished := false

## Entrées dessinées, groupes finis et temps passé depuis le début, pour les mesures.
var drawn := 0
var elapsed_ms := 0

var _loading := false
var _frames := 0
var _rest := 0
var _base_ms := 16.0
var _last_usec := 0
var _start_msec := 0
var _sliced := false
var _viewport: SubViewport
var _camera: Camera3D
var _lights: Node3D
var _batch: Node3D
var _box := BoxMesh.new()
var _multimesh_cache := {}
var _group_ready := -1


static func enabled() -> bool:
	var args := OS.get_cmdline_user_args()
	if DisplayServer.get_name() == "headless" or args.has("--sans-prechauffage"):
		return false
	return OS.has_feature("template") or args.has("--prechauffage")


## Toutes les entrées de l'inventaire ont été dessinées.
static func is_finished() -> bool:
	return _finished


func _ready() -> void:
	name = "ShaderWarmup"
	if _finished or not enabled():
		set_process(false)
		return
	_box.size = Vector3(0.3, 0.3, 0.3)
	_start_msec = Time.get_ticks_msec()


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var frame_ms := (now - _last_usec) / 1000.0 if _last_usec > 0 else 0.0
	_last_usec = now
	var transition := get_node_or_null(^"/root/Transition")
	if get_tree().paused or (transition and transition.call(&"is_busy")):
		_stop()
		return
	_frames += 1
	if _frames < START_FRAMES:
		return
	if _kept == null:
		_load()
		return
	if _viewport == null:
		_build_view()
	_clear_batch()
	# Image qui a dessiné une tranche : le menu souffle d'autant ; sinon, elle donne le temps d'une image ordinaire.
	if _sliced:
		_sliced = false
		_rest = clampi(int(frame_ms / maxf(_base_ms, 4.0)) - 1, 0, MAX_REST)
	elif frame_ms > 0.0:
		_base_ms = lerpf(_base_ms, frame_ms, 0.2)
	if _rest > 0:
		_rest -= 1
		return
	elapsed_ms = Time.get_ticks_msec() - _start_msec
	if not _next_slice():
		_finished = true
		_stop()


func _load() -> void:
	if not _loading:
		_loading = ResourceLoader.load_threaded_request(LIST_PATH, "", false) == OK
		if not _loading:
			_stop()
		return
	var status := ResourceLoader.load_threaded_get_status(LIST_PATH)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		return
	_kept = ResourceLoader.load_threaded_get(LIST_PATH) as ShaderWarmList if status == ResourceLoader.THREAD_LOAD_LOADED else null
	if _kept == null:
		push_warning("Préparation des shaders : %s illisible" % LIST_PATH)
		_stop()


func _build_view() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "View"
	_viewport.size = VIEW_SIZE
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	# Mêmes réglages 3D que l'écran : l'échelle choisit, avec la lueur, où se fait le mappage des tons.
	var root := get_tree().root
	_viewport.scaling_3d_mode = root.scaling_3d_mode
	_viewport.scaling_3d_scale = root.scaling_3d_scale
	add_child(_viewport)
	_camera = Camera3D.new()
	_camera.near = 0.05
	_camera.far = 30.0
	_viewport.add_child(_camera)
	_lights = Node3D.new()
	_viewport.add_child(_lights)
	_batch = Node3D.new()
	_viewport.add_child(_batch)


## Dessine l'entrée suivante. Faux quand l'inventaire est fini.
func _next_slice() -> bool:
	while _group_index < _kept.groups.size():
		var group: Dictionary = _kept.groups[_group_index]
		if _group_ready != _group_index:
			_setup_group(group)
			_group_ready = _group_index
			_render()
			return true
		var materials: Array = group.materials
		var labels: Array = group.labels
		var process: Array = group.process
		var index := _entry_index
		var lit := _lit_pass
		# Le passage sous la lumière ponctuelle n'existe que si le lieu en a, et pas pour les particules.
		_lit_pass = not lit and bool(group.omni) and index < materials.size() + labels.size()
		if not _lit_pass:
			_entry_index += 1
		var spot := LIT if lit else UNLIT
		if index < materials.size():
			var usage: int = (group.usages as PackedByteArray)[index]
			_add_material(materials[index] as Material, usage, spot, not lit and usage & ShaderWarmList.SHADOW)
		elif index < materials.size() + labels.size():
			_add_label(labels[index - materials.size()] as Dictionary, spot, not lit)
		elif index < materials.size() + labels.size() + process.size():
			_add_particles(process[index - materials.size() - labels.size()] as Material)
		else:
			_group_index += 1
			_entry_index = 0
			continue
		drawn += 1
		_render()
		return true
	return false


func _render() -> void:
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	_sliced = true


## Lumières et environnement du groupe, avec les ombres du cran de qualité courant.
func _setup_group(group: Dictionary) -> void:
	for light in _lights.get_children():
		light.free()
	var environment := group.environment as Environment
	_camera.environment = environment
	var quality := get_node_or_null(^"/root/RenderQuality")
	var tier: int = quality.get(&"tier") if quality else 0
	for settings: Dictionary in group.suns:
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-55.0, 30.0, 0.0)
		sun.shadow_enabled = bool(settings.shadow) and tier < Quality.TIER_NO_SHADOWS
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL if tier >= Quality.TIER_LIGHT_SHADOWS \
			else int(settings.mode)
		sun.directional_shadow_blend_splits = bool(settings.blend)
		sun.directional_shadow_max_distance = 20.0
		_lights.add_child(sun)
	if group.omni:
		var omni := OmniLight3D.new()
		omni.position = LIT + Vector3(0.0, 0.4, 0.3)
		omni.omni_range = OMNI_RANGE
		_lights.add_child(omni)


func _add_material(material: Material, usage: int, spot: Vector3, shadow: bool) -> void:
	var geometry: GeometryInstance3D
	if usage & ShaderWarmList.INSTANCED:
		var instances := MultiMeshInstance3D.new()
		instances.multimesh = _multimesh()
		geometry = instances
	else:
		var mesh := MeshInstance3D.new()
		mesh.mesh = _box
		geometry = mesh
	geometry.material_override = material
	_place(geometry, spot, shadow)


func _add_label(settings: Dictionary, spot: Vector3, shadow: bool) -> void:
	var label := Label3D.new()
	for property in settings:
		if property != "font" or settings.font != null:
			label.set(property, settings[property])
	label.text = "Aa"
	label.pixel_size = 0.01
	_place(label, spot, shadow and label.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)


func _add_particles(material: Material) -> void:
	var particles := GPUParticles3D.new()
	particles.amount = 1
	particles.process_material = material
	particles.draw_pass_1 = _box
	_place(particles, UNLIT, false)


func _place(geometry: GeometryInstance3D, spot: Vector3, shadow: bool) -> void:
	geometry.position = spot
	geometry.rotation_degrees = Vector3(20.0, 35.0, 0.0)
	geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow \
		else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_batch.add_child(geometry)


func _multimesh() -> MultiMesh:
	if not _multimesh_cache.has(0):
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.use_colors = true
		multimesh.use_custom_data = true
		multimesh.mesh = _box
		multimesh.instance_count = 1
		_multimesh_cache[0] = multimesh
	return _multimesh_cache[0]


func _clear_batch() -> void:
	if _batch:
		for child in _batch.get_children():
			child.free()


## Arrêt : plus rien n'est dessiné. Les programmes compilés restent, et la liste aussi (_kept).
func _stop() -> void:
	set_process(false)
	if _viewport:
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		_viewport.queue_free()
		_viewport = null
	elapsed_ms = Time.get_ticks_msec() - _start_msec
