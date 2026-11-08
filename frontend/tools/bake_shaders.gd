extends SceneTree
## Inventaire des matériaux du jeu pour la préparation des shaders au menu (ShaderWarmup), écrit dans
## assets/shader_warm_list.tres (ShaderWarmList).
##
## Chaque lieu est instancié comme en jeu, puis laissé quelques images : le décor dispersé, les effets, le joueur et
## les panneaux créés par les scripts y sont. On relève alors, pour chaque nœud dessiné, ses matériaux et leur usage
## (maillage simple ou en instances, ombre projetée), les particules (matériau de traitement), les Label3D, les
## soleils et les lumières ponctuelles du lieu, et son environnement. Un nœud sous « Interior » ou « BunkerInterior » est
## dessiné sans brouillard ni soleil (le lieu les coupe à l'intérieur) : il va dans le groupe intérieur.
##
## Un matériau n'est gardé qu'une fois par contexte de rendu (brouillard, soleils et leurs ombres, lumières
## ponctuelles) : deux lieux éclairés de la même façon compilent les mêmes programmes.
##
## À relancer après l'ajout d'un matériau, d'un shader ou d'un lieu :
##   cd frontend && godot --headless --fixed-fps 60 --path . --script res://tools/bake_shaders.gd
## --fixed-fps 60 rend le relevé indépendant de la charge de la machine : certains lieux préparent leur décor au fil
## du temps (regroupement du hub), et le relevé se fait au bout de SETTLE_FRAMES images.
## Avec « -- --check », rien n'est écrit : le script compare le fichier au calcul, et sort en erreur s'ils diffèrent.

const PATH := "res://assets/shader_warm_list.tres"
## Lieux dans l'ordre où le menu les prépare : le hub d'abord, où commence une partie.
const PLACES := [
	["hub", "res://scenes/levels/hub/hub.tscn"],
	["plaine", "res://scenes/levels/plaine/plaine.tscn"],
	["desert", "res://scenes/levels/desert/desert.tscn"],
	["marais", "res://scenes/levels/marais/marais.tscn"],
	["village", "res://scenes/levels/village/village.tscn"],
]
const INSIDE_NAMES := ["Interior", "BunkerInterior"]
## Images laissées au lieu pour créer ce que ses scripts ajoutent.
const SETTLE_FRAMES := 12

