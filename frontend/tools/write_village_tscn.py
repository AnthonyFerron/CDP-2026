"""Écrit frontend/scenes/levels/village/village.tscn : l'ambiance, le terrain, les moulins, les panneaux de lore,
la mairie et son intérieur sous la carte (fragments, meubles qui s'ouvrent, dispositif des cinq codes, salle secrète).
Les murs et les meubles de l'intérieur sont dans village_hall.tscn (tools/build_village.py) : les positions des
fragments et des meubles qui s'ouvrent ci-dessous doivent rester en accord avec eux.

    python write_village_tscn.py <dossier frontend>
"""
import math
import sys
from pathlib import Path

FRONTEND = Path(sys.argv[1])
K = "res://assets/models/kenney/"
A = "res://assets/audio/"
EXT = [
    ("Script", "res://scenes/levels/village/village.gd", "1_village"),
    ("Script", "res://scenes/levels/village/village_terrain.gd", "2_terrain"),
    ("Script", "res://scenes/levels/village/village_scatter.gd", "3_scatter"),
    ("Shader", "res://scenes/levels/marais/marais_ground.gdshader", "4_ground"),
    ("Shader", "res://scenes/levels/marais/swamp_water.gdshader", "5_water"),
    ("PackedScene", "res://scenes/levels/village/village_props.tscn", "6_props"),
    ("PackedScene", "res://scenes/props/portal/portal.tscn", "7_portal"),
    ("PackedScene", "res://scenes/player/player.tscn", "8_player"),
    ("PackedScene", "res://scenes/ui/hud.tscn", "9_hud"),
    ("Script", "res://scripts/fire_effect.gd", "10_fire"),
    ("Script", "res://scripts/smoke_effect.gd", "11_smoke"),
    ("Script", "res://scripts/flickering_light.gd", "12_flicker"),
    ("PackedScene", K + "fantasy_town_kit/windmill.glb", "13_windmill"),
    ("PackedScene", K + "fantasy_town_kit/watermill.glb", "14_watermill"),
    ("Script", "res://scripts/sign_board.gd", "15_sign"),
    ("PackedScene", K + "nature_kit/grass_large.glb", "20_grass"),
    ("PackedScene", K + "nature_kit/grass_leafsLarge.glb", "21_grass_leafs"),
    ("PackedScene", K + "nature_kit/plant_bush.glb", "22_bush"),
    ("PackedScene", K + "mini_arena/bricks.glb", "23_bricks"),
    ("PackedScene", K + "castle_kit/rocks-small.glb", "24_rocks_small"),
    ("PackedScene", K + "graveyard_kit/debris-wood.glb", "25_debris_wood"),
    ("PackedScene", K + "nature_kit/tree_default.glb", "26_tree_default"),
    ("PackedScene", K + "nature_kit/tree_oak.glb", "27_tree_oak"),
    ("PackedScene", K + "nature_kit/tree_thin_dark.glb", "28_tree_thin"),
    ("PackedScene", K + "graveyard_kit/pine-crooked.glb", "29_pine"),
    ("PackedScene", K + "nature_kit/rock_largeB.glb", "30_rock"),
    ("PackedScene", K + "castle_kit/rocks-large.glb", "31_rocks_large"),
    ("AudioStream", A + "village_ambience.wav", "40_ambience"),
    ("AudioStream", A + "stream.wav", "41_stream"),
    ("AudioStream", A + "fire_crackle.wav", "42_crackle"),
    ("AudioStream", A + "footstep_ash_1.wav", "43_step1"),
    ("AudioStream", A + "footstep_ash_2.wav", "44_step2"),
    ("AudioStream", A + "footstep_ash_3.wav", "45_step3"),
    ("AudioStream", A + "tablet_chime_2.wav", "46_chime"),
    ("AudioStream", A + "tablet_reset.wav", "47_reject"),
    ("AudioStream", A + "stone_door.wav", "48_rumble"),
    ("PackedScene", "res://scenes/levels/village/village_hall.tscn", "50_hall"),
    ("Script", "res://scenes/levels/village/paper_fragment.gd", "51_fragment"),
    ("Script", "res://scenes/levels/village/storage.gd", "52_storage"),
    ("Script", "res://scripts/interactable.gd", "53_interactable"),
    ("PackedScene", "res://scenes/levels/village/code_puzzle.tscn", "54_code_puzzle"),
    ("PackedScene", "res://scenes/levels/village/paper_notebook.tscn", "55_notebook"),
    ("PackedScene", K + "furniture_kit/bookcaseClosedWide.glb", "56_shelf"),
    ("Script", "res://scripts/readable.gd", "57_readable"),
    ("PackedScene", K + "furniture_kit/books.glb", "58_books"),
    ("Script", "res://scenes/levels/village/village_particles.gd", "60_particles"),
    ("AudioStream", A + "desert_wind.wav", "61_wind"),
    ("AudioStream", A + "plaine_wind.wav", "62_ruin_wind"),
    ("AudioStream", A + "cave_ambience.wav", "63_hall"),
    ("Script", "res://scenes/levels/village/village_crow.gd", "64_crow"),
    ("Script", "res://scenes/levels/village/village_cat.gd", "65_cat"),
    ("Script", "res://scenes/levels/village/village_life.gd", "66_life"),
    ("Script", "res://scenes/levels/hub/volcano.gd", "90_volcano"),
]

