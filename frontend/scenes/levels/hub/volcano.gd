class_name Volcano
extends Node3D
## Volcan low-poly qui domine le hub, construit par code : un cône à facettes, son cratère et des coulées
## de lave qui suivent ses pentes. Trois états : endormi, en réveil (fissures qui rougeoient, fumée
## légère), en éruption (lave à flots, nuage de rochers sombres et projections incandescentes).
## Vu de loin, depuis un lieu (distant), il n'a que sa fumée et sa lueur : pas de lumière dynamique ni d'éruption.

enum State { DORMANT, AWAKE, ERUPTING }

@export var height := 80.0
@export var base_radius := 115.0
@export var crater_radius := 15.0
@export var crater_depth := 6.0
@export var segments := 22
@export var rings := 9
@export var rivers := 6
@export var seed := 5814
## Volcan à l'horizon d'un lieu : lac et coulées de lave qui brillent seuls (matériaux émissifs) et fumée, sans
## lumière dynamique, ni projections, ni nuage d'éruption. Seul le hub joue l'éruption, à la fin perdue.
@export var distant := false

const ROCK_TOP := Color(0.2, 0.17, 0.19)
const ROCK_MID := Color(0.26, 0.21, 0.23)
const ROCK_BASE := Color(0.42, 0.22, 0.15)
const LAVA_HOT := Color(1.0, 0.62, 0.12)
const LAVA_CORE := Color(1.0, 0.3, 0.05)

var state := State.AWAKE

var _rng := RandomNumberGenerator.new()
var _jitter: Array[PackedFloat32Array] = []
var _rivers: MeshInstance3D
var _river_material: StandardMaterial3D
var _pool: MeshInstance3D
var _pool_material: StandardMaterial3D
var _light: OmniLight3D
var _wisps: Array[CPUParticles3D] = []
var _bombs: CPUParticles3D
var _cloud: Node3D


func _ready() -> void:
	_rng.seed = seed
	for ring in rings + 1:
		var row := PackedFloat32Array()
		for segment in segments:
			row.append(_rng.randf_range(-1.0, 1.0))
		_jitter.append(row)
	add_child(_build_cone())
	_pool_material = _glow_material(LAVA_CORE)
	_pool = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = crater_radius * 0.72
	disc.bottom_radius = crater_radius * 0.72
	disc.height = 0.4
	disc.radial_segments = segments
	disc.material = _pool_material
	_pool.mesh = disc
	_pool.position.y = height - crater_depth + 0.6
	add_child(_pool)
	_river_material = _glow_material(LAVA_HOT)
	_rivers = MeshInstance3D.new()
	_rivers.mesh = _build_rivers()
	_rivers.material_override = _river_material
	add_child(_rivers)
	if not distant:
		_light = OmniLight3D.new()
		_light.light_color = Color(1.0, 0.45, 0.15)
		_light.omni_range = 110.0
		_light.position.y = height + 4.0
		add_child(_light)
	for offset in [Vector3(-2.5, 0, 1.0), Vector3(2.0, 0, -1.5)]:
		var wisp := SmokeEffect.new()
		wisp.smoke_color = Color(0.82, 0.8, 0.78)
		wisp.radius = 2.0
		wisp.puff_size = 9.0
		wisp.rise_speed = 3.0
		wisp.position = Vector3(0, height - 2.0, 0) + offset
		add_child(wisp)
		_wisps.append(wisp)
		if distant:
			# De loin, le brouillard du lieu effaçait la fumée : elle reste visible au-dessus du cratère.
			(wisp.mesh as QuadMesh).material.disable_fog = true
	if distant:
		add_child(_build_glow())
	else:
		_bombs = _build_bombs()
		add_child(_bombs)
		_cloud = _build_cloud()
		add_child(_cloud)
	set_state(state)


## Rayon du cône à la hauteur relative t (0 au pied, 1 au bord du cratère) : des flancs concaves.
func _profile(t: float) -> float:
	return crater_radius + (base_radius - crater_radius) * pow(1.0 - t, 1.8)


