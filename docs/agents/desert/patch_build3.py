from pathlib import Path

p = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/tools/build_desert.py")
t = p.read_text(encoding="utf-8")


def rep(old, new, count=1):
    global t
    assert t.count(old) == count, (t.count(old), old[:90])
    t = t.replace(old, new)


rep('''# Teinte des congères : la couleur du sable au soleil.
SAND_TINT = (0.86, 0.66, 0.42)''', '''# Teinte des congères : la couleur du sable au soleil.
SAND_TINT = (0.86, 0.66, 0.42)
# Côté des cases qui découpent les formes qui s'effacent au loin : la distance de visibilité d'un MultiMesh se mesure
# jusqu'au centre de sa boîte, il en faut un par case pour que rien ne disparaisse loin du centre de la carte.
CHUNK = 32.0''')
rep('''            extra = []
            if not shadow:
                extra.append("cast_shadow = 0")
            if fade:
                extra += [f"visibility_range_end = {fmt(fade)}", "visibility_range_fade_mode = 1"]
            if len(instances) >= 3:
                values = []
                for basis, origin in instances:
                    for row in range(3):
                        values += [basis[row][0], basis[row][1], basis[row][2], origin[row]]
                resources += [f'[sub_resource type="MultiMesh" id="MultiMesh_{index}"]', "transform_format = 1",
                              f"instance_count = {len(instances)}", f'mesh = SubResource("Mesh_{index}")',
                              "buffer = PackedFloat32Array(" + ", ".join(fmt(v) for v in values) + ")", ""]
                nodes += [f'[node name="{kind}_{index}" type="MultiMeshInstance3D" parent="Shapes"]',
                          f'multimesh = SubResource("MultiMesh_{index}")', *extra, ""]
            else:''', '''            extra = []
            if not shadow:
                extra.append("cast_shadow = 0")
            if fade:
                extra += [f"visibility_range_end = {fmt(fade)}", "visibility_range_end_margin = 8.0",
                          "visibility_range_fade_mode = 1"]
            if len(instances) >= 3:
                # Une forme qui s'efface au loin est découpée en cases, chacune avec sa propre distance.
                groups = {}
                for basis, origin in instances:
                    cell = (math.floor(origin[0] / CHUNK), math.floor(origin[2] / CHUNK)) if fade else (0, 0)
                    groups.setdefault(cell, []).append((basis, origin))
                for part, members in enumerate(groups.values()):
                    values = []
                    for basis, origin in members:
                        for row in range(3):
                            values += [basis[row][0], basis[row][1], basis[row][2], origin[row]]
                    resources += [f'[sub_resource type="MultiMesh" id="MultiMesh_{index}_{part}"]', "transform_format = 1",
                                  f"instance_count = {len(members)}", f'mesh = SubResource("Mesh_{index}")',
                                  "buffer = PackedFloat32Array(" + ", ".join(fmt(v) for v in values) + ")", ""]
                    nodes += [f'[node name="{kind}_{index}_{part}" type="MultiMeshInstance3D" parent="Shapes"]',
                              f'multimesh = SubResource("MultiMesh_{index}_{part}")', *extra, ""]
            else:''')
p.write_text(t, encoding="utf-8", newline="\n")
print("ok")
