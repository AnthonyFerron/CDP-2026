@tool
class_name DesertScatter
extends Node3D
## Habille le désert de Pythania : quelques cactus, des rochers, des colonnes renversées, des épaves de guerre,
## les restes épars des voyageurs, des ossements de bêtes et des crânes de vautours, et les sables mouvants.
## Les placements sont reproductibles et les petits détails disparaissent au loin.

@export var terrain: DesertTerrain
@export var cactus_models: Array[PackedScene]
@export var rock_models: Array[PackedScene]
@export var ruin_models: Array[PackedScene]
## Catapulte, baliste et trébuchet démolis, dans l'ordre de WRECK_BOXES : aucun engin couvert d'un toit.
@export var wreck_models: Array[PackedScene]
## Lance, bouclier, épée, jarre, roue, tonneau, squelette : les restes épars de PROPS.
@export var prop_models: Array[PackedScene]
@export var quicksand_material: Material
@export var cactus_count := 90
@export var rock_count := 140
@export var ruin_count := 18
@export var border_rock_count := 44
## Crânes de vautours et ossements de bêtes semés dans les dunes.
@export var skull_count := 36
@export var bone_count := 48
## Distance à laquelle les petits détails disparaissent.
@export var detail_range := 70.0

## Épaves de machines de siège, sans toit (catapulte, baliste, trébuchet) : position (x, z) et échelle.
## Leur cap est tiré au hasard ; elles sont à moitié ensablées.
const WRECKS: Array[Vector3] = [
	Vector3(26.0, 32.0, 4.4), Vector3(-46.0, 14.0, 4.0), Vector3(30.0, -18.0, 4.2), Vector3(-14.0, -38.0, 3.8),
	Vector3(44.0, -40.0, 4.0), Vector3(-52.0, -6.0, 3.6),
]
## Boîte des épaves à l'échelle 1, dans l'ordre de wreck_models : coin et taille.
const WRECK_BOXES := [
	[Vector3(-0.64, 0.0, -0.87), Vector3(1.68, 0.32, 1.67)],
	[Vector3(-0.91, 0.0, -0.79), Vector3(1.75, 0.51, 1.55)],
	[Vector3(-0.87, 0.0, -1.05), Vector3(1.93, 0.31, 2.1)],
]
## Côté des cases qui découpent les détails épars : la distance de visibilité d'un MultiMesh se mesure jusqu'au
## centre de sa boîte, il en faut un par case pour que rien ne disparaisse sous les pieds loin du centre.
const CHUNK := 32.0
## Restes épars dans les dunes, posés sur le sol maillé : modèle (indice dans prop_models), x, z, cap,
## échelle, inclinaison en degrés, enfoncement en mètres, rayon de collision (0 : aucune, l'objet est bas).
## Armes de la guerre plantées dans le sable, jarres brisées, roues et squelettes de voyageurs perdus.
const PROPS := [
	[0, 13.5, 30.0, 20.0, 3.2, 24.0, 0.35, 0.0],
	[0, 15.0, 31.5, 70.0, 3.2, -18.0, 0.35, 0.0],
	[1, 14.2, 29.0, 160.0, 3.0, 78.0, 0.05, 0.0],
	[2, 16.0, 30.6, 35.0, 3.0, 82.0, 0.0, 0.0],
	[6, 12.6, 31.8, 110.0, 3.4, -88.0, 0.0, 0.0],
	[0, -16.0, 36.0, 200.0, 3.2, 30.0, 0.35, 0.0],
	[1, -15.0, 37.4, 20.0, 3.0, 80.0, 0.05, 0.0],
	[3, -44.0, -8.0, 30.0, 1.8, 90.0, 0.1, 0.0],
	[3, -43.0, -9.6, 140.0, 1.6, 0.0, 0.25, 0.55],
	[4, -46.0, -16.0, 75.0, 3.0, 80.0, 0.15, 0.0],
	[5, -45.0, -18.0, 15.0, 2.6, 0.0, 0.5, 0.65],
	[6, 46.0, 18.0, 250.0, 3.4, -88.0, 0.0, 0.0],
	[3, 47.5, 16.5, 60.0, 1.7, 90.0, 0.1, 0.0],
	[2, 45.0, 16.0, 300.0, 3.0, 85.0, 0.0, 0.0],
	[0, 8.0, -44.0, 120.0, 3.2, 26.0, 0.35, 0.0],
	[1, 9.5, -42.5, 300.0, 3.0, 75.0, 0.05, 0.0],
	[6, -8.0, -56.0, 45.0, 3.4, -88.0, 0.0, 0.0],
	[3, -6.5, -55.0, 200.0, 1.8, 0.0, 0.2, 0.55],
	[4, 52.0, -24.0, 120.0, 3.0, 82.0, 0.1, 0.0],
	[5, 50.0, -26.0, 210.0, 2.6, 12.0, 0.45, 0.65],
	[3, -52.0, 30.0, 300.0, 1.6, 90.0, 0.1, 0.0],
	[0, -50.0, 32.0, 10.0, 3.2, -22.0, 0.35, 0.0],
	[6, 10.0, 58.0, 160.0, 3.4, -88.0, 0.0, 0.0],
	[3, -12.0, 58.0, 20.0, 1.8, 0.0, 0.2, 0.55],
]

