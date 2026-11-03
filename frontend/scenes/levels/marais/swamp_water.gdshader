shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_opaque;

// Eau stagnante : surface sombre et luisante, rides lentes et plaques d'algues.

uniform sampler2D ripple_noise : repeat_enable, filter_linear;
uniform vec3 water_color : source_color = vec3(0.05, 0.085, 0.06);
uniform vec3 scum_color : source_color = vec3(0.12, 0.17, 0.07);
uniform float opacity = 0.86;
uniform float ripple_strength = 0.35;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 drift = vec2(0.006, 0.004) * TIME;
	float a = texture(ripple_noise, world_pos.xz * 0.08 + drift).r;
	float b = texture(ripple_noise, world_pos.xz * 0.15 - drift * 1.3).r;
	float c = texture(ripple_noise, (world_pos.xz + vec2(0.7, 0.0)) * 0.08 + drift).r;
	float d = texture(ripple_noise, (world_pos.xz + vec2(0.0, 0.7)) * 0.08 + drift).r;
	NORMAL_MAP = normalize(vec3((a - c) * ripple_strength * 6.0 + 0.5, (a - d) * ripple_strength * 6.0 + 0.5, 1.0));

	float scum = smoothstep(0.6, 0.72, texture(ripple_noise, world_pos.xz * 0.025).r + b * 0.15);
	ALBEDO = mix(water_color, scum_color, scum);
	ALPHA = mix(opacity, 0.97, scum);
	ROUGHNESS = mix(0.06, 0.8, scum);
	SPECULAR = mix(0.6, 0.15, scum);
}
