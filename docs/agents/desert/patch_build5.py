"""Piliers d'angle de la citerne : socle, fût, chapiteau et dé, au lieu d'un bloc uni."""
from pathlib import Path

p = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/tools/build_desert.py")
t = p.read_text(encoding="utf-8")
old = '''            scene.shape("box", {"size": (1.5, 1.7, 1.5)}, "stone_dark", (x, 0.85, z))
'''
new = '''            scene.shape("box", {"size": (1.6, 0.35, 1.6)}, "stone_dark", (x, 0.175, z))
            scene.shape("box", {"size": (1.3, 1.1, 1.3)}, "stone", (x, 0.9, z))
            scene.shape("box", {"size": (1.55, 0.22, 1.55)}, "stone_dark", (x, 1.56, z))
            scene.shape("box", {"size": (1.0, 0.15, 1.0)}, "stone", (x, 1.745, z))
            scene.box_collider((x, 0.175, z), (1.6, 0.35, 1.6))
            scene.box_collider((x, 1.6, z), (1.3, 2.5, 1.3))
'''
assert t.count(old) == 1
t = t.replace(old, new)
p.write_text(t, encoding="utf-8")
print("ok")
