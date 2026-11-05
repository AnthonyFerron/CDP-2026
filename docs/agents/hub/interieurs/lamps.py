"""Fuites des lumières des intérieurs : pour chaque lumière, distance au sol du dehors (au-delà de la face extérieure
des murs) comparée à sa portée. Au-delà de la portée, la lumière n'éclaire rien dehors."""
import math
import re
import sys

sys.path.insert(0, "/home/ubuntu/cdp-dev/.claude/worktrees/hub/frontend/tools")
import build_hub as bh  # noqa: E402
import random  # noqa: E402

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
houses = {f"House{n:02d}": h for n, h in enumerate(bh.house_layout(random.Random(5814)))}
houses.update({name: h for name, h, _, _ in bh.LANDMARKS + bh.QUARTERS})
bad = 0
for path, (transform, script, props, kind) in scene.pivots.items():
    if not script or not script.endswith("hub_lamp.gd"):
        continue
    name = path.split("/")[1]
    origin = scene.origins[path]
    values = [float(v) for v in re.findall(r"-?[\d.]+", props["spots"].split("(", 1)[1])]
    reach = float(props["light_range"])
    if name not in houses:
        print(f"{path}: hors des maisons (observatoire), portée {reach}")
        continue
    cx, cz, w, d, *_ = houses[name]
    hx, hz = w * bh.TILE / 2 + 0.2, d * bh.TILE / 2 + 0.2
    for i in range(0, len(values), 3):
        x, y, z = origin[0] + values[i], origin[1] + values[i + 1], origin[2] + values[i + 2]
        flat = min(hx - abs(x - cx), hz - abs(z - cz))
        distance = math.hypot(flat, y)
        status = "ok" if distance >= reach else "FUITE"
        if status != "ok":
            bad += 1
        print(f"{path} lumière {i // 3} : sol du dehors à {distance:.2f} m, portée {reach} : {status}")
print(bad, "fuites")
