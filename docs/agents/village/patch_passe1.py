"""Passe au centimètre, premières corrections : rempart sud, cloisons des écuries, rangs du potager et du champ,
gravats, four, trémie du meunier, foin, pots, lanterne couchée, corbeaux du rempart."""
import sys
from pathlib import Path

builder, writer, scatter = (Path(p) for p in sys.argv[1:4])


def patch(path, pairs):
    text = path.read_text(encoding="utf-8")
    for old, new in pairs:
        assert text.count(old) == 1, (path.name, old[:90], text.count(old))
        text = text.replace(old, new)
    path.write_text(text, encoding="utf-8", newline="\n")


patch(builder, [
    # Le mur étroit du rempart sud est tourné de 90 degrés : sa moitié pleine est côté extérieur (z de 42 à 44).
    ('''        # Le mur étroit n'occupe que la moitié de sa case, côté village : sa collision le suit.
        depth = 0.5 * RAMPART if model == "wall-narrow" else RAMPART
        rampart_piece(scene, x, south, model, 90.0, (x, south - (RAMPART - depth) / 2), (RAMPART, 5.2, depth))''',
     '''        # Le mur étroit, tourné d'un quart de tour, n'occupe que la moitié extérieure de sa case (z de 42 à 44) : sa
        # collision le suit, sans mur invisible côté village.
        depth = 0.5 * RAMPART if model == "wall-narrow" else RAMPART
        rampart_piece(scene, x, south, model, 90.0, (x, south + (RAMPART - depth) / 2), (RAMPART, 5.2, depth))'''),
    # Cloisons des stalles : posées par leur boîte, leur collision sur leur maillage.
    ('''    for z in (28.0, 32.0):
        scene.add("nature_kit/fence_planks", (26.25, 0.0, z + 0.48), 0.0, (2.9, 3.6, 2.0))
        block(scene, (26.25, 0.65, z), (2.9, 1.3, 0.25), label="cloison de stalle")''',
     '''    for z in (28.0, 32.0):
        place(scene, "nature_kit/fence_planks", (26.25, 0.0, z), 0.0, (2.9, 3.6, 2.0), height=1.26, label="cloison de stalle")'''),
    # Les légumes et le blé se traversent comme l'herbe : plus de murs invisibles là où une plante manque.
    ('''        block(scene, (-27.8, 0.35, z), (6.4, 0.7, 1.4), label="planche du potager")
''', ''),
    ('''        block(scene, (-27.8, 0.35, z), (6.4, 0.7, 1.0), label="sillons brûlés")
''', ''),
    ('''    block(scene, (19.25, 0.5, -17.4), (4.4, 1.0, 9.0), label="champ de blé")
''', ''),
    # Le four : sa collision couvre aussi la voûte, sur laquelle on monterait en sautant sur le socle.
    ('''    block(scene, (base[0], 0.55, base[2]), (2.3, 1.1, 2.0), frame.yaw(), label="four")''',
     '''    block(scene, (base[0], 0.95, base[2]), (2.3, 1.9, 2.0), frame.yaw(), label="four")'''),
    ('''    post(scene, x, z, 1.0, 0.95, label="meules")''', '''    post(scene, x, z, 1.0, 1.85, label="meules et trémie")'''),
    ('''    lay(scene, "graveyard_kit/hay-bale", (27.6, 0.0, 21.8), 40.0, 1.8)''',
     '''    place(scene, "graveyard_kit/hay-bale", (27.6, 0.0, 21.8), 40.0, 1.8, height=0.63, label="botte de foin")'''),
    ('''        fl(scene, frame, "mini_dungeon/pot", -far * 1.6, -2.9, 30.0, 1.1, y=FLOOR)''',
     '''        fp(scene, frame, "mini_dungeon/pot", -far * 1.6, -2.7, 30.0, 1.1, height=0.47, y=FLOOR, label="marmite")'''),
    # La lanterne fauchée ne barre plus la grande rue : couchée au bord, contre la barricade, avec sa collision.
    ('''    scene.add("fantasy_town_kit/lantern", (-1.0, 0.0, 33.2), 30.0, 2.2, tilt=0.0, roll=88.0)''',
     '''    place(scene, "fantasy_town_kit/lantern", (-4.3, 0.0, 32.4), 15.0, 2.2, height=0.5, roll=90.0, label="lanterne fauchée")'''),
    # Les gravats des cratères restent sous la cheville.
    ('''        lay(scene, "mini_arena/bricks" if index % 2 else "graveyard_kit/debris", (px, 0.0, pz), rng.uniform(0, 360),
            0.6 if index % 2 else 1.4)''', '''        lay(scene, "mini_arena/bricks" if index % 2 else "graveyard_kit/debris", (px, 0.0, pz), rng.uniform(0, 360),
            0.6 if index % 2 else 1.25)'''),
    ('''        lay(scene, "graveyard_kit/debris", (x, 0.0, z), rng.uniform(0, 360), 2.0)''',
     '''        lay(scene, "graveyard_kit/debris", (x, 0.0, z), rng.uniform(0, 360), 1.6)'''),
])

patch(writer, [
    # Les corbeaux du rempart sud se posent sur le mur visible (z de 42 à 44).
    ('''    ((-22.4, 5.24, 41.0), 160.0, False), ((13.4, 5.24, 41.1), 200.0, False), ((14.3, 5.24, 40.8), 120.0, False),''',
     '''    ((-22.4, 5.24, 43.0), 160.0, False), ((13.4, 5.24, 43.1), 200.0, False), ((14.3, 5.24, 42.8), 120.0, False),'''),
])

patch(scatter, [
    # Gravats sous la cheville (0,3 m au plus) : ils n'ont pas de collision et se traversent.
    ('''	_scatter(rubble_models, rubble_count, Vector2(1.5, 3.0), 0.0, false)''',
     '''	# Sans collision, les gravats restent sous la cheville (0,3 m au plus) : on marche dessus sans les traverser.
	_scatter(rubble_models, rubble_count, Vector2(0.45, 0.6), 0.0, false)'''),
])
print("ok")
