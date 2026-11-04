@tool
class_name PlaineScatter
extends Node3D
## Habille la Plaine : herbe brûlée, roches, arbres morts, lanternes, lave dans les cratères et dans la coulée.
## Les placements sont reproductibles et l'herbe disparaît au loin pour alléger le rendu.

signal lava_touched(body: Node3D)

const SMOKING_CRATERS := 4
const LIT_CRATERS := 4
const SMOKING_IMPACTS := 4
## Hauteur des poteaux des lanternes.
const POST_HEIGHT := 2.7
## Pas des bandes de la zone qui brûle, et épaisseur de lave à partir de laquelle elle brûle.
const HAZARD_STEP := 0.25
const HAZARD_DEPTH := 0.08
const HAZARD_LENGTH := 1.0
## Côté des cases des petits détails (herbes, cailloux), et longueur de leur fondu au loin.
const CHUNK_SIZE := 32.0
const CHUNK_FADE := 8.0
## Lanternes du chemin : position (x, z), et si elles sont renversées. Deux gardent les têtes du pont.
const LANTERNS: Array[Vector3] = [
	Vector3(-3.2, 16.5, 0.0),
	Vector3(3.0, 22.0, 0.0),
	Vector3(-3.0, 37.0, 0.0),
	Vector3(3.4, 37.6, 1.0),
	Vector3(3.4, 44.0, 0.0),
	Vector3(-3.4, 48.0, 1.0),
]
## Points à garder nus (x, z, rayon) : panneaux, stèles et abords du pont, où rien ne doit pousser.
const CLEARINGS: Array[Vector3] = [
	Vector3(-8.6, 15.5, 2.6),
	Vector3(-4.6, 46.0, 2.2),
	Vector3(0.0, 29.5, 8.0),
]

@export var terrain: PlaineTerrain
@export var grass_models: Array[PackedScene]
@export var small_rock_models: Array[PackedScene]
@export var large_rock_models: Array[PackedScene]
## Poteau de bois et lanterne à bougie des lanternes du chemin.
@export var post_model: PackedScene
@export var lantern_model: PackedScene
@export var lava_material: Material
@export var lava_sound: AudioStream
@export var grass_count := 1500
@export var small_rock_count := 220
@export var large_rock_count := 26
@export var dead_tree_count := 38
@export var border_rock_count := 46
## Distance à laquelle les petits détails disparaissent.
@export var detail_range := 60.0

