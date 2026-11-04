from pathlib import Path

p = Path("C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/write_desert_tscn.py")
t = p.read_text(encoding="utf-8")


def rep(old, new, count=1):
    global t
    assert t.count(old) == count, (t.count(old), old[:90])
    t = t.replace(old, new)


rep('''"""Écrit la première version de frontend/scenes/levels/desert/desert.tscn."""''',
    '''"""Écrit frontend/scenes/levels/desert/desert.tscn, le désert de Pythania (argument : le dossier frontend)."""''')
# Ressources : le panneau d'entrée devient un SignBoard, les restes épars des dunes.
rep('''    ("PackedScene", K + "survival_kit/signpost.glb", "14_signpost"),
''', '''    ("Script", "res://scripts/sign_board.gd", "14_sign"),
''')
rep('''    ("PackedScene", K + "castle_kit/siege-ram-demolished.glb", "28_ram"),
''', '''    ("PackedScene", K + "castle_kit/siege-ram-demolished.glb", "28_ram"),
    ("PackedScene", K + "mini_dungeon/weapon-spear.glb", "29_spear"),
    ("PackedScene", K + "mini_dungeon/shield-round.glb", "30_shield"),
    ("PackedScene", K + "mini_dungeon/weapon-sword.glb", "31_sword"),
    ("PackedScene", K + "mini_dungeon/pot.glb", "32_pot"),
    ("PackedScene", K + "fantasy_town_kit/wheel.glb", "33_wheel"),
    ("PackedScene", K + "mini_dungeon/barrel.glb", "34_barrel"),
    ("PackedScene", K + "graveyard_kit/character-skeleton.glb", "35_skeleton"),
''')
rep('''    ("PackedScene", K + "mini_dungeon/chest.glb", "19_chest"),
''', '')
rep('''    ("AudioStream", A + "fire_crackle.wav", "52_crackle"),
''', '''    ("AudioStream", A + "fire_crackle.wav", "52_crackle"),
    ("AudioStream", A + "stone_door.wav", "53_rumble"),
''')

