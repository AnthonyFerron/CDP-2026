REPLACEMENTS = [
('''[sub_resource type="BoxShape3D" id="BoxShape3D_throne"]
size = Vector3(4, 3.2, 2.6)''', '''[sub_resource type="BoxShape3D" id="BoxShape3D_throne"]
size = Vector3(2.1, 3.35, 1.45)

[sub_resource type="BoxShape3D" id="BoxShape3D_dais"]
size = Vector3(4, 0.3, 2.6)'''),
('''    node(lines, "Shape", "CollisionShape3D", "Castle/Throne", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.6, 0)", 'shape = SubResource("BoxShape3D_throne")'])''',
 '''    # L'estrade et le trône ont chacun leur collision : on peut monter sur l'estrade à côté du trône.
    node(lines, "Shape", "CollisionShape3D", "Castle/Throne", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.675, 0.05)", 'shape = SubResource("BoxShape3D_throne")'])
    node(lines, "DaisShape", "CollisionShape3D", "Castle/Throne", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.15, 0)", 'shape = SubResource("BoxShape3D_dais")'])'''),
]
