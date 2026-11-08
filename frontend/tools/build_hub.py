"""Génère les objets fixes du hub : le camp des survivants, le village de Codia, le château du roi et le bunker.

Le village se reconstruit au fil des livres posés au château : chaque élément réparable est écrit
deux fois, en ruine et reconstruit, sous un nœud qui porte le nombre de livres qui le répare.

La scène produite s'ouvre et se modifie dans Godot, mais le script l'écrase :
pour un changement durable, modifier ce script puis le relancer depuis le dossier frontend :

    python tools/build_hub.py
"""

import math
import random
from pathlib import Path

from build_plaine import (MEDIEVAL, MODEL_BOXES, OUTWARD_ANGLES, WALL_HEIGHT, WALL_SCALE, Scene, arch_fill, doorway,
                          multiply, rotation_x, rotation_y, rotation_z, wall)
from build_plaine import furniture as _furniture

# Boîtes englobantes (coin, taille, à l'échelle 1) des modèles ajoutés pour le hub.
MODEL_BOXES.update({
    "castle_kit/siege-catapult-demolished": ((-0.63, 0.0, -0.87), (1.67, 0.31, 1.66)),
    "castle_kit/siege-ram-demolished": ((-1.03, 0.0, -0.79), (2.07, 0.71, 1.64)),
    "fantasy_town_kit/chimney-base": ((0.07, 0.0, -0.25), (0.34, 1.0, 0.51)),
    "fantasy_town_kit/fountain-square": ((-1.0, 0.0, -1.0), (2.0, 0.45, 2.0)),
    "fantasy_town_kit/fountain-square-detail": ((-1.0, 0.0, -1.0), (2.0, 0.47, 2.0)),
    "fantasy_town_kit/hedge": ((0.25, 0.0, -0.5), (0.25, 0.25, 1.0)),
    "fantasy_town_kit/hedge-large": ((0.09, 0.0, -0.5), (0.39, 0.59, 1.0)),
    "food_kit/bag": ((-0.15, 0.0, -0.28), (0.31, 0.83, 0.57)),
    "food_kit/bag-flat": ((-0.31, 0.0, -0.22), (0.64, 0.18, 0.46)),
    "food_kit/loaf": ((-0.28, 0.0, -0.17), (0.57, 0.43, 0.37)),
    "food_kit/loaf-round": ((-0.38, 0.0, -0.25), (0.76, 0.28, 0.5)),
    "food_kit/loaf-baguette": ((-0.41, 0.0, -0.12), (0.82, 0.25, 0.25)),
    "food_kit/cutting-board": ((-0.28, 0.0, -0.4), (0.57, 0.05, 0.81)),
    "food_kit/rollingPin": ((-0.4, -0.07, -0.07), (0.81, 0.14, 0.15)),
    "food_kit/pot-stew": ((-0.32, 0.0, -0.4), (0.65, 0.35, 0.81)),
    "food_kit/mortar-pestle": ((-0.05, 0.0, -0.07), (0.1, 0.34, 0.12)),
    "food_kit/cabbage": ((-0.18, 0.0, -0.19), (0.37, 0.31, 0.39)),
    "food_kit/apple": ((-0.09, 0.0, -0.09), (0.19, 0.18, 0.19)),
    "food_kit/cheese": ((-0.34, 0.0, -0.34), (0.68, 0.21, 0.68)),
    "food_kit/carrot": ((-0.17, 0.0, -0.17), (0.34, 0.71, 0.34)),
    "food_kit/fish": ((-0.09, 0.0, -0.31), (0.19, 0.31, 0.62)),
    "mini_forest/ladder": ((-0.25, 0.0, -0.04), (0.5, 1.0, 0.14)),
    "mini_forest/target": ((-0.28, 0.0, -0.28), (0.55, 0.57, 0.46)),
    "mini_arena/weapon-rack": ((-0.41, 0.0, -0.14), (0.77, 0.46, 0.44)),
    "mini_arena/statue": ((-0.34, 0.0, -0.34), (0.69, 1.33, 0.69)),
    "mini_arena/trophy": ((-0.28, 0.0, -0.22), (0.56, 0.47, 0.44)),
    "mini_dungeon/shield-rectangle": ((-0.14, 0.0, -0.04), (0.28, 0.29, 0.12)),
    "mini_dungeon/potion": ((-0.15, 0.0, -0.15), (0.32, 0.39, 0.32)),
    "survival_kit/bucket": ((-0.07, 0.0, -0.07), (0.14, 0.18, 0.14)),
    "graveyard_kit/candle": ((-0.07, 0.0, -0.07), (0.14, 0.19, 0.14)),
    "graveyard_kit/bench-damaged": ((-0.47, 0.0, -0.22), (0.9, 0.51, 0.45)),
    "nature_kit/statue_block": ((-0.19, 0.0, -0.19), (0.39, 0.39, 0.39)),
    "nature_kit/statue_column": ((-0.14, 0.0, -0.14), (0.29, 1.0, 0.29)),
    "nature_kit/statue_columnDamaged": ((-0.14, 0.0, -0.14), (0.29, 0.69, 0.29)),
    "nature_kit/stump_old": ((-0.15, 0.0, -0.18), (0.35, 0.26, 0.37)),
    "nature_kit/tree_default": ((-0.37, 0.0, -0.32), (0.75, 1.7, 0.64)),
    "nature_kit/tree_oak": ((-0.31, 0.0, -0.37), (0.63, 1.23, 0.74)),
    "nature_kit/tree_fat": ((-0.37, 0.0, -0.32), (0.75, 1.14, 0.64)),
    "nature_kit/tree_thin_dark": ((-0.25, 0.0, -0.25), (0.68, 1.49, 0.62)),
    "nature_kit/canoe": ((-0.14, 0.0, -0.57), (0.29, 0.17, 1.14)),
    # Intérieurs des nouveaux bâtiments.
    "food_kit/bowl": ((-0.27, 0.0, -0.31), (0.54, 0.23, 0.62)),
    "food_kit/mug": ((-0.12, 0.0, -0.14), (0.34, 0.27, 0.29)),
    "food_kit/plate": ((-0.45, 0.0, -0.45), (0.89, 0.09, 0.89)),
    "food_kit/honey": ((-0.16, 0.0, -0.16), (0.33, 0.32, 0.33)),
    "food_kit/onion": ((-0.11, 0.0, -0.12), (0.21, 0.25, 0.25)),
    "food_kit/pot": ((-0.33, 0.0, -0.41), (0.66, 0.36, 0.82)),
    "food_kit/wine-red": ((-0.1, 0.0, -0.08), (0.19, 0.7, 0.17)),
    "graveyard_kit/detail-plate": ((-0.14, 0.0, -0.14), (0.27, 0.05, 0.27)),
    "graveyard_kit/lantern-glass": ((-0.12, 0.0, -0.12), (0.24, 0.39, 0.24)),
    "graveyard_kit/trunk": ((-0.27, 0.0, -0.27), (0.54, 0.45, 0.55)),
    "graveyard_kit/urn-square": ((-0.13, 0.0, -0.13), (0.26, 0.28, 0.26)),
    "mini_dungeon/coin": ((-0.21, 0.0, -0.08), (0.42, 0.42, 0.17)),
    "mini_dungeon/key": ((-0.3, 0.0, -0.08), (0.59, 0.36, 0.16)),
    "survival_kit/resource-wood": ((-0.1, 0.0, -0.04), (0.21, 0.06, 0.09)),
    "survival_kit/tool-axe": ((-0.07, 0.0, -0.02), (0.11, 0.26, 0.03)),
    "survival_kit/tool-hoe": ((-0.07, 0.0, -0.04), (0.08, 0.24, 0.07)),
    "survival_kit/tool-shovel": ((-0.04, 0.0, -0.02), (0.07, 0.29, 0.03)),
    "survival_kit/bedroll-frame": ((-0.14, 0.0, -0.3), (0.27, 0.15, 0.61)),
    "nature_kit/plant_bush": ((-0.2, 0.0, -0.2), (0.4, 0.24, 0.4)),
    "nature_kit/plant_flatShort": ((-0.14, 0.0, -0.14), (0.28, 0.24, 0.28)),
    "nature_kit/mushroom_red": ((-0.09, 0.0, -0.1), (0.17, 0.2, 0.2)),
    "fantasy_town_kit/chimney-top": ((0.21, 0.0, -0.17), (0.25, 0.63, 0.34)),
    "survival_kit/tool-hammer": ((-0.04, 0.0, -0.02), (0.09, 0.15, 0.04)),
    "nature_kit/campfire_logs": ((-0.15, 0.0, -0.15), (0.29, 0.06, 0.29)),
    "survival_kit/bedroll-packed": ((-0.13, 0.0, -0.04), (0.26, 0.09, 0.09)),
})


# Meubles toujours solides, même posés sans hauteur : chaises, tabourets, bancs, roues, plantes. On bute dessus au lieu
# de les traverser.
SOLID = ("furniture_kit/chair", "furniture_kit/stoolBar", "fantasy_town_kit/stall-stool", "furniture_kit/bench",
         "fantasy_town_kit/wheel", "graveyard_kit/bench-damaged", "furniture_kit/pottedPlant", "mini_dungeon/chair",
         "survival_kit/bucket", "survival_kit/tool-hoe", "survival_kit/tool-shovel")


def footprint(model, center, degrees=0.0, scale=2.6, tilt=0.0, roll=0.0):
    """Emprise au sol (polygone convexe, x et z) et hauteur d'un modèle posé comme furniture() le pose."""
    model = MEDIEVAL.get(model, model)
    (px, py, pz), (sx, sy, sz) = MODEL_BOXES[model]
    scales = scale if isinstance(scale, tuple) else (scale, scale, scale)
    basis = multiply(multiply(rotation_y(degrees), rotation_x(tilt)), rotation_z(roll))
    corners = []
    for cx in (px, px + sx):
        for cy in (py, py + sy):
            for cz in (pz, pz + sz):
                local = (cx * scales[0], cy * scales[1], cz * scales[2])
                corners.append([sum(basis[r][i] * local[i] for i in range(3)) for r in range(3)])
    low = [min(c[i] for c in corners) for i in range(3)]
    high = [max(c[i] for c in corners) for i in range(3)]
    mx, mz = (low[0] + high[0]) / 2, (low[2] + high[2]) / 2
    points = convex_hull([(center[0] + c[0] - mx, center[2] + c[2] - mz) for c in corners])
    return points, center[1], center[1] + high[1] - low[1]


def convex_hull(points):
    points = sorted(set((round(x, 4), round(z, 4)) for x, z in points))
    if len(points) < 3:
        return points

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    lower, upper = [], []
    for point in points:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], point) <= 0:
            lower.pop()
        lower.append(point)
    for point in reversed(points):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], point) <= 0:
            upper.pop()
        upper.append(point)
    return lower[:-1] + upper[:-1]


def apart(a, b, margin=0.05):
    """Vrai si deux polygones convexes sont séparés d'au moins margin (axe séparateur)."""
    for polygon in (a, b):
        for index in range(len(polygon)):
            x1, z1 = polygon[index]
            x2, z2 = polygon[(index + 1) % len(polygon)]
            nx, nz = z2 - z1, x1 - x2
            length = math.hypot(nx, nz) or 1.0
            nx, nz = nx / length, nz / length
            pa = [nx * x + nz * z for x, z in a]
            pb = [nx * x + nz * z for x, z in b]
            if max(pa) + margin <= min(pb) or max(pb) + margin <= min(pa):
                return True
    return False


def furniture(scene, model, center, degrees=0.0, scale=2.6, height=None, tilt=0.0, roll=0.0):
    """Comme furniture() de build_plaine, avec en plus une échelle par axe du modèle (x, y, z)."""
    if hasattr(scene, "footprints"):
        scene.footprints.setdefault(scene.group, []).append(footprint(model, center, degrees, scale, tilt, roll))
    if height is None and model in SOLID:
        # Hauteur de la boîte du meuble tel qu'il est posé, debout ou renversé.
        height = MODEL_BOXES[MEDIEVAL.get(model, model)][1][1] * (scale if not isinstance(scale, tuple) else scale[1])
    if not isinstance(scale, tuple):
        return _furniture(scene, model, center, degrees, scale, height, tilt, roll)
    model = MEDIEVAL.get(model, model)
    (px, py, pz), (sx, sy, sz) = MODEL_BOXES[model]
    basis = multiply(multiply(rotation_y(degrees), rotation_x(tilt)), rotation_z(roll))
    corners = []
    for cx in (px, px + sx):
        for cy in (py, py + sy):
            for cz in (pz, pz + sz):
                local = (cx * scale[0], cy * scale[1], cz * scale[2])
                corners.append([sum(basis[r][i] * local[i] for i in range(3)) for r in range(3)])
    low = [min(c[i] for c in corners) for i in range(3)]
    high = [max(c[i] for c in corners) for i in range(3)]
    scene.add(model, (center[0] - (low[0] + high[0]) / 2, center[1] - low[1], center[2] - (low[2] + high[2]) / 2), degrees, scale,
              tilt=tilt, roll=roll)
    if height:
        if round(degrees) % 90 and not tilt and not roll:
            scene.add_box((center[0], center[1] + height / 2, center[2]), (sx * scale[0], height, sz * scale[2]), degrees)
        else:
            scene.add_box((center[0], center[1] + height / 2, center[2]), (high[0] - low[0], height, high[2] - low[2]))

OUTPUT = Path(__file__).resolve().parent.parent / "scenes" / "levels" / "hub" / "hub_props.tscn"
# Intérieur du bunker, sous la carte : son repère est celui du nœud BunkerInterior de hub.tscn.
BUNKER_OUTPUT = OUTPUT.parent / "hub_bunker.tscn"
# Abri de 5 cases sur 3 : de x = -10 à 10, de z = -6 à 6, la porte au sud.
SHELTER = (0.0, 0.0, 5, 3)
TILE = WALL_SCALE
# Enceinte du château, au nord : de x = -25 à 25, de z = -95 (fond) à -50 (porterie).
CURTAIN_SCALE = 5.0
CASTLE_X = 25.0
CASTLE_BACK = -95.0
CASTLE_FRONT = -50.0
# Donjon au fond de la cour : murs de 4 m d'épaisseur autour de la salle des livres,
# qui va de x = -10 à 10 et de z = -87 à -75. Mêmes valeurs dans le script qui écrit hub.tscn.
KEEP_SCALE = 4.0
KEEP_X = 12.0
KEEP_BACK = -89.0
KEEP_FRONT = -73.0
KEEP_LAYER = 4.4
BUNKER = (78.0, 0.0)
# Maisons du village : (rayon, angle en degrés) depuis le feu de camp, entre les chemins.
HOUSE_SPOTS = [(24.0, a) for a in (-112.5, -67.5, -22.5, 22.5, 70.0, 110.0, 160.0, 200.0)] + [
    (38.0, a) for a in (-112.5, -67.5, -22.5, 22.5, 72.0, 108.0, 162.0, 198.0)
]
# Chemins qui partent du feu de camp : portails, château et bunker.
ROADS = [(-38.0, -38.0), (38.0, -38.0), (38.0, 38.0), (-38.0, 38.0), (0.0, CASTLE_FRONT), BUNKER, (0.0, 55.0), (-53.0, 0.0)]
OUTWARDS = {"north": (0, -1), "south": (0, 1), "east": (1, 0), "west": (-1, 0)}
DOOR_YAWS = {"south": 0.0, "north": 180.0, "east": 90.0, "west": -90.0}


def quote(text):
    """Chaîne d'un fichier .tscn, entre guillemets."""
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


class StagedScene(Scene):
    """Scène dont les modèles et les collisions sont rangés par groupe, chacun sous son propre nœud."""

    def __init__(self, root_name):
        super().__init__(root_name)
        self.group = "Fixed"
        self.metadata = {}
        # Nœuds de groupe portant une position et un script : chemin -> (transformée, script, propriétés).
        self.pivots = {}
        self.scripts = {}
        self.root_script = None
        # Emprises au sol des meubles de chaque groupe (furniture()).
        self.footprints = {}
        # Position dans le monde de chaque groupe posé, et les groupes qui sont des textes (Readable, panneau).
        self.origins = {}
        self.texts = set()

    def batched(self, script):
        """Script de la racine qui regroupe les modèles de chaque groupe en MultiMesh au chargement."""
        self.scripts.setdefault(script, f"{len(self.scripts) + 1}_script")
        self.root_script = script

    def pivot(self, path, position, script, properties, degrees=0.0, kind="Node3D"):
        """Ouvre un groupe posé en un point du monde, tourné de degrees autour de y, avec un script : les ajouts
        suivants s'y placent dans son repère. Sous un autre groupe posé (un panneau sous son Readable), la position
        est ramenée dans le repère du parent, qui n'est jamais tourné."""
        assert path not in self.pivots, f"deux nœuds {path}"
        if script:
            self.scripts.setdefault(script, f"{len(self.scripts) + 1}_script")
        self.origins[path] = tuple(position)
        parent = self.origins.get(path.rsplit("/", 1)[0])
        if parent:
            position = tuple(position[i] - parent[i] for i in range(3))
        c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
        values = [c, 0.0, s, 0.0, 1.0, 0.0, -s, 0.0, c, *position]
        transform = "Transform3D(" + ", ".join(f"{round(v, 5) + 0.0:g}" for v in values) + ")"
        self.pivots[path] = (transform, script, properties, kind)
        self.group = path

    def board(self, name, point, degrees, text, style=0, mount=1, size=(1.2, 0.6), height=1.6, line=0.12):
        """Panneau (SignBoard) dans le groupe courant, sa face tournée de degrees (vers +Z du nœud)."""
        group = self.group
        self.pivot(f"{group}/{name}", point, "res://scripts/sign_board.gd",
                   {"text": quote(text), "style": str(style), "mount": str(mount), "board_size": f"Vector2({size[0]:g}, {size[1]:g})",
                    "board_height": f"{height:g}", "line_height": f"{line:g}"}, degrees)
        self.group = group

    def inscription(self, name, point, degrees, text, pixel=0.004, color="Color(0.16, 0.14, 0.12, 1)", font=64):
        """Inscription gravée ou peinte : un Label3D collé à sa surface, éclairé comme elle, sans halo ni contour."""
        group = self.group
        self.pivot(f"{group}/{name}", point, None,
                   {"pixel_size": f"{pixel:g}", "shaded": "true", "double_sided": "false", "alpha_cut": "1", "modulate": color,
                    "text": quote(text), "font_size": str(font), "outline_size": "0"}, degrees, kind="Label3D")
        self.group = group

    def lamp(self, name, center, spots, energy=1.4, light_range=5.0, color=None):
        """Lumière chaude d'un intérieur, dans le groupe courant (hub_lamp.gd) : allumée quand on approche.
        spots : points des lumières, en coordonnées du monde."""
        group = self.group
        offsets = ", ".join(f"{x - center[0]:.3f}, {y - center[1]:.3f}, {z - center[2]:.3f}" for x, y, z in spots)
        properties = {"energy": f"{energy:g}", "light_range": f"{light_range:g}", "spots": f"PackedVector3Array({offsets})"}
        if color:
            properties["color"] = color
        self.pivot(f"{group}/{name}", center, "res://scenes/levels/hub/hub_lamp.gd", properties)
        self.group = group

    def reader(self, name, point, title, body, prompt, radius=1.8):
        """Texte à lire avec E (Readable), posé dans le groupe courant : il suit la ruine ou la reconstruction.
        Le groupe courant devient le Readable : on peut y poser son panneau, puis revenir au groupe d'avant."""
        group = self.group
        self.pivot(f"{group}/{name}", point, "res://scripts/readable.gd",
                   {"title": quote(title), "body": quote(body), "prompt": quote(prompt), "radius": f"{radius:g}"})
        self.texts.add(self.group)
        return group

    def add(self, model, position, degrees=0.0, scale=1.0, tilt=0.0, roll=0.0):
        assert self.group not in self.texts, f"modèle {model} posé sous le texte {self.group}"
        super().add(model, position, degrees, scale, tilt, roll)
        self.visuals[-1] = self.visuals[-1] + (self.group,)

    def add_box(self, center, size, degrees=0.0):
        super().add_box(center, size, degrees)
        self.colliders[-1] = self.colliders[-1] + (self.group,)

    def text(self):
        lines = ["[gd_scene format=3]", ""]
        for path, identifier in self.models_in_use():
            lines.append(f'[ext_resource type="PackedScene" path="{path}" id="{identifier}"]')
        for path, identifier in self.scripts.items():
            lines.append(f'[ext_resource type="Script" path="{path}" id="{identifier}"]')
        lines.append("")
        for size, identifier in self.boxes.items():
            lines += [f'[sub_resource type="BoxShape3D" id="{identifier}"]', f"size = Vector3({size[0]:g}, {size[1]:g}, {size[2]:g})", ""]
        lines += [f'[node name="{self.root_name}" type="Node3D"]']
        if self.root_script:
            lines.append(f'script = ExtResource("{self.scripts[self.root_script]}")')
        lines.append("")
        groups = list(dict.fromkeys([v[3] for v in self.visuals] + [c[2] for c in self.colliders] + list(self.pivots)))
        created = set()
        for group in groups:
            parts = group.split("/")
            for depth in range(1, len(parts) + 1):
                path = "/".join(parts[:depth])
                if path in created:
                    continue
                created.add(path)
                parent = "/".join(parts[:depth - 1]) or "."
                lines.append(f'[node name="{parts[depth - 1]}" type="Node3D" parent="{parent}"]')
                if path in self.pivots:
                    transform, script, properties, kind = self.pivots[path]
                    lines[-1] = lines[-1].replace('type="Node3D"', f'type="{kind}"')
                    lines.append(f"transform = {transform}")
                    if script:
                        lines.append(f'script = ExtResource("{self.scripts[script]}")')
                    for key, value in properties.items():
                        lines.append(f"{key} = {value}")
                for key, value in self.metadata.get(path, {}).items():
                    lines.append(f"metadata/{key} = {value}")
                lines.append("")
            for index, (name, model, transform, owner) in enumerate(self.visuals):
                if owner == group:
                    lines += [f'[node name="{name}_{index}" parent="{group}" instance=ExtResource("{self.models[model]}")]',
                              f"transform = {transform}", ""]
            boxes = [(i, c) for i, c in enumerate(self.colliders) if c[2] == group]
            if boxes:
                lines += [f'[node name="Collision" type="StaticBody3D" parent="{group}"]', ""]
                for index, (transform, identifier, _) in boxes:
                    lines += [f'[node name="Box{index}" type="CollisionShape3D" parent="{group}/Collision"]',
                              f"transform = {transform}", f'shape = SubResource("{identifier}")', ""]
        return "\n".join(lines)

    def models_in_use(self):
        for _, path, _, _ in self.visuals:
            self._model_id(path)
        return self.models.items()

    def repair(self, name, stage):
        """Ouvre un élément réparable : les ajouts suivants vont dans sa version en ruine."""
        self.metadata[f"Repairs/{name}"] = {"stage": stage}
        self.group = f"Repairs/{name}/Ruins"

    def rebuilt(self, name):
        self.group = f"Repairs/{name}/Rebuilt"


