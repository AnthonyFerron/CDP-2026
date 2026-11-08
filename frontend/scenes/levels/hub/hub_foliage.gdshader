shader_type spatial;
render_mode cull_disabled;

// Feuillage du décor dispersé du hub (arbres, forêt, buissons, roseaux, nénuphars) : il reprend la couleur, la texture
// et le métal de son matériau Kenney, et ne s'en écarte que tant que sa copie n'a pas repris vie. Chaque copie d'un
// MultiMesh porte dans INSTANCE_CUSTOM.r le palier de vie (0, 0,25, 0,5, 0,75 ou 1) où elle reverdit : en dessous, son
// feuillage est sec, gris et brun, comme brûlé par les cendres. Un MultiMesh sans données par copie reste vert.
// Aucun appel de dessin de plus : la copie verte et la copie sèche sont le même maillage.

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;
uniform float metallic = 0.0;
uniform float roughness = 1.0;
// Vie du hub : 0 sans livre posé, 1 avec les quatre (Hub._apply_life).
uniform float life : hint_range(0.0, 1.0) = 1.0;
// Teinte du feuillage sec.
uniform vec3 withered : source_color = vec3(0.46, 0.36, 0.25);

varying float revive;

void vertex() {
	revive = INSTANCE_CUSTOM.r;
}

void fragment() {
	vec3 color = albedo.rgb * texture(albedo_texture, UV).rgb;
	// Pendant le plan large de la réparation, la vie monte en quatre secondes : chaque copie reverdit en fondu.
	float alive = smoothstep(revive - 0.12, revive - 0.01, life);
	float grey = dot(color, vec3(0.3, 0.59, 0.11));
	vec3 dead = mix(vec3(grey), withered, 0.7) * 0.72;
	ALBEDO = mix(dead, color, alive);
	METALLIC = metallic;
	ROUGHNESS = roughness;
}
