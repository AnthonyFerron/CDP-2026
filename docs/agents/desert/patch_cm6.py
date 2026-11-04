from pathlib import Path

b = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/tools/build_desert.py")
t = b.read_text(encoding="utf-8")


def rep(text, old, new, count=1):
    assert text.count(old) == count, (text.count(old), old[:90])
    return text.replace(old, new)


t = rep(t, '''    def cylinder_collider(self, center, radius, height):
        self.extra_colliders.append((transform_text(rotation_y(0.0), center), "CylinderShape3D",''', '''    def cylinder_collider(self, center, radius, height, degrees=0.0, tilt=0.0):
        basis = multiply(rotation_y(degrees), rotation_x(tilt))
        self.extra_colliders.append((transform_text(basis, center), "CylinderShape3D",''')
t = rep(t, '''    def column_collider(self, x, z, width, height, base=0.0):''', '''    def rubble_collider(self, center, model, degrees, scale):
        """Tas de gravats : une boîte plus basse et plus étroite que la boîte du modèle, au cœur du tas."""
        (px, py, pz), (sx, sy, sz) = MODEL_BOXES[model]
        self.add_box((center[0], sy * scale * 0.33, center[2]), (sx * scale * 0.75, sy * scale * 0.66, sz * scale * 0.75), degrees)

    def column_collider(self, x, z, width, height, base=0.0):''')
t = rep(t, '''    put(scene, "mini_arena/bricks", (-7.0, 0.0, z + 3.0), 20.0, 3.0, height=1.2)
    put(scene, "mini_arena/bricks", (8.0, 0.0, z + 2.5), -40.0, 3.0, height=1.2)''', '''    for center, degrees in (((-7.0, 0.0, z + 3.0), 20.0), ((8.0, 0.0, z + 2.5), -40.0)):
        put(scene, "mini_arena/bricks", center, degrees, 3.0)
        scene.rubble_collider(center, "mini_arena/bricks", degrees, 3.0)''')
t = rep(t, '''                              (0.8 * GATE_SCALE, GATE_SCALE, 0.8 * GATE_SCALE))''', '''                              (0.8 * GATE_SCALE, GATE_SCALE * 0.8, 0.8 * GATE_SCALE))''')
t = rep(t, '''    put(scene, "mini_arena/column-damaged", (6.5, 0.0, 6.5), 0.0, 3.0, height=1.8, tilt=90.0)''', '''    put(scene, "mini_arena/column-damaged", (6.5, 0.0, 6.5), 0.0, 3.0, tilt=90.0)
    scene.cylinder_collider((6.5, 0.85, 6.5), 0.85, 2.16, 0.0, 90.0)''')
t = rep(t, '''    scene.add_box((hx, 2.6, hz), (5.0, 5.2, 4.0), -56.0)''', '''    scene.add_box((hx, 2.4, hz), (4.0, 4.8, 3.0), -56.0)''')
b.write_text(t, encoding="utf-8", newline="\n")
print("ok")
