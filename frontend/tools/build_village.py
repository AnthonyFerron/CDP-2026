"""Génère les objets fixes du Village détruit : l'enceinte, les maisons, la place, l'hôtel de ville et les moulins,
puis l'intérieur de la mairie.

Les scènes produites s'ouvrent et se modifient dans Godot, mais le script les écrase :
pour un changement durable, modifier ce script puis le relancer depuis le dossier frontend :

    python tools/build_village.py

Le script contrôle aussi le décor qu'il pose : il signale tout objet solide qui en traverse un autre, et tout
objet posé sur un passage à garder libre (grande rue, portes, chemins de l'énigme).
"""

import math
import random
import re
from pathlib import Path

from build_plaine import (SHELVES, DOORWAY_HEIGHT, MODEL_BOXES, WALL_HEIGHT, WALL_SCALE, WALL_THICKNESS, Scene, arch_fill, doorway,
                          furniture, multiply, rotation_x, rotation_y, rotation_z, transform_text, wall)

OUTPUT = Path(__file__).resolve().parent.parent / "scenes" / "levels" / "village" / "village_props.tscn"
TILE = WALL_SCALE
RAMPART = 4.0

# Boîtes englobantes (coin, taille) des modèles ajoutés pour le Village, à l'échelle 1.
MODEL_BOXES.update({
    "food_kit/bag": ((-0.16, 0.0, -0.29), (0.31, 0.84, 0.58)),
    "food_kit/bag-flat": ((-0.32, 0.0, -0.23), (0.65, 0.19, 0.47)),
    "food_kit/barrel": ((-0.38, 0.0, -0.34), (0.76, 0.68, 0.68)),
    "food_kit/loaf": ((-0.29, 0.0, -0.18), (0.58, 0.44, 0.37)),
    "food_kit/loaf-round": ((-0.39, 0.0, -0.26), (0.77, 0.29, 0.51)),
    "food_kit/loaf-baguette": ((-0.42, 0.0, -0.13), (0.83, 0.25, 0.25)),
    "food_kit/croissant": ((-0.17, 0.0, -0.24), (0.35, 0.19, 0.48)),
    "food_kit/bread": ((-0.22, 0.0, -0.18), (0.44, 0.04, 0.37)),
    "food_kit/apple": ((-0.1, 0.0, -0.1), (0.2, 0.19, 0.2)),
    "food_kit/carrot": ((-0.17, 0.0, -0.17), (0.34, 0.72, 0.34)),
    "food_kit/cheese": ((-0.34, 0.0, -0.34), (0.68, 0.22, 0.68)),
    "food_kit/cabbage": ((-0.19, 0.0, -0.2), (0.38, 0.31, 0.4)),
    "food_kit/pumpkin": ((-0.21, 0.0, -0.21), (0.42, 0.23, 0.42)),
    "food_kit/mug": ((-0.12, 0.0, -0.14), (0.34, 0.27, 0.29)),
    "food_kit/plate": ((-0.45, 0.0, -0.45), (0.89, 0.09, 0.89)),
    "food_kit/plate-broken": ((-0.28, 0.0, -0.24), (0.55, 0.09, 0.47)),
    "food_kit/pot-stew": ((-0.33, 0.0, -0.41), (0.66, 0.36, 0.82)),
    "food_kit/whole-ham": ((-0.19, 0.0, -0.32), (0.38, 0.44, 0.64)),
    "food_kit/wine-red": ((-0.1, 0.0, -0.08), (0.19, 0.7, 0.17)),
    "food_kit/fish": ((-0.1, 0.0, -0.31), (0.2, 0.32, 0.62)),
    "food_kit/onion": ((-0.11, 0.0, -0.12), (0.21, 0.25, 0.25)),
    "food_kit/leek": ((-0.14, 0.0, -0.14), (0.27, 0.85, 0.27)),
    "food_kit/rollingPin": ((-0.41, -0.07, -0.08), (0.81, 0.14, 0.16)),
    "food_kit/cutting-board": ((-0.29, 0.0, -0.41), (0.58, 0.06, 0.82)),
    "food_kit/honey": ((-0.16, 0.0, -0.16), (0.33, 0.32, 0.33)),
    "food_kit/mortar-pestle": ((-0.06, 0.0, -0.07), (0.11, 0.34, 0.13)),
    "food_kit/pie": ((-0.48, 0.0, -0.48), (0.95, 0.15, 0.95)),
    "food_kit/pear": ((-0.1, 0.0, -0.1), (0.2, 0.27, 0.2)),
    "food_kit/egg": ((-0.06, 0.0, -0.07), (0.12, 0.17, 0.13)),
    "mini_dungeon/weapon-sword": ((-0.12, -0.1, -0.05), (0.23, 0.45, 0.11)),
    "mini_dungeon/shield-rectangle": ((-0.14, 0.0, -0.05), (0.28, 0.3, 0.13)),
    "mini_dungeon/pot": ((-0.3, 0.0, -0.2), (0.6, 0.43, 0.41)),
    "mini_dungeon/chair": ((-0.17, 0.0, -0.19), (0.35, 0.48, 0.38)),
    "mini_dungeon/potion": ((-0.16, 0.0, -0.16), (0.33, 0.4, 0.33)),
    "mini_dungeon/coin": ((-0.21, 0.0, -0.08), (0.42, 0.42, 0.17)),
    "mini_dungeon/stones": ((-0.45, 0.0, -0.4), (0.89, 0.45, 0.8)),
    "mini_arena/weapon-rack": ((-0.42, 0.0, -0.15), (0.78, 0.47, 0.45)),
    "mini_arena/bricks": ((-0.39, 0.0, -0.42), (0.77, 0.41, 0.85)),
    "mini_arena/statue": ((-0.35, 0.0, -0.35), (0.7, 1.34, 0.7)),
    "survival_kit/bucket": ((-0.07, 0.0, -0.07), (0.14, 0.19, 0.14)),
    "survival_kit/barrel-open": ((-0.12, 0.0, -0.12), (0.24, 0.34, 0.24)),
    "survival_kit/box-open": ((-0.13, 0.0, -0.13), (0.25, 0.31, 0.25)),
    "survival_kit/box-large-open": ((-0.13, 0.0, -0.25), (0.25, 0.31, 0.5)),
    "survival_kit/tool-axe": ((-0.07, 0.0, -0.02), (0.11, 0.26, 0.03)),
    "survival_kit/tool-hammer": ((-0.04, 0.0, -0.02), (0.09, 0.15, 0.04)),
    "survival_kit/tool-hoe": ((-0.07, 0.0, -0.04), (0.08, 0.24, 0.07)),
    "survival_kit/tool-shovel": ((-0.04, 0.0, -0.02), (0.07, 0.29, 0.03)),
    "survival_kit/resource-planks": ((-0.19, 0.0, -0.31), (0.37, 0.09, 0.63)),
    "survival_kit/resource-wood": ((-0.1, 0.0, -0.04), (0.21, 0.06, 0.09)),
    "survival_kit/fence-fortified": ((-0.25, 0.0, -0.25), (0.5, 0.52, 0.05)),
    "survival_kit/tree-log-small": ((-0.12, 0.0, -0.32), (0.25, 0.28, 0.65)),
    "survival_kit/bottle": ((-0.03, 0.0, -0.03), (0.05, 0.15, 0.06)),
    "graveyard_kit/debris": ((-0.29, 0.0, -0.31), (0.54, 0.16, 0.55)),
    "graveyard_kit/debris-wood": ((-0.23, 0.0, -0.25), (0.46, 0.1, 0.5)),
    "graveyard_kit/lantern-glass": ((-0.12, 0.0, -0.12), (0.24, 0.39, 0.24)),
    "graveyard_kit/bench-damaged": ((-0.48, 0.0, -0.23), (0.91, 0.52, 0.46)),
    "graveyard_kit/fence-damaged": ((-0.5, 0.0, -0.11), (1.0, 0.62, 0.31)),
    "graveyard_kit/urn-round": ((-0.13, 0.0, -0.13), (0.26, 0.28, 0.26)),
    "graveyard_kit/detail-plate": ((-0.14, 0.0, -0.14), (0.27, 0.05, 0.27)),
    "graveyard_kit/detail-chalice": ((-0.08, 0.0, -0.08), (0.16, 0.25, 0.16)),
    "graveyard_kit/candle": ((-0.07, 0.0, -0.07), (0.14, 0.2, 0.14)),
    "graveyard_kit/pumpkin": ((-0.19, 0.0, -0.19), (0.38, 0.32, 0.38)),
    "graveyard_kit/shovel": ((-0.1, 0.0, -0.05), (0.19, 0.61, 0.1)),
    "graveyard_kit/rocks": ((-0.44, 0.0, -0.43), (1.08, 0.38, 0.96)),
    "fantasy_town_kit/stall-stool": ((-0.13, 0.0, -0.13), (0.26, 0.23, 0.26)),
    "fantasy_town_kit/fence": ((0.42, 0.0, -0.5), (0.08, 0.38, 1.0)),
    "fantasy_town_kit/fence-broken": ((0.25, 0.0, -0.5), (0.25, 0.38, 1.0)),
    "fantasy_town_kit/lantern": ((-0.11, 0.0, -0.11), (0.22, 1.56, 0.22)),
    "fantasy_town_kit/banner-green": ((0.38, 0.16, -0.25), (0.05, 0.84, 0.5)),
    "castle_kit/rocks-small": ((-0.52, 0.0, -0.55), (1.03, 0.5, 1.11)),
    "castle_kit/rocks-large": ((-0.6, 0.0, -0.67), (1.2, 0.5, 1.35)),
    "castle_kit/tree-log": ((-0.12, -0.11, -0.5), (0.25, 0.28, 1.0)),
    "castle_kit/flag-banner-long": ((0.0, 0.0, -0.32), (0.04, 2.17, 0.63)),
    "castle_kit/siege-ballista-demolished": ((-0.91, 0.0, -0.79), (1.75, 0.51, 1.55)),
    "castle_kit/door": ((-0.08, 0.0, -0.18), (0.15, 0.61, 0.36)),
    "nature_kit/crops_dirtDoubleRow": ((-0.5, 0.0, -0.44), (1.0, 0.05, 0.94)),
    "nature_kit/crop_carrot": ((-0.17, 0.0, -0.17), (0.34, 0.62, 0.34)),
    "nature_kit/crop_turnip": ((-0.17, 0.0, -0.17), (0.34, 0.66, 0.34)),
    "nature_kit/crop_melon": ((-0.21, 0.0, -0.18), (0.42, 0.35, 0.36)),
    "nature_kit/crops_leafsStageB": ((-0.19, 0.0, -0.19), (0.39, 0.68, 0.39)),
    "nature_kit/crops_cornStageB": ((-0.15, 0.0, -0.15), (0.3, 1.0, 0.3)),
    "nature_kit/crops_wheatStageA": ((-0.27, 0.0, -0.22), (0.54, 0.33, 0.45)),
    "nature_kit/fence_planks": ((-0.5, 0.0, -0.53), (1.0, 0.35, 0.1)),
    "nature_kit/fence_simpleLow": ((-0.52, 0.0, -0.52), (1.04, 0.2, 0.11)),
    "nature_kit/log": ((-0.11, 0.0, -0.35), (0.23, 0.17, 0.71)),
    "nature_kit/stump_old": ((-0.16, 0.0, -0.19), (0.36, 0.27, 0.37)),
    "nature_kit/pot_small": ((-0.16, 0.0, -0.14), (0.32, 0.27, 0.28)),
    "nature_kit/plant_bushSmall": ((-0.19, 0.0, -0.17), (0.38, 0.21, 0.34)),
    "nature_kit/flower_redA": ((-0.1, 0.0, -0.09), (0.16, 0.29, 0.18)),
    "nature_kit/flower_yellowA": ((-0.1, 0.0, -0.09), (0.16, 0.19, 0.18)),
    "nature_kit/statue_columnDamaged": ((-0.15, 0.0, -0.15), (0.3, 0.7, 0.3)),
    "furniture_kit/plantSmall1": ((-0.09, 0.0, -0.09), (0.19, 0.28, 0.19)),
    "furniture_kit/rugSquare": ((0.0, 0.0, -0.92), (0.9, 0.01, 0.92)),
    "mini_forest/weapon-arrow": ((-0.06, -0.06, -0.23), (0.12, 0.12, 0.46)),
    "survival_kit/resource-stone": ((-0.08, 0.0, -0.07), (0.17, 0.11, 0.14)),
    "nature_kit/campfire_logs": ((-0.15, 0.0, -0.15), (0.29, 0.06, 0.29)),
    "mini_arena/weapon-spear": ((-0.07, 0.0, -0.06), (0.15, 0.7, 0.12)),
})

# Kits dont les modèles répétés sont dessinés en une fois (MultiMesh, voir village_instances.gd) : leurs
# modèles n'ont qu'un maillage. Les meubles du kit furniture, faits de pièces, restent des instances.
INSTANCED_KITS = ("food_kit/", "nature_kit/", "survival_kit/", "mini_dungeon/", "mini_arena/", "graveyard_kit/",
                  "castle_kit/rocks", "castle_kit/wall-narrow", "castle_kit/tree-log", "fantasy_town_kit/wall",
                  "fantasy_town_kit/pillar", "fantasy_town_kit/planks", "fantasy_town_kit/poles", "fantasy_town_kit/lantern",
                  "fantasy_town_kit/fence", "fantasy_town_kit/rock", "mini_forest/")
# Les petits objets s'effacent au loin, comme l'herbe du terrain.
SMALL_KITS = ("food_kit/", "survival_kit/bottle", "survival_kit/bucket", "survival_kit/tool", "graveyard_kit/candle",
              "graveyard_kit/detail", "mini_dungeon/coin", "mini_dungeon/potion", "mini_forest/weapon-arrow",
              "nature_kit/flower", "nature_kit/crop_", "nature_kit/crops_leafs", "nature_kit/plant_bushSmall")
SMALL_RANGE = 45.0


# --- Sol du bourg -------------------------------------------------------------------------------------------------

def smoothstep(edge0, edge1, x):
    t = min(max((x - edge0) / (edge1 - edge0), 0.0), 1.0)
    return t * t * (3.0 - 2.0 * t)


def town_ground(x, z):
    """Hauteur du sol dans le bourg, comme village_terrain.gd : le relief y est effacé, restent la colline du moulin
    et la rive du ruisseau."""
    hill = math.hypot(x - 30.0, z + 30.0) / 12.0
    height = max(0.0, 4.0 * (1.0 - smoothstep(0.35, 1.0, hill)))
    return height - 1.4 * (1.0 - smoothstep(1.8, 4.5, abs(x + 38.0)))


def ground_span(x0, x1, z0, z1):
    """Plus basse et plus haute hauteur du sol maillé (grille de 1,25 m) sous un rectangle du bourg."""
    cell, half = 1.25, 85.0
    heights = []
    for i in range(math.floor((x0 + half) / cell), math.ceil((x1 + half) / cell) + 1):
        for k in range(math.floor((z0 + half) / cell), math.ceil((z1 + half) / cell) + 1):
            heights.append(town_ground(i * cell - half, k * cell - half))
    return min(heights), max(heights)


# --- Scène ----------------------------------------------------------------------------------------------------------

def basis_of(degrees=0.0, tilt=0.0, roll=0.0, scale=1.0):
    basis = multiply(multiply(rotation_y(degrees), rotation_x(tilt)), rotation_z(roll))
    axes = scale if isinstance(scale, tuple) else (scale, scale, scale)
    return [[row[column] * axes[column] for column in range(3)] for row in basis]


def fmt(value):
    return f"{round(value, 5):g}"


