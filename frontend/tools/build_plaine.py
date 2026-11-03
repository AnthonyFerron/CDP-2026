"""Génère les ruines et l'intérieur de la bibliothèque de la Plaine, sans dépendance externe.

Les scènes produites s'ouvrent et se modifient dans Godot, mais le script les écrase :
pour un changement durable, modifier ce script puis le relancer depuis le dossier frontend :

    python tools/build_plaine.py
"""

import math
from pathlib import Path

OUTPUT_DIR = Path(__file__).resolve().parent.parent / "scenes" / "levels" / "plaine"
KENNEY = "res://assets/models/kenney"

WALL_SCALE = 4.0
WALL_HEIGHT = 4.0
WALL_THICKNESS = 0.5
# Les murs du kit sont décalés de 0,45 tuile par rapport au centre de leur case.
WALL_OFFSET = 0.45
# Passage laissé libre dans les murs à porte voûtée.
DOORWAY_WIDTH = 1.9
DOORWAY_HEIGHT = 2.9

# Direction du mur vers l'extérieur de la pièce, associée à l'orientation du modèle.
OUTWARD_ANGLES = {(1, 0): 0, (-1, 0): 180, (0, -1): 90, (0, 1): -90}


def rotation_y(degrees):
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
    return [[c, 0, s], [0, 1, 0], [-s, 0, c]]


def rotation_x(degrees):
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
    return [[1, 0, 0], [0, c, -s], [0, s, c]]


def multiply(a, b):
    return [[sum(a[r][i] * b[i][c] for i in range(3)) for c in range(3)] for r in range(3)]


def transform_text(basis, origin):
    values = [value for row in basis for value in row] + list(origin)
    return "Transform3D(" + ", ".join(f"{round(v, 5):g}" for v in values) + ")"


class Scene:
    """Écrit une scène Godot : des modèles instanciés et un corps de collision unique."""

    def __init__(self, root_name):
        self.root_name = root_name
        self.models = {}
        self.boxes = {}
        self.visuals = []
        self.colliders = []

    def _model_id(self, path):
        return self.models.setdefault(path, f"{len(self.models) + 1}_model")

    def _box_id(self, size):
        key = tuple(round(v, 3) for v in size)
        return self.boxes.setdefault(key, f"BoxShape3D_{len(self.boxes) + 1}")

    def add(self, model, position, degrees=0.0, scale=1.0, tilt=0.0):
        basis = multiply(rotation_y(degrees), rotation_x(tilt))
        basis = [[value * scale for value in row] for row in basis]
        name = model.rsplit("/", 1)[-1].replace("-", "_")
        self.visuals.append((name, f"{KENNEY}/{model}.glb", transform_text(basis, position)))

    def add_box(self, center, size, degrees=0.0):
        self.colliders.append((transform_text(rotation_y(degrees), center), self._box_id(size)))

    def text(self):
        lines = ["[gd_scene format=3]", ""]
        for path, identifier in self.models_in_use():
            lines.append(f'[ext_resource type="PackedScene" path="{path}" id="{identifier}"]')
        lines.append("")
        for size, identifier in self.boxes.items():
            lines += [
                f'[sub_resource type="BoxShape3D" id="{identifier}"]',
                f"size = Vector3({size[0]:g}, {size[1]:g}, {size[2]:g})",
                "",
            ]
        lines += [f'[node name="{self.root_name}" type="Node3D"]', ""]
        lines += ['[node name="Models" type="Node3D" parent="."]', ""]
        for index, (name, path, transform) in enumerate(self.visuals):
            lines += [
                f'[node name="{name}_{index}" parent="Models" instance=ExtResource("{self.models[path]}")]',
                f"transform = {transform}",
                "",
            ]
        lines += ['[node name="Collision" type="StaticBody3D" parent="."]', ""]
        for index, (transform, identifier) in enumerate(self.colliders):
            lines += [
                f'[node name="Box{index}" type="CollisionShape3D" parent="Collision"]',
                f"transform = {transform}",
                f'shape = SubResource("{identifier}")',
                "",
            ]
        return "\n".join(lines)

    def models_in_use(self):
        for _, path, _ in self.visuals:
            self._model_id(path)
        return self.models.items()


