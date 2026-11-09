class_name LibraryBreach
extends Node3D
## La voûte percée de la salle de lecture. Une pierre des catapultes de Vibelandia a crevé le plafond des archives : la
## pierre, les moellons et une solive calcinée gisent dessous (tools/build_plaine.py, BREACH). Par le trou, on voit le
## ciel de cendre, bordé de braises ; un rai de lumière en tombe jusqu'au tas, la poussière y flotte, la cendre et
## quelques braises y descendent lentement, et le vent siffle dans la brèche.
## Le nœud est posé au sol, sous le centre du trou. Le plafond (ceiling, une BoxMesh) reçoit à sa place un maillage
## percé du même matériau, avec le puits de la brèche, ses pierres arrachées et deux solives : un seul appel de dessin,
## comme avant. Sa collision ne change pas : le trou est hors d'atteinte. Rien n'éclaire : le ciel, le rai et la tache
## au sol sont des surfaces additives sans ombrage (breach_light.gdshader), sans lumière dynamique ni ombre.

@export var ceiling: MeshInstance3D
@export var light_shader: Shader
@export var wind_sound: AudioStream
## Taille du trou (x, z) et hauteur du puits au-dessus du plafond.
@export var hole_size := Vector2(1.8, 1.6)
@export var shaft_height := 0.8

const SKY := Color(1.0, 0.74, 0.68)
const EMBERS := Color(1.0, 0.42, 0.12)

var _materials: Array[ShaderMaterial] = []
var _time := 0.0


func _ready() -> void:
	var top := _ceiling_bottom()
	# Le rai part du ciel de cendre, en haut du puits, et descend jusqu'au sol : la voûte en cache le haut de côté.
	var sky := top
	if ceiling and ceiling.mesh is BoxMesh:
		sky += (ceiling.mesh as BoxMesh).size.y + shaft_height
		_pierce_ceiling()
	var shaft := _light_quad("Shaft", 0, Vector2(hole_size.x + 0.7, sky), Vector3(0.0, sky / 2.0, 0.0), 0.5)
	# Tourné vers la caméra par son shader : sa boîte d'origine, plate, le ferait disparaître de biais.
	var reach := (hole_size.x + 0.7) / 2.0
	shaft.custom_aabb = AABB(Vector3(-reach, -sky / 2.0, -reach), Vector3(reach * 2.0, sky, reach * 2.0))
	add_child(shaft)
	var pool := _light_quad("Pool", 1, Vector2.ONE * (hole_size.x + 1.4), Vector3(0.0, 0.015, 0.0), 0.45)
	pool.rotation.x = -PI / 2.0
	add_child(pool)
	add_child(_dust(top))
	add_child(_falling_ash(top))
	if wind_sound:
		var wind := AudioStreamPlayer3D.new()
		wind.name = "Wind"
		wind.stream = wind_sound
		wind.volume_db = -15.0
		wind.max_db = -11.0
		wind.unit_size = 2.5
		wind.max_distance = 13.0
		wind.position.y = top + 0.3
		wind.autoplay = true
		add_child(wind)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	# Le ciel de cendre et les braises respirent, lentement.
	var pulse := 0.9 + 0.07 * sin(_time * 0.8) + 0.04 * sin(_time * 2.1 + 1.0)
	for material in _materials:
		material.set_shader_parameter("pulse", pulse)


## Hauteur du dessous du plafond, dans le repère du nœud.
func _ceiling_bottom() -> float:
	if not ceiling or not ceiling.mesh is BoxMesh:
		return 4.0
	var box := ceiling.mesh as BoxMesh
	return to_local(ceiling.to_global(Vector3(0.0, -box.size.y / 2.0, 0.0))).y


