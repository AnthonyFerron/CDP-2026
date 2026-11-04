REPLACEMENTS = [
('''def roof(scene, cx, cz, width, depth, base):
    """Toit à deux pans : les tuiles se rejoignent au faîte, au milieu de la largeur."""
    for column in range(width):
        x = cx - (width - 1) * TILE / 2 + column * TILE
        outward = (1, 0) if x > cx else (-1, 0)
        for row in range(depth):
            z = cz - (depth - 1) * TILE / 2 + row * TILE
            if abs(x - cx) < 0.1:
                scene.add("fantasy_town_kit/roof-flat", (x, base + 0.1, z), 0.0, TILE)
            else:
                scene.add("fantasy_town_kit/roof", (x, base, z), OUTWARD_ANGLES[outward], TILE)''',
'''def roof(scene, cx, cz, width, depth, base):
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
                scene.add("fantasy_town_kit/roof", (x, base, z), OUTWARD_ANGLES[(-outward[0], -outward[1])], TILE)'''),
]
