"""Chevauchements entre meubles et objets posés dans les scènes de la Plaine : emprises (boîtes tournées) qui se
recouvrent au sol et en hauteur. Usage : python check_props.py <dossier tools>"""
import sys

sys.path.insert(0, sys.argv[1])
import build_plaine as bp  # noqa: E402

ITEMS = []
_furniture = bp.furniture


def furniture(scene, model, center, degrees=0.0, scale=2.6, height=None, tilt=0.0, roll=0.0):
    (px, py, pz), (sx, sy, sz) = bp.MODEL_BOXES[model]
    basis = bp.multiply(bp.multiply(bp.rotation_y(degrees), bp.rotation_x(tilt)), bp.rotation_z(roll))
    corners = []
    for cx in (px, px + sx):
        for cy in (py, py + sy):
            for cz in (pz, pz + sz):
                local = (cx * scale, cy * scale, cz * scale)
                corners.append([sum(basis[r][i] * local[i] for i in range(3)) for r in range(3)])
    low = [min(c[i] for c in corners) for i in range(3)]
    high = [max(c[i] for c in corners) for i in range(3)]
    w, h, d = (high[i] - low[i] for i in range(3))
    ITEMS.append((model, center[0] - w / 2, center[0] + w / 2, center[2] - d / 2, center[2] + d / 2, center[1],
                  center[1] + h))
    return _furniture(scene, model, center, degrees, scale, height, tilt, roll)


bp.furniture = furniture
for name, builder in (("ruines", bp.build_ruins), ("champ de bataille", bp.build_battlefield),
                      ("archives", bp.build_interior)):
    ITEMS.clear()
    import contextlib
    import io
    with contextlib.redirect_stdout(io.StringIO()):
        builder()
    found = 0
    for i, a in enumerate(ITEMS):
        for b in ITEMS[i + 1:]:
            dx = min(a[2], b[2]) - max(a[1], b[1])
            dz = min(a[4], b[4]) - max(a[3], b[3])
            dy = min(a[6], b[6]) - max(a[5], b[5])
            # Les boîtes englobantes des objets tournés débordent : on ne signale que les vrais recouvrements.
            if dx > 0.15 and dz > 0.15 and dy > 0.05:
                found += 1
                print(f"{name} : {a[0]} ({(a[1] + a[2]) / 2:.1f}, {(a[3] + a[4]) / 2:.1f}) et {b[0]} "
                      f"({(b[1] + b[2]) / 2:.1f}, {(b[3] + b[4]) / 2:.1f}) : {dx:.2f} x {dz:.2f}")
    print(f"{name} : {len(ITEMS)} objets, {found} recouvrements")
