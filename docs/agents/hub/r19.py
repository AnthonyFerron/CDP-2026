REPLACEMENTS = [
('''def furniture(scene, model, center, degrees=0.0, scale=2.6, height=None, tilt=0.0, roll=0.0):
    """Comme furniture() de build_plaine, avec en plus une échelle par axe du modèle (x, y, z)."""
    if not isinstance(scale, tuple):''',
'''# Meubles toujours solides, même posés sans hauteur : chaises, tabourets, bancs, roues, poutres. On bute dessus au lieu
# de les traverser.
SOLID = ("furniture_kit/chair", "furniture_kit/stoolBar", "fantasy_town_kit/stall-stool", "furniture_kit/bench",
         "fantasy_town_kit/wheel", "fantasy_town_kit/poles-horizontal", "graveyard_kit/bench-damaged")


def furniture(scene, model, center, degrees=0.0, scale=2.6, height=None, tilt=0.0, roll=0.0):
    """Comme furniture() de build_plaine, avec en plus une échelle par axe du modèle (x, y, z)."""
    if height is None and model in SOLID:
        # Hauteur de la boîte du meuble tel qu'il est posé, debout ou renversé.
        height = MODEL_BOXES[MEDIEVAL.get(model, model)][1][1] * (scale if not isinstance(scale, tuple) else scale[1])
    if not isinstance(scale, tuple):'''),
('''    for sx in (-1, 1):
        for sz in (-1, 1):
            scene.add(pillar, (cx + sx * half_w, 0.0, cz + sz * half_d), 0.0, WALL_SCALE)
    # Poutres de la charpente tombées au sol, en travers de la pièce.
    for beam in range(rng.randint(1, 2)):
        point = (cx + rng.uniform(-half_w + 1.8, half_w - 1.8), 0.0, cz + rng.uniform(-half_d + 1.8, half_d - 1.8))
        furniture(scene, "fantasy_town_kit/poles-horizontal", point, rng.uniform(0, 180), 3.0, tilt=90.0)''',
'''    for sx in (-1, 1):
        for sz in (-1, 1):
            scene.add(pillar, (cx + sx * half_w, 0.0, cz + sz * half_d), 0.0, WALL_SCALE)
            # Le pilier d'angle tient même quand les murs voisins sont tombés : il garde sa collision.
            scene.add_box((cx + sx * half_w, WALL_HEIGHT / 2, cz + sz * half_d), (0.6, WALL_HEIGHT, 0.6))
    # Poutres de la charpente tombées au sol, couchées en travers de la pièce.
    for beam in range(rng.randint(1, 2)):
        point = (cx + rng.uniform(-half_w + 1.8, half_w - 1.8), 0.0, cz + rng.uniform(-half_d + 1.8, half_d - 1.8))
        furniture(scene, "fantasy_town_kit/poles-horizontal", point, rng.uniform(0, 180), 3.0, roll=90.0)'''),
('''            for floor in range(floors):
                scene.add(pillar, (cx + sx * half_w, floor * WALL_HEIGHT, cz + sz * half_d), 0.0, WALL_SCALE)
    roof(scene, cx, cz, width, depth, WALL_HEIGHT * floors)''',
'''            for floor in range(floors):
                scene.add(pillar, (cx + sx * half_w, floor * WALL_HEIGHT, cz + sz * half_d), 0.0, WALL_SCALE)
            scene.add_box((cx + sx * half_w, WALL_HEIGHT / 2, cz + sz * half_d), (0.6, WALL_HEIGHT, 0.6))
    roof(scene, cx, cz, width, depth, WALL_HEIGHT * floors)'''),
('''    scene.add("fantasy_town_kit/fence", (18.0, 0.0, -68.0), 90.0, 4.0)
    scene.add_box((18.0, 0.8, -66.3), (4.0, 1.6, 0.3))''',
 '''    # Le modèle de barrière est décalé de 0,42 tuile de son origine : tourné, il ferme l'enclos à z = -68.
    scene.add("fantasy_town_kit/fence", (18.0, 0.0, -66.3), 90.0, 4.0)
    scene.add_box((18.0, 0.8, -68.0), (4.0, 1.6, 0.3))'''),
]
