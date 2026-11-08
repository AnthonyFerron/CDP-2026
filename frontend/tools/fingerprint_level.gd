extends SceneTree
## Empreinte d'un lieu chargé comme en jeu : ce qui se dessine (maillages, MultiMesh, particules, textes, lumières)
## et ce qui arrête le joueur (formes de collision), avec leur place dans le monde. Sert à vérifier qu'un
## changement du chargement (calcul d'avance, travail étalé) ne change ni le rendu ni les collisions :
##   cd frontend && godot --headless --fixed-fps 60 --path . --script res://tools/fingerprint_level.gd -- <lieu> <fichier> [--images N]
## <fichier> reçoit une ligne par objet, triée : deux empreintes se comparent avec diff. Les chemins des nœuds n'y
## sont pas (un calcul d'avance peut ranger autrement), seulement leur genre, leur place et leur contenu.
## Le hub regroupe son décor au fil des images : l'outil attend qu'il ait fini.

const LEVELS := {
	"hub": "res://scenes/levels/hub/hub.tscn",
	"plaine": "res://scenes/levels/plaine/plaine.tscn",
	"desert": "res://scenes/levels/desert/desert.tscn",
	"marais": "res://scenes/levels/marais/marais.tscn",
	"village": "res://scenes/levels/village/village.tscn",
}

var _mesh_hashes := {}
var _material_hashes := {}
var _shape_hashes := {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var place := args[0]
	var out := args[1]
	var frames := 20
	var index := args.find("--images")
	if index >= 0 and index + 1 < args.size():
		frames = int(args[index + 1])
	var state: Node = root.get_node("GameState")
	state.reset()
	state.intro_done = true
	await process_frame
	# Les bêtes tirent leur départ au hasard : même tirage à chaque passage.
	seed(5814)
	var level: Node = (load(LEVELS[place]) as PackedScene).instantiate()
	root.add_child(level)
	current_scene = level
	for frame in frames:
		await process_frame
	# Le regroupement du décor du hub se fait par tranches, au fil des images.
	var batches := level.find_children("*", "Node3D", true, false).filter(
		func(node: Node) -> bool: return node.has_method("is_done"))
	for frame in 3000:
		if batches.all(func(node: Node) -> bool: return node.is_done()):
			break
		await process_frame
	for frame in 3:
		await process_frame

	var lines: Array[String] = []
	var counts := {}
	_walk(level, lines, counts)
	lines.sort()
	var file := FileAccess.open(out, FileAccess.WRITE)
	for line in lines:
		file.store_line(line)
	file.close()
	var kinds := counts.keys()
	kinds.sort()
	var summary: Array[String] = []
	for kind: String in kinds:
		summary.append("%s=%d" % [kind, counts[kind]])
	var whole := "\n".join(lines).md5_text()
	print("EMPREINTE %s %s lignes=%d %s" % [place, whole, lines.size(), " ".join(summary)])
	for category in ["DESSIN", "COLLISION", "LUMIERE", "AUTRE"]:
		var part := lines.filter(func(line: String) -> bool: return line.begins_with(category))
		print("  %s : %d lignes, %s" % [category, part.size(), "\n".join(part).md5_text()])
	state.reset()
	quit()


## Parcourt tout l'arbre, enfants internes compris (VillageInstances y range ses MultiMesh).
func _walk(node: Node, lines: Array[String], counts: Dictionary) -> void:
	var line := _describe(node)
	if not line.is_empty():
		lines.append(line)
		var kind := line.get_slice(" ", 0) + ":" + node.get_class()
		counts[kind] = counts.get(kind, 0) + 1
	for child_index in node.get_child_count(true):
		_walk(node.get_child(child_index, true), lines, counts)


func _describe(node: Node) -> String:
	if node is CollisionShape3D:
		var holder := node as CollisionShape3D
		var body := holder.get_parent() as CollisionObject3D
		var owner_text := "%s layer=%d mask=%d" % [body.get_class(), body.collision_layer, body.collision_mask] if body else "sans-corps"
		return "COLLISION %s %s disabled=%s %s" % [owner_text, _xform(holder.global_transform), holder.disabled,
			_shape(holder.shape)]
	if node is CollisionPolygon3D:
		var polygon := node as CollisionPolygon3D
		return "COLLISION polygone %s depth=%s %s" % [_xform(polygon.global_transform), polygon.depth,
			_hash(polygon.polygon)]
	if node is Light3D:
		return "LUMIERE %s %s visible=%s %s" % [node.get_class(), _xform(node.global_transform), node.is_visible_in_tree(),
			_properties(node)]
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var materials: Array[String] = []
		if instance.mesh:
			for surface in instance.mesh.get_surface_count():
				materials.append(_material(instance.get_active_material(surface)))
		return "DESSIN MeshInstance3D %s visible=%s %s mesh=%s mat=%s" % [_xform(instance.global_transform),
			instance.is_visible_in_tree(), _geometry(instance), _mesh(instance.mesh), ",".join(materials)]
	if node is MultiMeshInstance3D:
		var instance := node as MultiMeshInstance3D
		var multimesh := instance.multimesh
		var text := "vide"
		if multimesh:
			var materials: Array[String] = []
			if multimesh.mesh:
				for surface in multimesh.mesh.get_surface_count():
					materials.append(_material(instance.material_override if instance.material_override
						else multimesh.mesh.surface_get_material(surface)))
			text = "n=%d visibles=%d mesh=%s buffer=%s mat=%s" % [multimesh.instance_count,
				multimesh.visible_instance_count, _mesh(multimesh.mesh), _hash(multimesh.buffer),
				",".join(materials)]
		return "DESSIN MultiMeshInstance3D %s visible=%s %s %s" % [_xform(instance.global_transform),
			instance.is_visible_in_tree(), _geometry(instance), text]
	if node is GeometryInstance3D:
		return "DESSIN %s %s visible=%s %s %s" % [node.get_class(), _xform(node.global_transform),
			node.is_visible_in_tree(), _geometry(node), _properties(node)]
	if node is Area3D or node is AudioStreamPlayer3D or node is Camera3D or node is Marker3D:
		return "AUTRE %s %s" % [node.get_class(), _xform(node.global_transform)]
	return ""


## Empreinte MD5 d'une valeur, octet pour octet.
func _hash(value: Variant) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_MD5)
	context.update(var_to_bytes(value))
	return context.finish().hex_encode()


