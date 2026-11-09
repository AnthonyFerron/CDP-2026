extends SceneTree
## Outil de la mine refaite le 8 novembre (hub-mine). Depuis frontend, sous xvfb-run :
## godot --path . --resolution 1280x720 --audio-driver Dummy --script <chemin>/mine_shots.gd -- <dossier absolu> [books=N]
##   [boxes] <vues...> --api=http://127.0.0.1:9/api/v1 ; boxes montre en rouge les collisions à moins de 18 m de la mine.
## Captures et appels de dessin autour de la mine du Hub, dehors, une fois le décor regroupé :
##   -- <dossier absolu> [books=N] [frames=N] <nom>=x,h,z:cx,cy,cz[:ortho] ...
## La hauteur h de l'œil est prise au-dessus du sol (HubTerrain.surface_height) ; la cible est absolue.
## Pour chaque vue : appels de dessin (visibles + ombres), objets, primitives, et une capture PNG.
const ALL: Array[StringName] = [&"projenomicon", &"algonicon", &"logiconomicon", &"codonomicon"]
const WARMUP := 6

var frames_per_view := 3


func _initialize() -> void:
	_run.call_deferred()


func frames(count: int) -> void:
	for i in count:
		await process_frame


func _vec(text: String) -> Vector3:
	var v := text.split(",")
	return Vector3(float(v[0]), float(v[1]), float(v[2]))


func _run() -> void:
	var args := PackedStringArray()
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--"):
			args.append(argument)
	var out: String = args[0]
	var books := 0
	var boxes := false
	var views: Array[String] = []
	for arg in args.slice(1):
		if arg.begins_with("books="):
			books = int(arg.substr(6))
		elif arg == "boxes":
			boxes = true
		elif arg.begins_with("frames="):
			frames_per_view = int(arg.substr(7))
		else:
			views.append(arg)
	DirAccess.make_dir_recursive_absolute(out)
	var state: Node = root.get_node("GameState")
	state.reset()
	state.intro_done = true
	for index in books:
		state.books.append(ALL[index])
		state.placed_books.append(ALL[index])
	change_scene_to_file("res://scenes/levels/hub/hub.tscn")
	await frames(2)
	var level: Node = current_scene
	var props: Node = level.get_node_or_null("Props")
	while props and props.has_method("is_done") and not props.is_done():
		await process_frame
	await frames(30)
	level.get_node("Hud").visible = false
	level.get_node("Player").process_mode = Node.PROCESS_MODE_DISABLED
	if root.has_node("PauseMenu"):
		root.get_node("PauseMenu").process_mode = Node.PROCESS_MODE_DISABLED
		for child in root.get_node("PauseMenu").get_children():
			if child is CanvasItem or child is CanvasLayer:
				child.visible = false
	paused = false
	level.call("_set_location", false)
	var terrain: Node = level.get_node("Terrain")
	if boxes:
		_show_boxes(level, Vector3(82.6, 0.0, -39.6), 18.0)
	var camera := Camera3D.new()
	camera.fov = 75.0
	camera.far = 500.0
	level.add_child(camera)
	camera.current = true
	for view in views:
		var name := view.split("=")[0]
		var spec := view.split("=")[1].split(":")
		var eye := _vec(spec[0])
		eye.y += terrain.surface_height(eye.x, eye.z)
		var target := _vec(spec[1])
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		if spec.size() > 2:
			camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			camera.size = float(spec[2])
		camera.global_position = eye
		var up := Vector3.FORWARD if absf((target - eye).normalized().y) > 0.99 else Vector3.UP
		camera.look_at(target, up)
		await frames(WARMUP)
		var d := 0
		var o := 0
		var p := 0
		for i in frames_per_view:
			await process_frame
			d += root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
			d += root.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
			o += root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_OBJECTS_IN_FRAME)
			p += root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)
		print("MINESHOT %s | %d appels, %d objets, %d k primitives" % [name, d / frames_per_view, o / frames_per_view, p / frames_per_view / 1000])
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join(name + ".png"))
	state.reset()
	quit()


## Montre en rouge translucide chaque boîte de collision à moins de radius du point center (la mine).
func _show_boxes(level: Node, center: Vector3, radius: float) -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1.0, 0.1, 0.1, 0.35)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var count := 0
	for shape: CollisionShape3D in level.find_children("*", "CollisionShape3D", true, false):
		if not shape.shape is BoxShape3D:
			continue
		var at := shape.global_position
		if Vector2(at.x - center.x, at.z - center.z).length() > radius or at.y < -20.0:
			continue
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = (shape.shape as BoxShape3D).size
		mesh.mesh = box
		mesh.material_override = material
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		level.add_child(mesh)
		mesh.global_transform = shape.global_transform
		count += 1
	print("MINESHOT %d boîtes de collision montrées" % count)
