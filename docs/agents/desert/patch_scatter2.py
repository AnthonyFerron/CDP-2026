from pathlib import Path

p = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/scenes/levels/desert/desert_scatter.gd")
t = p.read_text(encoding="utf-8")
start = t.index("		var scale_factor := _rng.randf_range(scale_range.x, scale_range.y)")
end = t.index("		placed += 1\n")
new = '''		var scale_factor := _rng.randf_range(scale_range.x, scale_range.y)
		var group := placed % groups.size()
		# Seules les colonnes se couchent ; les tas de briques restent posés à plat.
		var lying := tilted and group == 0
		var basis := Basis(Vector3.UP, _rng.randf() * TAU)
		var lean := _rng.randf_range(70.0, 90.0) if tilted else 0.0
		if lying:
			basis = basis * Basis(Vector3.FORWARD, deg_to_rad(lean))
		var origin := Vector3(spot.x, terrain.footing_height(spot.x, spot.y) - 0.15, spot.y)
		if lying:
			origin.y += 0.3 * scale_factor
		groups[group].append(Transform3D(basis.scaled(Vector3.ONE * scale_factor), origin))
		if solid:
			var collision := CollisionShape3D.new()
			if tilted and group < RUIN_BOXES.size():
				# Une boîte tournée comme la ruine, sur toute sa longueur.
				var box := BoxShape3D.new()
				box.size = RUIN_BOXES[group] * scale_factor
				collision.shape = box
				collision.transform = Transform3D(basis, origin + basis * Vector3(0.0, RUIN_BOXES[group].y * 0.5 * scale_factor, 0.0))
			else:
				var shape := CylinderShape3D.new()
				shape.radius = radius * scale_factor
				shape.height = 2.5
				collision.shape = shape
				collision.position = origin + Vector3.UP * 1.0
			body.add_child(collision)
'''
t = t[:start] + new + t[end:]
p.write_text(t, encoding="utf-8", newline="\n")
print("ok")
