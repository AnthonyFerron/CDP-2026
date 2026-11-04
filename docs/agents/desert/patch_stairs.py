import math
from pathlib import Path

w = Path("C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/write_desert_tscn.py")
t = w.read_text(encoding="utf-8")


def rep(text, old, new, count=1):
    assert text.count(old) == count, (text.count(old), old[:90])
    return text.replace(old, new)


# Le plafond de la salle s'arrête au pied de l'escalier : la cage de l'escalier a son propre plafond, plus haut.
t = rep(t, '''[sub_resource type="BoxMesh" id="BoxMesh_ceiling"]
material = SubResource("StandardMaterial3D_cave_stone")
size = Vector3(20.4, 0.3, 16.4)

[sub_resource type="BoxMesh" id="BoxMesh_cellar_step"]
material = SubResource("StandardMaterial3D_cave_stone")
size = Vector3(2.8, 0.39, 0.36)

[sub_resource type="BoxShape3D" id="BoxShape3D_cellar_stairs"]
size = Vector3(2.8, 3.9, 3.6)
''', '''[sub_resource type="BoxMesh" id="BoxMesh_ceiling"]
material = SubResource("StandardMaterial3D_cave_stone")
size = Vector3(20.4, 0.3, 12.4)

[sub_resource type="BoxMesh" id="BoxMesh_shaft_ceiling"]
material = SubResource("StandardMaterial3D_cave_stone")
size = Vector3(4.0, 0.3, 4.2)

[sub_resource type="BoxMesh" id="BoxMesh_shaft_lintel"]
material = SubResource("StandardMaterial3D_cave_stone")
size = Vector3(4.0, 1.45, 0.4)

[sub_resource type="BoxMesh" id="BoxMesh_shaft_side"]
material = SubResource("StandardMaterial3D_cave_stone")
size = Vector3(0.6, 1.45, 4.0)

[sub_resource type="BoxMesh" id="BoxMesh_shaft_back"]
material = SubResource("StandardMaterial3D_cave_stone")
size = Vector3(4.0, 1.45, 0.6)

[sub_resource type="BoxShape3D" id="BoxShape3D_cellar_ramp"]
size = Vector3(2.8, 0.6, 4.54)
''')
steps = []
for k in range(9):
    top = 0.3 * (k + 1)
    steps.append(f'''[sub_resource type="BoxMesh" id="BoxMesh_step{k}"]
material = SubResource("StandardMaterial3D_cave_stone")
size = Vector3(2.8, {top:g}, 0.34)
''')
t = rep(t, '''[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_sun_mark"]''', "\n".join(steps) + '''
[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_sun_mark"]''')

angle = math.atan2(3.0, 3.4)
c, s = math.cos(angle), math.sin(angle)
center_y = 1.5 - 0.3 * c
center_z = 1.56 + 0.3 * s
t = rep(t, '''    # Plafond de pierre sombre, sur toute la salle et sur l'escalier.
    node(lines, "Ceiling", "MeshInstance3D", "Interior", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 4.3, -4)", 'mesh = SubResource("BoxMesh_ceiling")'])
    # Escalier de pierre qui remonte vers la trappe, dans la case au sud de la salle.
    node(lines, "Stairs", "StaticBody3D", "Interior")
    for step in range(10):
        node(lines, f"Step{step}", "MeshInstance3D", "Interior/Stairs", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {0.195 + step * 0.39:g}, {0.58 + step * 0.36:g})",
            'mesh = SubResource("BoxMesh_cellar_step")'])
    node(lines, "Shape", "CollisionShape3D", "Interior/Stairs", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.95, 2.2)", 'shape = SubResource("BoxShape3D_cellar_stairs")'])''',
        f'''    # Plafond de pierre sombre sur la salle ; la cage de l'escalier, plus haute, a le sien, raccordé par un linteau.
    node(lines, "Ceiling", "MeshInstance3D", "Interior", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 4.3, -6)", 'mesh = SubResource("BoxMesh_ceiling")'])
    node(lines, "ShaftCeiling", "MeshInstance3D", "Interior", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 5.55, 2.0)", 'mesh = SubResource("BoxMesh_shaft_ceiling")'])
    node(lines, "ShaftLintel", "MeshInstance3D", "Interior", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 4.85, 0.2)", 'mesh = SubResource("BoxMesh_shaft_lintel")'])
    for name, mesh, x, z in (("ShaftWest", "BoxMesh_shaft_side", -1.7, 2.0), ("ShaftEast", "BoxMesh_shaft_side", 1.7, 2.0),
                             ("ShaftBack", "BoxMesh_shaft_back", 0.0, 3.7)):
        node(lines, name, "MeshInstance3D", "Interior", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {{x:g}}, 4.85, {{z:g}})", f'mesh = SubResource("{{mesh}}")'])
    # Escalier de pierre qui remonte vers la trappe, dans la case au sud de la salle : neuf marches de 30 cm,
    # que le joueur monte et descend sur une rampe de collision à 41 degrés posée sur leurs nez.
    node(lines, "Stairs", "StaticBody3D", "Interior")
    for step in range(9):
        node(lines, f"Step{{step}}", "MeshInstance3D", "Interior/Stairs", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {{0.15 * (step + 1):g}}, {{0.37 + step * 0.34:g}})",
            f'mesh = SubResource("BoxMesh_step{{step}}")'])
    node(lines, "Shape", "CollisionShape3D", "Interior/Stairs", props=[
        "transform = Transform3D(1, 0, 0, 0, {c:.6g}, {s:.6g}, 0, {-s:.6g}, {c:.6g}, 0, {center_y:.4g}, {center_z:.4g})",
        'shape = SubResource("BoxShape3D_cellar_ramp")'])''')