## Bassins de lave : centre de la surface et rayon.
var lava_pools: Array[Dictionary] = []
## Sommet du tronc de chaque modèle d'arbre mort, pour pencher sa collision comme lui.
var _tree_tops: Array[Vector3] = []
## Dessous de chaque modèle de gros rocher, en 25 points de son emprise (repère du modèle).
var _undersides := {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	# Le terrain se construit avant ses voisins : il faut ses hauteurs pour poser le décor.
	if not terrain.is_node_ready():
		await terrain.ready
	_rng.seed = 2026
	_scatter_grass()
	_scatter_small_rocks()
	_scatter_large_rocks()
	_scatter_dead_trees()
	_add_border_rocks()
	_add_lanterns()
	_add_crater_effects()
	_add_lava_flow()
	_add_lava_hazards()


func is_near_lava(point: Vector3, margin: float) -> bool:
	for pool in lava_pools:
		var center: Vector3 = pool.center
		if Vector2(point.x - center.x, point.z - center.z).length() < pool.radius + margin:
			return true
	return PlaineTerrain.flow_distance(point.x, point.z) < PlaineTerrain.flow_lava_half_width() + margin


func _scatter_grass() -> void:
	var soot := _flat_material(Color(0.07, 0.06, 0.065))
	var rust := _flat_material(Color(0.36, 0.13, 0.05))
	for model_index in grass_models.size():
		var mesh := _load_mesh(grass_models[model_index])
		var share := grass_count / grass_models.size()
		var burnt: Array[Transform3D] = []
		var glowing: Array[Transform3D] = []
		for i in share:
			var spot := _random_spot(0.0)
			var scale_factor := _rng.randf_range(2.5, 5.0)
			var item := _ground_transform(spot, scale_factor)
			if _rng.randf() < 0.22:
				glowing.append(item)
			else:
				burnt.append(item)
		_add_chunked_multimesh(mesh, burnt, soot, "Grass")
		_add_chunked_multimesh(mesh, glowing, rust, "Grass")


func _scatter_small_rocks() -> void:
	var material := _flat_material(Color(0.2, 0.18, 0.2))
	var count := small_rock_count / small_rock_models.size()
	var body := StaticBody3D.new()
	body.name = "SmallRocks"
	add_child(body)
	for model in small_rock_models:
		var mesh := _load_mesh(model)
		var size := mesh.get_aabb().size
		var items: Array[Transform3D] = []
		for i in count:
			var item := _ground_transform(_random_spot(0.3), _rng.randf_range(1.5, 4.0))
			items.append(item)
			# Les cailloux assez hauts pour gêner le pas ont une collision à leur taille ; les plus plats se franchissent.
			if (size * item.basis.get_scale()).y < 0.25:
				continue
			body.add_child(_rock_collision(mesh, item, false))
		_add_chunked_multimesh(mesh, items, material, "Pebbles")


func _scatter_large_rocks() -> void:
	var material := _flat_material(Color(0.17, 0.15, 0.17))
	var count := large_rock_count / large_rock_models.size()
	var body := StaticBody3D.new()
	body.name = "LargeRocks"
	add_child(body)
	for model in large_rock_models:
		var mesh := _load_mesh(model)
		var items: Array[Transform3D] = []
		for i in count:
			var item := _sink_rock(mesh, _ground_transform(_random_spot(1.1), _rng.randf_range(5.0, 9.0)))
			items.append(item)
			body.add_child(_rock_collision(mesh, item, true))
		var instance := _add_multimesh(mesh, items, material)
		instance.name = "LargeRocksMesh%d" % get_child_count()
		instance.visibility_range_end = 0.0


func _scatter_dead_trees() -> void:
	var material := _flat_material(Color(0.08, 0.06, 0.06))
	var meshes: Array[ArrayMesh] = [_dead_tree_mesh(), _dead_tree_mesh(), _dead_tree_mesh()]
	var body := StaticBody3D.new()
	body.name = "DeadTrees"
	add_child(body)
	var items: Array[Array] = [[], [], []]
	for i in dead_tree_count:
		var spot := _random_spot(1.0)
		var item := _ground_transform(spot, _rng.randf_range(0.9, 1.5))
		items[i % meshes.size()].append(item)
		# Le tronc penche : sa collision le suit, à sa grosseur, jusqu'au-dessus de la tête.
		var axis := (item.basis * _tree_tops[i % meshes.size()]).normalized()
		var shape := CylinderShape3D.new()
		shape.radius = 0.44 * item.basis.get_scale().x
		shape.height = 3.2
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.transform = Transform3D(Basis(Quaternion(Vector3.UP, axis)), item.origin + axis * 1.6)
		body.add_child(collision)
	for index in meshes.size():
		var transforms: Array[Transform3D] = []
		transforms.assign(items[index])
		var instance := _add_multimesh(meshes[index], transforms, material)
		instance.name = "DeadTreesMesh%d" % index
		instance.visibility_range_end = 0.0


## Collision d'un rocher, à sa taille. Un caillou d'un seul bloc prend l'enveloppe convexe de son maillage ; un gros
## rocher, fait de plusieurs blocs, prend son maillage même (exact) : une enveloppe comblait les creux entre les
## blocs, des murs invisibles de plusieurs mètres une fois le rocher grossi.
func _rock_collision(mesh: Mesh, item: Transform3D, exact: bool) -> CollisionShape3D:
	var points := PackedVector3Array()
	var scale := item.basis.get_scale()
	for vertex in mesh.get_faces():
		points.append(vertex * scale)
	var shape: Shape3D
	if exact:
		var faces := ConcavePolygonShape3D.new()
		faces.set_faces(points)
		shape = faces
	else:
		var hull := ConvexPolygonShape3D.new()
		hull.points = points
		shape = hull
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.transform = Transform3D(item.basis.orthonormalized(), item.origin)
	return collision


## Abaisse un gros rocher pour qu'aucun de ses bords ne flotte : en 25 points de son emprise, jusqu'à ses bords, le dessous de son
## maillage (lu sur ses triangles, une fois par modèle) doit passer sous le sol. Sur la pente des remparts, un rocher
## posé à la hauteur de son centre débordait de plusieurs mètres dans le vide du côté de la descente.
func _sink_rock(mesh: Mesh, item: Transform3D) -> Transform3D:
	if not _undersides.has(mesh):
		var faces := mesh.get_faces()
		var box := mesh.get_aabb()
		var points: Array[Vector3] = []
		var ratios: Array[float] = [0.03, 0.25, 0.5, 0.75, 0.97]
		for u in ratios:
			for v in ratios:
				var local := Vector3(box.position.x + box.size.x * u, box.position.y - 1.0, box.position.z + box.size.z * v)
				var underside := INF
				for t in range(0, faces.size(), 3):
					var hit: Variant = Geometry3D.ray_intersects_triangle(local, Vector3.UP, faces[t], faces[t + 1], faces[t + 2])
					if hit != null:
						underside = minf(underside, (hit as Vector3).y)
				if underside < INF:
					points.append(Vector3(local.x, underside, local.z))
		_undersides[mesh] = points
	var gap := 0.0
	for point: Vector3 in _undersides[mesh]:
		var world := item * point
		gap = maxf(gap, world.y - terrain.surface_height(world.x, world.z))
	if gap > 0.0:
		item.origin.y -= gap + 0.05
	return item


## Remparts : de hauts rochers sur le pourtour, pour que la zone ne s'arrête pas sur une pente nue.
func _add_border_rocks() -> void:
	var material := _flat_material(Color(0.16, 0.14, 0.16))
	var items: Array[Array] = []
	items.resize(large_rock_models.size())
	for list in items:
		list.assign([])
	for i in border_rock_count:
		var angle := TAU * i / border_rock_count + _rng.randf_range(-0.04, 0.04)
		var distance := PlaineTerrain.PLAY_RADIUS + _rng.randf_range(1.5, 7.0)
		var spot := Vector2.from_angle(angle) * distance
		var item := _ground_transform(spot, _rng.randf_range(9.0, 16.0))
		item.origin.y -= 0.6
		items[i % items.size()].append(item)
	# Les plus gros débordent en deçà de la limite : ils ont leur collision, comme les rochers de la plaine.
	var body := StaticBody3D.new()
	body.name = "BorderRocks"
	add_child(body)
	for index in large_rock_models.size():
		var transforms: Array[Transform3D] = []
		transforms.assign(items[index])
		var border_mesh := _load_mesh(large_rock_models[index])
		for k in transforms.size():
			transforms[k] = _sink_rock(border_mesh, transforms[k])
		for item: Transform3D in transforms:
			body.add_child(_rock_collision(border_mesh, item, true))
		var instance := _add_multimesh(border_mesh, transforms, material)
		instance.name = "BorderRocksMesh%d" % index
		instance.visibility_range_end = 0.0


## Lanternes du chemin : un poteau de bois, une potence et une lanterne à bougie qui pend vers le chemin.
## Certaines tiennent encore debout et brillent, d'autres sont tombées, leur lanterne renversée dans la cendre.
func _add_lanterns() -> void:
	var flame := StandardMaterial3D.new()
	flame.albedo_color = Color(1.0, 0.62, 0.25)
	flame.emission_enabled = true
	flame.emission = Color(1.0, 0.55, 0.2)
	flame.emission_energy_multiplier = 4.0
	var wick := SphereMesh.new()
	wick.radius = 0.06
	wick.height = 0.12
	wick.material = flame
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.22, 0.14, 0.08)
	var beam := BoxMesh.new()
	beam.size = Vector3(0.75, 0.1, 0.1)
	beam.material = wood
	var lanterns := Node3D.new()
	lanterns.name = "Lanterns"
	add_child(lanterns)
	var body := StaticBody3D.new()
	body.name = "LanternPosts"
	add_child(body)
	for spot in LANTERNS:
		var ground := terrain.footing_height(spot.x, spot.y)
		var fallen := spot.z > 0.5
		# La potence se tourne vers le chemin ; un poteau tombé tombe du côté opposé, pour ne jamais le barrer.
		var toward := 1.0 if spot.x < 0.0 else -1.0
		var post: Node3D = post_model.instantiate()
		post.scale = Vector3(2.0, POST_HEIGHT, 2.0)
		var lantern: Node3D = lantern_model.instantiate()
		lantern.scale = Vector3.ONE * 1.6
		var shape := BoxShape3D.new()
		var collision := CollisionShape3D.new()
		collision.shape = shape
		var base := Vector3(spot.x, ground, spot.y)
		if fallen:
			var heading := Basis(Vector3.UP, (0.0 if spot.x < 0.0 else PI) + _rng.randf_range(-0.45, 0.45))
			# Couché par une rotation autour de z : le poteau s'étend vers -x, dans son cap.
			post.basis = heading * Basis(Vector3.BACK, deg_to_rad(90.0)) * Basis.from_scale(post.scale)
			post.position = base + Vector3.UP * 0.16
			var tip := base + heading * Vector3(-POST_HEIGHT - 0.5, 0.0, 0.0)
			lantern.basis = heading * Basis(Vector3.BACK, deg_to_rad(80.0)) * Basis.from_scale(lantern.scale)
			lantern.position = tip + Vector3.UP * 0.2
			# Le poteau couché et sa lanterne, à leur taille : rien de plus large qu'eux.
			shape.size = Vector3(POST_HEIGHT + 1.0, 0.36, 0.45)
			collision.transform = Transform3D(heading, base + heading * Vector3(-(POST_HEIGHT + 1.0) * 0.5, 0.18, 0.0))
		else:
			post.position = base
			var arm := MeshInstance3D.new()
			arm.mesh = beam
			arm.position = base + Vector3(toward * 0.3, POST_HEIGHT - 0.12, 0.0)
			lanterns.add_child(arm)
			# La lanterne pend sous le bout de la potence, au-dessus de la tête du joueur.
			lantern.position = base + Vector3(toward * 0.58, POST_HEIGHT - 0.17 - 0.39 * 1.6, 0.0)
			var light := MeshInstance3D.new()
			light.mesh = wick
			light.position = lantern.position + Vector3.UP * 0.3
			add_child(light)
			shape.size = Vector3(0.5, POST_HEIGHT + 0.3, 0.5)
			collision.position = base + Vector3.UP * (POST_HEIGHT + 0.3) * 0.5
		lanterns.add_child(post)
		lanterns.add_child(lantern)
		body.add_child(collision)


