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

from build_plaine import WALL_HEIGHT, WALL_SCALE, OUTWARD_ANGLES, Scene, doorway, furniture, wall

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
ROADS = [(-38.0, -38.0), (38.0, -38.0), (38.0, 38.0), (-38.0, 38.0), (0.0, CASTLE_FRONT), BUNKER]
OUTWARDS = {"north": (0, -1), "south": (0, 1), "east": (1, 0), "west": (-1, 0)}
DOOR_YAWS = {"south": 0.0, "north": 180.0, "east": 90.0, "west": -90.0}


class StagedScene(Scene):
    """Scène dont les modèles et les collisions sont rangés par groupe, chacun sous son propre nœud."""

    def __init__(self, root_name):
        super().__init__(root_name)
        self.group = "Fixed"
        self.metadata = {}

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
        lines.append("")
        for size, identifier in self.boxes.items():
            lines += [f'[sub_resource type="BoxShape3D" id="{identifier}"]', f"size = Vector3({size[0]:g}, {size[1]:g}, {size[2]:g})", ""]
        lines += [f'[node name="{self.root_name}" type="Node3D"]', ""]
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


def ruined_house(scene, rng, house):
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
    furnish(scene, house, True, rng)


def rebuilt_house(scene, rng, house):
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
    furnish(scene, house, False, rng)


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
            if clear_of(houses, x, z, 1.2) and not (-18.0 < x < -11.0 and -7.0 < z < 7.0) and math.hypot(x - 30.0, z - 4.2) > 3.8:
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
    furniture(scene, "fantasy_town_kit/wheel", (-14.5, 0.0, 2.0), 30.0, 3.0, tilt=90.0)
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


def curtain_wall(scene, x, z, along_x):
    scene.add("castle_kit/wall", (x, 0.0, z), 0.0 if along_x else 90.0, CURTAIN_SCALE)
    size = (CURTAIN_SCALE, 6.6, CURTAIN_SCALE) if along_x else (CURTAIN_SCALE, 6.6, CURTAIN_SCALE)
    scene.add_box((x, 3.3, z), size)


def square_tower(scene, x, z, scale, floors, roofed=True):
    """Tour carrée : base, étages à fenêtres, couronnement, et son toit si elle en a un. Renvoie sa hauteur."""
    y = 0.0
    for model in ["tower-square-base"] + ["tower-square-mid-windows"] * (floors - 2) + ["tower-square-mid"]:
        scene.add(f"castle_kit/{model}", (x, y, z), 0.0, scale)
        y += scale
    scene.add("castle_kit/tower-square-top", (x, y, z), 0.0, scale)
    scene.add_box((x, (y + 0.3 * scale) / 2, z), (scale, y + 0.3 * scale, scale))
    if roofed:
        scene.add("castle_kit/tower-square-roof", (x, y + 0.3 * scale, z), 0.0, scale)
    return y + 0.3 * scale


def round_tower(scene, x, z, scale):
    """Grosse tour d'angle de l'enceinte, hexagonale, coiffée d'un toit pointu. Renvoie sa hauteur."""
    y = 0.0
    for model, height in (("tower-hexagon-base", 1.31), ("tower-hexagon-mid", 0.46), ("tower-hexagon-mid", 0.46), ("tower-hexagon-top", 0.13)):
        scene.add(f"castle_kit/{model}", (x, y, z), 0.0, scale)
        y += height * scale
    scene.add("castle_kit/tower-hexagon-roof", (x, y, z), 0.0, scale)
    scene.add_box((x, y / 2, z), (0.8 * scale, y, 0.7 * scale))
    return y


