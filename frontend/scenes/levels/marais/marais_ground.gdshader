shader_type spatial;
render_mode cull_back;

// Sol du Marais : la couleur vient des faces, et le sol devient luisant près de l'eau.

uniform float wet_height = 0.25;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float wet = 1.0 - smoothstep(0.0, wet_height, world_pos.y);
	ALBEDO = COLOR.rgb * mix(1.0, 0.65, wet);
	ROUGHNESS = mix(1.0, 0.35, wet);
	SPECULAR = mix(0.1, 0.45, wet);
}
