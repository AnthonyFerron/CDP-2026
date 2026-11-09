extends Node3D
## Décor fixe du hub (hub_props.tscn), regroupé au chargement pour le web. Dans chaque groupe (le décor fixe, et pour
## chaque élément réparable sa ruine et sa reconstruction) et dans chaque case de CELL mètres, toutes les surfaces qui
## partagent un matériau sont fondues en un seul maillage : un appel de dessin au lieu d'un par modèle et par surface.
## Deux matériaux qui ne diffèrent que par leur instance (chaque modèle d'un kit Kenney a le sien, sur la même
## texture) comptent pour un ; deux matériaux sans texture qui ne diffèrent que par leur couleur (kit Nature) aussi :
## la couleur passe dans les sommets. Signature des matériaux et peinture dans les sommets : l'outil commun
## (DecorBatch, scripts/decor_batch.gd), dont la mémoire par état décrit chaque état de matériau une seule fois (227
## matériaux distincts dans le décor du hub, pour 11 signatures). Elle est oubliée quand le hub se ferme.
## Les groupes restent séparés : les réparations continuent de montrer, cacher ou faire monter chacun d'un bloc.
## Les collisions ne bougent pas : elles sont dans les nœuds Collision de chaque groupe, que le regroupement ne touche pas.
## Chaque maillage fondu garde, en métadonnée « pieces », le nom et la boîte (monde) de chaque modèle qu'il contient.
## Ombres : le soleil redessine chaque objet qui projette une ombre dans chacune de ses 4 tranches, et c'est là que
## partait l'essentiel des appels de dessin. La profondeur d'une ombre ne dépend pas du matériau (opaque) : tous les
## lots d'une case projettent leur ombre d'un seul maillage, dessiné seulement dans les ombres (SHADOWS_ONLY). Les lots
## visibles n'en projettent plus. L'ombre reste exactement la même : mêmes triangles, même face cachée.
## Chargement : rien ne se regroupe avant la première image (le rendu est le même, en plus d'appels de dessin) ; les
## groupes se regroupent ensuite par tranches de BUDGET_MSEC par image, ceux qu'on voit d'abord, et un groupe caché
## qui apparaît (une réparation, la sortie du bunker) se regroupe aussitôt. Ne sont jamais fondus : les nœuds à script (panneaux, lampes, textes, portes, roue du moulin), les
## collisions, les arbres, et tout modèle qui contient autre chose que des maillages.

const GROUPS: Array[StringName] = [&"Fixed", &"Ruins", &"Rebuilt"]
## Côté des cases (m) : un lot n'est dessiné que si sa case est dans le champ de la caméra.
const CELL := 32.0
## Les petits objets (vaisselle, livres, chandelles, outils : moins de SMALL mètres) ne se dessinent plus au-delà de
## SMALL_RANGE mètres, en fondu : à cette distance ils ne font que quelques pixels, et chaque intérieur en compte des
## dizaines. Godot mesure la portée jusqu'au centre du lot : elle est allongée de son demi-diamètre, pour qu'aucun petit
## objet ne disparaisse plus près que SMALL_RANGE. Ils gardent leur ombre, et ce qui luit n'est jamais effacé.
const SMALL := 1.0
const SMALL_RANGE := 40.0
const FADE_MARGIN := 6.0
## Temps de regroupement par image (ms), après le chargement : au moins un groupe par image.
const BUDGET_MSEC := 8
## Attributs de sommet comparés entre surfaces : seules des surfaces de même format se fondent ensemble.
const FORMAT_MASK := 0xFF

## Signatures par instance de matériau, matériaux et surfaces peints (DecorBatch.signature), d'un groupe à l'autre.
var _cache := {}
var _shadow_materials := {}
## Groupes pas encore regroupés, pris par la fin.
var _pending: Array[Node3D] = []
## Temps passé à regrouper, en millisecondes (pour les mesures).
var batch_msec := 0.0


func _ready() -> void:
	for group in find_children("*", "Node3D", true, false):
		if StringName(group.name) in GROUPS:
			_pending.append(group)
	set_process(false)
	# Le hub montre les ruines ou les reconstructions dans son propre _ready, qui passe après celui-ci.
	_batch_shown.call_deferred()