## Clés déjà gardées, tous lieux confondus (contexte de rendu compris).
var _seen := {}
var _fingerprint := PackedStringArray()
## Brouillard de l'extérieur du lieu en cours.
var _fog := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var check := OS.get_cmdline_user_args().has("--check")
	var start := Time.get_ticks_msec()
	var list := ShaderWarmList.new()
	for place in PLACES:
		var packed := load(place[1]) as PackedScene
		# Brouillard de l'extérieur tel que la scène le donne : le lieu le coupe s'il commence à l'intérieur (le hub).
		_fog = _scene_fog(packed)
		# Chargé comme en jeu (scène courante) : certains scripts la cherchent.
		change_scene_to_packed(packed)
		await scene_changed
		for frame in SETTLE_FRAMES:
			await process_frame
		var scene := current_scene
		for inside in [false, true]:
			var group := _group(scene, String(place[0]), inside)
			if group:
				list.groups.append(group)
				print("  %s, %s : %d matériaux, %d particules, %d textes" % [group.place, "intérieur" if inside else "extérieur",
					(group.materials as Array).size(), (group.process as Array).size(), (group.labels as Array).size()])
	unload_current_scene()
	await process_frame
	list.fingerprint = _fingerprint
	var count := 0
	for group in list.groups:
		count += (group.materials as Array).size() + (group.process as Array).size() + (group.labels as Array).size()
	print("Shaders : %d groupes, %d entrées, relevées en %d ms" % [list.groups.size(), count, Time.get_ticks_msec() - start])

	if check:
		var saved := ResourceLoader.load(PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as ShaderWarmList
		var same := saved != null and saved.fingerprint == list.fingerprint
		if saved == null:
			print("  %s illisible" % PATH)
		if not same and saved != null:
			for line in list.fingerprint:
				if not saved.fingerprint.has(line):
					print("  nouveau : ", line)
			for line in saved.fingerprint:
				if not list.fingerprint.has(line):
					print("  disparu : ", line)
		print("Shaders : %s" % ("inventaire à jour" if same else "INVENTAIRE PÉRIMÉ, relancer tools/bake_shaders.gd"))
		quit(0 if same else 1)
		return
	var error := ResourceSaver.save(list, PATH)
	print("Shaders : %s écrit (%d octets)" % [PATH, FileAccess.get_file_as_bytes(PATH).size()] if error == OK
		else "Shaders : écriture impossible (%s)" % error_string(error))
	quit(0 if error == OK else 1)


## Le groupe extérieur ou intérieur d'un lieu, ou un dictionnaire vide s'il n'apporte rien de neuf.
func _group(scene: Node, place: String, inside: bool) -> Dictionary:
	var environment: Environment = null
	var suns: Array[Dictionary] = []
	var omni := false
	for node in _walk(scene):
		if node is WorldEnvironment and environment == null:
			environment = (node as WorldEnvironment).environment
		elif node is DirectionalLight3D and not inside:
			var sun := node as DirectionalLight3D
			suns.append({"shadow": sun.shadow_enabled, "mode": sun.directional_shadow_mode,
				"blend": sun.directional_shadow_blend_splits})
		elif node is OmniLight3D and _is_inside(node) == inside:
			omni = true
	var fog := environment != null and _fog and not inside
	# Contexte de rendu : ce qui choisit les variantes des shaders (brouillard, soleils et leurs ombres, lumières
	# ponctuelles). Le reste de l'environnement (ciel, lueur) est le même dans tous les lieux.
	var context := "fog=%s suns=%s omni=%s" % [fog, suns.map(func(s: Dictionary) -> String:
		return "%s/%s/%s" % [s.shadow, s.mode, s.blend]), omni]
	var group := {"place": place, "inside": inside, "environment": _environment(environment, fog), "suns": suns,
		"omni": omni, "materials": [], "usages": PackedByteArray(), "process": [], "labels": [], "entries": []}
	for node in _walk(scene):
		if not node is GeometryInstance3D or _is_inside(node) != inside:
			continue
		var geometry := node as GeometryInstance3D
		var shadow := ShaderWarmList.SHADOW if geometry.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF else 0
		var materials: Array[Material] = []
		var usage := shadow
		if geometry is MeshInstance3D and (geometry as MeshInstance3D).mesh:
			var mesh_instance := geometry as MeshInstance3D
			for surface in mesh_instance.mesh.get_surface_count():
				materials.append(mesh_instance.get_active_material(surface))
		elif geometry is MultiMeshInstance3D and (geometry as MultiMeshInstance3D).multimesh:
			usage |= ShaderWarmList.INSTANCED
			materials.append_array(_mesh_materials((geometry as MultiMeshInstance3D).multimesh.mesh))
		elif geometry is CPUParticles3D:
			usage |= ShaderWarmList.INSTANCED
			materials.append_array(_mesh_materials((geometry as CPUParticles3D).mesh))
		elif geometry is GPUParticles3D:
			var particles := geometry as GPUParticles3D
			usage |= ShaderWarmList.INSTANCED
			for index in particles.draw_passes:
				materials.append_array(_mesh_materials(particles.get_draw_pass_mesh(index)))
			_add(group, context, particles.process_material, 0, "process")
		elif geometry is Label3D:
			_add_label(group, context, geometry as Label3D)
		if geometry.material_override:
			materials = [geometry.material_override]
		if geometry.material_overlay:
			materials.append(geometry.material_overlay)
		for material in materials:
			_add(group, context, material, usage, "materials")
	# Ordre stable d'un passage à l'autre : les scripts des lieux ne créent pas toujours leurs nœuds dans le même ordre.
	var entries: Array = group.entries
	entries.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	group.erase("entries")
	for entry in entries:
		_fingerprint.append(entry[0])
		(group[entry[1]] as Array).append(entry[2])
		if entry[1] == "materials":
			group.usages.append(entry[3])
	return {} if entries.is_empty() else group


func _add(group: Dictionary, context: String, material: Material, usage: int, field: String) -> void:
	if material == null:
		return
	var line := "%s %s %s usage=%d %s" % [context, field, _key(material), usage, ""]
	if _seen.has(line):
		return
	_seen[line] = true
	(group.entries as Array).append(["%s/%s: %s" % [group.place, "int" if group.inside else "ext", line.strip_edges()],
		field, _canonical(material) if field == "materials" else material.duplicate(true), usage])


func _add_label(group: Dictionary, context: String, label: Label3D) -> void:
	var font := label.font if label.font and label.font.resource_path.begins_with("res://") \
		and not label.font.resource_path.contains("::") else null
	var settings := {"shaded": label.shaded, "double_sided": label.double_sided, "no_depth_test": label.no_depth_test,
		"fixed_size": label.fixed_size, "alpha_cut": label.alpha_cut, "billboard": label.billboard,
		"texture_filter": label.texture_filter, "alpha_antialiasing_mode": label.alpha_antialiasing_mode,
		"cast_shadow": label.cast_shadow, "font": font}
	var key := "%s labels %s" % [context, var_to_str(settings).replace("\n", "")]
	if _seen.has(key):
		return
	_seen[key] = true
	(group.entries as Array).append(["%s/%s: %s" % [group.place, "int" if group.inside else "ext", key], "labels", settings, 0])


## Clé du shader qu'un matériau compile : le fichier du shader, ou les réglages qui choisissent le code généré
## (énumérations et cases à cocher ; les couleurs, nombres et textures ne sont que des valeurs d'uniformes).
## Les particules générées dépendent aussi de la présence de leurs courbes et dégradés.
func _key(material: Material) -> String:
	var parts := PackedStringArray([material.get_class()])
	if material is ShaderMaterial:
		var shader := (material as ShaderMaterial).shader
		if shader == null:
			parts.append("-")
		elif shader.resource_path.begins_with("res://") and not shader.resource_path.contains("::"):
			parts.append(shader.resource_path)
		else:
			parts.append("code:%d" % shader.code.hash())
	else:
		for property in material.get_property_list():
			if not property.usage & PROPERTY_USAGE_STORAGE or property.name in ["resource_local_to_scene", "render_priority"]:
				continue
			if property.type == TYPE_INT or property.type == TYPE_BOOL:
				parts.append("%s=%s" % [property.name, material.get(property.name)])
			elif property.type == TYPE_OBJECT and material is ParticleProcessMaterial and material.get(property.name) is Texture:
				parts.append(property.name)
	if material.next_pass:
		parts.append("puis(%s)" % _key(material.next_pass))
	return " ".join(parts)


## Matériau réduit à ce qui choisit son shader : le même shader sans paramètres, ou un matériau neuf de la même classe
## avec les seuls réglages de la clé. Couleurs, nombres et textures ne changent pas le code des shaders, et le menu n'a
## pas à charger les textures. Deux matériaux de même clé donnent la même copie.
func _canonical(material: Material) -> Material:
	var copy: Material
	if material is ShaderMaterial:
		copy = ShaderMaterial.new()
		(copy as ShaderMaterial).shader = (material as ShaderMaterial).shader
	else:
		copy = ClassDB.instantiate(material.get_class()) as Material
		for property in material.get_property_list():
			if property.usage & PROPERTY_USAGE_STORAGE and (property.type == TYPE_INT or property.type == TYPE_BOOL) \
					and property.name != "resource_local_to_scene":
				copy.set(property.name, material.get(property.name))
	if material.next_pass:
		copy.next_pass = _canonical(material.next_pass)
	return copy


func _scene_fog(packed: PackedScene) -> bool:
	var state := packed.get_state()
	for node in state.get_node_count():
		if state.get_node_type(node) != &"WorldEnvironment":
			continue
		for property in state.get_node_property_count(node):
			if state.get_node_property_name(node, property) == &"environment":
				var environment := state.get_node_property_value(node, property) as Environment
				return environment != null and environment.fog_enabled
	return false


func _environment(environment: Environment, fog: bool) -> Environment:
	if environment == null:
		return null
	var copy := environment.duplicate(true) as Environment
	copy.fog_enabled = fog
	return copy


func _mesh_materials(mesh: Mesh) -> Array[Material]:
	var materials: Array[Material] = []
	if mesh:
		for surface in mesh.get_surface_count():
			materials.append(mesh.surface_get_material(surface))
	return materials


func _is_inside(node: Node) -> bool:
	var parent := node
	while parent:
		if parent.name in INSIDE_NAMES:
			return true
		parent = parent.get_parent()
	return false


## Tous les nœuds d'un lieu, internes compris (le maillage d'un CPUParticles3D, par exemple), dans l'ordre de l'arbre.
func _walk(node: Node) -> Array[Node]:
	var nodes: Array[Node] = [node]
	for child in node.get_children(true):
		nodes.append_array(_walk(child))
	return nodes
