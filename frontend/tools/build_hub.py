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

from build_plaine import (MEDIEVAL, MODEL_BOXES, OUTWARD_ANGLES, WALL_HEIGHT, WALL_SCALE, Scene, doorway, multiply,
                          rotation_x, rotation_y, rotation_z, wall)
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
})


def furniture(scene, model, center, degrees=0.0, scale=2.6, height=None, tilt=0.0, roll=0.0):
    """Comme furniture() de build_plaine, avec en plus une échelle par axe du modèle (x, y, z)."""
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

    def batched(self, script):
        """Script de la racine qui regroupe les modèles de chaque groupe en MultiMesh au chargement."""
        self.scripts.setdefault(script, f"{len(self.scripts) + 1}_script")
        self.root_script = script

    def pivot(self, path, position, script, properties):
        """Ouvre un groupe posé en un point, avec un script : les ajouts suivants s'y placent dans son repère."""
        self.scripts.setdefault(script, f"{len(self.scripts) + 1}_script")
        self.pivots[path] = (f"Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {position[0]:g}, {position[1]:g}, {position[2]:g})", script, properties)
        self.group = path

    def add(self, model, position, degrees=0.0, scale=1.0, tilt=0.0, roll=0.0):
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
        groups = list(dict.fromkeys([v[3] for v in self.visuals] + [c[2] for c in self.colliders]))
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
                    transform, script, properties = self.pivots[path]
                    lines.append(f"transform = {transform}")
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
    """Toit à deux pans : les tuiles se rejoignent au faîte, au milieu de la largeur."""
    for column in range(width):
        x = cx - (width - 1) * TILE / 2 + column * TILE
        outward = (1, 0) if x > cx else (-1, 0)
        for row in range(depth):
            z = cz - (depth - 1) * TILE / 2 + row * TILE
            if abs(x - cx) < 0.1:
                scene.add("fantasy_town_kit/roof-flat", (x, base + 0.1, z), 0.0, TILE)
            else:
                scene.add("fantasy_town_kit/roof", (x, base, z), OUTWARD_ANGLES[outward], TILE)


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


def furnish(scene, house, ruined, rng):
    """Meubles d'une maison : lit, table, cuisine et étagère ; renversés et cassés dans les ruines."""
    frame = HouseFrame(house)
    hu, hv = frame.half_u, frame.half_v
    # Dans les ruines, les meubles sont renversés : couchés sur le flanc, posés au sol.
    tilt = (lambda: rng.choice((90.0, 90.0, 0.0))) if ruined else (lambda: 0.0)
    # Lit contre le mur du fond, à gauche ; cuisine contre le mur du fond, à droite.
    furniture(scene, "furniture_kit/bedSingle", frame.at(-hu + 1.6, -hv + 1.8), frame.turn(rng.uniform(-6, 6) if ruined else 0.0),
              1.6, height=0.8)
    for index, model in enumerate(("kitchenCabinet", "kitchenStove", "kitchenSink")):
        if ruined and index == 1:
            continue
        furniture(scene, f"furniture_kit/{model}", frame.at(hu - 0.6 - index * 1.15, -hv + 0.65), frame.turn(0.0), 2.6,
                  height=1.2)
    # Table et chaises au milieu, étagère contre le mur de droite.
    table = frame.at(0.6, 0.2)
    furniture(scene, "furniture_kit/tableRound", table, frame.turn(rng.uniform(0, 90)), 2.2,
              height=0.8, tilt=90.0 if ruined else 0.0)
    for side in (-1, 1):
        furniture(scene, "furniture_kit/chair", frame.at(0.6 + side * 1.3, 0.2), frame.turn(90.0 * side + (rng.uniform(-40, 40) if ruined else 0.0)),
                  2.6, tilt=tilt())
    if ruined:
        furniture(scene, "furniture_kit/bookcaseOpenLow", frame.at(hu - 1.0, 0.8), frame.turn(-90.0 + rng.uniform(-15, 15)), 3.0,
                  height=0.8, tilt=90.0)
    else:
        furniture(scene, "furniture_kit/bookcaseOpenLow", frame.at(hu - 0.4, 0.6), frame.turn(-90.0), 3.0, height=1.2)
    if ruined:
        scene.add("survival_kit/resource-planks", frame.at(rng.uniform(-1, 1), rng.uniform(-1, 1)), rng.uniform(0, 360), 3.0)
        scene.add("castle_kit/rocks-small", frame.at(-hu + 1.0, hv - 1.2), rng.uniform(0, 360), 1.4)
    else:
        furniture(scene, "furniture_kit/rugRound", frame.at(0.6, 0.2, 0.02), frame.turn(0.0), 2.6)
        furniture(scene, "furniture_kit/pottedPlant", frame.at(-hu + 0.5, hv - 0.6), frame.turn(0.0), 2.6)
        # Tonneau et caisse dehors, contre la façade, du côté opposé à la porte.
        side = -1.0 if frame.door_u >= 0 else 1.0
        furniture(scene, "survival_kit/barrel", frame.at(side * (hu - 0.4), hv + 1.2), frame.turn(0.0), 3.2, height=1.1)
        furniture(scene, "survival_kit/box", frame.at(side * (hu - 1.5), hv + 1.2), frame.turn(20.0), 3.2, height=0.8)


