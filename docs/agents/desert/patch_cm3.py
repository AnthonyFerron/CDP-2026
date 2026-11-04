from pathlib import Path

w = Path("C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/write_desert_tscn.py")
t = w.read_text(encoding="utf-8")


def rep(text, old, new, count=1):
    assert text.count(old) == count, (text.count(old), old[:90])
    return text.replace(old, new)


# Panneaux sur poteaux : la collision du SignBoard couvre tout le dessous de la planche (mur invisible entre les
# poteaux). On la coupe et on pose la nôtre : deux poteaux et la planche.
POSTED = [(1.9, 0.9, 1.6), (1.3, 0.75, 1.1), (0.95, 0.62, 0.85)]
t = rep(t, '''def ext(identifier):''', '''def posts_body(lines, parent, width, height, board_height):
    """Collision d'un SignBoard sur poteaux : ses deux poteaux et sa planche, rien entre les poteaux sous la planche."""
    node(lines, "PostsBody", "StaticBody3D", parent)
    top = board_height + height / 2 + 0.08
    for side, name in ((-1, "PostLeft"), (1, "PostRight")):
        node(lines, name, "CollisionShape3D", f"{parent}/PostsBody", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {side * (width / 2 + 0.03):g}, {top / 2:g}, -0.1)",
            f'shape = SubResource("BoxShape3D_post_{top:g}")'])
    node(lines, "Plank", "CollisionShape3D", f"{parent}/PostsBody", props=[
        f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {board_height:g}, 0)",
        f'shape = SubResource("BoxShape3D_board_{width:g}_{height:g}")'])


def ext(identifier):''')
shapes = []
for width, height, board_height in POSTED:
    top = board_height + height / 2 + 0.08
    shapes.append(f'''[sub_resource type="BoxShape3D" id="BoxShape3D_post_{top:g}"]
size = Vector3(0.16, {top:g}, 0.16)

[sub_resource type="BoxShape3D" id="BoxShape3D_board_{width:g}_{height:g}"]
size = Vector3({width + 0.1:g}, {height + 0.05:g}, 0.2)
''')
t = rep(t, '''[sub_resource type="BoxShape3D" id="BoxShape3D_chest"]''', "\n".join(shapes) + '''
[sub_resource type="BoxShape3D" id="BoxShape3D_chest"]''')
t = rep(t, '''        "board_size = Vector2(1.9, 0.9)", "board_height = 1.6", "line_height = 0.16"])''', '''        "board_size = Vector2(1.9, 0.9)", "board_height = 1.6", "line_height = 0.16", "collision = false"])
    posts_body(lines, "Exterior/Sign", 1.9, 0.9, 1.6)''')
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