# Matériaux : trappe de pierre, table ronde de pierre, coffre de pierre, carnet, sable sur la trappe.
rep('''[sub_resource type="BoxMesh" id="BoxMesh_plank"]
material = SubResource("StandardMaterial3D_wood")
size = Vector3(0.55, 0.12, 2.4)

[sub_resource type="BoxMesh" id="BoxMesh_strap"]
material = SubResource("StandardMaterial3D_iron")
size = Vector3(2.5, 0.14, 0.18)
''', '''[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_hatch_stone"]
albedo_color = Color(0.7, 0.55, 0.4, 1)
roughness = 1.0

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_groove"]
albedo_color = Color(0.36, 0.26, 0.17, 1)
roughness = 1.0

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_bronze"]
albedo_color = Color(0.4, 0.27, 0.13, 1)
metallic = 0.6
roughness = 0.5

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_drift"]
albedo_color = Color(0.84, 0.64, 0.4, 1)
roughness = 1.0

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_void"]
albedo_color = Color(0.02, 0.015, 0.01, 1)
roughness = 1.0

[sub_resource type="BoxMesh" id="BoxMesh_hatch_slab"]
material = SubResource("StandardMaterial3D_hatch_stone")
size = Vector3(1.17, 0.16, 2.4)

[sub_resource type="BoxMesh" id="BoxMesh_hatch_groove"]
material = SubResource("StandardMaterial3D_groove")
size = Vector3(0.05, 0.02, 2.2)

[sub_resource type="TorusMesh" id="TorusMesh_ring"]
material = SubResource("StandardMaterial3D_bronze")
inner_radius = 0.11
outer_radius = 0.16
rings = 12
ring_segments = 4

[sub_resource type="SphereMesh" id="SphereMesh_drift"]
material = SubResource("StandardMaterial3D_drift")
radial_segments = 12
rings = 6

[sub_resource type="BoxMesh" id="BoxMesh_hole"]
material = SubResource("StandardMaterial3D_void")
size = Vector3(2.3, 0.02, 2.3)

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_leather"]
albedo_color = Color(0.32, 0.18, 0.09, 1)
roughness = 0.9

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_paper"]
albedo_color = Color(0.88, 0.8, 0.6, 1)
roughness = 1.0

[sub_resource type="BoxMesh" id="BoxMesh_notebook"]
material = SubResource("StandardMaterial3D_leather")
size = Vector3(0.34, 0.06, 0.46)

[sub_resource type="BoxMesh" id="BoxMesh_pages"]
material = SubResource("StandardMaterial3D_paper")
size = Vector3(0.31, 0.045, 0.43)

[sub_resource type="BoxMesh" id="BoxMesh_cord"]
material = SubResource("StandardMaterial3D_groove")
size = Vector3(0.36, 0.065, 0.025)
''')
rep('''[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_cave_stone"]
albedo_color = Color(0.36, 0.29, 0.23, 1)
roughness = 1.0
''', '''[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_cave_stone"]
albedo_color = Color(0.36, 0.29, 0.23, 1)
roughness = 1.0

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_rock"]
albedo_color = Color(0.5, 0.46, 0.41, 1)
roughness = 1.0

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_rock_dark"]
albedo_color = Color(0.3, 0.27, 0.24, 1)
roughness = 1.0

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_slot"]
albedo_color = Color(0.12, 0.11, 0.1, 1)
roughness = 0.8
emission_enabled = true
emission = Color(0.3, 0.6, 1, 1)
emission_energy_multiplier = 0.0

[sub_resource type="CylinderMesh" id="CylinderMesh_table_base"]
material = SubResource("StandardMaterial3D_rock")
top_radius = 1.2
bottom_radius = 1.4
height = 0.8
radial_segments = 10

[sub_resource type="CylinderMesh" id="CylinderMesh_table_top"]
material = SubResource("StandardMaterial3D_rock")
top_radius = 1.6
bottom_radius = 1.65
height = 0.22
radial_segments = 20

[sub_resource type="TorusMesh" id="TorusMesh_table_rim"]
material = SubResource("StandardMaterial3D_rock_dark")
inner_radius = 1.52
outer_radius = 1.68
rings = 20
ring_segments = 4

[sub_resource type="BoxMesh" id="BoxMesh_slot"]
material = SubResource("StandardMaterial3D_slot")
size = Vector3(0.5, 0.02, 0.36)

[sub_resource type="CylinderMesh" id="CylinderMesh_table_sun"]
material = SubResource("StandardMaterial3D_rock_dark")
top_radius = 0.32
bottom_radius = 0.32
height = 0.02
radial_segments = 16

[sub_resource type="BoxMesh" id="BoxMesh_chest_body"]
material = SubResource("StandardMaterial3D_rock")
size = Vector3(1.5, 0.75, 0.95)

[sub_resource type="BoxMesh" id="BoxMesh_chest_lid"]
material = SubResource("StandardMaterial3D_rock")
size = Vector3(1.6, 0.24, 1.04)

[sub_resource type="BoxMesh" id="BoxMesh_chest_band"]
material = SubResource("StandardMaterial3D_bronze")
size = Vector3(1.62, 0.08, 1.06)

[sub_resource type="BoxMesh" id="BoxMesh_chest_lock"]
material = SubResource("StandardMaterial3D_bronze")
size = Vector3(0.22, 0.26, 0.06)

[sub_resource type="BoxShape3D" id="BoxShape3D_chest"]
size = Vector3(1.7, 1.0, 1.7)
''')
rep('''[sub_resource type="BoxMesh" id="BoxMesh_algo_slab"]
material = SubResource("StandardMaterial3D_cave_stone")''', '''[sub_resource type="BoxMesh" id="BoxMesh_algo_slab"]
material = SubResource("StandardMaterial3D_rock")''')
rep('''[sub_resource type="CylinderMesh" id="CylinderMesh_table"]
material = SubResource("StandardMaterial3D_sandstone")
top_radius = 1.6
bottom_radius = 1.4
height = 1.0
radial_segments = 20

''', '')

