"""Planches et gravats sans collision : à moins de 22 cm du sol, sous la cheville, on les enjambe (plaine_part.py)."""
from pathlib import Path

path = Path(__file__).with_name("plaine_part.py")
text = path.read_text(encoding="utf-8")
old = '''        furniture_fit(scene, "survival_kit/resource-planks", (position[0], 0.0, position[1]), degrees, 3.0)'''
new = '''        # 2,5 : la pile ne monte qu'à 22 cm, on l'enjambe sans collision.
        furniture_fit(scene, "survival_kit/resource-planks", (position[0], 0.0, position[1]), degrees, 2.5)'''
assert text.count(old) == 2
text = text.replace(old, new)
old = '''    furniture_fit(scene, "graveyard_kit/debris", (-0.6, 0.0, -9.0), 30.0, 1.7)'''
assert old in text
text = text.replace(old, '''    furniture_fit(scene, "graveyard_kit/debris", (-0.6, 0.0, -9.0), 30.0, 1.4)''')
path.write_text(text, encoding="utf-8", newline="\n")
print("ok")
