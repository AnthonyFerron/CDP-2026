"""Toiles : un liseré sombre et une bande claire tissée, plus d'aplat uni ; fanion du poste de garde moins sombre."""
from pathlib import Path

F = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/scenes/levels/desert")
p = F / "desert_cloth.gdshader"
t = p.read_text(encoding="utf-8")
old = '''void fragment() {
	// Toile délavée par le soleil, plus claire vers le bord libre.
	ALBEDO = color * (0.8 + 0.25 * (hanging ? UV.y : UV.x));
	ROUGHNESS = 1.0;
}'''
new = '''void fragment() {
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
}'''
assert t.count(old) == 1
p.write_text(t.replace(old, new), encoding="utf-8", newline="\n")

p = F / "desert_life.gd"
t = p.read_text(encoding="utf-8")
old = "[Vector3(35.2, 0.0, 30.2), 3.0, Vector2(1.3, 0.6), Color(0.18, 0.28, 0.5)],"
assert t.count(old) == 1
p.write_text(t.replace(old, "[Vector3(35.2, 0.0, 30.2), 3.0, Vector2(1.3, 0.6), Color(0.24, 0.36, 0.6)],"), encoding="utf-8", newline="\n")
print("ok")
