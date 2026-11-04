REPLACEMENTS = [
('''def furniture(scene, model, center, degrees=0.0, scale=2.6, height=None, tilt=0.0, roll=0.0):
    (px, py, pz), (sx, sy, sz) = bp.MODEL_BOXES[model]''',
'''def furniture(scene, model, center, degrees=0.0, scale=2.6, height=None, tilt=0.0, roll=0.0):
    model = bp.MEDIEVAL.get(model, model)
    (px, py, pz), (sx, sy, sz) = bp.MODEL_BOXES[model]
    axes = scale if isinstance(scale, tuple) else (scale, scale, scale)'''),
('''                local = (cx * scale, cy * scale, cz * scale)
                corners.append([sum(basis[r][i] * local[i] for i in range(3)) for r in range(3)])
    low = [min(c[i] for c in corners) for i in range(3)]
    high = [max(c[i] for c in corners) for i in range(3)]
    w, h, d = (high[i] - low[i] for i in range(3))
    ITEMS.append((model, center[0] - w / 2, center[0] + w / 2, center[2] - d / 2, center[2] + d / 2,
                  center[1], center[1] + h, CURRENT[0]))
    return _furniture(scene, model, center, degrees, scale, height, tilt, roll)''',
'''                local = (cx * axes[0], cy * axes[1], cz * axes[2])
                corners.append([sum(basis[r][i] * local[i] for i in range(3)) for r in range(3)])
    low = [min(c[i] for c in corners) for i in range(3)]
    high = [max(c[i] for c in corners) for i in range(3)]
    w, h, d = (high[i] - low[i] for i in range(3))
    ITEMS.append((model, center[0] - w / 2, center[0] + w / 2, center[2] - d / 2, center[2] + d / 2,
                  center[1], center[1] + h, CURRENT[0]))
    return _hub_furniture(scene, model, center, degrees, scale, height, tilt, roll)'''),
('''bp.wall = wall
bp.furniture = furniture
for name in ("build_hub", "build_village", "build_desert", "build_marais"):''',
'''bp.wall = wall
import build_hub as _bh
_hub_furniture = _bh.furniture
bp.furniture = furniture
for name in ("build_hub",):'''),
('''import build_village as bv
''', ''),
('''    bh.build_mine(scene, rng)
''', '''    bh.build_mine(scene, rng)
    bh.build_bridges(scene, rng)
    bh.build_quarters(scene, random.Random(5820))
    bh.build_park(scene, random.Random(5821))
    bh.build_quarter_paths(scene)
'''),
('''run("hub", hub)
run("abri", bh.build_shelter)


def village():
    rng = random.Random(5815)
    scene = bp.Scene("V")
    bv.build_rampart(scene, rng)
    bv.build_streets(scene, rng)
    for number, house in enumerate(bv.HOUSES):
        bv.build_house(scene, rng, number, house)
    bv.build_town_hall(scene)


run("village", village)
run("mairie", bv.build_hall_interior)
run("bibliothèque", bp.build_interior)
run("ruines plaine", bp.build_ruins)''', '''run("hub", hub)
run("abri", bh.build_shelter)'''),
]
