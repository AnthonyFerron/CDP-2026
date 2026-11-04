from pathlib import Path

p = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/scenes/levels/desert/rune_puzzle.gd")
t = p.read_text(encoding="utf-8")


def rep(o, n):
    global t
    assert t.count(o) == 1, o[:70]
    t = t.replace(o, n)


rep('''		_set_feedback("Les runes s'illuminent d'une lueur rouge : les algorithmes ne s'exécutent pas. Le volcan gronde…", Ornate.ERROR)''',
    '''		# Le temps perdu s'affiche dans le bandeau « Mauvaise réponse » du HUD : ici, seulement ce que font les runes.
		_set_feedback("Les runes s'illuminent d'une lueur rouge : les algorithmes ne s'exécutent pas.", Ornate.ERROR)''')
rep('''	var instruction := Ornate.label("Choisissez une rune, puis la case où la graver : les deux algorithmes doivent s'exécuter.", 23, Ornate.MUTED)
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Ornate.place(_frame, instruction, Vector2(60, 56), Vector2(FRAME_RECT.size.x - 120, 36))
''', '')
rep('''	_feedback = Ornate.label("", 24, Ornate.MUTED)
	_feedback.name = "Feedback"
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Ornate.place(_frame, _feedback, Vector2(60, 790), Vector2(FRAME_RECT.size.x - 120, 56))''', '''	# La ligne du haut donne la consigne, ou ce qui vient de se passer : le bas du panneau reste libre pour le
	# bandeau « Mauvaise réponse » du HUD.
	_feedback = Ornate.label("", 23, Ornate.MUTED)
	_feedback.name = "Feedback"
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Ornate.place(_frame, _feedback, Vector2(60, 50), Vector2(FRAME_RECT.size.x - 120, 48))''')
rep('''func _set_feedback(text: String, color: Color) -> void:
	_feedback.text = text
	_feedback.add_theme_color_override("font_color", color)''', '''func _set_feedback(text: String, color: Color) -> void:
	_feedback.text = text if text != "" else INSTRUCTION
	_feedback.add_theme_color_override("font_color", color)''')
rep('''const LINE_TOP := 168.0''', '''const LINE_TOP := 168.0
const INSTRUCTION := "Choisissez une rune, puis la case où la graver : les deux algorithmes doivent s'exécuter."''')
rep('''	_flash.tween_interval(0.6)
	_flash.tween_callback(_end_flash)''', '''	_flash.tween_interval(2.4)
	_flash.tween_callback(_end_flash)''')
rep('''func _end_flash() -> void:
	_wrong = false
	_set_border(COLOR_IDLE)
	_rebuild()''', '''func _end_flash() -> void:
	_wrong = false
	_set_border(COLOR_IDLE)
	_set_feedback("", Ornate.MUTED)
	_rebuild()''')
p.write_text(t, encoding="utf-8", newline="\n")
print("ok")