func _surface_point(ring: int, segment: int) -> Vector3:
	var t := float(ring) / rings
	var angle := TAU * (segment % segments) / segments + _jitter[ring][segment % segments] * 0.12
	var radius := _profile(t) * (1.0 + _jitter[ring][(segment + 3) % segments] * 0.09 * (1.0 - t * 0.6))
	var y := t * height + _jitter[ring][(segment + 7) % segments] * 2.2 * (1.0 if ring > 0 and ring < rings else 0.0)
	return Vector3(cos(angle) * radius, y, sin(angle) * radius)


func _rock_color(t: float, jitter: float) -> Color:
	var color := ROCK_BASE.lerp(ROCK_MID, smoothstep(0.0, 0.35, t)).lerp(ROCK_TOP, smoothstep(0.4, 1.0, t))
	return color.lightened(jitter * 0.12) if jitter > 0.0 else color.darkened(-jitter * 0.18)


## Cône à facettes plates, son bord de cratère et l'entonnoir qui descend jusqu'au lac de lave.
func _build_cone() -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_smooth_group(-1)
	for ring in rings:
		for segment in segments:
			var a := _surface_point(ring, segment)
			var b := _surface_point(ring, segment + 1)
			var c := _surface_point(ring + 1, segment)
			var d := _surface_point(ring + 1, segment + 1)
			var t := (ring + 0.5) / rings
			_triangle(tool, a, c, b, _rock_color(t, _jitter[ring][segment]), _away(a + d))
			_triangle(tool, b, c, d, _rock_color(t, _jitter[ring + 1][segment]), _away(a + d))
	# Lèvre du cratère, plus claire, puis la paroi intérieure.
	var floor_y := height - crater_depth
	for segment in segments:
		var a := _surface_point(rings, segment)
		var b := _surface_point(rings, segment + 1)
		var inner := 0.78
		var c := Vector3(a.x * inner, floor_y, a.z * inner)
		var d := Vector3(b.x * inner, floor_y, b.z * inner)
		# La paroi intérieure regarde vers l'axe du cratère.
		_triangle(tool, a, b, c, ROCK_TOP.lightened(0.2), -_away(a + b) + Vector3.UP * 0.6)
		_triangle(tool, b, d, c, ROCK_TOP.darkened(0.3), -_away(b + c) + Vector3.UP * 0.6)
		_triangle(tool, c, d, Vector3(0, floor_y, 0), ROCK_TOP.darkened(0.5), Vector3.UP)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	material.disable_fog = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mesh := tool.commit()
	mesh.surface_set_material(0, material)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	return instance


## Ajoute un triangle à facette plate, tourné vers outward : son ordre de sommets en dépend.
func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color, outward: Vector3) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if normal.dot(outward) < 0.0:
		var swap := b
		b = c
		c = swap
		normal = -normal
	tool.set_color(color)
	tool.set_normal(normal)
	# Godot tient pour face avant celle dont les sommets tournent dans le sens horaire.
	for point in [a, c, b]:
		tool.add_vertex(point)


## Direction qui s'éloigne de l'axe du volcan, et un peu vers le haut.
func _away(point: Vector3) -> Vector3:
	return Vector3(point.x, 0.0, point.z).normalized() + Vector3.UP * 0.3


## Coulées de lave : des rubans qui partent du cratère et serpentent jusqu'au pied, collés aux flancs.
func _build_rivers() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_smooth_group(-1)
	for river in rivers:
		var angle := TAU * river / rivers + _rng.randf_range(-0.3, 0.3)
		var drift := _rng.randf_range(-0.5, 0.5)
		var steps := 14
		var previous_left := Vector3.ZERO
		var previous_right := Vector3.ZERO
		for step in steps + 1:
			var t := 1.0 - float(step) / steps * _rng.randf_range(0.82, 1.0) if step > 0 else 1.0
			var a := angle + drift * (1.0 - t) + sin(step * 1.3 + river) * 0.06
			var radius := _profile(t) + 0.6
			var center := Vector3(cos(a) * radius, t * height + 0.5, sin(a) * radius)
			var width := lerpf(3.0, 13.0, 1.0 - t) * _rng.randf_range(0.7, 1.25)
			var side := Vector3(-sin(a), 0, cos(a)) * width * 0.5
			var left := center - side
			var right := center + side
			if step > 0:
				_triangle(tool, previous_left, left, previous_right, Color.WHITE, _away(center))
				_triangle(tool, previous_right, left, right, Color.WHITE, _away(center))
			previous_left = left
			previous_right = right
	return tool.commit()


