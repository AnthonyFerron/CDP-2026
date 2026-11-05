"""Plans des intérieurs du hub, sans Godot : collisions (gris), emprises des meubles (contours), cases où le joueur
(rayon 0,4 m) tient et qu'il atteint depuis le dehors de la porte (vert), cases libres qu'il n'atteint pas (orange).
Usage : plan.py <dossier de sortie> <livres 0|4> [bâtiments...]"""
import math
import struct
import sys
import zlib

sys.path.insert(0, "/home/ubuntu/cdp-dev/.claude/worktrees/hub/frontend/tools")
sys.path.insert(0, "/home/ubuntu/cdp-work/hub/tools")
import build_hub as bh  # noqa: E402
from interiors import buildings  # noqa: E402

BOXES = []   # (groupe, centre, taille, degrés)
_add_box = bh.StagedScene.add_box


def add_box(self, center, size, degrees=0.0):
    BOXES.append((self.group, center, size, degrees))
    return _add_box(self, center, size, degrees)


bh.StagedScene.add_box = add_box


def png(path, width, height, pixels):
    raw = b"".join(b"\x00" + bytes(pixels[y * width * 3:(y + 1) * width * 3]) for y in range(height))

    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)

    data = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
    data += chunk(b"IDAT", zlib.compress(raw, 6)) + chunk(b"IEND", b"")
    open(path, "wb").write(data)


def box_polygon(center, size, degrees):
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
    pts = []
    for du, dv in ((-1, -1), (1, -1), (1, 1), (-1, 1)):
        x, z = du * size[0] / 2, dv * size[2] / 2
        pts.append((center[0] + c * x + s * z, center[2] - s * x + c * z))
    return pts


def inside(poly, x, z):
    hit = False
    for i in range(len(poly)):
        x1, z1 = poly[i]
        x2, z2 = poly[(i + 1) % len(poly)]
        if (z1 > z) != (z2 > z) and x < x1 + (z - z1) * (x2 - x1) / (z2 - z1):
            hit = not hit
    return hit


def distance_to_polygon(poly, x, z):
    if inside(poly, x, z):
        return 0.0
    best = 1e9
    for i in range(len(poly)):
        x1, z1 = poly[i]
        x2, z2 = poly[(i + 1) % len(poly)]
        dx, dz = x2 - x1, z2 - z1
        t = max(0.0, min(1.0, ((x - x1) * dx + (z - z1) * dz) / (dx * dx + dz * dz or 1.0)))
        best = min(best, math.hypot(x - x1 - t * dx, z - z1 - t * dz))
    return best


