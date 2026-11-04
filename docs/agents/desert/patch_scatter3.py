from pathlib import Path

p = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/scenes/levels/desert/desert_scatter.gd")
t = p.read_text(encoding="utf-8")


def rep(old, new, count=1):
    global t
    assert t.count(old) == count, (t.count(old), old[:90])
    t = t.replace(old, new)


rep('''## Habille le Désert : cactus, rochers, colonnes renversées, épaves de guerre et sables mouvants.''',
    '''## Habille le désert de Pythania : quelques cactus, des rochers, des colonnes renversées, des épaves de guerre,
## les restes épars des voyageurs, des ossements de bêtes et des crânes de vautours, et les sables mouvants.''')
rep('''@export var border_rock_count := 44
''', '''@export var border_rock_count := 44
## Crânes de vautours et ossements de bêtes semés dans les dunes.
@export var skull_count := 36
@export var bone_count := 48
''')
rep('''	_add_props()
	_add_border_rocks()''', '''	_add_props()
	_add_bones()
	_add_border_rocks()''')
rep('''func _add_border_rocks() -> void:''', '''## Ossements dans les dunes : des crânes de vautours au bec crochu et des tas d'os de bêtes, sans collision.
func _add_bones() -> void:
	var bone := StandardMaterial3D.new()
	bone.albedo_color = Color(0.9, 0.86, 0.74)
	bone.roughness = 0.85
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.02, 0.015, 0.01)
	var sphere := SphereMesh.new()
	sphere.radial_segments = 10
	sphere.rings = 5
	var skull := _compose([
		[sphere, Transform3D(Basis().scaled(Vector3(0.1, 0.085, 0.12)), Vector3(0.0, 0.09, 0.0))],
		[_cone(0.012, 0.045, 0.2, 5), Transform3D(Basis(Vector3.RIGHT, deg_to_rad(100.0)), Vector3(0.0, 0.08, 0.17))],
		[_cone(0.006, 0.018, 0.07, 4), Transform3D(Basis(Vector3.RIGHT, deg_to_rad(170.0)), Vector3(0.0, 0.045, 0.265))],
	], bone)
	_compose([
		[sphere, Transform3D(Basis().scaled(Vector3.ONE * 0.03), Vector3(0.085, 0.12, 0.06))],
		[sphere, Transform3D(Basis().scaled(Vector3.ONE * 0.03), Vector3(-0.085, 0.12, 0.06))],
	], dark, skull)
	var long_bone := _cone(0.035, 0.035, 0.85, 6)
	var bones := _compose([
		[long_bone, Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(0.0, 0.035, 0.0))],
		[long_bone, Transform3D(Basis(Vector3.UP, 0.7) * Basis(Vector3.FORWARD, PI * 0.5), Vector3(0.1, 0.1, 0.12))],
		[long_bone, Transform3D(Basis(Vector3.UP, -1.1) * Basis(Vector3.FORWARD, PI * 0.5), Vector3(-0.2, 0.035, 0.25))],
		[_cone(0.07, 0.09, 0.12, 6), Transform3D(Basis(), Vector3(0.3, 0.06, -0.2))],
		[_cone(0.07, 0.09, 0.12, 6), Transform3D(Basis(Vector3.RIGHT, 1.2), Vector3(0.45, 0.07, -0.05))],
	], bone)
	for item: Array in [[skull, skull_count, 1.4, 1.9], [bones, bone_count, 0.9, 1.4]]:
		var transforms: Array[Transform3D] = []
		for attempt in item[1] * 12:
			if transforms.size() >= item[1]:
				break
			var spot := Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * (DesertTerrain.PLAY_RADIUS - 3.0)
			if not is_free(spot, 0.2):
				continue
			var basis := Basis(Vector3.UP, _rng.randf() * TAU) * Basis(Vector3.RIGHT, _rng.randf_range(-0.2, 0.2))
			var origin := Vector3(spot.x, terrain.footing_height(spot.x, spot.y) - 0.03, spot.y)
			transforms.append(Transform3D(basis.scaled(Vector3.ONE * _rng.randf_range(item[2], item[3])), origin))
		var instance := _add_multimesh(item[0], transforms)
		instance.visibility_range_end = 55.0


func _cone(top: float, bottom: float, height: float, segments: int) -> CylinderMesh:
	var cone := CylinderMesh.new()
	cone.top_radius = top
	cone.bottom_radius = bottom
	cone.height = height
	cone.radial_segments = segments
	cone.rings = 1
	return cone


## Fond des maillages simples, chacun à sa place, en une surface d'un seul matériau, ajoutée à mesh s'il est donné.
func _compose(parts: Array, material: Material, mesh: ArrayMesh = null) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for part: Array in parts:
		tool.append_from(part[0], 0, part[1])
	var result := tool.commit(mesh)
	result.surface_set_material(result.get_surface_count() - 1, material)
	return result


func _add_border_rocks() -> void:''')
p.write_text(t, encoding="utf-8", newline="\n")
print("ok")
