REPLACEMENTS = [
('''            scene.add("fantasy_town_kit/lantern", (center[0] + outward[0] * 0.5 + along[0] * 1.6, 0.0,
                                                   center[1] + outward[1] * 0.5 + along[1] * 1.6), 0.0, 2.2)''',
 '''            lantern = (center[0] + outward[0] * 0.5 + along[0] * 1.6, center[1] + outward[1] * 0.5 + along[1] * 1.6)
            scene.add("fantasy_town_kit/lantern", (lantern[0], 0.0, lantern[1]), 0.0, 2.2)
            scene.add_box((lantern[0], 1.0, lantern[1]), (0.45, 2.0, 0.45))'''),
('''        scene.add(f"fantasy_town_kit/{model}", (x, 0.0, z), degrees, 3.0)
        scene.add_box((x, 1.5, z), (3.0, 3.0, 3.0), degrees)''',
 '''        scene.add(f"fantasy_town_kit/{model}", (x, 0.0, z), degrees, 3.0)
        # L'étal simple est un banc d'1,1 m : sa collision suit sa forme, pas celle des étals à auvent.
        scene.add_box((x, 0.55, z) if model == "stall" else (x, 1.5, z), (1.95, 1.1, 3.0) if model == "stall" else (3.0, 3.0, 3.0), degrees)'''),
('''            furniture(scene, "graveyard_kit/hay-bale-bundled", (x, 1.0, cz + 4.5), 0.0, 2.2)''',
 '''            furniture(scene, "graveyard_kit/hay-bale-bundled", (x, 1.0, cz + 4.5), 0.0, 2.2, height=0.8)'''),
('''    furniture(scene, "mini_forest/ladder", frame.at(-hu + 0.9 if not ruined else 0.4, 0.8), frame.turn(90.0), 3.8, tilt=-12.0 if not ruined else 90.0)''',
 '''    furniture(scene, "mini_forest/ladder", frame.at(-hu + 0.9 if not ruined else 0.4, 0.8), frame.turn(90.0), 3.8, height=3.6 if not ruined else 0.5,
              tilt=-12.0 if not ruined else 90.0)'''),
('''        furniture(scene, "mini_arena/statue", (x, 0.94, z), 90.0 if x < cx else -90.0, 1.6)''',
 '''        furniture(scene, "mini_arena/statue", (x, 0.94, z), 90.0 if x < cx else -90.0, 1.6, height=2.1)'''),
('''            furniture(scene, "fantasy_town_kit/hedge", (x + side * 1.9, 0.0, z), 0.0, (1.0, 1.6, 3.6))
            furniture(scene, "fantasy_town_kit/hedge", (x, 0.0, z + side * 1.9), 90.0, (1.0, 1.6, 3.6))''',
 '''            furniture(scene, "fantasy_town_kit/hedge", (x + side * 1.9, 0.0, z), 0.0, (1.0, 1.6, 3.6), height=0.4)
            furniture(scene, "fantasy_town_kit/hedge", (x, 0.0, z + side * 1.9), 90.0, (1.0, 1.6, 3.6), height=0.4)'''),
('''SOLID = ("furniture_kit/chair", "furniture_kit/stoolBar", "fantasy_town_kit/stall-stool", "furniture_kit/bench",
         "fantasy_town_kit/wheel", "fantasy_town_kit/poles-horizontal", "graveyard_kit/bench-damaged")''',
 '''SOLID = ("furniture_kit/chair", "furniture_kit/stoolBar", "fantasy_town_kit/stall-stool", "furniture_kit/bench",
         "fantasy_town_kit/wheel", "fantasy_town_kit/poles-horizontal", "graveyard_kit/bench-damaged", "furniture_kit/pottedPlant")'''),
]
