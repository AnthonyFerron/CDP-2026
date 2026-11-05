class_name DesertMirages
extends Node3D
## Mirages du désert de Pythania, nés des vents brûlants :
## - au fond de l'oasis asséchée, de loin, une nappe d'eau scintille ; elle s'efface quand on approche ;
## - sur les crêtes qui ferment la zone, une caravane fantôme de marchands d'autrefois et de leurs chameaux
##   marche sans fin autour du désert ; on ne la rattrape jamais : elle se dissout dès qu'on s'en approche.
## Tout est construit au lancement, en formes simples, sans collision ni ombre.

const POOL_SHADER := preload("res://scenes/levels/desert/mirage_pool.gdshader")
const CARAVAN_SHADER := preload("res://scenes/levels/desert/mirage_caravan.gdshader")
## Nappe du mirage : au ras du bassin asséché (DesertTerrain.POND), un peu plus large que lui, sous les roseaux.
const POOL_HEIGHT := 0.03
const POOL_MARGIN := 1.04
## Caravane fantôme : rayon du cercle des crêtes (juste derrière leur rebord, à 74 m), vitesse de marche (m/s),
## écart entre deux membres, et taille : le mirage grandit ce qu'il montre.
const CARAVAN_RADIUS := 75.5
const CARAVAN_SPEED := 1.1
const CARAVAN_SPACING := 4.6
const CARAVAN_SCALE := 1.35
## Membres de la caravane, de la tête à la queue : 0 marcheur, 1 chameau monté, 2 chameau de bât.
const CARAVAN := [0, 1, 2, 2, 1, 2, 0]
## Hauteurs des hanches (chameau, marcheur), pour l'animation des pattes dans le shader.
const CAMEL_HIP := 1.25
const WALKER_HIP := 0.8

@export var terrain: DesertTerrain

var _members: Array[Node3D] = []
var _angle := 0.0


func _ready() -> void:
	if not terrain.is_node_ready():
		await terrain.ready
	_build_pool()
	_build_caravan()
	_angle = deg_to_rad(200.0)
	_place_caravan()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_angle = wrapf(_angle + CARAVAN_SPEED / CARAVAN_RADIUS * delta, 0.0, TAU)
	_place_caravan()


# --- Mirage de l'oasis ------------------------------------------------------------------------------------

func _build_pool() -> void:
	var pond := DesertTerrain.POND
	var plane := PlaneMesh.new()
	plane.size = Vector2(pond.z * 2.0 * POOL_MARGIN, pond.w * 2.0 * POOL_MARGIN)
	var material := ShaderMaterial.new()
	material.shader = POOL_SHADER
	plane.material = material
	var pool := MeshInstance3D.new()
	pool.name = "OasisMirage"
	pool.mesh = plane
	pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pool.position = Vector3(pond.x, POOL_HEIGHT, pond.y)
	add_child(pool)


# --- Caravane fantôme -------------------------------------------------------------------------------------

func _build_caravan() -> void:
	var material := ShaderMaterial.new()
	material.shader = CARAVAN_SHADER
	var meshes := [_walker_mesh(), _camel_mesh(true), _camel_mesh(false)]
	var caravan := Node3D.new()
	caravan.name = "GhostCaravan"
	add_child(caravan)
	for index in CARAVAN.size():
		var member := MeshInstance3D.new()
		member.mesh = meshes[CARAVAN[index]]
		member.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		member.scale = Vector3.ONE * CARAVAN_SCALE
		# Chaque silhouette tremble à son rythme ; les chameaux marchent plus lentement que les hommes.
		var own := material.duplicate() as ShaderMaterial
		own.set_shader_parameter("phase", index * 1.37)
		own.set_shader_parameter("stride", 2.6 if CARAVAN[index] > 0 else 3.4)
		own.set_shader_parameter("swing", 0.32 if CARAVAN[index] > 0 else 0.22)
		member.material_override = own
		caravan.add_child(member)
		_members.append(member)


func _place_caravan() -> void:
	for index in _members.size():
		var angle := _angle - index * CARAVAN_SPACING / CARAVAN_RADIUS
		var spot := Vector2(cos(angle), sin(angle)) * CARAVAN_RADIUS
		var member := _members[index]
		# Les pieds sur le plus haut du rebord, sur la ligne qui mène au centre : une bosse de la crête ne
		# cache pas la caravane à ceux qui la regardent depuis le désert.
		var ground := -INF
		for back: float in [0.0, 1.0, 2.0]:
			var probe := spot * (CARAVAN_RADIUS - back) / CARAVAN_RADIUS
			ground = maxf(ground, terrain.surface_height(probe.x, probe.y))
		member.position = Vector3(spot.x, ground - 0.05, spot.y)
		# Elle tourne dans le sens des angles croissants : la tangente du cercle.
		var tangent := Vector2(-sin(angle), cos(angle))
		member.rotation.y = atan2(tangent.x, tangent.y)


