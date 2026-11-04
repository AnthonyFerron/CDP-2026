"""Compare MODEL_BOXES aux boîtes mesurées (boxes_out.txt) : écarts de plus de 2 cm. Usage : compare_boxes.py <tools>"""
import sys
from pathlib import Path

sys.path.insert(0, sys.argv[1])
import build_plaine as bp  # noqa: E402

measured = {}
for line in Path(__file__).with_name("boxes_out.txt").read_text(encoding="utf-8").splitlines():
    parts = line.split("\t")
    if len(parts) < 7:
        print("absent :", line)
        continue
    values = [float(v) for v in parts[1:7]]
    measured[parts[0]] = ((values[0], values[1], values[2]), (values[3], values[4], values[5]), parts[7])
for model, (corner, size) in bp.MODEL_BOXES.items():
    (mc, ms, meshes) = measured[model]
    delta = max(abs(a - b) for a, b in zip(corner + size, mc + ms))
    if delta > 0.02:
        print(f"{model}\n    écrit  {corner} {size}\n    mesuré {tuple(round(v, 2) for v in mc)} "
              f"{tuple(round(v, 2) for v in ms)}  (écart {delta:.2f})\n    {meshes[:200]}")
