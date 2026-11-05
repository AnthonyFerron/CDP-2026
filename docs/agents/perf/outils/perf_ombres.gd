extends SceneTree
## Mesure d'un lieu au point d'arrivée, avec la caméra du joueur : -- <scène res://> <étiquette>
## Temps de chargement, nœuds, lumières, puis appels de dessin (visibles + ombres), objets et primitives
## dans 8 directions (tour complet). Rendu Compatibility, comme le web.
## Copie de captures/outils/perf_web.gd : les appels d'ombre y sont mesurés par différence (ombres éteintes).
const FRAMES := 6


func _initialize() -> void:
	_run.call_deferred()


func frames(count: int) -> void:
	for i in count:
		await process_frame


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var scene: String = args[0]
	var label: String = args[1] if args.size() > 1 else scene.get_file()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var state: Node = root.get_node("GameState")
	state.reset()
	state.intro_done = true
	var start := Time.get_ticks_usec()
	change_scene_to_file(scene)
	await process_frame
	await process_frame
	var load_ms := (Time.get_ticks_usec() - start) / 1000.0
	await frames(90)
	var level: Node = current_scene
	root.get_node("PauseMenu").process_mode = Node.PROCESS_MODE_DISABLED
	paused = false
	var nodes := level.find_children("*", "", true, false).size()
	var lights := level.find_children("*", "Light3D", true, false)
	var shadows := 0
	for l: Light3D in lights:
		if l.shadow_enabled and l.is_visible_in_tree():
			shadows += 1
	var camera := root.get_viewport().get_camera_3d()
	if level.has_node("Player"):
		level.get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	var base_yaw := camera.global_rotation.y
	# Rendu Compatibility : RENDER_INFO_TYPE_SHADOW reste à 0, les passes d'ombre sont comptées avec les appels
	# visibles. Les appels d'ombre sont donc mesurés par différence, ombres allumées puis éteintes, à la même vue.
	var casting: Array[Light3D] = []
	for l: Light3D in lights:
		if l.shadow_enabled and l.is_visible_in_tree():
			casting.append(l)
	var worst := 0
	var worst_shadow := 0
	var worst_obj := 0
	var worst_prim := 0
	var sum := 0
	var sum_visible := 0
	var sum_shadow := 0
	var worst_total_shadow := 0
	for k in 8:
		var r := camera.global_rotation
		r.y = base_yaw + k * TAU / 8.0
		camera.global_rotation = r
		for l in casting:
			l.shadow_enabled = true
		await frames(5)
		var total := 0
		var o := 0
		var p := 0
		var rs := 0
		for i in FRAMES:
			await process_frame
			total += root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
			rs += root.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
			o += root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_OBJECTS_IN_FRAME)
			p += root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)
		total = (total + rs) / FRAMES
		for l in casting:
			l.shadow_enabled = false
		await frames(5)
		var d := 0
		for i in FRAMES:
			await process_frame
			d += root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
		d /= FRAMES
		var s := maxi(total - d, 0)
		for l in casting:
			l.shadow_enabled = true
		sum += total
		sum_visible += d
		sum_shadow += s
		worst_total_shadow = maxi(worst_total_shadow, s)
		if total > worst + worst_shadow:
			worst = d
			worst_shadow = s
			worst_obj = o / FRAMES
			worst_prim = p / FRAMES
	# Part du corps du joueur (invisible à la première personne, mais qui projette son ombre).
	var body := 0
	if level.has_node("Player/Visual"):
		var visual: Node3D = level.get_node("Player/Visual")
		var r0 := camera.global_rotation
		r0.y = base_yaw
		camera.global_rotation = r0
		await frames(5)
		var with_body := 0
		for i in FRAMES:
			await process_frame
			with_body += root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
		visual.visible = false
		await frames(5)
		var without := 0
		for i in FRAMES:
			await process_frame
			without += root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
		visual.visible = true
		body = (with_body - without) / FRAMES
	print("PERFOMBRES %s | corps du joueur %d appels" % [label, body])
	print("PERFOMBRES %s | moyenne %d = %d visibles + %d ombres | pire %d = %d + %d | ombres au pire %d" % [
		label, sum / 8, sum_visible / 8, sum_shadow / 8, worst + worst_shadow, worst, worst_shadow, worst_total_shadow])
	print("PERFWEB %s | chargement %.0f ms | nœuds %d | lumières %d (ombres %d) | appels moyens %d | pire direction : %d appels + %d ombres, %d objets, %d k primitives" % [
		label, load_ms, nodes, lights.size(), shadows, sum / 8, worst, worst_shadow, worst_obj, worst_prim / 1000])
	quit()
