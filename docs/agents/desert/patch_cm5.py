from pathlib import Path

b = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/tools/build_desert.py")
t = b.read_text(encoding="utf-8")


def rep(text, old, new, count=1):
    assert text.count(old) == count, (text.count(old), old[:90])
    return text.replace(old, new)


t = rep(t, '''        scene.add_box((x, y + 0.45, z), (0.62, 0.9, 0.62))''', '''        scene.cylinder_collider((x, y + 0.45, z), 0.31, 0.9)''')
t = rep(t, '''    scene.add_box((x, y + 0.62, z), (0.7, 1.24, 0.7))''', '''    scene.cylinder_collider((x, y + 0.62, z), 0.32, 1.24)''')
t = rep(t, '''                scene.add_box((foot[0], y + 0.65, foot[2]), (thick * 2.4, 1.3, thick * 2.4), degrees)''',
        '''                inward = frame(side * radius * 0.92, v, 0.0)
                scene.add_box((inward[0], y + 0.35, inward[2]), (thick * 2.2, 0.7, thick * 2.2), degrees)''')
# Roues couchées : un disque bas, pas une boîte qui déborde de la jante.
for old_line in ('''    put(scene, "fantasy_town_kit/wheel", at(1.9, -6.4), heading + 30.0, 2.8, height=0.7, roll=90.0)''',
                 '''    put(scene, "fantasy_town_kit/wheel", (x - 3.4, 0.0, z - 2.8), 20.0, 2.8, height=0.7, roll=90.0)'''):
    new_line = old_line.replace(", height=0.7, roll=90.0)", ", roll=90.0)")
    target = old_line.split("put(scene, \"fantasy_town_kit/wheel\", ")[1].split(", ")[0]
    t = rep(t, old_line, new_line + f'''
    wheel_center = {target}
    scene.cylinder_collider((wheel_center[0], 0.25, wheel_center[2]), 0.62, 0.5)''')
b.write_text(t, encoding="utf-8", newline="\n")

s = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/scenes/levels/desert/desert_scatter.gd")
t = s.read_text(encoding="utf-8")
t = rep(t, '''		var shape := BoxShape3D.new()
		shape.size = Vector3(box[1].x, box[1].y, box[1].z) * scale_factor
		var collision := CollisionShape3D.new()
		collision.shape = shape
		var center: Vector3 = (box[0] + box[1] * 0.5) * scale_factor
		collision.transform = Transform3D(basis, origin + basis * center)
		body.add_child(collision)''', '''		# L'enveloppe convexe de l'épave, tournée et mise à l'échelle comme elle.
		var hull := _load_mesh(wreck_models[kind]).create_convex_shape(true, true) as ConvexPolygonShape3D
		var points := PackedVector3Array()
		var xform := Transform3D(basis.scaled(Vector3.ONE * scale_factor), Vector3.ZERO)
		for point in hull.points:
			points.append(xform * point)
		var shape := ConvexPolygonShape3D.new()
		shape.points = points
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position = origin
		body.add_child(collision)''')
s.write_text(t, encoding="utf-8", newline="\n")
print("ok")
