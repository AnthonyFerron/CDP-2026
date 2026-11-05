shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// Mirage de l'oasis asséchée : de loin, une nappe d'eau scintille au fond du bassin, le reflet du ciel brouillé
// par la chaleur. Elle s'efface à mesure qu'on approche, pixel par pixel : il ne reste que la boue craquelée.

uniform vec3 sky_color : source_color = vec3(0.58, 0.7, 0.84);
uniform vec3 horizon_color : source_color = vec3(0.96, 0.8, 0.58);
// Distance (en mètres) où la nappe disparaît tout à fait, et celle où elle est entière.
uniform float fade_near = 8.0;
uniform float fade_far = 18.0;
uniform float strength = 0.82;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	// Bord en ellipse, fondu : les roseaux de la berge la traversent comme une eau basse.
	float edge = 1.0 - smoothstep(0.62, 1.0, length(p));
	float fade = smoothstep(fade_near, fade_far, length(VERTEX));
	// Bandes de chaleur qui tremblent et se tordent, quelques éclats de lumière.
	float wobble = sin(UV.x * 11.0 + TIME * 1.3) * 0.6 + sin(UV.x * 27.0 - TIME * 2.1) * 0.25;
	float bands = 0.5 + 0.5 * sin(UV.y * 64.0 + wobble * 3.0 - TIME * 3.5);
	float glints = pow(0.5 + 0.5 * sin(UV.x * 83.0 + UV.y * 29.0 + TIME * 4.0), 14.0);
	vec3 color = mix(horizon_color, sky_color, 0.4 + 0.4 * bands);
	ALBEDO = color + vec3(1.0, 0.96, 0.86) * glints * 0.45;
	ALPHA = edge * fade * strength * (0.72 + 0.28 * bands);
}
