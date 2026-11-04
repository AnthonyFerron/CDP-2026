from pathlib import Path

s = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/scenes/levels/desert/desert_scatter.gd")
t = s.read_text(encoding="utf-8")


def rep(text, old, new, count=1):
    assert text.count(old) == count, (text.count(old), old[:90])
    return text.replace(old, new)


# Rochers et cactus : la collision est l'enveloppe convexe du modèle, à son échelle : elle colle à ce qu'on voit.
t = rep(t, '''	var placed := 0
	for attempt in count * 10:''', '''	var hulls: Array[PackedVector3Array] = []
	if not tilted and not heights.is_empty():
		for model in models:
			var hull := _load_mesh(model).create_convex_shape(true, true) as ConvexPolygonShape3D
			hulls.append(hull.points if hull else PackedVector3Array())
	var placed := 0
	for attempt in count * 10:''')
t = rep(t, '''			else:
				# Un cylindre à la hauteur du modèle : pas de mur invisible au-dessus d'un petit rocher.
				var height := (heights[group] if group < heights.size() else 0.5) * scale_factor + 0.15
				var shape := CylinderShape3D.new()
				shape.radius = radius * scale_factor
				shape.height = height
				collision.shape = shape
				collision.position = origin + Vector3.UP * height * 0.5''', '''			elif group < hulls.size() and not hulls[group].is_empty():
				# L'enveloppe du modèle, tournée et mise à l'échelle comme lui : pas de mur invisible autour.
				var points := PackedVector3Array()
				var xform := Transform3D(basis.scaled(Vector3.ONE * scale_factor), Vector3.ZERO)
				for point in hulls[group]:
					points.append(xform * point)
				var hull_shape := ConvexPolygonShape3D.new()
				hull_shape.points = points
				collision.shape = hull_shape
				collision.position = origin
			else:
				var height := (heights[group] if group < heights.size() else 0.5) * scale_factor + 0.15
				var shape := CylinderShape3D.new()
				shape.radius = radius * scale_factor
				shape.height = height
				collision.shape = shape
				collision.position = origin + Vector3.UP * height * 0.5''')
# Restes épars : la collision a la hauteur de la jarre ou du tonneau.
t = rep(t, '''		if prop[7] > 0.0:
			var shape := CylinderShape3D.new()
			shape.radius = prop[7]
			shape.height = 1.6
			var collision := CollisionShape3D.new()
			collision.shape = shape
			collision.position = item.position + Vector3.UP * 0.8''', '''		if prop[7] > 0.0:
			var height: float = PROP_HEIGHTS[prop[0]] * prop[4]
			var shape := CylinderShape3D.new()
			shape.radius = prop[7]
			shape.height = height
			var collision := CollisionShape3D.new()
			collision.shape = shape
			collision.position = item.position + Vector3.UP * height * 0.5''')
t = rep(t, '''## Hauteur à l'échelle 1 des cactus et des rochers, dans l'ordre de leurs modèles.''', '''## Hauteur à l'échelle 1 des restes épars, dans l'ordre de prop_models.
const PROP_HEIGHTS: Array[float] = [0.6, 0.38, 0.45, 0.43, 0.48, 0.48, 0.48]
## Hauteur à l'échelle 1 des cactus et des rochers, dans l'ordre de leurs modèles.''')
s.write_text(t, encoding="utf-8", newline="\n")

b = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/tools/build_desert.py")
t = b.read_text(encoding="utf-8")
t = rep(t, '''                scene.add_box((foot[0], y + 0.9, foot[2]), (thick * 3, 1.8, thick * 3), degrees)''', '''                scene.add_box((foot[0], y + 0.65, foot[2]), (thick * 2.4, 1.3, thick * 2.4), degrees)''')
t = rep(t, '''        put(scene, "mini_dungeon/stones", (x + dx, 0.0, z + dz), degrees, 1.5, height=0.65)''', '''        put(scene, "mini_dungeon/stones", (x + dx, 0.0, z + dz), degrees, 1.5, height=0.45)''')
t = rep(t, '''    furniture(scene, "mini_dungeon/chair", (3.9, 0.0, -3.75), 180.0, 2.0, height=0.96)''', '''    furniture(scene, "mini_dungeon/chair", (3.9, 0.0, -3.75), 180.0, 2.0, height=0.55)''')
b.write_text(t, encoding="utf-8", newline="\n")
print("ok")
