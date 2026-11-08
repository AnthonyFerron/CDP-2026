"""Écrit frontend/scenes/levels/desert/desert.tscn, le désert de Pythania (argument : le dossier frontend)."""
import math
import sys
from pathlib import Path

FRONTEND = Path(sys.argv[1])
K = "res://assets/models/kenney/"
A = "res://assets/audio/"
EXT = [
    ("Script", "res://scenes/levels/desert/desert.gd", "1_desert"),
    ("Script", "res://scenes/levels/desert/desert_terrain.gd", "2_terrain"),
    ("Script", "res://scenes/levels/desert/desert_scatter.gd", "3_scatter"),
    ("Shader", "res://scenes/levels/desert/desert_sand.gdshader", "4_sand"),
    ("Shader", "res://scenes/levels/desert/quicksand.gdshader", "5_quicksand"),
    ("PackedScene", "res://scenes/levels/desert/desert_ruins.tscn", "6_ruins"),
    ("PackedScene", "res://scenes/levels/desert/desert_cellar.tscn", "7_cellar"),
    ("PackedScene", "res://scenes/props/portal/portal.tscn", "8_portal"),
    ("PackedScene", "res://scenes/player/player.tscn", "9_player"),
    ("PackedScene", "res://scenes/ui/hud.tscn", "10_hud"),
    ("Script", "res://scripts/interactable.gd", "11_interactable"),
    ("Script", "res://scripts/readable.gd", "12_readable"),
    ("Script", "res://scripts/fire_effect.gd", "13_fire"),
    ("Script", "res://scripts/sign_board.gd", "14_sign"),
    ("PackedScene", K + "nature_kit/cactus_tall.glb", "20_cactus_tall"),
    ("PackedScene", K + "nature_kit/cactus_short.glb", "21_cactus_short"),
    ("PackedScene", K + "survival_kit/rock-sand-a.glb", "22_rock_a"),
    ("PackedScene", K + "survival_kit/rock-sand-b.glb", "23_rock_b"),
    ("PackedScene", K + "survival_kit/rock-sand-c.glb", "24_rock_c"),
    ("PackedScene", K + "mini_arena/column-damaged.glb", "25_column"),
    ("PackedScene", K + "mini_arena/bricks.glb", "26_bricks"),
    ("PackedScene", K + "castle_kit/siege-catapult-demolished.glb", "27_catapult"),
    ("PackedScene", K + "castle_kit/siege-ballista-demolished.glb", "28_ballista"),
    ("PackedScene", K + "castle_kit/siege-trebuchet-demolished.glb", "36_trebuchet"),
    ("PackedScene", K + "mini_dungeon/weapon-spear.glb", "29_spear"),
    ("PackedScene", K + "mini_dungeon/shield-round.glb", "30_shield"),
    ("PackedScene", K + "mini_dungeon/weapon-sword.glb", "31_sword"),
    ("PackedScene", K + "mini_dungeon/pot.glb", "32_pot"),
    ("PackedScene", K + "fantasy_town_kit/wheel.glb", "33_wheel"),
    ("PackedScene", K + "mini_dungeon/barrel.glb", "34_barrel"),
    ("PackedScene", K + "graveyard_kit/character-skeleton.glb", "35_skeleton"),
    ("Script", "res://scenes/levels/desert/rune.gd", "16_rune"),
    ("Script", "res://scenes/levels/desert/sand_pile.gd", "17_pile"),
    ("PackedScene", "res://scenes/levels/desert/rune_puzzle.tscn", "18_puzzle"),
    ("AudioStream", A + "desert_wind.wav", "40_wind"),
    ("AudioStream", A + "cave_ambience.wav", "41_cave"),
    ("AudioStream", A + "footstep_sand_1.wav", "42_sand1"),
    ("AudioStream", A + "footstep_sand_2.wav", "43_sand2"),
    ("AudioStream", A + "footstep_sand_3.wav", "44_sand3"),
    ("AudioStream", A + "footstep_ash_1.wav", "45_stone1"),
    ("AudioStream", A + "footstep_ash_2.wav", "46_stone2"),
    ("AudioStream", A + "footstep_ash_3.wav", "47_stone3"),
    ("AudioStream", A + "tablet_chime_1.wav", "48_chime1"),
    ("AudioStream", A + "tablet_chime_2.wav", "49_chime2"),
    ("AudioStream", A + "tablet_chime_3.wav", "50_chime3"),
    ("AudioStream", A + "tablet_reset.wav", "51_reset"),
    ("AudioStream", A + "fire_crackle.wav", "52_crackle"),
    ("AudioStream", A + "stone_door.wav", "53_rumble"),
    ("AudioStream", A + "plaine_wind.wav", "54_ruin_wind"),
    ("Script", "res://scenes/levels/desert/desert_life.gd", "37_life"),
    ("Script", "res://scenes/levels/desert/desert_mirages.gd", "38_mirages"),
    ("Script", "res://scenes/levels/desert/desert_whirlwinds.gd", "39_whirlwinds"),
    ("Script", "res://scenes/levels/hub/volcano.gd", "90_volcano"),
    ("Shader", "res://scenes/levels/desert/chest_sand.gdshader", "91_chest_sand"),
    # Sol et décor dispersé calculés d'avance (tools/bake_lieux.gd).
    ("Resource", "res://scenes/levels/desert/desert_bake.res", "92_bake"),
]

