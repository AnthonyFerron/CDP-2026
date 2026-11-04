"""Génère les objets fixes des marais de Kernel Swamp : le campement du gardien, le cimetière, la crypte et son
réseau souterrain, le village englouti de Brumeval, la chapelle en ruine, les pierres levées et les arbres morts.

Trois scènes sont écrites dans scenes/levels/marais/ :
- marais_props.tscn : les objets posés à une hauteur connue (replats des îlots, eaux du village englouti) ;
- marais_grounded.tscn : les objets des berges, que MaraisScatter descend au sol maillé à l'exécution ;
- marais_crypt.tscn : la crypte souterraine.

Les scènes produites s'ouvrent et se modifient dans Godot, mais le script les écrase :
pour un changement durable, modifier ce script puis le relancer depuis le dossier frontend :

    python tools/build_marais.py
"""

import math
import random
from pathlib import Path

from build_plaine import (
    KENNEY,
    MODEL_BOXES,
    WALL_HEIGHT,
    WALL_THICKNESS,
    Scene,
    multiply,
    rotation_x,
    rotation_y,
    rotation_z,
    transform_text,
    wall,
)

# Boîtes englobantes (coin, taille) à l'échelle 1 des modèles posés ici, mesurées dans Godot.
MODEL_BOXES.update({
    "survival_kit/tent-canvas": ((-0.28, 0.0, -0.28), (0.56, 0.49, 0.56)),
    "survival_kit/bucket": ((-0.07, 0.0, -0.07), (0.14, 0.19, 0.14)),
    "survival_kit/campfire-pit": ((-0.14, 0.0, -0.13), (0.28, 0.09, 0.27)),
    "survival_kit/campfire-fishing-stand": ((-0.2, 0.0, -0.13), (0.39, 0.28, 0.25)),
    "survival_kit/barrel-open": ((-0.12, 0.0, -0.12), (0.24, 0.34, 0.24)),
    "survival_kit/box-open": ((-0.13, 0.0, -0.13), (0.25, 0.31, 0.25)),
    "survival_kit/fish-large": ((-0.15, 0.0, -0.05), (0.31, 0.16, 0.1)),
    "survival_kit/resource-wood": ((-0.1, 0.0, -0.04), (0.21, 0.06, 0.09)),
    "graveyard_kit/crypt-large": ((-0.93, 0.0, -1.2), (1.85, 1.0, 2.4)),
    "graveyard_kit/pillar-obelisk": ((-0.17, 0.0, -0.17), (0.35, 1.01, 0.35)),
    "graveyard_kit/stone-wall": ((-0.5, 0.0, -0.5), (1.0, 0.73, 0.2)),
    "graveyard_kit/stone-wall-damaged": ((-0.5, 0.0, -0.5), (1.0, 0.73, 0.2)),
    "graveyard_kit/pine": ((-0.59, -0.1, -0.67), (1.18, 2.3, 1.33)),
    "graveyard_kit/pine-crooked": ((-0.57, -0.1, -0.67), (1.18, 2.11, 1.33)),
    "graveyard_kit/iron-fence": ((-0.5, 0.0, -0.38), (1.0, 0.88, 0.11)),
    "graveyard_kit/iron-fence-damaged": ((-0.5, 0.0, -0.38), (1.0, 0.88, 0.32)),
    "graveyard_kit/gravestone-wide": ((-0.43, 0.0, -0.15), (0.85, 0.57, 0.3)),
    "graveyard_kit/gravestone-broken": ((-0.22, 0.0, -0.13), (0.51, 0.34, 0.39)),
    "graveyard_kit/gravestone-bevel": ((-0.22, 0.0, -0.13), (0.45, 0.53, 0.25)),
    "graveyard_kit/gravestone-decorative": ((-0.26, 0.0, -0.13), (0.51, 0.59, 0.25)),
    "graveyard_kit/gravestone-roof": ((-0.24, 0.0, -0.13), (0.49, 0.61, 0.25)),
    "graveyard_kit/gravestone-cross-large": ((-0.22, 0.0, -0.12), (0.45, 0.94, 0.33)),
    "graveyard_kit/gravestone-debris": ((-0.27, -0.05, -0.52), (0.5, 0.27, 0.64)),
    "graveyard_kit/grave": ((-0.38, 0.0, -0.61), (0.72, 0.11, 1.24)),
    "graveyard_kit/grave-border": ((-0.4, 0.0, -0.73), (0.76, 0.11, 1.39)),
    "graveyard_kit/bench-damaged": ((-0.48, 0.0, -0.23), (0.91, 0.52, 0.46)),
    "graveyard_kit/coffin-old": ((-0.29, 0.0, -0.42), (0.57, 0.2, 0.84)),
    "graveyard_kit/coffin": ((-0.29, 0.0, -0.42), (0.57, 0.2, 0.84)),
    "graveyard_kit/urn-round": ((-0.13, 0.0, -0.13), (0.26, 0.28, 0.26)),
    "graveyard_kit/urn-square": ((-0.13, 0.0, -0.13), (0.26, 0.28, 0.26)),
    "graveyard_kit/candle": ((-0.07, 0.0, -0.07), (0.14, 0.2, 0.14)),
    "graveyard_kit/trunk-long": ((-0.27, 0.0, -0.27), (0.54, 1.0, 0.54)),
    "graveyard_kit/trunk": ((-0.27, 0.0, -0.27), (0.54, 0.45, 0.55)),
    "graveyard_kit/rocks-tall": ((-0.51, 0.0, -0.56), (1.03, 0.59, 1.02)),
    "graveyard_kit/rocks": ((-0.44, 0.0, -0.43), (1.08, 0.38, 0.96)),
    "graveyard_kit/character-skeleton": ((-0.26, -0.2, -0.15), (0.51, 0.48, 0.32)),
    "graveyard_kit/pillar-small": ((-0.09, 0.0, -0.09), (0.18, 0.76, 0.18)),
    "graveyard_kit/pillar-square": ((-0.17, 0.0, -0.17), (0.35, 1.15, 0.35)),
    "graveyard_kit/cross-column": ((-0.22, 0.0, -0.22), (0.45, 1.45, 0.45)),
    "graveyard_kit/cross-wood": ((-0.22, 0.0, -0.22), (0.43, 1.04, 0.43)),
    "graveyard_kit/debris": ((-0.29, 0.0, -0.31), (0.54, 0.16, 0.55)),
    "graveyard_kit/debris-wood": ((-0.23, 0.0, -0.25), (0.46, 0.1, 0.5)),
    "graveyard_kit/detail-chalice": ((-0.08, 0.0, -0.08), (0.16, 0.25, 0.16)),
    "graveyard_kit/shovel": ((-0.1, 0.0, -0.05), (0.19, 0.61, 0.1)),
    "graveyard_kit/shovel-dirt": ((-0.3, 0.0, -0.26), (0.62, 0.66, 0.52)),
    "graveyard_kit/crypt-small": ((-0.68, 0.0, -0.7), (1.35, 1.0, 1.4)),
    "graveyard_kit/road": ((-0.4, 0.0, -0.4), (0.8, 0.08, 0.79)),
    "mini_dungeon/banner": ((-0.3, 0.23, -0.53), (0.6, 0.65, 0.1)),
    "mini_dungeon/column": ((-0.25, 0.0, -0.25), (0.5, 1.1, 0.5)),
    "mini_dungeon/weapon-sword": ((-0.12, -0.1, -0.05), (0.23, 0.45, 0.11)),
    "mini_dungeon/pot": ((-0.3, 0.0, -0.2), (0.6, 0.43, 0.41)),
    "mini_dungeon/stones": ((-0.45, 0.0, -0.4), (0.89, 0.45, 0.8)),
    "mini_arena/statue": ((-0.35, 0.0, -0.35), (0.7, 1.34, 0.7)),
    "castle_kit/flag-banner-long": ((0.0, 0.0, -0.31), (0.04, 2.17, 0.63)),
    "fantasy_town_kit/roof-gable": ((-0.55, 0.0, -0.54), (1.1, 0.57, 1.07)),
    "fantasy_town_kit/roof-high-gable": ((-0.55, -0.04, -0.57), (1.1, 1.16, 1.13)),
    "fantasy_town_kit/roof-point": ((-0.55, 0.0, -0.55), (1.1, 0.5, 1.1)),
    "fantasy_town_kit/chimney": ((0.21, 0.0, -0.17), (0.21, 1.0, 0.34)),
    "fantasy_town_kit/chimney-top": ((0.21, 0.0, -0.17), (0.25, 0.63, 0.34)),
    "fantasy_town_kit/watermill": ((-0.43, -0.9, -0.9), (0.85, 1.8, 1.8)),
    "fantasy_town_kit/fence-broken": ((0.25, 0.0, -0.5), (0.25, 0.38, 1.0)),
    "fantasy_town_kit/lantern": ((-0.11, 0.0, -0.11), (0.22, 1.56, 0.22)),
    "fantasy_town_kit/rock-large": ((-0.87, 0.0, -0.72), (1.67, 1.16, 1.55)),
    "nature_kit/canoe": ((-0.15, 0.0, -0.57), (0.3, 0.18, 1.15)),
    "nature_kit/canoe_paddle": ((-0.04, 0.0, -0.33), (0.08, 0.04, 0.59)),
    "nature_kit/stump_old": ((-0.16, 0.0, -0.19), (0.36, 0.27, 0.37)),
    "nature_kit/stump_oldTall": ((-0.16, 0.0, -0.19), (0.36, 0.67, 0.37)),
    "nature_kit/log_large": ((-0.5, 0.0, -0.25), (1.0, 0.42, 0.55)),
    "nature_kit/hanging_moss": ((-0.08, 0.0, 0.47), (0.16, 0.48, 0.03)),
    "nature_kit/stone_tallA": ((-0.49, 0.0, -0.34), (0.98, 1.0, 0.68)),
    "nature_kit/stone_tallB": ((-0.38, 0.0, -0.39), (0.76, 0.88, 0.77)),
    "nature_kit/stone_tallC": ((-0.23, 0.0, -0.22), (0.46, 0.78, 0.44)),
    "nature_kit/stone_tallD": ((-0.22, 0.0, -0.23), (0.44, 0.77, 0.46)),
    "nature_kit/stone_tallG": ((-0.21, 0.0, -0.25), (0.42, 0.78, 0.49)),
    "nature_kit/path_wood": ((-0.5, 0.0, -0.26), (1.0, 0.05, 0.51)),
    "nature_kit/path_stone": ((-0.5, 0.0, -0.3), (1.0, 0.05, 0.58)),
    "nature_kit/plant_bushLarge": ((-0.19, 0.0, -0.17), (0.37, 0.24, 0.34)),
    "nature_kit/plant_bushDetailed": ((-0.3, 0.0, -0.3), (0.6, 0.36, 0.6)),
    "nature_kit/grass_large": ((-0.2, 0.0, -0.21), (0.41, 0.25, 0.41)),
    "nature_kit/plant_flatTall": ((-0.14, 0.0, -0.14), (0.27, 0.28, 0.27)),
    "nature_kit/mushroom_redTall": ((-0.06, 0.0, -0.07), (0.12, 0.25, 0.14)),
    "nature_kit/mushroom_tanGroup": ((-0.14, 0.0, -0.11), (0.27, 0.25, 0.25)),
    "nature_kit/flower_redA": ((-0.1, 0.0, -0.09), (0.16, 0.29, 0.18)),
    "nature_kit/flower_purpleA": ((-0.1, 0.0, -0.09), (0.16, 0.24, 0.18)),
    "nature_kit/flower_yellowA": ((-0.1, 0.0, -0.09), (0.16, 0.19, 0.18)),
    "modular_dungeon_kit/stairs": ((-2.2, 0.0, -6.2), (4.4, 8.55, 8.4)),
})

