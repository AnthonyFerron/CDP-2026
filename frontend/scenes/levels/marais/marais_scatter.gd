@tool
class_name MaraisScatter
extends Node3D
## Habille le Marais : pontons et leurs lanternes, arbres, roseaux, nénuphars en fleur, buissons, champignons
## et troncs noyés. Pose aussi au sol maillé le décor de marais_grounded.tscn, et couvre de mousse les
## pierres et les ruines. Les placements sont reproductibles et les petits détails disparaissent au loin.

## Zones gardées libres autour des lieux du parcours et du décor posé à la main : position (x, z) et rayon.
const RESERVED: Array[Vector3] = [
	Vector3(0.0, 58.0, 7.0),
	Vector3(-20.0, 22.0, 6.5),
	Vector3(16.0, 0.0, 11.5),
	Vector3(0.0, -37.0, 12.0),
	# Débarcadère de l'arrivée, chapelle, bosquet mort, pierres levées, dernière maison, vieux débarcadère.
	Vector3(10.0, 51.0, 4.0),
	Vector3(-36.0, -4.0, 7.5),
	Vector3(34.0, -30.0, 5.0),
	Vector3(-30.0, -44.0, 5.5),
	Vector3(36.0, 32.0, 5.0),
	Vector3(-40.0, 40.0, 5.5),
]
## Eaux du village englouti de Brumeval et des épaves : ni nénuphar ni tronc noyé à travers un toit.
const WATER_KEEP_OUT: Array[Vector3] = [
	Vector3(18.0, 30.0, 3.4),
	Vector3(25.0, 22.0, 3.4),
	Vector3(29.0, 38.0, 3.2),
	Vector3(21.5, 40.5, 3.0),
	Vector3(11.0, 25.0, 5.0),
	Vector3(32.0, 30.5, 3.0),
	Vector3(12.5, 49.5, 3.5),
	Vector3(-36.0, 44.5, 3.0),
	Vector3(-7.0, 38.5, 2.5),
]
## Côté des cases des petits détails, et marge de leur fondu au loin.
const CHUNK_SIZE := 32.0
const FADE_MARGIN := 6.0
const PLANK_WIDTH := 2.4
const PLANK_STEP := 1.2
## Lanternes des pontons : un pieu planté dans la vase, au bord des planches, tous les quelques mètres.
const LANTERN_SPACING := 7.0
const LANTERN_OFFSET := 1.55
const LANTERN_SCALE := 2.3

@export var terrain: MaraisTerrain
@export var tree_models: Array[PackedScene]
@export var reed_model: PackedScene
@export var lily_models: Array[PackedScene]
@export var flower_models: Array[PackedScene]
@export var bush_model: PackedScene
@export var mushroom_model: PackedScene
@export var log_model: PackedScene
@export var plank_model: PackedScene
@export var post_model: PackedScene
@export var lantern_model: PackedScene
## Décor dont chaque objet est descendu au sol maillé : marais_grounded.tscn.
@export var grounded: Node3D
## Décor dont les modèles nommés « moss_… » reçoivent la mousse et « dust_… » la poussière : marais_props.tscn
## et marais_crypt.tscn (et marais_grounded.tscn, ci-dessus).
@export var props_root: Node3D
@export var crypt_root: Node3D
@export var moss_material: Material
@export var dust_material: Material
@export var island_tree_count := 70
@export var bank_tree_count := 60
@export var reed_count := 520
@export var lily_count := 260
## Part des grands nénuphars qui portent une fleur.
@export var flower_ratio := 0.4
@export var bush_count := 160
@export var mushroom_count := 70
@export var log_count := 14
## Distance à laquelle les petits détails disparaissent, case par case.
@export var detail_range := 55.0

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	# Le terrain se construit avant ses voisins : il faut ses hauteurs pour poser le décor.
	if not terrain.is_node_ready():
		await terrain.ready
	_rng.seed = 4040
	_build_boardwalks()
	_build_lanterns()
	_scatter_trees()
	_scatter_by_height(reed_model, reed_count, -0.9, 0.05, Vector2(2.0, 3.2), 0.0, _flat_material(Color(0.2, 0.26, 0.1)))
	_scatter_lilies()
	_scatter_by_height(bush_model, bush_count, 0.25, 1.0, Vector2(3.0, 5.0), 0.0)
	_scatter_by_height(mushroom_model, mushroom_count, 0.25, 1.0, Vector2(2.5, 4.0), 0.0)
	_scatter_logs()
	_ground_props()
	_apply_moss()


