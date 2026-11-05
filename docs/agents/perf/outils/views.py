# Points de capture : arrivée (regard du joueur), ombre proche (sa propre ombre), ombre au loin (10 à 50 m).
import math, sys
spawn = {"hub": (0, 0.3, 12), "desert": (0, 0.3, 48), "marais": (0, 0.6, 57), "village": (0, 0.3, 57), "plaine": (0, 0.2, 50)}
sun_z = {"hub": (0.433, 0.5, 0.75), "plaine": (0.433, 0.5, 0.75), "desert": (0.4698, 0.5736, 0.671),
         "marais": (-0.5, 0.7071, 0.5), "village": (-0.845, 0.218, 0.488)}
extra = {"plaine": ["o3_facade=3,1.7,18:-2,2,6", "o5_siege=-6,1.7,44:-16,1,38"]}
lieu = sys.argv[1]
x, y, z = spawn[lieu]
lx, _, lz = [-c for c in sun_z[lieu]]
n = math.hypot(lx, lz); lx, lz = lx / n, lz / n
eye = y + 1.65
out = [
    f"arrivee={x},{eye:.2f},{z}:{x},{eye - 1.5:.2f},{z - 20}",
    f"ombre={x - lx * 1.5:.2f},{eye + 0.6:.2f},{z - lz * 1.5:.2f}:{x + lx * 4:.2f},{y:.2f},{z + lz * 4:.2f}",
    f"ombre_loin={x},{eye:.2f},{z}:{x + lx * 30:.2f},{y - 1:.2f},{z + lz * 30:.2f}",
] + extra.get(lieu, [])
print(" ".join(out))
