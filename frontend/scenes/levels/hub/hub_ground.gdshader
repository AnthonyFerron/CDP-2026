shader_type spatial;
render_mode cull_back;

// Sol du hub : l'herbe est grise et sèche au début, puis reverdit à mesure que les livres reviennent.

// 0 : aucun livre rapporté ; 1 : les quatre livres sont revenus.
uniform float life : hint_range(0.0, 1.0) = 0.0;
uniform vec3 dead_tint : source_color = vec3(0.42, 0.38, 0.32);

void fragment() {
	vec3 color = COLOR.rgb;
	float grey = dot(color, vec3(0.3, 0.59, 0.11));
	vec3 dead = vec3(grey) * dead_tint * 2.2;
	ALBEDO = mix(dead, color, 0.25 + life * 0.75);
	ROUGHNESS = 1.0;
	SPECULAR = 0.05;
}
