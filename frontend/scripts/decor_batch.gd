class_name DecorBatch
extends RefCounted
## Regroupe le décor fixe par matériau pour le web : dans chaque case, toutes les surfaces qui partagent un matériau,
## une même surcouche de mousse ou de poussière et une même taille sont fondues en un seul maillage : un appel de
## dessin au lieu d'un par modèle et par surface. Deux matériaux qui ne diffèrent que par leur instance (les modèles
## d'un même kit Kenney ont chacun le leur, sur la même texture) comptent pour un seul ; deux matériaux sans texture
## qui ne diffèrent que par leur couleur (kit Nature) aussi : la couleur passe dans les sommets.
## Les petits objets ne projettent plus d'ombre et s'effacent au loin ; les autres, et ce qui luit (flammes des
## lanternes), restent visibles comme avant. Godot mesure la portée depuis le centre du maillage fondu : elle est
## allongée de son rayon, pour qu'aucun petit objet ne disparaisse plus près que SMALL_RANGE.
## Chaque maillage fondu garde, en métadonnée « pieces », le nom et la boîte (monde) de chaque modèle qu'il contient :
## les tests les lisent pour vérifier les collisions modèle par modèle.
## Deux façons de regrouper, au même résultat : d'un bloc (merge), ou par étapes (new, puis step jusqu'à ce qu'il
## rende vrai) pour étaler le travail sur plusieurs images. Le Marais regroupe ainsi la crypte, cachée à l'arrivée,
## quelques millisecondes par image (marais.gd).
## Servent au Marais (décor, crypte, bêtes), à la Plaine (ruines, champ de bataille, archives) et, pour la signature
## des matériaux et leur peinture dans les sommets, au regroupement du hub (hub_batch.gd), qui garde ses propres règles
## (groupes réparables, ombres par case, modèles posés).

## Plus grande dimension (m) sous laquelle un objet est petit (cierge, fleur, urne, os) : sans ombre, effacé au-delà
## de SMALL_RANGE, dans une brume qui en cache déjà les trois quarts.
const SMALL := 1.0
const SMALL_RANGE := 40.0
const FADE_MARGIN := 6.0
## Attributs de sommet comparés entre surfaces : seules des surfaces de même format se fondent ensemble.
const FORMAT_MASK := 0xFF
## Échéance d'un regroupement d'un bloc (µs) : jamais atteinte.
const NO_DEADLINE := 9223372036854775807

## Signatures déjà calculées, par état d'un matériau : sa classe, son script, ses métadonnées et la valeur de chacune
## de ses propriétés (hors resource_*, et hors couleur s'il est peint). Deux matériaux dans le même état ont la même
## liste de propriétés stockées et les mêmes valeurs, donc la même signature : elle n'est calculée qu'une fois. Lire
## la liste des propriétés d'un matériau (get_property_list) coûtait l'essentiel du regroupement : 129 matériaux
## distincts dans le Marais pour 12 signatures, 227 dans le hub pour 11. Vidée quand le lieu se ferme (forget).
static var _by_state := {}
## Propriétés de chaque classe de matériau (ClassDB), lues une fois.
static var _class_properties := {}

var _root: Node3D
var _cell: float
var _shadows: bool
var _recursive: bool
var _fade: bool
var _skip: Array[String]
var _inverse: Transform3D
## Maillages à examiner, puis le prochain à examiner.
var _items: Array[Node] = []
var _scanned := false
var _next := 0
var _groups := {}
var _keys: Array = []
var _built := 0
var _merged: Array[MeshInstance3D] = []
## Signatures par instance de matériau, matériaux et surfaces peints (voir signature).
var _cache := {}
var _count := 0
var _done := false


