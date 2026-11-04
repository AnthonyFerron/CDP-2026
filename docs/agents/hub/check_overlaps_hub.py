"""Rejoue les générateurs du décor et liste les objets dont l'emprise au sol entre dans un mur ou dans une maison.

Chaque mur posé par wall() ou doorway() donne un segment épais ; chaque meuble posé par furniture() donne un
rectangle (boîte de son modèle tournée). Un meuble qui chevauche un mur, ou un objet de place (fontaine, étal)
qui entre dans l'emprise d'une maison, est signalé.
"""
import math
import random
import sys

sys.path.insert(0, sys.argv[1])
import build_plaine as bp

WALLS = []      # (xmin, xmax, zmin, zmax, ymin, ymax, scène)
ITEMS = []      # (nom, xmin, xmax, zmin, zmax, ymin, ymax, scène)
CURRENT = ["?"]

_wall = bp.wall
_furniture = bp.furniture


def wall(scene, kit_model, center, outward, height=bp.WALL_HEIGHT, base=0.0, solid=True):
    x, z = center
    half = bp.WALL_SCALE / 2
    thick = 0.2
    if outward[0]:
        WALLS.append((x - thick, x + thick, z - half, z + half, base, base + height, CURRENT[0], kit_model))
    else:
        WALLS.append((x - half, x + half, z - thick, z + thick, base, base + height, CURRENT[0], kit_model))
    return _wall(scene, kit_model, center, outward, height=height, base=base, solid=solid)


def furniture(scene, model, center, degrees=0.0, scale=2.6, height=None, tilt=0.0, roll=0.0):
    asked = model
    model = bp.MEDIEVAL.get(model, model)
    (px, py, pz), (sx, sy, sz) = bp.MODEL_BOXES[model]
    axes = scale if isinstance(scale, tuple) else (scale, scale, scale)
    basis = bp.multiply(bp.multiply(bp.rotation_y(degrees), bp.rotation_x(tilt)), bp.rotation_z(roll))
    corners = []
    for cx in (px, px + sx):
        for cy in (py, py + sy):
            for cz in (pz, pz + sz):
                local = (cx * axes[0], cy * axes[1], cz * axes[2])
                corners.append([sum(basis[r][i] * local[i] for i in range(3)) for r in range(3)])
    low = [min(c[i] for c in corners) for i in range(3)]
    high = [max(c[i] for c in corners) for i in range(3)]
    w, h, d = (high[i] - low[i] for i in range(3))
    ITEMS.append((model, center[0] - w / 2, center[0] + w / 2, center[2] - d / 2, center[2] + d / 2,
                  center[1], center[1] + h, CURRENT[0], getattr(scene, "group", "")))
    # Le meuble demandé, et non son remplaçant : build_hub.py applique lui-même ses règles (MEDIEVAL, hauteur).
    return _hub_furniture(scene, asked, center, degrees, scale, height, tilt, roll)


bp.wall = wall
import build_hub as _bh
_hub_furniture = _bh.furniture
bp.furniture = furniture
for name in ("build_hub",):
    module = __import__(name)
    module.wall = wall
    module.furniture = furniture
    if hasattr(module, "doorway"):
        pass

import build_hub as bh
import tempfile
from pathlib import Path as _Path

# Le contrôle rejoue les générateurs sans rien écrire dans la worktree : leurs sorties vont dans un dossier jetable.
_SINK = _Path(tempfile.mkdtemp())
bh.OUTPUT = _SINK / "hub_props.tscn"
bh.BUNKER_OUTPUT = _SINK / "hub_bunker.tscn"

# Les portes passent par doorway(), qui appelle bp.wall : déjà compté.
results = []


def overlap(a, b, margin=0.08):
    return (a[0] < b[1] - margin and a[1] > b[0] + margin and a[2] < b[3] - margin and a[3] > b[2] + margin
            and a[4] < b[5] - 0.05 and a[5] > b[4] + 0.05)


def run(label, builder):
    CURRENT[0] = label
    start_w, start_i = len(WALLS), len(ITEMS)
    builder()
    walls = WALLS[start_w:]
    items = ITEMS[start_i:]
    for item in items:
        box = item[1:7]
        for w in walls:
            if overlap(box, w[:6]):
                results.append(f"{label}: {item[0]} ({(box[0]+box[1])/2:.1f}, {(box[2]+box[3])/2:.1f}) traverse {w[7]} "
                               f"({(w[0]+w[1])/2:.1f}, {(w[2]+w[3])/2:.1f})")
                break


