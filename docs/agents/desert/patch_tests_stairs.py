from pathlib import Path

D = Path("C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert")


def rep(text, old, new, count=1):
    assert text.count(old) == count, (text.count(old), old[:90])
    return text.replace(old, new)


b = D / "desert_bounds_test.gd"
t = b.read_text(encoding="utf-8")
t = rep(t, '''const CEILING := -40.0 + 4.15
''', '''const CEILING := -40.0 + 4.15
## Plafond de la cage de l'escalier, plus haut, au sud de z = 0.
const SHAFT_CEILING := -40.0 + 5.4
''')
t = rep(t, '''				and box[2] < CEILING - 1.75 and box[3] > -40.5)''', '''				and box[2] < 0.0 and box[3] > -40.5)''')
t = rep(t, '''		top = maxf(top, p.y)
		bottom = minf(bottom, p.y)''', '''		# Marge entre la tête et le plafond au-dessus d'elle : négative tant que le joueur reste dessous.
		top = maxf(top, p.y + 1.75 - (SHAFT_CEILING if p.z > 0.05 else CEILING))
		bottom = minf(bottom, p.y)''')
t = rep(t, '''			check("cave vers %3d° depuis %s : enfermé (x %.1f..%.1f, z %.1f..%.1f, pieds au plus %.2f)" % [''', '''			check("cave vers %3d° depuis %s : enfermé (x %.1f..%.1f, z %.1f..%.1f, tête sous le plafond de %.2f m)" % [''')
t = rep(t, '''				roundi(rad_to_deg(angle)), Vector2(origin.x, origin.z), box[0].x, box[1].x, box[0].y, box[1].y, box[2]],''', '''				roundi(rad_to_deg(angle)), Vector2(origin.x, origin.z), box[0].x, box[1].x, box[0].y, box[1].y, -box[2]],''')
b.write_text(t, encoding="utf-8")

w = D / "desert_walk_test.gd"
t = w.read_text(encoding="utf-8")
t = rep(t, '''	[Vector3(0, -40, -0.9), Vector3(0, -38.8, 0.6), "Remonter"],
]''', '''	[Vector3(0, -40, -0.9), Vector3(0, -38.4, 1.7), "Remonter"],
	# L'escalier se monte et se descend en entier ; la sortie marche en bas comme en haut.
	[Vector3(0, -37.3, 3.0), Vector3(0, -38.4, 1.7), "Remonter"],
	[Vector3(0, -40, -1.6), null, ""],
	[Vector3(0, -37.3, 3.0), Vector3(0, -38.4, 1.7), "Remonter"],
]''')
t = rep(t, '''	await _route(CAVE)
	await press("interact")''', '''	await _route(CAVE)
	check("en haut de l'escalier (hauteur %.2f)" % (player.global_position.y + 40.0), player.global_position.y > -37.6)
	await press("interact")''')
w.write_text(t, encoding="utf-8")
print("ok")
