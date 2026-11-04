extends SceneTree
const MODELS := [
	"nature_kit/tree_palm", "nature_kit/tree_palmBend", "nature_kit/tree_palmDetailedShort", "nature_kit/tree_palmDetailedTall",
	"nature_kit/tree_palmShort", "nature_kit/tree_palmTall", "nature_kit/statue_head", "nature_kit/statue_obelisk",
	"nature_kit/statue_block", "nature_kit/statue_column", "nature_kit/statue_columnDamaged", "nature_kit/statue_ring",
	"nature_kit/pot_large", "nature_kit/pot_small", "graveyard_kit/character-skeleton", "graveyard_kit/urn-round",
	"graveyard_kit/urn-square", "graveyard_kit/pillar-obelisk", "graveyard_kit/column-large", "graveyard_kit/debris",
	"graveyard_kit/fire-basket", "graveyard_kit/pillar-small", "graveyard_kit/pillar-square", "graveyard_kit/pillar-large",
	"graveyard_kit/detail-bowl", "graveyard_kit/detail-chalice", "graveyard_kit/coffin-old", "graveyard_kit/rocks",
	"graveyard_kit/candle-multiple", "graveyard_kit/candle", "graveyard_kit/stone-wall", "graveyard_kit/stone-wall-damaged",
	"graveyard_kit/stone-wall-column", "graveyard_kit/border-pillar", "graveyard_kit/brick-wall", "graveyard_kit/brick-wall-end",
	"fantasy_town_kit/stall", "fantasy_town_kit/stall-red", "fantasy_town_kit/stall-green", "fantasy_town_kit/stall-bench",
	"fantasy_town_kit/stall-stool", "fantasy_town_kit/cart", "fantasy_town_kit/wheel", "fantasy_town_kit/wall-arch",
	"fantasy_town_kit/wall-broken", "fantasy_town_kit/fountain-round", "fantasy_town_kit/fountain-edge", "fantasy_town_kit/fountain-corner",
	"fantasy_town_kit/fountain-square", "fantasy_town_kit/fountain-center", "fantasy_town_kit/pillar-stone", "fantasy_town_kit/lantern",
	"fantasy_town_kit/poles", "fantasy_town_kit/rock-large", "fantasy_town_kit/rock-wide", "fantasy_town_kit/stairs-stone",
	"survival_kit/tent", "survival_kit/tent-canvas", "survival_kit/tent-canvas-half", "survival_kit/bucket", "survival_kit/bottle-large",
	"survival_kit/barrel-open", "survival_kit/box-open", "survival_kit/box-large-open", "survival_kit/bedroll", "survival_kit/campfire-pit",
	"survival_kit/structure-canvas", "survival_kit/signpost", "survival_kit/resource-planks", "survival_kit/floor-hole",
	"mini_dungeon/pot", "mini_dungeon/chest", "mini_dungeon/coin", "mini_dungeon/rocks", "mini_dungeon/stones", "mini_dungeon/dirt",
	"mini_dungeon/column", "mini_dungeon/banner", "mini_dungeon/table", "mini_dungeon/chair", "mini_dungeon/potion",
	"mini_dungeon/wood-support", "mini_dungeon/shield-rectangle", "mini_dungeon/weapon-sword", "mini_dungeon/gate",
	"mini_arena/column", "mini_arena/column-damaged", "mini_arena/statue", "mini_arena/bricks", "mini_arena/banner",
	"mini_arena/wall", "mini_arena/wall-gate", "mini_arena/wall-corner", "mini_arena/floor", "mini_arena/floor-detail",
	"mini_arena/block", "mini_arena/border-straight", "mini_arena/border-corner", "mini_arena/stairs", "mini_arena/trophy",
	"mini_arena/weapon-rack", "mini_arena/weapon-spear", "castle_kit/rocks-small", "castle_kit/rocks-large", "castle_kit/flag-banner-long",
	"castle_kit/tower-hexagon-base", "castle_kit/wall-half", "castle_kit/stairs-stone", "castle_kit/tree-log",
	"food_kit/fish-bones", "food_kit/tajine", "food_kit/tajine-lid", "food_kit/bag", "food_kit/bag-flat", "food_kit/pot", "food_kit/bowl",
	"food_kit/plate-broken", "food_kit/coconut", "food_kit/grapes", "food_kit/bread", "food_kit/mortar-pestle", "food_kit/barrel",
	"food_kit/meat-ribs", "food_kit/wine-red", "food_kit/loaf-round",
	"furniture_kit/bookcaseOpen", "furniture_kit/bookcaseOpenLow", "furniture_kit/bookcaseClosedWide", "furniture_kit/books",
	"furniture_kit/rugRectangle", "furniture_kit/rugRound", "furniture_kit/desk", "furniture_kit/sideTable",
	"modular_dungeon_kit/gate-door", "modular_dungeon_kit/template-wall", "modular_dungeon_kit/template-floor",
	"modular_dungeon_kit/template-wall-detail-a", "modular_dungeon_kit/template-detail", "modular_dungeon_kit/gate-metal-bars",
	"nature_kit/cactus_tall", "nature_kit/cactus_short", "nature_kit/plant_bushSmall", "nature_kit/log", "nature_kit/stump_old",
	"nature_kit/campfire_stones", "nature_kit/tent_detailedOpen", "nature_kit/tent_smallOpen", "nature_kit/rock_largeA",
	"nature_kit/rock_tallA", "nature_kit/stone_largeA", "nature_kit/stone_tallA", "nature_kit/cliff_blockHalf_stone",
	"survival_kit/rock-sand-a", "survival_kit/rock-sand-b", "survival_kit/rock-sand-c",
]
func _initialize():
	for m in MODELS:
		var res = load("res://assets/models/kenney/%s.glb" % m)
		if res == null:
			print("%-40s MANQUANT" % m)
			continue
		var s: Node = res.instantiate()
		root.add_child(s)
		var box := AABB()
		var first := true
		var count := 0
		for n in s.find_children("*", "MeshInstance3D", true, false):
			var b: AABB = n.global_transform * n.get_aabb()
			box = b if first else box.merge(b)
			first = false
			count += 1
		print("BOX %-40s pos %s size %s meshes %d" % [m, box.position.snappedf(0.01), box.size.snappedf(0.01), count])
		s.free()
	quit()
