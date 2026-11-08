shader_type spatial;
render_mode cull_back;

// Sol du hub : l'herbe est grise et sèche au début, puis reverdit à mesure que les livres reviennent. Les cendres du
// Mont Sam Altan le couvrent par larges plaques grises, qui reculent à chaque livre posé et ont disparu au quatrième.

// 0 : aucun livre rapporté ; 1 : les quatre livres sont revenus.
uniform float life : hint_range(0.0, 1.0) = 0.0;
uniform vec3 dead_tint : source_color = vec3(0.42, 0.38, 0.32);
// Bruit des plaques de cendres (celui des rides de l'eau).
uniform sampler2D ash_noise : repeat_enable, filter_linear;
uniform vec3 ash_color : source_color = vec3(0.4, 0.39, 0.37);
uniform vec3 char_color : source_color = vec3(0.24, 0.23, 0.22);

varying vec2 ground;

void vertex() {
	// Le sol est posé à l'origine : ses sommets sont en coordonnées du monde.
	ground = VERTEX.xz;
}

void fragment() {
	vec3 color = COLOR.rgb;
	float grey = dot(color, vec3(0.3, 0.59, 0.11));
	vec3 dead = vec3(grey) * dead_tint * 2.2;
	vec3 albedo = mix(dead, color, 0.25 + life * 0.75);
	// Plaques de cendres : un bruit large, aux bords adoucis par un plus fin ; le seuil monte avec la vie.
	float fine = texture(ash_noise, ground * 0.06 + vec2(0.37, 0.11)).r;
	float patches = texture(ash_noise, ground * 0.011).r * 0.8 + fine * 0.2;
	float cover = 0.5 + 0.28 * life;
	float ash = smoothstep(cover, cover + 0.12, patches) * (1.0 - smoothstep(0.8, 0.95, life));
	vec3 ash_tone = mix(ash_color, char_color, smoothstep(0.35, 0.75, fine) * 0.6);
	ALBEDO = mix(albedo, ash_tone, ash * 0.75);
	ROUGHNESS = 1.0;
	SPECULAR = 0.05;
}
