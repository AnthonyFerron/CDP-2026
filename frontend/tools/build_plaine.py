"""Génère les ruines et l'intérieur de la bibliothèque de la Plaine, sans dépendance externe.

Les scènes produites s'ouvrent et se modifient dans Godot, mais le script les écrase :
pour un changement durable, modifier ce script puis le relancer depuis le dossier frontend :

    python tools/build_plaine.py
"""

import math
import random
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
# Intrados du mur voûté (fantasy_town_kit/wall-doorway-round) à l'échelle du mur : demi-largeur de l'ouverture
# (m) par hauteur au-dessus du pied du mur, relevée sur les sommets du modèle. Droit jusqu'à 2,108 m, puis quatre
# pans jusqu'à la pointe, que le linteau de doorway() coupe à DOORWAY_HEIGHT.
ARCH_PROFILE = ((2.108, 0.8), (2.378, 0.668), (2.65, 0.45), (2.868, 0.178), (2.955, 0.0))
# Écart toléré entre les marches de arch_fill() et l'arche visible, de part et d'autre.
ARCH_TOLERANCE = 0.04

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
        # L'échelle peut aussi se donner par axe du modèle : (x, y, z).
        axes = scale if isinstance(scale, tuple) else (scale, scale, scale)
        basis = [[row[column] * axes[column] for column in range(3)] for row in basis]
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
    "furniture_kit/desk": ((-0.01, 0, -0.38), (0.73, 0.38, 0.39)),
    "furniture_kit/bookcaseClosedWide": ((0.0, 0.0, -0.25), (0.8, 0.79, 0.25)),
    "furniture_kit/bookcaseOpen": ((0.0, 0.0, -0.25), (0.4, 0.88, 0.25)),
    "furniture_kit/bookcaseOpenLow": ((0.0, 0.0, -0.25), (0.4, 0.4, 0.25)),
    "furniture_kit/bookcaseClosedDoors": ((0, 0, -0.25), (0.4, 0.85, 0.25)),
    "furniture_kit/kitchenCabinetDrawer": ((0, 0, -0.45), (0.43, 0.45, 0.45)),
    "furniture_kit/kitchenCabinet": ((0, 0, -0.45), (0.43, 0.45, 0.45)),
    "furniture_kit/kitchenStove": ((0, 0, -0.45), (0.43, 0.45, 0.45)),
    "furniture_kit/kitchenSink": ((0, 0, -0.45), (0.43, 0.49, 0.45)),
    "furniture_kit/sideTableDrawers": ((-0.01, 0, -0.21), (0.53, 0.38, 0.22)),
    "furniture_kit/sideTable": ((-0.01, 0.0, -0.21), (0.53, 0.38, 0.22)),
    "furniture_kit/cabinetBed": ((-0.01, 0.0, -0.21), (0.27, 0.23, 0.22)),
    "furniture_kit/tableCloth": ((0.0, 0.0, -0.45), (0.84, 0.33, 0.45)),
    "furniture_kit/table": ((0.0, 0.0, -0.45), (0.84, 0.33, 0.45)),
    "furniture_kit/tableRound": ((0.0, -0.27, -0.8), (0.69, 0.37, 0.8)),
    "furniture_kit/chairDesk": ((0, 0, -0.31), (0.34, 0.61, 0.31)),
    "furniture_kit/chair": ((0.0, 0.0, -0.2), (0.2, 0.47, 0.2)),
    "furniture_kit/bench": ((0.0, 0.0, -0.2), (0.4, 0.47, 0.2)),
    "furniture_kit/bedSingle": ((0.39, 0, -1.12), (0.57, 0.38, 1.12)),
    "furniture_kit/bedDouble": ((0, 0, -1.12), (0.96, 0.38, 1.12)),
    "furniture_kit/rugRectangle": ((0.0, 0.0, -0.92), (1.57, 0.01, 0.92)),
    "furniture_kit/rugRound": ((0.0, 0.0, -0.92), (0.92, 0.01, 0.92)),
    "furniture_kit/coatRackStanding": ((-0.14, 0.0, -0.14), (0.27, 0.77, 0.27)),
    "furniture_kit/lampRoundFloor": ((-0.02, 0.0, -0.15), (0.15, 0.86, 0.18)),
    "furniture_kit/pottedPlant": ((-0.11, 0, -0.12), (0.21, 0.65, 0.24)),
    "furniture_kit/cardboardBoxClosed": ((0.0, 0.0, -0.21), (0.21, 0.28, 0.21)),
    "furniture_kit/books": ((0.0, 0.0, -0.09), (0.15, 0.1, 0.09)),
    "graveyard_kit/altar-stone": ((-0.52, 0.0, -0.33), (1.04, 0.49, 0.65)),
    "graveyard_kit/candle-multiple": ((-0.12, 0.0, -0.13), (0.26, 0.2, 0.27)),
    "graveyard_kit/fire-basket": ((-0.21, 0.0, -0.21), (0.42, 0.17, 0.42)),
    "graveyard_kit/hay-bale": ((-0.3, 0.01, -0.2), (0.61, 0.35, 0.4)),
    "graveyard_kit/hay-bale-bundled": ((-0.3, 0.0, -0.22), (0.61, 0.38, 0.43)),
    "graveyard_kit/lightpost-single": ((-0.1, 0.0, -0.1), (0.21, 1.27, 0.46)),
    "mini_dungeon/barrel": ((-0.26, 0.0, -0.26), (0.52, 0.48, 0.52)),
    "mini_dungeon/chest": ((-0.25, 0, -0.25), (0.5, 0.45, 0.5)),
    "mini_dungeon/table": ((-0.44, 0.0, -0.32), (0.88, 0.31, 0.65)),
    "mini_dungeon/weapon-spear": ((-0.07, 0.0, -0.06), (0.15, 0.6, 0.12)),
    "mini_dungeon/shield-round": ((-0.19, -0.19, -0.05), (0.38, 0.38, 0.11)),
    "survival_kit/box-large": ((-0.13, 0.0, -0.25), (0.25, 0.25, 0.5)),
    "survival_kit/barrel": ((-0.12, 0.0, -0.12), (0.24, 0.34, 0.24)),
    "survival_kit/box": ((-0.13, 0.0, -0.13), (0.25, 0.25, 0.25)),
    "fantasy_town_kit/cart-high": ((-0.45, 0, -0.65), (0.89, 0.86, 1.39)),
    "castle_kit/siege-ballista": ((-0.64, 0, -0.6), (1.63, 0.91, 1.2)),
    "castle_kit/siege-catapult": ((-1, -0.15, -0.6), (1.74, 1.33, 1.21)),
    "castle_kit/tree-large": ((-0.44, 0.0, -0.44), (0.89, 1.85, 0.89)),
    "castle_kit/tree-small": ((-0.37, 0.0, -0.36), (0.74, 1.35, 0.72)),
    "fantasy_town_kit/pillar-stone": ((-0.08, 0.0, -0.08), (0.16, 1.0, 0.16)),
    "survival_kit/workbench-anvil": ((-0.15, 0, -0.15), (0.32, 0.34, 0.3)),
    "survival_kit/workbench-grind": ((-0.13, 0, -0.17), (0.26, 0.28, 0.33)),
    "mini_dungeon/wood-structure": ((-0.54, 0.0, -0.54), (1.09, 1.0, 1.09)),
    "mini_dungeon/wood-support": ((-0.54, 0.0, -0.12), (1.09, 1.0, 0.24)),
    "survival_kit/resource-stone-large": ((-0.19, 0.0, -0.17), (0.38, 0.16, 0.34)),
    "survival_kit/tool-pickaxe": ((-0.09, 0.0, -0.02), (0.18, 0.24, 0.04)),
    "nature_kit/crops_dirtRow": ((-0.5, 0.0, -0.28), (1.0, 0.05, 0.62)),
    "nature_kit/crops_wheatStageB": ((-0.27, 0.0, -0.22), (0.54, 0.53, 0.45)),
    "nature_kit/crops_cornStageD": ((-0.15, 0.0, -0.2), (0.43, 1.25, 0.35)),
    "nature_kit/crop_pumpkin": ((-0.22, 0.0, -0.23), (0.44, 0.33, 0.45)),
    "nature_kit/fence_simple": ((-0.5, 0.0, -0.5), (1.0, 0.35, 0.07)),
    "graveyard_kit/cross": ((-0.33, 0.0, -0.13), (0.67, 1.05, 0.25)),
    "graveyard_kit/altar-wood": ((-0.52, 0.0, -0.33), (1.05, 0.54, 0.66)),
    "graveyard_kit/bench": ((-0.4, 0.0, -0.23), (0.81, 0.53, 0.46)),
    "graveyard_kit/gravestone-round": ((-0.22, 0.0, -0.13), (0.45, 0.58, 0.25)),
    "graveyard_kit/gravestone-cross": ((-0.22, 0.0, -0.16), (0.45, 0.91, 0.33)),
    "furniture_kit/kitchenBar": ((0.0, 0.0, -0.21), (0.43, 0.42, 0.21)),
    "furniture_kit/stoolBar": ((0.0, 0.0, -0.23), (0.27, 0.44, 0.23)),
    "nature_kit/statue_obelisk": ((-0.15, 0.0, -0.15), (0.31, 0.88, 0.31)),
    "nature_kit/log_stack": ((-0.22, 0.0, -0.35), (0.42, 0.35, 0.71)),
    "nature_kit/tent_detailedOpen": ((-0.44, 0.0, -0.35), (0.87, 0.56, 0.67)),
    "nature_kit/campfire_stones": ((-0.25, 0.0, -0.26), (0.54, 0.08, 0.52)),
    "survival_kit/chest": ((-0.13, 0, -0.14), (0.26, 0.26, 0.27)),
    "fantasy_town_kit/stall-bench": ((-0.13, 0.0, -0.47), (0.26, 0.23, 0.94)),
    "fantasy_town_kit/stall-red": ((-0.5, 0.0, -0.5), (1.0, 1.24, 1.0)),
    "fantasy_town_kit/stall-green": ((-0.5, 0.0, -0.5), (1.0, 1.24, 1.0)),
    "fantasy_town_kit/stall": ((-0.32, 0.0, -0.5), (0.65, 0.37, 1.0)),
    "fantasy_town_kit/cart": ((-0.45, 0, -0.65), (0.89, 0.54, 1.34)),
    "fantasy_town_kit/wheel": ((0.2, 0.0, -0.23), (0.24, 0.48, 0.47)),
    "fantasy_town_kit/poles-horizontal": ((0.4, 0.0, -0.5), (0.1, 1.0, 1.0)),
    "fantasy_town_kit/planks": ((-0.5, 0.0, -0.5), (1.0, 0.06, 1.0)),
    "fantasy_town_kit/planks-half": ((0.0, 0.0, -0.5), (0.5, 0.06, 1.0)),
    "castle_kit/gate": ((-0.08, 0.0, -0.33), (0.15, 0.91, 0.66)),
    "mini_arena/column-damaged": ((-0.3, 0.0, -0.3), (0.6, 0.72, 0.6)),
    "furniture_kit/bedBunk": ((0, 0, -1.09), (0.57, 0.85, 1.09)),
    "furniture_kit/bookcaseClosed": ((0.0, 0.0, -0.25), (0.4, 0.85, 0.25)),
    "furniture_kit/tableCross": ((0, 0, -0.45), (0.85, 0.35, 0.45)),
    "furniture_kit/benchCushionLow": ((-0.01, 0.0, -0.21), (0.42, 0.2, 0.22)),
    "graveyard_kit/lantern-candle": ((-0.12, 0.0, -0.12), (0.24, 0.39, 0.24)),
    "survival_kit/bedroll": ((-0.16, 0.0, -0.3), (0.31, 0.13, 0.61)),
    "survival_kit/workbench": ((-0.15, 0, -0.15), (0.33, 0.29, 0.3)),
    "fantasy_town_kit/stall-stool": ((-0.13, 0.0, -0.13), (0.26, 0.23, 0.26)),
    "survival_kit/barrel-open": ((-0.12, 0.0, -0.12), (0.24, 0.34, 0.24)),
    # Plaine : champ de bataille et bibliothèque.
    "castle_kit/siege-catapult-demolished": ((-0.64, 0.0, -0.87), (1.68, 0.32, 1.67)),
    "castle_kit/siege-ballista-demolished": ((-0.91, 0.0, -0.79), (1.75, 0.51, 1.55)),
    "castle_kit/siege-ram-demolished": ((-1.04, 0.0, -0.8), (2.08, 0.72, 1.65)),
    "castle_kit/siege-tower-demolished": ((-1.09, 0.0, -0.97), (2.17, 2.1, 1.85)),
    "castle_kit/siege-trebuchet-demolished": ((-0.87, 0.0, -1.05), (1.93, 0.31, 2.1)),
    "castle_kit/tower-square-base": ((-0.5, 0.0, -0.5), (1.0, 1.01, 1.0)),
    "castle_kit/tower-square-mid-open": ((-0.47, 0.0, -0.47), (0.93, 1.01, 0.93)),
    "castle_kit/tower-square-mid": ((-0.47, 0.0, -0.47), (0.93, 1.01, 0.93)),
    "castle_kit/tower-square-top": ((-0.5, 0.0, -0.5), (1.0, 0.3, 1.0)),
    "castle_kit/tower-hexagon-top-wood": ((-0.43, 0.0, -0.37), (0.86, 0.46, 0.75)),
    "castle_kit/rocks-large": ((-0.6, 0.0, -0.67), (1.2, 0.5, 1.35)),
    "castle_kit/rocks-small": ((-0.52, 0.0, -0.55), (1.03, 0.5, 1.11)),
    "castle_kit/tree-log": ((-0.12, -0.11, -0.5), (0.25, 0.28, 1.0)),
    "castle_kit/flag-banner-long": ((0.0, 0.0, -0.32), (0.04, 2.17, 0.63)),
    "castle_kit/flag-wide": ((-0.05, 0.0, -0.27), (0.11, 0.87, 0.55)),
    "castle_kit/flag-pennant": ((-0.05, 0.0, -0.52), (0.11, 0.87, 0.57)),
    "nature_kit/bridge_stone": ((-0.52, -0.05, -0.52), (1.04, 0.4, 1.04)),
    "nature_kit/bridge_stoneRound": ((-0.52, -0.05, -0.52), (1.04, 0.45, 1.04)),
    "nature_kit/statue_columnDamaged": ((-0.15, -0.05, -0.15), (0.3, 0.7, 0.3)),
    "nature_kit/statue_head": ((-0.36, -0.05, -0.31), (0.73, 1.0, 0.55)),
    "nature_kit/log_large": ((-0.5, -0.05, -0.25), (1.0, 0.42, 0.55)),
    "survival_kit/fence-fortified": ((-0.25, 0.0, -0.25), (0.5, 0.52, 0.05)),
    "survival_kit/resource-planks": ((-0.19, 0.0, -0.31), (0.37, 0.09, 0.63)),
    "survival_kit/box-large-open": ((-0.13, 0.0, -0.25), (0.25, 0.31, 0.5)),
    "survival_kit/box-open": ((-0.13, 0.0, -0.13), (0.25, 0.31, 0.25)),
    "graveyard_kit/grave": ((-0.38, 0.0, -0.61), (0.72, 0.11, 1.24)),
    "graveyard_kit/cross-wood": ((-0.22, 0.0, -0.22), (0.43, 1.04, 0.43)),
    "graveyard_kit/gravestone-broken": ((-0.22, 0.0, -0.13), (0.51, 0.34, 0.39)),
    "graveyard_kit/debris-wood": ((-0.23, 0.0, -0.25), (0.46, 0.1, 0.5)),
    "graveyard_kit/debris": ((-0.29, 0.0, -0.31), (0.54, 0.16, 0.55)),
    "graveyard_kit/candle": ((-0.07, 0.0, -0.07), (0.14, 0.2, 0.14)),
    "graveyard_kit/urn-round": ((-0.13, 0.0, -0.13), (0.26, 0.38, 0.26)),
    "graveyard_kit/detail-chalice": ((-0.08, 0.0, -0.08), (0.16, 0.25, 0.16)),
    "graveyard_kit/pillar-obelisk": ((-0.18, 0.0, -0.18), (0.35, 1.01, 0.35)),
    "mini_dungeon/weapon-sword": ((-0.12, -0.1, -0.05), (0.23, 0.45, 0.11)),
    "mini_dungeon/shield-rectangle": ((-0.14, 0.0, -0.05), (0.28, 0.3, 0.13)),
    "mini_dungeon/chair": ((-0.17, 0.0, -0.19), (0.35, 0.48, 0.38)),
    "mini_dungeon/banner": ((-0.3, 0.23, -0.53), (0.6, 0.65, 0.1)),
    "mini_dungeon/pot": ((-0.3, 0.0, -0.2), (0.6, 0.43, 0.41)),
    "mini_dungeon/rocks": ((-0.5, 0.0, -0.5), (1.0, 0.5, 1.0)),
    "mini_dungeon/stones": ((-0.45, 0.0, -0.4), (0.89, 0.45, 0.8)),
    "mini_arena/weapon-rack": ((-0.36, 0.0, -0.15), (0.72, 0.47, 0.3)),
    "mini_arena/banner": ((-0.3, 0.0, -0.1), (0.6, 1.02, 0.22)),
    "mini_arena/statue": ((-0.35, 0.0, -0.35), (0.7, 1.34, 0.7)),
    "mini_forest/weapon-arrow": ((-0.06, -0.06, -0.23), (0.12, 0.12, 0.46)),
    "fantasy_town_kit/rock-large": ((-0.87, 0.0, -0.72), (1.67, 1.16, 1.55)),
    "fantasy_town_kit/rock-wide": ((-0.55, 0.0, -0.78), (1.09, 1.02, 1.57)),
    "fantasy_town_kit/banner-red": ((0.38, 0.16, -0.25), (0.05, 0.84, 0.5)),
    "fantasy_town_kit/banner-green": ((0.38, 0.16, -0.25), (0.05, 0.84, 0.5)),
    "fantasy_town_kit/pillar-wood": ((-0.08, 0.0, -0.08), (0.16, 1.0, 0.16)),
    "fantasy_town_kit/lantern": ((-0.11, 0.0, -0.11), (0.22, 1.56, 0.22)),
}


