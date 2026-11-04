"""Collisions à la forme des objets (plaine_part.py) : boîtes orientées pour les objets couchés, emprises réduites
des épaves et des tas de pierres, hampes penchées, étoffes des bannières, épées, base de la tour."""
import re
from pathlib import Path

path = Path(__file__).with_name("plaine_part.py")
text = path.read_text(encoding="utf-8")


def swap(old, new, count=1):
    global text
    assert old in text, old[:90]
    text = text.replace(old, new, count)


# 1. Toutes les poses de meubles de la Plaine passent par furniture_fit.
text = re.sub(r"(?<![_\w])furniture\(scene,", "furniture_fit(scene,", text)

swap('''def facing(inward):''', '''def furniture_fit(scene, model, center, degrees=0.0, scale=2.6, height=None, tilt=0.0, roll=0.0, footprint=1.0):
    """Comme furniture(), mais la collision suit l'objet : une boîte tournée comme lui, à la taille de sa boîte une
    fois penché ou couché, et non la boîte droite qui englobe le tout (elle laissait des murs invisibles autour des
    objets couchés de biais). footprint réduit l'emprise des épaves et des tas, faits de pièces éparses."""
    furniture(scene, model, center, degrees, scale, tilt=tilt, roll=roll)
    if not height:
        return
    (px, py, pz), (sx, sy, sz) = MODEL_BOXES[model]
    basis = multiply(rotation_x(tilt), rotation_z(roll))
    corners = []
    for cx in (px, px + sx):
        for cy in (py, py + sy):
            for cz in (pz, pz + sz):
                local = (cx * scale, cy * scale, cz * scale)
                corners.append([sum(basis[r][i] * local[i] for i in range(3)) for r in range(3)])
    size = [max(c[i] for c in corners) - min(c[i] for c in corners) for i in range(3)]
    high = size[1] if (tilt or roll) else height
    scene.add_box((center[0], center[1] + high / 2, center[2]), (size[0] * footprint, high, size[2] * footprint), degrees)


def facing(inward):''')

# 2. Épaves, tas de pierres et rochers : emprise réduite à leur masse.
for model, ratio in (("siege-trebuchet-demolished", 0.65), ("siege-catapult-demolished", 0.65),
                     ("siege-ballista-demolished", 0.65), ("siege-ram-demolished", 0.7)):
    pattern = re.compile(r'(furniture_fit\(scene, "castle_kit/%s"[^\n]*?height=[\d.]+)\)' % model)
    text, count = pattern.subn(lambda m: m.group(1) + ", footprint=%s)" % ratio, text)
    assert count, model
swap('''        furniture_fit(scene, f"castle_kit/{model}", (position[0], 0.0, position[1]), degrees, scale_rock, height=0.9)''',
     '''        furniture_fit(scene, f"castle_kit/{model}", (position[0], 0.0, position[1]), degrees, scale_rock, height=0.9,
                      footprint=0.7)''')
swap('''        furniture_fit(scene, model, position, degrees, scale, height=MODEL_BOXES[model][1][1] * scale * 0.85)''',
     '''        furniture_fit(scene, model, position, degrees, scale, height=MODEL_BOXES[model][1][1] * scale * 0.85,
                      footprint=0.75)''')
swap('''                  scale * 2.0, height=0.55 * scale)''', '''                  scale * 2.0, height=0.55 * scale, footprint=0.85)''')

# 3. Planches à plat : moins de 30 cm, on les enjambe.
text = text.replace(''', degrees, 3.0, height=0.3)''', ''', degrees, 3.0)''')

