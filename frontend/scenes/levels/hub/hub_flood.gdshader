shader_type spatial;
render_mode cull_disabled;

// Coulée de lave de la fin perdue (hub_lava_flood.gd). UV.x : instant où la lave atteint le sommet, en secondes ;
// UV.y : hauteur dont elle monte ensuite. Le bord suit cet instant, déformé par un bruit en lobes : il épouse
// le relief, sans découpe ronde. Derrière le front, la nappe s'épaissit ; sa croûte sombre se fend de veines
// incandescentes, plus vives là où la lave vient d'arriver.

uniform sampler2D flow_noise : repeat_enable, filter_linear;
uniform float progress = 0.0;
// Temps que met la nappe à monter derrière le front, et irrégularité du bord (en secondes d'avance ou de retard).
uniform float ramp = 1.6;
uniform float edge_jitter = 1.2;
uniform vec3 core_color : source_color = vec3(1.0, 0.72, 0.22);
uniform vec3 hot_color : source_color = vec3(1.0, 0.3, 0.04);
uniform vec3 crust_color : source_color = vec3(0.07, 0.04, 0.035);
uniform float emission_strength = 3.0;

varying float arrival;
varying vec3 world_pos;

void vertex() {
	arrival = UV.x;
	float rise = smoothstep(0.0, ramp, progress - UV.x);
	VERTEX.y += 0.12 + rise * UV.y;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// Veine fine là où le bruit passe par 0,5, d'une largeur constante à l'écran.
float vein(float value, float width) {
	float distance = abs(value - 0.5);
	float pixel = fwidth(value);
	return 1.0 - smoothstep(width, width + pixel * 1.5, distance);
}

void fragment() {
	float lobes = texture(flow_noise, world_pos.xz * 0.021).r * 0.7 + texture(flow_noise, world_pos.xz * 0.09).r * 0.3;
	float age = progress - arrival + (lobes - 0.5) * 2.0 * edge_jitter;
	if (age < 0.0) {
		discard;
	}
	// La croûte dérive lentement vers le sud, l'aval de la coulée.
	vec2 drift = vec2(0.002, -0.012) * TIME;
	float plates = texture(flow_noise, world_pos.xz * 0.028 + drift).r;
	float detail = texture(flow_noise, world_pos.xz * 0.085 + drift * 1.6).r;
	float veins = max(vein(plates, 0.035), vein(detail, 0.02) * 0.7);

	// Lave fraîche : vive au front qui avance ; elle se couvre de croûte en quelques secondes.
	float fresh = 1.0 - smoothstep(0.3, 5.0, age);
	// Le bord tout juste arrivé reste sombre : un bourrelet de croûte qui roule devant la coulée.
	float rim = 1.0 - smoothstep(0.0, 0.35, age);
	float open = smoothstep(0.42, 0.62, detail * 0.5 + plates * 0.5) * fresh;
	float heat = clamp(max(veins, open) * (1.0 - rim * 0.8), 0.0, 1.0);
	float pulse = 0.88 + 0.12 * sin(TIME * 1.7 + plates * 18.0);
	vec3 glow = mix(hot_color, core_color, heat * (0.4 + 0.6 * fresh));

	ALBEDO = mix(crust_color, glow * 0.3, heat);
	// La croûte garde un rougeoiement sourd : la nappe se lit de loin, même refroidie.
	EMISSION = (glow * heat * pulse + hot_color * 0.08 * (1.0 - rim)) * emission_strength;
	ROUGHNESS = mix(0.95, 0.4, heat);
	SPECULAR = 0.15;
}