# Stèles : dans les chambres du levant et du zénith, et dans l'avant-cour ; textes des anciens bâtisseurs.
rep('''STELES = [
    ("Levant", -13.0, -12.0, 60.0, "Stèle du levant",
     "Les bâtisseurs répétaient le même geste tant que l'ouvrage n'était pas achevé, puis seulement passaient à la suite."),
    ("Zenith", 13.0, -12.0, -60.0, "Stèle du zénith",
     "Avant d'ouvrir une porte, ils posaient une question. Selon la réponse, ils agissaient d'une façon, sinon d'une autre."),
    ("Couchant", -7.0, 8.0, 160.0, "Stèle du couchant",
     "Leurs instructions sont gravées sur des runes, dispersées dans les ruines et ensevelies sous le sable."),
]''', '''STELES = [
    ("Levant", -17.6, -12.0, 90.0, "Stèle du levant", "LEVANT",
     "Les anciens bâtisseurs répétaient le même geste tant que l'ouvrage n'était pas achevé, puis seulement passaient à la suite. Ainsi la jarre se remplit, seau après seau."),
    ("Zenith", 17.6, -12.0, -90.0, "Stèle du zénith", "ZÉNITH",
     "Avant d'ouvrir une porte, les bâtisseurs posaient une question. Selon la réponse, ils agissaient d'une façon, sinon d'une autre."),
    ("Couchant", -7.0, 8.0, 160.0, "Stèle du couchant", "COUCHANT",
     "Leurs instructions sont gravées sur des runes. Quand le sable a recouvert le monument, elles se sont dispersées dans ses salles, parmi les débris, et sous les dunes."),
]''')
rep('''RUNES = [
    ("tant_que", -11.6, 0.0, -10.4, False, False),''', '''RUNES = [
    ("tant_que", -15.4, 0.0, -14.4, False, False),''')
rep('''PILES = [
    ("PileWest", -9.0, -1.0, False, "puiser"),
    ("PileStatue", 7.0, -15.0, False, ""),
    ("PileGate", -4.0, 8.0, False, ""),
    ("PileCaveWest", -6.5, -8.8, True, "ouvrir"),
    ("PileCaveEast", 6.0, -4.4, True, "sinon"),
    ("PileCaveCorner", 6.5, -8.8, True, ""),
]''', '''PILES = [
    ("PileWest", -9.0, -1.0, False, "puiser"),
    ("PileEastRoom", 15.6, -9.4, False, ""),
    ("PileGate", -4.0, 8.0, False, ""),
    ("PileCaveWest", -6.5, -8.8, True, "ouvrir"),
    ("PileCaveEast", 6.0, -4.4, True, "sinon"),
    ("PileCaveNorth", -3.6, -8.2, True, ""),
]
# Coffre de pierre du livre, dans le coin nord-est de la cave, sous son tas de sable ; sa face regarde la salle.
CHEST = (7.6, -9.8, -63.0)''')

# Panneau d'entrée : un SignBoard de bois sur deux poteaux, face au portail.
rep('''    node(lines, "Sign", parent="Exterior", instance="14_signpost", props=[at(-5, 0, 44, 2.5)])
    node(lines, "SignText", "Label3D", "Exterior", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -5, 3.8, 44)", "pixel_size = 0.007", "billboard = 1",
        "modulate = Color(1, 0.9, 0.7, 1)", 'text = "Le Désert\\\\nLes archives du soleil"', "font_size = 64",
        "outline_size = 16"])''', '''    node(lines, "Sign", "Node3D", "Exterior", props=[
        at(-4.4, 0, 45.5, 1.0, 15.0), 'script = ExtResource("14_sign")', 'text = "Désert de Pythania\\\\nMonument des anciens bâtisseurs"',
        "board_size = Vector2(1.9, 0.9)", "board_height = 1.6", "line_height = 0.16"])''')

# Trappe de pierre, à demi recouverte de sable.
rep('''    node(lines, "Hatch", "Node3D", "Exterior/Trapdoor", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1.2)"])
    for index, x in enumerate((-0.9, -0.3, 0.3, 0.9)):
        node(lines, f"Plank{index}", "MeshInstance3D", "Exterior/Trapdoor/Hatch", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, 0, -1.2)", 'mesh = SubResource("BoxMesh_plank")'])
    for index, z in enumerate((-2.0, -0.4)):
        node(lines, f"Strap{index}", "MeshInstance3D", "Exterior/Trapdoor/Hatch", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.05, {z:g})", 'mesh = SubResource("BoxMesh_strap")'])
    node(lines, "Interactable", "Node3D", "Exterior/Trapdoor", props=[
        'script = ExtResource("11_interactable")', 'prompt = "Soulever la trappe et descendre"', "radius = 2.6"])''',
    '''    node(lines, "Hole", "MeshInstance3D", "Exterior/Trapdoor", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.05, 0)", 'mesh = SubResource("BoxMesh_hole")'])
    node(lines, "Hatch", "Node3D", "Exterior/Trapdoor", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1.2)"])
    for index, x in enumerate((-0.6, 0.6)):
        node(lines, f"Slab{index}", "MeshInstance3D", "Exterior/Trapdoor/Hatch", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, 0, -1.2)", 'mesh = SubResource("BoxMesh_hatch_slab")'])
        node(lines, f"Groove{index}", "MeshInstance3D", "Exterior/Trapdoor/Hatch", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x * 0.5:g}, 0.081, -1.2)", 'mesh = SubResource("BoxMesh_hatch_groove")'])
    node(lines, "Ring", "MeshInstance3D", "Exterior/Trapdoor/Hatch", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -0.3, 0.09, -0.35)", 'mesh = SubResource("TorusMesh_ring")'])
    # Le sable couvre une partie de la dalle : il se soulève avec elle.
    node(lines, "Drift", "MeshInstance3D", "Exterior/Trapdoor/Hatch", props=[
        "transform = Transform3D(0.75, 0, 0, 0, 0.12, 0, 0, 0, 1.25, 0.75, 0.06, -1.5)", 'mesh = SubResource("SphereMesh_drift")'])
    node(lines, "Interactable", "Node3D", "Exterior/Trapdoor", props=[
        'script = ExtResource("11_interactable")', 'prompt = "Soulever la trappe de pierre et descendre"', "radius = 2.6"])''')

