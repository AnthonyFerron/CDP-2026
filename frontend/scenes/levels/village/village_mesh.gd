class_name VillageMesh
extends RefCounted
## Petites bêtes et objets animés du Village taillés dans des formes simples (sphères, boîtes, cônes) : chaque partie
## qui bouge d'un bloc est fondue en un seul maillage, peint par sommets. Un seul appel de dessin par partie, au lieu
## d'un par forme : un corbeau posé passe de 10 appels à 2, une poule n'en coûte que 2.

## Matériau commun à toutes ces formes : la couleur vient des sommets.
static var _material: StandardMaterial3D


## Oublie le matériau commun ; les bêtes oublient leurs maillages partagés (release()) : appelé quand le Village se
## ferme, pour que rien ne reste en mémoire d'un lieu à l'autre.
static func release() -> void:
	_material = null
	VillageCrow.release()
	VillageHen.release()
	VillageCat.release()


static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.resource_name = "village_figure"
		_material.vertex_color_use_as_albedo = true
		_material.roughness = 0.75
	return _material


static func sphere(radius: float, segments := 10, rings := 5) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = segments
	mesh.rings = rings
	return mesh


static func box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


## Cône (rayon nul en haut), son axe selon y.
static func cone(radius: float, height: float, segments := 6) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	return mesh


## Place d'une forme : position, rotation en degrés (x, y, z) et étirement.
static func at(position: Vector3, degrees := Vector3.ZERO, stretch := Vector3.ONE) -> Transform3D:
	var basis := Basis.from_euler(degrees * PI / 180.0).scaled_local(stretch)
	return Transform3D(basis, position)


## Fond les formes en un seul maillage : chaque élément est [forme, Transform3D, Color].
static func merge(parts: Array) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for part: Array in parts:
		var arrays := (part[0] as PrimitiveMesh).get_mesh_arrays()
		var place: Transform3D = part[1]
		var color: Color = part[2]
		var normal_basis := place.basis.inverse().transposed()
		var base := vertices.size()
		var source: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var source_normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		for index in source.size():
			vertices.append(place * source[index])
			normals.append((normal_basis * source_normals[index]).normalized())
			colors.append(color)
		for index: int in arrays[Mesh.ARRAY_INDEX]:
			indices.append(base + index)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material())
	return mesh


## Nœud d'un maillage fondu, sans ombre, qui disparaît au-delà de hide_beyond mètres (0 : toujours dessiné). Sans
## fondu : la brume du soir couvre déjà ces petites formes à cette distance.
static func instance(mesh: Mesh, parent: Node3D, hide_beyond := 0.0) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.mesh = mesh
	item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	item.visibility_range_end = hide_beyond
	parent.add_child(item)
	return item
