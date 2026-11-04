class_name WillOWisps
extends Node3D
## Feux follets : de petites lueurs vertes qui flottent au-dessus des eaux, dérivent lentement autour de leur point
## d'attache et palpitent. Un cœur brillant et un halo tourné vers la caméra, sans lumière réelle (le halo et
## l'éclat suffisent, et la version web garde ses performances).

## Points d'attache : position (x, y, z) et rayon de dérive (w).
@export var anchors: Array[Vector4] = []
## Nombre de feux par point d'attache.
@export var counts: PackedInt32Array = PackedInt32Array()
@export var color := Color(0.55, 1.0, 0.75)

var _wisps: Array[Dictionary] = []
var _time := 0.0


func _ready() -> void:
	var core_material := StandardMaterial3D.new()
	core_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_material.albedo_color = Color(color.r * 2.6, color.g * 2.6, color.b * 2.6)
	var core := SphereMesh.new()
	core.radius = 0.06
	core.height = 0.12
	core.radial_segments = 8
	core.rings = 4
	core.material = core_material

	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 0.9))
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var halo_material := StandardMaterial3D.new()
	halo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	halo_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	halo_material.albedo_texture = texture
	halo_material.albedo_color = Color(color.r, color.g, color.b, 0.55)
	halo_material.no_depth_test = false
	var halo := QuadMesh.new()
	halo.size = Vector2(0.7, 0.7)
	halo.material = halo_material

	var rng := RandomNumberGenerator.new()
	rng.seed = 707
	for index in anchors.size():
		var anchor := anchors[index]
		var count := counts[index] if index < counts.size() else 1
		for i in count:
			var wisp := Node3D.new()
			add_child(wisp)
			var core_instance := MeshInstance3D.new()
			core_instance.mesh = core
			core_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			wisp.add_child(core_instance)
			var halo_instance := MeshInstance3D.new()
			halo_instance.mesh = halo
			halo_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			wisp.add_child(halo_instance)
			_wisps.append({
				"node": wisp,
				"center": Vector3(anchor.x, anchor.y, anchor.z),
				"radius": anchor.w * rng.randf_range(0.35, 1.0),
				"speed": Vector3(rng.randf_range(0.12, 0.3), rng.randf_range(0.5, 0.9), rng.randf_range(0.12, 0.3)),
				"phase": Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU),
				"pulse": rng.randf_range(1.5, 3.2),
			})
	_place(0.0)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	_place(_time)


## Chaque feu décrit une boucle lente autour de son point d'attache, monte et descend, et palpite.
func _place(time: float) -> void:
	for wisp: Dictionary in _wisps:
		var speed: Vector3 = wisp.speed
		var phase: Vector3 = wisp.phase
		var radius: float = wisp.radius
		var offset := Vector3(
			sin(time * speed.x + phase.x) * radius,
			sin(time * speed.y + phase.y) * 0.3,
			cos(time * speed.z + phase.z) * radius
		)
		var node: Node3D = wisp.node
		node.position = wisp.center + offset
		node.scale = Vector3.ONE * (0.8 + 0.3 * sin(time * wisp.pulse + phase.y))
