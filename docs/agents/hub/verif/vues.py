"""Vues des zones changées du hub : grille à hauteur d'yeux tous les 4 m (jardin du roi, place, mine), rives de la
rivière tous les 4 m, ponts, portes voûtées (dehors et dedans), et vues de dessus orthographiques.
Usage : vues.py <dossier> ; écrit <zone>.txt (une vue par ligne, hauteur « gH » au-dessus du sol libre)."""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from zones import buildings

RIVER = [(51.0, -127.0, 2.6), (53.0, -115.0, 3.0), (56.0, -104.0, 3.6), (60.0, -92.0, 4.0), (63.0, -78.0, 4.4),
         (63.0, -66.0, 4.0), (61.0, -52.0, 4.6), (60.0, -38.0, 4.8), (61.0, -24.0, 4.5), (62.0, -12.0, 4.0),
         (63.4, 0.0, 3.6), (65.0, 10.0, 3.8), (68.0, 20.0, 4.2), (71.0, 32.0, 4.6), (74.0, 42.0, 4.8),
         (73.6, 48.0, 5.4), (77.0, 56.0, 4.6), (85.0, 70.0, 5.0), (95.0, 84.0, 5.0), (108.0, 96.0, 4.8),
         (122.0, 104.0, 4.4), (136.0, 106.0, 4.0)]
EYE = 1.7
DIRS4 = [(0, -1), (1, 0), (0, 1), (-1, 0)]


def bezier(p0, c0, c1, p1, t):
    u = 1 - t
    return tuple(u * u * u * p0[i] + 3 * u * u * t * c0[i] + 3 * u * t * t * c1[i] + t * t * t * p1[i] for i in range(2))


def river_samples():
    out = []
    for index in range(len(RIVER) - 1):
        p0, p1, p2, p3 = RIVER[max(index - 1, 0)], RIVER[index], RIVER[index + 1], RIVER[min(index + 2, len(RIVER) - 1)]
        steps = max(int(math.hypot(p2[0] - p1[0], p2[1] - p1[1]) / 1.5), 1)
        for step in range(steps):
            t = step / steps
            c0 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
            c1 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
            x, z = bezier(p1[:2], c0, c1, p2[:2], t)
            out.append((x, z, p1[2] + (p2[2] - p1[2]) * t))
    out.append(RIVER[-1])
    return out


def line(name, x, z, tx, tz, dy=-0.45, h=EYE):
    return f"{name} {x:.2f},g{h},{z:.2f} {tx:.2f},{dy},{tz:.2f}"


def grid(prefix, x0, z0, x1, z1, keep=lambda x, z: True, dirs=DIRS4):
    lines = []
    z = z0
    while z <= z1 + 0.01:
        x = x0
        while x <= x1 + 0.01:
            if keep(x, z):
                for k, (dx, dz) in enumerate(dirs):
                    lines.append(line(f"{prefix}_{x:g}_{z:g}_{'nesw'[k]}", x, z, x + dx * 4, z + dz * 4))
            x += 4
        z += 4
    return lines


def ortho(prefix, x0, z0, x1, z1, size=12.0):
    """Tuiles vues de dessus : 2 x size m de haut (axe z ; la taille de la caméra orthographique est mesurée ici en
    demi-hauteur, vérifié sur l'étang), 16/9 de large (axe x)."""
    height = 2 * size
    width = height * 16 / 9
    lines = []
    z = z0 + height / 2
    while z - height / 2 < z1:
        x = x0 + width / 2
        while x - width / 2 < x1:
            lines.append(f"{prefix}_{x:.0f}_{z:.0f} {x:.2f},40,{z:.2f} {x:.2f},0,{z:.2f} {size}")
            x += width
        z += height
    return lines


