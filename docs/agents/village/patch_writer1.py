"""Met à jour ma copie de write_village_tscn.py : panneaux SignBoard, lore conforme au scénario, mairie corrigée."""
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")


def sub(old, new, count=1):
    global text
    assert text.count(old) == count, (old[:80], text.count(old))
    text = text.replace(old, new)


sub('''"""Écrit la première version de frontend/scenes/levels/village/village.tscn."""''',
    '''"""Écrit frontend/scenes/levels/village/village.tscn : l'ambiance, le terrain, les moulins, les panneaux de lore,
la mairie et son intérieur sous la carte (fragments, meubles qui s'ouvrent, dispositif des cinq codes, salle secrète).
Les murs et les meubles de l'intérieur sont dans village_hall.tscn (tools/build_village.py) : les positions des
fragments et des meubles qui s'ouvrent ci-dessous doivent rester en accord avec eux.

    python write_village_tscn.py <dossier frontend>
"""''')
sub('''    ("PackedScene", K + "survival_kit/signpost.glb", "15_signpost"),
''', '''    ("Script", "res://scripts/sign_board.gd", "15_sign"),
''')
sub('''    ("Script", "res://scripts/readable.gd", "57_readable"),
''', '''    ("Script", "res://scripts/readable.gd", "57_readable"),
    ("PackedScene", K + "furniture_kit/books.glb", "58_books"),
''')
# Matériaux supplémentaires : pierre du mémorial, lumière bleutée du dispositif.
sub('''[sub_resource type="CylinderShape3D" id="CylinderShape3D_post"]
height = 2.0
radius = 0.35
''', '''[sub_resource type="BoxMesh" id="BoxMesh_plinth"]
material = SubResource("Material_stone")
size = Vector3(2.0, 0.4, 0.9)

[sub_resource type="BoxMesh" id="BoxMesh_stele"]
material = SubResource("Material_stone")
size = Vector3(1.7, 1.5, 0.3)

[sub_resource type="BoxShape3D" id="BoxShape3D_memorial"]
size = Vector3(2.0, 1.9, 0.9)
''')
sub('''[sub_resource type="BoxMesh" id="BoxMesh_console"]
material = SubResource("Material_wood_dark")
size = Vector3(5.8, 1.1, 0.8)

[sub_resource type="BoxMesh" id="BoxMesh_backboard"]
material = SubResource("Material_stone")
size = Vector3(5.8, 2.4, 0.2)

[sub_resource type="BoxShape3D" id="BoxShape3D_console"]
size = Vector3(5.8, 3.6, 1.0)
''', '''[sub_resource type="BoxMesh" id="BoxMesh_console"]
material = SubResource("Material_wood_dark")
size = Vector3(5.8, 1.0, 0.8)

[sub_resource type="BoxMesh" id="BoxMesh_backboard"]
material = SubResource("Material_stone")
size = Vector3(5.8, 1.4, 0.2)

[sub_resource type="BoxShape3D" id="BoxShape3D_console"]
size = Vector3(5.8, 2.5, 1.0)
''')
sub('''# Feux qui couvent encore dans les ruines, et fumées qui montent des maisons.
FIRES = [(-9.5, 20.5, 1.2), (16.0, -4.5, 1.0), (-27.0, -1.0, 0.9), (5.5, 7.0, 0.8)]
SMOKES = [(-10.0, 20.0, 1.5), (17.0, -6.0, 1.2), (21.0, 12.0, 1.0), (2.0, -28.0, 1.4), (-28.0, -2.0, 1.0)]
LANTERNS = [(-2.4, 30.0), (2.4, -14.0)]
''', '''# Feux qui couvent encore : la charrette de la barricade, les cratères des boulets, la maison brûlée, le toit
# effondré des écuries. Fumées qui montent des ruines. La mairie, intacte, ne fume pas.
FIRES = [(4.6, 35.6, 0.9), (-7.5, -0.7, 0.7), (26.0, -2.2, 1.0), (-27.0, -1.0, 0.9), (21.4, 34.6, 0.8)]
SMOKES = [(-28.0, -2.0, 1.0), (27.0, -3.5, 1.4), (-8.6, -1.6, 1.0), (21.6, 34.0, 1.1), (-10.0, 20.0, 1.0)]
# Lanternes allumées : (x, hauteur, z).
LANTERNS = [(-2.4, 3.0, 30.0), (2.4, 3.0, -14.0), (0.0, 2.6, -18.9)]
''')
sub('''    (0, (-2.4, 1.075, -0.4), False),
    (2, (-4.3, 1.0, 3.1), False),
    (3, (0.4, 1.0, -0.8), True),
    (4, (-6.4, 0.03, -1.0), True),
    (7, (2.0, 1.18, -5.0), False),
    (8, (-6.15, 0.03, 5.5), False),
    (5, (-0.5, OFFICE + 1.075, -0.4), False),
    (1, (1.4, OFFICE + 1.0, -0.8), True),
    (9, (-6.6, OFFICE + 1.18, -5.0), False),
    (6, (1.6, OFFICE + 0.03, 4.6), True),
]''', '''    # Deux par langage : HTML 0 et 1, CSS 2 et 3, Python 4 et 5, PHP 6 et 7, TypeScript 8 et 9.
    (0, (-2.4, 1.075, -0.4), False),
    (2, (-4.3, 1.0, 3.1), False),
    (3, (0.4, 1.0, -0.8), True),
    (4, (-6.4, 0.03, -1.0), True),
    (7, (2.0, 1.18, -5.0), False),
    (8, (-4.6, 1.075, -3.0), True),
    (5, (-0.5, OFFICE + 1.075, -0.4), False),
    (1, (1.4, OFFICE + 1.0, -0.8), True),
    (9, (-6.6, OFFICE + 1.18, -5.0), False),
    (6, (1.6, OFFICE + 0.03, 4.45), True),
]''')
sub('''# Meubles qui s'ouvrent : nom, position de l'invite, nom du meuble, fragment caché.
STORAGES = [
    ("ReceptionDrawer", (0.4, 0.7, -0.8), "le tiroir de l'accueil", 3),
    ("ArchiveCabinet", (-7.0, 1.3, -1.0), "l'armoire des archives", 4),
    ("ArchiveCabinetNorth", (-7.0, 1.3, -3.5), "l'armoire aux registres", None),
    ("ArchiveCabinetSouth", (-7.0, 1.3, 1.5), "l'armoire aux actes", None),
    ("Dresser", (2.0, 0.7, -5.0), "le meuble à tiroirs", None),
    ("MayorDrawer", (1.4, OFFICE + 0.7, -0.8), "le tiroir du bureau", 1),
    ("MayorCabinet", (1.6, OFFICE + 1.3, 5.1), "l'armoire du maire", 6),
    ("OfficeDresser", (-6.6, OFFICE + 0.7, -5.0), "la commode", None),
]''', '''# Meubles qui s'ouvrent : nom, position de l'invite (devant la face qui s'ouvre, hors de la collision du meuble),
# nom du meuble, fragment caché.
STORAGES = [
    ("ReceptionDrawer", (0.4, 0.7, -0.15), "le tiroir de l'accueil", 3),
    ("ArchiveCabinet", (-6.72, 1.3, -1.0), "l'armoire des archives", 4),
    ("ArchiveCabinetNorth", (-6.72, 1.3, -3.5), "l'armoire aux registres", None),
    ("ArchiveCabinetSouth", (-6.72, 1.3, 1.5), "l'armoire aux actes", None),
    ("ArchivistDesk", (-3.8, 1.12, -4.35), "le tiroir de l'archiviste", 8),
    ("ComplaintsDesk", (2.0, 1.12, -2.45), "le tiroir du bureau des doléances", None),
    ("Dresser", (2.0, 0.7, -4.35), "le meuble à tiroirs", None),
    ("MayorDrawer", (1.4, OFFICE + 0.7, -1.42), "le tiroir du bureau", 1),
    ("MayorCabinet", (1.6, OFFICE + 1.3, 4.75), "l'armoire du maire", 6),
    ("OfficeDresser", (-6.6, OFFICE + 0.7, -4.35), "la commode", None),
]
INSCRIPTION = ("Cinq langages, cinq épreuves, un seul savoir. Comprends les instructions des anciens bâtisseurs "
               "et le dernier secret du village te sera révélé.")
# Pupitre de pierre de la salle secrète (posé par tools/build_village.py) : le livre repose sur son plateau incliné.
LECTERN = (-12.6, 0.0)
LECTERN_TILT = -15.0
# Panneaux de lore : nom, position, orientation (la face regarde +Z tournée de ces degrés), titre, texte, et le
# panneau qui le porte.
LORE = [
    ("Notice", (-4.6, 0.0, 13.0), 90.0, "L'avis du maire",
     "Proclamation du maire de Codia : la mairie reste ouverte tant que le village tient debout. Les registres et "
     "les savoirs des anciens bâtisseurs sont à l'abri dans le bureau du maire, à l'étage. Seul celui qui comprendra "
     "leurs cinq langages pourra en percer le dernier secret.",
     dict(text="Avis du maire\\nà la population de Codia", style=2, mount=0, roof=True, board_size=(1.3, 0.85),
          board_height=1.45, line_height=0.13)),
    ("Order", (-4.2, 0.0, 35.2), 90.0, "L'ordre du capitaine",
     "Ordre du capitaine de la garde, an 5812 : tenez la porte tant que les habitants ne sont pas à l'abri. Les "
     "catapultes de Vibelandia ont ouvert une brèche dans le rempart de l'est. Quand le cor sonnera trois fois, "
     "abandonnez la barricade et rejoignez le bunker du roi, près du château.",
     dict(text="Ordre du capitaine\\nde la garde", style=2, mount=0, board_size=(1.0, 0.7), board_height=1.35,
          line_height=0.12)),
    ("Slate", (4.9, 0.0, 28.6), -90.0, "L'ardoise de la boulangère",
     "Pain de seigle : deux sous. Pain blanc : trois sous. Plus de farine depuis que le meunier a fui. La dernière "
     "fournée est pour les gardes du rempart : qu'ils tiennent jusqu'au soir.",
     dict(text="Pain de seigle : 2 sous\\nPain blanc : 3 sous", style=3, mount=0, board_size=(0.85, 0.62),
          board_height=1.2, line_height=0.1, serif=False)),
]
MEMORIAL = ((12.0, 0.0, 37.5), -90.0, "Le mémorial des gardes",
            "Ici, les gardes de Codia ont tenu la porte trois jours et trois nuits face aux guerriers de Vibelandia. "
            "Quand elle a cédé, ils ont couvert la fuite des habitants jusqu'au bunker du roi. Leurs noms restent "
            "gravés dans la mémoire du village.")''')
