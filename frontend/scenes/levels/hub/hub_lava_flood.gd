extends MeshInstance3D
## Coulée de lave de la fin perdue. Elle déborde des crêtes du nord, au pied du Mont Sam Altan, dévale les
## pentes, file dans les creux (le lit de la rivière d'abord) et s'étale sur le plateau jusqu'à noyer le village.
## Le maillage épouse le sol : ses sommets sont ceux de la grille du terrain, avec la même diagonale. Chaque
## sommet porte l'instant où la lave l'atteint (UV.x) et la hauteur dont elle monte ensuite (UV.y).
## Cet instant vient d'un plus court chemin sur une grille plus lâche : la lave va vite dans les pentes, peine à
## remonter, et un bruit la fait avancer par lobes. Le shader (hub_flood.gdshader) découpe le bord d'après
## l'avancée (progress, en secondes), épaissit la nappe derrière le front et fait rougeoyer sa croûte.

## Points d'où la lave déborde des crêtes du nord (x, z, retard en secondes).
const SOURCES: Array[Vector3] = [Vector3(-40.0, -134.0, 0.6), Vector3(6.0, -138.0, 0.0), Vector3(50.0, -132.0, 0.3)]
## Pas du calcul de l'avancée, en cases du terrain.
const STRIDE := 2
## Niveau de la nappe sur le plateau, une fois remplie, et épaisseur de la coulée dans les pentes.
const LEVEL := 2.2
const MIN_DEPTH := 0.45
## Instant où la lave atteint le feu de camp, au centre du village.
const CENTER_ARRIVAL := 8.5
## Au-delà de cet instant, la lave ne va plus nulle part : ces cases ne sont pas maillées.
const LAST_ARRIVAL := 16.0

var _progress := 0.0