## Boîte à l'échelle 1 des ruines couchées, dans l'ordre de ruin_models : colonne abîmée, briques.
const RUIN_BOXES: Array[Vector3] = [Vector3(0.6, 0.72, 0.6), Vector3(0.77, 0.41, 0.85)]

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	# Le terrain se construit avant ses voisins : il faut ses hauteurs pour poser le décor.
	if not terrain.is_node_ready():
		await terrain.ready
	_rng.seed = 5814
	# Rayons de collision à l'échelle 1 : tige des cactus, corps des rochers, colonnes et briques couchées.
	_scatter(cactus_models, cactus_count, Vector2(3.0, 5.0), true, 0.17)
	_scatter(rock_models, rock_count, Vector2(2.0, 5.0), true, 0.3)
	_scatter(ruin_models, ruin_count, Vector2(2.5, 3.5), true, 0.32, true)
	_add_wrecks()
	_add_props()
	_add_bones()
	_add_border_rocks()
	_add_quicksands()


## Point libre : hors de l'esplanade, du chemin et de ses obélisques, de la muraille, des replats du décor,
## des épaves et des sables mouvants.
func is_free(spot: Vector2, margin: float) -> bool:
	if spot.distance_to(Vector2(DesertTerrain.PLAZA.x, DesertTerrain.PLAZA.y)) < DesertTerrain.PLAZA.z + 4.0 + margin:
		return false
	if absf(spot.x) < DesertTerrain.PATH_HALF_WIDTH + 5.5 + margin and spot.y > DesertTerrain.PATH_START - 6.0:
		return false
	# Muraille de l'arche d'entrée, en z = 16, et ses congères.
	if absf(spot.x) < 20.0 + margin and absf(spot.y - 16.0) < 4.5 + margin:
		return false
	for sand in DesertTerrain.QUICKSANDS:
		if spot.distance_to(Vector2(sand.x, sand.y)) < sand.z + 1.5 + margin:
			return false
	for site in DesertTerrain.SITES:
		if spot.distance_to(Vector2(site.x, site.y)) < site.z + 2.0 + margin:
			return false
	for wreck in WRECKS:
		if spot.distance_to(Vector2(wreck.x, wreck.y)) < 6.5 + margin:
			return false
	for prop: Array in PROPS:
		if spot.distance_to(Vector2(prop[1], prop[2])) < 1.5 + margin:
			return false
	return Vector2(spot).length() < DesertTerrain.LIMIT_RADIUS - 1.5