SUBRESOURCES = """
[sub_resource type="ProceduralSkyMaterial" id="ProceduralSkyMaterial_day"]
sky_top_color = Color(0.3, 0.5, 0.76, 1)
sky_horizon_color = Color(0.96, 0.76, 0.5, 1)
ground_bottom_color = Color(0.5, 0.38, 0.24, 1)
ground_horizon_color = Color(0.96, 0.76, 0.5, 1)
sun_angle_max = 14.0
sun_curve = 0.1

[sub_resource type="Sky" id="Sky_day"]
sky_material = SubResource("ProceduralSkyMaterial_day")

[sub_resource type="Environment" id="Environment_desert"]
background_mode = 2
sky = SubResource("Sky_day")
ambient_light_source = 3
ambient_light_color = Color(0.85, 0.72, 0.55, 1)
ambient_light_sky_contribution = 0.3
ambient_light_energy = 0.3
tonemap_mode = 3
tonemap_exposure = 0.86
glow_enabled = true
glow_intensity = 0.5
glow_bloom = 0.04
glow_hdr_threshold = 1.0
fog_enabled = true
fog_light_color = Color(0.9, 0.73, 0.5, 1)
fog_density = 0.007
fog_sky_affect = 0.2
fog_height = 1.2
fog_height_density = 0.035

[sub_resource type="FastNoiseLite" id="FastNoiseLite_grain"]
seed = 21
frequency = 0.05
fractal_octaves = 3

[sub_resource type="NoiseTexture2D" id="NoiseTexture2D_grain"]
width = 256
height = 256
seamless = true
noise = SubResource("FastNoiseLite_grain")

[sub_resource type="ShaderMaterial" id="ShaderMaterial_sand"]
render_priority = 0
shader = ExtResource("4_sand")
shader_parameter/grain_noise = SubResource("NoiseTexture2D_grain")

[sub_resource type="ShaderMaterial" id="ShaderMaterial_quicksand"]
render_priority = 0
shader = ExtResource("5_quicksand")
shader_parameter/swirl_noise = SubResource("NoiseTexture2D_grain")

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_sandstone"]
albedo_color = Color(0.78, 0.6, 0.4, 1)
roughness = 1.0

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_sandstone_dark"]
albedo_color = Color(0.6, 0.43, 0.27, 1)
roughness = 1.0

[sub_resource type="BoxMesh" id="BoxMesh_stele"]
material = SubResource("StandardMaterial3D_sandstone")
size = Vector3(1.3, 2.5, 0.46)

[sub_resource type="BoxShape3D" id="BoxShape3D_stele"]
size = Vector3(1.3, 2.5, 0.46)

[sub_resource type="BoxMesh" id="BoxMesh_stele_plinth"]
material = SubResource("StandardMaterial3D_sandstone_dark")
size = Vector3(1.8, 0.4, 0.9)

[sub_resource type="BoxShape3D" id="BoxShape3D_stele_plinth"]
size = Vector3(1.8, 0.4, 0.9)

[sub_resource type="BoxMesh" id="BoxMesh_stele_cap"]
material = SubResource("StandardMaterial3D_sandstone_dark")
size = Vector3(1.5, 0.2, 0.62)

[sub_resource type="BoxShape3D" id="BoxShape3D_stele_cap"]
size = Vector3(1.5, 0.2, 0.62)

[sub_resource type="PrismMesh" id="PrismMesh_stele_top"]
material = SubResource("StandardMaterial3D_sandstone")
size = Vector3(1.5, 0.42, 0.56)

[sub_resource type="BoxMesh" id="BoxMesh_stele_frame_v"]
material = SubResource("StandardMaterial3D_sandstone_dark")
size = Vector3(0.08, 2.3, 0.03)

[sub_resource type="BoxMesh" id="BoxMesh_stele_frame_h"]
material = SubResource("StandardMaterial3D_sandstone_dark")
size = Vector3(1.14, 0.08, 0.03)

[sub_resource type="BoxMesh" id="BoxMesh_algo_frame_v"]
material = SubResource("StandardMaterial3D_sandstone_dark")
size = Vector3(0.04, 2.6, 0.1)

[sub_resource type="BoxMesh" id="BoxMesh_algo_frame_h"]
material = SubResource("StandardMaterial3D_sandstone_dark")
size = Vector3(0.04, 0.1, 3.8)

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_wood"]
albedo_color = Color(0.32, 0.18, 0.09, 1)
roughness = 1.0

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_iron"]
albedo_color = Color(0.15, 0.15, 0.15, 1)
metallic = 0.6
roughness = 0.6

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_hatch_stone"]
albedo_color = Color(0.7, 0.55, 0.4, 1)
roughness = 1.0

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_groove"]
albedo_color = Color(0.36, 0.26, 0.17, 1)
roughness = 1.0

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_bronze"]
albedo_color = Color(0.4, 0.27, 0.13, 1)
metallic = 0.6
roughness = 0.5

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_drift"]
albedo_color = Color(0.84, 0.64, 0.4, 1)
roughness = 1.0

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_void"]
albedo_color = Color(0.02, 0.015, 0.01, 1)
roughness = 1.0

[sub_resource type="BoxMesh" id="BoxMesh_hatch_slab"]
material = SubResource("StandardMaterial3D_hatch_stone")
size = Vector3(1.17, 0.16, 2.4)

[sub_resource type="BoxMesh" id="BoxMesh_hatch_groove"]
material = SubResource("StandardMaterial3D_groove")
size = Vector3(0.05, 0.02, 2.2)

[sub_resource type="TorusMesh" id="TorusMesh_ring"]
material = SubResource("StandardMaterial3D_bronze")
inner_radius = 0.11
outer_radius = 0.16
rings = 12
ring_segments = 4

[sub_resource type="SphereMesh" id="SphereMesh_drift"]
material = SubResource("StandardMaterial3D_drift")
radial_segments = 12
rings = 6

[sub_resource type="BoxMesh" id="BoxMesh_hole"]
material = SubResource("StandardMaterial3D_void")
size = Vector3(2.3, 0.8, 2.3)

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_leather"]
albedo_color = Color(0.32, 0.18, 0.09, 1)
roughness = 0.9

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_paper"]
albedo_color = Color(0.88, 0.8, 0.6, 1)
roughness = 1.0

[sub_resource type="BoxMesh" id="BoxMesh_notebook"]
material = SubResource("StandardMaterial3D_leather")
size = Vector3(0.34, 0.06, 0.46)

[sub_resource type="BoxMesh" id="BoxMesh_pages"]
material = SubResource("StandardMaterial3D_paper")
size = Vector3(0.31, 0.045, 0.43)

[sub_resource type="BoxMesh" id="BoxMesh_cord"]
material = SubResource("StandardMaterial3D_groove")
size = Vector3(0.36, 0.065, 0.025)

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_cave_stone"]
albedo_color = Color(0.36, 0.29, 0.23, 1)
roughness = 1.0

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_rock"]
albedo_color = Color(0.5, 0.46, 0.41, 1)
roughness = 1.0

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_rock_dark"]
albedo_color = Color(0.3, 0.27, 0.24, 1)
roughness = 1.0

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_slot"]
albedo_color = Color(0.12, 0.11, 0.1, 1)
roughness = 0.8
emission_enabled = true
emission = Color(0.3, 0.6, 1, 1)
emission_energy_multiplier = 0.0

[sub_resource type="CylinderMesh" id="CylinderMesh_table_base"]
material = SubResource("StandardMaterial3D_rock")
top_radius = 1.2
bottom_radius = 1.4
height = 0.8
radial_segments = 10

[sub_resource type="CylinderMesh" id="CylinderMesh_table_top"]
material = SubResource("StandardMaterial3D_rock")
top_radius = 1.6
bottom_radius = 1.65
height = 0.22
radial_segments = 20

[sub_resource type="TorusMesh" id="TorusMesh_table_rim"]
material = SubResource("StandardMaterial3D_rock_dark")
inner_radius = 1.52
outer_radius = 1.68
rings = 20
ring_segments = 4

[sub_resource type="BoxMesh" id="BoxMesh_slot"]
material = SubResource("StandardMaterial3D_slot")
size = Vector3(0.5, 0.02, 0.36)

[sub_resource type="CylinderMesh" id="CylinderMesh_table_sun"]
material = SubResource("StandardMaterial3D_rock_dark")
top_radius = 0.32
bottom_radius = 0.32
height = 0.02
radial_segments = 16

[sub_resource type="BoxMesh" id="BoxMesh_chest_body"]
material = SubResource("StandardMaterial3D_rock")
size = Vector3(1.5, 0.75, 0.95)

[sub_resource type="BoxMesh" id="BoxMesh_chest_lid"]
material = SubResource("StandardMaterial3D_rock")
size = Vector3(1.6, 0.24, 1.04)

[sub_resource type="BoxMesh" id="BoxMesh_chest_band"]
material = SubResource("StandardMaterial3D_bronze")
size = Vector3(1.62, 0.08, 1.06)

[sub_resource type="BoxMesh" id="BoxMesh_chest_lock"]
material = SubResource("StandardMaterial3D_bronze")
size = Vector3(0.22, 0.26, 0.06)

[sub_resource type="BoxShape3D" id="BoxShape3D_chest"]
size = Vector3(1.7, 1.0, 1.7)

[sub_resource type="BoxMesh" id="BoxMesh_ceiling"]
material = SubResource("StandardMaterial3D_cave_stone")
size = Vector3(20.4, 0.3, 12.4)

[sub_resource type="BoxMesh" id="BoxMesh_shaft_ceiling"]
material = SubResource("StandardMaterial3D_cave_stone")
size = Vector3(4.0, 0.3, 4.2)

[sub_resource type="BoxMesh" id="BoxMesh_shaft_lintel"]
material = SubResource("StandardMaterial3D_cave_stone")
size = Vector3(4.0, 1.45, 0.4)

[sub_resource type="BoxShape3D" id="BoxShape3D_cellar_ramp"]
size = Vector3(2.8, 0.6, 4.54)

[sub_resource type="BoxMesh" id="BoxMesh_step0"]
material = SubResource("StandardMaterial3D_cave_stone")
size = Vector3(2.8, 0.3, 0.34)

[sub_resource type="BoxMesh" id="BoxMesh_step1"]
material = SubResource("StandardMaterial3D_cave_stone")
size = Vector3(2.8, 0.6, 0.34)

[sub_resource type="BoxMesh" id="BoxMesh_step2"]
material = SubResource("StandardMaterial3D_cave_stone")
size = Vector3(2.8, 0.9, 0.34)

[sub_resource type="BoxMesh" id="BoxMesh_step3"]
material = SubResource("StandardMaterial3D_cave_stone")
size = Vector3(2.8, 1.2, 0.34)

[sub_resource type="BoxMesh" id="BoxMesh_step4"]
material = SubResource("StandardMaterial3D_cave_stone")
size = Vector3(2.8, 1.5, 0.34)

[sub_resource type="BoxMesh" id="BoxMesh_step5"]
material = SubResource("StandardMaterial3D_cave_stone")
size = Vector3(2.8, 1.8, 0.34)

[sub_resource type="BoxMesh" id="BoxMesh_step6"]
material = SubResource("StandardMaterial3D_cave_stone")
size = Vector3(2.8, 2.1, 0.34)

[sub_resource type="BoxMesh" id="BoxMesh_step7"]
material = SubResource("StandardMaterial3D_cave_stone")
size = Vector3(2.8, 2.4, 0.34)

[sub_resource type="BoxMesh" id="BoxMesh_step8"]
material = SubResource("StandardMaterial3D_cave_stone")
size = Vector3(2.8, 2.7, 0.34)

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_sun_mark"]
albedo_color = Color(0.55, 0.3, 0.1, 1)
roughness = 1.0

[sub_resource type="CylinderMesh" id="CylinderMesh_sun_disc"]
material = SubResource("StandardMaterial3D_sun_mark")
top_radius = 0.2
bottom_radius = 0.2
height = 0.05
radial_segments = 16

[sub_resource type="BoxMesh" id="BoxMesh_sun_ray"]
material = SubResource("StandardMaterial3D_sun_mark")
size = Vector3(0.05, 0.14, 0.05)

[sub_resource type="CylinderMesh" id="CylinderMesh_torch"]
material = SubResource("StandardMaterial3D_wood")
top_radius = 0.09
bottom_radius = 0.06
height = 0.8

[sub_resource type="CylinderMesh" id="CylinderMesh_torch_collar"]
material = SubResource("StandardMaterial3D_iron")
top_radius = 0.095
bottom_radius = 0.095
height = 0.07
radial_segments = 8
rings = 1

[sub_resource type="BoxMesh" id="BoxMesh_torch_arm"]
material = SubResource("StandardMaterial3D_iron")
size = Vector3(0.2, 0.05, 0.05)

[sub_resource type="BoxMesh" id="BoxMesh_torch_plate"]
material = SubResource("StandardMaterial3D_iron")
size = Vector3(0.03, 0.24, 0.14)

[sub_resource type="BoxMesh" id="BoxMesh_pedestal"]
material = SubResource("StandardMaterial3D_sandstone")
size = Vector3(1.4, 1.1, 0.9)

[sub_resource type="BoxShape3D" id="BoxShape3D_pedestal"]
size = Vector3(1.4, 1.4, 0.9)

[sub_resource type="BoxMesh" id="BoxMesh_slab"]
size = Vector3(1.3, 0.14, 0.85)

[sub_resource type="BoxMesh" id="BoxMesh_algo_slab"]
material = SubResource("StandardMaterial3D_rock")
size = Vector3(0.35, 2.6, 3.8)

[sub_resource type="BoxShape3D" id="BoxShape3D_algo_slab"]
size = Vector3(0.35, 2.6, 3.8)

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_book"]
albedo_color = Color(0.55, 0.35, 0.08, 1)
emission_enabled = true
emission = Color(1, 0.75, 0.3, 1)
emission_energy_multiplier = 1.4

[sub_resource type="BoxMesh" id="BoxMesh_book"]
material = SubResource("StandardMaterial3D_book")
size = Vector3(0.6, 0.14, 0.8)

[sub_resource type="CylinderShape3D" id="CylinderShape3D_table"]
height = 1.2
radius = 1.6

[sub_resource type="ShaderMaterial" id="ShaderMaterial_chest_sand"]
render_priority = 0
shader = ExtResource("91_chest_sand")

[sub_resource type="CylinderMesh" id="CylinderMesh_chest_sand"]
material = SubResource("ShaderMaterial_chest_sand")
top_radius = 1.0
bottom_radius = 1.0
height = 1.0
radial_segments = 20
rings = 6
cap_bottom = false

"""

