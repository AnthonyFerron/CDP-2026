"""Carte de travail du hub, en PNG : maisons, bâtiments, chemins, château, portails, rivière et projets.
Usage : python plan_map.py <dossier tools de la worktree> <sortie.png> [plan.json]"""
import json
import math
import random
import struct
import sys
import zlib

sys.path.insert(0, sys.argv[1])
import build_hub as bh  # noqa: E402

SCALE = 3  # pixels par mètre
X0, X1, Z0, Z1 = -150, 170, -150, 150
W, H = (X1 - X0) * SCALE, (Z1 - Z0) * SCALE
pix = bytearray(b"\x30\x50\x28" * (W * H))


def put(px, py, c):
    if 0 <= px < W and 0 <= py < H:
        i = (py * W + px) * 3
        pix[i:i + 3] = bytes(c)


def to_px(x, z):
    return int((x - X0) * SCALE), int((z - Z0) * SCALE)


def rect(cx, cz, w, d, c, fill=True, yaw=0.0):
    ca, sa = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    r = math.hypot(w, d) / 2
    x0, y0 = to_px(cx - r, cz - r)
    x1, y1 = to_px(cx + r, cz + r)
    for py in range(y0, y1 + 1):
        for px in range(x0, x1 + 1):
            x = px / SCALE + X0 - cx
            z = py / SCALE + Z0 - cz
            u = ca * x - sa * z
            v = sa * x + ca * z
            inside = abs(u) <= w / 2 and abs(v) <= d / 2
            edge = inside and (abs(u) > w / 2 - 0.4 or abs(v) > d / 2 - 0.4)
            if (fill and inside) or edge:
                put(px, py, c)


def circle(cx, cz, r, c, fill=True):
    x0, y0 = to_px(cx - r, cz - r)
    x1, y1 = to_px(cx + r, cz + r)
    for py in range(y0, y1 + 1):
        for px in range(x0, x1 + 1):
            d = math.hypot(px / SCALE + X0 - cx, py / SCALE + Z0 - cz)
            if d <= r and (fill or d > r - 0.5):
                put(px, py, c)


def line(a, b, width, c):
    ax, az = a
    bx, bz = b
    length = math.hypot(bx - ax, bz - az)
    steps = max(int(length * SCALE), 1)
    for i in range(steps + 1):
        t = i / steps
        circle(ax + (bx - ax) * t, az + (bz - az) * t, width / 2, c)


# Quadrillage tous les 10 m, axes plus clairs.
for x in range(X0, X1 + 1, 10):
    for py in range(H):
        put(to_px(x, 0)[0], py, (0x60, 0x80, 0x50) if x else (0xa0, 0xa0, 0xa0))
for z in range(Z0, Z1 + 1, 10):
    for px in range(W):
        put(px, to_px(0, z)[1], (0x60, 0x80, 0x50) if z else (0xa0, 0xa0, 0xa0))

plan = json.load(open(sys.argv[3], encoding="utf-8")) if len(sys.argv) > 3 else {}

# Limite actuelle (cercle de 106) et nouvelle forme éventuelle.
circle(0, 0, 106, (0x90, 0x30, 0x30), fill=False)
circle(0, 0, 100, (0x70, 0x30, 0x30), fill=False)
if "extent" in plan:
    pts = plan["extent"]
    for i in range(720):
        th = math.radians(i / 2)
        r = 0
        # interpolation cosinus périodique entre les rayons donnés tous les 30 degrés, depuis -180.
        a = (math.degrees(th) + 180) % 360 / 30
        k = int(a) % 12
        f = a - int(a)
        f = (1 - math.cos(f * math.pi)) / 2
        r = pts[k] * (1 - f) + pts[(k + 1) % 12] * f
        th2 = math.radians(-180 + i / 2)
        put(*to_px(math.cos(th2) * r, math.sin(th2) * r), (0xff, 0x40, 0x40))
        put(*to_px(math.cos(th2) * (r - 6), math.sin(th2) * (r - 6)), (0xc0, 0x60, 0x40))

# Chemins.
for tx, tz in bh.ROADS:
    line((0, 0), (tx, tz), 3.2, (0x80, 0x60, 0x40))
for i in range(360):
    a = math.radians(i)
    put(*to_px(math.cos(a) * 31, math.sin(a) * 31), (0x80, 0x60, 0x40))
for path in plan.get("paths", []):
    for a, b in zip(path[:-1], path[1:]):
        line(a, b, 2.6, (0xb0, 0x90, 0x60))

# Château et donjon.
rect(0, -72.5, 50, 45, (0xd0, 0xc0, 0xa0), fill=False)
rect(0, -81, 24, 16, (0xd0, 0xc0, 0xa0), fill=False)
# Maisons.
for cx, cz, w, d, door, *_ in bh.house_layout(random.Random(5814)):
    rect(cx, cz, w * 4, d * 4, (0x40, 0xa0, 0xa0))
for name, (cx, cz, w, d, door, *_), stage, kind in bh.LANDMARKS:
    rect(cx, cz, w * 4, d * 4, (0x40, 0x60, 0xd0))
rect(56.2, 64, 9.6, 12, (0x90, 0x80, 0x30))  # champ
circle(86, -42, 9, (0x70, 0x70, 0x70))  # mine
rect(78, 0, 8, 12, (0x60, 0x60, 0x60))  # bunker
for px, pz in ((-38, -38), (38, -38), (38, 38), (-38, 38)):
    circle(px, pz, 2.0, (0xff, 0xff, 0x00))
circle(30, 4.2, 2.8, (0x40, 0x80, 0xff))
for x, z in ((-15, -4), (-15, 4), (15, -10)):
    rect(x, z, 3, 3, (0xd0, 0x40, 0x40))
rect(-47.7, -30, 4, 12.4, (0x90, 0x90, 0x90))  # cimetière

# Rivière.
for river in plan.get("rivers", []):
    pts = river["points"]
    for (a, b) in zip(pts[:-1], pts[1:]):
        line(a, b, river.get("width", 8), (0x30, 0x70, 0xe0))
for pond in plan.get("ponds", []):
    circle(pond[0], pond[1], pond[2], (0x30, 0x70, 0xe0))
for b in plan.get("bridges", []):
    rect(b[0], b[1], b[3], b[4], (0xe0, 0xe0, 0xe0), yaw=b[2])
for item in plan.get("buildings", []):
    rect(item[0], item[1], item[2], item[3], (0xff, 0x80, 0x20), yaw=item[4] if len(item) > 4 else 0)
for item in plan.get("areas", []):
    rect(item[0], item[1], item[2], item[3], (0xff, 0x60, 0xc0), fill=False)


def png(path):
    raw = b"".join(b"\x00" + bytes(pix[y * W * 3:(y + 1) * W * 3]) for y in range(H))

    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xffffffff)

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(raw, 6)) + chunk(b"IEND", b""))


png(sys.argv[2])
print(W, H)
