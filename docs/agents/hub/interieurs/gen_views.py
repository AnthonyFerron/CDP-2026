"""Vues à hauteur d'yeux de chaque intérieur : porte vue du dehors, entrée, fond, quatre coins, huit directions
depuis le centre, plafond. Usage : gen_views.py <fichier de sortie> [bâtiments...] [--set=full|dirs|quick]"""
import math
import sys

sys.path.insert(0, "/home/ubuntu/cdp-work/hub/tools")
from interiors import buildings

EYE = 1.6


def standing(b, books, u, v):
    """Case atteinte (plan.py) la plus proche du point (u, v) de la pièce, en (u, v)."""
    import json
    import os
    path = f"/home/ubuntu/cdp-work/hub/plans/{b['name']}_{books}.json"
    if not os.path.exists(path):
        return u, v
    cx, cz = b["center"]
    yaw = math.radians(b["yaw"])
    c, s = math.cos(yaw), math.sin(yaw)
    best = None
    for x, z in json.load(open(path)):
        du, dv = c * (x - cx) - s * (z - cz), s * (x - cx) + c * (z - cz)
        d = math.hypot(du - u, dv - v)
        if best is None or d < best[0]:
            best = (d, du, dv)
    return (best[1], best[2]) if best else (u, v)


BOOKS = 4


def views(b, which="full"):
    cx, cz = b["center"]
    yaw = math.radians(b["yaw"])
    c, s = math.cos(yaw), math.sin(yaw)
    hu, hv = b["hu"], b["hv"]

    def at(u, v, y=EYE):
        return (cx + c * u + s * v, y, cz - s * u + c * v)

    door_u = (b["door_point"][0] - cx) * c - (b["door_point"][1] - cz) * s
    out = []
    name = b["name"]
    out.append((f"{name}_dehors", at(door_u, hv + 5.0, 1.8), at(door_u, 0.0, 1.6)))
    out.append((f"{name}_entree", at(door_u, hv - 0.4), at(0.0, -hv, 1.2)))
    fu, fv = standing(b, BOOKS, 0.0, -hv + 0.8)
    out.append((f"{name}_fond", at(fu, fv), at(door_u, hv, 1.2)))
    if which in ("full", "quick"):
        for i, (su, sv) in enumerate(((-1, -1), (1, -1), (1, 1), (-1, 1))):
            pu, pv = standing(b, BOOKS, su * (hu - 0.5), sv * (hv - 0.5))
            out.append((f"{name}_coin{i}", at(pu, pv), at(-su * hu * 0.6, -sv * hv * 0.6, 1.0)))
    if which in ("full", "dirs"):
        mu, mv = standing(b, BOOKS, 0.0, 0.0)
        for k in range(8):
            a = math.radians(k * 45)
            out.append((f"{name}_dir{k}", at(mu, mv), at(mu + math.sin(a) * 4, mv + math.cos(a) * 4, 1.3)))
    out.append((f"{name}_plafond", at(0.0, 0.0, 1.5), at(0.3, 0.2, 5.0)))
    return out


if __name__ == "__main__":
    target = sys.argv[1]
    which = "full"
    for arg in sys.argv[2:]:
        if arg.startswith("--books="):
            BOOKS = int(arg[8:])
    names = []
    for arg in sys.argv[2:]:
        if arg.startswith("--set="):
            which = arg[6:]
        elif arg.startswith("--books=") or arg == "--houses":
            pass
        else:
            names.append(arg)
    lines = []
    # Salle des veilleurs de l'observatoire : tour carrée tournée de 45 degrés, porte au nord-est.
    tower = dict(name="Observatory", center=(-70.0, 58.0), yaw=45.0 + 90.0, hu=1.3, hv=1.3, door_point=(-70.0 + 2.14 * 0.7071, 58.0 - 2.14 * 0.7071))
    extra = [tower] if (not names or "Observatory" in names) else []
    houses = "--houses" in sys.argv
    for b in buildings(houses=houses) + extra:
        if names and b["name"] not in names:
            continue
        chosen = views(b, which)
        if b["name"].startswith("House"):
            # Maisons du village : l'entrée, le fond et deux coins suffisent.
            chosen = [v for v in views(b, "quick") if v[0].endswith(("_entree", "_fond", "_coin0", "_coin2"))]
        for name, p, t in chosen:
            lines.append(f"{name} {p[0]:.3f},{p[1]:.3f},{p[2]:.3f} {t[0]:.3f},{t[1]:.3f},{t[2]:.3f}")
    open(target, "w").write("\n".join(lines) + "\n")
    print(len(lines), "vues")