def main():
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    zones = {}
    zones["jardin"] = grid("jardin", 30, -89, 50, -53)
    zones["place"] = grid("place", -12, -12, 12, 12, keep=lambda x, z: math.hypot(x, z) <= 13.5)
    mx, mz = 82.6, -39.6
    zones["mine"] = grid("mine", mx - 12.6, mz - 12.4, mx + 13.4, mz + 12.6,
                         keep=lambda x, z: math.hypot(x - mx, z - mz) <= 13.5)
    # Rives : tous les 4 m le long du cours, sur chaque rive à 2,5 m de l'eau : en travers, et le long (vers l'amont
    # puis l'aval, en alternance).
    lines = []
    samples = river_samples()
    run = 0.0
    last = None
    station = 0
    for i, (x, z, hw) in enumerate(samples):
        if last is not None:
            run += math.hypot(x - last[0], z - last[1])
        last = (x, z)
        if run < 4.0 * station or abs(z) > 100 or x > 108:
            continue
        station += 1
        a = samples[max(i - 1, 0)]
        b = samples[min(i + 1, len(samples) - 1)]
        tx, tz = b[0] - a[0], b[1] - a[1]
        length = math.hypot(tx, tz) or 1.0
        tx, tz = tx / length, tz / length
        nx, nz = -tz, tx
        for side, sign in (("g", 1), ("d", -1)):
            px, pz = x + nx * sign * (hw + 2.5), z + nz * sign * (hw + 2.5)
            lines.append(line(f"riv_{station:03d}{side}_travers", px, pz, x - nx * sign * (hw + 2.5), z - nz * sign * (hw + 2.5), dy=-1.6))
            along = 1 if station % 2 else -1
            lines.append(line(f"riv_{station:03d}{side}_long", px, pz, px + tx * along * 6 - nx * sign * 2.5, pz + tz * along * 6 - nz * sign * 2.5, dy=-1.4))
    zones["riviere"] = lines
    # Ponts : sur le tablier aux deux bouts et au milieu, vers l'autre bout et vers l'eau ; depuis les rives.
    lines = []
    for name, (bx, bz, _deg, length, width) in (("grandpont", (63.25, 0.0, 0.0, 15.5, 5.0)), ("passerelle", (63.0, -66.0, 0.0, 15.0, 3.0))):
        half = length / 2
        for tag, x, tx in (("ouest", bx - half - 1.0, bx + half), ("est", bx + half + 1.0, bx - half)):
            lines.append(line(f"{name}_{tag}", x, bz, tx, bz, dy=-0.6))
        for tag, dz in (("amont", -1), ("aval", 1)):
            lines.append(line(f"{name}_milieu_{tag}", bx, bz, bx, bz + dz * 8, dy=-1.8))
            lines.append(line(f"{name}_rive_{tag}", bx - half - 2.0, bz + dz * 7.0, bx, bz, dy=-1.0))
            lines.append(line(f"{name}_rive_est_{tag}", bx + half + 2.0, bz + dz * 7.0, bx, bz, dy=-1.0))
    zones["ponts"] = lines
    # Portes voûtées : de dehors, à 4 m, et de dedans, à 2,5 m de la porte.
    lines = []
    for b in buildings():
        dx, dz = b["door_point"]
        ox, oz = b["outward"]
        lines.append(line(f"porte_{b['name']}_dehors", dx + ox * 4.0, dz + oz * 4.0, dx, dz, dy=-0.2))
        lines.append(line(f"porte_{b['name']}_dedans", dx - ox * 2.8, dz - oz * 2.8, dx, dz, dy=-0.1))
    zones["portes"] = lines
    # Vues de dessus.
    zones["dessus"] = (ortho("dessus_jardin", 28, -92, 54, -50, size=6.0) + ortho("dessus_mine", 70, -52, 96, -27, size=6.0)
                       + ortho("dessus_place", -14, -14, 14, 14, size=6.0)
                       + ortho("dessus_riviere", 46, -100, 82, 60, size=7.0) + ortho("dessus_riviere_sud", 70, 50, 108, 100, size=7.0))
    for name, lines in zones.items():
        open(os.path.join(out, name + ".txt"), "w").write("\n".join(lines) + "\n")
        print(name, len(lines))


if __name__ == "__main__":
    main()
