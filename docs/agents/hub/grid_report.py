"""Synthèse des grilles de marche : python grid_report.py <livres> [détail]"""
import collections
import glob
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
books = sys.argv[1]
detail = len(sys.argv) > 2
total = collections.Counter()
for path in sorted(glob.glob(os.path.join(HERE, "grid", f"*_{books}.json"))):
    region = os.path.basename(path).rsplit("_", 1)[0]
    report = json.load(open(path, encoding="utf-8"))
    total["cases"] += report["cases"]
    print(f"== {region} : {report['cases']} cases")
    holes = sorted({(round(t[0]), round(t[2])) for t in report["trous"]})
    if holes:
        print(f"  trous ({len(report['trous'])}) : {holes[:30]}{' ...' if len(holes) > 30 else ''}")
    for key in ("ressauts", "chutes", "glissades", "hors_vallee"):
        if report[key]:
            print(f"  {key} ({len(report[key])}) : {[[round(v, 1) if isinstance(v, float) else v for v in p] for p in report[key][:8]]}")
    walls = collections.Counter(w[0] for w in report["murs_invisibles"])
    for name, count in walls.most_common():
        sample = [(round(w[1], 1), round(w[2], 1), round(w[3], 1)) for w in report["murs_invisibles"] if w[0] == name][:4]
        print(f"  mur invisible : {name} x{count} {sample}")
    bare = collections.Counter(b[0].split(" ")[-1] for b in report["sans_collision"])
    for name, count in bare.most_common():
        sample = [(b[1], b[3], b[5]) for b in report["sans_collision"] if b[0].split(" ")[-1] == name][:4]
        groups = sorted({b[0].split("/")[2] if b[0].startswith("Props/Repairs") else b[0].split("/")[0] for b in report["sans_collision"] if b[0].split(" ")[-1] == name})
        print(f"  sans collision : {name} x{count} {sample} {groups[:6]}")
    if detail:
        for name, (count, point) in sorted(report["blocages"].items(), key=lambda kv: -kv[1][0])[:12]:
            print(f"  blocage {count} : {name}")
print("total cases", total["cases"])
