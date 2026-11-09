"""Synthèse des grilles de marche : rapport.py <dossier> <livres> [détail]"""
import collections
import glob
import json
import os
import sys

folder, books = sys.argv[1], sys.argv[2]
detail = len(sys.argv) > 3
for path in sorted(glob.glob(os.path.join(folder, f"*_{books}.json"))):
    zone = os.path.basename(path).rsplit("_", 1)[0]
    r = json.load(open(path, encoding="utf-8"))
    lines = []
    for key in ("trous", "ressauts", "chutes", "glissades", "hors_vallee"):
        if r[key]:
            lines.append(f"  {key} ({len(r[key])}) : {[[round(v, 1) if isinstance(v, float) else v for v in p] for p in r[key][:8]]}")
    walls = collections.Counter(w[0] for w in r["murs_invisibles"])
    for name, count in walls.most_common():
        sample = [(round(w[1], 1), round(w[2], 1), round(w[3], 1)) for w in r["murs_invisibles"] if w[0] == name][:6]
        lines.append(f"  mur invisible : {name} x{count} {sample}")
    for b in r["sans_collision"]:
        lines.append(f"  sans collision : {b}")
    if r.get("poches") and (detail or len(r["poches"]) < 200):
        cells = sorted({(round(p[0] * 2) / 2, round(p[2] * 2) / 2) for p in r["poches"]})
        lines.append(f"  poches ({len(r['poches'])}) : {cells[:40]}")
    if r.get("plafond_bas"):
        lines.append(f"  plafond bas ({len(r['plafond_bas'])}) : {r['plafond_bas'][:6]}")
    if lines:
        print(f"== {zone} : {r['cases']} cases")
        print("\n".join(lines))
