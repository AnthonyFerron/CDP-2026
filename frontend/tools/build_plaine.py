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


def rotation_z(degrees):
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
    return [[c, -s, 0], [s, c, 0], [0, 0, 1]]


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

    def add(self, model, position, degrees=0.0, scale=1.0, tilt=0.0, roll=0.0):
        basis = multiply(multiply(rotation_y(degrees), rotation_x(tilt)), rotation_z(roll))
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


# Boîte englobante (coin, taille) des modèles à l'échelle 1 : la plupart ont leur origine dans un coin,
# et certains descendent sous leur origine.
MODEL_BOXES = {
    "furniture_kit/desk": ((-0.01, 0.0, -0.38), (0.73, 0.38, 0.56)),
    "furniture_kit/bookcaseClosedWide": ((0.0, 0.0, -0.25), (0.8, 0.79, 0.25)),
    "furniture_kit/bookcaseOpen": ((0.0, 0.0, -0.25), (0.4, 0.88, 0.25)),
    "furniture_kit/bookcaseOpenLow": ((0.0, 0.0, -0.25), (0.4, 0.4, 0.25)),
    "furniture_kit/bookcaseClosedDoors": ((-0.16, 0.0, -0.25), (0.56, 0.85, 0.27)),
    "furniture_kit/kitchenCabinetDrawer": ((0.0, 0.0, -0.45), (0.43, 0.45, 0.48)),
    "furniture_kit/kitchenCabinet": ((0.0, 0.0, -0.45), (0.43, 0.45, 0.48)),
    "furniture_kit/kitchenStove": ((0.0, 0.0, -0.45), (0.43, 0.45, 0.48)),
    "furniture_kit/kitchenSink": ((0.0, 0.0, -0.45), (0.43, 0.49, 0.48)),
    "furniture_kit/sideTableDrawers": ((-0.01, 0.0, -0.21), (0.53, 0.38, 0.39)),
    "furniture_kit/sideTable": ((-0.01, 0.0, -0.21), (0.53, 0.38, 0.22)),
    "furniture_kit/cabinetBed": ((-0.01, 0.0, -0.21), (0.27, 0.23, 0.22)),
    "furniture_kit/tableCloth": ((0.0, 0.0, -0.45), (0.84, 0.33, 0.45)),
    "furniture_kit/table": ((0.0, 0.0, -0.45), (0.84, 0.33, 0.45)),
    "furniture_kit/tableRound": ((0.0, -0.27, -0.8), (0.69, 0.37, 0.8)),
    "furniture_kit/chairDesk": ((-0.17, 0.0, -0.28), (0.48, 0.42, 0.44)),
    "furniture_kit/chair": ((0.0, 0.0, -0.2), (0.2, 0.47, 0.2)),
    "furniture_kit/bench": ((0.0, 0.0, -0.2), (0.4, 0.47, 0.2)),
    "furniture_kit/bedSingle": ((-0.06, -0.13, -1.89), (1.62, 0.51, 1.89)),
    "furniture_kit/bedDouble": ((-0.06, -0.13, -1.89), (1.62, 0.51, 1.91)),
    "furniture_kit/rugRectangle": ((0.0, 0.0, -0.92), (1.57, 0.01, 0.92)),
    "furniture_kit/rugRound": ((0.0, 0.0, -0.92), (0.92, 0.01, 0.92)),
    "furniture_kit/coatRackStanding": ((-0.14, 0.0, -0.14), (0.27, 0.77, 0.27)),
    "furniture_kit/lampRoundFloor": ((-0.02, 0.0, -0.15), (0.15, 0.86, 0.18)),
    "furniture_kit/pottedPlant": ((-0.04, 0.0, -0.24), (0.25, 0.54, 0.29)),
    "furniture_kit/cardboardBoxClosed": ((0.0, 0.0, -0.21), (0.21, 0.28, 0.21)),
    "furniture_kit/books": ((0.0, 0.0, -0.09), (0.15, 0.1, 0.09)),
    "graveyard_kit/altar-stone": ((-0.52, 0.0, -0.33), (1.04, 0.49, 0.65)),
    "graveyard_kit/candle-multiple": ((-0.12, 0.0, -0.13), (0.26, 0.2, 0.27)),
    "graveyard_kit/fire-basket": ((-0.21, 0.0, -0.21), (0.42, 0.17, 0.42)),
    "graveyard_kit/hay-bale": ((-0.3, 0.01, -0.2), (0.61, 0.35, 0.4)),
    "graveyard_kit/hay-bale-bundled": ((-0.3, 0.0, -0.22), (0.61, 0.38, 0.43)),
    "graveyard_kit/lightpost-single": ((-0.1, 0.0, -0.1), (0.21, 1.27, 0.46)),
    "mini_dungeon/barrel": ((-0.26, 0.0, -0.26), (0.52, 0.48, 0.52)),
    "mini_dungeon/chest": ((-0.25, -0.05, -0.25), (0.5, 0.3, 0.7)),
    "mini_dungeon/table": ((-0.44, 0.0, -0.32), (0.88, 0.31, 0.65)),
    "mini_dungeon/weapon-spear": ((-0.07, 0.0, -0.06), (0.15, 0.6, 0.12)),
    "mini_dungeon/shield-round": ((-0.19, -0.19, -0.05), (0.38, 0.38, 0.11)),
    "survival_kit/box-large": ((-0.13, 0.0, -0.25), (0.25, 0.25, 0.5)),
    "survival_kit/barrel": ((-0.12, 0.0, -0.12), (0.24, 0.34, 0.24)),
    "survival_kit/box": ((-0.13, 0.0, -0.13), (0.25, 0.25, 0.25)),
    "fantasy_town_kit/cart-high": ((-0.32, 0.0, -0.64), (0.65, 0.86, 1.39)),
    "castle_kit/siege-ballista": ((-0.66, -0.2, -0.6), (1.33, 1.11, 1.2)),
    "castle_kit/siege-catapult": ((-1.42, -0.2, -0.47), (2.15, 1.38, 0.94)),
    "castle_kit/tree-large": ((-0.44, 0.0, -0.44), (0.89, 1.85, 0.89)),
    "castle_kit/tree-small": ((-0.37, 0.0, -0.36), (0.74, 1.35, 0.72)),
    "fantasy_town_kit/pillar-stone": ((-0.08, 0.0, -0.08), (0.16, 1.0, 0.16)),
    "fantasy_town_kit/stall-red": ((-0.5, 0.0, -0.5), (1.0, 1.24, 1.0)),
    "fantasy_town_kit/stall-green": ((-0.5, 0.0, -0.5), (1.0, 1.24, 1.0)),
    "fantasy_town_kit/stall": ((-0.32, 0.0, -0.5), (0.65, 0.37, 1.0)),
    "fantasy_town_kit/cart": ((-0.32, 0.0, -0.64), (0.65, 0.54, 1.34)),
    "fantasy_town_kit/wheel": ((0.2, 0.0, -0.23), (0.24, 0.48, 0.47)),
    "fantasy_town_kit/poles-horizontal": ((0.4, 0.0, -0.5), (0.1, 1.0, 1.0)),
    "fantasy_town_kit/planks": ((-0.5, 0.0, -0.5), (1.0, 0.06, 1.0)),
    "fantasy_town_kit/planks-half": ((0.0, 0.0, -0.5), (0.5, 0.06, 1.0)),
    "castle_kit/gate": ((-0.08, 0.0, -0.33), (0.15, 0.91, 0.66)),
    "mini_arena/column-damaged": ((-0.3, 0.0, -0.3), (0.6, 0.72, 0.6)),
    "furniture_kit/bedBunk": ((-0.06, -0.13, -1.89), (1.62, 0.98, 1.89)),
    "furniture_kit/bookcaseClosed": ((0.0, 0.0, -0.25), (0.4, 0.85, 0.25)),
    "furniture_kit/tableCross": ((0.0, 0.0, -1.07), (2.03, 0.83, 1.07)),
    "furniture_kit/benchCushionLow": ((-0.01, 0.0, -0.21), (0.42, 0.2, 0.22)),
    "graveyard_kit/lantern-candle": ((-0.12, 0.0, -0.12), (0.24, 0.39, 0.24)),
    "survival_kit/bedroll": ((-0.16, 0.0, -0.3), (0.31, 0.13, 0.61)),
    "survival_kit/workbench": ((-0.15, 0.0, -0.15), (0.3, 0.24, 0.3)),
}


