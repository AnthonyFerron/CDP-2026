extends SceneTree
const MODELS := [
"fantasy_town_kit/fountain-round", "fantasy_town_kit/fountain-round-detail", "fantasy_town_kit/fountain-center",
"fantasy_town_kit/lantern", "fantasy_town_kit/cart", "fantasy_town_kit/cart-high", "fantasy_town_kit/stall-stool",
"fantasy_town_kit/chimney", "fantasy_town_kit/chimney-base", "fantasy_town_kit/chimney-top", "fantasy_town_kit/fence", "fantasy_town_kit/fence-broken",
"fantasy_town_kit/fence-gate", "fantasy_town_kit/poles", "fantasy_town_kit/poles-horizontal", "fantasy_town_kit/overhang",
"fantasy_town_kit/banner-green", "fantasy_town_kit/banner-red", "fantasy_town_kit/wheel", "fantasy_town_kit/rock-small", "fantasy_town_kit/rock-large", "fantasy_town_kit/rock-wide",
"fantasy_town_kit/hedge", "fantasy_town_kit/planks-opening", "fantasy_town_kit/watermill", "fantasy_town_kit/windmill", "fantasy_town_kit/blade",
"fantasy_town_kit/roof-flat", "fantasy_town_kit/roof", "fantasy_town_kit/pillar-wood", "fantasy_town_kit/wall-block", "fantasy_town_kit/wall-block-half",
"castle_kit/rocks-small", "castle_kit/rocks-large", "castle_kit/flag", "castle_kit/flag-banner-long", "castle_kit/flag-banner-short", "castle_kit/tree-log", "castle_kit/tree-trunk",
"castle_kit/siege-catapult-demolished", "castle_kit/siege-ballista-demolished", "castle_kit/wall-narrow-wood-fence", "castle_kit/wall-narrow-wood",
"survival_kit/bucket", "survival_kit/barrel-open", "survival_kit/box-open", "survival_kit/box-large-open", "survival_kit/tool-axe", "survival_kit/tool-hammer", "survival_kit/tool-hoe", "survival_kit/tool-shovel",
"survival_kit/resource-planks", "survival_kit/resource-wood", "survival_kit/workbench-anvil", "survival_kit/workbench", "survival_kit/campfire-pit", "survival_kit/campfire-stand",
"survival_kit/fence", "survival_kit/fence-fortified", "survival_kit/floor-old", "survival_kit/signpost-single", "survival_kit/tree-log-small", "survival_kit/fish",
"graveyard_kit/debris", "graveyard_kit/debris-wood", "graveyard_kit/hay-bale", "graveyard_kit/hay-bale-bundled", "graveyard_kit/lantern-candle", "graveyard_kit/lantern-glass",
"graveyard_kit/lightpost-single", "graveyard_kit/lightpost-double", "graveyard_kit/bench-damaged", "graveyard_kit/fence-damaged", "graveyard_kit/urn-round", "graveyard_kit/detail-plate", "graveyard_kit/detail-bowl", "graveyard_kit/detail-chalice",
"graveyard_kit/candle", "graveyard_kit/fire-basket", "graveyard_kit/shovel", "graveyard_kit/trunk", "graveyard_kit/stone-wall-damaged", "graveyard_kit/pumpkin",
"mini_dungeon/weapon-sword", "mini_dungeon/weapon-spear", "mini_dungeon/shield-round", "mini_dungeon/shield-rectangle", "mini_dungeon/banner", "mini_dungeon/pot", "mini_dungeon/chair", "mini_dungeon/table", "mini_dungeon/chest", "mini_dungeon/barrel", "mini_dungeon/stones", "mini_dungeon/rocks", "mini_dungeon/coin",
"mini_arena/weapon-rack", "mini_arena/weapon-sword", "mini_arena/weapon-spear", "mini_arena/bricks", "mini_arena/banner", "mini_arena/trophy",
"food_kit/bread", "food_kit/loaf", "food_kit/loaf-round", "food_kit/loaf-baguette", "food_kit/apple", "food_kit/carrot", "food_kit/cheese", "food_kit/pot-stew", "food_kit/pan-stew", "food_kit/plate-broken", "food_kit/bowl", "food_kit/mug", "food_kit/rollingPin", "food_kit/cutting-board", "food_kit/barrel", "food_kit/croissant", "food_kit/pie", "food_kit/cabbage", "food_kit/pumpkin", "food_kit/fish", "food_kit/meat-ribs", "food_kit/whole-ham", "food_kit/bag", "food_kit/wine-red", "food_kit/onion", "food_kit/glass-wine",
"furniture_kit/books", "furniture_kit/bookcaseOpen", "furniture_kit/bookcaseClosedWide", "furniture_kit/rugRound", "furniture_kit/rugRectangle", "furniture_kit/chair", "furniture_kit/table", "furniture_kit/tableCloth", "furniture_kit/bedSingle", "furniture_kit/bedDouble", "furniture_kit/bench", "furniture_kit/pillow", "furniture_kit/kitchenStove", "furniture_kit/lampRoundTable", "furniture_kit/coatRack", "furniture_kit/plantSmall1", "furniture_kit/pottedPlant", "furniture_kit/sideTable", "furniture_kit/bookcaseOpenLow", "furniture_kit/cardboardBoxOpen", "furniture_kit/rugDoormat", "furniture_kit/benchCushion", "furniture_kit/lampWall",
"nature_kit/crops_dirtRow", "nature_kit/crops_dirtDoubleRow", "nature_kit/crop_carrot", "nature_kit/crop_turnip", "nature_kit/crop_pumpkin", "nature_kit/crop_melon", "nature_kit/crops_leafsStageA", "nature_kit/crops_leafsStageB", "nature_kit/crops_cornStageB", "nature_kit/crops_wheatStageA", "nature_kit/crops_wheatStageB",
"nature_kit/fence_simple", "nature_kit/fence_planks", "nature_kit/fence_gate", "nature_kit/fence_simpleLow", "nature_kit/log", "nature_kit/log_stack", "nature_kit/log_large", "nature_kit/stump_old", "nature_kit/stump_round", "nature_kit/pot_large", "nature_kit/pot_small", "nature_kit/sign", "nature_kit/bridge_wood",
"nature_kit/flower_redA", "nature_kit/flower_yellowA", "nature_kit/plant_bushSmall", "nature_kit/statue_column", "nature_kit/statue_columnDamaged", "nature_kit/statue_head", "nature_kit/campfire_logs", "nature_kit/campfire_planks", "nature_kit/campfire_bricks",
"mini_forest/target", "mini_forest/weapon-arrow", "mini_forest/weapon-bow", "mini_forest/ladder", "mini_forest/patch-dirt",
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
