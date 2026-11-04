REPLACEMENTS = [
('("BakerySign", 47.7, 37.9, -90.0,', '("BakerySign", 47.74, 36.0, -90.0,'),
('("MillSign", 56.7, 52.0, -90.0,', '("MillSign", 56.74, 50.0, -90.0,'),
('("StablesSign", -61.7, -46.1, 90.0,', '("StablesSign", -61.74, -44.0, 90.0,'),
('("BarracksSign", -50.3, -61.7, 0.0,', '("BarracksSign", -48.0, -61.74, 0.0,'),
('("ApothecarySign", -55.7, 30.0, 90.0,', '("ApothecarySign", -55.74, 32.0, 90.0,'),
('("ScriptoriumSign", -69.7, -16.1, 90.0,', '("ScriptoriumSign", -69.74, -14.0, 90.0,'),
('''        sign(lines, "Sign", f"Lore/{name}", board, style=style, mount=mount, size=size, roof=name == "NoticeBoard",
             line=0.13 if len(board) > 18 else 0.16)''',
 '''        # Les enseignes murales sont fixées au-dessus de la porte, sur le mur voûté qui tient debout même en ruine.
        sign(lines, "Sign", f"Lore/{name}", board, style=style, mount=mount, size=size, roof=name == "NoticeBoard",
             line=0.13 if len(board) > 18 else 0.16, height=3.42 if mount == "WALL" else None)'''),
('''             "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.35, -1.418)", pixel=0.0032, color="Color(0.55, 0.43, 0.2, 1)")''',
 '''             "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.25, -1.418)", pixel=0.0021, color="Color(0.5, 0.38, 0.16, 1)")'''),
('''             "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.95, -0.462)", pixel=0.0021, color="Color(0.14, 0.13, 0.12, 1)")''',
 '''             "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.75, -0.462)", pixel=0.0014, color="Color(0.14, 0.13, 0.12, 1)")'''),
]
