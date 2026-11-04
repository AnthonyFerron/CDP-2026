"""Vie du Village : corbeaux et chats animés (village.tscn), linge et bannières au vent, éclaboussures de la roue."""
import sys
from pathlib import Path

builder, writer, particles = (Path(p) for p in sys.argv[1:4])


def patch(path, pairs):
    text = path.read_text(encoding="utf-8")
    for old, new in pairs:
        assert text.count(old) == 1, (path.name, old[:90], text.count(old))
        text = text.replace(old, new)
    path.write_text(text, encoding="utf-8", newline="\n")


patch(builder, [
    ('''            lines += [f'[sub_resource type="StandardMaterial3D" id="Material_{key}"]',
                      "albedo_color''', '''            lines += [f'[sub_resource type="StandardMaterial3D" id="Material_{key}"]', f'resource_name = "{key}"',
                      "albedo_color'''),
    ('''    post(scene, sx, sz, 0.14, 1.9, label="épouvantail")
    crow(scene, sx + 0.55, 1.49, sz, 100.0)''', '''    post(scene, sx, sz, 0.14, 1.9, label="épouvantail")'''),
    ('''    crow(scene, 21.7, top_of("nature_kit/fence_simple", 2.4), 17.6, 30.0)
    crow(scene, 26.2, top_of("nature_kit/fence_simple", 2.4), 17.6, 250.0)
''', ''),
    ('''    # Corbeaux sur le rempart, la tour de la porte et la place.
    for x, y, z, degrees, pecking in ((-22.4, 5.24, 41.0, 160.0, False), (13.4, 5.24, 41.1, 200.0, False),
                                      (14.3, 5.24, 40.8, 120.0, False), (6.6, 9.2, 42.6, 10.0, False),
                                      (-6.2, 0.0, -6.4, 40.0, True), (-5.5, 0.0, -7.3, 300.0, True),
                                      (7.4, 0.0, 5.2, 200.0, True), (-25.6, 0.0, 30.6, 90.0, True),
                                      (-1.6, 0.0, 37.6, 120.0, True), (30.2, 5.24, -21.6, 250.0, False)):
        crow(scene, x, y, z, degrees, pecking)
''', '''    # Les corbeaux, qui s'envolent quand on approche, sont posés dans village.tscn (village_crow.gd).
'''),
    ('''    """Les chats restés au village : l'un garde la porte de la mairie, l'autre dort sur une caisse de la rue."""
    cat(scene, -2.7, 0.0, -18.9, 160.0, "cat_black")
''', '''    """Les chats restés au village : l'un dort sur une caisse de la rue (le gris du puits est posé avec le puits ; ceux
    qui se promènent sont dans village.tscn, village_cat.gd)."""
'''),
])

patch(particles, [
    ('''enum Kind { EMBERS, DUST }''', '''enum Kind { EMBERS, DUST, SPLASH }'''),
    ('''	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD''', '''	if kind != Kind.SPLASH:
		material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD'''),
    ('''	else:
		quad.size = Vector2.ONE * 0.045''', '''	elif kind == Kind.SPLASH:
		# Gouttes soulevées par les pales de la roue, qui retombent dans le ruisseau.
		quad.size = Vector2.ONE * 0.07
		amount = 26
		lifetime = 0.9
		preprocess = 1.0
		direction = Vector3(0, 1, 0.4)
		spread = 35.0
		gravity = Vector3(0, -9.0, 0)
		initial_velocity_min = 1.6
		initial_velocity_max = 3.0
		fade.set_color(0, Color(tint, 0.9))
		fade.set_color(1, Color(tint, 0.0))
	else:
		quad.size = Vector2.ONE * 0.045'''),
])

patch(writer, [
    ('''    ("AudioStream", A + "cave_ambience.wav", "63_hall"),
''', '''    ("AudioStream", A + "cave_ambience.wav", "63_hall"),
    ("Script", "res://scenes/levels/village/village_crow.gd", "64_crow"),
    ("Script", "res://scenes/levels/village/village_cat.gd", "65_cat"),
    ("Script", "res://scenes/levels/village/village_life.gd", "66_life"),
'''),
    ('''# Sons posés sur les objets : nom, son, position, volume, portée.''', '''# Corbeaux : position (les pieds), orientation, penché pour picorer. Sur le rempart et la tour de la porte, sur
# l'épouvantail, la clôture de l'enclos, le faîte des écuries, et au sol parmi les vivres de la place.
CROWS = [
    ((-22.4, 5.24, 41.0), 160.0, False), ((13.4, 5.24, 41.1), 200.0, False), ((14.3, 5.24, 40.8), 120.0, False),
    ((6.6, 9.2, 42.6), 10.0, False), ((-27.25, 1.49, 25.5), 100.0, False), ((21.7, 0.84, 17.6), 30.0, False),
    ((26.2, 0.84, 17.6), 250.0, False), ((24.0, 5.37, 31.0), 90.0, False),
    ((-6.2, 0.0, -6.4), 40.0, True), ((-5.5, 0.0, -7.3), 300.0, True), ((7.4, 0.0, 5.2), 200.0, True),
    ((-25.6, 0.0, 30.6), 90.0, True), ((-1.6, 0.0, 37.6), 120.0, True),
]
# Chats qui se promènent : pelage et points de passage. Le noir devant la mairie, le tigré autour du puits.
CATS = [
    ("Color(0.07, 0.07, 0.08, 1)", [(-4.6, 0.0, -18.7), (-1.9, 0.0, -18.4), (-3.4, 0.0, -17.3)]),
    ("Color(0.45, 0.36, 0.27, 1)", [(-17.2, 0.0, 26.6), (-18.6, 0.0, 31.4), (-21.8, 0.0, 31.6), (-17.0, 0.0, 30.0)]),
]
# Sons posés sur les objets : nom, son, position, volume, portée.'''),
    ('''    node(lines, "Sounds", "Node3D")''', '''    node(lines, "Crows", "Node3D")
    for index, ((x, y, z), degrees, pecking) in enumerate(CROWS):
        node(lines, f"Crow{index}", "Node3D", "Crows", props=[at(x, y, z, 1.0, degrees), 'script = ExtResource("64_crow")']
             + (["pecking = true"] if pecking else []))
    node(lines, "Cats", "Node3D")
    for index, (coat, points) in enumerate(CATS):
        array = ", ".join(f"{x:g}, {y:g}, {z:g}" for x, y, z in points)
        node(lines, f"Cat{index}", "Node3D", "Cats", props=[at(*points[0]), 'script = ExtResource("65_cat")',
                                                          f"coat = {coat}", f"waypoints = PackedVector3Array({array})"])
    # Le linge et les bannières ondulent au vent (village_life.gd).
    node(lines, "Life", "Node", props=['script = ExtResource("66_life")',
                                       'roots = Array[NodePath]([NodePath("../Props"), NodePath("../Interior/Hall")])'])
    node(lines, "WheelSplash", "CPUParticles3D", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -36.5, -0.35, -14)", 'script = ExtResource("60_particles")',
        "kind = 2", "extents = Vector3(0.35, 0.05, 1.5)", "tint = Color(0.75, 0.86, 0.95, 1)"])
    node(lines, "Sounds", "Node3D")'''),
])
print("ok")