def furniture(scene, model, center, degrees=0.0, scale=2.6, height=None, tilt=0.0, roll=0.0):
    """Pose un modèle centré sur le point donné et posé au sol, même renversé : sa boîte tournée touche le sol
    par son point le plus bas. Une hauteur donne une collision de la taille de la boîte tournée."""
    (px, py, pz), (sx, sy, sz) = MODEL_BOXES[model]
    basis = multiply(multiply(rotation_y(degrees), rotation_x(tilt)), rotation_z(roll))
    corners = []
    for cx in (px, px + sx):
        for cy in (py, py + sy):
            for cz in (pz, pz + sz):
                local = (cx * scale, cy * scale, cz * scale)
                corners.append([sum(basis[r][i] * local[i] for i in range(3)) for r in range(3)])
    low = [min(c[i] for c in corners) for i in range(3)]
    high = [max(c[i] for c in corners) for i in range(3)]
    x = center[0] - (low[0] + high[0]) / 2
    z = center[2] - (low[2] + high[2]) / 2
    scene.add(model, (x, center[1] - low[1], z), degrees, scale, tilt=tilt, roll=roll)
    if height:
        size = [high[i] - low[i] for i in range(3)]
        if tilt or roll:
            height = size[1]
        if round(degrees) % 90 and not tilt and not roll:
            scene.add_box((center[0], center[1] + height / 2, center[2]), (sx * scale, height, sz * scale), degrees)
        else:
            scene.add_box((center[0], center[1] + height / 2, center[2]), (size[0], height, size[2]))


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
    furniture(scene, "fantasy_town_kit/pillar-stone", (11.0, 0.0, 11.0), 40.0, 7.0, height=1.2, tilt=90.0)

    # Bannières et lanternes qui encadrent l'entrée.
    scene.add("fantasy_town_kit/banner-red", (-1.8, 2.6, front + 0.15), -90.0, 3.0)
    scene.add("fantasy_town_kit/banner-red", (1.8, 2.6, front + 0.15), -90.0, 3.0)
    for x in (-2.3, 2.3):
        scene.add("fantasy_town_kit/lantern", (x, 0.0, front + 1.5), 0.0, 2.2)
        scene.add_box((x, 1.7, front + 1.5), (0.5, 3.4, 0.5))

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
    # Rayonnages renversés au sol et rayonnages encore debout, chacun avec sa collision.
    for position, degrees, tilt in (
        ((-5.0, 0.0, 2.0), 20.0, 90.0),
        ((3.0, 0.0, -6.0), -35.0, 90.0),
        ((-7.0, 0.0, -7.0), 90.0, 0.0),
        ((7.0, 0.0, -4.0), -90.0, 0.0),
        ((13.5, 0.0, 7.0), 60.0, 90.0),
    ):
        furniture(scene, "furniture_kit/bookcaseClosedWide", position, degrees, 3.2, height=2.5, tilt=tilt)
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

    # Rayonnages : le long des murs de chaque salle, sauf devant les passages. Chacun est centré sur sa
    # collision, son dos contre la face intérieure du mur.
    shelf_scale = 3.2
    depth = 0.25 * shelf_scale
    inner = half_width - WALL_THICKNESS / 2
    for room in range(rooms):
        start = -room_length * room
        for offset, shelf in ((-3.0, "bookcaseClosedWide"), (-6.0, "bookcaseOpen"), (-9.0, "bookcaseClosedWide")):
            model = f"furniture_kit/{shelf}"
            height = MODEL_BOXES[model][1][1] * shelf_scale
            furniture(scene, model, (-inner + depth / 2, 0.0, start + offset), -90.0, shelf_scale, height=height)
            furniture(scene, model, (inner - depth / 2, 0.0, start + offset), 90.0, shelf_scale, height=height)
    for model, x, z in (("bookcaseClosedWide", 3.2, -0.25), ("bookcaseClosedWide", -3.2, -0.25),
                        ("bookcaseClosed", 0.6, -room_length - 0.25), ("bookcaseClosed", -0.6, -room_length * 2 - 0.25)):
        model = f"furniture_kit/{model}"
        furniture(scene, model, (x, 0.0, z - depth / 2), 180.0, shelf_scale, height=MODEL_BOXES[model][1][1] * shelf_scale)

    # Tables de lecture : chacune porte un indice, placé dans plaine.tscn.
    for x, z, degrees in ((0.0, -6.0, 0.0), (0.0, -18.0, 90.0), (-2.5, -28.0, 0.0), (2.5, -28.0, 0.0)):
        furniture(scene, "furniture_kit/table", (x, 0.0, z), degrees, 3.0, height=1.0)
        furniture(scene, "furniture_kit/books", (x - 0.2, 1.0, z), degrees, 3.0)

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
