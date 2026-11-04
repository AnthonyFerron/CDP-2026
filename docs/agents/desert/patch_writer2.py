from pathlib import Path

p = Path("C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/write_desert_tscn.py")
t = p.read_text(encoding="utf-8")


def rep(old, new, count=1):
    global t
    assert t.count(old) == count, (t.count(old), old[:90])
    t = t.replace(old, new)


rep('''    ("PackedScene", K + "castle_kit/siege-ram-demolished.glb", "28_ram"),''',
    '''    ("PackedScene", K + "castle_kit/siege-ballista-demolished.glb", "28_ballista"),
    ("PackedScene", K + "castle_kit/siege-trebuchet-demolished.glb", "36_trebuchet"),''')
rep('''        'wreck_models = Array[PackedScene]([ExtResource("27_catapult"), ExtResource("28_ram")])',''',
    '''        'wreck_models = Array[PackedScene]([ExtResource("27_catapult"), ExtResource("28_ballista"), ExtResource("36_trebuchet")])',''')
p.write_text(t, encoding="utf-8", newline="\n")

s = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/scenes/levels/desert/desert_scatter.gd")
t = s.read_text(encoding="utf-8")
rep('''		if spot.distance_to(Vector2(wreck.x, wreck.y)) < 4.5 + margin:''', '''		if spot.distance_to(Vector2(wreck.x, wreck.y)) < 6.5 + margin:''')
rep('''@export var wreck_models: Array[PackedScene]''', '''## Catapulte, baliste et trébuchet démolis, dans l'ordre de WRECK_BOXES : aucun engin couvert d'un toit.
@export var wreck_models: Array[PackedScene]''')
s.write_text(t, encoding="utf-8", newline="\n")
print("ok")