# Stèles : nom gravé sous le soleil.
rep('''    for name, x, z, yaw, title, body in STELES:''', '''    for name, x, z, yaw, title, engraved, body in STELES:''')
rep('''        node(lines, "Body", "StaticBody3D", f"Exterior/Clues/{name}")
        node(lines, "CollisionShape3D", "CollisionShape3D", f"Exterior/Clues/{name}/Body", props=[
            "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.4, 0)", 'shape = SubResource("BoxShape3D_stele")'])''',
    '''        # Nom de la stèle gravé dans la pierre, à fleur de sa face.
        node(lines, "Engraving", "Label3D", f"Exterior/Clues/{name}", props=[
            "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.45, 0.262)", "pixel_size = 0.0035", "shaded = true",
            "double_sided = false", "alpha_cut = 1", "modulate = Color(0.3, 0.17, 0.08, 1)", f'text = "{engraved}"',
            "font_size = 64", "outline_size = 0"])
        node(lines, "Body", "StaticBody3D", f"Exterior/Clues/{name}")
        node(lines, "CollisionShape3D", "CollisionShape3D", f"Exterior/Clues/{name}/Body", props=[
            "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.4, 0)", 'shape = SubResource("BoxShape3D_stele")'])''')

# Torches plus faibles : la cave est sombre.
rep('''            "light_energy = 2.2", "light_range = 8.0", 'crackle_sound = ExtResource("52_crackle")', "crackle_volume_db = -14.0"])''',
    '''            "light_energy = 1.5", "light_range = 7.0", 'crackle_sound = ExtResource("52_crackle")', "crackle_volume_db = -14.0"])''')
rep('''        "light_energy = 1.4", "omni_range = 6.0"])
    # Torches''', '''        "light_energy = 1.0", "omni_range = 6.0"])
    # Torches''')
# La sortie se tient au pied de l'escalier, pas dans sa collision.
rep('''        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.2, 0.6)", 'script = ExtResource("11_interactable")',''',
    '''        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.2, 0.05)", 'script = ExtResource("11_interactable")',''')

# Carnet du caravanier, posé sur la caisse de la caravane, et son texte.
rep('''    node(lines, "Caravan", "Node3D", "Exterior/Clues", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -33.25, 0.8, -30.75)", 'script = ExtResource("12_readable")',
        'title = "Le carnet du caravanier"', 'body = "Carnet d\\'un caravanier. Trois jours que la tempête nous tient. Le vieux guide dit que les bâtisseurs du sanctuaire écrivaient leurs ordres sur des runes, et qu\\'il suffit de les remettre dans l\\'ordre pour que le sable rende ce qu\\'il garde. Nous en avons vu briller sous les dunes, autour de l\\'esplanade. Certains tas ne cachent rien : il faut creuser quand même."', 'prompt = "Lire le carnet"', "radius = 2.4"])''',
    '''    node(lines, "Caravan", "Node3D", "Exterior/Clues", props=[
        at(-32.85, 0.9, -30.29, 1.0, 70.0), 'script = ExtResource("12_readable")',
        'title = "Le carnet du caravanier"', f"body = {quote(CARAVAN)}", 'prompt = "Lire le carnet"', "radius = 2.4"])
    node(lines, "Cover", "MeshInstance3D", "Exterior/Clues/Caravan", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.03, 0)", 'mesh = SubResource("BoxMesh_notebook")'])
    node(lines, "Pages", "MeshInstance3D", "Exterior/Clues/Caravan", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.025, 0.03, 0)", 'mesh = SubResource("BoxMesh_pages")'])
    node(lines, "Cord", "MeshInstance3D", "Exterior/Clues/Caravan", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.03, 0.08)", 'mesh = SubResource("BoxMesh_cord")'])''')
