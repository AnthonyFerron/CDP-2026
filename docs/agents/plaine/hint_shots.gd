extends "res://tests/scenes/common_test.gd"
## Captures des trois indices de la Plaine (fenêtre H), pour vérifier que chaque texte tient dans son cadre.
## Usage : -- <dossier> --api=http://127.0.0.1:9/api/v1


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := ""
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--"):
			out = argument
	DirAccess.make_dir_recursive_absolute(out)
	await start_level("res://scenes/levels/plaine/plaine.tscn")
	var hints: Node = root.get_node("Hints")
	hints.revealed.clear()
	for index in 3:
		hints.open()
		for i in 6:
			await process_frame
		var body: Label = hints.get_node("Hint").find_child("Body", true, false)
		check("indice %d : %d lignes, tient dans le cadre (%d visibles)" % [index + 1, body.get_line_count(),
			body.get_visible_line_count()], body.get_line_count() <= body.get_visible_line_count())
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out + "/indice_%d.png" % (index + 1))
		hints.close()
		for i in 3:
			await process_frame
	finish()