func _xform(transform: Transform3D) -> String:
	var values: Array[String] = []
	for vector: Vector3 in [transform.basis.x, transform.basis.y, transform.basis.z, transform.origin]:
		for axis in 3:
			values.append("%.4f" % vector[axis])
	return "[" + " ".join(values) + "]"


func _geometry(instance: GeometryInstance3D) -> String:
	return "ombre=%d portee=%s/%s/%s/%s fondu=%d calques=%d override=%s" % [instance.cast_shadow,
		instance.visibility_range_begin, instance.visibility_range_end, instance.visibility_range_begin_margin,
		instance.visibility_range_end_margin, instance.visibility_range_fade_mode, instance.layers,
		_material(instance.material_override)]


func _mesh(mesh: Mesh) -> String:
	if not mesh:
		return "aucun"
	if _mesh_hashes.has(mesh):
		return _mesh_hashes[mesh]
	var parts: Array[String] = [mesh.get_class()]
	for surface in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var primitive: int = (mesh as ArrayMesh).surface_get_primitive_type(surface) if mesh is ArrayMesh else Mesh.PRIMITIVE_TRIANGLES
		parts.append("%d:%s" % [primitive, _hash(arrays)])
	var text := ("|".join(parts)).md5_text().substr(0, 12) + "/%d" % mesh.get_surface_count()
	_mesh_hashes[mesh] = text
	return text


func _material(material: Material) -> String:
	if not material:
		return "-"
	if _material_hashes.has(material):
		return _material_hashes[material]
	var text := material.get_class() + ":" + _properties(material).md5_text().substr(0, 12)
	if material.next_pass:
		text += "+" + _material(material.next_pass)
	_material_hashes[material] = text
	return text


func _shape(shape: Shape3D) -> String:
	if not shape:
		return "aucune"
	if _shape_hashes.has(shape):
		return _shape_hashes[shape]
	var data: Variant
	if shape is ConcavePolygonShape3D:
		data = [shape.get_faces(), shape.backface_collision]
	elif shape is ConvexPolygonShape3D:
		data = shape.points
	else:
		data = _properties(shape)
	var text := "%s:%s" % [shape.get_class(), _hash(data).substr(0, 12)]
	_shape_hashes[shape] = text
	return text


## Propriétés enregistrées d'un objet, ressources comprises (par leur fichier ou leur contenu).
func _properties(object: Object) -> String:
	var parts: Array[String] = []
	for property in object.get_property_list():
		if not property.usage & PROPERTY_USAGE_STORAGE or property.name in ["script", "resource_name",
				"resource_local_to_scene", "resource_path", "resource_scene_unique_id"]:
			continue
		var value: Variant = object.get(property.name)
		if value is Resource:
			var resource := value as Resource
			if not resource.resource_path.is_empty() and not resource.resource_path.contains("::"):
				value = resource.resource_path
			elif resource is Texture2D:
				value = "%s %s" % [resource.get_class(), (resource as Texture2D).get_size()]
			elif resource is Material:
				value = _material(resource)
			elif resource is Mesh:
				value = _mesh(resource)
			else:
				value = resource.get_class()
		parts.append("%s=%s" % [property.name, var_to_str(value)])
	return ";".join(parts)
