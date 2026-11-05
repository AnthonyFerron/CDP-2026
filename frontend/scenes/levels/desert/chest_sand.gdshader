shader_type spatial;
render_mode cull_back;

// Tas de sable qui couvre le coffre du livre, dans la cave du Désert (desert.gd l'anime).
// Le maillage est un cylindre de rayon 1 et de hauteur 1, centré : le shader en fait un dôme posé sur le sol. Quand
// spread passe de 0 à 1, le sable glisse du sommet vers le bas et s'étale en une couche mince autour du coffre, sans
// disparaître : le haut part le premier, et chaque côté à son heure. Les faces sont plates, comme le reste du décor.

uniform float spread : hint_range(0.0, 1.0) = 0.0;
// Dôme du départ : rayon au sol et hauteur, en mètres. Il couvre tout le coffre (coins du couvercle : 0,95 m du
// centre, à 0,99 m de haut).
uniform float radius = 1.6;
uniform float height = 1.4;
// Couche étalée de la fin : rayon et épaisseur au plus haut.
uniform float spread_radius = 2.3;
uniform float layer = 0.1;
uniform vec3 color : source_color = vec3(0.8, 0.62, 0.38);

varying float shade;

void vertex() {
	// t : 0 au pied du dôme, 1 au sommet. Le couvercle du cylindre (y = 0,5) se replie au sommet.
	float t = clamp(VERTEX.y + 0.5, 0.0, 1.0);
	float len = length(VERTEX.xz);
	vec2 dir = len > 0.0001 ? VERTEX.xz / len : vec2(1.0, 0.0);
	float angle = atan(dir.y, dir.x);
	float phi = t * 1.5707963;
	// Irrégularité autour du tas : chaque côté glisse un peu plus tôt ou plus tard, et s'étale plus ou moins loin.
	float n = 0.5 + 0.25 * sin(3.0 * angle + 1.3) + 0.25 * sin(5.0 * angle + 4.1);
	float start_r = radius * cos(phi);
	float start_y = height * sin(phi) * (0.94 + 0.06 * n);
	float end_r = 0.3 + (spread_radius - 0.3) * cos(phi) * (0.88 + 0.24 * n);
	float end_y = layer * sin(phi) * (0.6 + 0.4 * n);
	// Le sommet part le premier, le pied en dernier : chaque sommet finit quand spread atteint 1.
	float delay = 0.45 * (1.0 - t) + 0.2 * n;
	float fall = smoothstep(delay, delay + 0.3, spread);
	float slide = smoothstep(delay, delay + 0.35, spread);
	// Le sable qui coule bombe un peu en avant de la pente avant de se poser.
	float bulge = 0.22 * sin(slide * 3.1415927) * (1.0 - t * 0.5);
	// Le centre du couvercle reste sur l'axe : sans lui, le sommet se replierait en éventail.
	float r = (mix(start_r, end_r, slide) + bulge) * step(0.0001, len);
	VERTEX = vec3(dir.x * r, mix(start_y, end_y, fall), dir.y * r);
	shade = 0.9 + 0.1 * t * (1.0 - fall);
}

void fragment() {
	// Normale de la face : le dôme déformé n'a pas de normales justes, et les faces plates vont au style du décor.
	vec3 face = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	if (dot(face, VIEW) < 0.0) {
		face = -face;
	}
	NORMAL = face;
	ALBEDO = color * shade;
	ROUGHNESS = 1.0;
	SPECULAR = 0.2;
}
