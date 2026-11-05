"""Récit du Marais, suite : une lanterne au pied de l'ardoise d'Ada (sa face, tournée vers l'allée, est à contre-jour
de la lune), et les deux panneaux muraux de la crypte posés à 1 cm du panneau central du mur au lieu de 3."""
import sys
from pathlib import Path

FRONTEND = Path(sys.argv[1])


def patch(path, replacements):
    text = path.read_text(encoding="utf-8")
    for old, new in replacements:
        count = text.count(old)
        if count != 1:
            raise SystemExit(f"{path.name} : motif trouvé {count} fois : {old[:80]!r}")
        text = text.replace(old, new)
    path.write_text(text, encoding="utf-8", newline="\n")
    print(f"{path.name} : patché")


patch(FRONTEND / "tools" / "build_marais.py", [
    ('''    scene.place("graveyard_kit/bench-damaged", (15.0, GROUND, 2.85), 180.0, 3.0, height=1.5)''',
     '''    scene.place("graveyard_kit/bench-damaged", (15.0, GROUND, 2.85), 180.0, 3.0, height=1.5)
    # La lanterne d'Ada, au pied de son ardoise (posée dans marais.tscn), entre sa tombe et la suivante.
    scene.place("graveyard_kit/lantern-candle", (12.75, GROUND, 3.75), 15.0, 2.0, height=True)'''),
])

patch(FRONTEND / "tools" / "write_marais_tscn.py", [
    ('''    sign(lines, "Board", "Clues/AdaSlate", (0.0, -0.9, 0.0), 180.0, "Leçon d'Ada\\nBRUME devient DPWKG", 1, 0,
         (1.0, 0.6), 1.15, 0.13, double_sided=True)''',
     '''    sign(lines, "Board", "Clues/AdaSlate", (0.0, -0.9, 0.0), 180.0, "Leçon d'Ada\\nBRUME devient DPWKG", 1, 0,
         (1.0, 0.6), 1.15, 0.13, double_sided=True)
    # La face de l'ardoise regarde l'allée, au nord, à contre-jour de la lune : la lanterne posée à son pied l'éclaire.
    node(lines, "Light", "OmniLight3D", "Clues/AdaSlate", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.85, -0.3, -0.65)", 'script = ExtResource("14_flicker")',
        "light_color = Color(1, 0.78, 0.45, 1)", "light_energy = 0.9", "omni_range = 3.5", "flicker = 0.15",
        "distance_fade_enabled = true", "distance_fade_begin = 38.0", "distance_fade_length = 8.0"])'''),
    ('''            ("OssuaryRegister", -14.0 - PANEL_FACE, -1.0,''',
     '''            ("OssuaryRegister", -14.0 - BOARD_FACE, -1.0,'''),
    ('''            ("GuardsOath", 14.0 + PANEL_FACE, 1.0,''',
     '''            ("GuardsOath", 14.0 + BOARD_FACE, 1.0,'''),
    ('''PANEL_FACE = 0.63
''',
     '''PANEL_FACE = 0.63
# Panneaux muraux du récit : à 1 cm du panneau central du mur.
BOARD_FACE = 0.61
'''),
])