def house_floor(scene, rng, house, ruined):
    """Plancher de bois sur toutes les cases, enfoncé pour affleurer le sol : il ne gêne pas les pas.
    Dans les ruines, des lattes manquent ou sont arrachées. Les maisons à étage ont aussi le plancher de l'étage."""
    cx, cz, width, depth, _, _, floors = house
    for column in range(width):
        for row in range(depth):
            x = cx - (width - 1) * TILE / 2 + column * TILE
            z = cz - (depth - 1) * TILE / 2 + row * TILE
            if not ruined:
                scene.add("fantasy_town_kit/planks", (x, -0.2, z), 0.0, TILE)
                for floor in range(1, floors):
                    scene.add("fantasy_town_kit/planks", (x, floor * WALL_HEIGHT - 0.2, z), 0.0, TILE)
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
            continue
        roll = rng.random()
        if roll < 0.2:
            scene.add("castle_kit/rocks-small", (center[0], 0.0, center[1]), rng.uniform(0, 360), 1.6)
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
    # Poutres de la charpente tombées au sol, en travers de la pièce.
    for beam in range(rng.randint(1, 2)):
        point = (cx + rng.uniform(-half_w + 1.8, half_w - 1.8), 0.0, cz + rng.uniform(-half_d + 1.8, half_d - 1.8))
        furniture(scene, "fantasy_town_kit/poles-horizontal", point, rng.uniform(0, 180), 3.0, tilt=90.0)
    house_floor(scene, rng, house, True)
    (furnisher or furnish)(scene, house, True, rng)


def rebuilt_house(scene, rng, house, furnisher=None):
    cx, cz, width, depth, door_side, style, floors = house
    plain, _, window, window_small = wall_models(style)
    for side, index, count, center, outward in edge_tiles(cx, cz, width, depth):
        if side == door_side and index == count // 2:
            doorway(scene, center, outward)
            along = (outward[1], outward[0])
            scene.add("fantasy_town_kit/lantern", (center[0] + outward[0] * 0.5 + along[0] * 1.6, 0.0,
                                                   center[1] + outward[1] * 0.5 + along[1] * 1.6), 0.0, 2.2)
        else:
            wall(scene, rng.choice((plain, window, window_small, window)), center, outward)
        if floors > 1:
            upper = "wall-wood-window-shutters" if index % 2 == 0 else "wall-wood"
            wall(scene, upper, center, outward, base=WALL_HEIGHT, solid=False)
    half_w, half_d = width * TILE / 2, depth * TILE / 2
    pillar = "fantasy_town_kit/pillar-wood" if style == "wood" else "fantasy_town_kit/pillar-stone"
    for sx in (-1, 1):
        for sz in (-1, 1):
            for floor in range(floors):
                scene.add(pillar, (cx + sx * half_w, floor * WALL_HEIGHT, cz + sz * half_d), 0.0, WALL_SCALE)
    roof(scene, cx, cz, width, depth, WALL_HEIGHT * floors)
    scene.add("fantasy_town_kit/chimney", (cx - half_w + 1.2, WALL_HEIGHT * floors, cz), 0.0, 3.0)
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
        rebuilt_house(scene, random.Random(100 + number), house)
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
        scene.add_box((x, 1.5, z), (3.0, 3.0, 3.0), degrees)
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
        ("survival_kit/bucket", 7.4, -5.2, 0.0, 4.0, None),
    ):
        scene.add(model, (x, 0.0, z), degrees, scale)
        if size:
            scene.add_box((x, size[1] / 2, z), size, degrees)
    scene.add("food_kit/bread", (9.6, 1.0, -5.6), 15.0, 2.5)


def curtain_wall(scene, x, z, along_x, height_scale=1.0):
    """Pan de l'enceinte ; éventré, il n'a plus qu'une partie de sa hauteur, et sa collision le suit."""
    scene.add("castle_kit/wall", (x, 0.0, z), 0.0 if along_x else 90.0, (CURTAIN_SCALE, CURTAIN_SCALE * height_scale, CURTAIN_SCALE))
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
    scene.add("castle_kit/wall", (0.0, 10.4, gate_z), 0.0, CURTAIN_SCALE)
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
        # La rangée du haut recouvre les créneaux de celle du bas : un peu plus épaisse, ses faces passent devant
        # au lieu de se confondre avec celles du bas, qui scintilleraient.
        scale = KEEP_SCALE if layer == 0 else (KEEP_SCALE, KEEP_SCALE, KEEP_SCALE * 1.03)
        for x in range(int(-KEEP_X), int(KEEP_X) + 1, int(KEEP_SCALE)):
            for z in (KEEP_BACK, KEEP_FRONT):
                if z == KEEP_FRONT and x == 0 and layer == 0:
                    continue
                scene.add("castle_kit/wall", (x, y, z), 0.0, scale)
        for z in range(int(KEEP_BACK + KEEP_SCALE), int(KEEP_FRONT), int(KEEP_SCALE)):
            for x in (-KEEP_X, KEEP_X):
                scene.add("castle_kit/wall", (x, y, z), 90.0, scale)
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
    scene.add("fantasy_town_kit/fence", (18.0, 0.0, -68.0), 90.0, 4.0)
    scene.add_box((18.0, 0.8, -66.3), (4.0, 1.6, 0.3))
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
    furniture(scene, "castle_kit/siege-catapult", (-9.0, 0.0, -68.3), 0.0, 2.6, height=2.6)
    furniture(scene, "castle_kit/siege-ballista", (10.0, 0.0, -68.4), -30.0, 2.6, height=2.2)
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
        scene.add("survival_kit/metal-panel", (bx - TILE - 0.3, 0.6, bz + dz), 90.0, 3.4)
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
    # Dalle de terre au-dessus du plafond : l'abri est enterré, aucun jour ne passe entre les planches.
    scene.add("fantasy_town_kit/roof-flat", (cx, WALL_HEIGHT + 0.3, cz), 0.0, 1.0)
    for column in range(width):
        for row in range(depth):
            x = cx - (width - 1) * TILE / 2 + column * TILE
            z = cz - (depth - 1) * TILE / 2 + row * TILE
            scene.add("fantasy_town_kit/roof-flat", (x, WALL_HEIGHT + 0.3, z), 0.0, TILE)
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