def wall(scene, kit_model, center, outward, height=WALL_HEIGHT, base=0.0, solid=True):
    """Pose une tuile de mur centrée sur sa ligne, avec sa collision éventuelle."""
    x, z = center
    dx, dz = outward
    offset = WALL_OFFSET * WALL_SCALE
    scene.add(
        f"fantasy_town_kit/{kit_model}",
        (x - dx * offset, base, z - dz * offset),
        OUTWARD_ANGLES[outward],
        WALL_SCALE,
    )
    if solid:
        size = (WALL_THICKNESS, height, WALL_SCALE) if dx else (WALL_SCALE, height, WALL_THICKNESS)
        scene.add_box((x, base + height / 2, z), size)


def doorway(scene, center, outward):
    """Pose un mur voûté : deux collisions latérales et un linteau laissent le passage."""
    x, z = center
    dx, dz = outward
    wall(scene, "wall-doorway-round", center, outward, solid=False)
    side_width = (WALL_SCALE - DOORWAY_WIDTH) / 2
    side_offset = (WALL_SCALE + DOORWAY_WIDTH) / 4
    along = (0, 1) if dx else (1, 0)
    for sign in (-1, 1):
        side_center = (x + along[0] * sign * side_offset, WALL_HEIGHT / 2, z + along[1] * sign * side_offset)
        size = (WALL_THICKNESS, WALL_HEIGHT, side_width) if dx else (side_width, WALL_HEIGHT, WALL_THICKNESS)
        scene.add_box(side_center, size)
    lintel = (WALL_THICKNESS, WALL_HEIGHT - DOORWAY_HEIGHT, DOORWAY_WIDTH) if dx else (
        DOORWAY_WIDTH, WALL_HEIGHT - DOORWAY_HEIGHT, WALL_THICKNESS
    )
    scene.add_box((x, (WALL_HEIGHT + DOORWAY_HEIGHT) / 2, z), lintel)


def against_wall(scene, model, point, inward, along_offset=0.0, scale=3.2, width=0.8, depth=0.25, height=0.8):
    """Adosse un meuble au mur, centré sur le point donné, sa face tournée vers la pièce."""
    x, z = point
    nx, nz = inward
    degrees = {(1, 0): -90, (-1, 0): 90, (0, 1): 180, (0, -1): 0}[inward]
    along_x, along_z = (nz, -nx) if degrees in (0, 180) else (-nz, nx)
    if degrees == 0:
        along_x, along_z = 1, 0
    elif degrees == 180:
        along_x, along_z = -1, 0
    elif degrees == -90:
        along_x, along_z = 0, 1
    else:
        along_x, along_z = 0, -1
    half = width * scale / 2
    origin = (x - along_x * half + along_x * along_offset, 0.0, z - along_z * half + along_z * along_offset)
    scene.add(f"furniture_kit/{model}", origin, degrees, scale)
    real_depth = depth * scale
    center = (
        x + along_x * along_offset + nx * real_depth / 2,
        height * scale / 2,
        z + along_z * along_offset + nz * real_depth / 2,
    )
    size = (real_depth, height * scale, width * scale) if nx else (width * scale, height * scale, real_depth)
    scene.add_box(center, size)


