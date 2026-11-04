extends SceneTree
## Planches contact : -- <préfixe de sortie> <colonnes> <largeur d'une vignette> <vignettes par planche> <dossier>
## [filtre] : toutes les images .png du dossier dont le nom commence par le filtre, par ordre de nom, réparties en
## planches numérotées <préfixe>_01.png, <préfixe>_02.png… La liste des noms de chaque planche est écrite à côté.

func _initialize() -> void:
	var args := Array(OS.get_cmdline_user_args()).filter(func(arg: String) -> bool: return not arg.begins_with("--"))
	var prefix: String = args[0]
	var columns := int(args[1])
	var width := int(args[2])
	var per_sheet := int(args[3])
	var folder: String = args[4]
	var filter: String = args[5] if args.size() > 5 else ""
	var files: Array[String] = []
	var names := DirAccess.get_files_at(folder)
	names.sort()
	for name in names:
		if name.ends_with(".png") and name.begins_with(filter):
			files.append(folder.path_join(name))
	var sheets := 0
	var index := 0
	while index < files.size():
		var chunk := files.slice(index, index + per_sheet)
		sheets += 1
		_sheet("%s_%02d.png" % [prefix, sheets], chunk, columns, width)
		index += per_sheet
	print("%d images, %d planches" % [files.size(), sheets])
	quit()


func _sheet(out: String, files: Array[String], columns: int, width: int) -> void:
	var first := Image.load_from_file(files[0])
	var height := int(round(width * float(first.get_height()) / first.get_width()))
	var rows := int(ceil(files.size() / float(columns)))
	var sheet := Image.create(columns * width, rows * height, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.1, 0.1, 0.1))
	var listing := PackedStringArray()
	for index in files.size():
		var image := Image.load_from_file(files[index])
		image.convert(Image.FORMAT_RGB8)
		image.resize(width, height, Image.INTERPOLATE_BILINEAR)
		var at := Vector2i((index % columns) * width, (index / columns) * height)
		sheet.blit_rect(image, Rect2i(0, 0, width, height), at)
		sheet.fill_rect(Rect2i(at.x, at.y, width, 2), Color(0.9, 0.7, 0.2))
		sheet.fill_rect(Rect2i(at.x, at.y, 2, height), Color(0.9, 0.7, 0.2))
		listing.append("%d,%d %s" % [index % columns, index / columns, files[index].get_file()])
	sheet.save_png(out)
	var file := FileAccess.open(out.get_basename() + ".txt", FileAccess.WRITE)
	file.store_string("\n".join(listing))
