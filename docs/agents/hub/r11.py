REPLACEMENTS = [
('''	for index in reed_models.size():
		_add_multimesh(reed_models[index], reeds[index])
	for index in rock_models.size():
		_add_multimesh(rock_models[index], rocks[index])
	for index in lily_models.size():
		_lilies.append(_add_multimesh(lily_models[index], lilies[index]).multimesh)''',
'''	for index in reed_models.size():
		_add_multimeshes(reed_models[index], reeds[index])
	for index in rock_models.size():
		_add_multimeshes(rock_models[index], rocks[index])
	for index in lily_models.size():
		_lilies.append_array(_add_multimeshes(lily_models[index], lilies[index]))'''),
('''func _add_multimesh(model: PackedScene, transforms: Array) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = _load_mesh(model)''',
'''## Instances d'un modèle par cases de 32 m : chaque case s'efface au loin selon sa propre distance à la caméra.
func _add_multimeshes(model: PackedScene, transforms: Array) -> Array[MultiMesh]:
	var mesh := _load_mesh(model)
	var cells := {}
	for transform: Transform3D in transforms:
		var cell := Vector2i(floori(transform.origin.x / 32.0), floori(transform.origin.z / 32.0))
		if not cells.has(cell):
			cells[cell] = []
		cells[cell].append(transform)
	var result: Array[MultiMesh] = []
	for cell: Vector2i in cells:
		result.append(_add_multimesh(mesh, cells[cell]).multimesh)
	return result


func _add_multimesh(mesh: Mesh, transforms: Array) -> MultiMeshInstance3D:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh'''),
('''	instance.visibility_range_end = detail_range
	instance.visibility_range_fade_mode''', '''	instance.visibility_range_end = detail_range
	instance.visibility_range_end_margin = 10.0
	instance.visibility_range_fade_mode'''),
]
