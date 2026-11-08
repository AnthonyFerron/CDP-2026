shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_opaque, specular_schlick_ggx;

// Eau de la rivière et de l'étang : rides qui suivent le courant (UV.y, en mètres le long du lit), traînées
// d'écume. Avant les livres, elle est trouble et grise, lente, et un voile de cendres flotte par plaques à sa
// surface ; à chaque livre posé elle s'éclaircit, le voile se déchire puis disparaît (deuxième livre), le courant
// s'anime et l'écume revient.

uniform sampler2D ripple_noise : repeat_enable, filter_linear;
// 0 : aucun livre posé ; 1 : les quatre.
uniform float life : hint_range(0.0, 1.0) = 0.0;
// Vitesse du courant vif, en mètres par seconde ; nulle pour l'étang.
uniform float flow_speed = 0.7;
// Largeur du lit couverte par UV.x, pour garder des rides à l'échelle.
uniform float across = 10.0;
uniform vec3 murky_color : source_color = vec3(0.16, 0.16, 0.13);
uniform vec3 clear_color : source_color = vec3(0.09, 0.25, 0.31);
uniform vec3 foam_color : source_color = vec3(0.78, 0.82, 0.8);
uniform vec3 ash_color : source_color = vec3(0.38, 0.37, 0.35);
// Opacité de l'eau claire ; l'eau trouble est presque opaque.
uniform float opacity = 0.84;

// Pente des rides d'une couche de courant, tirée de trois lectures du bruit.
vec2 ripples(vec2 flow) {
	float a = texture(ripple_noise, flow * 0.06).r;
	float c = texture(ripple_noise, (flow + vec2(0.55, 0.0)) * 0.06).r;
	float d = texture(ripple_noise, (flow + vec2(0.0, 0.55)) * 0.06).r;
	return vec2(a - c, a - d);
}

void fragment() {
	vec2 bed = vec2(UV.x * across, UV.y);
	// Deux couches de courant, l'une lente, l'autre vive, chacune à vitesse fixe : la vie passe de l'une à l'autre sans
	// à-coup (changer la vitesse d'une seule couche ferait courir les rides pendant que les livres la font varier).
	vec2 slow_flow = bed - vec2(0.0, TIME * flow_speed * 0.3);
	vec2 fast_flow = bed - vec2(0.0, TIME * flow_speed * 1.25);
	vec2 slope = mix(ripples(slow_flow) * 0.8, ripples(fast_flow) * 1.05, life);
	// Voile de cendres : de larges plaques qui dérivent avec l'eau lente, de moins en moins nombreuses.
	float veil = texture(ripple_noise, slow_flow * 0.022 + vec2(0.7, 0.2)).r;
	float cover = mix(0.54, 0.7, smoothstep(0.0, 0.25, life));
	float ash = smoothstep(cover, cover + 0.14, veil) * (1.0 - smoothstep(0.3, 0.5, life)) * 0.75;
	NORMAL_MAP = normalize(vec3(mix(slope, vec2(0.0), ash) + 0.5, 1.0));
	vec3 base = mix(murky_color, clear_color, life);
	float b = texture(ripple_noise, vec2(fast_flow.x * 0.18, fast_flow.y * 0.05) + vec2(0.31, TIME * 0.02)).r;
	float streak = smoothstep(0.72, 0.88, b) * mix(0.03, 0.17, life) * (1.0 - ash);
	ALBEDO = mix(mix(base, foam_color, streak), ash_color, ash);
	ALPHA = mix(mix(mix(0.95, opacity, life), 0.96, streak), 0.98, ash);
	ROUGHNESS = mix(mix(0.2, 0.1, life), 0.85, ash);
	SPECULAR = mix(mix(0.4, 0.5, life), 0.1, ash);
}
