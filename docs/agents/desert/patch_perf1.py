from pathlib import Path

g = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/scenes/levels/desert/desert.gd")
t = g.read_text(encoding="utf-8")


def rep(text, old, new, count=1):
    assert text.count(old) == count, (text.count(old), old[:90])
    return text.replace(old, new)


t = rep(t, '''const SMALL_PROP_RANGE := 70.0
const SMALL_PROP_SIZE := 1.6
''', '''const SMALL_PROP_RANGE := 70.0
const SMALL_PROP_SIZE := 1.6
## Côté des cases où les maillages fixes des ruines sont regroupés par matériau.
const MERGE_CHUNK := 32.0
''')
t = rep(t, '''	_fade_small_props($Exterior/Ruins)
''', '''	_merge_static($Exterior/Ruins)
	_fade_small_props($Exterior/Ruins)
''')
t = rep(t, '''## Les petits modèles des ruines''', '''## Regroupe les maillages fixes des ruines, modèles du kit et formes simples, par matériau et par case de 32 m :
## quelques dizaines d'appels de dessin au lieu de plusieurs centaines, ombres comprises. Les petits objets forment
## des groupes à part, sans ombre, qui s'effacent au loin case par case. Les MultiMesh restent tels quels.
func _merge_static(root: Node3D) -> void:
	var tools := {}
	var materials := {}
	var sources: Array[MeshInstance3D] = []
	var inverse := root.global_transform.affine_inverse()
	for mesh: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		if not mesh.mesh or not mesh.visible:
			continue
		var xform := inverse * mesh.global_transform
		if xform.basis.determinant() <= 0.0:
			continue
		var box := mesh.global_transform * mesh.get_aabb()
		var small := maxf(box.size.x, maxf(box.size.y, box.size.z)) < SMALL_PROP_SIZE
		var center := box.get_center()
		var cell := Vector2i(floori(center.x / MERGE_CHUNK), floori(center.z / MERGE_CHUNK))
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface)
			if not material:
				continue
			var key := "%d_%d_%d_%d" % [material.get_instance_id(), cell.x, cell.y, int(small)]
			if not tools.has(key):
				var tool := SurfaceTool.new()
				tool.begin(Mesh.PRIMITIVE_TRIANGLES)
				tools[key] = tool
				materials[key] = [material, small]
			(tools[key] as SurfaceTool).append_from(mesh.mesh, surface, xform)
		sources.append(mesh)
	var merged := Node3D.new()
	merged.name = "Merged"
	root.add_child(merged)
	for key: String in tools:
		var instance := MeshInstance3D.new()
		instance.mesh = (tools[key] as SurfaceTool).commit()
		instance.material_override = materials[key][0]
		if materials[key][1]:
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			instance.visibility_range_end = SMALL_PROP_RANGE
			instance.visibility_range_end_margin = 10.0
			instance.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		merged.add_child(instance)
	for mesh in sources:
		mesh.queue_free()


## Les petits modèles des ruines''')
g.write_text(t, encoding="utf-8", newline="\n")

w = Path("C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/write_desert_tscn.py")
t = w.read_text(encoding="utf-8")
t = rep(t, '''        "directional_shadow_max_distance = 80.0"])''', '''        "directional_shadow_mode = 1", "directional_shadow_max_distance = 55.0"])''')
w.write_text(t, encoding="utf-8", newline="\n")

s = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/scenes/levels/desert/desert_scatter.gd")
t = s.read_text(encoding="utf-8")
t = rep(t, '''		_add_multimesh(item[0], transforms, 55.0)''', '''		_add_multimesh(item[0], transforms, 55.0, false)''')
t = rep(t, '''func _add_multimesh(mesh: Mesh, transforms: Array[Transform3D], range_end := -1.0) -> void:
	if range_end < 0.0:
		range_end = detail_range
	if range_end == 0.0:
		_add_multimesh_part(mesh, transforms, 0.0)
		return''', '''func _add_multimesh(mesh: Mesh, transforms: Array[Transform3D], range_end := -1.0, shadow := true) -> void:
	if range_end < 0.0:
		range_end = detail_range
	if range_end == 0.0:
		_add_multimesh_part(mesh, transforms, 0.0, shadow)
		return''')
t = rep(t, '''		_add_multimesh_part(mesh, part, range_end)''', '''		_add_multimesh_part(mesh, part, range_end, shadow)''')
t = rep(t, '''func _add_multimesh_part(mesh: Mesh, transforms: Array[Transform3D], range_end: float) -> MultiMeshInstance3D:''',
        '''func _add_multimesh_part(mesh: Mesh, transforms: Array[Transform3D], range_end: float, shadow := true) -> MultiMeshInstance3D:''')
t = rep(t, '''	instance.visibility_range_end = range_end
	if range_end > 0.0:''', '''	instance.visibility_range_end = range_end
	if not shadow:
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if range_end > 0.0:''')
s.write_text(t, encoding="utf-8", newline="\n")
print("ok")
