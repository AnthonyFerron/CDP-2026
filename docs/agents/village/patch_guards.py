"""Rend les aides de formes tolérantes à une Scene ordinaire (check_overlaps.py rejoue les fonctions du Village)."""
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")


def sub(old, new, count=1):
    global text
    assert text.count(old) == count, (old, text.count(old))
    text = text.replace(old, new)


sub('''def box(scene, material, center, size, degrees=0.0, tilt=0.0, roll=0.0):
    scene.shape(''', '''def box(scene, material, center, size, degrees=0.0, tilt=0.0, roll=0.0):
    if not hasattr(scene, "shape"):
        return
    scene.shape(''')
sub('''def cylinder(scene, material, center, radius, height, top=None, degrees=0.0, tilt=0.0, roll=0.0, sides=12):
    mesh =''', '''def cylinder(scene, material, center, radius, height, top=None, degrees=0.0, tilt=0.0, roll=0.0, sides=12):
    if not hasattr(scene, "shape"):
        return
    mesh =''')
sub('''def sphere(scene, material, center, radius, scale=(1.0, 1.0, 1.0), degrees=0.0, tilt=0.0, hemisphere=False):
    mesh =''', '''def sphere(scene, material, center, radius, scale=(1.0, 1.0, 1.0), degrees=0.0, tilt=0.0, hemisphere=False):
    if not hasattr(scene, "shape"):
        return
    mesh =''')
sub('''def scorch(scene, x, z, radius, y=0.012, degrees=0.0):''', '''def torus(scene, material, center, inner, outer, degrees=0.0, tilt=0.0):
    if not hasattr(scene, "shape"):
        return
    mesh = scene.mesh("TorusMesh", inner_radius=float(inner), outer_radius=float(outer), rings=12, ring_segments=4)
    scene.shape(mesh, material, center, degrees, tilt)


def prism(scene, material, center, size, degrees=0.0):
    if not hasattr(scene, "shape"):
        return
    scene.shape(scene.mesh("PrismMesh", size=tuple(size)), material, center, degrees)


def sign(scene, name, position, degrees, **props):
    """Panneau SignBoard (scripts/sign_board.gd) : le texte est écrit sur sa planche, sa face regarde vers +Z."""
    if hasattr(scene, "sign"):
        scene.sign(name, position, degrees, **props)


def add_single(scene, model, position, degrees=0.0, scale=1.0):
    """Modèle toujours posé comme une instance ordinaire, même répété."""
    if isinstance(scene, VillageScene):
        scene.add(model, position, degrees, scale, single=True)
    else:
        scene.add(model, position, degrees, scale)


def scorch(scene, x, z, radius, y=0.012, degrees=0.0):''')
sub('''    scene.add_cylinder((x, y + height / 2, z), radius, height)
    LAYOUT.add(label''', '''    if hasattr(scene, "add_cylinder"):
        scene.add_cylinder((x, y + height / 2, z), radius, height)
    else:
        scene.add_box((x, y + height / 2, z), (radius * 1.6, height, radius * 1.6))
    LAYOUT.add(label''')
sub('''    boulder = scene.mesh("SphereMesh", radius=0.55, height=1.1, radial_segments=9, rings=5)
    scene.shape(boulder, "stone_dark", (x + 0.2, 0.25, z - 0.1), rng.uniform(0, 360), scale=(1.0, 0.85, 1.05))''',
    '''    sphere(scene, "stone_dark", (x + 0.2, 0.25, z - 0.1), 0.55, (1.0, 0.85, 1.05), rng.uniform(0, 360))''')
sub('''    scene.add("nature_kit/statue_columnDamaged", (0.0, 0.0, -2.0), 20.0, 3.0, single=True)''',
    '''    add_single(scene, "nature_kit/statue_columnDamaged", (0.0, 0.0, -2.0), 20.0, 3.0)''')
sub('''    hoop = scene.mesh("TorusMesh", inner_radius=0.36, outer_radius=0.42, rings=16, ring_segments=4)
    for a, b in ((far * 0.6, 0.8), (-far * 0.4, -0.6)):
        scene.shape(hoop, "iron", frame.p(a, b, FLOOR + 0.03), frame.yaw(20.0))''', '''    for a, b in ((far * 0.6, 0.8), (-far * 0.4, -0.6)):
        torus(scene, "iron", frame.p(a, b, FLOOR + 0.03), 0.36, 0.42, frame.yaw(20.0))''')
sub('''    shoe = scene.mesh("TorusMesh", inner_radius=0.05, outer_radius=0.08, rings=10, ring_segments=4)
    for x, z in ((24.2, 26.2), (21.4, 30.6), (23.0, 21.0)):
        scene.shape(shoe, "iron", (x, 0.02, z), rng.uniform(0, 360))''', '''    for x, z in ((24.2, 26.2), (21.4, 30.6), (23.0, 21.0)):
        torus(scene, "iron", (x, 0.02, z), 0.05, 0.08, rng.uniform(0, 360))''')
sub('''    prism = scene.mesh("PrismMesh", size=(12.4, 3.4, 12.4))
    scene.shape(prism, "plaster", (cx, top + 1.7, cz))''', '''    prism(scene, "plaster", (cx, top + 1.7, cz), (12.4, 3.4, 12.4))''')
sub('''    scene.sign(f"Enseigne_{trade}"''', '''    sign(scene, f"Enseigne_{trade}"''')
sub('''    scene.sign("Enseigne_mairie"''', '''    sign(scene, "Enseigne_mairie"''')
path.write_text(text, encoding="utf-8")
print("ok")