func _add_crater_effects() -> void:
	var smoke_texture := _smoke_texture()
	var ember_material := _ember_material()
	for index in PlaineTerrain.CRATERS.size():
		var crater := PlaineTerrain.CRATERS[index]
		var center := Vector3(crater.x, terrain.height_at(crater.x, crater.y), crater.y)
		var radius := crater.z * PlaineTerrain.LAVA_RATIO
		var surface := terrain.crater_lava_level(index)
		var pool := Vector3(crater.x, surface, crater.y)
		lava_pools.append({center = pool, radius = radius})
		add_child(_lava_surface(pool, radius))
		add_child(_embers(pool, radius, ember_material))
		if lava_sound:
			var rumble := AudioStreamPlayer3D.new()
			rumble.stream = lava_sound
			rumble.position = pool
			rumble.unit_size = radius
			rumble.max_distance = radius * 4.0
			rumble.volume_db = -4.0
			rumble.autoplay = not Engine.is_editor_hint()
			add_child(rumble)
		if index < LIT_CRATERS:
			var light := FlickeringLight.new()
			light.light_color = Color(1.0, 0.36, 0.1)
			light.light_energy = 3.0
			light.omni_range = crater.z * 1.5
			light.flicker = 0.18
			light.speed = 2.0
			light.position = pool + Vector3.UP * 2.0
			add_child(light)
		if index < SMOKING_CRATERS:
			add_child(_smoke(center, crater.z * 0.3, smoke_texture))
	# Quelques trous d'obus fument encore.
	for index in SMOKING_IMPACTS:
		var impact := PlaineTerrain.IMPACTS[index * 3 % PlaineTerrain.IMPACTS.size()]
		var smoke := _smoke(Vector3(impact.x, terrain.height_at(impact.x, impact.y), impact.y), 0.8, smoke_texture)
		smoke.amount = 6
		smoke.scale_amount_max = 1.4
		add_child(smoke)


