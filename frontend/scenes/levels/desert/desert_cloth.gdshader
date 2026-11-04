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
	ALBEDO = color * (0.8 + 0.25 * (hanging ? UV.y : UV.x));
	ROUGHNESS = 1.0;
}
