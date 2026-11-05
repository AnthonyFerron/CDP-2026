extends SceneTree
## Mesure des performances de la Plaine (copie adaptée de docs/agents/marais/tools/perf_views.gd) en quelques vues fixes : -- <étiquette> <dossier> [vue ...]
## vue : nom=x,y,z:tx,ty,tz (dehors) ou nom=in:x,y,z:tx,ty,tz (crypte). Compte les nœuds, maillages, MultiMesh,
## lumières (et ombres) ; par vue : appels de dessin (visibles et ombres), objets, primitives, lumières allumées,
## temps d'image (médiane, moyenne, 95e centile) sur 150 images, et une capture.
const DEFAULT_VIEWS := [
	"o1_arrivee=0,1.7,54:0,1.5,30",
	"o2_pont=-2,1.7,38:4,1,20",
	"o3_facade=3,1.7,18:-2,2,6",
	"o4_camp=4,1.7,47:16,1,42",
	"o5_siege=-6,1.7,44:-16,1,38",
	"o6_batterie=12,1.7,-12:17,1,-22",
	"o7_haut=0,45,75:0,0,5",
	"i1_lecture=in:0,-38.35,-1.5:0,-38.6,-12",
	"i2_scriptorium=in:-3.5,-38.35,-13.5:2,-39,-22",
	"i3_archives=in:3.5,-38.35,-25.5:0,-39,-33",
]
const FRAMES := 30


func _initialize() -> void:
	_run.call_deferred()


func frames(count: int) -> void:
	for i in count:
		await process_frame


func vec(text: String) -> Vector3:
	var p := text.split(",")
	return Vector3(float(p[0]), float(p[1]), float(p[2]))


func _run() -> void:
	var args := PackedStringArray()
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--"):
			args.append(argument)
	var label: String = args[0] if args.size() > 0 else "mesure"
	var out: String = (args[1] if args.size() > 1 else "/tmp/perf") + "/"
	DirAccess.make_dir_recursive_absolute(out)
	var views: Array = Array(args.slice(2)) if args.size() > 2 else DEFAULT_VIEWS
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var state: Node = root.get_node("GameState")
	state.reset()
	state.intro_done = true
	var start := Time.get_ticks_usec()
	change_scene_to_file("res://scenes/levels/plaine/plaine.tscn")
	await process_frame
	await process_frame
	var load_ms := (Time.get_ticks_usec() - start) / 1000.0
	await frames(60)
	var level: Node = current_scene
	root.get_node("PauseMenu").process_mode = Node.PROCESS_MODE_DISABLED
	paused = false
	if level.has_node("Hud"):
		level.get_node("Hud").visible = false
	var player: Node3D = level.get_node("Player")
	player.process_mode = Node.PROCESS_MODE_DISABLED
	print("PERF %s chargement %.0f ms" % [label, load_ms])
	_count(level, label)
	var camera := Camera3D.new()
	camera.fov = 75.0
	level.add_child(camera)
	camera.current = true
	var inside := false
	for entry: String in views:
		var name := entry.split("=")[0]
		var spec := entry.split("=")[1]
		var want_inside := spec.begins_with("in:")
		if want_inside:
			spec = spec.substr(3)
		if want_inside != inside:
			inside = want_inside
			level.set("_inside", inside)
			level.call("_apply_location")
			await frames(10)
		var parts := spec.split(":")
		camera.global_position = vec(parts[0])
		camera.look_at(vec(parts[1]), Vector3.UP)
		# Le joueur sous la caméra : lucioles et brume qui le suivent.
		player.global_position = Vector3(camera.global_position.x, camera.global_position.y - 2.0, camera.global_position.z)
		await frames(15)
		var times: Array[float] = []
		var draws := 0
		var shadow_draws := 0
		var objects := 0
		var primitives := 0
		var vp := root
		for i in FRAMES:
			var t := Time.get_ticks_usec()
			await process_frame
			times.append((Time.get_ticks_usec() - t) / 1000.0)
			draws += vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
			shadow_draws += vp.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
			objects += vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_OBJECTS_IN_FRAME)
			primitives += vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)
		var total := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		var sorted := times.duplicate()
		sorted.sort()
		var mean := 0.0
		for v in times:
			mean += v
		mean /= times.size()
		var lit := 0
		for light: Light3D in level.find_children("*", "Light3D", true, false):
			if light.is_visible_in_tree() and light is OmniLight3D:
				var reach: float = light.omni_range
				if light.global_position.distance_to(camera.global_position) < reach + 30.0:
					lit += 1
		print("PERF %s vue %s : image médiane %.1f ms, moyenne %.1f ms, 95 %% %.1f ms ; appels de dessin %d (+ ombres %d, total moniteur %d) ; objets %d ; primitives %d ; lumières ponctuelles proches %d" % [
			label, name, sorted[sorted.size() / 2], mean, sorted[int(sorted.size() * 0.95)], draws / FRAMES,
			shadow_draws / FRAMES, total, objects / FRAMES, primitives / FRAMES, lit])
		print("PERF %s vue %s répartition : %s" % [label, name, _breakdown(level, camera)])
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out + name + ".png")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--shots="):
			var shots_file := argument.substr(8)
			await _shots(level, camera, player, out + shots_file.get_file().get_basename() + "/",
				FileAccess.get_file_as_string(shots_file).split("\n", false))
	state.reset()
	quit()