class VillageScene(Scene):
    """Scène du Village : en plus des modèles et des boîtes, des collisions cylindriques, des formes simples
    (regroupées en MultiMesh quand elles se répètent), des modèles répétés dessinés en une fois et des panneaux."""

    def __init__(self, root_name):
        super().__init__(root_name)
        self.cylinders = []
        self.meshes = {}
        self.materials = {}
        self.shapes = {}
        self.signs = []
        self.lights = []

    def add(self, model, position, degrees=0.0, scale=1.0, tilt=0.0, roll=0.0, single=False):
        super().add(model, position, degrees, scale, tilt, roll)
        if single:
            self.visuals[-1] = self.visuals[-1] + ("single",)

    def add_cylinder(self, center, radius, height):
        self.cylinders.append((center, radius, height))

    def material(self, key, color, roughness=0.9, emission=None, energy=1.0, metallic=0.0):
        self.materials.setdefault(key, (color, roughness, emission, energy, metallic))
        return key

    def mesh(self, kind, **params):
        key = kind + "_" + "_".join(f"{name}{fmt(value) if isinstance(value, float) else value}"
                                    for name, value in sorted(params.items()))
        key = re.sub(r"[^A-Za-z0-9_]+", "_", key.replace(".", "p").replace("-", "m")).strip("_")
        self.meshes.setdefault(key, (kind, params))
        return key

    def shape(self, mesh_key, material_key, position, degrees=0.0, tilt=0.0, roll=0.0, scale=1.0):
        basis = basis_of(degrees, tilt, roll, scale)
        self.shapes.setdefault((mesh_key, material_key), []).append((basis, position))

    def sign(self, name, position, degrees, **props):
        self.signs.append((name, transform_text(rotation_y(degrees), position), props))

    def text(self):
        lines = ["[gd_scene format=3]", ""]
        single, grouped = [], {}
        for visual in self.visuals:
            name, path, transform = visual[:3]
            model = path[len("res://assets/models/kenney/"):-len(".glb")]
            if len(visual) == 3 and model.startswith(INSTANCED_KITS):
                grouped.setdefault(path, []).append(transform)
            else:
                single.append((name, path, transform))
        # Un modèle posé une ou deux fois reste une instance ordinaire.
        for path, transforms in list(grouped.items()):
            if len(transforms) < 3:
                name = path.rsplit("/", 1)[-1][:-4].replace("-", "_")
                single += [(name, path, transform) for transform in transforms]
                del grouped[path]
        paths = []
        for _, path, _ in single:
            if path not in paths:
                paths.append(path)
        for path in grouped:
            if path not in paths:
                paths.append(path)
        ids = {path: f"{index + 1}_model" for index, path in enumerate(paths)}
        for path in paths:
            lines.append(f'[ext_resource type="PackedScene" path="{path}" id="{ids[path]}"]')
        if grouped:
            lines.append('[ext_resource type="Script" path="res://scenes/levels/village/village_instances.gd" id="instances"]')
        if self.signs:
            lines.append('[ext_resource type="Script" path="res://scripts/sign_board.gd" id="sign"]')
        lines.append("")
        for size, identifier in self.boxes.items():
            lines += [f'[sub_resource type="BoxShape3D" id="{identifier}"]',
                      f"size = Vector3({size[0]:g}, {size[1]:g}, {size[2]:g})", ""]
        cylinder_ids = {}
        for _, radius, height in self.cylinders:
            key = (round(radius, 3), round(height, 3))
            if key not in cylinder_ids:
                cylinder_ids[key] = f"CylinderShape3D_{len(cylinder_ids) + 1}"
                lines += [f'[sub_resource type="CylinderShape3D" id="{cylinder_ids[key]}"]',
                          f"height = {key[1]:g}", f"radius = {key[0]:g}", ""]
        for key, (color, roughness, emission, energy, metallic) in self.materials.items():
            lines += [f'[sub_resource type="StandardMaterial3D" id="Material_{key}"]', f'resource_name = "{key}"',
                      "albedo_color = Color(%s, 1)" % ", ".join(fmt(c) for c in color), f"roughness = {fmt(roughness)}"]
            if metallic:
                lines.append(f"metallic = {fmt(metallic)}")
            if emission:
                lines += ["emission_enabled = true", "emission = Color(%s, 1)" % ", ".join(fmt(c) for c in emission),
                          f"emission_energy_multiplier = {fmt(energy)}"]
            lines.append("")
        for key, (kind, params) in self.meshes.items():
            lines.append(f'[sub_resource type="{kind}" id="{key}"]')
            for name, value in params.items():
                if isinstance(value, tuple):
                    value = ("Vector3(%s)" if len(value) == 3 else "Vector2(%s)") % ", ".join(fmt(v) for v in value)
                elif isinstance(value, bool):
                    value = "true" if value else "false"
                elif isinstance(value, float):
                    value = fmt(value)
                lines.append(f"{name} = {value}")
            lines.append("")
        multi = [(key, items) for key, items in self.shapes.items() if len(items) > 1]
        for index, ((mesh_key, _), items) in enumerate(multi):
            buffer = []
            for basis, origin in items:
                for row in range(3):
                    buffer += [basis[row][0], basis[row][1], basis[row][2], origin[row]]
            lines += [f'[sub_resource type="MultiMesh" id="MultiMesh_{index + 1}"]', "transform_format = 1",
                      f"instance_count = {len(items)}", f'mesh = SubResource("{mesh_key}")',
                      "buffer = PackedFloat32Array(" + ", ".join(fmt(v) for v in buffer) + ")", ""]
        lines += [f'[node name="{self.root_name}" type="Node3D"]', ""]
        lines += ['[node name="Models" type="Node3D" parent="."]', ""]
        for index, (name, path, transform) in enumerate(single):
            lines += [f'[node name="{name}_{index}" parent="Models" instance=ExtResource("{ids[path]}")]',
                      f"transform = {transform}", ""]
        if grouped:
            lines += ['[node name="Instances" type="Node3D" parent="."]', ""]
            for path, transforms in grouped.items():
                model = path[len("res://assets/models/kenney/"):-len(".glb")]
                name = model.replace("/", "_").replace("-", "_")
                lines += [f'[node name="{name}" type="Node3D" parent="Instances"]', 'script = ExtResource("instances")',
                          f'model = ExtResource("{ids[path]}")',
                          "transforms = Array[Transform3D]([" + ", ".join(transforms) + "])"]
                if model.startswith(SMALL_KITS):
                    lines.append(f"visibility_end = {SMALL_RANGE:g}")
                lines.append("")
        if self.shapes:
            lines += ['[node name="Shapes" type="Node3D" parent="."]', ""]
            multi_index = 0
            for (mesh_key, material_key), items in self.shapes.items():
                if len(items) > 1:
                    multi_index += 1
                    lines += [f'[node name="{mesh_key}_{material_key}" type="MultiMeshInstance3D" parent="Shapes"]',
                              f'material_override = SubResource("Material_{material_key}")',
                              f'multimesh = SubResource("MultiMesh_{multi_index}")', ""]
                else:
                    basis, origin = items[0]
                    lines += [f'[node name="{mesh_key}_{material_key}" type="MeshInstance3D" parent="Shapes"]',
                              f"transform = {transform_text(basis, origin)}",
                              f'material_override = SubResource("Material_{material_key}")',
                              f'mesh = SubResource("{mesh_key}")', ""]
        if self.signs:
            lines += ['[node name="Signs" type="Node3D" parent="."]', ""]
            for name, transform, props in self.signs:
                lines += [f'[node name="{name}" type="Node3D" parent="Signs"]', f"transform = {transform}",
                          'script = ExtResource("sign")']
                for key, value in props.items():
                    if isinstance(value, str):
                        value = '"' + value.replace('"', '\\"') + '"'
                    elif isinstance(value, bool):
                        value = "true" if value else "false"
                    elif isinstance(value, tuple):
                        value = "Vector2(%s)" % ", ".join(fmt(v) for v in value)
                    lines.append(f"{key} = {value}")
                lines.append("")
        lines += ['[node name="Collision" type="StaticBody3D" parent="."]', ""]
        for index, (transform, identifier) in enumerate(self.colliders):
            lines += [f'[node name="Box{index}" type="CollisionShape3D" parent="Collision"]', f"transform = {transform}",
                      f'shape = SubResource("{identifier}")', ""]
        for index, (center, radius, height) in enumerate(self.cylinders):
            identifier = cylinder_ids[(round(radius, 3), round(height, 3))]
            lines += [f'[node name="Cylinder{index}" type="CollisionShape3D" parent="Collision"]',
                      f"transform = {transform_text(rotation_y(0.0), center)}", f'shape = SubResource("{identifier}")', ""]
        return "\n".join(lines).rstrip("\n") + "\n"


# --- Contrôle du décor : rien ne traverse rien, les passages restent libres ---------------------------------------

class Layout:
    """Emprises au sol (rectangles tournés) des objets solides et des passages à garder libres."""

    def __init__(self):
        self.solids = []
        self.clear = []

    def reset(self):
        self.solids.clear()
        self.clear.clear()

    def add(self, label, group, center, size, degrees=0.0, y0=0.0, y1=None, structure=False):
        x, z = center[0], center[2]
        hx, hz = size[0] / 2, size[2] / 2
        c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
        # Même rotation que rotation_y : l'axe x du modèle devient (c, -s), son axe z (s, c).
        corners = [(x + c * u + s * v, z - s * u + c * v) for u, v in ((-hx, -hz), (hx, -hz), (hx, hz), (-hx, hz))]
        top = y1 if y1 is not None else y0 + size[1]
        self.solids.append((label, group, corners, y0, top, structure))

    def keep_clear(self, label, x0, x1, z0, z1, y0=0.05, y1=2.0):
        corners = [(x0, z0), (x1, z0), (x1, z1), (x0, z1)]
        self.clear.append((label, corners, y0, y1))

    @staticmethod
    def _overlap(a, b, margin=0.05):
        for shape in (a, b):
            for i in range(4):
                (x0, z0), (x1, z1) = shape[i], shape[(i + 1) % 4]
                axis = (z0 - z1, x1 - x0)
                length = math.hypot(*axis) or 1.0
                axis = (axis[0] / length, axis[1] / length)
                pa = [p[0] * axis[0] + p[1] * axis[1] for p in a]
                pb = [p[0] * axis[0] + p[1] * axis[1] for p in b]
                if max(pa) - margin <= min(pb) or max(pb) - margin <= min(pa):
                    return False
        return True

    @staticmethod
    def _where(corners):
        return "(%.1f, %.1f)" % (sum(p[0] for p in corners) / 4, sum(p[1] for p in corners) / 4)

    def report(self, title):
        problems = []
        items = self.solids
        for i, (label, group, corners, y0, y1, structure) in enumerate(items):
            for other in items[i + 1:]:
                if structure and other[5]:
                    continue
                if group and group == other[1]:
                    continue
                if y0 >= other[4] - 0.03 or other[3] >= y1 - 0.03:
                    continue
                if self._overlap(corners, other[2]):
                    problems.append(f"{title} : {label} {self._where(corners)} traverse {other[0]} {self._where(other[2])}")
            for zone, zone_corners, zy0, zy1 in self.clear:
                if structure or y1 <= zy0 or y0 >= zy1:
                    continue
                if self._overlap(corners, zone_corners, margin=0.0):
                    problems.append(f"{title} : {label} {self._where(corners)} sur le passage « {zone} »")
        return problems


LAYOUT = Layout()


def rotated_box(model, degrees, scale, tilt, roll):
    """Boîte du modèle après inclinaison, dans le repère tourné de degrees : (min, max) par axe."""
    (px, py, pz), (sx, sy, sz) = MODEL_BOXES[model]
    axes = scale if isinstance(scale, tuple) else (scale, scale, scale)
    basis = multiply(rotation_x(tilt), rotation_z(roll))
    corners = []
    for cx in (px, px + sx):
        for cy in (py, py + sy):
            for cz in (pz, pz + sz):
                local = (cx * axes[0], cy * axes[1], cz * axes[2])
                corners.append([sum(basis[r][i] * local[i] for i in range(3)) for r in range(3)])
    low = [min(c[i] for c in corners) for i in range(3)]
    high = [max(c[i] for c in corners) for i in range(3)]
    return low, high


def put(scene, model, center, degrees=0.0, scale=1.0, height=None, tilt=0.0, roll=0.0):
    """Comme furniture(), avec une échelle par axe, et une collision tournée avec le modèle même quand il est couché
    (furniture() lui donne alors la boîte droite qui l'englobe, plus large que lui)."""
    low, high = rotated_box(model, degrees, scale, tilt, roll)
    middle = [(low[i] + high[i]) / 2 for i in range(3)]
    rotation = rotation_y(degrees)
    shift = [sum(rotation[r][i] * middle[i] for i in range(3)) for r in range(3)]
    origin = (center[0] - shift[0], center[1] - low[1], center[2] - shift[2])
    scene.add(model, origin, degrees, scale, tilt=tilt, roll=roll)
    if height:
        size = [high[i] - low[i] for i in range(3)]
        if tilt or roll:
            height = size[1]
        scene.add_box((center[0], center[1] + height / 2, center[2]), (size[0], height, size[2]), degrees)


def place(scene, model, center, degrees=0.0, scale=2.6, height=None, tilt=0.0, roll=0.0, group=None, label=None):
    """Pose un meuble au sol par sa boîte et note son emprise ; une hauteur lui donne sa collision."""
    if isinstance(scale, tuple) or ((tilt or roll) and round(degrees) % 90):
        put(scene, model, center, degrees, scale, height=height, tilt=tilt, roll=roll)
    else:
        furniture(scene, model, center, degrees, scale, height=height, tilt=tilt, roll=roll)
    if height:
        low, high = rotated_box(model, degrees, scale, tilt, roll)
        size = (high[0] - low[0], high[1] - low[1], high[2] - low[2])
        top = center[1] + (size[1] if (tilt or roll) else height)
        LAYOUT.add(label or model.rsplit("/", 1)[-1], group, center, size, degrees, center[1], top)


def decor(scene, model, position, degrees=0.0, scale=1.0, tilt=0.0, roll=0.0):
    """Pose un modèle sans collision, par son origine : petits objets, posés sur un meuble ou couchés au sol."""
    scene.add(model, position, degrees, scale, tilt=tilt, roll=roll)


def lay(scene, model, center, degrees=0.0, scale=1.0, tilt=0.0, roll=0.0):
    """Pose un petit objet sans collision par le bas de sa boîte : il touche le support à la hauteur donnée."""
    put(scene, model, center, degrees, scale, tilt=tilt, roll=roll)


def block(scene, center, size, degrees=0.0, group=None, label="bloc", structure=False):
    scene.add_box(center, size, degrees)
    LAYOUT.add(label, group, (center[0], 0, center[2]), size, degrees, center[1] - size[1] / 2,
               center[1] + size[1] / 2, structure)


def add_tilted_box(scene, center, size, roll):
    """Collision inclinée autour de l'axe z (une rampe qui monte selon x) : Scene.add_box ne tourne que selon y."""
    scene.colliders.append((transform_text(rotation_z(roll), center), scene._box_id(size)))


def shaft(scene, position, degrees, scale, lean, half, width=0.14, label="hampe"):
    """Collision d'une hampe fichée de biais dans le sol (une flèche) : une boîte tournée comme elle, du point où elle
    sort du sol à sa pointe haute, aussi haute qu'elle. Sans elle, on passait au travers des flèches de la rue."""
    basis = basis_of(degrees, lean)
    # Le bout haut du modèle est son bout -z : sa direction une fois tourné et incliné.
    up = [-basis[r][2] for r in range(3)]
    top = half * scale
    ground = -position[1] / up[1]
    mid = (ground + top) / 2
    center = (position[0] + up[0] * mid, position[2] + up[2] * mid)
    height = position[1] + up[1] * top
    length = (top - ground) * math.hypot(up[0], up[2]) + width
    scene.add_box((center[0], height / 2, center[1]), (width, height, length), degrees)
    LAYOUT.add(label, None, (center[0], 0, center[1]), (width, height, length), degrees, 0.0, height)


def post(scene, x, z, radius, height, y=0.0, group=None, label="poteau"):
    """Collision cylindrique d'un poteau, d'un tonneau ou d'un tronc."""
    if hasattr(scene, "add_cylinder"):
        scene.add_cylinder((x, y + height / 2, z), radius, height)
    else:
        scene.add_box((x, y + height / 2, z), (radius * 1.6, height, radius * 1.6))
    LAYOUT.add(label, group, (x, 0, z), (radius * 1.6, height, radius * 1.6), 0.0, y, y + height)


def vwall(scene, kit_model, center, outward, height=WALL_HEIGHT, base=0.0, solid=True, group=None):
    wall(scene, kit_model, center, outward, height=height, base=base, solid=solid)
    if solid:
        size = (WALL_THICKNESS, height, WALL_SCALE) if outward[0] else (WALL_SCALE, height, WALL_THICKNESS)
        LAYOUT.add(kit_model, group, (center[0], 0, center[1]), size, 0.0, base, base + height, structure=True)


def vdoorway(scene, center, outward, group=None, keep=2.2):
    """Mur à porte voûtée, avec ses montants notés, et le passage devant et derrière la porte gardé libre."""
    doorway(scene, center, outward)
    # doorway() laisse ±0,95 m sur toute la hauteur, l'arche visible ±0,80 m puis sa pointe : sans ce complément, on
    # frôlait un mur invisible le long de l'arche.
    arch_fill(scene, center, outward)
    x, z = center
    side = (WALL_SCALE - 1.9) / 2
    offset = (WALL_SCALE + 1.9) / 4
    for sign in (-1, 1):
        if outward[0]:
            LAYOUT.add("montant", group, (x, 0, z + sign * offset), (WALL_THICKNESS, WALL_HEIGHT, side), structure=True)
        else:
            LAYOUT.add("montant", group, (x + sign * offset, 0, z), (side, WALL_HEIGHT, WALL_THICKNESS), structure=True)
    if outward[0]:
        LAYOUT.keep_clear(f"porte ({x:g}, {z:g})", x - keep, x + keep, z - 0.9, z + 0.9)
    else:
        LAYOUT.keep_clear(f"porte ({x:g}, {z:g})", x - 0.9, x + 0.9, z - keep, z + keep)


# --- Formes simples -------------------------------------------------------------------------------------------------

