extends Node3D
## Décor fixe du hub (hub_props.tscn), regroupé au chargement pour le web. Dans chaque groupe (le décor fixe, et pour
## chaque élément réparable sa ruine et sa reconstruction) et dans chaque case de CELL mètres, toutes les surfaces qui
## partagent un matériau sont fondues en un seul maillage : un appel de dessin au lieu d'un par modèle et par surface.
## Deux matériaux qui ne diffèrent que par leur instance (chaque modèle d'un kit Kenney a le sien, sur la même
## texture) comptent pour un ; deux matériaux sans texture qui ne diffèrent que par leur couleur (kit Nature) aussi :
## la couleur passe dans les sommets. Signature des matériaux, peinture dans les sommets et lecture des surfaces :
## l'outil commun (DecorBatch, scripts/decor_batch.gd), dont la mémoire par état décrit chaque état de matériau une
## seule fois (227 matériaux distincts dans le décor du hub, pour 11 signatures), et qui ne lit chaque surface de modèle
## qu'une fois (260 surfaces pour 5 064 morceaux). Elle est oubliée quand le hub se ferme.
## Les groupes restent séparés : les réparations continuent de montrer, cacher ou faire monter chacun d'un bloc.
## Les collisions ne bougent pas : elles sont dans les nœuds Collision de chaque groupe, que le regroupement ne touche pas.
## Chaque maillage fondu garde, en métadonnée « pieces », le nom et la boîte (monde) de chaque modèle qu'il contient.
## Ombres : le soleil redessine chaque objet qui projette une ombre dans chacune de ses 4 tranches, et c'est là que
## partait l'essentiel des appels de dessin. La profondeur d'une ombre ne dépend pas du matériau (opaque) : tous les
## lots d'une case projettent leur ombre d'un seul maillage, dessiné seulement dans les ombres (SHADOWS_ONLY). Les lots
## visibles n'en projettent plus. L'ombre reste exactement la même : mêmes triangles, même face cachée.
## Chargement : rien ne se regroupe avant la première image (le rendu est le même, en plus d'appels de dessin) ; les
## groupes se regroupent ensuite par pas (un modèle examiné, un morceau assemblé, un lot ou une ombre bâti), pendant
## BUDGET_MSEC par image, ceux qu'on voit d'abord. Un groupe ne change qu'à la fin de son regroupement, d'un coup : ses
## maillages fondus y entrent quand ses modèles en sortent, on ne le voit jamais à moitié regroupé. Un groupe caché qui
## apparaît (une réparation, la sortie du bunker) se regroupe aussitôt, d'un bloc.
## Les groupes qui ne peuvent pas se montrer pendant la visite (la ruine d'un élément déjà réparé, la reconstruction
## d'un élément au-delà des livres trouvés : leave_aside, appelé par le hub) ne sont pas regroupés : rien ne les dessine.
## S'ils apparaissent quand même, ils se regroupent aussitôt. Ne sont jamais fondus : les nœuds à script (panneaux,
## lampes, textes, portes, roue du moulin), les collisions, les arbres, et tout modèle qui contient autre chose que des
## maillages.

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
## Temps de regroupement par image (ms), après le chargement : au moins un pas par image.
const BUDGET_MSEC := 8
## Attributs de sommet comparés entre surfaces : seules des surfaces de même format se fondent ensemble.
const FORMAT_MASK := 0xFF

## Signatures par instance de matériau, matériaux et surfaces peints, surfaces lues (DecorBatch), d'un groupe à
## l'autre. Vidée quand tous les groupes prévus sont regroupés.
var _cache := {}
var _shadow_materials := {}
## Groupes à regrouper, pris par la fin.
var _pending: Array[Node3D] = []
## Groupes laissés de côté (leave_aside) : regroupés seulement s'ils apparaissent.
var _aside: Array[Node3D] = []
## Groupe en cours de regroupement.
var _job: Job
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


## Laisse de côté des groupes qui ne peuvent pas se montrer pendant la visite (à appeler avant la première image) : ils
## ne sont regroupés que s'ils apparaissent quand même.
func leave_aside(groups: Array[Node3D]) -> void:
	for group in groups:
		if group in _pending:
			_pending.erase(group)
			_aside.append(group)


