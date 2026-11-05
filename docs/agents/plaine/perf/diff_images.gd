extends SceneTree
## Compare deux dossiers de captures : -- <dossier avant> <dossier après> <dossier planches>
## Pour chaque PNG présent des deux côtés : écart moyen (0..255), part des pixels qui changent de plus de 24,
## et une planche avant | après | écart (amplifié ×4), à demi-taille.

func _initialize() -> void:
	var args := PackedStringArray()
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--"):
			args.append(argument)
	var before: String = args[0]
	var after: String = args[1]
	var out: String = args[2]
	DirAccess.make_dir_recursive_absolute(out)
	var files := DirAccess.get_files_at(before)
	for file in files:
		if not file.ends_with(".png") or not FileAccess.file_exists(after + "/" + file):
			continue
		var a := Image.load_from_file(before + "/" + file)
		var b := Image.load_from_file(after + "/" + file)
		if a.get_size() != b.get_size():
			print("DIFF %s : tailles différentes" % file)
			continue
		a.convert(Image.FORMAT_RGB8)
		b.convert(Image.FORMAT_RGB8)
		var w := a.get_width()
		var h := a.get_height()
		var d := Image.create(w, h, false, Image.FORMAT_RGB8)
		var total := 0.0
		var changed := 0
		for y in range(0, h):
			for x in range(0, w):
				var ca := a.get_pixel(x, y)
				var cb := b.get_pixel(x, y)
				var e := (absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)) / 3.0
				total += e
				if e * 255.0 > 24.0:
					changed += 1
				var v := minf(e * 4.0, 1.0)
				d.set_pixel(x, y, Color(v, v * 0.6, v * 0.2))
		print("DIFF %s : écart moyen %.2f, pixels changés %.2f %%" % [file, total / (w * h) * 255.0, 100.0 * changed / (w * h)])
		var sheet := Image.create(w * 3, h, false, Image.FORMAT_RGB8)
		sheet.blit_rect(a, Rect2i(0, 0, w, h), Vector2i(0, 0))
		sheet.blit_rect(b, Rect2i(0, 0, w, h), Vector2i(w, 0))
		sheet.blit_rect(d, Rect2i(0, 0, w, h), Vector2i(w * 2, 0))
		sheet.resize(w * 3 / 2, h / 2)
		sheet.save_png(out + "/" + file)
	quit()
