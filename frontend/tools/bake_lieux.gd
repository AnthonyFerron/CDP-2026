extends SceneTree
## Calcule d'avance ce que les lieux calculaient à chaque chargement, et l'écrit dans
## scenes/levels/<lieu>/<lieu>_bake.res (LevelBake) : hauteurs et couleurs du sol, positions et collisions du décor
## dispersé. Chaque lieu est chargé comme en jeu, sans ses données d'avance : ses nœuds calculent tout et relèvent ce
## qu'ils ont calculé (LevelBake.record). Le résultat est donc celui du chargement, et deux passages écrivent le même
## fichier.
## À relancer après tout changement du relief, du décor dispersé, de leurs réglages ou de leurs scripts (sinon le lieu
## le signale au chargement et recalcule tout) :
##   cd frontend && godot --headless --path . --script res://tools/bake_lieux.gd [-- <lieu> ...]
## Sans lieu, tous ceux de LEVELS. Avec « -- --check », rien n'est écrit : le script compare chaque fichier au calcul,
## et sort en erreur si l'un d'eux diffère (contrôle bake_lieux_check de tests/scenes/run_all.sh).

## Fichier de passage du contrôle.
const CHECK_PATH := "user://bake_lieux_check.res"
const LEVELS := {
	"village": "res://scenes/levels/village/village.tscn",
}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var check := args.has("--check")
	var places: Array = Array(args).filter(func(arg: String) -> bool: return LEVELS.has(arg))
	if places.is_empty():
		places = LEVELS.keys()
	var state: Node = root.get_node("GameState")
	var failed := false
	for place: String in places:
		var path := "res://scenes/levels/%s/%s_bake.res" % [place, place]
		if not check and not ResourceLoader.exists(path):
			# Le lieu s'y réfère : le fichier doit exister avant son chargement.
			ResourceSaver.save(LevelBake.new(), path, ResourceSaver.FLAG_COMPRESS)
		var start := Time.get_ticks_msec()
		state.reset()
		state.intro_done = true
		LevelBake.recorded = {}
		LevelBake.recording = true
		var level: Node = (load(LEVELS[place]) as PackedScene).instantiate()
		root.add_child(level)
		# Certains nœuds attendent leurs voisins (le décor attend le sol) : quelques images suffisent.
		for frame in 5:
			await process_frame
		LevelBake.recording = false
		var bake := LevelBake.new()
		var sizes: Array[String] = []
		for name: String in LevelBake.recorded:
			if name.begins_with(place + "/"):
				bake.parts[name] = LevelBake.recorded[name]
				sizes.append("%s %d octets" % [name, var_to_bytes(LevelBake.recorded[name][2]).size()])
		level.queue_free()
		await process_frame
		print("%s : %s, calculés en %d ms" % [place, ", ".join(sizes), Time.get_ticks_msec() - start])
		if bake.parts.is_empty():
			print("%s : AUCUNE DONNÉE RELEVÉE" % place)
			failed = true
			continue
		if check:
			# Comparés tels qu'enregistrés : un fichier relu ne garde pas le type des tableaux imbriqués.
			ResourceSaver.save(bake, CHECK_PATH, ResourceSaver.FLAG_COMPRESS)
			var fresh := ResourceLoader.load(CHECK_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as LevelBake
			DirAccess.remove_absolute(CHECK_PATH)
			var saved := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as LevelBake
			var same := saved != null and fresh != null and var_to_bytes(saved.parts) == var_to_bytes(fresh.parts)
			print("%s : %s" % [place, "données d'avance à jour" if same
				else "DONNÉES D'AVANCE PÉRIMÉES, relancer tools/bake_lieux.gd"])
			failed = failed or not same
			continue
		var error := ResourceSaver.save(bake, path, ResourceSaver.FLAG_COMPRESS)
		if error == OK:
			print("%s : %s écrit (%d octets)" % [place, path, FileAccess.get_file_as_bytes(path).size()])
		else:
			print("%s : écriture impossible (%s)" % [place, error_string(error)])
			failed = true
	state.reset()
	print("Lieux : %s" % ("ÉCHEC" if failed else ("à jour" if check else "écrits")))
	quit(1 if failed else 0)