def edge_tiles(cx, cz, width, depth, tile=TILE):
    """Renvoie, pour chaque côté, les centres des cases de mur et la direction vers l'extérieur."""
    half_w, half_d = width * tile / 2, depth * tile / 2
    for side, (dx, dz) in OUTWARDS.items():
        count = depth if dx else width
        for index in range(count):
            offset = -((count - 1) * tile) / 2 + index * tile
            if dx:
                yield side, index, count, (cx + dx * half_w, cz + offset), (dx, dz)
            else:
                yield side, index, count, (cx + offset, cz + dz * half_d), (dx, dz)


def wall_models(style):
    if style == "wood":
        return ("wall-wood", "wall-wood-broken", "wall-wood-window-shutters", "wall-wood-window-small")
    return ("wall", "wall-broken", "wall-window-stone", "wall-window-shutters")


def roof(scene, cx, cz, width, depth, base):
    """Toit à deux pans : les tuiles montent des gouttières jusqu'au faîte, au milieu. Le faîte court dans la longueur
    paire de la maison (le long de z, sauf si seule la profondeur est paire), pour que les deux pans se rejoignent sur
    un joint de tuiles. La tuile « roof » est basse du côté de son x négatif, avec le débord de la gouttière : on la
    tourne pour que ce côté regarde au-dehors."""
    ridge_along_x = width % 2 == 1 and depth % 2 == 0
    for column in range(width):
        x = cx - (width - 1) * TILE / 2 + column * TILE
        for row in range(depth):
            z = cz - (depth - 1) * TILE / 2 + row * TILE
            if ridge_along_x:
                outward = (0, 1) if z > cz else (0, -1)
            else:
                outward = (1, 0) if x > cx else (-1, 0)
            if abs((z - cz) if ridge_along_x else (x - cx)) < 0.1:
                # Case du milieu d'un côté impair : un toit plat au niveau du faîte.
                scene.add("fantasy_town_kit/roof-flat", (x, base + 0.5 * TILE, z), 0.0, TILE)
            else:
                scene.add("fantasy_town_kit/roof", (x, base, z), OUTWARD_ANGLES[(-outward[0], -outward[1])], TILE)


# Dessus de la tuile « roof », dans le repère du modèle : une droite qui monte de la gouttière (x = -0,57, y = 0,02)
# au faîte (x = 0,5, y = 0,63). Le dessus de la tuile « roof-flat » est à 0,126.
ROOF_SURFACE = (0.343, 0.566)
# Cheminée du toit : chimney-top, un conduit coiffé de son chapeau, plus large, en haut. Le modèle « chimney » a sa
# bague à mi-hauteur : posé sur le toit, son haut semblait au milieu du conduit, comme une cheminée à l'envers.
# Le conduit est centré à 0,339 de l'origine du modèle sur x, et large de 0,172 (x) sur 0,26 (z).
CHIMNEY_SCALE = 3.0
CHIMNEY_AXIS = 0.339
CHIMNEY_HALF = 0.086


def roof_ridge_along_x(width, depth):
    """Même règle que roof() : le faîte court le long de x seulement si la largeur est impaire et la profondeur paire."""
    return width % 2 == 1 and depth % 2 == 0


def roof_surface(house, x, z):
    """Hauteur du dessus du toit à deux pans d'une maison (roof()) au point (x, z)."""
    cx, cz, width, depth, _, _, floors = house
    base = WALL_HEIGHT * floors
    along_x = roof_ridge_along_x(width, depth)
    count, distance = (depth, abs(z - cz)) if along_x else (width, abs(x - cx))
    # Rangée de tuiles sous le point : distance de son centre au faîte.
    centers = [abs(-(count - 1) * TILE / 2 + index * TILE) for index in range(count)]
    center = min(centers, key=lambda c: abs(c - distance))
    if center < 0.1:
        return base + (0.5 + 0.126) * TILE
    low, rise = ROOF_SURFACE
    return base + TILE * (low + rise * (center - distance) / TILE)


def chimney(scene, house, x, z):
    """Cheminée qui sort du toit au point (x, z), son côté long le long du faîte. Le bas du conduit s'arrête juste
    sous le toit, du côté de la gouttière où le pan est le plus bas : on ne voit que le conduit et son chapeau."""
    cx, cz, width, depth, *_ = house
    along_x = roof_ridge_along_x(width, depth)
    # Tourné d'un quart de tour, le x du modèle (la largeur du conduit) suit la pente, vers -z.
    degrees = 90.0 if along_x else 0.0
    axis = CHIMNEY_AXIS * CHIMNEY_SCALE
    half = CHIMNEY_HALF * CHIMNEY_SCALE
    if along_x:
        origin = (x, z + axis)
        low = roof_surface(house, x, z + math.copysign(half, z - cz))
    else:
        origin = (x - axis, z)
        low = roof_surface(house, x + math.copysign(half, x - cx), z)
    scene.add("fantasy_town_kit/chimney-top", (origin[0], low - 0.08, origin[1]), degrees, CHIMNEY_SCALE)


class HouseFrame:
    """Repère d'une maison tourné vers sa porte : u le long de la façade, v vers la porte."""

    def __init__(self, house):
        self.cx, self.cz, width, depth, self.door, _, _ = house
        self.yaw = DOOR_YAWS[self.door]
        turned = self.door in ("east", "west")
        self.half_u = (depth if turned else width) * TILE / 2 - 0.35
        self.half_v = (width if turned else depth) * TILE / 2 - 0.35
        # Position de la porte le long de la façade : la case du milieu, décalée si le côté a un nombre pair de cases.
        count = depth if turned else width
        offset = -((count - 1) * TILE) / 2 + (count // 2) * TILE
        dx, dz = OUTWARDS[self.door]
        door_x, door_z = (0.0, offset) if dx else (offset, 0.0)
        c, s = math.cos(math.radians(self.yaw)), math.sin(math.radians(self.yaw))
        self.door_u = c * door_x - s * door_z

    def at(self, u, v, y=0.0):
        c, s = math.cos(math.radians(self.yaw)), math.sin(math.radians(self.yaw))
        return (self.cx + c * u + s * v, y, self.cz - s * u + c * v)

    def turn(self, degrees):
        return self.yaw + degrees


class Room:
    """Aide à meubler un bâtiment dans le repère de sa porte (HouseFrame) : u le long de la façade (vers la droite
    quand on entre), v vers la porte. Les angles sont comptés depuis la façade : 0 tourne la face avant (+Z) d'un
    modèle vers la porte, 180 vers le fond, 90 vers la droite, -90 vers la gauche."""

    def __init__(self, scene, house, ruined, rng):
        self.scene, self.house, self.ruined, self.rng = scene, house, ruined, rng
        self.frame = HouseFrame(house)
        self.hu, self.hv = self.frame.half_u, self.frame.half_v
        self.door_u = self.frame.door_u
        # Face intérieure des murs : les murs du kit ont 0,4 m d'épaisseur, centrés sur le bord des cases, et leur
        # collision 0,5 m. Les meubles s'arrêtent à la collision (wall_u, wall_v), les panneaux et les inscriptions se
        # posent sur la face visible (face_u, face_v).
        self.wall_u, self.wall_v = self.hu + 0.1, self.hv + 0.1
        self.face_u, self.face_v = self.hu + 0.1, self.hv + 0.1

    def at(self, u, v, y=0.0):
        return self.frame.at(u, v, y)

    def put(self, model, u, v, degrees=0.0, scale=2.6, height=None, y=0.0, tilt=0.0, roll=0.0):
        furniture(self.scene, model, self.frame.at(u, v, y), self.frame.turn(degrees), scale, height=height, tilt=tilt, roll=roll)

    def add(self, model, u, v, degrees=0.0, scale=1.0, y=0.0, tilt=0.0, roll=0.0):
        """Pose un modèle par son origine, sans le caler au sol ni de collision."""
        self.scene.add(model, self.frame.at(u, v, y), self.frame.turn(degrees), scale, tilt=tilt, roll=roll)

    def box(self, u, v, y, size, degrees=0.0):
        """Collision : boîte (largeur sur u, hauteur, profondeur sur v) centrée en (u, y, v)."""
        x, _, z = self.frame.at(u, v)
        self.scene.add_box((x, y, z), size, self.frame.turn(degrees))

    def outside(self, x, y, z):
        """Distance d'un point de la pièce au sol du dehors, au-delà de la face extérieure des murs (0,2 m après le
        bord des cases)."""
        cx, cz, width, depth, *_ = self.house
        flat = min(width * TILE / 2 + 0.2 - abs(x - cx), depth * TILE / 2 + 0.2 - abs(z - cz))
        return math.hypot(flat, y)

    def lamp(self, spots, energy=1.45, light_range=5.3, name="Lamp", color=None):
        """Lumière de la pièce, en points (u, v, y). Sa portée s'arrête avant le sol du dehors : sans ombres, la
        lumière d'une lampe traverse les murs, et elle éclairerait l'herbe au pied de la façade."""
        points = [self.frame.at(u, v, y) for u, v, y in spots]
        light_range = min(light_range, min(self.outside(*point) for point in points) - 0.05)
        self.scene.lamp(name, self.frame.at(0.0, 0.0, 3.0), points, energy, round(light_range, 2), color)

    def hearth_glow(self, u, v, y=0.6, energy=1.4, light_range=2.6):
        """Lueur orangée des braises d'un foyer, posée devant lui dans la pièce."""
        self.lamp([(u, v, y)], energy, light_range, name="Embers", color="Color(1, 0.48, 0.18, 1)")

    def reader(self, name, u, v, y, title, body, radius=1.8):
        """Texte à lire avec E, au point (u, v, y). Renvoie le groupe d'avant, à rétablir après un panneau."""
        return self.scene.reader(name, self.frame.at(u, v, y), title, body, "Lire : " + title, radius)

    def board(self, name, u, v, degrees, text, **options):
        """Panneau (SignBoard) en (u, v), sa face tournée de degrees, dans le repère de la pièce."""
        self.scene.board(name, self.frame.at(u, v), self.frame.turn(degrees), text, **options)

    def wall_board(self, name, side, along, text, height=1.8, **options):
        """Panneau fixé à la face intérieure d'un mur : side vaut "back", "left", "right" ou "front"."""
        u, v, degrees = self.on_wall(side, along)
        self.scene.board(name, self.frame.at(u, v), self.frame.turn(degrees), text, mount=1, height=height, **options)

    def on_wall(self, side, along, gap=0.0):
        """Point de la face intérieure d'un mur, et l'angle qui tourne une face vers la pièce."""
        if side == "back":
            return along, -self.face_v + gap, 0.0
        if side == "front":
            return along, self.face_v - gap, 180.0
        if side == "left":
            return -self.face_u + gap, along, 90.0
        return self.face_u - gap, along, -90.0

    def inscription(self, name, side, along, y, text, **options):
        """Inscription peinte ou gravée sur la face intérieure d'un mur, à 1,5 cm."""
        u, v, degrees = self.on_wall(side, along, 0.015)
        self.scene.inscription(name, self.frame.at(u, v, y), self.frame.turn(degrees), text, **options)


def furnish(scene, house, ruined, rng):
    """Meubles d'une maison : le lit de bois et son coffre, l'âtre et sa marmite sous la cheminée, la table et ses
    chaises, l'étagère de la vaisselle ; renversés et cassés dans les ruines."""
    r = Room(scene, house, ruined, rng)
    hu, hv = r.hu, r.hv
    # Lit contre le mur du fond, à gauche, et son coffre au pied ; l'âtre au fond, à droite.
    bed(r, -hu + 0.6 + (0.2 if ruined else 0.0), -r.wall_v + 1.0, broken=ruined)
    r.put("survival_kit/chest", -hu + 0.6, -r.wall_v + 2.45, 0.0, 3.0, height=0.78, tilt=90.0 if ruined and rng.random() < 0.5 else 0.0)
    hu_, hv_ = HEARTHS["house"](r.frame)
    hearth(r, hu_, hv_, "back")
    r.put("food_kit/pot-stew", hu_ + (0.5 if ruined else 0.0), hv_ + 1.27, rng.uniform(0, 360) if ruined else 0.0, 1.4, height=0.5,
          tilt=90.0 if ruined else 0.0)
    # Table et chaises au milieu, étagère contre le mur de droite.
    r.put("mini_dungeon/table", 0.6, 0.2, 0.0, 2.2, height=0.68, roll=90.0 if ruined else 0.0)
    for side in (-1, 1):
        fallen = ruined and rng.random() < 0.7
        r.put("mini_dungeon/chair", 0.6 + side * (1.5 if fallen else 1.45), 0.2, -90.0 * side + (rng.uniform(-10, 10) if fallen else 0.0), 2.2,
              tilt=90.0 if fallen else 0.0)
    if ruined:
        fallen_shelf(r, -hu + 1.0, 1.0, 90.0 + rng.uniform(-10, 10), width=1.4)
        r.add("survival_kit/resource-planks", rng.uniform(-1, 1), rng.uniform(-1, 1), rng.uniform(0, 360), 3.0)
        r.add("castle_kit/rocks-small", -hu + 1.0, hv - 1.2, rng.uniform(0, 360), 1.4)
        return
    shelf(r, r.wall_u - 0.3, 1.0, -90.0, width=1.4, height=1.3, depth=0.5, boards=3, books=False,
          items=[("food_kit/bowl", -0.35, 1, 0.8), ("food_kit/plate", 0.35, 1, 0.5), ("food_kit/mug", 0.0, 2, 0.6)])
    r.put("furniture_kit/rugRound", 0.6, 0.2, 0.0, 2.6, y=0.02)
    for u, model in ((-0.1, "food_kit/bowl"), (1.25, "food_kit/mug")):
        r.put(model, u, 0.25, 0.0, 0.8 if "bowl" in model else 0.6, y=0.68)
    r.put("graveyard_kit/candle", 0.6, -0.1, 0.0, 1.6, y=0.68)
    r.put("survival_kit/box-open", -hu + 0.5, hv - 0.6, 15.0, 2.6, height=0.8)
    if hu > 5.0:
        # Grande maison, trois cases de façade : le lit des enfants, et les réserves dans le coin de devant.
        bed(r, -hu + 1.7, -r.wall_v + 1.0)
        r.put("mini_dungeon/barrel", hu - 0.75, hv - 0.8, 0.0, 2.4, height=1.15)
        r.put("food_kit/bag", hu - 1.75, hv - 0.6, 15.0, 1.5, height=1.25)
    if hv > 5.0:
        # Maison profonde : un banc le long du mur de gauche, un tonneau au fond à gauche de l'âtre.
        r.put("fantasy_town_kit/stall-bench", -r.wall_u + 0.45, 1.6, 0.0, (3.0, 2.0, 2.6), height=0.46)
        r.put("mini_dungeon/barrel", hu - 2.6, -r.wall_v + 0.7, 0.0, 2.2, height=1.05)
    r.lamp([(0.0, 0.0, 3.0)])
    r.hearth_glow(hu_ - 1.0, hv_ + 1.5)
    # Tonneau et caisse dehors, contre la façade, du côté opposé à la porte.
    side = -1.0 if r.door_u >= 0 else 1.0
    r.put("survival_kit/barrel", side * (hu - 0.4), hv + 1.2, 0.0, 3.2, height=1.1)
    r.put("survival_kit/box", side * (hu - 1.5), hv + 1.2, 20.0, 3.2, height=0.8)


def house_floor(scene, rng, house, ruined):
    """Plancher de bois sur toutes les cases, enfoncé pour affleurer le sol : il ne gêne pas les pas.
    Dans les ruines, des lattes manquent ou sont arrachées. Les maisons à étage ont aussi le plancher de l'étage."""
    cx, cz, width, depth, _, _, floors = house
    if not ruined:
        # Couches croisées d'une seule pièce sous chaque plancher et au-dessus du plafond : entre les lattes et aux
        # joints des cases, on voit du bois, et non l'herbe du terrain ou le dessous du toit. Tournée d'un quart de
        # tour, la pièce prend la profondeur de la maison sur son axe x.
        span = (depth * TILE * 0.98, TILE, width * TILE * 0.98)
        for level in [-0.215] + [floor * WALL_HEIGHT - 0.215 for floor in range(1, floors)]:
            scene.add("fantasy_town_kit/planks", (cx, level, cz), 90.0, span)
        # Au-dessus du plafond, un panneau de bois plein (un mur de planches couché, d'une seule pièce) : par les
        # fentes des lattes, on voit du bois et non le dessous des tuiles du toit. Couché d'un quart de tour, le mur
        # prend son épaisseur (x de 0,4 à 0,5) sur la hauteur et sa hauteur sur la largeur de la maison.
        ceiling = floors * WALL_HEIGHT - 0.2
        full_width, full_depth = width * TILE * 0.98, depth * TILE * 0.98
        scene.add("fantasy_town_kit/wall-wood", (cx + full_width / 2, ceiling - 0.03, cz), 0.0, (0.5, full_width, full_depth), roll=90.0)
        # Le plafond du rez-de-chaussée arrête la tête : même depuis un coffre ou une table, un saut ne la passe
        # pas dans l'étage ou sous le toit.
        scene.add_box((cx, WALL_HEIGHT - 0.05, cz), (width * TILE, 0.3, depth * TILE))
    for column in range(width):
        for row in range(depth):
            x = cx - (width - 1) * TILE / 2 + column * TILE
            z = cz - (depth - 1) * TILE / 2 + row * TILE
            if not ruined:
                scene.add("fantasy_town_kit/planks", (x, -0.2, z), 0.0, TILE)
                for floor in range(1, floors):
                    scene.add("fantasy_town_kit/planks", (x, floor * WALL_HEIGHT - 0.2, z), 0.0, TILE)
                # Plafond sous le toit : vues d'en dessous, les tuiles du toit laisseraient voir le ciel.
                scene.add("fantasy_town_kit/planks", (x, floors * WALL_HEIGHT - 0.2, z), 0.0, TILE)
                continue
            roll = rng.random()
            if roll < 0.55:
                scene.add("fantasy_town_kit/planks", (x, -0.2, z), rng.choice((0.0, 90.0)), TILE)
            elif roll < 0.85:
                scene.add("fantasy_town_kit/planks-half", (x - TILE * 0.25, -0.2, z), 0.0, TILE)


def ruined_house(scene, rng, house, furnisher=None):
    cx, cz, width, depth, door_side, style, floors = house
    plain, broken, window, window_small = wall_models(style)
    for side, index, count, center, outward in edge_tiles(cx, cz, width, depth):
        if side == door_side and index == count // 2:
            doorway(scene, center, outward)
            arch_fill(scene, center, outward)
            continue
        roll = rng.random()
        if roll < 0.2:
            scene.add("castle_kit/rocks-small", (center[0], -0.08, center[1]), rng.uniform(0, 360), 1.6)
            scene.add_box((center[0], 0.4, center[1]), (1.6, 0.8, 1.6))
            continue
        if roll < 0.55:
            wall(scene, broken, center, outward, height=3.0)
        else:
            wall(scene, rng.choice((plain, window, window_small)), center, outward)
    half_w, half_d = width * TILE / 2, depth * TILE / 2
    pillar = "fantasy_town_kit/pillar-wood" if style == "wood" else "fantasy_town_kit/pillar-stone"
    for sx in (-1, 1):
        for sz in (-1, 1):
            scene.add(pillar, (cx + sx * half_w, 0.0, cz + sz * half_d), 0.0, WALL_SCALE)
            # Le pilier d'angle tient même quand les murs voisins sont tombés : il garde sa collision.
            scene.add_box((cx + sx * half_w, WALL_HEIGHT / 2, cz + sz * half_d), (0.6, WALL_HEIGHT, 0.6))
    house_floor(scene, rng, house, True)
    (furnisher or furnish)(scene, house, True, rng)
    fallen_beams(scene, rng, house, rng.randint(1, 2))


def fallen_beams(scene, rng, house, count):
    """Poutres de la charpente tombées au sol, couchées en travers de la pièce : chacune cherche une place libre,
    à l'écart des murs, des meubles renversés et des autres poutres, au lieu de les traverser."""
    cx, cz, width, depth, *_ = house
    half_w, half_d = width * TILE / 2 - 0.3, depth * TILE / 2 - 0.3
    taken = scene.footprints.setdefault(scene.group, [])
    for beam in range(count):
        for attempt in range(60):
            point = (cx + rng.uniform(-half_w + 1.0, half_w - 1.0), 0.0, cz + rng.uniform(-half_d + 1.0, half_d - 1.0))
            degrees = rng.uniform(0, 180)
            shape, _, _ = footprint("fantasy_town_kit/poles-horizontal", point, degrees, 3.0, roll=90.0)
            if any(abs(x - cx) > half_w or abs(z - cz) > half_d for x, z in shape):
                continue
            if all(apart(shape, other, 0.08) for other, low, high in taken if high > 0.06):
                furniture(scene, "fantasy_town_kit/poles-horizontal", point, degrees, 3.0, roll=90.0)
                break


def to_frame(frame, x, z):
    """Coordonnées (u, v) d'un point du monde dans le repère de la porte."""
    c, s = math.cos(math.radians(frame.yaw)), math.sin(math.radians(frame.yaw))
    dx, dz = x - frame.cx, z - frame.cz
    return c * dx - s * dz, s * dx + c * dz


def rebuilt_house(scene, rng, house, furnisher=None, kind=None):
    cx, cz, width, depth, door_side, style, floors = house
    plain, _, window, window_small = wall_models(style)
    frame = HouseFrame(house)
    # Murs pleins voulus à l'intérieur (foyer, tableau, inscription) : la case de mur la plus proche n'a pas de fenêtre.
    anchors = [anchor(frame) for anchor in PLAIN_WALLS.get(kind, ())]
    for side, index, count, center, outward in edge_tiles(cx, cz, width, depth):
        if side == door_side and index == count // 2:
            doorway(scene, center, outward)
            arch_fill(scene, center, outward)
            along = (outward[1], outward[0])
            lantern = (center[0] + outward[0] * 0.5 + along[0] * 1.6, center[1] + outward[1] * 0.5 + along[1] * 1.6)
            scene.add("fantasy_town_kit/lantern", (lantern[0], 0.0, lantern[1]), 0.0, 2.2)
            scene.add_box((lantern[0], 1.0, lantern[1]), (0.45, 2.0, 0.45))
        else:
            model = rng.choice((plain, window, window_small, window))
            u, v = to_frame(frame, *center)
            if any(math.hypot(u - au, v - av) < TILE / 2 - 0.05 for au, av in anchors):
                model = plain
            wall(scene, model, center, outward)
        if floors > 1:
            upper = "wall-wood-window-shutters" if index % 2 == 0 else "wall-wood"
            wall(scene, upper, center, outward, base=WALL_HEIGHT, solid=False)
    half_w, half_d = width * TILE / 2, depth * TILE / 2
    pillar = "fantasy_town_kit/pillar-wood" if style == "wood" else "fantasy_town_kit/pillar-stone"
    for sx in (-1, 1):
        for sz in (-1, 1):
            for floor in range(floors):
                scene.add(pillar, (cx + sx * half_w, floor * WALL_HEIGHT, cz + sz * half_d), 0.0, WALL_SCALE)
            scene.add_box((cx + sx * half_w, WALL_HEIGHT * floors / 2, cz + sz * half_d), (0.6, WALL_HEIGHT * floors, 0.6))
    roof(scene, cx, cz, width, depth, WALL_HEIGHT * floors)
    hearth = HEARTHS.get(kind, "default")
    if hearth == "default":
        chimney(scene, house, cx - half_w + 1.6, cz)
    elif hearth:
        # La cheminée sort du toit au-dessus du foyer de la pièce.
        x, _, z = frame.at(*hearth(frame))
        chimney(scene, house, x, z)
    house_floor(scene, rng, house, False)
    (furnisher or furnish)(scene, house, False, rng)


def house_layout(rng):
    """Maisons orientées vers le feu de camp, la porte du côté du centre."""
    houses = []
    for number, (radius, degrees) in enumerate(HOUSE_SPOTS):
        x = round(math.cos(math.radians(degrees)) * radius, 1)
        z = round(math.sin(math.radians(degrees)) * radius, 1)
        if abs(x) > abs(z):
            door = "west" if x > 0 else "east"
        else:
            door = "north" if z > 0 else "south"
        width, depth = (2, 2) if radius < 30 else rng.choice(((2, 2), (2, 3), (3, 2)))
        style = "stone" if number % 2 else "wood"
        floors = 2 if number % 3 == 0 else 1
        houses.append((x, z, width, depth, door, style, floors))
    return houses


def clear_of(houses, x, z, margin):
    """Vrai si le point est à plus de margin des murs de toutes les maisons."""
    for cx, cz, width, depth, *_ in houses:
        if abs(x - cx) < width * TILE / 2 + margin and abs(z - cz) < depth * TILE / 2 + margin:
            return False
    return True


def build_streets(scene, houses):
    """Lanternes le long des chemins, en quinconce, là où elles ne gênent ni maison ni étal."""
    for tx, tz in ROADS:
        length = math.hypot(tx, tz)
        dx, dz = tx / length, tz / length
        for index, distance in enumerate(range(10, int(min(length, 50.0)) - 3, 8)):
            side = 1 if index % 2 else -1
            x, z = dx * distance - dz * side * 2.7, dz * distance + dx * side * 2.7
            # Ni dans une maison, ni sur les étals du marché, ni sur la fontaine.
            if clear_of(houses + [house for _, house, _, _ in LANDMARKS], x, z, 1.2) and not (-18.0 < x < -11.0 and -7.0 < z < 7.0) and math.hypot(x - 30.0, z - 4.2) > 3.8:
                scene.add("fantasy_town_kit/lantern", (x, 0.0, z), 0.0, 2.2)
                scene.add_box((x, 1.0, z), (0.45, 2.0, 0.45))


def build_village(scene, rng):
    """Seize maisons, réparées quatre par quatre : d'abord les plus proches du camp."""
    houses = house_layout(rng)
    for number, house in enumerate(houses):
        stage = 1 + number // 4
        name = f"House{number:02d}"
        scene.repair(name, stage)
        ruined_house(scene, random.Random(number), house)
        scene.rebuilt(name)
        rebuilt_house(scene, random.Random(100 + number), house, kind="house")
    scene.group = "Fixed"
    build_streets(scene, houses)
    # Charrettes, foin et tonneaux entre les maisons.
    for model, x, z, degrees, height in (
        ("fantasy_town_kit/cart-high", -30.0, 2.0, 80.0, 2.4), ("graveyard_kit/hay-bale", -27.5, -1.5, 15.0, 1.0),
        ("graveyard_kit/hay-bale-bundled", -28.0, 4.6, -30.0, 1.1), ("mini_dungeon/barrel", 36.6, 5.2, 0.0, 1.2),
        ("mini_dungeon/barrel", 37.7, 4.2, 0.0, 1.2), ("fantasy_town_kit/cart-high", 4.5, 30.0, 10.0, 2.4),
    ):
        furniture(scene, model, (x, 0.0, z), degrees, 2.4 if "cart" in model else 2.6, height=height)
    # Étals du marché, qui reviennent avec le deuxième livre ; charrette renversée tant qu'il manque.
    scene.repair("Market", 2)
    furniture(scene, "fantasy_town_kit/cart", (-13.0, 0.0, -4.0), 60.0, 3.0, height=1.6, roll=90.0)
    furniture(scene, "fantasy_town_kit/wheel", (-11.6, 0.0, -6.8), 30.0, 3.0, tilt=90.0)
    scene.rebuilt("Market")
    for x, z, degrees, model in ((-15.0, -4.0, 90.0, "stall-red"), (-15.0, 4.0, 90.0, "stall-green"), (15.0, -10.0, -90.0, "stall")):
        scene.add(f"fantasy_town_kit/{model}", (x, 0.0, z), degrees, 3.0)
        # L'étal simple est un banc d'1,1 m : sa collision suit sa forme, pas celle des étals à auvent.
        scene.add_box((x, 0.55, z) if model == "stall" else (x, 1.5, z), (1.95, 1.1, 3.0) if model == "stall" else (3.0, 3.0, 3.0), degrees)
    for model, x, z in (("apple", -14.2, -4.4), ("carrot", -14.4, 4.2), ("bread", 14.6, -10.2)):
        scene.add(f"food_kit/{model}", (x, 1.1, z), rng.uniform(0, 360), 2.5)
    # Fontaine de la place est, au bord du chemin du bunker, à la rue circulaire ; sèche, puis remise en eau au troisième livre.
    scene.repair("Fountain", 3)
    fountain = (30.0, 0.0, 4.2)
    scene.add("fantasy_town_kit/fountain-round", fountain, 0.0, 3.0)
    scene.add("castle_kit/rocks-small", (fountain[0], 0.4, fountain[2]), 40.0, 1.8)
    scene.add_box((fountain[0], 0.5, fountain[2]), (5.6, 1.0, 5.6))
    scene.rebuilt("Fountain")
    scene.add("fantasy_town_kit/fountain-round-detail", fountain, 0.0, 3.0)
    scene.add_box((fountain[0], 0.5, fountain[2]), (5.6, 1.0, 5.6))
    scene.group = "Fixed"


def build_camp(scene):
    """Camp des survivants autour du feu : tentes, bancs de rondins, provisions et établi."""
    scene.add("survival_kit/campfire-pit", (0.0, 0.0, 0.0), 0.0, 6.0)
    scene.add_box((0.0, 0.3, 0.0), (1.8, 0.6, 1.8))
    for index in range(5):
        angle = math.radians(90 + index * 72)
        x, z = math.cos(angle) * 3.0, math.sin(angle) * 3.0
        scene.add("nature_kit/log", (x, 0.0, z), -math.degrees(angle), 4.0)
        scene.add_box((x, 0.35, z), (0.9, 0.7, 2.4), -math.degrees(angle))
    for x, z, degrees in ((12.0, 5.2, -115.0), (-10.5, 1.0, 100.0), (6.0, 10.0, -150.0), (-7.5, 9.0, 150.0)):
        scene.add("mini_forest/tent", (x, 0.0, z), degrees, 3.2)
        scene.add_box((x, 1.4, z), (3.4, 2.8, 3.0), degrees)
    for model, x, z, degrees, scale, size in (
        ("survival_kit/workbench", 8.5, -4.0, -60.0, 5.0, (1.5, 1.2, 1.5)),
        ("survival_kit/barrel", -8.0, -3.5, 0.0, 4.0, (1.0, 1.4, 1.0)),
        ("survival_kit/barrel", -8.9, -2.6, 30.0, 4.0, (1.0, 1.4, 1.0)),
        ("survival_kit/box-large", 9.6, -5.6, 20.0, 4.0, (1.0, 1.0, 2.0)),
        ("survival_kit/box", -9.4, -4.6, 45.0, 4.0, (1.0, 1.0, 1.0)),
        ("survival_kit/bucket", 7.4, -5.2, 0.0, 4.0, (0.6, 0.75, 0.6)),
    ):
        scene.add(model, (x, 0.0, z), degrees, scale)
        if size:
            scene.add_box((x, size[1] / 2, z), size, degrees)
    scene.add("food_kit/bread", (9.6, 1.0, -5.6), 15.0, 2.5)


# Bloc « wall » du kit du château : entre sa plinthe et sa corniche, ses faces x sont en retrait (0,465 au lieu de
# 0,5), ses faces z pleines. Ses faces z joignent donc les blocs voisins (un mur le long de x est tourné d'un quart
# de tour), et le retrait orne le dedans et le dehors du mur. Tournées l'une vers l'autre, deux faces en retrait
# laissaient entre les blocs une fente sur toute l'épaisseur du mur : des traits de jour et d'ombre.
def castle_wall_degrees(along_x):
    return 90.0 if along_x else 0.0


def curtain_wall(scene, x, z, along_x, height_scale=1.0):
    """Pan de l'enceinte ; éventré, il n'a plus qu'une partie de sa hauteur, et sa collision le suit."""
    scene.add("castle_kit/wall", (x, 0.0, z), castle_wall_degrees(along_x), (CURTAIN_SCALE, CURTAIN_SCALE * height_scale, CURTAIN_SCALE))
    height = 6.6 * height_scale
    scene.add_box((x, height / 2, z), (CURTAIN_SCALE, height, CURTAIN_SCALE))


def square_tower(scene, x, z, scale, floors, roofed=True, crowned=True):
    """Tour carrée : base, étages à fenêtres, couronnement, et son toit si elle en a un. Renvoie sa hauteur.
    Sans couronnement, la tour s'arrête net, comme décapitée."""
    y = 0.0
    for model in ["tower-square-base"] + ["tower-square-mid-windows"] * (floors - 2) + ["tower-square-mid"]:
        scene.add(f"castle_kit/{model}", (x, y, z), 0.0, scale)
        # Un étage du kit mesure 1,01 tuile : empilés à 1, deux étages se chevaucheraient et leurs faces scintilleraient.
        y += 1.01 * scale
    if crowned:
        scene.add("castle_kit/tower-square-top", (x, y, z), 0.0, scale)
        y += 0.3 * scale
    scene.add_box((x, y / 2, z), (scale, y, scale))
    if roofed:
        scene.add("castle_kit/tower-square-roof", (x, y, z), 0.0, scale)
    return y


def round_tower(scene, x, z, scale, ruined=False):
    """Grosse tour d'angle de l'enceinte, hexagonale, coiffée d'un toit pointu. Renvoie sa hauteur.
    En ruine, il ne reste que la base et un étage, sans toit."""
    y = 0.0
    pieces = [("tower-hexagon-base", 1.31), ("tower-hexagon-mid", 0.46)]
    if not ruined:
        pieces += [("tower-hexagon-mid", 0.46), ("tower-hexagon-top", 0.13)]
    for model, height in pieces:
        scene.add(f"castle_kit/{model}", (x, y, z), 0.0, scale)
        y += height * scale
    if not ruined:
        scene.add("castle_kit/tower-hexagon-roof", (x, y, z), 0.0, scale)
    scene.add_box((x, y / 2, z), (0.8 * scale, y, 0.7 * scale))
    return y


# Pans de l'enceinte éventrés par la guerre : (côté, position le long du côté). Ils sont relevés au deuxième livre.
BROKEN_WALLS = {("back", -12.5), ("back", 7.5), ("back", 17.5), ("front", -17.5),
                ("west", -77.5), ("west", -62.5), ("east", -82.5), ("east", -67.5)}


def rubble(scene, rng, x, z, along_x, count=3, spread=1.6):
    """Blocs tombés au pied d'un mur, en ligne le long du mur, avec leur collision."""
    for index in range(count):
        offset = (index - (count - 1) / 2) * spread
        px, pz = (x + offset, z) if along_x else (x, z + offset)
        px += rng.uniform(-0.3, 0.3)
        pz += rng.uniform(-0.3, 0.3)
        model = "castle_kit/rocks-small" if index % 2 else "castle_kit/rocks-large"
        scale = rng.uniform(1.8, 2.3)
        scene.add(model, (px, 0.0, pz), rng.uniform(0, 360), scale)
        scene.add_box((px, 0.25 * scale, pz), (1.15 * scale, 0.5 * scale, 1.2 * scale))


# Emprise réelle des engins de siège reconstruits, par tranche de hauteur (sommets de leurs maillages, en x et z du
# modèle ; hauteur de chaque boîte en mètres). La boîte de MODEL_BOXES de la baliste débordait de 0,33 unité d'un
# côté ; celle de la catapulte montait à 2,6 m au-dessus de son bras, qui traîne bas vers l'arrière : un mur
# invisible (grille de marche de la cour). Le bras a sa boîte basse (sous la hauteur d'un pas), le bâti sa boîte haute ; les roues gardent
# leur largeur (±0,6).
ENGINE_FOOTPRINTS = {
    "castle_kit/siege-ballista": [(-0.664, 0.664, -0.599, 0.599, 2.2)],
    "castle_kit/siege-catapult": [(-0.734, 0.734, -0.6, 0.6, 2.6), (-1.42, -0.734, -0.472, 0.472, 0.26)],
}


def engine_box(scene, model, center, degrees, scale):
    """Collision d'un engin de siège à son emprise réelle : le modèle est posé par furniture(), centré sur la boîte de
    MODEL_BOXES ; on retrouve son origine, puis on pose une boîte tournée comme lui sur ses sommets."""
    (px, _, pz), (sx, _, sz) = MODEL_BOXES[model]
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))

    def turned(x, z):
        return c * x + s * z, -s * x + c * z

    bx, bz = turned((px + sx / 2) * scale, (pz + sz / 2) * scale)
    origin = (center[0] - bx, center[2] - bz)
    for x0, x1, z0, z1, height in ENGINE_FOOTPRINTS[model]:
        gx, gz = turned((x0 + x1) / 2 * scale, (z0 + z1) / 2 * scale)
        scene.add_box((origin[0] + gx, center[1] + height / 2, origin[1] + gz), ((x1 - x0) * scale, height, (z1 - z0) * scale), degrees)