## Coulée de lave : un ruban incandescent au fond du lit, qui suit sa pente d'un cratère à l'autre et se jette dans
## leurs lacs à leur niveau (PlaineTerrain.flow_lava_height), avec sa zone qui brûle, ses braises, sa lueur et son
## grondement.
func _add_lava_flow() -> void:
	var points: Array[Vector2] = []
	var flow := PlaineTerrain.LAVA_FLOW
	for index in flow.size() - 1:
		var steps := ceili(flow[index].distance_to(flow[index + 1]) / 1.0)
		for step in steps:
			points.append(flow[index].lerp(flow[index + 1], float(step) / steps))
	points.append(flow[flow.size() - 1])
	var heights: Array[float] = []
	for point in points:
		heights.append(terrain.flow_lava_height(point.x, point.y))

	# Ruban un peu plus large que la lave visible : ses bords passent sous les berges.
	var half := PlaineTerrain.flow_lava_half_width() + 0.5
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var along := 0.0
	for index in points.size() - 1:
		var quad: Array[Vector3] = []
		for corner in 2:
			var i := index + corner
			var tangent := (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]).normalized()
			var side := Vector2(-tangent.y, tangent.x) * half
			quad.append(Vector3(points[i].x + side.x, heights[i], points[i].y + side.y))
			quad.append(Vector3(points[i].x - side.x, heights[i], points[i].y - side.y))
		var length := points[index].distance_to(points[index + 1])
		var uvs: Array[Vector2] = [
			Vector2(along, 0.0), Vector2(along, 1.0), Vector2(along + length, 0.0), Vector2(along + length, 1.0)
		]
		along += length
		for corner: int in [0, 2, 1, 1, 2, 3]:
			tool.set_uv(uvs[corner])
			tool.set_normal(Vector3.UP)
			tool.add_vertex(quad[corner])
	var material := lava_material.duplicate() as ShaderMaterial
	material.set_shader_parameter("ribbon", true)
	var surface := MeshInstance3D.new()
	surface.name = "LavaFlow"
	surface.mesh = tool.commit()
	surface.material_override = material
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(surface)


	# Braises, lueurs et grondement le long du lit.
	var ember_material := _ember_material()
	for fraction in [0.12, 0.38, 0.62, 0.88]:
		var i := int(fraction * (points.size() - 1))
		var spot := Vector3(points[i].x, heights[i], points[i].y)
		add_child(_embers(spot, 2.6, ember_material))
		# Deux lueurs suffisent : chaque lumière coûte cher au rendu web.
		if fraction < 0.3 or fraction > 0.7:
			continue
		var light := FlickeringLight.new()
		light.light_color = Color(1.0, 0.4, 0.12)
		light.light_energy = 2.2
		light.omni_range = 9.0
		light.flicker = 0.2
		light.speed = 1.6
		light.position = spot + Vector3.UP * 1.6
		add_child(light)
		if lava_sound and fraction > 0.3 and fraction < 0.7:
			var rumble := AudioStreamPlayer3D.new()
			rumble.stream = lava_sound
			rumble.position = spot
			rumble.unit_size = 3.0
			rumble.max_distance = 18.0
			rumble.volume_db = -6.0
			rumble.autoplay = not Engine.is_editor_hint()
			add_child(rumble)