func _exit_tree() -> void:
	DecorBatch.forget()


## Rien n'est regroupé pendant le chargement : à partir de la première image, chaque image regroupe des groupes
## pendant au plus BUDGET_MSEC, ceux qu'on voit d'abord. Un groupe caché qui apparaît avant son tour est regroupé
## aussitôt.
func _batch_shown() -> void:
	var shown: Array[Node3D] = []
	var hidden: Array[Node3D] = []
	for group in _pending:
		if group.is_visible_in_tree():
			shown.append(group)
		else:
			hidden.append(group)
			group.visibility_changed.connect(_batch_now.bind(group), CONNECT_ONE_SHOT)
	# _process prend les groupes par la fin : les groupes visibles passent en premier.
	_pending.assign(hidden + shown)
	set_process(not _pending.is_empty())


func _batch_now(group: Node3D) -> void:
	if group in _pending:
		_pending.erase(group)
		_batch(group)


func _process(_delta: float) -> void:
	var start := Time.get_ticks_msec()
	while not _pending.is_empty():
		var group: Node3D = _pending.pop_back()
		var callback := _batch_now.bind(group)
		if group.visibility_changed.is_connected(callback):
			group.visibility_changed.disconnect(callback)
		_batch(group)
		if Time.get_ticks_msec() - start >= BUDGET_MSEC:
			return
	set_process(false)


## Tous les groupes regroupés (pour les tests et les mesures).
func is_done() -> bool:
	return _pending.is_empty()


func _batch(group: Node3D) -> void:
	var start := Time.get_ticks_usec()
	_merge(group)
	batch_msec += (Time.get_ticks_usec() - start) / 1000.0


func _merge(group: Node3D) -> void:
	var lots := {}
	# Maillages qu'un lot commun ne saurait rendre à l'identique (transparents, tournés vers la caméra) : un MultiMesh
	# par maillage, comme avant.
	var apart := {}
	var batched: Array[Node] = []
	var inverse := group.global_transform.affine_inverse()
	for child in group.get_children():
		# Seuls les modèles posés tels quels : les nœuds à script (la roue du moulin, les textes, les lampes) gardent
		# leurs enfants.
		if not child is Node3D or child.scene_file_path.is_empty():
			continue
		# Les arbres restent des nœuds : peu nombreux, ils gardent chacun leur visibilité (le contrôle des collisions
		# des arbres les retrouve ainsi par leur scène).
		if child.scene_file_path.get_file().contains("tree"):
			continue
		# Seulement des modèles inertes : ni script, ni animation, ni lumière, ni particules, ni collision dedans.
		if not _inert(child):
			continue
		var model := _model_name(child)
		for item: MeshInstance3D in child.find_children("*", "MeshInstance3D", true, false):
			# Visibilité dans le modèle seulement : un groupe caché (ruine réparée) se regroupe aussi.
			if not item.mesh or not _shown_in(item, child):
				continue
			var place := inverse * item.global_transform
			if not _mergeable(item):
				if not apart.has(item.mesh):
					apart[item.mesh] = {"cast": item.cast_shadow, "transforms": []}
				apart[item.mesh].transforms.append(place)
				continue
			var box := place * item.mesh.get_aabb()
			var longest := maxf(box.size.x, maxf(box.size.y, box.size.z))
			var square := Vector2i(floori(box.get_center().x / CELL), floori(box.get_center().z / CELL))
			for surface in item.mesh.get_surface_count():
				var material: Material = item.material_override if item.material_override else item.mesh.surface_get_material(surface)
				var paint := DecorBatch.paintable(material)
				var tint: Color = (material as BaseMaterial3D).albedo_color if paint else Color.WHITE
				var small := longest < SMALL and not DecorBatch.glows(material)
				var format: int = (item.mesh as ArrayMesh).surface_get_format(surface) & FORMAT_MASK if item.mesh is ArrayMesh else 0
				if paint:
					format |= Mesh.ARRAY_FORMAT_COLOR
				var key := "%s_%d_%d_%d_%s_%d_%d" % [DecorBatch.signature(material, _cache),
					DecorBatch.instance_id(item.material_overlay), format, item.cast_shadow, small, square.x, square.y]
				if not lots.has(key):
					lots[key] = {"material": DecorBatch.painted_material(material, _cache) if paint else material,
						"overlay": item.material_overlay, "cast": item.cast_shadow, "small": small, "paint": paint,
						"square": square, "parts": [], "pieces": [], "center": Vector3.ZERO}
				var lot: Dictionary = lots[key]
				lot.parts.append([item.mesh, surface, place, tint])
				lot.pieces.append([model, group.global_transform * box])
				lot.center += box.get_center()
		batched.append(child)
	var index := 0
	var shadows := {}
	for key: String in lots:
		index += 1
		var instance := _add_lot(group, lots[key], index)
		var cull := _shadow_cull(instance.mesh.surface_get_material(0))
		if instance.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_ON or cull < 0:
			continue
		# L'ombre du lot passe dans celle de sa case (les petits objets à part : elle s'efface avec eux).
		var shadow_key := "%d_%d_%s_%d" % [lots[key].square.x, lots[key].square.y, lots[key].small, cull]
		if not shadows.has(shadow_key):
			shadows[shadow_key] = {"cull": cull, "small": lots[key].small, "square": lots[key].square, "parts": []}
		shadows[shadow_key].parts.append(instance)
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for key: String in shadows:
		_add_shadow(group, shadows[key])
	for mesh: Mesh in apart:
		_add_multimesh(group, mesh, apart[mesh].transforms, apart[mesh].cast)
	for child in batched:
		group.remove_child(child)
		child.queue_free()


