from pathlib import Path

p = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/scenes/levels/desert/desert_scatter.gd")
t = p.read_text(encoding="utf-8")


def rep(old, new, count=1):
    global t
    assert t.count(old) == count, (t.count(old), old[:90])
    t = t.replace(old, new)


rep('''## Épaves de machines de siège : position (x, z) et cap en degrés.
const WRECKS: Array[Vector3] = [
	Vector3(26.0, 32.0, 40.0), Vector3(-46.0, 14.0, 200.0), Vector3(30.0, -18.0, 120.0), Vector3(-14.0, -38.0, 300.0),
]''', '''## Épaves de machines de siège, sans toit (catapulte, baliste, trébuchet) : position (x, z) et échelle.
## Leur cap est tiré au hasard ; elles sont à moitié ensablées.
const WRECKS: Array[Vector3] = [
	Vector3(26.0, 32.0, 4.4), Vector3(-46.0, 14.0, 4.0), Vector3(30.0, -18.0, 4.2), Vector3(-14.0, -38.0, 3.8),
	Vector3(44.0, -40.0, 4.0), Vector3(-52.0, -6.0, 3.6),
]
## Boîte des épaves à l'échelle 1, dans l'ordre de wreck_models : coin et taille.
const WRECK_BOXES := [
	[Vector3(-0.64, 0.0, -0.87), Vector3(1.68, 0.32, 1.67)],
	[Vector3(-0.91, 0.0, -0.79), Vector3(1.75, 0.51, 1.55)],
	[Vector3(-0.87, 0.0, -1.05), Vector3(1.93, 0.31, 2.1)],
]
## Côté des cases qui découpent les détails épars : la distance de visibilité d'un MultiMesh se mesure jusqu'au
## centre de sa boîte, il en faut un par case pour que rien ne disparaisse sous les pieds loin du centre.
const CHUNK := 32.0''')
rep('''## Épaves de machines de siège, restes de la guerre, posées à des endroits fixes.
func _add_wrecks() -> void:
	var body := StaticBody3D.new()
	add_child(body)
	for index in WRECKS.size():
		var spot := WRECKS[index]
		var model: PackedScene = wreck_models[index % wreck_models.size()]
		var wreck: Node3D = model.instantiate()
		wreck.position = Vector3(spot.x, terrain.footing_height(spot.x, spot.y) - 0.1, spot.y)
		wreck.rotation.y = deg_to_rad(spot.z)
		wreck.scale = Vector3.ONE * 4.5
		add_child(wreck)
		var shape := BoxShape3D.new()
		shape.size = Vector3(6.0, 1.6, 6.0)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position = wreck.position + Vector3.UP * 0.8
		body.add_child(collision)''', '''## Épaves de machines de siège, restes de la guerre, à moitié ensablées à des endroits fixes : chacune a la
## collision de sa boîte, tournée comme elle, et une congère qui la recouvre d'un côté.
func _add_wrecks() -> void:
	var body := StaticBody3D.new()
	add_child(body)
	var sand := StandardMaterial3D.new()
	sand.albedo_color = Color(0.84, 0.64, 0.4)
	sand.roughness = 1.0
	var drift := SphereMesh.new()
	drift.radial_segments = 14
	drift.rings = 7
	drift.material = sand
	for index in WRECKS.size():
		var spot := WRECKS[index]
		var kind := index % wreck_models.size()
		var wreck: Node3D = wreck_models[kind].instantiate()
		var scale_factor := spot.z
		var box: Array = WRECK_BOXES[kind]
		var height: float = box[1].y * scale_factor
		var basis := Basis(Vector3.UP, _rng.randf() * TAU) * Basis(Vector3.RIGHT, _rng.randf_range(-0.05, 0.05))
		var origin := Vector3(spot.x, terrain.footing_height(spot.x, spot.y) - height * 0.45, spot.y)
		wreck.transform = Transform3D(basis.scaled(Vector3.ONE * scale_factor), origin)
		add_child(wreck)
		var shape := BoxShape3D.new()
		shape.size = Vector3(box[1].x, box[1].y, box[1].z) * scale_factor
		var collision := CollisionShape3D.new()
		collision.shape = shape
		var center: Vector3 = (box[0] + box[1] * 0.5) * scale_factor
		collision.transform = Transform3D(basis, origin + basis * center)
		body.add_child(collision)
		# Le sable s'est amassé contre l'épave, du côté du vent.
		var mound := MeshInstance3D.new()
		mound.mesh = drift
		var side := basis * Vector3(box[1].x * 0.3 * scale_factor, 0.0, 0.0)
		mound.transform = Transform3D(basis.scaled(Vector3(box[1].x * 0.45, 0.5 * height, box[1].z * 0.5) * scale_factor), origin + side)
		mound.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mound)''')
rep('''		var instance := _add_multimesh(item[0], transforms)
		instance.visibility_range_end = 55.0''', '''		_add_multimesh(item[0], transforms, 55.0)''')
rep('''		var instance := _add_multimesh(_load_mesh(rock_models[index]), transforms)
		instance.visibility_range_end = 0.0''', '''		_add_multimesh(_load_mesh(rock_models[index]), transforms, 0.0)''')
rep('''func _add_multimesh(mesh: Mesh, transforms: Array[Transform3D]) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()''', '''## Pose des instances en MultiMesh : sans distance de visibilité (rochers des crêtes), un seul pour toute la carte ;
## sinon un par case de CHUNK mètres, chacune avec sa distance mesurée jusqu'à elle et son fondu.
func _add_multimesh(mesh: Mesh, transforms: Array[Transform3D], range_end := -1.0) -> void:
	if range_end < 0.0:
		range_end = detail_range
	if range_end == 0.0:
		_add_multimesh_part(mesh, transforms, 0.0)
		return
	var cells := {}
	for item in transforms:
		var key := Vector2i(floori(item.origin.x / CHUNK), floori(item.origin.z / CHUNK))
		if not cells.has(key):
			cells[key] = []
		cells[key].append(item)
	for key: Vector2i in cells:
		var part: Array[Transform3D] = []
		part.assign(cells[key])
		_add_multimesh_part(mesh, part, range_end)


func _add_multimesh_part(mesh: Mesh, transforms: Array[Transform3D], range_end: float) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()''')
rep('''	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.visibility_range_end = detail_range
	instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(instance)
	return instance''', '''	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	instance.visibility_range_end = range_end
	if range_end > 0.0:
		instance.visibility_range_end_margin = 10.0
		instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	add_child(instance)
	return instance''')
p.write_text(t, encoding="utf-8", newline="\n")
print("ok")
