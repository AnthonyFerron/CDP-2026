from pathlib import Path

s = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/scenes/levels/desert/desert_scatter.gd")
t = s.read_text(encoding="utf-8")


def rep(text, old, new, count=1):
    assert text.count(old) == count, (text.count(old), old[:90])
    return text.replace(old, new)


t = rep(t, '''	_scatter(cactus_models, cactus_count, Vector2(3.0, 5.0), true, 0.17)
	_scatter(rock_models, rock_count, Vector2(2.0, 5.0), true, 0.3)
	_scatter(ruin_models, ruin_count, Vector2(2.5, 3.5), true, 0.32, true)''', '''	_scatter(cactus_models, cactus_count, Vector2(3.0, 5.0), true, 0.17, false, CACTUS_HEIGHTS)
	_scatter(rock_models, rock_count, Vector2(2.0, 5.0), true, 0.3, false, ROCK_HEIGHTS)
	_scatter(ruin_models, ruin_count, Vector2(2.5, 3.5), true, 0.32, true)''')
t = rep(t, '''func _scatter(models: Array[PackedScene], count: int, scale_range: Vector2, solid: bool, radius: float, tilted := false) -> void:''',
        '''func _scatter(models: Array[PackedScene], count: int, scale_range: Vector2, solid: bool, radius: float, tilted := false, heights: Array[float] = []) -> void:''')
t = rep(t, '''				var shape := CylinderShape3D.new()
				shape.radius = radius * scale_factor
				shape.height = 2.5
				collision.shape = shape
				collision.position = origin + Vector3.UP * 1.0''', '''				# Un cylindre à la hauteur du modèle : pas de mur invisible au-dessus d'un petit rocher.
				var height := (heights[group] if group < heights.size() else 0.5) * scale_factor + 0.15
				var shape := CylinderShape3D.new()
				shape.radius = radius * scale_factor
				shape.height = height
				collision.shape = shape
				collision.position = origin + Vector3.UP * height * 0.5''')
t = rep(t, '''## Boîte à l'échelle 1 des ruines couchées''', '''## Hauteur à l'échelle 1 des cactus et des rochers, dans l'ordre de leurs modèles.
const CACTUS_HEIGHTS: Array[float] = [0.75, 0.53]
const ROCK_HEIGHTS: Array[float] = [0.39, 0.45, 0.51]
## Boîte à l'échelle 1 des ruines couchées''')
s.write_text(t, encoding="utf-8", newline="\n")

# Panneaux sur poteaux : la collision du SignBoard couvre tout le dessous de la planche (mur invisible entre les
# poteaux). On la coupe et on pose la nôtre : deux poteaux et la planche.
w = Path("C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/write_desert_tscn.py")
t = w.read_text(encoding="utf-8")
t = rep(t, '''def ext(identifier):''', '''def posts_body(lines, parent, width, height, board_height):
    """Collision d'un SignBoard sur poteaux : ses deux poteaux et sa planche, rien entre les poteaux sous la planche."""
    node(lines, "PostsBody", "StaticBody3D", parent)
    top = board_height + height / 2 + 0.08
    for side, name in ((-1, "PostLeft"), (1, "PostRight")):
        lines += [f'[node name="{name}" type="CollisionShape3D" parent="{parent}/PostsBody"]',
                  f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {side * (width / 2 + 0.03):g}, {top / 2:g}, -0.1)",
                  f'shape = SubResource("BoxShape3D_post")', ""]
    lines += [f'[node name="Board" type="CollisionShape3D" parent="{parent}/PostsBody"]',
              f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {board_height:g}, 0)",
              f'shape = SubResource("BoxShape3D_board_{width:g}_{height:g}")', ""]


def ext(identifier):''')
t = rep(t, '''[sub_resource type="BoxShape3D" id="BoxShape3D_chest"]''', '''[sub_resource type="BoxShape3D" id="BoxShape3D_post"]
size = Vector3(0.16, 2.0, 0.16)

[sub_resource type="BoxShape3D" id="BoxShape3D_board_1.9_0.9"]
size = Vector3(2.0, 0.95, 0.2)

[sub_resource type="BoxShape3D" id="BoxShape3D_board_1.3_0.75"]
size = Vector3(1.4, 0.8, 0.2)

[sub_resource type="BoxShape3D" id="BoxShape3D_board_0.95_0.62"]
size = Vector3(1.05, 0.67, 0.2)

[sub_resource type="BoxShape3D" id="BoxShape3D_chest"]''')
# Le poteau fait 2 m : il ne doit pas dépasser du panneau ; on le règle par panneau avec une échelle.
t = rep(t, '''                    f'shape = SubResource("BoxShape3D_post")', ""]''', '''                    f'shape = SubResource("BoxShape3D_post")', ""]
        lines[-3] = f"transform = Transform3D(1, 0, 0, 0, {top / 2.0:g}, 0, 0, 0, 1, {side * (width / 2 + 0.03):g}, {top / 2:g}, -0.1)"''')
# Panneau d'entrée.
t = rep(t, '''        "board_size = Vector2(1.9, 0.9)", "board_height = 1.6", "line_height = 0.16"])''', '''        "board_size = Vector2(1.9, 0.9)", "board_height = 1.6", "line_height = 0.16", "collision = false"])
    posts_body(lines, "Exterior/Sign", 1.9, 0.9, 1.6)''')
# Panneaux du récit sur poteaux.
t = rep(t, '''            if style == 2:
                props.append("serif = false")
            node(lines, "Board", "Node3D", f"{parent}/{name}", props=props)''', '''            if style == 2:
                props.append("serif = false")
            if mount == 0:
                props.append("collision = false")
            node(lines, "Board", "Node3D", f"{parent}/{name}", props=props)
            if mount == 0:
                posts_body(lines, f"{parent}/{name}", size[0], size[1], height)''')
w.write_text(t, encoding="utf-8", newline="\n")
print("ok")
