"""Lumières du Marais pour le web : portées ajustées aux pièces, effacement au loin dehors, ombres de la lune en deux
tranches. Patch de write_marais_tscn.py (relançable : chaque remplacement vérifie qu'il s'applique une fois)."""
from pathlib import Path

PATH = Path(__file__).resolve().parent.parent / "write_marais_tscn.py"
text = PATH.read_text(encoding="utf-8")

FADE = '"distance_fade_enabled = true", "distance_fade_begin = 38.0", "distance_fade_length = 8.0"'

REPLACEMENTS = [
    ('"shadow_enabled = true",\n        "directional_shadow_max_distance = 60.0"])',
     '"shadow_enabled = true",\n        "directional_shadow_mode = 1", "directional_shadow_max_distance = 50.0"])'),
    ('"omni_range = 7.0", "flicker = 0.2"])', f'"omni_range = 7.0", "flicker = 0.2", {FADE}])'),
    ('"omni_range = 9.0", "flicker = 0.1"])', f'"omni_range = 9.0", "flicker = 0.1", {FADE}])'),
    ('"omni_range = 5.5", "flicker = 0.15"])', f'"omni_range = 5.5", "flicker = 0.15", {FADE}])'),
    ('"omni_range = 8.0", "flicker = 0.25"])', f'"omni_range = 8.0", "flicker = 0.25", {FADE}])'),
    ('    for name, x, y, z, energy, color in (("LightEntry", 0, 3.3, 1.0, 1.2, warm), ("LightStairs", 0, 7.4, 11.4, 0.7, cold),\n'
     '                                         ("LightStairsMid", 0, 5.0, 6.4, 0.9, warm),\n'
     '                                         ("LightHall", 0, 3.3, -12, 2.2, warm), ("LightEast", 24, 3.3, -12, 1.6, warm), ("LightEastTomb", 20.6, 1.5, -12, 0.5, warm),\n'
     '                                         ("LightWest", -24, 3.3, -12, 1.4, warm), ("LightOssuary", -18, 3.3, 2, 0.9, warm),\n'
     '                                         ("LightGuards", 18, 3.3, 2, 0.9, warm)):\n'
     '        node(lines, name, "OmniLight3D", "Interior", props=[\n'
     '            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, {z:g})", \'script = ExtResource("14_flicker")\',\n'
     '            f"light_color = {color}", f"light_energy = {energy:g}", "omni_range = 12.0", "flicker = 0.15"])',
     '    # Pour le web, chaque lumière ne porte que sur sa pièce : dans le rendu Compatibility, chaque lumière qui touche\n'
     '    # un objet le redessine une fois de plus.\n'
     '    for name, x, y, z, energy, color, reach in (\n'
     '            ("LightEntry", 0, 3.3, 1.0, 1.2, warm, 7.0), ("LightStairs", 0, 7.4, 11.4, 0.7, cold, 6.5),\n'
     '            ("LightStairsMid", 0, 5.0, 6.4, 0.9, warm, 6.5), ("LightHall", 0, 3.3, -12, 2.2, warm, 12.0),\n'
     '            ("LightEast", 24, 3.3, -12, 1.6, warm, 9.5), ("LightEastTomb", 20.6, 1.5, -12, 0.5, warm, 4.5),\n'
     '            ("LightWest", -24, 3.3, -12, 1.4, warm, 9.5), ("LightOssuary", -18, 3.3, 2, 0.9, warm, 7.5),\n'
     '            ("LightGuards", 18, 3.3, 2, 0.9, warm, 7.5)):\n'
     '        node(lines, name, "OmniLight3D", "Interior", props=[\n'
     '            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, {z:g})", \'script = ExtResource("14_flicker")\',\n'
     '            f"light_color = {color}", f"light_energy = {energy:g}", f"omni_range = {reach:g}", "flicker = 0.15"])'),
]

for old, new in REPLACEMENTS:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"motif trouvé {count} fois : {old[:70]!r}")
    text = text.replace(old, new)
PATH.write_text(text, encoding="utf-8", newline="\n")
print("write_marais_tscn.py : lumières patchées")
