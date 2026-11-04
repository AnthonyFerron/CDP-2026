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


