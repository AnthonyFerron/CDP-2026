shader_type spatial;
render_mode cull_disabled;

// Roseaux qui ondulent : le haut de chaque tige se balance plus que son pied, d'une vague lente qui traverse le
// marais, avec un frisson plus rapide. La position de chaque roseau (MultiMesh) décale sa phase.

uniform vec3 color : source_color = vec3(0.2, 0.26, 0.1);
uniform float sway = 0.08;
uniform float speed = 1.1;

void vertex() {
	vec3 origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float height = max(VERTEX.y, 0.0);
	float bend = height * height;
	float wave = sin(TIME * speed + origin.x * 0.21 + origin.z * 0.17) + 0.35 * sin(TIME * speed * 2.7 + origin.z * 0.9);
	VERTEX.x += wave * sway * bend;
	VERTEX.z += cos(TIME * speed * 0.8 + origin.x * 0.13) * sway * 0.6 * bend;
}

void fragment() {
	ALBEDO = color;
	ROUGHNESS = 1.0;
}
