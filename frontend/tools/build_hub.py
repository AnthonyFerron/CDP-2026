"""Génère les objets fixes du hub : le camp des survivants, le village de Codia, le château et le bunker.

Le village se reconstruit au fil des livres posés au château : chaque élément réparable est écrit
deux fois, en ruine et reconstruit, sous un nœud qui porte le nombre de livres qui le répare.

La scène produite s'ouvre et se modifie dans Godot, mais le script l'écrase :
pour un changement durable, modifier ce script puis le relancer depuis le dossier frontend :

    python tools/build_hub.py
"""

import math
import random
from pathlib import Path

from build_plaine import WALL_HEIGHT, WALL_SCALE, OUTWARD_ANGLES, Scene, doorway, wall

OUTPUT = Path(__file__).resolve().parent.parent / "scenes" / "levels" / "hub" / "hub_props.tscn"
TILE = WALL_SCALE
CASTLE_SCALE = 5.0
# Enceinte du château, au nord : de x = -25 à 25, de z = -94 (fond) à -54 (porte).
CASTLE_X = 25.0
CASTLE_BACK = -94.0
CASTLE_FRONT = -54.0
# Salle des livres, au fond de la cour : 5 cases sur 3, porte au sud.
HALL = (0.0, -84.0, 5, 3)
BUNKER = (78.0, 0.0)
# Maisons du village : (rayon, angle en degrés) depuis le feu de camp, entre les chemins.
HOUSE_SPOTS = [(24.0, a) for a in (-112.5, -67.5, -22.5, 22.5, 70.0, 110.0, 160.0, 200.0)] + [
    (38.0, a) for a in (-112.5, -67.5, -22.5, 22.5, 72.0, 108.0, 162.0, 198.0)
]
OUTWARDS = {"north": (0, -1), "south": (0, 1), "east": (1, 0), "west": (-1, 0)}


class StagedScene(Scene):
    """Scène dont les modèles et les collisions sont rangés par groupe, chacun sous son propre nœud."""

    def __init__(self, root_name):
        super().__init__(root_name)
        self.group = "Fixed"
        self.metadata = {}

    def add(self, model, position, degrees=0.0, scale=1.0, tilt=0.0):
        super().add(model, position, degrees, scale, tilt)
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
    for beam in range(rng.randint(1, 2)):
        x = cx + rng.uniform(-half_w + 1, half_w - 1)
        scene.add("fantasy_town_kit/poles-horizontal", (x, WALL_HEIGHT - 1.8, cz), 0.0, WALL_SCALE, tilt=rng.uniform(-25.0, 25.0))
    scene.add("survival_kit/resource-planks", (cx + rng.uniform(-1, 1), 0.0, cz + rng.uniform(-1, 1)), rng.uniform(0, 360), 3.0)