FOLDER = Path(__file__).resolve().parent.parent / "scenes" / "levels" / "marais"
OUTPUT = FOLDER / "marais_props.tscn"
GROUNDED_OUTPUT = FOLDER / "marais_grounded.tscn"
CRYPT_OUTPUT = FOLDER / "marais_crypt.tscn"
# Hauteur du dessus des îlots du parcours et des îlots du décor, fixée dans MaraisTerrain.ISLANDS.
GROUND = 0.4
LOW_GROUND = 0.3

GRAVESTONES = (
    "gravestone-round",
    "gravestone-cross",
    "gravestone-wide",
    "gravestone-broken",
    "gravestone-bevel",
    "gravestone-decorative",
    "gravestone-roof",
)


def basis_of(degrees, tilt=0.0, roll=0.0):
    return multiply(multiply(rotation_y(degrees), rotation_x(tilt)), rotation_z(roll))


def bounds(model, degrees=0.0, scale=1.0, tilt=0.0, roll=0.0):
    """Coins bas et haut de la boîte du modèle, tournée et mise à l'échelle, autour de son origine."""
    (px, py, pz), (sx, sy, sz) = MODEL_BOXES[model]
    axes = scale if isinstance(scale, tuple) else (scale, scale, scale)
    basis = basis_of(degrees, tilt, roll)
    corners = []
    for cx in (px, px + sx):
        for cy in (py, py + sy):
            for cz in (pz, pz + sz):
                local = (cx * axes[0], cy * axes[1], cz * axes[2])
                corners.append([sum(basis[r][i] * local[i] for i in range(3)) for r in range(3)])
    low = [min(c[i] for c in corners) for i in range(3)]
    high = [max(c[i] for c in corners) for i in range(3)]
    return low, high


class MarshScene(Scene):
    """Scène de modèles et de collisions, avec la mousse ou la poussière en option et des boîtes inclinées."""

    def add(self, model, position, degrees=0.0, scale=1.0, tilt=0.0, roll=0.0, coat=None):
        super().add(model, position, degrees, scale, tilt, roll)
        if coat:
            name, path, transform = self.visuals[-1]
            self.visuals[-1] = (f"{coat}_{name}", path, transform)

    def add_box(self, center, size, degrees=0.0, tilt=0.0, roll=0.0):
        self.colliders.append((transform_text(basis_of(degrees, tilt, roll), center), self._box_id(size)))

    def place(self, model, center, degrees=0.0, scale=1.0, tilt=0.0, roll=0.0, height=None, coat=None):
        """Pose le modèle centré sur (x, z), son point le plus bas à la hauteur donnée. Avec height, une collision
        de la taille de la boîte tournée (ou True pour toute sa hauteur)."""
        low, high = bounds(model, degrees, scale, tilt, roll)
        x = center[0] - (low[0] + high[0]) / 2
        z = center[2] - (low[2] + high[2]) / 2
        self.add(model, (x, center[1] - low[1], z), degrees, scale, tilt, roll, coat)
        if height:
            full = high[1] - low[1]
            h = full if height is True else min(height, full)
            if round(degrees) % 90 and not tilt and not roll:
                (_, _, _), (sx, _, sz) = MODEL_BOXES[model]
                axes = scale if isinstance(scale, tuple) else (scale, scale, scale)
                self.add_box((center[0], center[1] + h / 2, center[2]), (sx * axes[0], h, sz * axes[2]), degrees)
            else:
                self.add_box((center[0], center[1] + h / 2, center[2]), (high[0] - low[0], h, high[2] - low[2]))
        return low, high


class GroundItem:
    """Un objet de berge : ses modèles et ses boîtes, en coordonnées relatives à son pied."""

    def __init__(self, x, z, footprint, sink):
        self.x, self.z = x, z
        self.footprint = footprint
        self.sink = sink
        self.parts = []
        self.boxes = []

    def place(self, model, offset=(0.0, 0.0, 0.0), degrees=0.0, scale=1.0, tilt=0.0, roll=0.0, height=None, coat=None):
        low, high = bounds(model, degrees, scale, tilt, roll)
        x = offset[0] - (low[0] + high[0]) / 2
        z = offset[2] - (low[2] + high[2]) / 2
        self.parts.append((model, (x, offset[1] - low[1], z), degrees, scale, tilt, roll, coat))
        if height:
            full = high[1] - low[1]
            h = full if height is True else min(height, full)
            if round(degrees) % 90 and not tilt and not roll:
                (_, _, _), (sx, _, sz) = MODEL_BOXES[model]
                axes = scale if isinstance(scale, tuple) else (scale, scale, scale)
                self.box((offset[0], offset[1] + h / 2, offset[2]), (sx * axes[0], h, sz * axes[2]), degrees)
            else:
                self.box((offset[0], offset[1] + h / 2, offset[2]), (high[0] - low[0], h, high[2] - low[2]))
        return low, high

    def raw(self, model, origin, degrees=0.0, scale=1.0, tilt=0.0, roll=0.0, coat=None):
        """Pose le modèle par son origine, sans le recentrer."""
        self.parts.append((model, origin, degrees, scale, tilt, roll, coat))

    def box(self, center, size, degrees=0.0, tilt=0.0, roll=0.0):
        self.boxes.append((center, size, degrees, tilt, roll))


