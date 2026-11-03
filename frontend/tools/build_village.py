"""Génère les objets fixes du Village détruit : l'enceinte, les maisons, la place, l'hôtel de ville et les moulins.

La scène produite s'ouvre et se modifie dans Godot, mais le script l'écrase :
pour un changement durable, modifier ce script puis le relancer depuis le dossier frontend :

    python tools/build_village.py
"""

import random
from pathlib import Path

from build_plaine import WALL_HEIGHT, WALL_SCALE, WALL_THICKNESS, Scene, doorway, wall

OUTPUT = Path(__file__).resolve().parent.parent / "scenes" / "levels" / "village" / "village_props.tscn"
TILE = WALL_SCALE
RAMPART = 4.0

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
    (12.0, -18.0, 2, 2, "south", "stone", 2),
    (-31.0, -14.0, 2, 2, "east", "wood", 1),
)
OUTWARDS = {"north": (0, -1), "south": (0, 1), "east": (1, 0), "west": (-1, 0)}
# Lit, table et chaises posés dans certaines maisons, à leur centre.
FURNISHED = {0, 3, 4, 6, 9}


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


def build_house(scene, rng, number, house):
    cx, cz, width, depth, door_side, style, floors = house
    plain, broken, window, window_small = wall_models(style)
    for side, index, count, center, outward in edge_tiles(cx, cz, width, depth):
        if side == door_side and index == count // 2:
            doorway(scene, center, outward)
            continue
        roll = rng.random()
        if roll < 0.14:
            scene.add("castle_kit/rocks-small", (center[0], 0.0, center[1]), rng.uniform(0, 360), 1.6)
            continue
        if roll < 0.4:
            wall(scene, broken, center, outward, height=3.0)
        else:
            wall(scene, rng.choice((plain, plain, window, window_small)), center, outward)
        if floors > 1 and roll > 0.55:
            wall(scene, rng.choice(("wall-wood", "wall-wood-broken", "wall-wood-window-shutters")),
                 center, outward, base=WALL_HEIGHT, solid=False)
    half_w, half_d = width * TILE / 2, depth * TILE / 2
    pillar = "fantasy_town_kit/pillar-wood" if style == "wood" else "fantasy_town_kit/pillar-stone"
    for sx in (-1, 1):
        for sz in (-1, 1):
            for floor in range(floors):
                scene.add(pillar, (cx + sx * half_w, floor * WALL_HEIGHT, cz + sz * half_d), 0.0, WALL_SCALE)
    # Poutres calcinées en travers des maisons sans toit.
    for beam in range(rng.randint(1, 3)):
        x = cx + rng.uniform(-half_w + 1, half_w - 1)
        tilt = rng.uniform(-25.0, 25.0)
        scene.add("fantasy_town_kit/poles-horizontal", (x, WALL_HEIGHT * floors - 1.5, cz), 0.0, WALL_SCALE, tilt=tilt)
    if number in FURNISHED:
        scene.add("furniture_kit/bedSingle", (cx - half_w + 1.0, 0.0, cz + half_d - 1.0), 180.0, 2.4)
        scene.add_box((cx - half_w + 2.9, 0.6, cz + half_d - 3.3), (3.9, 1.2, 4.5))
        scene.add("furniture_kit/tableCloth", (cx + 0.4, 0.0, cz - 0.8), 15.0, 3.0)
        scene.add_box((cx + 1.6, 0.5, cz - 1.4), (2.6, 1.0, 1.5), 15.0)
        for x, z, degrees in ((cx + 0.6, cz + 0.8, 0.0), (cx + 2.6, cz - 2.4, 120.0)):
            scene.add("furniture_kit/chair", (x, 0.0, z), degrees, 3.0, tilt=rng.choice((0.0, 0.0, 85.0)))


def build_rampart(scene, rng):
    """Enceinte : un rempart au sud percé de la porte, et des pans sur les côtés, souvent effondrés."""
    south = 42.0
    for x in range(-30, 31, 4):
        if abs(x) <= 4:
            continue
        if abs(x) in (18, 26) or rng.random() < 0.15:
            scene.add("castle_kit/rocks-large", (x, 0.0, south), rng.uniform(0, 360), 2.6)
            scene.add_box((x, 0.6, south), (3.2, 1.2, 3.2))
            continue
        model = "wall-narrow" if rng.random() < 0.7 else "wall-half"
        scene.add(f"castle_kit/{model}", (x, 0.0, south), 90.0, RAMPART)
        scene.add_box((x, 2.6, south), (RAMPART, 5.2, 2.0))
    for sign in (-1, 1):
        for z in range(38, -27, -4):
            if rng.random() < 0.35:
                continue
            scene.add("castle_kit/wall-narrow", (sign * 34.0, 0.0, z), 0.0, RAMPART)
            scene.add_box((sign * 34.0, 2.6, z), (2.0, 5.2, RAMPART))
        # Tours de la porte, avec la porte arrachée couchée devant.
        x = sign * 6.0
        for model, y in (("tower-square-base", 0.0), ("tower-square-mid", 4.0), ("tower-square-top", 8.0)):
            scene.add(f"castle_kit/{model}", (x, y, south), 0.0, RAMPART)
        scene.add_box((x, 4.6, south), (4.0, 9.2, 4.0))
    scene.add("castle_kit/gate", (2.5, 0.25, south + 5.0), 70.0, 5.0, tilt=88.0)
    scene.add("castle_kit/siege-tower-demolished", (-16.0, 0.0, 52.0), 30.0, 4.0)
    scene.add_box((-16.0, 2.0, 52.0), (8.0, 4.0, 7.0), 30.0)
    scene.add("castle_kit/siege-ram-demolished", (14.0, 0.0, 50.0), -20.0, 4.0)
    scene.add_box((14.0, 1.0, 50.0), (4.0, 2.0, 7.0), -20.0)


