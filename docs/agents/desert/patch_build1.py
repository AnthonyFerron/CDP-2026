from pathlib import Path

p = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/tools/build_desert.py")
t = p.read_text(encoding="utf-8")
edits = [
    ('''def lying_skeleton(scene, x, z, degrees, buried=True):
    """Squelette de voyageur couché sur le dos, à demi recouvert de sable."""
    put(scene, "graveyard_kit/character-skeleton", (x, 0.0, z), degrees, 3.2, tilt=-90.0)
    if buried:
        frame = local_frame(x, z, degrees)
        a, _, b = frame(0.55, -0.35)
        mound(scene, a, b, 0.9, 0.22, 0.7, degrees, collide=False)''',
     '''def lying_skeleton(scene, x, z, degrees, buried=True, y=0.0):
    """Squelette de voyageur couché sur le dos, à demi recouvert de sable."""
    put(scene, "graveyard_kit/character-skeleton", (x, y, z), degrees, 3.2, tilt=-90.0)
    if buried:
        frame = local_frame(x, z, degrees)
        a, _, b = frame(0.55, -0.35)
        mound(scene, a, b, 0.9, 0.22, 0.7, degrees, y=y, collide=False)'''),
    ('''    put(scene, "mini_dungeon/chest", (-8.72, 0.0, -7.9 - 0.25), 0.0, 1.8, height=0.5)
''', ""),
    ('''    jars(scene, 7.8, 3.6, random.Random(32), 3, 0.9)''', '''    jars(scene, 6.8, 2.8, random.Random(32), 3, 0.8)'''),
    ('''    put(scene, "mini_arena/bricks", (12.6, 0.0, 0.2), -20.0, 3.0, height=1.2)''',
     '''    put(scene, "mini_arena/bricks", (12.6, 0.0, -1.0), -20.0, 3.0, height=1.2)'''),
    ('''(5.6, -20.9, 60.0)''', '''(5.6, -21.5, 60.0)'''),
    ('''    a = at(-7.6, -5.0)
    skeleton_beast(scene, a[0], a[2], heading + 15.0, 1.25, rng)
    jars(scene, *at(-6.6, -2.6)[0::2], random.Random(51), 3, 0.9)''',
     '''    a = at(-1.5, 6.8)
    skeleton_beast(scene, a[0], a[2], heading - 90.0, 1.25, rng)
    jars(scene, *at(-7.6, -2.4)[0::2], random.Random(51), 3, 0.9)'''),
    ('''(-3.0, 6.8, 200.0)''', '''(-5.6, 6.0, 200.0)'''),
    ('''    jars(scene, 31.6, 3.6, random.Random(61), 4, 1.2)''', '''    jars(scene, 31.2, 3.8, random.Random(61), 4, 1.0)'''),
    ('''    put(scene, "mini_arena/bricks", (x - 0.6, 0.0, z + 0.6), 30.0, 2.4, height=1.0)''',
     '''    put(scene, "mini_arena/bricks", (x - 1.4, 0.0, z + 0.6), 30.0, 2.4, height=1.0)'''),
    ('''    skeleton_beast(scene, x, z, 65.0, 5.2, rng, horns=True, walkable=True)''',
     '''    skeleton_beast(scene, x, z, 155.0, 5.2, rng, horns=True, walkable=True)'''),
    ('''        scene.shape("sphere", {"segments": 6, "rings": 3}, "void", frame(side * 0.06 * size, 0.05 * size, y + 0.11 * size),''',
     '''        scene.shape("sphere", {"segments": 6, "rings": 3}, "void", frame(side * 0.085 * size, 0.06 * size, y + 0.12 * size),'''),
    ('''    lying_skeleton(scene, cx + 0.4, cz + 1.2, 200.0, buried=False)''',
     '''    lying_skeleton(scene, cx + 0.4, cz + 1.2, 200.0, buried=False, y=floor)'''),
]
for old, new in edits:
    assert t.count(old) == 1, old[:80]
    t = t.replace(old, new)
p.write_text(t, encoding="utf-8", newline="\n")
print("ok")
