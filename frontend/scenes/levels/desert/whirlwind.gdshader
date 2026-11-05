shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// Tourbillon de sable : un entonnoir ouvert (CylinderMesh plus large en haut) où des traînées de sable
// tournent et montent. Le haut se dissout dans l'air, le pied touche le sol ; le fût ondule au vent.

uniform sampler2D noise : repeat_enable, filter_linear_mipmap;
uniform vec3 color : source_color = vec3(0.72, 0.54, 0.35);
uniform float height = 9.0;
uniform float spin = 1.6;
uniform float opacity = 0.62;
uniform float sway = 1.0;
uniform float phase = 0.0;

varying float rise;

void vertex() {
	rise = clamp(VERTEX.y / height + 0.5, 0.0, 1.0);
	VERTEX.x += sin(TIME * 0.9 + rise * 2.6 + phase) * sway * rise * rise;
	VERTEX.z += cos(TIME * 0.7 + rise * 2.1 + phase) * sway * rise * rise;
}

void fragment() {
	// UV.x fait le tour du cylindre sans couture. Deux couches de traînées montent en spirale, chacune à vitesse
	// constante (une vitesse qui changerait avec la hauteur tordrait le motif un peu plus à chaque seconde) :
	// la rapide en bas, où l'entonnoir est étroit, la lente en haut.
	vec2 low = vec2(UV.x * 4.0 + rise * 1.4 + TIME * spin * 1.3, rise * 0.55 - TIME * 0.3);
	vec2 high = vec2(UV.x * 3.0 + rise * 1.0 + TIME * spin * 0.6, rise * 0.5 - TIME * 0.22 + 0.5);
	float n = mix(texture(noise, low).r, texture(noise, high).r, rise);
	float n2 = texture(noise, low * vec2(2.0, 1.5) + vec2(0.37, TIME * 0.15)).r;
	float streak = smoothstep(0.38, 0.72, n * 0.6 + n2 * 0.5);
	float ends = smoothstep(0.0, 0.05, rise) * (1.0 - smoothstep(0.45, 1.0, rise));
	// Plus dense sur les bords vus de biais, comme un voile qu'on regarde par la tranche.
	float edge = mix(1.0, 0.55, abs(dot(NORMAL, VIEW)));
	float body = 0.22 + 0.78 * streak;
	ALBEDO = color * (0.82 + 0.3 * n2);
	ALPHA = clamp(body * ends * edge * opacity * (1.25 - 0.5 * rise), 0.0, 1.0);
}
