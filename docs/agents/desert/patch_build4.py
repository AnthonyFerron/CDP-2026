"""Murs de la citerne : des pans de muraille du kit (assises, meurtrières, chaperon) au lieu de boîtes unies."""
from pathlib import Path

p = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/tools/build_desert.py")
t = p.read_text(encoding="utf-8")


def sub(old, new):
    global t
    assert t.count(old) == 1, old
    t = t.replace(old, new)


sub('''        scene.shape("box", {"size": (length_x, height, ring)}, "stone", (cx, center_y, z))
''', '''        scene.add("mini_arena/wall", (cx, top - height, z), 0.0, (length_x, height, ring / 0.6))
''')
sub('''        scene.shape("box", {"size": (ring, height, length_z)}, "stone", (x, center_y, cz))
''', '''        scene.add("mini_arena/wall", (x, top - height, cz), 90.0, (length_z, height, ring / 0.6))
''')
sub('''    """Citerne des bâtisseurs, à l'ouest de la salle : une fosse aux murs épais (desert_terrain.gd la creuse),''',
    '''    """Citerne des bâtisseurs, à l'ouest de la salle : une fosse aux murs épais, des pans de muraille du kit comme
    ceux de la salle, pas des boîtes unies (desert_terrain.gd la creuse),''')
p.write_text(t, encoding="utf-8")
print("ok")