sub('''def ext(identifier):
    return f'ExtResource("{identifier}")'
''', '''def ext(identifier):
    return f'ExtResource("{identifier}")'


def value(item):
    if isinstance(item, bool):
        return "true" if item else "false"
    if isinstance(item, str):
        return '"' + item.replace('"', '\\\\"') + '"'
    if isinstance(item, tuple):
        return "Vector2(%s)" % ", ".join(f"{v:g}" for v in item)
    return f"{item:g}"


def sign_props(props):
    return ['script = ExtResource("15_sign")'] + [f"{key} = {value(item)}" for key, item in props.items()]
''')
sub('''    for index, (x, z) in enumerate(LANTERNS):
        node(lines, f"LanternLight{index}", "OmniLight3D", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, 3.0, {z:g})", 'script = ExtResource("12_flicker")',
            "light_color = Color(1, 0.7, 0.35, 1)", "light_energy = 1.4", "omni_range = 7.0", "flicker = 0.2"])''',
    '''    for index, (x, y, z) in enumerate(LANTERNS):
        node(lines, f"LanternLight{index}", "OmniLight3D", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, {z:g})", 'script = ExtResource("12_flicker")',
            "light_color = Color(1, 0.7, 0.35, 1)", "light_energy = 1.4", "omni_range = 7.0", "flicker = 0.2"])''')