## Prépare le regroupement des maillages fixes sous root, par cases de cell mètres. shadows : faux sous terre, où
## aucune lumière ne projette d'ombre. recursive : faux pour ne prendre que les enfants directs (les pièces mobiles
## d'une bête restent à part). fade : faux pour que rien ne s'efface au loin. skip : préfixes des noms de modèles
## laissés à part (animés par un autre script, comme les bannières de la Plaine). Rien n'est lu avant le premier step.
func _init(root: Node3D, cell: float, shadows: bool, recursive := true, fade := true, skip: Array[String] = []) -> void:
	_root = root
	_cell = cell
	_shadows = shadows
	_recursive = recursive
	_fade = fade
	_skip = skip


## Fond les maillages fixes sous root, d'un bloc (voir _init). Rend le nombre de maillages fondus.
static func merge(root: Node3D, cell: float, shadows: bool, recursive := true, fade := true,
		skip: Array[String] = []) -> int:
	var batch := DecorBatch.new(root, cell, shadows, recursive, fade, skip)
	batch.step(NO_DEADLINE)
	return batch.merged_count()


## Oublie les signatures gardées (à la fermeture du lieu).
static func forget() -> void:
	_by_state.clear()


## Avance le regroupement jusqu'à l'instant deadline (Time.get_ticks_usec), au moins d'un pas ; rend vrai quand il
## est fini. Les maillages sont examinés un à un, puis les lots bâtis un à un ; les modèles fondus disparaissent à
## la fin, d'un coup.
func step(deadline: int) -> bool:
	if _done:
		return true
	if not _scanned:
		_scanned = true
		_inverse = _root.global_transform.affine_inverse()
		_items = _root.find_children("*", "MeshInstance3D", _recursive, false)
	while _next < _items.size():
		_collect(_items[_next] as MeshInstance3D)
		_next += 1
		if Time.get_ticks_usec() >= deadline:
			return false
	if _keys.is_empty() and not _groups.is_empty() and _built == 0:
		_keys = _groups.keys()
	while _built < _keys.size():
		_build(_groups[_keys[_built]], _built + 1)
		_built += 1
		if Time.get_ticks_usec() >= deadline:
			return false
	# Les maillages fondus disparaissent (celui qui porte un maillage imbriqué, comme la cuve du cercueil sous son
	# couvercle, perd seulement son maillage), puis les nœuds de modèle restés vides.
	for item in _merged:
		if item.get_child_count() > 0:
			item.mesh = null
		else:
			item.free()
	_prune(_root)
	# Fini : rien n'est gardé (les lots tiennent leurs maillages et leurs matériaux).
	_count = _merged.size()
	_items.clear()
	_merged.clear()
	_groups.clear()
	_keys.clear()
	_cache.clear()
	_done = true
	return true


func is_done() -> bool:
	return _done


func merged_count() -> int:
	return _count


func _collect(item: MeshInstance3D) -> void:
	if not _mergeable(item, _root):
		return
	var model := _model_name(_root, item)
	if _skip.any(func(prefix: String) -> bool: return model.begins_with(prefix)):
		return
	var place := item.global_transform
	var box := place * item.mesh.get_aabb()
	var longest := maxf(box.size.x, maxf(box.size.y, box.size.z))
	var square := Vector2i(floori(box.get_center().x / _cell), floori(box.get_center().z / _cell))
	for surface in item.mesh.get_surface_count():
		var material: Material = item.material_override if item.material_override else item.mesh.surface_get_material(surface)
		var paint := paintable(material)
		var tint: Color = (material as BaseMaterial3D).albedo_color if paint else Color.WHITE
		# Ce qui luit se voit de loin dans la brume : jamais effacé.
		var small := _fade and longest < SMALL and not glows(material)
		var cast := _shadows and not small and item.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var format: int = (item.mesh as ArrayMesh).surface_get_format(surface) & FORMAT_MASK if item.mesh is ArrayMesh else 0
		if paint:
			format |= Mesh.ARRAY_FORMAT_COLOR
		var key := "%s_%d_%d_%s_%s_%d_%d" % [signature(material, _cache), instance_id(item.material_overlay), format, cast,
			small, square.x, square.y]
		if not _groups.has(key):
			_groups[key] = {"material": painted_material(material, _cache) if paint else material,
				"overlay": item.material_overlay, "cast": cast, "small": small, "paint": paint, "square": square,
				"parts": [], "pieces": [], "center": Vector3.ZERO}
		var group: Dictionary = _groups[key]
		group.parts.append([item.mesh, surface, _inverse * place, tint])
		group.pieces.append([model, box])
		group.center += box.get_center()
	_merged.append(item)


