"""Ambiance du Village dans ma copie de write_village_tscn.py : lumière d'appoint du ciel, braises, fumées des
cheminées, sons 3D (roue du moulin, vent, four, forge, mairie), poussière dans la mairie."""
import math
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")


def sub(old, new, count=1):
    global text
    assert text.count(old) == count, (old[:80], text.count(old))
    text = text.replace(old, new)


sub('''    ("PackedScene", K + "furniture_kit/books.glb", "58_books"),
''', '''    ("PackedScene", K + "furniture_kit/books.glb", "58_books"),
    ("Script", "res://scenes/levels/village/village_particles.gd", "60_particles"),
    ("AudioStream", A + "desert_wind.wav", "61_wind"),
    ("AudioStream", A + "plaine_wind.wav", "62_ruin_wind"),
    ("AudioStream", A + "cave_ambience.wav", "63_hall"),
''')
sub('''SMOKES = [(-28.0, -2.0, 1.0), (27.0, -3.5, 1.4), (-8.6, -1.6, 1.0), (21.6, 34.0, 1.1), (-10.0, 20.0, 1.0)]''',
    '''SMOKES = [(-28.0, -2.0, 1.0), (27.0, -3.5, 1.4), (-8.6, -1.6, 1.0), (21.6, 34.0, 1.1), (-10.0, 20.0, 1.0)]
# Filets de fumée claire des cheminées encore tièdes : la boulangerie et la forge (x, hauteur, z).
CHIMNEYS = [(12.65, 4.0, 28.7), (13.45, 4.1, 18.6)]
# Braises qui montent : les feux, la bouche du four, le foyer de la forge (x, hauteur, z, demi-largeur).
EMBERS = [(x, 0.5, z, 0.45 * size) for x, z, size in [(4.6, 35.6, 0.9), (-7.5, -0.7, 0.7), (26.0, -2.2, 1.0),
                                                      (-27.0, -1.0, 0.9), (21.4, 34.6, 0.8)]]
EMBERS += [(11.1, 1.25, 28.7, 0.2), (12.3, 1.3, 18.6, 0.3)]
# Sons posés sur les objets : nom, son, position, volume, portée.
SOUNDS = [
    ("WheelSound", "41_stream", (-36.5, 0.5, -14.0), -2.0, 26.0, 0.75),
    ("WindmillWind", "61_wind", (30.0, 12.0, -30.0), -9.0, 36.0, 1.0),
    ("BreachWind", "62_ruin_wind", (33.0, 3.0, -6.0), -12.0, 26.0, 1.0),
    ("GateWind", "62_ruin_wind", (0.0, 6.0, 42.0), -13.0, 24.0, 0.9),
    ("OvenCrackle", "42_crackle", (11.2, 1.2, 28.7), -15.0, 10.0, 1.1),
    ("ForgeCrackle", "42_crackle", (12.3, 1.3, 18.6), -15.0, 10.0, 0.9),
]''')


def look(direction):
    """Lignes de la base d'une lumière qui éclaire dans la direction donnée."""
    length = math.sqrt(sum(v * v for v in direction))
    d = [v / length for v in direction]
    z = [-d[0], -d[1], -d[2]]
    x = [z[2], 0.0, -z[0]]
    n = math.sqrt(x[0] ** 2 + x[2] ** 2)
    x = [x[0] / n, 0.0, x[2] / n]
    y = [z[1] * x[2] - z[2] * x[1], z[2] * x[0] - z[0] * x[2], z[0] * x[1] - z[1] * x[0]]
    rows = [[x[i], y[i], z[i]] for i in range(3)]
    return ", ".join(f"{v:.4f}" for row in rows for v in row)


sub('''    node(lines, "Terrain", "StaticBody3D",''', f'''    # Lumière d'appoint du ciel, froide et sans ombre, venue de l'est : le côté des murs à l'ombre du soleil
    # couchant n'est plus noir.
    node(lines, "SkyFill", "DirectionalLight3D", props=[
        "transform = Transform3D({look((-0.6, -0.5, 0.6))}, 0, 30, 0)",
        "light_color = Color(0.58, 0.64, 0.92, 1)", "light_energy = 0.24", "light_specular = 0.0"])
    node(lines, "Terrain", "StaticBody3D",''')
sub('''    node(lines, "Smokes", "Node3D")
    for index, (x, z, radius) in enumerate(SMOKES):
        node(lines, f"Smoke{index}", "CPUParticles3D", "Smokes", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, 3.5, {z:g})", 'script = ExtResource("11_smoke")',
            f"radius = {radius:g}"])''', '''    node(lines, "Smokes", "Node3D")
    for index, (x, z, radius) in enumerate(SMOKES):
        node(lines, f"Smoke{index}", "CPUParticles3D", "Smokes", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, 3.5, {z:g})", 'script = ExtResource("11_smoke")',
            f"radius = {radius:g}"])
    for index, (x, y, z) in enumerate(CHIMNEYS):
        node(lines, f"Chimney{index}", "CPUParticles3D", "Smokes", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, {z:g})", 'script = ExtResource("11_smoke")',
            "radius = 0.15", "puff_size = 1.4", "rise_speed = 0.9", "smoke_color = Color(0.5, 0.47, 0.45, 1)"])
    node(lines, "Embers", "Node3D")
    for index, (x, y, z, half) in enumerate(EMBERS):
        node(lines, f"Embers{index}", "CPUParticles3D", "Embers", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, {z:g})", 'script = ExtResource("60_particles")',
            f"extents = Vector3({half:g}, 0.15, {half:g})"])
    node(lines, "Sounds", "Node3D")
    for name, stream, (x, y, z), volume, reach, pitch in SOUNDS:
        node(lines, name, "AudioStreamPlayer3D", "Sounds", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, {z:g})", f'stream = ExtResource("{stream}")',
            f"volume_db = {volume:g}", "unit_size = 5.0", f"max_distance = {reach:g}", f"pitch_scale = {pitch:g}",
            "autoplay = true"])''')
sub('''    node(lines, "Fragments", "Node3D", "Interior")''', '''    # Poussière qui flotte dans la lumière de la mairie, et le souffle feutré des pièces fermées.
    for name, (x, y, z), half, tint in (("DustHall", (0.0, 2.0, 0.0), (7.0, 1.6, 5.2), "Color(1, 0.86, 0.62, 1)"),
                                        ("DustOffice", (0.0, OFFICE + 1.7, 0.0), (7.0, 1.5, 5.2), "Color(1, 0.86, 0.62, 1)"),
                                        ("DustSecret", (-12.0, OFFICE + 1.7, 0.0), (3.4, 1.4, 3.4), "Color(0.82, 0.72, 1, 1)")):
        node(lines, name, "CPUParticles3D", "Interior", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, {z:g})", 'script = ExtResource("60_particles")',
            "kind = 1", f"extents = Vector3({half[0]:g}, {half[1]:g}, {half[2]:g})", f"tint = {tint}"])
    node(lines, "HallHum", "AudioStreamPlayer3D", "Interior", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 3, 0)", 'stream = ExtResource("63_hall")',
        "volume_db = -16.0", "unit_size = 8.0", "max_distance = 30.0", "autoplay = true"])
    node(lines, "Fragments", "Node3D", "Interior")''')
path.write_text(text, encoding="utf-8", newline="\n")
print("ok")