sub('''    node(lines, "Sign", instance="15_signpost", props=[at(-4.5, 0, 55, 2.5)])
    node(lines, "SignText", "Label3D", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -4.5, 3.8, 55)", "pixel_size = 0.007", "billboard = 1",
        "modulate = Color(1, 0.88, 0.75, 1)", 'text = "Le Village détruit"', "font_size = 64", "outline_size = 16"])
    node(lines, "Lore", "Node3D")
    node(lines, "Notice", "Node3D", "Lore", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -4.6, 0, 13)", 'script = ExtResource("57_readable")', "title = \\"L'avis du maire\\"", "body = \\"Proclamation du maire : les registres de la mairie ont été mis à l'abri dans le bureau, à l'étage. Seul celui qui comprendra les cinq langages des anciens bâtisseurs pourra ouvrir la salle des archives.\\"", "prompt = \\"Lire : L'avis du maire\\"", "radius = 2.6"])
    node(lines, "Post", parent="Lore/Notice", instance="15_signpost", props=[at(0, 0, 0, 2.4)])
    node(lines, "Body", "StaticBody3D", "Lore/Notice")
    node(lines, "Shape", "CollisionShape3D", "Lore/Notice/Body", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0)", 'shape = SubResource("CylinderShape3D_post")'])
    node(lines, "Memorial", "Node3D", "Lore", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 12.0, 0, 37.5)", 'script = ExtResource("57_readable")', "title = \\"Le mémorial des gardes\\"", "body = \\"Ici, les gardes de Codia ont tenu la porte trois jours et trois nuits face aux Dragons du Chaos. Quand elle a cédé, ils ont mis les habitants à l'abri dans le bunker du roi.\\"", "prompt = \\"Lire : Le mémorial des gardes\\"", "radius = 2.6"])
    node(lines, "Post", parent="Lore/Memorial", instance="15_signpost", props=[at(0, 0, 0, 2.4)])
    node(lines, "Body", "StaticBody3D", "Lore/Memorial")
    node(lines, "Shape", "CollisionShape3D", "Lore/Memorial/Body", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0)", 'shape = SubResource("CylinderShape3D_post")'])
    # Porte de la mairie : elle mène à son intérieur, sous la carte.
    node(lines, "HallDoor", "Node3D", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.4, -20.2)", 'script = ExtResource("53_interactable")',
        'prompt = "Entrer dans la mairie"', "radius = 3.2"])''', '''    # Panneau d'entrée, sur ses poteaux au bord de la route, tourné vers le portail.
    node(lines, "EntranceSign", "Node3D", props=[at(-4.5, 0, 55, 1.0, 30)] + sign_props(dict(
        text="Codia\\nLe village détruit", board_size=(1.9, 0.95), board_height=1.55, line_height=0.26)))
    # Textes à lire avec E : le panneau ne porte qu'un titre, le Readable donne le texte entier.
    node(lines, "Lore", "Node3D")
    for name, (x, y, z), degrees, title, body, board in LORE:
        node(lines, name, "Node3D", "Lore", props=[at(x, y, z, 1.0, degrees), 'script = ExtResource("57_readable")',
                                                   f"title = {quote(title)}", f"body = {quote(body)}",
                                                   f"prompt = {quote('Lire : ' + title)}", "radius = 2.6"])
        node(lines, "Board", "Node3D", f"Lore/{name}", props=sign_props(board))
    # Mémorial des gardes : une stèle de pierre sur son socle, la plaque gravée sur sa face.
    (x, y, z), degrees, title, body = MEMORIAL
    node(lines, "Memorial", "Node3D", "Lore", props=[at(x, y, z, 1.0, degrees), 'script = ExtResource("57_readable")',
                                                     f"title = {quote(title)}", f"body = {quote(body)}",
                                                     f"prompt = {quote('Lire : ' + title)}", "radius = 2.6"])
    node(lines, "Plinth", "MeshInstance3D", "Lore/Memorial", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.2, -0.3)", 'mesh = SubResource("BoxMesh_plinth")'])
    node(lines, "Stele", "MeshInstance3D", "Lore/Memorial", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.15, -0.3)", 'mesh = SubResource("BoxMesh_stele")'])
    node(lines, "Body", "StaticBody3D", "Lore/Memorial")
    node(lines, "Shape", "CollisionShape3D", "Lore/Memorial/Body", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.95, -0.3)", 'shape = SubResource("BoxShape3D_memorial")'])
    node(lines, "Board", "Node3D", "Lore/Memorial", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, -0.15)"]
         + sign_props(dict(text="Aux gardes de Codia\\nqui ont tenu la porte", style=1, mount=1, board_size=(1.45, 0.8),
                           board_height=1.2, line_height=0.13, collision=False)))
    # Porte de la mairie : elle mène à son intérieur, sous la carte. Le point est devant le mur, pas dedans.
    node(lines, "HallDoor", "Node3D", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.4, -19.45)", 'script = ExtResource("53_interactable")',
        'prompt = "Entrer dans la mairie"', "radius = 3.2"])''')