## Planches, cadres, clous et poteaux d'un panneau (SignBoard) fondus en un seul maillage, leur couleur dans les
## sommets : un appel de dessin au lieu de 8 à 12. Le panneau garde son texte, sa collision et ses morceaux (cachés),
## qu'il refait lui-même si on le change.
static func merge_sign(sign: Node3D) -> void:
	var boxes: Array[MeshInstance3D] = []
	for child in sign.get_children(true):
		if child is MeshInstance3D and child.mesh is BoxMesh and child.visible and not child.has_meta(&"merged"):
			boxes.append(child)
	if boxes.size() < 2:
		return
	var base := (boxes[0].mesh as BoxMesh).material as StandardMaterial3D
	var white := base.duplicate() as StandardMaterial3D
	white.albedo_color = Color.WHITE
	white.vertex_color_use_as_albedo = true
	white.vertex_color_is_srgb = true
	var tool := SurfaceTool.new()
	for box in boxes:
		var arrays := box.mesh.surface_get_arrays(0)
		var colors := PackedColorArray()
		colors.resize((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size())
		colors.fill(((box.mesh as BoxMesh).material as StandardMaterial3D).albedo_color)
		arrays[Mesh.ARRAY_COLOR] = colors
		var painted := ArrayMesh.new()
		painted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		tool.append_from(painted, 0, box.transform)
		box.visible = false
	var mesh := tool.commit()
	mesh.surface_set_material(0, white)
	var merged := MeshInstance3D.new()
	merged.name = "Merged"
	merged.mesh = mesh
	merged.set_meta(&"merged", true)
	sign.add_child(merged, false, Node.INTERNAL_MODE_FRONT)


## Un lot fondu : un maillage d'une surface, posé au centre de ses modèles.
func _add_lot(group: Node3D, lot: Dictionary, index: int) -> MeshInstance3D:
	var center: Vector3 = lot.center / lot.parts.size()
	var shift := Transform3D(Basis(), -center)
	var tool := SurfaceTool.new()
	for part: Array in lot.parts:
		if lot.paint:
			tool.append_from(DecorBatch.painted_mesh(part[0], part[1], part[3], _cache), 0, shift * (part[2] as Transform3D))
		else:
			tool.append_from(part[0], part[1], shift * (part[2] as Transform3D))
	var mesh := tool.commit()
	mesh.surface_set_material(0, lot.material)
	var instance := MeshInstance3D.new()
	instance.name = "Merged_%d_%d_%d" % [lot.square.x, lot.square.y, index]
	instance.mesh = mesh
	instance.material_overlay = lot.overlay
	instance.cast_shadow = lot.cast
	if lot.small:
		instance.visibility_range_end = SMALL_RANGE + mesh.get_aabb().size.length() * 0.5
		instance.visibility_range_end_margin = FADE_MARGIN
		instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	instance.set_meta(&"pieces", lot.pieces)
	group.add_child(instance)
	instance.position = center
	return instance


## L'ombre d'une case : les maillages de ses lots fondus en un seul, dessiné seulement dans les ombres.
func _add_shadow(group: Node3D, shadow: Dictionary) -> void:
	var tool := SurfaceTool.new()
	var center := Vector3.ZERO
	for lot: MeshInstance3D in shadow.parts:
		center += lot.position
	center /= shadow.parts.size()
	for lot: MeshInstance3D in shadow.parts:
		tool.append_from(lot.mesh, 0, Transform3D(Basis(), lot.position - center))
	var mesh := tool.commit()
	mesh.surface_set_material(0, _shadow_material(shadow.cull))
	var instance := MeshInstance3D.new()
	instance.name = "Shadow_%d_%d" % [shadow.square.x, shadow.square.y]
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	if shadow.small:
		var lot: MeshInstance3D = shadow.parts[0]
		instance.visibility_range_end = SMALL_RANGE + mesh.get_aabb().size.length() * 0.5
		instance.visibility_range_end_margin = lot.visibility_range_end_margin
		instance.visibility_range_fade_mode = lot.visibility_range_fade_mode
	group.add_child(instance)
	instance.position = center


## Face cachée d'un matériau dans les ombres, ou -1 s'il ne peut pas se fondre dans l'ombre commune (transparent,
## découpé, ombre réglée à part).
static func _shadow_cull(material: Material) -> int:
	var base := material as BaseMaterial3D
	if not base or base.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or base.grow or base.use_point_size:
		return -1
	if base.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED or base.shadow_to_opacity:
		return -1
	return base.cull_mode


func _shadow_material(cull: int) -> Material:
	if not _shadow_materials.has(cull):
		var material := StandardMaterial3D.new()
		material.cull_mode = cull as BaseMaterial3D.CullMode
		_shadow_materials[cull] = material
	return _shadow_materials[cull]


func _add_multimesh(group: Node3D, mesh: Mesh, transforms: Array, cast: GeometryInstance3D.ShadowCastingSetting) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index in transforms.size():
		multimesh.set_instance_transform(index, transforms[index])
	var instance := MultiMeshInstance3D.new()
	instance.name = "Batch"
	instance.multimesh = multimesh
	instance.cast_shadow = cast
	group.add_child(instance)


## Un modèle posé tel quel : seulement des nœuds 3D vides et des maillages, sans script.
static func _inert(model: Node3D) -> bool:
	if model.get_script():
		return false
	for node in model.find_children("*", "", true, false):
		if node.get_script() or not (node.get_class() == "Node3D" or node.get_class() == "MeshInstance3D"):
			return false
	return true


## Le maillage est visible dans son modèle (ses parents jusqu'au modèle compris).
static func _shown_in(item: Node3D, model: Node3D) -> bool:
	var node: Node = item
	while node != model.get_parent():
		if node is Node3D and not (node as Node3D).visible:
			return false
		node = node.get_parent()
	return true


static func _mergeable(item: MeshInstance3D) -> bool:
	if item.get_script() or item.skeleton != NodePath(""):
		return false
	# Réglages propres à un objet, qu'un maillage commun ne garderait pas.
	if item.transparency > 0.0 or item.visibility_range_begin > 0.0 or item.visibility_range_end > 0.0 or item.layers != 1:
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
		var material := item.material_override if item.material_override else item.mesh.surface_get_material(surface)
		var base := material as BaseMaterial3D
		# Ce qui est transparent ou tourné vers la caméra se trie objet par objet : il reste à part.
		if base and (base.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED
				or base.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED):
			return false
		if material and not base:
			return false
	return true


## Nom d'un modèle posé, sans le numéro final (« bed_208 » → « bed »).
static func _model_name(node: Node) -> String:
	var name := String(node.name)
	var cut := name.rfind("_")
	if cut > 0 and name.substr(cut + 1).is_valid_int():
		name = name.substr(0, cut)
	return name
