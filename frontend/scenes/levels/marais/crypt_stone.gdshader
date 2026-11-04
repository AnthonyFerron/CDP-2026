shader_type spatial;
render_mode cull_back;

// Dalles de la crypte : la texture du kit de donjon, orangée, devient une pierre froide et humide.
// Seule la teinte change : le dessin des dalles reste.

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 tint : source_color = vec3(0.6, 0.63, 0.64);
// Part de la couleur d'origine gardée.
uniform float keep = 0.12;

void fragment() {
	vec3 color = texture(albedo_texture, UV).rgb;
	float light = dot(color, vec3(0.3, 0.59, 0.11));
	ALBEDO = mix(vec3(light), color, keep) * tint * 1.25;
	ROUGHNESS = 0.92;
	SPECULAR = 0.25;
}