sub('''        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -2, 1.2, 5.7)", 'script = ExtResource("53_interactable")',
        'prompt = "Sortir de la mairie"', "radius = 2.0"])''', '''        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -2, 1.2, 5.55)", 'script = ExtResource("53_interactable")',
        'prompt = "Sortir de la mairie"', "radius = 2.0"])''')
# Dispositif : console, panneau des cinq sections, noms gravés, et l'inscription au-dessus.
sub('''    node(lines, "Console", "MeshInstance3D", "Interior/Device", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.55, 0.1)", 'mesh = SubResource("BoxMesh_console")'])
    node(lines, "Backboard", "MeshInstance3D", "Interior/Device", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.3, -0.25)", 'mesh = SubResource("BoxMesh_backboard")'])
    node(lines, "Body", "StaticBody3D", "Interior/Device")
    node(lines, "Shape", "CollisionShape3D", "Interior/Device/Body", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.8, 0)", 'shape = SubResource("BoxShape3D_console")'])''',
    '''    node(lines, "Console", "MeshInstance3D", "Interior/Device", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 0.1)", 'mesh = SubResource("BoxMesh_console")'])
    node(lines, "Backboard", "MeshInstance3D", "Interior/Device", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.7, -0.25)", 'mesh = SubResource("BoxMesh_backboard")'])
    node(lines, "Body", "StaticBody3D", "Interior/Device")
    node(lines, "Shape", "CollisionShape3D", "Interior/Device/Body", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.25, 0)", 'shape = SubResource("BoxShape3D_console")'])''')