t = rep(t, '''        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.2, 0.05)", 'script = ExtResource("11_interactable")',
        'prompt = "Remonter à la surface"', "radius = 2.2"])''', '''        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.6, 1.7)", 'script = ExtResource("11_interactable")',
        'prompt = "Remonter à la surface"', "radius = 2.8"])''')
w.write_text(t, encoding="utf-8", newline="\n")

b = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/tools/build_desert.py")
t = b.read_text(encoding="utf-8")
t = rep(t, '''    tiles = set(CELLAR_TILES)
    for x, z in CELLAR_TILES:
        scene.add("modular_dungeon_kit/template-floor", (x, 0.0, z), 0.0, 1.0)
        scene.add_box((x, -0.25, z), (CELLAR_TILE, 0.5, CELLAR_TILE))
        scene.add_box((x, CELLAR_HEIGHT + 0.25, z), (CELLAR_TILE, 0.5, CELLAR_TILE))''', '''    tiles = set(CELLAR_TILES)
    for x, z in CELLAR_TILES:
        scene.add("modular_dungeon_kit/template-floor", (x, 0.0, z), 0.0, 1.0)
        scene.add_box((x, -0.25, z), (CELLAR_TILE, 0.5, CELLAR_TILE))
        # La cage de l'escalier monte plus haut que la salle : on tient debout sur la dernière marche.
        ceiling = SHAFT_HEIGHT if (x, z) == STAIR_TILE else CELLAR_HEIGHT
        scene.add_box((x, ceiling + 0.25, z), (CELLAR_TILE, 0.5, CELLAR_TILE))''')
t = rep(t, '''            size = (0.6, CELLAR_HEIGHT, CELLAR_TILE) if dx else (CELLAR_TILE, CELLAR_HEIGHT, 0.6)
            scene.add_box((edge[0] - dx * 0.3, CELLAR_HEIGHT / 2, edge[1] - dz * 0.3), size)''', '''            height = SHAFT_HEIGHT if (x, z) == STAIR_TILE else CELLAR_HEIGHT
            size = (0.6, height, CELLAR_TILE) if dx else (CELLAR_TILE, height, 0.6)
            scene.add_box((edge[0] - dx * 0.3, height / 2, edge[1] - dz * 0.3), size)''')
t = rep(t, '''# Bord du fond où s'élève la porte scellée, sous l'inscription.
SEALED_DOOR = (0.0, -12.0)''', '''# Bord du fond où s'élève la porte scellée, sous l'inscription.
SEALED_DOOR = (0.0, -12.0)
# Case de l'escalier et hauteur de sa cage, sous la trappe.
STAIR_TILE = (0.0, 2.0)
SHAFT_HEIGHT = 5.4''')
b.write_text(t, encoding="utf-8", newline="\n")
print("ok")
