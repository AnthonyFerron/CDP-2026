class_name Desert
extends Node3D
## Le désert de Pythania : les algorithmes oubliés. Le joueur ramasse des runes dans les salles du monument des
## anciens bâtisseurs, parmi les débris et sous le sable, puis reconstitue deux algorithmes sur la table ronde de
## pierre de la cave pour libérer l'Algonicon. Les sables mouvants ramènent le joueur en lieu sûr.

signal book_collected(book_id: StringName)
signal hub_requested

const ZONE := &"desert"
const BOOK_ID := &"algonicon"
const QUICKSAND_SPEED := 0.35
## Temps passé dans les sables mouvants avant d'être englouti.
const SINK_TIME := 1.6
const SAFE_FRAMES := 15
const WIND_DB := -8.0
## Teinte appliquée à la pierre claire du kit pour en faire du grès.
const SANDSTONE := Color(1.0, 0.8, 0.6)
## Pierres des cairns (modèle stones du kit) : une teinte unie, l'une de leurs pierres est gris foncé dans l'atlas
## et virait au noir sous la teinte du grès.
const CAIRN_STONE := Color(0.7, 0.58, 0.46)
## Modèles des ruines dont une boîte laisserait des murs invisibles (étals ouverts sous leur auvent, charrette
## renversée, bannières sur pied) : leur collision suit leurs triangles.
const EXACT_MODELS: Array[String] = ["cart_", "stall_", "banner_"]
## Lumière ambiante dehors et dans la cave, sombre et poussiéreuse.
const AMBIENT_OUTSIDE := 0.3
const AMBIENT_INSIDE := 0.22
## Au-delà de cette distance, les petits modèles des ruines disparaissent en fondu.
const SMALL_PROP_RANGE := 70.0
const SMALL_PROP_SIZE := 1.6
## Côté des cases où les maillages fixes des ruines sont regroupés par matériau.
const MERGE_CHUNK := 32.0

@export var sand_steps: Array[AudioStream]
@export var stone_steps: Array[AudioStream]
@export var chimes: Array[AudioStream]
@export var reset_sound: AudioStream

## Runes ramassées, dans l'ordre où le joueur les a trouvées.
var _inventory: Array[StringName] = []
var _inside := false
var _busy := false
var _sinking := 0.0
var _grounded_frames := 0
var _safe_position := Vector3.ZERO
var _sandstorm: CPUParticles3D
var _sand_veil: CPUParticles3D
var _dust: CPUParticles3D
var _slot_material: StandardMaterial3D
var _shake_tween: Tween
var _shake_rest := Vector3.ZERO
var _shake_strength := 0.0

@onready var _player: Player = $Player
@onready var _hud: Hud = $Hud
@onready var _wind: AudioStreamPlayer = $Wind
@onready var _cave_sound: AudioStreamPlayer = $CaveAmbience
@onready var _environment: Environment = $WorldEnvironment.environment
@onready var _sun: DirectionalLight3D = $Sun
@onready var _exterior: Node3D = $Exterior
@onready var _interior: Node3D = $Interior
@onready var _portal: Portal = $Exterior/Portal
@onready var _hatch: Node3D = $Exterior/Trapdoor/Hatch
@onready var _trapdoor: Interactable = $Exterior/Trapdoor/Interactable
@onready var _exit: Interactable = $Interior/Exit
@onready var _inside_spawn: Marker3D = $Interior/InsideSpawn
@onready var _outside_spawn: Marker3D = $Exterior/OutsideSpawn
@onready var _puzzle: RunePuzzle = $RunePuzzle
@onready var _table: Interactable = $Interior/RoundTable/Interactable
@onready var _table_glow: OmniLight3D = $Interior/RoundTable/Glow
@onready var _table_sound: AudioStreamPlayer3D = $Interior/RoundTable/Sound
@onready var _rumble: AudioStreamPlayer3D = $Interior/RoundTable/Rumble
@onready var _chest_lid: Node3D = $Interior/Chest/Lid
@onready var _chest: Node3D = $Interior/Chest
@onready var _chest_sand: Node3D = $Interior/ChestSand
@onready var _book: Node3D = $Interior/Book
@onready var _book_pickup: Interactable = $Interior/Book/Interactable
@onready var _book_target: Marker3D = $Interior/BookTarget