func _shots(level: Node, camera: Camera3D, player: Node3D, out: String, entries: PackedStringArray) -> void:
	DirAccess.make_dir_recursive_absolute(out)
	player.visible = false
	var inside: bool = level.get("_inside")
	for entry: String in entries:
		entry = entry.strip_edges()
		if entry.is_empty():
			continue
		if entry == "freeze":
			# Particules (cendres, poussière, feux, fumées) cachées, bougies sans scintillement, corbeaux et
			# bannières arrêtés : seul le décor fixe reste à comparer (la lave suit le temps de son shader).
			for node in level.find_children("*", "GeometryInstance3D", true, false):
				if node is CPUParticles3D or node is GPUParticles3D:
					node.visible = false
			for node in level.find_children("*", "Light3D", true, false):
				if "flicker" in node:
					node.set("flicker", 0.0)
			level.get_node("Exterior/Life").visible = false
			level.get_node("Exterior/Life").process_mode = Node.PROCESS_MODE_DISABLED
			level.set_process(false)
			Engine.time_scale = 0.0
			continue
		var name := entry.split("=")[0]
		var spec := entry.split("=")[1]
		var want_inside := spec.begins_with("in:")
		if want_inside:
			spec = spec.substr(3)
		if want_inside != inside:
			inside = want_inside
			level.set("_inside", inside)
			level.call("_apply_location")
			await frames(4)
		var parts := spec.split(":")
		camera.global_position = vec(parts[0])
		camera.look_at(vec(parts[1]), Vector3.UP)
		player.global_position = camera.global_position - Vector3.UP * 1.65
		await frames(5)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out + name + ".png")
	Engine.time_scale = 1.0


## Surfaces visibles dans le champ de la caméra, par branche du niveau (estimation des appels de dessin).
func _breakdown(level: Node, camera: Camera3D) -> String:
	var planes := camera.get_frustum()
	var counts := {}
	for node in level.find_children("*", "GeometryInstance3D", true, false):
		var item := node as GeometryInstance3D
		if not item.is_visible_in_tree():
			continue
		var box := item.global_transform * item.get_aabb()
		var inside := true
		for plane in planes:
			var corner := Vector3(box.end.x if plane.normal.x < 0 else box.position.x,
				box.end.y if plane.normal.y < 0 else box.position.y, box.end.z if plane.normal.z < 0 else box.position.z)
			if plane.is_point_over(corner):
				inside = false
				break
		if not inside:
			continue
		if item.visibility_range_end > 0.0 and camera.global_position.distance_to(box.get_center()) > item.visibility_range_end + item.visibility_range_end_margin:
			continue
		var surfaces := 1
		if item is MeshInstance3D and (item as MeshInstance3D).mesh:
			surfaces = (item as MeshInstance3D).mesh.get_surface_count()
		elif item is MultiMeshInstance3D and (item as MultiMeshInstance3D).multimesh and (item as MultiMeshInstance3D).multimesh.mesh:
			surfaces = (item as MultiMeshInstance3D).multimesh.mesh.get_surface_count()
		var path := String(level.get_path_to(item)).split("/")
		var branch := path[0] if path.size() < 2 or path[0] not in ["Exterior", "Interior"] else path[0] + "/" + path[1]
		counts[branch] = counts.get(branch, 0) + surfaces
	var keys := counts.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return counts[a] > counts[b])
	var parts: PackedStringArray = []
	for key: String in keys.slice(0, 10):
		parts.append("%s %d" % [key, counts[key]])
	return ", ".join(parts)


func _count(level: Node, label: String) -> void:
	var nodes := 0
	var meshes := 0
	var shadow_meshes := 0
	var multimeshes := 0
	var instances := 0
	var lights := 0
	var shadow_lights := 0
	var fading_lights := 0
	var particles := 0
	var bodies := 0
	var shapes := 0
	var ranged := 0
	for node in level.find_children("*", "", true, false):
		nodes += 1
		if node is GeometryInstance3D and (node as GeometryInstance3D).visibility_range_end > 0.0:
			ranged += 1
		if node is MeshInstance3D:
			if node.mesh:
				meshes += 1
				if node.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
					shadow_meshes += 1
		elif node is MultiMeshInstance3D and node.multimesh:
			multimeshes += 1
			instances += node.multimesh.instance_count
			if node.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				shadow_meshes += 1
		elif node is Light3D:
			lights += 1
			if node.shadow_enabled:
				shadow_lights += 1
			if node.distance_fade_enabled:
				fading_lights += 1
		elif node is CPUParticles3D or node is GPUParticles3D:
			particles += 1
		elif node is CollisionObject3D:
			bodies += 1
		elif node is CollisionShape3D:
			shapes += 1
	print("PERF %s nœuds %d, maillages %d, MultiMesh %d (%d instances), qui projettent une ombre %d, lumières %d (ombres %d, effacées au loin %d), particules %d, corps %d, formes %d, à distance de visibilité %d" % [
		label, nodes, meshes, multimeshes, instances, shadow_meshes, lights, shadow_lights, fading_lights, particles, bodies, shapes, ranged])