# Bâtiments publics du village, autour du cœur : (nom, maison, palier de réparation, ameublement).
# Leur porte regarde le feu de camp. Les panneaux et leurs textes sont posés dans hub.tscn.
LANDMARKS = [
    ("School", (0.0, 60.0, 3, 2, "north", "stone", 2), 2, "school"),
    ("Tavern", (-60.0, 0.0, 3, 2, "east", "wood", 2), 1, "tavern"),
    ("Chapel", (-56.0, -30.0, 2, 3, "east", "stone", 1), 3, "chapel"),
    ("Forge", (55.0, 18.0, 2, 2, "west", "stone", 1), 1, "forge"),
    ("Farm", (44.0, 64.0, 2, 2, "north", "wood", 1), 2, "farm"),
]


def furnish_school(scene, house, ruined, rng):
    """Salle de classe : pupitres en rangs face au bureau du maître, étagère de livres."""
    frame = HouseFrame(house)
    hu, hv = frame.half_u, frame.half_v
    furniture(scene, "furniture_kit/desk", frame.at(0.0, -hv + 1.1), frame.turn(0.0), 2.8, height=1.1, roll=90.0 if ruined else 0.0)
    for row in range(2):
        # Deux rangées de pupitres de part et d'autre de l'allée qui mène de la porte au maître.
        for column in (-4.0, -1.9, 1.9, 4.0):
            spot = frame.at(column, -0.4 + row * 2.2)
            tipped = ruined and rng.random() < 0.6
            furniture(scene, "furniture_kit/desk", spot, frame.turn(180.0 + (rng.uniform(-30, 30) if ruined else 0.0)), 1.8,
                      height=0.7, roll=90.0 if tipped else 0.0)
    furniture(scene, "furniture_kit/bookcaseOpen", frame.at(-hu + 0.6, -hv + 1.1), frame.turn(90.0), 3.0, height=2.6,
              roll=90.0 if ruined else 0.0)
    furniture(scene, "furniture_kit/bookcaseOpen", frame.at(hu - 0.6, -hv + 1.1), frame.turn(-90.0), 3.0, height=2.6)
    if not ruined:
        furniture(scene, "furniture_kit/rugRectangle", frame.at(0.0, 0.7, 0.02), frame.turn(0.0), 3.2)


def furnish_tavern(scene, house, ruined, rng):
    """La Chope du Dragon : comptoir et tabourets, tables et chaises, tonneaux de bière."""
    frame = HouseFrame(house)
    hu, hv = frame.half_u, frame.half_v
    for index in range(3):
        furniture(scene, "furniture_kit/kitchenBar", frame.at(-1.2 + index * 1.15, -hv + 0.7), frame.turn(0.0), 2.6, height=1.1)
        furniture(scene, "furniture_kit/stoolBar", frame.at(-1.2 + index * 1.15, -hv + 1.9), frame.turn(0.0), 2.4,
                  roll=90.0 if ruined and index != 1 else 0.0)
    for x in (-hu + 1.0, -hu + 2.1):
        furniture(scene, "mini_dungeon/barrel", frame.at(x, -hv + 0.8), frame.turn(0.0), 2.6, height=1.2)
    # Deux tables l'une derrière l'autre, dans la longueur de la salle.
    for v in (0.2, 3.2):
        table = frame.at(-0.8, v)
        furniture(scene, "furniture_kit/tableRound", table, frame.turn(0.0), 2.2, height=0.8, tilt=90.0 if ruined and v > 1 else 0.0)
        for side in (-1, 1):
            furniture(scene, "furniture_kit/chair", frame.at(-0.8 + side * 1.3, v), frame.turn(90.0 * side), 2.6,
                      tilt=90.0 if ruined and rng.random() < 0.5 else 0.0)


def furnish_chapel(scene, house, ruined, rng):
    """Chapelle : autel et croix au fond, bancs en deux rangées de part et d'autre de l'allée."""
    frame = HouseFrame(house)
    hu, hv = frame.half_u, frame.half_v
    furniture(scene, "graveyard_kit/altar-wood", frame.at(0.0, -hv + 1.0), frame.turn(0.0), 2.4, height=1.3)
    furniture(scene, "graveyard_kit/cross", frame.at(0.0, -hv + 0.25), frame.turn(0.0), 2.6, height=2.7, roll=90.0 if ruined else 0.0)
    for row in range(3):
        for side in (-1, 1):
            furniture(scene, "graveyard_kit/bench", frame.at(side * 1.6, -1.6 + row * 1.9), frame.turn(180.0 + (rng.uniform(-25, 25) if ruined else 0.0)),
                      2.2, height=1.0, roll=90.0 if ruined and rng.random() < 0.5 else 0.0)
    for side in (-1, 1):
        furniture(scene, "graveyard_kit/candle-multiple", frame.at(side * 1.6, -hv + 0.7), frame.turn(0.0), 2.6)