def build_streets(scene, rng):
    """Place du marché autour de la fontaine : les pavés des rues sont peints par le terrain."""
    scene.add("fantasy_town_kit/fountain-round", (0.0, 0.0, -2.0), 0.0, 3.6)
    scene.add_box((0.0, 0.5, -2.0), (6.6, 1.0, 6.6))
    for x, z, degrees, model in ((-7.0, -9.0, 20.0, "stall-red"), (7.5, -9.5, -15.0, "stall-green"), (8.5, 4.0, 200.0, "stall")):
        scene.add(f"fantasy_town_kit/{model}", (x, 0.0, z), degrees, 3.0)
        scene.add_box((x, 1.5, z), (3.0, 3.0, 3.0), degrees)
    scene.add("fantasy_town_kit/cart", (-7.5, 0.6, 4.5), 60.0, 3.0, tilt=80.0)
    scene.add_box((-7.5, 0.8, 4.5), (2.0, 1.6, 4.0), 60.0)
    scene.add("fantasy_town_kit/wheel", (-5.0, 0.0, 6.5), 30.0, 3.0, tilt=90.0)
    for model, x, z in (("apple", -6.0, -7.0), ("apple", -5.4, -6.4), ("carrot", 6.0, -7.4), ("bread", 7.2, 6.0),
                        ("cheese", -4.2, 5.6), ("apple", 5.0, 2.8), ("carrot", -8.0, -10.5)):
        scene.add(f"food_kit/{model}", (x, 0.0, z), rng.uniform(0, 360), 2.5, tilt=rng.choice((0.0, 90.0)))
    for x, z in ((-2.4, 30.0), (2.4, 20.0), (-2.4, 10.0), (2.4, -14.0)):
        scene.add("fantasy_town_kit/lantern", (x, 0.0, z), 0.0, 2.2)


def build_town_hall(scene):
    """Hôtel de ville au nord de la place : la façade à l'étage tient encore, le reste s'est effondré."""
    cx, cz, width, depth = 0.0, -26.0, 3, 3
    for side, index, count, center, outward in edge_tiles(cx, cz, width, depth):
        if side == "south" and index == 1:
            doorway(scene, center, outward)
        elif side == "north" and index == 2:
            wall(scene, "wall-broken", center, outward, height=3.0)
        else:
            wall(scene, "wall-window-stone" if index != 1 else "wall", center, outward)
        if side == "south" or (side in ("east", "west") and index > 0):
            wall(scene, "wall-window-stone" if side == "south" else "wall-broken",
                 center, outward, base=WALL_HEIGHT, solid=False)
    for x in (-6.0, 6.0):
        for z in (cz - 6.0, cz + 6.0):
            for floor in range(2):
                scene.add("fantasy_town_kit/pillar-stone", (x, floor * WALL_HEIGHT, z), 0.0, WALL_SCALE)
    for x in (-2.6, 2.6):
        scene.add("fantasy_town_kit/banner-red", (x, 4.8, cz + 6.2), -90.0, 3.4)
    for x, degrees in ((-4.4, 90.0), (4.4, -90.0)):
        scene.add("furniture_kit/bookcaseClosedWide", (x, 0.0, cz - 2.0), degrees, 3.2)
        scene.add_box((x - (0.4 if x > 0 else -0.4), 1.25, cz - 0.7), (0.8, 2.5, 2.6))
    scene.add("furniture_kit/tableCloth", (-1.3, 0.0, cz - 1.0), 0.0, 3.0)
    scene.add_box((0.0, 0.5, cz - 1.7), (2.6, 1.0, 1.4))


def build_mills(scene):
    """Moulin à eau au bord du ruisseau, avec son pont, et tour du moulin à vent sur sa colline."""
    scene.add("nature_kit/bridge_wood", (-38.0, -0.3, 6.0), 90.0, 6.5)
    scene.add_box((-38.0, 0.1, 6.0), (9.0, 0.4, 4.6))
    # La roue du moulin à eau tourne : elle est posée dans village.tscn, contre la maison du meunier.
    for model, y in (("tower-square-base", 0.0), ("tower-square-mid-windows", 3.0), ("tower-square-mid", 6.0), ("tower-square-top", 9.0)):
        scene.add(f"castle_kit/{model}", (30.0, 4.0 + y, -30.0), 0.0, 3.0)
    scene.add("castle_kit/tower-square-roof", (30.0, 4.0 + 9.9, -30.0), 0.0, 3.0)
    scene.add_box((30.0, 4.0 + 5.0, -30.0), (3.0, 10.0, 3.0))


def main():
    rng = random.Random(5815)
    scene = Scene("VillageProps")
    build_rampart(scene, rng)
    build_streets(scene, rng)
    for number, house in enumerate(HOUSES):
        build_house(scene, rng, number, house)
    build_town_hall(scene)
    build_mills(scene)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(scene.text(), encoding="utf-8", newline="\n")
    print(f"{OUTPUT.name} : {len(scene.visuals)} modèles, {len(scene.colliders)} collisions")


if __name__ == "__main__":
    main()
