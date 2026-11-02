shader_type spatial;
render_mode cull_back;

// Sol brûlé : la couleur vient des sommets et leur alpha indique l'intensité des braises.

uniform vec3 ember_color : source_color = vec3(1.0, 0.32, 0.06);
uniform float ember_strength = 3.0;
uniform float pulse_speed = 0.9;

varying float ember;

void vertex() {
	ember = COLOR.a;
}

void fragment() {
	float pulse = 0.75 + 0.25 * sin(TIME * pulse_speed + UV.x * 40.0);
	ALBEDO = COLOR.rgb;
	EMISSION = ember_color * ember * ember_strength * pulse;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
