"""Plus aucun meuble moderne dans le Village : chaises de bois, coffres, pots de terre, poupée de chiffon."""
import sys
from pathlib import Path

builder = Path(sys.argv[1])
writer = Path(sys.argv[2])
text = builder.read_text(encoding="utf-8")


def sub(old, new, count=1):
    global text
    assert text.count(old) == count, (old[:90], text.count(old))
    text = text.replace(old, new)


sub('''    "furniture_kit/bear": ((0.0, 0.0, -0.25), (0.39, 0.45, 0.25)),
''', '')
sub('''def top_of(model, scale):
    """Hauteur du dessus d'un meuble, d'après sa boîte."""
    (_, py, _), (_, sy, _) = MODEL_BOXES[model]
    return (py + sy) * scale''', '''def top_of(model, scale):
    """Hauteur du dessus d'un meuble au-dessus de son pied, d'après sa boîte : posé par furniture() ou put(), le bas
    de la boîte touche le sol."""
    return MODEL_BOXES[model][1][1] * scale''')
sub('''        # Le petit lit de l'enfant, et l'ours en peluche oublié dans la fuite.
        bed(scene, frame, -far * 2.3, -2.2, 0.0, 1.0)
        fl(scene, frame, "furniture_kit/bear", -far * 0.9, -2.9, 200.0, 1.1, y=FLOOR)
        fl(scene, frame, "fantasy_town_kit/cart", far * 0.2, 0.2, 50.0, 0.42, y=FLOOR)''', '''        # Le petit lit de l'enfant, sa poupée de chiffon oubliée dans la fuite et sa charrette de bois.
        bed(scene, frame, -far * 2.3, -2.2, 0.0, 1.0)
        doll(scene, frame.p(-far * 0.9, -2.9, FLOOR), frame.yaw(200.0))
        fl(scene, frame, "fantasy_town_kit/cart", far * 0.2, 0.2, 50.0, 0.42, y=FLOOR)''')
sub('''def sheet(scene, material, center, width, drop, degrees, sway=0.0):''', '''def doll(scene, position, degrees):
    """Poupée de chiffon couchée sur le dos : un corps de toile, une robe rouge, une tête et des bras."""
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))

    def at(u, h, v):
        return (position[0] + c * u + s * v, position[1] + h, position[2] - s * u + c * v)
    box(scene, "cloth_red", at(0, 0.04, 0), (0.16, 0.07, 0.24), degrees)
    sphere(scene, "burlap", at(0, 0.05, 0.17), 0.065)
    for side in (-1, 1):
        box(scene, "burlap", at(side * 0.12, 0.035, 0.04), (0.08, 0.04, 0.05), degrees + side * 30.0)
        box(scene, "burlap", at(side * 0.05, 0.03, -0.17), (0.05, 0.04, 0.12), degrees)


def sheet(scene, material, center, width, drop, degrees, sway=0.0):''')
# Mairie : chaises de bois devant les bureaux, coffres à la place des meubles de cuisine, pots de terre.
sub('''    hp(scene, "furniture_kit/chairDesk", (-2.0, 0.0, -2.2), 180.0, 2.6, label="fauteuil de l'accueil")''',
    '''    hp(scene, "furniture_kit/chair", (-2.0, 0.0, -2.0), 0.0, 3.0, label="chaise de l'accueil")''')
sub('''    hp(scene, "furniture_kit/chairDesk", (-3.0, 0.0, -3.6), 90.0, 2.6, label="fauteuil de l'archiviste")''',
    '''    hp(scene, "furniture_kit/chair", (-3.1, 0.0, -3.6), -90.0, 3.0, label="chaise de l'archiviste")''')
sub('''    hp(scene, "furniture_kit/kitchenCabinetDrawer", (2.0, 0.0, -5.1), 0.0, 2.6, label="meuble à tiroirs")''',
    '''    hp(scene, "mini_dungeon/chest", (2.0, 0.0, -5.1), 90.0, 2.4, label="coffre de l'accueil")''')
sub('''    lay(scene, "furniture_kit/pottedPlant", (-0.3, 0.0, 5.3), 0.0, 2.6)
    post(scene, -0.3, 5.3, 0.35, 1.4, label="plante")''', '''    potted_plant(scene, (-0.6, 0.0, 5.35))''')
sub('''    hp(scene, "furniture_kit/chairDesk", (-1.0, office, -2.2), 180.0, 2.6, label="fauteuil du maire")''',
    '''    hp(scene, "furniture_kit/chair", (-1.0, office, -2.0), 0.0, 3.0, label="chaise du maire")''')
sub('''    hp(scene, "furniture_kit/kitchenCabinetDrawer", (-6.6, office, -5.1), 0.0, 2.6, label="commode")''',
    '''    hp(scene, "mini_dungeon/chest", (-6.4, office, -5.1), 90.0, 2.4, label="coffre du bureau")''')
sub('''    lay(scene, "furniture_kit/pottedPlant", (-7.0, office, 5.1), 0.0, 2.6)
    post(scene, -7.0, 5.1, 0.35, 1.4, y=office, label="plante")''', '''    potted_plant(scene, (-7.0, office, 5.1))''')
sub('''def build_hall_interior():''', '''def potted_plant(scene, position):
    """Pot de terre et son buisson de simples, avec sa collision."""
    lay(scene, "nature_kit/pot_small", position, 20.0, 2.2)
    lay(scene, "nature_kit/plant_bushSmall", (position[0], position[1] + top_of("nature_kit/pot_small", 2.2) - 0.1, position[2]),
        0.0, 1.6)
    post(scene, position[0], position[2], 0.38, 0.9, y=position[1], label="pot de terre")


def build_hall_interior():''')
builder.write_text(text, encoding="utf-8", newline="\n")

text = writer.read_text(encoding="utf-8")
sub('''    (7, (1.7, 1.18, -5.0), False),''', '''    (7, (1.6, 0.73, -5.1), False),''')
sub('''    (9, (-6.6, OFFICE + 1.18, -5.0), True),''', '''    (9, (-6.4, OFFICE + 0.73, -5.1), True),''')
sub('''    # Sur le côté du meuble : de face, c'est le fragment posé dessus qu'on ramasse d'abord.
    ("Dresser", (2.66, 0.7, -5.05), "le meuble à tiroirs", None),''', '''    # Au bout du coffre : de face, c'est le fragment posé sur son couvercle qu'on ramasse d'abord.
    ("Dresser", (2.97, 0.4, -5.1), "le coffre de l'accueil", None),''')
sub('''    ("OfficeDresser", (-6.6, OFFICE + 0.7, -4.35), "la commode", 9),''',
    '''    ("OfficeDresser", (-5.43, OFFICE + 0.4, -5.1), "le coffre du bureau", 9),''')
writer.write_text(text, encoding="utf-8", newline="\n")
print("ok")
