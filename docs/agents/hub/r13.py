REPLACEMENTS = [
('''    furniture(scene, "mini_forest/ladder", frame.at(-hu + 0.25, 0.8), frame.turn(90.0), 3.8, tilt=-12.0 if not ruined else 90.0)''',
 '''    furniture(scene, "mini_forest/ladder", frame.at(-hu + 0.9 if not ruined else -hu + 1.6, 0.8), frame.turn(90.0), 3.8, tilt=-12.0 if not ruined else 90.0)'''),
('''    for index, u in enumerate((-hu + 1.0, -hu + 3.0, hu - 3.0, hu - 1.0)):
        furniture(scene, "furniture_kit/bedBunk", frame.at(u, -hv + 1.6), frame.turn(rng.uniform(-8, 8) if ruined else 0.0), 2.0,
                  height=2.0, tilt=90.0 if ruined and index % 2 else 0.0)
        furniture(scene, "survival_kit/chest", frame.at(u, -hv + 3.6), frame.turn(0.0), 3.0, height=0.7)
    table = frame.at(0.0, 0.6)
    furniture(scene, "mini_dungeon/table", table, frame.turn(90.0), 3.4, height=1.0, roll=90.0 if ruined else 0.0)
    for side in (-1, 1):
        furniture(scene, "furniture_kit/bench", frame.at(side * 1.6, 0.6), frame.turn(90.0 * side), 3.0,
                  tilt=90.0 if ruined and side > 0 else 0.0)
    for index, u in enumerate((-hu + 0.6, hu - 0.6)):
        furniture(scene, "mini_arena/weapon-rack", frame.at(u, 1.6), frame.turn(90.0 if u < 0 else -90.0), 3.0, height=1.4,
                  tilt=90.0 if ruined and index == 0 else 0.0)
    if not ruined:
        for u in (-1.5, 1.5):
            furniture(scene, "mini_dungeon/shield-rectangle", frame.at(u, -hv + 0.25, 2.2), frame.turn(0.0), 3.0)''',
 '''    # Trois lits superposés, la tête contre le mur du fond ; renversés dans les ruines, loin des murs.
    for index, u in enumerate((-4.2, -1.3, 1.6)):
        if ruined and index % 2:
            furniture(scene, "furniture_kit/bedBunk", frame.at(u + 0.2, -hv + 2.2), frame.turn(rng.uniform(-8, 8)), 1.6, height=1.0, roll=90.0)
            continue
        furniture(scene, "furniture_kit/bedBunk", frame.at(u, -hv + 1.65), frame.turn(rng.uniform(-4, 4) if ruined else 0.0), 1.6, height=1.6)
    furniture(scene, "survival_kit/chest", frame.at(4.4, -hv + 0.8), frame.turn(90.0), 3.0, height=0.7)
    table = frame.at(-3.0, 1.9)
    furniture(scene, "mini_dungeon/table", table, frame.turn(0.0), 3.4, height=1.0, roll=90.0 if ruined else 0.0)
    furniture(scene, "furniture_kit/bench", frame.at(-3.0, 0.3), frame.turn(0.0), 3.0, tilt=90.0 if ruined else 0.0)
    for index, v in enumerate((-0.6, 1.6)):
        furniture(scene, "mini_arena/weapon-rack", frame.at(hu - 0.7, v), frame.turn(-90.0), 3.0, height=1.4,
                  tilt=90.0 if ruined and index == 0 else 0.0)
    if not ruined:
        for u in (-4.2, -1.3, 1.6):
            furniture(scene, "mini_dungeon/shield-rectangle", frame.at(u, -hv + 0.25, 2.4), frame.turn(0.0), 3.0)'''),
('''    for index, u in enumerate((-hu + 1.2, 0.0)):
        furniture(scene, "furniture_kit/bookcaseOpen", frame.at(u, -hv + 0.4), frame.turn(0.0), 3.0, height=2.6,
                  tilt=90.0 if ruined and index == 1 else 0.0)''',
 '''    for index, u in enumerate((-hu + 1.2, 0.0)):
        if ruined and index == 1:
            furniture(scene, "furniture_kit/bookcaseOpen", frame.at(u, -hv + 1.6), frame.turn(0.0), 3.0, height=0.8, tilt=90.0)
            continue
        furniture(scene, "furniture_kit/bookcaseOpen", frame.at(u, -hv + 0.4), frame.turn(0.0), 3.0, height=2.6)'''),
('''    for u in (-hu + 0.4, hu - 0.4):
        furniture(scene, "furniture_kit/bookcaseClosedWide", frame.at(u, -hv + 1.6), frame.turn(90.0 if u < 0 else -90.0), 3.0, height=2.4,
                  tilt=90.0 if ruined and u > 0 else 0.0)''',
 '''    for u in (-hu + 0.4, hu - 0.4):
        if ruined and u > 0:
            furniture(scene, "furniture_kit/bookcaseClosedWide", frame.at(hu - 1.7, -hv + 1.6), frame.turn(-90.0), 3.0, height=0.8, tilt=90.0)
            continue
        furniture(scene, "furniture_kit/bookcaseClosedWide", frame.at(u, -hv + 1.6), frame.turn(90.0 if u < 0 else -90.0), 3.0, height=2.4)'''),
]
