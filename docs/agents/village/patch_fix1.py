"""Corrige les chevauchements signalés par le contrôle du décor du Village."""
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")


def sub(old, new, count=1):
    global text
    assert text.count(old) == count, (old, text.count(old))
    text = text.replace(old, new)


# Mairie : étagères et tonneau à l'écart des murs.
sub('''    for x in (-3.0, -1.6):
        hp(scene, "furniture_kit/bookcaseOpen", (x, 0.0, -5.4), 0.0, 3.2, label="étagère")
        shelf_books(scene, rng, (x, 0.0, -5.4), 0.0, (0.06, 0.98, 1.9), 1.1)''', '''    for x in (-3.0, -1.6):
        hp(scene, "furniture_kit/bookcaseOpen", (x, 0.0, -5.28), 0.0, 3.2, label="étagère")
        shelf_books(scene, rng, (x, 0.0, -5.28), 0.0, (0.06, 0.98, 1.9), 1.1)''')
sub('''    hp(scene, "mini_dungeon/barrel", (-4.9, 0.0, 5.2), 0.0, 2.6, label="tonneau")''',
    '''    hp(scene, "mini_dungeon/barrel", (-4.9, 0.0, 5.0), 0.0, 2.6, label="tonneau")''')
sub('''    hp(scene, "furniture_kit/bookcaseOpen", (-5.0, office, 5.4), 180.0, 3.2, label="étagère du maire")
    shelf_books(scene, rng, (-5.0, office, 5.4), 180.0, (0.06, 0.98, 1.9), 1.1)''', '''    hp(scene, "furniture_kit/bookcaseOpen", (-5.0, office, 5.28), 180.0, 3.2, label="étagère du maire")
    shelf_books(scene, rng, (-5.0, office, 5.28), 180.0, (0.06, 0.98, 1.9), 1.1)''')
# Brèche et meule du moulin à l'écart du rempart.
sub('''(31.2, -4.2, 250.0, 1.4)):''', '''(30.8, -4.4, 250.0, 1.4)):''')
sub('''    cylinder(scene, "stone", (31.6, 4.2, -27.4), 0.8, 0.35, tilt=0.0, sides=14)
    post(scene, 31.6, -27.4, 0.8, 0.4, y=4.0, label="meule")''', '''    cylinder(scene, "stone", (31.0, 4.2, -26.9), 0.8, 0.35, sides=14)
    post(scene, 31.0, -26.9, 0.8, 0.4, y=4.0, label="meule")''')
# La charrette renversée de la place libère la rue du pont ; la lanterne fauchée s'écarte.
sub('''    place(scene, "fantasy_town_kit/cart", (-7.5, 0.0, 4.5), 60.0, 3.0, height=2.0, roll=90.0, label="charrette renversée")
    place(scene, "fantasy_town_kit/wheel", (-5.0, 0.0, 6.5), 30.0, 3.0, height=0.7, tilt=90.0, label="roue")''',
    '''    place(scene, "fantasy_town_kit/cart", (-7.9, 0.0, 2.5), 60.0, 3.0, height=2.0, roll=90.0, label="charrette renversée")
    place(scene, "fantasy_town_kit/wheel", (-5.2, 0.0, 3.4), 30.0, 3.0, height=0.7, tilt=90.0, label="roue")''')
sub('''    place(scene, "fantasy_town_kit/lantern", (-10.0, 0.0, 1.4), 100.0, 2.2, height=0.5, tilt=90.0, label="lanterne couchée")''',
    '''    place(scene, "fantasy_town_kit/lantern", (-11.9, 0.0, 2.9), 100.0, 2.2, height=0.5, tilt=90.0, label="lanterne couchée")''')
sub('''    place(scene, "survival_kit/box-large-open", (10.4, 0.0, -6.9), 70.0, 2.6, height=0.8, label="caisse de carottes")''',
    '''    place(scene, "survival_kit/box-large-open", (10.0, 0.0, -8.3), 70.0, 2.6, height=0.8, label="caisse de carottes")''')
sub('''    LAYOUT.keep_clear("grande rue", -2.2, 2.2, 9.0, 62.0)
    LAYOUT.keep_clear("grande rue, au nord de la place", -2.2, 2.2, -19.5, -12.5)''', '''    LAYOUT.keep_clear("grande rue", -2.0, 2.0, 9.0, 62.0)
    LAYOUT.keep_clear("grande rue, au nord de la place", -2.0, 2.0, -19.5, -12.5)''')