def build_castle(scene, rng):
    """Château du roi, en ruine au début de la partie : pans d'enceinte éventrés, tours d'angle et porterie
    décapitées, cour encombrée des engins de siège brisés. Il se relève livre après livre : la porterie au premier,
    l'enceinte et la cour au deuxième, les tours d'angle et les drapeaux au troisième, les toits du donjon au dernier.
    Au cœur du donjon, la salle du trône et son cercle magique (posés dans hub.tscn)."""
    half = CURTAIN_SCALE / 2
    steps = int(CASTLE_X * 2 / CURTAIN_SCALE)
    segments = []
    for index in range(steps):
        x = -CASTLE_X + half + index * CURTAIN_SCALE
        segments.append(("back", x, x, CASTLE_BACK + half, True))
        if abs(x) > 8.0:
            segments.append(("front", x, x, CASTLE_FRONT - half, True))
    for index in range(1, int((CASTLE_FRONT - CASTLE_BACK) / CURTAIN_SCALE) - 1):
        z = CASTLE_BACK + half + index * CURTAIN_SCALE
        segments.append(("west", z, -CASTLE_X + half, z, False))
        segments.append(("east", z, CASTLE_X - half, z, False))
    for side, key, x, z, along_x in segments:
        if (side, key) not in BROKEN_WALLS:
            curtain_wall(scene, x, z, along_x)
    outward = {"back": (0, -1), "front": (0, 1), "west": (-1, 0), "east": (1, 0)}
    scene.repair("CastleWalls", 2)
    for side, key, x, z, along_x in segments:
        if (side, key) in BROKEN_WALLS:
            curtain_wall(scene, x, z, along_x, 0.42)
            ox, oz = outward[side]
            rubble(scene, rng, x + ox * 4.2, z + oz * 4.2, along_x)
    scene.rebuilt("CastleWalls")
    for side, key, x, z, along_x in segments:
        if (side, key) in BROKEN_WALLS:
            curtain_wall(scene, x, z, along_x)
    scene.group = "Fixed"

    # Tours d'angle : décapitées jusqu'au troisième livre.
    corners = [(x, z) for x in (-CASTLE_X + half, CASTLE_X - half) for z in (CASTLE_BACK + half, CASTLE_FRONT - half)]
    scene.repair("CastleTowers", 3)
    for x, z in corners:
        top = round_tower(scene, x, z, 7.0, ruined=True)
        scene.add("castle_kit/rocks-small", (x + 0.6, top - 0.4, z - 0.5), rng.uniform(0, 360), 2.4)
    scene.rebuilt("CastleTowers")
    # Pointe de chaque toit, où planter un drapeau : 0,83 tuile pour le toit hexagonal, 2 pour le toit carré.
    tops = [(x, round_tower(scene, x, z, 7.0) + 0.83 * 7.0 - 0.2, z) for x, z in corners]

    # Porterie : deux tours carrées et une arche voûtée entre elles, la herse relevée. Les tours et le mur au-dessus
    # de l'arche sont tombés ; ils se relèvent au premier livre. L'arche, elle, a tenu : le passage reste ouvert.
    gate_z = CASTLE_FRONT - half
    scene.repair("CastleGate", 1)
    for x in (-7.5, 7.5):
        top = square_tower(scene, x, gate_z, CURTAIN_SCALE, 2, roofed=False, crowned=False)
        scene.add("castle_kit/rocks-small", (x + 0.5, top - 0.3, gate_z - 0.4), rng.uniform(0, 360), 2.0)
    rubble(scene, rng, -11.0, gate_z + 4.6, True, count=2, spread=2.2)
    scene.rebuilt("CastleGate")
    for x in (-7.5, 7.5):
        tops.append((x, square_tower(scene, x, gate_z, CURTAIN_SCALE, 4) + 2.01 * CURTAIN_SCALE - 0.3, gate_z))
    scene.add("castle_kit/wall", (0.0, 10.4, gate_z), castle_wall_degrees(True), CURTAIN_SCALE)
    scene.add_box((0.0, 11.0, gate_z), (5.0, 7.2, 9.8))
    for x in (-4.4, 4.4):
        scene.add("castle_kit/flag-banner-long", (x, 4.0, gate_z + 4.95), 90.0, 3.0)
    scene.group = "Fixed"
    scene.add("castle_kit/tower-square-arch", (0.0, 0.0, gate_z), 0.0, 10.5)
    for sign in (-1, 1):
        scene.add_box((sign * 3.75, 5.3, gate_z), (2.5, 10.6, 9.8))
    scene.add("castle_kit/metal-gate", (0.0, 5.2, gate_z + 2.6), 90.0, 5.0)

    # Donjon : deux rangées de murs épais, quatre tours carrées et un portail voûté au sud.
    keep_half = KEEP_SCALE / 2
    for layer in range(2):
        y = layer * KEEP_LAYER
        # La rangée du haut recouvre les créneaux de celle du bas : un peu plus épaisse (x du bloc, son épaisseur
        # une fois tourné), ses faces passent devant au lieu de se confondre avec celles du bas, qui scintilleraient.
        scale = KEEP_SCALE if layer == 0 else (KEEP_SCALE * 1.03, KEEP_SCALE, KEEP_SCALE)
        for x in range(int(-KEEP_X), int(KEEP_X) + 1, int(KEEP_SCALE)):
            for z in (KEEP_BACK, KEEP_FRONT):
                if z == KEEP_FRONT and x == 0 and layer == 0:
                    continue
                scene.add("castle_kit/wall", (x, y, z), castle_wall_degrees(True), scale)
        for z in range(int(KEEP_BACK + KEEP_SCALE), int(KEEP_FRONT), int(KEEP_SCALE)):
            for x in (-KEEP_X, KEEP_X):
                scene.add("castle_kit/wall", (x, y, z), castle_wall_degrees(False), scale)
    height = KEEP_LAYER + 1.31 * KEEP_SCALE
    for x in range(int(-KEEP_X), int(KEEP_X) + 1, int(KEEP_SCALE)):
        scene.add_box((x, height / 2, KEEP_BACK), (KEEP_SCALE, height, KEEP_SCALE))
        if x != 0:
            scene.add_box((x, height / 2, KEEP_FRONT), (KEEP_SCALE, height, KEEP_SCALE))
    scene.add_box((0.0, (height + KEEP_LAYER) / 2, KEEP_FRONT), (KEEP_SCALE, height - KEEP_LAYER, KEEP_SCALE))
    for x in (-KEEP_X, KEEP_X):
        scene.add_box((x, height / 2, (KEEP_BACK + KEEP_FRONT) / 2), (KEEP_SCALE, height, KEEP_FRONT - KEEP_BACK))
    scene.add("castle_kit/tower-square-arch", (0.0, 0.0, KEEP_FRONT), 0.0, 6.0)
    for sign in (-1, 1):
        scene.add_box((sign * 2.05, 2.2, KEEP_FRONT), (1.5, 4.4, 5.6))
    for x in (-6.0, 6.0):
        scene.add("castle_kit/flag-banner-long", (x, 4.6, KEEP_FRONT + keep_half + 0.1), 90.0, 3.0)
    keep_corners = [(x, z) for x in (-KEEP_X - 1.0, KEEP_X + 1.0) for z in (KEEP_BACK - 0.5, KEEP_FRONT + 0.5)]

    # Salle du trône : colonnes, bannières et boucliers contre les murs. Le dallage reste nu : le cercle magique
    # y est incrusté (hub.tscn).
    for x in (-7.0, -2.4, 2.4, 7.0):
        for z in (-85.6, -76.4):
            for floor in range(2):
                scene.add("fantasy_town_kit/pillar-stone", (x, floor * WALL_HEIGHT, z), 0.0, WALL_SCALE)
            scene.add_box((x, WALL_HEIGHT, z), (0.7, 2 * WALL_HEIGHT, 0.7))
    # Le drap de la bannière est décalé de 0,4 tuile de son origine, comme les murs du kit.
    for z in (-84.0, -78.0):
        for x, degrees in ((-8.55, 180.0), (8.55, 0.0)):
            scene.add("fantasy_town_kit/banner-red", (x, 2.6, z), degrees, 3.4)
    for x, degrees in ((-9.75, 90.0), (9.75, -90.0)):
        for z in (-86.0, -81.0, -76.0):
            furniture(scene, "mini_dungeon/shield-round", (x, 4.6, z), degrees, 3.0)

    # Cour : puits, écurie, chariot, provisions, râteliers d'armes et braseros. Rien sur les allées qui mènent
    # de la porterie aux quatre coins de la cour et au donjon.
    furniture(scene, "castle_kit/tree-small", (18.0, 0.0, -84.8), 70.0, 3.2, height=4.0)
    scene.add("fantasy_town_kit/fountain-square", (-15.0, 0.0, -60.0), 0.0, 1.6)
    scene.add_box((-15.0, 0.4, -60.0), (3.2, 0.8, 3.2))
    for z in (-62.0, -66.0):
        scene.add("fantasy_town_kit/fence", (14.0, 0.0, z), 0.0, 4.0)
        scene.add_box((15.7, 0.8, z), (0.3, 1.6, 4.0))
    # Le modèle de barrière est décalé de 0,42 tuile de son origine : tourné, il ferme l'enclos à z = -68.
    scene.add("fantasy_town_kit/fence", (18.0, 0.0, -66.3), 90.0, 4.0)
    scene.add_box((18.0, 0.8, -68.0), (4.0, 1.6, 0.3))
    for model, x, z, degrees, height in (
        ("graveyard_kit/hay-bale", 18.9, -62.5, 10.0, 1.0), ("graveyard_kit/hay-bale-bundled", 18.4, -65.0, -20.0, 1.1),
        ("fantasy_town_kit/cart-high", 13.5, -56.4, 90.0, 2.4), ("mini_dungeon/barrel", -9.0, -56.5, 0.0, 1.2),
        ("mini_dungeon/barrel", -10.2, -57.4, 0.0, 1.2), ("mini_dungeon/chest", -11.5, -56.3, 15.0, 0.8),
        ("survival_kit/box-large", -13.2, -56.0, 0.0, 0.9),
    ):
        furniture(scene, model, (x, 0.0, z), degrees, 2.4 if "cart" in model else 2.6, height=height)
    # Râtelier de lances contre l'enceinte ouest.
    for z in (-57.5, -59.0, -60.5):
        furniture(scene, "mini_dungeon/weapon-spear", (-19.4, 0.0, z), 90.0, 3.4, height=2.0)
    for x, z in ((-4.5, -69.5), (4.5, -69.5), (-4.0, -55.5), (4.0, -55.5)):
        furniture(scene, "graveyard_kit/fire-basket", (x, 0.0, z), 0.0, 3.0, height=0.6)

    # Cour : engins de siège brisés et blocs tombés, rangés et remplacés au deuxième livre.
    scene.repair("CastleCourt", 2)
    furniture(scene, "castle_kit/siege-catapult-demolished", (-9.0, 0.0, -68.2), 10.0, 2.6, height=1.0)
    furniture(scene, "castle_kit/siege-ram-demolished", (10.2, 0.0, -68.4), -15.0, 1.7, height=1.2)
    for x, z in ((-6.0, -57.0), (7.5, -57.0)):
        scene.add("castle_kit/rocks-large", (x, 0.0, z), rng.uniform(0, 360), 2.0)
        scene.add_box((x, 0.5, z), (2.3, 1.0, 2.4))
    scene.rebuilt("CastleCourt")
    for model, point, degrees in (("castle_kit/siege-catapult", (-9.0, 0.0, -68.3), 0.0),
                                  ("castle_kit/siege-ballista", (10.0, 0.0, -68.4), -30.0)):
        furniture(scene, model, point, degrees, 2.6)
        engine_box(scene, model, point, degrees, 2.6)
    for x, z in ((-8.0, -61.0), (8.0, -61.0)):
        scene.add("nature_kit/plant_bushLarge", (x, 0.0, z), rng.uniform(0, 360), 3.0)
    # Drapeaux hissés au troisième livre.
    scene.repair("CastleFlags", 3)
    scene.rebuilt("CastleFlags")
    for x, y, z in tops:
        scene.add("castle_kit/flag", (x, y, z), 0.0, 4.0)
    for x in (-17.5, 17.5):
        scene.add("castle_kit/flag-banner-long", (x, 1.4, CASTLE_FRONT - CURTAIN_SCALE - 0.1), 90.0, 3.0)
    # Tours du donjon : leurs toits effondrés sont relevés avec le quatrième livre.
    scene.repair("KeepRoofs", 4)
    for x, z in keep_corners:
        top = square_tower(scene, x, z, CURTAIN_SCALE, 5, roofed=False)
        scene.add("castle_kit/rocks-small", (x + 0.8, top, z - 0.6), rng.uniform(0, 360), 2.0)
    scene.rebuilt("KeepRoofs")
    for x, z in keep_corners:
        top = square_tower(scene, x, z, CURTAIN_SCALE, 5)
        scene.add("castle_kit/flag", (x, top + 2.01 * CURTAIN_SCALE - 0.3, z), 0.0, 4.0)
    scene.group = "Fixed"