def materials(scene):
    scene.material("soot", (0.15, 0.125, 0.105), 1.0)
    scene.material("ash", (0.27, 0.24, 0.21), 1.0)
    scene.material("char", (0.1, 0.075, 0.06), 1.0)
    # Planches brûlées : les grands pans (plancher qui pend, toit effondré) restent lisibles comme du bois, vus d'en
    # dessous dans l'ombre ; en charbon pur, ils faisaient des trous noirs dans l'image.
    scene.material("char_wood", (0.27, 0.18, 0.12), 1.0)
    scene.material("ember", (0.35, 0.08, 0.02), 0.8, emission=(1.0, 0.32, 0.06), energy=2.2)
    scene.material("stone", (0.42, 0.4, 0.38), 1.0)
    scene.material("stone_dark", (0.3, 0.29, 0.29), 1.0)
    scene.material("brick", (0.5, 0.27, 0.18), 0.95)
    scene.material("wood", (0.42, 0.28, 0.17), 0.9)
    scene.material("wood_dark", (0.26, 0.17, 0.1), 0.9)
    scene.material("rope", (0.55, 0.47, 0.33), 1.0)
    scene.material("iron", (0.2, 0.2, 0.22), 0.5, metallic=0.6)
    scene.material("water", (0.08, 0.13, 0.16), 0.15)
    scene.material("flour", (0.86, 0.83, 0.76), 1.0)
    scene.material("burlap", (0.62, 0.5, 0.32), 1.0)
    scene.material("straw", (0.78, 0.65, 0.33), 1.0)
    scene.material("crow", (0.05, 0.05, 0.07), 0.6)
    scene.material("beak", (0.16, 0.15, 0.14), 0.6)
    scene.material("cat_grey", (0.36, 0.35, 0.36), 1.0)
    scene.material("cat_ginger", (0.72, 0.42, 0.18), 1.0)
    scene.material("cat_black", (0.07, 0.07, 0.08), 0.9)
    scene.material("eye", (0.6, 0.55, 0.12), 0.4, emission=(0.4, 0.36, 0.05), energy=0.6)
    for name, color in (("linen", (0.86, 0.83, 0.74)), ("linen_blue", (0.45, 0.55, 0.68)),
                        ("linen_red", (0.62, 0.28, 0.22)), ("linen_green", (0.4, 0.5, 0.33)),
                        ("linen_burnt", (0.25, 0.2, 0.16))):
        scene.material(name, color, 1.0)
    scene.material("herb", (0.32, 0.42, 0.2), 1.0)
    scene.material("herb_dry", (0.48, 0.45, 0.24), 1.0)
    scene.material("parchment", (0.86, 0.78, 0.6), 1.0)
    scene.material("leather", (0.36, 0.2, 0.11), 0.8)
    scene.material("cloth_red", (0.55, 0.12, 0.1), 1.0)


def box(scene, material, center, size, degrees=0.0, tilt=0.0, roll=0.0):
    if not hasattr(scene, "shape"):
        return
    scene.shape(scene.mesh("BoxMesh", size=tuple(size)), material, center, degrees, tilt, roll)


def cylinder(scene, material, center, radius, height, top=None, degrees=0.0, tilt=0.0, roll=0.0, sides=12):
    if not hasattr(scene, "shape"):
        return
    mesh = scene.mesh("CylinderMesh", top_radius=float(radius if top is None else top), bottom_radius=float(radius),
                      height=float(height), radial_segments=sides, rings=1)
    scene.shape(mesh, material, center, degrees, tilt, roll)


def sphere(scene, material, center, radius, scale=(1.0, 1.0, 1.0), degrees=0.0, tilt=0.0, hemisphere=False):
    if not hasattr(scene, "shape"):
        return
    mesh = scene.mesh("SphereMesh", radius=float(radius), height=float(radius if hemisphere else radius * 2),
                      radial_segments=10, rings=5, is_hemisphere=hemisphere)
    scene.shape(mesh, material, center, degrees, tilt, 0.0, scale)


def torus(scene, material, center, inner, outer, degrees=0.0, tilt=0.0):
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


def scorch(scene, x, z, radius, y=0.012, degrees=0.0):
    """Trace de brûlure au sol, sans collision : des taches de suie qui se chevauchent sur un halo de cendre, pour
    un contour irrégulier plutôt qu'un disque."""
    seed = random.Random(round(x * 73.0 + z * 31.0))
    cylinder(scene, "ash", (x, y, z), radius * 1.2, 0.01, degrees=degrees, sides=14)
    for index in range(3):
        angle = math.radians(index * 120.0 + seed.uniform(-30, 30))
        offset = radius * seed.uniform(0.15, 0.35)
        cylinder(scene, "soot", (x + math.cos(angle) * offset, y + 0.004 + index * 0.002, z + math.sin(angle) * offset),
                 radius * seed.uniform(0.55, 0.75), 0.01, degrees=seed.uniform(0, 360), sides=11)


def charred_beam(scene, center, length, degrees, tilt=0.0, roll=0.0, solid=True, group=None):
    """Poutre calcinée : un madrier noirci, posé en travers."""
    box(scene, "char", center, (0.26, 0.26, length), degrees, tilt, roll)
    if solid:
        block(scene, (center[0], 0.15, center[2]), (0.3, 0.3, length * math.cos(math.radians(tilt))), degrees,
              group=group, label="poutre")


def crow(scene, x, y, z, degrees, pecking=False):
    """Corbeau : un corps, une tête, un bec, une queue et deux pattes. Il regarde vers +Z tourné de degrees."""
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))

    def at(u, h, v):
        return (x + c * u + s * v, y + h, z - s * u + c * v)
    lean = 35.0 if pecking else 0.0
    sphere(scene, "crow", at(0, 0.13, 0), 0.08, (1.0, 0.85, 1.7), degrees, tilt=lean)
    head = (0.0, 0.07, 0.17) if pecking else (0.0, 0.21, 0.13)
    sphere(scene, "crow", at(*head), 0.055, (1.0, 1.0, 1.1), degrees)
    beak = (head[0], head[1] - (0.03 if pecking else 0.0), head[2] + 0.07)
    cylinder(scene, "beak", at(*beak), 0.018, 0.07, top=0.0, degrees=degrees, tilt=90.0 + (25.0 if pecking else 0.0), sides=5)
    box(scene, "crow", at(0, 0.16 + (0.05 if pecking else 0.0), -0.17), (0.09, 0.015, 0.14), degrees,
        tilt=-20.0 if not pecking else -35.0)
    for side in (-0.03, 0.03):
        box(scene, "beak", at(side, 0.03, 0.0), (0.012, 0.06, 0.012), degrees)


def cat(scene, x, y, z, degrees, coat, lying=False):
    """Chat assis (ou couché en rond) : corps, tête, oreilles, queue. Il regarde vers +Z tourné de degrees."""
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))

    def at(u, h, v):
        return (x + c * u + s * v, y + h, z - s * u + c * v)
    if lying:
        sphere(scene, coat, at(0, 0.09, 0), 0.13, (1.25, 0.7, 1.0), degrees)
        sphere(scene, coat, at(0.12, 0.1, 0.09), 0.075, (1.0, 0.9, 1.0), degrees)
        for side in (0.08, 0.16):
            cylinder(scene, coat, at(side, 0.19, 0.09), 0.022, 0.05, top=0.0, degrees=degrees, sides=4)
        box(scene, coat, at(-0.05, 0.05, 0.15), (0.26, 0.05, 0.05), degrees + 20.0)
        return
    sphere(scene, coat, at(0, 0.16, 0), 0.11, (1.0, 1.35, 1.25), degrees)
    sphere(scene, coat, at(0, 0.36, 0.05), 0.08, (1.0, 0.92, 1.0), degrees)
    for side in (-0.045, 0.045):
        cylinder(scene, coat, at(side, 0.45, 0.04), 0.025, 0.06, top=0.0, degrees=degrees, sides=4)
        sphere(scene, "eye", at(side * 0.8, 0.375, 0.12), 0.012)
    box(scene, coat, at(0.09, 0.03, -0.08), (0.04, 0.04, 0.24), degrees + 35.0)


def axe_in_block(scene, edge, degrees, scale):
    """Hache fichée dans un billot : le tranchant de son fer (bout -x du haut du modèle) enfoncé au point edge, le
    manche relevé de 30 degrés au-dessus de l'horizontale. Posée par le bas de son manche, elle flottait."""
    roll = 120.0
    basis = basis_of(degrees, 0.0, roll, scale)
    blade = (-0.07, 0.22, 0.0)
    offset = [sum(basis[r][i] * blade[i] for i in range(3)) for r in range(3)]
    scene.add("survival_kit/tool-axe", (edge[0] - offset[0], edge[1] - offset[1], edge[2] - offset[2]), degrees, scale, roll=roll)


def doll(scene, position, degrees):
    """Poupée de chiffon couchée sur le dos : un corps de toile, une robe rouge, une tête et des bras."""
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))

    def at(u, h, v):
        return (position[0] + c * u + s * v, position[1] + h, position[2] - s * u + c * v)
    box(scene, "cloth_red", at(0, 0.04, 0), (0.16, 0.07, 0.24), degrees)
    sphere(scene, "burlap", at(0, 0.05, 0.17), 0.065)
    for side in (-1, 1):
        box(scene, "burlap", at(side * 0.12, 0.035, 0.04), (0.08, 0.04, 0.05), degrees + side * 30.0)
        box(scene, "burlap", at(side * 0.05, 0.03, -0.17), (0.05, 0.04, 0.12), degrees)


def sheet(scene, material, center, width, drop, degrees, sway=0.0):
    """Drap étendu sur une corde : un pan de tissu à peine incliné par le vent."""
    box(scene, material, (center[0], center[1] - drop / 2, center[2]), (width, drop, 0.02), degrees, tilt=sway)


# --- Enceinte ------------------------------------------------------------------------------------------------------

# Côté ouest, la maison du meunier (z de -18 à -10) fait partie de l'enceinte, et la porte de l'ouest (z = 6) laisse
# passer la rue du pont : pas de rempart à ces endroits.
WEST_OPENINGS = (6, -10, -14, -18)
# Côté est, la brèche ouverte par les catapultes de Vibelandia, face au cratère.
EAST_BREACH = (-6,)


def rampart_piece(scene, x, z, model, degrees, box_center, box_size):
    """Pan de rempart posé au plus bas du sol sous lui et rehaussé pour garder son faîte au-dessus du point le plus
    haut : rien ne flotte au bord du ruisseau ni sur la pente de la colline."""
    hx, hz = box_size[0] / 2, box_size[2] / 2
    low, high = ground_span(box_center[0] - hx, box_center[0] + hx, box_center[1] - hz, box_center[1] + hz)
    low = min(low, 0.0) - 0.05
    height = 5.24 + max(high, 0.0) - low
    scene.add(f"castle_kit/{model}", (x, low, z), degrees, (RAMPART, RAMPART * height / 5.24, RAMPART))
    block(scene, (box_center[0], low + height / 2, box_center[1]), (box_size[0], height, box_size[2]),
          label="rempart", structure=True)


def build_rampart(scene, rng):
    """Enceinte : un rempart au sud percé de la porte, et des pans sur les côtés, souvent effondrés."""
    south = 42.0
    for x in range(-30, 31, 4):
        if abs(x) <= 4:
            continue
        rubble = abs(x) in (18, 26) or rng.random() < 0.15
        model = None if rubble else ("wall-narrow" if rng.random() < 0.7 else "wall-half")
        # Les tours de la porte occupent les cases x = ±6.
        if abs(x) <= 6:
            continue
        if rubble:
            scene.add("castle_kit/rocks-large", (x, 0.0, south), rng.uniform(0, 360), 2.6)
            block(scene, (x, 0.65, south), (3.3, 1.3, 3.3), label="éboulis du rempart", structure=True)
            continue
        # Le mur étroit, tourné d'un quart de tour, n'occupe que la moitié extérieure de sa case (z de 42 à 44) : sa
        # collision le suit, sans mur invisible côté village.
        depth = 0.5 * RAMPART if model == "wall-narrow" else RAMPART
        rampart_piece(scene, x, south, model, 90.0, (x, south + (RAMPART - depth) / 2), (RAMPART, 5.2, depth))
    for sign in (-1, 1):
        for z in range(38, -27, -4):
            if rng.random() < 0.35:
                continue
            if (sign < 0 and z in WEST_OPENINGS) or (sign > 0 and z in EAST_BREACH):
                continue
            rampart_piece(scene, sign * 34.0, z, "wall-narrow", 0.0, (sign * 34.0 - 0.25 * RAMPART, z),
                          (0.5 * RAMPART, 5.2, RAMPART))
        # Tours de la porte, avec la porte arrachée couchée devant.
        x = sign * 6.0
        for model, y in (("tower-square-base", 0.0), ("tower-square-mid", 4.0), ("tower-square-top", 8.0)):
            scene.add(f"castle_kit/{model}", (x, y, south), 0.0, RAMPART)
        block(scene, (x, 4.6, south), (4.0, 9.2, 4.0), label="tour de la porte", structure=True)
    furniture(scene, "castle_kit/gate", (2.5, 0.0, south + 5.0), 70.0, 5.0, height=0.8, roll=90.0)
    scene.add("castle_kit/siege-tower-demolished", (-16.0, 0.0, 52.0), 30.0, 4.0)
    scene.add_box((-16.0 + 0.0, 4.2, 52.0 - 0.24), (8.7, 8.4, 7.4), 30.0)
    scene.add("castle_kit/siege-ram-demolished", (14.0, 0.0, 50.0), -20.0, 4.0)
    scene.add_box((14.0, 1.45, 50.0), (8.3, 2.9, 6.6), -20.0)
    # Porte de l'ouest, sur la rue du pont : deux piliers de pierre et le vantail arraché, couché sur la berge.
    for z in (2.9, 9.1):
        scene.add("fantasy_town_kit/pillar-stone", (-34.6, -0.4, z), 0.0, (7.0, 6.4, 7.0))
        block(scene, (-34.6, 1.8, z), (1.2, 4.4, 1.2), label="pilier de la porte de l'ouest", structure=True)
    # Brèche de l'est : les pierres du rempart éboulées vers l'intérieur.
    for x, z, degrees, scale in ((33.0, -6.0, 40.0, 2.2), (30.8, -7.4, 130.0, 1.6), (30.8, -4.4, 250.0, 1.4)):
        scene.add("castle_kit/rocks-large", (x, 0.0, z), degrees, scale)
        block(scene, (x, 0.3 * scale, z), (1.2 * scale, 0.6 * scale, 1.3 * scale), degrees, label="éboulis de la brèche")


# --- Place du marché -----------------------------------------------------------------------------------------------

def build_streets(scene, rng):
    """Place du marché autour de la fontaine : les pavés des rues sont peints par le terrain. Les étals ont été
    renversés, les vivres piétinés ; la statue du roi fondateur tient encore debout au bord du bassin, noircie."""
    scene.add("fantasy_town_kit/fountain-round", (0.0, 0.0, -2.0), 0.0, 3.6)
    # Bassin rond : quatre boîtes tournées épousent mieux le cercle qu'un seul carré.
    for degrees in (0.0, 45.0):
        scene.add_box((0.0, 0.5, -2.0), (6.9, 1.0, 2.9), degrees)
        scene.add_box((0.0, 0.5, -2.0), (2.9, 1.0, 6.9), degrees)
    LAYOUT.add("fontaine", "fontaine", (0.0, 0, -2.0), (6.9, 1.0, 6.9), 0.0, 0.0, 1.0)
    # La colonne brisée de la fontaine, au milieu de l'eau, et la statue du roi fondateur, debout sur son socle :
    # couchée, son socle à gradins se dressait comme une planche plantée de travers.
    add_single(scene, "nature_kit/statue_columnDamaged", (0.0, 0.0, -2.0), 20.0, 3.0)
    place(scene, "mini_arena/statue", (-4.4, 0.0, -6.5), 35.0, 1.7, height=top_of("mini_arena/statue", 1.7),
          label="statue du roi fondateur")
    scorch(scene, -4.6, -6.2, 1.1)
    for x, z, degrees, model in ((-7.0, -9.0, 20.0, "stall-red"), (7.5, -9.5, -15.0, "stall-green"), (8.5, 4.0, 200.0, "stall")):
        place(scene, f"fantasy_town_kit/{model}", (x, 0.0, z), degrees, 3.0, height=1.1 if model == "stall" else 3.6,
              label=f"étal {model}")
    place(scene, "fantasy_town_kit/cart", (-7.9, 0.0, 2.5), 60.0, 3.0, height=2.0, roll=90.0, label="charrette renversée")
    place(scene, "fantasy_town_kit/wheel", (-5.2, 0.0, 3.4), 30.0, 3.0, height=0.7, tilt=90.0, label="roue")
    # Bancs et tabourets des marchands, renversés ; caisses éventrées.
    place(scene, "fantasy_town_kit/stall-bench", (-9.6, 0.0, -4.4), 75.0, 3.0, height=0.7, roll=90.0, label="banc d'étal")
    place(scene, "fantasy_town_kit/stall-stool", (6.4, 0.0, -6.0), 30.0, 2.0, height=0.5, label="tabouret")
    place(scene, "fantasy_town_kit/stall-stool", (9.8, 0.0, 6.4), 0.0, 2.0, height=0.5, tilt=90.0, label="tabouret couché")
    place(scene, "survival_kit/box-open", (-9.7, 0.0, -9.9), 15.0, 2.6, height=0.8, label="caisse de pommes")
    place(scene, "survival_kit/box-large-open", (10.0, 0.0, -8.3), 70.0, 2.6, height=0.8, label="caisse de carottes")
    place(scene, "survival_kit/box", (10.8, 0.0, 1.6), 40.0, 2.4, height=0.6, tilt=90.0, label="caisse renversée")
    place(scene, "food_kit/barrel", (-10.4, 0.0, -8.6), 0.0, 1.4, height=0.95, label="tonneau de l'étal")
    # Vivres répandus : à leur vraie taille, autour des étals et de la charrette.
    for model, x, z, scale in (("apple", -6.0, -6.8, 0.42), ("apple", -5.4, -6.2, 0.42), ("apple", -6.6, -6.0, 0.42),
                               ("apple", -9.0, -10.2, 0.42), ("apple", -8.6, -11.6, 0.42), ("pear", -5.6, -7.4, 0.42),
                               ("carrot", 6.0, -7.4, 0.32), ("carrot", 9.4, -6.0, 0.32), ("carrot", 6.7, -6.9, 0.32),
                               ("bread", 7.2, 6.0, 0.32), ("loaf-round", 7.8, 5.6, 0.42), ("cheese", -4.4, 6.2, 0.55),
                               ("apple", 5.0, 2.8, 0.42), ("cabbage", -8.8, -6.2, 0.6), ("cabbage", 8.2, -6.6, 0.6),
                               ("fish", 9.8, 0.4, 0.5), ("onion", -6.2, 6.9, 0.5), ("leek", 7.0, -12.2, 0.45)):
        lay(scene, f"food_kit/{model}", (x, 0.0, z), rng.uniform(0, 360), scale,
            tilt=90.0 if model in ("carrot", "leek") else 0.0)
    for x, z in ((-8.1, -11.0), (6.7, -11.8), (-3.2, 5.9)):
        lay(scene, "food_kit/plate-broken", (x, 0.0, z), rng.uniform(0, 360), 0.45)
    for x, z in ((-6.8, -4.8), (-6.4, -5.2), (-7.2, -5.0), (5.6, -8.4)):
        lay(scene, "mini_dungeon/coin", (x, 0.0, z), rng.uniform(0, 360), 0.45, tilt=90.0)
    for x, z in ((-2.4, 30.0), (2.4, 20.0), (-2.4, 10.0), (2.4, -14.0), (-10.6, 8.6), (11.0, -12.8), (-11.2, -13.4)):
        scene.add("fantasy_town_kit/lantern", (x, 0.0, z), 0.0, 2.2)
        block(scene, (x, 1.7, z), (0.5, 3.4, 0.5), label="lanterne")
    # Une lanterne fauchée par la charrette, couchée en travers du pavé.
    place(scene, "fantasy_town_kit/lantern", (-11.9, 0.0, 2.9), 100.0, 2.2, height=0.5, tilt=90.0, label="lanterne couchée")
    # Les pierres des catapultes de Vibelandia, tombées sur la place : un cratère noirci et des pavés soulevés.
    crater(scene, rng, -8.6, -1.6, 2.0)


