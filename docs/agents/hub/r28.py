REPLACEMENTS = [
('''        span = (depth * TILE * 0.98, TILE, width * TILE * 0.98)
        for level in [-0.215] + [floor * WALL_HEIGHT - 0.215 for floor in range(1, floors)] + [floors * WALL_HEIGHT - 0.185]:
            scene.add("fantasy_town_kit/planks", (cx, level, cz), 90.0, span)''',
'''        span = (depth * TILE * 0.98, TILE, width * TILE * 0.98)
        for level in [-0.215] + [floor * WALL_HEIGHT - 0.215 for floor in range(1, floors)]:
            scene.add("fantasy_town_kit/planks", (cx, level, cz), 90.0, span)
        # Au-dessus du plafond, un panneau de bois plein (un mur de planches couché, d'une seule pièce) : par les
        # fentes des lattes, on voit du bois et non le dessous des tuiles du toit. Couché d'un quart de tour, le mur
        # prend son épaisseur (x de 0,4 à 0,5) sur la hauteur et sa hauteur sur la largeur de la maison.
        ceiling = floors * WALL_HEIGHT - 0.2
        full_width, full_depth = width * TILE * 0.98, depth * TILE * 0.98
        scene.add("fantasy_town_kit/wall-wood", (cx + full_width / 2, ceiling - 0.03, cz), 0.0, (0.5, full_width, full_depth), roll=90.0)'''),
]