class GroundScene:
    """Scène des objets de berge : chaque objet est un nœud que MaraisScatter descend au sol maillé, au point le plus
    bas de son emprise (métadonnée footprint), avec ses modèles et sa collision."""

    def __init__(self, root_name):
        self.root_name = root_name
        self.items = []
        self.models = {}
        self.boxes = {}

    def item(self, x, z, footprint=0.5, sink=0.05):
        item = GroundItem(x, z, footprint, sink)
        self.items.append(item)
        return item

    def text(self):
        lines = ["[gd_scene format=3]", ""]
        for item in self.items:
            for part in item.parts:
                self.models.setdefault(part[0], f"{len(self.models) + 1}_model")
            for _, size, *_ in item.boxes:
                key = tuple(round(v, 3) for v in size)
                self.boxes.setdefault(key, f"BoxShape3D_{len(self.boxes) + 1}")
        for model, identifier in self.models.items():
            lines.append(f'[ext_resource type="PackedScene" path="{KENNEY}/{model}.glb" id="{identifier}"]')
        lines.append("")
        for size, identifier in self.boxes.items():
            lines += [f'[sub_resource type="BoxShape3D" id="{identifier}"]', f"size = Vector3({size[0]:g}, {size[1]:g}, {size[2]:g})", ""]
        lines += [f'[node name="{self.root_name}" type="Node3D"]', ""]
        for index, item in enumerate(self.items):
            name = f"Item{index}"
            lines += [
                f'[node name="{name}" type="Node3D" parent="."]',
                f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {item.x:g}, {-item.sink:g}, {item.z:g})",
                f"metadata/footprint = {item.footprint:g}",
                "",
            ]
            for part_index, (model, origin, degrees, scale, tilt, roll, coat) in enumerate(item.parts):
                axes = scale if isinstance(scale, tuple) else (scale, scale, scale)
                basis = basis_of(degrees, tilt, roll)
                basis = [[row[column] * axes[column] for column in range(3)] for row in basis]
                label = model.rsplit("/", 1)[-1].replace("-", "_")
                if coat:
                    label = f"{coat}_{label}"
                lines += [
                    f'[node name="{label}_{part_index}" parent="{name}" instance=ExtResource("{self.models[model]}")]',
                    f"transform = {transform_text(basis, origin)}",
                    "",
                ]
            if item.boxes:
                lines += [f'[node name="Body" type="StaticBody3D" parent="{name}"]', ""]
                for box_index, (center, size, degrees, tilt, roll) in enumerate(item.boxes):
                    key = tuple(round(v, 3) for v in size)
                    lines += [
                        f'[node name="Shape{box_index}" type="CollisionShape3D" parent="{name}/Body"]',
                        f"transform = {transform_text(basis_of(degrees, tilt, roll), center)}",
                        f'shape = SubResource("{self.boxes[key]}")',
                        "",
                    ]
        return "\n".join(lines)


def dead_tree(ground, rng, x, z, height=4.5, lean=8.0, roots=5, branches=3, girth=1.6):
    """Arbre mort aux formes tordues : un tronc nu penché, des branches cassées et des racines qui plongent dans la vase."""
    item = ground.item(x, z, footprint=0.9, sink=0.25)
    heading = rng.uniform(0, 360)
    item.raw("graveyard_kit/trunk-long", (0.0, 0.0, 0.0), heading, (girth, height, girth), tilt=lean, coat="moss")
    # Axe du tronc penché : sa direction, pour accrocher les branches à la bonne place.
    axis = [sum(basis_of(heading, lean)[r][i] * (0.0, 1.0, 0.0)[i] for i in range(3)) for r in range(3)]
    for index in range(branches):
        along = height * rng.uniform(0.55, 0.92)
        base = (axis[0] * along, axis[1] * along, axis[2] * along)
        yaw = heading + 140.0 * index + rng.uniform(-30, 30)
        length = rng.uniform(1.3, 2.4) * height / 4.5
        item.raw("graveyard_kit/trunk-long", base, yaw, (girth * 0.32, length, girth * 0.32), tilt=rng.uniform(38, 72))
    for index in range(roots):
        yaw = heading + 360.0 / roots * index + rng.uniform(-18, 18)
        start = rng.uniform(0.45, 0.8)
        item.raw("graveyard_kit/trunk-long", (0.0, start, 0.0), yaw, (girth * 0.3, start / 0.42 + 0.2, girth * 0.3),
                 tilt=rng.uniform(112, 122), coat="moss")
    # Collision du tronc, penchée avec lui, un peu plus haute pour envelopper le départ des branches.
    width = 0.54 * girth
    reach = height + 1.2
    item.box((axis[0] * reach / 2, axis[1] * reach / 2, axis[2] * reach / 2), (width, reach, width), heading, lean)
    return item


def build_hut(scene):
    """Campement du gardien, sur l'îlot de l'ouest : sa tente, le feu et son grill à poissons, ses provisions.
    Le passage entre les deux pontons, du nord-ouest au sud-est de l'îlot, reste libre."""
    scene.add("survival_kit/tent-canvas", (-22.5, GROUND, 24.5), 30.0, 4.5)
    scene.add_box((-22.5, 1.1, 24.5), (2.4, 2.2, 2.4), 30.0)
    scene.add("survival_kit/campfire-pit", (-18.0, GROUND, 21.0), 0.0, 5.0)
    scene.place("survival_kit/campfire-fishing-stand", (-18.0, GROUND, 21.0), 70.0, 3.4, height=True)
    for model, position, degrees, scale, height in (
        ("mini_dungeon/barrel", (-24.2, GROUND, 20.6), 15.0, 2.0, True),
        ("survival_kit/bucket", (-23.2, GROUND, 19.6), 15.0, 4.0, True),
        # La table du gardien, où son journal est resté ouvert.
        ("mini_dungeon/table", (-19.8, GROUND, 25.9), 25.0, 2.2, True),
        ("mini_dungeon/chest", (-25.0, GROUND, 22.8), 15.0, 1.8, True),
        ("survival_kit/bedroll", (-21.2, GROUND, 22.2), 30.0, 3.5, None),
        ("nature_kit/log_stack", (-21.2, GROUND, 18.4), 100.0, 2.6, True),
        ("mini_dungeon/barrel", (-24.9, GROUND, 24.8), 40.0, 1.6, True),
    ):
        scene.place(model, position, degrees, scale, height=height)
    # Lanterne sur le coffre, pelle plantée contre la tente, bois coupé près du feu.
    scene.place("graveyard_kit/lantern-candle", (-25.0, GROUND + 0.54, 22.8), 20.0, 2.0)
    scene.place("graveyard_kit/shovel", (-24.0, GROUND, 26.4), 60.0, 3.0, tilt=10.0, height=True)
    scene.place("survival_kit/resource-wood", (-19.8, GROUND, 19.8), 35.0, 4.0)


