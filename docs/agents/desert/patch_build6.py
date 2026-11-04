"""Poutre tombée de la citerne : bois moins sombre, cerclée de deux frettes de bronze (plus de bande noire unie)."""
from pathlib import Path

p = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/tools/build_desert.py")
t = p.read_text(encoding="utf-8")
old = '''    scene.shape("box", {"size": (0.6, 0.55, 9.4)}, "wood_dark", (cx, top + 0.45, cz), 90.0 - beam + 8.0, roll=4.0)
'''
new = '''    yaw = 90.0 - beam + 8.0
    scene.shape("box", {"size": (0.6, 0.55, 9.4)}, "wood", (cx, top + 0.45, cz), yaw, roll=4.0)
    for u in (-3.2, 2.6):
        scene.shape("box", {"size": (0.66, 0.61, 0.14)}, "bronze",
                    (cx + math.sin(math.radians(yaw)) * u, top + 0.45, cz + math.cos(math.radians(yaw)) * u), yaw, roll=4.0)
'''
assert t.count(old) == 1
t = t.replace(old, new)
p.write_text(t, encoding="utf-8")
print("ok")
