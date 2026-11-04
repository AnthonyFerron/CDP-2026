REPLACEMENTS = [
('''@export var detail_range := 70.0
''', '''@export var detail_range := 70.0
## Côté des cases de la grille qui découpe les petits détails : chaque case a son propre MultiMesh, et sa propre
## distance de visibilité, mesurée jusqu'à elle et non jusqu'au milieu de la carte.
@export var chunk_size := 32.0
'''),
('''		multimeshes.append(_add_multimesh(_load_mesh(models[index]), transforms, body != null).multimesh)
	return multimeshes''', '''		multimeshes.append_array(_add_multimeshes(_load_mesh(models[index]), transforms, body != null))
	return multimeshes'''),
('''func _add_multimesh(mesh: Mesh, transforms: Array[Transform3D], always_visible: bool) -> MultiMeshInstance3D:''',
'''## Place les instances d'un modèle : d'un seul MultiMesh s'il reste toujours visible (arbres, rochers), sinon par
## cases de chunk_size mètres, chacune effacée au loin selon sa propre distance à la caméra. Renvoie les MultiMesh.
func _add_multimeshes(mesh: Mesh, transforms: Array[Transform3D], always_visible: bool) -> Array[MultiMesh]:
	var result: Array[MultiMesh] = []
	if always_visible:
		result.append(_add_multimesh(mesh, transforms, true).multimesh)
		return result
	var cells := {}
	for transform in transforms:
		var cell := Vector2i(floori(transform.origin.x / chunk_size), floori(transform.origin.z / chunk_size))
		if not cells.has(cell):
			cells[cell] = [] as Array[Transform3D]
		cells[cell].append(transform)
	for cell: Vector2i in cells:
		result.append(_add_multimesh(mesh, cells[cell], false).multimesh)
	return result


func _add_multimesh(mesh: Mesh, transforms: Array[Transform3D], always_visible: bool) -> MultiMeshInstance3D:'''),
('''		instance.visibility_range_end = detail_range
		instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF''',
'''		instance.visibility_range_end = detail_range
		instance.visibility_range_end_margin = 10.0
		instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF'''),
]
