extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var display: Node = root.get_node("Display")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_F
	key.pressed = true
	Input.parse_input_event(key)
	for i in 20:
		await process_frame
	print("apres F : plein ecran = ", display.is_fullscreen())
	display.toggle_fullscreen()
	for i in 20:
		await process_frame
	print("apres bascule : plein ecran = ", display.is_fullscreen())
	quit()