def build_cemetery(scene, ground, rng):
    """Cimetière clos de grilles, sur le grand îlot de l'est, ouvert à l'ouest face au ponton et au nord-ouest vers
    le ponton de la crypte. Une allée dallée mène de la grille à la tombe du gardien ; les stèles la regardent."""
    west, east, south, north = 7.0, 25.0, 9.0, -9.0
    for index in range(6):
        z = north + 1.5 + index * 3.0
        x = west + 1.5 + index * 3.0
        model = "graveyard_kit/iron-fence-damaged" if index in (1, 4) else "graveyard_kit/iron-fence"
        # Les grilles des coins descendent au sol : les berges y commencent.
        if index not in (3, 4):
            ground.item(west, z, footprint=1.5, sink=0.05).place(model, (0.0, 0.0, 0.0), 90.0, 3.0, height=2.6)
        ground.item(east, z, footprint=1.5, sink=0.05).place(model, (0.0, 0.0, 0.0), -90.0, 3.0, height=2.6)
        if index != 0:
            ground.item(x, north, footprint=1.5, sink=0.05).place("graveyard_kit/iron-fence", (0.0, 0.0, 0.0), 180.0, 3.0, height=2.6)
        ground.item(x, south, footprint=1.5, sink=0.05).place("graveyard_kit/iron-fence", (0.0, 0.0, 0.0), 0.0, 3.0, height=2.6)
    for z in (-0.3, 6.3):
        scene.place("graveyard_kit/lightpost-single", (west, GROUND, z), 90.0, 3.0, height=3.8)

    # Rangées de tombes : au nord de l'allée, les stèles regardent le sud ; au sud, le nord. La tombe est devant.
    stones = []
    for z, facing in ((-6.5, 0.0), (-3.0, 0.0), (6.5, 180.0)):
        for x in (10.5, 13.5, 16.5, 19.5):
            if (x, z) == (10.5, 6.5):
                continue
            model = "graveyard_kit/" + rng.choice(GRAVESTONES)
            stones.append((x, z, facing))
            scene.place(model, (x, GROUND, z), facing + rng.uniform(-6, 6), 2.6, height=True, coat="moss" if rng.random() < 0.4 else None)
            front = 1.64 if facing == 0.0 else -1.64
            if (x, z) != (19.5, 6.5):
                scene.place("graveyard_kit/grave", (x, GROUND, z + front), facing, 2.0)
    # Bougies et fleurs sur quelques tombes, une tombe fraîchement creusée près de la tombe du gardien.
    for x, z, facing in stones[::3]:
        front = 0.55 if facing == 0.0 else -0.55
        scene.place("graveyard_kit/candle", (x + 0.5, GROUND, z + front), 0.0, 2.5)
    for (x, z, facing), flower in zip(stones[1::3], ("flower_redA", "flower_purpleA", "flower_yellowA", "flower_redA")):
        front = 1.9 if facing == 0.0 else -1.9
        scene.place(f"nature_kit/{flower}", (x - 0.2, GROUND + 0.1, z + front), rng.uniform(0, 360), 2.6)
    scene.place("graveyard_kit/shovel-dirt", (19.6, GROUND, 4.7), 160.0, 2.4, height=True)

    # Tombe d'Ada, usée et moussue ; tombe du gardien au bout de l'allée, plus grande que les autres.
    scene.place("graveyard_kit/gravestone-round", (10.5, GROUND, 6.5), 180.0, 2.8, height=True, coat="moss")
    scene.place("graveyard_kit/grave", (10.5, GROUND, 4.86), 180.0, 2.0)
    scene.add("graveyard_kit/gravestone-cross", (23.0, GROUND, 1.5), -90.0, 3.6)
    scene.add_box((23.0, 1.7 + GROUND, 1.5), (1.0, 3.4, 1.8))
    scene.place("graveyard_kit/grave-border", (20.7, GROUND, 1.5), -90.0, 2.6)
    scene.place("graveyard_kit/grave", (20.7, GROUND, 1.5), -90.0, 2.4)
    scene.add("graveyard_kit/candle-multiple", (21.8, GROUND, 3.2), 0.0, 3.0)
    scene.add("graveyard_kit/candle-multiple", (21.8, GROUND, -0.2), 40.0, 3.0)
    scene.place("graveyard_kit/bench-damaged", (15.0, GROUND, 2.85), 180.0, 3.0, height=1.5)
    # Allée dallée, de la grille à la tombe du gardien.
    for index in range(9):
        scene.place("nature_kit/path_stone", (8.8 + index * 1.45, GROUND, 1.6 + rng.uniform(-0.1, 0.1)), 90.0 + rng.uniform(-5, 5), 2.2)
    # Le caveau d'une vieille famille du marais, dans l'angle nord-est.
    scene.place("graveyard_kit/crypt-small", (22.2, GROUND, -5.3), 180.0, 2.2, height=True, coat="moss")
    for x, z in ((14.0, -9.8), (24.0, 7.5), (24.0, -7.8)):
        scene.add("graveyard_kit/pine-crooked", (x, GROUND, z), rng.uniform(0, 360), 3.5)
        scene.add_box((x, 2.0, z), (0.8, 4.0, 0.8))


def build_crypt(scene, ground, rng):
    """Crypte du gardien, au nord : sa porte regarde le ponton, entre deux obélisques et deux murets. La végétation
    l'a gagnée : mousse pendue au fronton, buissons et herbes hautes au pied, arbres morts tout autour."""
    scene.add("graveyard_kit/crypt-large", (0.0, GROUND, -41.0), 0.0, 4.0, coat="moss")
    scene.add("graveyard_kit/crypt-large-roof", (0.0, GROUND + 4.0, -41.0), 0.0, 4.0, coat="moss")
    scene.add_box((0.0, 3.0, -41.0), (7.6, 6.0, 9.6))
    for x in (-6.0, 6.0):
        scene.place("graveyard_kit/pillar-obelisk", (x, GROUND, -36.5), 0.0, 4.0, height=True, coat="moss")
    # Murets de part et d'autre de la crypte, posés au sol maillé : leur bout nord descend sur la berge.
    for x, z, degrees, model in (
        (-6.6, -39.6, 90.0, "stone-wall"),
        (-6.6, -43.4, 90.0, "stone-wall-damaged"),
        (6.6, -39.6, -90.0, "stone-wall-damaged"),
        (6.6, -43.4, -90.0, "stone-wall"),
    ):
        ground.item(x, z, footprint=2.0, sink=0.1).place(f"graveyard_kit/{model}", (0.0, 0.0, 0.0), degrees, 4.0, height=True, coat="moss")
    for x, z in ((-8.0, -45.5), (8.6, -45.4), (-3.5, -48.0)):
        ground.item(x, z, footprint=0.6, sink=0.1).place("graveyard_kit/pine", (0.0, 0.0, 0.0), rng.uniform(0, 360), 4.0)
        ground.items[-1].box((0.0, 2.0, 0.0), (0.9, 4.0, 0.9))
    # Lanternes sur de petits piliers, de part et d'autre de la porte.
    for x in (-2.3, 2.3):
        scene.place("graveyard_kit/pillar-small", (x, GROUND, -35.55), 0.0, 2.0, height=True)
        scene.place("graveyard_kit/lantern-candle", (x, GROUND + 1.52, -35.55), 0.0, 2.2)
        scene.place("graveyard_kit/candle-multiple", (x * 0.62, GROUND, -35.75), rng.uniform(0, 360), 2.4)
    # Mousse pendue au fronton et aux colonnes, buissons et herbes hautes au pied de la façade.
    for x, y, scale in ((-3.4, 1.3, 5.0), (-2.75, 2.0, 3.6), (2.8, 1.6, 4.4), (3.45, 1.1, 5.4), (-1.6, 3.0, 2.4), (1.5, 2.8, 2.6)):
        scene.add("nature_kit/hanging_moss", (x, GROUND + y, -36.15 - 0.5 * scale), 0.0, scale)
    for x, z, model, scale in (
        (-5.0, -36.6, "plant_bushLarge", 4.2), (4.6, -36.5, "plant_bushDetailed", 3.4), (-3.6, -36.6, "grass_large", 4.0),
        (3.4, -36.6, "plant_flatTall", 4.5), (-7.6, -37.5, "plant_bushLarge", 3.6), (7.4, -37.8, "plant_bushDetailed", 3.0),
        (-1.9, -36.5, "grass_large", 3.0), (1.9, -36.5, "grass_large", 3.2),
    ):
        scene.place(f"nature_kit/{model}", (x, GROUND, z), rng.uniform(0, 360), scale)
    # Un arbre mort tombé contre l'angle gauche de la façade, et sa mousse ; deux buissons devant les angles.
    scene.add("graveyard_kit/trunk-long", (-6.0, GROUND - 0.2, -34.8), 122.2, (1.3, 4.6, 1.3), tilt=40.4, coat="moss")
    scene.add_box((-5.55, 1.0, -35.05), (0.8, 1.4, 0.8), 122.2)
    for x, y, z in ((-4.9, 1.6, -35.6), (-4.2, 2.4, -35.9)):
        scene.add("nature_kit/hanging_moss", (x, GROUND + y, z - 0.48 * 3.0), 30.0, 3.0)
    scene.place("nature_kit/plant_bushLarge", (-3.4, GROUND, -35.3), 40.0, 3.6)
    scene.place("nature_kit/plant_bushDetailed", (3.6, GROUND, -35.2), 10.0, 3.0)
    # Chemin de dalles du ponton à la porte.
    for index in range(6):
        t = index / 5
        scene.place("nature_kit/path_stone", (2.6 - 2.4 * t, GROUND, -29.4 - 5.4 * t), 20.0 + rng.uniform(-8, 8), 2.2)
    # Tombes des anciens gardiens, sur les pelouses de l'îlot, à l'écart du chemin.
    for x, z, model, degrees in ((-6.8, -31.4, "gravestone-cross-large", 15.0), (-8.0, -34.6, "cross-column", 0.0),
                                 (6.9, -30.8, "gravestone-roof", -15.0), (7.8, -33.6, "gravestone-broken", -40.0)):
        scene.place(f"graveyard_kit/{model}", (x, GROUND, z), degrees + 180.0, 2.6, height=True, coat="moss")
    dead_tree(ground, rng, -10.2, -33.0, height=5.0, lean=12.0)
    dead_tree(ground, rng, 9.8, -38.5, height=4.2, lean=-10.0, branches=2)


