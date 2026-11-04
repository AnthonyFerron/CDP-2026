"""Épaves, tas de pierres, tentes, charrettes : plus de boîte dans le script, leur enveloppe convexe est faite au
chargement par plaine.gd (plaine_part.py)."""
import re
from pathlib import Path

path = Path(__file__).with_name("plaine_part.py")
text = path.read_text(encoding="utf-8")
models = ("siege-trebuchet-demolished", "siege-catapult-demolished", "siege-ballista-demolished",
          "siege-ram-demolished", "castle_kit/{model}", "fantasy_town_kit/rock-", "resource-stone-large",
          "tower-hexagon-top-wood", "tent_detailedOpen", "fantasy_town_kit/cart")
count = 0
lines = text.split("\n")
index = 0
while index < len(lines):
    line = lines[index]
    if "furniture_fit(scene" in line and any(name in line for name in models) or (
            "furniture_fit(scene, model, position, degrees, scale" in line):
        # Rassemble l'appel jusqu'à sa parenthèse fermante.
        end = index
        while lines[end].count("(") - lines[end].count(")") > 0 and not lines[end].rstrip().endswith(")") or \
                sum(l.count("(") - l.count(")") for l in lines[index:end + 1]) > 0:
            end += 1
        call = "\n".join(lines[index:end + 1])
        new = re.sub(r",\s*height=[^,()]*(\([^)]*\))?[^,()]*", "", call)
        new = re.sub(r",\s*footprint=[\d.]+", "", new)
        if new != call:
            count += 1
            lines[index:end + 1] = new.split("\n")
    index += 1
text = "\n".join(lines)
path.write_text(text, encoding="utf-8", newline="\n")
print("appels modifiés :", count)