def furnish_forge(scene, house, ruined, rng):
    """Forge : enclume et meule, établi, tonneaux et outils."""
    frame = HouseFrame(house)
    hu, hv = frame.half_u, frame.half_v
    furniture(scene, "survival_kit/workbench-anvil", frame.at(-1.0, -0.6), frame.turn(0.0), 4.0, height=1.2, roll=90.0 if ruined else 0.0)
    furniture(scene, "survival_kit/workbench-grind", frame.at(1.6, -hv + 1.0), frame.turn(180.0), 4.0, height=1.2)
    furniture(scene, "survival_kit/workbench", frame.at(-hu + 1.0, 1.0), frame.turn(90.0), 5.0, height=1.2)
    furniture(scene, "mini_dungeon/barrel", frame.at(hu - 0.8, -hv + 0.8), frame.turn(0.0), 2.6, height=1.2)
    furniture(scene, "survival_kit/chest", frame.at(hu - 0.8, 1.4), frame.turn(-90.0), 3.4, height=0.8)
    furniture(scene, "nature_kit/log_stack", frame.at(-hu + 0.9, -hv + 1.1), frame.turn(0.0), 3.0, height=1.0)


def furnish_farm(scene, house, ruined, rng):
    """Ferme : lit, table, et dehors les champs, le foin et l'enclos."""
    furnish(scene, house, ruined, rng)
    cx, cz = house[0], house[1]
    # Champ à l'est de la ferme : rangées de terre et de cultures, qui repoussent avec le village.
    for row in range(5):
        z = cz - 5.0 + row * 2.4
        for column in range(4):
            x = cx + 8.0 + column * 2.4
            scene.add("nature_kit/crops_dirtRow", (x, 0.0, z), 0.0, 2.4)
            if not ruined:
                crop = ("nature_kit/crops_wheatStageB", "nature_kit/crops_cornStageD", "nature_kit/crop_pumpkin")[row % 3]
                scene.add(crop, (x, 0.0, z), rng.uniform(0, 360), 2.4)
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
        rebuilt_house(scene, random.Random(name + "!"), house, FURNISHERS[kind])
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


def build_mine(scene, rng):
    """Mine d'argent au pied des montagnes, au nord-est : galerie boisée sous un tertre de roche, effondrée."""
    mx, mz = 86.0, -42.0
    # Tertre de roche autour de l'entrée, qui regarde le village : deux étages de gros blocs.
    for index in range(12):
        angle = math.radians(-20 + index * 30)
        if index in (5, 6):
            continue
        for ring, (radius, y, scale) in enumerate(((7.0, 0.0, 8.0), (4.0, 3.2, 8.5))):
            x, z = mx + 2.0 + math.cos(angle) * radius, mz - 2.0 + math.sin(angle) * radius
            scene.add("castle_kit/rocks-large", (x, y, z), rng.uniform(0, 360), scale * rng.uniform(0.9, 1.1))
        x, z = mx + 2.0 + math.cos(angle) * 7.0, mz - 2.0 + math.sin(angle) * 7.0
        scene.add_box((x, 2.4, z), (5.0, 4.8, 5.0))
    scene.add("castle_kit/rocks-large", (mx + 2.0, 5.6, mz - 2.0), 30.0, 9.0)
    scene.add_box((mx + 2.0, 3.0, mz - 2.0), (8.0, 6.0, 8.0))
    # Boisage de l'entrée, sous le tertre, et l'éboulis qui la bouche.
    for offset in (0.0, 1.6):
        furniture(scene, "mini_dungeon/wood-structure", (mx - 2.6 + offset, 0.0, mz + 2.6 - offset), -45.0, 4.6)
    scene.add_box((mx - 1.6, 2.3, mz + 1.6), (5.0, 4.6, 1.4), -45.0)
    for x, z in ((mx - 2.2, mz + 2.2), (mx - 1.2, mz + 1.4), (mx - 3.0, mz + 1.6)):
        furniture(scene, "survival_kit/resource-stone-large", (x, 0.0, z), rng.uniform(0, 360), 6.0)
    # Chariot de minerai renversé, outils et caisses abandonnés devant.
    furniture(scene, "fantasy_town_kit/cart", (mx - 9.0, 0.0, mz + 6.5), 30.0, 2.6, height=1.4, roll=90.0)
    for x, z, yaw in ((mx - 5.0, mz + 7.0, 20.0), (mx - 6.0, mz + 8.0, 70.0)):
        furniture(scene, "survival_kit/tool-pickaxe", (x, 0.0, z), yaw, 4.0, tilt=90.0)
    for x, z in ((mx - 9.5, mz + 2.0), (mx - 9.0, mz + 3.4)):
        furniture(scene, "survival_kit/box-large", (x, 0.0, z), 30.0, 3.6, height=0.9)


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
    """Boulangerie : le four de briques au fond, le pétrin et la table à pain, les sacs de farine, les miches."""
    frame = HouseFrame(house)
    hu, hv = frame.half_u, frame.half_v
    oven = frame.at(-hu + 1.6, -hv + 0.9)
    furniture(scene, "fantasy_town_kit/chimney-base", oven, frame.turn(-90.0), 3.6, height=3.6)
    furniture(scene, "graveyard_kit/fire-basket", frame.at(-hu + 1.6, -hv + 2.3), frame.turn(0.0), 2.6, height=0.5)
    table = frame.at(0.9, -hv + 1.0)
    furniture(scene, "mini_dungeon/table", table, frame.turn(0.0), 3.2, height=1.0, roll=90.0 if ruined else 0.0)
    for index in range(3):
        furniture(scene, "food_kit/bag", frame.at(hu - 0.6, -hv + 0.8 + index * 1.0), frame.turn(rng.uniform(-20, 20)), 1.6,
                  height=1.3, tilt=90.0 if ruined and index == 1 else 0.0)
    furniture(scene, "mini_dungeon/barrel", frame.at(hu - 0.7, 1.4), frame.turn(0.0), 2.6, height=1.2)
    if ruined:
        furniture(scene, "food_kit/bag-flat", frame.at(-0.5, 0.5), frame.turn(rng.uniform(0, 90)), 1.6)
        scene.add("survival_kit/resource-planks", frame.at(-1.2, 1.4), rng.uniform(0, 360), 3.0)
        return
    top = 1.0
    for index, model in enumerate(("food_kit/loaf", "food_kit/loaf-round", "food_kit/loaf-baguette")):
        furniture(scene, model, frame.at(0.1 + index * 0.75, -hv + 1.0, top), frame.turn(rng.uniform(-30, 30)), 0.9)
    furniture(scene, "food_kit/cutting-board", frame.at(1.9, -hv + 1.0, top), frame.turn(90.0), 1.0)
    furniture(scene, "food_kit/rollingPin", frame.at(1.9, -hv + 1.0, top + 0.06), frame.turn(10.0), 1.0)
    # Étal devant la porte : le pain du matin, sous l'auvent.
    side = -1.0 if frame.door_u >= 0 else 1.0
    stall = frame.at(side * 2.0, hv + 1.4)
    furniture(scene, "fantasy_town_kit/stall-bench", stall, frame.turn(90.0), 3.0, height=0.7)
    for index in range(3):
        furniture(scene, "food_kit/loaf-round" if index % 2 else "food_kit/loaf", frame.at(side * 2.0 - 0.9 + index * 0.9, hv + 1.4, 0.7),
                  frame.turn(rng.uniform(0, 360)), 0.8)