sub('''            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, 2.45, -0.12)", f'mesh = SubResource("BoxMesh_section{index}")'])
        node(lines, f"Language{index}", "Label3D", "Interior/Device", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, 1.7, -0.13)", "pixel_size = 0.0028",
            "modulate = Color(0.85, 0.88, 1, 1)", f"text = {quote(LANGUAGES[index])}", "font_size = 64", "outline_size = 10"])
    node(lines, "Inscription", "Label3D", "Interior/Device", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 3.25, -0.13)", "pixel_size = 0.0026",
        "modulate = Color(1, 0.88, 0.6, 1)", 'text = "CINQ LANGAGES, CINQ ÉPREUVES, UN SEUL SAVOIR"', "font_size = 64",
        "outline_size = 10"])''', '''            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, 1.87, -0.12)", f'mesh = SubResource("BoxMesh_section{index}")'])
        # Nom du langage gravé et doré dans la pierre du panneau, à 2 cm de sa face.
        node(lines, f"Language{index}", "Label3D", "Interior/Device", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, 1.24, -0.13)", "pixel_size = 0.0026",
            "shaded = true", "alpha_cut = 1", "modulate = Color(0.86, 0.7, 0.4, 1)", f"text = {quote(LANGUAGES[index])}",
            "font_size = 64", "outline_size = 0"])
    # L'inscription des anciens bâtisseurs, sur une plaque de pierre scellée au mur, au-dessus du dispositif.
    node(lines, "Inscription", "Node3D", "Interior/Device", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.93, -0.35)"] + sign_props(dict(
            text=INSCRIPTION, style=1, mount=1, board_size=(5.6, 0.9), board_height=0.0, line_height=0.15,
            collision=False)))
    node(lines, "DeviceLight", "OmniLight3D", "Interior/Device", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.0, 1.0)", "light_color = Color(0.45, 0.65, 1, 1)",
        "light_energy = 0.0", "omni_range = 9.0"])''')
sub('''        "size = Vector3(0.95, 0.95, 0.06)", ""]''', '''        "size = Vector3(0.8, 0.8, 0.06)", ""]''')
# Livres sur la bibliothèque qui glisse : ils bougent avec elle.
sub('''    node(lines, "Body", "StaticBody3D", "Interior/SecretShelf")''', '''    for row, y in enumerate((0.13, 1.07, 1.98)):
        for k in range(6):
            if (row * 7 + k * 3) % 5 == 0:
                continue
            z = -1.15 + k * 0.46
            node(lines, f"Books{row}_{k}", parent="Interior/SecretShelf", instance="58_books", props=[
                at(0.05, y, z + 0.15, 3.2 + (k % 3) * 0.25, -90 if (row + k) % 2 else 90)])
    node(lines, "Body", "StaticBody3D", "Interior/SecretShelf")''')
# Le Codonomicon sur le plateau incliné du pupitre de pierre.
sub('''    node(lines, "Book", "Node3D", "Interior", props=[f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -12.6, {OFFICE + 1.1:g}, 0)"])''',
    '''    c, s_ = math.cos(math.radians(LECTERN_TILT)), math.sin(math.radians(LECTERN_TILT))
    node(lines, "Book", "Node3D", "Interior", props=[
        f"transform = Transform3D({c:.5f}, {-s_:.5f}, 0, {s_:.5f}, {c:.5f}, 0, 0, 0, 1, {LECTERN[0]:g}, {OFFICE + 1.2:g}, {LECTERN[1]:g})"])''')
path.write_text(text, encoding="utf-8")
print("ok")
