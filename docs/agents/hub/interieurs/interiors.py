"""Liste des bâtiments du hub qui ont un intérieur : centre, taille, porte, repère, et points de vue."""
import json
import math
import sys

sys.path.insert(0, "/home/ubuntu/cdp-dev/.claude/worktrees/hub/frontend/tools")
import build_hub as bh

TILE = bh.TILE


def buildings(houses=False):
    out = []
    entries = list(bh.LANDMARKS + bh.QUARTERS)
    if houses:
        import random
        entries = [(f"House{n:02d}", h, 1 + n // 4, "house") for n, h in enumerate(bh.house_layout(random.Random(5814)))] + entries
    for name, house, stage, kind in entries:
        cx, cz, width, depth, door, style, floors = house
        frame = bh.HouseFrame(house)
        # Porte : centre de la case de porte sur la façade.
        dx, dz = bh.OUTWARDS[door]
        door_pt = frame.at(frame.door_u, frame.half_v + 0.35)
        out.append(dict(name=name, kind=kind, stage=stage, center=(cx, cz), size=(width * TILE, depth * TILE), door=door,
                        style=style, floors=floors, yaw=frame.yaw, hu=frame.half_u, hv=frame.half_v,
                        door_point=(door_pt[0], door_pt[2]), outward=(dx, dz)))
    return out


if __name__ == "__main__":
    for b in buildings():
        print(json.dumps(b))