## Rien n'est regroupé pendant le chargement : à partir de la première image, chaque image avance le regroupement
## pendant au plus BUDGET_MSEC, les groupes qu'on voit d'abord. Un groupe caché qui apparaît avant son tour est regroupé
## aussitôt.
func _batch_shown() -> void:
	var shown: Array[Node3D] = []
	var hidden: Array[Node3D] = []
	for group in _aside.duplicate():
		# Montré malgré tout avant la première image (aperçu d'une fin) : regroupé comme les autres.
		if group.visible:
			_aside.erase(group)
			_pending.append(group)
	for group in _pending:
		if group.is_visible_in_tree():
			shown.append(group)
		else:
			hidden.append(group)
			group.visibility_changed.connect(_batch_now.bind(group), CONNECT_ONE_SHOT)
	for group in _aside:
		group.visibility_changed.connect(_batch_now.bind(group), CONNECT_ONE_SHOT)
	# _process prend les groupes par la fin : les groupes visibles passent en premier.
	_pending.assign(hidden + shown)
	set_process(not _pending.is_empty())


## Regroupe aussitôt un groupe qui apparaît (ou tout ce qui reste de son regroupement s'il est en cours).
func _batch_now(group: Node3D) -> void:
	var start := Time.get_ticks_usec()
	if _job and _job.group == group:
		_job.step(DecorBatch.NO_DEADLINE)
		_job = null
	elif group in _pending or group in _aside:
		_pending.erase(group)
		_aside.erase(group)
		Job.new(self, group).step(DecorBatch.NO_DEADLINE)
	_done(group)
	batch_msec += (Time.get_ticks_usec() - start) / 1000.0


func _process(_delta: float) -> void:
	var start := Time.get_ticks_usec()
	var deadline := start + BUDGET_MSEC * 1000
	while true:
		if not _job:
			if _pending.is_empty():
				break
			_job = Job.new(self, _pending.pop_back())
		if _job.step(deadline):
			var group := _job.group
			_job = null
			_done(group)
		if Time.get_ticks_usec() >= deadline:
			break
	batch_msec += (Time.get_ticks_usec() - start) / 1000.0
	if is_done():
		set_process(false)


## Un groupe regroupé : il n'attend plus de paraître, et la mémoire des surfaces est vidée quand plus rien n'est prévu.
func _done(group: Node3D) -> void:
	var callback := _batch_now.bind(group)
	if group.visibility_changed.is_connected(callback):
		group.visibility_changed.disconnect(callback)
	if is_done():
		_cache.clear()


## Tous les groupes prévus regroupés (pour les tests et les mesures).
func is_done() -> bool:
	return _pending.is_empty() and not _job


## Regroupe d'un bloc tout ce qui reste, groupes laissés de côté compris (outils : empreinte du décor regroupé).
func finish_all() -> void:
	for group in _aside.duplicate():
		_batch_now(group)
	while not is_done():
		_batch_now(_job.group if _job else _pending.back())


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


func _shadow_material(cull: int) -> Material:
	if not _shadow_materials.has(cull):
		var material := StandardMaterial3D.new()
		material.cull_mode = cull as BaseMaterial3D.CullMode
		_shadow_materials[cull] = material
	return _shadow_materials[cull]