STELES = [
    ("Levant", -17.6, -12.0, 90.0, "Stèle du couchant", "COUCHANT",
     "Les anciens bâtisseurs répétaient le même geste tant que l'ouvrage n'était pas achevé, puis seulement passaient à la suite. Ainsi la jarre se remplit, seau après seau."),
    ("Zenith", 17.6, -12.0, -90.0, "Stèle du levant", "LEVANT",
     "Avant d'ouvrir une porte, les bâtisseurs posaient une question. Selon la réponse, ils agissaient d'une façon, sinon d'une autre."),
    ("Couchant", -7.0, 8.0, 35.0, "Stèle du midi", "MIDI",
     "Leurs instructions sont gravées sur des runes. Quand le sable a recouvert le monument, elles se sont dispersées dans ses salles, parmi les débris, et sous les dunes."),
]
# Runes : identifiant, position (x, y, z), dans la cave, cachée sous le sable. Dans la cave, « si » et « fermer »
# sont posées sur les deux tables de l'entrée, les autres sous des tas de sable, loin des meubles.
RUNES = [
    ("tant_que", -15.4, 0.0, -14.4, False, False),
    ("porter", 8.4, 0.0, 7.6, False, False),
    ("pour", 2.6, 0.0, 12.0, False, False),
    ("puiser", -9.0, 0.0, -1.0, False, True),
    ("si", -7.0, 0.94, -2.3, True, False),
    ("fermer", 7.0, 0.94, -2.3, True, False),
    ("ouvrir", -5.6, 0.0, -8.4, True, True),
    ("sinon", 6.2, 0.0, -6.2, True, True),
]
# Tas de sable : position (x, z), dans la cave, rune cachée dessous.
PILES = [
    ("PileWest", -9.0, -1.0, False, "puiser"),
    ("PileEastRoom", 15.6, -9.4, False, ""),
    ("PileGate", -4.0, 8.0, False, ""),
    ("PileCaveWest", -5.6, -8.4, True, "ouvrir"),
    ("PileCaveEast", 6.2, -6.2, True, "sinon"),
    ("PileCaveNorth", 3.8, -9.0, True, ""),
]
# Coffre de pierre du livre, dans le coin nord-est de la cave, sous son tas de sable ; sa face regarde la salle.
# Le tas (1,5 m de rayon au pied) s'arrête au pied des plinthes des murs nord et est.
CHEST = (7.2, -9.3, -63.0)
# Cave des archives (build_desert.py) : hauteur sous plafond et face des murs est et ouest, à x = ±9,45.
CELLAR_HEIGHT = 4.8
WALL_FACE_X = 9.45
# Torches : leur pied est à TORCH_OFFSET de la face du mur, le manche penché de TORCH_LEAN degrés vers la salle.
TORCH_OFFSET = 0.22
TORCH_LEAN = 18.0
# Un algorithme par mur de la cave : le premier à l'ouest, le second à l'est.
ALGORITHM_WEST = (
    "Algorithme 1 — Remplir la jarre sacrée\\n"
    "1  Prendre une jarre vide\\n2  [ ? ]\\n3      [ ? ]\\n4      Verser l'eau dans la jarre\\n5  FIN TANT QUE\\n6  [ ? ]"
)
ALGORITHM_EAST = (
    "Algorithme 2 — Garder l'entrée du temple\\n"
    "1  Demander le mot de passe au voyageur\\n2  [ ? ]\\n3      [ ? ]\\n4  [ ? ]\\n5      Sonner l'alarme\\n6  FIN SI"
)