def build_bunker(scene, rng):
    """Bunker de l'est : une casemate de pierre pleine, porte de fer vers le village, sous un tertre de rochers."""
    bx, bz = BUNKER
    width, depth = 2, 3
    for side, index, count, center, outward in edge_tiles(bx, bz, width, depth):
        if side == "west" and index == count // 2:
            wall(scene, "wall-doorway-square", center, outward, solid=False)
            scene.add_box((center[0], WALL_HEIGHT / 2, center[1]), (0.5, WALL_HEIGHT, TILE))
        else:
            wall(scene, "wall-block", center, outward)
    for column in range(width):
        for row in range(depth):
            scene.add("fantasy_town_kit/roof-flat", (bx - TILE / 2 + column * TILE, WALL_HEIGHT, bz - TILE + row * TILE), 0.0, TILE)
    scene.add("castle_kit/metal-gate", (bx - TILE - 0.1, 0.0, bz), 0.0, 4.2)
    for dz in (-2.6, 2.6):
        scene.add("survival_kit/metal-panel", (bx - TILE - 0.3, 0.0, bz + dz), 90.0, 3.4)
        scene.add_box((bx - TILE - 0.3, 0.85, bz + dz), (0.25, 1.7, 1.7))
    # Rochers entassés sur les flancs et le toit : de loin, un tertre.
    for index in range(14):
        angle = math.radians(-80 + index * (160 / 13))
        x, z = bx + 1.5 + math.cos(angle) * 6.0, bz + math.sin(angle) * 8.0
        scene.add("castle_kit/rocks-large", (x, 0.0, z), rng.uniform(0, 360), rng.uniform(4.0, 5.5))
        scene.add_box((x, 1.2, z), (3.0, 2.4, 3.0))
    for x, z in ((bx + 1.0, bz - 3.0), (bx + 2.0, bz + 2.5), (bx - 1.0, bz)):
        scene.add("castle_kit/rocks-large", (x, WALL_HEIGHT - 0.6, z), rng.uniform(0, 360), 4.5)


def build_shelter():
    """Abri des survivants, sous le bunker : lits superposés, couchages, table commune, réserves et cuisine."""
    scene = Scene("HubBunker")
    rng = random.Random(5816)
    cx, cz, width, depth = SHELTER
    half_w, half_d = width * TILE / 2, depth * TILE / 2
    for side, index, count, center, outward in edge_tiles(cx, cz, width, depth):
        if side == "south" and index == count // 2:
            # Porte fermée vers l'escalier de la surface : son encadrement déborde d'un côté du mur, tourné vers le dehors.
            wall(scene, "wall-door", center, (-outward[0], -outward[1]))
        else:
            wall(scene, rng.choice(("wall", "wall", "wall-detail-horizontal")), center, outward)
    for sx in (-1, 1):
        for sz in (-1, 1):
            scene.add("fantasy_town_kit/pillar-stone", (cx + sx * half_w, 0.0, cz + sz * half_d), 0.0, WALL_SCALE)
    # Plancher affleurant et plafond de planches, retourné pour se voir d'en dessous.
    for column in range(width):
        for row in range(depth):
            x = cx - (width - 1) * TILE / 2 + column * TILE
            z = cz - (depth - 1) * TILE / 2 + row * TILE
            scene.add("fantasy_town_kit/planks", (x, -0.2, z), 0.0, TILE)
            scene.add("fantasy_town_kit/planks", (x, WALL_HEIGHT + 0.24, z), 0.0, TILE, tilt=180.0)
    scene.add_box((cx, -0.2, cz), (width * TILE, 0.48, depth * TILE))
    # Plafond plein, de mur à mur et au-delà : même en sautant depuis un lit superposé, on ne sort pas de l'abri.
    scene.add_box((cx, WALL_HEIGHT + 0.5, cz), (width * TILE + 2.0, 1.0, depth * TILE + 2.0))
    # Panneau de bois plein au-dessus du plafond (un mur de planches couché, d'une seule pièce) : l'abri est enterré,
    # et entre les planches on voit du bois, non le vert des tuiles d'un toit.
    full_width, full_depth = width * TILE * 0.99, depth * TILE * 0.99
    scene.add("fantasy_town_kit/wall-wood", (cx + full_width / 2, WALL_HEIGHT + 0.05, cz), 0.0, (0.5, full_width, full_depth), roll=90.0)
    # Dortoir au nord : lits superposés à l'ouest, couchages à même le sol à l'est.
    for x in (-8.2, -5.4):
        furniture(scene, "furniture_kit/bedBunk", (x, 0.0, -3.9), 0.0, 2.0, height=2.0)
    for x in (5.6, 7.2, 8.8):
        furniture(scene, "survival_kit/bedroll", (x, 0.0, -4.4), rng.uniform(-8, 8), 3.0)
    # Table commune et ses bancs, à l'ouest.
    furniture(scene, "mini_dungeon/table", (-5.6, 0.0, 2.0), 0.0, 3.2, height=1.0)
    for x in (-6.4, -4.8):
        for z, yaw in ((0.4, 0.0), (3.6, 180.0)):
            furniture(scene, "furniture_kit/bench", (x, 0.0, z), yaw, 3.0)
    furniture(scene, "graveyard_kit/lantern-candle", (-5.6, 1.0, 2.0), 0.0, 2.4)
    for z in (-0.8, 1.2, 3.2):
        furniture(scene, "furniture_kit/bookcaseClosed", (-9.4, 0.0, z), 90.0, 3.0, height=2.6)
    # Cuisine et établi à l'est, réserves dans les coins sud.
    furniture(scene, "furniture_kit/kitchenStove", (9.1, 0.0, 0.2), -90.0, 2.6, height=1.2)
    furniture(scene, "furniture_kit/kitchenCabinet", (9.1, 0.0, -1.0), -90.0, 2.6, height=1.2)
    furniture(scene, "survival_kit/workbench", (8.0, 0.0, 2.6), -90.0, 5.0, height=1.2)
    for x, z in ((-8.8, 4.9), (-7.6, 4.9)):
        furniture(scene, "mini_dungeon/barrel", (x, 0.0, z), rng.uniform(0, 360), 2.6, height=1.2)
    for x, z in ((8.8, 4.9), (8.8, 3.7)):
        furniture(scene, "survival_kit/box-large", (x, 0.0, z), 90.0, 3.6, height=0.9)
    furniture(scene, "furniture_kit/rugRectangle", (0.0, 0.05, -0.8), 0.0, 3.2)
    BUNKER_OUTPUT.write_text(scene.text(), encoding="utf-8", newline="\n")
    print(f"{BUNKER_OUTPUT.name} : {len(scene.visuals)} modèles, {len(scene.colliders)} collisions")


# Foyer de chaque bâtiment, en (u, v) du repère de sa porte : la cheminée du toit sort juste au-dessus. None : pas de
# feu dans la pièce (ni cheminée) ; absent : la cheminée des maisons. Le foyer est un manteau de pierre
# (chimney-base) adossé au mur : son centre à 0,62 m de la collision du mur.
HEARTH_DEPTH = 0.62
# Recul des bûches dans l'ouverture du foyer, vers la pièce.
HEARTH_LOGS = 0.2
HEARTHS = {
    "house": lambda f: (f.half_u - 1.05, -(f.half_v + 0.1) + HEARTH_DEPTH),
    "tavern": lambda f: (0.0, -(f.half_v + 0.1) + HEARTH_DEPTH),
    "bakery": lambda f: (-f.half_u + 1.05, -(f.half_v + 0.1) + HEARTH_DEPTH),
    "forge": lambda f: (-f.half_u + 1.05, -(f.half_v + 0.1) + HEARTH_DEPTH),
    "farm": lambda f: (f.half_u + 0.1 - HEARTH_DEPTH, 0.0),
    "apothecary": lambda f: (f.half_u - 1.05, -(f.half_v + 0.1) + HEARTH_DEPTH),
    "barracks": lambda f: (-(f.half_u + 0.1) + HEARTH_DEPTH, -1.9),
    "school": None, "chapel": None, "mill": None, "stables": None, "scriptorium": None,
}
# Murs sans fenêtre voulus : points (u, v) du repère de la porte, sur la ligne du mur.
PLAIN_WALLS = {
    "house": [lambda f: (f.half_u - 1.05, -f.half_v - 0.35), lambda f: (f.half_u + 0.35, 2.0)],
    "tavern": [lambda f: (0.0, -f.half_v - 0.35), lambda f: (f.half_u + 0.35, -2.0)],
    "bakery": [lambda f: (-f.half_u + 1.05, -f.half_v - 0.35), lambda f: (-2.0, f.half_v + 0.35)],
    "forge": [lambda f: (-f.half_u + 1.05, -f.half_v - 0.35), lambda f: (f.half_u + 0.35, -2.0)],
    "farm": [lambda f: (f.half_u + 0.35, -1.0), lambda f: (f.half_u + 0.35, 1.0)],
    "apothecary": [lambda f: (f.half_u - 1.05, -f.half_v - 0.35), lambda f: (-2.0, -f.half_v - 0.35),
                   lambda f: (-f.half_u - 0.35, -2.0)],
    "barracks": [lambda f: (-f.half_u - 0.35, -1.9), lambda f: (0.0, -f.half_v - 0.35)],
    "school": [lambda f: (0.0, -f.half_v - 0.35), lambda f: (-f.half_u - 0.35, -2.0), lambda f: (f.half_u + 0.35, -2.0)],
    "scriptorium": [lambda f, side=side, v=v: (side * (f.half_u + 0.35), v) for side in (-1, 1) for v in (-2.0, 2.0)],
    "chapel": [lambda f: (0.0, -f.half_v - 0.35)],
    "stables": [lambda f: (f.half_u + 0.35, -4.0), lambda f: (f.half_u + 0.35, 0.0), lambda f: (f.half_u + 0.35, 4.0)],
}


# Bâtiments publics du village, autour du cœur : (nom, maison, palier de réparation, ameublement).
# Leur porte regarde le feu de camp. Les panneaux et leurs textes sont posés dans hub.tscn.
LANDMARKS = [
    ("School", (0.0, 60.0, 3, 2, "north", "stone", 2), 2, "school"),
    ("Tavern", (-60.0, 0.0, 3, 2, "east", "wood", 2), 1, "tavern"),
    ("Chapel", (-56.0, -30.0, 2, 3, "east", "stone", 1), 3, "chapel"),
    ("Forge", (55.0, 18.0, 2, 2, "west", "stone", 1), 1, "forge"),
    ("Farm", (44.0, 64.0, 2, 2, "north", "wood", 1), 2, "farm"),
]


def frame_offset(degrees, x, z):
    """Décalage (u, v) d'un point (x, z) du repère d'un modèle tourné de degrees dans le repère de la pièce."""
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
    return c * x + s * z, -s * x + c * z


def shelf(r, u, v, degrees, width=1.6, height=2.0, depth=0.5, boards=4, books=True, items=()):
    """Étagère de bois faite de planches sur quatre montants, sa face tournée de degrees, dos au mur. Des livres sur
    les planches du milieu ; items : (modèle, x le long de l'étagère, planche, échelle) posés en plus."""
    step = (height - 0.16) / (boards - 1)
    for k in range(boards):
        r.add("fantasy_town_kit/planks", u, v, degrees, (width, 1.0, depth), y=0.1 + k * step)
    for sx in (-1, 1):
        for sz in (-1, 1):
            du, dv = frame_offset(degrees, sx * (width / 2 - 0.05), sz * (depth / 2 - 0.05))
            r.add("fantasy_town_kit/pillar-wood", u + du, v + dv, degrees, (0.55, height, 0.55))
    r.box(u, v, height / 2, (width, height, depth), degrees)
    rng = r.rng
    if books:
        for k in range(1, boards - 1):
            x = -width / 2 + 0.25
            while x < width / 2 - 0.3:
                if rng.random() < 0.8:
                    du, dv = frame_offset(degrees, x + 0.15, -0.02)
                    r.put("furniture_kit/books", u + du, v + dv, degrees + rng.uniform(-8, 8), 2.2, y=0.16 + k * step)
                x += 0.42
    for model, x, board, scale in items:
        du, dv = frame_offset(degrees, x, 0.0)
        r.put(model, u + du, v + dv, degrees + rng.uniform(-20, 20), scale, y=0.16 + board * step)


def bed(r, u, v, degrees=0.0, width=0.86, length=1.95, broken=False, slide=None):
    """Lit de bois : un cadre de planches sur quatre pieds, la paillasse dessus et son traversin, la tête vers -Z du
    lit (le mur du fond quand degrees vaut 0). Cassé dans les ruines : le cadre au sol, la paillasse de travers."""
    rng = r.rng
    mat = (width * 0.92 / 0.31, 2.0, length * 0.94 / 0.61)
    if broken:
        r.add("fantasy_town_kit/planks", u, v, degrees + rng.uniform(-8, 8), (width, 1.0, length), y=0.0)
        # La paillasse a glissé de côté, vers le milieu de la pièce sauf avis contraire (slide, le long de u).
        du, dv = (-math.copysign(0.3, u) if slide is None else slide), 0.0
        r.put("survival_kit/bedroll", u + du, v + dv, degrees + rng.uniform(-6, 6), mat, y=0.06)
        return
    top = 0.34
    r.add("fantasy_town_kit/planks", u, v, degrees, (width, 1.0, length), y=top)
    for sx in (-1, 1):
        for sz in (-1, 1):
            du, dv = frame_offset(degrees, sx * (width / 2 - 0.06), sz * (length / 2 - 0.06))
            r.add("fantasy_town_kit/pillar-wood", u + du, v + dv, degrees, (0.6, top, 0.6))
    r.put("survival_kit/bedroll", u, v, degrees, mat, y=top + 0.06)
    du, dv = frame_offset(degrees, 0.0, -length / 2 + 0.25)
    r.put("survival_kit/bedroll-packed", u + du, v + dv, degrees, (width * 0.8 / 0.26, 2.4, 2.4), y=top + 0.3)
    r.box(u, v, 0.32, (width, 0.64, length), degrees)


def fallen_shelf(r, u, v, degrees, width=1.6, depth=0.5):
    """Étagère renversée : ses planches et deux montants à terre, des livres épars."""
    for k in range(3):
        du, dv = frame_offset(degrees, 0.0, (k - 1) * 0.55)
        r.add("fantasy_town_kit/planks", u + du, v + dv, degrees + r.rng.uniform(-12, 12), (width, 1.0, depth), y=0.0)
    for k in (-1, 1):
        du, dv = frame_offset(degrees, k * width / 2, 0.0)
        r.put("fantasy_town_kit/pillar-wood", u + du, v + dv, degrees + 90.0 + r.rng.uniform(-10, 10), (0.55, 1.8, 0.55), roll=90.0)
    for index in range(3):
        du, dv = frame_offset(degrees, r.rng.uniform(-width / 2, width / 2), r.rng.uniform(-0.8, 0.8))
        r.add("furniture_kit/books", u + du, v + dv, r.rng.uniform(0, 360), 2.2)


def hearth(r, u, v, wall_side, logs=True):
    """Âtre de pierre adossé à un mur (chimney-base, ouverture vers la pièce), ses bûches et ses braises."""
    degrees = {"back": -90.0, "left": 0.0, "right": 180.0}[wall_side]
    r.put("fantasy_town_kit/chimney-base", u, v, degrees, 3.6, height=3.6)
    if logs and not r.ruined:
        inward = {"back": (0.0, 1.0), "left": (1.0, 0.0), "right": (-1.0, 0.0)}[wall_side]
        r.add("nature_kit/campfire_logs", u + inward[0] * HEARTH_LOGS, v + inward[1] * HEARTH_LOGS, degrees, 2.2)


LADDER_REACH = 0.7
# Un râtelier d'armes couché flotte de 0,15 m par unité d'échelle (mesuré par float_check) : sa boîte (MODEL_BOXES)
# est plus profonde que son modèle, on l'abaisse d'autant.
RACK_SINK = 0.15


def attic_ladder(r, u, v, degrees):
    """Échelle vers l'étage, appuyée contre un mur jusqu'au plafond : degrees tourne sa face vers la pièce (0 : appuyée
    au mur du fond). Son centre se pose à LADDER_REACH de la collision du mur : sa boîte va du pied, dans la pièce,
    au haut, contre le mur. Les échelles ne se grimpent pas : l'étage reste fermé."""
    r.put("mini_forest/ladder", u, v, degrees, 3.8, height=3.6, tilt=-12.0)


