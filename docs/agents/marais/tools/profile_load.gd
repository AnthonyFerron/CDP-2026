extends SceneTree
## Temps de chargement du Marais, morceau par morceau : regroupement de chaque racine (MaraisBatch), mécanisme
## gravé (RingMechanism), et la scène entière.

func _initialize() -> void:
	_run.call_deferred()


func _time(label: String, callable: Callable) -> void:
	var start := Time.get_ticks_usec()
	callable.call()
	print("TEMPS %s : %.0f ms" % [label, (Time.get_ticks_usec() - start) / 1000.0])


func _run() -> void:
	var state: Node = root.get_node("GameState")
	state.reset()
	state.intro_done = true
	var holder := Node3D.new()
	root.add_child(holder)
	var start := Time.get_ticks_usec()
	var props: Node3D = (load("res://scenes/levels/marais/marais_props.tscn") as PackedScene).instantiate()
	var grounded: Node3D = (load("res://scenes/levels/marais/marais_grounded.tscn") as PackedScene).instantiate()
	var crypt: Node3D = (load("res://scenes/levels/marais/marais_crypt.tscn") as PackedScene).instantiate()
	print("TEMPS chargement des trois décors : %.0f ms" % ((Time.get_ticks_usec() - start) / 1000.0))
	holder.add_child(props)
	holder.add_child(grounded)
	holder.add_child(crypt)
	if ResourceLoader.exists("res://scenes/levels/marais/marais_batch.gd"):
		var batch: GDScript = load("res://scenes/levels/marais/marais_batch.gd")
		for entry: Array in [["Props/Models", props.get_node("Models"), 32.0, true], ["Grounded", grounded, 32.0, true],
				["Crypt/Models", crypt.get_node("Models"), 12.0, false]]:
			start = Time.get_ticks_usec()
			var count: int = batch.merge(entry[1], entry[2], entry[3])
			print("TEMPS regroupement %s : %.0f ms (%d maillages)" % [entry[0], (Time.get_ticks_usec() - start) / 1000.0, count])
	var mechanism := Node3D.new()
	mechanism.set_script(load("res://scenes/levels/marais/ring_mechanism.gd"))
	_time("mécanisme gravé", func() -> void: holder.add_child(mechanism))
	holder.queue_free()
	await process_frame
	for i in 2:
		var begin := Time.get_ticks_usec()
		var level: Node = (load("res://scenes/levels/marais/marais.tscn") as PackedScene).instantiate()
		var mid := Time.get_ticks_usec()
		root.add_child(level)
		print("TEMPS scène entière, essai %d : instance %.0f ms, prête %.0f ms" % [i + 1, (mid - begin) / 1000.0, (Time.get_ticks_usec() - mid) / 1000.0])
		await process_frame
		level.queue_free()
		await process_frame
	state.reset()
	quit()
