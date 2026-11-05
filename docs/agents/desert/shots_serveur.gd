extends SceneTree
## Captures du désert depuis des caméras libres (dérivé de tests/scenes/cam_shots.gd) :
##   -- <scène> <dossier> <nom>=x,y,z:cible ...
## - y en « +h » : h mètres au-dessus du sol maillé (Exterior/Terrain) ;
## - cible : « x,y,z » (y en « +h » possible) ou « @Chemin/Du/Noeud[+dy] » (position du nœud, plus dy) ;
## - « wait=N » attend N images ; « set=Chemin:propriété:valeur » règle un nombre ; « inside », « noshadow ».
## Les arguments en « -- » (comme --api=…) sont ignorés.

var level: Node
var terrain: Node


func _initialize() -> void:
	_run.call_deferred()


func frames(count: int) -> void:
	for i in count:
		await process_frame


func ground(x: float, z: float) -> float:
	return terrain.surface_height(x, z) if terrain else 0.0


func point(text: String) -> Vector3:
	if text.begins_with("@"):
		var spec := text.substr(1)
		var dy := 0.0
		if "+" in spec:
			dy = float(spec.get_slice("+", 1))
			spec = spec.get_slice("+", 0)
		return (level.get_node(spec) as Node3D).global_position + Vector3.UP * dy
	var p := text.split(",")
	var x := float(p[0])
	var z := float(p[2])
	var y := ground(x, z) + float(p[1].substr(1)) if p[1].begins_with("+") else float(p[1])
	return Vector3(x, y, z)


func _run() -> void:
	var args := PackedStringArray()
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--"):
			args.append(argument)
	var out := args[1] + "/"
	DirAccess.make_dir_recursive_absolute(out)
	var state: Node = root.get_node("GameState")
	state.reset()
	state.intro_done = true
	change_scene_to_file(args[0])
	await frames(30)
	level = current_scene
	terrain = level.get_node_or_null("Exterior/Terrain")
	if level.has_node("Hud"):
		level.get_node("Hud").visible = false
	if level.has_node("Player"):
		level.get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	var camera := Camera3D.new()
	camera.fov = 75.0
	camera.far = 500.0
	level.add_child(camera)
	camera.current = true
	for entry in args.slice(2):
		if entry == "noshadow":
			level.get_node("Sun").shadow_enabled = false
			await frames(4)
			continue
		if entry == "inside":
			level.set("_inside", true)
			level.call("_apply_location")
			await frames(4)
			continue
		if entry.begins_with("fov="):
			camera.fov = float(entry.substr(4))
			continue
		if entry.begins_with("wait="):
			await frames(int(entry.substr(5)))
			continue
		if entry.begins_with("set="):
			var pieces := entry.substr(4).split(":")
			var holder := level.get_node_or_null(pieces[0])
			if holder:
				holder.set(pieces[1], float(pieces[2]))
			await frames(2)
			continue
		var name := entry.get_slice("=", 0)
		var spec := entry.get_slice("=", 1)
		var parts := spec.split(":")
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		if parts.size() > 2:
			camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			camera.size = float(parts[2])
		camera.global_position = point(parts[0])
		var target := point(parts[1])
		var up := Vector3.FORWARD if absf((target - camera.global_position).normalized().y) > 0.99 else Vector3.UP
		camera.look_at(target, up)
		await frames(8)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out + name + ".png")
		print("CAPTURE %s depuis %s vers %s" % [name, camera.global_position.snappedf(0.1), target.snappedf(0.1)])
	for path in ["Exterior/Whirlwinds", "Exterior/Mirages/GhostCaravan"]:
		var group := level.get_node_or_null(path)
		if group:
			for child in group.get_children():
				if child is Node3D:
					print("POSITION %s/%s %s" % [path, child.name, (child as Node3D).global_position.snappedf(0.1)])
	state.reset()
	quit()
