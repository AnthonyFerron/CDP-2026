extends SceneTree
const MODELS := [
"mini_dungeon/potion",
"food_kit/mortar-pestle",
"furniture_kit/bear",
"castle_kit/wall-narrow-gate",
"castle_kit/metal-gate",
"castle_kit/door",
"food_kit/bag-flat",
"survival_kit/bedroll-packed",
"nature_kit/plant_bushDetailed",
"food_kit/pot",
"food_kit/frying-pan",
"food_kit/plate",
"food_kit/cup",
"survival_kit/bottle",
"survival_kit/bottle-large",
"graveyard_kit/lightpost-all",
"fantasy_town_kit/stall-bench",
"survival_kit/tent-canvas",
"survival_kit/structure",
"survival_kit/structure-roof",
"survival_kit/floor",
"nature_kit/fence_simpleHigh",
"nature_kit/fence_corner",
"mini_dungeon/wood-support",
"mini_dungeon/key",
"graveyard_kit/crypt-door",
"graveyard_kit/brick-wall",
"graveyard_kit/stone-wall",
"graveyard_kit/border-pillar",
"graveyard_kit/pillar-small",
"graveyard_kit/rocks",
"nature_kit/rock_smallA",
"nature_kit/rock_smallFlatA",
"nature_kit/stone_smallA",
"food_kit/meat-raw",
"food_kit/sausage",
"food_kit/egg",
"food_kit/honey",
"fantasy_town_kit/stairs-stone",
"fantasy_town_kit/wall-wood-block-half",
"furniture_kit/kitchenBar",
"furniture_kit/benchCushionLow",
"furniture_kit/cabinetBedDrawer",
"food_kit/tomato",
"food_kit/lemon",
"food_kit/pear",
"food_kit/grapes",
"food_kit/leek",
"food_kit/eggplant",
"survival_kit/resource-stone",
"survival_kit/rock-flat",
"fantasy_town_kit/roof-gable",
"fantasy_town_kit/roof-high-flat",
"mini_arena/statue",
"mini_arena/column",
"mini_arena/block",
"graveyard_kit/hay-bale",
"castle_kit/siege-trebuchet-demolished",
"castle_kit/wall-pillar",
"castle_kit/tower-square-base-border",
"survival_kit/chest",
"mini_dungeon/trap",
"graveyard_kit/coffin-old",
"furniture_kit/rugRounded",
"furniture_kit/rugSquare",
"furniture_kit/chairCushion",
"furniture_kit/tableRound",
"furniture_kit/bookcaseClosed",
"food_kit/watermelon",
"food_kit/corn",
"food_kit/cheese-cut",
"food_kit/pie",
"food_kit/cake",
"food_kit/whisk",
"food_kit/steamer",
"food_kit/pan",
"food_kit/pot-lid"
]
func _initialize():
	for m in MODELS:
		var res = load("res://assets/models/kenney/%s.glb" % m)
		if res == null:
			print("%-44s MANQUANT" % m)
			continue
		var s: Node = res.instantiate()
		root.add_child(s)
		var box := AABB()
		var first := true
		for n in s.find_children("*", "MeshInstance3D", true, false):
			var b: AABB = n.global_transform * n.get_aabb()
			box = b if first else box.merge(b)
			first = false
		print("%-44s pos %s size %s" % [m, box.position.snappedf(0.01), box.size.snappedf(0.01)])
		s.free()
	quit()