def build_arrival(scene, ground, rng):
    """Arrivée, au sud : le vieux débarcadère des pêcheurs de Brumeval, une barque amarrée, une autre renversée."""
    start, end = (7.6, 53.2), (14.2, 51.2)
    dx, dz = end[0] - start[0], end[1] - start[1]
    length = math.hypot(dx, dz)
    ux, uz = dx / length, dz / length
    yaw = math.degrees(math.atan2(ux, uz))
    across = (uz, -ux)

    def at(t, side=0.0):
        return (start[0] + ux * t + across[0] * side, start[1] + uz * t + across[1] * side)

    for index in range(7):
        x, z = at(0.4 + index * 1.0)
        scene.place("nature_kit/path_wood", (x, 0.25 + rng.uniform(-0.02, 0.02), z), yaw + 90.0 + rng.uniform(-3, 3), 2.0)
    mid = at(length / 2)
    scene.add_box((mid[0], 0.2, mid[1]), (2.0, 0.3, length + 0.6), yaw)
    for t in (1.5, 3.5, 5.5):
        for side in (-1.05, 1.05):
            x, z = at(t, side)
            scene.add("graveyard_kit/trunk-long", (x, -1.9, z), rng.uniform(0, 360), (0.45, 2.15, 0.45))
            scene.add_box((x, -0.85, z), (0.24, 2.1, 0.24))
    x, z = at(6.7, 1.2)
    scene.add("graveyard_kit/trunk-long", (x, -1.9, z), 0.0, (0.6, 3.0, 0.6))
    scene.add_box((x, -0.4, z), (0.35, 3.0, 0.35))
    x, z = at(5.0, -2.1)
    scene.place("nature_kit/canoe", (x, -0.22, z), yaw + 6.0, 3.5, roll=4.0, coat="moss")
    x, z = at(2.2, 0.4)
    scene.place("nature_kit/canoe_paddle", (x, 0.37, z), yaw + 70.0, 3.0)
    # La lanterne du panneau d'accueil (sa lumière est posée dans marais.tscn).
    scene.place("fantasy_town_kit/lantern", (-5.65, GROUND, 53.6), 0.0, 1.5, height=True)
    ground.item(6.5, 54.6, footprint=0.5).place("mini_dungeon/barrel", degrees=20.0, scale=2.0, height=True)
    ground.item(6.9, 55.9, footprint=0.5).place("survival_kit/chest", degrees=-15.0, scale=3.4, height=True)
    ground.item(-9.2, 60.4, footprint=2.0, sink=0.1).place("nature_kit/canoe", degrees=25.0, scale=3.5, roll=180.0, height=True, coat="moss")
    dead_tree(ground, rng, -10.0, 51.0, height=4.8, lean=14.0)
    dead_tree(ground, rng, 9.6, 61.2, height=3.8, lean=-9.0, branches=2)


def sunken_house(scene, x, z, yaw, size, top, roof, walls, roof_scale=None, chimney=False, roof_tilt=0.0):
    """Maison engloutie : ses murs de bois montent de la vase jusqu'au ras de l'eau, son toit émerge."""
    bottom = -2.2
    for index, model in enumerate(walls):
        scene.add(f"fantasy_town_kit/{model}", (x, bottom, z), yaw + 90.0 * index, (size, top - bottom, size), coat="moss")
    scene.add_box((x, (bottom + top) / 2, z), (size, top - bottom, size), yaw)
    if roof:
        scale = roof_scale or size
        scene.add(f"fantasy_town_kit/{roof}", (x, top, z), yaw, scale, roll=roof_tilt, coat="moss")
        low, high = bounds(f"fantasy_town_kit/{roof}", yaw, scale)
        scene.add_box((x, top + (high[1] - low[1]) * 0.35, z), (size, (high[1] - low[1]) * 0.7, size), yaw)
    if chimney:
        scene.add("fantasy_town_kit/chimney", (x, top, z), yaw + 180.0, size)


def build_village(scene, rng):
    """Brumeval, le village des pêcheurs, englouti quand les digues ont cédé pendant la guerre contre Vibelandia :
    ses toits émergent des eaux de l'est, entre l'arrivée et la dernière maison encore debout."""
    sunken_house(scene, 18.0, 30.0, 10.0, 3.2, 0.25, "roof-gable", ("wall-wood", "wall-wood-window-shutters", "wall-wood", "wall-wood-broken"))
    sunken_house(scene, 25.0, 22.0, -15.0, 3.0, 0.1, "roof-high-gable", ("wall-wood-window-shutters", "wall-wood", "wall-wood-broken", "wall-wood"), chimney=True)
    sunken_house(scene, 29.0, 38.0, 30.0, 2.8, 0.35, "roof-point", ("wall-wood", "wall-wood", "wall-wood-window-shutters", "wall-wood"))
    # Maison effondrée : la cheminée seule sort de l'eau, le toit a glissé à côté.
    sunken_house(scene, 21.5, 40.5, 52.0, 3.0, -0.15, None, ("wall-wood-broken", "wall-wood", "wall-wood-broken", "wall-wood"), chimney=True)
    scene.place("fantasy_town_kit/roof-gable", (23.6, -0.9, 42.3), 70.0, 3.0, roll=24.0, coat="moss")
    # Le moulin et sa roue, couchée à demi dans la vase.
    sunken_house(scene, 11.0, 25.0, -20.0, 3.4, 0.6, "roof-high-gable", ("wall-wood", "wall-wood-window-shutters", "wall-wood", "wall-wood"))
    yaw = math.radians(-20.0)
    offset = 1.7 + 0.43 * 3.0 + 0.15
    scene.add("fantasy_town_kit/watermill", (11.0 + offset * math.cos(yaw), -0.4, 25.0 - offset * math.sin(yaw)), -20.0, 3.0, roll=7.0, coat="moss")
    # Pieux du ponton qui menait à la dernière maison ; deux planches tiennent encore.
    for index, x in enumerate((30.0, 28.5, 27.0, 25.5, 24.0)):
        for side in (-1.0, 1.0):
            top = 0.85 - index * 0.12 + rng.uniform(-0.15, 0.1)
            scene.add("graveyard_kit/trunk-long", (x, -2.0, 31.0 + side), rng.uniform(0, 360), (0.5, top + 2.0, 0.5), tilt=rng.uniform(-6, 6))
            scene.add_box((x, (top - 2.0) / 2, 31.0 + side), (0.27, top + 2.0, 0.27))
        if index in (1, 2):
            scene.place("nature_kit/path_wood", (x, 0.55, 31.0), 90.0 + rng.uniform(-8, 8), 2.2, roll=rng.uniform(-4, 4))
    # Épaves qui flottent : tonneaux, caisses et planches.
    for x, z, model, degrees, roll, bottom, scale in (
        (20.6, 27.4, "mini_dungeon/barrel", 30.0, 90.0, -0.5, 1.9),
        (27.6, 25.8, "mini_dungeon/chest", 10.0, 18.0, -0.4, 1.8),
        (15.2, 33.6, "nature_kit/path_wood", 40.0, 4.0, -0.03, 2.2),
        (31.5, 35.0, "mini_dungeon/barrel", 75.0, 90.0, -0.5, 1.9),
        (23.0, 35.2, "nature_kit/path_wood", 110.0, -3.0, -0.03, 2.0),
        (14.8, 21.6, "survival_kit/chest", 50.0, 12.0, -0.45, 3.4),
    ):
        scene.place(model, (x, bottom, z), degrees, scale, roll=roll, coat="moss")
    scene.place("fantasy_town_kit/fence-broken", (16.4, -0.9, 27.2), 35.0, 2.6, tilt=8.0)
    scene.place("fantasy_town_kit/fence-broken", (26.8, -0.9, 19.6), -50.0, 2.6, roll=10.0)


def build_last_house(scene, ground):
    """La dernière maison de Brumeval, sur son îlot : sa porte regarde le village englouti."""
    x, z, yaw = 36.0, 32.0, 188.0
    walls = ("wall-wood-door", "wall-wood", "wall-wood-window-shutters", "wall-wood")
    for index, model in enumerate(walls):
        scene.add(f"fantasy_town_kit/{model}", (x, LOW_GROUND, z), yaw + 90.0 * index, (3.0, 2.6, 3.0), coat="moss")
    scene.add_box((x, LOW_GROUND + 1.3, z), (3.0, 2.6, 3.0), yaw)
    scene.add("fantasy_town_kit/roof-gable", (x, LOW_GROUND + 2.6, z), yaw, 3.2, coat="moss")
    scene.add("fantasy_town_kit/chimney", (x, LOW_GROUND + 2.6, z), yaw + 180.0, 3.0)
    ground.item(32.4, 33.4, footprint=0.4).place("fantasy_town_kit/lantern", degrees=0.0, scale=1.5, height=True)
    ground.item(39.6, 29.2, footprint=2.0, sink=0.1).place("nature_kit/canoe", degrees=120.0, scale=3.5, tilt=5.0, height=0.6, coat="moss")
    ground.item(34.0, 34.6, footprint=0.5).place("mini_dungeon/barrel", degrees=0.0, scale=2.0, height=True)
    ground.item(38.4, 34.6, footprint=0.6).place("survival_kit/campfire-fishing-stand", degrees=20.0, scale=3.0, height=True)