## Bâtit un lot : un maillage d'une surface, posé au centre de ses modèles.
func _build(group: Dictionary, index: int) -> void:
	var center: Vector3 = _inverse * (group.center / group.parts.size())
	var shift := Transform3D(Basis(), -center)
	var tool := SurfaceTool.new()
	for part: Array in group.parts:
		if group.paint:
			tool.append_from(painted_mesh(part[0], part[1], part[3], _cache), 0, shift * (part[2] as Transform3D))
		else:
			tool.append_from(part[0], part[1], shift * (part[2] as Transform3D))
	var mesh := tool.commit()
	mesh.surface_set_material(0, group.material)
	var instance := MeshInstance3D.new()
	instance.name = "Merged_%d_%d_%d" % [group.square.x, group.square.y, index]
	instance.mesh = mesh
	instance.material_overlay = group.overlay
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if group.cast else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if group.small:
		# Godot mesure la portée jusqu'au centre de la boîte du maillage : on l'allonge de son demi-diamètre.
		instance.visibility_range_end = SMALL_RANGE + mesh.get_aabb().size.length() * 0.5
		instance.visibility_range_end_margin = FADE_MARGIN
		instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	instance.set_meta(&"pieces", group.pieces)
	_root.add_child(instance)
	instance.position = center


static func _mergeable(item: MeshInstance3D, root: Node) -> bool:
	if not item.mesh or not item.visible or item.get_script() or item.skeleton != NodePath(""):
		return false
	# Ce que porte un nœud scripté (texte à lire, panneau, porte, objet d'énigme) reste à sa place : son script peut
	# le montrer, le cacher ou le déplacer.
	var parent := item.get_parent()
	while parent and parent != root:
		if parent.get_script():
			return false
		parent = parent.get_parent()
	# Réglages propres à un objet, qu'un maillage commun ne garderait pas (la portée, elle, est celle du lot).
	if item.transparency > 0.0 or item.visibility_range_begin > 0.0 or item.layers != 1:
		return false
	if item.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
		return false
	if item.mesh is ArrayMesh and (item.mesh as ArrayMesh).get_blend_shape_count() > 0:
		return false
	for surface in item.get_surface_override_material_count():
		if item.get_surface_override_material(surface):
			return false
	for surface in item.mesh.get_surface_count():
		if item.mesh is ArrayMesh and (item.mesh as ArrayMesh).surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES:
			return false
		var material := item.mesh.surface_get_material(surface)
		if item.material_override:
			material = item.material_override
		var base := material as BaseMaterial3D
		# Les halos tournés vers la caméra restent à part, comme ce qui est transparent : trié objet par objet.
		if base and (base.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED
				or base.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED):
			return false
	return true


## Ce qui luit (sans éclairage, ou émissif) : jamais effacé au loin.
static func glows(material: Material) -> bool:
	var base := material as BaseMaterial3D
	return base != null and (base.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED or base.emission_enabled)


## Matériau sans texture, dont la couleur peut passer dans les sommets.
static func paintable(material: Material) -> bool:
	return material is StandardMaterial3D and not (material as StandardMaterial3D).albedo_texture \
		and not (material as StandardMaterial3D).vertex_color_use_as_albedo


