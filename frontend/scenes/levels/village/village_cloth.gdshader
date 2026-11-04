// Tissu qui ondule au vent : linge étendu, bannières. Le haut reste accroché, le bas flotte.
// Les draps se mesurent en hauteur du monde (leur corde est à la même hauteur partout), les bannières en hauteur
// du modèle (leur barre est en haut du modèle).
shader_type spatial;
render_mode cull_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_texture = false;
uniform float amplitude = 0.1;
uniform float speed = 2.2;
uniform bool world_anchor = true;
// Hauteur du point d'attache, et hauteur sur laquelle le tissu passe de fixe à libre.
uniform float anchor = 2.15;
uniform float span = 1.2;
// Un tissu tombé au sol, sous cette hauteur du monde, ne bouge pas.
uniform float ground = 0.3;
uniform vec3 sway_axis = vec3(0.0, 0.0, 1.0);

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float height = world_anchor ? world.y : VERTEX.y;
	float hang = clamp((anchor - height) / span, 0.0, 1.0) * step(ground, world.y);
	float wave = sin(TIME * speed + world.x * 1.7 + world.z * 1.3) + 0.4 * sin(TIME * speed * 2.3 + world.x * 3.1 - world.z);
	VERTEX += sway_axis * wave * amplitude * hang;
}

void fragment() {
	vec4 color = albedo;
	if (use_texture) {
		color *= texture(albedo_texture, UV);
	}
	ALBEDO = color.rgb;
	ROUGHNESS = 1.0;
}