def build_landing(scene, ground, rng):
    """Le vieux débarcadère du sud-ouest : barques tirées sur la berge, ponton effondré, feu froid et grill à poissons."""
    ground.item(-36.2, 43.6, footprint=2.0, sink=0.1).place("nature_kit/canoe", degrees=35.0, scale=3.6, tilt=6.0, height=0.6, coat="moss")
    ground.item(-43.6, 36.6, footprint=2.0, sink=0.1).place("nature_kit/canoe", degrees=-25.0, scale=3.4, roll=180.0, height=0.6, coat="moss")
    ground.item(-41.0, 41.5, footprint=0.6).place("nature_kit/campfire_stones", degrees=0.0, scale=3.0)
    ground.items[-1].place("survival_kit/campfire-fishing-stand", (0.0, 0.0, 0.0), 40.0, 3.0, height=True)
    ground.item(-38.4, 37.8, footprint=0.5).place("mini_dungeon/barrel", degrees=0.0, scale=2.0, height=True)
    ground.item(-39.3, 37.0, footprint=0.5).place("survival_kit/chest", degrees=25.0, scale=3.6, height=True)
    for index, (x, z) in enumerate(((-35.6, 45.0), (-34.4, 46.2), (-33.2, 47.4))):
        for side in (-1.0, 1.0):
            px, pz = x - side * 0.75, z + side * 0.75
            height = 2.5 - index * 0.25
            scene.add("graveyard_kit/trunk-long", (px, -2.0, pz), rng.uniform(0, 360), (0.5, height, 0.5), tilt=rng.uniform(-5, 5))
            scene.add_box((px, -2.0 + height / 2, pz), (0.27, height, 0.27))
    scene.place("nature_kit/path_wood", (-35.0, 0.46, 45.6), 45.0 + 90.0, 2.2, roll=6.0)
    dead_tree(ground, rng, -42.6, 43.2, height=4.4, lean=10.0)


def build_chapel(scene, ground, rng):
    """Chapelle en ruine sur l'îlot de l'ouest : la nef sans toit, sa façade tournée vers les pontons, la croix tombée
    devant la porte, des bancs brisés et un pin qui pousse entre les dalles."""
    base = LOW_GROUND

    def ruin_wall(model, center, outward, height):
        x, z = center
        dx, dz = outward
        offset = 0.45 * 4.0
        angles = {(1, 0): 0, (-1, 0): 180, (0, -1): 90, (0, 1): -90}
        scene.add(f"fantasy_town_kit/{model}", (x - dx * offset, base, z - dz * offset), angles[outward], 4.0, coat="moss")
        size = (WALL_THICKNESS, height, 4.0) if dx else (4.0, height, WALL_THICKNESS)
        if model == "wall-door":
            along = (0, 1) if dx else (1, 0)
            for sign in (-1, 1):
                side_center = (x + along[0] * sign * 1.48, base + height / 2, z + along[1] * sign * 1.48)
                scene.add_box(side_center, (WALL_THICKNESS, height, 1.05) if dx else (1.05, height, WALL_THICKNESS))
            scene.add_box((x, base + 3.45, z), (WALL_THICKNESS, 1.1, 1.9) if dx else (1.9, 1.1, WALL_THICKNESS))
        else:
            scene.add_box((x, base + height / 2, z), size)

    ruin_wall("wall-door", (-32.0, -4.0), (1, 0), WALL_HEIGHT)
    ruin_wall("wall-window-round", (-40.0, -4.0), (-1, 0), WALL_HEIGHT)
    ruin_wall("wall-broken", (-38.0, -6.0), (0, -1), 3.0)
    ruin_wall("wall-half", (-34.0, -6.0), (0, -1), 2.0)
    ruin_wall("wall-window-stone", (-38.0, -2.0), (0, 1), WALL_HEIGHT)
    ruin_wall("wall-broken", (-34.0, -2.0), (0, 1), 3.0)
    # Fronton brisé au-dessus de la porte.
    scene.add("fantasy_town_kit/wall-broken", (-32.0 - 1.8, base + WALL_HEIGHT, -4.0), 0.0, (4.0, 2.2, 4.0), coat="moss")
    # Dans la nef (x de -39,8 à -32,2, z de -5,8 à -2,2) : l'autel, un banc debout, un autre renversé.
    scene.place("graveyard_kit/altar-stone", (-38.7, base, -4.0), 90.0, 2.0, height=True, coat="moss")
    scene.place("graveyard_kit/candle-multiple", (-38.7, base + 0.98, -4.5), 0.0, 2.0)
    scene.place("graveyard_kit/candle", (-38.6, base + 0.98, -3.4), 0.0, 2.2)
    scene.place("graveyard_kit/bench-damaged", (-36.4, base, -4.0), -90.0, 2.4, height=1.2)
    scene.place("graveyard_kit/bench-damaged", (-34.4, base, -4.0), -90.0, 2.4, tilt=-80.0, height=True)
    # Dehors, au pied du mur effondré : gravats, un rocher, une colonne couchée, un pin qui pousse dans la brèche.
    scene.place("graveyard_kit/debris", (-34.2, base, -7.0), 30.0, 3.0)
    scene.place("fantasy_town_kit/rock-large", (-39.6, base, -6.9), 40.0, 0.7, height=True, coat="moss")
    scene.place("fantasy_town_kit/pillar-stone", (-36.5, base, -8.0), 0.0, 4.0, roll=90.0, height=True, coat="moss")
    scene.place("graveyard_kit/pine-crooked", (-34.6, base, -0.6), 30.0, 3.0)
    scene.add_box((-34.6, base + 2.0, -0.6), (0.7, 4.0, 0.7))
    # La croix du fronton, tombée devant la porte.
    ground.item(-30.0, -4.3, footprint=1.2, sink=0.08).place("graveyard_kit/cross", degrees=80.0, scale=2.6, tilt=-90.0, coat="moss")
    for x, z, model, degrees in ((-31.0, -7.6, "gravestone-broken", 200.0), (-30.6, -0.6, "cross-wood", 260.0),
                                 (-41.4, 0.4, "gravestone-bevel", 20.0), (-41.6, -7.8, "gravestone-debris", 140.0),
                                 (-33.4, 0.6, "gravestone-round", -30.0)):
        ground.item(x, z, footprint=0.5, sink=0.06).place(f"graveyard_kit/{model}", degrees=degrees, scale=2.6, height=True, coat="moss")
    dead_tree(ground, rng, -42.4, -2.0, height=5.2, lean=9.0)


def build_grove(ground, rng):
    """Le bosquet mort, au nord-est : des troncs tordus et nus, leurs racines dans l'eau, un tronc couché."""
    for x, z, height, lean in ((34.0, -30.0, 5.4, 7.0), (36.6, -27.6, 4.2, -12.0), (31.4, -31.8, 3.6, 15.0), (35.8, -33.0, 4.8, -6.0)):
        dead_tree(ground, rng, x, z, height=height, lean=lean, branches=3 if height > 4 else 2)
    ground.item(33.0, -27.2, footprint=0.4).place("nature_kit/stump_oldTall", degrees=40.0, scale=3.0, height=True, coat="moss")
    ground.item(37.2, -31.0, footprint=1.3, sink=0.1).place("nature_kit/log_large", degrees=30.0, scale=3.0, height=True, coat="moss")
    for x, z, model in ((33.6, -26.6, "mushroom_redTall"), (37.8, -30.4, "mushroom_tanGroup"), (32.2, -29.0, "mushroom_tanGroup")):
        ground.item(x, z, footprint=0.2, sink=0.02).place(f"nature_kit/{model}", degrees=rng.uniform(0, 360), scale=3.0)


def build_stones(ground, rng):
    """Les pierres levées, au nord-ouest : un cercle de menhirs moussus autour d'une table de pierre, l'un d'eux couché."""
    models = ("stone_tallA", "stone_tallB", "stone_tallC", "stone_tallD", "stone_tallG", "stone_tallA", "stone_tallC")
    for index, model in enumerate(models):
        angle = math.tau * index / len(models) + 0.3
        x, z = -30.0 + math.cos(angle) * 2.7, -44.0 + math.sin(angle) * 2.7
        facing = math.degrees(math.atan2(-math.cos(angle), -math.sin(angle)))
        item = ground.item(x, z, footprint=0.5, sink=0.15)
        if index == 4:
            item.place(f"nature_kit/{model}", degrees=facing, scale=2.6, tilt=82.0, height=True, coat="moss")
        else:
            item.place(f"nature_kit/{model}", degrees=facing + rng.uniform(-15, 15), scale=rng.uniform(2.4, 2.9), tilt=rng.uniform(-6, 6), height=True, coat="moss")
    ground.item(-30.0, -44.0, footprint=0.8, sink=0.05).place("graveyard_kit/altar-stone", degrees=25.0, scale=1.6, height=True, coat="moss")
    for index in range(7):
        angle = math.tau * index / 7 + 0.75
        ground.item(-30.0 + math.cos(angle) * 1.6, -44.0 + math.sin(angle) * 1.6, footprint=0.2, sink=0.02).place(
            "nature_kit/mushroom_tanGroup", degrees=rng.uniform(0, 360), scale=2.4)


