"""Écrit frontend/scenes/levels/hub/hub.tscn : environnement, terrain, rivière, portails, salle du trône et son cercle
magique, personnages et leurs accessoires, panneaux, bunker, caméras et sons.

Usage : python write_hub_tscn.py <dossier frontend de la worktree>
"""
import math
import sys
from pathlib import Path

FRONTEND = Path(sys.argv[1])
K = "res://assets/models/kenney/"
A = "res://assets/audio/"
EXT = [
    ("Script", "res://scenes/levels/hub/hub.gd", "1_hub"),
    ("Script", "res://scenes/levels/hub/hub_terrain.gd", "2_terrain"),
    ("Script", "res://scenes/levels/hub/hub_scatter.gd", "3_scatter"),
    ("Shader", "res://scenes/levels/hub/hub_ground.gdshader", "4_ground"),
    ("PackedScene", "res://scenes/levels/hub/hub_props.tscn", "5_props"),
    ("PackedScene", "res://scenes/props/portal/portal.tscn", "6_portal"),
    ("PackedScene", "res://scenes/player/player.tscn", "7_player"),
    ("PackedScene", "res://scenes/ui/hud.tscn", "8_hud"),
    ("Script", "res://scripts/interactable.gd", "9_interactable"),
    ("Script", "res://scripts/readable.gd", "10_readable"),
    ("Script", "res://scripts/fire_effect.gd", "11_fire"),
    ("Script", "res://scripts/sign_board.gd", "12_sign"),
    ("PackedScene", K + "mini_forest/character-archer.glb", "13_archer"),
    ("PackedScene", K + "mini_dungeon/character-human.glb", "14_human"),
    ("PackedScene", K + "mini_arena/character-soldier.glb", "16_king"),
    ("PackedScene", K + "nature_kit/tree_default.glb", "20_tree_default"),
    ("PackedScene", K + "nature_kit/tree_oak.glb", "21_tree_oak"),
    ("PackedScene", K + "nature_kit/tree_fat.glb", "22_tree_fat"),
    ("PackedScene", K + "mini_forest/tree.glb", "23_tree_forest"),
    ("PackedScene", K + "mini_forest/tree-high.glb", "24_tree_high"),
    ("PackedScene", K + "nature_kit/plant_bush.glb", "25_bush"),
    ("PackedScene", K + "nature_kit/plant_bushLarge.glb", "26_bush_large"),
    ("PackedScene", K + "nature_kit/rock_largeB.glb", "27_rock"),
    ("PackedScene", K + "castle_kit/rocks-large.glb", "28_rocks"),
    ("PackedScene", K + "nature_kit/flower_redA.glb", "29_flower_red"),
    ("PackedScene", K + "nature_kit/flower_yellowA.glb", "30_flower_yellow"),
    ("PackedScene", K + "nature_kit/flower_purpleA.glb", "31_flower_purple"),
    ("PackedScene", K + "nature_kit/crops_bambooStageA.glb", "32_reed_a"),
    ("PackedScene", K + "nature_kit/crops_bambooStageB.glb", "33_reed_b"),
    ("PackedScene", K + "nature_kit/grass_large.glb", "34_grass"),
    ("PackedScene", K + "nature_kit/rock_smallA.glb", "35_stone_a"),
    ("PackedScene", K + "nature_kit/rock_smallC.glb", "36_stone_c"),
    ("PackedScene", K + "nature_kit/rock_smallFlatA.glb", "37_stone_flat"),
    ("PackedScene", K + "nature_kit/lily_large.glb", "38_lily_large"),
    ("PackedScene", K + "nature_kit/lily_small.glb", "39_lily_small"),
    ("AudioStream", A + "hub_ambience.wav", "40_ambience"),
    ("AudioStream", A + "fire_crackle.wav", "41_crackle"),
    ("AudioStream", A + "footstep_grass_1.wav", "42_grass1"),
    ("AudioStream", A + "footstep_grass_2.wav", "43_grass2"),
    ("AudioStream", A + "footstep_grass_3.wav", "44_grass3"),
    ("AudioStream", A + "tablet_chime_3.wav", "45_chime"),
    ("AudioStream", A + "stone_door.wav", "46_rumble"),
    ("Script", "res://scenes/levels/hub/volcano.gd", "47_volcano"),
    ("Script", "res://scenes/levels/hub/hub_ending.gd", "48_ending"),
    ("Shader", "res://scenes/levels/hub/hub_flood.gdshader", "49_flood"),
    ("AudioStream", A + "volcano_eruption.wav", "50_eruption"),
    ("PackedScene", "res://scenes/levels/hub/hub_bunker.tscn", "51_bunker"),
    ("Script", "res://scenes/levels/hub/hub_river.gd", "52_river"),
    ("Shader", "res://scenes/levels/hub/hub_water.gdshader", "53_water"),
    ("Script", "res://scenes/levels/hub/hub_sounds.gd", "54_sounds"),
]


# Petites aides de géométrie : matrices 3 x 3 écrites ligne par ligne, comme Transform3D dans un .tscn.
def rot_x(degrees):
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
    return [[1, 0, 0], [0, c, -s], [0, s, c]]


def rot_y(degrees):
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
    return [[c, 0, s], [0, 1, 0], [-s, 0, c]]


def rot_z(degrees):
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
    return [[c, -s, 0], [s, c, 0], [0, 0, 1]]


def mul(a, b):
    return [[sum(a[r][i] * b[i][c] for i in range(3)) for c in range(3)] for r in range(3)]


def scaled(m, sx, sy=None, sz=None):
    sy = sx if sy is None else sy
    sz = sx if sz is None else sz
    return [[m[r][0] * sx, m[r][1] * sy, m[r][2] * sz] for r in range(3)]


IDENTITY = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]


def tf(basis=IDENTITY, origin=(0.0, 0.0, 0.0)):
    values = [v for row in basis for v in row] + list(origin)
    return "transform = Transform3D(" + ", ".join(f"{round(v, 5):g}" for v in values) + ")"


def at(x, y, z, scale=1.0, yaw=0.0):
    return tf(scaled(rot_y(yaw), scale), (x, y, z))


def yaw_toward(dx, dz):
    """Cap qui tourne la face +Z d'un nœud vers la direction (dx, dz)."""
    return math.degrees(math.atan2(dx, dz))


