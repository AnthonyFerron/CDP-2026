shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back;

// Mousse par-dessus la pierre et le bois : sur les faces tournées vers le ciel et au ras de l'eau,
// en plaques irrégulières. Appliquée en surcouche (material_overlay) sans toucher aux textures Kenney.

uniform vec3 moss_color : source_color = vec3(0.17, 0.27, 0.1);
uniform vec3 damp_color : source_color = vec3(0.1, 0.16, 0.08);
// Plus la valeur est basse, plus la mousse gagne les faces inclinées.
uniform float coverage = 0.35;
// Hauteur au-dessus de l'eau jusqu'où remonte la mousse humide, et sa force (0 pour la poussière de la crypte).
uniform float damp_height = 0.9;
uniform float damp_amount = 0.85;

varying vec3 world_normal;
varying vec3 world_pos;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x), mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x), mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float patches = noise(world_pos * 2.6) * 0.6 + noise(world_pos * 7.1) * 0.4;
	float top = smoothstep(coverage, coverage + 0.3, world_normal.y + (patches - 0.5) * 0.9);
	float damp = (1.0 - smoothstep(0.0, max(damp_height, 0.01), world_pos.y)) * smoothstep(0.35, 0.6, patches);
	float amount = clamp(max(top, damp * damp_amount), 0.0, 1.0);
	ALBEDO = mix(damp_color, moss_color, top) * (0.75 + patches * 0.5);
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
	ALPHA = amount * 0.78;
}
