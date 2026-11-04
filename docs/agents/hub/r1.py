REPLACEMENTS = [
('''        sign(lines, "Sign", f"Portals/{name}", label, style="STONE", size=(1.7, 0.55), line=0.14,
             transform=at(px - x, 0, pz - z, 1.0, yaw_toward(dx, dz) - (math.degrees(math.atan2(-x, -z)))))''',
'''        sign(lines, name, "PortalSigns", label, style="STONE", size=(1.7, 0.55), line=0.14,
             transform=at(px, 0, pz, 1.0, yaw_toward(dx, dz)))'''),
('''    """Panneau de pierre au bord du chemin, quelques pas avant chaque portail, tourné vers le village."""
''', '''    """Panneau de pierre au bord du chemin, quelques pas avant chaque portail, tourné vers le village."""
    node(lines, "PortalSigns", "Node3D")
'''),
('''        rad = math.radians(angle)
        middle = (2.86 + 3.92) / 2
        node(lines''', '''        rad = math.radians(angle)
        node(lines'''),
('size = Vector3(0.12, 0.02, 2.4)', 'size = Vector3(0.12, 0.02, 1.5)'),
('''"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.72, 0.322)",
                 pixel=0.0022,''', '''"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.78, 0.322)",
                 pixel=0.0012,'''),
('''f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, {-HALL_HALF_DEPTH + 1.5:g})", f'script = {ext("10_readable")}',''',
 '''f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 1.4, 0, {-HALL_HALF_DEPTH + 2.9:g})", f'script = {ext("10_readable")}','''),
('''             f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 4.4, {-1.5 + 0.012:g})", pixel=0.0055,''',
 '''             f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -1.4, 4.4, {-2.9 + 0.012:g})", pixel=0.0055,'''),
('''    "Merlon": (2.3, HALL_Z + 3.4, yaw_toward(CIRCLE[0] - 2.3, CIRCLE[1] - 3.4), 0.1),
    "Codeon": (0.0, HALL_Z - 2.7, 0.0, 0.1),''', '''    "Merlon": (1.2, HALL_Z + 4.1, yaw_toward(CIRCLE[0] - 1.2, CIRCLE[1] - 4.1), 0.1),
    "Codeon": (-1.3, HALL_Z - 2.6, 20.0, 0.1),'''),
('''    engraved(lines, "Text", f"Lore/{name}", "AUX SOLDATS DE CODIA\\n5804 - 5812",
             "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.55, -0.462)", pixel=0.0026, color="Color(0.14, 0.13, 0.12, 1)")''',
 '''    engraved(lines, "Text", f"Lore/{name}", "AUX SOLDATS\\nDE CODIA\\n5804 - 5812",
             "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.95, -0.462)", pixel=0.0021, color="Color(0.14, 0.13, 0.12, 1)")'''),
]