func _glow_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.disable_fog = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


## Lueur du cratère vue de loin, à la place de la lumière dynamique : un halo orangé, additif et toujours tourné
## vers la caméra, dont le bord du cratère cache le bas.
func _build_glow() -> MeshInstance3D:
	var falloff := Gradient.new()
	falloff.set_color(0, Color(1.0, 0.45, 0.12, 0.75))
	falloff.set_color(1, Color(1.0, 0.3, 0.08, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = falloff
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.disable_fog = true
	material.albedo_texture = texture
	var quad := QuadMesh.new()
	quad.size = Vector2(crater_radius * 4.0, crater_radius * 2.6)
	quad.material = material
	var glow := MeshInstance3D.new()
	glow.mesh = quad
	glow.position.y = height + 1.0
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return glow


## Projections de lave : des éclats incandescents lancés haut au-dessus du cratère, qui retombent.
func _build_bombs() -> CPUParticles3D:
	var shard := PrismMesh.new()
	shard.size = Vector3(1.6, 2.2, 1.6)
	shard.material = _glow_material(Color(1.0, 0.35, 0.08))
	var bombs := CPUParticles3D.new()
	bombs.mesh = shard
	bombs.amount = 90
	bombs.lifetime = 5.0
	bombs.emitting = false
	bombs.position.y = height
	bombs.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	bombs.emission_sphere_radius = crater_radius * 0.5
	bombs.direction = Vector3.UP
	bombs.spread = 38.0
	bombs.gravity = Vector3(0, -18.0, 0)
	bombs.initial_velocity_min = 30.0
	bombs.initial_velocity_max = 55.0
	bombs.angular_velocity_min = -180.0
	bombs.angular_velocity_max = 180.0
	bombs.particle_flag_rotate_y = true
	bombs.scale_amount_min = 0.6
	bombs.scale_amount_max = 1.6
	return bombs


## Nuage d'éruption : des blocs de roche sombre à facettes, empilés au-dessus du cratère.
func _build_cloud() -> Node3D:
	var cloud := Node3D.new()
	cloud.position.y = height + 8.0
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.42, 0.36, 0.35)
	material.roughness = 1.0
	material.disable_fog = true
	for index in 14:
		var puff := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radial_segments = 7
		sphere.rings = 4
		var size := _rng.randf_range(9.0, 17.0)
		sphere.radius = size
		sphere.height = size * 1.7
		sphere.material = material
		puff.mesh = sphere
		var up := float(index) / 14.0
		puff.position = Vector3(_rng.randf_range(-12, 12) + up * 22.0, up * 55.0, _rng.randf_range(-10, 10))
		puff.rotation = Vector3(_rng.randf() * TAU, _rng.randf() * TAU, 0)
		cloud.add_child(puff)
	return cloud


func set_state(value: State) -> void:
	state = State.AWAKE if distant and value == State.ERUPTING else value
	var awake := state != State.DORMANT
	var erupting := state == State.ERUPTING
	_pool.visible = awake
	_rivers.visible = awake
	_river_material.emission_energy_multiplier = 4.0 if erupting else 1.6
	_rivers.scale = Vector3.ONE * (1.0 if erupting else 0.96)
	if _light:
		_light.visible = awake
		_light.light_energy = 14.0 if erupting else 3.0
	# Une fumée légère monte toujours du cratère, sauf pendant l'éruption où le nuage la remplace.
	for wisp in _wisps:
		wisp.emitting = not erupting
	if _bombs:
		_bombs.emitting = erupting
		_cloud.visible = erupting


## Passe en éruption : le nuage jaillit du cratère et grossit, les projections commencent.
func erupt() -> void:
	if distant:
		return
	set_state(State.ERUPTING)
	_cloud.scale = Vector3.ONE * 0.1
	create_tween().tween_property(_cloud, "scale", Vector3.ONE, 3.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
