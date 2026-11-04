from pathlib import Path

p = Path("C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/desert_audit_test.gd")
t = p.read_text(encoding="utf-8")
old = '''const PLACES := [
	["arche d'entrée", Vector2(0, 16), false],
	["centre de l'esplanade", Vector2(0, -2), false],
	["campement de la caravane", Vector2(-31, -26), false],
]'''
new = '''const PLACES := [
	["arche d'entrée", Vector2(0, 16), false],
	["allée des obélisques", Vector2(0, 32), false],
	["salle des colonnes", Vector2(0, -2), false],
	["chambre du levant", Vector2(-16, -11), false],
	["chambre du zénith", Vector2(16, -11), false],
	["portique du sanctuaire englouti", Vector2(0, -25), false],
	["campement de la caravane", Vector2(-33, -26), false],
	["puits de l'oasis", Vector2(36.2, 0.2), false],
	["bassin asséché", Vector2(41, -3), false],
	["abords de la citerne", Vector2(-30, 3), false],
	["tête colossale", Vector2(-29, 34), false],
	["poste de garde", Vector2(36, 27), false],
	["colonnade engloutie", Vector2(-20, -44), false],
	["porte des vents", Vector2(21, -41), false],
	["tombes des caravaniers", Vector2(-24, 45), false],
	["sous les côtes de la bête des sables", Vector2(26, 50), false],
	["pied de l'escalier de la cave", Vector2(0, -1), true],
	["coin du coffre de pierre", Vector2(6, -8.4), true],
	["pupitre de lecture", Vector2(2.6, -2.8), true],
]'''
assert old in t
t = t.replace(old, new)
p.write_text(t, encoding="utf-8", newline="\n")
print("ok")