# Les meubles adossés restent à 0,9 m de la ligne du mur : un pan effondré y laisse un tas de pierres.
sub('''        return s * (self.side - 0.4 - deep / 2), 90.0 * s''', '''        return s * (self.side - 0.9 - deep / 2), 90.0 * s''')
sub('''        return -(self.depth - 0.4 - deep / 2)''', '''        return -(self.depth - 0.9 - deep / 2)''')
# Auberge : le foyer dans le coin du fond, les tables au milieu, les tonneaux espacés.
sub('''    for a, b, local in ((far * 2.0, -1.4, 90.0), (-far * 0.6, -1.9, 0.0)):''', '''    for a, b, local in ((far * 1.3, -0.2, 90.0), (-far * 0.7, -2.3, 0.0)):''')
sub('''    fp(scene, frame, "mini_dungeon/table", -far * 0.3, 0.9, 15.0, 2.2, height=0.7, roll=90.0, label="table renversée")
    for a, b, local in ((far * 0.9, -1.4, 90.0), (-far * 0.6, -0.8, 180.0), (far * 2.0, 0.1, 0.0)):''', '''    fp(scene, frame, "mini_dungeon/table", -far * 0.4, 1.5, 15.0, 2.2, height=0.7, roll=90.0, label="table renversée")
    for a, b, local in ((far * 0.1, -0.2, 90.0), (-far * 0.7, -1.2, 180.0), (far * 2.6, 0.2, -90.0)):''')
sub('''    fp(scene, frame, "mini_dungeon/chair", -far * 1.7, 0.2, 40.0, 2.0, height=0.5, tilt=90.0, label="tabouret couché")''',
    '''    fp(scene, frame, "mini_dungeon/chair", far * 1.6, 1.7, 40.0, 2.0, height=0.5, tilt=90.0, label="tabouret couché")''')
sub('''    for b in (-2.7, -1.75):
        fp(scene, frame, "food_kit/barrel", a, b, local, 1.35, height=0.92, label="tonneau en perce")
    fp(scene, frame, "food_kit/barrel", a, 0.2, local, 1.35, height=0.9, roll=90.0, label="tonneau couché")
    fl(scene, frame, "nature_kit/campfire_stones", far * 2.4, -2.6, 0.0, 2.2, y=FLOOR)
    fp(scene, frame, "mini_dungeon/pot", far * 2.4, -2.6, 20.0, 1.4, height=0.6, y=FLOOR, label="marmite")''', '''    for b in (-2.5, -1.3):
        fp(scene, frame, "food_kit/barrel", a, b, local, 1.35, height=0.92, label="tonneau en perce")
    fp(scene, frame, "food_kit/barrel", a, 0.3, local, 1.35, height=0.9, roll=90.0, label="tonneau couché")
    fl(scene, frame, "nature_kit/campfire_stones", far * 2.3, -2.4, 0.0, 2.2, y=FLOOR)
    fp(scene, frame, "mini_dungeon/pot", far * 2.3, -2.4, 20.0, 1.4, height=0.6, y=FLOOR, label="marmite")''')
# Tonnellerie : des tonneaux qui ne se traversent pas.
sub('''    for a, b in ((far * 2.6, -2.6), (far * 1.6, -2.7), (far * 2.7, -1.6)):
        fp(scene, frame, "mini_dungeon/barrel", a, b, rng.uniform(0, 360), 1.8, height=0.86, label="tonneau")
    fp(scene, frame, "mini_dungeon/barrel", far * 2.15, -2.15, 0.0, 1.5, height=0.72, y=0.86, label="tonneau empilé")''', '''    for a, b in ((far * 2.4, -2.4), (far * 1.35, -2.45), (far * 2.45, -1.35)):
        fp(scene, frame, "mini_dungeon/barrel", a, b, rng.uniform(0, 360), 1.8, height=0.86, label="tonneau")
    fp(scene, frame, "mini_dungeon/barrel", far * 2.0, -2.0, 0.0, 1.5, height=0.72, y=0.86, label="tonneau empilé")''')
