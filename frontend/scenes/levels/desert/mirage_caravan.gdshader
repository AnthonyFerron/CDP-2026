shader_type spatial;
render_mode unshaded, blend_mix, depth_prepass_alpha, cull_back, shadows_disabled;

// Caravane fantôme : les silhouettes des marchands d'autrefois et de leurs chameaux qui marchent sur les crêtes,
// tremblantes dans l'air brûlant. Elles s'effacent dès qu'on s'en approche, comme un mirage.
// Couleur des sommets : g = 1 pour une patte, r = sa phase (0 à 1), b = la hauteur de sa hanche / 2.

uniform vec3 color : source_color = vec3(0.24, 0.16, 0.14);
uniform float fade_near = 30.0;
uniform float fade_far = 50.0;
uniform float strength = 0.78;
uniform float stride = 3.0;
uniform float swing = 0.3;
uniform float phase = 0.0;

void vertex() {
	if (COLOR.g > 0.5) {
		float hip = COLOR.b * 2.0;
		float k = clamp((hip - VERTEX.y) / hip, 0.0, 1.0);
		float step_phase = TIME * stride + COLOR.r * 6.2832 + phase;
		VERTEX.z += sin(step_phase) * swing * k;
		VERTEX.y += max(0.0, cos(step_phase)) * 0.06 * k;
	}
	// L'air chaud fait onduler la silhouette de bas en haut, et l'étire un peu.
	VERTEX.x += sin(TIME * 5.0 + VERTEX.y * 6.0 + phase) * 0.06;
	VERTEX.y *= 1.0 + 0.05 * sin(TIME * 1.7 + phase);
}

void fragment() {
	float fade = smoothstep(fade_near, fade_far, length(VERTEX));
	// Bandes horizontales qui papillotent, comme l'air au-dessus du sable.
	float flicker = 0.72 + 0.28 * sin(TIME * 9.0 + FRAGCOORD.y * 0.4 + phase);
	ALBEDO = color;
	ALPHA = fade * strength * flicker;
}