# Meubles modernes du kit Furniture, sans place dans Codia : où qu'ils soient demandés, ils sont remplacés par
# leur équivalent médiéval (brasero de cuisine, tonneaux, coffres, tabouret de marché, chaise de bois).
MEDIEVAL = {
    "furniture_kit/kitchenStove": "graveyard_kit/fire-basket",
    "furniture_kit/kitchenSink": "survival_kit/barrel-open",
    "furniture_kit/kitchenCabinet": "survival_kit/chest",
    "furniture_kit/kitchenCabinetDrawer": "survival_kit/chest",
    "furniture_kit/kitchenBar": "survival_kit/barrel",
    "furniture_kit/stoolBar": "fantasy_town_kit/stall-stool",
    "furniture_kit/chairDesk": "furniture_kit/chair",
}


def furniture(scene, model, center, degrees=0.0, scale=2.6, height=None, tilt=0.0, roll=0.0):
    """Pose un modèle centré sur le point donné et posé au sol, même renversé : sa boîte tournée touche le sol
    par son point le plus bas. Une hauteur donne une collision de la taille de la boîte tournée."""
    replaced = MEDIEVAL.get(model)
    if replaced:
        model = replaced
        # La collision suit la taille du remplaçant, plus petit que le meuble moderne.
        if height:
            height = min(height, MODEL_BOXES[model][1][1] * scale)
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


def camp(scene, rng, cx, cz, heading):
    """Campement à l'abandon autour d'un feu éteint : deux tentes, des caisses, des tonneaux et une charrette couchée.
    heading oriente l'ensemble ; tout est posé au sol et a sa collision."""
    import math as _math

    def at(u, v):
        c, s = _math.cos(_math.radians(heading)), _math.sin(_math.radians(heading))
        return (cx + c * u + s * v, 0.0, cz - s * u + c * v)

    furniture(scene, "nature_kit/campfire_stones", at(0.0, 0.0), heading, 3.0)
    for u, yaw in ((-3.6, 60.0), (3.4, -50.0)):
        furniture(scene, "nature_kit/tent_detailedOpen", at(u, -2.4), heading + yaw, 3.6, height=2.0)
    for u, v in ((-1.8, 2.4), (1.6, 2.6)):
        furniture(scene, "nature_kit/log_stack", at(u, v), heading + rng.uniform(60, 120), 2.6, height=0.9)
    furniture(scene, "survival_kit/chest", at(2.6, 1.2), heading + 20.0, 3.4, height=0.8)
    for u, v in ((-3.4, 1.6), (-4.2, 2.6)):
        furniture(scene, "mini_dungeon/barrel", at(u, v), rng.uniform(0, 360), 2.6, height=1.2)
    furniture(scene, "survival_kit/box-large", at(4.4, -0.2), heading + 70.0, 3.6, height=0.9)
    furniture(scene, "fantasy_town_kit/cart", at(-1.0, -6.0), heading + 100.0, 2.8, height=1.5, roll=90.0)


def against_wall(scene, model, point, inward, along_offset=0.0, scale=3.2, width=0.8, depth=0.25, height=0.8):
    """Adosse un meuble au mur, centré sur le point donné, sa face tournée vers la pièce.
    Les meubles du kit ont leur face avant vers +Z, leur origine au coin avant gauche et leur dos vers -Z :
    on tourne +Z vers la pièce, et l'origine se pose à une profondeur du mur."""
    x, z = point
    nx, nz = inward
    degrees = {(1, 0): 90, (-1, 0): -90, (0, 1): 0, (0, -1): 180}[inward]
    # Axe x du modèle une fois tourné : rotation_y(degrees) envoie (1, 0, 0) vers (cos, 0, -sin).
    along_x = round(math.cos(math.radians(degrees)))
    along_z = round(-math.sin(math.radians(degrees)))
    half = width * scale / 2
    real_depth = depth * scale
    origin = (x - along_x * half + along_x * along_offset + nx * real_depth, 0.0,
              z - along_z * half + along_z * along_offset + nz * real_depth)
    scene.add(f"furniture_kit/{model}", origin, degrees, scale)
    center = (
        x + along_x * along_offset + nx * real_depth / 2,
        height * scale / 2,
        z + along_z * along_offset + nz * real_depth / 2,
    )
    size = (real_depth, height * scale, width * scale) if nx else (width * scale, height * scale, real_depth)
    scene.add_box(center, size)


# ----------------------------------------------------------------------------------------------------------------
# Les plaines d'Hexcole : champ de bataille de la guerre contre Vibelandia, au pied de l'ancienne bibliothèque, et ses
# archives souterraines.
# ----------------------------------------------------------------------------------------------------------------

# Replats du champ de bataille (x, z, rayon), comme SITES dans plaine_terrain.gd : le sol y est à plat, à la hauteur 0,
# comme sous les ruines (rayon 24), sur le chemin (|x| < 5) et au campement.
SITES = {
    "camp": (14.0, 42.0, 7.0),
    "graves": (22.5, 50.5, 5.0),
    "siege": (-14.0, 39.0, 7.5),
    "tower": (-23.0, 52.0, 7.5),
    "battery": (17.0, -22.0, 6.5),
}
# Le chemin franchit la coulée de lave sur un pont de pierre, centré sur x = 0.
BRIDGE_Z = 29.5
BRIDGE_SCALE = 4.0
# Le tablier dépasse à peine le sol, pour ne pas se confondre avec lui.
BRIDGE_DECK = 0.04
# Hauteur du toit de la bibliothèque, à l'échelle du modèle (0,571 m) : 3,4 m au faîte.
ROOF_RISE = 6.0

# Couleurs des formes simples.
PARCHMENT = (0.86, 0.78, 0.6)
PARCHMENT_DARK = (0.62, 0.52, 0.36)
INK = (0.08, 0.06, 0.05)
WOOD_DARK = (0.24, 0.15, 0.09)
IRON = (0.16, 0.15, 0.16)
WAX = (0.92, 0.86, 0.7)
FLAME = (1.0, 0.62, 0.25)
GOLD = (0.78, 0.6, 0.25)
ASH = (0.12, 0.11, 0.11)