def crater(scene, rng, x, z, radius, ring=True):
    """Impact d'un boulet de catapulte : le sol noirci, le boulet à moitié enfoncé, les pavés soulevés autour."""
    scorch(scene, x, z, radius)
    sphere(scene, "stone_dark", (x + 0.2, 0.25, z - 0.1), 0.55, (1.0, 0.85, 1.05), rng.uniform(0, 360))
    post(scene, x + 0.2, z - 0.1, 0.55, 0.8, label="boulet")
    if not ring:
        return
    for index in range(6):
        angle = math.radians(index * 60.0 + rng.uniform(-12, 12))
        distance = radius * rng.uniform(0.75, 0.95)
        px, pz = x + math.cos(angle) * distance, z + math.sin(angle) * distance
        lay(scene, "mini_arena/bricks" if index % 2 else "graveyard_kit/debris", (px, 0.0, pz), rng.uniform(0, 360),
            0.6 if index % 2 else 1.25)


# --- Maisons --------------------------------------------------------------------------------------------------------

# Maisons : centre (x, z), largeur et profondeur en cases de 4 m, côté de la porte, style et étages.
HOUSES = (
    (-10.0, 30.0, 2, 2, "east", "stone", 1),
    (-10.0, 20.0, 2, 2, "east", "wood", 2),
    (10.0, 30.0, 2, 2, "west", "wood", 1),
    (10.0, 20.0, 2, 2, "west", "stone", 2),
    (-17.0, -6.0, 2, 3, "east", "stone", 2),
    (17.0, -6.0, 2, 3, "west", "wood", 1),
    (-20.0, 14.0, 2, 2, "south", "wood", 1),
    (-28.0, -2.0, 2, 2, "south", "stone", 1),
    (21.0, 12.0, 2, 2, "west", "stone", 1),
    (-12.0, -18.0, 2, 2, "south", "wood", 1),
    # Le tonnelier ouvre vers la place, à l'ouest : au sud, sa porte donnait à 2 m sur le mur nord de l'herboristerie.
    (12.0, -18.0, 2, 2, "west", "stone", 2),
    (-31.0, -14.0, 2, 2, "east", "wood", 1),
)
OUTWARDS = {"north": (0, -1), "south": (0, 1), "east": (1, 0), "west": (-1, 0)}
# Métier de chaque maison : ce qu'on y trouve, et l'enseigne pendue près de sa porte.
TRADES = ("home", "inn", "bakery", "forge", "grocer", "herbalist", "home", "burnt", "guard", "family", "cooper", "miller")
SIGNS = {"inn": "Auberge du Chaudron", "bakery": "Boulangerie", "forge": "Forge", "grocer": "Épicerie",
         "herbalist": "Herboristerie", "guard": "Corps de garde", "cooper": "Tonnelier", "miller": "Moulin"}


def wall_models(style):
    if style == "wood":
        return ("wall-wood", "wall-wood-broken", "wall-wood-window-shutters", "wall-wood-window-small")
    return ("wall", "wall-broken", "wall-window-stone", "wall-window-shutters")


def edge_tiles(cx, cz, width, depth):
    """Renvoie, pour chaque côté, les centres des cases de mur et la direction vers l'extérieur."""
    half_w, half_d = width * TILE / 2, depth * TILE / 2
    for side, (dx, dz) in OUTWARDS.items():
        count = depth if dx else width
        for index in range(count):
            offset = -((count - 1) * TILE) / 2 + index * TILE
            if dx:
                yield side, index, count, (cx + dx * half_w, cz + offset), (dx, dz)
            else:
                yield side, index, count, (cx + offset, cz + dz * half_d), (dx, dz)


