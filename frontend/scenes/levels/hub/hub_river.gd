class_name HubRiver
extends Node3D
## La rivière et l'étang du jardin : l'eau qui coule, des berges qu'on ne franchit que par les ponts, et la vie
## des rives (roseaux, pierres, nénuphars), qui revient avec les livres : les roseaux secs reverdissent un quart par
## livre, d'abord au ras de l'eau (HubFoliage), et les nénuphars se multiplient.
## Tout suit le tracé de HubTerrain : la rivière y est creusée, ses ponts y sont déclarés.

@export var terrain: HubTerrain
@export var water_material: ShaderMaterial
@export var pond_material: ShaderMaterial
@export var reed_models: Array[PackedScene]
@export var rock_models: Array[PackedScene]
@export var lily_models: Array[PackedScene]
## Shader du feuillage qui reprend vie (hub_foliage.gdshader).
@export var foliage_shader: Shader
@export var reed_count := 420
@export var rock_count := 220
@export var lily_count := 160
@export var detail_range := 75.0
## Distance du mur invisible au bord de l'eau, sur la berge.
@export var wall_offset := 1.0
## Le mur dépasse d'autant le plus haut point qu'un saut en courant (vitesse de course et saut du joueur) atteint
## en arrivant sur lui, depuis le sol des environs : un mètre de plus couvre un élan pris sur une caisse ou un rocher.
@export var wall_margin := 1.2
const SPRINT_SPEED := 8.0
const JUMP_VELOCITY := 5.5
## Portée du regard en arrière depuis le mur, en mètres : au-delà, un saut redescend sous son point de départ.
const JUMP_REACH := 10.0
## Lieux où les rives restent dégagées : (x, z, rayon), le lavoir, la roue du moulin et la passerelle des pêcheurs.
@export var clear_spots: Array[Vector3] = [Vector3(59.5, 6.5, 3.0), Vector3(70.5, 48.0, 4.5)]

var _rng := RandomNumberGenerator.new()
var _lilies: Array[MultiMesh] = []
var _foliage: HubFoliage


func _ready() -> void:
	if not terrain.is_node_ready():
		await terrain.ready
	_rng.seed = 5830
	_foliage = HubFoliage.new(foliage_shader)
	_build_river_water()
	_build_ponds()
	_build_banks()
	_build_life()
	set_life(0.0)


## L'eau s'éclaircit et les nénuphars reviennent avec les livres : de 0 à 1.
func set_life(life: float) -> void:
	for material in [water_material, pond_material]:
		if material:
			material.set_shader_parameter("life", life)
	for multimesh in _lilies:
		multimesh.visible_instance_count = int(multimesh.instance_count * clampf(0.1 + life * 0.9, 0.0, 1.0))
	if _foliage:
		_foliage.set_life(life)


## Tracé de la rivière prolongé à chaque bout sous la berge, avec la direction et la normale de chaque point.
func _course() -> Array:
	var samples := HubTerrain.river_samples()
	var points: Array[Vector2] = []
	var widths: Array[float] = []
	for sample in samples:
		points.append(Vector2(sample.x, sample.y))
		widths.append(sample.z)
	var start_dir := (points[1] - points[0]).normalized()
	var end_dir := (points[-1] - points[-2]).normalized()
	points.insert(0, points[0] - start_dir * (widths[0] + 3.0))
	widths.insert(0, widths[0])
	points.append(points[-1] + end_dir * (widths[-1] + 3.0))
	widths.append(widths[-1])
	var normals: Array[Vector2] = []
	for index in points.size():
		var ahead := points[mini(index + 1, points.size() - 1)]
		var behind := points[maxi(index - 1, 0)]
		normals.append((ahead - behind).normalized().orthogonal())
	return [points, widths, normals]


func _build_river_water() -> void:
	var course := _course()
	var points: Array[Vector2] = course[0]
	var widths: Array[float] = course[1]
	var normals: Array[Vector2] = course[2]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var travelled := 0.0
	var level := HubTerrain.WATER_LEVEL
	for index in points.size() - 1:
		var quad: Array[Vector3] = []
		var uvs: Array[Vector2] = []
		for step in 2:
			var i := index + step
			var half := widths[i] + 2.4
			var along := travelled + (points[index].distance_to(points[index + 1]) if step == 1 else 0.0)
			for side: float in [-1.0, 1.0]:
				var point := points[i] + normals[i] * half * side
				quad.append(Vector3(point.x, level, point.y))
				uvs.append(Vector2(0.5 + side * 0.5, along))
		travelled += points[index].distance_to(points[index + 1])
		for corner in [0, 1, 2, 1, 3, 2]:
			tool.set_normal(Vector3.UP)
			tool.set_uv(uvs[corner])
			tool.add_vertex(quad[corner])
	var water := MeshInstance3D.new()
	water.name = "RiverWater"
	water.mesh = tool.commit()
	water.material_override = water_material
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)