def rebuilt_house(scene, rng, house):
    cx, cz, width, depth, door_side, style, floors = house
    plain, _, window, window_small = wall_models(style)
    for side, index, count, center, outward in edge_tiles(cx, cz, width, depth):
        if side == door_side and index == count // 2:
            doorway(scene, center, outward)
            scene.add("fantasy_town_kit/lantern", (center[0] + outward[0] * 0.6 + outward[1] * 1.6, 0.0,
                                                   center[1] + outward[1] * 0.6 + outward[0] * 1.6), 0.0, 2.2)
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
    # Étals du marché, qui reviennent avec le deuxième livre ; charrette renversée tant qu'il manque.
    scene.repair("Market", 2)
    scene.add("fantasy_town_kit/cart", (-13.0, 0.6, -4.0), 60.0, 3.0, tilt=80.0)
    scene.add_box((-13.0, 0.8, -4.0), (2.0, 1.6, 4.0), 60.0)
    scene.add("fantasy_town_kit/wheel", (-14.5, 0.0, 2.0), 30.0, 3.0, tilt=90.0)
    scene.rebuilt("Market")
    for x, z, degrees, model in ((-15.0, -4.0, 90.0, "stall-red"), (-15.0, 4.0, 90.0, "stall-green"), (15.0, -10.0, -90.0, "stall")):
        scene.add(f"fantasy_town_kit/{model}", (x, 0.0, z), degrees, 3.0)
        scene.add_box((x, 1.5, z), (3.0, 3.0, 3.0), degrees)
    for model, x, z in (("apple", -14.2, -4.4), ("carrot", -14.4, 4.2), ("bread", 14.6, -10.2)):
        scene.add(f"food_kit/{model}", (x, 1.1, z), rng.uniform(0, 360), 2.5)
    # Fontaine de la place est, sèche puis remise en eau au troisième livre.
    scene.repair("Fountain", 3)
    scene.add("fantasy_town_kit/fountain-round", (17.0, 0.0, 6.0), 0.0, 3.0)
    scene.add("castle_kit/rocks-small", (17.0, 0.4, 6.0), 40.0, 1.8)
    scene.add_box((17.0, 0.5, 6.0), (5.6, 1.0, 5.6))
    scene.rebuilt("Fountain")
    scene.add("fantasy_town_kit/fountain-round-detail", (17.0, 0.0, 6.0), 0.0, 3.0)
    scene.add_box((17.0, 0.5, 6.0), (5.6, 1.0, 5.6))
    scene.group = "Fixed"


def build_camp(scene):
    """Camp des survivants autour du feu : tentes, bancs de rondins, provisions et établi."""
    scene.add("survival_kit/campfire-pit", (0.0, 0.0, 0.0), 0.0, 6.0)
    for index in range(5):
        angle = math.radians(90 + index * 72)
        x, z = math.cos(angle) * 3.0, math.sin(angle) * 3.0
        scene.add("nature_kit/log", (x, 0.0, z), -math.degrees(angle), 4.0)
        scene.add_box((x, 0.35, z), (0.9, 0.7, 2.4), -math.degrees(angle))
    for x, z, degrees in ((10.5, 1.0, -100.0), (-10.5, 1.0, 100.0), (7.5, 9.0, -150.0), (-7.5, 9.0, 150.0)):
        scene.add("mini_forest/tent", (x, 0.0, z), degrees, 3.2)
        scene.add_box((x, 1.6, z), (3.6, 3.2, 3.2), degrees)
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


def castle_wall(scene, x, z, along_x):
    scene.add("castle_kit/wall", (x, 0.0, z), 0.0 if along_x else 90.0, CASTLE_SCALE)
    size = (CASTLE_SCALE, 6.6, 2.4) if along_x else (2.4, 6.6, CASTLE_SCALE)
    scene.add_box((x, 3.3, z), size)


def castle_tower(scene, x, z, floors=3):
    y = 0.0
    for model, height in [("tower-square-base", 1.0)] + [("tower-square-mid-windows", 1.0)] * (floors - 2) + [("tower-square-top", 0.3)]:
        scene.add(f"castle_kit/{model}", (x, y, z), 0.0, CASTLE_SCALE)
        y += height * CASTLE_SCALE
    scene.add("castle_kit/tower-square-roof", (x, y, z), 0.0, CASTLE_SCALE)
    scene.add_box((x, y / 2, z), (CASTLE_SCALE, y, CASTLE_SCALE))
    return y