SUBRESOURCES = """
[sub_resource type="ProceduralSkyMaterial" id="ProceduralSkyMaterial_hub"]
sky_top_color = Color(0.3, 0.29, 0.36, 1)
sky_horizon_color = Color(0.5, 0.45, 0.45, 1)
ground_bottom_color = Color(0.18, 0.16, 0.14, 1)
ground_horizon_color = Color(0.5, 0.45, 0.45, 1)

[sub_resource type="Sky" id="Sky_hub"]
sky_material = SubResource("ProceduralSkyMaterial_hub")

[sub_resource type="Environment" id="Environment_hub"]
background_mode = 2
sky = SubResource("Sky_hub")
ambient_light_source = 3
ambient_light_color = Color(0.75, 0.72, 0.7, 1)
ambient_light_energy = 0.5
tonemap_mode = 3
glow_enabled = true
glow_intensity = 0.5
glow_bloom = 0.04
glow_hdr_threshold = 1.0
fog_enabled = true
fog_light_color = Color(0.45, 0.42, 0.42, 1)
fog_density = 0.02
fog_sky_affect = 0.3

[sub_resource type="ShaderMaterial" id="ShaderMaterial_ground"]
render_priority = 0
shader = ExtResource("4_ground")

[sub_resource type="FastNoiseLite" id="FastNoiseLite_ripples"]
seed = 5831
frequency = 0.05
fractal_octaves = 3

[sub_resource type="NoiseTexture2D" id="NoiseTexture2D_ripples"]
width = 256
height = 256
seamless = true
noise = SubResource("FastNoiseLite_ripples")

[sub_resource type="ShaderMaterial" id="ShaderMaterial_river"]
render_priority = 0
shader = ExtResource("53_water")
shader_parameter/ripple_noise = SubResource("NoiseTexture2D_ripples")
shader_parameter/flow_speed = 0.8
shader_parameter/across = 10.0

[sub_resource type="ShaderMaterial" id="ShaderMaterial_pond"]
render_priority = 0
shader = ExtResource("53_water")
shader_parameter/ripple_noise = SubResource("NoiseTexture2D_ripples")
shader_parameter/flow_speed = 0.05
shader_parameter/across = 1.0
shader_parameter/clear_color = Color(0.08, 0.22, 0.2, 1)

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_stone"]
albedo_color = Color(0.42, 0.4, 0.4, 1)
roughness = 1.0

[sub_resource type="StandardMaterial3D" id="Material_pedestal_dark"]
albedo_color = Color(0.32, 0.3, 0.31, 1)
roughness = 1.0

[sub_resource type="BoxMesh" id="BoxMesh_pedestal_base"]
material = SubResource("Material_pedestal_dark")
size = Vector3(1.1, 0.22, 1.1)

[sub_resource type="BoxMesh" id="BoxMesh_pedestal"]
material = SubResource("StandardMaterial3D_stone")
size = Vector3(0.78, 0.86, 0.78)

[sub_resource type="BoxMesh" id="BoxMesh_pedestal_top"]
material = SubResource("Material_pedestal_dark")
size = Vector3(0.98, 0.12, 0.98)

[sub_resource type="BoxShape3D" id="BoxShape3D_pedestal"]
size = Vector3(0.82, 1.3, 0.82)

[sub_resource type="StandardMaterial3D" id="Material_robe"]
albedo_color = Color(0.3, 0.18, 0.55, 1)
roughness = 0.9

[sub_resource type="StandardMaterial3D" id="Material_star"]
albedo_color = Color(0.95, 0.85, 0.4, 1)
emission_enabled = true
emission = Color(1, 0.85, 0.35, 1)

[sub_resource type="StandardMaterial3D" id="Material_beard"]
albedo_color = Color(0.9, 0.9, 0.88, 1)
roughness = 1.0

[sub_resource type="StandardMaterial3D" id="Material_staff"]
albedo_color = Color(0.36, 0.22, 0.12, 1)

[sub_resource type="StandardMaterial3D" id="Material_orb"]
albedo_color = Color(0.7, 0.55, 1, 1)
emission_enabled = true
emission = Color(0.6, 0.4, 1, 1)
emission_energy_multiplier = 2.5

[sub_resource type="CylinderMesh" id="CylinderMesh_robe"]
material = SubResource("Material_robe")
top_radius = 0.36
bottom_radius = 0.62
height = 1.0
radial_segments = 10

[sub_resource type="CylinderMesh" id="CylinderMesh_hat"]
material = SubResource("Material_robe")
top_radius = 0.0
bottom_radius = 0.6
height = 1.15
radial_segments = 10

[sub_resource type="CylinderMesh" id="CylinderMesh_brim"]
material = SubResource("Material_robe")
top_radius = 0.78
bottom_radius = 0.78
height = 0.07
radial_segments = 12

[sub_resource type="CylinderMesh" id="CylinderMesh_band"]
material = SubResource("Material_star")
top_radius = 0.58
bottom_radius = 0.61
height = 0.1
radial_segments = 10

[sub_resource type="BoxMesh" id="BoxMesh_beard_jaw"]
material = SubResource("Material_beard")
size = Vector3(0.88, 0.27, 0.62)

[sub_resource type="BoxMesh" id="BoxMesh_beard_tail1"]
material = SubResource("Material_beard")
size = Vector3(0.7, 0.22, 0.2)

[sub_resource type="BoxMesh" id="BoxMesh_beard_tail2"]
material = SubResource("Material_beard")
size = Vector3(0.5, 0.2, 0.18)

[sub_resource type="BoxMesh" id="BoxMesh_beard_tail3"]
material = SubResource("Material_beard")
size = Vector3(0.28, 0.18, 0.16)

[sub_resource type="CapsuleMesh" id="CapsuleMesh_mustache"]
material = SubResource("Material_beard")
radius = 0.055
height = 0.36
radial_segments = 8
rings = 2

[sub_resource type="CylinderMesh" id="CylinderMesh_staff"]
material = SubResource("Material_staff")
top_radius = 0.045
bottom_radius = 0.055
height = 2.5
radial_segments = 6

[sub_resource type="SphereMesh" id="SphereMesh_orb"]
material = SubResource("Material_orb")
radius = 0.17
height = 0.34

[sub_resource type="StandardMaterial3D" id="Material_gold"]
albedo_color = Color(0.85, 0.65, 0.25, 1)
metallic = 0.6
roughness = 0.4

[sub_resource type="StandardMaterial3D" id="Material_crown"]
cull_mode = 2
albedo_color = Color(0.9, 0.7, 0.25, 1)
metallic = 0.6
roughness = 0.35

[sub_resource type="StandardMaterial3D" id="Material_velvet"]
albedo_color = Color(0.55, 0.08, 0.1, 1)
roughness = 0.9

[sub_resource type="StandardMaterial3D" id="Material_hall_floor"]
albedo_color = Color(0.4, 0.38, 0.37, 1)
roughness = 1.0

[sub_resource type="StandardMaterial3D" id="Material_hall_ceiling"]
albedo_color = Color(0.3, 0.2, 0.13, 1)
roughness = 1.0

[sub_resource type="StandardMaterial3D" id="Material_circle"]
albedo_color = Color(0.2, 0.19, 0.2, 1)
roughness = 0.7
emission_enabled = true
emission = Color(0.35, 0.6, 1, 1)
emission_energy_multiplier = 0.0

[sub_resource type="TorusMesh" id="TorusMesh_circle_outer"]
material = SubResource("Material_circle")
inner_radius = 5.38
outer_radius = 5.62
rings = 48
ring_segments = 4

[sub_resource type="TorusMesh" id="TorusMesh_circle_inner"]
material = SubResource("Material_circle")
inner_radius = 3.92
outer_radius = 4.08
rings = 40
ring_segments = 4

[sub_resource type="TorusMesh" id="TorusMesh_circle_heart"]
material = SubResource("Material_circle")
inner_radius = 2.72
outer_radius = 2.86
rings = 32
ring_segments = 4

[sub_resource type="BoxMesh" id="BoxMesh_circle_spoke"]
material = SubResource("Material_circle")
size = Vector3(0.12, 0.02, 1.5)

[sub_resource type="BoxMesh" id="BoxMesh_dais"]
material = SubResource("Material_hall_floor")
size = Vector3(4, 0.3, 2.6)

[sub_resource type="BoxMesh" id="BoxMesh_throne_seat"]
material = SubResource("Material_velvet")
size = Vector3(1.6, 0.6, 1.3)

[sub_resource type="BoxMesh" id="BoxMesh_throne_back"]
material = SubResource("Material_velvet")
size = Vector3(1.6, 2.8, 0.3)

[sub_resource type="BoxMesh" id="BoxMesh_throne_frame"]
material = SubResource("Material_gold")
size = Vector3(0.22, 1.2, 1.4)

[sub_resource type="BoxMesh" id="BoxMesh_throne_crest"]
material = SubResource("Material_gold")
size = Vector3(1.9, 0.3, 0.36)

[sub_resource type="BoxShape3D" id="BoxShape3D_throne"]
size = Vector3(2.1, 3.35, 1.45)

[sub_resource type="BoxShape3D" id="BoxShape3D_dais"]
size = Vector3(4, 0.3, 2.6)

[sub_resource type="BoxMesh" id="BoxMesh_hall_floor"]
material = SubResource("Material_hall_floor")
size = Vector3(20, 0.1, 12)

[sub_resource type="BoxMesh" id="BoxMesh_bunker_cover"]
material = SubResource("Material_hall_ceiling")
size = Vector3(21, 0.3, 13)

[sub_resource type="BoxMesh" id="BoxMesh_hall_ceiling"]
material = SubResource("Material_hall_ceiling")
size = Vector3(20.4, 0.4, 12.4)

[sub_resource type="BoxMesh" id="BoxMesh_beam"]
material = SubResource("Material_hall_ceiling")
size = Vector3(0.5, 0.6, 12)

[sub_resource type="BoxShape3D" id="BoxShape3D_hall_floor"]
size = Vector3(20, 0.1, 12)

[sub_resource type="FastNoiseLite" id="FastNoiseLite_flood"]
seed = 66
frequency = 0.03
fractal_octaves = 3

[sub_resource type="NoiseTexture2D" id="NoiseTexture2D_flood"]
width = 256
height = 256
seamless = true
noise = SubResource("FastNoiseLite_flood")

[sub_resource type="ShaderMaterial" id="ShaderMaterial_flood"]
render_priority = 0
shader = ExtResource("49_flood")
shader_parameter/flow_noise = SubResource("NoiseTexture2D_flood")
shader_parameter/emission_strength = 3.0

[sub_resource type="StandardMaterial3D" id="Material_ermine"]
albedo_color = Color(0.95, 0.94, 0.9, 1)
roughness = 1.0

[sub_resource type="CylinderMesh" id="CylinderMesh_crown"]
material = SubResource("Material_crown")
top_radius = 0.63
bottom_radius = 0.594
height = 0.24
radial_segments = 4
cap_top = false
cap_bottom = false

[sub_resource type="PrismMesh" id="PrismMesh_crown_spike"]
material = SubResource("Material_crown")
size = Vector3(0.16, 0.22, 0.07)

[sub_resource type="SphereMesh" id="SphereMesh_jewel"]
material = SubResource("Material_velvet")
radius = 0.06
height = 0.12

[sub_resource type="BoxMesh" id="BoxMesh_cape"]
material = SubResource("Material_velvet")
size = Vector3(1.5, 0.9, 0.08)

[sub_resource type="CylinderMesh" id="CylinderMesh_collar"]
material = SubResource("Material_ermine")
top_radius = 0.5
bottom_radius = 0.58
height = 0.14
radial_segments = 12

[sub_resource type="CylinderMesh" id="CylinderMesh_scepter"]
material = SubResource("Material_gold")
top_radius = 0.035
bottom_radius = 0.045
height = 1.2
radial_segments = 6

[sub_resource type="SphereMesh" id="SphereMesh_scepter"]
material = SubResource("Material_gold")
radius = 0.1
height = 0.2

[sub_resource type="CylinderShape3D" id="CylinderShape3D_character"]
height = 2.0
radius = 0.6
"""