## Construit la coulée sur le terrain, encore invisible (progress à 0).
func build(terrain: HubTerrain, material: Material) -> void:
	var stride := HubTerrain.COLUMNS + 1
	var heights := PackedFloat32Array()
	heights.resize(stride * (HubTerrain.ROWS + 1))
	for row in HubTerrain.ROWS + 1:
		for column in stride:
			heights[row * stride + column] = terrain.surface_height(_x(column), _z(row))
	var arrival := _arrivals(heights)

	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	vertices.resize(heights.size())
	uvs.resize(heights.size())
	normals.resize(heights.size())
	for row in HubTerrain.ROWS + 1:
		for column in stride:
			var index := row * stride + column
			var ground := heights[index]
			vertices[index] = Vector3(_x(column), ground, _z(row))
			uvs[index] = Vector2(arrival[index], clampf(LEVEL - ground, MIN_DEPTH, 5.0))
			normals[index] = Vector3.UP
	var indices := PackedInt32Array()
	for row in HubTerrain.ROWS:
		for column in HubTerrain.COLUMNS:
			var first := row * stride + column
			var corners: Array[int] = [first, first + 1, first + stride, first + stride + 1]
			var earliest := INF
			for corner in corners:
				earliest = minf(earliest, arrival[corner])
			if earliest > LAST_ARRIVAL:
				continue
			# Même découpe que les triangles du terrain : la nappe reste parallèle au sol.
			indices.append_array(PackedInt32Array([corners[0], corners[1], corners[2], corners[1], corners[3], corners[2]]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# La nappe monte jusqu'à 5 m au-dessus du sol : la boîte englobante doit le savoir pour ne pas être écartée.
	array_mesh.custom_aabb = array_mesh.get_aabb().grow(5.0)
	mesh = array_mesh
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	set_progress(0.0)


## Avancée de la coulée, en secondes depuis son débordement.
func set_progress(value: float) -> void:
	_progress = value
	(material_override as ShaderMaterial).set_shader_parameter(&"progress", value)


func get_progress() -> float:
	return _progress


## Instant d'arrivée de la lave à chaque sommet du terrain : plus court chemin sur une grille de STRIDE cases,
## puis interpolé, et mis à l'échelle pour atteindre le village à CENTER_ARRIVAL.
func _arrivals(heights: PackedFloat32Array) -> PackedFloat32Array:
	var stride := HubTerrain.COLUMNS + 1
	var columns := HubTerrain.COLUMNS / STRIDE + 1
	var rows := HubTerrain.ROWS / STRIDE + 1
	var step := HubTerrain.CELL_SIZE * STRIDE
	var lobes := FastNoiseLite.new()
	lobes.seed = 5814
	lobes.frequency = 0.035
	var coarse := PackedFloat32Array()
	var resistance := PackedFloat32Array()
	coarse.resize(columns * rows)
	resistance.resize(columns * rows)
	for row in rows:
		for column in columns:
			var index := row * columns + column
			coarse[index] = heights[row * STRIDE * stride + column * STRIDE]
			var x := _x(column * STRIDE)
			var z := _z(row * STRIDE)
			# Lobes : la lave avance plus vite par endroits ; et elle préfère les creux, comme le lit de la rivière.
			resistance[index] = (0.55 + 0.9 * (lobes.get_noise_2d(x, z) * 0.5 + 0.5)) * (1.0 + clampf(coarse[index], 0.0, 4.0) * 0.12)
	var time := PackedFloat32Array()
	time.resize(columns * rows)
	time.fill(INF)
	var heap := _Heap.new()
	for source in SOURCES:
		var column := clampi(roundi((source.x - HubTerrain.GRID_ORIGIN.x) / step), 0, columns - 1)
		var row := clampi(roundi((source.y - HubTerrain.GRID_ORIGIN.y) / step), 0, rows - 1)
		var index := row * columns + column
		time[index] = 0.0
		heap.push(0.0, index)
	var neighbours: Array[Vector3i] = []
	for dz in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			if dx != 0 or dz != 0:
				neighbours.append(Vector3i(dx, dz, 0))
	while not heap.empty():
		var top := heap.pop()
		var index := int(top.y)
		if top.x > time[index]:
			continue
		var column := index % columns
		var row := index / columns
		for offset in neighbours:
			var next_column := column + offset.x
			var next_row := row + offset.y
			if next_column < 0 or next_row < 0 or next_column >= columns or next_row >= rows:
				continue
			var next := next_row * columns + next_column
			var distance := step * (1.41421 if offset.x != 0 and offset.y != 0 else 1.0)
			var slope := (coarse[next] - coarse[index]) / distance
			# Elle dévale les pentes, et chaque mètre de montée la freine beaucoup.
			var speed := (1.0 + clampf(-slope, 0.0, 1.5) * 0.8) / (1.0 + maxf(slope, 0.0) * 14.0)
			var cost := distance * resistance[next] / speed
			if time[index] + cost < time[next]:
				time[next] = time[index] + cost
				heap.push(time[next], next)

	var center_column := roundi(-HubTerrain.GRID_ORIGIN.x / step)
	var center_row := roundi(-HubTerrain.GRID_ORIGIN.y / step)
	var scale := CENTER_ARRIVAL / maxf(time[center_row * columns + center_column], 0.001)
	var result := PackedFloat32Array()
	result.resize(heights.size())
	for row in HubTerrain.ROWS + 1:
		for column in stride:
			var gx := float(column) / STRIDE
			var gz := float(row) / STRIDE
			var c0 := mini(int(gx), columns - 2)
			var r0 := mini(int(gz), rows - 2)
			var u := gx - c0
			var v := gz - r0
			var first := r0 * columns + c0
			var top_row := lerpf(time[first], time[first + 1], u)
			var bottom_row := lerpf(time[first + columns], time[first + columns + 1], u)
			result[row * stride + column] = lerpf(top_row, bottom_row, v) * scale + _delay(_x(column), _z(row))
	return result


## Retard de la source la plus proche : les crêtes ne débordent pas toutes au même instant.
func _delay(x: float, z: float) -> float:
	var best := INF
	var delay := 0.0
	for source in SOURCES:
		var distance := Vector2(x, z).distance_squared_to(Vector2(source.x, source.y))
		if distance < best:
			best = distance
			delay = source.z
	return delay


func _x(column: int) -> float:
	return HubTerrain.GRID_ORIGIN.x + column * HubTerrain.CELL_SIZE


func _z(row: int) -> float:
	return HubTerrain.GRID_ORIGIN.y + row * HubTerrain.CELL_SIZE


## File de priorité minimale (tas binaire) : (clé, valeur) dans x et y.
class _Heap:
	var _keys := PackedFloat32Array()
	var _values := PackedInt32Array()

	func empty() -> bool:
		return _keys.is_empty()

	func push(key: float, value: int) -> void:
		_keys.append(key)
		_values.append(value)
		var child := _keys.size() - 1
		while child > 0:
			var parent := (child - 1) / 2
			if _keys[parent] <= _keys[child]:
				break
			_swap(parent, child)
			child = parent

	func pop() -> Vector2:
		var top := Vector2(_keys[0], _values[0])
		var last := _keys.size() - 1
		_keys[0] = _keys[last]
		_values[0] = _values[last]
		_keys.resize(last)
		_values.resize(last)
		var parent := 0
		while true:
			var smallest := parent
			for child in [parent * 2 + 1, parent * 2 + 2]:
				if child < last and _keys[child] < _keys[smallest]:
					smallest = child
			if smallest == parent:
				break
			_swap(parent, smallest)
			parent = smallest
		return top

	func _swap(a: int, b: int) -> void:
		var key := _keys[a]
		_keys[a] = _keys[b]
		_keys[b] = key
		var value := _values[a]
		_values[a] = _values[b]
		_values[b] = value