## Le regroupement d'un groupe, par pas (step, comme DecorBatch.step) : ses modèles examinés un à un, puis chaque lot
## assemblé morceau par morceau, puis l'ombre de chaque case, puis les MultiMesh de ce qui reste à part. Rien n'entre
## dans le groupe avant le dernier pas, où ses maillages fondus remplacent ses modèles d'un coup.
class Job:
	var group: Node3D
	var _batch: Node3D
	var _cache: Dictionary
	var _inverse: Transform3D
	var _world: Transform3D
	var _children: Array[Node]
	var _next_child := 0
	var _lots := {}
	## Maillages qu'un lot commun ne saurait rendre à l'identique (transparents, tournés vers la caméra) : un MultiMesh
	## par maillage, comme avant.
	var _apart := {}
	var _batched: Array[Node] = []
	var _lot_list: Array = []
	var _next_lot := 0
	var _shadows := {}
	var _shadow_list: Array = []
	var _next_shadow := 0
	## Assemblage en cours (lot ou ombre) : l'outil, le morceau suivant, et le centre.
	var _tool: SurfaceTool
	var _next_part := 0
	var _center := Vector3.ZERO
	var _nodes: Array[Node3D] = []
	var _phase := Phase.SCAN
	var _done := false

	enum Phase { SCAN, LOTS, SHADOWS, FINISH }

	func _init(batch: Node3D, target: Node3D) -> void:
		_batch = batch
		_cache = batch._cache
		group = target
		_world = group.global_transform
		_inverse = _world.affine_inverse()
		_children = group.get_children()


	## Avance jusqu'à l'instant deadline (Time.get_ticks_usec), d'au moins un pas ; rend vrai quand le groupe est
	## regroupé.
	func step(deadline: int) -> bool:
		while not _done:
			_advance()
			if Time.get_ticks_usec() >= deadline:
				break
		return _done


	func _advance() -> void:
		match _phase:
			Phase.SCAN:
				if _next_child < _children.size():
					_scan(_children[_next_child])
					_next_child += 1
					return
				_lot_list = _lots.values()
				_phase = Phase.LOTS
			Phase.LOTS:
				if _next_lot < _lot_list.size():
					_lot_step(_lot_list[_next_lot])
					return
				_shadow_list = _shadows.values()
				_phase = Phase.SHADOWS
			Phase.SHADOWS:
				if _next_shadow < _shadow_list.size():
					_shadow_step(_shadow_list[_next_shadow])
					return
				_phase = Phase.FINISH
			Phase.FINISH:
				_finish()


	## Examine un enfant du groupe : un modèle posé, inerte, qui n'est pas un arbre, a ses surfaces rangées dans leurs
	## lots (ou à part) et sera retiré.
	func _scan(child: Node) -> void:
		# Seuls les modèles posés tels quels : les nœuds à script (la roue du moulin, les textes, les lampes) gardent
		# leurs enfants.
		if not child is Node3D or child.scene_file_path.is_empty():
			return
		# Les arbres restent des nœuds : peu nombreux, ils gardent chacun leur visibilité (le contrôle des collisions
		# des arbres les retrouve ainsi par leur scène).
		if child.scene_file_path.get_file().contains("tree"):
			return
		# Seulement des modèles inertes : ni script, ni animation, ni lumière, ni particules, ni collision dedans. Ses
		# nœuds ne sont parcourus qu'une fois : ses maillages en sont, dans le même ordre.
		if child.get_script():
			return
		var nodes := child.find_children("*", "", true, false)
		if not _inert(nodes):
			return
		var model := _model_name(child)
		for node in nodes:
			if node.get_class() != "MeshInstance3D":
				continue
			var item := node as MeshInstance3D
			# Visibilité dans le modèle seulement : un groupe caché (ruine réparée) se regroupe aussi.
			if not item.mesh or not _shown_in(item, child):
				continue
			var place := _inverse * item.global_transform
			var surfaces: Variant = _surfaces(item.mesh, item.material_override, item.material_overlay)
			if surfaces == null or not _item_mergeable(item):
				if not _apart.has(item.mesh):
					_apart[item.mesh] = {"cast": item.cast_shadow, "transforms": []}
				_apart[item.mesh].transforms.append(place)
				continue
			var box := place * item.mesh.get_aabb()
			var longest := maxf(box.size.x, maxf(box.size.y, box.size.z))
			var square := Vector2i(floori(box.get_center().x / CELL), floori(box.get_center().z / CELL))
			var pieces := [model, _world * box]
			for info: Array in surfaces as Array:
				var small: bool = longest < SMALL and not info[3]
				# La clé : signature du matériau, surcouche, format (info[5]), ombre, taille et case.
				var key: String = info[5] + "_%d_%s_%d_%d" % [item.cast_shadow, small, square.x, square.y]
				if not _lots.has(key):
					_lots[key] = {"material": DecorBatch.painted_material(info[0], _cache) if info[1] else info[0],
						"overlay": item.material_overlay, "cast": item.cast_shadow, "small": small, "paint": info[1],
						"square": square, "parts": [], "pieces": [], "center": Vector3.ZERO}
				var lot: Dictionary = _lots[key]
				lot.parts.append([item.mesh, info[6], place, info[2]])
				lot.pieces.append(pieces)
				lot.center += box.get_center()
		_batched.append(child)


	## Les surfaces d'un maillage telles que le regroupement les range : [matériau, peint, couleur, luit, format, début
	## de la clé (signature du matériau, surcouche et format), numéro de la surface], ou null si le maillage ne peut
	## pas se fondre. Ne dépend que du maillage quand rien ne lui impose de matériau : gardé alors dans le cache commun
	## (un même modèle revient des dizaines de fois).
	func _surfaces(mesh: Mesh, override: Material, overlay: Material) -> Variant:
		var shared := override == null and overlay == null
		if shared and _cache.has(mesh):
			return _cache[mesh]
		var surfaces: Variant = null
		if _mesh_mergeable(mesh, override):
			surfaces = []
			for surface in mesh.get_surface_count():
				var material: Material = override if override else mesh.surface_get_material(surface)
				var paint := DecorBatch.paintable(material)
				var format: int = (mesh as ArrayMesh).surface_get_format(surface) & FORMAT_MASK if mesh is ArrayMesh else 0
				if paint:
					format |= Mesh.ARRAY_FORMAT_COLOR
				(surfaces as Array).append([material, paint, (material as BaseMaterial3D).albedo_color if paint else Color.WHITE,
					DecorBatch.glows(material), format, "%s_%d_%d" % [DecorBatch.signature(material, _cache),
					DecorBatch.instance_id(overlay), format], surface])
		if shared:
			_cache[mesh] = surfaces
		return surfaces


	## Un pas d'un lot : un morceau assemblé, ou le lot fini (un maillage d'une surface, posé au centre de ses modèles),
	## dont l'ombre va dans celle de sa case.
	func _lot_step(lot: Dictionary) -> void:
		if _next_part == 0:
			_tool = SurfaceTool.new()
			_center = lot.center / lot.parts.size()
		if _next_part < lot.parts.size():
			var part: Array = lot.parts[_next_part]
			_tool.append_from(DecorBatch.part_source(part, lot.paint, _cache), 0,
				Transform3D(Basis(), -_center) * (part[2] as Transform3D))
			_next_part += 1
			return
		var mesh := _tool.commit()
		mesh.surface_set_material(0, lot.material)
		var instance := MeshInstance3D.new()
		instance.name = "Merged_%d_%d_%d" % [lot.square.x, lot.square.y, _next_lot + 1]
		instance.mesh = mesh
		instance.material_overlay = lot.overlay
		instance.cast_shadow = lot.cast
		if lot.small:
			instance.visibility_range_end = SMALL_RANGE + mesh.get_aabb().size.length() * 0.5
			instance.visibility_range_end_margin = FADE_MARGIN
			instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		instance.set_meta(&"pieces", lot.pieces)
		instance.position = _center
		_nodes.append(instance)
		_tool = null
		_next_part = 0
		_next_lot += 1
		var cull := _shadow_cull(mesh.surface_get_material(0))
		if instance.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_ON or cull < 0:
			return
		# L'ombre du lot passe dans celle de sa case (les petits objets à part : elle s'efface avec eux).
		var shadow_key := "%d_%d_%s_%d" % [lot.square.x, lot.square.y, lot.small, cull]
		if not _shadows.has(shadow_key):
			_shadows[shadow_key] = {"cull": cull, "small": lot.small, "square": lot.square, "parts": []}
		_shadows[shadow_key].parts.append(instance)
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


	## Un pas de l'ombre d'une case : un lot ajouté, ou l'ombre finie (les maillages de ses lots fondus en un seul,
	## dessiné seulement dans les ombres).
	func _shadow_step(shadow: Dictionary) -> void:
		if _next_part == 0:
			_tool = SurfaceTool.new()
			_center = Vector3.ZERO
			for lot: MeshInstance3D in shadow.parts:
				_center += lot.position
			_center /= shadow.parts.size()
		if _next_part < shadow.parts.size():
			var lot: MeshInstance3D = shadow.parts[_next_part]
			_tool.append_from(lot.mesh, 0, Transform3D(Basis(), lot.position - _center))
			_next_part += 1
			return
		var mesh := _tool.commit()
		mesh.surface_set_material(0, _batch._shadow_material(shadow.cull))
		var instance := MeshInstance3D.new()
		instance.name = "Shadow_%d_%d" % [shadow.square.x, shadow.square.y]
		instance.mesh = mesh
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		if shadow.small:
			var lot: MeshInstance3D = shadow.parts[0]
			instance.visibility_range_end = SMALL_RANGE + mesh.get_aabb().size.length() * 0.5
			instance.visibility_range_end_margin = lot.visibility_range_end_margin
			instance.visibility_range_fade_mode = lot.visibility_range_fade_mode
		instance.position = _center
		_nodes.append(instance)
		_tool = null
		_next_part = 0
		_next_shadow += 1


	## Dernier pas : les MultiMesh de ce qui reste à part, puis les maillages fondus entrent dans le groupe et les
	## modèles fondus en sortent, dans la même image.
	func _finish() -> void:
		for mesh: Mesh in _apart:
			var multimesh := MultiMesh.new()
			multimesh.transform_format = MultiMesh.TRANSFORM_3D
			multimesh.mesh = mesh
			var transforms: Array = _apart[mesh].transforms
			multimesh.instance_count = transforms.size()
			for index in transforms.size():
				multimesh.set_instance_transform(index, transforms[index])
			var instance := MultiMeshInstance3D.new()
			instance.name = "Batch"
			instance.multimesh = multimesh
			instance.cast_shadow = _apart[mesh].cast
			_nodes.append(instance)
		for node in _nodes:
			group.add_child(node)
		for child in _batched:
			group.remove_child(child)
			child.queue_free()
		_children.clear()
		_lots.clear()
		_apart.clear()
		_batched.clear()
		_lot_list.clear()
		_shadows.clear()
		_shadow_list.clear()
		_nodes.clear()
		_done = true


	## Face cachée d'un matériau dans les ombres, ou -1 s'il ne peut pas se fondre dans l'ombre commune (transparent,
	## découpé, ombre réglée à part).
	static func _shadow_cull(material: Material) -> int:
		var base := material as BaseMaterial3D
		if not base or base.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or base.grow or base.use_point_size:
			return -1
		if base.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED or base.shadow_to_opacity:
			return -1
		return base.cull_mode


	## Les nœuds d'un modèle (tous ses descendants) sont ceux d'un modèle posé tel quel : seulement des nœuds 3D vides et
	## des maillages, sans script.
	static func _inert(nodes: Array[Node]) -> bool:
		for node in nodes:
			if node.get_script():
				return false
			var type := node.get_class()
			if type != "Node3D" and type != "MeshInstance3D":
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


	## Réglages propres à un objet, qu'un maillage commun ne garderait pas.
	static func _item_mergeable(item: MeshInstance3D) -> bool:
		if item.get_script() or item.skeleton != NodePath(""):
			return false
		if item.transparency > 0.0 or item.visibility_range_begin > 0.0 or item.visibility_range_end > 0.0 or item.layers != 1:
			return false
		if item.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
			return false
		for surface in item.get_surface_override_material_count():
			if item.get_surface_override_material(surface):
				return false
		return true


	## Le maillage peut se fondre (avec le matériau imposé override, s'il y en a un) : des triangles, sans forme de
	## morphose, ni rien de transparent ou tourné vers la caméra.
	static func _mesh_mergeable(mesh: Mesh, override: Material) -> bool:
		if mesh is ArrayMesh and (mesh as ArrayMesh).get_blend_shape_count() > 0:
			return false
		for surface in mesh.get_surface_count():
			if mesh is ArrayMesh and (mesh as ArrayMesh).surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES:
				return false
			var material := override if override else mesh.surface_get_material(surface)
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