func _ready() -> void:
	var interaction: InteractionController = _player.get_node("Interaction")
	interaction.prompt_changed.connect(_hud.set_prompt)
	_hud.reader_closed.connect(_close_panel)
	_raise_gate_grille()
	for clues: Node in [$Exterior/Clues, $Interior/Clues]:
		for clue: Readable in clues.get_children():
			clue.interacted.connect(_read.bind(clue))
	for rune: Rune in find_children("*", "Rune", true, false):
		rune.interacted.connect(_on_rune_taken.bind(rune))
	for pile: SandPile in find_children("*", "SandPile", true, false):
		pile.cleared.connect(_on_pile_cleared)
	_table.interacted.connect(_open_table)
	_puzzle.validated.connect(_on_puzzle_validated)
	_puzzle.closed.connect(_close_panel)
	_trapdoor.interacted.connect(_travel.bind(true))
	_exit.interacted.connect(_travel.bind(false))
	_book_pickup.interacted.connect(_on_book_taken)
	_portal.refused.connect(_on_portal_refused)
	_portal.travel_requested.connect(_on_portal_crossed)

	_book_pickup.enabled = false
	_book.hide()
	_chest.hide()
	_table_glow.visible = false
	_safe_position = _player.global_position
	_tint_stone($Exterior/Ruins)
	_exact_colliders($Exterior/Ruins)
	# Les tests d'audit, qui mesurent les maillages triangle par triangle, lancent le niveau sans ce regroupement.
	if not "sans_regroupement" in OS.get_cmdline_user_args():
		_merge_static($Exterior/Ruins)
		# Chaque stèle (socle, fût, corniche, cadres, soleils des deux faces) en quelques maillages par matériau.
		for stele: Node3D in [$Exterior/Clues/Levant, $Exterior/Clues/Zenith, $Exterior/Clues/Couchant]:
			_merge_static(stele)
	_fade_small_props($Exterior/Ruins)
	_sandstorm = _create_sandstorm()
	_exterior.add_child(_sandstorm)
	_sand_veil = _create_sand_veil()
	_exterior.add_child(_sand_veil)
	_dust = _create_dust()
	_interior.add_child(_dust)
	_interior.add_child(_create_falling_dust())
	# Les sons d'ambiance tournent en boucle : le vent partout, celui qui siffle dans les ruines, la cave.
	for sound: AudioStreamPlayer3D in $Exterior/Sounds.get_children():
		sound.finished.connect(sound.play)
	_wind.finished.connect(_wind.play)
	_cave_sound.finished.connect(_cave_sound.play)
	var slot := $Interior/RoundTable/Slots.get_child(0) as MeshInstance3D
	_slot_material = slot.mesh.surface_get_material(0)
	_apply_location()
	# Le nom du lieu s'affiche déjà pendant la transition du portail.
	if GameState.has_book(BOOK_ID):
		_portal.is_open = true
		_hud.show_message("Vous avez déjà trouvé le livre de cette zone : le portail est ouvert.")


func _process(delta: float) -> void:
	_sandstorm.global_position = _player.global_position + Vector3(-12.0, 1.5, 0.0)
	_sand_veil.global_position = _player.global_position + Vector3(-10.0, 0.5, 0.0)
	if _book.visible:
		_book.rotation.y += delta * 0.8


func _physics_process(delta: float) -> void:
	if _busy or _inside:
		return
	var in_sand := _quicksand_at(_player.global_position)
	_player.speed_multiplier = QUICKSAND_SPEED if in_sand else 1.0
	if in_sand:
		_sinking += delta
		if _sinking >= SINK_TIME:
			_swallow()
		return
	_sinking = 0.0
	# Juste après un déplacement, is_on_floor() vaut encore l'image précédente : on attend d'être posé.
	if _player.is_on_floor():
		_grounded_frames += 1
		if _grounded_frames >= SAFE_FRAMES:
			_safe_position = _player.global_position
	else:
		_grounded_frames = 0


func inventory() -> Array[StringName]:
	return _inventory


func _quicksand_at(point: Vector3) -> bool:
	for sand in DesertTerrain.QUICKSANDS:
		if Vector2(point.x - sand.x, point.z - sand.y).length() < sand.z * 0.85:
			return true
	return false


