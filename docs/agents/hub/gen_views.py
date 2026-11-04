"""Points de vue de la grille de captures du hub, en JSON : python gen_views.py <dossier tools> <sortie.json>
Chaque vue : nom, œil, cible, livres posés, intérieur (bunker)."""
import json
import math
import random
import sys

sys.path.insert(0, sys.argv[1])
import build_hub as bh  # noqa: E402

views = []


def view(group, name, eye, target, books, inside=False):
    views.append({"group": group, "name": name, "eye": list(eye), "target": list(target), "books": books, "inside": inside})


# Bâtiments : deux coins opposés à hauteur d'yeux, et une vue vers le haut (plafond, toit vu de dessous).
buildings = [(f"House{i:02d}", h) for i, h in enumerate(bh.house_layout(random.Random(5814)))]
buildings += [(name, house) for name, house, _, _ in bh.LANDMARKS] + [(name, house) for name, house, _, _ in bh.QUARTERS]
for books in (0, 4):
    for name, (cx, cz, width, depth, door, style, floors) in buildings:
        hw, hd = width * 2 - 0.9, depth * 2 - 0.9
        for sx, sz, tag in ((1, 1, "a"), (-1, -1, "b")):
            view(f"maisons_{books}", f"{name}_{tag}", (cx + sx * hw, 1.65, cz + sz * hd), (cx - sx * hw, 1.0, cz - sz * hd), books)
        if books == 4:
            view("plafonds", f"{name}_haut", (cx + 0.3, 1.65, cz + 0.2), (cx + 0.31, 6.0, cz + 0.21), books)

# Chemins et ruelles : tous les 12 m, dans le sens du chemin et en sens inverse.
roads = [[(0.0, 0.0), target] for target in bh.ROADS]
for books in (0, 4):
    index = 0
    for road in roads:
        (ax, az), (bx, bz) = road
        length = math.hypot(bx - ax, bz - az)
        steps = max(int(length / 12), 1)
        for step in range(1, steps + 1):
            t = step / (steps + 1)
            x, z = ax + (bx - ax) * t, az + (bz - az) * t
            dx, dz = (bx - ax) / length, (bz - az) / length
            view(f"chemins_{books}", f"route{index:03d}", (x, 1.65, z), (x + dx * 10, 1.2, z + dz * 10), books)
            view(f"chemins_{books}", f"route{index:03d}r", (x, 1.65, z), (x - dx * 10, 1.2, z - dz * 10), books)
            index += 1

# Château : cour, enceinte vue de dedans et de dehors, salle du trône (coins, trône, plafond).
for books in (0, 2, 4):
    for name, eye, target in (
        ("porte", (0, 1.65, -44), (0, 3, -60)), ("cour_ouest", (-17, 1.65, -57), (5, 2, -66)), ("cour_est", (17, 1.65, -57), (-5, 2, -66)),
        ("couloir_ouest", (-18, 1.65, -66), (-18, 2, -88)), ("couloir_est", (18, 1.65, -66), (18, 2, -88)),
        ("donjon_porte", (0, 1.65, -68), (0, 3, -73)), ("enceinte_ouest_dehors", (-34, 1.65, -72), (-25, 3, -72)),
        ("enceinte_est_dehors", (32, 1.65, -72), (25, 3, -72)), ("enceinte_nord_dehors", (8, 1.65, -100), (8, 3, -93)),
        ("salle_entree", (0, 1.65, -76), (0, 2, -86)), ("salle_coin_ouest", (-9, 1.65, -76), (6, 1, -86)),
        ("salle_coin_est", (9, 1.65, -86), (-6, 1, -76)), ("salle_plafond", (0, 1.65, -81), (0.01, 9, -81.01)),
        ("cercle", (-6, 5.5, -78), (0, 0, -82)), ("trone", (0, 1.65, -80), (0, 2, -87)),
    ):
        view(f"chateau_{books}", name, eye, target, books)

# Rivière : le long des deux berges, regardant vers l'aval puis l'amont ; abords des ponts.
samples = []
river = [(51.0, -127.0), (53.0, -115.0), (55.0, -104.0), (58.0, -92.0), (62.0, -78.0), (63.0, -66.0), (61.0, -52.0), (60.0, -38.0),
         (61.0, -24.0), (62.0, -12.0), (63.4, 0.0), (65.0, 10.0), (68.0, 20.0), (71.0, 32.0), (74.0, 42.0), (73.6, 48.0), (77.0, 56.0),
         (85.0, 70.0), (95.0, 84.0)]
