"""Épaves : collision sur leurs triangles (tous leurs maillages) au lieu de l'enveloppe convexe, qui comblait les
vides entre les bras d'une baliste démolie (mur invisible au bord de la carte)."""
from pathlib import Path

p = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/scenes/levels/desert/desert_scatter.gd")
t = p.read_bytes().decode("utf-8")
old = '''		# L'enveloppe convexe de l'épave, tournée et mise à l'échelle comme elle.
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
		body.add_child(collision)
'''
new = '''		# Les triangles de l'épave, tous ses maillages, tournés et mis à l'échelle comme elle : une enveloppe
		# convexe comblerait les vides entre ses bras et ses roues, des murs invisibles.
		var inverse := body.global_transform.affine_inverse()
		for part: MeshInstance3D in wreck.find_children("*", "MeshInstance3D", true, false):
			if not part.mesh:
				continue
			var faces := part.mesh.get_faces()
			var xform := inverse * part.global_transform
			for corner in faces.size():
				faces[corner] = xform * faces[corner]
			var shape := ConcavePolygonShape3D.new()
			shape.set_faces(faces)
			shape.backface_collision = true
			var collision := CollisionShape3D.new()
			collision.shape = shape
			body.add_child(collision)
'''
assert t.count(old) == 1
t = t.replace(old, new)
p.write_bytes(t.encode("utf-8"))
print("ok")
