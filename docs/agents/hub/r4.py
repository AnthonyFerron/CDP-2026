REPLACEMENTS = [
('''def main():
    build_shelter()''',
'''# Ponts sur la rivière : (x, z, cap du tablier, longueur, largeur), comme BRIDGES dans hub_terrain.gd.
# Le tablier affleure le chemin (dessus à 0,1 m) ; ses parapets portent une collision haute, pour qu'on ne saute pas
# dans la rivière, dont les berges ne s'ouvrent que sous les ponts.
BRIDGES = [(63.25, 0.0, 0.0, 15.5, 5.0), (63.0, -66.0, 0.0, 15.0, 3.0)]
DECK_TOP = 0.1


def bridge_collision(scene, x, z, degrees, length, width, rail):
    """Tablier et parapets d'un pont : la collision est la même, pont de fortune ou reconstruit."""
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
    scene.add_box((x, DECK_TOP - 0.25, z), (length + 0.6, 0.5, width), degrees)
    for side in (-1, 1):
        # Le côté du tablier : la normale de son axe, dans le plan.
        nx, nz = s * side * rail, c * side * rail
        scene.add_box((x + nx, DECK_TOP + 1.1, z + nz), (length + 0.6, 2.2, 0.3), degrees)


def build_bridges(scene, rng):
    """Le grand pont de pierre du chemin du bunker, et la passerelle du jardin du roi vers la rive est."""
    x, z, degrees, length, width = BRIDGES[0]
    scene.group = "Fixed"
    bridge_collision(scene, x, z, degrees, length, width, 2.06)
    # Avant le premier livre : un pont de fortune, des planches jetées sur les piles du pont effondré.
    scene.repair("GreatBridge", 1)
    scene.add("nature_kit/bridge_wood", (x, DECK_TOP - 0.15 * 6.0, z), degrees, (length / 1.04, 6.0, width / 1.04))
    for dx, dz in ((-4.5, 2.6), (3.0, -2.7), (5.5, 2.4)):
        scene.add("castle_kit/rocks-small", (x + dx, -1.3, z + dz * 1.4), rng.uniform(0, 360), 1.6)
    scene.rebuilt("GreatBridge")
    scene.add("nature_kit/bridge_stoneRound", (x, DECK_TOP - 0.15 * 6.0, z), degrees, (length / 1.04, 6.0, width / 1.04))
    for end in (-1, 1):
        for side in (-1, 1):
            lx, lz = x + end * (length / 2 + 0.7), z + side * 2.9
            scene.add("graveyard_kit/lightpost-single", (lx, 0.0, lz), 0.0 if side < 0 else 180.0, 2.2)
            scene.add_box((lx, 1.4, lz), (0.45, 2.8, 0.45))
    # Passerelle de bois du jardin du roi : reconstruite avec le jardin, au deuxième livre.
    x, z, degrees, length, width = BRIDGES[1]
    scene.group = "Fixed"
    bridge_collision(scene, x, z, degrees, length, width, 1.24)
    scene.repair("ParkFootbridge", 2)
    scene.add("mini_forest/bridge", (x, DECK_TOP - 0.47 * 0.2, z), degrees, (length / 1.04, 0.2 / 0.47 * 1.0, width / 0.8))
    scene.rebuilt("ParkFootbridge")
    scene.add("nature_kit/bridge_woodRound", (x, DECK_TOP - 0.15 * 6.0, z), degrees, (length / 1.04, 6.0, width / 1.04))
    scene.group = "Fixed"


def main():
    build_shelter()'''),
('''    build_mine(scene, rng)
    OUTPUT.parent.mkdir''', '''    build_mine(scene, rng)
    build_bridges(scene, rng)
    OUTPUT.parent.mkdir'''),
]