def transform_of(position, degrees=0.0, scale=1.0, tilt=0.0, roll=0.0):
    basis = multiply(multiply(rotation_y(degrees), rotation_x(tilt)), rotation_z(roll))
    axes = scale if isinstance(scale, tuple) else (scale, scale, scale)
    basis = [[row[column] * axes[column] for column in range(3)] for row in basis]
    return transform_text(basis, position)


class PlaineScene(Scene):
    """Scène de la Plaine : en plus des modèles et des collisions de Scene, des formes simples colorées (feuillets,
    bougies, lustres, pupitres) et des modèles répétés regroupés en MultiMesh (livres des rayonnages)."""

    def __init__(self, root_name):
        super().__init__(root_name)
        self.materials = {}
        self.meshes = {}
        self.shapes = []
        self.many = {}

    def _material(self, color, emission, roughness):
        key = (tuple(round(c, 3) for c in color), round(emission, 3), round(roughness, 2))
        return self.materials.setdefault(key, f"Material_{len(self.materials) + 1}")

    def _mesh(self, kind, dims, color, emission=0.0, roughness=0.9):
        key = (kind, tuple(round(d, 4) for d in dims), self._material(color, emission, roughness))
        return self.meshes.setdefault(key, f"Mesh_{len(self.meshes) + 1}")

    def add_shape(self, kind, dims, color, position, degrees=0.0, tilt=0.0, roll=0.0, emission=0.0, roughness=0.9):
        """Forme simple : box (x, y, z), cylinder (rayon, hauteur), cone (rayon bas, rayon haut, hauteur),
        torus (rayon intérieur, rayon extérieur) ou sphere (rayon)."""
        mesh = self._mesh(kind, dims, color, emission, roughness)
        self.shapes.append((kind, mesh, transform_of(position, degrees, 1.0, tilt, roll)))

    def add_many(self, model, position, degrees=0.0, scale=1.0, tilt=0.0, roll=0.0):
        """Modèle Kenney répété sans collision, écrit en MultiMesh."""
        self.many.setdefault(("model", f"{KENNEY}/{model}.glb"), []).append(
            transform_of(position, degrees, scale, tilt, roll))

    def add_tilted_box(self, center, size, degrees=0.0, tilt=0.0):
        """Collision inclinée, pour une rampe ou un meuble couché de travers."""
        self.colliders.append((transform_of(center, degrees, 1.0, tilt), self._box_id(size)))

    def add_many_shape(self, kind, dims, color, position, degrees=0.0, tilt=0.0, roll=0.0, emission=0.0):
        mesh = self._mesh(kind, dims, color, emission)
        self.many.setdefault(("mesh", mesh), []).append(transform_of(position, degrees, 1.0, tilt, roll))

    def text(self):
        script = "multimesh_script"
        for kind, source in self.many:
            if kind == "model":
                self._model_id(source)
        lines = ["[gd_scene format=3]", ""]
        for path, identifier in self.models_in_use():
            lines.append(f'[ext_resource type="PackedScene" path="{path}" id="{identifier}"]')
        if self.many:
            lines.append(f'[ext_resource type="Script" path="res://scenes/levels/plaine/model_multimesh.gd" id="{script}"]')
        lines.append("")
        for size, identifier in self.boxes.items():
            lines += [
                f'[sub_resource type="BoxShape3D" id="{identifier}"]',
                f"size = Vector3({size[0]:g}, {size[1]:g}, {size[2]:g})",
                "",
            ]
        for (color, emission, roughness), identifier in self.materials.items():
            lines += [
                f'[sub_resource type="StandardMaterial3D" id="{identifier}"]',
                f"albedo_color = Color({color[0]:g}, {color[1]:g}, {color[2]:g}, 1)",
                f"roughness = {roughness:g}",
            ]
            if emission:
                lines += [
                    "emission_enabled = true",
                    f"emission = Color({color[0]:g}, {color[1]:g}, {color[2]:g}, 1)",
                    f"emission_energy_multiplier = {emission:g}",
                ]
            lines.append("")
        for (kind, dims, material), identifier in self.meshes.items():
            if kind == "box":
                body = [f"size = Vector3({dims[0]:g}, {dims[1]:g}, {dims[2]:g})"]
                resource = "BoxMesh"
            elif kind == "cylinder":
                body = [f"top_radius = {dims[0]:g}", f"bottom_radius = {dims[0]:g}", f"height = {dims[1]:g}",
                        "radial_segments = 8", "rings = 1"]
                resource = "CylinderMesh"
            elif kind == "cone":
                body = [f"bottom_radius = {dims[0]:g}", f"top_radius = {dims[1]:g}", f"height = {dims[2]:g}",
                        "radial_segments = 8", "rings = 1"]
                resource = "CylinderMesh"
            elif kind == "torus":
                body = [f"inner_radius = {dims[0]:g}", f"outer_radius = {dims[1]:g}", "rings = 20", "ring_segments = 6"]
                resource = "TorusMesh"
            else:
                body = [f"radius = {dims[0]:g}", f"height = {dims[0] * 2:g}", "radial_segments = 8", "rings = 4"]
                resource = "SphereMesh"
            lines += [f'[sub_resource type="{resource}" id="{identifier}"]', f'material = SubResource("{material}")']
            lines += body + [""]
        lines += [f'[node name="{self.root_name}" type="Node3D"]', ""]
        lines += ['[node name="Models" type="Node3D" parent="."]', ""]
        for index, (name, path, transform) in enumerate(self.visuals):
            lines += [
                f'[node name="{name}_{index}" parent="Models" instance=ExtResource("{self.models[path]}")]',
                f"transform = {transform}",
                "",
            ]
        if self.shapes:
            lines += ['[node name="Shapes" type="Node3D" parent="."]', ""]
            for index, (kind, mesh, transform) in enumerate(self.shapes):
                lines += [
                    f'[node name="{kind}_{index}" type="MeshInstance3D" parent="Shapes"]',
                    f"transform = {transform}",
                    f'mesh = SubResource("{mesh}")',
                    "",
                ]
        if self.many:
            lines += ['[node name="Repeated" type="Node3D" parent="."]', ""]
            for index, ((kind, source), transforms) in enumerate(self.many.items()):
                name = source.rsplit("/", 1)[-1].replace(".glb", "").replace("-", "_") if kind == "model" else source
                reference = f'model = ExtResource("{self.models[source]}")' if kind == "model" else (
                    f'mesh = SubResource("{source}")')
                lines += [
                    f'[node name="{name}_{index}" type="Node3D" parent="Repeated"]',
                    f'script = ExtResource("{script}")',
                    reference,
                    "transforms = Array[Transform3D]([" + ", ".join(transforms) + "])",
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


def along_wall(center, inward, offset, out=0.0, up=0.0):
    """Point d'un meuble adossé : son centre, décalé le long du mur puis vers la pièce."""
    nx, nz = inward
    return (center[0] + nz * offset + nx * out, center[1] + up, center[2] - nx * offset + nz * out)


def furniture_fit(scene, model, center, degrees=0.0, scale=2.6, height=None, tilt=0.0, roll=0.0, footprint=1.0):
    """Comme furniture(), mais la collision suit l'objet : une boîte tournée comme lui, à la taille de sa boîte une
    fois penché ou couché, et non la boîte droite qui englobe le tout (elle laissait des murs invisibles autour des
    objets couchés de biais). footprint réduit l'emprise des épaves et des tas, faits de pièces éparses."""
    furniture(scene, model, center, degrees, scale, tilt=tilt, roll=roll)
    if not height:
        return
    (px, py, pz), (sx, sy, sz) = MODEL_BOXES[model]
    basis = multiply(rotation_x(tilt), rotation_z(roll))
    corners = []
    for cx in (px, px + sx):
        for cy in (py, py + sy):
            for cz in (pz, pz + sz):
                local = (cx * scale, cy * scale, cz * scale)
                corners.append([sum(basis[r][i] * local[i] for i in range(3)) for r in range(3)])
    size = [max(c[i] for c in corners) - min(c[i] for c in corners) for i in range(3)]
    high = size[1] if (tilt or roll) else height
    scene.add_box((center[0], center[1] + high / 2, center[2]), (size[0] * footprint, high, size[2] * footprint), degrees)


def facing(inward):
    """Angle qui tourne la face avant (+Z) d'un modèle vers la pièce."""
    return math.degrees(math.atan2(inward[0], inward[1]))


# Hauteurs des tablettes des rayonnages (échelle 1), de la plus basse au dessus du meuble.
SHELVES = {
    "furniture_kit/bookcaseClosedWide": (0.07, 0.31, 0.55, 0.79),
    "furniture_kit/bookcaseOpen": (0.13, 0.37, 0.61, 0.85),
    "furniture_kit/bookcaseClosed": (0.13, 0.37, 0.61, 0.85),
}
SHELF_SCALE = 3.2
# Livres décoratifs : le modèle est un groupe de trois livres, dos tournés vers +Z.
BOOKS_SCALE = 3.0
BOOK_GROUP_WIDTH = 0.15 * BOOKS_SCALE
# Livre à fouiller (searchable_book.gd) : sa tranche dépasse un peu de la rangée.
SEARCHABLE_THICKNESS = 0.11
SEARCHABLE_HEIGHT = 0.36


def bookcase(scene, rng, model, wall_point, inward, fill=0.85, gaps=(), searched=None, top=True):
    """Rayonnage adossé au mur : wall_point est sur la face intérieure du mur, au milieu du meuble. Ses tablettes sont
    garnies de livres, avec des trous, des livres penchés ou couchés. gaps : emplacements (tablette, décalage) laissés
    libres pour un livre à fouiller ; searched reçoit leur transformation."""
    (_, _, _), (width, height, depth) = MODEL_BOXES[model]
    width, height, depth = width * SHELF_SCALE, height * SHELF_SCALE, depth * SHELF_SCALE
    nx, nz = inward
    center = (wall_point[0] + nx * depth / 2, 0.0, wall_point[1] + nz * depth / 2)
    degrees = facing(inward)
    furniture_fit(scene, model, center, degrees, SHELF_SCALE, height=height)
    # Repère du meuble : a suit l'axe x des modèles tournés comme lui, n sort vers la pièce.
    ax, az = math.cos(math.radians(degrees)), -math.sin(math.radians(degrees))
    front = depth / 2

    def at(u, out, y):
        return (center[0] + ax * u + nx * out, y, center[2] + az * u + nz * out)

    usable = width - 0.24
    levels = SHELVES[model] if top else SHELVES[model][:-1]
    lying = 0.1 * BOOKS_SCALE
    for shelf, level in enumerate(levels):
        y = level * SHELF_SCALE + 0.005
        reserved = [offset for gap_shelf, offset in gaps if gap_shelf == shelf]
        u = -usable / 2
        while u < usable / 2 - BOOK_GROUP_WIDTH:
            step = BOOK_GROUP_WIDTH + rng.uniform(0.0, 0.05)
            if any(u - SEARCHABLE_THICKNESS / 2 - 0.03 < offset < u + BOOK_GROUP_WIDTH + SEARCHABLE_THICKNESS / 2 + 0.03
                   for offset in reserved):
                u += step
                continue
            # Une rangée pleine autour d'un livre à fouiller : il s'en distingue en dépassant d'elle.
            choice = rng.random() * (0.8 if reserved else 1.0)
            # Le dessus du meuble n'a que quelques piles.
            if shelf == len(SHELVES[model]) - 1 and choice < 0.6:
                u += step
                continue
            if choice > fill:
                u += step * rng.uniform(1.0, 2.0)
                continue
            inset = rng.uniform(0.05, 0.12)
            if choice > fill - 0.1:
                # Pile couchée : le modèle tourné d'un quart de tour sur son axe avant s'étend vers -x.
                scene.add_many("furniture_kit/books", at(u + lying, front - inset, y), degrees, BOOKS_SCALE, roll=90.0)
                u += lying + rng.uniform(0.02, 0.06)
                continue
            scene.add_many("furniture_kit/books", at(u, front - inset, y), degrees, BOOKS_SCALE,
                           roll=rng.choice((0.0, 0.0, 0.0, 6.0, -6.0)))
            u += step
    if searched is not None:
        for shelf, offset in gaps:
            y = SHELVES[model][shelf] * SHELF_SCALE + SEARCHABLE_HEIGHT / 2 + 0.005
            searched.append((at(offset, front + 0.03, y), inward))
    return center, degrees


def floor_books(scene, rng, x, z, count, spread=0.8, y=0.0):
    """Livres tombés au sol, couchés et ouverts en désordre."""
    for _ in range(count):
        px, pz = x + rng.uniform(-spread, spread), z + rng.uniform(-spread, spread)
        # Debout, renversés sur le dos ou en pile couchée : chaque pose garde le modèle au-dessus du sol.
        # Couchés, sur le dos ou sur la tranche : moins de 30 cm, on les enjambe sans collision.
        tilt, roll = rng.choice(((90.0, 0.0), (90.0, 0.0), (90.0, 12.0), (90.0, -12.0)))
        scene.add_many("furniture_kit/books", (px, y + 0.003, pz), rng.uniform(0, 360),
                       BOOKS_SCALE * rng.uniform(0.85, 1.0), tilt=tilt, roll=roll)


def sheets(scene, rng, x, z, count, spread=1.0, y=0.0, scrolls=0):
    """Documents abandonnés : feuilles de parchemin posées à plat, et quelques rouleaux."""
    for _ in range(count):
        color = PARCHMENT if rng.random() < 0.7 else PARCHMENT_DARK
        scene.add_many_shape("box", (0.3, 0.004, 0.4), color,
                             (x + rng.uniform(-spread, spread), y + 0.004, z + rng.uniform(-spread, spread)),
                             rng.uniform(0, 360))
    for _ in range(scrolls):
        scene.add_many_shape("cylinder", (0.045, 0.5), PARCHMENT,
                             (x + rng.uniform(-spread, spread), y + 0.045, z + rng.uniform(-spread, spread)),
                             rng.uniform(0, 360), roll=90.0)


def candle(scene, x, y, z, height=0.22, radius=0.035):
    """Bougie de cire et sa flamme."""
    scene.add_shape("cylinder", (radius, height), WAX, (x, y + height / 2, z))
    scene.add_shape("sphere", (radius * 0.9,), FLAME, (x, y + height + radius * 0.8, z), emission=4.0)


def candle_stand(scene, x, z, y=0.0):
    """Chandelier sur pied : un socle, un fût de fer, une coupelle et un cierge allumé."""
    scene.add_shape("cylinder", (0.17, 0.05), IRON, (x, y + 0.025, z), roughness=0.5)
    scene.add_shape("cone", (0.09, 0.03, 0.22), IRON, (x, y + 0.16, z), roughness=0.5)
    scene.add_shape("cylinder", (0.025, 1.3), IRON, (x, y + 0.92, z), roughness=0.5)
    scene.add_shape("cylinder", (0.12, 0.03), IRON, (x, y + 1.585, z), roughness=0.5)
    candle(scene, x, y + 1.6, z, 0.26, 0.045)
    scene.add_box((x, y + 0.85, z), (0.4, 1.7, 0.4))


def chandelier(scene, x, z, ceiling=WALL_HEIGHT, drop=0.9, radius=0.75):
    """Lustre de fer suspendu par trois chaînes, garni de bougies : sa lumière est posée dans plaine.tscn."""
    y = ceiling - drop
    scene.add_shape("torus", (radius - 0.06, radius), IRON, (x, y, z), roughness=0.5)
    scene.add_shape("torus", (0.12, 0.18), IRON, (x, y - 0.12, z), roughness=0.5)
    for index in range(3):
        angle = math.radians(index * 120.0 + 30.0)
        cx, cz = x + math.cos(angle) * radius * 0.97, z + math.sin(angle) * radius * 0.97
        length = math.hypot(drop, radius * 0.97)
        tilt = math.degrees(math.atan2(radius * 0.97, drop))
        scene.add_shape("box", (0.03, length, 0.03), IRON, ((cx + x) / 2, y + drop / 2, (cz + z) / 2),
                        degrees=-math.degrees(angle) + 90.0, tilt=0.0, roll=tilt)
    for index in range(8):
        angle = math.radians(index * 45.0)
        candle(scene, x + math.cos(angle) * (radius - 0.03), y + 0.02, z + math.sin(angle) * (radius - 0.03), 0.16)
    scene.add_box((x, y + 0.1, z), (radius * 2 + 0.1, 0.4, radius * 2 + 0.1))


def fallen_chandelier(scene, x, z, radius=0.75):
    """Lustre tombé du plafond, couché de travers, ses bougies éteintes éparpillées : bas, il s'enjambe."""
    scene.add_shape("torus", (radius - 0.06, radius), IRON, (x, 0.1, z), degrees=20.0, tilt=3.0, roughness=0.5)
    for index in range(5):
        angle = math.radians(index * 70.0 + 10.0)
        scene.add_shape("cylinder", (0.035, 0.16), WAX,
                        (x + math.cos(angle) * (radius + 0.2), 0.035, z + math.sin(angle) * (radius + 0.2)),
                        degrees=index * 37.0, tilt=90.0)
    # Couché, il ne dépasse pas la cheville : on l'enjambe, sans collision.


def lectern(scene, x, z, degrees, open_book=True):
    """Pupitre de lecture : un pied, un plateau incliné vers le lecteur, un livre ouvert dessus."""
    scene.add_shape("box", (0.7, 0.06, 0.5), WOOD_DARK, (x, 0.03, z), degrees)
    scene.add_shape("box", (0.14, 1.05, 0.14), WOOD_DARK, (x, 0.55, z), degrees)
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
    top = (x, 1.12, z)
    scene.add_shape("box", (0.72, 0.05, 0.52), WOOD_DARK, top, degrees, tilt=24.0)
    if open_book:
        for side in (-1, 1):
            px, pz = x + c * side * 0.15, z - s * side * 0.15
            scene.add_shape("box", (0.29, 0.03, 0.4), PARCHMENT, (px, 1.155, pz), degrees, tilt=24.0,
                            roll=-side * 4.0)
        scene.add_shape("box", (0.62, 0.02, 0.44), (0.42, 0.1, 0.08), (x, 1.135, z), degrees, tilt=24.0)
    scene.add_box((x, 0.6, z), (0.7, 1.2, 0.55), degrees)


# Dessus des tables, à l'échelle 1, mesuré sur les sommets de leur maillage : ce qu'on y pose part de là (la boîte de
# MODEL_BOXES arrondit, et 0,31 enfonçait feuillets et bougies dans le plateau, 0,33 les faisait flotter).
DUNGEON_TABLE_TOP = 0.315
TABLE_TOP = 0.327


def writing_desk(scene, rng, x, z, degrees, overturned=False):
    """Pupitre de scribe : une table, un tabouret, une bougie, un encrier, une plume et des feuillets."""
    if overturned:
        furniture_fit(scene, "mini_dungeon/table", (x, 0.0, z), degrees, 2.2, height=1.0, roll=90.0)
        furniture_fit(scene, "fantasy_town_kit/stall-stool", (x + 1.2, 0.0, z + 0.9), degrees + 40.0, 2.4, height=0.5,
                  tilt=90.0)
        sheets(scene, rng, x + 0.6, z + 0.4, 6, 1.0)
        return
    furniture_fit(scene, "mini_dungeon/table", (x, 0.0, z), degrees, 2.2, height=0.69)
    top = DUNGEON_TABLE_TOP * 2.2
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))

    def on_desk(u, v):
        return x + c * u + s * v, z - s * u + c * v

    # Tabouret du scribe, devant la table.
    sx, sz = on_desk(0.0, 1.05)
    furniture_fit(scene, "fantasy_town_kit/stall-stool", (sx, 0.0, sz), degrees, 2.4, height=0.55)
    cx, cz = on_desk(-0.65, -0.3)
    candle(scene, cx, top, cz, 0.18, 0.04)
    ix, iz = on_desk(0.55, -0.35)
    scene.add_shape("cylinder", (0.05, 0.08), INK, (ix, top + 0.04, iz))
    scene.add_shape("box", (0.012, 0.012, 0.32), WAX, (ix + 0.03, top + 0.16, iz), degrees + 30.0, tilt=-50.0)
    # Feuillets et livre ouvert sur la table.
    for index in range(rng.randint(2, 4)):
        px, pz = on_desk(rng.uniform(-0.4, 0.4), rng.uniform(-0.15, 0.25))
        scene.add_shape("box", (0.3, 0.004, 0.4), PARCHMENT, (px, top + 0.003 + index * 0.003, pz),
                        degrees + rng.uniform(-20, 20))
    bx, bz = on_desk(0.0, 0.1)
    scene.add_shape("box", (0.5, 0.025, 0.34), (0.35, 0.12, 0.08), (bx, top + 0.02, bz), degrees)
    for side in (-1, 1):
        px, pz = on_desk(side * 0.12, 0.1)
        scene.add_shape("box", (0.23, 0.02, 0.32), PARCHMENT, (px, top + 0.04, pz), degrees, roll=side * 3.0)


