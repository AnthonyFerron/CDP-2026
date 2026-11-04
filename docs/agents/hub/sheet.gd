extends SceneTree
## Planche contact : -- <dossier> <sortie.png> <colonnes> [premier] [nombre]
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var dir := DirAccess.open(args[0])
	var files: Array[String] = []
	for file in dir.get_files():
		if file.ends_with(".png"):
			files.append(file)
	files.sort()
	var first := int(args[3]) if args.size() > 3 else 0
	var count := int(args[4]) if args.size() > 4 else files.size()
	files = files.slice(first, first + count)
	var columns := int(args[2])
	var w := 400
	var h := 225
	var rows := ceili(float(files.size()) / columns)
	var sheet := Image.create(columns * w, rows * (h + 18), false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.1, 0.1, 0.1))
	for index in files.size():
		var image := Image.load_from_file(args[0] + "/" + files[index])
		image.convert(Image.FORMAT_RGB8)
		image.resize(w, h)
		sheet.blit_rect(image, Rect2i(0, 0, w, h), Vector2i((index % columns) * w, (index / columns) * (h + 18) + 18))
		print(index, " ", files[index])
	sheet.save_png(args[1])
	quit()