## Le plafond percé : la dalle en quatre morceaux autour du trou, le puits, son couvercle, les pierres arrachées au
## bord et deux solives calcinées, en une seule surface du matériau du plafond. Le ciel de cendre est collé sous le
## couvercle.
func _pierce_ceiling() -> void:
	var box := ceiling.mesh as BoxMesh
	var material := box.material
	var size := box.size
	var center := ceiling.to_local(global_position)
	var half := size / 2.0
	var x0 := center.x - hole_size.x / 2.0
	var x1 := center.x + hole_size.x / 2.0
	var z0 := center.z - hole_size.y / 2.0
	var z1 := center.z + hole_size.y / 2.0
	var wall := 0.25
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	# La dalle, autour du trou.
	_box(tool, Vector3(0.0, 0.0, (-half.z + z0) / 2.0), Vector3(size.x, size.y, z0 + half.z))
	_box(tool, Vector3(0.0, 0.0, (z1 + half.z) / 2.0), Vector3(size.x, size.y, half.z - z1))
	_box(tool, Vector3((-half.x + x0) / 2.0, 0.0, center.z), Vector3(x0 + half.x, size.y, hole_size.y))
	_box(tool, Vector3((x1 + half.x) / 2.0, 0.0, center.z), Vector3(half.x - x1, size.y, hole_size.y))
	# Le puits, au-dessus, et son couvercle.
	var base := half.y
	var height := shaft_height
	_box(tool, Vector3(x0 - wall / 2.0, base + height / 2.0, center.z), Vector3(wall, height, hole_size.y + wall * 2.0))
	_box(tool, Vector3(x1 + wall / 2.0, base + height / 2.0, center.z), Vector3(wall, height, hole_size.y + wall * 2.0))
	_box(tool, Vector3(center.x, base + height / 2.0, z0 - wall / 2.0), Vector3(hole_size.x, height, wall))
	_box(tool, Vector3(center.x, base + height / 2.0, z1 + wall / 2.0), Vector3(hole_size.x, height, wall))
	_box(tool, Vector3(center.x, base + height + 0.1, center.z),
		Vector3(hole_size.x + wall * 2.0, 0.2, hole_size.y + wall * 2.0))
	# Pierres arrachées au bord du trou : elles mordent sur l'ouverture et pendent un peu sous la voûte (au plus 40 cm,
	# bien au-dessus de la tête d'un joueur qui saute).
	var random := RandomNumberGenerator.new()
	random.seed = 5812
	for index in 12:
		var side := index % 4
		var along := random.randf_range(-0.42, 0.42)
		var inset := random.randf_range(0.04, 0.22)
		var spot: Vector3
		match side:
			0:
				spot = Vector3(x0 + inset, 0.0, center.z + along * hole_size.y)
			1:
				spot = Vector3(x1 - inset, 0.0, center.z + along * hole_size.y)
			2:
				spot = Vector3(center.x + along * hole_size.x, 0.0, z0 + inset)
			_:
				spot = Vector3(center.x + along * hole_size.x, 0.0, z1 - inset)
		spot.y = random.randf_range(-0.2, 0.05)
		var chunk := Vector3(random.randf_range(0.22, 0.42), random.randf_range(0.3, 0.42), random.randf_range(0.2, 0.36))
		var turn := Basis.from_euler(Vector3(random.randf_range(-0.45, 0.45), random.randf() * TAU,
			random.randf_range(-0.45, 0.45)))
		_box(tool, spot, chunk, turn)
	# Deux solives calcinées en travers du puits, l'une cassée, qui pend.
	_box(tool, Vector3(center.x - hole_size.x * 0.3, base + height * 0.6, center.z),
		Vector3(0.18, 0.18, hole_size.y + wall * 2.0))
	_box(tool, Vector3(center.x + hole_size.x * 0.33, base + height * 0.2, center.z + hole_size.y * 0.22),
		Vector3(0.16, 0.16, hole_size.y * 0.6), Basis(Vector3.RIGHT, 0.5))
	var mesh := tool.commit()
	mesh.surface_set_material(0, material)
	ceiling.mesh = mesh
	# Le ciel de cendre, juste sous le couvercle du puits, tourné vers le bas.
	var sky := _light_quad("Sky", 2, hole_size, Vector3.ZERO, 1.1)
	sky.rotation.x = PI / 2.0
	ceiling.add_child(sky)
	sky.position = Vector3(center.x, base + height - 0.01, center.z)