def reading_table(scene, rng, x, z, degrees, chairs=((-1, -0.55), (-1, 0.55), (1, -0.55), (1, 0.55)), tipped=()):
    """Longue table de lecture, ses chaises, des livres empilés et une bougie."""
    furniture_fit(scene, "furniture_kit/table", (x, 0.0, z), degrees, 3.0, height=0.99)
    top = TABLE_TOP * 3.0
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))

    def at(u, v):
        return x + c * u + s * v, z - s * u + c * v

    for index, (side, along) in enumerate(chairs):
        px, pz = at(along * 2.0, side * 1.1)
        yaw = degrees + (180.0 if side > 0 else 0.0)
        if index in tipped:
            # Chaise renversée sur le dos : une boîte orientée comme elle, pas la boîte droite qui l'englobe.
            furniture_fit(scene, "furniture_kit/chair", (px + 0.2 * side, 0.0, pz), yaw + 25.0, 3.0, tilt=-90.0)
            # Seuls l'assise et les pieds se dressent ; le dossier à plat s'enjambe.
            lying = math.radians(yaw + 25.0)
            scene.add_box((px + 0.2 * side + math.sin(lying) * 0.33, 0.3, pz + math.cos(lying) * 0.33), (0.6, 0.6, 0.7),
                          yaw + 25.0)
        else:
            furniture_fit(scene, "furniture_kit/chair", (px, 0.0, pz), yaw + rng.uniform(-12, 12), 3.0, height=1.4)
    for u, v in ((-0.7, 0.1), (0.6, -0.15)):
        px, pz = at(u, v)
        scene.add_many("furniture_kit/books", (px, top, pz), degrees + rng.uniform(-30, 30), BOOKS_SCALE, roll=90.0)
    px, pz = at(0.05, 0.05)
    scene.add_shape("box", (0.5, 0.025, 0.34), (0.3, 0.14, 0.1), (px, top + 0.0125, pz), degrees + 10.0)
    for side in (-1, 1):
        qx, qz = at(0.05 + side * 0.12, 0.05)
        scene.add_shape("box", (0.23, 0.02, 0.32), PARCHMENT, (qx, top + 0.035, qz), degrees + 10.0, roll=side * 3.0)
    cx, cz = at(0.0, -0.3)
    furniture_fit(scene, "graveyard_kit/candle-multiple", (cx, top, cz), 0.0, 1.8)
    for index in range(rng.randint(1, 3)):
        qx, qz = at(rng.uniform(-1.0, 1.0), rng.uniform(-0.4, 0.4))
        scene.add_shape("box", (0.3, 0.004, 0.4), PARCHMENT, (qx, top + 0.003, qz), rng.uniform(0, 360))


