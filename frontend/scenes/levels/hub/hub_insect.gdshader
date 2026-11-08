shader_type spatial;
render_mode cull_disabled, unshaded, shadows_disabled;

// Papillons du jardin et libellules de la rivière, revenus avec les livres (hub_wildlife.gd) : chaque copie d'un
// MultiMesh vole en boucle autour de sa place, ailes battantes, sans aucun calcul du processeur. Le maillage est à
// plat, la tête vers +Z, une aile de chaque côté de x = 0.
// INSTANCE_CUSTOM : r, décalage de phase (0 à 1) ; g, rayon du vol (m) ; b, vitesse (rad/s) ; a, hauteur du vol (m).

// Battements d'ailes par seconde (en radians), et leur amplitude.
uniform float flap_speed = 14.0;
uniform float flap = 0.9;

varying vec3 tint;

vec3 path(float t, float radius, float height, float phase) {
	return vec3(sin(t) * radius, height + 0.22 * sin(t * 2.3 + phase * 9.0), sin(t * 0.71 + phase * 4.0) * cos(t * 0.5) * radius);
}

void vertex() {
	float phase = INSTANCE_CUSTOM.r;
	float t = TIME * INSTANCE_CUSTOM.b + phase * 6.2832;
	vec3 here = path(t, INSTANCE_CUSTOM.g, INSTANCE_CUSTOM.a, phase);
	vec3 ahead = path(t + 0.05, INSTANCE_CUSTOM.g, INSTANCE_CUSTOM.a, phase) - here;
	float yaw = atan(ahead.x, ahead.z);
	// Ailes : chacune tourne autour du corps (l'axe z), en sens contraires.
	float angle = sin(TIME * flap_speed + phase * 40.0) * flap;
	vec3 v = VERTEX;
	v = vec3(v.x * cos(angle), v.y + abs(v.x) * sin(angle), v.z);
	v = vec3(v.x * cos(yaw) + v.z * sin(yaw), v.y, -v.x * sin(yaw) + v.z * cos(yaw));
	VERTEX = v + here;
	tint = COLOR.rgb;
}

void fragment() {
	ALBEDO = tint;
}
