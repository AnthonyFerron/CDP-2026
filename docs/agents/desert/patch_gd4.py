from pathlib import Path

p = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/scenes/levels/desert/desert.gd")
t = p.read_text(encoding="utf-8")


def rep(old, new, count=1):
    global t
    assert t.count(old) == count, (t.count(old), old[:90])
    t = t.replace(old, new)


rep('''const AMBIENT_OUTSIDE := 0.45''', '''const AMBIENT_OUTSIDE := 0.36''')
rep('''var _sandstorm: CPUParticles3D
''', '''var _sandstorm: CPUParticles3D
var _sand_veil: CPUParticles3D
''')
rep('''	_sandstorm = _create_sandstorm()
	_exterior.add_child(_sandstorm)
	_dust = _create_dust()
	_interior.add_child(_dust)''', '''	_sandstorm = _create_sandstorm()
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
	_cave_sound.finished.connect(_cave_sound.play)''')
rep('''	_sandstorm.global_position = _player.global_position + Vector3(-12.0, 1.5, 0.0)''', '''	_sandstorm.global_position = _player.global_position + Vector3(-12.0, 1.5, 0.0)
	_sand_veil.global_position = _player.global_position + Vector3(-10.0, 0.5, 0.0)''')
rep('''	_sandstorm.emitting = not _inside
''', '''	_sandstorm.emitting = not _inside
	_sand_veil.emitting = not _inside
''')
rep('''## Rafales de sable qui balaient le sol autour du joueur.''', '''## Poussière qui tombe en filets des fissures du plafond de la cave.
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


## Rafales de sable qui balaient le sol autour du joueur.''')
rep('''	_dust.emitting = _inside
''', '''	_dust.emitting = _inside
	for stream: CPUParticles3D in _interior.get_node("FallingDust").get_children():
		stream.emitting = _inside
''')
p.write_text(t, encoding="utf-8", newline="\n")
print("ok")
