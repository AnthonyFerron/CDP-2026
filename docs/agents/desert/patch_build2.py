from pathlib import Path

p = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/tools/build_desert.py")
t = p.read_text(encoding="utf-8")
edits = [
    ('''        if any(math.hypot(x - px, z - pz) < 1.0 for px, pz in placed):''',
     '''        if any(math.hypot(x - px, z - pz) < 1.25 for px, pz in placed):'''),
    ('''    for u, v in ((-3.4, 1.2), (-4.1, 2.3)):''', '''    for u, v in ((-3.3, 1.0), (-3.1, 2.45)):'''),
    ('''    put(scene, "mini_arena/column-damaged", (-17.8, 0.0, -8.6), 30.0, 2.4, height=1.5, tilt=90.0)''',
     '''    put(scene, "mini_arena/column-damaged", (-16.6, 0.0, -9.0), 30.0, 2.4, height=1.5, tilt=90.0)'''),
    ('''    put(scene, "mini_arena/block", (14.2, 0.0, -15.8), 25.0, 1.4, height=0.7)
    put(scene, "mini_arena/block", (15.6, 0.0, -16.1), 70.0, 1.2, height=0.6)''',
     '''    put(scene, "mini_arena/block", (14.0, 0.0, -15.6), 25.0, 1.4, height=0.7)
    put(scene, "mini_arena/block", (15.9, 0.0, -16.2), 70.0, 1.2, height=0.6)'''),
    ('''(10.2, -25.4, 25.0)''', '''(10.0, -25.7, 25.0)'''),
    ('''(11.6, -24.2, 80.0)''', '''(12.1, -24.0, 80.0)'''),
]
for old, new in edits:
    assert t.count(old) == 1, old[:80]
    t = t.replace(old, new)
p.write_text(t, encoding="utf-8", newline="\n")

s = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/scenes/levels/desert/desert_sand.gdshader")
t = s.read_text(encoding="utf-8")
old = '''uniform float ripple_depth = 0.08;
'''
new = '''uniform float ripple_depth = 0.08;
// Couleur des congères, qui n'ont pas de couleurs de sommets : le terrain garde 1.
uniform vec3 tint = vec3(1.0);
'''
assert old in t
t = t.replace(old, new)
t = t.replace("	ALBEDO = COLOR.rgb * (1.0 - ripples * ripple_depth);", "	ALBEDO = COLOR.rgb * tint * (1.0 - ripples * ripple_depth);")
s.write_text(t, encoding="utf-8", newline="\n")
print("ok")