def furnish_mill(scene, house, ruined, rng):
    """Moulin : la meule au milieu, les sacs de grain et de farine, des caisses, l'échelle vers le grenier."""
    frame = HouseFrame(house)
    hu, hv = frame.half_u, frame.half_v
    furniture(scene, "survival_kit/workbench-grind", frame.at(0.8, -0.6), frame.turn(0.0), 6.0, height=1.8, roll=90.0 if ruined else 0.0)
    for index in range(4):
        furniture(scene, "food_kit/bag", frame.at(-hu + 0.6 + index * 0.9, -hv + 0.6), frame.turn(rng.uniform(-25, 25)), 1.6,
                  height=1.3, tilt=90.0 if ruined and index % 2 else 0.0)
    for index in range(2):
        furniture(scene, "survival_kit/box-large", frame.at(hu - 0.8, -hv + 1.0 + index * 1.6), frame.turn(90.0), 3.4, height=0.9)
    furniture(scene, "mini_forest/ladder", frame.at(-hu + 0.9 if not ruined else 0.4, 0.8), frame.turn(90.0), 3.8, tilt=-12.0 if not ruined else 90.0)
    if not ruined:
        furniture(scene, "mini_dungeon/barrel", frame.at(hu - 0.7, 1.8), frame.turn(0.0), 2.6, height=1.2)
        # Charrette de sacs devant la porte, du côté opposé.
        side = -1.0 if frame.door_u >= 0 else 1.0
        furniture(scene, "fantasy_town_kit/cart", frame.at(side * 2.2, hv + 2.4), frame.turn(90.0), 2.6, height=1.4)
        furniture(scene, "food_kit/bag", frame.at(side * 2.2, hv + 2.4, 0.72), frame.turn(10.0), 1.3)


def furnish_stables(scene, house, ruined, rng):
    """Écuries royales : des stalles séparées par des barrières, du foin, des seaux et des abreuvoirs. Les chevaux
    sont partis avec l'armée ; les stalles attendent leur retour."""
    frame = HouseFrame(house)
    hu, hv = frame.half_u, frame.half_v
    for index, v in enumerate((-hv + 2.6, -hv + 5.4, -hv + 8.2)):
        furniture(scene, "nature_kit/fence_simple", frame.at(-hu + 1.4, v), frame.turn(90.0), 2.8, height=1.0,
                  roll=90.0 if ruined and index == 1 else 0.0)
        furniture(scene, "graveyard_kit/hay-bale", frame.at(-hu + 0.7, v + 1.2), frame.turn(90.0 + rng.uniform(-10, 10)), 2.4, height=0.9)
        furniture(scene, "survival_kit/barrel-open", frame.at(-hu + 0.5, v - 0.6), frame.turn(0.0), 3.0, height=1.0,
                  tilt=90.0 if ruined and index == 2 else 0.0)
    furniture(scene, "survival_kit/bucket", frame.at(hu - 0.6, -hv + 0.8), frame.turn(0.0), 3.4)
    furniture(scene, "graveyard_kit/hay-bale-bundled", frame.at(hu - 0.8, -hv + 2.4), frame.turn(0.0), 2.6, height=1.0)
    if not ruined:
        furniture(scene, "survival_kit/chest", frame.at(hu - 0.7, -hv + 4.2), frame.turn(-90.0), 3.4, height=0.8)
        # Enclos derrière les écuries, côté forêt.
        cx, cz = house[0], house[1]
        for index in range(4):
            furniture(scene, "nature_kit/fence_simple", (cx - 8.6, 0.0, cz - 5.0 + index * 2.8), 90.0, 2.8, height=1.0)
            furniture(scene, "nature_kit/fence_simple", (cx - 6.6 - index * 2.8 + 4.0, 0.0, cz + 6.4), 0.0, 2.8, height=1.0)


