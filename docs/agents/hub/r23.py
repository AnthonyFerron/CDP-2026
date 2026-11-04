REPLACEMENTS = [
('''        scene.add("survival_kit/metal-panel", (bx - TILE - 0.3, 0.6, bz + dz), 90.0, 3.4)''',
 '''        scene.add("survival_kit/metal-panel", (bx - TILE - 0.3, 0.0, bz + dz), 90.0, 3.4)'''),
('''        furniture(scene, "food_kit/bag", frame.at(hu - 0.6, -hv + 0.8 + index * 1.0), frame.turn(rng.uniform(-20, 20)), 1.6,
                  height=1.3, tilt=90.0 if ruined and index == 1 else 0.0)''',
 '''        # Un sac couché ne remplit pas sa boîte : on l'abaisse d'autant pour qu'il touche le sol.
        tipped = ruined and index == 1
        furniture(scene, "food_kit/bag", frame.at(hu - 0.6, -hv + 0.8 + index * 1.0, -0.14 if tipped else 0.0), frame.turn(rng.uniform(-20, 20)), 1.6,
                  height=1.3, tilt=90.0 if tipped else 0.0)'''),
('''        furniture(scene, "food_kit/bag", frame.at(-hu + 0.6 + index * 0.9, -hv + 0.6), frame.turn(rng.uniform(-25, 25)), 1.6,
                  height=1.3, tilt=90.0 if ruined and index % 2 else 0.0)''',
 '''        tipped = ruined and index % 2 == 1
        furniture(scene, "food_kit/bag", frame.at(-hu + 0.6 + index * 0.9, -hv + 0.6, -0.15 if tipped else 0.0), frame.turn(rng.uniform(-25, 25)), 1.6,
                  height=1.3, tilt=90.0 if tipped else 0.0)'''),
('''    furniture(scene, "mini_forest/ladder", frame.at(-hu + 0.9 if not ruined else 0.4, 0.8), frame.turn(90.0), 3.8, height=3.6 if not ruined else 0.5,''',
 '''    furniture(scene, "mini_forest/ladder", frame.at(-hu + 0.9 if not ruined else 0.4, 0.8, 0.0 if not ruined else -0.05), frame.turn(90.0), 3.8,
              height=3.6 if not ruined else 0.5,'''),
('''        furniture(scene, "mini_arena/weapon-rack", frame.at(hu - 0.7, v), frame.turn(-90.0), 3.0, height=1.4,
                  tilt=90.0 if ruined and index == 0 else 0.0)''',
 '''        tipped = ruined and index == 0
        furniture(scene, "mini_arena/weapon-rack", frame.at(hu - 0.7, v, -0.45 if tipped else 0.0), frame.turn(-90.0), 3.0, height=1.4,
                  tilt=90.0 if tipped else 0.0)'''),
('''    benches = [(39.8, -60.0, 90.0), (44.2, -60.0, -90.0), (39.8, -82.0, 90.0), (44.4, -79.4, -90.0), (33.2, -67.6, 90.0), (50.4, -72.6, 180.0)]''',
 '''    benches = [(39.8, -60.0, 90.0), (44.2, -60.0, -90.0), (39.8, -82.0, 90.0), (43.6, -78.4, -90.0), (33.2, -67.6, 90.0), (50.4, -72.6, 180.0)]'''),
('''        furniture(scene, "graveyard_kit/bench-damaged", (x, 0.0, z), degrees + rng.uniform(-15, 15), 2.2, height=0.9, roll=90.0 if x > 44 else 0.0)''',
 '''        furniture(scene, "graveyard_kit/bench-damaged", (x, -0.12 if x > 44 else 0.0, z), degrees + rng.uniform(-15, 15), 2.2, height=0.9,
                  roll=90.0 if x > 44 else 0.0)'''),
('''    for index, (x, z) in enumerate(((cx - 2.6, cz - 3.0), (cx + 2.6, cz - 3.0))):
        furniture(scene, "survival_kit/barrel-open", (x, 0.0, z), 0.0, 3.0, height=1.0)''',
 '''    for index, (x, z) in enumerate(((cx - 2.6, cz - 3.0), (cx + 2.0, cz - 3.0))):
        furniture(scene, "survival_kit/barrel-open", (x, 0.0, z), 0.0, 3.0, height=1.0)'''),
('''        furniture(scene, "nature_kit/statue_column", (px, 0.26, pz), 0.0, (2.2, 3.4, 2.2), height=3.4)''',
 '''        furniture(scene, "nature_kit/statue_column", (px, 0.17, pz), 0.0, (2.2, 3.4, 2.2), height=3.4)'''),
]
