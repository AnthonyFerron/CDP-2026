REPLACEMENTS = [
('''    for dx, dz in ((-4.5, 2.6), (3.0, -2.7), (5.5, 2.4)):
        scene.add("castle_kit/rocks-small", (x + dx, -1.3, z + dz * 1.4), rng.uniform(0, 360), 1.6)''',
 '''    # Blocs du pont effondré, tombés dans le lit de la rivière : ils affleurent de l'eau, de part et d'autre du tablier.
    for dx, dz in ((-1.6, 3.6), (1.4, -3.8), (0.2, 4.2)):
        scene.add("castle_kit/rocks-small", (x + dx, -1.75, z + dz), rng.uniform(0, 360), 1.6)'''),
]