def furnish_school(scene, house, ruined, rng):
    """Salle de classe : la chaire du maître et le tableau au fond, deux rangées de tables et de bancs de part et
    d'autre de l'allée, les livres sur les étagères ; l'échelle de l'étage, où logeait le maître, dans un coin."""
    r = Room(scene, house, ruined, rng)
    hu, hv = r.hu, r.hv
    # Chaire du maître, face aux élèves, et sa chaise devant le tableau.
    r.put("mini_dungeon/table", 0.0, -hv + 1.4, 0.0, (2.2, 2.2, 1.8), height=0.68, roll=90.0 if ruined else 0.0)
    if ruined:
        r.put("mini_dungeon/chair", 1.7, -hv + 0.9, 140.0, 2.2, tilt=90.0)
    else:
        r.put("mini_dungeon/chair", 0.0, -hv + 0.38, 0.0, 2.2)
    # Tables et bancs des élèves, tournés vers la chaire : l'allée du milieu mène de la porte au maître.
    for row, v in enumerate((-0.9, 1.3)):
        for side in (-1, 1):
            u = side * 2.45
            tipped = ruined and rng.random() < 0.6
            r.put("mini_dungeon/table", u, v, rng.uniform(-20, 20) if tipped else 0.0, (3.6, 2.0, 1.6), height=0.62,
                  roll=90.0 if tipped else 0.0)
            fallen = ruined and rng.random() < 0.5
            r.put("fantasy_town_kit/stall-bench", u, v + 1.0 + (0.2 if fallen else 0.0), 90.0 + (rng.uniform(-15, 15) if fallen else 0.0),
                  (2.6, 2.0, 3.3), height=0.46, roll=90.0 if fallen else 0.0)
    # Étagères de livres dans les coins du fond, contre les murs de côté.
    for side in (-1, 1):
        if ruined and side > 0:
            fallen_shelf(r, hu - 1.4, -hv + 1.3, 80.0)
            continue
        shelf(r, side * (hu - 0.3), -hv + 1.05, -90.0 * side, width=1.6, height=2.2, depth=0.5, boards=4)
    if ruined:
        for index in range(4):
            r.add("furniture_kit/books", rng.uniform(-3.5, 3.5), rng.uniform(-1.2, 2.6), rng.uniform(0, 360), 2.4)
        return
    top = 0.68
    r.put("furniture_kit/books", -0.5, -hv + 1.4, 10.0, 2.4, y=top)
    r.put("graveyard_kit/candle", 0.55, -hv + 1.25, 0.0, 1.6, y=top)
    r.put("food_kit/apple", 0.15, -hv + 1.6, 0.0, 1.0, y=top)
    for v in (-0.9, 1.3):
        for side in (-1, 1):
            for k in (-1, 1):
                r.put("furniture_kit/books", side * 2.45 + k * 0.85, v, rng.uniform(-20, 20), 2.0, y=0.62)
    # Le tableau du maître, au mur du fond : la leçon du jour est restée écrite.
    group = r.reader("Lesson", 0.0, -hv + 0.4, 1.6, "Le tableau de la classe",
                     "À la craie, d'une écriture appliquée : « Leçon du jour : découper un problème en étapes, mettre les étapes dans l'ordre, vérifier chaque résultat. » Dessous, une autre main a ajouté : « Les anciens bâtisseurs ont tout consigné dans quatre livres. »",
                     radius=2.6)
    r.wall_board("Blackboard", "back", 0.0, "Découper,\nordonner,\nvérifier.", height=2.15, style=3, size=(2.2, 1.0), line=0.16)
    scene.group = group
    r.put("furniture_kit/rugRectangle", 0.0, 0.7, 90.0, (2.0, 1.0, 1.0), y=0.02)
    attic_ladder(r, -3.0, -r.wall_v + LADDER_REACH, 0.0)
    r.lamp([(-2.0, 0.0, 3.0), (2.0, 0.0, 3.0)])


def furnish_tavern(scene, house, ruined, rng):
    """La Chope du Dragon : l'âtre au fond, le comptoir et ses tonneaux à droite, les tables à gauche et devant ;
    l'ardoise des prix au mur, et le tonneau du fond, réservé pour le jour où Codia renaîtra."""
    r = Room(scene, house, ruined, rng)
    hu, hv = r.hu, r.hv
    hu_, hv_ = HEARTHS["tavern"](r.frame)
    hearth(r, hu_, hv_, "back")
    r.put("food_kit/pot-stew", 1.5, -hv + 0.75, 0.0, 1.4, height=0.5)
    # Comptoir le long du mur de droite, ses tabourets devant, les tonneaux derrière.
    r.put("fantasy_town_kit/stall-bench", 2.1, -1.3, 0.0, (3.6, 4.4, 3.6), height=1.0, roll=90.0 if ruined else 0.0)
    for index, v in enumerate((-2.8, -1.9, -1.0, -0.1)):
        if ruined and index == 2:
            # Tombé, il a roulé devant le comptoir.
            r.put("survival_kit/barrel", 0.75, -1.0, 90.0, 3.4, height=0.82, tilt=90.0)
            continue
        r.put("survival_kit/barrel", 3.25, v, 0.0, 3.4, height=1.15)
    for index, v in enumerate((-2.4, -1.3, -0.2)):
        if ruined and index == 1:
            continue
        r.put("fantasy_town_kit/stall-stool", 1.25, v, rng.uniform(-10, 10), 2.4, roll=90.0 if ruined else 0.0)
    # Le tonneau réservé, dans le coin du fond.
    r.put("mini_dungeon/barrel", 2.95, -hv + 0.85, 0.0, 2.6, height=1.25)
    # Tables à gauche, chacune avec ses quatre chaises ; une table et ses bancs devant, à droite de la porte.
    for index, v in enumerate((-2.6, 0.6)):
        tipped = ruined and index == 1
        r.put("mini_dungeon/table", -1.7, v, 90.0, 2.4, height=0.74, roll=90.0 if tipped else 0.0)
        for side in (-1, 1):
            for k in (-0.5, 0.5):
                fallen = ruined and rng.random() < 0.5
                if tipped:
                    # La table renversée a chassé ses chaises : celles du mur ont disparu, les autres gisent dans l'allée.
                    if side < 0:
                        r.put("mini_dungeon/chair", 0.15, v + k * 1.6, -90.0 + k * 20.0, 2.2, tilt=90.0)
                    continue
                r.put("mini_dungeon/chair", -1.7 - side * (1.37 if fallen else 1.25), v + k, 90.0 * side + (rng.uniform(-6, 6) if fallen else 0.0), 2.2,
                      tilt=90.0 if fallen else 0.0)
    r.put("mini_dungeon/table", 2.25, 3.4, 0.0, 2.4, height=0.74, roll=90.0 if ruined else 0.0)
    for v in (2.15, 4.65):
        r.put("fantasy_town_kit/stall-bench", 2.25, v, 90.0, (3.0, 2.0, 2.7), height=0.46, roll=90.0 if ruined and v > 3 else 0.0)
    if not ruined:
        attic_ladder(r, -2.5, -r.wall_v + LADDER_REACH, 0.0)
    if ruined:
        for index in range(3):
            r.add("food_kit/mug", rng.uniform(-1.0, 0.6), rng.uniform(-3.0, 2.0), rng.uniform(0, 360), 0.6, tilt=90.0)
        return
    for v in (-1.9, -0.8, 0.2):
        r.put("food_kit/mug", 2.0, v, rng.uniform(0, 360), 0.6, y=1.0)
    r.put("mini_arena/trophy", 2.1, -2.55, 180.0, 1.1, height=0.52, y=1.0)
    for v in (-2.6, 0.6):
        r.put("graveyard_kit/candle", -1.7, v, 0.0, 1.6, y=0.74)
        for k in (-0.5, 0.5):
            r.put("food_kit/mug", -2.15, v + k, rng.uniform(0, 360), 0.6, y=0.74)
            r.put("food_kit/plate", -1.25, v + k, 0.0, 0.5, y=0.74)
    r.put("food_kit/mug", 1.75, 3.3, 0.0, 0.6, y=0.74)
    r.put("food_kit/bowl", 2.65, 3.5, 0.0, 0.9, y=0.74)
    group = r.reader("Slate", 2.1, -0.8, 1.2, "L'ardoise de la Chope du Dragon",
                     "À la craie, de la main de la tavernière : « Bière de la Chope, deux sous. Ragoût du jour, trois sous. » Dessous, les ardoises des habitués, qui ne seront jamais payées, et une ligne soulignée deux fois : « Le tonneau du fond est réservé. On l'ouvrira le jour où Codia renaîtra. »",
                     radius=2.0)
    r.wall_board("Board", "right", -0.8, "Bière : 2 sous\nRagoût : 3 sous", height=1.95, style=3, size=(1.1, 0.6), line=0.12)
    scene.group = group
    r.lamp([(0.0, -2.0, 3.0), (0.0, 2.0, 3.0)])
    r.hearth_glow(hu_, hv_ + 1.5)


def furnish_chapel(scene, house, ruined, rng):
    """Chapelle des Quatre Livres : l'autel de pierre au fond, sous la prière gravée, et les quatre lutrins vides qui
    attendent les livres des anciens bâtisseurs ; trois rangs de bancs de part et d'autre de l'allée."""
    r = Room(scene, house, ruined, rng)
    hu, hv = r.hu, r.hv
    r.put("graveyard_kit/altar-stone", 0.0, -hv + 1.15, 0.0, 2.0, height=0.98)
    # Les quatre lutrins de pierre, deux de chaque côté de l'autel ; deux sont tombés dans les ruines.
    for index, u in enumerate((-3.1, -1.9, 1.9, 3.1)):
        if ruined and index in (0, 3):
            r.put("nature_kit/statue_column", u * 0.9, -hv + 1.3, rng.uniform(60, 120), (1.3, 1.15, 1.3), height=0.38, tilt=90.0)
            continue
        r.put("nature_kit/statue_column", u, -hv + 0.7, 0.0, (1.3, 1.15, 1.3), height=1.15)
    for row, v in enumerate((-0.45, 1.65)):
        for side in (-1, 1):
            fallen = ruined and rng.random() < 0.5
            r.put("graveyard_kit/bench", side * 2.2 + (rng.uniform(-0.2, 0.2) if ruined else 0.0), v,
                  180.0 + (rng.uniform(-20, 20) if ruined else 0.0), 2.4, height=1.1, roll=90.0 if fallen else 0.0)
    for side in (-1, 1):
        r.put("graveyard_kit/urn-round", side * (hu - 0.4), -hv + 0.45, 0.0, 2.2, height=0.84, tilt=90.0 if ruined and side > 0 else 0.0)
    if ruined:
        r.put("graveyard_kit/candle-multiple", 0.2, -1.45, 40.0, 2.0, tilt=90.0)
        return
    for u in (-0.7, 0.7):
        r.put("graveyard_kit/candle-multiple", u, -hv + 1.15, 0.0, 2.0, y=0.98)
    # Bronze sombre : l'or clair de 0.55, 0.42, 0.18 ne ressortait qu'à 2,3 pour 1 sur la pierre claire du mur.
    r.inscription("PrayerText", "back", 0.0, 2.75, "QUE L'ORDRE, LA RIGUEUR,\nLA LOGIQUE ET LA CLARTÉ\nVEILLENT SUR CODIA",
                  pixel=0.0034, color="Color(0.27, 0.17, 0.04, 1)")
    back = r.reader("Prayer", 0.0, -hv + 1.9, 1.0, "La prière des Quatre Livres",
                    "Gravé au-dessus de l'autel : « Que l'ordre du Projenomicon, la rigueur de l'Algonicon, la logique du Logiconomicon et la clarté du Codonomicon veillent sur Codia. » De part et d'autre, quatre lutrins de pierre attendent toujours leurs livres.",
                    radius=2.4)
    scene.group = back
    r.lamp([(-2.0, 0.0, 3.0), (2.0, 0.0, 3.0)])


def furnish_forge(scene, house, ruined, rng):
    """Forge de Bran : le foyer au fond, l'enclume devant, le baquet où l'on trempait le fer, la meule, l'établi et ses
    outils, le râtelier des armes forgées pour l'armée et le carnet de commandes."""
    r = Room(scene, house, ruined, rng)
    hu, hv = r.hu, r.hv
    hu_, hv_ = HEARTHS["forge"](r.frame)
    hearth(r, hu_, hv_, "back")
    r.put("survival_kit/workbench-anvil", -1.6, -1.2, 0.0, 3.4, height=1.16, roll=90.0 if ruined else 0.0)
    r.put("survival_kit/barrel-open", -0.4, -2.3, 0.0, 3.0, height=1.0, tilt=90.0 if ruined else 0.0)
    r.put("survival_kit/workbench-grind", 1.2, -hv + 0.75, 180.0, 3.6, height=1.0)
    r.put("survival_kit/workbench", -r.wall_u + 0.5, 1.2, 90.0, (5.0, 3.0, 3.0), height=0.87, roll=90.0 if ruined else 0.0)
    tipped = ruined
    r.put("mini_arena/weapon-rack", r.wall_u - 0.6, -1.2, -90.0, 2.6, height=1.2, y=-RACK_SINK * 2.6 if tipped else 0.0, tilt=90.0 if tipped else 0.0)
    r.put("mini_dungeon/barrel", 2.9, -3.0, 0.0, 2.4, height=1.15)
    r.put("survival_kit/chest", -3.0, 2.95, 90.0, 3.0, height=0.78)
    r.put("nature_kit/log_stack", -1.2, -hv + 0.6, 0.0, 1.6, height=0.56)
    if ruined:
        r.add("survival_kit/tool-hammer", -1.0, 0.3, 30.0, 4.0, tilt=90.0)
        return
    # Dessus de l'établi : 0,2366 de son modèle (sa boîte monte à 0,29 avec le marteau et la feuille posés dessus),
    # à l'échelle 3 sur sa hauteur. Posés à 0,87, les outils et le carnet flottaient de 16 cm.
    top = 0.2366 * 3.0
    r.put("survival_kit/tool-hammer", -3.3, 0.65, 90.0, 3.4, y=top, tilt=90.0)
    r.put("survival_kit/tool-axe", -3.3, 1.85, 90.0, 3.4, y=top, tilt=90.0)
    for v in (-2.0, -0.4):
        r.put("mini_dungeon/shield-round", r.face_u - 0.13, v, -90.0, 2.2, y=2.0)
    # Épées forgées pour l'armée, la pointe dans le tonneau du coin, la garde dehors.
    for du, dv, yaw in ((-0.2, 0.1, 0.0), (0.15, -0.1, 60.0), (0.1, 0.25, 120.0)):
        r.put("mini_dungeon/weapon-sword", 2.9 + du, -3.0 + dv, yaw, 3.0, y=0.2, tilt=180.0)
    r.put("furniture_kit/books", -3.3, 1.25, 100.0, 2.4, y=top)
    back = r.reader("Orders", -3.3, 1.2, 0.95, "Le carnet de commandes",
                    "Commande de l'armée de Codia, hiver 5811 : quarante épées, soixante pointes de lance, vingt boucliers ronds. Livré : douze épées. En bas de la page, de la main de Bran : « Plus de fer, plus de charbon. Je garde le dernier marteau pour reconstruire. »",
                    radius=2.0)
    scene.group = back
    r.lamp([(0.0, 0.0, 3.0)])
    r.hearth_glow(hu_ + 1.0, hv_ + 1.5, energy=1.8)


def furnish_farm(scene, house, ruined, rng):
    """Ferme du roi : l'âtre et sa marmite, la table et ses bancs, les deux lits de bois, les réserves de grain et de
    légumes, les outils près de la porte ; dehors, les champs, le foin et l'enclos."""
    r = Room(scene, house, ruined, rng)
    hu, hv = r.hu, r.hv
    hu_, hv_ = HEARTHS["farm"](r.frame)
    hearth(r, hu_, hv_, "right")
    r.put("food_kit/pot-stew", hu_ - 1.2, hv_ - 1.3, 90.0, 1.4, height=0.5, tilt=90.0 if ruined else 0.0)
    r.put("mini_dungeon/table", -0.7, 1.1, 0.0, 2.4, height=0.74, roll=90.0 if ruined else 0.0)
    for v in (-0.08, 2.28):
        r.put("fantasy_town_kit/stall-bench", -0.7, v, 90.0, (3.0, 2.0, 2.3), height=0.46, roll=90.0 if ruined and v > 0 else 0.0)
    for index, u in enumerate((-3.15, -2.0)):
        bed(r, u, -hv + 1.15 + (0.3 if ruined and index else 0.0), broken=ruined)
    r.put("survival_kit/chest", -0.75, -hv + 0.5, 0.0, 3.0, height=0.78)
    for index, (u, v) in enumerate(((3.2, 3.1), (2.5, 3.15))):
        tipped = ruined and index == 1
        r.put("food_kit/bag", u - (0.4 if tipped else 0.0), v - (0.6 if tipped else 0.0), rng.uniform(-20, 20) if not tipped else 0.0, 1.6, height=1.3,
              y=-0.14 if tipped else 0.0, tilt=90.0 if tipped else 0.0)
    r.put("survival_kit/box-open", 1.55, 3.25, 0.0, 2.6, height=0.8)
    r.put("survival_kit/barrel-open", 3.2, 2.2, 0.0, 3.0, height=1.0)
    for v, model in ((1.0, "survival_kit/tool-hoe"), (1.5, "survival_kit/tool-shovel")):
        r.put(model, -r.wall_u + 0.35 + (0.35 if ruined and v > 1.2 else 0.0), v + (0.3 if ruined and v > 1.2 else 0.0), 90.0, 5.0,
              tilt=-10.0 if not ruined else 0.0, roll=90.0 if ruined else 0.0)
    if not ruined:
        top = 0.74
        for u in (-0.95, 0.05):
            r.put("food_kit/bowl", u, 1.45, 0.0, 0.8, y=top)
        r.put("food_kit/loaf-round", -0.3, 0.75, 20.0, 0.7, y=top)
        r.put("graveyard_kit/candle", 0.15, 0.7, 0.0, 1.6, y=top)
        for model, du, scale in (("food_kit/cabbage", -0.15, 0.6), ("food_kit/carrot", 0.15, 0.45)):
            r.put(model, 1.55 + du, 3.25, rng.uniform(0, 360), scale, y=0.8)
        r.put("furniture_kit/books", -1.55, 0.85, 80.0, 2.2, y=top)
        back = r.reader("Almanac", -1.45, 1.0, 0.9, "L'almanach de la ferme",
                        "Semailles d'automne 5811 : blé dans le champ de l'est, citrouilles le long de l'enclos. Été 5812 : les soldats de Vibelandia ont brûlé la moisson avant qu'on puisse la rentrer. Dernière ligne, avant le départ pour le bunker : « Garder les semences au sec. On replantera. »",
                        radius=2.0)
        scene.group = back
        r.lamp([(0.0, 0.0, 3.0)])
        r.hearth_glow(hu_ - 1.5, hv_)
    cx, cz = house[0], house[1]
    # Champ à l'est de la ferme : rangées de terre et de cultures, qui repoussent avec le village. Une rangée du
    # modèle est une bande de terre plate entre deux petits sillons : posée à y = 0, sa bande se confondait avec le
    # sol et scintillait en rayures, à demi cachée par l'herbe. Elle est relevée de 5 cm, ses sillons montés à 15 cm,
    # et les cultures sont plantées sur la bande.
    lift, ridge = 0.05, 0.15
    for row in range(5):
        z = cz - 5.0 + row * 2.4
        for column in range(4):
            x = cx + 8.0 + column * 2.4
            scene.add("nature_kit/crops_dirtRow", (x, lift, z), 0.0, (2.4, ridge / 0.05, 2.4))
            if not ruined:
                crop = ("nature_kit/crops_wheatStageB", "nature_kit/crops_cornStageD", "nature_kit/crop_pumpkin")[row % 3]
                scene.add(crop, (x, lift, z), rng.uniform(0, 360), 2.4)
    # Enclos et foin au sud de la ferme.
    for index in range(4):
        x = cx - 4.0 + index * 2.8
        furniture(scene, "nature_kit/fence_simple", (x, 0.0, cz + 7.0), 0.0, 2.8, height=1.0, roll=90.0 if ruined and index == 2 else 0.0)
    for x, z in ((cx - 2.5, cz + 9.0), (cx + 1.5, cz + 9.4)):
        furniture(scene, "graveyard_kit/hay-bale", (x, 0.0, z), rng.uniform(0, 60), 2.6, height=1.0)


FURNISHERS = {"school": furnish_school, "tavern": furnish_tavern, "chapel": furnish_chapel, "forge": furnish_forge, "farm": furnish_farm}


def build_landmarks(scene, rng):
    """Bâtiments publics du village, en ruine puis rebâtis à leur palier, et le cimetière de la chapelle."""
    for name, house, stage, kind in LANDMARKS:
        scene.repair(name, stage)
        ruined_house(scene, random.Random(name), house, FURNISHERS[kind])
        scene.rebuilt(name)
        rebuilt_house(scene, random.Random(name + "!"), house, FURNISHERS[kind], kind)
    scene.group = "Fixed"
    # Cimetière des soldats tombés contre les Quatre Dragons, devant la chapelle, de part et d'autre de l'allée.
    for row in range(2):
        for index in range(3):
            for side in (-1, 1):
                x = -49.5 + index * 1.8
                z = -30.0 + side * (3.4 + row * 1.6)
                model = "graveyard_kit/gravestone-cross" if (index + row) % 2 else "graveyard_kit/gravestone-round"
                furniture(scene, model, (x, 0.0, z), 90.0, 2.4, height=1.2)
    furniture(scene, "nature_kit/statue_obelisk", (-45.0, 0.0, -36.0), 0.0, 3.4, height=3.0)


# Mine d'argent : entrée de la galerie, dans un tertre de falaise au pied des montagnes du nord-est. Repère de l'entrée :
# MINE_MOUTH au ras de la façade, u le long de la façade (vers la droite quand on regarde l'entrée), v vers le dehors ;
# la façade regarde le bout de la ruelle de la mine (hub_terrain.gd : ALLEYS, 79,5 ; -38).
MINE_MOUTH = (82.6, -39.6)
MINE_YAW = -60.0
# Côté des blocs de falaise (nature_kit, cubes de 1 m), et enfoncement dans le sol, qui reste plat sur le replat de la
# mine (LANDMARKS de hub_terrain.gd : 84, -40, rayon 13).
MINE_BLOCK = 4.0
MINE_SINK = 0.3
# Profondeur de la façade percée (cliff_cave_rock : face avant à z = 0,5, face arrière à z = 0,33), et fond de la galerie,
# bouché par l'éboulis : le boisage et les planches tiennent entre les deux.
MINE_FACADE = 0.17 * MINE_BLOCK
MINE_BACK = 2.4