## Ajoute une boîte (centre, taille, rotation) à la surface, dans le repère du plafond.
func _box(tool: SurfaceTool, at: Vector3, size: Vector3, turn := Basis.IDENTITY) -> void:
	var shape := BoxMesh.new()
	shape.size = size
	tool.append_from(shape, 0, Transform3D(turn, at))


func _light_quad(title: String, mode: int, size: Vector2, at: Vector3, energy: float) -> MeshInstance3D:
	var material := ShaderMaterial.new()
	material.shader = light_shader
	material.set_shader_parameter("mode", mode)
	material.set_shader_parameter("color", SKY)
	material.set_shader_parameter("ember_color", EMBERS)
	material.set_shader_parameter("energy", energy)
	material.set_shader_parameter("top_width", hole_size.x / size.x)
	_materials.append(material)
	var quad := QuadMesh.new()
	quad.size = size
	var instance := MeshInstance3D.new()
	instance.name = title
	instance.mesh = quad
	instance.material_override = material
	instance.position = at
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance


## Poussière qui flotte dans le rai et accroche sa lumière.
func _dust(top: float) -> CPUParticles3D:
	var material := StandardMaterial3D.new()
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.emission_enabled = true
	material.emission = Color(1.0, 0.82, 0.7)
	material.emission_energy_multiplier = 0.7
	var quad := QuadMesh.new()
	quad.size = Vector2(0.028, 0.028)
	quad.material = material
	var colors := Gradient.new()
	colors.set_color(0, Color(1.0, 0.9, 0.8, 0.0))
	colors.set_color(1, Color(1.0, 0.9, 0.8, 0.0))
	colors.add_point(0.25, Color(1.0, 0.92, 0.82, 0.75))
	colors.add_point(0.75, Color(1.0, 0.9, 0.8, 0.6))
	var dust := CPUParticles3D.new()
	dust.name = "Dust"
	dust.mesh = quad
	dust.amount = 40
	dust.lifetime = 8.0
	dust.preprocess = 8.0
	# Réglée comme la poussière des archives (plaine.gd), ombre comprise : aucune lumière des archives ne projette
	# d'ombre, et le matériau est déjà dans l'inventaire des shaders préparés au menu.
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(hole_size.x * 0.42, top * 0.42, hole_size.y * 0.42)
	dust.position.y = top / 2.0
	dust.direction = Vector3(0.2, 1.0, 0.1)
	dust.spread = 180.0
	dust.gravity = Vector3(0.0, 0.008, 0.0)
	dust.initial_velocity_min = 0.02
	dust.initial_velocity_max = 0.07
	dust.color_ramp = colors
	return dust


## Cendre qui tombe lentement du trou, avec quelques braises orangées, et s'efface sur le tas.
func _falling_ash(top: float) -> CPUParticles3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	var quad := QuadMesh.new()
	quad.size = Vector2(0.045, 0.045)
	quad.material = material
	var kinds := Gradient.new()
	kinds.set_color(0, Color(0.42, 0.39, 0.38))
	kinds.set_color(1, Color(1.0, 0.55, 0.18))
	kinds.add_point(0.82, Color(0.55, 0.5, 0.48))
	kinds.add_point(0.86, Color(1.0, 0.45, 0.12))
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 1.0, 1.0, 0.0))
	fade.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	fade.add_point(0.06, Color(1.0, 1.0, 1.0, 0.9))
	fade.add_point(0.85, Color(1.0, 1.0, 1.0, 0.8))
	var ash := CPUParticles3D.new()
	ash.name = "Ash"
	ash.mesh = quad
	ash.amount = 22
	ash.lifetime = 10.0
	ash.preprocess = 10.0
	# Même réglage que les lueurs autour du Projenomicon (Interior/Book/Motes), pour la même raison que la poussière.
	ash.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ash.emission_box_extents = Vector3(hole_size.x * 0.4, 0.05, hole_size.y * 0.4)
	ash.position.y = top - 0.05
	ash.direction = Vector3.DOWN
	ash.spread = 14.0
	ash.gravity = Vector3(0.03, -0.015, 0.01)
	ash.initial_velocity_min = 0.3
	ash.initial_velocity_max = 0.42
	ash.color_initial_ramp = kinds
	ash.color_ramp = fade
	return ash