func _scatter(models: Array[PackedScene], count: int, scale_range: Vector2, solid: bool, radius: float, tilted := false) -> void:
	var body: StaticBody3D
	if solid:
		body = StaticBody3D.new()
		add_child(body)
	var groups: Array[Array] = []
	for model in models:
		groups.append([])
	var placed := 0
	for attempt in count * 10:
		if placed >= count:
			break
		var spot := Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * DesertTerrain.PLAY_RADIUS
		if not is_free(spot, 0.5):
			continue
		var scale_factor := _rng.randf_range(scale_range.x, scale_range.y)
		var group := placed % groups.size()
		# Seules les colonnes se couchent ; les tas de briques restent posés à plat.
		var lying := tilted and group == 0
		var basis := Basis(Vector3.UP, _rng.randf() * TAU)
		var lean := _rng.randf_range(70.0, 90.0) if tilted else 0.0
		if lying:
			basis = basis * Basis(Vector3.FORWARD, deg_to_rad(lean))
		var origin := Vector3(spot.x, terrain.footing_height(spot.x, spot.y) - 0.15, spot.y)
		if lying:
			origin.y += 0.3 * scale_factor
		groups[group].append(Transform3D(basis.scaled(Vector3.ONE * scale_factor), origin))
		if solid:
			var collision := CollisionShape3D.new()
			if tilted and group < RUIN_BOXES.size():
				# Une boîte tournée comme la ruine, sur toute sa longueur.
				var box := BoxShape3D.new()
				box.size = RUIN_BOXES[group] * scale_factor
				collision.shape = box
				collision.transform = Transform3D(basis, origin + basis * Vector3(0.0, RUIN_BOXES[group].y * 0.5 * scale_factor, 0.0))
			else:
				var shape := CylinderShape3D.new()
				shape.radius = radius * scale_factor
				shape.height = 2.5
				collision.shape = shape
				collision.position = origin + Vector3.UP * 1.0
			body.add_child(collision)
		placed += 1
	for index in models.size():
		var transforms: Array[Transform3D] = []
		transforms.assign(groups[index])
		_add_multimesh(_load_mesh(models[index]), transforms)


## Épaves de machines de siège, restes de la guerre, à moitié ensablées à des endroits fixes : chacune a la
## collision de sa boîte, tournée comme elle, et une congère qui la recouvre d'un côté.
func _add_wrecks() -> void:
	var body := StaticBody3D.new()
	add_child(body)
	var sand := StandardMaterial3D.new()
	sand.albedo_color = Color(0.84, 0.64, 0.4)
	sand.roughness = 1.0
	var drift := SphereMesh.new()
	drift.radial_segments = 14
	drift.rings = 7
	drift.material = sand
	for index in WRECKS.size():
		var spot := WRECKS[index]
		var kind := index % wreck_models.size()
		var wreck: Node3D = wreck_models[kind].instantiate()
		var scale_factor := spot.z
		var box: Array = WRECK_BOXES[kind]
		var height: float = box[1].y * scale_factor
		var basis := Basis(Vector3.UP, _rng.randf() * TAU) * Basis(Vector3.RIGHT, _rng.randf_range(-0.05, 0.05))
		var origin := Vector3(spot.x, terrain.footing_height(spot.x, spot.y) - height * 0.45, spot.y)
		wreck.transform = Transform3D(basis.scaled(Vector3.ONE * scale_factor), origin)
		add_child(wreck)
		var shape := BoxShape3D.new()
		shape.size = Vector3(box[1].x, box[1].y, box[1].z) * scale_factor
		var collision := CollisionShape3D.new()
		collision.shape = shape
		var center: Vector3 = (box[0] + box[1] * 0.5) * scale_factor
		collision.transform = Transform3D(basis, origin + basis * center)
		body.add_child(collision)
		# Le sable s'est amassé contre l'épave, du côté du vent.
		var mound := MeshInstance3D.new()
		mound.mesh = drift
		var side := basis * Vector3(box[1].x * 0.3 * scale_factor, 0.0, 0.0)
		mound.transform = Transform3D(basis.scaled(Vector3(box[1].x * 0.45, 0.5 * height, box[1].z * 0.5) * scale_factor), origin + side)
		mound.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mound)