def mine_at(u, v, y=0.0):
    c, s = math.cos(math.radians(MINE_YAW)), math.sin(math.radians(MINE_YAW))
    return (MINE_MOUTH[0] + c * u + s * v, y, MINE_MOUTH[1] - s * u + c * v)


def mine_box(scene, u0, u1, v0, v1, y0, y1):
    """Collision d'un pavé du tertre, donné dans le repère de l'entrée."""
    scene.add_box(mine_at((u0 + u1) / 2, (v0 + v1) / 2, (y0 + y1) / 2), (u1 - u0, y1 - y0, v1 - v0), MINE_YAW)


def build_mine(scene, rng):
    """Mine d'argent au pied des montagnes, au nord-est : l'entrée d'une galerie creusée dans un tertre de falaise, son
    boisage, et des planches clouées en travers par ordre du roi Codeon V ; derrière, l'éboulis de la guerre."""
    size, sink = MINE_BLOCK, MINE_SINK
    top = size - sink
    block = "nature_kit/cliff_block_stone"
    # Cœur du tertre : la façade de pierre taillée, percée de l'entrée, puis la galerie, entre deux parois et jusqu'au
    # bloc du fond. Les rochers l'habillent ; seule la façade reste à nu.
    scene.add("nature_kit/cliff_cave_stone", mine_at(0.0, -size / 2, -sink), MINE_YAW, size)
    gallery = MINE_BACK - MINE_FACADE
    for u in (-size / 2 - 0.3, size / 2 + 0.3):
        scene.add(block, mine_at(u, -MINE_FACADE - gallery / 2, -sink), MINE_YAW, (0.6, size, gallery))
    depth = 1.5 * size - MINE_BACK
    scene.add(block, mine_at(0.0, -MINE_BACK - depth / 2, -sink), MINE_YAW, (size, size, depth))
    # Collisions du cœur : blocs pleins, galerie fermée au droit des planches, montants de la façade.
    half = size * 1.5
    mine_box(scene, -half, -size / 2, -size, 0.0, 0.0, top)
    mine_box(scene, size / 2, half, -size, 0.0, 0.0, top)
    mine_box(scene, -size / 2, size / 2, -1.5 * size, -MINE_FACADE - 0.05, 0.0, top)
    for u0, u1 in ((-size / 2, -0.4 * size), (0.4 * size, size / 2)):
        mine_box(scene, u0, u1, -MINE_FACADE - 0.05, 0.0, 0.0, top)
    # Rochers du tertre, comme celui du bunker voisin : deux qui encadrent la façade, puis les flancs et le dos, tous
    # posés au sol avec leur collision ; la crête repose sur le cœur, au-dessus de la façade, hors d'atteinte.
    for u, v, yaw, scale in ((-5.6, 0.0, 15.0, 6.0), (5.6, -0.2, -30.0, 6.0), (-7.4, -5.4, 60.0, 7.5), (7.4, -5.6, -50.0, 7.5),
                             (-3.4, -9.6, 100.0, 8.0), (3.8, -9.2, 160.0, 8.0)):
        scene.add("castle_kit/rocks-large", mine_at(u, v, -0.4), MINE_YAW + yaw, scale)
        scene.add_box(mine_at(u, v, 1.2), (0.55 * 1.2 * scale, 2.4, 0.55 * 1.35 * scale), MINE_YAW + yaw)
    scene.add("castle_kit/rocks-large", mine_at(-0.2, -3.0, top), MINE_YAW + 10.0, 5.5)
    # Boisage de la galerie : un cadre juste derrière la façade, un autre au fond, à moitié pris dans l'éboulis.
    furniture(scene, "mini_dungeon/wood-support", mine_at(0.0, -MINE_FACADE - 0.4), MINE_YAW, 2.7)
    furniture(scene, "mini_dungeon/wood-support", mine_at(0.1, -MINE_BACK + 0.35), MINE_YAW, 2.5)
    # Éboulis qui bouche la galerie, contre le bloc du fond.
    furniture(scene, "mini_dungeon/rocks", mine_at(0.0, -MINE_BACK + 0.6), MINE_YAW + 15.0, (2.4, 4.4, 1.1))
    furniture(scene, "mini_dungeon/stones", mine_at(-0.7, -MINE_BACK + 1.05), MINE_YAW + 40.0, 1.2)
    # Planches clouées en travers sur le premier cadre, et l'écriteau de l'ordre du roi.
    for y, roll in ((0.25, 0.0), (0.95, 0.0), (1.65, 0.0)):
        furniture(scene, "fantasy_town_kit/planks-half", mine_at(0.0, -MINE_FACADE - 0.06, y), MINE_YAW + 90.0,
                  (1.0, 1.0, 3.6), tilt=0.0, roll=90.0)
    scene.board("MineOrder", mine_at(0.0, -MINE_FACADE - 0.03), MINE_YAW,
                "Fermée par ordre\ndu roi Codeon V", style=0, mount=1, size=(1.15, 0.5), height=1.3, line=0.1)
    # Devant l'entrée : le wagonnet du minerai, ses outils et des caisses abandonnés.
    furniture(scene, "fantasy_town_kit/cart", mine_at(-4.2, 5.0), MINE_YAW + 75.0, 2.6, height=1.4)
    for x, z, yaw, model in ((-2.4, 4.4, 20.0, "survival_kit/tool-pickaxe"), (-2.8, 6.0, 75.0, "survival_kit/tool-shovel")):
        furniture(scene, model, mine_at(x, z), MINE_YAW + yaw, 4.0, tilt=90.0)
    furniture(scene, "survival_kit/box-large", mine_at(5.0, 5.0), MINE_YAW + 10.0, 3.6, height=0.9)
    furniture(scene, "survival_kit/box-large", mine_at(5.6, 6.3), MINE_YAW - 15.0, 3.6, height=0.9)
    # Déblais tirés de la galerie, en tas sur le côté.
    furniture(scene, "mini_dungeon/stones", mine_at(-7.0, 4.6), MINE_YAW + 70.0, 2.6, height=0.9)


# ---------------------------------------------------------------------------------------------------------------
# Quartiers autour du village : la rivière et ses métiers à l'est, la garde au nord-ouest, le savoir à l'ouest,
# l'observatoire et l'herboristerie au sud-ouest, la halle et le verger au sud, le jardin du roi au nord-est.
# Les positions reprennent LANDMARKS, ALLEYS et PARK_AREA de hub_terrain.gd.
# ---------------------------------------------------------------------------------------------------------------

# Bâtiments de pierre ou de bois bâtis comme les maisons : (nom, maison, palier de réparation, ameublement).
QUARTERS = [
    ("Bakery", (52.0, 34.0, 2, 2, "west", "stone", 1), 1, "bakery"),
    ("Mill", (61.0, 48.0, 2, 2, "west", "wood", 2), 2, "mill"),
    ("Stables", (-68.0, -46.0, 3, 2, "east", "wood", 1), 2, "stables"),
    ("Barracks", (-48.0, -66.0, 3, 2, "south", "stone", 2), 3, "barracks"),
    ("Apothecary", (-60.0, 30.0, 2, 2, "east", "wood", 1), 3, "apothecary"),
    ("Scriptorium", (-74.0, -16.0, 2, 2, "east", "stone", 2), 4, "scriptorium"),
]


