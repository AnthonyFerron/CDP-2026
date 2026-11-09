"""Zones de la grille de marche du hub : dehors par régions de 80 m, l'abri souterrain, chaque bâtiment (pièce,
poches, plafond) et la salle de l'observatoire. Usage : zones.py <fichier> [dehors|interieurs|tout] [pas]"""
import math
import random
import sys

sys.path.insert(0, "/home/ubuntu/cdp-dev/.claude/worktrees/verif-hub/frontend/tools")
import build_hub as bh

TILE = bh.TILE
REGIONS = [
    ("nw", -110, -110, -30, -30, 0, "-32,-34;-50,-50;-60,-40;-48,-61"),
    ("n", -30, -110, 50, -30, 0, "0,-40;40,-44;0,-60;31,-55;42,-70"),
    ("ne", 50, -110, 130, -30, 0, "78,-30;52,-40;64,-60;80,-60;80,-34"),
    ("w", -110, -30, -30, 50, 0, "-40,0;-60,10;-50,-20;-66,-9"),
    ("c", -30, -30, 50, 50, 0, "0,8;20,20;-20,-20;35,-35"),
    ("e", 50, -30, 130, 50, 0, "52,0;72,0;56,20;85,20;56,44"),
    ("sw", -110, 50, -30, 115, 0, "-50,60;-66,52;-40,80"),
    ("s", -30, 50, 50, 115, 0, "0,52;12,72;-24,61;40,55"),
    ("se", 50, 50, 130, 115, 0, "56,54;85,60;60,80"),
    ("bunker", 66, -8, 90, 8, -40, "78,3"),
]


def buildings():
    out = []
    houses = [(f"House{n:02d}", h) for n, h in enumerate(bh.house_layout(random.Random(5814)))]
    houses += [(name, h) for name, h, _stage, _kind in bh.LANDMARKS + bh.QUARTERS]
    for name, house in houses:
        cx, cz, width, depth, door, _style, _floors = house
        frame = bh.HouseFrame(house)
        door_pt = frame.at(frame.door_u, frame.half_v + 0.35)
        out.append(dict(name=name, center=(cx, cz), size=(width * TILE, depth * TILE), outward=bh.OUTWARDS[door],
                        door_point=(door_pt[0], door_pt[2])))
    return out


def main():
    target = sys.argv[1]
    which = sys.argv[2] if len(sys.argv) > 2 else "tout"
    step = sys.argv[3] if len(sys.argv) > 3 else None
    lines = []
    if which in ("dehors", "tout"):
        for name, x0, z0, x1, z1, y, seeds in REGIONS:
            lines.append(f"{name} {x0} {z0} {x1} {z1} {y} {seeds}")
    if which in ("interieurs", "tout"):
        for b in buildings():
            cx, cz = b["center"]
            w, d = b["size"]
            ox, oz = b["outward"]
            dx, dz = b["door_point"]
            seed = (dx + ox * 2.5, dz + oz * 2.5)
            inner = (cx - w / 2 + 0.3, cz - d / 2 + 0.3, cx + w / 2 - 0.3, cz + d / 2 - 0.3)
            lines.append(f"{b['name']} {cx - w / 2 - 3:g} {cz - d / 2 - 3:g} {cx + w / 2 + 3:g} {cz + d / 2 + 3:g} 0 "
                         f"{seed[0]:.2f},{seed[1]:.2f} {inner[0]:.2f},{inner[1]:.2f},{inner[2]:.2f},{inner[3]:.2f}")
        x, z, scale = bh.OBSERVATORY
        a = 0.465 * scale + 2.5
        door = (x + a * math.cos(math.radians(45)), z - a * math.sin(math.radians(45)))
        inner = 0.349 * scale * 0.707 - 0.1
        lines.append(f"Observatory {x - 6:g} {z - 6:g} {x + 6:g} {z + 6:g} 0 {door[0]:.2f},{door[1]:.2f};-70.07,57.51 "
                     f"{x - inner:.2f},{z - inner:.2f},{x + inner:.2f},{z + inner:.2f}")
        # Abri souterrain : la pièce entière (20 x 12 m), pour les poches et le plafond.
        lines.append("BunkerRoom 66 -8 90 8 -40 78,3 68.3,-5.7,87.7,5.7")
    if step:
        lines = [line + ("" if len(line.split()) > 7 else " 0,0,0,0") + f" {step}" for line in lines]
    open(target, "w").write("\n".join(lines) + "\n")
    print(len(lines), "zones")


if __name__ == "__main__":
    main()
