shader_type spatial;
render_mode cull_disabled;

// Sables mouvants : un sable plus sombre et humide qui tourne lentement vers le centre.

uniform sampler2D swirl_noise : repeat_enable, filter_linear;
uniform vec3 sand_color : source_color = vec3(0.8, 0.6, 0.36);
uniform vec3 wet_color : source_color = vec3(0.56, 0.4, 0.23);

void fragment() {
	vec2 centered = UV - 0.5;
	float radius = length(centered) * 2.0;
	if (radius > 1.0) {
		discard;
	}
	float angle = atan(centered.y, centered.x) + TIME * 0.25 + radius * 3.0;
	vec2 swirl = vec2(cos(angle), sin(angle)) * radius;
	float grain = texture(swirl_noise, swirl * 0.5 + TIME * 0.01).r;
	float edge = smoothstep(0.75, 1.0, radius);
	ALBEDO = mix(wet_color, sand_color, clamp(grain * 0.8 + edge, 0.0, 1.0));
	ROUGHNESS = mix(0.7, 0.95, edge);
	SPECULAR = 0.1;
}