func _swallow() -> void:
	_busy = true
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	await _hud.fade(true)
	_player.global_position = _safe_position
	_player.velocity = Vector3.ZERO
	_player.speed_multiplier = 1.0
	_sinking = 0.0
	_grounded_frames = 0
	_hud.show_message("Les sables mouvants vous happent : vous vous arrachez de justesse.")
	await _hud.fade(false)
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_busy = false


func _travel(inside: bool) -> void:
	_busy = true
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	if inside:
		var tween := create_tween()
		tween.tween_property(_hatch, "rotation:x", deg_to_rad(-110.0), 0.6).set_trans(Tween.TRANS_BACK)
		await tween.finished
	await _hud.fade(true)
	_inside = inside
	_apply_location()
	var spawn := _inside_spawn if inside else _outside_spawn
	_player.global_position = spawn.global_position
	_player.velocity = Vector3.ZERO
	_player.speed_multiplier = 1.0
	_hatch.rotation.x = 0.0
	if not inside:
		_safe_position = spawn.global_position
	await _hud.fade(false)
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_busy = false


func _apply_location() -> void:
	_interior.visible = _inside
	_exterior.visible = not _inside
	_sun.visible = not _inside
	_environment.fog_enabled = not _inside
	_sandstorm.emitting = not _inside
	_sand_veil.emitting = not _inside
	_dust.emitting = _inside
	for stream: CPUParticles3D in _interior.get_node("FallingDust").get_children():
		stream.emitting = _inside
	# Dans la cave, la lumière ambiante ne vient plus du ciel bleu mais d'une pénombre chaude.
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR if _inside else Environment.AMBIENT_SOURCE_SKY
	_environment.ambient_light_energy = AMBIENT_INSIDE if _inside else AMBIENT_OUTSIDE
	_player.footstep_sounds = stone_steps if _inside else sand_steps
	_wind.volume_db = WIND_DB - 18.0 if _inside else WIND_DB
	if _inside:
		_cave_sound.play()
	else:
		_cave_sound.stop()


func _read(readable: Readable) -> void:
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hud.show_text(readable.title, readable.body)


func _close_panel() -> void:
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_hud.set_crosshair_visible(true)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_rune_taken(rune: Rune) -> void:
	rune.collect()
	_inventory.append(rune.rune_id)
	_table_sound.stream = chimes[0]
	_table_sound.play()
	_hud.show_message("Rune ramassée : « %s »" % RunePuzzle.RUNES[rune.rune_id])


func _on_pile_cleared(had_rune: bool) -> void:
	_hud.show_message("Une rune affleure sous le sable." if had_rune else "Rien sous ce tas de sable.")


func _open_table() -> void:
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hud.set_crosshair_visible(false)
	_puzzle.open(_inventory)


func _on_puzzle_validated(correct: bool) -> void:
	_table_glow.visible = true
	if not correct:
		# Les runes rougissent, une violente secousse ébranle la cave et le volcan se rapproche de l'éruption.
		GameState.penalize()
		_table_glow.light_color = Color(1.0, 0.15, 0.1)
		_table_glow.light_energy = 3.0
		_light_slots(Color(1.0, 0.15, 0.1), 3.0)
		_table_sound.stream = reset_sound
		_table_sound.play()
		_rumble.pitch_scale = 0.7
		_rumble.play()
		_shake(0.9, 0.16)
		var flash := create_tween()
		flash.tween_interval(1.2)
		flash.tween_callback(_table_glow.hide)
		flash.tween_callback(_light_slots.bind(Color(0.3, 0.6, 1.0), 0.0))
		return
	_close_panel()
	_table.enabled = false
	# Les runes s'embrasent d'une intense lumière bleutée, un grondement mécanique monte des profondeurs.
	_table_glow.light_color = Color(0.4, 0.7, 1.0)
	_table_glow.light_energy = 0.0
	create_tween().tween_property(_table_glow, "light_energy", 7.0, 1.2).set_trans(Tween.TRANS_SINE)
	_light_slots(Color(0.35, 0.7, 1.0), 6.0)
	_table_sound.stream = chimes[2]
	_table_sound.play()
	_rumble.pitch_scale = 0.85
	_rumble.play()
	_shake(1.6, 0.05)
	_hud.show_message("Les runes s'illuminent d'une intense lumière bleutée. Un grondement mécanique : dans un coin, le sable se disperse…")
	var tween := create_tween()
	tween.tween_property(_chest_sand, "scale", Vector3(1.4, 0.02, 1.4), 2.0).set_trans(Tween.TRANS_SINE)
	await tween.finished
	_chest_sand.hide()
	_chest.show()
	# Le coffre de pierre se déverrouille : son couvercle bascule en arrière.
	var unlock := create_tween()
	unlock.tween_property(_chest_lid, "rotation:x", deg_to_rad(-105.0), 1.0).set_trans(Tween.TRANS_BACK)
	await unlock.finished
	var target := _book_target.global_position
	_book.global_position = target + Vector3.DOWN * 1.2
	_book.show()
	var rise := create_tween()
	rise.tween_property(_book, "global_position", target, 1.8).set_trans(Tween.TRANS_SINE)
	await rise.finished
	_book_pickup.enabled = true


