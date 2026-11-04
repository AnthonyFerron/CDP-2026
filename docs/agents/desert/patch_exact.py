"""Murs invisibles restants de la grille (rien de visible à moins d'1 m) : étals ouverts, charrette renversée et
bannières sur pied prennent une collision taillée sur leurs triangles (desert.gd) ; la porte des vents a ses deux
piliers, son linteau et sa grille au lieu d'une boîte pleine."""
from pathlib import Path

F = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend")


def patch(path, pairs):
    t = path.read_bytes().decode("utf-8")
    for old, new in pairs:
        assert t.count(old) == 1, old
        t = t.replace(old, new)
    path.write_bytes(t.encode("utf-8"))


patch(F / "tools/build_desert.py", [
    ('''def put(scene, model, center, degrees=0.0, scale=1.0, height=None, tilt=0.0, roll=0.0, label=None):
    """furniture() de build_plaine, en retenant l'emprise de ce qui a une collision."""
    furniture(scene, model, center, degrees, scale, height=height, tilt=tilt, roll=roll)
''', '''def put(scene, model, center, degrees=0.0, scale=1.0, height=None, tilt=0.0, roll=0.0, label=None, box=True):
    """furniture() de build_plaine, en retenant l'emprise de ce qui a une collision. box=False : pas de boîte,
    desert.gd taille la collision du modèle sur ses triangles (EXACT_MODELS), l'emprise reste vérifiée."""
    furniture(scene, model, center, degrees, scale, height=height if box else None, tilt=tilt, roll=roll)
'''),
    ('''        scene.add("mini_arena/banner", (x, 0.0, -17.5), 0.0, 3.4)
        scene.add_box((x, 1.75, -17.5), (2.0, 3.5, 0.8))
''', '''        # Collision taillée sur la bannière par desert.gd (EXACT_MODELS) : son pied, sa hampe et sa toile.
        scene.add("mini_arena/banner", (x, 0.0, -17.5), 0.0, 3.4)
'''),
    ('''    put(scene, "fantasy_town_kit/stall-red", at(-6.0, 3.4), heading + 90.0, 2.6, height=3.2)
    put(scene, "fantasy_town_kit/stall-green", at(5.8, 3.8), heading - 90.0, 2.6, height=3.2)
''', '''    # Étals ouverts sous leur auvent : collision taillée sur leurs triangles par desert.gd (EXACT_MODELS).
    put(scene, "fantasy_town_kit/stall-red", at(-6.0, 3.4), heading + 90.0, 2.6, height=3.2, box=False)
    put(scene, "fantasy_town_kit/stall-green", at(5.8, 3.8), heading - 90.0, 2.6, height=3.2, box=False)
'''),
    ('''    put(scene, "fantasy_town_kit/cart", at(-1.0, -7.0), heading + 100.0, 2.8, height=1.5, roll=90.0)
''', '''    put(scene, "fantasy_town_kit/cart", at(-1.0, -7.0), heading + 100.0, 2.8, height=1.5, roll=90.0, box=False)
'''),
    ('''    scene.add("mini_arena/wall-gate", (x, -0.6, z), 35.0, 3.6)
    scene.add_box((x, 1.5, z), (3.6, 3.0, 2.2), 35.0)
''', '''    scene.add("mini_arena/wall-gate", (x, -0.6, z), 35.0, 3.6)
    # Ses deux piliers, son linteau et sa grille baissée, comme l'arche d'entrée : pas de boîte pleine
    # qui arrêterait le joueur à un mètre de la grille.
    scale = 3.6
    side = (0.5 - GATE_HALF_OPENING) * scale
    offset = GATE_HALF_OPENING * scale + side / 2
    for sign in (-1, 1):
        scene.box_collider((x + math.cos(math.radians(35.0)) * sign * offset, -0.6 + scale / 2,
                            z - math.sin(math.radians(35.0)) * sign * offset), (side, scale, 0.6 * scale), 35.0)
    lintel = scale * (1 - GATE_OPENING_HEIGHT)
    scene.box_collider((x, -0.6 + scale - lintel / 2, z), (GATE_HALF_OPENING * 2 * scale, lintel, 0.6 * scale), 35.0)
    opening = scale * GATE_OPENING_HEIGHT
    scene.box_collider((x, -0.6 + opening / 2, z), (GATE_HALF_OPENING * 2 * scale, opening, 0.5), 35.0)
'''),
])

patch(F / "scenes/levels/desert/desert.gd", [
    ('''const CAIRN_STONE := Color(0.7, 0.58, 0.46)
''', '''const CAIRN_STONE := Color(0.7, 0.58, 0.46)
## Modèles des ruines dont une boîte laisserait des murs invisibles (étals ouverts sous leur auvent, charrette
## renversée, bannières sur pied) : leur collision suit leurs triangles.
const EXACT_MODELS: Array[String] = ["cart_", "stall_", "banner_"]
'''),
    ('''	_tint_stone($Exterior/Ruins)
''', '''	_tint_stone($Exterior/Ruins)
	_exact_colliders($Exterior/Ruins)
'''),
    ('''## Modèle du kit auquel appartient un maillage : l'enfant du nœud Models qui le contient.
''', '''## Collision des modèles EXACT_MODELS : leurs triangles, dans un corps à part, avant le regroupement des maillages.
func _exact_colliders(root: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "ExactCollision"
	root.add_child(body)
	var inverse := body.global_transform.affine_inverse()
	for model: Node in root.get_node("Models").get_children():
		var exact := false
		for prefix in EXACT_MODELS:
			exact = exact or String(model.name).begins_with(prefix)
		if not exact:
			continue
		for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			if not mesh.mesh:
				continue
			var xform := inverse * mesh.global_transform
			var faces := mesh.mesh.get_faces()
			for index in faces.size():
				faces[index] = xform * faces[index]
			var shape := ConcavePolygonShape3D.new()
			shape.set_faces(faces)
			# La toile d'une bannière n'a qu'une face : elle arrête aussi le joueur qui vient de derrière.
			shape.backface_collision = true
			var holder := CollisionShape3D.new()
			holder.shape = shape
			body.add_child(holder)


## Modèle du kit auquel appartient un maillage : l'enfant du nœud Models qui le contient.
'''),
])
print("ok")