def build_ruins():
    """Ruines de la bibliothèque, à la surface : la façade regarde le portail, vers +Z."""
    scene = Scene("PlaineRuins")
    front, back, side = 8.0, -12.0, 10.0

    # Façade : porte au centre, fenêtres, puis murs qui s'effondrent vers les côtés.
    wall(scene, "wall-door", (0, front), (0, 1))
    wall(scene, "wall-window-stone", (-4, front), (0, 1))
    wall(scene, "wall-window-stone", (4, front), (0, 1))
    wall(scene, "wall-broken", (-8, front), (0, 1), height=3.0)
    wall(scene, "wall-half", (8, front), (0, 1), height=2.0)
    wall(scene, "wall", (0, front), (0, 1), base=WALL_HEIGHT, solid=False)
    wall(scene, "wall-window-stone", (-4, front), (0, 1), base=WALL_HEIGHT, solid=False)
    wall(scene, "wall-broken", (4, front), (0, 1), base=WALL_HEIGHT, solid=False)
    wall(scene, "wall-arch", (0, front), (0, 1), base=WALL_HEIGHT * 2, solid=False)

    # Côtés et fond éventrés, avec de larges brèches.
    for z, model, height in ((6, "wall", 4.0), (2, "wall-broken", 3.0), (-6, "wall-half", 2.0), (-10, "wall", 4.0)):
        wall(scene, model, (-side, z), (-1, 0), height=height)
    for z, model, height in ((6, "wall-broken", 3.0), (-2, "wall-half", 2.0), (-10, "wall-broken", 3.0)):
        wall(scene, model, (side, z), (1, 0), height=height)
    for x, model, height in ((-8, "wall", 4.0), (-4, "wall-broken", 3.0), (4, "wall-half", 2.0), (8, "wall", 4.0)):
        wall(scene, model, (x, back), (0, -1), height=height)

    # Colonnes de la façade, dont une brisée au sol.
    for x in (-6.0, -2.4, 2.4, 6.0):
        scene.add("fantasy_town_kit/pillar-stone", (x, 0.0, front + 3.0), 0.0, 8.0)
        scene.add_box((x, 4.0, front + 3.0), (1.3, 8.0, 1.3))
    scene.add("fantasy_town_kit/pillar-stone", (11.0, 0.5, 11.0), 40.0, 7.0, tilt=84.0)

    # Bannières et lanternes qui encadrent l'entrée.
    scene.add("fantasy_town_kit/banner-red", (-1.8, 2.6, front + 0.15), -90.0, 3.0)
    scene.add("fantasy_town_kit/banner-red", (1.8, 2.6, front + 0.15), -90.0, 3.0)
    scene.add("fantasy_town_kit/lantern", (-2.3, 0.0, front + 1.5), 0.0, 2.2)
    scene.add("fantasy_town_kit/lantern", (2.3, 0.0, front + 1.5), 0.0, 2.2)

    # Gravats et rayonnages renversés, à l'intérieur comme devant le bâtiment.
    for model, position, degrees, scale in (
        ("rock-large", (-11.5, 0.0, 4.0), 30.0, 2.2),
        ("rock-wide", (12.0, 0.0, 2.0), 110.0, 2.4),
        ("rock-large", (6.5, 0.0, -11.0), 200.0, 1.8),
        ("rock-wide", (-3.0, 0.0, -2.0), 70.0, 1.6),
        ("rock-large", (5.0, 0.0, 3.0), 160.0, 1.4),
    ):
        scene.add(f"fantasy_town_kit/{model}", position, degrees, scale)
        scene.add_box((position[0], 0.9 * scale / 2, position[2]), (1.2 * scale, 0.9 * scale, 1.2 * scale))
    for position, degrees, tilt in (
        ((-5.0, 0.4, 2.0), 20.0, 70.0),
        ((3.0, 0.4, -6.0), -35.0, 80.0),
        ((-7.0, 0.0, -7.0), 90.0, 0.0),
        ((7.0, 0.0, -4.0), -90.0, 0.0),
        ((13.5, 0.4, 7.0), 60.0, 75.0),
    ):
        scene.add("furniture_kit/bookcaseClosedWide", position, degrees, 3.2, tilt=tilt)
    scene.add_box((-7.0 + 0.4, 1.25, -7.0 - 1.28), (0.8, 2.5, 2.56))
    scene.add_box((7.0 - 0.4, 1.25, -4.0 + 1.28), (0.8, 2.5, 2.56))
    for position, degrees in (((-3.0, 0.0, 12.5), 30.0), ((4.5, 0.0, 13.5), 200.0), ((-9.0, 0.0, 12.5), 80.0)):
        scene.add("furniture_kit/books", position, degrees, 5.0)
    return scene


