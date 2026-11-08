extends SceneTree
## Coût du HUD : temps de son _process (CPU), puis temps de rendu d'une image, appels de dessin compris, avec le HUD
## affiché ou caché, seul sur un fond noir (sans 3D, pour isoler le 2D), puis au hub dehors. Voir docs/hud.md.
##
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --audio-driver Dummy --path frontend --resolution 1920x1080 \
##     --script res://tests/scenes/hud_perf.gd -- <étiquette> [sans-hub] --api=http://127.0.0.1:9/api/v1

const N_CALLS := 20000
const N_FRAMES := 240


func _initialize() -> void:
	_run.call_deferred()


func frames(count: int) -> void:
	for i in count:
		await process_frame


func measure(label: String, count := N_FRAMES) -> String:
	var rid := root.get_viewport_rid()
	var cpu := 0.0
	var gpu := 0.0
	var draws := 0
	var canvas_draws := 0
	var start := Time.get_ticks_usec()
	var samples: Array[float] = []
	for i in count:
		await RenderingServer.frame_post_draw
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(rid)
		var sample := RenderingServer.viewport_get_measured_render_time_gpu(rid)
		gpu += sample
		samples.append(sample)
		draws += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		canvas_draws += root.get_render_info(2, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
	var frame := (Time.get_ticks_usec() - start) / 1000.0 / count
	samples.sort()
	return "%s : image %.3f ms, rendu CPU %.3f ms, rendu GPU %.3f ms (médiane %.3f, min %.3f), appels de dessin %.1f (dont 2D %.1f)" % [
		label, frame, cpu / count, gpu / count, samples[count / 2], samples[0], float(draws) / count, float(canvas_draws) / count]


func _run() -> void:
	var tag := ""
	var skip_hub := false
	for argument in OS.get_cmdline_user_args():
		if argument == "sans-hub":
			skip_hub = true
		elif not argument.begins_with("--"):
			tag = argument
	var state: Node = root.get_node("GameState")
	state.reset()
	state.intro_done = true
	state.begin_mission()
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	var lines: Array[String] = []

	# 1. HUD seul, sur fond noir : chronomètre, message, invite.
	var holder := Node.new()
	root.add_child(holder)
	var hud: Node = load("res://scenes/ui/hud.tscn").instantiate()
	holder.add_child(hud)
	await frames(30)
	hud.message_duration = 9999.0
	hud.show_message("Le portail des plaines d'Hexcole vous attend au nord-ouest du village, non loin des ruines du château.")
	hud.set_prompt("Lire : L'école de Codia")
	await frames(30)
	# _process du HUD : le chronomètre qui ne change pas d'une image à l'autre, puis qui change à chaque appel (pire cas).
	var t0 := Time.get_ticks_usec()
	for i in N_CALLS:
		hud._process(0.016)
	var steady := float(Time.get_ticks_usec() - t0) / N_CALLS
	t0 = Time.get_ticks_usec()
	for i in N_CALLS:
		state.time_left = 3000.0 - i
		hud._process(0.016)
	var changing := float(Time.get_ticks_usec() - t0) / N_CALLS
	state.time_left = 3000.0
	lines.append("[%s] _process du HUD : %.2f us par image (chronomètre inchangé), %.2f us (chronomètre changé à chaque appel)" % [tag, steady, changing])
	hud.visible = true
	await frames(20)
	lines.append("[%s] %s" % [tag, await measure("HUD seul, affiché (chronomètre, message, invite)")])
	hud.show_text("Le carnet du caravanier", "Carnet d'un caravanier. Nous menions nos épices et nos étoffes vers Codia quand Vibelandia a déclaré la guerre : les routes du nord sont tombées, il ne restait que la piste du désert de Pythania.")
	await frames(20)
	lines.append("[%s] %s" % [tag, await measure("HUD seul, lecteur ouvert")])
	hud._reader.hide()
	hud.visible = false
	await frames(20)
	lines.append("[%s] %s" % [tag, await measure("HUD seul, caché")])
	holder.queue_free()
	await frames(5)

	# 2. Au hub, dehors.
	if skip_hub:
		for line in lines:
			print(line)
		state.reset()
		quit()
		return
	change_scene_to_file("res://scenes/levels/hub/hub.tscn")
	await frames(120)
	var level := current_scene
	hud = level.get_node("Hud")
	hud.message_duration = 9999.0
	hud.show_message("Le portail des plaines d'Hexcole vous attend au nord-ouest du village, non loin des ruines du château.")
	await frames(60)
	lines.append("[%s] %s" % [tag, await measure("Hub, HUD affiché", 60)])
	hud.visible = false
	await frames(20)
	lines.append("[%s] %s" % [tag, await measure("Hub, HUD caché", 60)])
	hud.visible = true
	await frames(20)
	lines.append("[%s] %s" % [tag, await measure("Hub, HUD affiché (2e mesure)", 60)])
	for line in lines:
		print(line)
	state.reset()
	quit()