rep('''def ext(identifier):''', '''CARAVAN = (
    "Carnet d'un caravanier. Nous menions nos épices et nos étoffes vers Codia quand Vibelandia a déclaré la guerre : "
    "les routes du nord sont tombées, il ne restait que la piste du désert de Pythania. Trois jours que la tempête nous tient, "
    "et le vent brûle comme une forge. Le vieux guide dit que les anciens bâtisseurs gravaient leurs instructions sur des runes, "
    "et qu'il suffit de les remettre dans l'ordre pour que le sable rende ce qu'il garde. Nous en avons vu briller dans les salles "
    "du monument, parmi les débris, et sous des tas de sable. Certains tas ne cachent rien : il faut creuser quand même. "
    "L'eau manque. Les vautours tournent au-dessus des bêtes."
)
INSCRIPTION = (
    "Les anciens bâtisseurs maîtrisaient l'art des instructions. Retrouve les fragments de leur savoir, "
    "rétablis leur ordre et les secrets enfouis te seront révélés."
)


def ext(identifier):''')

# Inscription : une plaque de pierre gravée sur la porte scellée, au lieu d'un texte qui flotte.
rep('''    node(lines, "Inscription", "Node3D", "Interior/Clues", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.6, -11.2)", 'script = ExtResource("12_readable")',
        'title = "L\\'inscription de la table"',
        'body = "Les anciens bâtisseurs maîtrisaient l\\'art des instructions. Retrouve les fragments de leur savoir, rétablis leur ordre et les secrets enfouis te seront révélés."',
        'prompt = "Lire l\\'inscription"', "radius = 4.5"])
    node(lines, "Text", "Label3D", "Interior/Clues/Inscription", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.6, 0.1)", "pixel_size = 0.006",
        "modulate = Color(1, 0.8, 0.45, 1)", 'text = "RÉTABLIS L\\'ORDRE DES INSTRUCTIONS"', "font_size = 64", "no_depth_test = true",
        "outline_size = 12"])''',
    '''    node(lines, "Inscription", "Node3D", "Interior/Clues", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, -11.32)", 'script = ExtResource("12_readable")',
        'title = "L\\'inscription de la porte scellée"', f"body = {quote(INSCRIPTION)}",
        'prompt = "Lire l\\'inscription"', "radius = 3.2"])
    node(lines, "Plaque", "Node3D", "Interior/Clues/Inscription", props=[
        'script = ExtResource("14_sign")', f"text = {quote(INSCRIPTION)}", "style = 1", "mount = 1",
        "board_size = Vector2(2.1, 1.1)", "board_height = 1.95", "line_height = 0.11", "serif = false"])''')

# Table ronde de pierre : un pied, un plateau, six emplacements de runes et un soleil gravé.
rep('''    node(lines, "Mesh", "MeshInstance3D", "Interior/RoundTable", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 0)", 'mesh = SubResource("CylinderMesh_table")'])''',
    '''    node(lines, "Base", "MeshInstance3D", "Interior/RoundTable", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.4, 0)", 'mesh = SubResource("CylinderMesh_table_base")'])
    node(lines, "Top", "MeshInstance3D", "Interior/RoundTable", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.91, 0)", 'mesh = SubResource("CylinderMesh_table_top")'])
    node(lines, "Rim", "MeshInstance3D", "Interior/RoundTable", props=[
        "transform = Transform3D(1, 0, 0, 0, 0.5, 0, 0, 0, 1, 0, 1.0, 0)", 'mesh = SubResource("TorusMesh_table_rim")'])
    node(lines, "Sun", "MeshInstance3D", "Interior/RoundTable", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.025, 0)", 'mesh = SubResource("CylinderMesh_table_sun")'])
    node(lines, "Slots", "Node3D", "Interior/RoundTable")
    for slot in range(6):
        angle = math.radians(slot * 60.0 + 30.0)
        c, s = math.cos(angle), math.sin(angle)
        node(lines, f"Slot{slot}", "MeshInstance3D", "Interior/RoundTable/Slots", props=[
            f"transform = Transform3D({c:.5g}, 0, {s:.5g}, 0, 1, 0, {-s:.5g}, 0, {c:.5g}, {s * 1.05:.4g}, 1.03, {c * 1.05:.4g})",
            'mesh = SubResource("BoxMesh_slot")'])''')
