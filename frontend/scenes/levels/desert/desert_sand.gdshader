shader_type spatial;
render_mode cull_back;

// Sable du Désert : la couleur vient des faces, avec des rides de vent et quelques grains qui scintillent.

uniform sampler2D grain_noise : repeat_enable, filter_linear;
uniform float ripple_scale = 1.6;
uniform float ripple_depth = 0.08;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float warp = texture(grain_noise, world_pos.xz * 0.02).r * 6.0;
	float ripples = sin((world_pos.x * 0.8 + world_pos.z * 0.35) * ripple_scale + warp) * 0.5 + 0.5;
	float sparkle = step(0.83, texture(grain_noise, world_pos.xz * 0.9).r);
	ALBEDO = COLOR.rgb * (1.0 - ripples * ripple_depth);
	ROUGHNESS = 0.95;
	SPECULAR = 0.15 + sparkle * 0.6;
}