SUBRESOURCES = """
[sub_resource type="ProceduralSkyMaterial" id="ProceduralSkyMaterial_dusk"]
sky_top_color = Color(0.26, 0.28, 0.42, 1)
sky_horizon_color = Color(0.92, 0.58, 0.38, 1)
ground_bottom_color = Color(0.15, 0.13, 0.12, 1)
ground_horizon_color = Color(0.92, 0.58, 0.38, 1)
sun_angle_max = 15.0

[sub_resource type="Sky" id="Sky_dusk"]
sky_material = SubResource("ProceduralSkyMaterial_dusk")

[sub_resource type="Environment" id="Environment_village"]
background_mode = 2
sky = SubResource("Sky_dusk")
ambient_light_source = 3
ambient_light_color = Color(0.78, 0.68, 0.62, 1)
ambient_light_energy = 0.55
tonemap_mode = 3
glow_enabled = true
glow_intensity = 0.6
glow_bloom = 0.05
glow_hdr_threshold = 1.0
fog_enabled = true
fog_light_color = Color(0.62, 0.5, 0.44, 1)
fog_density = 0.012
fog_sky_affect = 0.35

[sub_resource type="ShaderMaterial" id="ShaderMaterial_ground"]
render_priority = 0
shader = ExtResource("4_ground")
shader_parameter/wet_height = -0.2

[sub_resource type="FastNoiseLite" id="FastNoiseLite_ripples"]
seed = 15
frequency = 0.03
fractal_octaves = 3

[sub_resource type="NoiseTexture2D" id="NoiseTexture2D_ripples"]
width = 256
height = 256
seamless = true
noise = SubResource("FastNoiseLite_ripples")

[sub_resource type="ShaderMaterial" id="ShaderMaterial_stream"]
render_priority = 0
shader = ExtResource("5_water")
shader_parameter/ripple_noise = SubResource("NoiseTexture2D_ripples")
shader_parameter/water_color = Color(0.1, 0.17, 0.2, 1)
shader_parameter/scum_color = Color(0.1, 0.17, 0.2, 1)
shader_parameter/opacity = 0.8
shader_parameter/ripple_strength = 0.6

[sub_resource type="PlaneMesh" id="PlaneMesh_stream"]
material = SubResource("ShaderMaterial_stream")
size = Vector2(7.5, 170)

[sub_resource type="StandardMaterial3D" id="Material_wood_dark"]
albedo_color = Color(0.3, 0.2, 0.13, 1)
roughness = 0.9

[sub_resource type="StandardMaterial3D" id="Material_wood"]
albedo_color = Color(0.45, 0.31, 0.2, 1)
roughness = 0.85

[sub_resource type="StandardMaterial3D" id="Material_plaster"]
albedo_color = Color(0.55, 0.5, 0.45, 1)
roughness = 1.0

[sub_resource type="StandardMaterial3D" id="Material_stone"]
albedo_color = Color(0.35, 0.34, 0.36, 1)
roughness = 1.0

[sub_resource type="BoxMesh" id="BoxMesh_plinth"]
material = SubResource("Material_stone")
size = Vector3(2.0, 0.4, 0.9)

[sub_resource type="BoxMesh" id="BoxMesh_stele"]
material = SubResource("Material_stone")
size = Vector3(1.7, 1.5, 0.3)

[sub_resource type="BoxShape3D" id="BoxShape3D_memorial"]
size = Vector3(2.0, 1.9, 0.9)

[sub_resource type="BoxShape3D" id="BoxShape3D_ramp"]
size = Vector3(3, 0.3, 10.06)

[sub_resource type="BoxMesh" id="BoxMesh_console"]
material = SubResource("Material_wood_dark")
size = Vector3(5.8, 1.0, 0.8)

[sub_resource type="BoxMesh" id="BoxMesh_backboard"]
material = SubResource("Material_stone")
size = Vector3(5.8, 1.4, 0.2)

[sub_resource type="BoxShape3D" id="BoxShape3D_console"]
size = Vector3(5.8, 2.5, 1.0)

[sub_resource type="BoxShape3D" id="BoxShape3D_shelf"]
size = Vector3(0.95, 3.0, 3.04)

[sub_resource type="BoxMesh" id="BoxMesh_post"]
material = SubResource("Material_wood_dark")
size = Vector3(0.14, 1.1, 0.14)

[sub_resource type="StandardMaterial3D" id="Material_codonomicon"]
albedo_color = Color(0.3, 0.15, 0.5, 1)
emission_enabled = true
emission = Color(0.45, 0.2, 0.8, 1)
emission_energy_multiplier = 1.5

[sub_resource type="BoxMesh" id="BoxMesh_codonomicon"]
material = SubResource("Material_codonomicon")
size = Vector3(0.55, 0.14, 0.75)
"""

# Feux qui couvent encore : la charrette de la barricade, les cratères des boulets, la maison brûlée, le toit
# effondré des écuries. Fumées qui montent des ruines. La mairie, intacte, ne fume pas.
FIRES = [(4.6, 35.6, 0.9), (-7.5, -0.7, 0.7), (26.0, -2.2, 1.0), (-27.0, -1.0, 0.9), (21.4, 34.6, 0.8)]
SMOKES = [(-28.0, -2.0, 1.0), (27.0, -3.5, 1.4), (-8.6, -1.6, 1.0), (21.6, 34.0, 1.1), (-10.0, 20.0, 1.0)]
# Filets de fumée claire des cheminées encore tièdes : la boulangerie et la forge (x, hauteur, z).
CHIMNEYS = [(12.65, 4.0, 28.7), (13.45, 4.1, 18.6)]
# Braises qui montent : les feux, la bouche du four, le foyer de la forge (x, hauteur, z, demi-largeur).
EMBERS = [(x, 0.5, z, 0.45 * size) for x, z, size in [(4.6, 35.6, 0.9), (-7.5, -0.7, 0.7), (26.0, -2.2, 1.0),
                                                      (-27.0, -1.0, 0.9), (21.4, 34.6, 0.8)]]
EMBERS += [(11.1, 1.25, 28.7, 0.2), (12.3, 1.3, 18.6, 0.3)]
# Corbeaux : position (les pieds), orientation, penché pour picorer. Sur le rempart et la tour de la porte, sur
# l'épouvantail, la clôture de l'enclos, le faîte des écuries, et au sol parmi les vivres de la place.
CROWS = [
    ((-22.4, 5.24, 43.0), 160.0, False), ((13.4, 5.24, 43.1), 200.0, False), ((14.3, 5.24, 42.8), 120.0, False),
    ((6.6, 9.2, 42.6), 10.0, False), ((-27.25, 1.49, 25.5), 100.0, False), ((21.7, 0.84, 17.6), 30.0, False),
    ((26.2, 0.84, 17.6), 250.0, False), ((24.0, 5.37, 31.0), 90.0, False),
    ((-6.2, 0.0, -6.4), 40.0, True), ((-5.5, 0.0, -7.3), 300.0, True), ((7.4, 0.0, 5.2), 200.0, True),
    ((-25.6, 0.0, 30.6), 90.0, True), ((-1.6, 0.0, 37.6), 120.0, True),
]
# Chats qui se promènent : pelage et points de passage. Le noir devant la mairie, le tigré autour du puits.
CATS = [
    ("Color(0.07, 0.07, 0.08, 1)", [(-4.6, 0.0, -18.7), (-1.9, 0.0, -18.4), (-3.4, 0.0, -17.3)]),
    ("Color(0.45, 0.36, 0.27, 1)", [(-17.2, 0.0, 26.6), (-18.6, 0.0, 31.4), (-21.8, 0.0, 31.6), (-17.0, 0.0, 30.0)]),
]
# Sons posés sur les objets : nom, son, position, volume, portée.
SOUNDS = [
    ("WheelSound", "41_stream", (-36.5, 0.5, -14.0), -2.0, 26.0, 0.75),
    ("WindmillWind", "61_wind", (30.0, 12.0, -30.0), -9.0, 36.0, 1.0),
    ("BreachWind", "62_ruin_wind", (33.0, 3.0, -6.0), -12.0, 26.0, 1.0),
    ("GateWind", "62_ruin_wind", (0.0, 6.0, 42.0), -13.0, 24.0, 0.9),
    ("OvenCrackle", "42_crackle", (11.2, 1.2, 28.7), -15.0, 10.0, 1.1),
    ("ForgeCrackle", "42_crackle", (12.3, 1.3, 18.6), -15.0, 10.0, 0.9),
]
# Lanternes allumées : (x, hauteur, z).
LANTERNS = [(-2.4, 3.0, 30.0), (2.4, 3.0, -14.0), (0.0, 2.6, -18.9)]

