extends SceneTree
func _initialize():
	for m in ["furniture_kit/bedSingle", "nature_kit/bridge_wood", "castle_kit/tower-square-top", "castle_kit/tower-square-mid-windows", "castle_kit/tower-square-base", "castle_kit/tower-square-mid", "castle_kit/tower-square-roof", "castle_kit/wall-narrow", "castle_kit/wall-half", "castle_kit/gate", "castle_kit/siege-tower-demolished", "castle_kit/siege-ram-demolished", "fantasy_town_kit/stall-red", "fantasy_town_kit/stall", "fantasy_town_kit/stall-green", "furniture_kit/desk", "furniture_kit/sideTableDrawers", "furniture_kit/kitchenCabinetDrawer", "furniture_kit/bookcaseClosedDoors", "furniture_kit/tableCloth", "survival_kit/box-large", "furniture_kit/chairDesk", "furniture_kit/coatRackStanding"]:
		var s: Node = load("res://assets/models/kenney/%s.glb" % m).instantiate()
		root.add_child(s)
		for n in s.find_children("*", "MeshInstance3D", true, false):
			var b: AABB = n.global_transform * n.get_aabb()
			print("%-40s %-20s pos %s size %s" % [m, n.name, b.position.snappedf(0.01), b.size.snappedf(0.01)])
		s.free()
	quit()
