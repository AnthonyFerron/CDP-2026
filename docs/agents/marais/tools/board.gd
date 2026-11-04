extends SceneTree
## Planche avant / après : -- <sortie.png> <avant.png> <après.png> [<avant.png> <après.png> ...]
## Chaque paire forme une ligne : avant à gauche, après à droite, séparés d'un liseré (rouge avant, vert après).
const CELL := Vector2i(640, 360)
const GAP := 8

func _initialize() -> void:
	var args := Array(OS.get_cmdline_user_args()).filter(func(arg: String) -> bool: return not arg.begins_with("--"))
	var rows := (args.size() - 1) / 2
	var board := Image.create(CELL.x * 2 + GAP * 3, rows * (CELL.y + GAP) + GAP, false, Image.FORMAT_RGB8)
	board.fill(Color(0.08, 0.07, 0.06))
	for row in rows:
		for column in 2:
			var image := Image.load_from_file(args[1 + row * 2 + column])
			image.convert(Image.FORMAT_RGB8)
			image.resize(CELL.x, CELL.y, Image.INTERPOLATE_BILINEAR)
			var at := Vector2i(GAP + column * (CELL.x + GAP), GAP + row * (CELL.y + GAP))
			board.fill_rect(Rect2i(at - Vector2i(3, 3), CELL + Vector2i(6, 6)), Color(0.75, 0.2, 0.15) if column == 0 else Color(0.25, 0.7, 0.3))
			board.blit_rect(image, Rect2i(Vector2i.ZERO, CELL), at)
	board.save_png(args[0])
	print("PLANCHE %s" % args[0])
	quit()