rep('''        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.2, 0)", "unit_size = 6.0"])''',
    '''        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.2, 0)", "unit_size = 6.0"])
    node(lines, "Rumble", "AudioStreamPlayer3D", "Interior/RoundTable", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.2, 0)", 'stream = ExtResource("53_rumble")', "unit_size = 10.0",
        "volume_db = 2.0"])''')

# Algorithmes gravés dans la roche : encre dorée, à fleur de la dalle, sans contour.
rep('''            at(-side * 0.0, 0.0, -side * 1.7, 1.0, yaw), "pixel_size = 0.0024",
            "modulate = Color(0.65, 0.85, 1, 1)", f'text = "{body}"', "font_size = 64", "outline_size = 10",
            "horizontal_alignment = 0"])''', '''            at(side * 0.012, 0.0, -side * 1.7, 1.0, yaw), "pixel_size = 0.0024", "shaded = true", "double_sided = false",
            "alpha_cut = 1", "modulate = Color(0.86, 0.66, 0.3, 1)", f'text = "{body}"', "font_size = 64", "outline_size = 0",
            "horizontal_alignment = 0"])''')

# Coffre de pierre dans le coin nord-est, sous son tas de sable ; son couvercle se soulève à la réussite.
rep('''    node(lines, "Chest", parent="Interior", instance="19_chest", props=[at(0, 0, -10.0, 3.0, 180)])
    node(lines, "ChestSand", "MeshInstance3D", "Interior", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.65, -10.0)", 'mesh = SubResource("CylinderMesh_chest_sand")'])''',
    '''    cx, cz, cyaw = CHEST
    node(lines, "Chest", "Node3D", "Interior", props=[at(cx, 0, cz, 1.0, cyaw)])
    node(lines, "Body", "MeshInstance3D", "Interior/Chest", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.375, 0)", 'mesh = SubResource("BoxMesh_chest_body")'])
    node(lines, "Band", "MeshInstance3D", "Interior/Chest", props=[
        "transform = Transform3D(0.94, 0, 0, 0, 1, 0, 0, 0, 0.92, 0, 0.12, 0)", 'mesh = SubResource("BoxMesh_chest_band")'])
    node(lines, "Lid", "Node3D", "Interior/Chest", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.75, -0.5)"])
    node(lines, "Mesh", "MeshInstance3D", "Interior/Chest/Lid", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.12, 0.5)", 'mesh = SubResource("BoxMesh_chest_lid")'])
    node(lines, "Band", "MeshInstance3D", "Interior/Chest/Lid", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.12, 0.5)", 'mesh = SubResource("BoxMesh_chest_band")'])
    node(lines, "Lock", "MeshInstance3D", "Interior/Chest/Lid", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.0, 1.03)", 'mesh = SubResource("BoxMesh_chest_lock")'])
    node(lines, "ChestSand", "MeshInstance3D", "Interior", props=[
        f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {cx:g}, 0.65, {cz:g})", 'mesh = SubResource("CylinderMesh_chest_sand")'])
    # Le tas puis le coffre arrêtent le joueur au même endroit.
    node(lines, "ChestBody", "StaticBody3D", "Interior", props=[f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {cx:g}, 0.5, {cz:g})"])
    node(lines, "Shape", "CollisionShape3D", "Interior/ChestBody", props=['shape = SubResource("BoxShape3D_chest")'])''')
rep('''    node(lines, "BookTarget", "Marker3D", "Interior", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.9, -10.0)"])
    node(lines, "Book", "Node3D", "Interior", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.9, -10.0)"])''',
    '''    node(lines, "BookTarget", "Marker3D", "Interior", props=[f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {cx:g}, 1.9, {cz:g})"])
    node(lines, "Book", "Node3D", "Interior", props=[f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {cx:g}, 1.9, {cz:g})"])''')

# Peu de cactus, mais les restes épars des dunes.
rep('''        'wreck_models = Array[PackedScene]([ExtResource("27_catapult"), ExtResource("28_ram")])',''',
    '''        'wreck_models = Array[PackedScene]([ExtResource("27_catapult"), ExtResource("28_ram")])',
        'prop_models = Array[PackedScene]([ExtResource("29_spear"), ExtResource("30_shield"), ExtResource("31_sword"), ExtResource("32_pot"), ExtResource("33_wheel"), ExtResource("34_barrel"), ExtResource("35_skeleton")])',
        "cactus_count = 34",''')
p.write_text(t, encoding="utf-8", newline="\n")
print("ok")