func _add_props() -> void:
	if prop_models.is_empty():
		return
	var body := StaticBody3D.new()
	add_child(body)
	for prop: Array in PROPS:
		var model: PackedScene = prop_models[prop[0]]
		var item: Node3D = model.instantiate()
		var x: float = prop[1]
		var z: float = prop[2]
		item.position = Vector3(x, terrain.footing_height(x, z) - prop[6], z)
		item.rotation = Vector3(0.0, deg_to_rad(prop[3]), 0.0)
		item.rotate_object_local(Vector3.RIGHT, deg_to_rad(prop[5]))
		item.scale = Vector3.ONE * prop[4]
		add_child(item)
		if prop[7] > 0.0:
			var shape := CylinderShape3D.new()
			shape.radius = prop[7]
			shape.height = 1.6
			var collision := CollisionShape3D.new()
			collision.shape = shape
			collision.position = item.position + Vector3.UP * 0.8
			body.add_child(collision)


## Ossements dans les dunes : des crânes de vautours au bec crochu et des tas d'os de bêtes, sans collision.
func _add_bones() -> void:
	var bone := StandardMaterial3D.new()
	bone.albedo_color = Color(0.9, 0.86, 0.74)
	bone.roughness = 0.85
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.02, 0.015, 0.01)
	var sphere := SphereMesh.new()
	sphere.radial_segments = 10
	sphere.rings = 5
	var skull := _compose([
		[sphere, Transform3D(Basis().scaled(Vector3(0.1, 0.085, 0.12)), Vector3(0.0, 0.09, 0.0))],
		[_cone(0.012, 0.045, 0.2, 5), Transform3D(Basis(Vector3.RIGHT, deg_to_rad(100.0)), Vector3(0.0, 0.08, 0.17))],
		[_cone(0.006, 0.018, 0.07, 4), Transform3D(Basis(Vector3.RIGHT, deg_to_rad(170.0)), Vector3(0.0, 0.045, 0.265))],
	], bone)
	_compose([
		[sphere, Transform3D(Basis().scaled(Vector3.ONE * 0.03), Vector3(0.085, 0.12, 0.06))],
		[sphere, Transform3D(Basis().scaled(Vector3.ONE * 0.03), Vector3(-0.085, 0.12, 0.06))],
	], dark, skull)
	var long_bone := _cone(0.035, 0.035, 0.85, 6)
	var bones := _compose([
		[long_bone, Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(0.0, 0.035, 0.0))],
		[long_bone, Transform3D(Basis(Vector3.UP, 0.7) * Basis(Vector3.FORWARD, PI * 0.5), Vector3(0.1, 0.1, 0.12))],
		[long_bone, Transform3D(Basis(Vector3.UP, -1.1) * Basis(Vector3.FORWARD, PI * 0.5), Vector3(-0.2, 0.035, 0.25))],
		[_cone(0.07, 0.09, 0.12, 6), Transform3D(Basis(), Vector3(0.3, 0.06, -0.2))],
		[_cone(0.07, 0.09, 0.12, 6), Transform3D(Basis(Vector3.RIGHT, 1.2), Vector3(0.45, 0.07, -0.05))],
	], bone)
	for item: Array in [[skull, skull_count, 1.4, 1.9], [bones, bone_count, 0.9, 1.4]]:
		var transforms: Array[Transform3D] = []
		for attempt in item[1] * 12:
			if transforms.size() >= item[1]:
				break
			var spot := Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * (DesertTerrain.PLAY_RADIUS - 3.0)
			if not is_free(spot, 0.2):
				continue
			var basis := Basis(Vector3.UP, _rng.randf() * TAU) * Basis(Vector3.RIGHT, _rng.randf_range(-0.2, 0.2))
			var origin := Vector3(spot.x, terrain.footing_height(spot.x, spot.y) - 0.03, spot.y)
			transforms.append(Transform3D(basis.scaled(Vector3.ONE * _rng.randf_range(item[2], item[3])), origin))
		_add_multimesh(item[0], transforms, 55.0)


