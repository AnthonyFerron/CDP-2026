extends SceneTree
## Lettres A à Z en TextMesh, pour chaque police : nombre de sommets (0 = lettre perdue).

func _initialize() -> void:
	for path in ["", "res://ui/cinzel_bold.tres", "res://assets/fonts/Lora.ttf"]:
		var line := "%s :" % (path if path else "police par défaut")
		for letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
			var glyph := TextMesh.new()
			if path:
				glyph.font = load(path)
			glyph.text = letter
			glyph.font_size = 64
			glyph.pixel_size = 0.004
			glyph.depth = 0.0
			var arrays := glyph.get_mesh_arrays()
			var count: int = (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() if arrays.size() > 0 and arrays[Mesh.ARRAY_VERTEX] else 0
			line += " %s%d" % [letter, count]
		print(line)
	quit()