## Le matériau commun d'un maillage peint : le même, blanc, qui prend sa couleur dans les sommets (en sRGB, comme
## la couleur du matériau). Un par signature, gardé dans cache (celui de signature).
static func painted_material(material: Material, cache: Dictionary) -> Material:
	var key := "matériau_" + signature(material, cache)
	if not cache.has(key):
		var white := material.duplicate() as StandardMaterial3D
		white.albedo_color = Color.WHITE
		white.vertex_color_use_as_albedo = true
		white.vertex_color_is_srgb = true
		cache[key] = white
	return cache[key]


## Copie d'une surface dont chaque sommet porte la couleur du matériau, gardée dans cache.
static func painted_mesh(mesh: Mesh, surface: int, tint: Color, cache: Dictionary) -> Mesh:
	var key := "%d_%d_%s" % [mesh.get_instance_id(), surface, tint.to_html()]
	if not cache.has(key):
		var arrays := mesh.surface_get_arrays(surface)
		var colors := PackedColorArray()
		colors.resize((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
		colors.fill(tint)
		arrays[Mesh.ARRAY_COLOR] = colors
		var copy := ArrayMesh.new()
		copy.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		cache[key] = copy
	return cache[key]


## Clé d'un matériau : ses réglages et ses textures, sans son nom ni son instance (ni sa couleur, s'il est peint
## dans les sommets). Deux matériaux identiques partagent ainsi un seul maillage fondu. cache garde la signature de
## chaque instance déjà vue (un dictionnaire par regroupement) ; la mémoire par état (_by_state) est commune.
static func signature(material: Material, cache: Dictionary) -> String:
	if not material:
		return "0"
	var id := material.get_instance_id()
	if cache.has(id):
		return cache[id]
	var text := str(id)
	if material is StandardMaterial3D or material is ORMMaterial3D:
		if material.get_script():
			# Les variables d'un script ne sont pas dans l'état : décrit à chaque fois.
			text = _describe(material)
		else:
			var state := _state(material)
			if not _by_state.has(state):
				_by_state[state] = _describe(material)
			text = _by_state[state]
	cache[id] = text
	return text


## La signature elle-même : la liste des propriétés stockées du matériau (qui dépend de ses réglages : un matériau
## sans éclairage n'en a pas les propriétés), chacune avec sa valeur, les ressources par leur instance.
static func _describe(material: Material) -> String:
	var paint := paintable(material)
	var parts: PackedStringArray = [material.get_class(), "peint" if paint else "uni"]
	for property in material.get_property_list():
		var property_name: String = property.name
		if not (property.usage & PROPERTY_USAGE_STORAGE) or property_name.begins_with("resource_"):
			continue
		if paint and property_name == "albedo_color":
			continue
		var value: Variant = material.get(property_name)
		parts.append("%s=%s" % [property_name, str(instance_id(value)) if value is Resource else var_to_str(value)])
	return "|".join(parts).md5_text()


## État d'un matériau, de quoi dépend sa signature : sa classe, son script, ses métadonnées, puis la valeur de chaque
## propriété de sa classe (les ressources par leur instance), sauf son nom et, s'il est peint, sa couleur.
static func _state(material: Material) -> Array:
	var type := material.get_class()
	if not _class_properties.has(type):
		var names: Array[StringName] = []
		for property in ClassDB.class_get_property_list(type):
			var property_name: String = property.name
			if property.usage & (PROPERTY_USAGE_CATEGORY | PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SUBGROUP) \
					or property_name.is_empty() or property_name.begins_with("resource_"):
				continue
			names.append(StringName(property_name))
		_class_properties[type] = names
	var paint := paintable(material)
	var state := [type, paint, material.get_script()]
	for meta in material.get_meta_list():
		state.append(meta)
		state.append(material.get_meta(meta))
	for property_name: StringName in _class_properties[type]:
		if paint and property_name == &"albedo_color":
			state.append(null)
			continue
		var value: Variant = material.get(property_name)
		state.append(instance_id(value) if value is Resource else value)
	return state


## Instance d'une ressource, 0 pour aucune.
static func instance_id(resource: Resource) -> int:
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
