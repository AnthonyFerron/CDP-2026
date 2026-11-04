from pathlib import Path

w = Path("C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/write_desert_tscn.py")
t = w.read_text(encoding="utf-8")


def rep(text, old, new, count=1):
    assert text.count(old) == count, (text.count(old), old[:90])
    return text.replace(old, new)


t = rep(t, '''    ("Script", "res://scenes/levels/hub/volcano.gd", "90_volcano"),''', '''    ("Script", "res://scenes/levels/desert/desert_life.gd", "37_life"),
    ("Script", "res://scenes/levels/hub/volcano.gd", "90_volcano"),''')
t = rep(t, '''    node(lines, "Ruins", parent="Exterior", instance="6_ruins")''', '''    node(lines, "Ruins", parent="Exterior", instance="6_ruins")
    # Vautours, lézards, scorpions et toiles au vent (desert_life.gd).
    lines += [
        '[node name="Life" type="Node3D" parent="Exterior" node_paths=PackedStringArray("terrain")]',
        'script = ExtResource("37_life")',
        'terrain = NodePath("../Terrain")',
        "",
    ]''')
w.write_text(t, encoding="utf-8", newline="\n")

b = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/tools/build_desert.py")
t = b.read_text(encoding="utf-8")
t = rep(t, '''def stake_with_skull(scene, x, z, rng):
    """Pieu planté dans le sable, coiffé d'un crâne de vautour : la marque des pilleurs."""
    scene.shape("cyl", {"top": 0.04, "bottom": 0.06, "height": 1.7, "segments": 5}, "wood_dark", (x, 0.85, z), rng.uniform(0, 90),
                tilt=rng.uniform(-6, 6))
    vulture_skull(scene, x, z + 0.02, rng.uniform(0, 360), 1.6, y=1.62)
    scene.shape("box", {"size": (0.06, 0.5, 0.02)}, rng.choice(["cloth_red", "cloth_ochre"]), (x + 0.05, 1.3, z), rng.uniform(0, 360),
                roll=rng.uniform(-10, 10))
    scene.add_box((x, 0.9, z), (0.25, 1.8, 0.25))''', '''def stake_with_skull(scene, x, z, rng):
    """Pieu planté dans le sable, coiffé d'un crâne de vautour : la marque des pilleurs. Le chiffon noué au pieu,
    qui claque au vent, est posé par desert_life.gd (STAKES)."""
    scene.shape("cyl", {"top": 0.04, "bottom": 0.06, "height": 1.7, "segments": 5}, "wood_dark", (x, 0.85, z), rng.uniform(0, 90),
                tilt=rng.uniform(-6, 6))
    vulture_skull(scene, x, z + 0.02, rng.uniform(0, 360), 1.6, y=1.62)
    rng.choice(["cloth_red", "cloth_ochre"])
    rng.uniform(0, 360)
    rng.uniform(-10, 10)
    scene.add_box((x, 0.9, z), (0.25, 1.8, 0.25))''')
b.write_text(t, encoding="utf-8", newline="\n")
print("ok")
