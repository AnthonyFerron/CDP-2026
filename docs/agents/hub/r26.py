REPLACEMENTS = [
('''const COLOR_BED := Color(0.24, 0.21, 0.15)''', '''const COLOR_BED := Color(0.24, 0.21, 0.15)
## Sol sous les planchers des bâtiments : entre les lattes, on voit une terre sombre et non l'herbe.
const COLOR_FLOOR := Color(0.16, 0.11, 0.08)
## Emprise des maisons et des bâtiments (tools/build_hub.py : house_layout, LANDMARKS, QUARTERS).
const BUILDING_FLOORS: Array[Rect2] = [
	Rect2(-13.2, -26.2, 8, 8), Rect2(5.2, -26.2, 8, 8), Rect2(18.2, -13.2, 8, 8), Rect2(18.2, 5.2, 8, 8), Rect2(4.2, 18.6, 8, 8),
	Rect2(-12.2, 18.6, 8, 8), Rect2(-26.6, 4.2, 8, 8), Rect2(-26.6, -12.2, 8, 8), Rect2(-20.5, -39.1, 12, 8), Rect2(8.5, -39.1, 12, 8),
	Rect2(31.1, -18.5, 8, 8), Rect2(29.1, 10.5, 12, 8), Rect2(7.7, 32.1, 8, 8), Rect2(-15.7, 30.1, 8, 12), Rect2(-40.1, 7.7, 8, 8),
	Rect2(-40.1, -17.7, 8, 12), Rect2(-6, 56, 12, 8), Rect2(-66, -4, 12, 8), Rect2(-60, -36, 8, 12), Rect2(51, 14, 8, 8),
	Rect2(40, 60, 8, 8), Rect2(48, 30, 8, 8), Rect2(57, 44, 8, 8), Rect2(-74, -50, 12, 8), Rect2(-54, -70, 12, 8),
	Rect2(-64, 26, 8, 8), Rect2(-78, -20, 8, 8),
]'''),
('''	color = color.lerp(COLOR_PATH, path_mask(x, z))
	var play := play_radius(point.angle())''', '''	color = color.lerp(COLOR_PATH, path_mask(x, z))
	for floor_area in BUILDING_FLOORS:
		if floor_area.grow(-0.2).has_point(point):
			color = COLOR_FLOOR
			break
	var play := play_radius(point.angle())'''),
]
