"""Stèles sculptées des deux côtés, panneaux sur poteaux lisibles des deux côtés, cadre des dalles des algorithmes,
lumière ambiante chaude dehors (le ciel bleu ne donne plus que 30 % de l'ambiance : ombres moins vert-gris)."""
from pathlib import Path

p = Path(__file__).parent / "write_desert_tscn.py"
t = p.read_text(encoding="utf-8")


def sub(old, new, count=1):
    global t
    assert t.count(old) == count, (old, t.count(old))
    t = t.replace(old, new)


# --- Ambiance : la couleur chaude domine, le ciel n'apporte qu'une part de la lumière ambiante. ---
sub('ambient_light_color = Color(0.85, 0.72, 0.55, 1)\nambient_light_energy = 0.3\n',
    'ambient_light_color = Color(0.85, 0.72, 0.55, 1)\nambient_light_sky_contribution = 0.3\nambient_light_energy = 0.3\n')

# --- Ressources des stèles : socle, fût, corniche, fronton, cadre en relief. ---
sub('''[sub_resource type="BoxMesh" id="BoxMesh_stele"]
material = SubResource("StandardMaterial3D_sandstone")
size = Vector3(1.4, 2.8, 0.5)

[sub_resource type="BoxShape3D" id="BoxShape3D_stele"]
size = Vector3(1.4, 2.8, 0.5)
''', '''[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_sandstone_dark"]
albedo_color = Color(0.6, 0.43, 0.27, 1)
roughness = 1.0

[sub_resource type="BoxMesh" id="BoxMesh_stele"]
material = SubResource("StandardMaterial3D_sandstone")
size = Vector3(1.3, 2.5, 0.46)

[sub_resource type="BoxShape3D" id="BoxShape3D_stele"]
size = Vector3(1.3, 2.5, 0.46)

[sub_resource type="BoxMesh" id="BoxMesh_stele_plinth"]
material = SubResource("StandardMaterial3D_sandstone_dark")
size = Vector3(1.8, 0.4, 0.9)

[sub_resource type="BoxShape3D" id="BoxShape3D_stele_plinth"]
size = Vector3(1.8, 0.4, 0.9)

[sub_resource type="BoxMesh" id="BoxMesh_stele_cap"]
material = SubResource("StandardMaterial3D_sandstone_dark")
size = Vector3(1.5, 0.2, 0.62)

[sub_resource type="BoxShape3D" id="BoxShape3D_stele_cap"]
size = Vector3(1.5, 0.2, 0.62)

[sub_resource type="PrismMesh" id="PrismMesh_stele_top"]
material = SubResource("StandardMaterial3D_sandstone")
size = Vector3(1.5, 0.42, 0.56)

[sub_resource type="BoxMesh" id="BoxMesh_stele_frame_v"]
material = SubResource("StandardMaterial3D_sandstone_dark")
size = Vector3(0.08, 2.3, 0.03)

[sub_resource type="BoxMesh" id="BoxMesh_stele_frame_h"]
material = SubResource("StandardMaterial3D_sandstone_dark")
size = Vector3(1.14, 0.08, 0.03)

[sub_resource type="BoxMesh" id="BoxMesh_algo_frame_v"]
material = SubResource("StandardMaterial3D_sandstone_dark")
size = Vector3(0.04, 2.6, 0.1)

[sub_resource type="BoxMesh" id="BoxMesh_algo_frame_h"]
material = SubResource("StandardMaterial3D_sandstone_dark")
size = Vector3(0.04, 0.1, 3.8)
''')

# La stèle du couchant tourne sa face vers l'arche (z = 16), d'où l'on arrive.
sub('("Couchant", -7.0, 8.0, 160.0, ', '("Couchant", -7.0, 8.0, 35.0, ')

old_stele = t[t.index('        node(lines, "Mesh", "MeshInstance3D", f"Exterior/Clues/{name}", props=[\n            "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.4, 0)", \'mesh = SubResource("BoxMesh_stele")\'])'):
              t.index('    node(lines, "Interior", "Node3D"')]
