"""Points de lecture des textes des intérieurs (4 livres) : pour chaque Readable, la case atteinte (plans/*.json) la
plus proche à moins de son rayon moins 0,3 m. Écrit des lignes « lire <bâtiment> x,z tx,ty,tz <titre> »."""
import json
import math
import os
import random
import sys

sys.path.insert(0, "/home/ubuntu/cdp-dev/.claude/worktrees/hub/frontend/tools")
import build_hub as bh  # noqa: E402

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
lines = []
for path, (transform, script, props, kind) in scene.pivots.items():
    if not script or not script.endswith("readable.gd") or "/Rebuilt/" not in path:
        continue
    name = path.split("/")[1]
    x, y, z = scene.origins[path]
    radius = float(props["radius"])
    title = props["title"].strip('"')
    cells_path = f"/home/ubuntu/cdp-work/hub/plans/{name}_4.json"
    if not os.path.exists(cells_path):
        print("sans plan :", name, file=sys.stderr)
        continue
    best = None
    for cx, cz in json.load(open(cells_path)):
        d = math.hypot(cx - x, cz - z)
        if 0.6 < d < radius - 0.3 and (best is None or abs(d - 1.1) < abs(best[0] - 1.1)):
            best = (d, cx, cz)
    if best is None:
        print("aucune case à portée :", path, file=sys.stderr)
        lines.append(f"lire {name} {x:.2f},{z:.2f} {x:.2f},{y:.2f},{z:.2f} {title}")
        continue
    lines.append(f"lire {name} {best[1]:.2f},{best[2]:.2f} {x:.2f},{y:.2f},{z:.2f} {title}")
# Observatoire (sans plan) : depuis le point d'arrivée de la porte.
lines.append("lire Observatory -70.07,57.51 -70.39,0.95,59.03 Le registre des veilleurs")
open(sys.argv[1], "w").write("\n".join(lines) + "\n")
print("\n".join(lines))