# Potager : les derniers pans de clôture ne se chevauchent plus.
sub('''    for z in (21.7, 23.7, 25.7, 27.7, 29.4):
        place(scene, fence, (-31.7, 0.0, z), 90.0, 2.0 if z != 29.4 else (1.6, 2.0, 2.0), height=0.7, label="clôture")
        if z in (23.7, 25.7):
            continue
        place(scene, fence, (-23.5, 0.0, z), 90.0, 2.0 if z != 29.4 else (1.6, 2.0, 2.0), height=0.7, label="clôture")''', '''    for z in (21.7, 23.7, 25.7, 27.7, 29.55):
        place(scene, fence, (-31.7, 0.0, z), 90.0, 2.0 if z != 29.55 else (1.5, 2.0, 2.0), height=0.7, label="clôture")
        if z in (23.7, 25.7):
            continue
        place(scene, fence, (-23.5, 0.0, z), 90.0, 2.0 if z != 29.55 else (1.5, 2.0, 2.0), height=0.7, label="clôture")''')
sub('''    place(scene, "nature_kit/log_stack", (-22.2, 0.0, -25.0), 90.0, 2.6, height=0.9, label="tas de bois")
    place(scene, "nature_kit/log_stack", (-20.4, 0.0, -25.2), 85.0, 2.6, height=0.9, label="tas de bois")''', '''    place(scene, "nature_kit/log_stack", (-22.5, 0.0, -25.0), 90.0, 2.6, height=0.9, label="tas de bois")
    place(scene, "nature_kit/log_stack", (-20.3, 0.0, -25.2), 90.0, 2.6, height=0.9, label="tas de bois")''')
# Écuries : la travée effondrée ne prend plus les poteaux, les cloisons s'arrêtent avant le mur du fond.
sub('''    box(scene, "char", (21.7, 2.1, 33.0), (5.2, 0.14, 6.0), roll=42.0)
    block(scene, (20.6, 0.6, 33.0), (2.2, 1.2, 5.8), label="toit effondré")
    for z in (31.0, 34.5):
        charred_beam(scene, (19.0, 0.15, z), 2.4, 70.0)''', '''    box(scene, "char", (21.7, 2.1, 34.0), (5.2, 0.14, 3.5), roll=42.0)
    block(scene, (20.6, 0.6, 34.0), (2.2, 1.2, 3.3), label="toit effondré")
    for z in (30.6, 33.0):
        charred_beam(scene, (18.0, 0.15, z), 2.4, 70.0)''')
sub('''        scene.add("nature_kit/fence_planks", (26.4, 0.0, z + 0.48), 0.0, (3.2, 3.6, 2.0))
        block(scene, (26.4, 0.65, z), (3.2, 1.3, 0.25), label="cloison de stalle")''', '''        scene.add("nature_kit/fence_planks", (26.25, 0.0, z + 0.48), 0.0, (2.9, 3.6, 2.0))
        block(scene, (26.25, 0.65, z), (2.9, 1.3, 0.25), label="cloison de stalle")''')
sub('''    for z in (18.8, 22.8):
        place(scene, fence, (18.0, 0.0, z), 90.0, 2.4 if z != 22.8 else (1.8, 2.4, 2.4), height=0.84, label="clôture de l'enclos")
        place(scene, fence, (30.0, 0.0, z), 90.0, 2.4 if z != 22.8 else (1.8, 2.4, 2.4), height=0.84, label="clôture de l'enclos")''', '''    for z in (19.0, 22.9):
        place(scene, fence, (18.0, 0.0, z), 90.0, 2.4 if z != 22.9 else (1.6, 2.4, 2.4), height=0.84, label="clôture de l'enclos")
        place(scene, fence, (30.0, 0.0, z), 90.0, 2.4 if z != 22.9 else (1.6, 2.4, 2.4), height=0.84, label="clôture de l'enclos")''')
# Les murs qui bordent une ruelle devant une porte ne sont pas des objets posés sur le passage.
sub('''            for zone, zone_corners, zy0, zy1 in self.clear:
                if y1 <= zy0 or y0 >= zy1:''', '''            for zone, zone_corners, zy0, zy1 in self.clear:
                if structure or y1 <= zy0 or y0 >= zy1:''')
path.write_text(text, encoding="utf-8")
print("ok")