## Distance au ponton le plus proche, à plat.
func distance_to_boardwalk(point: Vector2) -> float:
	var nearest := INF
	for walk in MaraisTerrain.BOARDWALKS:
		var start := Vector2(walk.x, walk.y)
		var end := Vector2(walk.z, walk.w)
		nearest = minf(nearest, point.distance_to(Geometry2D.get_closest_point_to_segment(point, start, end)))
	return nearest


func _build_boardwalks() -> void:
	var body := StaticBody3D.new()
	body.name = "Boardwalks"
	add_child(body)
	var wood := _flat_material(Color(0.3, 0.2, 0.12))
	for walk in MaraisTerrain.BOARDWALKS:
		var start := Vector3(walk.x, 0.0, walk.y)
		var end := Vector3(walk.z, 0.0, walk.w)
		var direction := (end - start).normalized()
		var length := start.distance_to(end)
		var yaw := atan2(direction.x, direction.z)
		var across := direction.cross(Vector3.UP)
		var count := int(length / PLANK_STEP) + 1
		for i in count:
			var plank: Node3D = plank_model.instantiate()
			plank.position = start + direction * (i * PLANK_STEP) + Vector3.UP * (MaraisTerrain.DECK_HEIGHT - 0.1)
			plank.position.y += _rng.randf_range(-0.03, 0.03)
			plank.rotation.y = yaw + PI * 0.5 + deg_to_rad(_rng.randf_range(-3.0, 3.0))
			plank.scale = Vector3.ONE * PLANK_WIDTH
			body.add_child(plank)
			for mesh: MeshInstance3D in plank.find_children("*", "MeshInstance3D", true, false):
				mesh.material_override = wood
			if i % 3 == 0:
				for side in [-1.0, 1.0]:
					var post: Node3D = post_model.instantiate()
					post.position = plank.position + across * side * (PLANK_WIDTH * 0.5 - 0.1)
					post.position.y = MaraisTerrain.BED_HEIGHT - 0.2
					post.scale = Vector3(0.45, 2.1, 0.45)
					body.add_child(post)
					var pillar := CylinderShape3D.new()
					pillar.radius = 0.12
					pillar.height = 2.1
					var support := CollisionShape3D.new()
					support.shape = pillar
					support.position = post.position + Vector3.UP * 1.05
					body.add_child(support)
		var shape := BoxShape3D.new()
		shape.size = Vector3(PLANK_WIDTH, 0.3, length + PLANK_STEP)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.transform = Transform3D(
			Basis(Vector3.UP, yaw), (start + end) * 0.5 + Vector3.UP * (MaraisTerrain.DECK_HEIGHT - 0.15)
		)
		body.add_child(collision)


## Lanternes des pêcheurs au bord des pontons, en alternance d'un côté et de l'autre : un pieu sort de la vase
## à côté des planches, le réverbère s'y dresse et penche sa lanterne au-dessus du passage.
func _build_lanterns() -> void:
	if not lantern_model:
		return
	var body := StaticBody3D.new()
	body.name = "Lanterns"
	add_child(body)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(2.4, 1.7, 0.7)
	var flame := SphereMesh.new()
	flame.radius = 0.09
	flame.height = 0.2
	flame.material = glow
	# Halo de la flamme, tourné vers la caméra : la lanterne se voit de loin dans la brume.
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 0.8))
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
	halo_material.albedo_color = Color(1.0, 0.75, 0.4, 0.5)
	var halo := QuadMesh.new()
	halo.size = Vector2(1.1, 1.1)
	halo.material = halo_material
	var deck_top := MaraisTerrain.DECK_HEIGHT - 0.03
	var side := 1.0
	for walk in MaraisTerrain.BOARDWALKS:
		var start := Vector3(walk.x, 0.0, walk.y)
		var end := Vector3(walk.z, 0.0, walk.w)
		var direction := (end - start).normalized()
		var across := direction.cross(Vector3.UP)
		var distance := 2.0
		while distance < start.distance_to(end) - 1.5:
			var foot := start + direction * distance + across * side * LANTERN_OFFSET
			var pile: Node3D = post_model.instantiate()
			pile.position = Vector3(foot.x, MaraisTerrain.BED_HEIGHT - 0.3, foot.z)
			pile.scale = Vector3(0.9, deck_top - pile.position.y, 0.9)
			body.add_child(pile)
			var lantern: Node3D = lantern_model.instantiate()
			lantern.position = Vector3(foot.x, deck_top, foot.z)
			# Le bras du réverbère (vers +Z du modèle) se tourne vers le milieu du ponton.
			var inward := -across * side
			lantern.rotation.y = atan2(inward.x, inward.z)
			lantern.scale = Vector3.ONE * LANTERN_SCALE
			body.add_child(lantern)
			var light := MeshInstance3D.new()
			light.mesh = flame
			light.position = Vector3(0.0, 1.0, 0.28)
			light.scale = Vector3.ONE / LANTERN_SCALE
			light.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			lantern.add_child(light)
			var shine := MeshInstance3D.new()
			shine.mesh = halo
			shine.position = light.position
			shine.scale = light.scale
			shine.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			lantern.add_child(shine)
			var shape := CylinderShape3D.new()
			shape.radius = 0.28
			shape.height = 5.4
			var collision := CollisionShape3D.new()
			collision.shape = shape
			collision.position = Vector3(foot.x, MaraisTerrain.BED_HEIGHT + 2.4, foot.z)
			body.add_child(collision)
			side = -side
			distance += LANTERN_SPACING