func _build_ponds() -> void:
	for pond in HubTerrain.PONDS:
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		var radius := pond.z + 1.8
		var segments := 28
		for index in segments:
			var a := Vector3(cos(TAU * index / segments), 0.0, sin(TAU * index / segments)) * radius
			var b := Vector3(cos(TAU * (index + 1) / segments), 0.0, sin(TAU * (index + 1) / segments)) * radius
			for vertex in [Vector3.ZERO, a, b]:
				tool.set_normal(Vector3.UP)
				tool.set_uv(Vector2(vertex.x, vertex.z) * 0.1)
				tool.add_vertex(vertex)
		var water := MeshInstance3D.new()
		water.name = "PondWater"
		water.mesh = tool.commit()
		water.material_override = pond_material
		water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		water.position = Vector3(pond.x, HubTerrain.POND_LEVEL, pond.y)
		add_child(water)


## Murs invisibles sur les deux berges, un peu au-dessus de l'eau, sauf sous les ponts dont les parapets prennent
## le relais ; et un anneau autour de l'étang.
func _build_banks() -> void:
	var body := StaticBody3D.new()
	body.name = "Banks"
	add_child(body)
	var course := _course()
	var points: Array[Vector2] = course[0]
	var widths: Array[float] = course[1]
	var normals: Array[Vector2] = course[2]
	for index in points.size() - 1:
		for side: float in [-1.0, 1.0]:
			var a := points[index] + normals[index] * (widths[index] + wall_offset) * side
			var b := points[index + 1] + normals[index + 1] * (widths[index + 1] + wall_offset) * side
			_add_wall(body, a, b, ((normals[index] + normals[index + 1]) * 0.5 * side).normalized())
	for pond in HubTerrain.PONDS:
		var segments := 24
		var radius := pond.z + 0.9
		for index in segments:
			var a := Vector2(pond.x, pond.y) + Vector2.from_angle(TAU * index / segments) * radius
			var b := Vector2(pond.x, pond.y) + Vector2.from_angle(TAU * (index + 1) / segments) * radius
			_add_wall(body, a, b, ((a + b) * 0.5 - Vector2(pond.x, pond.y)).normalized())


## Un pan de mur de a à b ; outward pointe vers la terre ferme, d'où le joueur peut prendre son élan.
## Le mur montait à 3,1 m au-dessus de la berge : depuis le haut d'une berge, un saut en courant le passait et
## le joueur tombait dans le lit, d'où il ne pouvait plus sortir. Il dépasse maintenant tout saut pris alentour.
func _add_wall(body: StaticBody3D, a: Vector2, b: Vector2, outward: Vector2) -> void:
	var middle := (a + b) * 0.5
	if not HubTerrain.inside_limit(middle, -3.0):
		return
	for bridge: Array in HubTerrain.BRIDGES:
		if HubTerrain.bridge_contains(bridge, middle, 0.45):
			return
	var ground := terrain.surface_height(middle.x, middle.y)
	var top := maxf(ground + 3.1, _jump_height(a, b, outward) + wall_margin)
	var bottom := ground - 0.5
	var shape := BoxShape3D.new()
	shape.size = Vector3(a.distance_to(b) + 0.3, top - bottom, 0.4)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3(middle.x, (top + bottom) * 0.5, middle.y)
	collision.rotation.y = -(b - a).angle()
	body.add_child(collision)


## Plus haute altitude des pieds d'un joueur qui arrive sur le pan de mur ab en sautant en courant depuis la terre
## ferme : sol à distance d du mur, plus la hauteur gagnée au bout de d mètres de saut (nulle une fois redescendu).
func _jump_height(a: Vector2, b: Vector2, outward: Vector2) -> float:
	var best := -INF
	var along := (b - a).normalized()
	for spot: Vector2 in [a - along * 1.5, (a + b) * 0.5, b + along * 1.5]:
		var distance := 0.0
		while distance <= JUMP_REACH:
			var t := distance / SPRINT_SPEED
			var rise := maxf(JUMP_VELOCITY * t - 0.5 * 9.8 * t * t, 0.0)
			for slant: float in [-0.5, 0.0, 0.5]:
				var point := spot + (outward + along * slant).normalized() * distance
				best = maxf(best, terrain.surface_height(point.x, point.y) + rise)
			distance += 1.0
	return best


