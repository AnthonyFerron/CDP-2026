"""Arbres sans collision du hub qui sont dans la vallée jouable (en deçà de la limite)."""
import math
import re
import sys

EXTENT = [106.0, 106.0, 106.0, 106.0, 114.0, 122.0, 126.0, 122.0, 112.0, 106.0, 106.0, 106.0]


def limit(angle):
    steps = ((math.degrees(angle) + 180.0) % 360.0) / 30.0
    index = int(steps) % 12
    blend = (1 - math.cos((steps - math.floor(steps)) * math.pi)) / 2
    return EXTENT[index] * (1 - blend) + EXTENT[(index + 1) % 12] * blend


inside = 0
section = False
for line in open(sys.argv[1], encoding="utf-8", errors="replace"):
    if line.startswith("== "):
        section = line.startswith("== hub/hub")
        continue
    if not section:
        continue
    match = re.search(r"\((-?[\d.]+), (-?[\d.]+), (-?[\d.]+)\)", line)
    if not match:
        continue
    x, z = float(match.group(1)), float(match.group(3))
    if math.hypot(x, z) < limit(math.atan2(z, x)) - 0.5:
        inside += 1
        print("dans la vallée :", line.strip())
print(inside, "arbre(s) sans collision dans la vallée")