CARAVAN = (
    "Carnet d'un caravanier. Nous menions nos épices et nos étoffes vers Codia quand Vibelandia a déclaré la guerre : "
    "les routes du nord sont tombées, il ne restait que la piste du désert de Pythania. Trois jours que la tempête nous tient, "
    "et le vent brûle comme une forge. Le vieux guide dit que les anciens bâtisseurs gravaient leurs instructions sur des runes, "
    "et qu'il suffit de les remettre dans l'ordre pour que le sable rende ce qu'il garde. Nous en avons vu briller dans les salles "
    "du monument, parmi les débris, et sous des tas de sable. Certains tas ne cachent rien : il faut creuser quand même. "
    "L'eau manque. Les vautours tournent au-dessus des bêtes."
)
INSCRIPTION = (
    "Les anciens bâtisseurs maîtrisaient l'art des instructions. Retrouve les fragments de leur savoir, "
    "rétablis leur ordre et les secrets enfouis te seront révélés."
)


# Récit du lieu : textes laissés par les bâtisseurs et par les voyageurs qui ont fui la guerre. Chacun aide à comprendre
# les algorithmes de la cave sans donner la solution. Nom, parent, position (x, y, z), cap, titre, invite, rayon, corps,
# puis le panneau qui le porte : style (0 bois, 1 pierre, 2 parchemin), montage (0 poteaux, 1 mur), taille, hauteur,
# texte court, inclinaison (couché à plat : -90), ou None s'il n'y a pas de panneau.
LORE = [
    ("MonumentPlaque", "Exterior/Clues", (-10.5, 0.0, 6.0), 0.0, "Plaque du monument", "Lire la plaque", 2.6,
     "Monument des anciens bâtisseurs de Codia. Ici, les maîtres enseignaient l'art des instructions : décomposer un "
     "ouvrage en gestes simples, les écrire dans l'ordre où ils s'accomplissent, répéter un geste tant que l'ouvrage "
     "l'exige, et choisir un geste selon la réponse à une question. Leurs leçons furent gravées sur des runes et "
     "gardées dans les archives, sous la salle des colonnes.",
     (1, 1, (1.8, 0.95), 1.45, "MONUMENT DES ANCIENS BÂTISSEURS\nIci l'on enseignait l'art des instructions", 0.0)),
    ("EliasJournal", "Exterior/Clues", (34.2, 0.555, 4.75), 0.0, "Le journal d'Elias", "Lire le journal", 2.4,
     "Journal d'Elias, marchand d'étoffes. Nous avons quitté Vibelandia à la nuit tombée : ses soldats prenaient les "
     "chariots pour la guerre contre Codia, et nous ne voulions que vendre notre drap. Trois jours de piste dans le "
     "désert de Pythania. À l'oasis, le puits donne encore un peu d'eau, seau après seau. Le vieux puisatier nous a "
     "montré la jarre sacrée : on recommence le même geste aussi longtemps qu'elle n'est pas pleine, et l'on ne porte "
     "au temple qu'une jarre pleine. Nous repartons demain vers le monument.",
     (2, 1, (0.8, 0.5), 0.0, "Journal d'Elias", -90.0)),
    ("JoranLetter", "Exterior/Clues", (-20.0, 0.0, 46.5), 90.0, "La lettre de Joran", "Lire la lettre", 2.4,
     "Lettre glissée sous la planche. « Ma petite Lise, si cette lettre te parvient, sache que nous avons fui "
     "Vibelandia avant que la guerre ne nous prenne tout. La tempête nous a surpris près du monument ; trois des nôtres "
     "reposent ici. Le guide a ramassé les runes qui brillaient dans le sable, mais il en a mis deux de côté : elles ne "
     "répondaient à aucun des murs de la cave, disait-il, et les anciens ne gravaient rien d'inutile. Garde courage. "
     "Ton père, Joran. »",
     (0, 0, (1.3, 0.75), 1.1, "Caravane de Joran\nQu'ils reposent en paix", 0.0)),
    ("ApprenticeTablet", "Exterior/Clues", (14.6, 0.0, -13.6), -90.0, "La tablette de l'apprenti", "Lire la tablette", 2.2,
     "Tablette d'argile d'un apprenti bâtisseur. L'élève avait gravé : « Pour chaque grain de sable, compter un. Fermer "
     "la porte à clé. » Le maître a rayé les deux lignes et gravé dessous : « Compter les grains ne remplit aucune jarre, "
     "et une porte que l'on ferme ne répond à personne. Ne grave que ce que l'ouvrage demande. »",
     (1, 0, (0.95, 0.62), 0.85, "Tablette d'un apprenti", 0.0)),
    ("ArchivistScroll", "Interior/Clues", (4.15, 0.64, -3.2), 0.0, "Le rouleau de l'archiviste", "Lire le rouleau", 2.0,
     "Rouleau resté ouvert sur le pupitre. « Avant d'ouvrir la porte du temple, le gardien pose une question au "
     "voyageur. Si la réponse est la bonne, il agit d'une façon ; sinon, il agit d'une autre, et la cité entière "
     "l'entend. Une condition commence par sa question et s'achève quand ses deux chemins se rejoignent. » En marge, "
     "d'une autre main : « Les runes rangées ici ont été mêlées à celles du dehors. Remettez-les dans l'ordre des murs. »",
     None),
]


