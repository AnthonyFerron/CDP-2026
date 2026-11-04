"""Compare les boîtes MODEL_BOXES des modèles posés par build_marais.py avec leurs boîtes exactes (aabb_true.gd).

Usage : python check_boxes.py <dossier frontend>
"""
import re
import subprocess
import sys
from pathlib import Path

FRONTEND = Path(sys.argv[1])
sys.path.insert(0, str(FRONTEND / "tools"))
import build_marais as bm  # noqa: E402

used = set()
for scene_text in (bm.OUTPUT, bm.GROUNDED_OUTPUT, bm.CRYPT_OUTPUT):
    for match in re.finditer(r'path="res://assets/models/kenney/([^"]+)\.glb"', scene_text.read_text(encoding="utf-8")):
        used.add(match.group(1))
models = sorted(m for m in used if m in bm.MODEL_BOXES)
godot = "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/godot/Godot_v4.7.2-stable_win64_console.exe"
script = "C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/marais/tools/aabb_true.gd"
out = subprocess.run([godot, "--headless", "--path", str(FRONTEND), "--script", script, "--", *models],
                     capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=200).stdout
bad = 0
for line in out.splitlines():
    match = re.match(r'"([^"]+)": \(\(([-\d.]+), ([-\d.]+), ([-\d.]+)\), \(([-\d.]+), ([-\d.]+), ([-\d.]+)\)\),', line)
    if not match:
        continue
    model = match.group(1)
    true = [float(v) for v in match.groups()[1:]]
    stored = [v for pair in bm.MODEL_BOXES[model] for v in pair]
    diff = max(abs(a - b) for a, b in zip(true, stored))
    if diff > 0.02:
        bad += 1
        print(f"ÉCART {diff:.2f} {model} : stockée {bm.MODEL_BOXES[model]}, exacte {line.split(': ', 1)[1]}")
print(f"{len(models)} modèles contrôlés, {bad} écarts")
