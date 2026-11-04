from pathlib import Path

p = Path("C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/desert_walk_test.gd")
t = p.read_text(encoding="utf-8")
start = t.index("const OUTSIDE := [")
end = t.index("const CAVE := [")
outside = '''const OUTSIDE := [
	[Vector3(0, 0, 40), null, ""],
	[Vector3(0, 0, 14), null, ""],
	[Vector3(1.6, 0, 12.6), Vector3(2.6, 0, 12), "Ramasser la rune"],
	[Vector3(8.4, 0, 9.4), Vector3(8.4, 0, 7.6), "Ramasser la rune"],
	[Vector3(-4, 0, 6.4), Vector3(-4, 0, 8), "Maintenir"],
	[Vector3(-6.4, 0, 6.8), Vector3(-7, 1.4, 8), "Lire la stèle"],
	[Vector3(-10.5, 0, 7.6), Vector3(-10.5, 1.45, 6), "Lire la plaque"],
	[Vector3(-4, 0, 7.4), null, ""],
	[Vector3(-3, 0, 3), null, ""],
	[Vector3(-7.3, 0, -1), Vector3(-9, 0, -1), "Maintenir"],
	[Vector3(-8, 0, -10), null, ""],
	[Vector3(-11.6, 0, -12), null, ""],
	[Vector3(-15, 0, -12.8), Vector3(-15.4, 0, -14.4), "Ramasser la rune"],
	[Vector3(-15.6, 0, -12), Vector3(-17.6, 1.4, -12), "Lire la stèle"],
	[Vector3(-11.6, 0, -12), null, ""],
	[Vector3(8, 0, -12), null, ""],
	[Vector3(11.6, 0, -12), null, ""],
	[Vector3(14.6, 0, -10.8), Vector3(15.6, 0, -9.4), "Maintenir"],
	[Vector3(15.8, 0, -12), Vector3(17.6, 1.4, -12), "Lire la stèle"],
	[Vector3(13.4, 0, -13.6), Vector3(14.6, 0.85, -13.6), "Lire la tablette"],
	[Vector3(11.6, 0, -12), null, ""],
	[Vector3(8, 0, -12), null, ""],
	[Vector3(7.75, 0, -17.6), null, ""],
	[Vector3(7.75, 0, -21.3), null, ""],
	[Vector3(0, 0, -21.3), null, ""],
	[Vector3(-7.75, 0, -21.3), null, ""],
	[Vector3(-7.75, 0, -17.6), null, ""],
	[Vector3(-7, 0, -10), null, ""],
	[Vector3(8, 0, -10), null, ""],
	[Vector3(14, 0, -12), null, ""],
	[Vector3(18.3, 0, -8.6), null, ""],
	[Vector3(18.3, 0, -5.0), null, ""],
	[Vector3(30, 0, -2), null, ""],
	[Vector3(36.5, 0, -1.5), null, ""],
	[Vector3(38.2, 0, 2), null, ""],
	[Vector3(36, 0, 6.6), Vector3(34.2, 0.56, 4.75), "Lire le journal"],
	[Vector3(38.2, 0, 2), null, ""],
	[Vector3(30, 0, -2), null, ""],
	[Vector3(18.3, 0, -5.0), null, ""],
	[Vector3(18.3, 0, -8.6), null, ""],
	[Vector3(14, 0, -12), null, ""],
	[Vector3(-11.6, 0, -12), null, ""],
	[Vector3(-14, 0, -9.5), null, ""],
	[Vector3(-14, 0, -5.5), null, ""],
	[Vector3(-23, 0, -4.5), null, ""],
	[Vector3(-22, 0, -10), null, ""],
	[Vector3(-20.5, 0, -20), null, ""],
	[Vector3(-21, 0, -24), null, ""],
	[Vector3(-29, 0, -28.5), null, ""],
	[Vector3(-32.4, 0, -28.6), Vector3(-32.85, 0.9, -30.29), "Lire le carnet"],
	[Vector3(-29, 0, -28.5), null, ""],
	[Vector3(-21, 0, -24), null, ""],
	[Vector3(-20.5, 0, -20), null, ""],
	[Vector3(-22, 0, -10), null, ""],
	[Vector3(-23, 0, -4.5), null, ""],
	[Vector3(-14, 0, 8), null, ""],
	[Vector3(-14, 0, 30), null, ""],
	[Vector3(-18.6, 0, 44), null, ""],
	[Vector3(-18.6, 0, 46.5), Vector3(-20, 1.1, 46.5), "Lire la lettre"],
	[Vector3(-10, 0, 36), null, ""],
	[Vector3(-3, 0, 36), null, ""],
	[Vector3(0, 0, 12), null, ""],
	[Vector3(0, 0, -3.8), Vector3(0, 0, -6), "Soulever la trappe"],
]
'''
t = t[:start] + outside + t[end:]
t = t.replace('''	[Vector3(6.6, -40, -3.4), Vector3(7, -39.06, -1.9), "Ramasser la rune"],''', '''	[Vector3(7.4, -40, -3.0), Vector3(7, -39.06, -1.9), "Ramasser la rune"],''')
t = t.replace('''		if not reached:
			# On repart du point voulu, pour vérifier la suite du parcours.
			player.global_position = point + Vector3.UP * 0.3
			await wait(10)''', '''		if not reached:
			# On repart du point voulu, posé sur le sol, pour vérifier la suite du parcours.
			var ground: float = point.y if point.y < -20.0 else level.get_node("Exterior/Terrain").surface_height(point.x, point.z)
			player.global_position = Vector3(point.x, ground + 0.3, point.z)
			player.velocity = Vector3.ZERO
			await wait(10)''')
p.write_text(t, encoding="utf-8")
print("ok")