def furnish_bakery(scene, house, ruined, rng):
    """Boulangerie : le four de pierre au fond, son bois, la table à pain, le pétrin où lève la pâte, les sacs de
    farine du moulin, l'étagère des miches près de la porte ; dehors, l'étal du pain du matin."""
    r = Room(scene, house, ruined, rng)
    hu, hv = r.hu, r.hv
    hu_, hv_ = HEARTHS["bakery"](r.frame)
    hearth(r, hu_, hv_, "back")
    r.put("nature_kit/log_stack", -1.2, -hv + 0.6, 0.0, 1.6, height=0.56)
    r.put("mini_dungeon/table", 0.95, -2.6, 0.0, (3.0, 3.0, 2.4), height=0.93, roll=90.0 if ruined else 0.0)
    for index, v in enumerate((-3.2, -2.25, -1.3)):
        # Un sac couché ne remplit pas sa boîte : on l'abaisse d'autant pour qu'il touche le sol.
        tipped = ruined and index == 1
        r.put("food_kit/bag", 3.25 - (0.75 if tipped else 0.0), v, rng.uniform(-20, 20) if not tipped else 90.0, 1.6,
              height=1.3, y=-0.14 if tipped else 0.0, tilt=90.0 if tipped else 0.0)
    r.put("mini_dungeon/barrel", 3.1, 0.5, 0.0, 2.4, height=1.15)
    kneading = 0.87
    r.put("mini_dungeon/table", -2.65, 0.7, 90.0, 2.8, height=kneading, roll=90.0 if ruined else 0.0)
    r.put("fantasy_town_kit/stall-stool", -1.05, 0.9, 0.0, 2.4, roll=90.0 if ruined else 0.0)
    if ruined:
        r.put("food_kit/bag-flat", 0.2, 0.3, rng.uniform(0, 90), 1.6)
        r.add("survival_kit/resource-planks", 0.6, 1.6, rng.uniform(0, 360), 3.0)
        fallen_shelf(r, -1.5, r.wall_v - 1.0, 180.0, width=1.8)
        return
    top = 0.93
    for index, model in enumerate(("food_kit/loaf", "food_kit/loaf-round", "food_kit/loaf-baguette")):
        r.put(model, -0.05 + index * 0.62, -2.6, 90.0 if index == 2 else 0.0, 0.9, y=top)
    r.put("food_kit/cutting-board", 1.95, -2.6, 90.0, 1.0, y=top)
    r.put("food_kit/rollingPin", 1.95, -2.6, 10.0, 1.0, y=top + 0.05)
    r.put("food_kit/bowl", -2.65, 0.0, 0.0, 1.5, y=kneading)
    r.put("food_kit/bag-flat", -2.55, 0.85, 80.0, 1.2, y=kneading)
    r.put("furniture_kit/books", -2.7, 1.6, 100.0, 2.4, y=kneading)
    back = r.reader("Ledger", -2.65, 1.6, 0.95, "Le livre de comptes du boulanger",
                    "Farine reçue du moulin, an 5812 : trois sacs au printemps, deux en été, un seul à l'automne. Pain cuit pour les soldats de la garde, par ordre du roi, sans paiement. Dernière ligne, d'une main pressée : « Les cloches sonnent. Le levain reste dans sa jatte. Que le premier qui reviendra rallume le four. »",
                    radius=2.0)
    scene.group = back
    # Étagère à pain contre la façade, à gauche de la porte : les miches du jour sur ses planches.
    shelf(r, -1.5, r.wall_v - 0.3, 180.0, width=1.8, height=1.6, depth=0.5, boards=3, books=False,
          items=[("food_kit/loaf-round" if k % 2 else "food_kit/loaf", -0.55 + (k % 3) * 0.55, 1 + k // 3, 0.6) for k in range(6)])
    r.lamp([(0.0, 0.0, 3.0)])
    r.hearth_glow(hu_ + 1.0, hv_ + 1.5, energy=1.6)
    # Étal devant la porte : le pain du matin, sous l'auvent.
    side = -1.0 if r.door_u >= 0 else 1.0
    r.put("fantasy_town_kit/stall-bench", side * 2.0, hv + 1.4, 90.0, 3.0, height=0.7)
    for index in range(3):
        r.put("food_kit/loaf-round" if index % 2 else "food_kit/loaf", side * 2.0 - 0.9 + index * 0.9, hv + 1.4, rng.uniform(0, 360), 0.8, y=0.7)


def furnish_mill(scene, house, ruined, rng):
    """Moulin : la meule au fond, contre le mur où l'axe de la roue entre, les sacs de grain et de farine, les caisses,
    l'échelle vers le grenier, la table du meunier et son cahier."""
    r = Room(scene, house, ruined, rng)
    hu, hv = r.hu, r.hv
    # L'axe de la roue traverse le mur du fond jusqu'à la meule (dehors, il va de la roue au mur).
    wall_x = house[0] + house[2] * TILE / 2
    scene.add("fantasy_town_kit/pillar-wood", (wall_x + 0.2, MILL_WHEEL[1], MILL_WHEEL[2]), 0.0, (2.7, 1.0, 2.7), roll=90.0)
    r.put("survival_kit/workbench-grind", 0.0, -hv + 1.25, 0.0, 5.0, height=1.4, roll=90.0 if ruined else 0.0)
    for index, v in enumerate((-3.1, -2.15, -1.2, -0.25)):
        tipped = ruined and index % 2 == 1
        r.put("food_kit/bag", -3.25 + (0.75 if tipped else 0.0), v, rng.uniform(-25, 25) if not tipped else 90.0, 1.6, height=1.3,
              y=-0.15 if tipped else 0.0, tilt=90.0 if tipped else 0.0)
    for index, v in enumerate((-2.6, -0.8)):
        r.put("survival_kit/box-large", 3.3, v, 0.0, 3.4, height=0.85)
    if ruined:
        r.put("mini_forest/ladder", -1.6, 1.8, 90.0, 3.8, height=0.5, y=-0.05, tilt=90.0)
        return
    attic_ladder(r, -r.wall_u + LADDER_REACH, 1.4, 90.0)
    r.put("mini_dungeon/barrel", 3.0, 1.8, 0.0, 2.6, height=1.25)
    top = 0.81
    r.put("mini_dungeon/table", -0.9, 2.5, 0.0, 2.6, height=top)
    r.put("food_kit/bowl", -1.5, 2.2, 0.0, 1.4, y=top)
    r.put("food_kit/bag-flat", -0.85, 3.0, 0.0, 1.2, y=top)
    r.put("graveyard_kit/candle", 0.0, 2.7, 0.0, 1.6, y=top)
    r.put("furniture_kit/books", -0.5, 2.0, 75.0, 2.2, y=top)
    for u, model in ((1.3, "survival_kit/tool-shovel"), (1.8, "survival_kit/tool-hoe")):
        r.put(model, u, -r.wall_v + 0.35, 0.0, 5.0, tilt=-10.0)
    back = r.reader("Notebook", -0.5, 2.0, 0.9, "Le cahier du meunier",
                    "Sacs moulus pour la boulangerie et pour la garde, an 5812 : quarante, puis plus un seul grain à moudre. Dernière ligne, la veille du départ pour le bunker : « Roue arrêtée, meule calée. Si la rivière retrouve sa force, il suffira d'ôter la cale. »",
                    radius=2.0)
    scene.group = back
    r.lamp([(0.0, 0.0, 3.0)])
    # Charrette de sacs devant la porte, du côté opposé.
    side = -1.0 if r.door_u >= 0 else 1.0
    r.put("fantasy_town_kit/cart", side * 2.2, hv + 2.4, 90.0, 2.6, height=1.4)
    r.put("food_kit/bag", side * 2.2, hv + 2.4, 10.0, 1.3, y=0.72)


def furnish_stables(scene, house, ruined, rng):
    """Écuries royales : quatre stalles à droite de l'allée, chacune avec son foin, son seau et le nom de son cheval
    au-dessus ; à gauche, le foin en réserve, le coffre du palefrenier, le banc, les outils. Les chevaux sont partis
    avec l'armée de Devlyn en 5804 ; les stalles attendent leur retour."""
    r = Room(scene, house, ruined, rng)
    hu, hv = r.hu, r.hv
    names = ("Brume", "Silex", "Comète", "Orage")
    stalls = (-4.35, -1.45, 1.45, 4.35)
    for index, v in enumerate((-2.9, 0.0, 2.9)):
        broken = ruined and index == 1
        r.put("nature_kit/fence_simple", 2.2, v + (0.4 if broken else 0.0), rng.uniform(-10, 10) if broken else 0.0, (3.05, 3.6, 3.0),
              height=1.26, roll=90.0 if broken else 0.0)
    for index, v in enumerate(stalls):
        r.put("graveyard_kit/hay-bale", 3.25, v - 0.55, 90.0 + rng.uniform(-6, 6), 2.0, height=0.7, roll=90.0 if ruined and index == 2 else 0.0)
        r.put("survival_kit/bucket", 3.35, v + 0.75, 0.0, 3.4, tilt=90.0 if ruined and index % 2 else 0.0)
    r.put("graveyard_kit/hay-bale-bundled", -3.1, -4.6, 90.0, 2.6, height=0.99)
    r.put("survival_kit/barrel-open", -3.25, -3.2, 0.0, 3.0, height=1.0, tilt=90.0 if ruined else 0.0)
    if ruined:
        # Tombée à plat au milieu de l'allée, à l'écart du passage de la porte.
        r.put("fantasy_town_kit/wheel", -0.1, 1.2, 0.0, 3.0, height=1.44, roll=90.0)
    else:
        r.put("fantasy_town_kit/wheel", -3.3, 3.3, 0.0, 3.0, height=1.44)
    if ruined:
        r.put("graveyard_kit/hay-bale", 0.0, -1.6, rng.uniform(0, 40), 1.8, height=0.7, roll=90.0)
        return
    r.put("survival_kit/chest", -3.3, -1.8, 90.0, 3.4, height=0.88)
    r.put("graveyard_kit/candle-multiple", -3.3, -1.8, 0.0, 1.6, y=0.88)
    r.put("graveyard_kit/bench", -3.3, 0.2, 90.0, 2.0, height=0.92)
    for v, model in ((1.6, "survival_kit/tool-hoe"), (2.1, "survival_kit/tool-shovel")):
        r.put(model, -r.wall_u + 0.35, v, 90.0, 5.0, tilt=-10.0)
    for index, v in enumerate(stalls):
        r.wall_board(f"Name{index}", "right", v, names[index], height=2.3, size=(0.9, 0.32), line=0.15)
    back = r.reader("Stalls", 0.9, -1.45, 1.2, "Les stalles des chevaux de la garde",
                    "Au-dessus de chaque stalle, un nom peint sur une planche : Brume, Silex, Comète, Orage. Les chevaux de la garde sont partis avec l'armée de Devlyn en 5804, contre Vibelandia ; aucun n'est revenu. Le palefrenier a pourtant laissé du foin dans chaque stalle, comme s'ils allaient rentrer le soir même.",
                    radius=2.2)
    scene.group = back
    r.lamp([(0.0, -2.0, 3.0), (0.0, 2.0, 3.0)])
    # Enclos derrière les écuries, côté forêt.
    cx, cz = house[0], house[1]
    for index in range(4):
        furniture(scene, "nature_kit/fence_simple", (cx - 8.6, 0.0, cz - 5.0 + index * 2.8), 90.0, 2.8, height=1.0)
        furniture(scene, "nature_kit/fence_simple", (cx - 6.6 - index * 2.8 + 4.0, 0.0, cz + 6.4), 0.0, 2.8, height=1.0)


def furnish_barracks(scene, house, ruined, rng):
    """Caserne de la garde : six lits de camp le long du mur du fond et leurs coffres, le râtelier au milieu, sous la
    liste des volontaires ; l'âtre à gauche, la grande table et le registre devant, les râteliers d'armes à droite."""
    r = Room(scene, house, ruined, rng)
    hu, hv = r.hu, r.hv
    hu_, hv_ = HEARTHS["barracks"](r.frame)
    hearth(r, hu_, hv_, "left")
    for index, u in enumerate((-3.85, -2.65, -1.45, 1.45, 2.65, 3.85)):
        moved = ruined and index % 2 == 1
        bed(r, u + (0.1 if moved else 0.0), -hv + 0.95 + (0.25 if moved else 0.0), broken=moved,
            slide=math.copysign(0.3, u) if abs(u) < 2.0 else -math.copysign(0.3, u))
        if not moved:
            r.put("survival_kit/chest", u, -1.4, 0.0, 2.4, height=0.62)
    r.put("mini_arena/weapon-rack", 0.0, -hv + 0.55, 0.0, 2.4, height=1.1, y=-RACK_SINK * 2.4 if ruined else 0.0, tilt=90.0 if ruined else 0.0)
    r.put("mini_dungeon/table", -2.8, 2.0, 0.0, 2.8, height=0.87, roll=90.0 if ruined else 0.0)
    for v in (0.6, 3.32):
        r.put("fantasy_town_kit/stall-bench", -2.8, v, 90.0, (3.0, 2.0, 3.0), height=0.46, roll=90.0 if ruined and v > 1 else 0.0)
    for index, v in enumerate((-0.9, 1.4)):
        tipped = ruined and index == 0
        r.put("mini_arena/weapon-rack", r.wall_u - 0.6, v, -90.0, 2.6, height=1.2, y=-RACK_SINK * 2.6 if tipped else 0.0, tilt=90.0 if tipped else 0.0)
    r.put("survival_kit/barrel", 5.1, 3.2, 0.0, 3.0, height=1.0)
    if ruined:
        return
    attic_ladder(r, 3.2, r.wall_v - LADDER_REACH, 180.0)
    top = 0.87
    r.put("furniture_kit/books", -3.7, 2.0, 15.0, 2.6, y=top)
    r.put("graveyard_kit/candle", -3.3, 1.4, 0.0, 1.6, y=top)
    for u, v in ((-2.4, 1.5), (-1.9, 2.5)):
        r.put("food_kit/mug", u, v, rng.uniform(0, 360), 0.6, y=top)
    r.put("graveyard_kit/detail-plate", -2.8, 2.5, 0.0, 2.4, y=top)
    back = r.reader("Register", -3.7, 2.0, 0.95, "Le registre de la garde",
                    "An 5804 : Vibelandia déclare la guerre ; cent douze volontaires s'engagent en une semaine. An 5808 : il en reste soixante. An 5812 : ordre du roi Codeon V, la garde conduit les habitants jusqu'au bunker ; le garde Aldric fermera la porte derrière le dernier d'entre eux. La suite de la page est restée blanche.",
                    radius=2.0)
    scene.group = back
    back = r.reader("Volunteers", 0.0, -1.7, 1.6, "La liste des volontaires",
                    "Trois planches couvertes de noms, gravés au couteau par les volontaires eux-mêmes, de 5804 à 5812. Beaucoup sont barrés d'un trait : ceux qui ne sont pas revenus. Tout en bas de la dernière planche, un nom qui n'est pas barré : Aldric.",
                    radius=2.2)
    for index, u in enumerate((-1.2, 0.0, 1.2)):
        r.wall_board(f"Board{index}", "back", u, ("Volontaires\n5804", "Volontaires\n5807", "Volontaires\n5810")[index],
                     height=2.6, size=(1.05, 0.7), line=0.14)
    scene.group = back
    r.lamp([(-2.0, 0.0, 3.0), (2.0, 0.0, 3.0)])
    r.hearth_glow(hu_ + 1.5, hv_)
    # Cour d'entraînement, entre la caserne et l'enceinte du château : cibles, mannequins de paille, râtelier.
    cx, cz = house[0], house[1]
    for index, (x, z) in enumerate(((cx + 10.0, cz - 3.0), (cx + 13.0, cz - 3.0), (cx + 16.0, cz - 3.0))):
        furniture(scene, "mini_forest/target", (x, 0.0, z), 0.0, 3.0, height=1.6)
    for x in (cx + 10.5, cx + 14.5):
        furniture(scene, "graveyard_kit/hay-bale-bundled", (x, 0.0, cz + 4.5), 90.0, 2.6, height=1.0)
        furniture(scene, "graveyard_kit/hay-bale-bundled", (x, 1.0, cz + 4.5), 0.0, 2.2, height=0.8)
    furniture(scene, "mini_arena/weapon-rack", (cx + 18.0, 0.0, cz + 1.0), -90.0, 3.0, height=1.4)


def furnish_apothecary(scene, house, ruined, rng):
    """Herboristerie : le chaudron sur son âtre, les étagères de fioles, la table du mortier et du miel, le lit où l'on
    soignait les blessés du front, les herbes qui sèchent ; dehors, le jardin des simples."""
    r = Room(scene, house, ruined, rng)
    hu, hv = r.hu, r.hv
    hu_, hv_ = HEARTHS["apothecary"](r.frame)
    hearth(r, hu_, hv_, "back")
    r.put("food_kit/pot-stew", hu_, hv_ + 1.27, 0.0, 1.4, height=0.5, tilt=90.0 if ruined else 0.0)
    r.put("mini_dungeon/table", -0.5, -0.6, 0.0, 2.8, height=0.87, roll=90.0 if ruined else 0.0)
    r.put("fantasy_town_kit/stall-stool", -0.5, 0.75, 0.0, 2.4, roll=90.0 if ruined else 0.0)
    bed(r, 3.2, 2.6, 180.0, broken=ruined)
    r.put("mini_dungeon/barrel", 3.0, 0.3, 0.0, 2.2, height=1.05)
    for u, v in ((-3.2, 3.1), (-3.2, 2.3)):
        r.put("survival_kit/box-open", u, v, rng.uniform(-10, 10), 2.6, height=0.8, tilt=90.0 if ruined and v > 3 else 0.0)
    if ruined:
        fallen_shelf(r, -1.4, -2.3, 10.0, width=2.2)
        fallen_shelf(r, -2.6, 0.9, 80.0, width=1.8)
        for u, v in ((1.2, 1.2), (1.7, 0.85), (-1.6, 1.7)):
            r.put("mini_dungeon/potion", u, v, rng.uniform(0, 360), 1.0, tilt=90.0)
        return
    potions = [("mini_dungeon/potion", -0.8 + (k % 4) * 0.5, 1 + k // 4, 0.7) for k in range(8)]
    shelf(r, -1.55, -r.wall_v + 0.3, 0.0, width=2.2, height=2.2, depth=0.5, boards=4, books=False,
          items=potions + [("food_kit/honey", 0.8, 3, 0.8), ("graveyard_kit/urn-square", -0.6, 3, 1.4)])
    shelf(r, -r.wall_u + 0.3, -0.6, 90.0, width=1.8, height=2.2, depth=0.5, boards=4, books=True)
    top = 0.87
    for index in range(3):
        r.put("mini_dungeon/potion", -1.4 + index * 0.45, -0.75, rng.uniform(0, 360), 0.8, y=top)
    r.put("food_kit/mortar-pestle", 0.35, -0.4, 0.0, 1.4, y=top)
    r.put("food_kit/honey", 0.3, -1.0, 0.0, 0.9, y=top)
    r.put("food_kit/bowl", -0.4, -0.3, 0.0, 1.0, y=top)
    r.put("furniture_kit/books", -1.35, -0.2, 70.0, 2.2, y=top)
    for u, v in ((-3.2, 3.1), (-3.2, 2.3)):
        r.put("nature_kit/plant_bush", u, v, rng.uniform(0, 360), 1.4, y=0.8)
    back = r.reader("Herbal", -1.35, -0.2, 0.95, "Le carnet de l'herboriste",
                    "Pour les brûlures : sauge et miel. Pour la fièvre : écorce de saule, en tisane. Pour les plaies du front : onguent de souci, et du linge propre. Plus bas, souligné deux fois : « Pour la peur, quand les cloches sonnent : une tisane de tilleul, et quelqu'un à qui parler. »",
                    radius=2.0)
    scene.group = back
    r.lamp([(0.0, 0.0, 3.0)])
    r.hearth_glow(hu_ - 1.0, hv_ + 1.5)
    # Jardin des simples, entre la porte et le chemin : carrés d'herbes et de racines.
    cx, cz = house[0], house[1]
    for row in range(3):
        for column in range(2):
            x, z = cx + 6.5 + column * 1.8, cz - 3.6 + row * 1.5
            scene.add("nature_kit/crops_dirtRow", (x, 0.0, z), 90.0, 1.8)
            crop = ("nature_kit/crops_leafsStageB", "nature_kit/crop_carrot", "nature_kit/crop_turnip")[row]
            scene.add(crop, (x, 0.0, z), rng.uniform(0, 360), 1.4)


def furnish_scriptorium(scene, house, ruined, rng):
    """Scriptorium, où l'on recopiait les écrits des anciens bâtisseurs : les rayonnages le long des murs, quatre
    pupitres et leurs tabourets, le lutrin du maître copiste au fond, avec la page qu'il recopiait."""
    r = Room(scene, house, ruined, rng)
    hu, hv = r.hu, r.hv
    for side in (-1, 1):
        if ruined and side > 0:
            fallen_shelf(r, 2.75, -1.2, 90.0, width=2.6)
            continue
        shelf(r, side * (r.wall_u - 0.3), -1.2, -90.0 * side, width=2.6, height=2.6, depth=0.5, boards=5)
    for row, v in enumerate((-0.8, 1.4)):
        for side in (-1, 1):
            tipped = ruined and side > 0
            r.put("mini_dungeon/table", side * 1.4, v, 0.0, 2.0, height=0.62, roll=90.0 if tipped else 0.0)
            r.put("fantasy_town_kit/stall-stool", side * 1.4, v + 1.05, 0.0, 2.4, roll=90.0 if ruined and row == 1 else 0.0)
            if not ruined:
                r.put("furniture_kit/books", side * 1.4 - 0.35, v, rng.uniform(-20, 20), 2.4, y=0.62)
                r.put("graveyard_kit/candle", side * 1.4 + 0.5, v - 0.25, 0.0, 1.6, y=0.62)
    lectern = 1.6 * MODEL_BOXES["graveyard_kit/altar-wood"][1][1]
    r.put("graveyard_kit/altar-wood", 0.0, -hv + 0.6, 0.0, 1.6, height=lectern)
    r.put("survival_kit/chest", -2.7, -3.2, 0.0, 3.0, height=0.78)
    if ruined:
        for index in range(4):
            r.add("furniture_kit/books", rng.uniform(-2.0, 2.0), rng.uniform(-1.0, 2.0), rng.uniform(0, 360), 2.4)
        return
    r.put("furniture_kit/books", -0.2, -hv + 0.6, 90.0, 2.6, y=lectern)
    r.put("graveyard_kit/candle-multiple", 0.55, -hv + 0.5, 0.0, 1.4, y=lectern)
    r.put("furniture_kit/rugRectangle", 0.0, 0.2, 90.0, (2.2, 1.0, 0.8), y=0.02)
    back = r.reader("Page", 0.0, -hv + 0.6, 0.95, "La page du maître copiste",
                    "Fragment recopié des anciens bâtisseurs : « Quatre livres gardent notre savoir. Le Projenomicon apprend à mener un ouvrage, l'Algonicon à ordonner les instructions, le Logiconomicon à raisonner et à chiffrer, le Codonomicon à parler aux machines. » En marge, le copiste a ajouté : « Fragment incomplet. Les originaux sont perdus ; peut-être dorment-ils encore aux quatre coins du royaume. »",
                    radius=2.2)
    scene.group = back
    attic_ladder(r, 2.75, r.wall_v - LADDER_REACH, 180.0)
    r.lamp([(0.0, 0.0, 3.0)], energy=1.4)


QUARTER_FURNISHERS = {"bakery": furnish_bakery, "mill": furnish_mill, "stables": furnish_stables, "barracks": furnish_barracks,
                      "apothecary": furnish_apothecary, "scriptorium": furnish_scriptorium}


def build_quarters(scene, rng):
    for name, house, stage, kind in QUARTERS:
        scene.repair(name, stage)
        ruined_house(scene, random.Random(name), house, QUARTER_FURNISHERS[kind])
        scene.rebuilt(name)
        rebuilt_house(scene, random.Random(name + "!"), house, QUARTER_FURNISHERS[kind], kind)
    scene.group = "Fixed"
    build_mill_wheel(scene, rng)
    build_lavoir(scene, rng)
    build_market_hall(scene, rng)
    build_observatory(scene, rng)
    build_orchard(scene, rng)


# Roue du moulin, dans le courant devant le mur est du moulin : son axe traverse la berge jusqu'au mur.
MILL_WHEEL = (70.5, 1.25, 48.0)


def build_mill_wheel(scene, rng):
    x, y, z = MILL_WHEEL
    scene.repair("MillWheel", 2)
    # Arrêtée, à demi arrachée, des pales manquantes.
    scene.add("fantasy_town_kit/watermill", (x, y - 0.5, z), 0.0, 3.0, roll=18.0)
    scene.add("fantasy_town_kit/pillar-wood", (69.3, y, z), 0.0, (2.7, 4.3, 2.7), roll=90.0)
    scene.rebuilt("MillWheel")
    scene.add("fantasy_town_kit/pillar-wood", (69.3, y, z), 0.0, (2.7, 4.3, 2.7), roll=90.0)
    scene.pivot("Repairs/MillWheel/Rebuilt/Wheel", (x, y, z), "res://scenes/levels/hub/hub_spinner.gd", {"speed": 0.6})
    scene.add("fantasy_town_kit/watermill", (0.0, 0.0, 0.0), 0.0, 3.0)
    scene.group = "Fixed"


def build_lavoir(scene, rng):
    """Lavoir au bord du grand pont : un bassin de pierre sous un toit de tuiles posé sur quatre poteaux. Au premier
    livre, l'eau revient dans le bassin et le linge sèche sur une corde."""
    cx, cz = 54.0, 6.5
    # Dallage de pierre sous le toit, de pilier à pilier (deux dalles de 4 m du kit des donjons, celles de la crypte
    # du marais), à 3 cm au-dessus du sol : en ruine comme rebâti, le bassin et les baquets ne sont plus dans l'herbe.
    # La dalle « road » du kit de la ville, essayée d'abord, est bleue : on aurait dit de l'eau répandue.
    for x in (cx - TILE / 2, cx + TILE / 2):
        scene.add("modular_dungeon_kit/template-floor", (x, 0.03, cz), 0.0, 1.0)
    scene.repair("Lavoir", 1)
    furniture(scene, "fantasy_town_kit/fountain-square", (cx, 0.0, cz), 0.0, 2.0, height=0.9)
    scene.add("castle_kit/rocks-small", (cx + 1.0, 0.3, cz - 0.5), rng.uniform(0, 360), 1.4)
    for x, z in ((cx - 4.0, cz - 2.0), (cx + 4.0, cz + 2.0)):
        scene.add("fantasy_town_kit/pillar-wood", (x, 0.0, z), 0.0, 3.2)
        scene.add_box((x, 1.6, z), (0.5, 3.2, 0.5))
    scene.add("fantasy_town_kit/pillar-wood", (cx + 1.5, 0.0, cz + 3.4), 60.0, 3.2, tilt=90.0)
    scene.add("survival_kit/resource-planks", (cx - 2.0, 0.0, cz + 3.6), 20.0, 3.0)
    scene.rebuilt("Lavoir")
    furniture(scene, "fantasy_town_kit/fountain-square-detail", (cx, 0.0, cz), 0.0, 2.0, height=0.9)
    # Les piliers côté rivière (x = 58) sont au haut de la berge, qui descend déjà de 0,1 à 0,25 m sous leur pied :
    # ils s'enfoncent de 0,3 m pour ne pas laisser de jour sous leur base, et gardent leur haut sous le toit.
    for x in (cx - 4.0, cx + 4.0):
        sink = 0.3 if x > cx else 0.0
        for z in (cz - 2.0, cz + 2.0):
            scene.add("fantasy_town_kit/pillar-wood", (x, -sink, z), 0.0, (4.0, 4.0 + sink, 4.0))
            scene.add_box((x, 2.0, z), (0.5, 4.0, 0.5))
    roof(scene, cx, cz, 2, 1, WALL_HEIGHT)
    # Séchoir à l'ouest du lavoir, sur le plat : deux perches, une barre de bois en travers de leur tête, et les
    # draps et bannières pendus à la barre par leur tringle. Il était au bord de la rivière, ses perches sur la pente
    # de la berge, 0,6 à 0,9 m au-dessus du sol, et les bannières flottaient à 1,5 m de la ligne des perches.
    line_x, line_y = cx - 5.4, 2.3
    for z in (cz - 2.6, cz + 2.6):
        scene.add("fantasy_town_kit/pillar-wood", (line_x, 0.0, z), 0.0, (1.0, 2.4, 1.0))
        scene.add_box((line_x, 1.2, z), (0.3, 2.4, 0.3))
    # Barre : un poteau couché le long de z, de 6 cm d'épaisseur, d'une perche à l'autre.
    scene.add("fantasy_town_kit/pillar-wood", (line_x, line_y, cz - 2.65), 0.0, (0.6, 5.3, 0.6), tilt=90.0)
    # Bannière (échelle 1,2 sur 1,4) : son drap est à x = 0,4 de son origine, le haut de sa tringle à 1,0.
    for index, z in enumerate((cz - 1.4, cz + 0.2, cz + 1.6)):
        scene.add("fantasy_town_kit/banner-green" if index % 2 else "fantasy_town_kit/banner-red",
                  (line_x - 0.4 * 1.2, line_y - 0.03 - 1.4, z), 0.0, (1.2, 1.4, 1.2))
    for index, (x, z) in enumerate(((cx - 2.6, cz - 3.0), (cx + 2.0, cz - 3.0))):
        furniture(scene, "survival_kit/barrel-open", (x, 0.0, z), 0.0, 3.0, height=1.0)
    furniture(scene, "survival_kit/bucket", (cx - 1.0, 0.0, cz - 3.0), 0.0, 3.4)
    furniture(scene, "graveyard_kit/bench", (cx - 2.2, 0.0, cz + 3.2), 180.0, 2.2, height=1.0)
    furniture(scene, "survival_kit/box-open", (cx + 1.8, 0.0, cz + 3.1), 15.0, 2.8, height=0.85)
    furniture(scene, "food_kit/bag-flat", (cx + 1.8, 0.45, cz + 3.1), 40.0, 1.2)
    scene.group = "Fixed"


def build_market_hall(scene, rng):
    """Halle du marché, au sud du village : un grand toit sur des piliers de bois, des étals à l'abri. Le toit,
    effondré pendant la guerre, est relevé au deuxième livre."""
    cx, cz, width, depth = -24.0, 66.0, 3, 2
    half_w, half_d = width * TILE / 2, depth * TILE / 2
    pillars = [(cx + sx * half_w, cz + sz * half_d) for sx in (-1, 1) for sz in (-1, 0, 1)]
    # Plancher de la halle, comme celui des maisons (house_floor) : des lattes sur chaque case, affleurantes, et une
    # couche d'une seule pièce dessous, croisée, pour qu'on ne voie pas l'herbe entre les lattes. Les étals et les
    # tonneaux ne sont plus posés dans l'herbe ; il reste sous le toit effondré.
    scene.add("fantasy_town_kit/planks", (cx, -0.215, cz), 90.0, (depth * TILE * 0.98, TILE, width * TILE * 0.98))
    for column in range(width):
        for row in range(depth):
            scene.add("fantasy_town_kit/planks", (cx - (width - 1) * TILE / 2 + column * TILE, -0.2, cz - (depth - 1) * TILE / 2 + row * TILE), 0.0, TILE)
    scene.repair("MarketHall", 2)
    for index, (x, z) in enumerate(pillars):
        if index in (1, 4):
            scene.add("fantasy_town_kit/pillar-wood", (x + 1.4, 0.0, z + 0.6), rng.uniform(0, 180), 4.0, tilt=90.0)
            continue
        scene.add("fantasy_town_kit/pillar-wood", (x, 0.0, z), 0.0, (4.0, 2.4 if index % 2 else 4.0, 4.0))
        scene.add_box((x, 1.2 if index % 2 else 2.0, z), (0.6, 2.4 if index % 2 else 4.0, 0.6))
    for x, z, degrees in ((cx - 2.0, cz - 1.0, 20.0), (cx + 3.0, cz + 1.5, -35.0)):
        scene.add("fantasy_town_kit/roof", (x, 0.0, z), degrees, TILE, tilt=12.0)
        scene.add_box((x, 0.6, z), (3.6, 1.2, 3.6), degrees)
    furniture(scene, "fantasy_town_kit/stall-bench", (cx - 4.0, 0.0, cz), 30.0, 3.0, height=0.7, roll=90.0)
    scene.rebuilt("MarketHall")
    for x, z in pillars:
        scene.add("fantasy_town_kit/pillar-wood", (x, 0.0, z), 0.0, 4.0)
        scene.add_box((x, 2.0, z), (0.6, 4.0, 0.6))
    roof(scene, cx, cz, width, depth, WALL_HEIGHT)
    # Étals sous la halle, en deux rangées de part et d'autre de l'allée centrale.
    for index, x in enumerate((cx - 4.0, cx, cx + 4.0)):
        for side in (-1, 1):
            z = cz + side * 2.0
            furniture(scene, "fantasy_town_kit/stall-bench", (x, 0.0, z), 90.0, 3.0, height=0.7)
            food = ("food_kit/cabbage", "food_kit/apple", "food_kit/cheese", "food_kit/carrot", "food_kit/fish", "food_kit/loaf-round")[(index * 2 + (side > 0)) % 6]
            scale = {"food_kit/cheese": 0.9, "food_kit/fish": 1.2, "food_kit/loaf-round": 1.1}.get(food, 1.5)
            for offset in (-0.9, 0.0, 0.9):
                furniture(scene, food, (x + offset, 0.69, z), rng.uniform(-15, 15), scale)
    for x, z in ((cx - 6.6, cz - 3.2), (cx - 6.6, cz + 3.2), (cx + 6.6, cz - 3.2)):
        furniture(scene, "mini_dungeon/barrel", (x + 1.0 if x < cx else x - 1.0, 0.0, z), 0.0, 2.4, height=1.1)
    furniture(scene, "survival_kit/box-large", (cx + 5.6, 0.0, cz + 3.2), 90.0, 3.0, height=0.8)
    for index, x in enumerate((cx + 4.2, cx + 3.4)):
        furniture(scene, "food_kit/bag", (x, 0.0, cz + 3.4), rng.uniform(-20, 20), 1.6, height=1.3)
    scene.group = "Fixed"


# Observatoire du Mont Sam Altan : centre, échelle des étages de la tour, et son quart de tour.
OBSERVATORY = (-70.0, 58.0, 4.6)
TOWER_YAW = 45.0


def tower_point(x, z, a, b):
    """Point de la tour à (a, b) dans son repère : a vers la porte (face +x du modèle), b sur le côté."""
    c, s = math.cos(math.radians(TOWER_YAW)), math.sin(math.radians(TOWER_YAW))
    return x + a * c + b * s, z - a * s + b * c


def tower_walls(scene, x, z, scale, height):
    """Murs de la tour en quatre boîtes autour de la salle du bas, au lieu d'un bloc plein. La porte du modèle, sur
    sa face +x (nord-est), est une porte de bois fermée : le mur reste plein, et l'on passe par elle avec E
    (tower_doors)."""
    outer, inner = 0.465 * scale, 0.349 * scale
    middle, thick = (outer + inner) / 2, outer - inner
    for a, b, size in ((-middle, 0.0, (thick, height, 2 * outer)), (middle, 0.0, (thick, height, 2 * outer)),
                       (0.0, middle, (2 * outer, height, thick)), (0.0, -middle, (2 * outer, height, thick))):
        px, pz = tower_point(x, z, a, b)
        scene.add_box((px, height / 2, pz), size, TOWER_YAW)


def tower_doors(scene, x, z, scale, name):
    """Les deux côtés de la porte fermée de la tour : un Interactable dehors pour entrer, un dedans pour sortir. Chacun
    porte le point d'arrivée (destination) et le cap de la caméra (facing) ; hub.gd fait passer le joueur en fondu."""
    outer, inner = 0.465 * scale, 0.349 * scale
    group = scene.group
    c, s = math.cos(math.radians(TOWER_YAW)), math.sin(math.radians(TOWER_YAW))
    # Direction de la porte (+a) dans le monde, et le cap de la caméra (atan2(-x, -z) du regard) : dedans, on regarde
    # la salle ; dehors, on tourne le dos à la tour.
    out_x, out_z = c, -s
    look_in = math.atan2(out_x, out_z)
    look_out = math.atan2(-out_x, -out_z)
    for key, (a, prompt, (da, db), facing) in {
        "DoorOutside": (outer + 0.3, "Entrer dans l'observatoire", (0.3, -0.4), look_in),
        "DoorInside": (inner - 0.2, "Sortir de l'observatoire", (outer + 1.6, 0.0), look_out),
    }.items():
        px, pz = tower_point(x, z, a, 0.0)
        path = f"{group}/{key}"
        scene.pivot(path, (px, 1.2, pz), "res://scripts/interactable.gd", {"prompt": quote(prompt), "radius": "1.7"})
        tx, tz = tower_point(x, z, da, db)
        scene.metadata[path] = {"destination": f"Vector3({tx:.3f}, 0.3, {tz:.3f})", "facing": f"{facing:.4f}"}
        scene.texts.add(path)
        scene.group = group


def furnish_observatory(scene, x, z, scale, ruined, rng):
    """Salle des veilleurs, au pied de la tour, derrière sa porte fermée : la table où l'on tenait le registre du volcan (texte à lire), la
    chaise, la paillasse du veilleur de nuit, le coffre et sa lanterne, et l'échelle vers la chambre de guet. Plancher
    de bois, et le plafond de l'étage au-dessus ; dans la tour décapitée, la table est renversée et le registre est
    resté à terre."""
    def at(a, b, y=0.0):
        px, pz = tower_point(x, z, a, b)
        return (px, y, pz)

    def turn(degrees):
        return TOWER_YAW + degrees

    # Plancher en deux couches croisées, jusque sous les murs : entre les lattes, on voit du bois et non l'herbe.
    side = 2 * 0.465 * scale
    scene.add("fantasy_town_kit/planks", at(0.0, 0.0, -0.18), turn(0.0), (side, 3.3, side))
    scene.add("fantasy_town_kit/planks", at(0.0, 0.0, -0.2), turn(90.0), (side, 3.3, side))
    if ruined:
        furniture(scene, "mini_dungeon/table", at(-0.9, 0.5), turn(90.0), 1.8, height=0.6, roll=90.0)
        scene.add("furniture_kit/books", at(-0.2, -0.3), turn(rng.uniform(0, 360)), 2.4)
        furniture(scene, "mini_dungeon/chair", at(0.3, 0.9), turn(30.0), 2.0, tilt=90.0)
        scene.add("survival_kit/resource-planks", at(0.3, -0.9), turn(rng.uniform(0, 360)), 2.6)
        return
    ceiling = 1.01 * scale - 0.2
    scene.add("fantasy_town_kit/planks", at(0.0, 0.0, ceiling), turn(0.0), (side, 3.3, side))
    scene.add("fantasy_town_kit/planks", at(0.0, 0.0, ceiling - 0.015), turn(90.0), (side, 3.3, side))
    # Le plafond arrête la tête du joueur qui saute depuis le coffre ou la table.
    px, _, pz = at(0.0, 0.0)
    scene.add_box((px, ceiling + 0.15, pz), (side, 0.3, side), TOWER_YAW)
    top = 1.8 * MODEL_BOXES["mini_dungeon/table"][1][1]
    furniture(scene, "mini_dungeon/table", at(-1.0, 0.6), turn(90.0), 1.8, height=top)
    furniture(scene, "furniture_kit/books", at(-1.05, 0.45, top), turn(100.0), 2.4)
    furniture(scene, "graveyard_kit/candle", at(-1.25, 1.15, top), turn(0.0), 1.6)
    furniture(scene, "mini_dungeon/chair", at(0.05, 0.45), turn(-90.0), 2.0)
    furniture(scene, "survival_kit/bedroll", at(-0.6, -1.15), turn(0.0), 2.4)
    furniture(scene, "survival_kit/chest", at(1.0, -1.2), turn(0.0), 2.4, height=0.62)
    furniture(scene, "graveyard_kit/candle-multiple", at(1.0, -1.2, 2.4 * MODEL_BOXES["survival_kit/chest"][1][1]), turn(0.0), 1.6)
    furniture(scene, "mini_forest/ladder", at(0.85, 1.4), turn(180.0), (2.6, 4.4, 2.6), height=4.2, tilt=-8.0)
    group = scene.group
    scene.reader("Register", at(-1.0, 0.45, 0.95), "Le registre des veilleurs",
                 "Chaque soir, le veilleur notait la fumée du Mont Sam Altan : des siècles de lignes semblables, « Le volcan dort. » En 5810, la terre tremble à chaque bataille lointaine. Dernière ligne, en 5812 : « Fumée légère au sommet. Rien à signaler. Départ pour le bunker demain, à l'aube. »",
                 "Lire : Le registre des veilleurs", 2.0)
    scene.group = group
    scene.lamp("Lamp", at(0.0, 0.0, 3.0), [at(0.0, 0.0, 3.2)], 1.0, 3.6)


def build_observatory(scene, rng):
    """L'observatoire du Mont Sam Altan, au sud-ouest : la tour d'où les veilleurs du roi guettaient le volcan
    endormi depuis des siècles. Décapitée par la guerre, elle retrouve son toit au quatrième livre. Sa salle du bas
    se visite, par la porte du nord-est."""
    x, z, scale = OBSERVATORY
    scene.repair("Observatory", 4)
    y = 0.0
    for model in ("tower-square-mid-door", "tower-square-mid-windows", "tower-square-mid-windows"):
        scene.add(f"castle_kit/{model}", (x, y, z), TOWER_YAW, scale)
        y += 1.01 * scale
    tower_walls(scene, x, z, scale, y)
    tower_doors(scene, x, z, scale, "Observatory")
    furnish_observatory(scene, x, z, scale, True, rng)
    rubble(scene, rng, x + 3.6, z + 3.6, True, count=2, spread=2.0)
    scene.rebuilt("Observatory")
    y = 0.0
    for model in ("tower-square-mid-door", "tower-square-mid-windows", "tower-square-mid-windows", "tower-square-mid-windows"):
        scene.add(f"castle_kit/{model}", (x, y, z), TOWER_YAW, scale)
        y += 1.01 * scale
    scene.add("castle_kit/tower-square-top-roof-high-windows", (x, y, z), TOWER_YAW, scale)
    tower_walls(scene, x, z, scale, y + 1.07 * scale)
    tower_doors(scene, x, z, scale, "Observatory")
    furnish_observatory(scene, x, z, scale, False, rng)
    scene.add("castle_kit/flag-pennant", (x, y + 1.07 * scale, z), 0.0, 3.0)
    scene.group = "Fixed"
    # Banc de pierre et lanterne au pied de la tour, face au nord, d'où l'on voit le volcan.
    furniture(scene, "graveyard_kit/bench", (x + 5.0, 0.0, z - 1.8), 200.0, 2.2, height=1.0)
    scene.add("fantasy_town_kit/lantern", (x + 3.6, 0.0, z - 3.6), 0.0, 2.2)
    scene.add_box((x + 3.6, 1.0, z - 3.6), (0.45, 2.0, 0.45))


# Verger du roi, au sud : quatre rangées d'arbres fruitiers. Jusqu'au deuxième livre, des souches et quelques arbres morts.
ORCHARD = (14.0, 82.0)


def build_orchard(scene, rng):
    cx, cz = ORCHARD
    spots = [(cx - 8.0 + column * 5.2, cz - 6.0 + row * 4.4) for row in range(4) for column in range(4)]
    scene.repair("Orchard", 2)
    for index, (x, z) in enumerate(spots):
        if index % 3 == 0:
            furniture(scene, "nature_kit/tree_thin_dark", (x, 0.0, z), rng.uniform(0, 360), 2.6, height=3.0)
        else:
            furniture(scene, "nature_kit/stump_old", (x, 0.0, z), rng.uniform(0, 360), 2.4, height=0.6)
    scene.rebuilt("Orchard")
    for index, (x, z) in enumerate(spots):
        model = ("nature_kit/tree_default", "nature_kit/tree_fat", "nature_kit/tree_oak")[index % 3]
        furniture(scene, model, (x, 0.0, z), rng.uniform(0, 360), 3.6, height=3.0)
        for offset in range(2):
            scene.add("food_kit/apple", (x + rng.uniform(-1.2, 1.2), 0.0, z + rng.uniform(1.0, 1.8)), rng.uniform(0, 360), 1.5)
    furniture(scene, "mini_forest/ladder", (cx - 8.0 + 0.9, 0.0, cz - 6.0 + 0.4), 30.0, 3.4, tilt=-14.0)
    for x, z in ((cx + 11.0, cz - 4.0), (cx + 11.0, cz - 2.6)):
        furniture(scene, "survival_kit/barrel-open", (x, 0.0, z), 0.0, 3.0, height=1.0)
    scene.group = "Fixed"


# ---------------------------------------------------------------------------------------------------------------
# Jardin du roi, à l'est du château et au bord de la rivière : allées gravillonnées en croix autour de la statue
# de Devlyn, l'allée des rois Codeon, le kiosque, l'étang, des parterres et des bancs. Il reprend vie livre après livre.
# ---------------------------------------------------------------------------------------------------------------
PARK = (29.0, -90.0, 52.0, -52.0)
PARK_CENTER = (42.0, -70.0)
KIOSK = (36.0, -82.0)


def hedge_line(scene, start, end, step=2.0, model="fantasy_town_kit/hedge-large", height=1.2):
    """Haie taillée d'un point à un autre, en éléments de deux mètres, avec sa collision."""
    (ax, az), (bx, bz) = start, end
    length = math.hypot(bx - ax, bz - az)
    count = max(int(round(length / step)), 1)
    degrees = math.degrees(math.atan2(bx - ax, bz - az))
    for index in range(count):
        t = (index + 0.5) / count
        furniture(scene, model, (ax + (bx - ax) * t, 0.0, az + (bz - az) * t), degrees, step, height=height)


def build_park(scene, rng):
    x0, z0, x1, z1 = PARK
    cx, cz = PARK_CENTER
    # Haies du pourtour, ouvertes aux entrées : au sud-ouest, au sud, et à l'est vers la passerelle.
    hedge_line(scene, (x0, z0), (x0, z1 - 3.0))
    hedge_line(scene, (x0, z0), (x1, z0))
    hedge_line(scene, (x1, z0), (x1, -68.6))
    hedge_line(scene, (x1, -63.4), (x1, z1))
    hedge_line(scene, (x1, z1), (cx + 2.4, z1))
    hedge_line(scene, (cx - 2.4, z1), (x0 + 5.0, z1))
    # Arbres plantés le long des haies.
    for index, z in enumerate((-61.0, -56.0)):
        furniture(scene, "nature_kit/tree_oak" if index % 2 else "nature_kit/tree_default", (x1 - 2.2, 0.0, z), rng.uniform(0, 360), 4.4, height=4.0)
    furniture(scene, "nature_kit/tree_default", (35.0, 0.0, -75.6), rng.uniform(0, 360), 4.2, height=4.0)
    # Lanternes au bord des allées.
    for x, z in ((40.4, -55.0), (43.6, -64.0), (40.4, -77.0), (40.4, -87.0), (32.6, -60.0), (32.6, -79.0), (49.0, -67.8)):
        scene.add("fantasy_town_kit/lantern", (x, 0.0, z), 0.0, 2.2)
        scene.add_box((x, 1.0, z), (0.45, 2.0, 0.45))

    # Parterres : quatre carrés bordés de buis bas, au sud et au nord-est. Fleuris au premier livre.
    beds = [(36.0, -58.0), (36.0, -64.0), (48.0, -58.0), (48.0, -64.0), (47.6, -76.4)]
    scene.repair("ParkBeds", 1)
    for x, z in beds:
        for dx, dz in ((-1.4, -1.4), (1.4, 1.4), (1.4, -1.4), (-1.4, 1.4)):
            scene.add("nature_kit/crops_dirtRow", (x + dx * 0.5, 0.0, z + dz * 0.5), 0.0, 2.0)
        scene.add("nature_kit/stump_round", (x, 0.0, z), rng.uniform(0, 360), 2.0)
    scene.rebuilt("ParkBeds")
    for x, z in beds:
        for side in (-1, 1):
            furniture(scene, "fantasy_town_kit/hedge", (x + side * 1.9, 0.0, z), 0.0, (1.0, 1.6, 3.6), height=0.4)
            furniture(scene, "fantasy_town_kit/hedge", (x, 0.0, z + side * 1.9), 90.0, (1.0, 1.6, 3.6), height=0.4)
        for index in range(9):
            model = ("nature_kit/flower_redA", "nature_kit/flower_yellowA", "nature_kit/flower_purpleA")[(index + int(x)) % 3]
            scene.add(model, (x - 1.1 + (index % 3) * 1.1, 0.0, z - 1.1 + (index // 3) * 1.1), rng.uniform(0, 360), 2.6)
    scene.group = "Fixed"

    # Bancs le long des allées : brisés jusqu'au premier livre.
    benches = [(39.8, -60.0, 90.0), (44.2, -60.0, -90.0), (39.8, -82.0, 90.0), (43.6, -78.4, -90.0), (33.2, -67.6, 90.0), (50.4, -72.6, 180.0)]
    scene.repair("ParkBenches", 1)
    for x, z, degrees in benches:
        furniture(scene, "graveyard_kit/bench-damaged", (x, -0.12 if x > 44 else 0.0, z), degrees + rng.uniform(-15, 15), 2.2, height=0.9,
                  roll=90.0 if x > 44 else 0.0)
    scene.rebuilt("ParkBenches")
    for x, z, degrees in benches:
        furniture(scene, "graveyard_kit/bench", (x, 0.0, z), degrees, 2.2, height=1.0)
    scene.group = "Fixed"

    # Allée des rois : Codeon I à IV, de part et d'autre de l'allée sud. Leurs statues, renversées pendant la guerre,
    # sont relevées au deuxième livre.
    kings = [(39.2, -56.0), (44.8, -56.0), (39.2, -61.5), (44.8, -61.5)]
    scene.repair("ParkKings", 2)
    for index, (x, z) in enumerate(kings):
        furniture(scene, "nature_kit/statue_block", (x, 0.0, z), 0.0, 2.4, height=0.95)
        side = -1 if x < cx else 1
        furniture(scene, "mini_arena/statue", (x + side * 1.6, 0.0, z + 0.3), rng.uniform(-30, 30) + 90.0, 1.6, height=0.9, tilt=90.0)
    scene.rebuilt("ParkKings")
    for x, z in kings:
        furniture(scene, "nature_kit/statue_block", (x, 0.0, z), 0.0, 3.2, height=1.25)
        furniture(scene, "mini_arena/statue", (x, 0.39 * 3.2, z), 90.0 if x < cx else -90.0, 1.6, height=2.1)
    scene.group = "Fixed"

    # Statue de Devlyn, vainqueur des Quatre Dragons du Chaos, au milieu du rond-point : un socle à degrés, le héros,
    # et les quatre trophées des dragons à ses pieds. Brisée, elle n'est relevée qu'avec le quatrième livre.
    scene.repair("ParkStatue", 4)
    furniture(scene, "nature_kit/statue_block", (cx, 0.0, cz), 0.0, 6.0, height=2.3)
    furniture(scene, "nature_kit/statue_columnDamaged", (cx + 0.4, 2.34, cz - 0.3), 20.0, 3.0)
    furniture(scene, "mini_arena/statue", (cx + 2.9, 0.0, cz + 2.0), 40.0, 2.0, height=1.4, tilt=90.0)
    scene.rebuilt("ParkStatue")
    furniture(scene, "nature_kit/statue_block", (cx, 0.0, cz), 0.0, 6.0, height=2.3)
    furniture(scene, "mini_arena/statue", (cx, 2.34, cz), 0.0, 2.6)
    for dx, dz in ((-1.6, -1.6), (1.6, -1.6), (-1.6, 1.6), (1.6, 1.6)):
        furniture(scene, "mini_arena/trophy", (cx + dx * 1.35, 0.0, cz + dz * 1.35), math.degrees(math.atan2(dx, dz)) + 180.0, 1.6, height=0.8)
    scene.group = "Fixed"

    # Kiosque à musique, au nord-ouest du jardin : six piliers et un toit hexagonal sur une estrade de pierre.
    kx, kz = KIOSK
    scene.repair("ParkKiosk", 3)
    scene.add("castle_kit/tower-hexagon-top", (kx, 0.0, kz), 0.0, (6.0, 2.0, 6.0))
    scene.add_box((kx, 0.13, kz), (5.0, 0.26, 4.4))
    for index in range(6):
        angle = math.radians(30 + index * 60)
        px, pz = kx + math.cos(angle) * 2.3, kz + math.sin(angle) * 2.0
        if index in (0, 3):
            furniture(scene, "nature_kit/statue_columnDamaged", (px, 0.0, pz), 0.0, 2.2, height=1.5)
        elif index == 4:
            continue
        else:
            furniture(scene, "nature_kit/statue_column", (px, 0.0, pz), 0.0, 2.2, height=2.2)
    scene.add("castle_kit/tower-hexagon-roof", (kx + 3.4, 0.0, kz + 2.4), 50.0, (4.0, 2.4, 4.0), tilt=70.0)
    scene.add_box((kx + 3.4, 0.9, kz + 2.4), (2.8, 1.8, 2.8), 50.0)
    scene.rebuilt("ParkKiosk")
    scene.add("castle_kit/tower-hexagon-top", (kx, 0.0, kz), 0.0, (6.0, 2.0, 6.0))
    scene.add_box((kx, 0.13, kz), (5.0, 0.26, 4.4))
    # Le dessous du toit est un hexagone régulier de 2,42 m de rayon (0,432 x 5,6), ses sommets sur l'axe x, sous
    # un débord plus large qui commence 0,39 m plus haut. Posés sur une ellipse (2,3 m sur x, 2 m sur z), les
    # piliers du milieu des côtés dépassaient du dessous du toit : on voyait le jour entre eux et le débord. Ils sont
    # maintenant au milieu de chaque côté, à 1,7 m du centre (le côté est à 2,1 m), tournés vers le centre, et
    # montent jusque dans le plateau du toit.
    roof_y = 3.66
    for index in range(6):
        degrees = 30 + index * 60
        angle = math.radians(degrees)
        px, pz = kx + math.cos(angle) * 1.7, kz + math.sin(angle) * 1.7
        if index == 1:
            continue
        height = roof_y + 0.04 - 0.17
        furniture(scene, "nature_kit/statue_column", (px, 0.17, pz), 90.0 - degrees, (2.2, height, 2.2), height=height)
    scene.add("castle_kit/tower-hexagon-roof", (kx, roof_y, kz), 0.0, (5.6, 2.6, 5.6))
    scene.group = "Fixed"

    # Étang : une barque échouée sur la rive.
    furniture(scene, "nature_kit/canoe", (43.0, 0.0, -89.0), 80.0, 2.4)


def build_quarter_paths(scene):
    """Lanternes au bout des ruelles des nouveaux lieux."""
    # Aucune dans un bâtiment : celle de la boulangerie est devenue la lanterne de sa porte, celle de l'herboristerie
    # est passée au coin du jardin des simples.
    for x, z in ((-41.0, -51.5), (-55.2, 24.6), (-57.0, -7.0), (-20.0, 58.0), (8.0, 68.0), (74.8, -16.0)):
        scene.add("fantasy_town_kit/lantern", (x, 0.0, z), 0.0, 2.2)
        scene.add_box((x, 1.0, z), (0.45, 2.0, 0.45))


# Ponts sur la rivière : (x, z, cap du tablier, longueur, largeur), comme BRIDGES dans hub_terrain.gd.
# Le tablier affleure le chemin (dessus à 0,1 m) ; ses parapets portent une collision haute, pour qu'on ne saute pas
# dans la rivière, dont les berges ne s'ouvrent que sous les ponts.
BRIDGES = [(63.25, 0.0, 0.0, 15.5, 5.0), (63.0, -66.0, 0.0, 15.0, 3.0)]
DECK_TOP = 0.1


def bridge_collision(scene, x, z, degrees, length, width, rail):
    """Tablier et parapets d'un pont : la collision est la même, pont de fortune ou reconstruit."""
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
    scene.add_box((x, DECK_TOP - 0.25, z), (length + 0.6, 0.5, width), degrees)
    for side in (-1, 1):
        # Le côté du tablier : la normale de son axe, dans le plan.
        nx, nz = s * side * rail, c * side * rail
        scene.add_box((x + nx, DECK_TOP + 1.1, z + nz), (length + 0.6, 2.2, 0.3), degrees)


def build_bridges(scene, rng):
    """Le grand pont de pierre du chemin du bunker, et la passerelle du jardin du roi vers la rive est."""
    x, z, degrees, length, width = BRIDGES[0]
    scene.group = "Fixed"
    bridge_collision(scene, x, z, degrees, length, width, 2.06)
    # Avant le premier livre : un pont de fortune, des planches jetées sur les piles du pont effondré.
    scene.repair("GreatBridge", 1)
    scene.add("nature_kit/bridge_wood", (x, DECK_TOP - 0.15 * 6.0, z), degrees, (length / 1.04, 6.0, width / 1.04))
    # Blocs du pont effondré, tombés dans le lit de la rivière : ils affleurent de l'eau, de part et d'autre du tablier.
    for dx, dz, y in ((-1.6, 3.6, -1.95), (1.4, -3.8, -2.05), (0.2, 4.2, -2.3)):
        scene.add("castle_kit/rocks-small", (x + dx, y, z + dz), rng.uniform(0, 360), 1.6)
    scene.rebuilt("GreatBridge")
    scene.add("nature_kit/bridge_stoneRound", (x, DECK_TOP - 0.15 * 6.0, z), degrees, (length / 1.04, 6.0, width / 1.04))
    for end in (-1, 1):
        for side in (-1, 1):
            lx, lz = x + end * (length / 2 + 0.7), z + side * 2.9
            scene.add("fantasy_town_kit/lantern", (lx, 0.0, lz), 0.0, 2.2)
            scene.add_box((lx, 1.0, lz), (0.45, 2.0, 0.45))
    # Passerelle de bois du jardin du roi : reconstruite avec le jardin, au deuxième livre.
    x, z, degrees, length, width = BRIDGES[1]
    scene.group = "Fixed"
    bridge_collision(scene, x, z, degrees, length, width, 1.24)
    scene.repair("ParkFootbridge", 2)
    scene.add("nature_kit/bridge_wood", (x, DECK_TOP - 0.15 * 6.0, z), degrees, (length / 1.04, 6.0, width / 1.04))
    scene.add("survival_kit/resource-planks", (x + 6.5, -1.0, z + 2.6), 30.0, 2.6)
    scene.rebuilt("ParkFootbridge")
    scene.add("nature_kit/bridge_woodRound", (x, DECK_TOP - 0.15 * 6.0, z), degrees, (length / 1.04, 6.0, width / 1.04))
    scene.group = "Fixed"


def main():
    build_shelter()
    rng = random.Random(5814)
    scene = StagedScene("HubProps")
    scene.batched("res://scenes/levels/hub/hub_batch.gd")
    build_camp(scene)
    build_village(scene, rng)
    build_castle(scene, rng)
    build_bunker(scene, rng)
    build_landmarks(scene, rng)
    build_mine(scene, rng)
    build_bridges(scene, rng)
    build_quarters(scene, random.Random(5820))
    build_park(scene, random.Random(5821))
    build_quarter_paths(scene)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(scene.text(), encoding="utf-8", newline="\n")
    print(f"{OUTPUT.name} : {len(scene.visuals)} modèles, {len(scene.colliders)} collisions")


if __name__ == "__main__":
    main()