def furnish_barracks(scene, house, ruined, rng):
    """Caserne de la garde : lits superposés le long du mur du fond, râteliers d'armes, coffres, la grande table."""
    frame = HouseFrame(house)
    hu, hv = frame.half_u, frame.half_v
    # Trois lits superposés, la tête contre le mur du fond ; renversés dans les ruines, loin des murs.
    for index, u in enumerate((-4.2, -1.3, 1.6)):
        if ruined and index % 2:
            furniture(scene, "furniture_kit/bedBunk", frame.at(u + 0.2, -hv + 2.2), frame.turn(rng.uniform(-8, 8)), 1.6, height=1.0, roll=90.0)
            continue
        furniture(scene, "furniture_kit/bedBunk", frame.at(u, -hv + 1.65), frame.turn(rng.uniform(-4, 4) if ruined else 0.0), 1.6, height=1.6)
    furniture(scene, "survival_kit/chest", frame.at(4.4, -hv + 0.8), frame.turn(90.0), 3.0, height=0.7)
    table = frame.at(-3.0, 1.9)
    furniture(scene, "mini_dungeon/table", table, frame.turn(0.0), 3.4, height=1.0, roll=90.0 if ruined else 0.0)
    furniture(scene, "furniture_kit/bench", frame.at(-3.0, 0.3), frame.turn(0.0), 3.0, tilt=90.0 if ruined else 0.0)
    for index, v in enumerate((-0.6, 1.6)):
        furniture(scene, "mini_arena/weapon-rack", frame.at(hu - 0.7, v), frame.turn(-90.0), 3.0, height=1.4,
                  tilt=90.0 if ruined and index == 0 else 0.0)
    if not ruined:
        for u in (-4.2, -1.3, 1.6):
            furniture(scene, "mini_dungeon/shield-rectangle", frame.at(u, -hv + 0.25, 2.4), frame.turn(0.0), 3.0)
        # Cour d'entraînement, entre la caserne et l'enceinte du château : cibles, mannequins de paille, râtelier.
        cx, cz = house[0], house[1]
        for index, (x, z) in enumerate(((cx + 10.0, cz - 3.0), (cx + 13.0, cz - 3.0), (cx + 16.0, cz - 3.0))):
            furniture(scene, "mini_forest/target", (x, 0.0, z), 0.0, 3.0, height=1.6)
        for x in (cx + 10.5, cx + 14.5):
            furniture(scene, "graveyard_kit/hay-bale-bundled", (x, 0.0, cz + 4.5), 90.0, 2.6, height=1.0)
            furniture(scene, "graveyard_kit/hay-bale-bundled", (x, 1.0, cz + 4.5), 0.0, 2.2)
        furniture(scene, "mini_arena/weapon-rack", (cx + 18.0, 0.0, cz + 1.0), -90.0, 3.0, height=1.4)


def furnish_apothecary(scene, house, ruined, rng):
    """Herboristerie : étagères de fioles, chaudron et mortier sur la table, bocaux et herbes séchées ; dehors,
    le jardin des simples."""
    frame = HouseFrame(house)
    hu, hv = frame.half_u, frame.half_v
    for index, u in enumerate((-hu + 1.2, 0.0)):
        if ruined and index == 1:
            furniture(scene, "furniture_kit/bookcaseOpen", frame.at(u, -hv + 1.6), frame.turn(0.0), 3.0, height=0.8, tilt=90.0)
            continue
        furniture(scene, "furniture_kit/bookcaseOpen", frame.at(u, -hv + 0.4), frame.turn(0.0), 3.0, height=2.6)
    table = frame.at(-0.6, 0.0)
    furniture(scene, "mini_dungeon/table", table, frame.turn(0.0), 3.0, height=1.0, roll=90.0 if ruined else 0.0)
    furniture(scene, "food_kit/pot-stew", frame.at(hu - 1.0, -hv + 1.0), frame.turn(0.0), 2.0, height=0.8)
    furniture(scene, "graveyard_kit/fire-basket", frame.at(hu - 1.0, -hv + 2.6), frame.turn(0.0), 2.4, height=0.5)
    furniture(scene, "mini_dungeon/barrel", frame.at(hu - 0.7, 1.6), frame.turn(0.0), 2.4, height=1.1)
    if ruined:
        for index in range(3):
            scene.add("mini_dungeon/potion", frame.at(rng.uniform(-1.5, 1.5), rng.uniform(-1.0, 1.5)), rng.uniform(0, 360), 1.0, tilt=90.0)
        return
    for index in range(3):
        furniture(scene, "mini_dungeon/potion", frame.at(-0.9 + index * 0.6, 0.0, 0.94), frame.turn(rng.uniform(0, 360)), 0.8)
    furniture(scene, "food_kit/mortar-pestle", frame.at(0.3, 0.3, 0.94), frame.turn(0.0), 1.4)
    for index, u in enumerate((-hu + 0.9, -hu + 1.5)):
        furniture(scene, "mini_dungeon/potion", frame.at(u, -hv + 0.4, 1.25), frame.turn(rng.uniform(0, 360)), 0.7)
    # Jardin des simples, entre la porte et le chemin : carrés d'herbes et de racines.
    cx, cz = house[0], house[1]
    for row in range(3):
        for column in range(2):
            x, z = cx + 6.5 + column * 1.8, cz - 3.6 + row * 1.5
            scene.add("nature_kit/crops_dirtRow", (x, 0.0, z), 90.0, 1.8)
            crop = ("nature_kit/crops_leafsStageB", "nature_kit/crop_carrot", "nature_kit/crop_turnip")[row]
            scene.add(crop, (x, 0.0, z), rng.uniform(0, 360), 1.4)