def hub():
    rng = random.Random(5814)
    scene = bh.StagedScene("HubProps")
    bh.build_camp(scene)
    bh.build_village(scene, rng)
    bh.build_castle(scene, rng)
    bh.build_bunker(scene, rng)
    bh.build_landmarks(scene, rng)
    bh.build_mine(scene, rng)
    bh.build_bridges(scene, rng)
    bh.build_quarters(scene, random.Random(5820))
    bh.build_park(scene, random.Random(5821))
    bh.build_quarter_paths(scene)
    # Emprise de chaque bâtiment public : ni sur une maison, ni sur le château, un portail, la fontaine ou un chemin.
    houses = bh.house_layout(random.Random(5814))
    def seg(px, pz, ax, az):
        t = max(0.0, min(1.0, (px * ax + pz * az) / (ax * ax + az * az)))
        return math.hypot(px - ax * t, pz - az * t)
    for name, (cx, cz, wd, dp, *_), _, _ in bh.LANDMARKS:
        hw, hd = wd * bh.TILE / 2 + 1.0, dp * bh.TILE / 2 + 1.0
        for hx, hz, hwd, hdp, *_ in houses:
            if abs(cx - hx) < hw + hwd * 2 and abs(cz - hz) < hd + hdp * 2:
                results.append(f"hub: {name} touche la maison ({hx}, {hz})")
        if -25 - hw < cx < 25 + hw and -95 - hd < cz < -50 + hd:
            results.append(f"hub: {name} entre dans le château")
        for px, pz in ((-38, -38), (38, -38), (38, 38), (-38, 38), (30.0, 4.2), (78.0, 0.0)):
            if abs(cx - px) < hw + 5 and abs(cz - pz) < hd + 5:
                results.append(f"hub: {name} trop près de ({px}, {pz})")
        corners = [(cx + sx * hw, cz + sz * hd) for sx in (-1, 0, 1) for sz in (-1, 0, 1)]
        for ax, az in bh.ROADS:
            end_x, end_z = ax, az
            if min(seg(x, z, end_x, end_z) for x, z in corners) < 1.8 and (end_x, end_z) not in ((0.0, 55.0), (-53.0, 0.0)):
                results.append(f"hub: {name} sur le chemin vers ({ax}, {az})")
    # Emprises des maisons : un objet de place qui y entre est mal placé.
    for cx, cz, wd, dp, *_ in bh.house_layout(random.Random(5814)):
        hw, hd = wd * bh.TILE / 2, dp * bh.TILE / 2
        for name, x, z, r in (("fontaine", 30.0, 4.2, 2.9), ("étal rouge", -15.0, -4.0, 1.6), ("étal vert", -15.0, 4.0, 1.6),
                              ("étal", 15.0, -10.0, 1.6), ("charrette", -13.0, -4.0, 2.0)):
            if abs(x - cx) < hw + r and abs(z - cz) < hd + r:
                results.append(f"hub: {name} ({x}, {z}) entre dans la maison ({cx}, {cz})")


run("hub", hub)

# Meubles qui se chevauchent dans un même groupe (une pièce, en ruine ou reconstruite) : les tapis et les objets
# plats (moins de 6 cm) passent sous les autres, et un objet posé sur un meuble ne le touche que par sa base.
by_group = {}
for item in ITEMS:
    if item[8].startswith("Repairs/") and not any(word in item[0] for word in ("rug", "planks", "crops_", "crop_", "flower")):
        by_group.setdefault(item[8], []).append(item)
for group, items in by_group.items():
    for index, a in enumerate(items):
        for b in items[index + 1:]:
            if a[6] - a[5] < 0.06 or b[6] - b[5] < 0.06:
                continue
            # Posé sur un autre meuble (pain sur l'étagère, sac sur la charrette, fiole sur le rayon) : sa base est
            # nettement plus haute. L'échelle du verger est appuyée contre son arbre.
            if abs(a[5] - b[5]) > 0.3 or ("ladder" in a[0] + b[0] and "tree" in a[0] + b[0]):
                continue
            if overlap(a[1:7], b[1:7], margin=0.05):
                results.append(f"{group}: {a[0]} ({(a[1]+a[2])/2:.1f}, {(a[3]+a[4])/2:.1f}) chevauche {b[0]} "
                               f"({(b[1]+b[2])/2:.1f}, {(b[3]+b[4])/2:.1f})")
run("abri", bh.build_shelter)
print("\n".join(results) if results else "aucun chevauchement")
print(len(ITEMS), "meubles contrôlés,", len(WALLS), "murs")