class Frame:
    """Repère d'une maison : b vers la porte, a sur le côté. Les meubles s'y placent quelle que soit son orientation.
    Un modèle tourné de frame.yaw(0) a sa face (+Z) vers la porte ; de 90, vers -a ; de -90, vers +a."""

    def __init__(self, number, house):
        cx, cz, width, depth, door_side, style, floors = house
        self.number, self.style, self.floors = number, style, floors
        self.cx, self.cz = cx, cz
        self.f = OUTWARDS[door_side]
        self.r = (-self.f[1], self.f[0])
        half_w, half_d = width * TILE / 2, depth * TILE / 2
        self.depth = half_w if self.f[0] else half_d
        self.side = half_d if self.f[0] else half_w
        door = [center for side, index, count, center, _ in edge_tiles(cx, cz, width, depth)
                if side == door_side and index == count // 2][0]
        self.door = door
        self.door_a = (door[0] - cx) * self.r[0] + (door[1] - cz) * self.r[1]
        self.group = f"maison{number}"
        # Le côté opposé à la porte, où l'on range le plus gros mobilier.
        self.far = -1.0 if self.door_a > 0 else 1.0

    def p(self, a, b, y=0.0):
        return (self.cx + self.r[0] * a + self.f[0] * b, y, self.cz + self.r[1] * a + self.f[1] * b)

    def xz(self, a, b):
        point = self.p(a, b)
        return point[0], point[2]

    def yaw(self, local=0.0):
        return math.degrees(math.atan2(self.f[0], self.f[1])) + local

    def wall_a(self, s, deep):
        """Position a d'un meuble de profondeur deep adossé au mur de côté s (±1), et son orientation vers la pièce."""
        return s * (self.side - 0.9 - deep / 2), 90.0 * s

    def back_b(self, deep):
        """Position b d'un meuble de profondeur deep adossé au mur du fond (sa face regarde la porte)."""
        return -(self.depth - 0.9 - deep / 2)


def build_house(scene, rng, number, house):
    cx, cz, width, depth, door_side, style, floors = house
    frame = Frame(number, house)
    plain, broken, window, window_small = wall_models(style)
    group = frame.group
    for side, index, count, center, outward in edge_tiles(cx, cz, width, depth):
        if side == door_side and index == count // 2:
            vdoorway(scene, center, outward, group=group)
            continue
        roll = rng.random()
        if roll < 0.14:
            scene.add("castle_kit/rocks-small", (center[0], 0.0, center[1]), rng.uniform(0, 360), 1.6)
            block(scene, (center[0], 0.4, center[1]), (1.7, 0.8, 1.7), group=group, label="éboulis", structure=True)
            continue
        if roll < 0.4:
            vwall(scene, broken, center, outward, height=3.0, group=group)
        else:
            vwall(scene, rng.choice((plain, plain, window, window_small)), center, outward, group=group)
        if floors > 1 and roll > 0.55:
            wall(scene, rng.choice(("wall-wood", "wall-wood-broken", "wall-wood-window-shutters")),
                 center, outward, base=WALL_HEIGHT, solid=False)
    half_w, half_d = width * TILE / 2, depth * TILE / 2
    pillar = "fantasy_town_kit/pillar-wood" if style == "wood" else "fantasy_town_kit/pillar-stone"
    for sx in (-1, 1):
        for sz in (-1, 1):
            for floor in range(floors):
                scene.add(pillar, (cx + sx * half_w, floor * WALL_HEIGHT, cz + sz * half_d), 0.0, WALL_SCALE)
            block(scene, (cx + sx * half_w, WALL_HEIGHT * floors / 2, cz + sz * half_d), (0.7, WALL_HEIGHT * floors, 0.7),
                  group=group, label="pilier", structure=True)
    if number == 11:
        # La maison du meunier repose côté ruisseau sur un soubassement de pierre, planté dans la berge.
        box(scene, "stone_dark", (cx - half_w + 0.05, -0.7, cz), (0.7, 1.5, depth * TILE + 0.9))
        block(scene, (cx - half_w + 0.05, -0.7, cz), (0.7, 1.5, depth * TILE + 0.9), group=group, label="soubassement",
              structure=True)
    # Les poutres tombées sont posées avec le mobilier, là où il reste de la place ; les tirages d'origine sont
    # gardés pour que les murs des maisons suivantes ne changent pas.
    for beam in range(rng.randint(1, 3)):
        rng.uniform(0, 1), rng.uniform(0, 1), rng.uniform(0, 180)
    # Plancher arraché par endroits, affleurant le sol.
    for column in range(width):
        for row in range(depth):
            x = cx - (width - 1) * TILE / 2 + column * TILE
            z = cz - (depth - 1) * TILE / 2 + row * TILE
            roll = rng.random()
            if roll < 0.55:
                scene.add("fantasy_town_kit/planks", (x, -0.2, z), rng.choice((0.0, 90.0)), TILE)
            elif roll < 0.85:
                scene.add("fantasy_town_kit/planks-half", (x - TILE * 0.25, -0.2, z), 0.0, TILE)
    TRADE_FURNISHING[TRADES[number]](scene, random.Random(number * 31 + 7), frame)
    if floors > 1:
        upper_floor(scene, frame)


def fp(scene, frame, model, a, b, local=0.0, scale=2.6, height=None, tilt=0.0, roll=0.0, y=0.0, label=None):
    """Meuble posé au sol (ou sur un autre, à la hauteur y) dans le repère de la maison."""
    place(scene, model, frame.p(a, b, y), frame.yaw(local), scale, height=height, tilt=tilt, roll=roll, label=label)


def flat(model, scale, thickness=0.22):
    """Échelle d'une arme ou d'un bouclier couché (tilt 90) : son épaisseur (son axe z, devenu vertical) ramenée sous
    la cheville, pour qu'on l'enjambe sans passer au travers."""
    depth = MODEL_BOXES[model][1][2] if model in MODEL_BOXES else None
    if depth is None or depth * scale <= thickness:
        return scale
    return (scale, scale, thickness / depth)


def fl(scene, frame, model, a, b, local=0.0, scale=1.0, y=0.0, tilt=0.0, roll=0.0):
    """Petit objet sans collision posé dans le repère de la maison, par le bas de sa boîte."""
    lay(scene, model, frame.p(a, b, y), frame.yaw(local), scale, tilt=tilt, roll=roll)


def top_of(model, scale):
    """Hauteur du dessus d'un meuble au-dessus de son pied, d'après sa boîte : posé par furniture() ou put(), le bas
    de la boîte touche le sol."""
    return MODEL_BOXES[model][1][1] * scale


def bed(scene, frame, a, b, local, scale=1.5):
    fp(scene, frame, "furniture_kit/bedSingle", a, b, local, scale, height=0.8, label="lit")


FLOOR = 0.05


def upper_floor(scene, frame):
    """Étage effondré : les solives tiennent encore entre les murs, une partie du plancher pend dans le vide."""
    half = frame.side - 0.4
    for a in (-half * 0.5, half * 0.5):
        box(scene, "wood_dark", frame.p(a, 0.0, WALL_HEIGHT - 0.2), (0.3, 0.3, frame.depth * 2 - 0.55), frame.yaw())
    box(scene, "wood", frame.p(-frame.far * half * 0.5, -frame.depth * 0.45, WALL_HEIGHT - 0.02),
        (frame.side * 0.9, 0.08, frame.depth * 0.8), frame.yaw())
    box(scene, "char_wood", frame.p(frame.far * half * 0.6, -frame.depth * 0.3, WALL_HEIGHT - 0.9),
        (frame.side * 0.5, 0.08, 1.8), frame.yaw(), tilt=35.0)


def home(scene, rng, frame, child=False):
    """Logis pillé : le lit, la table renversée, les chaises, le coffre vidé, la vaisselle brisée."""
    far = frame.far
    bed(scene, frame, far * 2.15, -1.9, 0.0)
    if child:
        # Le petit lit de l'enfant, sa poupée de chiffon oubliée dans la fuite et sa charrette de bois.
        bed(scene, frame, -far * 2.3, -2.2, 0.0, 1.0)
        doll(scene, frame.p(-far * 0.9, -2.9, FLOOR), frame.yaw(200.0))
        fl(scene, frame, "fantasy_town_kit/cart", far * 0.2, 0.2, 50.0, 0.42, y=FLOOR)
    else:
        fp(scene, frame, "mini_dungeon/chair", -far * 2.4, -2.5, 160.0, 2.2, height=1.0, label="chaise")
        fp(scene, frame, "survival_kit/barrel-open", -far * 2.8, -0.6, 0.0, 2.6, height=0.9, label="tonneau")
        fp(scene, frame, "mini_dungeon/pot", -far * 1.2, -3.0, 30.0, 1.1, height=0.47, y=FLOOR, label="marmite")
    fp(scene, frame, "mini_dungeon/table", -far * 0.4, -0.4, 25.0, 2.4, height=0.75, roll=90.0, label="table renversée")
    fp(scene, frame, "mini_dungeon/chair", far * 0.9, 1.0, 0.0, 2.2, height=0.5, tilt=90.0, label="chaise couchée")
    deep = 0.7 * 1.6
    a, local = frame.wall_a(far, deep)
    fp(scene, frame, "mini_dungeon/chest", a, 1.2, local + 90.0, 1.6, height=0.6, label="coffre vidé")
    fl(scene, frame, "furniture_kit/rugRound", -far * 1.9, -1.4, 0.0, 2.0, y=FLOOR)
    for a2, b2 in ((0.7, -1.9), (-0.6, 1.2), (far * 1.5, 2.2)):
        fl(scene, frame, "food_kit/plate-broken", a2, b2, rng.uniform(0, 360), 0.45, y=FLOOR)
    fl(scene, frame, "food_kit/mug", -far * 1.4, 0.9, 80.0, 0.4, y=FLOOR, roll=90.0)
    scorch(scene, *frame.xz(far * 0.4, 0.4), 0.8, y=FLOOR + 0.01)
    charred_beam(scene, frame.p(far * 1.1, 2.5, 0.15), 2.4, frame.yaw(85.0))


def family(scene, rng, frame):
    home(scene, rng, frame, child=True)


def inn(scene, rng, frame):
    """Auberge du Chaudron : tables, tabourets, chopes abandonnées, tonneaux en perce et la grande marmite."""
    far = frame.far
    top = top_of("mini_dungeon/table", 2.2)
    for a, b, local in ((far * 1.3, -0.2, 90.0), (-far * 0.7, -2.3, 0.0)):
        fp(scene, frame, "mini_dungeon/table", a, b, local, 2.2, height=0.68, label="table")
        for da, db in ((-0.4, 0.15), (0.35, -0.2)):
            fl(scene, frame, "food_kit/mug", a + da, b + db, rng.uniform(0, 360), 0.4, y=top)
        fl(scene, frame, "food_kit/plate", a + 0.1, b + 0.3, 0.0, 0.3, y=top)
    fp(scene, frame, "mini_dungeon/table", -far * 0.4, 1.5, 15.0, 2.2, height=0.7, roll=90.0, label="table renversée")
    for a, b, local in ((far * 0.1, -0.2, 90.0), (-far * 0.7, -1.2, 180.0), (far * 2.6, 0.2, -90.0)):
        fp(scene, frame, "mini_dungeon/chair", a, b, local, 2.0, height=0.9, label="tabouret")
    fp(scene, frame, "mini_dungeon/chair", far * 1.6, 1.7, 40.0, 2.0, height=0.5, tilt=90.0, label="tabouret couché")
    deep = 0.68 * 1.35
    a, local = frame.wall_a(-far, deep)
    for b in (-2.5, -1.3):
        fp(scene, frame, "food_kit/barrel", a, b, local, 1.35, height=0.92, label="tonneau en perce")
    fp(scene, frame, "food_kit/barrel", a, 0.3, local, 1.35, height=0.9, roll=90.0, label="tonneau couché")
    fl(scene, frame, "nature_kit/campfire_stones", far * 2.3, -2.4, 0.0, 2.2, y=FLOOR)
    fp(scene, frame, "mini_dungeon/pot", far * 2.3, -2.4, 20.0, 1.4, height=0.6, y=FLOOR, label="marmite")
    for a, b in ((0.3, 2.3), (far * 1.9, 1.6)):
        fl(scene, frame, "food_kit/wine-red", a, b, rng.uniform(0, 360), 0.42, y=FLOOR, tilt=90.0)
    fl(scene, frame, "food_kit/plate-broken", -far * 0.3, -0.2, 40.0, 0.45, y=FLOOR)


def bakery(scene, rng, frame):
    """Boulangerie : le four de briques au fond, le pétrin, les pains du dernier matin, les sacs de farine."""
    far = frame.far
    # Four : un socle de pierre, une voûte de briques, la bouche noire où rougeoient encore des braises.
    b0 = frame.back_b(2.0)
    base = frame.p(far * 1.3, b0)
    block(scene, (base[0], 0.95, base[2]), (2.3, 1.9, 2.0), frame.yaw(), label="four")
    box(scene, "stone", (base[0], 0.55, base[2]), (2.3, 1.1, 2.0), frame.yaw())
    sphere(scene, "brick", (base[0], 1.1, base[2]), 0.95, (1.1, 0.85, 1.0), frame.yaw(), hemisphere=True)
    mouth = frame.p(far * 1.3, b0 + 0.97)
    box(scene, "soot", (mouth[0], 1.4, mouth[2]), (0.65, 0.42, 0.06), frame.yaw())
    box(scene, "ember", (mouth[0], 1.22, mouth[2]), (0.45, 0.05, 0.07), frame.yaw())
    chimney = frame.p(far * 1.3, b0 - 0.55)
    box(scene, "brick", (chimney[0], 2.75, chimney[2]), (0.55, 2.3, 0.5), frame.yaw())
    # Pétrin et pains du dernier matin.
    fp(scene, frame, "mini_dungeon/table", -far * 1.1, -0.6, 90.0, 2.4, height=0.75, label="pétrin")
    top = top_of("mini_dungeon/table", 2.4)
    for model, da, db, scale in (("loaf", -0.3, -0.5, 0.5), ("loaf-round", 0.25, -0.1, 0.42),
                                 ("loaf-baguette", -0.15, 0.45, 0.7), ("croissant", 0.3, 0.6, 0.35),
                                 ("rollingPin", 0.1, -0.85, 0.5)):
        fl(scene, frame, f"food_kit/{model}", -far * 1.1 + da, -0.6 + db, rng.uniform(0, 360), scale, y=top)
    deep = 0.25 * 2.6
    a, local = frame.wall_a(-far, deep)
    fp(scene, frame, "furniture_kit/bookcaseOpen", a, -2.2, local, 2.6, height=2.3, label="étagère à pains")
    for row, y in enumerate((0.06, 0.8, 1.52)):
        fl(scene, frame, "food_kit/loaf", a, -2.2 + (row - 1) * 0.15, local, 0.4, y=y)
    for a2, b2, local2 in ((far * 2.6, 0.7, 0.0), (far * 2.6, 1.5, 30.0), (far * 1.9, 1.1, 70.0)):
        fp(scene, frame, "food_kit/bag", a2, b2, local2, 1.0, height=0.84, label="sac de farine")
    fl(scene, frame, "food_kit/bag-flat", far * 1.2, 1.9, 20.0, 1.0, y=FLOOR)
    cylinder(scene, "flour", frame.p(far * 1.0, 2.2, FLOOR + 0.01), 0.7, 0.01, sides=9)
    for a2, b2 in ((-0.4, 1.3), (0.5, 0.4)):
        fl(scene, frame, "food_kit/bread", a2, b2, rng.uniform(0, 360), 0.32, y=FLOOR)
    # La pelle à enfourner, appuyée contre le four.
    box(scene, "wood", frame.p(-far * 0.05, b0 + 0.4, 0.95), (0.06, 1.9, 0.06), frame.yaw(), roll=-22.0 * far)
    box(scene, "wood", frame.p(-far * 0.4, b0 + 0.4, 0.12), (0.4, 0.04, 0.32), frame.yaw(), roll=-22.0 * far)


def forge(scene, rng, frame):
    """Forge : le foyer et sa hotte, l'enclume, la meule, le baquet de trempe, et le râtelier vidé par les gardes."""
    far = frame.far
    b0 = frame.back_b(1.6)
    hearth = frame.p(far * 1.4, b0)
    block(scene, (hearth[0], 0.45, hearth[2]), (2.2, 0.9, 1.6), frame.yaw(), label="foyer")
    box(scene, "stone_dark", (hearth[0], 0.45, hearth[2]), (2.2, 0.9, 1.6), frame.yaw())
    lay(scene, "graveyard_kit/fire-basket", (hearth[0], 0.9, hearth[2]), frame.yaw(), 2.4)
    box(scene, "ember", (hearth[0], 1.13, hearth[2]), (0.7, 0.05, 0.7), frame.yaw(20.0))
    # La hotte et le conduit sont scellés au mur du fond, au-dessus du foyer.
    hood = frame.p(far * 1.4, -frame.depth + 0.25 + 0.7)
    box(scene, "stone_dark", (hood[0], 2.25, hood[2]), (1.8, 0.7, 1.4), frame.yaw())
    flue = frame.p(far * 1.4, -frame.depth + 0.25 + 0.3)
    box(scene, "stone_dark", (flue[0], 3.3, flue[2]), (0.8, 1.4, 0.6), frame.yaw())
    fp(scene, frame, "survival_kit/workbench-anvil", far * 0.3, -0.2, 20.0, 2.8,
       height=top_of("survival_kit/workbench-anvil", 2.8), label="enclume")
    fl(scene, frame, "survival_kit/tool-hammer", far * 0.3, -0.2, 70.0, 2.2, y=top_of("survival_kit/workbench-anvil", 2.8),
       tilt=90.0)
    fp(scene, frame, "survival_kit/workbench-grind", -far * 1.0, -2.7, 0.0, 2.8, height=0.9, label="meule")
    fp(scene, frame, "survival_kit/barrel-open", far * 2.8, -0.1, 0.0, 2.6, height=0.9, label="baquet de trempe")
    cylinder(scene, "water", frame.p(far * 2.8, -0.1, 0.8), 0.27, 0.02, sides=10)
    deep = 0.45 * 2.4
    a, local = frame.wall_a(-far, deep)
    fp(scene, frame, "mini_arena/weapon-rack", a, -0.6, local, 2.4, height=1.15, label="râtelier")
    fl(scene, frame, "mini_dungeon/weapon-sword", -far * 1.4, 1.0, 60.0, 2.2, y=FLOOR, tilt=90.0)
    fl(scene, frame, "mini_dungeon/shield-round", far * 0.9, 1.6, 0.0, 1.8, y=FLOOR, tilt=90.0)
    for a2, b2 in ((far * 2.5, 1.5), (far * 2.8, 2.1)):
        fl(scene, frame, "survival_kit/resource-stone", a2, b2, rng.uniform(0, 360), 2.4, y=FLOOR)
    fl(scene, frame, "survival_kit/tool-pickaxe", -far * 1.9, -1.4, 10.0, 2.6, y=FLOOR, tilt=90.0)


def grocer(scene, rng, frame):
    """Épicerie : étagères de bocaux, sacs, tonneaux, caisses de légumes et meules de fromage sur le comptoir."""
    far = frame.far
    deep = 0.25 * 2.6
    for s, b in ((-far, -2.2), (-far, -0.6), (far, -2.2)):
        a, local = frame.wall_a(s, deep)
        fp(scene, frame, "furniture_kit/bookcaseOpen", a, b, local, 2.6, height=2.3, label="étagère")
        for row, y in enumerate((0.06, 0.8, 1.52)):
            model, scale = ("food_kit/honey", 0.45) if row % 2 else ("nature_kit/pot_small", 1.1)
            fl(scene, frame, model, a, b + (row - 1) * 0.2, rng.uniform(0, 360), scale, y=y)
    fp(scene, frame, "mini_dungeon/table", far * 0.4, -1.8, 0.0, 2.6, height=0.8, label="comptoir")
    top = top_of("mini_dungeon/table", 2.6)
    for da, db, model, scale in ((-0.6, 0.0, "cheese", 0.55), (0.0, 0.2, "cheese", 0.45), (0.6, -0.1, "whole-ham", 0.55)):
        fl(scene, frame, f"food_kit/{model}", far * 0.4 + da, -1.8 + db, rng.uniform(0, 360), scale, y=top)
    for a, b, local in ((far * 3.0, 1.2, 0.0), (far * 3.6, 1.9, 25.0), (far * 4.2, 1.1, 60.0)):
        fp(scene, frame, "food_kit/bag", a, b, local, 1.0, height=0.84, label="sac")
    fp(scene, frame, "food_kit/barrel", -far * 4.3, 1.6, 0.0, 1.35, height=0.92, label="tonneau")
    fp(scene, frame, "survival_kit/box-large-open", -far * 2.6, 2.3, 90.0, 2.6, height=0.8, label="caisse de légumes")
    fp(scene, frame, "survival_kit/box-open", far * 2.0, 2.6, 30.0, 2.6, height=0.8, tilt=90.0, label="caisse renversée")
    for model, a, b in (("cabbage", far * 1.6, 1.8), ("carrot", far * 2.6, 1.6), ("onion", far * 1.4, 2.6),
                        ("onion", far * 2.8, 2.4), ("apple", -far * 1.6, 0.4), ("leek", -far * 2.6, 1.4)):
        fl(scene, frame, f"food_kit/{model}", a, b, rng.uniform(0, 360), 0.5 if model != "leek" else 0.45, y=FLOOR,
           tilt=90.0 if model in ("carrot", "leek") else 0.0)
    scorch(scene, *frame.xz(-far * 1.4, 1.4), 1.0, y=FLOOR + 0.01)


def herbalist(scene, rng, frame):
    """Herboristerie : fioles, pots de simples, mortier, la marmite des onguents et les bouquets mis à sécher."""
    far = frame.far
    deep = 0.25 * 2.6
    for b in (-2.2, -0.6):
        a, local = frame.wall_a(-far, deep)
        fp(scene, frame, "furniture_kit/bookcaseOpen", a, b, local, 2.6, height=2.3, label="étagère")
        for row, y in enumerate((0.06, 0.8, 1.52)):
            fl(scene, frame, "mini_dungeon/potion", a, b + (row - 1) * 0.25, rng.uniform(0, 360), 0.55, y=y)
    fp(scene, frame, "mini_dungeon/table", far * 0.6, -1.6, 0.0, 2.4, height=0.75, label="table de l'herboriste")
    top = top_of("mini_dungeon/table", 2.4)
    fl(scene, frame, "food_kit/mortar-pestle", far * 0.2, -1.6, 0.0, 0.5, y=top)
    for da in (-0.6, 0.5):
        fl(scene, frame, "mini_dungeon/potion", far * 0.6 + da, -1.5, rng.uniform(0, 360), 0.5, y=top)
    fl(scene, frame, "nature_kit/plant_bushSmall", far * 1.1, -1.8, 0.0, 1.2, y=top)
    fp(scene, frame, "mini_dungeon/pot", far * 4.0, -2.4, 0.0, 1.5, height=0.65, label="marmite")
    fl(scene, frame, "nature_kit/campfire_logs", far * 4.0, -2.4, 0.0, 2.6, y=FLOOR)
    for a, b in ((far * 4.4, 1.0), (far * 3.4, 2.2), (far * 4.4, 2.6)):
        fp(scene, frame, "nature_kit/pot_small", a, b, rng.uniform(0, 360), 1.6, height=0.45, label="pot de simples")
        fl(scene, frame, "nature_kit/plant_bushSmall", a, b, rng.uniform(0, 360), 1.0, y=top_of("nature_kit/pot_small", 1.6) - 0.08)
    # Bouquets d'herbes pendus à une perche, au-dessus de la table.
    perch = frame.p(far * 0.6, -1.6, 2.6)
    box(scene, "wood_dark", perch, (3.0, 0.08, 0.08), frame.yaw())
    for da in (-1.1, -0.5, 0.1, 0.7, 1.2):
        box(scene, "herb" if da < 0.5 else "herb_dry", frame.p(far * 0.6 + da, -1.6, 2.33), (0.14, 0.45, 0.12), frame.yaw(),
            tilt=8.0)
    for a, b in ((-far * 1.0, 1.0), (far * 2.0, 2.0)):
        fl(scene, frame, "survival_kit/bottle", a, b, rng.uniform(0, 360), 2.4, y=FLOOR, tilt=90.0)


def cooper(scene, rng, frame):
    """Tonnellerie : des tonneaux montés ou en pièces, les douelles, les cercles de fer et l'établi."""
    far = frame.far
    for a, b in ((far * 2.4, -2.4), (far * 1.3, -2.45), (far * 2.45, -1.2)):
        fp(scene, frame, "mini_dungeon/barrel", a, b, rng.uniform(0, 360), 1.8, height=0.86, label="tonneau")
    fp(scene, frame, "mini_dungeon/barrel", far * 2.0, -2.0, 0.0, 1.5, height=0.72, y=0.86, label="tonneau empilé")
    fp(scene, frame, "survival_kit/workbench", -far * 1.5, -2.4, 0.0, 3.0, height=top_of("survival_kit/workbench", 3.0),
       label="établi")
    fl(scene, frame, "survival_kit/tool-hammer", -far * 1.5, -2.4, 30.0, 2.2, y=top_of("survival_kit/workbench", 3.0),
       tilt=90.0)
    for a, b, local in ((-far * 2.5, 0.2, 0.0), (-far * 2.2, 1.3, 40.0)):
        fl(scene, frame, "survival_kit/resource-planks", a, b, local, 2.6, y=FLOOR)
    for a, b in ((far * 0.6, 0.8), (-far * 0.4, -0.6)):
        torus(scene, "iron", frame.p(a, b, FLOOR + 0.03), 0.36, 0.42, frame.yaw(20.0))
    fp(scene, frame, "survival_kit/barrel-open", far * 0.9, -0.8, 0.0, 2.6, height=0.6, roll=90.0, label="tonneau éventré")


def guard(scene, rng, frame):
    """Corps de garde : paillasses, la table du sergent et sa carte, les boucliers, le râtelier vide."""
    far = frame.far
    for a in (far * 2.6, far * 1.6, far * 0.6):
        fl(scene, frame, "survival_kit/bedroll", a, -2.3, 0.0, 3.0, y=FLOOR)
    fp(scene, frame, "mini_dungeon/table", -far * 1.4, -0.6, 0.0, 2.2, height=0.68, label="table du sergent")
    top = top_of("mini_dungeon/table", 2.2)
    box(scene, "parchment", frame.p(-far * 1.4, -0.6, top + 0.01), (0.7, 0.01, 0.5), frame.yaw(12.0))
    lay(scene, "graveyard_kit/candle", frame.p(-far * 0.9, -0.9, top), 0.0, 0.8)
    fp(scene, frame, "mini_dungeon/chair", -far * 1.4, 0.6, 180.0, 2.0, height=0.9, label="tabouret")
    deep = 0.45 * 2.4
    a, local = frame.wall_a(-far, deep)
    fp(scene, frame, "mini_arena/weapon-rack", a, -2.4, local, 2.4, height=1.15, label="râtelier vide")
    for a2, b2 in ((far * 2.4, 0.6), (far * 1.4, 1.5)):
        fl(scene, frame, "mini_dungeon/shield-rectangle", a2, b2, rng.uniform(0, 360), flat("mini_dungeon/shield-rectangle", 2.6),
           y=FLOOR, tilt=90.0)
    fl(scene, frame, "mini_dungeon/weapon-spear", -far * 0.4, 1.7, 70.0, flat("mini_dungeon/weapon-spear", 3.2), y=FLOOR, tilt=90.0)
    a, local = frame.wall_a(far, 1.12)
    fp(scene, frame, "mini_dungeon/chest", a, 0.6, local + 90.0, 1.6, height=0.6, label="coffre")


def miller(scene, rng, frame):
    """Maison du meunier : les meules de pierre, la trémie, les sacs de farine prêts à partir."""
    far = frame.far
    x, z = frame.xz(-far * 1.2, -1.2)
    for y, radius in ((0.25, 1.0), (0.72, 0.95)):
        cylinder(scene, "stone", (x, y, z), radius, 0.45, sides=14)
    post(scene, x, z, 1.0, 1.85, label="meules et trémie")
    box(scene, "wood", (x, 1.4, z), (0.9, 0.9, 0.9), frame.yaw(45.0))
    for a, b, local in ((far * 2.6, -2.6, 0.0), (far * 1.9, -2.7, 40.0), (far * 2.6, -1.8, 80.0), (far * 2.6, 0.4, 10.0)):
        fp(scene, frame, "food_kit/bag", a, b, local, 1.05, height=0.88, label="sac de farine")
    fl(scene, frame, "food_kit/bag-flat", far * 1.3, -0.5, 70.0, 1.0, y=FLOOR)
    cylinder(scene, "flour", frame.p(far * 1.1, -0.1, FLOOR + 0.01), 0.8, 0.01, sides=9)
    fp(scene, frame, "survival_kit/barrel-open", -far * 2.7, 1.4, 0.0, 2.6, height=0.9, label="tonneau")


def burnt(scene, rng, frame):
    """Maison brûlée de fond en comble : il n'en reste que des poutres noires et un lit de cendres."""
    far = frame.far
    scorch(scene, frame.cx, frame.cz, 2.6, y=FLOOR + 0.01)
    for a, b, local in ((-far * 1.5, -1.8, 30.0), (far * 1.0, -2.4, 100.0)):
        charred_beam(scene, frame.p(a, b, 0.15), 2.6, frame.yaw(local))
    box(scene, "char", frame.p(far * 2.2, -0.4, 1.1), (0.26, 0.26, 3.0), frame.yaw(10.0), tilt=48.0)
    block(scene, frame.p(far * 2.2, -0.4, 0.6), (0.5, 1.2, 2.0), frame.yaw(10.0), label="poutre appuyée")
    for a, b in ((far * 2.4, 2.0), (-far * 2.5, -2.6)):
        fl(scene, frame, "graveyard_kit/debris-wood", a, b, rng.uniform(0, 360), 2.4, y=FLOOR)


TRADE_FURNISHING = {"home": home, "family": family, "inn": inn, "bakery": bakery, "forge": forge, "grocer": grocer,
                    "herbalist": herbalist, "cooper": cooper, "guard": guard, "miller": miller, "burnt": burnt}


def shop_sign(scene, number):
    """Enseigne pendue à sa potence, contre la façade près de la porte, lisible des deux côtés de la rue."""
    trade = TRADES[number]
    if trade not in SIGNS:
        return
    frame = Frame(number, HOUSES[number])
    text = SIGNS[trade]
    width = 1.6 if len(text) > 12 else 1.2
    reach = width / 2 + 0.25
    along = frame.door_a - 2.0 * (1 if frame.door_a > 0 else -1) if abs(frame.door_a) > 0.5 else -2.0
    foot = frame.p(along, frame.depth + 0.42)
    out = frame.f
    # La potence est contre le mur, la planche avance vers la rue : sa face regarde le long de la façade.
    node = (foot[0] + out[0] * reach, 0.0, foot[2] + out[1] * reach)
    degrees = math.degrees(math.atan2(-out[1], out[0]))
    # Le panneau suspendu n'arrête le joueur qu'à son montant (sign_board.gd) : on note seulement son emprise.
    sign(scene, f"Enseigne_{trade}", node, degrees, text=text, mount=2, board_size=(width, 0.55), board_height=2.75,
         line_height=0.16, double_sided=True)
    LAYOUT.add(f"potence {trade}", None, foot, (0.3, 3.4, 0.3), degrees, 0.0, 3.4)


# --- Abords de la porte : la dernière défense des gardes ------------------------------------------------------------

def build_gate_defense(scene, rng):
    """Barricade de charrettes derrière la porte forcée, armes et boucliers des gardes, flèches de Vibelandia."""
    place(scene, "fantasy_town_kit/cart-high", (-6.2, 0.0, 37.5), 90.0, 2.6, height=1.7, roll=90.0, label="charrette de la barricade")
    place(scene, "fantasy_town_kit/cart", (6.0, 0.0, 37.2), 75.0, 2.8, height=1.5, roll=90.0, label="charrette de la barricade")
    place(scene, "fantasy_town_kit/wheel", (8.6, 0.0, 35.6), 10.0, 2.6, height=0.6, tilt=90.0, label="roue arrachée")
    for x, z in ((-3.5, 38.9), (3.6, 39.1)):
        place(scene, "mini_dungeon/barrel", (x, 0.0, z), rng.uniform(0, 360), 2.2, height=1.05, label="tonneau de la barricade")
    place(scene, "mini_dungeon/barrel", (-9.4, 0.0, 36.0), 30.0, 2.2, height=1.1, roll=90.0, label="tonneau couché")
    place(scene, "survival_kit/box-large", (-9.6, 0.0, 38.4), 15.0, 3.2, height=0.8, label="caisse")
    place(scene, "survival_kit/box-large", (-9.8, 0.8, 38.4), 105.0, 2.6, height=0.65, label="caisse empilée")
    # Pieux plantés face à la porte.
    for x, z, degrees in ((-12.6, 38.2, 10.0), (-14.6, 37.9, -12.0), (9.4, 39.2, -8.0), (14.8, 38.7, 14.0)):
        place(scene, "survival_kit/fence-fortified", (x, 0.0, z), degrees, 3.0, height=1.5, label="pieux")
    # Le râtelier des gardes, contre le rempart, et leurs armes abandonnées.
    place(scene, "mini_arena/weapon-rack", (-17.6, 0.0, 39.1), 180.0, 2.4, height=1.15, label="râtelier des gardes")
    for model, x, z, degrees, scale in (("mini_dungeon/weapon-spear", -4.4, 35.9, 70.0, 3.2), ("mini_dungeon/weapon-spear", 4.2, 34.6, 120.0, 3.2),
                                        ("mini_dungeon/weapon-sword", -7.6, 35.4, 30.0, 2.2), ("mini_dungeon/weapon-sword", 9.6, 37.4, 160.0, 2.2),
                                        ("mini_arena/weapon-spear", -15.6, 38.6, 95.0, 3.0)):
        lay(scene, model, (x, 0.0, z), degrees, flat(model, scale), tilt=90.0)
    for model, x, z, scale in (("mini_dungeon/shield-round", -5.2, 34.9, 1.9), ("mini_dungeon/shield-rectangle", 7.4, 34.9, 2.8),
                               ("mini_dungeon/shield-round", -11.4, 36.6, 1.9), ("mini_dungeon/shield-rectangle", 3.4, 35.8, 2.8)):
        lay(scene, model, (x, 0.0, z), rng.uniform(0, 360), flat(model, scale), tilt=90.0)
    # Bannière de Codia arrachée, couchée au pied de la tour.
    lay(scene, "castle_kit/flag-banner-long", (-11.5, 0.0, 35.0), 0.0, 1.4, roll=90.0)
    # Flèches de Vibelandia fichées dans le sol et dans les charrettes.
    for x, z, degrees, lean in ((-3.3, 33.0, 20.0, 35.0), (3.1, 31.4, 200.0, 40.0), (-4.2, 27.2, 150.0, 30.0),
                                (3.4, 41.2, 10.0, 45.0), (-2.4, 44.0, 0.0, 50.0), (5.0, 36.1, 260.0, 30.0)):
        decor(scene, "mini_forest/weapon-arrow", (x, 0.12, z), degrees, 3.0, tilt=lean)
        shaft(scene, (x, 0.12, z), degrees, 3.0, lean, 0.23, label="flèche fichée")
    place(scene, "fantasy_town_kit/lantern", (-3.3, 0.0, 27.4), 0.0, 2.2, height=0.5, tilt=90.0, label="lanterne fauchée")
    # Autour du mémorial des gardes (posé dans village.tscn, en (12, 37,5)) : leurs lances plantées, leurs boucliers
    # appuyés au socle, des bougies et des fleurs déposées par les survivants.
    for z in (36.0, 39.0):
        scene.add("mini_dungeon/weapon-spear", (12.6, 0.0, z), 0.0, 3.2)
        post(scene, 12.6, z, 0.09, 1.9, label="lance du mémorial")
    for z, degrees in ((36.8, -80.0), (38.2, -100.0)):
        decor(scene, "mini_dungeon/shield-round", (11.75, 0.42, z), degrees, 1.9, tilt=-12.0)
    for z in (37.1, 37.9):
        lay(scene, "graveyard_kit/candle", (11.45, 0.0, z), 0.0, 0.8)
    for model, x, z in (("flower_redA", 11.4, 36.5), ("flower_yellowA", 11.3, 38.4), ("flower_redA", 11.5, 38.7)):
        lay(scene, f"nature_kit/{model}", (x, 0.0, z), 0.0, 1.6)
    for x, z, radius in ((1.5, 36.0, 1.0), (-6.0, 35.0, 1.0), (1.6, 44.6, 1.3), (6.6, 34.6, 0.9)):
        scorch(scene, x, z, radius)


# --- Jardins, puits et linge ------------------------------------------------------------------------------------------

def build_gardens(scene, rng):
    """Potagers derrière les maisons de l'ouest : planches de légumes piétinées, épouvantail, puits et linge étendu."""
    rows = (("nature_kit/crops_leafsStageB", 1.0), ("nature_kit/crop_carrot", 0.9), ("nature_kit/crop_turnip", 0.9),
            ("nature_kit/crop_pumpkin", 1.1))
    xs = (-30.2, -28.6, -27.0, -25.4)
    for row, z in enumerate((22.2, 24.4, 26.6, 28.8)):
        model, scale = rows[row]
        for x in xs:
            scene.add("nature_kit/crops_dirtDoubleRow", (x, 0.0, z), 0.0, 1.6)
            for dx in ((-0.4, 0.4) if model != "nature_kit/crop_pumpkin" else (0.0,)):
                for dz in (-0.37, 0.37):
                    if rng.random() < 0.22:
                        continue
                    uprooted = rng.random() < 0.15
                    lay(scene, model, (x + dx, 0.04, z + dz), rng.uniform(0, 360), scale, tilt=80.0 if uprooted else 0.0)
    # Clôture du potager, avec sa barrière ouverte à l'est et des pans renversés.
    fence = "nature_kit/fence_simple"
    for x in (-30.6, -28.6, -26.6, -24.6):
        for z, broken in ((30.3, x == -28.6), (20.7, x == -26.6)):
            if broken:
                lay(scene, fence, (x, 0.0, z + 0.4), 8.0, 2.0, tilt=85.0)
                continue
            place(scene, fence, (x, 0.0, z), 0.0, 2.0, height=0.7, label="clôture")
    for z in (21.7, 23.7, 25.7, 27.7, 29.55):
        place(scene, fence, (-31.7, 0.0, z), 90.0, 2.0 if z != 29.55 else (1.5, 2.0, 2.0), height=0.7, label="clôture")
        if z in (23.7, 25.7):
            continue
        place(scene, fence, (-23.5, 0.0, z), 90.0, 2.0 if z != 29.55 else (1.5, 2.0, 2.0), height=0.7, label="clôture")
    # Épouvantail : un poteau, des bras, une tête de toile et un chapeau, et un corbeau sur son bras.
    sx, sz = -27.8, 25.5
    box(scene, "wood_dark", (sx, 0.95, sz), (0.1, 1.9, 0.1))
    box(scene, "wood_dark", (sx, 1.45, sz), (1.4, 0.08, 0.08))
    box(scene, "burlap", (sx, 1.25, sz), (0.5, 0.6, 0.22))
    box(scene, "linen_red", (sx, 1.47, sz), (1.1, 0.16, 0.24))
    sphere(scene, "burlap", (sx, 1.78, sz), 0.16)
    cylinder(scene, "straw", (sx, 1.97, sz), 0.26, 0.03, sides=10)
    cylinder(scene, "straw", (sx, 2.07, sz), 0.13, 0.2, top=0.05, sides=8)
    # Ses bras et son corps de paille sont à hauteur de poitrine : on s'y heurte, on ne passe pas au travers.
    block(scene, (sx, 1.0, sz), (1.45, 2.0, 0.3), label="épouvantail")
    # Le second potager a brûlé : quelques tiges de maïs noircies dans des sillons gris.
    for z in (32.6, 34.2, 35.8, 37.4):
        for x in (-30.2, -28.6, -27.0, -25.4):
            scene.add("nature_kit/crops_dirtRow", (x, 0.0, z), 0.0, 1.6)
            if rng.random() < 0.45:
                lay(scene, "nature_kit/crops_cornStageB", (x + rng.uniform(-0.4, 0.4), 0.03, z), rng.uniform(0, 360), 1.3)
            elif rng.random() < 0.5:
                box(scene, "char", (x + rng.uniform(-0.5, 0.5), 0.3, z), (0.05, 0.6, 0.05), rng.uniform(0, 90), tilt=rng.uniform(-25, 25))
    for x, z, radius in ((-28.6, 34.4, 1.8), (-26.0, 36.6, 1.3), (-30.4, 37.2, 1.0)):
        scorch(scene, x, z, radius, y=0.06)
    # Le puits du quartier.
    wx, wz = -20.0, 29.0
    cylinder(scene, "stone", (wx, 0.45, wz), 0.85, 0.9, top=0.8, sides=14)
    cylinder(scene, "water", (wx, 0.62, wz), 0.62, 0.02, sides=14)
    cylinder(scene, "stone_dark", (wx, 0.92, wz), 0.86, 0.06, sides=14)
    for side in (-0.78, 0.78):
        box(scene, "wood_dark", (wx + side, 1.35, wz), (0.14, 1.9, 0.14))
    cylinder(scene, "wood", (wx, 1.9, wz), 0.06, 1.7, roll=90.0, sides=8)
    for side, lean in ((-0.3, 32.0), (0.3, -32.0)):
        box(scene, "wood", (wx, 2.36, wz + side), (1.95, 0.06, 0.72), tilt=lean)
    box(scene, "rope", (wx + 0.1, 1.55, wz), (0.02, 0.7, 0.02))
    lay(scene, "survival_kit/bucket", (wx + 0.1, 1.0, wz), 0.0, 2.2)
    post(scene, wx, wz, 0.92, 1.0, label="puits")
    cat(scene, wx - 0.45, 0.95, wz - 0.6, 210.0, "cat_grey")
    lay(scene, "survival_kit/bucket", (wx + 1.3, 0.0, wz + 0.6), 40.0, 2.2, roll=90.0)
    # Linge encore étendu entre deux perches ; un drap est tombé, un autre a pris feu.
    line_z = 36.4
    for x in (-21.6, -15.4):
        box(scene, "wood_dark", (x, 1.15, line_z), (0.1, 2.3, 0.1))
        post(scene, x, line_z, 0.1, 2.3, label="perche à linge")
    box(scene, "rope", (-18.5, 2.15, line_z), (6.2, 0.02, 0.02))
    for x, material, width, drop, sway in ((-20.6, "linen", 1.0, 1.1, 4.0), (-19.3, "linen_blue", 0.8, 0.9, -3.0),
                                           (-18.0, "linen_red", 0.9, 1.2, 5.0), (-16.6, "linen_burnt", 0.7, 0.55, 2.0)):
        sheet(scene, material, (x, 2.14, line_z), width, drop, 0.0, sway)
    block(scene, (-18.5, 1.5, line_z), (5.8, 1.2, 0.2), label="linge étendu")
    box(scene, "linen_green", (-17.6, 0.02, line_z + 1.1), (1.0, 0.02, 0.85), 18.0)
    place(scene, "survival_kit/box-open", (-15.9, 0.0, line_z + 1.0), 20.0, 2.2, height=0.65, label="panier à linge")
    # Un second fil, dans la ruelle entre l'épicerie et la maison brûlée.
    for z in (-5.2, -0.8):
        box(scene, "wood_dark", (-22.5, 1.15, z), (0.1, 2.3, 0.1))
        post(scene, -22.5, z, 0.1, 2.3, label="perche à linge")
    box(scene, "rope", (-22.5, 2.1, -3.0), (0.02, 0.02, 4.4))
    for z, material, width, drop in ((-4.2, "linen", 0.9, 1.0), (-3.0, "linen_blue", 0.7, 0.8), (-1.9, "linen_burnt", 0.8, 0.5)):
        sheet(scene, material, (-22.5, 2.09, z), width, drop, 90.0, 3.0)
    # Tas de bois et billot du meunier, poulailler vidé derrière le moulin.
    place(scene, "nature_kit/log_stack", (-22.5, 0.0, -25.0), 90.0, 2.6, height=0.9, label="tas de bois")
    place(scene, "nature_kit/log_stack", (-20.3, 0.0, -25.2), 90.0, 2.6, height=0.9, label="tas de bois")
    place(scene, "nature_kit/stump_old", (-24.4, 0.0, -23.0), 0.0, 2.2, height=0.6, label="billot")
    axe_in_block(scene, (-24.4, top_of("nature_kit/stump_old", 2.2) - 0.06, -23.0), 30.0, 3.0)
    for x, z in ((-23.6, -22.2), (-25.0, -22.0)):
        lay(scene, "nature_kit/log", (x, 0.0, z), rng.uniform(0, 360), 1.6)
    cx, cz = -26.4, -29.0
    box(scene, "wood", (cx, 0.7, cz), (1.8, 1.2, 1.4))
    box(scene, "wood_dark", (cx, 1.42, cz), (2.1, 0.08, 1.7), tilt=12.0)
    box(scene, "soot", (cx + 0.5, 0.45, cz + 0.71), (0.4, 0.5, 0.02))
    box(scene, "wood_dark", (cx + 0.5, 0.25, cz + 1.2), (0.36, 0.04, 1.0), tilt=24.0)
    block(scene, (cx, 0.7, cz), (1.9, 1.4, 1.5), label="poulailler")
    for x, z, degrees in ((-24.6, -27.2, 0.0), (-28.2, -27.2, 0.0), (-24.4, -30.4, 90.0)):
        place(scene, "nature_kit/fence_simpleLow", (x, 0.0, z), degrees, 2.4, height=0.5, label="enclos")
    for x, z in ((-25.6, -27.9), (-25.4, -28.1), (-27.0, -27.6)):
        lay(scene, "food_kit/egg", (x, 0.0, z), rng.uniform(0, 360), 0.4)


# --- Écuries ----------------------------------------------------------------------------------------------------------

def build_stables(scene, rng):
    """Écuries près de la porte : stalles, foin, abreuvoirs, la charrette du foin. Les chevaux ont fui, une moitié du
    toit s'est effondrée en brûlant."""
    x0, x1, z0, z1 = 20.0, 28.0, 24.0, 36.0
    for x in (x0, x1):
        for z in (z0, 28.0, 32.0, z1):
            scene.add("fantasy_town_kit/pillar-wood", (x, 0.0, z), 0.0, (3.0, 4.0, 3.0))
            block(scene, (x, 2.0, z), (0.5, 4.0, 0.5), label="poteau de l'écurie", structure=True)
    for z in (26.0, 30.0, 34.0):
        vwall(scene, "wall-wood", (x1, z), (1, 0), group="écuries")
    for x in (22.0, 26.0):
        vwall(scene, "wall-wood" if x == 26.0 else "wall-wood-broken", (x, z0), (0, -1), height=4.0 if x == 26.0 else 3.0,
              group="écuries")
    vwall(scene, "wall-wood-broken", (26.0, z1), (0, 1), height=3.0, group="écuries")
    # Toit à deux pans, faîte nord-sud ; la moitié sud du pan ouest s'est effondrée.
    slope = math.degrees(math.atan2(1.2, 4.0))
    run = math.hypot(4.0, 1.2) + 0.5
    box(scene, "wood_dark", (26.1, 4.65, 30.0), (run, 0.14, 12.8), roll=-slope)
    box(scene, "wood_dark", (21.9, 4.65, 27.0), (run, 0.14, 6.6), roll=slope)
    box(scene, "wood_dark", (24.0, 5.22, 30.0), (0.3, 0.3, 12.8))
    box(scene, "char_wood", (21.7, 2.1, 34.0), (5.2, 0.14, 3.5), roll=42.0)
    block(scene, (20.6, 0.6, 34.0), (2.2, 1.2, 3.3), label="toit effondré")
    # Le pan lui-même, incliné comme lui : on ne passe plus au travers de sa moitié haute.
    add_tilted_box(scene, (21.7, 2.1, 34.0), (5.2, 0.3, 3.5), 42.0)
    # Poutres tombées du toit, à l'écart de l'entrée de l'écurie.
    for x, z, degrees in ((21.6, 37.6, 85.0), (24.6, 38.4, 100.0)):
        charred_beam(scene, (x, 0.15, z), 2.4, degrees)
    # Stalles : cloisons de planches entre le mur du fond et l'allée.
    for z in (28.0, 32.0):
        place(scene, "nature_kit/fence_planks", (26.25, 0.0, z), 0.0, (2.9, 3.6, 2.0), height=1.26, label="cloison de stalle")
    for z in (25.6, 29.6, 33.6):
        box(scene, "wood", (27.2, 0.3, z + 0.4), (0.6, 0.55, 1.8))
        box(scene, "straw", (27.2, 0.56, z + 0.4), (0.5, 0.04, 1.7))
        block(scene, (27.2, 0.3, z + 0.4), (0.62, 0.6, 1.82), label="mangeoire")
    for x, z, degrees in ((25.6, 25.2, 10.0), (25.4, 30.6, 80.0), (26.0, 34.8, 30.0)):
        place(scene, "graveyard_kit/hay-bale", (x, 0.0, z), degrees, 2.0, height=0.7, label="botte de foin")
    place(scene, "graveyard_kit/hay-bale-bundled", (21.6, 0.0, 24.9), 90.0, 2.0, height=0.76, label="botte de foin")
    place(scene, "fantasy_town_kit/cart-high", (22.6, 0.0, 28.6), 0.0, 2.2, height=1.9, label="charrette à foin")
    lay(scene, "graveyard_kit/hay-bale", (22.6, top_of("fantasy_town_kit/cart-high", 2.2) - 0.4, 28.4), 15.0, 1.8)
    box(scene, "leather", (25.0, 1.32, 28.0), (0.5, 0.12, 0.34))
    for x, z in ((25.0, 31.7), (23.4, 33.0)):
        lay(scene, "survival_kit/bucket", (x, 0.0, z), rng.uniform(0, 360), 2.2)
        post(scene, x, z, 0.17, 0.42, label="seau")
    for x, z in ((24.2, 26.2), (21.4, 30.6), (23.0, 21.0)):
        torus(scene, "iron", (x, 0.02, z), 0.05, 0.08, rng.uniform(0, 360))
    decor(scene, "survival_kit/tool-hoe", (20.45, 0.0, 29.0), 90.0, 5.6, roll=-14.0)
    block(scene, (20.45, 0.65, 29.0), (0.36, 1.3, 0.5), label="houe")
    # Enclos devant les écuries, clôture brisée par les chevaux en fuite.
    fence = "nature_kit/fence_simple"
    for x in (19.2, 21.6, 24.0, 26.4, 28.8):
        if x == 24.0:
            lay(scene, fence, (x, 0.0, 17.9), 5.0, 2.4, tilt=82.0)
            continue
        place(scene, fence, (x, 0.0, 17.6), 0.0, 2.4, height=0.84, label="clôture de l'enclos")
    for z in (19.0, 22.9):
        place(scene, fence, (18.0, 0.0, z), 90.0, 2.4 if z != 22.9 else (1.6, 2.4, 2.4), height=0.84, label="clôture de l'enclos")
        place(scene, fence, (30.0, 0.0, z), 90.0, 2.4 if z != 22.9 else (1.6, 2.4, 2.4), height=0.84, label="clôture de l'enclos")
    box(scene, "wood", (25.0, 0.3, 20.6), (2.0, 0.6, 0.7))
    box(scene, "water", (25.0, 0.58, 20.6), (1.8, 0.02, 0.5))
    block(scene, (25.0, 0.3, 20.6), (2.0, 0.6, 0.7), label="abreuvoir")
    place(scene, "graveyard_kit/hay-bale", (27.6, 0.0, 21.8), 40.0, 1.8, height=0.63, label="botte de foin")


# --- Traces de l'attaque -------------------------------------------------------------------------------------------

def build_battle_scars(scene, rng):
    """La brèche de l'est et son cratère, les traces de brûlure dans les rues, un champ de blé à moitié brûlé."""
    crater(scene, rng, 27.0, -3.5, 3.0)
    place(scene, "fantasy_town_kit/cart", (24.2, 0.0, 2.6), 200.0, 2.8, height=1.5, roll=90.0, label="charrette brûlée")
    for x, z, degrees in ((23.6, -6.4, 20.0), (29.6, 0.2, 110.0), (25.2, -9.4, 75.0)):
        charred_beam(scene, (x, 0.15, z), 2.8, degrees)
    for x, z in ((30.0, -9.2), (24.0, 0.0), (29.8, 2.4)):
        lay(scene, "graveyard_kit/debris", (x, 0.0, z), rng.uniform(0, 360), 1.6)
    for x, z, radius in ((1.7, 26.5, 0.8), (-1.7, 14.6, 0.8), (1.6, -16.5, 0.7), (-15.0, 6.4, 1.4), (-25.0, 5.4, 1.0),
                         (-4.2, 22.0, 0.8), (4.6, 12.0, 1.0), (14.6, 2.4, 1.2), (16.0, 22.0, 0.9), (-13.4, 12.0, 1.0),
                         (0.4, -24.0, 0.8), (-19.0, -12.6, 1.1)):
        scorch(scene, x, z, radius)
    # Champ de blé au pied de la colline du moulin : la moitié est a brûlé sur pied.
    for i, x in enumerate((17.6, 18.7, 19.8, 20.9)):
        for k in range(9):
            z = -21.4 + k * 1.0
            if i >= 2 and (k + i) % 3:
                box(scene, "char", (x + rng.uniform(-0.2, 0.2), 0.12, z), (0.6, 0.24, 0.5), rng.uniform(0, 90))
                continue
            lay(scene, "nature_kit/crops_wheatStageB", (x, 0.0, z), rng.uniform(0, 360), 2.0)
    scorch(scene, 20.6, -17.6, 2.2)
    # Les corbeaux, qui s'envolent quand on approche, sont posés dans village.tscn (village_crow.gd).


def build_wildlife(scene):
    """Les chats restés au village : l'un dort sur une caisse de la rue (le gris du puits est posé avec le puits ; ceux
    qui se promènent sont dans village.tscn, village_cat.gd)."""
    place(scene, "survival_kit/box-large", (4.3, 0.0, 26.6), 0.0, 3.0, height=0.75, label="caisse devant la boulangerie")
    cat(scene, 4.3, 0.75, 26.4, 60.0, "cat_ginger", lying=True)


# --- Mairie : le dernier bâtiment intact ------------------------------------------------------------------------------

def build_town_hall(scene):
    """Hôtel de ville au nord de la place : le seul bâtiment que la guerre a épargné, murs entiers et toit."""
    cx, cz, width, depth = 0.0, -26.0, 3, 3
    for side, index, count, center, outward in edge_tiles(cx, cz, width, depth):
        if side == "south" and index == 1:
            # Porte fermée : on entre par l'interaction, qui mène à l'intérieur, sous la carte.
            vwall(scene, "wall-door", center, outward, group="mairie")
            door_leaf(scene, center, outward, step=True)
        else:
            vwall(scene, "wall-window-shutters" if index != 1 else "wall", center, outward, group="mairie")
        wall(scene, "wall-window-stone" if (side == "south" or index != 1) else "wall-detail-cross",
             center, outward, base=WALL_HEIGHT, solid=False)
    for x in (-6.0, 6.0):
        for z in (cz - 6.0, cz + 6.0):
            for floor in range(2):
                scene.add("fantasy_town_kit/pillar-stone", (x, floor * WALL_HEIGHT, z), 0.0, WALL_SCALE)
            block(scene, (x, WALL_HEIGHT, z), (0.7, WALL_HEIGHT * 2, 0.7), group="mairie", label="pilier", structure=True)
    for x in (-2.6, 2.6):
        scene.add("fantasy_town_kit/banner-red", (x, 4.8, cz + 6.2), -90.0, 3.4)
    # Ses fenêtres luisent dans le soir : une lueur chaude derrière chaque vitre, côté intérieur.
    for side, index, count, center, outward in edge_tiles(cx, cz, width, depth):
        inward = (center[0] - outward[0] * 0.45, center[1] - outward[1] * 0.45)
        size = (0.04, 1.6, 1.4) if outward[0] else (1.4, 1.6, 0.04)
        floors = (1.9, 5.9) if index != 1 else (5.9,) if side == "south" else ()
        for y in floors:
            box(scene, "window_glow", (inward[0], y, inward[1]), size)
    # Toit à deux pans, pignon sur la place, et sa cheminée.
    top = WALL_HEIGHT * 2
    prism(scene, "plaster", (cx, top + 1.7, cz), (12.4, 3.4, 12.4))
    slope = math.degrees(math.atan2(3.4, 6.2))
    run = math.hypot(6.2, 3.4) + 0.6
    for side in (-1, 1):
        offset = (run / 2 - 0.3) * math.cos(math.radians(slope))
        box(scene, "roof", (cx + side * (offset - 0.05), top + 1.7 + 0.12, cz), (run, 0.2, 13.2), roll=-side * slope)
    box(scene, "roof", (cx, top + 3.45, cz), (0.4, 0.3, 13.3))
    box(scene, "brick", (cx + 3.2, top + 2.6, cz - 3.0), (0.8, 2.6, 0.8))
    # Lanternes de part et d'autre de la porte.
    for x in (-2.3, 2.3):
        scene.add("fantasy_town_kit/lantern", (x, 0.0, cz + 6.7), 0.0, 1.7)
        block(scene, (x, 1.3, cz + 6.7), (0.4, 2.6, 0.4), label="lanterne de la mairie")
    LAYOUT.keep_clear("porte de la mairie", -1.5, 1.5, cz + 6.3, cz + 10.0)
    sign(scene, "Enseigne_mairie", (cx, 3.45, cz + 6.26), 0.0, text="Mairie", style=1, mount=1,
         board_size=(3.0, 0.62), board_height=0.0, line_height=0.32, collision=False)


def build_mills(scene, rng):
    """Moulin à eau au bord du ruisseau, avec son pont, et tour du moulin à vent sur sa colline."""
    # Pont de bois en travers du ruisseau, le long de la rue du pont (son tablier va selon x) : tablier à 0,98 m
    # au-dessus de son origine, marches à 0,33 m à ses bouts, garde-corps sur ses côtés. Il est posé assez bas pour
    # que son tablier prolonge la rue, et des rampes de collision montent des berges jusqu'à lui.
    bridge_y = -0.84
    deck = bridge_y + 0.98
    scene.add("nature_kit/bridge_wood", (-38.0, bridge_y, 6.0), 0.0, 6.5)
    # Le tablier va d'un flanc à l'autre ; les flancs pleins (z de ±2,28 à ±3,38 du centre) descendent dans l'eau.
    block(scene, (-38.0, deck - 0.1, 6.0), (5.4, 0.2, 4.56), label="tablier du pont", structure=True)
    street = -0.11
    for side in (-1, 1):
        # Rampe du bord du tablier (x0, en haut) à la rue (x1, en bas) : elle descend en s'éloignant du pont.
        x0, x1 = -38.0 + side * 2.7, -38.0 + side * 4.0
        run, rise = abs(x1 - x0), deck - street
        roll = -math.degrees(math.atan2(rise, run)) * side
        top = ((x0 + x1) / 2, (deck + street) / 2)
        r = math.radians(roll)
        center = (top[0] + math.sin(r) * 0.1, top[1] - math.cos(r) * 0.1, 6.0)
        add_tilted_box(scene, center, (math.hypot(run, rise) + 0.1, 0.2, 5.2), roll)
        # La rampe se voit : des planches du bout du tablier à la rue, sur une culée de pierre enfoncée dans la berge.
        # Sans elles, le tablier s'arrêtait au-dessus de l'eau et le pont semblait ne toucher aucune rive.
        planks = (top[0] + math.sin(r) * 0.08, top[1] - math.cos(r) * 0.08, 6.0)
        box(scene, "wood", planks, (math.hypot(run, rise) + 0.3, 0.16, 4.5), roll=roll)
        for k in range(-3, 4):
            box(scene, "wood_dark", (planks[0] - math.sin(r) * 0.081, planks[1] + math.cos(r) * 0.081, 6.0 + k * 0.62),
                (math.hypot(run, rise) + 0.3, 0.005, 0.04), roll=roll)
        box(scene, "stone", ((x0 + x1) / 2 + side * 0.15, (street - 0.04 - 1.4) / 2, 6.0), (run + 0.6, street - 0.04 + 1.4, 5.0))
    for side in (-1, 1):
        # Flancs du pont, du lit du ruisseau au haut du garde-corps : ni on n'y entre depuis l'eau, ni on ne s'y
        # enfonce depuis le tablier.
        bottom, top = -1.4, deck + 0.66
        block(scene, (-38.0, (bottom + top) / 2, 6.0 + side * 2.83), (6.76, top - bottom, 1.1), label="flanc du pont",
              structure=True)
        # Ses quatre piles d'angle montent plus haut que le garde-corps (1,44 m) : à l'ouest, elles sortent de la berge.
        for end in (-1, 1):
            block(scene, (-38.0 + end * 2.925, (bottom + 1.44) / 2, 6.0 + side * 2.83), (0.91, 1.44 - bottom, 1.1),
                  label="pile du pont", structure=True)
    # La roue du moulin à eau tourne : elle est posée dans village.tscn, contre la maison du meunier (centre
    # (-36.5, 1.0, -14), rayon 2,7 m, épaisse de 2,6 m). Sa collision, ici : on la longe dans le lit du ruisseau
    # sans passer au travers. À hauteur de poitrine, la roue est presque aussi large que son diamètre.
    block(scene, (-36.5, 0.85, -14.0), (2.6, 5.7, 5.4), label="roue du moulin à eau", structure=True)
    for model, y in (("tower-square-base", 0.0), ("tower-square-mid-windows", 3.0), ("tower-square-mid", 6.0), ("tower-square-top", 9.0)):
        scene.add(f"castle_kit/{model}", (30.0, 4.0 + y, -30.0), 0.0, 3.0)
    scene.add("castle_kit/tower-square-roof", (30.0, 4.0 + 9.9, -30.0), 0.0, 3.0)
    scene.add_box((30.0, 4.0 + 5.0, -30.0), (3.0, 10.0, 3.0))
    # Porte du moulin, sacs de grain et meule de rechange au pied de la tour.
    # La porte est dans le mur ouest de la tour (son modèle est mince selon x) : tournée d'un quart de tour, elle en
    # sortait de travers comme une planche.
    scene.add("castle_kit/door", (28.56, 4.0, -30.0), 0.0, 4.0)
    block(scene, (28.4, 4.0 + 1.22, -30.0), (0.34, 2.44, 1.44), label="porte du moulin", structure=True)
    for x, z, degrees in ((27.8, -28.4, 20.0), (27.6, -27.6, 80.0), (28.4, -27.4, 140.0)):
        place(scene, "food_kit/bag", (x, 4.0, z), degrees, 1.05, height=0.88, label="sac de grain")
    cylinder(scene, "stone", (31.0, 4.2, -26.9), 0.8, 0.35, sides=14)
    post(scene, 31.0, -26.9, 0.8, 0.4, y=4.0, label="meule")


def build_props():
    rng = random.Random(5815)
    scene = VillageScene("VillageProps")
    materials(scene)
    scene.material("plaster", (0.8, 0.74, 0.64), 1.0)
    scene.material("roof", (0.36, 0.2, 0.16), 0.9)
    scene.material("window_glow", (0.9, 0.6, 0.32), 1.0, emission=(1.0, 0.6, 0.28), energy=1.6)
    # Passages à garder libres : la grande rue, le tour de la fontaine emprunté par le test, la rue du pont.
    LAYOUT.keep_clear("grande rue", -2.0, 2.0, 9.0, 62.0)
    LAYOUT.keep_clear("grande rue, au nord de la place", -2.0, 2.0, -19.5, -12.5)
    LAYOUT.keep_clear("est de la fontaine", 3.9, 5.4, -12.5, 2.5)
    LAYOUT.keep_clear("rue du pont", -34.0, -3.0, 4.6, 7.4)
    build_rampart(scene, rng)
    build_streets(scene, rng)
    for number, house in enumerate(HOUSES):
        build_house(scene, rng, number, house)
        shop_sign(scene, number)
    build_town_hall(scene)
    build_mills(scene, rng)
    build_gate_defense(scene, random.Random(42))
    build_gardens(scene, random.Random(43))
    build_stables(scene, random.Random(44))
    build_battle_scars(scene, random.Random(45))
    build_wildlife(scene)
    return scene


# --- Intérieur de la mairie ---------------------------------------------------------------------------------------

# L'accueil au rez-de-chaussée, le bureau du maire à l'étage, et la salle secrète derrière le mur ouest du bureau.
# Coordonnées locales au nœud Interior de village.tscn, où sont aussi posés les fragments, les meubles qui
# s'ouvrent, le dispositif et le livre : leurs positions doivent rester en accord avec celles-ci.
HALL_OUTPUT = OUTPUT.parent / "village_hall.tscn"
OFFICE_FLOOR = 4.5
# Les murs de l'étage reposent sur ceux du rez-de-chaussée : leur pied est caché sous le plancher du bureau.
OFFICE_WALLS = WALL_HEIGHT


def room_walls(scene, cx, cz, width, depth, base, doors, skip=(), closed=(), models=("wall", "wall-detail-cross", "wall", "wall-detail-horizontal"),
               windows=()):
    """Murs de pierre d'une pièce. Les portes sont des couples (côté, case) : celles de doors sont des passages voûtés,
    celles de closed des portes fermées qu'on franchit par interaction. Celles de windows sont des fenêtres : la pièce
    est posée sous la carte, une lueur du soir derrière chaque vitre tient lieu de dehors."""
    for side, index, count, center, outward in edge_tiles(cx, cz, width, depth):
        if side in skip:
            continue
        if (side, index) in windows:
            vwall(scene, "wall-window-glass", center, outward, base=base, group="murs")
            size = (0.04, 1.7, 1.6) if outward[0] else (1.6, 1.7, 0.04)
            box(scene, "dusk", (center[0] + outward[0] * 0.42, base + 1.9, center[1] + outward[1] * 0.42), size)
            continue
        if (side, index) in closed:
            vwall(scene, "wall-door", center, outward, base=base, group="murs")
            door_leaf(scene, center, outward, base=base, face=-1)
        elif (side, index) in doors:
            wall(scene, "wall-doorway-round", center, outward, base=base, solid=False)
            # Montants et linteau de la porte.
            along = (0, 1) if outward[0] else (1, 0)
            for sign in (-1, 1):
                size = (0.5, WALL_HEIGHT, 1.05) if outward[0] else (1.05, WALL_HEIGHT, 0.5)
                block(scene, (center[0] + along[0] * sign * 1.48, base + WALL_HEIGHT / 2, center[1] + along[1] * sign * 1.48),
                      size, label="montant", structure=True)
            lintel = (0.5, 1.1, 1.9) if outward[0] else (1.9, 1.1, 0.5)
            scene.add_box((center[0], base + WALL_HEIGHT - 0.55, center[1]), lintel)
            # Les montants laissent ±0,95 m comme doorway() : même complément que arch_fill(), posé à l'étage.
            for sign in (-1, 1):
                for inner, outer, low, high in ((0.8, 0.95, 0.0, DOORWAY_HEIGHT), (0.5, 0.8, 2.3, DOORWAY_HEIGHT),
                                                (0.15, 0.5, 2.7, DOORWAY_HEIGHT)):
                    offset = sign * (inner + outer) / 2
                    width = outer - inner
                    size = (WALL_THICKNESS, high - low, width) if outward[0] else (width, high - low, WALL_THICKNESS)
                    scene.add_box((center[0] + along[0] * offset, base + (low + high) / 2, center[1] + along[1] * offset), size)
        else:
            vwall(scene, models[(index + len(side)) % len(models)], center, outward, base=base, group="murs")
    half_w, half_d = width * TILE / 2, depth * TILE / 2
    for sx in (-1, 1):
        for sz in (-1, 1):
            # Pas de pilier d'angle du côté laissé ouvert : le mur voisin y tient lieu de mur, et le pilier en sortait
            # (salle secrète : une colonne pâle plantée dans le mur ouest du bureau, qui se battait avec lui à l'angle).
            if ("east" in skip and sx > 0) or ("west" in skip and sx < 0) or ("north" in skip and sz < 0) \
                    or ("south" in skip and sz > 0):
                continue
            scene.add("fantasy_town_kit/pillar-stone", (cx + sx * half_w, base, cz + sz * half_d), 0.0, WALL_SCALE)


def door_leaf(scene, center, outward, base=0.0, face=1, step=False):
    """Vantail de bois clouté posé dans l'arche de la porte fermée (wall-door), côté face (+1 dehors, -1 dedans) : des
    planches, deux pentures de fer, un anneau et sa serrure. Le modèle seul ne montre qu'un encadrement et une lucarne,
    et les testeurs ne voyaient pas de porte, ni dehors ni dedans."""
    x, z = center
    nx, nz = outward[0] * face, outward[1] * face
    along = (abs(outward[1]), abs(outward[0]))
    degrees = 0.0 if outward[1] else 90.0
    width, height = 1.12, 2.5

    def at(u, h, out):
        return (x + along[0] * u + nx * out, base + h, z + along[1] * u + nz * out)
    box(scene, "wood_dark", at(0.0, height / 2, 0.24), (width, height, 0.08), degrees)
    for u in (-0.28, 0.0, 0.28):
        box(scene, "soot", at(u, height / 2, 0.285), (0.025, height - 0.08, 0.012), degrees)
    for h in (0.45, 1.95):
        box(scene, "iron", at(-0.08, h, 0.29), (width - 0.12, 0.09, 0.02), degrees)
        for u in (-0.46, 0.3):
            box(scene, "iron", at(u, h, 0.302), (0.05, 0.05, 0.02), degrees)
    box(scene, "iron", at(0.38, 1.15, 0.295), (0.12, 0.2, 0.025), degrees)
    torus(scene, "iron", at(0.38, 0.98, 0.31), 0.06, 0.085, degrees, tilt=90.0)
    if step:
        box(scene, "stone", at(0.0, 0.06, 0.6), (1.9, 0.12, 0.7), degrees)


def hp(scene, model, center, degrees=0.0, scale=2.6, solid=True, label=None, tilt=0.0, roll=0.0):
    """Meuble de la mairie : sa collision a exactement la hauteur du modèle, pour que les papiers posés dessus
    soient au-dessus d'elle."""
    height = None
    if solid:
        low, high = rotated_box(model, degrees, scale, tilt, roll)
        height = high[1] - low[1]
    place(scene, model, center, degrees, scale, height=height, tilt=tilt, roll=roll, label=label)


# Dessus des trois planches basses de l'étagère ouverte (bookcaseOpen à l'échelle 3,2), d'après SHELVES de
# build_plaine : les livres posés plus bas passaient sous les planches.
OPEN_SHELF_ROWS = tuple(round(level * 3.2 + 0.005, 3) for level in SHELVES["furniture_kit/bookcaseOpen"][:3])


def shelf_books(scene, rng, center, degrees, rows, width):
    """Livres rangés sur les planches d'une étagère : une rangée de piles par planche, centrée entre ses côtés.
    rows : hauteurs du dessus des planches."""
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
    count = int(width / 0.42)
    for y in rows:
        for k in range(count):
            if rng.random() < 0.25:
                continue
            u = (k - (count - 1) / 2) * 0.44
            lay(scene, "furniture_kit/books", (center[0] + c * u, center[1] + y, center[2] - s * u), degrees + rng.choice((0.0, 180.0)),
                2.4 + rng.uniform(-0.2, 0.3))


def potted_plant(scene, position):
    """Pot de terre et son buisson de simples, avec sa collision."""
    lay(scene, "nature_kit/pot_small", position, 20.0, 2.2)
    lay(scene, "nature_kit/plant_bushSmall", (position[0], position[1] + top_of("nature_kit/pot_small", 2.2) - 0.1, position[2]),
        0.0, 1.6)
    post(scene, position[0], position[2], 0.38, 0.9, y=position[1], label="pot de terre")


def build_hall_interior():
    scene = VillageScene("VillageHall")
    materials(scene)
    # Ciel du soir derrière les vitres : une lueur chaude et douce, comme celle qui baigne le village.
    scene.material("dusk", (0.85, 0.62, 0.45), 1.0, emission=(0.95, 0.62, 0.4), energy=0.9)
    rng = random.Random(77)
    LAYOUT.reset()
    # Rez-de-chaussée : l'accueil des habitants et ses bureaux. Porte au sud, escalier le long du mur est.
    # Ses fenêtres donnent au sud et au nord, au-dessus des bancs, du pied de l'escalier, du coin de l'archiviste et
    # de la table d'appoint.
    room_walls(scene, 0.0, 0.0, 4, 3, 0.0, doors=set(), closed={("south", 1)},
               windows={("south", 2), ("south", 3), ("north", 0), ("north", 2)})
    # Le comptoir de l'accueil et son tiroir, tourné vers les visiteurs.
    hp(scene, "furniture_kit/desk", (-2.0, 0.0, -0.6), 180.0, 2.8, label="comptoir")
    hp(scene, "furniture_kit/chair", (-2.0, 0.0, -2.0), 0.0, 3.0, label="chaise de l'accueil")
    hp(scene, "furniture_kit/sideTableDrawers", (0.4, 0.0, -0.8), 0.0, 2.6, label="tiroir de l'accueil")
    lay(scene, "graveyard_kit/candle", (-1.3, top_of("furniture_kit/desk", 2.8), -1.0), 0.0, 0.8)
    lay(scene, "furniture_kit/books", (-1.7, top_of("furniture_kit/desk", 2.8), -0.3), 20.0, 2.6)
    # Les armoires des archives, contre le mur ouest.
    for z in (-3.5, -1.0, 1.5):
        hp(scene, "furniture_kit/bookcaseClosedDoors", (-7.3, 0.0, z), 90.0, 3.2, label="armoire des archives")
    # Le bureau de l'archiviste, face aux armoires. Les passages entre les meubles gardent au moins un mètre.
    hp(scene, "furniture_kit/desk", (-4.4, 0.0, -3.6), 90.0, 2.8, label="bureau de l'archiviste")
    hp(scene, "furniture_kit/chair", (-3.1, 0.0, -3.6), -90.0, 3.0, label="chaise de l'archiviste")
    lay(scene, "furniture_kit/books", (-4.2, top_of("furniture_kit/desk", 2.8), -4.2), 80.0, 2.6)
    lay(scene, "graveyard_kit/candle", (-4.9, top_of("furniture_kit/desk", 2.8), -2.9), 0.0, 0.8)
    for x in (-3.0, -1.6):
        hp(scene, "furniture_kit/bookcaseOpen", (x, 0.0, -5.28), 0.0, 3.2, label="étagère")
        shelf_books(scene, rng, (x, 0.0, -5.28), 0.0, OPEN_SHELF_ROWS, 1.1)
    # Une table d'appoint au plateau plat contre le mur nord (un fragment y est posé), et le coffre de l'accueil.
    hp(scene, "furniture_kit/sideTable", (1.6, 0.0, -5.4), 0.0, 2.6, label="table d'appoint")
    hp(scene, "mini_dungeon/chest", (3.5, 0.0, -5.1), 90.0, 2.4, label="coffre de l'accueil")
    # Le coin d'attente : une table, des chaises, des bancs le long du mur sud.
    hp(scene, "furniture_kit/tableCloth", (-4.6, 0.0, 3.4), 0.0, 3.0, label="table d'attente")
    for x, z, degrees in ((-5.8, 2.2, 0.0), (-3.4, 4.6, 180.0)):
        hp(scene, "furniture_kit/chair", (x, 0.0, z), degrees, 3.0, label="chaise")
    for x, z in ((-5.2, 3.3), (-4.0, 3.6)):
        lay(scene, "furniture_kit/books", (x, top_of("furniture_kit/tableCloth", 3.0), z), 30.0, 3.0)
    for x in (1.0, 3.0):
        place(scene, "furniture_kit/bench", (x, 0.0, 5.4), 0.0, 3.0, height=0.8, label="banc")
    hp(scene, "survival_kit/box-large", (-7.0, 0.0, 4.6), 0.0, 3.6, label="caisses")
    hp(scene, "mini_dungeon/barrel", (-4.9, 0.0, 5.0), 0.0, 2.6, label="tonneau")
    lay(scene, "furniture_kit/rugRectangle", (-2.0, 0.0, 2.6), 90.0, 2.6)
    lay(scene, "furniture_kit/coatRackStanding", (-3.6, 0.0, 5.3), 0.0, 2.6)
    post(scene, -3.6, 5.3, 0.3, 2.0, label="portemanteau")
    potted_plant(scene, (-0.6, 0.0, 5.35))

    # Étage : le bureau du maire, avec le dispositif des cinq codes contre le mur nord.
    # Celles du bureau, au sud et à l'est, au-dessus de la cage d'escalier.
    room_walls(scene, 0.0, 0.0, 4, 3, OFFICE_WALLS, doors={("west", 1)},
               windows={("south", 1), ("south", 3), ("east", 0), ("east", 1), ("east", 2)})
    office = OFFICE_FLOOR
    hp(scene, "furniture_kit/desk", (-1.0, office, -0.6), 180.0, 2.8, label="bureau du maire")
    hp(scene, "furniture_kit/chair", (-1.0, office, -2.0), 0.0, 3.0, label="chaise du maire")
    lay(scene, "graveyard_kit/candle", (-1.8, office + top_of("furniture_kit/desk", 2.8), -1.1), 0.0, 0.8)
    lay(scene, "furniture_kit/books", (-1.6, office + top_of("furniture_kit/desk", 2.8), -0.2), 60.0, 2.6)
    hp(scene, "furniture_kit/sideTableDrawers", (1.4, office, -0.8), 180.0, 2.6, label="tiroir du maire")
    hp(scene, "furniture_kit/bookcaseOpen", (-5.0, office, 5.28), 180.0, 3.2, label="étagère du maire")
    shelf_books(scene, rng, (-5.0, office, 5.28), 180.0, OPEN_SHELF_ROWS, 1.1)
    hp(scene, "furniture_kit/bookcaseClosedDoors", (1.6, office, 5.3), 180.0, 3.2, label="armoire du maire")
    hp(scene, "mini_dungeon/chest", (-6.4, office, -5.1), 90.0, 2.4, label="coffre du bureau")
    lay(scene, "furniture_kit/rugRectangle", (-1.0, office, 1.4), 0.0, 2.6)
    lay(scene, "furniture_kit/coatRackStanding", (3.6, office, 5.3), 0.0, 2.6)
    post(scene, 3.6, 5.3, 0.3, 2.0, y=office, label="portemanteau")
    hp(scene, "mini_dungeon/chest", (6.4, office, 4.6), 0.0, 1.6, label="coffre du maire")
    potted_plant(scene, (-7.0, office, 5.1))
    for x in (-4.4, 2.4):
        # Le drap est décalé de 0,4 tuile de l'origine du modèle, vers le mur.
        scene.add("fantasy_town_kit/banner-red", (x, office + 0.6, -4.35), 90.0, 3.4)
    # Collisions du garde-corps autour de la trémie de l'escalier, dessiné dans village.tscn : plus hautes que la
    # rambarde, pour qu'on ne saute pas par-dessus dans la cage d'escalier.
    scene.add_box((4.5, office + 1.2, -1.1), (0.3, 2.4, 6.2))
    scene.add_box((6.2, office + 1.2, 2.1), (3.4, 2.4, 0.3))

    # Salle secrète, derrière la bibliothèque du bureau : intacte, un pupitre de pierre, des bougies et des bannières.
    room_walls(scene, -12.0, 0.0, 2, 2, OFFICE_WALLS, doors=set(), skip=("east",))
    lx, lz = -12.6, 0.0
    box(scene, "stone", (lx, office + 0.08, lz), (1.0, 0.16, 1.0))
    box(scene, "stone", (lx, office + 0.58, lz), (0.5, 0.86, 0.5))
    box(scene, "stone", (lx, office + 1.06, lz), (0.95, 0.12, 0.8), roll=-15.0)
    block(scene, (lx, office + 0.55, lz), (1.0, 1.1, 1.0), label="pupitre de pierre")
    lay(scene, "furniture_kit/rugRectangle", (-11.6, office, 0.0), 90.0, 2.6)
    for x, z in ((-14.8, -3.0), (-14.8, 3.0), (-9.6, -3.2), (-9.6, 3.2)):
        lay(scene, "graveyard_kit/candle-multiple", (x, office, z), 0.0, 2.4)
    for z in (-1.6, 1.6):
        scene.add("fantasy_town_kit/banner-red", (-14.28, office + 0.6, z), 180.0, 3.4)
    for z in (-3.1, 3.1):
        hp(scene, "graveyard_kit/urn-round", (-12.8, office, z), 0.0, 2.0, label="urne")
    problems = LAYOUT.report("mairie")
    HALL_OUTPUT.write_text(scene.text(), encoding="utf-8", newline="\n")
    print(f"{HALL_OUTPUT.name} : {len(scene.visuals)} modèles, {len(scene.colliders)} collisions")
    return problems


def main():
    problems = build_hall_interior()
    LAYOUT.reset()
    scene = build_props()
    problems += LAYOUT.report("village")
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(scene.text(), encoding="utf-8", newline="\n")
    print(f"{OUTPUT.name} : {len(scene.visuals)} modèles, {len(scene.colliders)} collisions, "
          f"{len(scene.cylinders)} cylindres, {sum(len(v) for v in scene.shapes.values())} formes")
    for problem in problems:
        print("  ! " + problem)
    print(f"{len(problems)} problème(s) de placement")


if __name__ == "__main__":
    main()
