from pathlib import Path

base = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/scenes/levels/desert")
p = base / "desert.gd"
t = p.read_text(encoding="utf-8")


def rep(old, new, count=1):
    global t
    assert t.count(old) == count, (t.count(old), old[:90])
    t = t.replace(old, new)


rep('''## Secousse de la caméra : forte et brève à l'erreur, longue et sourde à la réussite.
func _shake(duration: float, strength: float) -> void:
	var pivot := _player.get_node("CameraPivot") as Node3D
	var rest := pivot.position
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		var amount := strength * (1.0 - t)
		pivot.position = rest + Vector3(randf_range(-amount, amount), randf_range(-amount, amount) * 0.6, randf_range(-amount, amount))
		pivot.rotation.z = randf_range(-amount, amount) * 0.25, 0.0, 1.0, duration)
	tween.tween_callback(func() -> void:
		pivot.position = rest
		pivot.rotation.z = 0.0)
''', '''## Secousse de la caméra : forte et brève à l'erreur, longue et sourde à la réussite.
func _shake(duration: float, strength: float) -> void:
	var pivot := _player.get_node("CameraPivot") as Node3D
	if _shake_tween:
		_shake_tween.kill()
		pivot.position = _shake_rest
	_shake_rest = pivot.position
	_shake_strength = strength
	_shake_tween = create_tween()
	_shake_tween.tween_method(_shake_step.bind(pivot), 0.0, 1.0, duration)
	_shake_tween.tween_callback(_shake_step.bind(1.0, pivot))


func _shake_step(progress: float, pivot: Node3D) -> void:
	var amount := _shake_strength * (1.0 - progress)
	pivot.position = _shake_rest + Vector3(randf_range(-amount, amount), randf_range(-amount, amount) * 0.6, randf_range(-amount, amount))
	pivot.rotation.z = randf_range(-amount, amount) * 0.25
''')
rep('''var _slot_material: StandardMaterial3D
''', '''var _slot_material: StandardMaterial3D
var _shake_tween: Tween
var _shake_rest := Vector3.ZERO
var _shake_strength := 0.0
''')
p.write_text(t, encoding="utf-8", newline="\n")

q = base / "rune_puzzle.gd"
t = q.read_text(encoding="utf-8")
rep('''	# Une violente secousse ébranle le panneau, comme la cave.
	_flash.tween_method(func(t: float) -> void:
		var amount := 18.0 * (1.0 - t)
		_root.position = Vector2(randf_range(-amount, amount), randf_range(-amount, amount)), 0.0, 1.0, 0.6)
	_flash.tween_callback(func() -> void: _root.position = Vector2.ZERO)
	_flash.tween_interval(0.6)''', '''	# Une violente secousse ébranle le panneau, comme la cave.
	_flash.tween_method(_shake_step, 0.0, 1.0, 0.6)
	_flash.tween_callback(_shake_step.bind(1.0))
	_flash.tween_interval(0.6)''')
rep('''func _on_close_pressed() -> void:''', '''func _shake_step(progress: float) -> void:
	var amount := 18.0 * (1.0 - progress)
	_root.position = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))


func _on_close_pressed() -> void:''')
q.write_text(t, encoding="utf-8", newline="\n")
print("ok")