## Chameau, tourné vers +Z : quatre pattes (l'amble : les deux pattes d'un côté ensemble), le corps, la bosse,
## le cou et la tête ; monté, un marchand enturbanné sur la bosse ; de bât, des ballots de chaque côté.
func _camel_mesh(ridden: bool) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var still := Color(0.0, 0.0, 0.0)
	for side: float in [-1.0, 1.0]:
		for along: float in [-0.55, 0.6]:
			var leg := Color(0.0 if side < 0.0 else 0.5, 1.0, CAMEL_HIP / 2.0)
			_append(tool, _cylinder(0.06, 0.08, CAMEL_HIP + 0.15), Transform3D(Basis(), Vector3(side * 0.22, (CAMEL_HIP + 0.15) / 2.0, along)), leg)
	_append(tool, _sphere(), Transform3D(Basis().scaled(Vector3(0.36, 0.33, 0.78)), Vector3(0.0, 1.48, 0.0)), still)
	_append(tool, _sphere(), Transform3D(Basis().scaled(Vector3(0.27, 0.32, 0.36)), Vector3(0.0, 1.78, -0.05)), still)
	_append(tool, _cylinder(0.09, 0.13, 0.85), Transform3D(Basis(Vector3.RIGHT, 0.75), Vector3(0.0, 1.82, 0.92)), still)
	_append(tool, _box(Vector3(0.17, 0.18, 0.44)), Transform3D(Basis(Vector3.RIGHT, 0.2), Vector3(0.0, 2.15, 1.3)), still)
	_append(tool, _cylinder(0.02, 0.04, 0.5), Transform3D(Basis(Vector3.RIGHT, -0.35), Vector3(0.0, 1.3, -0.82)), still)
	if ridden:
		_append(tool, _cylinder(0.12, 0.26, 0.72), Transform3D(Basis(), Vector3(0.0, 2.3, -0.05)), still)
		_append(tool, _sphere(), Transform3D(Basis().scaled(Vector3(0.12, 0.13, 0.12)), Vector3(0.0, 2.8, -0.03)), still)
		_append(tool, _sphere(), Transform3D(Basis().scaled(Vector3(0.16, 0.08, 0.16)), Vector3(0.0, 2.9, -0.03)), still)
		# La lance du marchand, posée sur l'épaule.
		_append(tool, _cylinder(0.015, 0.015, 2.2), Transform3D(Basis(Vector3.RIGHT, -0.5), Vector3(0.22, 2.7, 0.1)), still)
	else:
		for side: float in [-1.0, 1.0]:
			_append(tool, _box(Vector3(0.3, 0.42, 0.55)), Transform3D(Basis(), Vector3(side * 0.44, 1.42, 0.05)), still)
		_append(tool, _box(Vector3(0.5, 0.28, 0.4)), Transform3D(Basis(), Vector3(0.0, 2.08, -0.05)), still)
	tool.generate_normals()
	return tool.commit()


## Marcheur en robe, tourné vers +Z, son bâton à la main.
func _walker_mesh() -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var still := Color(0.0, 0.0, 0.0)
	for side: float in [-1.0, 1.0]:
		var leg := Color(0.0 if side < 0.0 else 0.5, 1.0, WALKER_HIP / 2.0)
		_append(tool, _cylinder(0.05, 0.06, WALKER_HIP), Transform3D(Basis(), Vector3(side * 0.1, WALKER_HIP / 2.0, 0.0)), leg)
	_append(tool, _cylinder(0.15, 0.3, 1.0), Transform3D(Basis(), Vector3(0.0, 1.05, 0.0)), still)
	_append(tool, _sphere(), Transform3D(Basis().scaled(Vector3(0.12, 0.13, 0.12)), Vector3(0.0, 1.68, 0.0)), still)
	_append(tool, _sphere(), Transform3D(Basis().scaled(Vector3(0.15, 0.07, 0.15)), Vector3(0.0, 1.78, 0.0)), still)
	_append(tool, _cylinder(0.02, 0.02, 1.85), Transform3D(Basis(Vector3.RIGHT, 0.12), Vector3(0.32, 0.95, 0.15)), still)
	tool.generate_normals()
	return tool.commit()


## Ajoute les triangles d'une forme simple, placée par xform, chaque sommet marqué de la couleur donnée.
func _append(tool: SurfaceTool, mesh: PrimitiveMesh, xform: Transform3D, color: Color) -> void:
	var arrays := mesh.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for index in indices:
		tool.set_color(color)
		tool.add_vertex(xform * vertices[index])


func _cylinder(top: float, bottom: float, height: float) -> CylinderMesh:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = top
	cylinder.bottom_radius = bottom
	cylinder.height = height
	cylinder.radial_segments = 6
	cylinder.rings = 1
	return cylinder


func _sphere() -> SphereMesh:
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 8
	sphere.rings = 5
	return sphere


func _box(size: Vector3) -> BoxMesh:
	var box := BoxMesh.new()
	box.size = size
	return box