def wall_map(scene, x, z, inward, width=2.4, height=1.6, y=2.0):
    """Carte du royaume clouée au mur : un parchemin, la côte, les routes et les villes, et le volcan en rouge."""
    nx, nz = inward
    degrees = facing(inward)

    def on_map(u, v, out):
        return x + nz * -u * -1 + nx * out if False else (x + nz * u + nx * out, y + v, z - nx * u + nz * out)

    scene.add_shape("box", (width + 0.12, height + 0.12, 0.04), WOOD_DARK, on_map(0.0, 0.0, 0.02), degrees)
    scene.add_shape("box", (width, height, 0.02), PARCHMENT_DARK, on_map(0.0, 0.0, 0.045), degrees)
    # Rivage et routes : des traits d'encre sur le parchemin.
    for u, v, length, angle in ((-0.7, 0.35, 0.9, 20), (0.1, 0.1, 1.2, -15), (0.6, -0.3, 0.8, 35), (-0.3, -0.35, 0.9, -5),
                                (0.85, 0.35, 0.5, 80)):
        scene.add_shape("box", (length, 0.025, 0.005), INK, on_map(u, v, 0.058), degrees, roll=angle)
    # Villes, et le volcan au nord.
    for u, v in ((-0.75, 0.2), (0.15, 0.05), (0.55, -0.45), (-0.25, -0.5)):
        scene.add_shape("box", (0.08, 0.08, 0.008), INK, on_map(u, v, 0.06), degrees)
    scene.add_shape("box", (0.16, 0.16, 0.008), (0.65, 0.12, 0.05), on_map(0.3, 0.55, 0.06), degrees, roll=45.0)


def wall_banner(scene, x, z, inward, y=1.0, color="red"):
    """Bannière de Codia accrochée au mur, côté pièce."""
    nx, nz = inward
    # Le modèle a son tissu décalé de 0,38 sur x : on le ramène contre le mur.
    degrees = facing(inward) - 90.0
    scale = 2.6
    scene.add(f"fantasy_town_kit/banner-{color}", (x + nx * (0.04 - 0.38 * scale), y, z + nz * (0.04 - 0.38 * scale)),
              degrees, scale)


LANTERN_POST = 2.7
# Bas de la collision d'une lanterne qui pend : sous le haut du joueur (1,8 m), pour qu'il s'y cogne la tête.
LANTERN_HEAD = 1.7


def lantern_post(scene, x, z, toward):
    """Poteau de bois et sa potence, d'où pend une lanterne à bougie : toward (+1 ou -1) oriente la potence sur x.
    Comme les lanternes du chemin (plaine_scatter.gd) ; la lanterne pend au-dessus de la tête du joueur."""
    scene.add("fantasy_town_kit/pillar-wood", (x, 0.0, z), 0.0, (2.0, LANTERN_POST, 2.0))
    scene.add("fantasy_town_kit/pillar-wood", (x, LANTERN_POST - 0.17, z), 0.0, (1.2, 0.75, 1.2), roll=-90.0 * toward)
    hang = LANTERN_POST - 0.17 - 0.39 * 1.6
    scene.add("graveyard_kit/lantern-candle", (x + toward * 0.58, hang, z), 0.0, 1.6)
    scene.add_shape("sphere", (0.06,), FLAME, (x + toward * 0.58, hang + 0.3, z), emission=4.0)
    scene.add_box((x, (LANTERN_POST + 0.3) / 2, z), (0.5, LANTERN_POST + 0.3, 0.5))
    # La potence et sa lanterne : on s'y cogne la tête en sautant, ou en passant dessous.
    scene.add_box((x + toward * 0.47, (LANTERN_HEAD + LANTERN_POST + 0.1) / 2, z),
                  (0.62, LANTERN_POST + 0.1 - LANTERN_HEAD, 0.42))


def soldiers_camp(scene, rng, cx, cz, heading):
    """Campement des soldats, comme camp() mais espacé pour que rien ne se traverse : feu éteint, deux tentes, bois,
    coffre (le journal du soldat y est posé, dans plaine.tscn), tonneaux, caisse et charrette couchée."""

    def at(u, v):
        c, s = math.cos(math.radians(heading)), math.sin(math.radians(heading))
        return (cx + c * u + s * v, 0.0, cz - s * u + c * v)

    furniture_fit(scene, "nature_kit/campfire_stones", at(0.0, 0.0), heading, 3.0)
    for u, yaw in ((-3.6, 60.0), (3.4, -50.0)):
        furniture_fit(scene, "nature_kit/tent_detailedOpen", at(u, -2.6), heading + yaw, 3.6)
    for u, v in ((-1.6, 2.6), (1.2, 3.4)):
        furniture_fit(scene, "nature_kit/log_stack", at(u, v), heading + rng.uniform(60, 120), 2.6, height=0.9)
    furniture_fit(scene, "survival_kit/chest", at(2.6, 1.2), heading + 20.0, 3.4, height=0.9)
    for u, v in ((-4.0, 0.9), (-5.5, 2.7)):
        furniture_fit(scene, "mini_dungeon/barrel", at(u, v), rng.uniform(0, 360), 2.6, height=1.2)
    furniture_fit(scene, "survival_kit/box-large", at(5.6, 1.4), heading + 70.0, 3.6, height=0.9)
    furniture_fit(scene, "fantasy_town_kit/cart", at(-1.0, -6.4), heading + 100.0, 2.8, roll=90.0)


def arch_half_width(height):
    """Demi-largeur de l'arche visible du mur voûté, à cette hauteur au-dessus du pied du mur."""
    if height <= ARCH_PROFILE[0][0]:
        return ARCH_PROFILE[0][1]
    for (h0, w0), (h1, w1) in zip(ARCH_PROFILE, ARCH_PROFILE[1:]):
        if height <= h1:
            return w0 + (w1 - w0) * (height - h0) / (h1 - h0)
    return 0.0


def arch_height(half_width):
    """Hauteur où l'arche visible du mur voûté ne laisse plus que cette demi-largeur."""
    for (h0, w0), (h1, w1) in zip(ARCH_PROFILE, ARCH_PROFILE[1:]):
        if half_width >= w1:
            return h0 + (h1 - h0) * (w0 - half_width) / (w0 - w1)
    return ARCH_PROFILE[-1][0]


def arch_steps():
    """Marches de arch_fill(), de l'extérieur vers la pointe : (bord intérieur, bord extérieur, bas), toutes jusqu'au
    linteau. Chacune reste à ARCH_TOLERANCE au plus de l'arche sur sa hauteur : elle commence où l'arche passe à
    ARCH_TOLERANCE du bord de la précédente, et son bord est au milieu de ce que l'arche gagne sur sa hauteur."""
    straight = ARCH_PROFILE[0][1]
    steps = [(straight, DOORWAY_WIDTH / 2, 0.0)]
    edge = straight
    start = straight - ARCH_TOLERANCE
    while True:
        low = arch_height(start)
        end = max(start - 2 * ARCH_TOLERANCE, arch_half_width(DOORWAY_HEIGHT))
        if DOORWAY_HEIGHT - low < 0.03:
            break
        inner = round((start + end) / 2, 3)
        steps.append((inner, edge, round(low, 3)))
        edge = inner
        start -= 2 * ARCH_TOLERANCE
    return steps


def arch_fill(scene, center, outward, base=0.0):
    """Complète la collision d'un mur voûté posé par doorway() : son arche ne laisse que ±0,80 m de passage jusqu'à
    2,1 m, puis se referme en pointe jusqu'à 2,95 m, alors que doorway() laisse ±0,95 m jusqu'au linteau (2,9 m).
    Des marches suivent l'arche à 4 cm près (5 cm dans les 4 derniers millimètres sous le linteau), d'après
    ARCH_PROFILE et ARCH_TOLERANCE ; `base` est le pied du mur."""
    x, z = center
    along = (0, 1) if outward[0] else (1, 0)
    for sign in (-1, 1):
        for inner, outer, low in arch_steps():
            offset = sign * (inner + outer) / 2
            width = outer - inner
            high = DOORWAY_HEIGHT
            size = (WALL_THICKNESS, high - low, width) if outward[0] else (width, high - low, WALL_THICKNESS)
            scene.add_box((x + along[0] * offset, base + (low + high) / 2, z + along[1] * offset), size)


def build_ruins():
    """Bibliothèque, à la surface : la façade regarde le portail, vers +Z. Le bâtiment est entier, comme ses archives
    sous la carte : mêmes murs, porte au centre, 12 m de large, un long toit à deux pans ; la bataille a laissé ses
    traces autour (gravats, rayonnage jeté dehors, colonne brisée)."""
    scene = PlaineScene("PlaineRuins")
    front, back, side = 8.0, -20.0, 6.0

    # Façade : la porte au centre, comme le mur d'entrée des archives ; au-dessus, un étage de façade à fenêtres et
    # son arche, qui cachent le pignon du toit.
    wall(scene, "wall", (-4, front), (0, 1))
    wall(scene, "wall-door", (0, front), (0, 1))
    wall(scene, "wall", (4, front), (0, 1))
    wall(scene, "wall-window-stone", (-4, front), (0, 1), base=WALL_HEIGHT, solid=False)
    wall(scene, "wall", (0, front), (0, 1), base=WALL_HEIGHT, solid=False)
    wall(scene, "wall-window-stone", (4, front), (0, 1), base=WALL_HEIGHT, solid=False)
    wall(scene, "wall-arch", (0, front), (0, 1), base=WALL_HEIGHT * 2, solid=False)

    # Côtés et fond pleins, des mêmes murs que les salles.
    for z in range(int(front) - 2, int(back), -4):
        wall(scene, "wall", (-side, z), (-1, 0))
        wall(scene, "wall", (side, z), (1, 0))
    for x in (-4, 0, 4):
        wall(scene, "wall", (x, back), (0, -1))
    # Plafond au haut des murs, comme dans les archives : le bâtiment est fermé, on n'entre que par la porte.
    scene.add_box((0.0, WALL_HEIGHT + 0.15, (front + back) / 2), (side * 2 + 0.5, 0.3, front - back + 0.5))

    # Toit à deux pans, faîte dans la longueur : un pan par case de 4 m, les deux bouts en croupe.
    roof_scale = (WALL_SCALE / 1.1, ROOF_RISE, (side + 0.4) / 0.535)
    for z in range(int(front) - 2, int(back), -4):
        if z == int(front) - 2:
            scene.add("fantasy_town_kit/roof-gable-end", (0.0, WALL_HEIGHT, z), 90.0, roof_scale)
        elif z == int(back) + 2:
            scene.add("fantasy_town_kit/roof-gable-end", (0.0, WALL_HEIGHT, z), -90.0, roof_scale)
        else:
            scene.add("fantasy_town_kit/roof-gable", (0.0, WALL_HEIGHT, z), 90.0, roof_scale)

    # Colonnes de la façade, dont une brisée au sol.
    for x in (-6.0, -2.4, 2.4, 6.0):
        scene.add("fantasy_town_kit/pillar-stone", (x, 0.0, front + 3.0), 0.0, 8.0)
        scene.add_box((x, 4.0, front + 3.0), (1.3, 8.0, 1.3))
    furniture_fit(scene, "fantasy_town_kit/pillar-stone", (13.5, 0.0, 13.5), 40.0, 7.0, height=1.2, tilt=90.0)

    # Bannières qui encadrent l'entrée, et deux poteaux de bois dont la potence tend une lanterne à bougie vers la
    # porte (leur lumière est dans plaine.tscn).
    scene.add("fantasy_town_kit/banner-red", (-1.8, 2.6, front + 0.15), -90.0, 3.0)
    scene.add("fantasy_town_kit/banner-red", (1.8, 2.6, front + 0.15), -90.0, 3.0)
    for x in (-2.3, 2.3):
        lantern_post(scene, x, front + 1.5, -1.0 if x > 0 else 1.0)

    # Gravats tombés le long des murs : la collision suit la boîte du modèle.
    for model, position, degrees, scale in (
        ("rock-large", (-12.6, 0.0, 3.6), 30.0, 2.2),
        ("rock-wide", (12.0, 0.0, 2.0), 110.0, 2.4),
        ("rock-large", (9.0, 0.0, -9.8), 200.0, 1.8),
        ("rock-wide", (-8.6, 0.0, -14.0), 70.0, 1.6),
    ):
        model = f"fantasy_town_kit/{model}"
        furniture_fit(scene, model, position, degrees, scale)
    # Rayonnages jetés dehors pendant le pillage, couchés dans la cendre, chacun avec sa collision.
    for position, degrees, tilt in (
        ((13.5, 0.0, 7.0), 60.0, 90.0),
        ((-10.5, 0.0, -9.0), 15.0, 90.0),
    ):
        furniture_fit(scene, "furniture_kit/bookcaseClosedWide", position, degrees, 3.2, height=2.5, tilt=tilt)
    # Campement des soldats envoyés défendre la bibliothèque, sur le replat au bord du chemin.
    soldiers_camp(scene, random.Random(7), 14.0, 42.0, -30.0)
    for position, degrees in (((-3.0, 0.0, 12.5), 30.0), ((4.5, 0.0, 13.5), 200.0), ((-9.0, 0.0, 12.5), 80.0)):
        furniture_fit(scene, "furniture_kit/books", position, degrees, 5.0, height=0.5)
    return scene


