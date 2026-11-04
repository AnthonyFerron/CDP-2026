from pathlib import Path

S = Path("C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad")
t = (S / "desert_puzzle_test.gd").read_text(encoding="utf-8")
old = 'await walk_to(Vector3(1.6, -40, -8.6), "devant le coffre")'
assert old in t
t = t.replace(old, 'await walk_to(Vector3(5.2, -40, -8.0), "devant le coffre, dans le coin nord-est")')
t = t.replace("## Desert : runes ramassees", "## Desert (copie de l'agent du Desert : le coffre de pierre est passe dans le coin nord-est de la cave) : runes ramassees")
(S / "agents/desert/desert_puzzle_test.gd").write_text(t, encoding="utf-8", newline="\n")
print("ok")