func _scatter_trees() -> void:
	var body := StaticBody3D.new()
	body.name = "Trees"
	add_child(body)
	var groups: Array[Array] = []
	for model in tree_models:
		groups.append([])
	var placed := 0
	for attempt in island_tree_count * 20:
		if placed >= island_tree_count:
			break
		var spot := _random_spot(MaraisTerrain.PLAY_RADIUS)
		if terrain.height_at(spot.x, spot.y) < 0.2 or _is_reserved(spot, 2.0):
			continue
		var item := _ground_transform(spot, _rng.randf_range(3.2, 4.8))
		groups[placed % groups.size()].append(item)
		var shape := CylinderShape3D.new()
		shape.radius = 0.45
		shape.height = 4.0
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position = item.origin + Vector3.UP * 2.0
		body.add_child(collision)
		placed += 1
	# Le joueur peut gravir la berge : ses arbres ont aussi leur collision au tronc.
	for i in bank_tree_count:
		var angle := TAU * i / bank_tree_count + _rng.randf_range(-0.05, 0.05)
		var spot := Vector2.from_angle(angle) * (MaraisTerrain.PLAY_RADIUS + _rng.randf_range(3.0, 9.0))
		var item := _ground_transform(spot, _rng.randf_range(4.5, 6.5))
		groups[i % groups.size()].append(item)
		var shape := CylinderShape3D.new()
		shape.radius = 0.5
		shape.height = 4.0
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position = item.origin + Vector3.UP * 2.0
		body.add_child(collision)
	for index in tree_models.size():
		var transforms: Array[Transform3D] = []
		transforms.assign(groups[index])
		var mesh := _load_mesh(tree_models[index])
		var instance := _add_multimesh(mesh, transforms)
		instance.visibility_range_end = 0.0


func _scatter_by_height(
	model: PackedScene, count: int, low: float, high: float, scale_range: Vector2, sink: float, material: Material = null
) -> void:
	var items: Array[Transform3D] = []
	for attempt in count * 6:
		if items.size() >= count:
			break
		var spot := _random_spot(MaraisTerrain.PLAY_RADIUS)
		var height := terrain.height_at(spot.x, spot.y)
		if height < low or height > high or _is_reserved(spot, 0.5) or distance_to_boardwalk(spot) < 1.8:
			continue
		var item := _ground_transform(spot, _rng.randf_range(scale_range.x, scale_range.y))
		item.origin.y -= sink
		items.append(item)
	_add_chunked(_load_mesh(model), items, material)


## Nénuphars sur les eaux profondes ; une partie des grands porte une fleur, posée au cœur de la feuille.
func _scatter_lilies() -> void:
	var per_model := lily_count / lily_models.size()
	var flowers: Array[Array] = []
	for model in flower_models:
		flowers.append([])
	for model_index in lily_models.size():
		var items: Array[Transform3D] = []
		for attempt in per_model * 6:
			if items.size() >= per_model:
				break
			var spot := _random_spot(MaraisTerrain.PLAY_RADIUS)
			if terrain.height_at(spot.x, spot.y) > -0.5 or distance_to_boardwalk(spot) < 1.5 or _in_keep_out(spot):
				continue
			var size := _rng.randf_range(3.0, 5.0)
			var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * size)
			items.append(Transform3D(basis, Vector3(spot.x, MaraisTerrain.WATER_LEVEL - 0.03, spot.y)))
			if model_index == 0 and not flowers.is_empty() and _rng.randf() < flower_ratio:
				var bloom := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * size * 0.55)
				var heart := Vector3(spot.x, MaraisTerrain.WATER_LEVEL - 0.03 + 0.035 * size, spot.y)
				flowers[_rng.randi() % flowers.size()].append(Transform3D(bloom, heart))
		_add_chunked(_load_mesh(lily_models[model_index]), items)
	for index in flower_models.size():
		var transforms: Array[Transform3D] = []
		transforms.assign(flowers[index])
		_add_chunked(_load_mesh(flower_models[index]), transforms)