func _on_book_taken() -> void:
	# Le livre vole jusqu'à la main du joueur, qui le garde jusqu'au château.
	_player.receive_book(BOOK_ID, _book.global_position)
	_book.hide()
	_book_pickup.enabled = false
	_portal.is_open = true
	_hud.show_message("L'Algonicon est à vous. Rapportez-le au château : le portail du désert de Pythania s'est rouvert.")
	GameState.collect_book(BOOK_ID)
	book_collected.emit(BOOK_ID)


func _on_portal_refused() -> void:
	_hud.show_message("Le portail reste éteint : trouvez le livre du désert de Pythania.")


func _on_portal_crossed() -> void:
	hub_requested.emit()
	GameState.return_to_hub(ZONE)


## Teinte les matériaux des modèles en grès, en partageant une copie par matériau d'origine. Les formes simples
## (nœud Shapes) ont déjà leurs couleurs, et les squelettes gardent la blancheur de leurs os.
func _tint_stone(root: Node) -> void:
	var tinted := {}
	for mesh: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if mesh.get_parent().name == &"Shapes" or _model_of(mesh).name.begins_with("character_skeleton"):
			continue
		var cairn := _model_of(mesh).name.begins_with("stones_")
		for surface in mesh.get_surface_override_material_count():
			var original := mesh.get_active_material(surface) as BaseMaterial3D
			if not original:
				continue
			var key := [original, cairn]
			if not tinted.has(key):
				var copy: BaseMaterial3D = original.duplicate()
				if cairn:
					copy.albedo_texture = null
					copy.albedo_color = CAIRN_STONE
				else:
					copy.albedo_color *= SANDSTONE
				tinted[key] = copy
			mesh.set_surface_override_material(surface, tinted[key])


## Collision des modèles EXACT_MODELS : leurs triangles, dans un corps à part, avant le regroupement des maillages.
func _exact_colliders(root: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "ExactCollision"
	root.add_child(body)
	var inverse := body.global_transform.affine_inverse()
	for model: Node in root.get_node("Models").get_children():
		var exact := false
		for prefix in EXACT_MODELS:
			exact = exact or String(model.name).begins_with(prefix)
		if not exact:
			continue
		for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			if not mesh.mesh:
				continue
			var xform := inverse * mesh.global_transform
			var faces := mesh.mesh.get_faces()
			for index in faces.size():
				faces[index] = xform * faces[index]
			var shape := ConcavePolygonShape3D.new()
			shape.set_faces(faces)
			# La toile d'une bannière n'a qu'une face : elle arrête aussi le joueur qui vient de derrière.
			shape.backface_collision = true
			var holder := CollisionShape3D.new()
			holder.shape = shape
			body.add_child(holder)


## Modèle du kit auquel appartient un maillage : l'enfant du nœud Models qui le contient.
func _model_of(node: Node) -> Node:
	while node.get_parent() and node.get_parent().name != &"Models":
		node = node.get_parent()
	return node


## Regroupe les maillages fixes des ruines, modèles du kit et formes simples, par matériau et par case de 32 m :
## quelques dizaines d'appels de dessin au lieu de plusieurs centaines, ombres comprises. Les petits objets forment
## des groupes à part, sans ombre, qui s'effacent au loin case par case. Les MultiMesh restent tels quels.
func _merge_static(root: Node3D) -> void:
	var tools := {}
	var materials := {}
	var sources: Array[MeshInstance3D] = []
	var inverse := root.global_transform.affine_inverse()
	for mesh: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if not mesh.mesh or not mesh.visible:
			continue
		var xform := inverse * mesh.global_transform
		if xform.basis.determinant() <= 0.0:
			continue
		var box := mesh.global_transform * mesh.get_aabb()
		var small := maxf(box.size.x, maxf(box.size.y, box.size.z)) < SMALL_PROP_SIZE
		var center := box.get_center()
		var cell := Vector2i(floori(center.x / MERGE_CHUNK), floori(center.z / MERGE_CHUNK))
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface)
			if not material:
				continue
			var key := "%d_%d_%d_%d" % [material.get_instance_id(), cell.x, cell.y, int(small)]
			if not tools.has(key):
				var tool := SurfaceTool.new()
				tool.begin(Mesh.PRIMITIVE_TRIANGLES)
				tools[key] = tool
				materials[key] = [material, small]
			(tools[key] as SurfaceTool).append_from(mesh.mesh, surface, xform)
		sources.append(mesh)
	var merged := Node3D.new()
	merged.name = "Merged"
	root.add_child(merged)
	for key: String in tools:
		var instance := MeshInstance3D.new()
		instance.mesh = (tools[key] as SurfaceTool).commit()
		instance.material_override = materials[key][0]
		if materials[key][1]:
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			instance.visibility_range_end = SMALL_PROP_RANGE
			instance.visibility_range_end_margin = 10.0
			instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		merged.add_child(instance)
	for mesh in sources:
		mesh.queue_free()


