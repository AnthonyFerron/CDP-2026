shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

// Brume qui roule au ras de l'eau : deux bruits qui glissent lentement en sens contraires, des nappes qui
// s'ouvrent et se referment. Elle s'efface près de la caméra pour ne jamais faire de mur devant les yeux.

uniform sampler2D noise_tex : repeat_enable, filter_linear;
uniform vec3 fog_color : source_color = vec3(0.55, 0.64, 0.62);
uniform float density = 0.3;
uniform float scale = 0.025;
uniform vec2 drift = vec2(0.008, 0.003);
// Distance à la caméra sous laquelle la brume s'efface.
uniform float near_fade = 5.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = world_pos.xz * scale;
	float a = texture(noise_tex, uv + TIME * drift).r;
	float b = texture(noise_tex, uv * 2.3 + vec2(0.37, 0.71) - TIME * drift.yx * 1.6).r;
	float sheets = smoothstep(0.38, 0.82, a * 0.65 + b * 0.45);
	float near = smoothstep(1.0, near_fade, distance(CAMERA_POSITION_WORLD, world_pos));
	ALBEDO = fog_color;
	ALPHA = sheets * density * near;
}
