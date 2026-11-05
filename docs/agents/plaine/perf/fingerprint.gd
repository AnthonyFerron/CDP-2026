extends "res://tests/scenes/common_test.gd"
## Empreinte exacte de la Plaine chargée, pour prouver qu'une optimisation du chargement ne change rien :
## - chaque forme de collision (corps, transformation monde exacte, données exactes de la forme) ;
## - chaque objet dessiné (classe, transformation monde exacte, réglages d'ombre et de portée, matériaux décrits,
##   maillage : tableaux de chaque surface ; MultiMesh : tampon des instances).
## Les lignes sont triées (l'ordre des enfants ne compte pas) et écrites dans <dossier>/collisions.txt et
## <dossier>/dessin.txt. Usage : -- <dossier> --api=http://127.0.0.1:9/api/v1

var _auto := RegEx.create_from_string("@[A-Za-z0-9_]+@[0-9]+")


func _initialize() -> void:
	_run.call_deferred()


func _hash_bytes(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_MD5)
	context.update(bytes)
	return context.finish().hex_encode()


func _hash(value: Variant) -> String:
	return _hash_bytes(var_to_bytes(value))


func _path(node: Node) -> String:
	return _auto.sub(String(level.get_path_to(node)), "@", true)


## Description d'une ressource : son chemin si elle vient d'un fichier, sinon sa classe et ses réglages.
func _describe(resource: Resource, depth := 0) -> String:
	if not resource:
		return "-"
	if not resource.resource_path.is_empty() and not resource.resource_path.contains("::"):
		return resource.resource_path
	if depth > 3:
		return resource.get_class()
	var parts: PackedStringArray = [resource.get_class()]
	for property in resource.get_property_list():
		var name: String = property.name
		if not (property.usage & PROPERTY_USAGE_STORAGE) or name.begins_with("resource_") or name == "script":
			continue
		var value: Variant = resource.get(name)
		if value is Resource:
			parts.append("%s=%s" % [name, _describe(value, depth + 1)])
		elif value is Object:
			continue
		else:
			parts.append("%s=%s" % [name, _hash(value) if typeof(value) >= TYPE_PACKED_BYTE_ARRAY else var_to_str(value)])
	return "{" + ",".join(parts) + "}"


func _mesh(mesh: Mesh) -> String:
	if not mesh:
		return "-"
	if not mesh is ArrayMesh:
		return _describe(mesh)
	var parts: PackedStringArray = []
	for surface in mesh.get_surface_count():
		parts.append("%s/%s" % [_hash(mesh.surface_get_arrays(surface)), _describe(mesh.surface_get_material(surface))])
	return "[" + ";".join(parts) + "]"


func _run() -> void:
	var out := ""
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--"):
			out = argument
	DirAccess.make_dir_recursive_absolute(out)
	await start_level("res://scenes/levels/plaine/plaine.tscn")
	var skip: Array[Node] = [level.get_node("Player"), level.get_node("Hud")]
	var collisions: PackedStringArray = []
	for node in level.find_children("*", "CollisionShape3D", true, false):
		if skip.any(func(s: Node) -> bool: return s.is_ancestor_of(node)):
			continue
		var shape := node as CollisionShape3D
		var data := "-"
		if shape.shape is ConcavePolygonShape3D:
			data = "concave " + _hash((shape.shape as ConcavePolygonShape3D).get_faces())
		elif shape.shape is ConvexPolygonShape3D:
			data = "convexe " + _hash((shape.shape as ConvexPolygonShape3D).points)
		else:
			data = _describe(shape.shape)
		var body := shape.get_parent() as CollisionObject3D
		var flags := "%d/%d/%s" % [body.collision_layer, body.collision_mask, shape.disabled] if body else "?"
		collisions.append("%s | %s | %s | %s" % [_path(shape.get_parent()), var_to_str(shape.global_transform), flags, data])
	collisions.sort()
	var drawn: PackedStringArray = []
	for node in level.find_children("*", "GeometryInstance3D", true, false):
		if skip.any(func(s: Node) -> bool: return s.is_ancestor_of(node)):
			continue
		var item := node as GeometryInstance3D
		# Bannières et corbeaux bougent avec le temps : leur place n'entre pas dans l'empreinte.
		var where := var_to_str(item.global_transform)
		if _path(item).contains("/flag_") or level.get_node("Exterior/Life").is_ancestor_of(item):
			where = "anime"
		var line := "%s | %s | %s | ombre %d | portée %s %s %s %d | vis %s | over %s | overlay %s" % [
			item.get_class(), _path(item.get_parent()), where, item.cast_shadow,
			item.visibility_range_begin, item.visibility_range_end, item.visibility_range_end_margin,
			item.visibility_range_fade_mode, item.is_visible_in_tree(), _describe(item.material_override),
			_describe(item.material_overlay)]
		if item is MeshInstance3D:
			line += " | " + _mesh((item as MeshInstance3D).mesh)
		elif item is MultiMeshInstance3D:
			var multimesh := (item as MultiMeshInstance3D).multimesh
			line += " | mm %d %s %s" % [multimesh.instance_count, _hash(multimesh.buffer), _mesh(multimesh.mesh)]
		elif item is CPUParticles3D:
			line += " | particules " + _mesh((item as CPUParticles3D).mesh)
		drawn.append(line)
	drawn.sort()
	for spec: Array in [["collisions", collisions], ["dessin", drawn]]:
		var lines: PackedStringArray = spec[1]
		var file := FileAccess.open(out + "/%s.txt" % spec[0], FileAccess.WRITE)
		file.store_string("\n".join(lines))
		file.close()
		print("EMPREINTE %s : %d lignes, %s" % [spec[0], lines.size(), "\n".join(lines).md5_text()])
	finish()
