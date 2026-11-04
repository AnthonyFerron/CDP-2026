shader_type spatial;

// Dallage des archives : grandes dalles décalées d'une rangée à l'autre, joints sombres, teinte qui varie d'une dalle
// à l'autre et traces de suie.

uniform vec3 stone_color : source_color = vec3(0.34, 0.3, 0.28);
uniform vec3 joint_color : source_color = vec3(0.1, 0.085, 0.08);
uniform vec2 tile_size = vec2(1.3, 0.9);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 p = world_pos.xz / tile_size;
	p.x += mod(floor(p.y), 2.0) * 0.5;
	vec2 cell = floor(p);
	vec2 f = fract(p);
	float edge = min(min(f.x, 1.0 - f.x) * tile_size.x, min(f.y, 1.0 - f.y) * tile_size.y);
	float joint = 1.0 - smoothstep(0.012, 0.03, edge);
	float shade = 0.75 + 0.4 * hash(cell);
	float soot = smoothstep(0.55, 0.95, hash(cell + 17.3)) * 0.35;
	ALBEDO = mix(stone_color * shade * (1.0 - soot), joint_color, joint);
	ROUGHNESS = 0.95;
	SPECULAR = 0.2;
}
