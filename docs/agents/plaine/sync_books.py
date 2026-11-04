"""Reporte dans plaine.tscn la place des livres à fouiller calculée par tools/build_plaine.py.
Usage : python sync_books.py <dossier frontend>"""
import contextlib
import io
import re
import sys
from pathlib import Path

frontend = Path(sys.argv[1])
sys.path.insert(0, str(frontend / "tools"))
import build_plaine  # noqa: E402

output = io.StringIO()
with contextlib.redirect_stdout(output):
    build_plaine.build_interior()
places = {}
for line in output.getvalue().splitlines():
    match = re.match(r"\s+(\w+): \(([-\d.]+), ([-\d.]+), ([-\d.]+)\) vers \((-?\d), (-?\d)\)", line)
    if match:
        name, x, y, z, nx, nz = match.groups()
        places[name] = (float(x), float(y), float(z), int(nx), int(nz))

scene_path = frontend / "scenes" / "levels" / "plaine" / "plaine.tscn"
text = scene_path.read_text(encoding="utf-8")
for name, (x, y, z, nx, nz) in places.items():
    basis = build_plaine.rotation_y(build_plaine.facing((nx, nz)))
    transform = build_plaine.transform_text(basis, (x, y, z))
    pattern = re.compile(r'(\[node name="%s" type="Node3D" parent="Interior/Books"\]\n)transform = [^\n]+' % name)
    text, count = pattern.subn(lambda m: m.group(1) + "transform = " + transform, text)
    print(name, transform if count else "INTROUVABLE")
scene_path.write_text(text, encoding="utf-8", newline="\n")
