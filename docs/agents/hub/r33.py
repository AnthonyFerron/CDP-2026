REPLACEMENTS = [
# Moulin : échelle tombée à l'écart de la meule, table du meunier, outils contre le mur du fond.
('''    furniture(scene, "mini_forest/ladder", frame.at(-hu + 0.9 if not ruined else 0.4, 0.8, 0.0 if not ruined else -0.05), frame.turn(90.0), 3.8,
              height=3.6 if not ruined else 0.5,
              tilt=-12.0 if not ruined else 90.0)
    if not ruined:
        furniture(scene, "mini_dungeon/barrel", frame.at(hu - 0.7, 1.8), frame.turn(0.0), 2.6, height=1.2)''',
'''    furniture(scene, "mini_forest/ladder", frame.at(-hu + 0.9 if not ruined else -1.6, 0.8 if not ruined else 1.8, 0.0 if not ruined else -0.05),
              frame.turn(90.0), 3.8, height=3.6 if not ruined else 0.5, tilt=-12.0 if not ruined else 90.0)
    if not ruined:
        furniture(scene, "mini_dungeon/barrel", frame.at(hu - 0.7, 1.8), frame.turn(0.0), 2.6, height=1.2)
        # La table du meunier, près de la façade : une jatte de farine, un sac entamé, une chandelle.
        top = 2.6 * MODEL_BOXES["mini_dungeon/table"][1][1]
        furniture(scene, "mini_dungeon/table", frame.at(-0.9, 2.5), frame.turn(0.0), 2.6, height=top)
        furniture(scene, "food_kit/bowl", frame.at(-1.4, 2.4, top), frame.turn(20.0), 1.4)
        furniture(scene, "food_kit/bag-flat", frame.at(-0.4, 2.6, top), frame.turn(-10.0), 1.2)
        furniture(scene, "graveyard_kit/candle", frame.at(0.05, 2.2, top), frame.turn(0.0), 1.6)
        # Pelle et fourche appuyées contre le mur du fond, entre les sacs et les caisses.
        for u, model in ((0.4, "survival_kit/tool-shovel"), (1.0, "survival_kit/tool-hoe")):
            furniture(scene, model, frame.at(u, -hv + 0.3), frame.turn(0.0), 5.0, tilt=-10.0)'''),
# Écuries : foin et abreuvoirs des stalles sans se toucher ; outils, banc, lanterne et auge du côté droit.
('''        furniture(scene, "graveyard_kit/hay-bale", frame.at(-hu + 0.7, v + 1.2), frame.turn(90.0 + rng.uniform(-10, 10)), 2.4, height=0.9)
        furniture(scene, "survival_kit/barrel-open", frame.at(-hu + 0.5, v - 0.6), frame.turn(0.0), 3.0, height=1.0,
                  tilt=90.0 if ruined and index == 2 else 0.0)''',
'''        furniture(scene, "graveyard_kit/hay-bale", frame.at(-hu + 0.7, v + 1.1), frame.turn(90.0 + rng.uniform(-6, 6)), 2.0, height=0.8)
        furniture(scene, "survival_kit/barrel-open", frame.at(-hu + 0.5, v - 0.7), frame.turn(0.0), 3.0, height=1.0,
                  tilt=90.0 if ruined and index == 2 else 0.0)'''),
('''        furniture(scene, "survival_kit/chest", frame.at(hu - 0.7, -hv + 4.2), frame.turn(-90.0), 3.4, height=0.8)
        # Enclos derrière les écuries, côté forêt.''',
'''        furniture(scene, "survival_kit/chest", frame.at(hu - 0.7, -hv + 4.2), frame.turn(-90.0), 3.4, height=0.8)
        furniture(scene, "graveyard_kit/lantern-candle", frame.at(hu - 0.7, -hv + 4.2, 3.4 * MODEL_BOXES["survival_kit/chest"][1][1]),
                  frame.turn(0.0), 1.6)
        # Fourche et pelle du palefrenier contre le mur de droite, un banc, et l'auge près de la porte.
        for v, model in ((0.2, "survival_kit/tool-hoe"), (0.8, "survival_kit/tool-shovel")):
            furniture(scene, model, frame.at(hu - 0.3, v), frame.turn(-90.0), 5.0, tilt=-10.0)
        furniture(scene, "graveyard_kit/bench", frame.at(hu - 0.6, 2.3), frame.turn(-90.0), 2.0, height=0.9)
        furniture(scene, "survival_kit/box-large-open", frame.at(hu - 0.6, 4.4), frame.turn(0.0), 2.8, height=0.85)
        # Enclos derrière les écuries, côté forêt.'''),
# Caserne : banc tombé loin de la table, râteliers espacés ; registre, chopes, assiette et chandelle sur la table,
# tabourets en face, coffre au pied d'un lit, tonneau d'eau près de la porte.
('''    furniture(scene, "furniture_kit/bench", frame.at(-3.0, 0.3), frame.turn(0.0), 3.0, tilt=90.0 if ruined else 0.0)
    for index, v in enumerate((-0.6, 1.6)):''',
'''    furniture(scene, "furniture_kit/bench", frame.at(-3.0, -0.2 if ruined else 0.3), frame.turn(0.0), 3.0, tilt=90.0 if ruined else 0.0)
    for index, v in enumerate((-1.0, 1.5)):'''),
('''    if not ruined:
        for u in (-4.2, -1.3, 1.6):
            furniture(scene, "mini_dungeon/shield-rectangle", frame.at(u, -hv + 0.25, 2.4), frame.turn(0.0), 3.0)''',
'''    if not ruined:
        for u in (-4.2, -1.3, 1.6):
            furniture(scene, "mini_dungeon/shield-rectangle", frame.at(u, -hv + 0.25, 2.4), frame.turn(0.0), 3.0)
        top = 3.4 * MODEL_BOXES["mini_dungeon/table"][1][1]
        # Le registre de la garde (texte à lire, write_hub_tscn.py), ouvert devant la place du sergent.
        furniture(scene, "furniture_kit/books", frame.at(-3.9, 1.9, top), frame.turn(15.0), 2.6)
        furniture(scene, "graveyard_kit/candle", frame.at(-3.6, 1.2, top), frame.turn(0.0), 1.6)
        for u, v in ((-2.5, 1.4), (-2.0, 2.4)):
            furniture(scene, "food_kit/mug", frame.at(u, v, top), frame.turn(rng.uniform(0, 360)), 1.3)
        furniture(scene, "graveyard_kit/detail-plate", frame.at(-2.9, 2.5, top), frame.turn(0.0), 2.4)
        for u in (-3.6, -2.4):
            furniture(scene, "fantasy_town_kit/stall-stool", frame.at(u, 3.35), frame.turn(0.0), 2.4)
        furniture(scene, "survival_kit/chest", frame.at(1.6, -0.75), frame.turn(0.0), 2.6, height=0.7)
        furniture(scene, "survival_kit/barrel", frame.at(2.4, 3.1), frame.turn(0.0), 3.0, height=1.0)'''),
# Herboristerie : étagère tombée à l'écart de la table ; dans la boutique, pots de miel, jatte, tabouret, et les
# paniers d'herbes cueillies près de la porte.
('''        if ruined and index == 1:
            furniture(scene, "furniture_kit/bookcaseOpen", frame.at(u, -hv + 1.6), frame.turn(0.0), 3.0, height=0.8, tilt=90.0)
            continue
        furniture(scene, "furniture_kit/bookcaseOpen", frame.at(u, -hv + 0.4), frame.turn(0.0), 3.0, height=2.6)''',
'''        if ruined and index == 1:
            furniture(scene, "furniture_kit/bookcaseOpen", frame.at(1.3, -hv + 1.6), frame.turn(0.0), 3.0, height=0.8, tilt=90.0)
            continue
        furniture(scene, "furniture_kit/bookcaseOpen", frame.at(u, -hv + 0.4), frame.turn(0.0), 3.0, height=2.6)'''),
('''    for index, u in enumerate((-hu + 0.9, -hu + 1.5)):
        furniture(scene, "mini_dungeon/potion", frame.at(u, -hv + 0.4, 1.25), frame.turn(rng.uniform(0, 360)), 0.7)''',
'''    for index, u in enumerate((-hu + 0.9, -hu + 1.5)):
        furniture(scene, "mini_dungeon/potion", frame.at(u, -hv + 0.4, 1.25), frame.turn(rng.uniform(0, 360)), 0.7)
    furniture(scene, "food_kit/honey", frame.at(-1.5, -0.5, 0.94), frame.turn(0.0), 1.0)
    furniture(scene, "food_kit/honey", frame.at(-1.55, 0.05, 0.94), frame.turn(30.0), 0.8)
    furniture(scene, "food_kit/bowl", frame.at(-1.35, 0.55, 0.94), frame.turn(0.0), 1.1)
    furniture(scene, "fantasy_town_kit/stall-stool", frame.at(-0.6, 1.5), frame.turn(0.0), 2.4)
    for v in (2.6, 3.3):
        furniture(scene, "survival_kit/box-open", frame.at(hu - 0.6, v), frame.turn(rng.uniform(-10, 10)), 2.6, height=0.8)
        furniture(scene, "nature_kit/plant_bush", frame.at(hu - 0.6, v, 0.45), frame.turn(rng.uniform(0, 360)), 1.4)'''),
# Scriptorium : lutrin au fond, pupitres avancés d'un pas, et la page en cours de copie sur le lutrin.
('''    for row in range(2):
        for side in (-1, 1):
            spot = frame.at(side * 1.6, -hv + 1.6 + row * 2.4)
            furniture(scene, "mini_dungeon/table", spot, frame.turn(0.0), 2.4, height=0.8, roll=90.0 if ruined and side > 0 else 0.0)
            furniture(scene, "furniture_kit/chair", frame.at(side * 1.6, -hv + 2.6 + row * 2.4), frame.turn(180.0), 2.4,
                      tilt=90.0 if ruined and row == 1 else 0.0)
            if not ruined:
                furniture(scene, "furniture_kit/books", frame.at(side * 1.6 - 0.2, -hv + 1.6 + row * 2.4, 0.78), frame.turn(rng.uniform(-20, 20)), 2.6)
                furniture(scene, "graveyard_kit/candle", frame.at(side * 1.6 + 0.4, -hv + 1.4 + row * 2.4, 0.78), frame.turn(0.0), 1.6)
    furniture(scene, "graveyard_kit/altar-wood", frame.at(0.0, -hv + 0.6), frame.turn(0.0), 1.8, height=1.0)
    if ruined:
        for index in range(4):
            scene.add("furniture_kit/books", frame.at(rng.uniform(-2.0, 2.0), rng.uniform(-1.0, 2.0)), rng.uniform(0, 360), 2.6)
    else:
        furniture(scene, "survival_kit/chest", frame.at(hu - 0.8, 1.6), frame.turn(-90.0), 3.0, height=0.7)''',
'''    for row in range(2):
        for side in (-1, 1):
            spot = frame.at(side * 1.6, -hv + 1.8 + row * 2.4)
            furniture(scene, "mini_dungeon/table", spot, frame.turn(0.0), 2.4, height=0.8, roll=90.0 if ruined and side > 0 else 0.0)
            furniture(scene, "furniture_kit/chair", frame.at(side * 1.6, -hv + 2.9 + row * 2.4), frame.turn(180.0), 2.4,
                      tilt=90.0 if ruined and row == 1 else 0.0)
            if not ruined:
                furniture(scene, "furniture_kit/books", frame.at(side * 1.6 - 0.2, -hv + 1.8 + row * 2.4, 0.78), frame.turn(rng.uniform(-20, 20)), 2.6)
                furniture(scene, "graveyard_kit/candle", frame.at(side * 1.6 + 0.4, -hv + 1.6 + row * 2.4, 0.78), frame.turn(0.0), 1.6)
    # Le lutrin du maître copiste, au fond : la page qu'il recopiait y est restée ouverte (texte à lire).
    lectern = 1.6 * MODEL_BOXES["graveyard_kit/altar-wood"][1][1]
    furniture(scene, "graveyard_kit/altar-wood", frame.at(0.0, -hv + 0.45), frame.turn(0.0), 1.6, height=lectern)
    if ruined:
        for index in range(4):
            scene.add("furniture_kit/books", frame.at(rng.uniform(-2.0, 2.0), rng.uniform(-1.0, 2.0)), rng.uniform(0, 360), 2.6)
    else:
        furniture(scene, "furniture_kit/books", frame.at(0.0, -hv + 0.45, lectern), frame.turn(90.0), 2.6)
        furniture(scene, "graveyard_kit/candle-multiple", frame.at(0.6, -hv + 0.35, lectern), frame.turn(0.0), 1.4)
        furniture(scene, "survival_kit/chest", frame.at(hu - 0.8, 1.6), frame.turn(-90.0), 3.0, height=0.7)
        furniture(scene, "furniture_kit/rugRectangle", frame.at(0.0, 0.4, 0.02), frame.turn(90.0), 2.2)'''),
('''        if ruined and u > 0:
            furniture(scene, "furniture_kit/bookcaseClosedWide", frame.at(hu - 1.7, -hv + 1.6), frame.turn(-90.0), 3.0, height=0.8, tilt=90.0)
            continue''',
'''        if ruined and u > 0:
            furniture(scene, "furniture_kit/bookcaseClosedWide", frame.at(2.3, 2.4), frame.turn(-90.0), 3.0, height=0.8, tilt=90.0)
            continue'''),
]