ZONES = [
    # nom, zone, couleur intérieure, couleur extérieure, couleur du livre, nom du lieu
    ("Plaine", "plaine", "Color(1, 0.8, 0.35, 1)", "Color(0.9, 0.2, 0.05, 1)", "Color(0.5, 0.08, 0.05, 1)", "Les plaines d'Hexcole"),
    ("Desert", "desert", "Color(1, 0.95, 0.6, 1)", "Color(0.95, 0.62, 0.15, 1)", "Color(0.55, 0.35, 0.08, 1)", "Le désert de Pythania"),
    ("Marais", "marais", "Color(0.6, 1, 0.7, 1)", "Color(0.1, 0.55, 0.3, 1)", "Color(0.1, 0.35, 0.25, 1)", "Les marais de Kernel Swamp"),
    ("Village", "village", "Color(0.85, 0.7, 1, 1)", "Color(0.45, 0.2, 0.8, 1)", "Color(0.3, 0.15, 0.5, 1)", "Le village détruit"),
]
BOOK_TITLES = {"plaine": "PROJENOMICON", "desert": "ALGONICON", "marais": "LOGICONOMICON", "village": "CODONOMICON"}
PORTALS = {"plaine": (-38.0, -38.0), "desert": (38.0, -38.0), "marais": (38.0, 38.0), "village": (-38.0, 38.0)}
# Salle du trône du château : centre et profondeur, comme dans tools/build_hub.py.
HALL_Z = -81.0
HALL_HALF_DEPTH = 6.0
# Trône contre le mur ouest de la salle (qui va de x = -10 à 10), tourné vers le cercle : au fond de la salle, son
# estrade recouvrait l'anneau extérieur du cercle (5,62 m de rayon pour 6 m de demi-profondeur).
THRONE_X = -8.7
# Cercle magique au milieu de la salle, dans son repère : centre, rayon des piédestaux, rayon des lettres.
CIRCLE = (0.0, -0.2)
PEDESTAL_RADIUS = 5.0
LETTER_RADIUS = 3.4
# Piédestaux autour du cercle, dans l'ordre des livres : angle (degrés, de +x vers +z) de chacun.
PEDESTAL_ANGLES = {"plaine": 135.0, "desert": 225.0, "marais": 315.0, "village": 45.0}
# Braseros de la cour et de la porterie, comme dans tools/build_hub.py : leur lumière.
BRAZIERS = [(-4.5, -69.5), (4.5, -69.5), (-4.0, -55.5), (4.0, -55.5)]
# Abri du bunker : origine de son intérieur, sous la carte, et points où se tiennent ses habitants.
BUNKER_INSIDE = (78.0, -40.0, 0.0)


def inside(x, z):
    return BUNKER_INSIDE[0] + x, BUNKER_INSIDE[2] + z


def around_fire(degrees, radius=4.8):
    """Repère tourné vers le feu de camp de la place, entre ses rondins."""
    x, z = round(math.cos(math.radians(degrees)) * radius, 3) + 0.0, round(math.sin(math.radians(degrees)) * radius, 3) + 0.0
    return x, z, math.degrees(math.atan2(-x, -z)), 0.0


def pedestal_spot(zone):
    angle = math.radians(PEDESTAL_ANGLES[zone])
    return CIRCLE[0] + math.cos(angle) * PEDESTAL_RADIUS, CIRCLE[1] + math.sin(angle) * PEDESTAL_RADIUS


# Tous les habitants restent au bunker pendant la partie. À la victoire, hub.gd les pose sur ces repères :
# Merlon et le roi dans la salle du trône pour le rituel, les autres autour du feu, face à la caméra de la fin.
OUTSIDE = {
    "Merlon": (1.2, HALL_Z + 4.1, yaw_toward(CIRCLE[0] - 1.2, CIRCLE[1] - 4.1), 0.1),
    "Codeon": (-6.3, HALL_Z - 2.2, 70.0, 0.1),
    "Mira": around_fire(180.0),
    "Bran": around_fire(225.0),
    "Elda": around_fire(270.0),
    "Tom": around_fire(315.0),
    "Garde": around_fire(0.0),
}
# Personnages : (nœud, modèle, x, z, cap, échelle, titre, texte, invite, pose, y).
CHARACTERS = [
    ("Merlon", "14_human", *inside(2.4, -3.0), 0.0, 2.5, "Merlon, le mage", "", "Parler à Merlon", "holding-left", BUNKER_INSIDE[1]),
    ("Codeon", "14_human", *inside(-2.4, -3.0), 0.0, 2.4, "Codeon V, roi de Codia", "", "Parler au roi", "holding-left", BUNKER_INSIDE[1]),
    ("Mira", "13_archer", *inside(-7.4, -1.6), 70.0, 2.4, "Mira, l'éclaireuse",
     "Deux ans que nous vivons sous terre, au bruit des combats lointains. Puis le silence… La guerre contre Vibelandia est finie, mais personne n'ose remonter. On raconte que les livres des anciens bâtisseurs gardent la mémoire du monde d'avant. S'ils reviennent, peut-être que la terre se souviendra.",
     "Parler à Mira", "idle", BUNKER_INSIDE[1]),
    ("Bran", "14_human", *inside(7.0, -0.8), -90.0, 2.4, "Bran, le forgeron",
     "Pendant huit ans, j'ai forgé les épées de tes soldats, Devlyn. Ma forge est restée là-haut, au bord de la rivière. Les portails que Merlon a ouverts mènent à des terres perdues : fais attention, ce qui reste là-bas n'a rien d'accueillant.",
     "Parler à Bran", "idle", BUNKER_INSIDE[1]),
    ("Elda", "14_human", *inside(-3.0, 3.2), 70.0, 2.3, "Elda, la tisserande",
     "Quand le roi a fait sonner les cloches, nous avons couru jusqu'ici avec ce que nous pouvions porter. Tant d'autres ne sont jamais arrivés… Si tu rapportes ces livres, nous pourrons enfin remonter vivre au soleil.",
     "Parler à Elda", "idle", BUNKER_INSIDE[1]),
    ("Tom", "13_archer", *inside(4.2, 3.0), -110.0, 2.2, "Tom, l'apprenti",
     "C'est vrai que tu as vaincu les Quatre Dragons du Chaos, il y a des années ? Et que tu as commandé l'armée contre Vibelandia ? Moi, un jour, je partirai aussi par les portails.",
     "Parler à Tom", "idle", BUNKER_INSIDE[1]),
    ("Garde", "16_king", *inside(2.2, 4.6), 200.0, 2.4, "Aldric, garde royal",
     "Devlyn ! Le roi te fait demander : il t'attend au fond de l'abri, avec un vieil homme que personne ici ne connaissait. Je garde la porte du bunker. Quand tu remonteras, prends le chemin du château : ce qu'il en reste se dresse au nord du village.",
     "Parler au garde", "idle", BUNKER_INSIDE[1]),
]