def build_castle(scene, rng):
    """Château du roi : une enceinte à tours d'angle, une cour, et la salle des livres au fond."""
    half = CASTLE_SCALE / 2
    steps = int(CASTLE_X * 2 / CASTLE_SCALE)
    for index in range(steps):
        x = -CASTLE_X + half + index * CASTLE_SCALE
        castle_wall(scene, x, CASTLE_BACK, True)
        if abs(x) > 8.0:
            castle_wall(scene, x, CASTLE_FRONT, True)
    for index in range(int((CASTLE_FRONT - CASTLE_BACK) / CASTLE_SCALE)):
        z = CASTLE_BACK + half + index * CASTLE_SCALE
        for x in (-CASTLE_X, CASTLE_X):
            castle_wall(scene, x, z, False)
    tops = []
    for x in (-CASTLE_X, CASTLE_X):
        for z in (CASTLE_BACK, CASTLE_FRONT):
            tops.append((x, castle_tower(scene, x, z, 4), z))
    # Tours de la porte, qui encadrent un passage libre.
    for x in (-7.5, 7.5):
        tops.append((x, castle_tower(scene, x, CASTLE_FRONT, 3), CASTLE_FRONT))
        scene.add("castle_kit/flag-banner-long", (x, 6.0, CASTLE_FRONT + CASTLE_SCALE / 2 + 0.1), 0.0, 4.0)

    # Salle des livres : pierre, porte voûtée, colonnes, bannières et torches.
    cx, cz, width, depth = HALL
    for side, index, count, center, outward in edge_tiles(cx, cz, width, depth):
        if side == "south" and index == count // 2:
            doorway(scene, center, outward)
        else:
            wall(scene, "wall-window-stone" if side != "north" and index % 2 else "wall", center, outward)
        wall(scene, "wall", center, outward, base=WALL_HEIGHT, solid=False)
    half_w, half_d = width * TILE / 2, depth * TILE / 2
    for sx in (-1, 1):
        for sz in (-1, 1):
            for floor in range(2):
                scene.add("fantasy_town_kit/pillar-stone", (cx + sx * half_w, floor * WALL_HEIGHT, cz + sz * half_d), 0.0, WALL_SCALE)
    for x in (-7.0, 7.0):
        scene.add("fantasy_town_kit/banner-red", (x, 3.2, cz - half_d + 0.5), 90.0, 3.4)
    for x in (-2.0, 2.0):
        scene.add("fantasy_town_kit/banner-green", (x, 6.0, cz + half_d + 0.3), -90.0, 3.4)

    # Cour : ruines de la guerre, rangées au deuxième livre ; drapeaux hissés au troisième.
    scene.repair("CastleCourt", 2)
    scene.add("castle_kit/siege-catapult-demolished", (-15.0, 0.0, -64.0), 30.0, 4.0)
    scene.add_box((-15.0, 1.5, -64.0), (6.0, 3.0, 6.0), 30.0)
    scene.add("castle_kit/siege-tower-demolished", (16.0, 0.0, -68.0), -20.0, 4.0)
    scene.add_box((16.0, 2.0, -68.0), (8.0, 4.0, 7.0), -20.0)
    for x, z in ((-6.0, -70.0), (9.0, -60.0), (-19.0, -78.0)):
        scene.add("castle_kit/rocks-large", (x, 0.0, z), rng.uniform(0, 360), 2.4)
    scene.rebuilt("CastleCourt")
    scene.add("castle_kit/siege-catapult", (-17.0, 0.0, -62.0), 30.0, 4.0)
    scene.add_box((-17.0, 1.5, -62.0), (5.0, 3.0, 5.0), 30.0)
    for x, z in ((-12.0, -76.0), (12.0, -76.0)):
        scene.add("nature_kit/plant_bushLarge", (x, 0.0, z), rng.uniform(0, 360), 3.0)
    scene.repair("CastleFlags", 3)
    scene.rebuilt("CastleFlags")
    for x, y, z in tops:
        scene.add("castle_kit/flag", (x, y + CASTLE_SCALE * 2.0, z), 0.0, 4.0)
    # Toit de la salle, reposé avec le quatrième livre.
    scene.repair("HallRoof", 4)
    scene.rebuilt("HallRoof")
    for column in range(width):
        for row in range(depth):
            x = cx - (width - 1) * TILE / 2 + column * TILE
            z = cz - (depth - 1) * TILE / 2 + row * TILE
            scene.add("fantasy_town_kit/roof-flat", (x, WALL_HEIGHT * 2, z), 0.0, TILE)
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


def main():
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
