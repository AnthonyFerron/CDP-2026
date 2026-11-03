shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 inner_color : source_color = vec3(1.0, 0.85, 0.4);
uniform vec3 outer_color : source_color = vec3(0.9, 0.12, 0.03);
uniform float spin_speed = 0.8;

void fragment() {
	vec2 centered = UV - 0.5;
	float radius = length(centered) * 2.0;
	float angle = atan(centered.y, centered.x);
	float swirl = sin(angle * 4.0 + radius * 10.0 - TIME * spin_speed * 4.0);
	ALBEDO = mix(inner_color, outer_color, clamp(radius + swirl * 0.2, 0.0, 1.0));
	ALPHA = 1.0 - smoothstep(0.92, 1.0, radius);
}