# Os des personnages Kenney (mini_dungeon, mini_forest, mini_arena), en unités du modèle : origine de l'os de la
# tête et du torse au repos, et pose du bras gauche dans l'animation holding-left (origine, rotation autour de Y).
HEAD_BONE = (0.0, 0.343, 0.003)
TORSO_BONE = (0.0, 0.176, -0.024)
ARM_LEFT_HOLD = ((0.1, 0.288, -0.012), -60.0)
BONES = {"torso": 3, "arm-left": 4, "head": 6}


def gear(origin, yaw, scale):
    """Repère enfant d'un os qui annule la pose de l'os et l'échelle du modèle : ses enfants se placent en mètres,
    dans le repère du personnage tel qu'il se tient dans sa pose."""
    rt = [list(row) for row in zip(*rot_y(yaw))]
    basis = [[v / scale for v in row] for row in rt]
    o = [-sum(rt[r][c] * origin[c] for c in range(3)) for r in range(3)]
    return tf(basis, o)


# Panneaux à lire des lieux du village : (nom, x, z, cap, titre, texte, enseigne, style, accroche, taille).
# Le cap tourne la face du panneau vers le chemin d'où l'on arrive.
LORE = [
    ("SchoolSign", -2.8, 54.6, 180.0, "L'école de Codia",
     "Avant la guerre, on y apprenait aux enfants l'art des instructions : découper un problème, mettre les étapes dans l'ordre, vérifier chaque résultat. Sur le tableau, quelqu'un a écrit à la craie : « Les anciens bâtisseurs ont tout consigné dans quatre livres. »",
     "École de Codia", "WOOD", "POSTS", (1.3, 0.6)),
    ("TavernSign", -52.6, 4.6, 90.0, "La Chope du Dragon",
     "La tavernière aime raconter l'an 5802 : Devlyn et ses compagnons y fêtaient leur victoire sur les Quatre Dragons du Chaos. Elle jure que la dernière bière tirée avant la guerre contre Vibelandia attend encore au fond d'un tonneau, pour le jour où Codia renaîtra.",
     "La Chope du Dragon", "WOOD", "HANGING", (1.4, 0.6)),
    ("ChapelSign", -50.8, -26.0, 90.0, "La chapelle des Quatre Livres",
     "Les anciens priaient ici devant quatre lutrins vides. Une prière est gravée au-dessus de l'autel : « Que l'ordre du Projenomicon, la rigueur de l'Algonicon, la logique du Logiconomicon et la clarté du Codonomicon veillent sur Codia. »",
     "Chapelle des Quatre Livres", "STONE", "POSTS", (1.4, 0.6)),
    ("ForgeSign", 49.8, 22.6, -90.0, "La forge de Bran",
     "Pendant huit ans de guerre contre Vibelandia, Bran y a forgé les épées et les boucliers de l'armée de Codia, nuit et jour, au bord de la rivière. Sur l'enclume, une marque : la couronne de l'atelier royal.",
     "Forge", "IRON", "HANGING", (1.1, 0.5)),
    ("FarmSign", 48.8, 58.4, 180.0, "La ferme du roi",
     "Elle nourrissait tout le village, jusqu'à ce que les armées de Vibelandia brûlent ses récoltes. Mira dit que les champs repousseront quand les livres seront revenus au château.",
     "Ferme du roi", "WOOD", "POSTS", (1.2, 0.55)),
    ("MineSign", 76.2, -29.4, -15.0, "La mine d'argent",
     "La galerie s'est effondrée pendant la guerre. Un écriteau est cloué au boisage : « Fermée par ordre du roi Codeon V. Les mineurs ont rejoint le bunker. »",
     "Mine d'argent", "WOOD", "POSTS", (1.2, 0.55)),
    ("NoticeBoard", -2.6, -9.6, 0.0, "Avis à la population",
     "Par ordre du roi Codeon V : les armées de Vibelandia approchent. Que chacun rejoigne sans attendre l'ancien bunker, à l'est du village, au-delà de la rivière. N'emportez que l'essentiel, et aidez les plus faibles. Codia, an 5812.",
     "Avis à la population", "PARCHMENT", "POSTS", (1.2, 0.8)),
    ("CastleSign", 3.6, -43.6, 0.0, "Les ruines du château",
     "Le château du roi Codeon V. Ses murailles ont tenu huit ans face aux armées de Vibelandia, puis la guerre les a éventrées. Au cœur du donjon, la salle du trône garde un cercle magique plus ancien que le royaume, et quatre piédestaux qui attendent les livres des anciens bâtisseurs.",
     "Château de Codeon V", "STONE", "POSTS", (1.6, 0.6)),
    # Lieux autour du village (tools/build_hub.py) : les enseignes des bâtiments sont fixées à leur façade.
    ("LavoirSign", 48.0, 3.4, 180.0, "Le lavoir de la rivière",
     "Ici, on lavait le linge dans l'eau claire qui descend des montagnes. Le jour où le roi fit sonner les cloches, en 5812, les draps sont restés sur la corde ; deux ans plus tard, le vent les avait emportés jusqu'au pont.",
     "Lavoir", "WOOD", "POSTS", (1.1, 0.5)),
    ("BakerySign", 47.74, 36.0, -90.0, "La boulangerie",
     "Chaque matin, l'odeur du pain chaud montait jusqu'au château. La farine venait du moulin voisin, le blé de la ferme du roi. Pendant la guerre, le boulanger cuisait encore pour les soldats, jusqu'à la dernière poignée de farine.",
     "Boulangerie", "WOOD", "WALL", (1.3, 0.5)),
    ("MillSign", 56.74, 50.0, -90.0, "Le moulin de la rivière",
     "La roue tournait jour et nuit dans le courant, et la meule réduisait le blé en farine pour tout Codia. Le meunier l'a arrêtée la veille du départ pour le bunker : elle ne repartira que si la rivière retrouve sa force.",
     "Moulin", "WOOD", "WALL", (1.1, 0.5)),
    ("StablesSign", -61.74, -44.0, 90.0, "Les écuries royales",
     "Les chevaux de la garde y attendaient leurs cavaliers. Ils sont tous partis avec l'armée de Devlyn en 5804, contre Vibelandia ; aucun n'est revenu. Les stalles attendent des jours meilleurs.",
     "Écuries royales", "WOOD", "WALL", (1.5, 0.5)),
    ("BarracksSign", -48.0, -61.74, 0.0, "La caserne de la garde",
     "Aldric y a fait ses classes, comme tous les gardes du roi. Sur le mur, la liste des volontaires partis défendre Codia contre Vibelandia couvre trois planches entières ; beaucoup de noms sont barrés.",
     "Caserne de la garde", "STONE", "WALL", (1.7, 0.5)),
    ("ApothecarySign", -55.74, 32.0, 90.0, "L'herboristerie",
     "Onguents, tisanes et remèdes : l'herboriste soignait ici les blessés que l'on ramenait du front. Au jardin des simples, devant la porte, quelques pieds de sauge ont survécu à la guerre.",
     "Herboristerie", "WOOD", "WALL", (1.4, 0.5)),
    ("ScriptoriumSign", -69.74, -14.0, 90.0, "Le scriptorium",
     "Les copistes de Codia y recopiaient, ligne après ligne, ce qui restait des écrits des anciens bâtisseurs. Les quatre livres originaux, disait-on, étaient perdus depuis des siècles ; on n'en gardait ici que des fragments, et des légendes.",
     "Scriptorium", "STONE", "WALL", (1.3, 0.5)),
    ("ObservatorySign", -64.1, 53.1, -136.0, "L'observatoire du Mont Sam Altan",
     "Du haut de cette tour, les veilleurs du roi guettaient le volcan, endormi depuis des siècles. Leur registre s'arrête en 5812, la veille du départ pour le bunker : « Fumée légère au sommet. Rien à signaler. »",
     "Observatoire", "STONE", "POSTS", (1.3, 0.5)),
    ("MarketHallSign", -21.0, 60.4, 180.0, "La halle du marché",
     "Les jours de marché, les paysans des plaines d'Hexcole et les marchands venus du désert de Pythania s'y retrouvaient à l'abri. Son toit s'est effondré pendant les combats ; les étals sont restés dessous.",
     "Halle du marché", "WOOD", "POSTS", (1.4, 0.5)),
    ("OrchardSign", 9.6, 71.6, 190.0, "Le verger du roi",
     "Pommiers et poiriers en rangs serrés : le roi Codeon III les avait plantés pour les enfants du village, qui venaient y cueillir les fruits à l'automne. La guerre n'a laissé que des souches.",
     "Verger du roi", "WOOD", "POSTS", (1.3, 0.5)),
    ("ParkSign", 33.4, -50.4, 0.0, "Le jardin du roi",
     "Allées de gravier, parterres et kiosque à musique : les habitants s'y promenaient le soir, au bord de la rivière. Au centre, la statue de Devlyn rappelle la victoire de l'an 5802 sur les Quatre Dragons du Chaos.",
     "Jardin du roi", "STONE", "POSTS", (1.4, 0.5)),
    ("KingsSign", 39.4, -53.4, 0.0, "L'allée des rois",
     "Codeon I, le bâtisseur ; Codeon II, le sage ; Codeon III, le jardinier ; Codeon IV, le prudent. Les statues des anciens rois bordent l'allée qui mène à celle de Devlyn. Renversées pendant la guerre, elles attendent qu'on les relève.",
     "Allée des rois", "STONE", "POSTS", (1.3, 0.45)),
]