def bridge(scene):
    """Pont de pierre du chemin au-dessus de la coulée : trois travées, l'arche au milieu, au ras du sol aux deux bouts.
    Le tablier a sa collision et les parapets empêchent de tomber dans la lave."""
    span = 1.04 * BRIDGE_SCALE
    base = BRIDGE_DECK - 0.15 * BRIDGE_SCALE
    for index, model in ((-1, "bridge_stone"), (0, "bridge_stoneRound"), (1, "bridge_stone")):
        scene.add(f"nature_kit/{model}", (0.0, base, BRIDGE_Z + index * span), 90.0, BRIDGE_SCALE)
    length = span * 3
    scene.add_box((0.0, BRIDGE_DECK - 0.4, BRIDGE_Z), (span - 0.2, 0.8, length))
    for side in (-1, 1):
        scene.add_box((side * 1.85, BRIDGE_DECK + 0.55, BRIDGE_Z), (0.3, 1.1, length))


def stake_line(scene, rng, start, end, broken=(), fallen=()):
    """Barricade de pieux taillés entre deux points ; certains pans manquent, d'autres sont tombés."""
    scale = 3.6
    width = 0.5 * scale
    dx, dz = end[0] - start[0], end[1] - start[1]
    count = max(1, round(math.hypot(dx, dz) / width))
    degrees = -math.degrees(math.atan2(dz, dx))
    for index in range(count):
        if index in broken:
            continue
        t = (index + 0.5) / count
        x, z = start[0] + dx * t, start[1] + dz * t
        if index in fallen:
            furniture_fit(scene, "survival_kit/fence-fortified", (x, 0.0, z + 0.6), degrees + rng.uniform(-10, 10), scale,
                      height=0.4, tilt=-80.0)
        else:
            furniture_fit(scene, "survival_kit/fence-fortified", (x, 0.0, z), degrees + rng.uniform(-4, 4), scale,
                      height=1.9, tilt=rng.uniform(-6, 6))


def planted_sword(scene, rng, x, z, scale=3.0):
    """Épée plantée en terre, un peu de travers."""
    yaw = rng.uniform(0, 360)
    scene.add("mini_dungeon/weapon-sword", (x, 0.1 * scale - 0.25, z), yaw, scale,
              tilt=rng.uniform(-14, 14), roll=rng.uniform(-10, 10))
    scene.add_box((x, 0.65, z), (0.25 * scale, 1.3, 0.14 * scale), yaw)


def planted_spear(scene, rng, x, z, scale=3.2, lean=25.0):
    """Lance ou carreau fiché de biais dans le sol ; sa collision suit la hampe penchée."""
    yaw = rng.uniform(0, 360)
    scene.add("mini_dungeon/weapon-spear", (x, -0.3, z), yaw, scale, tilt=lean)
    leaning_box(scene, x, z, yaw, lean, 0.6 * scale, thickness=0.25, y=-0.3)


def leaning_box(scene, x, z, yaw, lean, length, thickness=0.3, top=2.2, width=None, shift=0.0, start=0.0, y=0.0):
    """Collision d'une hampe plantée de biais : une boîte penchée comme elle (rotation_x(lean), puis yaw), le long de
    son axe, de start jusqu'à la hauteur top au-delà de laquelle le joueur ne la touche plus. width l'élargit à
    l'étoffe d'une bannière, décalée de shift sur l'axe z du modèle."""
    reach = min(length, top / max(math.cos(math.radians(lean)), 0.2)) - start
    if reach <= 0.0:
        return
    basis = multiply(rotation_y(yaw), rotation_x(lean))
    local = (0.0, start + reach / 2, shift)
    center = [sum(basis[r][i] * local[i] for i in range(3)) for r in range(3)]
    scene.add_tilted_box((x + center[0], y + center[1], z + center[2]), (thickness, reach, width or thickness), yaw, lean)


def arrows(scene, rng, x, z, count, spread=1.5):
    """Volée de flèches fichées dans le sol, chacune avec sa petite collision."""
    for _ in range(count):
        px, pz = x + rng.uniform(-spread, spread), z + rng.uniform(-spread, spread)
        yaw = rng.uniform(0, 360)
        scene.add_many("mini_forest/weapon-arrow", (px, 0.2, pz), yaw, 1.7, tilt=rng.uniform(-62, -40))
        scene.add_box((px, 0.25, pz), (0.2, 0.5, 0.2))


def banner_pole(scene, rng, x, z, model="castle_kit/flag-banner-long", scale=1.8, lean=10.0, degrees=None):
    """Bannière déchirée sur sa hampe, plantée de travers dans la cendre."""
    yaw = rng.uniform(0, 360) if degrees is None else degrees
    stretch = rng.uniform(0.85, 1.0)
    scene.add(model, (x, -0.2, z), yaw, (scale, scale * stretch, scale), tilt=lean)
    (_, _, pz), (_, sy, sz) = MODEL_BOXES[model]
    if model.endswith("pennant"):
        # Une hampe, et un fanion entre 0,57 et 0,73 de sa hauteur.
        leaning_box(scene, x, z, yaw, lean, sy * scale * stretch, y=-0.2)
        leaning_box(scene, x, z, yaw, lean, 0.73 * scale * stretch, width=0.5 * scale, shift=-0.24 * scale,
                    start=0.57 * scale * stretch, y=-0.2)
    else:
        # Panneau ou étoffe tendue sur toute la hauteur.
        leaning_box(scene, x, z, yaw, lean, sy * scale * stretch, thickness=0.25, width=sz * scale,
                    shift=(pz + sz / 2) * scale, y=-0.2)


def book_cart(scene, rng, x, z, degrees, tipped=False, scale=2.6):
    """Charrette de livres abandonnée pendant l'évacuation : son plateau chargé, et des livres tombés autour."""
    if tipped:
        furniture_fit(scene, "fantasy_town_kit/cart", (x, 0.0, z), degrees, scale, roll=90.0)
        floor_books(scene, rng, x + 1.4, z + 0.4, 9, 1.1)
        sheets(scene, rng, x + 1.8, z, 10, 1.6)
        return
    furniture_fit(scene, "fantasy_town_kit/cart", (x, 0.0, z), degrees, scale)
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
    bed = 0.3 * scale
    for u, v in ((-0.2, -0.6), (0.25, -0.5), (-0.15, 0.0), (0.2, 0.2), (0.0, 0.6), (-0.25, 0.55)):
        px, pz = x + c * u + s * v, z - s * u + c * v
        scene.add_many("furniture_kit/books", (px, bed + rng.uniform(0.0, 0.08), pz), degrees + rng.uniform(-40, 40),
                       BOOKS_SCALE, roll=90.0 if rng.random() < 0.6 else 0.0)
    floor_books(scene, rng, x + c * 1.6, z - s * 1.6, 4, 0.8)


def graves(scene, rng):
    """Tombes des défenseurs de la bibliothèque : deux rangées de tertres, croix et épées plantées, boucliers posés."""
    gx, gz, _ = SITES["graves"]
    for row, z in enumerate((gz - 1.8, gz + 2.2)):
        for column, x in enumerate((gx - 2.6, gx, gx + 2.6)):
            furniture_fit(scene, "graveyard_kit/grave", (x, 0.0, z), rng.uniform(-4, 4), 2.2)
            head = z - 1.9
            if (row + column) % 2:
                furniture_fit(scene, "graveyard_kit/cross-wood", (x, 0.0, head), rng.uniform(-6, 6), 2.0, height=2.1,
                          tilt=rng.uniform(-5, 5))
                # Le bouclier du mort, posé à plat sur son tertre.
                furniture_fit(scene, "mini_dungeon/shield-round", (x, 0.11 * 2.2, z + 0.2), rng.uniform(0, 360), 2.4,
                          height=0.3, tilt=-90.0)
            else:
                planted_sword(scene, rng, x, head)
    sheets(scene, rng, gx, gz + 0.2, 3, 2.0)


def watchtower(scene, rng):
    """Tour de guet de la bibliothèque, effondrée : la base tient, l'étage s'est fendu, le crénelage et la guérite de
    bois gisent autour, dans les gravats."""
    tx, tz, _ = SITES["tower"]
    scale = 3.4
    bx, bz = tx - 0.6, tz + 1.2
    scene.add("castle_kit/tower-square-base", (bx, 0.0, bz), 8.0, scale)
    scene.add("castle_kit/tower-square-mid-open", (bx, 1.01 * scale, bz), 8.0, scale, tilt=4.0)
    scene.add_box((bx, 1.01 * scale, bz), (3.45, 2.02 * scale, 3.45), 8.0)
    furniture_fit(scene, "castle_kit/tower-square-top", (tx + 4.0, 0.0, tz - 0.6), 30.0, 3.0, height=1.0, roll=6.0)
    furniture_fit(scene, "castle_kit/tower-hexagon-top-wood", (tx - 4.6, 0.0, tz - 2.4), 140.0, 3.0,
              roll=14.0)
    for position, model, degrees, scale_rock in (((tx + 0.0, tz + 5.4), "rocks-large", 20.0, 2.4),
                                                 ((tx - 4.0, tz + 2.8), "rocks-small", 70.0, 2.2),
                                                 ((tx + 1.0, tz - 4.6), "rocks-small", 150.0, 1.8)):
        furniture_fit(scene, f"castle_kit/{model}", (position[0], 0.0, position[1]), degrees, scale_rock)
    for position, degrees in (((tx + 4.2, tz + 3.4), 15.0), ((tx - 1.6, tz - 4.4), 75.0), ((tx + 5.6, tz - 4.0), 120.0)):
        # 2,5 : la pile ne monte qu'à 22 cm, on l'enjambe sans collision.
        furniture_fit(scene, "survival_kit/resource-planks", (position[0], 0.0, position[1]), degrees, 2.5)
    banner_pole(scene, rng, tx - 3.4, tz + 5.4, lean=28.0)


def siege_works(scene, rng):
    """Engins de siège de Vibelandia, brisés par les défenseurs : trébuchet, catapulte, boulets et roues."""
    sx, sz, _ = SITES["siege"]
    furniture_fit(scene, "castle_kit/siege-trebuchet-demolished", (sx - 3.0, 0.0, sz + 2.5), 25.0, 2.4)
    furniture_fit(scene, "castle_kit/siege-catapult-demolished", (sx + 3.8, 0.0, sz - 2.4), -40.0, 2.2)
    for position, scale in (((sx - 2.2, sz - 4.0), 1.6), ((sx - 0.8, sz - 4.6), 1.4), ((sx - 1.8, sz - 5.9), 1.2)):
        furniture_fit(scene, "survival_kit/resource-stone-large", (position[0], 0.0, position[1]), rng.uniform(0, 360),
                  scale * 2.0)
    for position, degrees in (((sx - 5.6, sz - 3.0), 30.0), ((sx + 5.2, sz + 3.4), 120.0)):
        furniture_fit(scene, "fantasy_town_kit/wheel", (position[0], 0.0, position[1]), degrees, 3.0, height=0.3, roll=90.0)
    furniture_fit(scene, "nature_kit/log_large", (sx + 3.0, 0.0, sz + 5.4), 165.0, 2.4, height=1.0)
    for position, degrees in (((sx - 0.2, sz - 2.2), 40.0), ((sx + 2.4, sz + 2.2), 100.0)):
        # 2,5 : la pile ne monte qu'à 22 cm, on l'enjambe sans collision.
        furniture_fit(scene, "survival_kit/resource-planks", (position[0], 0.0, position[1]), degrees, 2.5)
    banner_pole(scene, rng, sx + 0.6, sz + 3.6, model="castle_kit/flag-wide", scale=3.4, lean=-16.0)
    arrows(scene, rng, sx + 4.5, sz - 6.0, 9, 1.2)


