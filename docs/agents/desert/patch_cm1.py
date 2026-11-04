from pathlib import Path

b = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/tools/build_desert.py")
t = b.read_text(encoding="utf-8")


def rep(text, old, new, count=1):
    assert text.count(old) == count, (text.count(old), old[:90])
    return text.replace(old, new)


# Collision cylindrique, au plus près des fûts de colonnes.
t = rep(t, '''    def convex_collider(self, center, degrees, points):''', '''    def cylinder_collider(self, center, radius, height):
        self.extra_colliders.append((transform_text(rotation_y(0.0), center), "CylinderShape3D",
                                     f"radius = {fmt(radius)}\\nheight = {fmt(height)}"))

    def column_collider(self, x, z, width, height, base=0.0):
        """Colonne du kit : un socle carré au pied, puis un fût cylindrique un peu plus étroit que le chapiteau."""
        top = base + height
        if top <= 0.05:
            return
        foot = max(base, 0.0)
        self.add_box((x, foot + 0.12 * width / 2, z), (width, 0.12 * width, width))
        self.cylinder_collider((x, (foot + top) / 2, z), width * 0.36, top - foot)

    def convex_collider(self, center, degrees, points):''')
# Obélisque : le socle large, puis le fût seul (plus de mur invisible autour du fût).
t = rep(t, '''    scene.add_box((x, (y0 + shaft + 0.55) / 2, z), (1.9, y0 + shaft + 0.55, 1.9), degrees)''',
        '''    scene.add_box((x, 0.25, z), (1.9, 0.5, 1.9), degrees)
    scene.add_box((x, 0.675, z), (1.35, 0.35, 1.35), degrees)
    scene.add_box((x, y0 + (shaft + 0.55) / 2, z), (wb * 2 + 0.04, shaft + 0.55, wb * 2 + 0.04), degrees)''')
t = rep(t, '''        brazier(scene, sign * 5.4, z + 3.6, rng)''', '''        brazier(scene, sign * 5.8, z + 4.8, rng)''')
t = rep(t, '''        scene.add_box((x, 1.8, z), (2.0, 3.6, 2.0))''', '''        scene.column_collider(x, z, 0.6 * 3.6, (1.0 if model == "column" else 0.72) * 3.6)''')
t = rep(t, '''        scene.add_box((x, 2.65, pz), (2.3, 5.3, 2.3))''', '''        scene.column_collider(x, pz, 0.6 * 4.0, 6.5, base=-1.2)''')
t = rep(t, '''    jars(scene, 31.2, 3.8, random.Random(61), 4, 1.0)''', '''    jars(scene, 30.4, 4.6, random.Random(61), 4, 1.0)''')
t = rep(t, '''        scene.add_box((p[0], visible / 2, p[2]), (1.4, visible, 1.4))''', '''        scene.column_collider(p[0], p[2], 0.6 * 2.4, (1.0 if model == "column" else 0.72) * height, base=-1.4)''')
t = rep(t, '''        scene.add_box((x, 2.0, -10.2), (1.6, 4.0, 1.6))''', '''        scene.column_collider(x, -10.2, 0.5 * 3.6, 1.1 * 3.6)''')
b.write_text(t, encoding="utf-8", newline="\n")

g = Path("C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/desert_grid_test.gd")
t = g.read_text(encoding="utf-8")
t = rep(t, '''		if not border and not floor_hit.is_empty() and floor_hit.normal.y < cos(deg_to_rad(40.0)):''',
        '''		if not border and not floor_hit.is_empty() and floor_hit.normal.y < cos(deg_to_rad(44.0)):''')
t = rep(t, '''	var segments: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK, Vector3.UP, Vector3.DOWN]''',
        '''	var segments: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK, Vector3.UP, Vector3.DOWN]
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				segments.append(Vector3(sx, sy, sz).normalized())''')
g.write_text(t, encoding="utf-8")
print("ok")
