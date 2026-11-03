shader_type spatial;
render_mode unshaded, cull_disabled;

// Surface d'un portail en arche : un rectangle surmonté d'un demi-cercle, qui tourbillonne.

uniform vec3 inner_color : source_color = vec3(1.0, 0.85, 0.4);
uniform vec3 outer_color : source_color = vec3(0.9, 0.12, 0.03);
uniform float spin_speed = 0.8;
// Dimensions de l'ouverture, en mètres : largeur et hauteur des piliers droits.
uniform float opening_width = 2.0;
uniform float pillar_height = 2.2;

void fragment() {
	float half_width = opening_width * 0.5;
	float height = pillar_height + half_width;
	vec2 point = vec2((UV.x - 0.5) * opening_width, (1.0 - UV.y) * height);
	// Distance au bord de l'arche, normalisée : 0 au centre, 1 sur le bord.
	float edge = point.y < pillar_height
		? abs(point.x) / half_width
		: length(point - vec2(0.0, pillar_height)) / half_width;
	if (edge > 1.0) {
		discard;
	}
	vec2 centered = point - vec2(0.0, height * 0.45);
	float angle = atan(centered.y, centered.x);
	float swirl = sin(angle * 3.0 + length(centered) * 5.0 - TIME * spin_speed * 4.0);
	ALBEDO = mix(inner_color, outer_color, clamp(edge * 0.9 + swirl * 0.2, 0.0, 1.0));
	ALPHA = 1.0 - smoothstep(0.9, 1.0, edge);
}