func _lava_surface(center: Vector3, radius: float) -> MeshInstance3D:
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * radius * 2.0
	plane.subdivide_width = 24
	plane.subdivide_depth = 24
	plane.material = lava_material
	var surface := MeshInstance3D.new()
	surface.mesh = plane
	surface.position = center
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return surface


## Hauteur de la lave visible en un point : lac d'un cratère ou ruban de la coulée, sinon -INF.
func lava_surface_at(x: float, z: float) -> float:
	var lava := -INF
	for pool in lava_pools:
		var center: Vector3 = pool.center
		if Vector2(x - center.x, z - center.z).length() < pool.radius:
			lava = maxf(lava, center.y)
	if PlaineTerrain.flow_distance(x, z) < PlaineTerrain.flow_lava_half_width() + 0.5:
		var nearest := PlaineTerrain.flow_nearest(x, z)
		lava = maxf(lava, terrain.flow_lava_height(nearest.x, nearest.y))
	return lava


## Zone qui brûle, calée sur la lave visible : par rangées de HAZARD_STEP mètres, des bandes là où la lave couvre le
## sol de plus de HAZARD_DEPTH. Elle colle aux rives tortueuses des lacs comme aux élargissements de la coulée, et
## reste sous le tablier du pont.
func _add_lava_hazards() -> void:
	var area := Area3D.new()
	area.name = "LavaHazard"
	add_child(area)
	var regions: Array[Rect2] = []
	for pool in lava_pools:
		var center: Vector3 = pool.center
		regions.append(Rect2(center.x - pool.radius, center.z - pool.radius, pool.radius * 2.0, pool.radius * 2.0))
	var flow := PlaineTerrain.LAVA_FLOW
	var bounds := Rect2(flow[0], Vector2.ZERO)
	for point in flow:
		bounds = bounds.expand(point)
	regions.append(bounds.grow(PlaineTerrain.flow_lava_half_width() + 0.5))
	for region in regions:
		var z := region.position.y + HAZARD_STEP * 0.5
		while z < region.end.y:
			var start := INF
			var top := -INF
			var bottom := INF
			var x := region.position.x
			while x <= region.end.x + HAZARD_STEP:
				var ground := terrain.surface_height(x, z)
				var lava := lava_surface_at(x, z) if x <= region.end.x else -INF
				# La bande couvre toute sa rangée : la lave doit y couvrir le sol d'un bord à l'autre.
				var depth := lava - ground
				for edge in [-HAZARD_STEP * 0.48, HAZARD_STEP * 0.48]:
					depth = minf(depth, lava_surface_at(x, z + edge) - terrain.surface_height(x, z + edge))
				# Bandes courtes, pour que leur dessus suive la lave : jamais au-dessus du tablier du pont.
				if start != INF and x - start > HAZARD_LENGTH:
					_hazard_strip(area, start, x, z, bottom - 0.4, top + 0.3)
					start = INF
					top = -INF
					bottom = INF
				if depth > HAZARD_DEPTH:
					if start == INF:
						start = x
					top = maxf(top, lava)
					bottom = minf(bottom, ground)
				elif start != INF:
					_hazard_strip(area, start, x, z, bottom - 0.4, top + 0.3)
					start = INF
					top = -INF
					bottom = INF
				x += HAZARD_STEP * 0.5
			z += HAZARD_STEP
	print_verbose("Plaine : %d bandes de lave" % area.get_child_count())
	area.body_entered.connect(func(body: Node3D) -> void: lava_touched.emit(body))


