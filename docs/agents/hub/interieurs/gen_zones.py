"""Zones de la grille de marche des intérieurs : une ligne par bâtiment (et la tour de l'observatoire)."""
import math
import sys

sys.path.insert(0, "/home/ubuntu/cdp-work/hub/tools")
from interiors import buildings

lines = []
for b in buildings():
    cx, cz = b["center"]
    w, d = b["size"]
    ox, oz = b["outward"]
    dx, dz = b["door_point"]
    seed = (dx + ox * 2.5, dz + oz * 2.5)
    inner = (cx - w / 2 + 0.3, cz - d / 2 + 0.3, cx + w / 2 - 0.3, cz + d / 2 - 0.3)
    lines.append(f"{b['name']} {cx - w / 2 - 3:g} {cz - d / 2 - 3:g} {cx + w / 2 + 3:g} {cz + d / 2 + 3:g} 0 "
                 f"{seed[0]:.2f},{seed[1]:.2f} {inner[0]:.2f},{inner[1]:.2f},{inner[2]:.2f},{inner[3]:.2f}")
# Observatoire : tour carrée tournée de 45 degrés, porte au nord-est.
x, z, scale = -70.0, 58.0, 4.6
a = 0.465 * scale + 2.5
door = (x + a * math.cos(math.radians(45)), z - a * math.sin(math.radians(45)))
inner = 0.349 * scale * 0.707 - 0.1
# Deux départs : devant la porte, et dans la salle (on y entre avec E).
lines.append(f"Observatory {x - 6:g} {z - 6:g} {x + 6:g} {z + 6:g} 0 {door[0]:.2f},{door[1]:.2f};-70.07,57.51 "
             f"{x - inner:.2f},{z - inner:.2f},{x + inner:.2f},{z + inner:.2f}")
# Même grille au quart de mètre : les passages de 0,8 à 1 m n'ont pas toujours une case du demi-mètre en leur milieu.
step = sys.argv[2] if len(sys.argv) > 2 else None
if step:
    lines = [f"{line.split()[0]}_fin {' '.join(line.split()[1:])} {step}" for line in lines]
open(sys.argv[1], "w").write("\n".join(lines) + "\n")
print("\n".join(lines))