def build_shores(ground, rng):
    """Arbres morts le long des berges du parcours : leurs silhouettes tordues se dressent au-dessus de l'eau."""
    for x, z, height, lean in ((-13.8, 28.4, 4.6, 12.0), (-27.4, 18.0, 5.0, -10.0), (3.6, -4.6, 4.4, 9.0),
                               (28.8, 6.2, 5.2, -8.0), (-6.4, 44.6, 3.8, 14.0), (14.6, -14.0, 4.0, -12.0)):
        dead_tree(ground, rng, x, z, height=height, lean=lean, branches=2 + int(height > 4.5))


CRYPT_TILE = 4.0
CRYPT_HEIGHT = 4.15
# Cases de la crypte souterraine, en indices de case de 4 m : (x, z) du centre = 4 × indice.
CRYPT_ROOMS = {
    "entree": [(0, 0)],
    "salle": [(x, z) for x in range(-2, 3) for z in range(-5, 0)],
    "couloir_est": [(3, -3), (4, -3)],
    "chambre_est": [(x, z) for x in range(5, 8) for z in range(-4, -1)],
    "couloir_ouest": [(-3, -3), (-4, -3)],
    "chambre_ouest": [(x, z) for x in range(-7, -4) for z in range(-4, -1)],
    # Embranchements du sud : l'ossuaire à l'ouest, la chambre des gardiens à l'est.
    "couloir_sud_ouest": [(-3, -1), (-3, 0)],
    "ossuaire": [(x, z) for x in range(-5, -3) for z in range(0, 2)],
    "couloir_sud_est": [(3, -1), (3, 0)],
    "chambre_gardiens": [(x, z) for x in range(4, 6) for z in range(0, 2)],
}
NEIGHBOURS = {(0, -1): 180.0, (0, 1): 0.0, (1, 0): 90.0, (-1, 0): -90.0}
# Bord ouvert sur le long escalier de pierre, qui remonte vers la trappe au sud de l'entrée.
OPEN_EDGES = {((0, 0), (0, 1))}
# Escalier du kit : son pied (z local -6,2) touche l'entrée, il monte de 4,05 m jusqu'au palier.
STAIRS_ORIGIN = (0.0, 0.0, 8.2)
LANDING = (0.0, 4.05, 12.4)
# Façade des murs vue depuis la pièce : à 0,45 m du bord de la case (la collision dépasse, à 0,6 m).
WALL_FACE = 0.45


# Niches d'ossuaire : point de la façade du mur et direction de la pièce. Leur cadre de pierre et sa collision
# sont posés dans marais.tscn (write_marais_tscn.py, NICHES) ; ici, ce qu'elles abritent.
NICHES = (
    ((-10.0 + WALL_FACE, -8.0), (1, 0)), ((-10.0 + WALL_FACE, -16.0), (1, 0)),
    ((10.0 - WALL_FACE, -8.0), (-1, 0)), ((10.0 - WALL_FACE, -16.0), (-1, 0)),
    ((-18.0, 6.0 - WALL_FACE), (0, -1)), ((18.0, 6.0 - WALL_FACE), (0, -1)),
)
NICHE_DEPTH = 0.9
NICHE_FLOOR = 0.55
NICHE_SHELF = 1.56


def niche_contents(scene, rng, face, inward):
    """Un squelette couché sur la tablette basse, la tête le long du mur ; des urnes sur la tablette haute."""
    x, z = face
    nx, nz = inward
    along = (nz, -nx) if nz else (-nz, nx)
    yaw = 0.0 if nx else 90.0
    depth = NICHE_DEPTH / 2
    scene.place("graveyard_kit/character-skeleton", (x + nx * depth, NICHE_FLOOR, z + nz * depth), yaw + rng.choice((0.0, 180.0)), 1.7, tilt=-90.0, coat="dust")
    for offset, model in ((-0.6, "urn-round"), (0.0, "urn-square"), (0.6, "urn-round")):
        scene.place(f"graveyard_kit/{model}", (x + nx * depth + along[0] * offset, NICHE_SHELF, z + nz * depth + along[1] * offset),
                    rng.uniform(0, 90), 2.0, coat="dust")