def build_interior():
    """Intérieur sous la carte : trois salles en enfilade et une alcôve fermée par une pierre."""
    scene = Scene("LibraryInterior")
    half_width = 6.0
    room_length = 12.0
    rooms = 3
    end = -room_length * rooms
    cell_x = (-4.0, 0.0, 4.0)

    for index in range(rooms * 3):
        z = -2.0 - WALL_SCALE * index
        wall(scene, "wall", (-half_width, z), (-1, 0))
        wall(scene, "wall", (half_width, z), (1, 0))

    # Mur d'entrée, avec la porte qui ramène à la surface.
    for x in cell_x:
        wall(scene, "wall-door" if x == 0 else "wall", (x, 0.0), (0, 1))

    # Murs entre les salles, avec des passages décalés pour casser la ligne droite.
    for z, opening in ((-room_length, -4.0), (-room_length * 2, 4.0)):
        for x in cell_x:
            if x == opening:
                doorway(scene, (x, z), (0, -1))
            else:
                wall(scene, "wall", (x, z), (0, -1))

    # Mur du fond et alcôve du livre.
    wall(scene, "wall", (-4.0, end), (0, -1))
    wall(scene, "wall", (4.0, end), (0, -1))
    doorway(scene, (0.0, end), (0, -1))
    wall(scene, "wall", (-2.0, end - 2.0), (-1, 0))
    wall(scene, "wall", (2.0, end - 2.0), (1, 0))
    wall(scene, "wall", (0.0, end - 4.0), (0, -1))

    floor_center = (0.0, -0.25, (end - 4.0) / 2)
    floor_size = (half_width * 2 + 1, 0.5, -end + 5.0)
    scene.add_box(floor_center, floor_size)
    scene.add_box((0.0, WALL_HEIGHT + 0.25, (end - 4.0) / 2), floor_size)

    # Rayonnages : le long des murs de chaque salle, sauf devant les passages.
    west, east = (-half_width + WALL_THICKNESS / 2, 0), (half_width - WALL_THICKNESS / 2, 0)
    for room in range(rooms):
        start = -room_length * room
        for offset, shelf in ((-3.0, "bookcaseClosedWide"), (-6.0, "bookcaseOpen"), (-9.0, "bookcaseClosedWide")):
            width = 0.8 if shelf == "bookcaseClosedWide" else 0.4
            against_wall(scene, shelf, (west[0], start + offset), (1, 0), width=width, height=0.88)
            against_wall(scene, shelf, (east[0], start + offset), (-1, 0), width=width, height=0.88)
    against_wall(scene, "bookcaseClosedWide", (3.2, -0.25), (0, -1), height=0.88)
    against_wall(scene, "bookcaseClosedWide", (-3.2, -0.25), (0, -1), height=0.88)
    against_wall(scene, "bookcaseClosed", (0.6, -room_length - 0.25), (0, -1), width=0.4, height=0.88)
    against_wall(scene, "bookcaseClosed", (-0.6, -room_length * 2 - 0.25), (0, -1), width=0.4, height=0.88)

    # Tables de lecture : chacune porte un indice, placé dans plaine.tscn.
    for x, z, degrees in ((0.0, -6.0, 0.0), (0.0, -18.0, 90.0), (-2.5, -28.0, 0.0), (2.5, -28.0, 0.0)):
        radians = math.radians(degrees)
        half_x, half_z = 0.84 * 1.5, 0.45 * 1.5
        origin = (
            x - half_x * math.cos(radians) - half_z * math.sin(radians),
            0.0,
            z + half_x * math.sin(radians) - half_z * math.cos(radians) + 2 * half_z * math.cos(radians),
        )
        scene.add("furniture_kit/table", origin, degrees, 3.0)
        size = (2.5, 1.0, 1.35) if degrees == 0 else (1.35, 1.0, 2.5)
        scene.add_box((x, 0.5, z), size)
        scene.add("furniture_kit/books", (x - 0.2, 1.0, z), degrees, 3.0)

    # Détails au sol et lumières de décor, modestes pour rester légères.
    scene.add("furniture_kit/rugRectangle", (-1.7, 0.01, -2.0), 0.0, 3.0)
    scene.add("furniture_kit/rugRectangle", (-1.7, 0.01, -14.5), 0.0, 3.0)
    scene.add("furniture_kit/rugRound", (-1.5, 0.01, -32.0), 0.0, 3.0)
    return scene


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, scene in (("plaine_ruins", build_ruins()), ("library_interior", build_interior())):
        (OUTPUT_DIR / f"{name}.tscn").write_text(scene.text(), encoding="utf-8", newline="\n")
        print(f"{name}.tscn : {len(scene.visuals)} modèles, {len(scene.colliders)} collisions")


if __name__ == "__main__":
    main()
