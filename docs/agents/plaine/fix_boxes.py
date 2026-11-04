"""Remplace dans MODEL_BOXES (tools/build_plaine.py) les boîtes fausses par leur mesure (boxes_out.txt).
Les modèles du kit nature dont seule une plaque de 5 cm descend sous l'origine sont laissés : ils restent un peu
enfoncés, sans flotter. Usage : fix_boxes.py <tools>"""
import re
import sys
from pathlib import Path

tools = Path(sys.argv[1])
sys.path.insert(0, str(tools))
import build_plaine as bp  # noqa: E402

measured = {}
for line in Path(__file__).with_name("boxes_out.txt").read_text(encoding="utf-8").splitlines():
    parts = line.split("\t")
    values = [round(float(v), 2) + 0.0 for v in parts[1:7]]
    measured[parts[0]] = ((values[0], values[1], values[2]), (values[3], values[4], values[5]))

path = tools / "build_plaine.py"
text = path.read_text(encoding="utf-8")
changed = []
for model, (corner, size) in bp.MODEL_BOXES.items():
    real = measured[model]
    if max(abs(a - b) for a, b in zip(corner + size, real[0] + real[1])) <= 0.02:
        continue
    if model.startswith("nature_kit/") and abs(real[0][1] + 0.05) < 0.01 and abs(corner[1]) < 0.01:
        continue
    pattern = re.compile(r'(    "%s": )\(\([^)]*\), \([^)]*\)\),' % re.escape(model))
    new = f"(({real[0][0]:g}, {real[0][1]:g}, {real[0][2]:g}), ({real[1][0]:g}, {real[1][1]:g}, {real[1][2]:g})),"
    text, count = pattern.subn(lambda m: m.group(1) + new, text, count=1)
    if count:
        changed.append(f"{model}: {corner} {size} -> {real[0]} {real[1]}")
path.write_text(text, encoding="utf-8", newline="\n")
print("\n".join(changed))
