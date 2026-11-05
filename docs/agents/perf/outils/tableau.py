# Tableau avant / après depuis les journaux de mesure : tableau.py <avant.log> <apres.log>
import re, sys
pat = re.compile(r"PERFOMBRES (\w+) \| moyenne (\d+) = (\d+) visibles \+ (\d+) ombres \| pire (\d+) = (\d+) \+ (\d+)")
body = re.compile(r"PERFOMBRES (\w+) \| corps du joueur (-?\d+) appels")
def read(path):
    data, corps = {}, {}
    for line in open(path, encoding="utf-8"):
        m = pat.search(line)
        if m:
            data[m.group(1)] = [int(v) for v in m.groups()[1:]]
        m = body.search(line)
        if m:
            corps[m.group(1)] = int(m.group(2))
    return data, corps
a, ca = read(sys.argv[1])
b, cb = read(sys.argv[2])
names = {"hub": "Hub", "desert": "Désert", "marais": "Marais", "village": "Village", "plaine": "Plaine"}
def pct(x, y):
    return f"{round(100 * (y - x) / x):+d} %" if x else "-"
print("| Lieu | Appels moyens avant | après | écart | dont ombres avant | après | Pire direction avant | après | écart | Corps du joueur avant | après |")
print("| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |")
for k in ["hub", "desert", "marais", "village", "plaine"]:
    if k not in a or k not in b:
        continue
    x, y = a[k], b[k]
    print(f"| {names[k]} | {x[0]} | {y[0]} | {pct(x[0], y[0])} | {x[2]} | {y[2]} | {x[3]} ({x[4]} + {x[5]}) | {y[3]} ({y[4]} + {y[5]}) | {pct(x[3], y[3])} | {ca.get(k, '-')} | {cb.get(k, '-')} |")
