from pathlib import Path

base = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend")
p = base / "scenes/levels/desert/desert.gd"
t = p.read_text(encoding="utf-8")


def rep(old, new, count=1):
    global t
    assert t.count(old) == count, (t.count(old), old[:90])
    t = t.replace(old, new)


rep('''	_environment.ambient_light_energy = AMBIENT_INSIDE if _inside else AMBIENT_OUTSIDE
''', '''	# Dans la cave, la lumière ambiante ne vient plus du ciel bleu mais d'une pénombre chaude.
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR if _inside else Environment.AMBIENT_SOURCE_SKY
	_environment.ambient_light_energy = AMBIENT_INSIDE if _inside else AMBIENT_OUTSIDE
''')
rep('''## Teinte les matériaux des modèles en grès, en partageant une copie par matériau d'origine. Les formes simples
## (nœud Shapes) ont déjà leurs couleurs.
func _tint_stone(root: Node) -> void:
	var tinted := {}
	for mesh: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if mesh.get_parent().name == &"Shapes":
			continue''', '''## Teinte les matériaux des modèles en grès, en partageant une copie par matériau d'origine. Les formes simples
## (nœud Shapes) ont déjà leurs couleurs, et les squelettes gardent la blancheur de leurs os.
func _tint_stone(root: Node) -> void:
	var tinted := {}
	for mesh: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if mesh.get_parent().name == &"Shapes" or _model_of(mesh).name.begins_with("character_skeleton"):
			continue''')
rep('''## Les petits modèles des ruines''', '''## Modèle du kit auquel appartient un maillage : l'enfant du nœud Models qui le contient.
func _model_of(node: Node) -> Node:
	while node.get_parent() and node.get_parent().name != &"Models":
		node = node.get_parent()
	return node


## Les petits modèles des ruines''')
rep('''	gradient.add_point(0.3, Color(0.95, 0.85, 0.65, 0.45))
	gradient.add_point(0.7, Color(0.95, 0.85, 0.65, 0.35))
	var dust := CPUParticles3D.new()''', '''	gradient.add_point(0.3, Color(0.95, 0.85, 0.65, 0.3))
	gradient.add_point(0.7, Color(0.95, 0.85, 0.65, 0.22))
	var dust := CPUParticles3D.new()''')
p.write_text(t, encoding="utf-8", newline="\n")

b = base / "tools/build_desert.py"
t = b.read_text(encoding="utf-8")
rep('''    scene.add("nature_kit/statue_head", (hx, -2.6, hz), 125.0, 7.5, tilt=-8.0)
    scene.add_box((hx, 2.3, hz), (4.8, 4.6, 3.8), 125.0)''', '''    # Le visage (+X du modèle) regarde l'arche et le monument, la tête un peu renversée en arrière.
    scene.add("nature_kit/statue_head", (hx, -1.8, hz), 33.0, 7.5, roll=10.0)
    scene.add_box((hx, 2.6, hz), (4.6, 5.2, 3.8), 33.0)''')
rep('''    mound(scene, hx + 0.6, hz + 1.6, 4.4, 1.3, 2.6, 125.0)''', '''    mound(scene, hx - 1.4, hz + 0.9, 4.4, 1.3, 2.6, 33.0)''')
b.write_text(t, encoding="utf-8", newline="\n")
print("ok")