for books in (0, 4):
    for index in range(3, len(river) - 1):
        (ax, az), (bx, bz) = river[index], river[index + 1]
        dx, dz = bx - ax, bz - az
        length = math.hypot(dx, dz)
        nx, nz = -dz / length, dx / length
        for side, tag in ((1, "g"), (-1, "d")):
            eye = (ax + nx * side * 7.5, 1.65, az + nz * side * 7.5)
            view(f"riviere_{books}", f"berge{index:02d}{tag}", eye, (ax + dx * 0.8, -1.0, az + dz * 0.8), books)
    for bx, bz, _, length, width in bh.BRIDGES:
        for end in (-1, 1):
            for side in (-1, 1):
                eye = (bx + end * (length / 2 + 2), 1.65, bz + side * (width / 2 + 2.5))
                view(f"ponts_{books}", f"pont{int(bz)}_{end}_{side}", eye, (bx + end * (length / 2 - 2), -0.8, bz), books)
        view(f"ponts_{books}", f"pont{int(bz)}_dessus", (bx - length / 2 + 1, 1.65, bz), (bx + length / 2, 1.0, bz), books)
        view(f"ponts_{books}", f"pont{int(bz)}_dessous", (bx, -0.6, bz + width / 2 + 5), (bx, -0.5, bz), books)

# Jardin du roi, quartiers extérieurs.
for books in (0, 1, 2, 3, 4):
    for name, eye, target in (
        ("jardin_entree", (31, 1.65, -50), (42, 1, -70)), ("jardin_statue", (42, 1.65, -63), (42, 2, -70)),
        ("jardin_kiosque", (40, 1.65, -77), (36, 1.5, -82)), ("jardin_etang", (42, 1.65, -80), (48, -0.5, -84.5)),
        ("jardin_rois", (42, 1.65, -53), (42, 1.5, -62)), ("jardin_est", (50, 1.65, -55), (35, 1, -85)),
        ("moulin", (54, 1.65, 54), (70.5, 1, 48)), ("lavoir", (50, 1.65, 1), (55, 1, 7)), ("boulangerie", (44, 1.65, 32), (52, 1.5, 34)),
        ("ecuries", (-58, 1.65, -40), (-68, 1.5, -46)), ("caserne", (-40, 1.65, -56), (-48, 1.5, -66)),
        ("herboristerie", (-50, 1.65, 28), (-60, 1.5, 30)), ("scriptorium", (-64, 1.65, -10), (-74, 1.5, -16)),
        ("observatoire", (-62, 1.65, 50), (-70, 4, 58)), ("halle", (-24, 1.65, 58), (-24, 1.5, 66)), ("verger", (12, 1.65, 70), (14, 1.5, 82)),
        ("mine", (72, 1.65, -28), (86, 2, -42)), ("bunker_dehors", (64, 1.65, 6), (78, 2, 0)), ("forge", (46, 1.65, 18), (55, 1.5, 18)),
        ("ferme", (44, 1.65, 52), (50, 1, 64)),
    ):
        view(f"lieux_{books}", name, eye, target, books)

# Bunker, intérieur : coins et plafond.
for name, eye, target in (("coin_no", (-9, 1.65, -5), (8, 1, 4)), ("coin_ne", (9, 1.65, -5), (-8, 1, 4)), ("coin_so", (-9, 1.65, 5), (8, 1, -4)),
                          ("coin_se", (9, 1.65, 5), (-8, 1, -4)), ("plafond", (0, 1.65, 0), (0.01, 5, 0.01)), ("porte", (0, 1.65, -2), (0, 1.5, 6))):
    view("bunker", name, (78 + eye[0], -40 + eye[1], eye[2]), (78 + target[0], -40 + target[1], target[2]), 0, True)

# Pied du volcan et montagnes, depuis la vallée.
for name, eye, target in (("nord", (0, 1.65, -40), (20, 10, -215)), ("nord_est", (60, 1.65, -90), (52, 6, -125)),
                          ("est", (100, 1.65, 0), (140, 10, 0)), ("sud_est", (88, 1.65, 80), (115, 6, 100)), ("sud", (0, 1.65, 95), (0, 10, 140)),
                          ("ouest", (-95, 1.65, 0), (-140, 10, 0)), ("nord_ouest", (-70, 1.65, -70), (-110, 10, -110)),
                          ("volcan_haut", (0, 40, -60), (20, 30, -215))):
    for books in (0, 4):
        view(f"montagnes_{books}", name, eye, target, books)

json.dump(views, open(sys.argv[2], "w", encoding="utf-8"), indent=0)
groups = {}
for v in views:
    groups[v["group"]] = groups.get(v["group"], 0) + 1
print(len(views), groups)
