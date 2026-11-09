shader_type spatial;
render_mode cull_back;

// Sol du Village : la couleur vient des faces, assombrie dans le bourg et sur ses abords, pleine au fond du lit du
// ruisseau. Il est mat partout.
// Le Village prenait le sol du Marais (marais_ground.gdshader) avec wet_height = -0.2 : son smoothstep(0.0, -0.2, y),
// aux bornes inversées, rendait « mouillé » tout le sol au-dessus de 0, c'est-à-dire tout le bourg. Luisant
// (rugosité 0,35), il renvoyait le soleil couchant en grandes taches blanches dès qu'on regardait vers l'ouest. Les
// couleurs restent celles d'avant : seul ce reflet disparaît.

// Profondeur sous laquelle le sol reprend sa couleur pleine (le bas des berges et le lit).
uniform float shade_depth = 0.2;

varying float height;

void vertex() {
	height = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	float t = clamp(-height / shade_depth, 0.0, 1.0);
	float bed = t * t * (3.0 - 2.0 * t);
	ALBEDO = COLOR.rgb * mix(0.65, 1.0, bed);
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
}
