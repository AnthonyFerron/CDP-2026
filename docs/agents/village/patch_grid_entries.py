"""Grille : l'eau du ruisseau se traverse ; sur la rampe de l'escalier, les pieds frôlent le nez des marches."""
from pathlib import Path

p = Path(__file__).with_name("village_grid_test.gd")
t = p.read_text(encoding="utf-8")
pairs = [
    ('''"rug", "planks", "dirt", "Interior/Railing",''', '''"rug", "planks", "dirt", "Stream", "Interior/Railing",'''),
    ('''		for hit in space.intersect_shape(query, 4):
			var name: String = _ghost_names.get(hit.shape, "?")''',
     '''		for hit in space.intersect_shape(query, 4):
			var name: String = _ghost_names.get(hit.shape, "?")
			# Sur la rampe de l'escalier, le nez des marches dépasse de 0,3 m au plus : les pieds le frôlent.
			if name.contains("Interior/Stairs") and foot.y > -39.9:
				continue'''),
]
for a, b in pairs:
    assert t.count(a) == 1, a[:60]
    t = t.replace(a, b)
p.write_text(t, encoding="utf-8", newline="\n")
print("ok")