func _scatter_logs() -> void:
	var items: Array[Transform3D] = []
	for attempt in log_count * 20:
		if items.size() >= log_count:
			break
		var spot := _random_spot(MaraisTerrain.PLAY_RADIUS - 4.0)
		if terrain.height_at(spot.x, spot.y) > -0.8 or distance_to_boardwalk(spot) < 3.5 or _in_keep_out(spot):
			continue
		var basis := Basis(Vector3.UP, _rng.randf() * TAU) * Basis(Vector3.RIGHT, deg_to_rad(_rng.randf_range(-12.0, 12.0)))
		items.append(Transform3D(basis.scaled(Vector3.ONE * _rng.randf_range(3.0, 4.5)), Vector3(spot.x, -0.55, spot.y)))
	var instance := _add_multimesh(_load_mesh(log_model), items)
	instance.visibility_range_end = 0.0


## Descend chaque objet de marais_grounded.tscn sur le sol maillé : son pied se pose au point le plus bas de son
## emprise (métadonnée footprint, en mètres), pour ne jamais flotter au-dessus d'une berge en pente.
func _ground_props() -> void:
	if not grounded:
		return
	for item: Node3D in grounded.get_children():
		var radius: float = item.get_meta(&"footprint", 0.4)
		var lowest := terrain.footing_height(item.position.x, item.position.z)
		for step in 8:
			var offset := Vector2.from_angle(TAU * step / 8.0) * radius
			lowest = minf(lowest, terrain.footing_height(item.position.x + offset.x, item.position.z + offset.y))
		item.position.y += lowest


## Mousse en surcouche sur les modèles nommés « moss_… » (pierres levées, ruines, épaves, tombes usées), poussière
## sur les « dust_… » (tombeaux et ossements de la crypte).
func _apply_moss() -> void:
	for root: Node3D in [grounded, props_root, crypt_root]:
		if not root:
			continue
		for coat: Array in [["moss_*", moss_material], ["dust_*", dust_material]]:
			if not coat[1]:
				continue
			for node in root.find_children(coat[0], "Node3D", true, false):
				for mesh: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
					mesh.material_overlay = coat[1]


func _is_reserved(spot: Vector2, margin: float) -> bool:
	for zone in RESERVED:
		if spot.distance_to(Vector2(zone.x, zone.y)) < zone.z + margin:
			return true
	return distance_to_boardwalk(spot) < 2.5 + margin


func _in_keep_out(spot: Vector2) -> bool:
	for zone in WATER_KEEP_OUT:
		if spot.distance_to(Vector2(zone.x, zone.y)) < zone.z:
			return true
	return false


func _random_spot(radius: float) -> Vector2:
	return Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * radius


func _ground_transform(spot: Vector2, scale_factor: float) -> Transform3D:
	var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * scale_factor)
	return Transform3D(basis, Vector3(spot.x, terrain.footing_height(spot.x, spot.y) - 0.05, spot.y))


## Dispersion permanente (arbres, troncs noyés) : un seul MultiMesh pour toute la carte, visible de partout.
func _add_multimesh(mesh: Mesh, transforms: Array[Transform3D], origin := Vector3.ZERO) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in transforms.size():
		multimesh.set_instance_transform(index, transforms[index].translated(-origin))
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.position = origin
	add_child(instance)
	return instance


## Petits détails (roseaux, nénuphars, fleurs, buissons, champignons) : découpés en cases de CHUNK_SIZE mètres,
## un MultiMesh par case, posé au centre de sa case. Godot mesure la distance d'affichage jusqu'au centre de chaque
## MultiMesh : une case entière s'efface au loin, mais jamais ce qui est sous les pieds du joueur.
func _add_chunked(mesh: Mesh, transforms: Array[Transform3D], material: Material = null) -> void:
	var cells := {}
	for item in transforms:
		var key := Vector2i(floori(item.origin.x / CHUNK_SIZE), floori(item.origin.z / CHUNK_SIZE))
		if not cells.has(key):
			cells[key] = [] as Array[Transform3D]
		cells[key].append(item)
	for key: Vector2i in cells:
		var center := Vector3((key.x + 0.5) * CHUNK_SIZE, 0.0, (key.y + 0.5) * CHUNK_SIZE)
		var instance := _add_multimesh(mesh, cells[key], center)
		instance.name = "Detail_%d_%d" % [key.x, key.y]
		instance.material_override = material
		instance.visibility_range_end = detail_range
		instance.visibility_range_end_margin = FADE_MARGIN
		instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF


func _flat_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material


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