## Les petits modèles des ruines (jarres, crânes, bols) disparaissent en fondu au loin : moins de dessin pour le web.
func _fade_small_props(root: Node) -> void:
	for mesh: GeometryInstance3D in root.find_children("*", "GeometryInstance3D", true, false):
		if mesh.visibility_range_end > 0.0:
			continue
		var box: AABB = mesh.get_aabb() if mesh is VisualInstance3D else AABB()
		var size := (mesh.global_transform.basis * box.size).abs()
		if maxf(size.x, maxf(size.y, size.z)) < SMALL_PROP_SIZE:
			mesh.visibility_range_end = SMALL_PROP_RANGE
			mesh.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF


## Allume les six emplacements de la table ronde.
func _light_slots(color: Color, energy: float) -> void:
	_slot_material.emission = color
	_slot_material.emission_energy_multiplier = energy


## Secousse de la caméra : forte et brève à l'erreur, longue et sourde à la réussite.
func _shake(duration: float, strength: float) -> void:
	var pivot := _player.get_node("CameraPivot") as Node3D
	if _shake_tween:
		_shake_tween.kill()
		pivot.position = _shake_rest
	_shake_rest = pivot.position
	_shake_strength = strength
	_shake_tween = create_tween()
	_shake_tween.tween_method(_shake_step.bind(pivot), 0.0, 1.0, duration)
	_shake_tween.tween_callback(_shake_step.bind(1.0, pivot))


func _shake_step(progress: float, pivot: Node3D) -> void:
	var amount := _shake_strength * (1.0 - progress)
	pivot.position = _shake_rest + Vector3(randf_range(-amount, amount), randf_range(-amount, amount) * 0.6, randf_range(-amount, amount))
	pivot.rotation.z = randf_range(-amount, amount) * 0.25


## Poussière en suspension dans la cave, qui flotte lentement dans la lumière des torches.
func _create_dust() -> CPUParticles3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	var quad := QuadMesh.new()
	quad.size = Vector2(0.035, 0.035)
	quad.material = material
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.95, 0.82, 0.6, 0.0))
	gradient.set_color(1, Color(0.95, 0.82, 0.6, 0.0))
	gradient.add_point(0.3, Color(0.95, 0.85, 0.65, 0.3))
	gradient.add_point(0.7, Color(0.95, 0.85, 0.65, 0.22))
	var dust := CPUParticles3D.new()
	dust.mesh = quad
	dust.amount = 140
	dust.lifetime = 9.0
	dust.preprocess = 9.0
	dust.position = Vector3(0.0, 2.0, -6.0)
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(9.0, 1.8, 5.5)
	dust.direction = Vector3(0.3, 0.2, 0.1)
	dust.spread = 180.0
	dust.gravity = Vector3(0.0, -0.01, 0.0)
	dust.initial_velocity_min = 0.03
	dust.initial_velocity_max = 0.12
	dust.color_ramp = gradient
	dust.emitting = false
	return dust


