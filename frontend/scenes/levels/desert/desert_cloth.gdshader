shader_type spatial;
render_mode cull_disabled;

// Toile qui claque au vent : un plan subdivisé dont les vagues grandissent loin du bord attaché.
// hanging : attachée par le haut (bannière) ; sinon par le bord gauche (fanion sur sa hampe).

uniform vec3 color : source_color = vec3(0.6, 0.18, 0.1);
uniform float speed = 6.0;
uniform float amplitude = 0.14;
uniform float phase = 0.0;
uniform bool hanging = false;

void vertex() {
	float weight = hanging ? UV.y : UV.x;
	float wave = sin(TIME * speed + UV.x * 7.0 + UV.y * 2.5 + phase) + 0.45 * sin(TIME * speed * 1.7 + UV.x * 13.0 + phase * 2.0);
	VERTEX.y += wave * amplitude * weight;
}

void fragment() {
	// Toile délavée par le soleil, plus claire vers le bord libre.
	vec3 base = color * (0.8 + 0.25 * (hanging ? UV.y : UV.x));
	// Une bande claire tissée au milieu (verticale sur une bannière, en long sur un fanion) et un liseré sombre
	// le long des bords cousus : la toile a un motif, pas un aplat uni.
	float band = hanging ? step(abs(UV.x - 0.5), 0.12) : step(abs(UV.y - 0.5), 0.11);
	float hem = hanging
		? max(step(UV.y, 0.05), max(step(UV.x, 0.05), step(0.95, UV.x)))
		: max(step(UV.x, 0.06), max(step(UV.y, 0.09), step(0.91, UV.y)));
	base = mix(base, mix(base, vec3(0.93, 0.84, 0.66), 0.55), band);
	base = mix(base, base * 0.55, hem);
	ALBEDO = base;
	ROUGHNESS = 1.0;
}
