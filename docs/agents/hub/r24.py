REPLACEMENTS = [
('''const POND_DEPTH := 0.7''', '''const POND_DEPTH := 0.7
## Berge de l'étang, plus courte que celle de la rivière : le jardin reste plat jusqu'à ses haies.
const POND_BANK := 1.5'''),
('''static func carve(natural: float, distance: float, half_width: float, level: float, depth: float) -> float:''',
 '''static func carve(natural: float, distance: float, half_width: float, level: float, depth: float, bank_width := BANK_WIDTH) -> float:'''),
('''	var bank := BANK_WIDTH + minf(0.6 * maxf(natural - 1.0, 0.0), 12.0)''',
 '''	var bank := bank_width + minf(0.6 * maxf(natural - 1.0, 0.0), 12.0)'''),
('''		var area := Rect2(center, Vector2.ZERO).grow(pond.z + BANK_WIDTH + 2.0)''',
 '''		var area := Rect2(center, Vector2.ZERO).grow(pond.z + POND_BANK + 2.0)'''),
('''		heights[vertex] = carve(heights[vertex], nearest[vertex], half_widths[vertex],
			POND_LEVEL if pond else WATER_LEVEL, POND_DEPTH if pond else RIVER_DEPTH)''',
 '''		heights[vertex] = carve(heights[vertex], nearest[vertex], half_widths[vertex],
			POND_LEVEL if pond else WATER_LEVEL, POND_DEPTH if pond else RIVER_DEPTH, POND_BANK if pond else BANK_WIDTH)'''),
('''const PONDS: Array[Vector3] = [Vector3(48.0, -84.5, 3.8)]''', '''const PONDS: Array[Vector3] = [Vector3(47.4, -84.8, 3.2)]'''),
]
