extends SceneTree
## Vérifie RenderQuality dans le paquet exporté : -- <dossier des captures> [scène]
## F3 affiche le compteur, F4 fait le tour auto -> 100 % -> 75 % -> 50 % -> auto. Captures à chaque étape.
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func frames(count: int) -> void:
	for i in count:
		await process_frame


func check(label: String, ok: bool) -> void:
	print(("OK     " if ok else "ECHEC  ") + label)
	if not ok:
		_failures += 1


func press(code: Key) -> void:
	for pressed in [true, false]:
		var key := InputEventKey.new()
		key.physical_keycode = code
		key.keycode = code
		key.pressed = pressed
		Input.parse_input_event(key)
		await frames(2)


func shot(out: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out + name + ".png")


func _run() -> void:
	var args := PackedStringArray()
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--"):
			args.append(argument)
	var out := args[0] + "/"
	DirAccess.make_dir_recursive_absolute(out)
	var scene := args[1] if args.size() > 1 else "res://scenes/levels/hub/hub.tscn"
	var state: Node = root.get_node("GameState")
	state.reset()
	state.intro_done = true
	change_scene_to_file(scene)
	await frames(60)
	var quality: CanvasLayer = root.get_node("RenderQuality")
	var label: Label = quality.get_child(0)
	var window := DisplayServer.window_get_size()
	var expected := clampf(sqrt(1920.0 * 1080.0 / maxf(1.0, float(window.x) * float(window.y))), 0.5, 1.0)
	print("fenêtre %d x %d, échelle auto attendue %.3f" % [window.x, window.y, expected])
	check("compteur caché au lancement", not label.visible)
	check("échelle auto (%.3f)" % root.scaling_3d_scale, is_equal_approx(root.scaling_3d_scale, expected))
	check("mise à l'échelle bilinéaire", root.scaling_3d_mode == Viewport.SCALING_3D_MODE_BILINEAR)
	await press(KEY_F3)
	await frames(40)
	check("F3 affiche le compteur", label.visible)
	print("compteur : ", label.text.replace("\n", " / "))
	check("compteur en caractères simples", label.text.is_valid_ascii_identifier() or label.text.to_ascii_buffer().get_string_from_ascii() == label.text)
	await shot(out, "1_auto")
	for step in [[1.0, "2_100"], [0.75, "3_75"], [0.5, "4_50"]]:
		await press(KEY_F4)
		await frames(40)
		check("F4 -> %d %%" % roundi(step[0] * 100.0), is_equal_approx(root.scaling_3d_scale, step[0]))
		print("compteur : ", label.text.replace("\n", " / "))
		await shot(out, step[1])
	await press(KEY_F4)
	await frames(10)
	check("F4 revient en auto", is_equal_approx(root.scaling_3d_scale, expected))
	await press(KEY_F3)
	check("F3 cache le compteur", not label.visible)
	print("RESULTAT verif_rq : %d echec(s)" % _failures)
	state.reset()
	quit()