new_stele = '''        # Socle, fût, corniche et fronton ; les deux faces portent le même cadre, le même soleil et le même nom
        # gravés : la stèle n'a pas de dos nu, d'où qu'on arrive.
        for part, mesh, y in (("Plinth", "BoxMesh_stele_plinth", 0.2), ("Mesh", "BoxMesh_stele", 1.65),
                              ("Cap", "BoxMesh_stele_cap", 3.0), ("Top", "PrismMesh_stele_top", 3.31)):
            node(lines, part, "MeshInstance3D", f"Exterior/Clues/{name}", props=[
                f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {y:g}, 0)", f'mesh = SubResource("{mesh}")'])
        for face, sign in (("Front", 1.0), ("Back", -1.0)):
            yaw_face = 0.0 if sign > 0 else 180.0
            node(lines, face, "Node3D", f"Exterior/Clues/{name}", props=[at(0, 0, 0, 1.0, yaw_face)])
            for part, mesh, x, y in (("FrameLeft", "BoxMesh_stele_frame_v", -0.5, 1.65), ("FrameRight", "BoxMesh_stele_frame_v", 0.5, 1.65),
                                     ("FrameLow", "BoxMesh_stele_frame_h", 0.0, 0.54), ("FrameHigh", "BoxMesh_stele_frame_h", 0.0, 2.76)):
                node(lines, part, "MeshInstance3D", f"Exterior/Clues/{name}/{face}", props=[
                    f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, 0.245)", f'mesh = SubResource("{mesh}")'])
            # Soleil gravé : un disque et huit rayons, en relief sur la face de la stèle.
            node(lines, "Sun", "Node3D", f"Exterior/Clues/{name}/{face}", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.15, 0.24)"])
            node(lines, "Disc", "MeshInstance3D", f"Exterior/Clues/{name}/{face}/Sun", props=[
                "transform = Transform3D(1, 0, 0, 0, 0, -1, 0, 1, 0, 0, 0, 0)", 'mesh = SubResource("CylinderMesh_sun_disc")'])
            for ray in range(8):
                angle = math.radians(ray * 45.0)
                c, s_ = math.cos(angle), math.sin(angle)
                node(lines, f"Ray{ray}", "MeshInstance3D", f"Exterior/Clues/{name}/{face}/Sun", props=[
                    f"transform = Transform3D({c:.6g}, {-s_:.6g}, 0, {s_:.6g}, {c:.6g}, 0, 0, 0, 1, {-s_ * 0.33:.4g}, {c * 0.33:.4g}, 0)",
                    'mesh = SubResource("BoxMesh_sun_ray")'])
            # Nom de la stèle gravé dans la pierre, à fleur de sa face.
            node(lines, "Engraving", "Label3D", f"Exterior/Clues/{name}/{face}", props=[
                "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.35, 0.232)", "pixel_size = 0.0033", "shaded = true",
                "double_sided = false", "alpha_cut = 1", "modulate = Color(0.3, 0.17, 0.08, 1)", f'text = "{engraved}"',
                "font_size = 64", "outline_size = 0"])
        node(lines, "Body", "StaticBody3D", f"Exterior/Clues/{name}")
        for part, shape, y in (("Plinth", "BoxShape3D_stele_plinth", 0.2), ("CollisionShape3D", "BoxShape3D_stele", 1.65),
                               ("Cap", "BoxShape3D_stele_cap", 3.0)):
            node(lines, part, "CollisionShape3D", f"Exterior/Clues/{name}/Body", props=[
                f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {y:g}, 0)", f'shape = SubResource("{shape}")'])

'''
t = t.replace(old_stele, new_stele)

# --- Panneaux sur poteaux : cadre et texte des deux côtés, plus de dos de planche nu. ---
sub('"board_size = Vector2(1.9, 0.9)", "board_height = 1.6", "line_height = 0.16", "collision = false"])',
    '"board_size = Vector2(1.9, 0.9)", "board_height = 1.6", "line_height = 0.16", "double_sided = true", "collision = false"])')
sub('''            if mount == 0:
                props.append("collision = false")''', '''            if mount == 0:
                props += ["double_sided = true", "collision = false"]''')

# --- Dalles des algorithmes : un cadre de grès sombre en relief autour du texte. ---
sub('''        node(lines, "Shape", "CollisionShape3D", f"Interior/Clues/{name}/Slab", props=[
            'shape = SubResource("BoxShape3D_algo_slab")'])
''', '''        node(lines, "Shape", "CollisionShape3D", f"Interior/Clues/{name}/Slab", props=[
            'shape = SubResource("BoxShape3D_algo_slab")'])
        face_x = -side * (0.175 + 0.02)
        for part, mesh, y, z in (("FrameLeft", "BoxMesh_algo_frame_v", 0.0, -1.85), ("FrameRight", "BoxMesh_algo_frame_v", 0.0, 1.85),
                                 ("FrameLow", "BoxMesh_algo_frame_h", -1.25, 0.0), ("FrameHigh", "BoxMesh_algo_frame_h", 1.25, 0.0)):
            node(lines, part, "MeshInstance3D", f"Interior/Clues/{name}/Slab", props=[
                f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {face_x:g}, {y:g}, {z:g})", f'mesh = SubResource("{mesh}")'])
''')

p.write_text(t, encoding="utf-8")
print("ok")
