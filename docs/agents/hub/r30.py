REPLACEMENTS = [
('''    # Dalle de terre au-dessus du plafond : l'abri est enterré, aucun jour ne passe entre les planches.
    scene.add("fantasy_town_kit/roof-flat", (cx, WALL_HEIGHT + 0.3, cz), 0.0, 1.0)
    for column in range(width):
        for row in range(depth):
            x = cx - (width - 1) * TILE / 2 + column * TILE
            z = cz - (depth - 1) * TILE / 2 + row * TILE
            scene.add("fantasy_town_kit/roof-flat", (x, WALL_HEIGHT + 0.3, z), 0.0, TILE)''',
'''    # Panneau de bois plein au-dessus du plafond (un mur de planches couché, d'une seule pièce) : l'abri est enterré,
    # et entre les planches on voit du bois, non le vert des tuiles d'un toit.
    full_width, full_depth = width * TILE * 0.99, depth * TILE * 0.99
    scene.add("fantasy_town_kit/wall-wood", (cx + full_width / 2, WALL_HEIGHT + 0.05, cz), 0.0, (0.5, full_width, full_depth), roll=90.0)'''),
]
