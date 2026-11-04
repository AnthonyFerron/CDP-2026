shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_opaque, specular_schlick_ggx;

// Eau de la rivière et de l'étang : rides qui suivent le courant (UV.y, en mètres le long du lit), traînées
// d'écume. Trouble et grise au début, elle s'éclaircit à mesure que les livres reviennent.

uniform sampler2D ripple_noise : repeat_enable, filter_linear;
// 0 : aucun livre posé ; 1 : les quatre.
uniform float life : hint_range(0.0, 1.0) = 0.0;
// Vitesse du courant, en mètres par seconde ; nulle pour l'étang.
uniform float flow_speed = 0.7;
// Largeur du lit couverte par UV.x, pour garder des rides à l'échelle.
uniform float across = 10.0;
uniform vec3 murky_color : source_color = vec3(0.16, 0.16, 0.13);
uniform vec3 clear_color : source_color = vec3(0.09, 0.25, 0.31);
uniform vec3 foam_color : source_color = vec3(0.78, 0.82, 0.8);
uniform float opacity = 0.84;

void fragment() {
	vec2 flow = vec2(UV.x * across, UV.y - TIME * flow_speed);
	float a = texture(ripple_noise, flow * 0.09).r;
	float c = texture(ripple_noise, (flow + vec2(0.55, 0.0)) * 0.09).r;
	float d = texture(ripple_noise, (flow + vec2(0.0, 0.55)) * 0.09).r;
	float b = texture(ripple_noise, vec2(flow.x * 0.18, flow.y * 0.05) + vec2(0.31, TIME * 0.02)).r;
	NORMAL_MAP = normalize(vec3((a - c) * 1.4 + 0.5, (a - d) * 1.4 + 0.5, 1.0));
	vec3 base = mix(murky_color, clear_color, life);
	float streak = smoothstep(0.7, 0.86, b) * mix(0.1, 0.22, life);
	ALBEDO = mix(base, foam_color, streak);
	ALPHA = mix(opacity, 0.96, streak);
	ROUGHNESS = mix(0.12, 0.05, life);
	SPECULAR = 0.6;
}
