class_name HubEnding
extends Node3D
## Les deux fins du jeu, jouées dans le hub par une caméra qui se déplace seule.
## Éruption : la caméra s'approche du volcan, il explose, puis elle recule sur le village englouti par la lave.
## Bonne fin : la caméra s'élève au-dessus du village reconstruit, puis s'approche du volcan endormi.

signal finished

@export var volcano: Volcano
@export var eruption_sound: AudioStream
## Nappe de lave qui monte sur le village pendant l'éruption.
@export var flood_material: Material
@export var flood_radius := 75.0

var _camera: Camera3D
var _overlay: CanvasLayer
var _flash: ColorRect
var _title: Label
var _subtitle: Label
var _shake := 0.0
var _look_target := Vector3.ZERO


func _process(delta: float) -> void:
	if not _camera:
		return
	_camera.look_at(_look_target)
	if _shake > 0.0:
		_shake = maxf(_shake - delta, 0.0)
		_camera.h_offset = randf_range(-1.0, 1.0) * _shake * 0.9
		_camera.v_offset = randf_range(-1.0, 1.0) * _shake * 0.9


func play_eruption() -> void:
	_begin(Vector3(0, 9, 22), _volcano_top())
	await _move(Vector3(-34, 58, -86), _volcano_top(), 4.0, 44.0)
	volcano.erupt()
	_play_sound()
	_shake = 2.2
	await _flash_screen(Color(1.0, 0.6, 0.3), 0.15, 1.4)
	_darken_sky()
	await get_tree().create_timer(2.5).timeout
	_flood_village()
	await _move(Vector3(0, 48, 72), Vector3(0, 0, -18), 5.0, 70.0)
	await _show_title("Le volcan s'est réveillé", "Les livres n'ont pas été réunis à temps. Codia a disparu sous la lave.", Color(1.0, 0.45, 0.25))
	finished.emit()


func play_victory() -> void:
	volcano.set_state(Volcano.State.DORMANT)
	_begin(Vector3(2, 3.2, 9), Vector3(0, 1.6, 0))
	_clear_air()
	await _move(Vector3(0, 30, 58), Vector3(0, 2, -14), 6.5, 68.0)
	await get_tree().create_timer(1.0).timeout
	# Au-dessus du château, pour qu'aucune tour ne cache le volcan.
	await _move(Vector3(-34, 58, -86), _volcano_top(), 5.5, 44.0)
	await _show_title("Le volcan s'est endormi", "Les quatre livres sont réunis. Le rituel a apaisé le volcan, et Codia renaît.", Color(0.95, 0.85, 0.45))
	finished.emit()


func _volcano_top() -> Vector3:
	return volcano.global_position + Vector3.UP * volcano.height * 0.7


func _begin(position: Vector3, target: Vector3) -> void:
	_camera = Camera3D.new()
	_camera.far = 600.0
	_camera.fov = 70.0
	add_child(_camera)
	_camera.global_position = position
	_look_target = target
	_camera.current = true
	_build_overlay()


func _move(position: Vector3, target: Vector3, duration: float, fov: float) -> void:
	var tween := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_camera, "global_position", position, duration)
	tween.tween_property(self, "_look_target", target, duration)
	tween.tween_property(_camera, "fov", fov, duration)
	await tween.finished


func _play_sound() -> void:
	if not eruption_sound:
		return
	var player := AudioStreamPlayer.new()
	player.stream = eruption_sound
	player.volume_db = 2.0
	add_child(player)
	player.play()


func _flash_screen(color: Color, attack: float, release: float) -> void:
	_flash.color = Color(color, 0.0)
	var tween := create_tween()
	tween.tween_property(_flash, "color:a", 0.85, attack)
	tween.tween_property(_flash, "color:a", 0.0, release)
	await tween.finished


## Ciel et brume virent au rouge sombre de la cendre.
func _darken_sky() -> void:
	var environment := get_viewport().world_3d.environment
	if not environment and get_tree().current_scene.has_node("WorldEnvironment"):
		environment = get_tree().current_scene.get_node("WorldEnvironment").environment
	if not environment:
		return
	var sky := environment.sky.sky_material as ProceduralSkyMaterial if environment.sky else null
	var tween := create_tween().set_parallel()
	if sky:
		tween.tween_property(sky, "sky_top_color", Color(0.18, 0.06, 0.05), 4.0)
		tween.tween_property(sky, "sky_horizon_color", Color(0.75, 0.25, 0.08), 4.0)
		tween.tween_property(sky, "ground_horizon_color", Color(0.75, 0.25, 0.08), 4.0)
		tween.tween_property(sky, "ground_bottom_color", Color(0.35, 0.1, 0.05), 4.0)
	tween.tween_property(environment, "fog_light_color", Color(0.45, 0.16, 0.08), 4.0)
	tween.tween_property(environment, "fog_density", 0.008, 4.0)


## Air limpide d'une belle journée : la brume se lève et la lumière se pose, pour que le village se lise de loin.
func _clear_air() -> void:
	var environment: Environment = get_tree().current_scene.get_node("WorldEnvironment").environment
	environment.fog_density = 0.0012
	environment.fog_light_color = Color(0.62, 0.74, 0.88)
	environment.fog_sky_affect = 0.0
	environment.ambient_light_energy = 0.45
	environment.glow_intensity = 0.2
	var sun: DirectionalLight3D = get_tree().current_scene.get_node("Sun")
	sun.light_energy = 1.1
	sun.light_color = Color(1.0, 0.85, 0.66)


## Une nappe de lave monte du sol et recouvre tout le village.
func _flood_village() -> void:
	var lava := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * flood_radius * 2.0
	plane.subdivide_width = 40
	plane.subdivide_depth = 40
	plane.material = flood_material
	lava.mesh = plane
	lava.position = Vector3(0, -1.5, -10)
	get_tree().current_scene.add_child(lava)
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.4, 0.1)
	glow.light_energy = 6.0
	glow.omni_range = 90.0
	glow.position = Vector3(0, 12, -10)
	get_tree().current_scene.add_child(glow)
	create_tween().tween_property(lava, "position:y", 2.2, 6.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _build_overlay() -> void:
	_overlay = CanvasLayer.new()
	_overlay.layer = 5
	add_child(_overlay)
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(0, 0, 0, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(_flash)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	box.anchor_top = 0.62
	box.anchor_bottom = 0.9
	box.anchor_left = 0.1
	box.anchor_right = 0.9
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	_overlay.add_child(box)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 84)
	_title.add_theme_constant_override("outline_size", 18)
	_title.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.03))
	_title.modulate.a = 0.0
	box.add_child(_title)
	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.add_theme_font_size_override("font_size", 34)
	_subtitle.add_theme_constant_override("outline_size", 12)
	_subtitle.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.03))
	_subtitle.modulate.a = 0.0
	box.add_child(_subtitle)


func _show_title(title: String, subtitle: String, color: Color) -> void:
	_title.text = title
	_title.add_theme_color_override("font_color", color)
	_subtitle.text = subtitle
	var tween := create_tween()
	tween.tween_property(_title, "modulate:a", 1.0, 1.2)
	tween.tween_property(_subtitle, "modulate:a", 1.0, 1.0)
	await tween.finished