# Intérieur de la mairie (repère du nœud Interior), comme dans tools/build_village.py.
OFFICE = 4.5
# Dalles : nom, x min, x max, y min, y max, z min, z max, matériau. La trémie de l'escalier reste ouverte.
SLABS = [
    ("GroundFloor", -8.3, 8.3, -0.3, 0.0, -6.3, 6.3, "wood_dark"),
    ("OfficeFloorWest", -8.3, 4.5, 4.0, OFFICE, -6.3, 6.3, "wood"),
    ("OfficeFloorNorth", 4.5, 8.3, 4.0, OFFICE, -6.3, -4.2, "wood"),
    ("OfficeFloorSouth", 4.5, 8.3, 4.0, OFFICE, 2.0, 6.3, "wood"),
    ("OfficeCeiling", -8.3, 8.3, 8.0, 8.3, -6.3, 6.3, "plaster"),
    ("SecretFloor", -16.3, -8.0, 4.0, OFFICE, -4.3, 4.3, "stone"),
    ("SecretCeiling", -16.3, -8.0, 8.0, 8.3, -4.3, 4.3, "plaster"),
]
# Fragments : numéro, position, caché dans un meuble.
FRAGMENT_SPOTS = [
    # Chacun repose à la hauteur exacte du dessus de son meuble, mesurée sur le modèle, sans rien traverser.
    # Deux par langage : HTML 0 et 1, CSS 2 et 3, Python 4 et 5, PHP 6 et 7, TypeScript 8 et 9.
    (0, (-2.4, 1.075, -0.4), False),
    (2, (-4.3, 1.0, 3.1), False),
    (3, (0.4, 1.0, -0.8), True),
    (4, (-6.4, 0.03, -1.0), True),
    (7, (1.6, 1.0, -5.4), False),
    (8, (-4.6, 1.075, -3.0), True),
    (5, (-0.5, OFFICE + 1.075, -0.4), False),
    (1, (1.4, OFFICE + 1.0, -0.8), True),
    (9, (-6.4, OFFICE + 0.03, -4.2), True),
    (6, (1.6, OFFICE + 0.03, 4.45), True),
]
# Meubles qui s'ouvrent : nom, position de l'invite (devant la face qui s'ouvre, hors de la collision du meuble),
# nom du meuble, fragment caché.
STORAGES = [
    ("ReceptionDrawer", (0.4, 0.7, -0.15), "le tiroir de l'accueil", 3),
    ("ArchiveCabinet", (-6.72, 1.3, -1.0), "l'armoire des archives", 4),
    ("ArchiveCabinetNorth", (-6.72, 1.3, -3.5), "l'armoire aux registres", None),
    ("ArchiveCabinetSouth", (-6.72, 1.3, 1.5), "l'armoire aux actes", None),
    ("ArchivistDesk", (-3.8, 1.12, -4.35), "le tiroir de l'archiviste", 8),
    ("Dresser", (3.5, 0.4, -4.35), "le coffre de l'accueil", None),
    ("MayorDrawer", (1.4, OFFICE + 0.7, -1.42), "le tiroir du bureau", 1),
    ("MayorCabinet", (1.6, OFFICE + 1.3, 4.75), "l'armoire du maire", 6),
    ("OfficeDresser", (-5.43, OFFICE + 0.4, -5.1), "le coffre du bureau", 9),
]
INSCRIPTION = ("Cinq langages, cinq épreuves, un seul savoir. Comprends les instructions des anciens bâtisseurs "
               "et le dernier secret du village te sera révélé.")
# Pupitre de pierre de la salle secrète (posé par tools/build_village.py) : le livre repose sur son plateau incliné.
LECTERN = (-12.6, 0.0)
LECTERN_TILT = -15.0
# Panneaux de lore : nom, position, orientation (la face regarde +Z tournée de ces degrés), titre, texte, et le
# panneau qui le porte.
LORE = [
    ("Notice", (-4.6, 0.0, 13.0), 90.0, "L'avis du maire",
     "Proclamation du maire de Codia : la mairie reste ouverte tant que le village tient debout. Les registres et "
     "les savoirs des anciens bâtisseurs sont à l'abri dans le bureau du maire, à l'étage. Seul celui qui comprendra "
     "leurs cinq langages pourra en percer le dernier secret.",
     dict(text="Avis du maire\nà la population de Codia", style=2, mount=0, roof=True, board_size=(1.3, 0.85),
          board_height=1.45, line_height=0.13, double_sided=True)),
    ("Order", (-4.2, 0.0, 35.2), 90.0, "L'ordre du capitaine",
     "Ordre du capitaine de la garde, an 5812 : tenez la porte tant que les habitants ne sont pas à l'abri. Les "
     "catapultes de Vibelandia ont ouvert une brèche dans le rempart de l'est. Quand le cor sonnera trois fois, "
     "abandonnez la barricade et rejoignez le bunker du roi, près du château.",
     dict(text="Ordre du capitaine\nde la garde", style=2, mount=0, board_size=(1.0, 0.7), board_height=1.35,
          line_height=0.12, double_sided=True)),
    ("Slate", (4.9, 0.0, 28.6), -90.0, "L'ardoise de la boulangère",
     "Pain de seigle : deux sous. Pain blanc : trois sous. Plus de farine depuis que le meunier a fui. La dernière "
     "fournée est pour les gardes du rempart : qu'ils tiennent jusqu'au soir.",
     dict(text="Pain de seigle : 2 sous\nPain blanc : 3 sous", style=3, mount=0, board_size=(0.85, 0.62),
          board_height=1.2, line_height=0.1, serif=False, double_sided=True)),
]
MEMORIAL = ((12.0, 0.0, 37.5), -90.0, "Le mémorial des gardes",
            "Ici, les gardes de Codia ont tenu la porte trois jours et trois nuits face aux guerriers de Vibelandia. "
            "Quand elle a cédé, ils ont couvert la fuite des habitants jusqu'au bunker du roi. Leurs noms restent "
            "gravés dans la mémoire du village.")