def build_castle(scene, rng):
    """Château du roi : enceinte à tours d'angle, porterie voûtée, cour, et donjon qui abrite la salle des livres."""
    half = CURTAIN_SCALE / 2
    steps = int(CASTLE_X * 2 / CURTAIN_SCALE)
    for index in range(steps):
        x = -CASTLE_X + half + index * CURTAIN_SCALE
        curtain_wall(scene, x, CASTLE_BACK + half, True)
        if abs(x) > 8.0:
            curtain_wall(scene, x, CASTLE_FRONT - half, True)
    for index in range(1, int((CASTLE_FRONT - CASTLE_BACK) / CURTAIN_SCALE) - 1):
        z = CASTLE_BACK + half + index * CURTAIN_SCALE
        for x in (-CASTLE_X + half, CASTLE_X - half):
            curtain_wall(scene, x, z, False)
    corners = [(x, z) for x in (-CASTLE_X + half, CASTLE_X - half) for z in (CASTLE_BACK + half, CASTLE_FRONT - half)]
    # Pointe de chaque toit, où planter un drapeau : 0,83 tuile pour le toit hexagonal, 2 pour le toit carré.
    tops = [(x, round_tower(scene, x, z, 7.0) + 0.83 * 7.0 - 0.2, z) for x, z in corners]

    # Porterie : deux tours carrées et une arche voûtée entre elles, la herse relevée.
    gate_z = CASTLE_FRONT - half
    for x in (-7.5, 7.5):
        tops.append((x, square_tower(scene, x, gate_z, CURTAIN_SCALE, 4) + 2.01 * CURTAIN_SCALE - 0.3, gate_z))
    scene.add("castle_kit/tower-square-arch", (0.0, 0.0, gate_z), 0.0, 10.5)
    scene.add("castle_kit/wall", (0.0, 10.4, gate_z), 0.0, CURTAIN_SCALE)
    for sign in (-1, 1):
        scene.add_box((sign * 3.75, 5.3, gate_z), (2.5, 10.6, 9.8))
    scene.add_box((0.0, 11.0, gate_z), (5.0, 7.2, 9.8))
    scene.add("castle_kit/metal-gate", (0.0, 5.2, gate_z + 2.6), 90.0, 5.0)
    for x in (-4.4, 4.4):
        scene.add("castle_kit/flag-banner-long", (x, 4.0, gate_z + 4.95), 90.0, 3.0)

    # Donjon : deux rangées de murs épais, quatre tours carrées et un portail voûté au sud.
    keep_half = KEEP_SCALE / 2
    for layer in range(2):
        y = layer * KEEP_LAYER
        for x in range(int(-KEEP_X), int(KEEP_X) + 1, int(KEEP_SCALE)):
            for z in (KEEP_BACK, KEEP_FRONT):
                if z == KEEP_FRONT and x == 0 and layer == 0:
                    continue
                scene.add("castle_kit/wall", (x, y, z), 0.0, KEEP_SCALE)
        for z in range(int(KEEP_BACK + KEEP_SCALE), int(KEEP_FRONT), int(KEEP_SCALE)):
            for x in (-KEEP_X, KEEP_X):
                scene.add("castle_kit/wall", (x, y, z), 90.0, KEEP_SCALE)
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

    # Salle des livres : colonnes, bannières et boucliers contre les murs, tapis jusqu'au trône.
    for x in (-7.0, -2.4, 2.4, 7.0):
        for z in (-85.6, -76.4):
            for floor in range(2):
                scene.add("fantasy_town_kit/pillar-stone", (x, floor * WALL_HEIGHT, z), 0.0, WALL_SCALE)
    # Le drap de la bannière est décalé de 0,4 tuile de son origine, comme les murs du kit.
    for z in (-84.0, -78.0):
        for x, degrees in ((-8.55, 180.0), (8.55, 0.0)):
            scene.add("fantasy_town_kit/banner-red", (x, 2.6, z), degrees, 3.4)
    for x, degrees in ((-9.75, 90.0), (9.75, -90.0)):
        for z in (-86.0, -81.0, -76.0):
            furniture(scene, "mini_dungeon/shield-round", (x, 4.6, z), degrees, 3.0)
    for z in (-77.5, -83.0):
        furniture(scene, "furniture_kit/rugRectangle", (0.0, 0.03, z), 90.0, 3.6)

    # Cour : puits, écurie, chariot, provisions, râteliers d'armes, arbres et braseros.
    furniture(scene, "castle_kit/tree-large", (-20.0, 0.0, -88.0), 20.0, 5.0, height=6.0)
    furniture(scene, "castle_kit/tree-small", (20.5, 0.0, -88.5), 70.0, 5.0, height=5.0)
    scene.add("fantasy_town_kit/fountain-square", (-15.0, 0.0, -60.0), 0.0, 1.6)
    scene.add_box((-15.0, 0.4, -60.0), (3.2, 0.8, 3.2))
    for z in (-62.0, -66.0):
        scene.add("fantasy_town_kit/fence", (14.0, 0.0, z), 0.0, 4.0)
        scene.add_box((15.7, 0.8, z), (0.3, 1.6, 4.0))
    scene.add("fantasy_town_kit/fence", (18.0, 0.0, -68.0), 90.0, 4.0)
    scene.add_box((18.0, 0.8, -66.3), (4.0, 1.6, 0.3))
    for model, x, z, degrees, height in (
        ("graveyard_kit/hay-bale", 19.0, -62.5, 10.0, 1.0), ("graveyard_kit/hay-bale-bundled", 20.5, -65.0, -20.0, 1.1),
        ("fantasy_town_kit/cart-high", 10.5, -57.0, 20.0, 2.4), ("mini_dungeon/barrel", -9.0, -56.5, 0.0, 1.2),
        ("mini_dungeon/barrel", -10.2, -57.6, 0.0, 1.2), ("mini_dungeon/chest", -11.5, -56.4, 15.0, 0.8),
        ("survival_kit/box-large", -20.5, -72.0, 90.0, 0.9),
    ):
        furniture(scene, model, (x, 0.0, z), degrees, 2.4 if "cart" in model else 2.6, height=height)
    # Râtelier de lances contre l'enceinte ouest.
    for z in (-57.5, -59.0, -60.5):
        furniture(scene, "mini_dungeon/weapon-spear", (-21.8, 0.0, z), 90.0, 3.4, height=2.0)
    for x, z in ((-4.5, -69.5), (4.5, -69.5), (-4.0, -55.5), (4.0, -55.5)):
        furniture(scene, "graveyard_kit/fire-basket", (x, 0.0, z), 0.0, 3.0, height=0.6)

    # Cour : ruines de la guerre, rangées au deuxième livre.
    scene.repair("CastleCourt", 2)
    scene.add("castle_kit/siege-catapult-demolished", (-12.0, 0.0, -64.0), 30.0, 4.0)
    scene.add_box((-12.0, 1.5, -64.0), (6.0, 3.0, 6.0), 30.0)
    scene.add("castle_kit/siege-tower-demolished", (16.0, 0.0, -76.0), -20.0, 4.0)
    scene.add_box((16.0, 2.0, -76.0), (8.0, 4.0, 7.0), -20.0)
    for x, z in ((-6.0, -63.0), (8.0, -60.0), (-19.0, -78.0)):
        scene.add("castle_kit/rocks-large", (x, 0.0, z), rng.uniform(0, 360), 2.4)
        scene.add_box((x, 0.6, z), (2.6, 1.2, 2.6))
    scene.rebuilt("CastleCourt")
    furniture(scene, "castle_kit/siege-catapult", (-13.0, 0.0, -64.0), 30.0, 3.4, height=3.0)
    furniture(scene, "castle_kit/siege-ballista", (16.0, 0.0, -77.0), -30.0, 3.4, height=2.4)
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


def main():
    build_shelter()
    rng = random.Random(5814)
    scene = StagedScene("HubProps")
    build_camp(scene)
    build_village(scene, rng)
    build_castle(scene, rng)
    build_bunker(scene, rng)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(scene.text(), encoding="utf-8", newline="\n")
    print(f"{OUTPUT.name} : {len(scene.visuals)} modèles, {len(scene.colliders)} collisions")


if __name__ == "__main__":
    main()
