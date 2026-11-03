shader_type spatial;
render_mode cull_disabled;

// Bassin de lave : une croûte sombre dérive sur un fond incandescent qui pulse.

uniform sampler2D flow_noise : repeat_enable, filter_linear;
uniform vec3 core_color : source_color = vec3(1.0, 0.85, 0.35);
uniform vec3 hot_color : source_color = vec3(1.0, 0.38, 0.06);
uniform vec3 crust_color : source_color = vec3(0.09, 0.055, 0.05);
uniform float emission_strength = 3.5;
uniform float flow_speed = 1.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float swell = texture(flow_noise, world_pos.xz * 0.05 + TIME * 0.01 * flow_speed).r;
	VERTEX.y += (swell - 0.5) * 0.18;
}

void fragment() {
	float edge = length(UV - 0.5) * 2.0;
	if (edge > 1.0) {
		discard;
	}
	vec2 drift = vec2(0.012, 0.008) * TIME * flow_speed;
	float large = texture(flow_noise, world_pos.xz * 0.06 + drift).r;
	float small = texture(flow_noise, world_pos.xz * 0.14 - drift * 1.7).r;
	float heat = large * 0.6 + small * 0.4;

	// La croûte se forme sur les zones froides et sur les bords, où la lave refroidit.
	float crust = smoothstep(0.52, 0.64, heat);
	crust = max(crust, smoothstep(0.78, 1.0, edge));
	float pulse = 0.85 + 0.15 * sin(TIME * 1.4 + heat * 14.0);
	vec3 glow = mix(hot_color, core_color, smoothstep(0.46, 0.26, heat));

	ALBEDO = mix(glow * 0.25, crust_color, crust);
	EMISSION = glow * (1.0 - crust) * emission_strength * pulse;
	ROUGHNESS = mix(0.35, 1.0, crust);
	SPECULAR = 0.2;
}
