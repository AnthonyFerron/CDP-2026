shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// Mirage de l'oasis asséchée : de loin, une nappe d'eau scintille au fond du bassin, le reflet du ciel brouillé
// par la chaleur. Comme un vrai mirage, il n'apparaît que vu de biais, au ras du sol, et s'efface à mesure qu'on
// approche : il ne reste que la boue craquelée.

uniform vec3 sky_color : source_color = vec3(0.6, 0.76, 0.98);
uniform vec3 haze_color : source_color = vec3(0.92, 0.9, 0.86);
// Distance (en mètres) où la nappe disparaît tout à fait, et celle où elle est entière.
uniform float fade_near = 8.0;
uniform float fade_far = 18.0;
uniform float strength = 0.95;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	// Bord en ellipse, fondu : les roseaux de la berge la traversent comme une eau basse.
	float edge = 1.0 - smoothstep(0.45, 1.0, length(p));
	float fade = smoothstep(fade_near, fade_far, length(VERTEX));
	// Plus on la regarde de biais, plus elle brille : vue d'en haut, il n'y a que la boue.
	float grazing = smoothstep(0.65, 0.9, 1.0 - abs(dot(NORMAL, VIEW)));
	// L'air chaud tremble en bandes horizontales à l'écran, qui ondulent et montent.
	float wave = sin(SCREEN_UV.x * 21.0 + TIME * 1.6) * 1.4 + sin(SCREEN_UV.x * 47.0 - TIME * 2.3) * 0.5;
	float shimmer = 0.5 + 0.5 * sin(SCREEN_UV.y * 150.0 + wave - TIME * 5.0);
	ALBEDO = mix(sky_color, haze_color, 0.2 + 0.3 * shimmer);
	ALPHA = edge * fade * grazing * strength * (0.75 + 0.25 * shimmer);
}
