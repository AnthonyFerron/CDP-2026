shader_type spatial;
// Lumière de la brèche de la voûte (library_breach.gd), sans lumière dynamique : des surfaces qui luisent, additives,
// sans ombrage ni profondeur écrite.
//   mode 0 : le rai qui tombe du trou jusqu'au sol, tourné vers la caméra autour de la verticale, plus étroit en haut,
//            qui s'efface vers le sol, traversé de stries de poussière lentes ;
//   mode 1 : la tache de lumière qu'il pose au sol ;
//   mode 2 : le ciel de cendre vu par le trou, bordé de braises qui rougeoient.
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform int mode = 0;
uniform vec4 color : source_color = vec4(0.95, 0.6, 0.5, 1.0);
uniform vec4 ember_color : source_color = vec4(1.0, 0.42, 0.12, 1.0);
uniform float energy = 1.0;
// Largeur du rai en haut et au pied, en part de la largeur du quadrilatère.
uniform float top_width = 0.7;
uniform float bottom_width = 1.0;
// Respiration de la lueur, donnée par le script : 1 au repos.
uniform float pulse = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	if (mode == 0) {
		// Tourné vers la caméra autour de l'axe vertical (comme BILLBOARD_FIXED_Y).
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
			vec4(0.0, 1.0, 0.0, 0.0),
			vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
			MODEL_MATRIX[3]);
		MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	}
}

void fragment() {
	float alpha;
	vec3 tint = color.rgb;
	if (mode == 0) {
		// UV.y vaut 0 en haut, contre la voûte, et 1 au pied.
		float half_width = mix(top_width, bottom_width, UV.y) * 0.5;
		float across = abs(UV.x - 0.5) / max(half_width, 0.001);
		float edge = 1.0 - smoothstep(0.3, 1.0, across);
		float ends = smoothstep(0.0, 0.05, UV.y) * (1.0 - smoothstep(0.82, 1.0, UV.y));
		float drift = 0.7 + 0.3 * noise(vec2(UV.x * 7.0 + TIME * 0.12, UV.y * 2.5 - TIME * 0.08));
		alpha = edge * edge * mix(1.0, 0.45, UV.y) * ends * drift;
	} else if (mode == 1) {
		float d = length(UV - vec2(0.5)) * 2.0;
		alpha = 1.0 - smoothstep(0.15, 1.0, d);
		alpha *= alpha;
	} else {
		float rim = max(abs(UV.x - 0.5), abs(UV.y - 0.5)) * 2.0;
		float n = noise(UV * 6.0 + vec2(TIME * 0.05, -TIME * 0.04)) * noise(UV * 13.0 - vec2(TIME * 0.09, TIME * 0.06));
		float embers = smoothstep(0.55, 1.0, rim) * smoothstep(0.08, 0.3, n);
		tint = mix(color.rgb, ember_color.rgb * 1.6, embers);
		alpha = 0.55 + 0.45 * embers;
	}
	ALBEDO = tint * energy * pulse;
	ALPHA = clamp(alpha, 0.0, 1.0);
}