func _cone(top: float, bottom: float, height: float, segments: int) -> CylinderMesh:
	var cone := CylinderMesh.new()
	cone.top_radius = top
	cone.bottom_radius = bottom
	cone.height = height
	cone.radial_segments = segments
	cone.rings = 1
	return cone


## Fond des maillages simples, chacun à sa place, en une surface d'un seul matériau, ajoutée à mesh s'il est donné.
func _compose(parts: Array, material: Material, mesh: ArrayMesh = null) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for part: Array in parts:
		tool.append_from(part[0], 0, part[1])
	var result := tool.commit(mesh)
	result.surface_set_material(result.get_surface_count() - 1, material)
	return result


func _add_border_rocks() -> void:
	var items: Array[Array] = []
	for model in rock_models:
		items.append([])
	for i in border_rock_count:
		var angle := TAU * i / border_rock_count + _rng.randf_range(-0.05, 0.05)
		var spot := Vector2.from_angle(angle) * (DesertTerrain.PLAY_RADIUS + _rng.randf_range(2.0, 8.0))
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(12.0, 20.0))
		# Ces rochers sont énormes : enfoncés d'un dixième de leur taille pour ne pas flotter au-dessus des pentes.
		var sink := basis.get_scale().x * 0.12
		items[i % items.size()].append(Transform3D(basis, Vector3(spot.x, terrain.footing_height(spot.x, spot.y) - sink, spot.y)))
	for index in rock_models.size():
		var transforms: Array[Transform3D] = []
		transforms.assign(items[index])
		_add_multimesh(_load_mesh(rock_models[index]), transforms, 0.0)


func _add_quicksands() -> void:
	for sand in DesertTerrain.QUICKSANDS:
		var plane := PlaneMesh.new()
		plane.size = Vector2.ONE * sand.z * 2.2
		plane.material = quicksand_material
		var surface := MeshInstance3D.new()
		surface.mesh = plane
		# Le disque affleure au bord du creux, pour remplir la cuvette de sable meuble.
		var rim := INF
		for i in 12:
			var edge := Vector2.from_angle(TAU * i / 12.0) * sand.z * 1.05
			rim = minf(rim, terrain.height_at(sand.x + edge.x, sand.y + edge.y))
		surface.position = Vector3(sand.x, rim - 0.12, sand.y)
		surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(surface)


## Pose des instances en MultiMesh : sans distance de visibilité (rochers des crêtes), un seul pour toute la carte ;
## sinon un par case de CHUNK mètres, chacune avec sa distance mesurée jusqu'à elle et son fondu.
func _add_multimesh(mesh: Mesh, transforms: Array[Transform3D], range_end := -1.0) -> void:
	if range_end < 0.0:
		range_end = detail_range
	if range_end == 0.0:
		_add_multimesh_part(mesh, transforms, 0.0)
		return
	var cells := {}
	for item in transforms:
		var key := Vector2i(floori(item.origin.x / CHUNK), floori(item.origin.z / CHUNK))
		if not cells.has(key):
			cells[key] = []
		cells[key].append(item)
	for key: Vector2i in cells:
		var part: Array[Transform3D] = []
		part.assign(cells[key])
		_add_multimesh_part(mesh, part, range_end)


func _add_multimesh_part(mesh: Mesh, transforms: Array[Transform3D], range_end: float) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in transforms.size():
		multimesh.set_instance_transform(index, transforms[index])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.visibility_range_end = range_end
	if range_end > 0.0:
		instance.visibility_range_end_margin = 10.0
		instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(instance)
	return instance


func _load_mesh(model: PackedScene) -> Mesh:
	var scene := model.instantiate()
	var mesh := _find_mesh(scene)
	scene.free()
	return mesh


func _find_mesh(node: Node) -> Mesh:
	if node is MeshInstance3D:
		return node.mesh
	for child in node.get_children():
		var mesh := _find_mesh(child)
		if mesh:
			return mesh
	return null