def furnish_scriptorium(scene, house, ruined, rng):
    """Scriptorium, où l'on recopiait les livres de Codia : pupitres à écrire, livres ouverts, chandelles,
    bibliothèques le long des murs."""
    frame = HouseFrame(house)
    hu, hv = frame.half_u, frame.half_v
    for u in (-hu + 0.4, hu - 0.4):
        if ruined and u > 0:
            furniture(scene, "furniture_kit/bookcaseClosedWide", frame.at(hu - 1.7, -hv + 1.6), frame.turn(-90.0), 3.0, height=0.8, tilt=90.0)
            continue
        furniture(scene, "furniture_kit/bookcaseClosedWide", frame.at(u, -hv + 1.6), frame.turn(90.0 if u < 0 else -90.0), 3.0, height=2.4)
    for row in range(2):
        for side in (-1, 1):
            spot = frame.at(side * 1.6, -hv + 1.6 + row * 2.4)
            furniture(scene, "mini_dungeon/table", spot, frame.turn(0.0), 2.4, height=0.8, roll=90.0 if ruined and side > 0 else 0.0)
            furniture(scene, "furniture_kit/chair", frame.at(side * 1.6, -hv + 2.6 + row * 2.4), frame.turn(180.0), 2.4,
                      tilt=90.0 if ruined and row == 1 else 0.0)
            if not ruined:
                furniture(scene, "furniture_kit/books", frame.at(side * 1.6 - 0.2, -hv + 1.6 + row * 2.4, 0.78), frame.turn(rng.uniform(-20, 20)), 2.6)
                furniture(scene, "graveyard_kit/candle", frame.at(side * 1.6 + 0.4, -hv + 1.4 + row * 2.4, 0.78), frame.turn(0.0), 1.6)
    furniture(scene, "graveyard_kit/altar-wood", frame.at(0.0, -hv + 0.6), frame.turn(0.0), 1.8, height=1.0)
    if ruined:
        for index in range(4):
            scene.add("furniture_kit/books", frame.at(rng.uniform(-2.0, 2.0), rng.uniform(-1.0, 2.0)), rng.uniform(0, 360), 2.6)
    else:
        furniture(scene, "survival_kit/chest", frame.at(hu - 0.8, 1.6), frame.turn(-90.0), 3.0, height=0.7)


QUARTER_FURNISHERS = {"bakery": furnish_bakery, "mill": furnish_mill, "stables": furnish_stables, "barracks": furnish_barracks,
                      "apothecary": furnish_apothecary, "scriptorium": furnish_scriptorium}


def build_quarters(scene, rng):
    for name, house, stage, kind in QUARTERS:
        scene.repair(name, stage)
        ruined_house(scene, random.Random(name), house, QUARTER_FURNISHERS[kind])
        scene.rebuilt(name)
        rebuilt_house(scene, random.Random(name + "!"), house, QUARTER_FURNISHERS[kind])
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
    for x in (cx - 4.0, cx + 4.0):
        for z in (cz - 2.0, cz + 2.0):
            scene.add("fantasy_town_kit/pillar-wood", (x, 0.0, z), 0.0, 4.0)
            scene.add_box((x, 2.0, z), (0.5, 4.0, 0.5))
    roof(scene, cx, cz, 2, 1, WALL_HEIGHT)
    # Corde à linge entre deux perches, au bord de l'eau ; draps et bannières à sécher.
    for z in (cz - 2.6, cz + 2.6):
        scene.add("fantasy_town_kit/pillar-wood", (cx + 5.6, 0.0, z), 0.0, (1.0, 2.4, 1.0))
        scene.add_box((cx + 5.6, 1.2, z), (0.3, 2.4, 0.3))
    for index, z in enumerate((cz - 1.4, cz + 0.2, cz + 1.6)):
        scene.add("fantasy_town_kit/banner-green" if index % 2 else "fantasy_town_kit/banner-red", (cx + 5.6 - 1.5, 1.0, z), 0.0, (1.2, 1.4, 1.2))
    for index, (x, z) in enumerate(((cx - 2.6, cz - 3.0), (cx + 2.6, cz - 3.0))):
        furniture(scene, "survival_kit/barrel-open", (x, 0.0, z), 0.0, 3.0, height=1.0)
    furniture(scene, "survival_kit/bucket", (cx - 1.0, 0.0, cz - 3.0), 0.0, 3.4)
    scene.group = "Fixed"


def build_market_hall(scene, rng):
    """Halle du marché, au sud du village : un grand toit sur des piliers de bois, des étals à l'abri. Le toit,
    effondré pendant la guerre, est relevé au deuxième livre."""
    cx, cz, width, depth = -24.0, 66.0, 3, 2
    half_w, half_d = width * TILE / 2, depth * TILE / 2
    pillars = [(cx + sx * half_w, cz + sz * half_d) for sx in (-1, 1) for sz in (-1, 0, 1)]
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
            for offset in (-0.8, 0.0, 0.8):
                furniture(scene, food, (x + offset, 0.69, z), rng.uniform(0, 360), 1.6 if "cheese" not in food else 1.0)
    for x, z in ((cx - 6.6, cz - 3.2), (cx - 6.6, cz + 3.2), (cx + 6.6, cz - 3.2)):
        furniture(scene, "mini_dungeon/barrel", (x + 1.0 if x < cx else x - 1.0, 0.0, z), 0.0, 2.4, height=1.1)
    furniture(scene, "survival_kit/box-large", (cx + 5.6, 0.0, cz + 3.2), 90.0, 3.0, height=0.8)
    scene.group = "Fixed"