func _is_clear(point: Vector2, margin: float) -> bool:
	if not HubTerrain.inside_limit(point, -12.0):
		return false
	for bridge: Array in HubTerrain.BRIDGES:
		if HubTerrain.bridge_contains(bridge, point, margin):
			return false
	for spot in clear_spots:
		if point.distance_to(Vector2(spot.x, spot.y)) < spot.z:
			return false
	return true


## Vrai si le disque (point, radius) touche une case gravillonnée du sol (une couleur par case de 2 m, prise au centre
## de la case : HubTerrain.gravel_mask).
func _on_gravel(point: Vector2, radius: float) -> bool:
	var origin := HubTerrain.GRID_ORIGIN
	var size := HubTerrain.CELL_SIZE
	for i in range(floori((point.x - radius - origin.x) / size), floori((point.x + radius - origin.x) / size) + 1):
		for j in range(floori((point.y - radius - origin.y) / size), floori((point.y + radius - origin.y) / size) + 1):
			if terrain.gravel_mask(origin.x + (i + 0.5) * size, origin.y + (j + 0.5) * size) > 0.0:
				return true
	return false


## Roseaux en touffes au bord de l'eau, pierres sur les berges et dans le courant, nénuphars dans les eaux calmes.
func _build_life() -> void:
	var course := _course()
	var points: Array[Vector2] = course[0]
	var widths: Array[float] = course[1]
	var normals: Array[Vector2] = course[2]
	var reeds := _groups(reed_models)
	var rocks := _groups(rock_models)
	var lilies := _groups(lily_models)
	var placed := 0
	# Roseaux : par touffes de trois à six tiges, au ras de l'eau et sur le bas de la berge.
	for attempt in reed_count:
		var index := _rng.randi_range(1, points.size() - 2)
		var side := -1.0 if _rng.randf() < 0.5 else 1.0
		var centre := points[index] + normals[index] * (widths[index] + _rng.randf_range(-0.3, 1.4)) * side
		if not _is_clear(centre, 2.5):
			continue
		for stem in _rng.randi_range(2, 4):
			var spot := centre + Vector2(_rng.randf_range(-0.6, 0.6), _rng.randf_range(-0.6, 0.6))
			var ground := maxf(terrain.surface_height(spot.x, spot.y), HubTerrain.WATER_LEVEL - 0.3)
			# Une touffe d'herbe pour deux tiges : les tiges, plus hautes, restent clairsemées.
			var group := _rng.randi() % reeds.size() if _rng.randf() < 0.45 else reeds.size() - 1
			var scale_factor := _rng.randf_range(0.8, 1.3) if group < reeds.size() - 1 else _rng.randf_range(1.6, 2.6)
			reeds[group].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(1.0, _rng.randf_range(0.8, 1.2), 1.0) * scale_factor),
				Vector3(spot.x, ground - 0.05, spot.y)))
			placed += 1
	# Le long des murs invisibles des berges, dans la vallée : une touffe ou une pierre tous les trois mètres environ,
	# pour que la berge se lise comme infranchissable là où elle arrête le joueur.
	for index in range(1, points.size() - 1, 2):
		for side: float in [-1.0, 1.0]:
			var spot := points[index] + normals[index] * (widths[index] + wall_offset * 0.6) * side
			if not HubTerrain.inside_limit(spot, -1.0) or not _is_clear(spot, 1.5):
				continue
			var ground := maxf(terrain.surface_height(spot.x, spot.y), HubTerrain.WATER_LEVEL - 0.3)
			if index % 6 == 1:
				var stone := _rng.randi() % rocks.size()
				rocks[stone].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(2.0, 3.2)), Vector3(spot.x, ground - 0.15, spot.y)))
				continue
			for stem in 3:
				var offset := normals[index].orthogonal() * _rng.randf_range(-0.7, 0.7) + normals[index] * side * _rng.randf_range(-0.3, 0.3)
				var group := reeds.size() - 1 if stem == 0 else _rng.randi() % (reeds.size() - 1)
				var scale_factor := _rng.randf_range(1.8, 2.6) if group == reeds.size() - 1 else _rng.randf_range(0.8, 1.2)
				reeds[group].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * scale_factor), Vector3(spot.x + offset.x, ground - 0.05, spot.y + offset.y)))
	# Même chose autour de l'étang, sur son anneau.
	for pond in HubTerrain.PONDS:
		for step in 18:
			var spot := Vector2(pond.x, pond.y) + Vector2.from_angle(TAU * step / 18.0) * (pond.z + 0.5)
			var ground := maxf(terrain.surface_height(spot.x, spot.y), HubTerrain.POND_LEVEL - 0.2)
			# L'allée du jardin passe à l'ouest de l'étang : rien sur ses cases gravillonnées (les tirages restent les
			# mêmes, pour ne rien déplacer d'autre sur les rives).
			var on_alley := _on_gravel(spot, 0.5)
			var group := _rng.randi() % reeds.size()
			var tuft := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.9, 1.6)), Vector3(spot.x, ground - 0.05, spot.y))
			if not on_alley:
				reeds[group].append(tuft)
			if step % 3 == 0:
				var stone := _rng.randi() % rocks.size()
				var pebble := Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * 1.6), Vector3(spot.x, ground - 0.1, spot.y))
				if not on_alley:
					rocks[stone].append(pebble)
	# Pierres : sur la berge, et quelques-unes à moitié dans l'eau.
	for attempt in rock_count:
		var index := _rng.randi_range(1, points.size() - 2)
		var side := -1.0 if _rng.randf() < 0.5 else 1.0
		var offset := _rng.randf_range(-1.4, 0.8)
		var spot := points[index] + normals[index] * (widths[index] + offset) * side
		if not _is_clear(spot, 1.5):
			continue
		var ground := terrain.surface_height(spot.x, spot.y)
		var group := _rng.randi() % rocks.size()
		var scale_factor := _rng.randf_range(1.2, 3.2)
		rocks[group].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * scale_factor), Vector3(spot.x, ground - 0.08 * scale_factor, spot.y)))
	# Nénuphars : près des rives, là où le courant est faible, et sur l'étang.
	for attempt in lily_count:
		var spot: Vector2
		var level := HubTerrain.WATER_LEVEL
		if attempt % 3 == 0:
			var pond: Vector3 = HubTerrain.PONDS[0]
			spot = Vector2(pond.x, pond.y) + Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * (pond.z - 0.8)
			level = HubTerrain.POND_LEVEL
		else:
			var index := _rng.randi_range(1, points.size() - 2)
			var side := -1.0 if _rng.randf() < 0.5 else 1.0
			spot = points[index] + normals[index] * (widths[index] - _rng.randf_range(0.5, 1.6)) * side
			if not _is_clear(spot, 2.0):
				continue
		var group := _rng.randi() % lilies.size()
		lilies[group].append(Transform3D(Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(2.0, 3.4)), Vector3(spot.x, level + 0.02, spot.y)))
	for index in reed_models.size():
		_add_multimeshes(reed_models[index], reeds[index], 1)
	for index in rock_models.size():
		_add_multimeshes(rock_models[index], rocks[index])
	for index in lily_models.size():
		_lilies.append_array(_add_multimeshes(lily_models[index], lilies[index], 2))


