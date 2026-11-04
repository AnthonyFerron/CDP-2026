

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
    furniture(scene, "mini_forest/ladder", frame.at(-hu + 0.25, 0.8), frame.turn(90.0), 3.8, tilt=-12.0 if not ruined else 90.0)
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
    for index, u in enumerate((-hu + 1.0, -hu + 3.0, hu - 3.0, hu - 1.0)):
        furniture(scene, "furniture_kit/bedBunk", frame.at(u, -hv + 1.6), frame.turn(rng.uniform(-8, 8) if ruined else 0.0), 2.0,
                  height=2.0, tilt=90.0 if ruined and index % 2 else 0.0)
        furniture(scene, "survival_kit/chest", frame.at(u, -hv + 3.6), frame.turn(0.0), 3.0, height=0.7)
    table = frame.at(0.0, 0.6)
    furniture(scene, "mini_dungeon/table", table, frame.turn(90.0), 3.4, height=1.0, roll=90.0 if ruined else 0.0)
    for side in (-1, 1):
        furniture(scene, "furniture_kit/bench", frame.at(side * 1.6, 0.6), frame.turn(90.0 * side), 3.0,
                  tilt=90.0 if ruined and side > 0 else 0.0)
    for index, u in enumerate((-hu + 0.6, hu - 0.6)):
        furniture(scene, "mini_arena/weapon-rack", frame.at(u, 1.6), frame.turn(90.0 if u < 0 else -90.0), 3.0, height=1.4,
                  tilt=90.0 if ruined and index == 0 else 0.0)
    if not ruined:
        for u in (-1.5, 1.5):
            furniture(scene, "mini_dungeon/shield-rectangle", frame.at(u, -hv + 0.25, 2.2), frame.turn(0.0), 3.0)
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
        furniture(scene, "furniture_kit/bookcaseOpen", frame.at(u, -hv + 0.4), frame.turn(0.0), 3.0, height=2.6,
                  tilt=90.0 if ruined and index == 1 else 0.0)
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
        furniture(scene, "furniture_kit/bookcaseClosedWide", frame.at(u, -hv + 1.6), frame.turn(90.0 if u < 0 else -90.0), 3.0, height=2.4,
                  tilt=90.0 if ruined and u > 0 else 0.0)
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
    furniture(scene, "nature_kit/tree_fat", (34.0, 0.0, -87.6), rng.uniform(0, 360), 3.0, height=4.0)
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