def build_observatory(scene, rng):
    """L'observatoire du Mont Sam Altan, au sud-ouest : la tour d'où les veilleurs du roi guettaient le volcan
    endormi depuis des siècles. Décapitée par la guerre, elle retrouve son toit au quatrième livre."""
    x, z, scale = -70.0, 58.0, 4.6
    scene.repair("Observatory", 4)
    y = 0.0
    for model in ("tower-square-mid-door", "tower-square-mid-windows", "tower-square-mid-windows"):
        scene.add(f"castle_kit/{model}", (x, y, z), 45.0, scale)
        y += 1.01 * scale
    scene.add_box((x, y / 2, z), (scale, y, scale), 45.0)
    rubble(scene, rng, x + 3.6, z + 3.6, True, count=2, spread=2.0)
    scene.rebuilt("Observatory")
    y = 0.0
    for model in ("tower-square-mid-door", "tower-square-mid-windows", "tower-square-mid-windows", "tower-square-mid-windows"):
        scene.add(f"castle_kit/{model}", (x, y, z), 45.0, scale)
        y += 1.01 * scale
    scene.add("castle_kit/tower-square-top-roof-high-windows", (x, y, z), 45.0, scale)
    scene.add_box((x, (y + 1.07 * scale) / 2, z), (scale, y + 1.07 * scale, scale), 45.0)
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
        furniture(scene, model, (x, 0.0, z), rng.uniform(0, 360), 2.4, height=3.0)
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
        furniture(scene, "nature_kit/tree_oak" if index % 2 else "nature_kit/tree_default", (x1 - 2.2, 0.0, z), rng.uniform(0, 360), 3.2, height=4.0)
    furniture(scene, "nature_kit/tree_default", (35.0, 0.0, -75.6), rng.uniform(0, 360), 3.0, height=4.0)
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
            furniture(scene, "fantasy_town_kit/hedge", (x + side * 1.9, 0.0, z), 0.0, (1.0, 1.6, 3.6))
            furniture(scene, "fantasy_town_kit/hedge", (x, 0.0, z + side * 1.9), 90.0, (1.0, 1.6, 3.6))
        for index in range(9):
            model = ("nature_kit/flower_redA", "nature_kit/flower_yellowA", "nature_kit/flower_purpleA")[(index + int(x)) % 3]
            scene.add(model, (x - 1.1 + (index % 3) * 1.1, 0.0, z - 1.1 + (index // 3) * 1.1), rng.uniform(0, 360), 2.6)
    scene.group = "Fixed"

    # Bancs le long des allées : brisés jusqu'au premier livre.
    benches = [(39.8, -60.0, 90.0), (44.2, -60.0, -90.0), (39.8, -82.0, 90.0), (44.4, -79.4, -90.0), (33.2, -67.6, 90.0), (50.4, -72.6, 180.0)]
    scene.repair("ParkBenches", 1)
    for x, z, degrees in benches:
        furniture(scene, "graveyard_kit/bench-damaged", (x, 0.0, z), degrees + rng.uniform(-15, 15), 2.2, height=0.9, roll=90.0 if x > 44 else 0.0)
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
        furniture(scene, "nature_kit/statue_block", (x, 0.0, z), 0.0, 2.4, height=0.95)
        furniture(scene, "mini_arena/statue", (x, 0.94, z), 90.0 if x < cx else -90.0, 1.6)
    scene.group = "Fixed"

    # Statue de Devlyn, vainqueur des Quatre Dragons du Chaos, au milieu du rond-point : un socle à degrés, le héros,
    # et les quatre trophées des dragons à ses pieds. Brisée, elle n'est relevée qu'avec le quatrième livre.
    scene.repair("ParkStatue", 4)
    furniture(scene, "nature_kit/statue_block", (cx, 0.0, cz), 0.0, 6.0, height=2.3)
    furniture(scene, "nature_kit/statue_columnDamaged", (cx + 0.4, 2.34, cz - 0.3), 20.0, 3.0)
    furniture(scene, "mini_arena/statue", (cx + 2.4, 0.0, cz + 1.6), 40.0, 2.0, height=1.4, tilt=90.0)
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
    for index in range(6):
        angle = math.radians(30 + index * 60)
        px, pz = kx + math.cos(angle) * 2.3, kz + math.sin(angle) * 2.0
        if index == 1:
            continue
        furniture(scene, "nature_kit/statue_column", (px, 0.26, pz), 0.0, (2.2, 3.4, 2.2), height=3.4)
    scene.add("castle_kit/tower-hexagon-roof", (kx, 3.66, kz), 0.0, (5.6, 2.6, 5.6))
    scene.group = "Fixed"

    # Étang : une barque échouée sur la rive.
    furniture(scene, "nature_kit/canoe", (43.0, 0.0, -89.0), 80.0, 2.4)


def build_quarter_paths(scene):
    """Lanternes au bout des ruelles des nouveaux lieux."""
    for x, z in ((-41.0, -51.5), (-56.0, 28.0), (49.0, 32.0), (-57.0, -7.0), (-20.0, 58.0), (8.0, 68.0), (74.8, -16.0)):
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
    for dx, dz in ((-4.5, 2.6), (3.0, -2.7), (5.5, 2.4)):
        scene.add("castle_kit/rocks-small", (x + dx, -1.3, z + dz * 1.4), rng.uniform(0, 360), 1.6)
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
