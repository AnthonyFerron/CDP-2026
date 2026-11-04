from pathlib import Path

base = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/scenes/levels/desert")
p = base / "desert.gd"
t = p.read_text(encoding="utf-8")


def rep(old, new, count=1):
    global t
    assert t.count(old) == count, (t.count(old), old[:90])
    t = t.replace(old, new)


rep('''## Zone du Désert : les runes de l'algorithme. Le joueur ramasse des runes dans les ruines et sous
## le sable, puis reconstitue deux algorithmes sur la table ronde de la cave pour libérer l'Algonicon.
## Les sables mouvants ramènent le joueur en lieu sûr.''', '''## Le désert de Pythania : les algorithmes oubliés. Le joueur ramasse des runes dans les salles du monument des
## anciens bâtisseurs, parmi les débris et sous le sable, puis reconstitue deux algorithmes sur la table ronde de
## pierre de la cave pour libérer l'Algonicon. Les sables mouvants ramènent le joueur en lieu sûr.''')
rep('''const SANDSTONE := Color(1.0, 0.8, 0.6)
''', '''const SANDSTONE := Color(1.0, 0.8, 0.6)
## Lumière ambiante dehors et dans la cave, sombre et poussiéreuse.
const AMBIENT_OUTSIDE := 0.45
const AMBIENT_INSIDE := 0.22
## Au-delà de cette distance, les petits modèles des ruines disparaissent en fondu.
const SMALL_PROP_RANGE := 70.0
const SMALL_PROP_SIZE := 1.6
''')
rep('''var _sandstorm: CPUParticles3D
''', '''var _sandstorm: CPUParticles3D
var _dust: CPUParticles3D
var _slot_material: StandardMaterial3D
''')
rep('''@onready var _table_sound: AudioStreamPlayer3D = $Interior/RoundTable/Sound
''', '''@onready var _table_sound: AudioStreamPlayer3D = $Interior/RoundTable/Sound
@onready var _rumble: AudioStreamPlayer3D = $Interior/RoundTable/Rumble
@onready var _chest_lid: Node3D = $Interior/Chest/Lid
''')
rep('''	_tint_stone($Exterior/Ruins)
	_sandstorm = _create_sandstorm()
	_exterior.add_child(_sandstorm)
	_apply_location()
	_hud.show_message("Le Désert")
	if GameState.has_book(BOOK_ID):''', '''	_tint_stone($Exterior/Ruins)
	_fade_small_props($Exterior/Ruins)
	_sandstorm = _create_sandstorm()
	_exterior.add_child(_sandstorm)
	_dust = _create_dust()
	_interior.add_child(_dust)
	var slot := $Interior/RoundTable/Slots.get_child(0) as MeshInstance3D
	_slot_material = slot.mesh.surface_get_material(0)
	_apply_location()
	# Le nom du lieu s'affiche déjà pendant la transition du portail.
	if GameState.has_book(BOOK_ID):''')
rep('''	_sandstorm.emitting = not _inside
''', '''	_sandstorm.emitting = not _inside
	_dust.emitting = _inside
	_environment.ambient_light_energy = AMBIENT_INSIDE if _inside else AMBIENT_OUTSIDE
''')
rep('''	_table_glow.visible = true
	if not correct:
		# Les runes rougissent un instant et le volcan se rapproche de l'éruption.
		GameState.penalize()
		_table_glow.light_color = Color(1.0, 0.15, 0.1)
		_table_sound.stream = reset_sound
		_table_sound.play()
		var flash := create_tween()
		flash.tween_interval(1.2)
		flash.tween_callback(_table_glow.hide)
		return
	_close_panel()
	_table.enabled = false
	_table_glow.light_color = Color(0.4, 0.7, 1.0)
	_table_sound.stream = chimes[2]
	_table_sound.play()
	_hud.show_message("Les runes s'illuminent de bleu. Un grondement : dans un coin, le sable se disperse…")
	var tween := create_tween()
	tween.tween_property(_chest_sand, "scale", Vector3(1.4, 0.02, 1.4), 2.0).set_trans(Tween.TRANS_SINE)
	await tween.finished
	_chest_sand.hide()
	_chest.show()
	var target := _book_target.global_position''', '''	_table_glow.visible = true
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
	var target := _book_target.global_position''')
