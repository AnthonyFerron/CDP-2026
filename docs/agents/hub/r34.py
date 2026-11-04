REPLACEMENTS = [
# Observatoire : la salle du bas devient visitable.
('''def build_observatory(scene, rng):
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
    scene.group = "Fixed"''',
'''# Observatoire du Mont Sam Altan : centre, échelle des étages de la tour, et son quart de tour.
OBSERVATORY = (-70.0, 58.0, 4.6)
TOWER_YAW = 45.0


def tower_point(x, z, a, b):
    """Point de la tour à (a, b) dans son repère : a vers la porte (face +x du modèle), b sur le côté."""
    c, s = math.cos(math.radians(TOWER_YAW)), math.sin(math.radians(TOWER_YAW))
    return x + a * c + b * s, z - a * s + b * c


def tower_walls(scene, x, z, scale, height):
    """Murs de la tour en quatre boîtes autour de la salle du bas, au lieu d'un bloc plein : la porte, sur la face
    +x du modèle (nord-est), reste ouverte sous son linteau."""
    outer, inner = 0.465 * scale, 0.349 * scale
    middle, thick = (outer + inner) / 2, outer - inner
    door_half, door_top = 0.18 * scale, 0.6 * scale
    for a, b, size in ((-middle, 0.0, (thick, height, 2 * outer)), (0.0, middle, (2 * outer, height, thick)),
                       (0.0, -middle, (2 * outer, height, thick))):
        px, pz = tower_point(x, z, a, b)
        scene.add_box((px, height / 2, pz), size, TOWER_YAW)
    side = outer - door_half
    for b in (-(door_half + side / 2), door_half + side / 2):
        px, pz = tower_point(x, z, middle, b)
        scene.add_box((px, height / 2, pz), (thick, height, side), TOWER_YAW)
    px, pz = tower_point(x, z, middle, 0.0)
    scene.add_box((px, (door_top + height) / 2, pz), (thick, height - door_top, 2 * door_half), TOWER_YAW)


def furnish_observatory(scene, x, z, scale, ruined, rng):
    """Salle des veilleurs, au pied de la tour : la table où l'on tenait le carnet du volcan (texte à lire), la chaise,
    la paillasse du veilleur de nuit, le coffre, et l'échelle vers la chambre de guet. Plancher de bois, et le
    plafond de l'étage au-dessus ; dans la tour décapitée, la table est renversée et le carnet est resté à terre."""
    def at(a, b, y=0.0):
        px, pz = tower_point(x, z, a, b)
        return (px, y, pz)

    def turn(degrees):
        return TOWER_YAW + degrees

    side = 2 * 0.349 * scale
    scene.add("fantasy_town_kit/planks", at(0.0, 0.0, -0.18), turn(0.0), side + 0.1)
    if not ruined:
        ceiling = 1.01 * scale - 0.2
        scene.add("fantasy_town_kit/planks", at(0.0, 0.0, ceiling), turn(0.0), side + 0.1)
        scene.add("fantasy_town_kit/planks", at(0.0, 0.0, ceiling - 0.015), turn(90.0), side + 0.1)
    top = 2.0 * MODEL_BOXES["mini_dungeon/table"][1][1]
    if ruined:
        furniture(scene, "mini_dungeon/table", at(-0.8, 0.4), turn(90.0), 2.0, height=0.6, roll=90.0)
        scene.add("furniture_kit/books", at(-0.1, -0.2), turn(rng.uniform(0, 360)), 2.4)
        furniture(scene, "furniture_kit/chair", at(0.4, 1.0), turn(30.0), 2.4, tilt=90.0)
        scene.add("survival_kit/resource-planks", at(0.3, -0.9), turn(rng.uniform(0, 360)), 2.6)
    else:
        furniture(scene, "mini_dungeon/table", at(-0.9, 0.3), turn(90.0), 2.0, height=top)
        furniture(scene, "furniture_kit/books", at(-0.85, 0.15, top), turn(100.0), 2.4)
        furniture(scene, "graveyard_kit/candle", at(-1.15, 0.9, top), turn(0.0), 1.6)
        furniture(scene, "furniture_kit/chair", at(0.05, 0.3), turn(-90.0), 2.4)
        furniture(scene, "survival_kit/bedroll", at(-0.6, -1.15), turn(0.0), 2.4)
        furniture(scene, "survival_kit/chest", at(0.9, -1.25), turn(0.0), 2.6, height=0.7)
        furniture(scene, "graveyard_kit/lantern-candle", at(0.9, -1.25, 2.6 * MODEL_BOXES["survival_kit/chest"][1][1]), turn(0.0), 1.4)
        furniture(scene, "mini_forest/ladder", at(0.5, 1.35), turn(0.0), 3.8, tilt=10.0)


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
    furnish_observatory(scene, x, z, scale, True, rng)
    rubble(scene, rng, x + 3.6, z + 3.6, True, count=2, spread=2.0)
    scene.rebuilt("Observatory")
    y = 0.0
    for model in ("tower-square-mid-door", "tower-square-mid-windows", "tower-square-mid-windows", "tower-square-mid-windows"):
        scene.add(f"castle_kit/{model}", (x, y, z), TOWER_YAW, scale)
        y += 1.01 * scale
    scene.add("castle_kit/tower-square-top-roof-high-windows", (x, y, z), TOWER_YAW, scale)
    tower_walls(scene, x, z, scale, y + 1.07 * scale)
    furnish_observatory(scene, x, z, scale, False, rng)
    scene.add("castle_kit/flag-pennant", (x, y + 1.07 * scale, z), 0.0, 3.0)
    scene.group = "Fixed"'''),
# Lavoir : un banc face au bassin, et la corbeille de linge.
('''    furniture(scene, "survival_kit/bucket", (cx - 1.0, 0.0, cz - 3.0), 0.0, 3.4)
    scene.group = "Fixed"''',
'''    furniture(scene, "survival_kit/bucket", (cx - 1.0, 0.0, cz - 3.0), 0.0, 3.4)
    furniture(scene, "graveyard_kit/bench", (cx - 2.2, 0.0, cz + 3.2), 180.0, 2.2, height=1.0)
    furniture(scene, "survival_kit/box-open", (cx + 1.8, 0.0, cz + 3.1), 15.0, 2.8, height=0.85)
    furniture(scene, "food_kit/bag-flat", (cx + 1.8, 0.45, cz + 3.1), 40.0, 1.2)
    scene.group = "Fixed"'''),
# Halle : les denrées alignées sans se toucher, et des sacs de grain au bout de la halle.
('''            for offset in (-0.8, 0.0, 0.8):
                furniture(scene, food, (x + offset, 0.69, z), rng.uniform(0, 360), 1.6 if "cheese" not in food else 1.0)''',
'''            scale = {"food_kit/cheese": 0.9, "food_kit/fish": 1.2}.get(food, 1.5)
            for offset in (-0.9, 0.0, 0.9):
                furniture(scene, food, (x + offset, 0.69, z), rng.uniform(-15, 15), scale)'''),
('''    furniture(scene, "survival_kit/box-large", (cx + 5.6, 0.0, cz + 3.2), 90.0, 3.0, height=0.8)
    scene.group = "Fixed"''',
'''    furniture(scene, "survival_kit/box-large", (cx + 5.6, 0.0, cz + 3.2), 90.0, 3.0, height=0.8)
    for index, x in enumerate((cx + 4.2, cx + 3.4)):
        furniture(scene, "food_kit/bag", (x, 0.0, cz + 3.4), rng.uniform(-20, 20), 1.6, height=1.3)
    scene.group = "Fixed"'''),
# Statue de Devlyn renversée : à côté de son socle, sans y entrer.
('''    furniture(scene, "mini_arena/statue", (cx + 2.4, 0.0, cz + 1.6), 40.0, 2.0, height=1.4, tilt=90.0)''',
'''    furniture(scene, "mini_arena/statue", (cx + 2.9, 0.0, cz + 2.0), 40.0, 2.0, height=1.4, tilt=90.0)'''),
]