# 4. Hampes : une boîte penchée comme elles ; bannières : l'étoffe a la sienne.
swap('''def leaning_box(scene, x, z, yaw, lean, length, thickness=0.3, top=2.2):
    """Collision d'une hampe plantée de biais : rotation_x(lean) penche +y vers +z local, que yaw tourne.
    La boîte couvre la hampe jusqu'à la hauteur top, au-delà de laquelle le joueur ne la touche plus."""
    up = min(math.cos(math.radians(lean)) * length, top)
    reach = math.tan(math.radians(lean)) * up
    c, s = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    scene.add_box((x + s * reach / 2, up / 2, z + c * reach / 2), (thickness, up, thickness + abs(reach)), yaw)''',
     '''def leaning_box(scene, x, z, yaw, lean, length, thickness=0.3, top=2.2, width=None, shift=0.0, start=0.0, y=0.0):
    """Collision d'une hampe plantée de biais : une boîte penchée comme elle (rotation_x(lean), puis yaw), le long de
    son axe, de start jusqu'à la hauteur top au-delà de laquelle le joueur ne la touche plus. width l'élargit à
    l'étoffe d'une bannière, décalée de shift sur l'axe z du modèle."""
    reach = min(length, top / max(math.cos(math.radians(lean)), 0.2)) - start
    if reach <= 0.0:
        return
    basis = multiply(rotation_y(yaw), rotation_x(lean))
    local = (0.0, start + reach / 2, shift)
    center = [sum(basis[r][i] * local[i] for i in range(3)) for r in range(3)]
    scene.add_tilted_box((x + center[0], y + center[1], z + center[2]), (thickness, reach, width or thickness), yaw, lean)''')

swap('''    stretch = rng.uniform(0.85, 1.0)
    scene.add(model, (x, -0.2, z), yaw, (scale, scale * stretch, scale), tilt=lean)
    leaning_box(scene, x, z, yaw, lean, MODEL_BOXES[model][1][1] * scale * stretch)''',
     '''    stretch = rng.uniform(0.85, 1.0)
    scene.add(model, (x, -0.2, z), yaw, (scale, scale * stretch, scale), tilt=lean)
    (_, _, pz), (_, sy, sz) = MODEL_BOXES[model]
    if model.endswith("pennant"):
        # Une hampe, et un fanion entre 0,57 et 0,73 de sa hauteur.
        leaning_box(scene, x, z, yaw, lean, sy * scale * stretch, y=-0.2)
        leaning_box(scene, x, z, yaw, lean, 0.73 * scale * stretch, width=0.5 * scale, shift=-0.24 * scale,
                    start=0.57 * scale * stretch, y=-0.2)
    else:
        # Panneau ou étoffe tendue sur toute la hauteur.
        leaning_box(scene, x, z, yaw, lean, sy * scale * stretch, thickness=0.25, width=sz * scale,
                    shift=(pz + sz / 2) * scale, y=-0.2)''')

swap('''    scene.add("mini_dungeon/weapon-spear", (x, -0.3, z), yaw, scale, tilt=lean)
    leaning_box(scene, x, z, yaw, lean, 0.6 * scale - 0.3)''', '''    scene.add("mini_dungeon/weapon-spear", (x, -0.3, z), yaw, scale, tilt=lean)
    leaning_box(scene, x, z, yaw, lean, 0.6 * scale, thickness=0.25, y=-0.3)''')

# 5. Épée plantée : la garde dépasse de la lame.
swap('''    scene.add("mini_dungeon/weapon-sword", (x, 0.1 * scale - 0.25, z), rng.uniform(0, 360), scale,
              tilt=rng.uniform(-14, 14), roll=rng.uniform(-10, 10))
    scene.add_box((x, 0.6, z), (0.3, 1.2, 0.3))''', '''    yaw = rng.uniform(0, 360)
    scene.add("mini_dungeon/weapon-sword", (x, 0.1 * scale - 0.25, z), yaw, scale,
              tilt=rng.uniform(-14, 14), roll=rng.uniform(-10, 10))
    scene.add_box((x, 0.65, z), (0.25 * scale, 1.3, 0.14 * scale), yaw)''')

# 6. Base de la tour : sa plinthe déborde un peu de sa boîte.
swap('''    scene.add_box((bx, 1.01 * scale, bz), (3.3, 2.02 * scale, 3.3), 8.0)''',
     '''    scene.add_box((bx, 1.01 * scale, bz), (3.45, 2.02 * scale, 3.45), 8.0)''')

path.write_text(text, encoding="utf-8", newline="\n")
print("ok")