def build_crypt_underground(scene, rng):
    """Crypte souterraine : le long escalier, la salle du mécanisme, deux couloirs vers les chambres des rois et du
    livre, deux embranchements vers l'ossuaire et la chambre des gardiens. Les tombeaux de jeu (rois, livre) et les
    niches sont posés dans marais.tscn ; ici, les murs, l'escalier et le mobilier."""
    tiles = {tile for room in CRYPT_ROOMS.values() for tile in room}
    for ix, iz in sorted(tiles):
        x, z = ix * CRYPT_TILE, iz * CRYPT_TILE
        scene.add("modular_dungeon_kit/template-floor", (x, 0.0, z), 0.0, 1.0)
        scene.add("modular_dungeon_kit/template-floor", (x, CRYPT_HEIGHT, z), 0.0, 1.0, tilt=180.0)
        scene.add_box((x, -0.25, z), (CRYPT_TILE, 0.5, CRYPT_TILE))
        scene.add_box((x, CRYPT_HEIGHT + 0.25, z), (CRYPT_TILE, 0.5, CRYPT_TILE))
        # Un mur sur chaque bord qui ne donne sur aucune case : son pied regarde l'intérieur de la case.
        for (dx, dz), degrees in NEIGHBOURS.items():
            if (ix + dx, iz + dz) in tiles or ((ix, iz), (ix + dx, iz + dz)) in OPEN_EDGES:
                continue
            edge = (x + dx * CRYPT_TILE / 2, z + dz * CRYPT_TILE / 2)
            scene.add("modular_dungeon_kit/template-wall", (edge[0], 0.0, edge[1]), degrees, 1.0)
            size = (0.6, CRYPT_HEIGHT, CRYPT_TILE) if dx else (CRYPT_TILE, CRYPT_HEIGHT, 0.6)
            scene.add_box((edge[0] - dx * 0.3, CRYPT_HEIGHT / 2, edge[1] - dz * 0.3), size)

    # Le long escalier de pierre : le modèle du kit, sa rampe de collision, ses murs et son plafond en pente.
    sx, sy, sz = STAIRS_ORIGIN
    scene.add("modular_dungeon_kit/stairs", STAIRS_ORIGIN, 0.0, 1.0, coat="dust")
    scene.add_box((0.0, -0.25, sz - 5.0), (3.0, 0.5, 2.5))
    # Rampe de collision sur le nez des marches : sept marches de 0,58 m, la première à z local -3,25, la
    # dernière à 1,45 (mesurées sur le modèle). Elle part du sol à z local -4,03 et arrive au palier à 4,05 m :
    # chaque marche porte le joueur, sans ressaut ni marche à franchir.
    bottom, top_nose = -4.03, 1.45
    run, rise = top_nose - bottom, 4.05
    slope = math.degrees(math.atan2(rise, run))
    length = math.hypot(run, rise)
    normal = (math.cos(math.radians(slope)), math.sin(math.radians(slope)))
    mid_z, mid_y = sz + bottom + run / 2, rise / 2
    scene.add_box((0.0, mid_y - normal[0] * 0.3, mid_z + normal[1] * 0.3), (3.0, 0.6, length), 0.0, tilt=-slope)
    # Dernière marche, plate, jusqu'au palier.
    scene.add_box((0.0, rise - 0.25, sz + top_nose + 0.4), (3.0, 0.5, 0.8))
    for side in (-1.0, 1.0):
        scene.add_box((side * 1.8, 4.3, sz - 2.0), (0.7, 8.6, 8.4))
    # Plafond : en pente au-dessus du pied de l'escalier, en suivant le haut de ses murs, puis plat à 4,15 m au-dessus
    # du palier, jusqu'au fond. Les murs du modèle montent plus haut : aucun jour entre eux et le plafond.
    lx, ly, lz = LANDING
    top = ly + CRYPT_HEIGHT
    low_end = sz - 6.2
    high_end = low_end + (top - CRYPT_HEIGHT) / (8.55 - CRYPT_HEIGHT) * 3.9
    run_c, rise_c = high_end - low_end, top - CRYPT_HEIGHT
    tilt_c = math.degrees(math.atan2(rise_c, run_c))
    length_c = math.hypot(run_c, rise_c)
    middle = ((CRYPT_HEIGHT + top) / 2, (low_end + high_end) / 2)
    scene.add("modular_dungeon_kit/template-floor", (0.0, middle[0], middle[1]), 0.0, (0.75, 1.0, length_c / 4.0), tilt=180.0 - tilt_c)
    scene.add_box((0.0, middle[0] + 0.3 * math.cos(math.radians(tilt_c)), middle[1] - 0.3 * math.sin(math.radians(tilt_c))),
                  (3.6, 0.6, length_c + 0.3), 0.0, tilt=-tilt_c)
    flat_end = lz + 2.0
    flat_length = flat_end - high_end
    scene.add("modular_dungeon_kit/template-floor", (0.0, top, (high_end + flat_end) / 2), 0.0, (0.75, 1.0, flat_length / 4.0), tilt=180.0)
    scene.add_box((0.0, top + 0.3, (high_end + flat_end) / 2), (3.6, 0.6, flat_length + 0.2))
    # Palier du haut, sous la trappe : son sol (qui rejoint la dernière marche), ses murs.
    scene.add("modular_dungeon_kit/template-floor", (lx, ly, lz), 0.0, (0.75, 1.0, 1.0))
    scene.add_box((lx, ly - 0.25, lz - 0.3), (3.6, 0.5, 4.6))
    for (dx, dz), degrees in ((1, 0), 90.0), ((-1, 0), -90.0), ((0, 1), 0.0):
        edge = (lx + dx * 1.9, lz + dz * 2.0)
        scene.add("modular_dungeon_kit/template-wall", (edge[0], ly, edge[1]), degrees, (0.95, 1.0, 1.0) if dz else 1.0)
        size = (0.6, CRYPT_HEIGHT + 0.2, 4.0) if dx else (3.8, CRYPT_HEIGHT + 0.2, 0.6)
        scene.add_box((edge[0] - dx * 0.3, ly + CRYPT_HEIGHT / 2, edge[1] - dz * 0.3), size)

    # Salle du mécanisme : colonnes aux angles, bannières et cierges autour du mécanisme, braseros au fond.
    for x in (-7.0, 7.0):
        for z in (-5.0, -19.0):
            scene.add("mini_dungeon/column", (x, 0.0, z), 0.0, 3.6, coat="dust")
            scene.add_box((x, 2.0, z), (1.6, 4.0, 1.6))
    face = -22.0 + WALL_FACE
    for x in (-5.0, 5.0):
        scene.place("mini_dungeon/banner", (x, 1.4, face + 0.17), 0.0, 3.0)
    for x, z in ((-4.2, -8.0), (4.2, -8.0), (-4.2, -16.0), (4.2, -16.0)):
        scene.place("graveyard_kit/candle-multiple", (x, 0.0, z), rng.uniform(0, 360), 3.0)
    for x in (-8.4, 8.4):
        scene.place("graveyard_kit/fire-basket", (x, 0.0, -20.6), 0.0, 3.0, height=True)
    # Sarcophages poussiéreux contre le mur de l'entrée.
    for x in (-4.3, 4.3):
        scene.place("graveyard_kit/coffin", (x, 0.0, -3.9), 90.0, 3.0, height=True, coat="dust")
        scene.place("graveyard_kit/candle", (x + 0.6, 0.6, -3.9), 0.0, 2.0)
    # Bannières des couloirs, contre leur mur sud.
    for x in (-14.0, 14.0):
        scene.place("mini_dungeon/banner", (x, 1.4, -14.0 + WALL_FACE + 0.17), 0.0, 3.0)
    # Bas de l'escalier : deux cierges.
    for x in (-1.05, 1.05):
        scene.place("graveyard_kit/candle-multiple", (x, 0.0, 1.55), rng.uniform(0, 360), 2.2)

    # Chambre de l'ouest : les tombeaux des rois Codeon I à IV, posés dans marais.tscn, bordent l'allée ;
    # bannières royales sur les murs derrière eux, autel des offrandes sous l'hommage, urnes dans les angles.
    for x in (-21.2, -26.8):
        scene.add("castle_kit/flag-banner-long", (x, 0.95, -6.0 - WALL_FACE - 0.01), 90.0, 1.25)
        scene.add("castle_kit/flag-banner-long", (x, 0.95, -18.0 + WALL_FACE + 0.01), -90.0, 1.25)
    scene.place("graveyard_kit/altar-stone", (-28.35, 0.0, -12.0), 90.0, 2.0, height=True, coat="dust")
    scene.place("graveyard_kit/candle-multiple", (-28.4, 0.98, -12.75), 0.0, 2.0)
    scene.place("graveyard_kit/candle-multiple", (-28.4, 0.98, -11.25), 50.0, 2.0)
    scene.place("graveyard_kit/detail-chalice", (-28.3, 0.98, -12.0), 0.0, 2.4)
    for x, z in ((-28.7, -7.3), (-28.7, -16.7), (-19.3, -7.3), (-19.3, -16.7)):
        scene.place("graveyard_kit/urn-square", (x, 0.0, z), rng.uniform(0, 90), 2.4, height=True, coat="dust")

    # Chambre de l'est : le tombeau du livre au centre, gardé par une statue, entre deux lanternes et des cierges.
    scene.place("mini_arena/statue", (28.2, 0.0, -12.0), -90.0, 2.1, height=True, coat="dust")
    for x, z in ((28.4, -8.6), (28.4, -15.4)):
        scene.place("graveyard_kit/lantern-candle", (x, 0.0, z), 0.0, 3.0, height=True)
    for x, z in ((21.6, -9.0), (21.6, -15.0), (26.2, -8.6), (26.2, -15.4)):
        scene.place("graveyard_kit/candle-multiple", (x, 0.0, z), rng.uniform(0, 360), 2.6)
    for x in (21.0, 27.0):
        scene.add("castle_kit/flag-banner-long", (x, 0.95, -6.0 - WALL_FACE - 0.01), 90.0, 1.2)
        scene.add("castle_kit/flag-banner-long", (x, 0.95, -18.0 + WALL_FACE + 0.01), -90.0, 1.2)

    # Ossuaire, au sud-ouest : sarcophages et cercueils couverts de poussière, os entassés, une urne renversée.
    for z in (0.6, 3.6):
        scene.place("graveyard_kit/coffin-old", (-20.2, 0.0, z), 0.0, 2.6, height=True, coat="dust")
    scene.place("graveyard_kit/gravestone-debris", (-17.4, 0.0, -0.4), 30.0, 2.6, coat="dust")
    scene.place("mini_dungeon/stones", (-16.2, 0.0, 3.4), 20.0, 1.8, coat="dust")
    scene.place("graveyard_kit/urn-round", (-15.2, 0.0, 4.7), 40.0, 2.4, tilt=90.0, coat="dust")
    scene.place("graveyard_kit/candle-multiple", (-18.2, 0.0, 2.2), 10.0, 2.4)
    # Chambre des gardiens, au sud-est : leurs cercueils alignés, leurs boucliers et leurs lances.
    for x in (15.6, 20.4):
        scene.place("graveyard_kit/coffin-old", (x, 0.0, 3.9), 0.0, 2.6, height=True, coat="dust")
        scene.place("mini_dungeon/shield-round", (x, 0.52, 3.9), 0.0, 1.8, tilt=-90.0)
    scene.place("graveyard_kit/coffin", (18.6, 0.0, 0.3), 90.0, 2.8, height=True, coat="dust")
    scene.place("mini_dungeon/weapon-spear", (18.6, 0.56, 0.3), 90.0, 2.6, roll=90.0)
    scene.place("graveyard_kit/candle-multiple", (16.0, 0.0, 0.6), 0.0, 2.4)
    scene.place("graveyard_kit/candle-multiple", (21.0, 0.0, 1.6), 30.0, 2.4)
    for face, inward in NICHES:
        niche_contents(scene, rng, face, inward)


def main():
    rng = random.Random(4040)
    scene = MarshScene("MaraisProps")
    ground = GroundScene("MaraisGrounded")
    build_hut(scene)
    build_cemetery(scene, ground, rng)
    build_crypt(scene, ground, rng)
    build_arrival(scene, ground, rng)
    build_village(scene, rng)
    build_last_house(scene, ground)
    build_landing(scene, ground, rng)
    build_chapel(scene, ground, rng)
    build_grove(ground, rng)
    build_stones(ground, rng)
    build_shores(ground, rng)
    OUTPUT.write_text(scene.text(), encoding="utf-8", newline="\n")
    print(f"{OUTPUT.name} : {len(scene.visuals)} modèles, {len(scene.colliders)} collisions")
    GROUNDED_OUTPUT.write_text(ground.text(), encoding="utf-8", newline="\n")
    print(f"{GROUNDED_OUTPUT.name} : {len(ground.items)} objets")
    crypt = MarshScene("MaraisCrypt")
    build_crypt_underground(crypt, rng)
    CRYPT_OUTPUT.write_text(crypt.text(), encoding="utf-8", newline="\n")
    print(f"{CRYPT_OUTPUT.name} : {len(crypt.visuals)} modèles, {len(crypt.colliders)} collisions")


if __name__ == "__main__":
    main()