def battery(scene, rng):
    """Batterie de balistes de l'ennemi, derrière la bibliothèque : brisées, leurs carreaux plantés dans la cendre."""
    bx, bz, _ = SITES["battery"]
    furniture_fit(scene, "castle_kit/siege-ballista-demolished", (bx - 2.4, 0.0, bz + 2.0), 210.0, 2.2)
    furniture_fit(scene, "castle_kit/siege-ballista-demolished", (bx + 2.6, 0.0, bz - 2.2), 160.0, 2.2)
    for position in ((bx - 4.0, bz - 2.0), (bx - 3.2, bz - 2.8), (bx - 1.0, bz - 5.0)):
        planted_spear(scene, rng, position[0], position[1], lean=35.0)
    furniture_fit(scene, "mini_dungeon/barrel", (bx + 3.6, 0.0, bz + 2.4), 30.0, 2.6, height=1.2)
    furniture_fit(scene, "survival_kit/box-large-open", (bx + 1.8, 0.0, bz + 3.6), 80.0, 3.4, height=1.0)
    # Carreaux tirés sur la bibliothèque, fichés dans le sol devant son mur du fond.
    # Le mur du fond est en z = -20 : les carreaux se plantent juste devant, penchés vers lui.
    for x in (-5.5, -2.8, 1.5, 4.8):
        planted_spear(scene, rng, x, -22.1 + 0.3 * rng.uniform(-1.0, 1.0), lean=-38.0)


def library_front(scene, rng):
    """Devant la façade : la barricade des défenseurs, le bélier qui a enfoncé la porte, et les livres qu'on a voulu
    sauver."""
    # Barricade en deux ailes, laissant le chemin libre ; la charrette renversée en bouche l'aile est.
    stake_line(scene, rng, (-4.2, 20.2), (-12.8, 18.9), broken=(2,), fallen=(4,))
    stake_line(scene, rng, (8.2, 19.0), (14.6, 15.4), fallen=(1,))
    book_cart(scene, rng, 6.0, 19.8, 80.0, tipped=True)
    for position in ((3.2, 18.8), (3.9, 17.4)):
        furniture_fit(scene, "mini_dungeon/barrel", (position[0], 0.0, position[1]), rng.uniform(0, 360), 2.2, height=1.0)
    # Le bélier, abandonné devant l'entrée, pointé vers la porte.
    furniture_fit(scene, "castle_kit/siege-ram-demolished", (7.2, 0.0, 13.4), 35.0, 2.4)
    # Charrette chargée devant la brèche ouest, où l'on passait les livres.
    book_cart(scene, rng, -13.2, -2.0, 0.0)
    floor_books(scene, rng, -11.0, -2.0, 5, 0.6)
    sheets(scene, rng, -11.5, -1.0, 8, 1.4)
    # Armes et boucliers des défenseurs, au pied de la barricade.
    for position in ((-6.0, 17.0), (-10.4, 15.3), (10.4, 16.0)):
        planted_sword(scene, rng, position[0], position[1])
    for position, degrees in (((-7.6, 18.0), 20.0), ((11.6, 20.8), 200.0)):
        furniture_fit(scene, "mini_dungeon/shield-round", (position[0], 0.0, position[1]), degrees, 2.6, height=0.3,
                  tilt=-90.0)
    furniture_fit(scene, "mini_dungeon/shield-rectangle", (-12.0, 0.0, 14.2), 60.0, 3.0, height=0.4, tilt=-90.0)
    arrows(scene, rng, -8.5, 21.2, 8, 1.2)
    arrows(scene, rng, 11.0, 20.0, 6, 1.0)
    banner_pole(scene, rng, -5.2, 21.8, model="castle_kit/flag-banner-long", lean=-9.0, degrees=10.0)
    banner_pole(scene, rng, 5.4, 22.6, model="castle_kit/flag-banner-long", lean=14.0, degrees=-20.0)
    # Livres brûlés et feuillets que le vent pousse vers le chemin.
    floor_books(scene, rng, -5.2, 13.2, 4, 0.8)
    floor_books(scene, rng, 4.6, 11.6, 3, 0.6)
    sheets(scene, rng, -1.5, 14.5, 10, 2.2)


def road(scene, rng):
    """Le long du chemin : une charrette de livres abandonnée, une bannière tombée, des armes."""
    book_cart(scene, rng, -4.0, 41.5, 4.0)
    furniture_fit(scene, "fantasy_town_kit/wheel", (-4.4, 0.0, 44.4), 70.0, 2.6, height=0.3, roll=90.0)
    sheets(scene, rng, -2.6, 40.0, 6, 1.4)
    banner_pole(scene, rng, 4.2, 26.0, model="castle_kit/flag-pennant", scale=3.0, lean=-30.0, degrees=80.0)
    for position in ((4.6, 34.2), (-4.3, 24.6)):
        planted_sword(scene, rng, position[0], position[1])
    arrows(scene, rng, 3.8, 12.0, 4, 0.8)


def camp_extras(scene, rng):
    """Autour du campement : le râtelier d'armes, la table du capitaine et le tableau de l'ordre d'évacuation."""
    cx, cz, _ = SITES["camp"]
    furniture_fit(scene, "mini_arena/weapon-rack", (cx - 5.2, 0.0, cz + 4.8), 60.0, 2.6, height=1.2)
    furniture_fit(scene, "mini_dungeon/table", (cx + 5.0, 0.0, cz + 3.6), -30.0, 2.2, height=0.69)
    top = DUNGEON_TABLE_TOP * 2.2
    scene.add_shape("box", (1.0, 0.006, 0.7), PARCHMENT_DARK, (cx + 5.0, top + 0.004, cz + 3.6), -24.0)
    furniture_fit(scene, "graveyard_kit/candle", (cx + 4.6, top, cz + 3.4), 0.0, 1.6)
    furniture_fit(scene, "mini_dungeon/chair", (cx + 3.2, 0.0, cz + 5.5), 150.0, 2.4, height=1.1)


# Positions de Vibelandia (x, z, rayon), comme VIBELANDIA_CAMPS dans scenes/levels/plaine/plaine_life.gd : les engins de
# siège et la batterie de balistes. Les bannières plantées là portent le vert de Vibelandia (variante b des couleurs du
# kit Castle, posée par plaine_life.gd) ; les autres gardent le bleu de Codia, celui des bannières du château du hub.
VIBELANDIA_CAMPS = ((-14.0, 39.0, 9.0), (17.0, -22.0, 8.0))


def in_vibelandia_camp(x, z):
    return any(math.hypot(x - cx, z - cz) < radius for cx, cz, radius in VIBELANDIA_CAMPS)


def standards(scene):
    """Les étendards des deux camps. Vibelandia : un grand étendard planté au bord du chemin, devant ses engins de
    siège, un autre piétiné à plat dans la cendre, un troisième sur la batterie de balistes. Codia : l'étendard des
    défenseurs, encore debout au-dessus de leurs tombes. Posés après tout le reste, avec leur propre tirage : les
    noms et les places du décor existant ne bougent pas."""
    rng = random.Random(5804)
    planted = []
    banner_pole(scene, rng, -8.6, 40.2, model="castle_kit/flag-banner-long", scale=2.1, lean=7.0, degrees=100.0)
    planted.append((-8.6, 40.2, True))
    # Piétiné : couché à plat dans la cendre ; à 7 cm du sol, on l'enjambe, sans collision.
    furniture_fit(scene, "castle_kit/flag-banner-long", (-16.6, 0.0, 36.7), 196.0, 1.6, roll=90.0)
    planted.append((-16.6, 36.7, True))
    bx, bz, _ = SITES["battery"]
    banner_pole(scene, rng, bx - 0.2, bz - 3.0, model="castle_kit/flag-wide", scale=3.2, lean=-12.0, degrees=225.0)
    planted.append((bx - 0.2, bz - 3.0, True))
    gx, gz, _ = SITES["graves"]
    # Tourné vers le sud-ouest, vers le chemin d'arrivée : le soleil l'éclaire et son bleu se lit depuis le portail et
    # le campement.
    banner_pole(scene, rng, gx, gz - 5.3, model="castle_kit/flag-banner-long", scale=2.0, lean=3.0, degrees=-120.0)
    planted.append((gx, gz - 5.3, False))
    for x, z, enemy in planted:
        assert in_vibelandia_camp(x, z) == enemy, (x, z)


def build_battlefield():
    """Champ de bataille des plaines d'Hexcole, sur les replats du terrain : tout y est posé au sol, à la hauteur 0."""
    scene = PlaineScene("PlaineBattlefield")
    rng = random.Random(2026)
    bridge(scene)
    library_front(scene, rng)
    road(scene, rng)
    camp_extras(scene, rng)
    graves(scene, rng)
    watchtower(scene, rng)
    siege_works(scene, rng)
    battery(scene, rng)
    standards(scene)
    return scene


# Escalier oublié derrière la dalle : un palier, puis quatre marches qui descendent d'un mètre vers la petite salle
# souterraine où le Projenomicon repose sur un pupitre de pierre (le livre et sa lueur sont dans plaine.tscn).
STAIR_TOP = -36.7
STAIR_BOTTOM = -38.5
CRYPT_FLOOR = -1.0
CRYPT_END = -44.0
LECTERN_Z = -39.8
STONE = (0.3, 0.28, 0.3)
STONE_DARK = (0.2, 0.19, 0.21)


def passage(scene):
    """Passage derrière la dalle : murs posés au niveau de la petite salle, plafond plus bas, marches, rampe invisible
    pour les gravir sans à-coups, et le pupitre de pierre."""
    for z in (-38.0, -42.0):
        wall(scene, "wall", (-2.0, z), (-1, 0), base=CRYPT_FLOOR)
        wall(scene, "wall", (2.0, z), (1, 0), base=CRYPT_FLOOR)
    wall(scene, "wall", (0.0, CRYPT_END), (0, -1), base=CRYPT_FLOOR)
    ceiling = CRYPT_FLOOR + WALL_HEIGHT
    middle = (-36.25 + CRYPT_END - 0.25) / 2
    length = -36.25 - CRYPT_END + 0.25
    scene.add_shape("box", (4.4, 0.3, length), STONE_DARK, (0.0, ceiling + 0.15, middle))
    scene.add_box((0.0, ceiling + 0.15, middle), (4.4, 0.3, length))
    # Marches : chacune descend de 25 cm, la dernière rejoint le sol de la salle.
    rise = -CRYPT_FLOOR / 4
    run = (STAIR_TOP - STAIR_BOTTOM) / 4
    for step in range(3):
        top = -rise * (step + 1)
        front = STAIR_TOP - run * step
        bottom = CRYPT_FLOOR - 0.3
        scene.add_shape("box", (3.5, top - bottom, run), STONE, (0.0, (top + bottom) / 2, front - run / 2))
    floor_start = STAIR_TOP - run * 3
    floor_length = floor_start - CRYPT_END + 0.25
    scene.add_shape("box", (4.4, 0.3, floor_length), STONE, (0.0, CRYPT_FLOOR - 0.15, floor_start - floor_length / 2))
    scene.add_box((0.0, CRYPT_FLOOR - 0.15, floor_start - floor_length / 2), (4.4, 0.3, floor_length))
    # Rampe de collision qui passe par le nez des marches.
    dz, dy = STAIR_TOP - STAIR_BOTTOM, -CRYPT_FLOOR
    slope = math.hypot(dz, dy)
    angle = math.degrees(math.atan2(dy, dz))
    normal = (dz / slope, -dy / slope)
    scene.add_tilted_box((0.0, CRYPT_FLOOR / 2 - normal[0] * 0.15, (STAIR_TOP + STAIR_BOTTOM) / 2 - normal[1] * 0.15),
                         (3.5, 0.3, slope + 0.1), tilt=-angle)
    # Pupitre de pierre, son plateau penché vers celui qui descend l'escalier.
    scene.add_shape("box", (0.9, 0.12, 0.7), STONE_DARK, (0.0, CRYPT_FLOOR + 0.06, LECTERN_Z))
    scene.add_shape("box", (0.55, 0.9, 0.42), STONE, (0.0, CRYPT_FLOOR + 0.57, LECTERN_Z))
    scene.add_shape("box", (0.95, 0.1, 0.72), STONE_DARK, (0.0, CRYPT_FLOOR + 1.04, LECTERN_Z), tilt=15.0)
    scene.add_box((0.0, CRYPT_FLOOR + 0.54, LECTERN_Z), (0.95, 1.08, 0.75))


