shader_type spatial;
render_mode blend_mul, unshaded, depth_draw_never, fog_disabled;

// Calque de suie posé sur les ruines : noircit le pied des murs et y trace des coulures.

uniform sampler2D soot_noise : repeat_enable, filter_linear;
uniform vec3 soot_color : source_color = vec3(0.42, 0.35, 0.34);
uniform float base_height = 3.0;
// Hauteur du sol sous le calque : les archives sont sous la carte.
uniform float floor_height = 0.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float streaks = texture(soot_noise, vec2((world_pos.x + world_pos.z) * 0.12, world_pos.y * 0.035)).r;
	float base = 1.0 - smoothstep(floor_height, floor_height + base_height, world_pos.y);
	float soot = clamp(base * 0.45 + smoothstep(0.52, 0.72, streaks) * 0.5, 0.0, 0.6);
	ALBEDO = mix(vec3(1.0), soot_color, soot);
}
