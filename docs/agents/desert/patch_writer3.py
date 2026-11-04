from pathlib import Path

p = Path("C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/write_desert_tscn.py")
t = p.read_text(encoding="utf-8")


def rep(old, new, count=1):
    global t
    assert t.count(old) == count, (t.count(old), old[:90])
    t = t.replace(old, new)


# Ciel brûlant, horizon voilé de chaleur, soleil dur et chaud, brume de sable au ras des dunes.
rep('''sky_top_color = Color(0.36, 0.55, 0.78, 1)
sky_horizon_color = Color(0.92, 0.78, 0.58, 1)
ground_bottom_color = Color(0.5, 0.38, 0.24, 1)
ground_horizon_color = Color(0.92, 0.78, 0.58, 1)
sun_angle_max = 20.0''', '''sky_top_color = Color(0.3, 0.5, 0.76, 1)
sky_horizon_color = Color(0.96, 0.76, 0.5, 1)
ground_bottom_color = Color(0.5, 0.38, 0.24, 1)
ground_horizon_color = Color(0.96, 0.76, 0.5, 1)
sun_angle_max = 14.0
sun_curve = 0.1''')
rep('''ambient_light_energy = 0.45
tonemap_mode = 3
tonemap_exposure = 0.95''', '''ambient_light_energy = 0.36
tonemap_mode = 3
tonemap_exposure = 0.95''')
rep('''fog_light_color = Color(0.86, 0.72, 0.52, 1)
fog_density = 0.006
fog_sky_affect = 0.15''', '''fog_light_color = Color(0.9, 0.73, 0.5, 1)
fog_density = 0.007
fog_sky_affect = 0.2
fog_height = 1.2
fog_height_density = 0.06''')
rep('''        "light_color = Color(1, 0.88, 0.7, 1)", "light_energy = 1.0", "shadow_enabled = true",''',
    '''        "light_color = Color(1, 0.84, 0.6, 1)", "light_energy = 1.35", "shadow_enabled = true",''')
rep('''    ("AudioStream", A + "stone_door.wav", "53_rumble"),''', '''    ("AudioStream", A + "stone_door.wav", "53_rumble"),
    ("AudioStream", A + "plaine_wind.wav", "54_ruin_wind"),''')
# Vent qui siffle dans les ruines : des sources posées sur les pierres, en plus du vent qui souffle partout.
rep('''    # Volcan en éveil au nord''', '''    node(lines, "Sounds", "Node3D", "Exterior")
    for name, x, y, z, stream, pitch, volume in (
        ("WindSanctum", 0.0, 3.0, -24.0, "54_ruin_wind", 0.85, -3.0),
        ("WindArch", 0.0, 4.0, 16.0, "40_wind", 1.25, -6.0),
        ("WindGate", 24.0, 2.0, -44.0, "40_wind", 1.4, -2.0),
        ("WindColonnade", -22.0, 2.5, -48.0, "54_ruin_wind", 1.1, -3.0),
        ("WindBeast", 26.0, 2.0, 50.0, "54_ruin_wind", 0.7, -4.0),
        ("WindHead", -34.0, 4.0, 30.0, "40_wind", 0.9, -5.0),
    ):
        node(lines, name, "AudioStreamPlayer3D", "Exterior/Sounds", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, {z:g})", f'stream = ExtResource("{stream}")',
            f"pitch_scale = {pitch:g}", f"volume_db = {volume:g}", "unit_size = 7.0", "max_distance = 30.0", "autoplay = true"])
    # Volcan en éveil au nord''')
p.write_text(t, encoding="utf-8", newline="\n")
print("ok")
