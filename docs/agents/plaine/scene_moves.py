"""Compare un .tscn à sa version committée : modèles déplacés, par type, avec l'écart en hauteur et au sol.
Usage : python scene_moves.py <worktree> <chemin du tscn relatif à la worktree>"""
import re
import subprocess
import sys
from collections import defaultdict

worktree, relative = sys.argv[1], sys.argv[2]
old = subprocess.run(["git", "-C", worktree, "show", f"HEAD:{relative}"], capture_output=True, text=True,
                     encoding="utf-8").stdout
new = open(f"{worktree}/{relative}", encoding="utf-8").read()
node = re.compile(r'\[node name="([^"]+)" parent="Models" instance=ExtResource\("[^"]+"\)\]\ntransform = Transform3D\(([^)]*)\)')


def models(text):
    result = {}
    for name, values in node.findall(text):
        numbers = [float(v) for v in values.split(",")]
        result[name] = numbers
    return result


before, after = models(old), models(new)
moves = defaultdict(list)
for name, values in after.items():
    if name not in before:
        continue
    a, b = before[name], values
    dy = b[10] - a[10]
    dxz = ((b[9] - a[9]) ** 2 + (b[11] - a[11]) ** 2) ** 0.5
    if abs(dy) > 0.005 or dxz > 0.005:
        kind = re.sub(r"_\d+$", "", name)
        moves[kind].append((dy, dxz))
for kind, items in sorted(moves.items()):
    dys = [d for d, _ in items]
    dxzs = [d for _, d in items]
    print(f"{kind:32s} {len(items):3d} déplacés : hauteur {min(dys):+.2f}..{max(dys):+.2f}, au sol jusqu'à {max(dxzs):.2f} m")
print(f"{len(before)} modèles avant, {len(after)} après")