LANGUAGES = ["HTML", "CSS", "Python", "PHP", "JS / TS"]
# Escalier le long du mur est : quinze marches pleines de z = 5 au sol jusqu'à z = -4 à l'étage.
STEPS = 15
STEP_RUN = 9.0 / STEPS
STEP_RISE = OFFICE / STEPS
# Rambarde autour de la trémie : centre (x, z), longueur, le long de z ou non.
RAILS = [((4.5, -1.1), 6.2, True), ((6.15, 2.0), 3.3, False)]
## Longueur de la pente de l'escalier, et hauteur de la ligne des nez de marches en z (0,3 m au nez de la première).
STAIR_LENGTH = math.hypot(9.0, OFFICE)


def nose_height(z):
    return STEP_RISE + (5.0 - z) * OFFICE / 9.0
SHELF_SCALE = 3.8
# Ailes du moulin à vent (modèle windmill à l'échelle 3, axe x du rotor) : chaque aile occupe de 40 à 80 degrés autour
# de son axe dans le plan (y, z) du rotor, de 1,8 à 4,7 m du moyeu. Une boîte par aile, enfant du rotor : elle tourne
# avec lui. Sans elles, on traversait les ailes en sautant au pied de la tour.
SAIL_ANGLES = (57.0, 147.0, 237.0, 327.0)
SAIL_RADIUS = 3.2
SAIL_SIZE = (0.6, 2.9, 2.0)


def ext(identifier):
    return f'ExtResource("{identifier}")'


def value(item):
    if isinstance(item, bool):
        return "true" if item else "false"
    if isinstance(item, str):
        return '"' + item.replace('"', '\\"') + '"'
    if isinstance(item, tuple):
        return "Vector2(%s)" % ", ".join(f"{v:g}" for v in item)
    return f"{item:g}"


def sign_props(props):
    return ['script = ExtResource("15_sign")'] + [f"{key} = {value(item)}" for key, item in props.items()]


def at(x, y, z, scale=1.0, yaw=0.0):
    c = math.cos(math.radians(yaw)) * scale
    s = math.sin(math.radians(yaw)) * scale
    return f"transform = Transform3D({c:.6g}, 0, {s:.6g}, 0, {scale:g}, 0, {-s:.6g}, 0, {c:.6g}, {x:g}, {y:g}, {z:g})"


def quote(text):
    return '"' + text.replace('"', '\\"') + '"'


def node(lines, name, kind=None, parent=".", instance=None, props=()):
    head = f'[node name="{name}"'
    if kind:
        head += f' type="{kind}"'
    if parent is not None:
        head += f' parent="{parent}"'
    if instance:
        head += f" instance={ext(instance)}"
    lines += [head + "]", *props, ""]


