class_name MaraisBatch
extends RefCounted
## Regroupe le décor fixe par matériau pour le web : dans chaque case, toutes les surfaces qui partagent un matériau
## (les modèles d'un même kit Kenney partagent leur texture), une même surcouche de mousse ou de poussière et une même
## taille sont fondues en un seul maillage : un appel de dessin au lieu d'un par modèle et par surface. Les petits
## objets ne projettent plus d'ombre et s'effacent au loin ; les moyens un peu plus loin ; les grands restent visibles.
## Chaque maillage fondu garde, en métadonnée « pieces », le nom et la boîte (monde) de chaque modèle qu'il contient :
## les tests les lisent pour vérifier les collisions modèle par modèle.

## Plus grande dimension (m) sous laquelle un objet est petit : sans ombre, effacé au-delà de SMALL_RANGE.
const SMALL := 1.0
const SMALL_RANGE := 40.0
## Objets moyens (bancs, tonneaux, tombes) : effacés au-delà de MEDIUM_RANGE.
const MEDIUM := 2.5
const MEDIUM_RANGE := 80.0
const FADE_MARGIN := 6.0
## Attributs de sommet comparés entre surfaces : seules des surfaces de même format se fondent ensemble.
const FORMAT_MASK := 0xFF


## Fond les maillages fixes sous root, par cases de cell mètres. shadows : faux sous terre, où aucune lumière ne
## projette d'ombre. Rend le nombre de maillages fondus.
static func merge(root: Node3D, cell: float, shadows: bool) -> int:
	var groups := {}
	var merged: Array[MeshInstance3D] = []
	var inverse := root.global_transform.affine_inverse()
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var item := node as MeshInstance3D
		if not _mergeable(item):
			continue
		var place := item.global_transform
		var box := place * item.mesh.get_aabb()
		var longest := maxf(box.size.x, maxf(box.size.y, box.size.z))
		var size := 0 if longest < SMALL else (1 if longest < MEDIUM else 2)
		var square := Vector2i(floori(box.get_center().x / cell), floori(box.get_center().z / cell))
		var cast := shadows and size > 0 and item.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var model := _model_name(root, item)
		for surface in item.mesh.get_surface_count():
			var material: Material = item.material_override if item.material_override else item.mesh.surface_get_material(surface)
			var format: int = (item.mesh as ArrayMesh).surface_get_format(surface) & FORMAT_MASK if item.mesh is ArrayMesh else 0
			var key := "%d_%d_%d_%s_%d_%d_%d" % [_id(material), _id(item.material_overlay), format, cast, size, square.x, square.y]
			if not groups.has(key):
				groups[key] = {"material": material, "overlay": item.material_overlay, "cast": cast, "size": size,
					"square": square, "parts": [], "pieces": [], "center": Vector3.ZERO}
			var group: Dictionary = groups[key]
			group.parts.append([item.mesh, surface, inverse * place])
			group.pieces.append([model, box])
			group.center += box.get_center()
		merged.append(item)
	for key: String in groups:
		var group: Dictionary = groups[key]
		# Le maillage fondu se pose au centre de ses modèles : la distance d'effacement se mesure depuis là.
		var center: Vector3 = inverse * (group.center / group.parts.size())
		var shift := Transform3D(Basis(), -center)
		var tool := SurfaceTool.new()
		for part: Array in group.parts:
			tool.append_from(part[0], part[1], shift * (part[2] as Transform3D))
		var mesh := tool.commit()
		mesh.surface_set_material(0, group.material)
		var instance := MeshInstance3D.new()
		instance.name = "Merged_%d_%d" % [group.square.x, group.square.y]
		instance.mesh = mesh
		instance.material_overlay = group.overlay
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if group.cast else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if group.size < 2:
			instance.visibility_range_end = SMALL_RANGE if group.size == 0 else MEDIUM_RANGE
			instance.visibility_range_end_margin = FADE_MARGIN
			instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		instance.set_meta(&"pieces", group.pieces)
		root.add_child(instance)
		instance.position = center
	# Les maillages fondus disparaissent (celui qui porte un maillage imbriqué, comme la cuve du cercueil sous son
	# couvercle, perd seulement son maillage), puis les nœuds de modèle restés vides.
	for item in merged:
		if item.get_child_count() > 0:
			item.mesh = null
		else:
			item.free()
	_prune(root)
	return merged.size()


static func _mergeable(item: MeshInstance3D) -> bool:
	if not item.mesh or not item.visible or item.get_script() or item.skeleton != NodePath(""):
		return false
	if item.mesh is ArrayMesh and (item.mesh as ArrayMesh).get_blend_shape_count() > 0:
		return false
	for surface in item.get_surface_override_material_count():
		if item.get_surface_override_material(surface):
			return false
	# Les halos tournés vers la caméra restent à part.
	for surface in item.mesh.get_surface_count():
		var material := item.mesh.surface_get_material(surface) as BaseMaterial3D
		if material and material.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED:
			return false
	return true


static func _id(resource: Resource) -> int:
	return resource.get_instance_id() if resource else 0


## Nom du modèle d'un maillage : l'instance de modèle (.glb) qui le porte, sans le numéro final
## (« dust_coffin_208 » → « dust_coffin »).
static func _model_name(root: Node, item: Node) -> String:
	var top := item
	while top != root and top.scene_file_path.is_empty() and top.get_parent():
		top = top.get_parent()
	if top == root:
		top = item
	var name := String(top.name)
	var cut := name.rfind("_")
	if cut > 0 and name.substr(cut + 1).is_valid_int():
		name = name.substr(0, cut)
	return name


## Retire les nœuds 3D simples restés sans enfant (modèles dont tous les maillages ont été fondus).
static func _prune(node: Node) -> void:
	for child in node.get_children():
		_prune(child)
		if child.get_child_count() > 0 or child.get_script():
			continue
		if child.get_class() == "Node3D" or (child is MeshInstance3D and not (child as MeshInstance3D).mesh):
			child.free()
