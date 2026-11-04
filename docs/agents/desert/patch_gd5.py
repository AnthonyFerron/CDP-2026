"""Pierres des cairns : une couleur de pierre unie au lieu de l'atlas, dont le gris foncé virait au noir sous la teinte."""
from pathlib import Path

p = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/scenes/levels/desert/desert.gd")
t = p.read_text(encoding="utf-8")


def sub(old, new):
    global t
    assert t.count(old) == 1, old
    t = t.replace(old, new)


sub('const SANDSTONE := Color(1.0, 0.8, 0.6)\n',
    'const SANDSTONE := Color(1.0, 0.8, 0.6)\n'
    '## Pierres des cairns (modèle stones du kit) : une teinte unie, l\'une de leurs pierres est gris foncé dans l\'atlas\n'
    '## et virait au noir sous la teinte du grès.\n'
    'const CAIRN_STONE := Color(0.7, 0.58, 0.46)\n')
sub('''		if mesh.get_parent().name == &"Shapes" or _model_of(mesh).name.begins_with("character_skeleton"):
			continue
		for surface in mesh.get_surface_override_material_count():
			var original := mesh.get_active_material(surface) as BaseMaterial3D
			if not original:
				continue
			if not tinted.has(original):
				var copy: BaseMaterial3D = original.duplicate()
				copy.albedo_color *= SANDSTONE
				tinted[original] = copy
			mesh.set_surface_override_material(surface, tinted[original])
''', '''		if mesh.get_parent().name == &"Shapes" or _model_of(mesh).name.begins_with("character_skeleton"):
			continue
		var cairn := _model_of(mesh).name.begins_with("stones_")
		for surface in mesh.get_surface_override_material_count():
			var original := mesh.get_active_material(surface) as BaseMaterial3D
			if not original:
				continue
			var key := [original, cairn]
			if not tinted.has(key):
				var copy: BaseMaterial3D = original.duplicate()
				if cairn:
					copy.albedo_texture = null
					copy.albedo_color = CAIRN_STONE
				else:
					copy.albedo_color *= SANDSTONE
				tinted[key] = copy
			mesh.set_surface_override_material(surface, tinted[key])
''')
p.write_text(t, encoding="utf-8", newline="\n")
print("ok")
