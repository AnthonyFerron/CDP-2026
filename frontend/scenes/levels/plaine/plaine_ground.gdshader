shader_type spatial;
render_mode cull_back;

// Sol brûlé : la couleur vient des faces, les veines de braise d'une texture de bruit.
// L'alpha des sommets dit où les veines peuvent apparaître, UV.x la lueur autour de la lave.

uniform sampler2D crack_noise : repeat_enable, filter_linear;
uniform vec3 ember_color : source_color = vec3(1.0, 0.32, 0.06);
uniform float crack_scale = 0.018;
uniform float crack_width = 0.016;
uniform float crack_strength = 2.0;
uniform float glow_strength = 1.8;
// Échelle des plaques où les veines se regroupent, pour laisser du sol nu entre elles.
uniform float patch_scale = 0.0045;

varying vec3 world_pos;
varying float crack_mask;
varying float lava_glow;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	crack_mask = COLOR.a;
	lava_glow = UV.x;
}

void fragment() {
	float noise = texture(crack_noise, world_pos.xz * crack_scale).r;
	float patches = smoothstep(0.5, 0.62, texture(crack_noise, world_pos.zx * patch_scale + 0.37).r);
	float crack = (1.0 - smoothstep(0.0, crack_width, abs(noise - 0.5))) * crack_mask * patches;
	float pulse = 0.7 + 0.3 * sin(TIME * 0.8 + world_pos.x * 0.3 + world_pos.z * 0.2);
	ALBEDO = mix(COLOR.rgb, COLOR.rgb * 0.35, crack);
	EMISSION = ember_color * (crack * crack_strength * pulse + lava_glow * lava_glow * glow_strength);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
