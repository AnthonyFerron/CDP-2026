class_name FireEffect
extends Node3D
## Flamme : particules qui montent, lumière qui vacille et crépitement, que l'on peut allumer ou éteindre.

@export var lit := true:
	set = set_lit
@export var size := 1.0
@export var light_energy := 2.5
@export var light_range := 7.0
@export var crackle_sound: AudioStream
@export var crackle_volume_db := -6.0

var _flames: CPUParticles3D
var _light: FlickeringLight
var _crackle: AudioStreamPlayer3D


func _ready() -> void:
	_flames = _create_flames()
	add_child(_flames)
	_light = FlickeringLight.new()
	_light.light_color = Color(1.0, 0.55, 0.2)
	_light.light_energy = light_energy
	_light.omni_range = light_range
	_light.flicker = 0.3
	_light.speed = 7.0
	_light.position = Vector3.UP * 0.6 * size
	add_child(_light)
	if crackle_sound:
		_crackle = AudioStreamPlayer3D.new()
		_crackle.stream = crackle_sound
		_crackle.volume_db = crackle_volume_db
		_crackle.unit_size = 2.5
		_crackle.max_distance = 18.0
		add_child(_crackle)
	_refresh()


func set_lit(value: bool) -> void:
	lit = value
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	_flames.emitting = lit
	_light.visible = lit
	if _crackle:
		if lit and not _crackle.playing and not Engine.is_editor_hint():
			_crackle.play()
		elif not lit:
			_crackle.stop()


func _create_flames() -> CPUParticles3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.vertex_color_use_as_albedo = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * 0.35 * size
	quad.material = material
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.85, 0.4, 0.9))
	gradient.set_color(1, Color(0.6, 0.1, 0.02, 0.0))
	gradient.add_point(0.4, Color(1.0, 0.45, 0.1, 0.7))
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 0.2))

	var flames := CPUParticles3D.new()
	flames.mesh = quad
	flames.amount = 28
	flames.lifetime = 0.8
	flames.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	flames.emission_sphere_radius = 0.18 * size
	flames.direction = Vector3.UP
	flames.spread = 12.0
	flames.gravity = Vector3(0.0, 1.2 * size, 0.0)
	flames.initial_velocity_min = 0.3 * size
	flames.initial_velocity_max = 0.8 * size
	flames.scale_amount_curve = curve
	flames.color_ramp = gradient
	return flames