# Statue de Devlyn, au rond-point du jardin : inscription gravée sur la face sud du socle, et son Readable devant.
STATUE = ("Statue", 42.0, -67.4, 0.0, "La statue de Devlyn",
          "« À Devlyn, vainqueur des Quatre Dragons du Chaos, an 5802. » Le royaume la fit dresser après la bataille, quand chacun croyait la paix revenue pour toujours. Deux ans plus tard, Vibelandia déclarait la guerre.")

# Stèle du mémorial : texte gravé sur la face est de l'obélisque du cimetière, et son Readable devant.
MEMORIAL = ("Memorial", -44.0, -36.0, 90.0, "Le mémorial des soldats",
            "Aux soldats de Codia, tombés face aux armées de Vibelandia, de 5804 à 5812. Leurs noms se sont effacés de la pierre ; leur courage, lui, ne s'efface pas.")


def ext(identifier):
    return f'ExtResource("{identifier}")'


def quote(text):
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def node(lines, name, kind=None, parent=".", instance=None, props=()):
    head = f'[node name="{name}"'
    if kind:
        head += f' type="{kind}"'
    if parent is not None:
        head += f' parent="{parent}"'
    if instance:
        head += f" instance={ext(instance)}"
    lines += [head + "]", *props, ""]


def sign(lines, name, parent, text, style="WOOD", mount="POSTS", size=(1.3, 0.6), height=None, transform=None,
         line=0.15, serif=True, double=False, roof=False, collision=True):
    styles = {"WOOD": 0, "STONE": 1, "PARCHMENT": 2, "IRON": 3}
    mounts = {"POSTS": 0, "WALL": 1, "HANGING": 2}
    if height is None:
        height = {"POSTS": 1.25, "WALL": 2.5, "HANGING": 2.2}[mount]
    props = [transform or "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0)", f'script = {ext("12_sign")}',
             f"text = {quote(text)}", f"style = {styles[style]}", f"mount = {mounts[mount]}",
             f"board_size = Vector2({size[0]:g}, {size[1]:g})", f"board_height = {height:g}", f"line_height = {line:g}"]
    if not serif:
        props.append("serif = false")
    if double:
        props.append("double_sided = true")
    if roof:
        props.append("roof = true")
    if not collision:
        props.append("collision = false")
    node(lines, name, "Node3D", parent, props=props)


def engraved(lines, name, parent, text, transform, pixel=0.004, color="Color(0.16, 0.14, 0.12, 1)", font=64, width=None):
    """Inscription gravée : un Label3D collé à sa surface, éclairé comme elle, sans halo ni contour."""
    props = [transform, f"pixel_size = {pixel:g}", "shaded = true", "double_sided = false", "alpha_cut = 1",
             f"modulate = {color}", f"text = {quote(text)}", f"font_size = {font}", "outline_size = 0"]
    if width:
        props += [f"width = {width:g}", "autowrap_mode = 3"]
    node(lines, name, "Label3D", parent, props=props)


def characters(lines):
    node(lines, "Characters", "Node3D")
    for name, model, x, z, yaw, scale, title, body, prompt, pose, y in CHARACTERS:
        base = f"Characters/{name}"
        node(lines, name, "Node3D", "Characters", props=[
            at(x, y, z, 1.0, yaw), f'script = {ext("10_readable")}',
            f"title = {quote(title)}", f"body = {quote(body)}", f"prompt = {quote(prompt)}", "radius = 3.0",
            f'metadata/pose = "{pose}"'])
        node(lines, "Model", parent=base, instance=model, props=[at(0, 0, 0, scale)])
        node(lines, "Body", "StaticBody3D", base)
        node(lines, "CollisionShape3D", "CollisionShape3D", f"{base}/Body", props=[
            "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0)", 'shape = SubResource("CylinderShape3D_character")'])

    def attach(character, bone, scale, origin, yaw=0.0):
        """Repère accroché à un os du personnage : renvoie le chemin de son nœud Gear."""
        skeleton = f"Characters/{character}/Model/character-human/Skeleton3D"
        label = {"head": "Head", "torso": "Torso", "arm-left": "Hand"}[bone]
        node(lines, label, "BoneAttachment3D", skeleton, props=[f'bone_name = "{bone}"', f"bone_idx = {BONES[bone]}"])
        node(lines, "Gear", "Node3D", f"{skeleton}/{label}", props=[gear(origin, yaw, scale)])
        return f"{skeleton}/{label}/Gear"

    def mesh(name, mesh_id, parent, basis=IDENTITY, origin=(0, 0, 0)):
        node(lines, name, "MeshInstance3D", parent, props=[tf(basis, origin), f'mesh = SubResource("{mesh_id}")'])

    # Merlon le mage : longue robe, chapeau pointu posé sur le crâne, barbe blanche taillée en blocs comme la tête du
    # modèle : elle enveloppe la mâchoire et les joues, puis tombe en trois gradins sur la robe ; bâton à orbe tenu dans
    # la main gauche. Mesures de la tête (modèle à l'échelle 2,5, vues orthographiques) : un cube de x = -0,40 à 0,40 et
    # de z = -0,40 à 0,41, du menton (0,85 m) au haut du crâne (1,525 m), la bouche vers 1,03 m.
    node(lines, "Wizard", "Node3D", "Characters/Merlon")
    mesh("Robe", "CylinderMesh_robe", "Characters/Merlon/Wizard", origin=(0, 0.5, 0.02))
    head = attach("Merlon", "head", 2.5, HEAD_BONE)
    mesh("Brim", "CylinderMesh_brim", head, origin=(0, 1.545, 0.05))
    mesh("Band", "CylinderMesh_band", head, origin=(0, 1.625, 0.05))
    mesh("Hat", "CylinderMesh_hat", head, origin=(0, 2.155, 0.05))
    # Mâchoire : de 0,79 à 1,06 m, de z = -0,1 (les joues) à 0,52 (devant le menton), un peu plus large que la tête.
    mesh("BeardJaw", "BoxMesh_beard_jaw", head, origin=(0, 0.925, 0.21))
    # Gradins sur la robe, chacun enfoncé de 3 cm dans le précédent et dans le devant de la robe (qui s'évase vers le bas).
    mesh("BeardTail1", "BoxMesh_beard_tail1", head, origin=(0, 0.7, 0.55))
    mesh("BeardTail2", "BoxMesh_beard_tail2", head, origin=(0, 0.52, 0.575))
    mesh("BeardTail3", "BoxMesh_beard_tail3", head, origin=(0, 0.36, 0.6))
    for side in (-1, 1):
        mesh("Mustache" + ("Left" if side > 0 else "Right"), "CapsuleMesh_mustache", head,
             mul(rot_y(side * 14.0), rot_z(-side * 105.0)), (side * 0.15, 1.07, 0.55))
    hand = attach("Merlon", "arm-left", 2.5, *ARM_LEFT_HOLD)
    mesh("Staff", "CylinderMesh_staff", hand, origin=(0.47, 1.25, 0.47))
    mesh("Orb", "SphereMesh_orb", hand, origin=(0.47, 2.6, 0.47))
    node(lines, "OrbLight", "OmniLight3D", hand, props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.47, 2.6, 0.47)", "light_color = Color(0.65, 0.45, 1, 1)",
        "light_energy = 1.4", "omni_range = 4.0"])
    node(lines, "MerlonLight", "OmniLight3D", "Characters/Merlon", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 2.2, 0.9)", "light_color = Color(0.6, 0.45, 1, 1)",
        "light_energy = 1.0", "omni_range = 4.0"])

    # Le roi Codeon V : couronne carrée comme sa tête (un cube de ±0,39 m, haut du crâne à 1,47 m à l'échelle 2,4),
    # enfoncée sur le haut du crâne de 1,33 à 1,57 m, ses faces à 3 cm de celles de la tête ; trois fleurons par face.
    # Col d'hermine et cape au torse, sceptre dans la main gauche.
    head = attach("Codeon", "head", 2.4, HEAD_BONE)
    mesh("Crown", "CylinderMesh_crown", head, rot_y(45.0), (0, 1.45, 0.0))
    for face in range(4):
        yaw = face * 90.0
        nx, nz = math.sin(math.radians(yaw)), math.cos(math.radians(yaw))
        for index, offset in enumerate((-0.27, 0.0, 0.27)):
            tall = 1.3 if offset == 0.0 else 1.0
            mesh(f"Spike{face * 3 + index}", "PrismMesh_crown_spike", head, scaled(rot_y(yaw), 1.0, tall, 1.0),
                 (nx * 0.42 + nz * offset, 1.57 + 0.11 * tall - 0.02, nz * 0.42 - nx * offset))
    mesh("Jewel", "SphereMesh_jewel", head, origin=(0, 1.45, 0.45))
    torso = attach("Codeon", "torso", 2.4, TORSO_BONE)
    mesh("Collar", "CylinderMesh_collar", torso, origin=(0, 0.86, 0.0))
    mesh("Cape", "BoxMesh_cape", torso, origin=(0, 0.47, -0.44))
    hand = attach("Codeon", "arm-left", 2.4, *ARM_LEFT_HOLD)
    mesh("Scepter", "CylinderMesh_scepter", hand, origin=(0.45, 0.95, 0.45))
    mesh("ScepterTop", "SphereMesh_scepter", hand, origin=(0.45, 1.6, 0.45))

    node(lines, "Spots", "Node3D")
    for name, (x, z, yaw, y) in OUTSIDE.items():
        node(lines, name + "Outside", "Marker3D", "Spots", props=[at(x, y, z, 1.0, yaw)])