# Livres à fouiller, nœuds de plaine.tscn : rayonnage (mur, salle, place), tablette et décalage le long du meuble.
# Leur position est imprimée par le script, pour la reporter dans la scène.
SEARCHABLE_BOOKS = {
    "West03": ("west", 0, 0, 1, 0.3),
    "West09": ("west", 0, 2, 2, -0.3),
    "West15": ("west", 1, 0, 1, 0.35),
    "West21": ("west", 1, 2, 2, 0.25),
    "West27": ("west", 2, 0, 2, -0.35),
    "West33": ("west", 2, 2, 1, 0.2),
    "East06": ("east", 0, 1, 1, 0.3),
    "East09": ("east", 0, 2, 2, -0.2),
    "East18": ("east", 1, 1, 1, -0.3),
    "East21": ("east", 1, 2, 2, 0.3),
    "East30": ("east", 2, 1, 2, -0.3),
    "East33": ("east", 2, 2, 1, 0.25),
}


# Brèche de la voûte de la salle de lecture : centre du trou (x, z), comme le nœud Interior/Breach de plaine.tscn
# (library_breach.gd perce le plafond et fait tomber le rai de lumière). Entre deux poutres (z = -7,5 et -10,5), au-dessus
# des gravats bas déjà posés.
BREACH = (-0.2, -9.2)
CHARRED = (0.09, 0.07, 0.06)


def breach_rubble(scene):
    """Sous la brèche : la pierre de catapulte qui a crevé la voûte, les éclats tombés avec elle et une solive calcinée,
    couchée à plat contre la pierre. Posés après tout le reste : les noms et les places du décor existant ne bougent
    pas. Entre la pierre et le rayonnage du mur du fond, le passage garde 1,2 m (sonde de saut : une solive penchée de
    la pierre au sol y fermait une poche où l'on restait coincé)."""
    x, z = BREACH
    # La pierre, comme les boulets des engins de siège ; 48 cm de haut, avec sa collision.
    furniture_fit(scene, "survival_kit/resource-stone-large", (x + 0.35, 0.0, z - 0.1), 25.0, 3.0, height=0.48)
    # Éclats de la pierre et moellons de la voûte, de part et d'autre (les tas de rochers des kits, trop sombres sous
    # la suie, y faisaient des tas de charbon).
    furniture_fit(scene, "survival_kit/resource-stone-large", (x + 1.15, 0.0, z + 0.55), 70.0, 1.8, height=0.3,
                  tilt=8.0)
    furniture_fit(scene, "survival_kit/resource-stone-large", (x - 0.65, 0.0, z - 0.85), 200.0, 1.5, height=0.26,
                  roll=-10.0)
    furniture_fit(scene, "survival_kit/resource-stone-large", (x + 1.0, 0.0, z - 1.0), 130.0, 1.1)
    # Solive calcinée, à plat contre la pierre : 20 cm de haut, on l'enjambe, sans collision.
    scene.add_shape("box", (0.22, 0.2, 1.7), CHARRED, (x + 1.55, 0.1, z - 0.55), 72.0)


def build_interior():
    """Intérieur sous la carte : trois salles en enfilade (lecture, scriptorium, archives) et une alcôve fermée par une
    pierre. Les rayonnages tournent leur face vers la pièce et portent leurs livres."""
    scene = PlaineScene("LibraryInterior")
    rng = random.Random(1789)
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
                arch_fill(scene, (x, z), (0, -1))
            else:
                wall(scene, "wall", (x, z), (0, -1))

    # Mur du fond : la grande dalle (plaine.tscn) ferme son passage, qui mène à l'escalier oublié.
    wall(scene, "wall", (-4.0, end), (0, -1))
    wall(scene, "wall", (4.0, end), (0, -1))
    doorway(scene, (0.0, end), (0, -1))
    arch_fill(scene, (0.0, end), (0, -1))
    passage(scene)

    # Sol des trois salles, jusqu'au palier derrière la dalle, et plafond.
    floor_end = STAIR_TOP
    scene.add_box((0.0, -0.25, (0.5 + floor_end) / 2), (half_width * 2 + 1, 0.5, 0.5 - floor_end))
    scene.add_box((0.0, WALL_HEIGHT + 0.25, (end - 4.0) / 2), (half_width * 2 + 1, 0.5, -end + 5.0))

    # Poutres du plafond, d'un mur à l'autre.
    for index in range(13):
        scene.add_many_shape("box", (half_width * 2 - 0.5, 0.32, 0.34), WOOD_DARK,
                             (0.0, WALL_HEIGHT - 0.16, -1.5 - index * 3.0))

    inner = half_width - WALL_THICKNESS / 2
    wide = "furniture_kit/bookcaseClosedWide"
    searched = {}

    # Rayonnages des murs latéraux : trois par salle et par côté, centrés sur leur emplacement.
    slots = (-2.5, -6.0, -9.5)
    for side, inward, x in (("west", (1, 0), -inner), ("east", (-1, 0), inner)):
        for room in range(rooms):
            for place, offset in enumerate(slots):
                z = -room_length * room + offset
                # Des rayonnages ont basculé en avant : ils gisent au sol, leurs livres répandus devant eux.
                # Le rayonnage tombé du scriptorium (mur de travers) occupe la place du premier rayonnage est.
                if (side, room, place) == ("east", 1, 0):
                    continue
                if (side, room, place) in (("west", 2, 1), ("east", 0, 0)):
                    sign = inward[0]
                    furniture_fit(scene, wide, (x + sign * 1.35, 0.0, z), facing(inward), SHELF_SCALE, height=0.8,
                              tilt=90.0)
                    floor_books(scene, rng, x + sign * 3.0, z + 0.4, 10, 1.0)
                    sheets(scene, rng, x + sign * 3.2, z, 10, 1.3, scrolls=3)
                    continue
                gaps = [(shelf, along) for name, (wall_side, r, p, shelf, along) in SEARCHABLE_BOOKS.items()
                        if wall_side == side and r == room and p == place]
                names = [name for name, (wall_side, r, p, shelf, along) in SEARCHABLE_BOOKS.items()
                         if wall_side == side and r == room and p == place]
                found = []
                bookcase(scene, rng, wide, (x, z), inward, fill=rng.uniform(0.7, 0.92), gaps=gaps, searched=found)
                for name, slot in zip(names, found):
                    searched[name] = slot
            # Entre deux rayonnages, un chandelier de fer sur pied.
            for between in (-4.25, -7.75):
                candle_stand(scene, x + inward[0] * 0.4, -room_length * room + between)

    # Rayonnages des murs de travers, de part et d'autre des passages.
    for x, z, inward in ((3.2, -0.25, (0, -1)), (-3.2, -0.25, (0, -1)),
                         (1.45, -11.75, (0, 1)), (4.35, -11.75, (0, 1)),
                         (1.45, -12.25, (0, -1)), (4.35, -12.25, (0, -1)),
                         (-1.45, -23.75, (0, 1)), (-4.35, -23.75, (0, 1)),
                         (-1.45, -24.25, (0, -1)), (-4.35, -24.25, (0, -1))):
        # Le rayonnage du scriptorium près du passage est tombé en avant, ses livres répandus devant lui.
        if (x, z) == (4.35, -12.25):
            furniture_fit(scene, wide, (x, 0.0, z - 1.35), 180.0, SHELF_SCALE, height=0.8, tilt=90.0)
            floor_books(scene, rng, x - 0.6, z - 3.0, 8, 0.9)
            sheets(scene, rng, x - 0.8, z - 3.2, 6, 1.0, scrolls=2)
            continue
        bookcase(scene, rng, wide, (x, z), inward, fill=rng.uniform(0.6, 0.9))

    # Salle de lecture : longue table, pupitres, lustre.
    reading_table(scene, rng, 1.8, -6.2, 90.0, chairs=((-1, -0.5), (-1, 0.5), (1, -0.45)), tipped=(2,))
    lectern(scene, -2.4, -6.8, 60.0)
    lectern(scene, 3.4, -10.0, 200.0, open_book=False)
    chandelier(scene, 1.8, -6.2)
    scene.add("furniture_kit/rugRectangle", (-1.7, 0.01, -2.0), 0.0, 3.0)
    floor_books(scene, rng, -1.2, -9.5, 4, 0.6)
    floor_books(scene, rng, 0.2, -3.6, 3, 0.8)
    sheets(scene, rng, 0.0, -4.0, 10, 2.4, scrolls=3)
    # Gravats bas, qu'on enjambe : pas de collision, plutôt qu'une boîte plus haute que le tas.
    furniture_fit(scene, "graveyard_kit/debris", (-0.6, 0.0, -9.0), 30.0, 1.4)

    # Scriptorium : pupitres de scribes, l'un renversé, la carte du royaume au mur.
    writing_desk(scene, rng, 1.9, -15.6, 180.0)
    writing_desk(scene, rng, -2.7, -20.0, 0.0)
    writing_desk(scene, rng, -3.3, -17.0, 20.0, overturned=True)
    lectern(scene, 3.6, -16.9, -100.0)
    chandelier(scene, 0.0, -18.0)
    wall_map(scene, -1.45, -12.25, (0, -1), y=2.95, width=1.5, height=0.9)
    sheets(scene, rng, 0.5, -17.5, 14, 2.6, scrolls=4)
    floor_books(scene, rng, -0.6, -21.0, 4, 0.9)
    furniture_fit(scene, "graveyard_kit/debris-wood", (-0.8, 0.0, -21.8), 80.0, 2.4)

    # Archives : coffres et caisses d'archives, un lustre tombé, des registres répandus autour de la tablette.
    for position, model, degrees, scale, height in (
        ((-4.3, -26.3), "mini_dungeon/chest", 80.0, 2.0, 0.9),
        ((-3.9, -33.8), "mini_dungeon/chest", 100.0, 2.0, 0.9),
        ((-1.0, -26.4), "survival_kit/box-large-open", 10.0, 3.0, 0.9),
        ((-2.2, -26.0), "survival_kit/box-open", 35.0, 3.0, 0.9),
    ):
        furniture_fit(scene, model, (position[0], 0.0, position[1]), degrees, scale, height=height)
    # Lustre tombé à l'écart des livres répandus par le rayonnage renversé du mur ouest : ils passaient à travers
    # son anneau.
    fallen_chandelier(scene, 2.7, -29.6)
    floor_books(scene, rng, 1.6, -27.0, 5, 0.8)
    sheets(scene, rng, -0.5, -30.0, 14, 2.4)
    chandelier(scene, 1.0, -31.5, drop=0.8)

    # Petite salle du livre : bannières de Codia et bougies autour du pupitre de pierre.
    for side in (-1, 1):
        wall_banner(scene, side * 1.75, -41.6, (-side, 0), y=CRYPT_FLOOR + 1.3)
        furniture_fit(scene, "graveyard_kit/candle-multiple", (side * 1.2, CRYPT_FLOOR, -43.2), side * 30.0, 2.2,
                  height=0.45)
        # Les urnes au fond, sous les bannières : au pied de l'escalier, elles fermaient les deux côtés du pupitre.
        furniture_fit(scene, "graveyard_kit/urn-round", (side * 1.35, CRYPT_FLOOR, -42.3), 0.0, 2.4, height=0.9)

    breach_rubble(scene)

    for name in sorted(searched):
        (x, y, z), inward = searched[name]
        print(f"  {name}: ({x:.3f}, {y:.3f}, {z:.3f}) vers {inward}")
    return scene


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, scene in (("plaine_ruins", build_ruins()), ("plaine_battlefield", build_battlefield()),
                        ("library_interior", build_interior())):
        (OUTPUT_DIR / f"{name}.tscn").write_text(scene.text(), encoding="utf-8", newline="\n")
        print(f"{name}.tscn : {len(scene.visuals)} modèles, {len(scene.colliders)} collisions")


if __name__ == "__main__":
    main()