def ext(identifier):
    return f'ExtResource("{identifier}")'


def quote(text):
    return '"' + text.replace('"', '\\"') + '"'


def at(x, y, z, scale=1.0, yaw=0.0):
    c = math.cos(math.radians(yaw)) * scale
    s = math.sin(math.radians(yaw)) * scale
    return f"transform = Transform3D({c:.6g}, 0, {s:.6g}, 0, {scale:g}, 0, {-s:.6g}, 0, {c:.6g}, {x:g}, {y:g}, {z:g})"


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
    lines += [
        '[node name="Desert" type="Node3D"]',
        'script = ExtResource("1_desert")',
        'sand_steps = Array[AudioStream]([ExtResource("42_sand1"), ExtResource("43_sand2"), ExtResource("44_sand3")])',
        'stone_steps = Array[AudioStream]([ExtResource("45_stone1"), ExtResource("46_stone2"), ExtResource("47_stone3")])',
        'chimes = Array[AudioStream]([ExtResource("48_chime1"), ExtResource("49_chime2"), ExtResource("50_chime3")])',
        'reset_sound = ExtResource("51_reset")',
        "",
    ]
    node(lines, "WorldEnvironment", "WorldEnvironment", props=['environment = SubResource("Environment_desert")'])
    node(lines, "Sun", "DirectionalLight3D", props=[
        "transform = Transform3D(0.819152, -0.32899, 0.469846, 0, 0.819152, 0.573576, -0.573576, -0.469846, 0.67101, 0, 40, 0)",
        "light_color = Color(1, 0.84, 0.6, 1)", "light_energy = 1.35", "shadow_enabled = true",
        "shadow_normal_bias = 4.0", "directional_shadow_mode = 1", "directional_shadow_split_1 = 0.2",
        "directional_shadow_max_distance = 50.0"])

    node(lines, "Exterior", "Node3D")
    node(lines, "Terrain", "StaticBody3D", "Exterior", props=[
        'script = ExtResource("2_terrain")', 'ground_material = SubResource("ShaderMaterial_sand")',
        'bake = ExtResource("92_bake")'])
    lines += [
        '[node name="Scatter" type="Node3D" parent="Exterior" node_paths=PackedStringArray("terrain")]',
        'script = ExtResource("3_scatter")',
        'terrain = NodePath("../Terrain")',
        'cactus_models = Array[PackedScene]([ExtResource("20_cactus_tall"), ExtResource("21_cactus_short")])',
        'rock_models = Array[PackedScene]([ExtResource("22_rock_a"), ExtResource("23_rock_b"), ExtResource("24_rock_c")])',
        'ruin_models = Array[PackedScene]([ExtResource("25_column"), ExtResource("26_bricks")])',
        'wreck_models = Array[PackedScene]([ExtResource("27_catapult"), ExtResource("28_ballista"), ExtResource("36_trebuchet")])',
        'prop_models = Array[PackedScene]([ExtResource("29_spear"), ExtResource("30_shield"), ExtResource("31_sword"), ExtResource("32_pot"), ExtResource("33_wheel"), ExtResource("34_barrel"), ExtResource("35_skeleton")])',
        "cactus_count = 34",
        'quicksand_material = SubResource("ShaderMaterial_quicksand")',
        'bake = ExtResource("92_bake")',
        "",
    ]
    node(lines, "Ruins", parent="Exterior", instance="6_ruins")
    # Vautours, lézards, scorpions et toiles au vent (desert_life.gd).
    lines += [
        '[node name="Life" type="Node3D" parent="Exterior" node_paths=PackedStringArray("terrain")]',
        'script = ExtResource("37_life")',
        'terrain = NodePath("../Terrain")',
        "",
        # Mirages des vents brûlants : la nappe d'eau de l'oasis et la caravane fantôme des crêtes (desert_mirages.gd).
        '[node name="Mirages" type="Node3D" parent="Exterior" node_paths=PackedStringArray("terrain")]',
        'script = ExtResource("38_mirages")',
        'terrain = NodePath("../Terrain")',
        "",
        # Tourbillons de sable qui errent dans les dunes, avec le sifflement du vent (desert_whirlwinds.gd).
        '[node name="Whirlwinds" type="Node3D" parent="Exterior" node_paths=PackedStringArray("terrain")]',
        'script = ExtResource("39_whirlwinds")',
        'terrain = NodePath("../Terrain")',
        'sound = ExtResource("54_ruin_wind")',
        "",
    ]
    node(lines, "Portal", parent="Exterior", instance="8_portal", props=[
        at(0, 0, 54), 'closed_prompt = "Portail éteint"', 'open_prompt = "Retourner au hub"', "inner_color = Color(1, 0.95, 0.6, 1)", "outer_color = Color(0.95, 0.62, 0.15, 1)"])
    node(lines, "Sign", "Node3D", "Exterior", props=[
        at(-4.4, 0, 45.5, 1.0, 15.0), 'script = ExtResource("14_sign")', 'text = "Désert de Pythania\\nMonument des anciens bâtisseurs"',
        "board_size = Vector2(1.9, 0.9)", "board_height = 1.6", "line_height = 0.16", "double_sided = true"])
    node(lines, "OutsideSpawn", "Marker3D", "Exterior", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.3, -2.5)"])

    node(lines, "Trapdoor", "Node3D", "Exterior", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.08, -6)"])
    node(lines, "Hole", "MeshInstance3D", "Exterior/Trapdoor", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -0.44, 0)", 'mesh = SubResource("BoxMesh_hole")'])
    # La dalle pivote sur ses gonds du bord nord : desert.gd la relève vers le nord, au-dessus du dallage, et le joueur
    # qui arrive du sud voit le trou noir s'ouvrir devant lui.
    node(lines, "Hatch", "Node3D", "Exterior/Trapdoor", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, -1.2)"])
    for index, x in enumerate((-0.6, 0.6)):
        node(lines, f"Slab{index}", "MeshInstance3D", "Exterior/Trapdoor/Hatch", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, 0, 1.2)", 'mesh = SubResource("BoxMesh_hatch_slab")'])
        node(lines, f"Groove{index}", "MeshInstance3D", "Exterior/Trapdoor/Hatch", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x * 0.5:g}, 0.081, 1.2)", 'mesh = SubResource("BoxMesh_hatch_groove")'])
    node(lines, "Ring", "MeshInstance3D", "Exterior/Trapdoor/Hatch", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -0.3, 0.09, 2.05)", 'mesh = SubResource("TorusMesh_ring")'])
    # Le sable couvre une partie de la dalle : il se soulève avec elle.
    node(lines, "Drift", "MeshInstance3D", "Exterior/Trapdoor/Hatch", props=[
        "transform = Transform3D(0.75, 0, 0, 0, 0.12, 0, 0, 0, 1.25, 0.75, 0.06, 0.9)", 'mesh = SubResource("SphereMesh_drift")'])
    node(lines, "Interactable", "Node3D", "Exterior/Trapdoor", props=[
        'script = ExtResource("11_interactable")', 'prompt = "Soulever la trappe de pierre et descendre"', "radius = 2.6"])

    node(lines, "Clues", "Node3D", "Exterior")
    for name, x, z, yaw, title, engraved, body in STELES:
        node(lines, name, "Node3D", "Exterior/Clues", props=[
            at(x, 0, z, 1.0, yaw), 'script = ExtResource("12_readable")', f"title = {quote(title)}",
            f"body = {quote(body)}", 'prompt = "Lire la stèle"', "radius = 2.8"])
        # Socle, fût, corniche et fronton ; les deux faces portent le même cadre, le même soleil et le même nom
        # gravés : la stèle n'a pas de dos nu, d'où qu'on arrive.
        for part, mesh, y in (("Plinth", "BoxMesh_stele_plinth", 0.2), ("Mesh", "BoxMesh_stele", 1.65),
                              ("Cap", "BoxMesh_stele_cap", 3.0), ("Top", "PrismMesh_stele_top", 3.31)):
            node(lines, part, "MeshInstance3D", f"Exterior/Clues/{name}", props=[
                f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {y:g}, 0)", f'mesh = SubResource("{mesh}")'])
        for face, sign in (("Front", 1.0), ("Back", -1.0)):
            yaw_face = 0.0 if sign > 0 else 180.0
            node(lines, face, "Node3D", f"Exterior/Clues/{name}", props=[at(0, 0, 0, 1.0, yaw_face)])
            for part, mesh, x, y in (("FrameLeft", "BoxMesh_stele_frame_v", -0.5, 1.65), ("FrameRight", "BoxMesh_stele_frame_v", 0.5, 1.65),
                                     ("FrameLow", "BoxMesh_stele_frame_h", 0.0, 0.54), ("FrameHigh", "BoxMesh_stele_frame_h", 0.0, 2.76)):
                node(lines, part, "MeshInstance3D", f"Exterior/Clues/{name}/{face}", props=[
                    f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, 0.245)", f'mesh = SubResource("{mesh}")'])
            # Soleil gravé : un disque et huit rayons, en relief sur la face de la stèle.
            node(lines, "Sun", "Node3D", f"Exterior/Clues/{name}/{face}", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.15, 0.24)"])
            node(lines, "Disc", "MeshInstance3D", f"Exterior/Clues/{name}/{face}/Sun", props=[
                "transform = Transform3D(1, 0, 0, 0, 0, -1, 0, 1, 0, 0, 0, 0)", 'mesh = SubResource("CylinderMesh_sun_disc")'])
            for ray in range(8):
                angle = math.radians(ray * 45.0)
                c, s_ = math.cos(angle), math.sin(angle)
                node(lines, f"Ray{ray}", "MeshInstance3D", f"Exterior/Clues/{name}/{face}/Sun", props=[
                    f"transform = Transform3D({c:.6g}, {-s_:.6g}, 0, {s_:.6g}, {c:.6g}, 0, 0, 0, 1, {-s_ * 0.33:.4g}, {c * 0.33:.4g}, 0)",
                    'mesh = SubResource("BoxMesh_sun_ray")'])
            # Nom de la stèle gravé dans la pierre, à fleur de sa face.
            node(lines, "Engraving", "Label3D", f"Exterior/Clues/{name}/{face}", props=[
                "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.35, 0.232)", f"pixel_size = {min(0.0032, 0.0192 / len(engraved)):.5f}", "shaded = true",
                "double_sided = false", "alpha_cut = 1", "modulate = Color(0.3, 0.17, 0.08, 1)", f'text = "{engraved}"',
                "font_size = 64", "outline_size = 0"])
        node(lines, "Body", "StaticBody3D", f"Exterior/Clues/{name}")
        for part, shape, y in (("Plinth", "BoxShape3D_stele_plinth", 0.2), ("CollisionShape3D", "BoxShape3D_stele", 1.65),
                               ("Cap", "BoxShape3D_stele_cap", 3.0)):
            node(lines, part, "CollisionShape3D", f"Exterior/Clues/{name}/Body", props=[
                f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {y:g}, 0)", f'shape = SubResource("{shape}")'])

    node(lines, "Interior", "Node3D", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -40, 0)"])
    node(lines, "Cellar", parent="Interior", instance="7_cellar")
    # Plafond de pierre sombre sur la salle, à 4,8 m (CELLAR_HEIGHT de build_desert.py) : le haut des murs entre
    # dans sa dalle. La cage de l'escalier, plus haute, a le sien, raccordé par un linteau.
    node(lines, "Ceiling", "MeshInstance3D", "Interior", props=[
        f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {CELLAR_HEIGHT + 0.15:g}, -6)", 'mesh = SubResource("BoxMesh_ceiling")'])
    node(lines, "ShaftCeiling", "MeshInstance3D", "Interior", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 5.55, 2.0)", 'mesh = SubResource("BoxMesh_shaft_ceiling")'])
    node(lines, "ShaftLintel", "MeshInstance3D", "Interior", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 4.85, 0.2)", 'mesh = SubResource("BoxMesh_shaft_lintel")'])
    # Escalier de pierre qui remonte vers la trappe, dans la case au sud de la salle : neuf marches de 30 cm,
    # que le joueur monte et descend sur une rampe de collision à 41 degrés, à mi-hauteur de chaque marche.
    node(lines, "Stairs", "StaticBody3D", "Interior")
    for step in range(9):
        node(lines, f"Step{step}", "MeshInstance3D", "Interior/Stairs", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {0.15 * (step + 1):g}, {0.37 + step * 0.34:g})",
            f'mesh = SubResource("BoxMesh_step{step}")'])
    node(lines, "Shape", "CollisionShape3D", "Interior/Stairs", props=[
        "transform = Transform3D(1, 0, 0, 0, 0.749838, 0.661622, 0, -0.661622, 0.749838, 0, 1.125, 1.758)",
        'shape = SubResource("BoxShape3D_cellar_ramp")'])
    # Jour de la trappe, en haut de l'escalier.
    node(lines, "LightStairs", "OmniLight3D", "Interior", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 3.6, 2.6)", "light_color = Color(1, 0.88, 0.62, 1)",
        "light_energy = 1.0", "omni_range = 6.0"])
    # Torches contre les murs est et ouest, de part et d'autre des algorithmes : chacune penchée vers la salle, le
    # pied contre la pierre, tenue par un collier de fer et sa patte scellée dans le mur (face à WALL_FACE_X).
    lean = math.radians(TORCH_LEAN)
    for index, (side, z) in enumerate(((-1, -3.0), (1, -3.0), (-1, -9.0), (1, -9.0))):
        x = side * (WALL_FACE_X - TORCH_OFFSET)
        c, s_ = math.cos(lean), side * math.sin(lean)
        top = (-side * math.sin(lean) * 0.45, math.cos(lean) * 0.45)
        node(lines, f"Torch{index}", "Node3D", "Interior", props=[f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, 2.2, {z:g})"])
        node(lines, "Stick", "MeshInstance3D", f"Interior/Torch{index}", props=[
            f"transform = Transform3D({c:.5g}, {-s_:.5g}, 0, {s_:.5g}, {c:.5g}, 0, 0, 0, 1, 0, 0, 0)", 'mesh = SubResource("CylinderMesh_torch")'])
        # Collier autour du manche, au tiers bas, et patte de fer jusqu'au mur.
        ring = (side * math.sin(lean) * 0.12, -math.cos(lean) * 0.12)
        node(lines, "Collar", "MeshInstance3D", f"Interior/Torch{index}", props=[
            f"transform = Transform3D({c:.5g}, {-s_:.5g}, 0, {s_:.5g}, {c:.5g}, 0, 0, 0, 1, {ring[0]:.4g}, {ring[1]:.4g}, 0)",
            'mesh = SubResource("CylinderMesh_torch_collar")'])
        arm = (TORCH_OFFSET + ring[0] * side) / 2
        node(lines, "Arm", "MeshInstance3D", f"Interior/Torch{index}", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {side * arm:.4g}, {ring[1]:.4g}, 0)",
            'mesh = SubResource("BoxMesh_torch_arm")'])
        node(lines, "Plate", "MeshInstance3D", f"Interior/Torch{index}", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {side * (TORCH_OFFSET - 0.015):.4g}, {ring[1]:.4g}, 0)",
            'mesh = SubResource("BoxMesh_torch_plate")'])
        node(lines, "Fire", "Node3D", f"Interior/Torch{index}", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {top[0]:.4g}, {top[1]:.4g}, 0)", 'script = ExtResource("13_fire")', "size = 0.7",
            "light_energy = 1.5", "light_range = 7.0", 'crackle_sound = ExtResource("52_crackle")', "crackle_volume_db = -14.0"])
    node(lines, "InsideSpawn", "Marker3D", "Interior", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.3, -1.0)"])
    # Sortie au milieu de l'escalier : au pied, on la voit devant soi ; en haut, tourné vers le mur du fond, elle reste
    # à moins d'un mètre (portée sans viser de interaction_controller.gd), donc l'invite ne disparaît plus.
    node(lines, "Exit", "Node3D", "Interior", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.6, 2.4)", 'script = ExtResource("11_interactable")',
        'prompt = "Remonter à la surface"', "radius = 3.2"])
    node(lines, "Clues", "Node3D", "Interior")
    node(lines, "Caravan", "Node3D", "Exterior/Clues", props=[
        at(-32.85, 0.9, -30.29, 1.0, 70.0), 'script = ExtResource("12_readable")',
        'title = "Le carnet du caravanier"', f"body = {quote(CARAVAN)}", 'prompt = "Lire le carnet"', "radius = 2.4"])
    node(lines, "Cover", "MeshInstance3D", "Exterior/Clues/Caravan", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.03, 0)", 'mesh = SubResource("BoxMesh_notebook")'])
    node(lines, "Pages", "MeshInstance3D", "Exterior/Clues/Caravan", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.025, 0.03, 0)", 'mesh = SubResource("BoxMesh_pages")'])
    node(lines, "Cord", "MeshInstance3D", "Exterior/Clues/Caravan", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.03, 0.08)", 'mesh = SubResource("BoxMesh_cord")'])
    node(lines, "Inscription", "Node3D", "Interior/Clues", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, -11.32)", 'script = ExtResource("12_readable")',
        'title = "L\'inscription de la porte scellée"', f"body = {quote(INSCRIPTION)}",
        'prompt = "Lire l\'inscription"', "radius = 3.2"])
    node(lines, "Plaque", "Node3D", "Interior/Clues/Inscription", props=[
        'script = ExtResource("14_sign")', f"text = {quote(INSCRIPTION)}", "style = 1", "mount = 1",
        "board_size = Vector2(2.1, 1.1)", "board_height = 1.95", "line_height = 0.11", "serif = false"])

    for name, parent, (x, y, z), yaw, title, prompt, radius, body, board in LORE:
        node(lines, name, "Node3D", parent, props=[
            at(x, y, z, 1.0, yaw), 'script = ExtResource("12_readable")',
            f"title = {quote(title)}", f"body = {quote(body)}", f"prompt = {quote(prompt)}", f"radius = {radius:g}"])
        if board:
            style, mount, size, height, text, tilt = board
            props = ['script = ExtResource("14_sign")', f'text = "{text}"', f"style = {style}", f"mount = {mount}",
                     f"board_size = Vector2({size[0]:g}, {size[1]:g})", f"board_height = {height:g}"]
            if tilt:
                props.insert(0, "transform = Transform3D(1, 0, 0, 0, 0, 1, 0, -1, 0, 0, 0, 0)")
            if style == 2:
                props.append("serif = false")
            if mount == 0:
                props.append("double_sided = true")
            node(lines, "Board", "Node3D", f"{parent}/{name}", props=props)

    node(lines, "RoundTable", "Node3D", "Interior", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, -6)"])
    node(lines, "Base", "MeshInstance3D", "Interior/RoundTable", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.4, 0)", 'mesh = SubResource("CylinderMesh_table_base")'])
    node(lines, "Top", "MeshInstance3D", "Interior/RoundTable", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.91, 0)", 'mesh = SubResource("CylinderMesh_table_top")'])
    node(lines, "Rim", "MeshInstance3D", "Interior/RoundTable", props=[
        "transform = Transform3D(1, 0, 0, 0, 0.5, 0, 0, 0, 1, 0, 1.0, 0)", 'mesh = SubResource("TorusMesh_table_rim")'])
    node(lines, "Sun", "MeshInstance3D", "Interior/RoundTable", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.025, 0)", 'mesh = SubResource("CylinderMesh_table_sun")'])
    node(lines, "Slots", "Node3D", "Interior/RoundTable")
    for slot in range(6):
        angle = math.radians(slot * 60.0 + 30.0)
        c, s = math.cos(angle), math.sin(angle)
        node(lines, f"Slot{slot}", "MeshInstance3D", "Interior/RoundTable/Slots", props=[
            f"transform = Transform3D({c:.5g}, 0, {s:.5g}, 0, 1, 0, {-s:.5g}, 0, {c:.5g}, {s * 1.05:.4g}, 1.03, {c * 1.05:.4g})",
            'mesh = SubResource("BoxMesh_slot")'])
    node(lines, "Body", "StaticBody3D", "Interior/RoundTable")
    node(lines, "CollisionShape3D", "CollisionShape3D", "Interior/RoundTable/Body", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.6, 0)", 'shape = SubResource("CylinderShape3D_table")'])
    node(lines, "Glow", "OmniLight3D", "Interior/RoundTable", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.6, 0)", "light_color = Color(0.4, 0.7, 1, 1)",
        "light_energy = 2.5", "omni_range = 6.0"])
    node(lines, "Sound", "AudioStreamPlayer3D", "Interior/RoundTable", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.2, 0)", "unit_size = 6.0"])
    node(lines, "Rumble", "AudioStreamPlayer3D", "Interior/RoundTable", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.2, 0)", 'stream = ExtResource("53_rumble")', "unit_size = 10.0",
        "volume_db = 2.0"])
    node(lines, "Interactable", "Node3D", "Interior/RoundTable", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0)", 'script = ExtResource("11_interactable")',
        'prompt = "Examiner la table ronde"', "radius = 2.8"])
    # Chaque algorithme est gravé sur une dalle de pierre plaquée contre le mur, côté salle, au milieu du mur entre
    # ses deux torches : son dos touche la face du mur, son pied repose sur la plinthe (1 m), aucun pilier ni meuble
    # ne se dresse devant, et le texte tient dans son cadre.
    for name, x, yaw, body in (("AlgorithmWall", -9.0, 90.0, ALGORITHM_WEST), ("AlgorithmWallEast", 9.0, -90.0, ALGORITHM_EAST)):
        side = -1.0 if x < 0 else 1.0
        slab_x = WALL_FACE_X - 0.175 - abs(x)
        node(lines, name, "Node3D", "Interior/Clues", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, 2.35, -6)", 'script = ExtResource("12_readable")',
            'title = "Le mur des algorithmes"', f'body = "{body}"', 'prompt = "Examiner l\'algorithme"', "radius = 3.8"])
        node(lines, "Slab", "StaticBody3D", f"Interior/Clues/{name}", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {side * slab_x:g}, 0, 0)"])
        node(lines, "Mesh", "MeshInstance3D", f"Interior/Clues/{name}/Slab", props=['mesh = SubResource("BoxMesh_algo_slab")'])
        node(lines, "Shape", "CollisionShape3D", f"Interior/Clues/{name}/Slab", props=[
            'shape = SubResource("BoxShape3D_algo_slab")'])
        face_x = -side * (0.175 + 0.02)
        for part, mesh, y, z in (("FrameLeft", "BoxMesh_algo_frame_v", 0.0, -1.85), ("FrameRight", "BoxMesh_algo_frame_v", 0.0, 1.85),
                                 ("FrameLow", "BoxMesh_algo_frame_h", -1.25, 0.0), ("FrameHigh", "BoxMesh_algo_frame_h", 1.25, 0.0)):
            node(lines, part, "MeshInstance3D", f"Interior/Clues/{name}/Slab", props=[
                f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {face_x:g}, {y:g}, {z:g})", f'mesh = SubResource("{mesh}")'])
        # Le texte part du bord gauche de la dalle, vu de la salle, et s'étend vers la droite.
        node(lines, "Text", "Label3D", f"Interior/Clues/{name}", props=[
            at(side * (slab_x - 0.175 - 0.012), 0.0, -side * 1.7, 1.0, yaw), "pixel_size = 0.0024", "shaded = true", "double_sided = false",
            "alpha_cut = 1", "modulate = Color(0.86, 0.66, 0.3, 1)", f'text = "{body}"', "font_size = 64", "outline_size = 0",
            "horizontal_alignment = 0"])
    # Coffre du livre, au centre du fond, devant la porte scellée.
    cx, cz, cyaw = CHEST
    node(lines, "Chest", "Node3D", "Interior", props=[at(cx, 0, cz, 1.0, cyaw)])
    node(lines, "Body", "MeshInstance3D", "Interior/Chest", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.375, 0)", 'mesh = SubResource("BoxMesh_chest_body")'])
    node(lines, "Band", "MeshInstance3D", "Interior/Chest", props=[
        "transform = Transform3D(0.94, 0, 0, 0, 1, 0, 0, 0, 0.92, 0, 0.12, 0)", 'mesh = SubResource("BoxMesh_chest_band")'])
    node(lines, "Lid", "Node3D", "Interior/Chest", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.75, -0.5)"])
    node(lines, "Mesh", "MeshInstance3D", "Interior/Chest/Lid", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.12, 0.5)", 'mesh = SubResource("BoxMesh_chest_lid")'])
    node(lines, "Band", "MeshInstance3D", "Interior/Chest/Lid", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.12, 0.5)", 'mesh = SubResource("BoxMesh_chest_band")'])
    node(lines, "Lock", "MeshInstance3D", "Interior/Chest/Lid", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.0, 1.03)", 'mesh = SubResource("BoxMesh_chest_lock")'])
    # Tas de sable sur le coffre : chest_sand.gdshader fait du cylindre un dôme qui couvre tout le coffre, puis l'étale
    # en couche mince autour de lui. Son pied est 2 cm sous le sol, et sa boîte couvre la couche étalée.
    node(lines, "ChestSand", "MeshInstance3D", "Interior", props=[
        f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {cx:g}, -0.02, {cz:g})", 'mesh = SubResource("CylinderMesh_chest_sand")',
        "custom_aabb = AABB(-2.8, -0.1, -2.8, 5.6, 1.7, 5.6)"])
    # Le tas puis le coffre arrêtent le joueur au même endroit.
    node(lines, "ChestBody", "StaticBody3D", "Interior", props=[f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {cx:g}, 0.5, {cz:g})"])
    node(lines, "Shape", "CollisionShape3D", "Interior/ChestBody", props=['shape = SubResource("BoxShape3D_chest")'])
    node(lines, "Runes", "Node3D")
    for rune_id, x, y, z, inside, hidden in RUNES:
        node(lines, "".join(part.capitalize() for part in rune_id.split("_")), "Node3D", "Runes", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y - 40.0 if inside else y:g}, {z:g})",
            'script = ExtResource("16_rune")', f'rune_id = &"{rune_id}"', f"hidden_at_start = {'true' if hidden else 'false'}",
            "radius = 2.2"])
    node(lines, "SandPiles", "Node3D")
    for name, x, z, inside, rune_id in PILES:
        props = [f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {-40.0 if inside else 0:g}, {z:g})",
                 'script = ExtResource("17_pile")', "radius = 2.2"]
        if rune_id:
            props.append(f'rune = NodePath("../../Runes/{"".join(part.capitalize() for part in rune_id.split("_"))}")')
        node(lines, name, "Node3D", "SandPiles", props=props)
    node(lines, "BookTarget", "Marker3D", "Interior", props=[f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {cx:g}, 1.9, {cz:g})"])
    node(lines, "Book", "Node3D", "Interior", props=[f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {cx:g}, 1.9, {cz:g})"])
    node(lines, "Mesh", "MeshInstance3D", "Interior/Book", props=['mesh = SubResource("BoxMesh_book")'])
    node(lines, "Glow", "OmniLight3D", "Interior/Book", props=[
        "light_color = Color(1, 0.8, 0.4, 1)", "light_energy = 1.5", "omni_range = 4.0"])
    node(lines, "Interactable", "Node3D", "Interior/Book", props=[
        'script = ExtResource("11_interactable")', 'prompt = "Prendre l\'Algonicon"', "radius = 3.0"])

    node(lines, "Sounds", "Node3D", "Exterior")
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
    # Volcan en éveil au nord, au-delà des reliefs : il domine la zone comme le hub, vu de loin (fumée et lueur,
    # sans lumière dynamique ni éruption).
    node(lines, "Volcano", "Node3D", "Exterior", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 25, -6, -215)", 'script = ExtResource("90_volcano")',
        "distant = true"])
    node(lines, "Player", instance="9_player", props=[at(0, 0.3, 48), "respawn_height = -80.0", "first_person = true"])
    node(lines, "Wind", "AudioStreamPlayer", props=['stream = ExtResource("40_wind")', "volume_db = -8.0", "autoplay = true"])
    node(lines, "CaveAmbience", "AudioStreamPlayer", props=['stream = ExtResource("41_cave")', "volume_db = -6.0"])
    node(lines, "Hud", instance="10_hud")
    node(lines, "RunePuzzle", instance="18_puzzle")
    out = FRONTEND / "scenes" / "levels" / "desert" / "desert.tscn"
    out.write_text("\n".join(lines).rstrip("\n") + "\n", encoding="utf-8", newline="\n")
    print(out.name, len(lines), "lignes")


if __name__ == "__main__":
    main()