func _hazard_strip(area: Area3D, from_x: float, to_x: float, z: float, bottom: float, top: float) -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(to_x - from_x, top - bottom, HAZARD_STEP)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = Vector3((from_x + to_x) * 0.5 - HAZARD_STEP * 0.25, (top + bottom) * 0.5, z)
	area.add_child(collision)


func _embers(center: Vector3, radius: float, material: Material) -> CPUParticles3D:
	var quad := QuadMesh.new()
	quad.size = Vector2(0.12, 0.12)
	quad.material = material
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.8, 0.3, 1.0))
	gradient.set_color(1, Color(1.0, 0.2, 0.05, 0.0))
	var embers := CPUParticles3D.new()
	embers.mesh = quad
	embers.position = center + Vector3.UP * 0.2
	embers.amount = 18
	embers.lifetime = 3.5
	embers.preprocess = 3.5
	embers.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	embers.emission_sphere_radius = radius * 0.8
	embers.direction = Vector3.UP
	embers.spread = 25.0
	embers.gravity = Vector3(0.3, 0.4, 0.0)
	embers.initial_velocity_min = 0.6
	embers.initial_velocity_max = 1.8
	embers.color_ramp = gradient
	return embers


func _ember_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color(2.5, 1.4, 0.6)
	# Braise ronde et douce, plutôt qu'un carré.
	material.albedo_texture = _smoke_texture()
	return material


