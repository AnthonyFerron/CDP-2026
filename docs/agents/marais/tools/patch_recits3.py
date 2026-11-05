"""Récit du Marais, fin : une faible lueur chaude derrière les deux panneaux sur poteaux de l'arrivée. On voit leur dos
en revenant vers le portail, et il restait noir à contre-jour de la lune (sign_board.gd, lui, n'est pas à nous)."""
import sys
from pathlib import Path

PATH = Path(sys.argv[1]) / "tools" / "write_marais_tscn.py"
text = PATH.read_text(encoding="utf-8")
OLD = '''    # L'avis du port, au bout du débarcadère, tourné vers l'arrivée ;'''
NEW = '''    # Derrière l'accueil et l'avis du port, vus de dos en revenant vers le portail : une faible lueur chaude.
    for parent, x, y, z in (("Clues/Welcome", -0.45, 0.3, -1.13), ("Clues/Notice", 0.6, 0.2, -0.67)):
        node(lines, "BackLight", "OmniLight3D", parent, props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, {z:g})",
            "light_color = Color(1, 0.8, 0.55, 1)", "light_energy = 0.6", "omni_range = 2.5",
            "distance_fade_enabled = true", "distance_fade_begin = 38.0", "distance_fade_length = 8.0"])
    # L'avis du port, au bout du débarcadère, tourné vers l'arrivée ;'''
if text.count(OLD) != 1:
    raise SystemExit(f"motif trouvé {text.count(OLD)} fois")
PATH.write_text(text.replace(OLD, NEW), encoding="utf-8", newline="\n")
print("write_marais_tscn.py : lueurs au dos des panneaux de l'arrivée")
