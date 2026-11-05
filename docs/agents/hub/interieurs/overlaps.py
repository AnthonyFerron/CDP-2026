"""Chevauchements dans les intérieurs du hub : meuble contre mur, meuble contre meuble, porte encombrée.
Rejoue build_hub sans rien écrire. Usage : overlaps.py [bâtiments...]"""
import math
import sys

sys.path.insert(0, "/home/ubuntu/cdp-dev/.claude/worktrees/hub/frontend/tools")
import build_hub as bh
import build_plaine as bp

ITEMS = []   # (groupe, modèle, polygone xz, ymin, ymax, centre)
WALLS = []   # (groupe, polygone xz, ymin, ymax, modèle)
SCENE = [None]
_furniture = bh.furniture
_wall = bh.wall
_doorway = bh.doorway


def rect(cx, cz, sx, sz, degrees=0.0):
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
    pts = []
    for du, dv in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
        x, z = du * sx / 2, dv * sz / 2
        pts.append((cx + c * x + s * z, cz - s * x + c * z))
    return pts


def hull(points):
    points = sorted(set((round(x, 4), round(z, 4)) for x, z in points))
    if len(points) < 3:
        return points
    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lower, upper = [], []
    for p in points:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(points):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def shrink(poly, margin):
    cx = sum(p[0] for p in poly) / len(poly)
    cz = sum(p[1] for p in poly) / len(poly)
    out = []
    for x, z in poly:
        dx, dz = x - cx, z - cz
        d = math.hypot(dx, dz) or 1.0
        k = max(d - margin, 0.01) / d
        out.append((cx + dx * k, cz + dz * k))
    return out


def separated(a, b):
    for poly in (a, b):
        for i in range(len(poly)):
            x1, z1 = poly[i]
            x2, z2 = poly[(i + 1) % len(poly)]
            nx, nz = z2 - z1, x1 - x2
            pa = [nx * x + nz * z for x, z in a]
            pb = [nx * x + nz * z for x, z in b]
            if max(pa) <= min(pb) or max(pb) <= min(pa):
                return True
    return False


def furniture(scene, model, center, degrees=0.0, scale=2.6, height=None, tilt=0.0, roll=0.0):
    real = bp.MEDIEVAL.get(model, model)
    (px, py, pz), (sx, sy, sz) = bp.MODEL_BOXES[real]
    sc = scale if isinstance(scale, tuple) else (scale, scale, scale)
    basis = bp.multiply(bp.multiply(bp.rotation_y(degrees), bp.rotation_x(tilt)), bp.rotation_z(roll))
    corners = []
    for cx in (px, px + sx):
        for cy in (py, py + sy):
            for cz in (pz, pz + sz):
                local = (cx * sc[0], cy * sc[1], cz * sc[2])
                corners.append([sum(basis[r][i] * local[i] for i in range(3)) for r in range(3)])
    low = [min(c[i] for c in corners) for i in range(3)]
    high = [max(c[i] for c in corners) for i in range(3)]
    mx, mz = (low[0] + high[0]) / 2, (low[2] + high[2]) / 2
    poly = hull([(center[0] + c[0] - mx, center[2] + c[2] - mz) for c in corners])
    ITEMS.append((scene.group, real, poly, center[1], center[1] + high[1] - low[1], (center[0], center[2])))
    return _furniture(scene, model, center, degrees, scale, height, tilt, roll)


def wall(scene, kit_model, center, outward, height=bp.WALL_HEIGHT, base=0.0, solid=True):
    x, z = center
    if base < 1.0:
        size = (0.5, bp.WALL_SCALE) if outward[0] else (bp.WALL_SCALE, 0.5)
        WALLS.append((scene.group, rect(x, z, *size), base, base + height, kit_model))
    return _wall(scene, kit_model, center, outward, height=height, base=base, solid=solid)


bh.furniture = furniture
bh.wall = wall


def main(names):
    rng = __import__("random").Random(5814)
    scene = bh.StagedScene("HubProps")
    bh.build_camp(scene)
    bh.build_village(scene, rng)
    bh.build_castle(scene, rng)
    bh.build_bunker(scene, rng)
    bh.build_landmarks(scene, rng)
    bh.build_mine(scene, rng)
    bh.build_bridges(scene, rng)
    bh.build_quarters(scene, __import__("random").Random(5820))
    problems = []
    groups = sorted(set(i[0] for i in ITEMS if i[0].startswith("Repairs/")))
    for group in groups:
        name = group.split("/")[1]
        if names and name not in names:
            continue
        items = [i for i in ITEMS if i[0] == group]
        walls = [w for w in WALLS if w[0] == group]
        for item in items:
            # Accrochés au mur : boucliers et bannières touchent sa face visible, dans la collision.
            if any(word in item[1] for word in ("shield", "banner")) and item[3] > 1.0:
                continue
            core = shrink(item[2], 0.04)
            for w in walls:
                if item[3] < w[3] - 0.05 and item[4] > w[2] + 0.05 and not separated(core, w[1]):
                    problems.append(f"{group}: {item[1]} ({item[5][0]:.2f}, {item[5][1]:.2f}) dans le mur {w[4]}")
                    break
        for i, a in enumerate(items):
            for b in items[i + 1:]:
                # Posé dessus : les hauteurs se touchent sans se croiser.
                if a[3] >= b[4] - 0.03 or b[3] >= a[4] - 0.03:
                    continue
                if not separated(shrink(a[2], 0.03), shrink(b[2], 0.03)):
                    problems.append(f"{group}: {a[1]} ({a[5][0]:.2f}, {a[5][1]:.2f}) touche {b[1]} ({b[5][0]:.2f}, {b[5][1]:.2f})")
    print("\n".join(problems) if problems else "aucun chevauchement")
    print(len(problems), "problèmes")


main(sys.argv[1:])
