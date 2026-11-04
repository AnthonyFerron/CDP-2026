from pathlib import Path

p = Path(__file__).parent / "desert_grid_test.gd"
t = p.read_text(encoding="utf-8")
old_key = "\tvar key := Vector2i(floori(point.x / HASH), floori(point.z / HASH))\n"
assert old_key in t
t = t.replace(old_key, "", 1)
old = "\tfor entry: Array in _mesh_hash.get(key, []):\n\t\tvar node: GeometryInstance3D = entry[0]\n"
new = """\t# Toutes les cases de la table que touche la sphère de rayon r : un mur dont la face tombe pile sur le bord
\t# d'une case (x = 12 avec des cases de 4 m) n'est rangé que dans la case voisine.
\tvar entries: Array = []
\tfor i in range(floori((point.x - r) / HASH), floori((point.x + r) / HASH) + 1):
\t\tfor j in range(floori((point.z - r) / HASH), floori((point.z + r) / HASH) + 1):
\t\t\tfor entry: Array in _mesh_hash.get(Vector2i(i, j), []):
\t\t\t\tif not entry in entries:
\t\t\t\t\tentries.append(entry)
\tfor entry: Array in entries:
\t\tvar node: GeometryInstance3D = entry[0]
"""
assert old in t
t = t.replace(old, new, 1)
p.write_text(t, encoding="utf-8")
print("ok")