def main():
    out, books = sys.argv[1], int(sys.argv[2])
    names = sys.argv[3:]
    import os
    import random
    os.makedirs(out, exist_ok=True)
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
    stages = {path.split("/")[1]: meta["stage"] for path, meta in scene.metadata.items() if "stage" in meta}
    for b in buildings(houses=True):
        if names and b["name"] not in names:
            continue
        state = "Rebuilt" if books >= stages[b["name"]] else "Ruins"
        group = f"Repairs/{b['name']}/{state}"
        cx, cz = b["center"]
        w, d = b["size"]
        x0, z0, x1, z1 = cx - w / 2 - 3, cz - d / 2 - 3, cx + w / 2 + 3, cz + d / 2 + 3
        ppm = 25
        width, height = int((x1 - x0) * ppm), int((z1 - z0) * ppm)
        pixels = bytearray([235] * (width * height * 3))
        # Collisions qui arrêtent le corps du joueur (de 0,3 à 1,8 m au-dessus du sol).
        solids = []
        for g, center, size, degrees in BOXES:
            if g not in (group, "Fixed") and not g.startswith(group + "/"):
                continue
            low, high = center[1] - size[1] / 2, center[1] + size[1] / 2
            if high < 0.3 or low > 1.8:
                continue
            poly = box_polygon(center, size, degrees)
            if all(px < x0 - 1 or px > x1 + 1 or pz < z0 - 1 or pz > z1 + 1 for px, pz in poly):
                continue
            solids.append(poly)
        step = 0.1
        free = {}
        for i in range(int((x1 - x0) / step)):
            for j in range(int((z1 - z0) / step)):
                x, z = x0 + (i + 0.5) * step, z0 + (j + 0.5) * step
                free[(i, j)] = all(distance_to_polygon(p, x, z) > 0.4 for p in solids)
        # Propagation depuis le dehors de la porte.
        ox, oz = b["outward"]
        sx, sz = b["door_point"][0] + ox * 2.5, b["door_point"][1] + oz * 2.5
        start = (int((sx - x0) / step), int((sz - z0) / step))
        reached = set()
        queue = [start] if free.get(start) else []
        reached.update(queue)
        while queue:
            i, j = queue.pop()
            for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                n = (i + di, j + dj)
                if free.get(n) and n not in reached:
                    reached.add(n)
                    queue.append(n)
        pockets = 0
        for (i, j), ok in free.items():
            x, z = x0 + (i + 0.5) * step, z0 + (j + 0.5) * step
            indoor = abs(x - cx) < w / 2 - 0.3 and abs(z - cz) < d / 2 - 0.3
            color = None
            if (i, j) in reached:
                color = (150, 215, 150)
            elif ok and indoor:
                color = (250, 170, 60)
                pockets += 1
            if color:
                for py in range(int(j * step * ppm), int((j + 1) * step * ppm)):
                    for px in range(int(i * step * ppm), int((i + 1) * step * ppm)):
                        k = (py * width + px) * 3
                        pixels[k:k + 3] = bytes(color)
        for poly in solids:
            xs = [p[0] for p in poly]
            zs = [p[1] for p in poly]
            for py in range(max(0, int((min(zs) - z0) * ppm)), min(height, int((max(zs) - z0) * ppm) + 1)):
                for px in range(max(0, int((min(xs) - x0) * ppm)), min(width, int((max(xs) - x0) * ppm) + 1)):
                    if inside(poly, x0 + (px + 0.5) / ppm, z0 + (py + 0.5) / ppm):
                        k = (py * width + px) * 3
                        pixels[k:k + 3] = bytes((90, 90, 100))
        # Emprises des meubles, en contour rouge.
        for poly, low, high in scene.footprints.get(group, []):
            for i in range(len(poly)):
                (ax, az), (bx, bz) = poly[i], poly[(i + 1) % len(poly)]
                n = int(max(abs(bx - ax), abs(bz - az)) * ppm) + 1
                for t in range(n + 1):
                    px = int((ax + (bx - ax) * t / n - x0) * ppm)
                    py = int((az + (bz - az) * t / n - z0) * ppm)
                    if 0 <= px < width and 0 <= py < height:
                        k = (py * width + px) * 3
                        pixels[k:k + 3] = bytes((200, 30, 30) if high > 0.3 else (30, 30, 200))
        # Poches : zones libres non atteintes, en (u, v) du repère de la porte.
        loose = {(i, j) for (i, j), ok in free.items() if ok and (i, j) not in reached
                 and abs(x0 + (i + 0.5) * step - cx) < w / 2 - 0.3 and abs(z0 + (j + 0.5) * step - cz) < d / 2 - 0.3}
        yaw = math.radians(b["yaw"])
        c, s_ = math.cos(yaw), math.sin(yaw)
        while loose:
            seed = loose.pop()
            comp, stack = [seed], [seed]
            while stack:
                i, j = stack.pop()
                for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    n = (i + di, j + dj)
                    if n in loose:
                        loose.remove(n)
                        comp.append(n)
                        stack.append(n)
            uv = [(c * (x0 + (i + 0.5) * step - cx) - s_ * (z0 + (j + 0.5) * step - cz),
                   s_ * (x0 + (i + 0.5) * step - cx) + c * (z0 + (j + 0.5) * step - cz)) for i, j in comp]
            if len(comp) >= 10:
                print(f"  poche de {len(comp) * step * step:.2f} m² : u {min(p[0] for p in uv):.1f}..{max(p[0] for p in uv):.1f}, v {min(p[1] for p in uv):.1f}..{max(p[1] for p in uv):.1f}")
        png(f"{out}/{b['name']}_{books}.png", width, height, pixels)
        # Cases atteintes dans la pièce, pour poser les caméras là où le joueur peut se tenir.
        cells = [(round(x0 + (i + 0.5) * step, 2), round(z0 + (j + 0.5) * step, 2)) for i, j in reached
                 if abs(x0 + (i + 0.5) * step - cx) < w / 2 - 0.5 and abs(z0 + (j + 0.5) * step - cz) < d / 2 - 0.5]
        import json
        json.dump(cells, open(f"{out}/{b['name']}_{books}.json", "w"))
        print(f"{b['name']} {state} : {len(reached)} cases atteintes, {pockets} cases libres non atteintes dans la pièce")


main()
