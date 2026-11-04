REPLACEMENTS = [
('''    cx, cz, width, depth, _, _, floors = house
    for column in range(width):
        for row in range(depth):
            x = cx - (width - 1) * TILE / 2 + column * TILE
            z = cz - (depth - 1) * TILE / 2 + row * TILE
            if not ruined:
                scene.add("fantasy_town_kit/planks", (x, -0.2, z), 0.0, TILE)
                # Sous-plancher croisé : entre les lattes, on voit du bois et non l'herbe du terrain.
                scene.add("fantasy_town_kit/planks", (x, -0.215, z), 90.0, CROSS)
                for floor in range(1, floors):
                    scene.add("fantasy_town_kit/planks", (x, floor * WALL_HEIGHT - 0.2, z), 0.0, TILE)
                    scene.add("fantasy_town_kit/planks", (x, floor * WALL_HEIGHT - 0.215, z), 90.0, CROSS)
                # Plafond sous le toit : vues d'en dessous, les tuiles du toit laisseraient voir le ciel. Deux couches
                # croisées, comme le plancher, pour que le jour ne passe pas entre les lattes.
                scene.add("fantasy_town_kit/planks", (x, floors * WALL_HEIGHT - 0.2, z), 0.0, TILE)
                scene.add("fantasy_town_kit/planks", (x, floors * WALL_HEIGHT - 0.185, z), 90.0, CROSS)
                continue''',
'''    cx, cz, width, depth, _, _, floors = house
    if not ruined:
        # Couches croisées d'une seule pièce sous chaque plancher et au-dessus du plafond : entre les lattes et aux
        # joints des cases, on voit du bois, et non l'herbe du terrain ou le dessous du toit. Tournée d'un quart de
        # tour, la pièce prend la profondeur de la maison sur son axe x.
        span = (depth * TILE * 0.98, TILE, width * TILE * 0.98)
        for level in [-0.215] + [floor * WALL_HEIGHT - 0.215 for floor in range(1, floors)] + [floors * WALL_HEIGHT - 0.185]:
            scene.add("fantasy_town_kit/planks", (cx, level, cz), 90.0, span)
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
                continue'''),
('''# Couches croisées sous les planchers et au-dessus des plafonds : un peu plus larges qu'une case, elles couvrent aussi
# les joints entre deux cases de planches.
CROSS = (TILE * 1.04, TILE, TILE * 1.04)
''', ''),
]