rep('''func _on_portal_refused() -> void:
	_hud.show_message("Le portail reste éteint : trouvez le livre du Désert.")''', '''func _on_portal_refused() -> void:
	_hud.show_message("Le portail reste éteint : trouvez le livre du désert de Pythania.")''')
rep('''	_hud.show_message("L'Algonicon est à vous. Rapportez-le au château du hub : le portail du Désert s'est rouvert.")''',
    '''	_hud.show_message("L'Algonicon est à vous. Rapportez-le au château : le portail du désert de Pythania s'est rouvert.")''')
rep('''## Teinte les matériaux des modèles en grès, en partageant une copie par matériau d'origine.
func _tint_stone(root: Node) -> void:
	var tinted := {}
	for mesh: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.get_surface_override_material_count():''', '''## Teinte les matériaux des modèles en grès, en partageant une copie par matériau d'origine. Les formes simples
## (nœud Shapes) ont déjà leurs couleurs.
func _tint_stone(root: Node) -> void:
	var tinted := {}
	for mesh: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if mesh.get_parent().name == &"Shapes":
			continue
		for surface in mesh.get_surface_override_material_count():''')
rep('''## Rafales de sable qui balaient le sol autour du joueur.''', '''## Les petits modèles des ruines (jarres, crânes, bols) disparaissent en fondu au loin : moins de dessin pour le web.
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
	var rest := pivot.position
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		var amount := strength * (1.0 - t)
		pivot.position = rest + Vector3(randf_range(-amount, amount), randf_range(-amount, amount) * 0.6, randf_range(-amount, amount))
		pivot.rotation.z = randf_range(-amount, amount) * 0.25, 0.0, 1.0, duration)
	tween.tween_callback(func() -> void:
		pivot.position = rest
		pivot.rotation.z = 0.0)


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
	gradient.add_point(0.3, Color(0.95, 0.85, 0.65, 0.45))
	gradient.add_point(0.7, Color(0.95, 0.85, 0.65, 0.35))
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


## Rafales de sable qui balaient le sol autour du joueur.''')
p.write_text(t, encoding="utf-8", newline="\n")

# Secousse du panneau de la table à l'erreur.
q = base / "rune_puzzle.gd"
t = q.read_text(encoding="utf-8")
rep('''func _flash_wrong() -> void:
	if _flash:
		_flash.kill()
	_set_border(COLOR_WRONG)
	_flash = create_tween()
	_flash.tween_interval(1.2)
	_flash.tween_callback(_set_border.bind(COLOR_IDLE))''', '''func _flash_wrong() -> void:
	if _flash:
		_flash.kill()
	_set_border(COLOR_WRONG)
	_flash = create_tween()
	# Une violente secousse ébranle le panneau, comme la cave.
	_flash.tween_method(func(t: float) -> void:
		var amount := 18.0 * (1.0 - t)
		_root.position = Vector2(randf_range(-amount, amount), randf_range(-amount, amount)), 0.0, 1.0, 0.6)
	_flash.tween_callback(func() -> void: _root.position = Vector2.ZERO)
	_flash.tween_interval(0.6)
	_flash.tween_callback(_set_border.bind(COLOR_IDLE))''')
rep('''"Runes ramassées : %d. D'autres sont cachées dans les ruines et sous le sable."''',
    '''"Runes ramassées : %d. D'autres sont cachées dans les salles du monument, parmi les débris et sous le sable."''')
q.write_text(t, encoding="utf-8", newline="\n")
print("ok")
