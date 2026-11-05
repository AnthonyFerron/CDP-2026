extends SceneTree
## Temps de chargement de la Plaine, étape par étape : lecture des ressources, instance, entrée dans l'arbre
## (_ready de tous les scripts), puis premières images. -- [essais]
## Les scripts instrumentés écrivent leurs propres lignes « TEMPS … ».

const SCENE := "res://scenes/levels/plaine/plaine.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _ms(start: int) -> float:
	return (Time.get_ticks_usec() - start) / 1000.0


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var tries := 2
	for arg in args:
		if arg.is_valid_int():
			tries = int(arg)
	var state: Node = root.get_node("GameState")
	state.reset()
	state.intro_done = true
	for i in tries:
		var begin := Time.get_ticks_usec()
		var packed: PackedScene = load(SCENE)
		var loaded := _ms(begin)
		var mark := Time.get_ticks_usec()
		var level: Node = packed.instantiate()
		var instanced := _ms(mark)
		mark = Time.get_ticks_usec()
		root.add_child(level)
		var ready := _ms(mark)
		mark = Time.get_ticks_usec()
		await process_frame
		var first := _ms(mark)
		mark = Time.get_ticks_usec()
		await process_frame
		var second := _ms(mark)
		print("TEMPS essai %d : lecture %.0f ms, instance %.0f ms, prête %.0f ms, 1re image %.0f ms, 2e image %.0f ms, total %.0f ms" % [
			i + 1, loaded, instanced, ready, first, second, _ms(begin)])
		level.queue_free()
		await process_frame
		await process_frame
	state.reset()
	quit()