func _groups(models: Array[PackedScene]) -> Array[Array]:
	var groups: Array[Array] = []
	for model in models:
		groups.append([])
	return groups


## Instances d'un modèle par cases de 32 m : chaque case s'efface au loin selon sa propre distance à la caméra.
## wither : 1, son feuillage reprend vie avec les livres ; 2, le modèle entier (un nénuphar et sa fleur).
func _add_multimeshes(model: PackedScene, transforms: Array, wither := 0) -> Array[MultiMesh]:
	var mesh := _load_mesh(model)
	if wither > 0:
		mesh = _foliage.mesh(mesh, wither == 2)
	var cells := {}
	for transform: Transform3D in transforms:
		var cell := Vector2i(floori(transform.origin.x / 32.0), floori(transform.origin.z / 32.0))
		if not cells.has(cell):
			cells[cell] = []
		cells[cell].append(transform)
	var result: Array[MultiMesh] = []
	for cell: Vector2i in cells:
		result.append(_add_multimesh(mesh, cells[cell], wither > 0).multimesh)
	return result


func _add_multimesh(mesh: Mesh, transforms: Array, wither := false) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = wither
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in transforms.size():
		multimesh.set_instance_transform(index, transforms[index])
	if wither:
		HubFoliage.mark(multimesh, terrain)
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.visibility_range_end = detail_range
	instance.visibility_range_end_margin = 10.0
	instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(instance)
	return instance


func _load_mesh(model: PackedScene) -> Mesh:
	var scene := model.instantiate()
	var mesh: Mesh
	for node in scene.find_children("*", "MeshInstance3D", true, false):
		mesh = (node as MeshInstance3D).mesh
		break
	scene.free()
	return mesh