## Poussière qui tombe en filets des fissures du plafond de la cave.
func _create_falling_dust() -> Node3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	var quad := QuadMesh.new()
	quad.size = Vector2(0.03, 0.05)
	quad.material = material
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.85, 0.72, 0.52, 0.0))
	gradient.set_color(1, Color(0.85, 0.72, 0.52, 0.0))
	gradient.add_point(0.15, Color(0.88, 0.76, 0.56, 0.55))
	gradient.add_point(0.8, Color(0.88, 0.76, 0.56, 0.35))
	var streams := Node3D.new()
	streams.name = "FallingDust"
	for spot: Vector3 in [Vector3(-5.4, 4.05, -3.6), Vector3(5.2, 4.05, -7.8), Vector3(-1.9, 4.05, -9.6), Vector3(7.6, 4.05, -1.2)]:
		var dust := CPUParticles3D.new()
		dust.mesh = quad
		dust.amount = 24
		dust.lifetime = 3.0
		dust.preprocess = 3.0
		dust.position = spot
		dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		dust.emission_box_extents = Vector3(0.18, 0.02, 0.18)
		dust.direction = Vector3.DOWN
		dust.spread = 5.0
		dust.gravity = Vector3(0.0, -0.6, 0.0)
		dust.initial_velocity_min = 0.1
		dust.initial_velocity_max = 0.3
		dust.color_ramp = gradient
		dust.emitting = false
		streams.add_child(dust)
	return streams


## Voiles de sable que le vent pousse au ras des dunes, larges et à peine visibles.
func _create_sand_veil() -> CPUParticles3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	# Une tache douce, plus dense au centre : pas de rectangle aux bords francs qui flotte au-dessus du sable.
	var soft := Gradient.new()
	soft.set_color(0, Color(1, 1, 1, 1))
	soft.set_color(1, Color(1, 1, 1, 0))
	var texture := GradientTexture2D.new()
	texture.gradient = soft
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 64
	texture.height = 64
	material.albedo_texture = texture
	var quad := QuadMesh.new()
	quad.size = Vector2(3.2, 0.7)
	quad.material = material
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.95, 0.8, 0.55, 0.0))
	gradient.set_color(1, Color(0.95, 0.8, 0.55, 0.0))
	gradient.add_point(0.4, Color(0.95, 0.82, 0.58, 0.13))
	gradient.add_point(0.7, Color(0.95, 0.82, 0.58, 0.1))
	var veil := CPUParticles3D.new()
	veil.mesh = quad
	veil.amount = 36
	veil.lifetime = 6.0
	veil.preprocess = 6.0
	veil.local_coords = false
	veil.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	veil.emission_box_extents = Vector3(10.0, 0.3, 26.0)
	veil.direction = Vector3(1.0, 0.0, 0.15)
	veil.spread = 8.0
	veil.gravity = Vector3.ZERO
	veil.initial_velocity_min = 2.0
	veil.initial_velocity_max = 3.6
	veil.color_ramp = gradient
	veil.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return veil


## Rafales de sable qui balaient le sol autour du joueur.
func _create_sandstorm() -> CPUParticles3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	var quad := QuadMesh.new()
	quad.size = Vector2(0.35, 0.04)
	quad.material = material
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.95, 0.8, 0.55, 0.0))
	gradient.set_color(1, Color(0.95, 0.8, 0.55, 0.0))
	gradient.add_point(0.3, Color(0.95, 0.82, 0.58, 0.55))
	gradient.add_point(0.7, Color(0.95, 0.82, 0.58, 0.45))

	var storm := CPUParticles3D.new()
	storm.mesh = quad
	storm.amount = 220
	storm.lifetime = 2.5
	storm.preprocess = 2.5
	storm.local_coords = false
	storm.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	storm.emission_box_extents = Vector3(4.0, 1.5, 22.0)
	storm.direction = Vector3(1.0, 0.05, 0.15)
	storm.spread = 6.0
	storm.gravity = Vector3(0.0, -0.4, 0.0)
	storm.initial_velocity_min = 8.0
	storm.initial_velocity_max = 13.0
	storm.color_ramp = gradient
	return storm


## La grille de la porte de la muraille est relevée dans son logement : le passage est libre, comme sa collision.
func _raise_gate_grille() -> void:
	var grille := $Exterior/Ruins.find_child("gate", true, false) as Node3D
	if grille:
		grille.position.y += 0.62
