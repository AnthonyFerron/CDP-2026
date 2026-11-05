class_name DesertWhirlwinds
extends Node3D
## Tourbillons de sable : les vents brûlants de Pythania lèvent des colonnes de sable qui errent dans les dunes,
## loin du chemin et du monument. Chacun est un entonnoir transparent où le sable tourne (whirlwind.gdshader),
## un nuage de grains qui tourne à son pied, et son sifflement. Sans collision : le joueur peut les traverser.

const SHADER := preload("res://scenes/levels/desert/whirlwind.gdshader")
## Tourbillons : centre de leur boucle (x, z), demi-axes de la boucle (x, z), hauteur, vitesse de la boucle.
## Les boucles restent dans les dunes, hors de l'allée, de la muraille et de la salle des colonnes.
const LOOPS := [
	[Vector2(32.0, 24.0), Vector2(12.0, 9.0), 9.0, 0.05],
	[Vector2(-41.0, 9.0), Vector2(9.0, 13.0), 7.5, -0.06],
	[Vector2(6.0, -50.0), Vector2(15.0, 4.5), 11.0, 0.04],
]
## Au-delà de cette distance, l'entonnoir et ses grains disparaissent en fondu.
const VISIBLE_RANGE := 110.0

@export var terrain: DesertTerrain
@export var sound: AudioStream

var _winds: Array[Dictionary] = []
var _time := 0.0


func _ready() -> void:
	if not terrain.is_node_ready():
		await terrain.ready
	var noise := FastNoiseLite.new()
	noise.seed = 77
	noise.frequency = 0.03
	noise.fractal_octaves = 3
	var texture := NoiseTexture2D.new()
	texture.width = 128
	texture.height = 128
	texture.seamless = true
	texture.noise = noise
	for index in LOOPS.size():
		_winds.append(_build(index, LOOPS[index], texture))
	_move(0.0)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_move(delta)


func _move(delta: float) -> void:
	_time += delta
	for wind in _winds:
		var center: Vector2 = wind.center
		var axes: Vector2 = wind.axes
		var a: float = wind.phase + _time * float(wind.speed)
		# Une boucle déformée : le tourbillon ne repasse jamais tout à fait au même endroit.
		var spot := center + Vector2(cos(a) * axes.x + sin(a * 2.7) * axes.x * 0.25, sin(a) * axes.y + cos(a * 1.9) * axes.y * 0.25)
		var node: Node3D = wind.node
		node.position = Vector3(spot.x, terrain.surface_height(spot.x, spot.y), spot.y)


func _build(index: int, loop: Array, noise: Texture2D) -> Dictionary:
	var height: float = loop[2]
	var root := Node3D.new()
	root.name = "Whirlwind%d" % index
	add_child(root)
	# L'entonnoir, plus large en haut, posé le pied dans le sable.
	var funnel := CylinderMesh.new()
	funnel.top_radius = height * 0.24
	funnel.bottom_radius = 0.35
	funnel.height = height
	funnel.radial_segments = 18
	funnel.rings = 10
	funnel.cap_top = false
	funnel.cap_bottom = false
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("noise", noise)
	material.set_shader_parameter("height", height)
	material.set_shader_parameter("phase", index * 2.1)
	material.set_shader_parameter("spin", 1.4 + index * 0.25)
	material.set_shader_parameter("sway", height * 0.1)
	funnel.material = material
	var mesh := MeshInstance3D.new()
	mesh.mesh = funnel
	mesh.position.y = height / 2.0 - 0.1
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.visibility_range_end = VISIBLE_RANGE
	mesh.visibility_range_end_margin = 10.0
	mesh.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	root.add_child(mesh)
	root.add_child(_grains(height))
	if sound:
		var whistle := AudioStreamPlayer3D.new()
		whistle.stream = sound
		whistle.position.y = 1.5
		whistle.unit_size = 5.0
		whistle.max_distance = 40.0
		whistle.volume_db = -4.0
		whistle.pitch_scale = 1.25 + index * 0.1
		whistle.autoplay = true
		whistle.finished.connect(whistle.play)
		root.add_child(whistle)
	var loop_axes: Vector2 = loop[1]
	return {"node": root, "center": loop[0], "axes": loop_axes, "speed": loop[3], "phase": index * 2.3}


## Le nuage de grains au pied du tourbillon : des taches douces qui tournent, montent et retombent.
func _grains(height: float) -> CPUParticles3D:
	var soft := Gradient.new()
	soft.set_color(0, Color(1, 1, 1, 1))
	soft.set_color(1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = soft
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 32
	texture.height = 32
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = texture
	var quad := QuadMesh.new()
	quad.size = Vector2(1.8, 1.8)
	quad.material = material
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.85, 0.68, 0.46, 0.0))
	ramp.set_color(1, Color(0.85, 0.68, 0.46, 0.0))
	ramp.add_point(0.25, Color(0.8, 0.62, 0.42, 0.42))
	ramp.add_point(0.7, Color(0.8, 0.62, 0.42, 0.24))
	var grains := CPUParticles3D.new()
	grains.mesh = quad
	grains.amount = 40
	grains.lifetime = 2.2
	grains.preprocess = 2.2
	grains.local_coords = false
	grains.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	grains.emission_sphere_radius = 1.1
	grains.direction = Vector3.UP
	grains.spread = 35.0
	grains.gravity = Vector3(0.0, -0.6, 0.0)
	grains.initial_velocity_min = 1.0
	grains.initial_velocity_max = height * 0.3
	grains.tangential_accel_min = 4.0
	grains.tangential_accel_max = 7.0
	grains.radial_accel_min = -1.5
	grains.radial_accel_max = -0.5
	grains.scale_amount_min = 0.7
	grains.scale_amount_max = 1.8
	grains.color_ramp = ramp
	grains.position.y = 0.6
	grains.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	grains.visibility_range_end = VISIBLE_RANGE
	return grains