def hall(lines):
    """Salle du trône, dans le donjon : dallage, plafond à poutres, trône au fond, et l'ancien cercle magique au milieu,
    entouré des quatre piédestaux. Ses lettres s'illuminent livre après livre."""
    node(lines, "Castle", "Node3D", props=[f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, {HALL_Z:g})"])
    node(lines, "Floor", "StaticBody3D", "Castle")
    node(lines, "Mesh", "MeshInstance3D", "Castle/Floor", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.05, 0)", 'mesh = SubResource("BoxMesh_hall_floor")'])
    node(lines, "Shape", "CollisionShape3D", "Castle/Floor", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.05, 0)", 'shape = SubResource("BoxShape3D_hall_floor")'])
    node(lines, "Ceiling", "MeshInstance3D", "Castle", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 9.2, 0)", 'mesh = SubResource("BoxMesh_hall_ceiling")'])
    for index, x in enumerate((-7.5, -2.5, 2.5, 7.5)):
        node(lines, f"Beam{index}", "MeshInstance3D", "Castle", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, 8.7, 0)", 'mesh = SubResource("BoxMesh_beam")'])
    node(lines, "Throne", "StaticBody3D", "Castle", props=[at(THRONE_X, 0.0, CIRCLE[1], 1.0, 90.0)])
    for name, mesh, x, y, z in (("Dais", "dais", 0, 0.15, 0), ("Seat", "throne_seat", 0, 0.6, 0.1), ("Back", "throne_back", 0, 1.7, -0.5),
                                ("ArmLeft", "throne_frame", -0.9, 0.9, 0.05), ("ArmRight", "throne_frame", 0.9, 0.9, 0.05),
                                ("Crest", "throne_crest", 0, 3.2, -0.5)):
        node(lines, name, "MeshInstance3D", "Castle/Throne", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, {z:g})", f'mesh = SubResource("BoxMesh_{mesh}")'])
    # L'estrade et le trône ont chacun leur collision : on peut monter sur l'estrade à côté du trône.
    node(lines, "Shape", "CollisionShape3D", "Castle/Throne", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.675, 0.05)", 'shape = SubResource("BoxShape3D_throne")'])
    node(lines, "DaisShape", "CollisionShape3D", "Castle/Throne", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.15, 0)", 'shape = SubResource("BoxShape3D_dais")'])

    # Le cercle : trois anneaux incrustés dans le dallage, des rayons qui mènent aux piédestaux, et les noms des quatre
    # livres gravés lettre par lettre entre les anneaux. Chaque quart s'illumine quand son livre est posé.
    cx, cz = CIRCLE
    node(lines, "Circle", "Node3D", "Castle", props=[f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {cx:g}, 0.105, {cz:g})"])
    for name, mesh in (("Outer", "TorusMesh_circle_outer"), ("Inner", "TorusMesh_circle_inner"), ("Heart", "TorusMesh_circle_heart")):
        node(lines, name, "MeshInstance3D", "Castle/Circle", props=[tf(scaled(IDENTITY, 1.0, 0.08, 1.0)), f'mesh = SubResource("{mesh}")'])
    for zone, angle in PEDESTAL_ANGLES.items():
        rad = math.radians(angle)
        node(lines, f"Spoke{zone.capitalize()}", "MeshInstance3D", "Castle/Circle", props=[
            tf(rot_y(90.0 - angle), (math.cos(rad) * (4.08 + 5.38) / 2, 0.0, math.sin(rad) * (4.08 + 5.38) / 2)),
            'mesh = SubResource("BoxMesh_circle_spoke")'])
    for zone, angle in PEDESTAL_ANGLES.items():
        name = zone.capitalize()
        group = f"Castle/Circle/{name}"
        node(lines, name, "Node3D", "Castle/Circle")
        title = BOOK_TITLES[zone]
        span = 70.0
        for index, letter in enumerate(title):
            # Lettres de gauche à droite pour qui regarde le cercle depuis son piédestal, le haut vers le centre.
            a = angle + span / 2 - span * (index + 0.5) / len(title)
            rad = math.radians(a)
            basis = mul(rot_y(90.0 - a), rot_x(-90.0))
            node(lines, f"Letter{index}", "Label3D", group, props=[
                tf(basis, (math.cos(rad) * LETTER_RADIUS, 0.012, math.sin(rad) * LETTER_RADIUS)), "pixel_size = 0.0065",
                "shaded = true", "double_sided = false", "alpha_cut = 1", "modulate = Color(0.22, 0.2, 0.19, 1)",
                f"text = {quote(letter)}", "font_size = 64", "outline_size = 0"])
        px, pz = math.cos(math.radians(angle)) * (LETTER_RADIUS + 0.2), math.sin(math.radians(angle)) * (LETTER_RADIUS + 0.2)
        node(lines, "Glow", "OmniLight3D", group, props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {px:g}, 0.5, {pz:g})", "visible = false",
            "light_color = Color(0.45, 0.7, 1, 1)", "light_energy = 1.2", "omni_range = 3.5"])
    node(lines, "RitualView", "Marker3D", "Castle", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -6.4, 6.6, 1.6)"])

    node(lines, "Inscription", "Node3D", "Castle", props=[
        f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 1.4, 0, {-HALL_HALF_DEPTH + 2.9:g})", f'script = {ext("10_readable")}',
        'title = "Le cercle des anciens bâtisseurs"',
        'body = "Gravé dans le mur du fond, face à la porte : « Quatre livres, quatre savoirs. Posés autour du cercle, ils rendront la vie à Codia. » Les piédestaux attendent le Projenomicon, l\'Algonicon, le Logiconomicon et le Codonomicon ; chacun posé illumine son nom dans le cercle, et le rituel ne pourra commencer qu\'une fois les quatre réunis."',
        'prompt = "Lire l\'inscription"', "radius = 3.0"])
    # Sur deux lignes, entre les colonnes du mur du fond (x = ±2,4) et sous la rangée haute du donjon (y = 4,4), plus
    # épaisse que celle du bas : sur une ligne à 4,4 m, le haut des lettres rentrait dedans et les colonnes le coupaient.
    # Brun foncé sur l'enduit clair, pour le contraste.
    engraved(lines, "Text", "Castle/Inscription", "QUATRE LIVRES,\nQUATRE SAVOIRS",
             f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -1.4, 3.7, {-2.9 + 0.012:g})", pixel=0.0055,
             color="Color(0.24, 0.15, 0.07, 1)")
    for name, x, z in (("LightWest", -6.0, -3.0), ("LightEast", 6.0, -3.0), ("LightDoor", 0.0, 3.5)):
        node(lines, name, "OmniLight3D", "Castle", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, 5.0, {z:g})", "light_color = Color(1, 0.75, 0.45, 1)",
            "light_energy = 2.6", "omni_range = 13.0"])
    node(lines, "Pedestals", "Node3D", "Castle")
    for name, zone, _, _, _, label in ZONES:
        x, z = pedestal_spot(zone)
        base = f"Castle/Pedestals/{name}"
        # Face +Z (celle du nom) tournée vers le centre du cercle, d'où on voit les quatre.
        node(lines, name, "Node3D", "Castle/Pedestals", props=[
            at(x, 0.1, z, 1.0, yaw_toward(CIRCLE[0] - x, CIRCLE[1] - z)),
            f'script = {ext("9_interactable")}', 'prompt = "Piédestal"', "radius = 4.0"])
        for part, mesh, y in (("Base", "BoxMesh_pedestal_base", 0.11), ("Pedestal", "BoxMesh_pedestal", 0.65), ("Top", "BoxMesh_pedestal_top", 1.14)):
            node(lines, part, "MeshInstance3D", base, props=[f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {y:g}, 0)", f'mesh = SubResource("{mesh}")'])
        # En haut du fût, juste sous le plateau : plus près des yeux. Le fût a été élargi (0,62 à 0,78 m) pour que le
        # plus long nom (Logiconomicon, 0,67 m) y tienne à cette taille ; sur l'ancien, même Codonomicon débordait.
        # Crème sur la pierre sombre, pour le contraste.
        engraved(lines, "Label", base, BOOK_TITLES[zone].capitalize(), "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.92, 0.402)",
                 pixel=0.00135, color="Color(0.97, 0.88, 0.62, 1)")
        node(lines, "Body", "StaticBody3D", base)
        node(lines, "CollisionShape3D", "CollisionShape3D", f"{base}/Body", props=[
            "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.65, 0)", 'shape = SubResource("BoxShape3D_pedestal")'])
        node(lines, "Book", "Node3D", base, props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.28, 0)", "visible = false"])
        node(lines, "Mesh", "MeshInstance3D", f"{base}/Book", props=[f'mesh = SubResource("BoxMesh_book_{name}")'])
        node(lines, "Glow", "OmniLight3D", f"{base}/Book", props=["light_energy = 1.0", "omni_range = 2.5"])


def lore(lines):
    node(lines, "Lore", "Node3D")
    for name, x, z, yaw, title, body, board, style, mount, size in LORE:
        node(lines, name, "Node3D", "Lore", props=[at(x, 0, z, 1.0, yaw), f'script = {ext("10_readable")}',
             f"title = {quote(title)}", f"body = {quote(body)}", f"prompt = {quote('Lire : ' + title)}", "radius = 2.6"])
        # Les enseignes murales sont fixées au-dessus de la porte, sur le mur voûté qui tient debout même en ruine.
        sign(lines, "Sign", f"Lore/{name}", board, style=style, mount=mount, size=size, roof=name == "NoticeBoard",
             line=0.13 if len(board) > 18 else 0.16, height=3.42 if mount == "WALL" else None)
    name, x, z, yaw, title, body = STATUE
    node(lines, name, "Node3D", "Lore", props=[at(x, 0, z, 1.0, yaw), f'script = {ext("10_readable")}',
         f"title = {quote(title)}", f"body = {quote(body)}", f"prompt = {quote('Lire : ' + title)}", "radius = 2.6"])
    # Le socle (2,34 m de côté) est centré à 2,6 m derrière le Readable : sa face sud est à 1,43 m. Son creux (1,2 m de
    # large, de 0,3 à 1,5 m de haut : le modèle commence 5 cm sous son origine) a son fond 0,3 m plus loin, à 1,73 m : l'inscription y est gravée, en lignes
    # courtes qui tiennent dans sa largeur. Collée à la face avant et dorée, elle flottait devant le creux, en
    # débordait et se lisait mal sur la pierre blanche.
    engraved(lines, "Text", f"Lore/{name}", "DEVLYN\nVAINQUEUR\nDES QUATRE\nDRAGONS\nDU CHAOS\n5802",
             "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.9, -1.718)", pixel=0.0019, color="Color(0.14, 0.12, 0.1, 1)")
    name, x, z, yaw, title, body = MEMORIAL
    node(lines, name, "Node3D", "Lore", props=[at(x, 0, z, 1.0, yaw), f'script = {ext("10_readable")}',
         f"title = {quote(title)}", f"body = {quote(body)}", f"prompt = {quote('Lire : ' + title)}", "radius = 2.6"])
    # L'obélisque (échelle 3,4) est centré à 1 m derrière le Readable. Son socle n'a que 0,32 m de haut ; au-dessus, le
    # fût s'amincit de 0,309 m (demi-côté) à 0,248 m à 1,51 m de haut : sa face penche de 2,96 degrés vers le centre.
    # Le texte est collé à 1,2 cm de la face, penché comme elle, et tient dans sa largeur (0,57 m à 0,8 m de haut).
    # Posé à 0,54 m du centre et droit, il flottait 25 cm devant la face et en dépassait sur le côté.
    height = 0.8
    half = 0.3094 - (height - 0.3196) * 0.0614 / 1.1866
    lean = math.atan(0.0614 / 1.1866)
    engraved(lines, "Text", f"Lore/{name}", "AUX SOLDATS\nDE CODIA\n5804 - 5812",
             f"transform = Transform3D(1, 0, 0, 0, {math.cos(lean):.5f}, {math.sin(lean):.5f}, 0, {-math.sin(lean):.5f}, "
             f"{math.cos(lean):.5f}, 0, {height:g}, {-(1.0 - half) + 0.012:.4f})", pixel=0.001, color="Color(0.14, 0.13, 0.12, 1)")


def portal_signs(lines):
    """Panneau de pierre au bord du chemin, quelques pas avant chaque portail, tourné vers le village."""
    node(lines, "PortalSigns", "Node3D")
    for name, zone, _, _, _, label in ZONES:
        x, z = PORTALS[zone]
        length = math.hypot(x, z)
        dx, dz = -x / length, -z / length
        side = (-dz, dx)
        px, pz = x + dx * 4.5 + side[0] * 2.7, z + dz * 4.5 + side[1] * 2.7
        sign(lines, name, "PortalSigns", label, style="STONE", size=(1.7, 0.55), line=0.14,
             transform=at(px, 0, pz, 1.0, yaw_toward(dx, dz)))


def main():
    lines = ["[gd_scene format=3]", ""]
    lines += [f'[ext_resource type="{kind}" path="{path}" id="{identifier}"]' for kind, path, identifier in EXT]
    lines += [SUBRESOURCES]
    for name, _, _, _, book, _ in ZONES:
        lines += [
            f'[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_book_{name}"]',
            f"albedo_color = {book}", "emission_enabled = true", f"emission = {book}",
            "emission_energy_multiplier = 1.5", "",
            f'[sub_resource type="BoxMesh" id="BoxMesh_book_{name}"]',
            f'material = SubResource("StandardMaterial3D_book_{name}")', "size = Vector3(0.55, 0.14, 0.75)", "",
        ]
    lines += ['[node name="Hub" type="Node3D"]', 'script = ExtResource("1_hub")', ""]
    node(lines, "WorldEnvironment", "WorldEnvironment", props=['environment = SubResource("Environment_hub")'])
    node(lines, "Sun", "DirectionalLight3D", props=[
        "transform = Transform3D(0.866025, -0.25, 0.433013, 0, 0.866025, 0.5, -0.5, -0.433013, 0.75, 0, 40, 0)",
        "light_color = Color(1, 0.9, 0.78, 1)", "light_energy = 0.55", "shadow_enabled = true",
        "shadow_normal_bias = 4.0", "directional_shadow_mode = 1", "directional_shadow_split_1 = 0.2",
        "directional_shadow_max_distance = 50.0"])
    node(lines, "Terrain", "StaticBody3D", props=['script = ExtResource("2_terrain")', 'ground_material = SubResource("ShaderMaterial_ground")'])
    lines += [
        '[node name="Scatter" type="Node3D" parent="." node_paths=PackedStringArray("terrain")]',
        'script = ExtResource("3_scatter")',
        'terrain = NodePath("../Terrain")',
        'tree_models = Array[PackedScene]([ExtResource("20_tree_default"), ExtResource("21_tree_oak"), ExtResource("22_tree_fat"), ExtResource("23_tree_forest"), ExtResource("24_tree_high")])',
        'bush_models = Array[PackedScene]([ExtResource("25_bush"), ExtResource("26_bush_large")])',
        'rock_models = Array[PackedScene]([ExtResource("27_rock"), ExtResource("28_rocks")])',
        'flower_models = Array[PackedScene]([ExtResource("29_flower_red"), ExtResource("30_flower_yellow"), ExtResource("31_flower_purple")])',
        "",
        '[node name="River" type="Node3D" parent="." node_paths=PackedStringArray("terrain")]',
        'script = ExtResource("52_river")',
        'terrain = NodePath("../Terrain")',
        'water_material = SubResource("ShaderMaterial_river")',
        'pond_material = SubResource("ShaderMaterial_pond")',
        'reed_models = Array[PackedScene]([ExtResource("32_reed_a"), ExtResource("33_reed_b"), ExtResource("34_grass")])',
        'rock_models = Array[PackedScene]([ExtResource("35_stone_a"), ExtResource("36_stone_c"), ExtResource("37_stone_flat")])',
        'lily_models = Array[PackedScene]([ExtResource("38_lily_large"), ExtResource("39_lily_small")])',
        "",
    ]
    node(lines, "Props", instance="5_props")
    node(lines, "Campfire", "Node3D", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.3, 0)", 'script = ExtResource("11_fire")', "size = 2.0",
        "light_energy = 3.5", "light_range = 12.0", 'crackle_sound = ExtResource("41_crackle")', "crackle_volume_db = -4.0"])

    node(lines, "Portals", "Node3D")
    for name, zone, inner, outer, _, label in ZONES:
        x, z = PORTALS[zone]
        yaw = math.degrees(math.atan2(-x, -z))
        node(lines, name, parent="Portals", instance="6_portal", props=[
            at(x, 0, z, 1.0, yaw), f'closed_prompt = {quote(label + " : bientôt accessible")}',
            f'open_prompt = {quote("Entrer : " + label)}', f"inner_color = {inner}", f"outer_color = {outer}"])
    portal_signs(lines)

    hall(lines)
    characters(lines)
    lore(lines)
    node(lines, "Braziers", "Node3D")
    for index, (x, z) in enumerate(BRAZIERS):
        node(lines, f"Brazier{index}", "Node3D", "Braziers", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, 0.6, {z:g})", 'script = ExtResource("11_fire")', "size = 0.8",
            "light_energy = 2.0", "light_range = 8.0"])
    # Le bunker est un autre lieu, à l'est du village, au-delà de la rivière.
    node(lines, "Bunker", "Node3D", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 73.6, 1.2, 0)", 'script = ExtResource("9_interactable")',
        'prompt = "Descendre dans le bunker"', "radius = 3.5"])
    # Plaque de fer au-dessus de la porte, sur la façade ouest (sa face regarde le village).
    sign(lines, "BunkerSign", ".", "Bunker des survivants", style="IRON", mount="WALL", size=(1.9, 0.5), height=3.45,
         transform=at(73.74, 0, 0, 1.0, -90.0), line=0.16)
    node(lines, "BunkerOutside", "Marker3D", props=[at(70.6, 0.3, 0, 1.0, -90.0)])
    # Abri des survivants, sous le bunker : la partie commence ici.
    node(lines, "BunkerInterior", "Node3D", props=[f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {BUNKER_INSIDE[0]:g}, {BUNKER_INSIDE[1]:g}, {BUNKER_INSIDE[2]:g})"])
    node(lines, "Shelter", parent="BunkerInterior", instance="51_bunker")
    # Planche pleine au-dessus du plafond de planches (de 4 à 4,24 m), de mur à mur : entre les planches, on voit du
    # bois sombre, et rien de ce qui est au-dessus.
    node(lines, "CeilingCover", "MeshInstance3D", "BunkerInterior", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 4.45, 0)", 'mesh = SubResource("BoxMesh_bunker_cover")'])
    node(lines, "Spawn", "Marker3D", "BunkerInterior", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.3, 4.2)"])
    node(lines, "Exit", "Node3D", "BunkerInterior", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.2, 5.6)", 'script = ExtResource("9_interactable")',
        'prompt = "Remonter à la surface"', "radius = 2.4"])
    for name, x, z, energy in (("LightNorth", -4.0, -3.0, 2.2), ("LightSouth", 4.0, 2.5, 2.0), ("LightTable", -5.6, 2.0, 1.4)):
        node(lines, name, "OmniLight3D", "BunkerInterior", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, 3.2, {z:g})",
            "light_color = Color(1, 0.74, 0.46, 1)", f"light_energy = {energy:g}", "omni_range = 10.0"])
    # Plan large sur le village, le temps de le voir se reconstruire quand un livre est posé.
    node(lines, "RepairCamera", "Camera3D", props=[
        "transform = Transform3D(1, 0, 0, 0, 0.819152, 0.573576, 0, -0.573576, 0.819152, 6, 38, 56)", "fov = 72.0", "far = 450.0"])
    # Le Mont Sam Altan, au nord, au-delà des montagnes : il domine le hub pendant toute la partie.
    node(lines, "Volcano", "Node3D", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 20, -4, -215)", 'script = ExtResource("47_volcano")'])
    lines += [
        '[node name="Ending" type="Node3D" parent="." node_paths=PackedStringArray("volcano", "terrain")]',
        'script = ExtResource("48_ending")', 'volcano = NodePath("../Volcano")', 'terrain = NodePath("../Terrain")',
        'eruption_sound = ExtResource("50_eruption")', 'flood_material = SubResource("ShaderMaterial_flood")', ""]
    node(lines, "DefaultSpawn", "Marker3D", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.3, 12)"])
    node(lines, "Player", instance="7_player", props=[
        at(0, 0.3, 12), "respawn_height = -80.0", "first_person = true",
        'footstep_sounds = Array[AudioStream]([ExtResource("42_grass1"), ExtResource("43_grass2"), ExtResource("44_grass3")])'])
    node(lines, "PlaceSound", "AudioStreamPlayer", props=['stream = ExtResource("45_chime")', "volume_db = -2.0"])
    node(lines, "RepairSound", "AudioStreamPlayer", props=['stream = ExtResource("46_rumble")', "volume_db = -4.0"])
    node(lines, "TremorSound", "AudioStreamPlayer", props=['stream = ExtResource("46_rumble")', "volume_db = -9.0", "pitch_scale = 0.6"])
    node(lines, "Ambience", "AudioStreamPlayer", props=['stream = ExtResource("40_ambience")', "volume_db = -8.0", "autoplay = true"])
    # Eau de la rivière, feuillage et oiseaux du jardin du roi, roue du moulin : des sources dans l'espace, qui suivent
    # l'auditeur et les livres posés (hub_sounds.gd).
    node(lines, "Sounds", "Node3D", props=['script = ExtResource("54_sounds")'])
    node(lines, "Hud", instance="8_hud")
    # Les apparats du roi et de Merlon sont accrochés aux os de leur modèle importé. Sans ces marqueurs
    # (« enfants modifiables »), l'export, qui convertit la scène en binaire, les perd : le jeu en ligne les montrait
    # sans couronne, cape, sceptre, chapeau, barbe ni bâton.
    for character in ("Merlon", "Codeon"):
        lines += [f'[editable path="Characters/{character}/Model"]', ""]
    out = FRONTEND / "scenes" / "levels" / "hub" / "hub.tscn"
    out.write_text("\n".join(lines).rstrip("\n") + "\n", encoding="utf-8", newline="\n")
    print(out.name, len(lines), "lignes")


if __name__ == "__main__":
    main()