func _smoke(center: Vector3, radius: float, texture: Texture2D) -> CPUParticles3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = texture
	var quad := QuadMesh.new()
	quad.size = Vector2(5.0, 5.0)
	quad.material = material

	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.3, 0.26, 0.28, 0.0))
	gradient.set_color(1, Color(0.2, 0.18, 0.2, 0.0))
	gradient.add_point(0.2, Color(0.28, 0.24, 0.26, 0.4))

	var smoke := CPUParticles3D.new()
	smoke.mesh = quad
	smoke.position = center
	smoke.amount = 12
	smoke.lifetime = 12.0
	smoke.preprocess = 12.0
	smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	smoke.emission_sphere_radius = radius
	smoke.direction = Vector3.UP
	smoke.spread = 12.0
	smoke.gravity = Vector3.ZERO
	smoke.initial_velocity_min = 1.0
	smoke.initial_velocity_max = 1.8
	smoke.scale_amount_min = 1.0
	smoke.scale_amount_max = 2.2
	smoke.color_ramp = gradient
	return smoke


func _smoke_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture


## Tire un point libre : ni sur les ruines, ni sur le chemin, ni sur un replat, ni dans un cratère ou dans la coulée.
func _random_spot(crater_margin: float) -> Vector2:
	var spot := Vector2.ZERO
	for attempt in 40:
		spot = Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * PlaineTerrain.PLAY_RADIUS
		if _is_free(spot, crater_margin):
			break
	return spot


func _is_free(spot: Vector2, crater_margin: float) -> bool:
	# Les abords des ruines gardent leur propre décor, posé par tools/build_plaine.py.
	if spot.length() < 23.5:
		return false
	if absf(spot.x) < 4.5 and spot.y > 0.0:
		return false
	for site in PlaineTerrain.SITES:
		if spot.distance_to(Vector2(site.x, site.y)) < site.z + 2.0:
			return false
	for clearing in CLEARINGS:
		if spot.distance_to(Vector2(clearing.x, clearing.y)) < clearing.z:
			return false
	if PlaineTerrain.flow_distance(spot.x, spot.y) < PlaineTerrain.FLOW_HALF_WIDTH + crater_margin * 1.5:
		return false
	if PlaineTerrain.impact_ratio(spot.x, spot.y) < 0.7 + crater_margin * 0.4:
		return false
	for crater in PlaineTerrain.CRATERS:
		if Vector2(spot.x - crater.x, spot.y - crater.y).length() < crater.z * crater_margin:
			return false
	return true