def main():
    lines = ["[gd_scene format=3]", ""]
    lines += [f'[ext_resource type="{kind}" path="{path}" id="{identifier}"]' for kind, path, identifier in EXT]
    lines += [SUBRESOURCES]
    for name, x0, x1, y0, y1, z0, z1, material in SLABS:
        lines += [f'[sub_resource type="BoxMesh" id="BoxMesh_{name}"]', f'material = SubResource("Material_{material}")',
                  f"size = Vector3({x1 - x0:g}, {y1 - y0:g}, {z1 - z0:g})", "",
                  f'[sub_resource type="BoxShape3D" id="BoxShape3D_{name}"]', f"size = Vector3({x1 - x0:g}, {y1 - y0:g}, {z1 - z0:g})", ""]
    for step in range(STEPS):
        lines += [f'[sub_resource type="BoxMesh" id="BoxMesh_step{step}"]', 'material = SubResource("Material_wood_dark")',
                  f"size = Vector3(3, {STEP_RISE * (step + 1):g}, {STEP_RUN:g})", ""]
    for name, size, material in (("tread", (3.04, 0.06, STEP_RUN + 0.05), "wood"), ("stringer", (0.1, 0.42, 7.5 / math.cos(math.atan2(OFFICE, 9.0))), "wood"),
                                 ("handrail", (0.09, 0.09, 8.1 / math.cos(math.atan2(OFFICE, 9.0))), "wood"), ("baluster", (0.05, 0.9, 0.05), "wood_dark")):
        lines += [f'[sub_resource type="BoxMesh" id="BoxMesh_{name}"]', f'material = SubResource("Material_{material}")',
                  "size = Vector3(%s)" % ", ".join(f"{v:g}" for v in size), ""]
    for step in range(0, STEPS, 3):
        lines += [f'[sub_resource type="BoxMesh" id="BoxMesh_batten{step}"]', 'material = SubResource("Material_wood")',
                  f"size = Vector3(0.03, {STEP_RISE * (step + 1) - 0.1:g}, 0.12)", ""]
    lines += ['[sub_resource type="BoxShape3D" id="BoxShape3D_handrail"]', f"size = Vector3(0.14, 1.1, {STAIR_LENGTH - 0.9:g})", ""]
    lines += ['[sub_resource type="BoxShape3D" id="BoxShape3D_sail"]', "size = Vector3(%g, %g, %g)" % SAIL_SIZE, ""]
    # Le volume plein de l'escalier, sous sa rampe : ses marches sont des blocs pleins depuis le sol, et sous la rampe
    # seule on entrait dans l'escalier par son flanc. Le coin a pour dessus la rampe elle-même.
    x0, x1 = 6.05 - 1.5, 6.05 + 1.5
    wedge = [(x, y, z) for x in (x0, x1) for y, z in ((0.0, 5.0), (0.0, 5.0 - 9.0), (OFFICE, 5.0 - 9.0))]
    lines += ['[sub_resource type="ConvexPolygonShape3D" id="ConvexPolygonShape3D_stairs"]',
              "points = PackedVector3Array(" + ", ".join(f"{x:g}, {y:g}, {z:g}" for x, y, z in wedge) + ")", ""]
    for index, (_, length, along_z) in enumerate(RAILS):
        size = f"0.12, 0.12, {length:g}" if along_z else f"{length:g}, 0.12, 0.12"
        lines += [f'[sub_resource type="BoxMesh" id="BoxMesh_rail{index}"]', 'material = SubResource("Material_wood_dark")',
                  f"size = Vector3({size})", ""]
    for index in range(5):
        lines += [f'[sub_resource type="StandardMaterial3D" id="Material_section{index}"]', "resource_local_to_scene = true",
                  "albedo_color = Color(0.2, 0.22, 0.3, 1)", "emission_enabled = true", "emission = Color(0.4, 0.45, 0.7, 1)",
                  "emission_energy_multiplier = 0.6", "",
                  f'[sub_resource type="BoxMesh" id="BoxMesh_section{index}"]', f'material = SubResource("Material_section{index}")',
                  "size = Vector3(0.8, 0.8, 0.06)", ""]
    lines += ['[node name="Village" type="Node3D"]', 'script = ExtResource("1_village")', ""]
    node(lines, "WorldEnvironment", "WorldEnvironment", props=['environment = SubResource("Environment_village")'])
    # Soleil couchant, bas sur l'horizon à l'ouest.
    node(lines, "Sun", "DirectionalLight3D", props=[
        "transform = Transform3D(0.5, 0.19, -0.845, 0, 0.976, 0.218, 0.866, -0.109, 0.488, 0, 40, 0)",
        "light_color = Color(1, 0.72, 0.48, 1)", "light_energy = 1.1", "shadow_enabled = true",
        "directional_shadow_mode = 1", "directional_shadow_max_distance = 50.0"])
    # Lumière d'appoint du ciel, froide et sans ombre, venue de l'est : le côté des murs à l'ombre du soleil
    # couchant n'est plus noir.
    node(lines, "SkyFill", "DirectionalLight3D", props=[
        "transform = Transform3D(-0.7071, -0.3590, 0.6092, 0.0000, 0.8615, 0.5077, -0.7071, 0.3590, -0.6092, 0, 30, 0)",
        "light_color = Color(0.58, 0.64, 0.92, 1)", "light_energy = 0.24", "light_specular = 0.0"])
    # Lumière renvoyée par le sol, chaude, sans ombre, montant droit vers le ciel : le dessous des planchers qui
    # pendent, des toits effondrés et des auvents reste du bois sombre au lieu d'un trou noir.
    node(lines, "GroundBounce", "DirectionalLight3D", props=[
        "transform = Transform3D(1, 0, 0, 0, 0, -1, 0, 1, 0, 0, 20, 0)",
        "light_color = Color(0.86, 0.62, 0.44, 1)", "light_energy = 0.6", "light_specular = 0.0"])
    node(lines, "Terrain", "StaticBody3D", props=['script = ExtResource("2_terrain")', 'ground_material = SubResource("ShaderMaterial_ground")'])
    node(lines, "Stream", "MeshInstance3D", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -38, -0.45, 0)", 'mesh = SubResource("PlaneMesh_stream")',
        "cast_shadow = 0"])
    lines += [
        '[node name="Scatter" type="Node3D" parent="." node_paths=PackedStringArray("terrain")]',
        'script = ExtResource("3_scatter")',
        'terrain = NodePath("../Terrain")',
        'grass_models = Array[PackedScene]([ExtResource("20_grass"), ExtResource("21_grass_leafs"), ExtResource("22_bush")])',
        'rubble_models = Array[PackedScene]([ExtResource("23_bricks"), ExtResource("24_rocks_small"), ExtResource("25_debris_wood")])',
        'tree_models = Array[PackedScene]([ExtResource("26_tree_default"), ExtResource("27_tree_oak"), ExtResource("28_tree_thin"), ExtResource("29_pine")])',
        'rock_models = Array[PackedScene]([ExtResource("30_rock"), ExtResource("31_rocks_large")])',
        "",
    ]
    node(lines, "Props", instance="6_props")
    node(lines, "WindmillRotor", "Node3D", props=[at(30, 11, -28.3, 1.0, 90)])
    node(lines, "Model", parent="WindmillRotor", instance="13_windmill", props=["transform = Transform3D(3, 0, 0, 0, 3, 0, 0, 0, 3, 0, 0, 0)"])
    node(lines, "Sails", "StaticBody3D", "WindmillRotor")
    for index, degrees in enumerate(SAIL_ANGLES):
        c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
        node(lines, f"Sail{index}", "CollisionShape3D", "WindmillRotor/Sails", props=[
            f"transform = Transform3D(1, 0, 0, 0, {c:.6f}, {-s:.6f}, 0, {s:.6f}, {c:.6f}, 0, {SAIL_RADIUS * c:.4f}, {SAIL_RADIUS * s:.4f})",
            'shape = SubResource("BoxShape3D_sail")'])
    node(lines, "WaterWheel", "Node3D", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -36.5, 1.0, -14)"])
    node(lines, "Model", parent="WaterWheel", instance="14_watermill", props=["transform = Transform3D(3, 0, 0, 0, 3, 0, 0, 0, 3, 0, 0, 0)"])
    for index, (x, z) in enumerate(((-38.0, 6.0), (-38.0, -22.0))):
        node(lines, f"StreamSound{index}", "AudioStreamPlayer3D", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, 0, {z:g})", 'stream = ExtResource("41_stream")',
            "volume_db = -4.0", "unit_size = 6.0", "max_distance = 35.0", "autoplay = true"])
    node(lines, "Fires", "Node3D")
    for index, (x, z, size) in enumerate(FIRES):
        node(lines, f"Fire{index}", "Node3D", "Fires", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, 0.25, {z:g})", 'script = ExtResource("10_fire")',
            f"size = {size:g}", "light_energy = 2.4", "light_range = 8.0", 'crackle_sound = ExtResource("42_crackle")',
            "crackle_volume_db = -10.0"])
    node(lines, "Smokes", "Node3D")
    for index, (x, z, radius) in enumerate(SMOKES):
        # Les colonnes montent des ruines où l'on marche (maison brûlée, auberge, cratères, écuries) : leurs volutes
        # partent au-dessus de la tête, sinon le joueur qui y entre ne voit plus qu'une boule noire.
        node(lines, f"Smoke{index}", "CPUParticles3D", "Smokes", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, 5, {z:g})", 'script = ExtResource("11_smoke")',
            f"radius = {radius:g}", "puff_size = 2.6"])
    for index, (x, y, z) in enumerate(CHIMNEYS):
        node(lines, f"Chimney{index}", "CPUParticles3D", "Smokes", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, {z:g})", 'script = ExtResource("11_smoke")',
            "radius = 0.15", "puff_size = 1.4", "rise_speed = 0.9", "smoke_color = Color(0.5, 0.47, 0.45, 1)"])
    node(lines, "Embers", "Node3D")
    for index, (x, y, z, half) in enumerate(EMBERS):
        node(lines, f"Embers{index}", "CPUParticles3D", "Embers", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, {z:g})", 'script = ExtResource("60_particles")',
            f"extents = Vector3({half:g}, 0.15, {half:g})"])
    node(lines, "Crows", "Node3D")
    for index, ((x, y, z), degrees, pecking) in enumerate(CROWS):
        node(lines, f"Crow{index}", "Node3D", "Crows", props=[at(x, y, z, 1.0, degrees), 'script = ExtResource("64_crow")']
             + (["pecking = true"] if pecking else []))
    node(lines, "Cats", "Node3D")
    for index, (coat, points) in enumerate(CATS):
        array = ", ".join(f"{x:g}, {y:g}, {z:g}" for x, y, z in points)
        node(lines, f"Cat{index}", "Node3D", "Cats", props=[at(*points[0]), 'script = ExtResource("65_cat")',
                                                          f"coat = {coat}", f"waypoints = PackedVector3Array({array})"])
    # Le linge et les bannières ondulent au vent (village_life.gd).
    node(lines, "Life", "Node", props=['script = ExtResource("66_life")',
                                       'roots = Array[NodePath]([NodePath("../Props"), NodePath("../Interior/Hall")])'])
    node(lines, "WheelSplash", "CPUParticles3D", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -36.5, -0.35, -14)", 'script = ExtResource("60_particles")',
        "kind = 2", "extents = Vector3(0.35, 0.05, 1.5)", "tint = Color(0.75, 0.86, 0.95, 1)"])
    node(lines, "Sounds", "Node3D")
    for name, stream, (x, y, z), volume, reach, pitch in SOUNDS:
        node(lines, name, "AudioStreamPlayer3D", "Sounds", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, {z:g})", f'stream = ExtResource("{stream}")',
            f"volume_db = {volume:g}", "unit_size = 5.0", f"max_distance = {reach:g}", f"pitch_scale = {pitch:g}",
            "autoplay = true"])
    for index, (x, y, z) in enumerate(LANTERNS):
        node(lines, f"LanternLight{index}", "OmniLight3D", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, {z:g})", 'script = ExtResource("12_flicker")',
            "light_color = Color(1, 0.7, 0.35, 1)", "light_energy = 1.4", "omni_range = 7.0", "flicker = 0.2"])
    node(lines, "Portal", instance="7_portal", props=[
        at(0, 0, 63), 'closed_prompt = "Portail éteint"', 'open_prompt = "Retourner au hub"',
        "inner_color = Color(0.85, 0.7, 1, 1)", "outer_color = Color(0.45, 0.2, 0.8, 1)"])
    # Panneau d'entrée, sur ses poteaux au bord de la route, tourné vers le portail.
    node(lines, "EntranceSign", "Node3D", props=[at(-4.5, 0, 55, 1.0, 30)] + sign_props(dict(
        text="Codia\nLe village détruit", board_size=(1.9, 0.95), board_height=1.55, line_height=0.26)))
    # Textes à lire avec E : le panneau ne porte qu'un titre, le Readable donne le texte entier.
    node(lines, "Lore", "Node3D")
    for name, (x, y, z), degrees, title, body, board in LORE:
        node(lines, name, "Node3D", "Lore", props=[at(x, y, z, 1.0, degrees), 'script = ExtResource("57_readable")',
                                                   f"title = {quote(title)}", f"body = {quote(body)}",
                                                   f"prompt = {quote('Lire : ' + title)}", "radius = 2.6"])
        node(lines, "Board", "Node3D", f"Lore/{name}", props=sign_props(board))
    # Mémorial des gardes : une stèle de pierre sur son socle, la plaque gravée sur sa face.
    (x, y, z), degrees, title, body = MEMORIAL
    node(lines, "Memorial", "Node3D", "Lore", props=[at(x, y, z, 1.0, degrees), 'script = ExtResource("57_readable")',
                                                     f"title = {quote(title)}", f"body = {quote(body)}",
                                                     f"prompt = {quote('Lire : ' + title)}", "radius = 2.6"])
    node(lines, "Plinth", "MeshInstance3D", "Lore/Memorial", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.2, -0.3)", 'mesh = SubResource("BoxMesh_plinth")'])
    node(lines, "Stele", "MeshInstance3D", "Lore/Memorial", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.15, -0.3)", 'mesh = SubResource("BoxMesh_stele")'])
    node(lines, "Body", "StaticBody3D", "Lore/Memorial")
    node(lines, "Shape", "CollisionShape3D", "Lore/Memorial/Body", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.95, -0.3)", 'shape = SubResource("BoxShape3D_memorial")'])
    node(lines, "Board", "Node3D", "Lore/Memorial", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, -0.15)"]
         + sign_props(dict(text="Aux gardes de Codia\nqui ont tenu la porte", style=1, mount=1, board_size=(1.45, 0.8),
                           board_height=1.2, line_height=0.13, collision=False)))
    # Porte de la mairie : elle mène à son intérieur, sous la carte. Le point est devant le mur, pas dedans.
    node(lines, "HallDoor", "Node3D", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.4, -19.45)", 'script = ExtResource("53_interactable")',
        'prompt = "Entrer dans la mairie"', "radius = 3.2"])
    node(lines, "OutsideSpawn", "Marker3D", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.3, -17.4)"])
    node(lines, "Interior", "Node3D", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -40, 0)"])
    node(lines, "Hall", parent="Interior", instance="50_hall")
    node(lines, "Slabs", "StaticBody3D", "Interior")
    for name, x0, x1, y0, y1, z0, z1, _ in SLABS:
        center = f"{(x0 + x1) / 2:g}, {(y0 + y1) / 2:g}, {(z0 + z1) / 2:g}"
        node(lines, name, "MeshInstance3D", "Interior/Slabs", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {center})", f'mesh = SubResource("BoxMesh_{name}")'])
        node(lines, name + "Shape", "CollisionShape3D", "Interior/Slabs", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {center})", f'shape = SubResource("BoxShape3D_{name}")'])
    # Rampe sous les marches de l'escalier : de z = 5 au sol jusqu'à z = -4 à l'étage.
    angle = math.atan2(OFFICE, 9.0)
    c, s_ = math.cos(angle), math.sin(angle)
    node(lines, "RampShape", "CollisionShape3D", "Interior/Slabs", props=[
        f"transform = Transform3D(1, 0, 0, 0, {c:.6f}, {-s_:.6f}, 0, {s_:.6f}, {c:.6f}, 6.05, {OFFICE / 2 - 0.15 * c:.4f}, {0.5 - 0.15 * s_:.4f})",
        'shape = SubResource("BoxShape3D_ramp")'])
    node(lines, "StairsShape", "CollisionShape3D", "Interior/Slabs", props=['shape = SubResource("ConvexPolygonShape3D_stairs")'])
    # La main courante a sa collision, au-dessus des marches, le long du flanc ouvert.
    node(lines, "HandrailShape", "CollisionShape3D", "Interior/Slabs", props=[
        f"transform = Transform3D(1, 0, 0, 0, {c:.6f}, {-s_:.6f}, 0, {s_:.6f}, {c:.6f}, 4.68, {nose_height(0.0) + 0.45:.4f}, 0)",
        'shape = SubResource("BoxShape3D_handrail")'])
    node(lines, "Stairs", "Node3D", "Interior")
    for step in range(STEPS):
        height = STEP_RISE * (step + 1)
        z = 5.0 - STEP_RUN * (step + 0.5)
        node(lines, f"Step{step}", "MeshInstance3D", "Interior/Stairs", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 6.05, {height / 2:g}, {z:g})", f'mesh = SubResource("BoxMesh_step{step}")'])
        node(lines, f"Tread{step}", "MeshInstance3D", "Interior/Stairs", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 6.05, {height - 0.03 + 0.004:g}, {z + 0.025:g})", 'mesh = SubResource("BoxMesh_tread")'])
        if step % 3 == 0:
            node(lines, f"Batten{step}", "MeshInstance3D", "Interior/Stairs", props=[
                f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 4.535, {(height - 0.1) / 2:g}, {z:g})", f'mesh = SubResource("BoxMesh_batten{step}")'])
        if step % 2 == 1 and step < STEPS - 1:
            node(lines, f"Baluster{step}", "MeshInstance3D", "Interior/Stairs", props=[
                f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 4.68, {height + 0.45:g}, {z:g})", 'mesh = SubResource("BoxMesh_baluster")'])
    # Le limon et la main courante suivent la pente des nez de marches (le même angle que la rampe).
    for name, mesh, x, lift in (("Stringer", "stringer", 4.56, -0.18), ("Handrail", "handrail", 4.68, 0.92)):
        # Le limon et la main courante partent de la deuxième marche (z = 4,1), où commence la collision de la main
        # courante : on ne s'y frotte pas en entrant dans l'escalier. Le limon s'arrête au nez de la dernière marche
        # (z = -3,4), sous le niveau du bureau ; la main courante rejoint la rambarde de la trémie (z = -4).
        mid = 0.35 if name == "Stringer" else 0.05
        node(lines, name, "MeshInstance3D", "Interior/Stairs", props=[
            f"transform = Transform3D(1, 0, 0, 0, {c:.6f}, {-s_:.6f}, 0, {s_:.6f}, {c:.6f}, {x:g}, {nose_height(mid) + lift:.4f}, {mid:g})",
            f'mesh = SubResource("BoxMesh_{mesh}")'])
    node(lines, "Railing", "Node3D", "Interior", props=[f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {OFFICE:g}, 0)"])
    for index, ((x, z), length, along_z) in enumerate(RAILS):
        for height in (0.5, 1.05):
            node(lines, f"Rail{index}_{int(height * 100)}", "MeshInstance3D", "Interior/Railing", props=[
                f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {height:g}, {z:g})", f'mesh = SubResource("BoxMesh_rail{index}")'])
        posts = int(length / 1.0) + 1
        for post in range(posts):
            offset = -length / 2 + post * length / (posts - 1)
            px, pz = (x, z + offset) if along_z else (x + offset, z)
            node(lines, f"Post{index}_{post}", "MeshInstance3D", "Interior/Railing", props=[
                f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {px:g}, 0.55, {pz:g})", 'mesh = SubResource("BoxMesh_post")'])
    node(lines, "InsideSpawn", "Marker3D", "Interior", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -2, 0.3, 4.3)"])
    node(lines, "Exit", "Node3D", "Interior", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -2, 1.2, 5.55)", 'script = ExtResource("53_interactable")',
        'prompt = "Sortir de la mairie"', "radius = 2.0"])
    for name, x, y, z, energy in (("LightHall", -3.0, 3.4, 0.0, 2.2), ("LightStairs", 4.0, 3.4, 3.0, 1.4),
                                  ("LightOffice", -2.0, 7.6, -1.0, 2.2), ("LightOfficeEast", 4.5, 7.6, 4.0, 1.2)):
        node(lines, name, "OmniLight3D", "Interior", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, {z:g})", 'script = ExtResource("12_flicker")',
            "light_color = Color(1, 0.75, 0.48, 1)", f"light_energy = {energy:g}", "omni_range = 11.0", "flicker = 0.1"])
    # Poussière qui flotte dans la lumière de la mairie, et le souffle feutré des pièces fermées.
    for name, (x, y, z), half, tint in (("DustHall", (0.0, 2.0, 0.0), (7.0, 1.6, 5.2), "Color(1, 0.86, 0.62, 1)"),
                                        ("DustOffice", (0.0, OFFICE + 1.7, 0.0), (7.0, 1.5, 5.2), "Color(1, 0.86, 0.62, 1)"),
                                        ("DustSecret", (-12.0, OFFICE + 1.7, 0.0), (3.4, 1.4, 3.4), "Color(0.82, 0.72, 1, 1)")):
        node(lines, name, "CPUParticles3D", "Interior", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, {z:g})", 'script = ExtResource("60_particles")',
            "kind = 1", f"extents = Vector3({half[0]:g}, {half[1]:g}, {half[2]:g})", f"tint = {tint}"])
    node(lines, "HallHum", "AudioStreamPlayer3D", "Interior", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 3, 0)", 'stream = ExtResource("63_hall")',
        "volume_db = -16.0", "unit_size = 8.0", "max_distance = 30.0", "autoplay = true"])
    node(lines, "Fragments", "Node3D", "Interior")
    for number, (x, y, z), hidden in FRAGMENT_SPOTS:
        props = [f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, {z:g})", 'script = ExtResource("51_fragment")',
                 "radius = 2.2", f"fragment = {number}"]
        if hidden:
            props.append("hidden_at_start = true")
        node(lines, f"Fragment{number}", "Node3D", "Interior/Fragments", props=props)
    node(lines, "Storages", "Node3D", "Interior")
    for name, (x, y, z), label, number in STORAGES:
        props = [f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, {z:g})", 'script = ExtResource("52_storage")',
                 "radius = 2.2", f"furniture_name = {quote(label)}"]
        if number is not None:
            props.append(f'fragment = NodePath("../../Fragments/Fragment{number}")')
        node(lines, name, "Node3D", "Interior/Storages", props=props)
    # Dispositif des cinq codes, contre le mur nord du bureau.
    node(lines, "Device", "Node3D", "Interior", props=[f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -1, {OFFICE:g}, -5.4)"])
    node(lines, "Console", "MeshInstance3D", "Interior/Device", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 0.1)", 'mesh = SubResource("BoxMesh_console")'])
    node(lines, "Backboard", "MeshInstance3D", "Interior/Device", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.7, -0.25)", 'mesh = SubResource("BoxMesh_backboard")'])
    node(lines, "Body", "StaticBody3D", "Interior/Device")
    node(lines, "Shape", "CollisionShape3D", "Interior/Device/Body", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.25, 0)", 'shape = SubResource("BoxShape3D_console")'])
    node(lines, "Sections", "Node3D", "Interior/Device")
    for index in range(5):
        x = -2.2 + index * 1.1
        node(lines, f"Section{index}", "MeshInstance3D", "Interior/Device/Sections", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, 1.87, -0.12)", f'mesh = SubResource("BoxMesh_section{index}")'])
        # Nom du langage gravé et doré dans la pierre du panneau, à 2 cm de sa face.
        node(lines, f"Language{index}", "Label3D", "Interior/Device", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, 1.24, -0.13)", "pixel_size = 0.0026",
            "shaded = true", "alpha_cut = 1", "modulate = Color(0.86, 0.7, 0.4, 1)", f"text = {quote(LANGUAGES[index])}",
            "font_size = 64", "outline_size = 0"])
    # L'inscription des anciens bâtisseurs, sur une plaque de pierre scellée au mur, au-dessus du dispositif.
    node(lines, "Inscription", "Node3D", "Interior/Device", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.93, -0.35)"] + sign_props(dict(
            text=INSCRIPTION, style=1, mount=1, board_size=(5.6, 0.9), board_height=0.0, line_height=0.15,
            collision=False)))
    node(lines, "DeviceLight", "OmniLight3D", "Interior/Device", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.0, 1.0)", "light_color = Color(0.45, 0.65, 1, 1)",
        "light_energy = 0.0", "omni_range = 9.0"])
    node(lines, "Interactable", "Node3D", "Interior/Device", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.2, 0.6)", 'script = ExtResource("53_interactable")',
        'prompt = "Examiner le dispositif des cinq codes"', "radius = 3.0"])
    # Bibliothèque devant le passage de la salle secrète : elle glisse vers le sud une fois les codes résolus.
    node(lines, "SecretShelf", "Node3D", "Interior", props=[f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -7.25, {OFFICE:g}, 0)"])
    # Le modèle a son origine dans un coin : décalé pour que la bibliothèque soit centrée sur le passage.
    node(lines, "Model", parent="Interior/SecretShelf", instance="56_shelf", props=[
        at(0.125 * SHELF_SCALE, 0, 0.4 * SHELF_SCALE, SHELF_SCALE, 90)])
    for row, y in enumerate((0.13, 1.07, 1.98)):
        for k in range(6):
            if (row * 7 + k * 3) % 5 == 0:
                continue
            z = -1.15 + k * 0.46
            node(lines, f"Books{row}_{k}", parent="Interior/SecretShelf", instance="58_books", props=[
                at(0.05, y, z + 0.15, 3.2 + (k % 3) * 0.25, -90 if (row + k) % 2 else 90)])
    node(lines, "Body", "StaticBody3D", "Interior/SecretShelf")
    node(lines, "Shape", "CollisionShape3D", "Interior/SecretShelf/Body", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.5, 0)", 'shape = SubResource("BoxShape3D_shelf")'])
    node(lines, "SecretLight", "OmniLight3D", "Interior", props=[
        f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -12, {OFFICE + 3:g}, 0)", "light_color = Color(0.75, 0.6, 1, 1)",
        "light_energy = 2.4", "omni_range = 9.0"])
    c, s_ = math.cos(math.radians(LECTERN_TILT)), math.sin(math.radians(LECTERN_TILT))
    node(lines, "Book", "Node3D", "Interior", props=[
        f"transform = Transform3D({c:.5f}, {-s_:.5f}, 0, {s_:.5f}, {c:.5f}, 0, 0, 0, 1, {LECTERN[0]:g}, {OFFICE + 1.2:g}, {LECTERN[1]:g})"])
    node(lines, "Mesh", "MeshInstance3D", "Interior/Book", props=['mesh = SubResource("BoxMesh_codonomicon")'])
    node(lines, "Glow", "OmniLight3D", "Interior/Book", props=["light_color = Color(0.7, 0.45, 1, 1)", "light_energy = 1.2", "omni_range = 3.0"])
    node(lines, "Interactable", "Node3D", "Interior/Book", props=[
        'script = ExtResource("53_interactable")', 'prompt = "Prendre le Codonomicon"', "radius = 2.6"])
    # Volcan en éveil au nord, au-delà des reliefs : il domine la zone comme le hub, vu de loin (fumée et lueur,
    # sans lumière dynamique ni éruption).
    node(lines, "Volcano", "Node3D", ".", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 25, -6, -215)", 'script = ExtResource("90_volcano")',
        "distant = true"])
    node(lines, "Player", instance="8_player", props=[
        at(0, 0.3, 57), "respawn_height = -80.0", "first_person = true",
        'footstep_sounds = Array[AudioStream]([ExtResource("43_step1"), ExtResource("44_step2"), ExtResource("45_step3")])'])
    node(lines, "Ambience", "AudioStreamPlayer", props=['stream = ExtResource("40_ambience")', "volume_db = -6.0", "autoplay = true"])
    node(lines, "ChimeSound", "AudioStreamPlayer", props=['stream = ExtResource("46_chime")', "volume_db = -4.0"])
    node(lines, "RejectSound", "AudioStreamPlayer", props=['stream = ExtResource("47_reject")', "volume_db = -2.0"])
    node(lines, "RumbleSound", "AudioStreamPlayer", props=['stream = ExtResource("48_rumble")', "volume_db = -2.0"])
    node(lines, "CodePuzzle", instance="54_code_puzzle")
    node(lines, "PaperNotebook", instance="55_notebook")
    node(lines, "Hud", instance="9_hud")
    out = FRONTEND / "scenes" / "levels" / "village" / "village.tscn"
    out.write_text("\n".join(lines).rstrip("\n") + "\n", encoding="utf-8", newline="\n")
    print(out.name, len(lines), "lignes")


if __name__ == "__main__":
    main()
