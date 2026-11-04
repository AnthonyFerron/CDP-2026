"""Remplace, dans tools/build_plaine.py, tout ce qui suit against_wall() par plaine_part.py."""
import sys
from pathlib import Path

target = Path(sys.argv[1])
part = Path(__file__).with_name("plaine_part.py").read_text(encoding="utf-8")
text = target.read_text(encoding="utf-8")
# Fin d'against_wall(), la dernière fonction partagée : tout ce qui suit appartient à la Plaine.
anchor = "    scene.add_box(center, size)\n"
start = text.find("def against_wall(")
cut = text.find(anchor, start) + len(anchor)
assert start > 0 and cut > start
target.write_text(text[:cut].rstrip() + "\n\n\n" + part, encoding="utf-8", newline="\n")
print("ok", len(text[:cut].splitlines()), "+", len(part.splitlines()))