func _ground_transform(spot: Vector2, scale_factor: float) -> Transform3D:
	var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * scale_factor)
	return Transform3D(basis, Vector3(spot.x, terrain.footing_height(spot.x, spot.y) - 0.05, spot.y))


func _add_multimesh(
	mesh: Mesh, transforms: Array[Transform3D], material: Material
) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in transforms.size():
		multimesh.set_instance_transform(index, transforms[index])
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.material_override = material
	instance.visibility_range_end = detail_range
	instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(instance)
	return instance


## Petits détails qui s'effacent au loin : un MultiMesh par case de CHUNK_SIZE mètres. Godot mesure la distance
## d'effacement jusqu'au centre de la boîte de chaque MultiMesh : avec une seule boîte pour toute la carte, tout
## s'effaçait d'un coup, même sous les pieds du joueur, dès qu'il s'éloignait du centre.
func _add_chunked_multimesh(mesh: Mesh, transforms: Array[Transform3D], material: Material, kind: String) -> void:
	var cells := {}
	for item in transforms:
		var cell := Vector2i(floori(item.origin.x / CHUNK_SIZE), floori(item.origin.z / CHUNK_SIZE))
		if not cells.has(cell):
			cells[cell] = []
		(cells[cell] as Array).append(item)
	for cell: Vector2i in cells:
		var items: Array[Transform3D] = []
		items.assign(cells[cell])
		var instance := _add_multimesh(mesh, items, material)
		instance.name = "%sDetail%d_%d_%d" % [kind, get_child_count(), cell.x, cell.y]
		instance.visibility_range_end_margin = CHUNK_FADE


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


func _dead_tree_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var height := _rng.randf_range(5.0, 7.5)
	var lean := Vector3(_rng.randf_range(-0.5, 0.5), 0.0, _rng.randf_range(-0.5, 0.5))
	var top := Vector3.UP * height + lean
	_tree_tops.append(top)
	_add_limb(tool, Vector3.ZERO, top, 0.42, 0.1)
	for i in _rng.randi_range(4, 6):
		var start := top * _rng.randf_range(0.45, 0.95)
		var angle := _rng.randf() * TAU
		var reach := _rng.randf_range(1.4, 2.8)
		var tip := start + Vector3(cos(angle) * reach, reach * 0.8, sin(angle) * reach)
		_add_limb(tool, start, tip, 0.16, 0.03)
		var side := tip.lerp(start, 0.4)
		_add_limb(tool, side, side + Vector3(-sin(angle), 0.8, cos(angle)), 0.07, 0.02)
	tool.generate_normals()
	return tool.commit()


func _add_limb(tool: SurfaceTool, start: Vector3, end: Vector3, radius: float, tip_radius: float) -> void:
	const SIDES := 5
	var axis := (end - start).normalized()
	var reference := Vector3.RIGHT if absf(axis.dot(Vector3.UP)) > 0.9 else Vector3.UP
	var side_a := axis.cross(reference).normalized()
	var side_b := axis.cross(side_a)
	for i in SIDES:
		var angle_a := TAU * i / SIDES
		var angle_b := TAU * (i + 1) / SIDES
		var direction_a := side_a * cos(angle_a) + side_b * sin(angle_a)
		var direction_b := side_a * cos(angle_b) + side_b * sin(angle_b)
		var low_a := start + direction_a * radius
		var low_b := start + direction_b * radius
		var high_a := end + direction_a * tip_radius
		var high_b := end + direction_b * tip_radius
		for vertex in [low_a, high_a, low_b, low_b, high_a, high_b]:
			tool.add_vertex(vertex)
