"""Écrit frontend/scenes/levels/marais/marais.tscn : les marais de Kernel Swamp et la crypte du gardien.

Usage : python write_marais_tscn.py <dossier frontend>
Les objets fixes viennent de tools/build_marais.py (marais_props, marais_grounded, marais_crypt) ; ce script pose
le reste : lumières, textes et indices, tombeaux de jeu, mécanisme, niches de l'ossuaire, feux follets.
"""
import math
import sys
from pathlib import Path

FRONTEND = Path(sys.argv[1])
K = "res://assets/models/kenney/"
EXT = [
    ("Script", "res://scenes/levels/marais/marais.gd", "1_marais"),
    ("Script", "res://scenes/levels/marais/marais_terrain.gd", "2_terrain"),
    ("Script", "res://scenes/levels/marais/marais_scatter.gd", "3_scatter"),
    ("Shader", "res://scenes/levels/marais/marais_ground.gdshader", "4_ground"),
    ("Shader", "res://scenes/levels/marais/swamp_water.gdshader", "5_water"),
    ("PackedScene", "res://scenes/levels/marais/marais_props.tscn", "6_props"),
    ("PackedScene", "res://scenes/levels/marais/marais_grounded.tscn", "7_grounded"),
    ("PackedScene", "res://scenes/props/portal/portal.tscn", "8_portal"),
    ("PackedScene", "res://scenes/player/player.tscn", "9_player"),
    ("PackedScene", "res://scenes/ui/hud.tscn", "10_hud"),
    ("Script", "res://scripts/interactable.gd", "11_interactable"),
    ("Script", "res://scripts/readable.gd", "12_readable"),
    ("Script", "res://scripts/fire_effect.gd", "13_fire"),
    ("Script", "res://scripts/flickering_light.gd", "14_flicker"),
    ("PackedScene", K + "graveyard_kit/crypt-large-door.glb", "15_door"),
    ("PackedScene", K + "graveyard_kit/character-ghost.glb", "16_ghost"),
    ("Script", "res://scripts/sign_board.gd", "17_sign"),
    ("Shader", "res://scenes/levels/marais/moss_overlay.gdshader", "18_moss"),
    ("Script", "res://scenes/levels/marais/will_o_wisps.gd", "19_wisps"),
    ("PackedScene", K + "graveyard_kit/pine-crooked.glb", "20_pine_crooked"),
    ("PackedScene", K + "graveyard_kit/pine.glb", "21_pine"),
    ("PackedScene", K + "nature_kit/tree_thin_dark.glb", "22_tree_thin"),
    ("PackedScene", K + "nature_kit/tree_default_dark.glb", "23_tree_default"),
    ("PackedScene", K + "nature_kit/crops_bambooStageB.glb", "24_reed"),
    ("PackedScene", K + "nature_kit/lily_large.glb", "25_lily_large"),
    ("PackedScene", K + "nature_kit/lily_small.glb", "26_lily_small"),
    ("PackedScene", K + "nature_kit/plant_bushLarge.glb", "27_bush"),
    ("PackedScene", K + "nature_kit/mushroom_redGroup.glb", "28_mushroom"),
    ("PackedScene", K + "nature_kit/log_large.glb", "29_log"),
    ("PackedScene", K + "nature_kit/path_wood.glb", "30_plank"),
    ("PackedScene", K + "graveyard_kit/trunk-long.glb", "31_post"),
    ("PackedScene", K + "graveyard_kit/lightpost-single.glb", "32_lantern"),
    ("PackedScene", K + "nature_kit/flower_purpleA.glb", "33_flower_purple"),
    ("PackedScene", K + "nature_kit/flower_redA.glb", "34_flower_red"),
    ("PackedScene", K + "nature_kit/flower_yellowA.glb", "35_flower_yellow"),
    ("PackedScene", K + "mini_dungeon/weapon-sword.glb", "36_sword"),
    ("PackedScene", "res://scenes/levels/marais/marais_crypt.tscn", "50_crypt"),
    ("Script", "res://scenes/levels/marais/ring_mechanism.gd", "51_mechanism"),
    ("PackedScene", "res://scenes/levels/marais/ring_puzzle.tscn", "52_puzzle"),
    ("AudioStream", "res://assets/audio/cave_ambience.wav", "53_crypt_sound"),
    ("AudioStream", "res://assets/audio/tablet_reset.wav", "54_reject"),
    ("AudioStream", "res://assets/audio/footstep_ash_1.wav", "55_stone1"),
    ("AudioStream", "res://assets/audio/footstep_ash_2.wav", "56_stone2"),
    ("AudioStream", "res://assets/audio/footstep_ash_3.wav", "57_stone3"),
    ("AudioStream", "res://assets/audio/marais_ambience.wav", "40_ambience"),
    ("AudioStream", "res://assets/audio/stone_door.wav", "41_door_sound"),
    ("AudioStream", "res://assets/audio/fire_crackle.wav", "42_crackle"),
    ("AudioStream", "res://assets/audio/footstep_mud_1.wav", "43_mud1"),
    ("AudioStream", "res://assets/audio/footstep_mud_2.wav", "44_mud2"),
    ("AudioStream", "res://assets/audio/footstep_mud_3.wav", "45_mud3"),
    ("AudioStream", "res://assets/audio/footstep_splash_1.wav", "46_splash1"),
    ("AudioStream", "res://assets/audio/footstep_splash_2.wav", "47_splash2"),
    ("AudioStream", "res://assets/audio/footstep_splash_3.wav", "48_splash3"),
    ("Script", "res://scenes/levels/hub/volcano.gd", "90_volcano"),
    ("Shader", "res://scenes/levels/marais/swamp_fog.gdshader", "37_fog"),
    ("AudioStream", "res://assets/audio/stream.wav", "38_lapping"),
    ("AudioStream", "res://assets/audio/plaine_wind.wav", "39_wind"),
    ("Shader", "res://scenes/levels/marais/reeds_sway.gdshader", "58_reeds"),
    ("Script", "res://scenes/levels/marais/marais_life.gd", "59_life"),
    ("PackedScene", K + "survival_kit/fish-large.glb", "60_fish"),
    ("PackedScene", K + "graveyard_kit/lantern-candle.glb", "61_hanging_lantern"),
]
# Pierres levées (comme build_stones dans tools/build_marais.py) : les corbeaux se posent sur trois d'entre elles.
STONE_TOPS = [(-30.0 + math.cos(math.tau * i / 7 + 0.3) * 2.7, -44.0 + math.sin(math.tau * i / 7 + 0.3) * 2.7) for i in (0, 2, 5)]
# Sons posés dans le monde : nom, son, position, volume (dB), hauteur de son, taille et portée.
SOUNDS = [
    # Clapotis sous les pontons, un par ponton.
    ("LapWalk1", "38_lapping", (-10.5, 0.1, 37.5), -16.0, 0.7, 3.0, 16.0),
    ("LapWalk2", "38_lapping", (-5.0, 0.1, 11.5), -16.0, 0.62, 3.0, 16.0),
    ("LapWalk3", "38_lapping", (5.8, 0.1, -19.0), -16.0, 0.78, 3.0, 16.0),
    ("LapJetty", "38_lapping", (12.5, 0.1, 50.0), -18.0, 0.66, 2.5, 12.0),
    # Grenouilles et grillons dans les roseaux, du village englouti aux berges de l'ouest.
    ("FrogsVillage", "40_ambience", (20.0, 0.3, 30.0), -9.0, 1.08, 6.0, 30.0),
    ("FrogsWest", "40_ambience", (-30.0, 0.3, 14.0), -10.0, 0.94, 6.0, 30.0),
    ("FrogsNorth", "40_ambience", (14.0, 0.3, -24.0), -11.0, 1.15, 5.0, 26.0),
    # Le vent siffle dans la chapelle en ruine.
    ("ChapelWind", "39_wind", (-36.0, 3.0, -4.0), -9.0, 0.85, 6.0, 30.0),
    # Gouttes dans la crypte : l'ossuaire, la chambre des gardiens, la salle du mécanisme.
    ("DripOssuary", "53_crypt_sound", (-18.0, -38.0, 2.0), -12.0, 1.25, 3.0, 14.0),
    ("DripGuards", "53_crypt_sound", (18.0, -38.0, 2.0), -12.0, 1.1, 3.0, 14.0),
    ("DripHall", "53_crypt_sound", (-6.0, -37.0, -20.0), -13.0, 1.35, 3.0, 14.0),
]

SUBRESOURCES = """
[sub_resource type="ProceduralSkyMaterial" id="ProceduralSkyMaterial_night"]
sky_top_color = Color(0.03, 0.045, 0.07, 1)
sky_horizon_color = Color(0.13, 0.17, 0.17, 1)
ground_bottom_color = Color(0.03, 0.04, 0.04, 1)
ground_horizon_color = Color(0.13, 0.17, 0.17, 1)

[sub_resource type="Sky" id="Sky_night"]
sky_material = SubResource("ProceduralSkyMaterial_night")

[sub_resource type="Environment" id="Environment_marais"]
background_mode = 2
sky = SubResource("Sky_night")
ambient_light_source = 3
ambient_light_color = Color(0.42, 0.52, 0.5, 1)
ambient_light_energy = 0.7
tonemap_mode = 2
glow_enabled = true
glow_intensity = 0.7
glow_bloom = 0.06
glow_hdr_threshold = 0.9
fog_enabled = true
fog_light_color = Color(0.17, 0.22, 0.21, 1)
fog_density = 0.034
fog_sky_affect = 0.7

[sub_resource type="ShaderMaterial" id="ShaderMaterial_ground"]
render_priority = 0
shader = ExtResource("4_ground")

[sub_resource type="FastNoiseLite" id="FastNoiseLite_ripples"]
seed = 9
frequency = 0.02
fractal_octaves = 3

[sub_resource type="NoiseTexture2D" id="NoiseTexture2D_ripples"]
width = 256
height = 256
seamless = true
noise = SubResource("FastNoiseLite_ripples")

[sub_resource type="ShaderMaterial" id="ShaderMaterial_water"]
render_priority = 0
shader = ExtResource("5_water")
shader_parameter/ripple_noise = SubResource("NoiseTexture2D_ripples")

[sub_resource type="PlaneMesh" id="PlaneMesh_water"]
material = SubResource("ShaderMaterial_water")
size = Vector2(180, 180)

[sub_resource type="ShaderMaterial" id="ShaderMaterial_moss"]
render_priority = 1
shader = ExtResource("18_moss")

[sub_resource type="ShaderMaterial" id="ShaderMaterial_dust"]
render_priority = 1
shader = ExtResource("18_moss")
shader_parameter/moss_color = Color(0.55, 0.52, 0.47, 1)
shader_parameter/damp_color = Color(0.4, 0.38, 0.35, 1)
shader_parameter/coverage = 0.55
shader_parameter/damp_amount = 0.0

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_book"]
albedo_color = Color(0.1, 0.35, 0.25, 1)
emission_enabled = true
emission = Color(0.3, 1, 0.55, 1)
emission_energy_multiplier = 1.2

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_tomb"]
albedo_color = Color(0.4, 0.39, 0.37, 1)
roughness = 1.0

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_tomb_dark"]
albedo_color = Color(0.27, 0.26, 0.25, 1)
roughness = 1.0

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_gold"]
albedo_color = Color(0.92, 0.76, 0.36, 1)
cull_mode = 2
metallic = 0.7
roughness = 0.35

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_journal"]
albedo_color = Color(0.32, 0.17, 0.09, 1)
roughness = 0.9

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_niche_back"]
albedo_color = Color(0.18, 0.17, 0.16, 1)
roughness = 1.0

[sub_resource type="BoxMesh" id="BoxMesh_tomb"]
material = SubResource("StandardMaterial3D_tomb")
size = Vector3(1.8, 1.0, 3.0)

[sub_resource type="BoxMesh" id="BoxMesh_lid"]
material = SubResource("StandardMaterial3D_tomb")
size = Vector3(2.0, 0.2, 3.2)

[sub_resource type="BoxMesh" id="BoxMesh_plinth"]
material = SubResource("StandardMaterial3D_tomb_dark")
size = Vector3(2.2, 0.16, 3.4)

[sub_resource type="BoxMesh" id="BoxMesh_band"]
material = SubResource("StandardMaterial3D_tomb_dark")
size = Vector3(1.86, 0.12, 3.06)

[sub_resource type="BoxShape3D" id="BoxShape3D_tomb"]
size = Vector3(2.2, 1.0, 3.4)

[sub_resource type="BoxShape3D" id="BoxShape3D_lid"]
size = Vector3(2.0, 0.2, 3.2)

[sub_resource type="BoxShape3D" id="BoxShape3D_king"]
size = Vector3(2.2, 1.2, 3.4)

[sub_resource type="CylinderMesh" id="CylinderMesh_crown"]
material = SubResource("StandardMaterial3D_gold")
top_radius = 0.17
bottom_radius = 0.16
height = 0.08
radial_segments = 14
cap_top = false
cap_bottom = false

[sub_resource type="PrismMesh" id="PrismMesh_crown_point"]
material = SubResource("StandardMaterial3D_gold")
size = Vector3(0.08, 0.11, 0.025)

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_velvet"]
albedo_color = Color(0.36, 0.06, 0.08, 1)
roughness = 1.0

[sub_resource type="BoxMesh" id="BoxMesh_cushion"]
material = SubResource("StandardMaterial3D_velvet")
size = Vector3(0.5, 0.07, 0.5)

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_iron"]
albedo_color = Color(0.16, 0.16, 0.18, 1)
roughness = 0.6

[sub_resource type="BoxMesh" id="BoxMesh_chain"]
material = SubResource("StandardMaterial3D_iron")
size = Vector3(0.03, 2.4, 0.03)

[sub_resource type="BoxMesh" id="BoxMesh_hatch"]
material = SubResource("StandardMaterial3D_tomb_dark")
size = Vector3(2.2, 0.12, 1.8)

[sub_resource type="BoxMesh" id="BoxMesh_book"]
material = SubResource("StandardMaterial3D_book")
size = Vector3(0.6, 0.14, 0.8)

[sub_resource type="BoxMesh" id="BoxMesh_journal"]
material = SubResource("StandardMaterial3D_journal")
size = Vector3(0.36, 0.07, 0.5)

[sub_resource type="ShaderMaterial" id="ShaderMaterial_fog_low"]
render_priority = 0
shader = ExtResource("37_fog")
shader_parameter/noise_tex = SubResource("NoiseTexture2D_ripples")
shader_parameter/density = 0.34
shader_parameter/scale = 0.022
shader_parameter/drift = Vector2(0.009, 0.004)

[sub_resource type="ShaderMaterial" id="ShaderMaterial_fog_high"]
render_priority = 0
shader = ExtResource("37_fog")
shader_parameter/noise_tex = SubResource("NoiseTexture2D_ripples")
shader_parameter/fog_color = Color(0.6, 0.68, 0.68, 1)
shader_parameter/density = 0.16
shader_parameter/scale = 0.016
shader_parameter/drift = Vector2(-0.006, 0.007)
shader_parameter/near_fade = 7.0

[sub_resource type="PlaneMesh" id="PlaneMesh_fog_low"]
material = SubResource("ShaderMaterial_fog_low")
size = Vector2(150, 150)

[sub_resource type="PlaneMesh" id="PlaneMesh_fog_high"]
material = SubResource("ShaderMaterial_fog_high")
size = Vector2(150, 150)

[sub_resource type="Gradient" id="Gradient_moon"]
offsets = PackedFloat32Array(0, 0.42, 0.5, 1)
colors = PackedColorArray(1, 1, 1, 1, 0.95, 0.97, 1, 1, 0.7, 0.8, 0.95, 0.25, 0.6, 0.72, 0.9, 0)

[sub_resource type="GradientTexture2D" id="GradientTexture2D_moon"]
gradient = SubResource("Gradient_moon")
fill = 1
fill_from = Vector2(0.5, 0.5)
fill_to = Vector2(1, 0.5)

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_moon"]
transparency = 1
blend_mode = 1
shading_mode = 0
disable_fog = true
billboard_mode = 1
albedo_color = Color(1.25, 1.35, 1.5, 1)
albedo_texture = SubResource("GradientTexture2D_moon")

[sub_resource type="QuadMesh" id="QuadMesh_moon"]
material = SubResource("StandardMaterial3D_moon")
size = Vector2(38, 38)

[sub_resource type="ShaderMaterial" id="ShaderMaterial_reeds"]
render_priority = 0
shader = ExtResource("58_reeds")
"""

# Indices de l'extérieur : nom, position du point d'interaction, titre, texte, invite, rayon.
CLUES = [
    ("Notebook", -19.8, 1.2, 25.9, "Journal du gardien, an 5803",
     "La crypte garde l'un des livres anciens. Son tombeau ne s'ouvre que si l'on inscrit, sur le mécanisme "
     "des cinq cercles, le nom du royaume transformé selon la règle gravée au mur. Je l'ai noté ici pour ne jamais l'oublier… "
     "et j'ai arraché la page le lendemain.", "Lire le journal", 2.2),
    ("KeeperTomb", 22.15, 1.6, 1.5, "Tombe du gardien",
     "Ci-gît Aldric, gardien du marais. Né en 5761, mort en 5803. Même la mort ne lui a pas fait quitter son poste.",
     "Lire l'épitaphe", 3.0),
    ("AdaTomb", 10.5, 1.1, 5.85, "Une tombe usée",
     "Ici repose Ada, qui cachait ses lettres en décalant l'alphabet.", "Lire l'épitaphe", 2.2),
    ("Ghost", 19.0, 1.6, 3.6, "Le fantôme du gardien",
     "Tu cherches le livre, voyageur ? Il dort dans la crypte, au nord. Le mécanisme réclame le nom de notre royaume, "
     "mais jamais tel quel : lis bien ce qui est gravé au mur.", "Parler au fantôme", 3.6),
    ("Plaque", -4.0, 1.25, -34.05, "Plaque de la crypte",
     "Crypte du gardien. Ceux qui descendent doivent savoir dans quel royaume ils se trouvent.", "Lire la plaque", 2.8),
    ("Welcome", -4.4, 1.3, 53.25, "Les marais de Kernel Swamp",
     "Ici vivaient les pêcheurs de Brumeval. Quand la guerre contre Vibelandia a brisé les digues, l'eau a englouti "
     "le village ; seuls ses toits sortent encore de la brume. Au nord, au bout des pontons, la crypte du gardien "
     "veille sur les tombeaux des premiers rois de Codia.", "Lire le panneau", 2.6),
    # Récit des marais : l'avis du port au débarcadère, la leçon d'Ada au cimetière, l'ordre du roi devant la crypte.
    ("Notice", 3.6, 1.3, 53.0, "Avis de la capitainerie, an 5807",
     "Par ordre du capitaine du port de Brumeval. Les soldats de Vibelandia ont ouvert les digues du nord, et l'eau "
     "monte chaque nuit. Que chaque famille charge ses barques et gagne le château avant la nouvelle lune ; ne prenez "
     "que le nécessaire. Personne ne s'abritera dans la crypte des rois : depuis la mort du gardien Aldric, nul ne sait "
     "plus l'ouvrir, et l'on dit que son fantôme veille encore au cimetière.", "Lire l'avis", 2.8),
    ("AdaSlate", 11.9, 1.3, 4.4, "L'ardoise d'Ada",
     "Ada apprenait aux enfants de Brumeval à cacher leurs messages. Pour chaque lettre, on avance ou l'on recule dans "
     "l'alphabet, et l'on change de sens à chaque lettre. Exemple, avec deux pas : B avance de deux et devient D, R "
     "recule de deux et devient P, U avance et devient W, M recule et devient K, E avance et devient G. Ainsi BRUME "
     "s'écrit DPWKG. Après Z, on repart de A ; avant A, on revient à Z. Pour relire, il suffit de refaire le chemin "
     "à l'envers.", "Lire l'ardoise", 2.8),
    ("RoyalOrder", 4.6, 1.3, -32.6, "Ordre du roi Codeon V, an 5812",
     "Codeon V, roi de Codia, à tous ceux qui vivent encore dans les marais. L'armée de Vibelandia marche sur le "
     "château. Rejoignez sans attendre le vieux refuge souterrain, près du château : ses portes se fermeront bientôt. "
     "Que personne ne force la crypte des rois. Le livre de la logique et du chiffrement y dort sous la garde de nos "
     "ancêtres, et seul celui qui sait dans quel royaume il se trouve pourra l'éveiller.", "Lire l'ordre du roi", 2.8),
]

# Épitaphes des quatre premiers rois : le nom du royaume, puis trois pas en avant, trois en arrière, et ainsi de suite.
EPITAPHS = [
    "Codeon I, le Fondateur. Il donna son nom au royaume de Codia, et c'est par ce nom que tout commence.",
    "Codeon II, le Hardi. Sous son règne, le royaume avança de trois pas vers la lumière.",
    "Codeon III, le Prudent. Là où son père avait avancé, il recula de trois pas, pour garder ce qui était acquis.",
    "Codeon IV, le Juste. Il reprit la marche en avant, de trois pas encore, puis ferma la mine d'argent. Son fils, Codeon V, règne aujourd'hui sur Codia.",
]
# Tombeaux des rois, de part et d'autre de l'allée de la chambre de l'ouest (z = -12), à 0,75 m des murs.
KINGS = ((-21.2, -8.95), (-26.8, -8.95), (-21.2, -15.05), (-26.8, -15.05))
# Niches de l'ossuaire : même liste que NICHES dans tools/build_marais.py (point de la façade, direction de la pièce).
WALL_FACE = 0.45
# Le panneau central des murs du kit avance jusqu'à 0,6 m du bord : les dalles gravées s'y posent devant.
PANEL_FACE = 0.63
# Panneaux muraux du récit : à 1 cm du panneau central du mur.
BOARD_FACE = 0.61
NICHES = (
    ((-10.0 + WALL_FACE, -8.0), (1, 0)), ((-10.0 + WALL_FACE, -16.0), (1, 0)),
    ((10.0 - WALL_FACE, -8.0), (-1, 0)), ((10.0 - WALL_FACE, -16.0), (-1, 0)),
    ((-18.0, 6.0 - WALL_FACE), (0, -1)), ((18.0, 6.0 - WALL_FACE), (0, -1)),
)
NICHE_WIDTH, NICHE_HEIGHT, NICHE_DEPTH = 2.4, 2.7, 0.9
NICHE_FLOOR, NICHE_SHELF = 0.55, 1.56
# Palier du haut du long escalier, sous la trappe (LANDING dans build_marais.py).
LANDING_Y = 4.05

INSCRIPTION = ("Pour ouvrir le tombeau, inscris le nom du royaume dans lequel tu te trouves. Puis, pour chaque lettre, "
               "alterne entre trois lettres en avant et trois lettres en arrière dans l'alphabet. Seul le nom ainsi "
               "transformé révélera le secret des anciens.")

OSSUARY_REGISTER = ("Ici reposent les bâtisseurs qui ont creusé la crypte sous le règne de Codeon I. Ils ont gravé "
                    "l'alphabet entier sur cinq cercles de pierre, un cercle par lettre du nom à inscrire : le premier "
                    "cercle, au centre, porte la première lettre, et le cinquième, au bord, la dernière. Le repère d'or, "
                    "au nord du mécanisme, montre la lettre choisie sur chaque cercle. Note du gardien : vérifier chaque "
                    "cercle avant de valider. Une erreur fait gronder la crypte, et le volcan s'éveille plus vite.")
GUARDS_OATH = ("Moi, gardien du marais, je jure de veiller sur le tombeau des rois et sur le livre des anciens "
               "bâtisseurs. Je ne prononcerai jamais le mot du mécanisme et ne l'écrirai jamais en clair. Je le "
               "garderai comme on me l'a appris : le nom du royaume, chaque lettre déplacée tour à tour vers l'avant "
               "puis vers l'arrière. Ainsi le secret survit aux gardiens.")


# Pontons, comme MaraisTerrain.BOARDWALKS : début et fin.
BOARDWALKS = ((-3.0, 48.0, -18.0, 27.0), (-16.0, 19.0, 6.0, 4.0), (8.5, -10.0, 3.0, -28.0))


def pad_frogs():
    """Nénuphars des grenouilles, à 2,5 m de l'axe des pontons, d'un côté puis de l'autre."""
    spots = []
    for index, (x0, z0, x1, z1) in enumerate(BOARDWALKS):
        length = math.hypot(x1 - x0, z1 - z0)
        ux, uz = (x1 - x0) / length, (z1 - z0) / length
        for t, side in ((0.32, 1.0), (0.68, -1.0)):
            side *= -1.0 if index % 2 else 1.0
            x = x0 + ux * length * t + uz * side * 2.5
            z = z0 + uz * length * t - ux * side * 2.5
            spots.append(f"Vector2({x:.2f}, {z:.2f})")
    return spots


def ext(identifier):
    return f'ExtResource("{identifier}")'


def quote(text):
    return '"' + text.replace('"', '\\"').replace("\n", "\\n") + '"'


def basis(yaw=0.0, scale=1.0, tilt=0.0):
    """Rotation autour de Y puis de X, à l'échelle donnée, en texte de Transform3D (9 valeurs)."""
    cy, sy = math.cos(math.radians(yaw)), math.sin(math.radians(yaw))
    ct, st = math.cos(math.radians(tilt)), math.sin(math.radians(tilt))
    ry = [[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]]
    rx = [[1, 0, 0], [0, ct, -st], [0, st, ct]]
    m = [[sum(ry[r][i] * rx[i][c] for i in range(3)) * scale for c in range(3)] for r in range(3)]
    return ", ".join(f"{round(v, 6):g}" for row in m for v in row)


def at(x, y, z, scale=1.0, yaw=0.0, tilt=0.0):
    return f"transform = Transform3D({basis(yaw, scale, tilt)}, {x:g}, {y:g}, {z:g})"


def node(lines, name, kind=None, parent=".", instance=None, props=()):
    head = f'[node name="{name}"'
    if kind:
        head += f' type="{kind}"'
    if parent is not None:
        head += f' parent="{parent}"'
    if instance:
        head += f" instance={ext(instance)}"
    lines += [head + "]", *props, ""]


def sign(lines, name, parent, position, yaw, text, style, mount, size, height, line=0.15, serif=True, collision=True,
         double_sided=False):
    """Panneau SignBoard : style 0 bois, 1 pierre, 2 parchemin, 3 fer ; mount 0 poteaux, 1 mur, 2 potence.
    double_sided : le texte et le cadre aussi au dos (panneau sur poteaux vu des deux côtés, jamais un dos nu)."""
    props = [
        at(*position, 1.0, yaw), f"script = {ext('17_sign')}", f"text = {quote(text)}", f"style = {style}",
        f"mount = {mount}", f"board_size = Vector2({size[0]:g}, {size[1]:g})", f"board_height = {height:g}",
        f"line_height = {line:g}", f"serif = {'true' if serif else 'false'}", f"collision = {'true' if collision else 'false'}"]
    if double_sided:
        props.append("double_sided = true")
    node(lines, name, "Node3D", parent, props=props)


def engraving(lines, name, parent, position, yaw, text, pixel, color="Color(0.12, 0.11, 0.1, 1)", font_size=64):
    """Inscription gravée collée à une face : pas de contour, éclairée comme la pierre, orientée comme la face (+Z)."""
    node(lines, name, "Label3D", parent, props=[
        at(*position, 1.0, yaw), f"pixel_size = {pixel:g}", "shaded = true", "double_sided = false", "alpha_cut = 1",
        f"modulate = {color}", f"text = {quote(text)}", f"font_size = {font_size}", "outline_size = 0",
        "horizontal_alignment = 1"])


def box_mesh(lines, name, parent, position, size, material, overlay=None, yaw=0.0):
    """Pavé de pierre : son maillage est écrit à la volée en sous-ressource (voir MESHES)."""
    key = (round(size[0], 3), round(size[1], 3), round(size[2], 3), material)
    identifier = MESHES.setdefault(key, f"BoxMesh_n{len(MESHES) + 1}")
    props = [at(*position, 1.0, yaw), f'mesh = SubResource("{identifier}")']
    if overlay:
        props.append(f'material_overlay = SubResource("{overlay}")')
    node(lines, name, "MeshInstance3D", parent, props=props)


MESHES = {}
SHAPES = {}


def box_shape(lines, name, parent, position, size, yaw=0.0):
    key = (round(size[0], 3), round(size[1], 3), round(size[2], 3))
    identifier = SHAPES.setdefault(key, f"BoxShape3D_n{len(SHAPES) + 1}")
    node(lines, name, "CollisionShape3D", parent, props=[at(*position, 1.0, yaw), f'shape = SubResource("{identifier}")'])


def write_niches(lines):
    """Cadres de pierre des niches de l'ossuaire, contre les murs de la salle et des chambres du sud."""
    node(lines, "Niches", "StaticBody3D", "Interior")
    for index, ((fx, fz), (nx, nz)) in enumerate(NICHES):
        parent = f"Interior/Niches/Niche{index}"
        center = (fx + nx * NICHE_DEPTH / 2, fz + nz * NICHE_DEPTH / 2)
        yaw = math.degrees(math.atan2(nx, nz))
        node(lines, f"Niche{index}", "Node3D", "Interior/Niches", props=[at(center[0], 0.0, center[1], 1.0, yaw)])
        # Repère local de la niche : x le long du mur, z vers la pièce, origine au milieu de sa profondeur.
        d = NICHE_DEPTH
        w, h = NICHE_WIDTH, NICHE_HEIGHT
        box_mesh(lines, "Back", parent, (0.0, h / 2, -d / 2 + 0.03), (w - 0.1, h - 0.1, 0.04), "StandardMaterial3D_niche_back")
        for side in (-1, 1):
            box_mesh(lines, f"Post{side + 1}", parent, (side * (w / 2 - 0.15), h / 2, 0.0), (0.3, h, d), "StandardMaterial3D_tomb", "ShaderMaterial_dust")
        box_mesh(lines, "Lintel", parent, (0.0, h - 0.15, 0.0), (w, 0.3, d), "StandardMaterial3D_tomb", "ShaderMaterial_dust")
        box_mesh(lines, "Base", parent, (0.0, NICHE_FLOOR / 2, 0.0), (w, NICHE_FLOOR, d), "StandardMaterial3D_tomb", "ShaderMaterial_dust")
        box_mesh(lines, "Shelf", parent, (0.0, NICHE_SHELF - 0.05, -0.02), (w - 0.6, 0.1, d - 0.05), "StandardMaterial3D_tomb_dark", "ShaderMaterial_dust")
        size = (d, h, w) if nx else (w, h, d)
        box_shape(lines, f"Shape{index}", "Interior/Niches", (center[0], h / 2, center[1]), size)


def main():
    lines = []
    body = []
    body += [
        '[node name="Marais" type="Node3D"]',
        'script = ExtResource("1_marais")',
        'ground_steps = Array[AudioStream]([ExtResource("43_mud1"), ExtResource("44_mud2"), ExtResource("45_mud3")])',
        'water_steps = Array[AudioStream]([ExtResource("46_splash1"), ExtResource("47_splash2"), ExtResource("48_splash3")])',
        'door_sound = ExtResource("41_door_sound")',
        'reject_sound = ExtResource("54_reject")',
        'stone_steps = Array[AudioStream]([ExtResource("55_stone1"), ExtResource("56_stone2"), ExtResource("57_stone3")])',
        "",
    ]
    lines = body
    node(lines, "WorldEnvironment", "WorldEnvironment", props=['environment = SubResource("Environment_marais")'])
    node(lines, "Moon", "DirectionalLight3D", props=[
        "transform = Transform3D(0.7071068, 0.5, -0.5, 0, 0.7071068, 0.7071068, 0.7071068, -0.5, 0.5, 0, 40, 0)",
        "light_color = Color(0.58, 0.7, 0.95, 1)", "light_energy = 0.5", "light_specular = 1.4", "shadow_enabled = true",
        "directional_shadow_mode = 1", "directional_shadow_max_distance = 50.0"])
    node(lines, "Terrain", "StaticBody3D", props=[
        'script = ExtResource("2_terrain")', 'ground_material = SubResource("ShaderMaterial_ground")'])
    node(lines, "Water", "MeshInstance3D", props=['mesh = SubResource("PlaneMesh_water")', "cast_shadow = 0"])
    # Brume qui roule au ras de l'eau, en deux nappes : l'une sous les pontons, l'autre à hauteur de genou.
    node(lines, "GroundFog", "Node3D")
    node(lines, "Low", "MeshInstance3D", "GroundFog", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.16, 0)", 'mesh = SubResource("PlaneMesh_fog_low")', "cast_shadow = 0"])
    node(lines, "High", "MeshInstance3D", "GroundFog", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.55, 0)", 'mesh = SubResource("PlaneMesh_fog_high")', "cast_shadow = 0"])
    # La lune, d'où vient la lumière froide : un disque pâle au sud-ouest, hors de la brume.
    node(lines, "MoonDisc", "MeshInstance3D", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -210, 297, 210)", 'mesh = SubResource("QuadMesh_moon")', "cast_shadow = 0"])
    node(lines, "Sounds", "Node3D")
    for name, stream, (x, y, z), volume, pitch, unit, reach in SOUNDS:
        node(lines, name, "AudioStreamPlayer3D", "Sounds", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, {z:g})", f'stream = ExtResource("{stream}")',
            f"volume_db = {volume:g}", f"pitch_scale = {pitch:g}", f"unit_size = {unit:g}", f"max_distance = {reach:g}", "autoplay = true"])
    lines += [
        '[node name="Scatter" type="Node3D" parent="." node_paths=PackedStringArray("terrain", "grounded", "props_root", "crypt_root")]',
        'script = ExtResource("3_scatter")',
        'terrain = NodePath("../Terrain")',
        'tree_models = Array[PackedScene]([ExtResource("20_pine_crooked"), ExtResource("21_pine"), '
        'ExtResource("22_tree_thin"), ExtResource("23_tree_default")])',
        'reed_model = ExtResource("24_reed")',
        'reed_material = SubResource("ShaderMaterial_reeds")',
        'lily_models = Array[PackedScene]([ExtResource("25_lily_large"), ExtResource("26_lily_small")])',
        'flower_models = Array[PackedScene]([ExtResource("33_flower_purple"), ExtResource("34_flower_red"), ExtResource("35_flower_yellow")])',
        'bush_model = ExtResource("27_bush")',
        'mushroom_model = ExtResource("28_mushroom")',
        'log_model = ExtResource("29_log")',
        'plank_model = ExtResource("30_plank")',
        'post_model = ExtResource("31_post")',
        'lantern_model = ExtResource("32_lantern")',
        'grounded = NodePath("../Grounded")',
        'props_root = NodePath("../Props")',
        'crypt_root = NodePath("../Interior/Crypt")',
        'moss_material = SubResource("ShaderMaterial_moss")',
        'dust_material = SubResource("ShaderMaterial_dust")',
        "",
    ]
    node(lines, "Props", instance="6_props")
    node(lines, "Grounded", instance="7_grounded")
    node(lines, "Portal", instance="8_portal", props=[
        at(0, 0.4, 63), 'closed_prompt = "Portail éteint"', 'open_prompt = "Retourner au hub"', "inner_color = Color(0.6, 1, 0.7, 1)", "outer_color = Color(0.1, 0.55, 0.3, 1)"])
    node(lines, "Campfire", "Node3D", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -18, 0.55, 21)", 'script = ExtResource("13_fire")',
        "size = 1.6", "light_energy = 3.0", "light_range = 9.0", 'crackle_sound = ExtResource("42_crackle")'])
    for name, x, z in (("GateLightNorth", 7.0, -0.3), ("GateLightSouth", 7.0, 6.3)):
        node(lines, name, "OmniLight3D", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, 3.8, {z:g})",
            'script = ExtResource("14_flicker")', "light_color = Color(1, 0.75, 0.4, 1)", "light_energy = 1.6",
            "omni_range = 7.0", "flicker = 0.2", "distance_fade_enabled = true", "distance_fade_begin = 38.0", "distance_fade_length = 8.0"])
    node(lines, "CryptLight", "OmniLight3D", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 3.5, -32)", 'script = ExtResource("14_flicker")',
        "light_color = Color(0.5, 0.9, 0.7, 1)", "light_energy = 1.2", "omni_range = 9.0", "flicker = 0.1", "distance_fade_enabled = true", "distance_fade_begin = 38.0", "distance_fade_length = 8.0"])
    # La lanterne du panneau d'accueil éclaire son texte.
    node(lines, "SignLight", "OmniLight3D", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -5.3, 2.5, 54.0)", 'script = ExtResource("14_flicker")',
        "light_color = Color(1, 0.78, 0.45, 1)", "light_energy = 1.4", "omni_range = 5.5", "flicker = 0.15", "distance_fade_enabled = true", "distance_fade_begin = 38.0", "distance_fade_length = 8.0"])
    # Une lueur froide persiste sur l'autel de la chapelle en ruine.
    node(lines, "ChapelLight", "OmniLight3D", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -37.8, 2.2, -4)", 'script = ExtResource("14_flicker")',
        "light_color = Color(0.55, 0.95, 0.85, 1)", "light_energy = 1.3", "omni_range = 8.0", "flicker = 0.25", "distance_fade_enabled = true", "distance_fade_begin = 38.0", "distance_fade_length = 8.0"])

    node(lines, "Clues", "Node3D")
    for name, x, y, z, title, text, prompt, radius in CLUES:
        node(lines, name, "Node3D", "Clues", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, {z:g})",
            'script = ExtResource("12_readable")', f"title = {quote(title)}", f"body = {quote(text)}",
            f"prompt = {quote(prompt)}", f"radius = {radius:g}"])
    # Ce que l'on voit de chaque indice : le journal sur sa caisse, les plaques et les inscriptions gravées.
    node(lines, "Journal", "MeshInstance3D", "Clues/Notebook", props=[at(0.0, -0.085, 0.0, 1.0, 40.0), 'mesh = SubResource("BoxMesh_journal")'])
    sign(lines, "Plate", "Clues/KeeperTomb", (0.57, -1.2, 0.0), -90.0, "Aldric\nGardien du marais\n5761 - 5803", 3, 1, (0.78, 0.52), 1.5, 0.12)
    engraving(lines, "Name", "Clues/AdaTomb", (0.0, 0.13, 0.355), 180.0, "ADA", 0.0042)
    # Panneaux sur poteaux : texte et cadre des deux côtés, pour qu'aucun dos sombre ne se voie à contre-jour.
    sign(lines, "Board", "Clues/Plaque", (0.0, -0.85, -0.35), 0.0, "Crypte du gardien", 1, 0, (1.3, 0.55), 1.05, 0.16,
         double_sided=True)
    sign(lines, "Board", "Clues/Welcome", (0.0, -0.9, -0.35), 30.0, "Les marais de\nKernel Swamp", 0, 0, (1.5, 0.8), 1.5, 0.2,
         double_sided=True)
    # Derrière l'accueil et l'avis du port, vus de dos en revenant vers le portail : une faible lueur chaude.
    for parent, x, y, z in (("Clues/Welcome", -0.45, 0.3, -1.13), ("Clues/Notice", 0.6, 0.2, -0.67)):
        node(lines, "BackLight", "OmniLight3D", parent, props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, {z:g})",
            "light_color = Color(1, 0.8, 0.55, 1)", "light_energy = 0.6", "omni_range = 2.5",
            "distance_fade_enabled = true", "distance_fade_begin = 38.0", "distance_fade_length = 8.0"])
    # L'avis du port, au bout du débarcadère, tourné vers l'arrivée ; l'ardoise d'Ada, entre sa tombe et la suivante,
    # tournée vers l'allée ; l'ordre du roi, au bout du dernier ponton, tourné vers lui.
    sign(lines, "Board", "Clues/Notice", (0.0, -0.9, 0.0), -42.0, "Capitainerie de Brumeval\nAvis aux pêcheurs", 2, 0,
         (1.1, 0.75), 1.35, 0.13, double_sided=True)
    sign(lines, "Board", "Clues/AdaSlate", (0.0, -0.9, 0.0), 180.0, "Leçon d'Ada\nBRUME devient DPWKG", 1, 0,
         (1.0, 0.6), 1.15, 0.13, double_sided=True)
    # La face de l'ardoise regarde l'allée, au nord, à contre-jour de la lune : la lanterne posée à son pied l'éclaire.
    node(lines, "Light", "OmniLight3D", "Clues/AdaSlate", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0.85, -0.3, -0.65)", 'script = ExtResource("14_flicker")',
        "light_color = Color(1, 0.78, 0.45, 1)", "light_energy = 0.9", "omni_range = 3.5", "flicker = 0.15",
        "distance_fade_enabled = true", "distance_fade_begin = 38.0", "distance_fade_length = 8.0"])
    sign(lines, "Board", "Clues/RoyalOrder", (0.0, -0.9, 0.0), -19.0, "Ordre du roi\nCodeon V", 2, 0, (1.0, 0.7), 1.35, 0.15,
         double_sided=True)

    node(lines, "Ghost", "Node3D", props=[at(19.0, 1.6, 3.6, 3.0, -90)])
    node(lines, "Model", parent="Ghost", instance="16_ghost")
    node(lines, "CryptDoor", "Node3D", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -1.26, 0.4, -37)"])
    node(lines, "Model", parent="CryptDoor", instance="15_door", props=[
        "transform = Transform3D(4, 0, 0, 0, 4, 0, 0, 0, 4, 1.26, 0, 0)"])
    node(lines, "Sound", "AudioStreamPlayer3D", "CryptDoor", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 1.26, 1.5, 0)", "unit_size = 4.0"])
    node(lines, "DoorInteractable", "Node3D", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.4, -36)", 'script = ExtResource("11_interactable")',
        'prompt = "Descendre dans la crypte"', "radius = 3.0"])
    node(lines, "OutsideSpawn", "Marker3D", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.6, -31.5)"])
    # Feux follets : au-dessus du village englouti, autour de la chapelle, du bosquet mort, des pierres levées,
    # de la tombe du gardien, et en chapelet le long du dernier ponton, jusqu'à la crypte.
    node(lines, "Wisps", "Node3D", props=[
        'script = ExtResource("19_wisps")',
        "anchors = Array[Vector4]([Vector4(22, 1.2, 30, 7), Vector4(12, 1.4, 26, 3), Vector4(-36, 1.6, -4, 5), "
        "Vector4(34, 1.5, -30, 3.5), Vector4(-30, 1.7, -44, 2.5), Vector4(20.5, 2.0, 1.5, 1.6), Vector4(6.6, 1.3, -15, 1.2), "
        "Vector4(4.4, 1.3, -21, 1.2), Vector4(2.2, 1.4, -27, 1.2), Vector4(-1.2, 1.6, -33.6, 1.0), Vector4(-26, 1.2, 36, 5)])",
        "counts = PackedInt32Array(7, 3, 4, 4, 3, 2, 1, 1, 1, 1, 3)"])

    # Crypte souterraine, sous la carte : le long escalier, la salle du mécanisme, les couloirs et les chambres.
    node(lines, "Interior", "Node3D", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -40, 0)"])
    node(lines, "Crypt", parent="Interior", instance="50_crypt")
    # On arrive en haut du long escalier, sous la trappe, et l'on descend vers la salle.
    node(lines, "InsideSpawn", "Marker3D", "Interior", props=[f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {LANDING_Y + 0.3:g}, 11.0)"])
    node(lines, "Hatch", "MeshInstance3D", "Interior", props=[
        f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {LANDING_Y + 4.15 - 0.07:g}, 13.0)", 'mesh = SubResource("BoxMesh_hatch")'])
    node(lines, "Exit", "Node3D", "Interior", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.2, 2.0)", 'script = ExtResource("11_interactable")',
        'prompt = "Remonter l\'escalier"', "radius = 2.2"])
    # En haut, sous la trappe : l'invite apparaît dès la dernière marche, là où l'on s'arrête en montant.
    node(lines, "ExitTop", "Node3D", "Interior", props=[
        f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {LANDING_Y + 1.2:g}, 12.4)", 'script = ExtResource("11_interactable")',
        'prompt = "Remonter à la surface"', "radius = 2.9"])
    # Lumières de la crypte : chaudes (cierges) ; celle du palier, sous la trappe, froide comme la nuit du dehors.
    warm, cold = "Color(1, 0.8, 0.6, 1)", "Color(0.72, 0.8, 0.88, 1)"
    # À mi-hauteur du long escalier, une lanterne pend du plafond au bout d'une chaîne : sans elle, le haut de la cage
    # restait noir, comme un trou.
    node(lines, "StairLantern", "Node3D", "Interior", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 8.2, 6.4)"])
    node(lines, "Chain", "MeshInstance3D", "Interior/StairLantern", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -1.2, 0)", 'mesh = SubResource("BoxMesh_chain")'])
    node(lines, "Lantern", parent="Interior/StairLantern", instance="61_hanging_lantern", props=[at(0.0, -2.4 - 0.39 * 1.6, 0.0, 1.6)])
    # Portée de 12 m pour toutes : dans le rendu Compatibility, une lumière sans ombre ne coûte aucun appel de dessin
    # de plus (mesuré : mêmes appels à 12 m qu'à la portée de la pièce), et une portée plus courte assombrissait les
    # murs. Chaque maillage fondu de la crypte en reçoit 7 au plus, sous la limite de 8 par objet.
    for name, x, y, z, energy, color, reach in (
            ("LightEntry", 0, 3.3, 1.0, 1.2, warm, 12.0), ("LightStairs", 0, 7.4, 11.4, 0.7, cold, 12.0),
            ("LightStairsMid", 0, 5.0, 6.4, 0.9, warm, 12.0), ("LightHall", 0, 3.3, -12, 2.2, warm, 12.0),
            ("LightEast", 24, 3.3, -12, 1.6, warm, 12.0), ("LightEastTomb", 20.6, 1.5, -12, 0.5, warm, 12.0),
            ("LightWest", -24, 3.3, -12, 1.4, warm, 12.0), ("LightOssuary", -18, 3.3, 2, 0.9, warm, 12.0),
            ("LightGuards", 18, 3.3, 2, 0.9, warm, 12.0)):
        node(lines, name, "OmniLight3D", "Interior", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, {y:g}, {z:g})", 'script = ExtResource("14_flicker")',
            f"light_color = {color}", f"light_energy = {energy:g}", f"omni_range = {reach:g}", "flicker = 0.15"])
    for index, x in enumerate((-8.4, 8.4)):
        node(lines, f"Brazier{index}", "Node3D", "Interior", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, 0.55, -20.6)", 'script = ExtResource("13_fire")',
            "size = 0.7", "light_energy = 1.0", "light_range = 6.0", 'crackle_sound = ExtResource("42_crackle")', "crackle_volume_db = -14.0"])
    node(lines, "Mechanism", "Node3D", "Interior", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, -12)", 'script = ExtResource("51_mechanism")'])
    node(lines, "MechanismInteractable", "Node3D", "Interior", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.6, -12)", 'script = ExtResource("11_interactable")',
        'prompt = "Examiner le mécanisme"', "radius = 5.6"])
    node(lines, "MechanismCamera", "Camera3D", "Interior", props=[
        "transform = Transform3D(1, 0, 0, 0, 0.422618, 0.906308, 0, -0.906308, 0.422618, 2.2, 3.8, -10.2)", "fov = 80.0"])
    # L'inscription, gravée sur une dalle du mur face au mécanisme.
    node(lines, "Inscription", "Node3D", "Interior", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.6, -21)", 'script = ExtResource("12_readable")',
        'title = "L\'inscription du mur"', f"body = {quote(INSCRIPTION)}", 'prompt = "Lire l\'inscription"', "radius = 5.0"])
    sign(lines, "Slab", "Interior/Inscription", (0.0, -1.6, -22.0 + PANEL_FACE + 21.0), 0.0, INSCRIPTION, 1, 1, (3.4, 1.55), 2.25, 0.14, serif=False)

    # Tombeau du livre, dans la chambre de l'est : son lourd couvercle glisse quand le mécanisme est résolu.
    node(lines, "Tomb", "Node3D", "Interior", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 24, 0, -12)"])
    node(lines, "Plinth", "MeshInstance3D", "Interior/Tomb", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.08, 0)", 'mesh = SubResource("BoxMesh_plinth")',
        'material_overlay = SubResource("ShaderMaterial_dust")'])
    node(lines, "Base", "MeshInstance3D", "Interior/Tomb", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 0)", 'mesh = SubResource("BoxMesh_tomb")',
        'material_overlay = SubResource("ShaderMaterial_dust")'])
    node(lines, "Band", "MeshInstance3D", "Interior/Tomb", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.86, 0)", 'mesh = SubResource("BoxMesh_band")'])
    engraving(lines, "Motto", "Interior/Tomb", (-0.912, 0.46, 0.0), -90.0, "ICI DORT LE SAVOIR\nDE LA LOGIQUE\nET DU CHIFFREMENT", 0.0026)
    node(lines, "Lid", "MeshInstance3D", "Interior/Tomb", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.1, 0)", 'mesh = SubResource("BoxMesh_lid")',
        'material_overlay = SubResource("ShaderMaterial_dust")'])
    node(lines, "Body", "StaticBody3D", "Interior/Tomb/Lid")
    node(lines, "Shape", "CollisionShape3D", "Interior/Tomb/Lid/Body", props=['shape = SubResource("BoxShape3D_lid")'])
    node(lines, "Body", "StaticBody3D", "Interior/Tomb")
    node(lines, "CollisionShape3D", "CollisionShape3D", "Interior/Tomb/Body", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 0)", 'shape = SubResource("BoxShape3D_tomb")'])
    node(lines, "Sound", "AudioStreamPlayer3D", "Interior/Tomb", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0)", "unit_size = 6.0"])
    node(lines, "Book", "Node3D", "Interior/Tomb", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.12, 0)"])
    node(lines, "Mesh", "MeshInstance3D", "Interior/Tomb/Book", props=['mesh = SubResource("BoxMesh_book")'])
    node(lines, "Glow", "OmniLight3D", "Interior/Tomb/Book", props=[
        "light_color = Color(0.4, 1, 0.6, 1)", "light_energy = 1.5", "omni_range = 4.0"])
    node(lines, "Interactable", "Node3D", "Interior/Tomb/Book", props=[
        'script = ExtResource("11_interactable")', 'prompt = "Prendre le Logiconomicon"', "radius = 2.8"])

    # Tombeaux des quatre premiers rois dans la chambre de l'ouest, à l'opposé de celui qui garde le livre ; ils bordent
    # l'allée, à distance des murs. Le nom est gravé sur la face tournée vers l'allée, l'épitaphe se lit devant.
    node(lines, "Kings", "Node3D", "Interior")
    for index, (x, z) in enumerate(KINGS):
        base = f"Interior/Kings/King{index + 1}"
        front = -1.0 if z > -12 else 1.0
        node(lines, f"King{index + 1}", "StaticBody3D", "Interior/Kings", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x:g}, 0, {z:g})"])
        node(lines, "Plinth", "MeshInstance3D", base, props=[
            "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.08, 0)", 'mesh = SubResource("BoxMesh_plinth")',
            'material_overlay = SubResource("ShaderMaterial_dust")'])
        node(lines, "Base", "MeshInstance3D", base, props=[
            "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.5, 0)", 'mesh = SubResource("BoxMesh_tomb")',
            'material_overlay = SubResource("ShaderMaterial_dust")'])
        node(lines, "Lid", "MeshInstance3D", base, props=[
            "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.1, 0)", 'mesh = SubResource("BoxMesh_lid")',
            'material_overlay = SubResource("ShaderMaterial_dust")'])
        node(lines, "Shape", "CollisionShape3D", base, props=[
            "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.6, 0)", 'shape = SubResource("BoxShape3D_king")'])
        # Sur le couvercle, la couronne du côté de la tête, contre le mur, et l'épée du gisant le long du corps : le
        # pommeau vers la tête, la lame vers l'allée (vue de l'allée, la poignée seule ressemblait à une boule orange).
        sword_yaw = 180.0 if front < 0 else 0.0
        node(lines, "Sword", parent=base, instance="36_sword", props=[
            at(0.05, 1.38, -front * 0.6, 3.0, sword_yaw, 90.0)])
        # La couronne du roi sur un coussin de velours : un bandeau d'or et cinq fleurons.
        node(lines, "Cushion", "MeshInstance3D", base, props=[at(0.0, 1.235, -front * 1.2), 'mesh = SubResource("BoxMesh_cushion")'])
        node(lines, "Crown", "MeshInstance3D", base, props=[at(0.0, 1.31, -front * 1.2), 'mesh = SubResource("CylinderMesh_crown")'])
        for point in range(5):
            angle = math.tau * point / 5
            node(lines, f"Fleuron{point}", "MeshInstance3D", base, props=[
                at(math.sin(angle) * 0.165, 1.4, -front * 1.2 + math.cos(angle) * 0.165, 1.0, math.degrees(angle)),
                'mesh = SubResource("PrismMesh_crown_point")'])
        name = f"Roi Codeon {['I', 'II', 'III', 'IV'][index]}"
        node(lines, "Epitaph", "Node3D", base, props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.8, {front * 1.95:g})", 'script = ExtResource("12_readable")',
            f"title = {quote(name)}", f"body = {quote(EPITAPHS[index])}", 'prompt = "Lire l\'épitaphe"',
            "radius = 2.6"])
        engraving(lines, "Name", base, (0.0, 0.58, front * 1.512), 0.0 if front > 0 else 180.0, name, 0.0028, "Color(0.85, 0.72, 0.42, 1)")
    # L'hommage aux rois, gravé sur une dalle du mur du fond, au-dessus de l'autel des offrandes.
    node(lines, "KingsTribute", "Node3D", "Interior", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -28.9, 2.5, -12)", 'script = ExtResource("12_readable")',
        'title = "Hommage aux rois"',
        'body = "Nos bons rois et protecteurs du Royaume de Codia ! Codeon I le Fondateur, Codeon II le Hardi, Codeon III le Prudent et Codeon IV le Juste reposent ici. Que leur sagesse veille sur Codeon V et sur tout le royaume."',
        'prompt = "Lire l\'hommage"', "radius = 2.8"])
    sign(lines, "Slab", "Interior/KingsTribute", (-30.0 + PANEL_FACE + 28.9, -2.5, 0.0), 90.0,
         "Nos bons rois et protecteurs\ndu Royaume de Codia !", 1, 1, (2.6, 0.9), 2.5, 0.16)
    # Registre de l'ossuaire et serment des gardiens : sur le pan de mur plein de chaque chambre du sud (au bout du
    # couloir, à z 2 à 6), sur le panneau central du mur, au-dessus de l'urne couchée et du cercueil.
    for name, x, facing, title, body, board, style, prompt in (
            ("OssuaryRegister", -14.0 - BOARD_FACE, -1.0, "Registre de l'ossuaire", OSSUARY_REGISTER,
             "Registre de l'ossuaire", 2, "Lire le registre"),
            ("GuardsOath", 14.0 + BOARD_FACE, 1.0, "Le serment des gardiens", GUARDS_OATH,
             "Serment des gardiens", 1, "Lire le serment")):
        node(lines, name, "Node3D", "Interior", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x + facing * 0.37:g}, 1.6, 4)",
            'script = ExtResource("12_readable")', f"title = {quote(title)}", f"body = {quote(body)}",
            f"prompt = {quote(prompt)}", "radius = 3.0"])
        sign(lines, "Board", f"Interior/{name}", (-facing * 0.37, -1.6, 0.0), 90.0 * facing, board, style, 1,
             (1.3, 0.7), 1.75, 0.15)
    write_niches(lines)

    # Volcan en éveil au nord, au-delà des reliefs : il domine la zone comme le hub.
    # La vie des marais : grenouilles des berges, poissons, corbeaux, chauves-souris de la crypte, lanternes pendues.
    crows = [f"Vector3({x:.2f}, 0, {z:.2f})" for x, z in STONE_TOPS] + ["Vector3(33, 0, -27.2)", "Vector3(11.5, 0, -9.0)", "Vector3(22.2, 0, -5.3)"]
    lines += [
        '[node name="Life" type="Node3D" parent="." node_paths=PackedStringArray("terrain", "player")]',
        'script = ExtResource("59_life")',
        'terrain = NodePath("../Terrain")',
        'player = NodePath("../Player")',
        'fish_model = ExtResource("60_fish")',
        'lantern_model = ExtResource("61_hanging_lantern")',
        "frog_islands = Array[Vector3]([Vector3(0, 56, 8.5), Vector3(-20, 22, 5.8), Vector3(16, 0, 12.3), Vector3(0, -36, 10.4)])",
        f"pad_frogs = Array[Vector2]([{', '.join(pad_frogs())}])",
        f"crow_perches = Array[Vector3]([{', '.join(crows)}])",
        "shy_crows = PackedInt32Array(4, 5)",
        "bat_roosts = Array[Vector3]([Vector3(-18.5, -36.15, 3), Vector3(-17, -36.15, 1.5), Vector3(18.5, -36.15, 3), Vector3(3.5, -36.15, -3.8), "
        "Vector3(-3.5, -36.15, -18.5), Vector3(-24, -36.15, -12), Vector3(21.5, -36.15, -15)])",
        "gallows = Array[Vector4]([Vector4(7.2, 52.2, 0, 90), Vector4(-16, 25.6, 0, 90), Vector4(4.4, -31.2, 0, -90)])",
        "",
    ]
    node(lines, "Volcano", "Node3D", ".", props=[
        "transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 25, -6, -215)", 'script = ExtResource("90_volcano")'])
    node(lines, "Player", instance="9_player", props=[at(0, 0.6, 57), "respawn_height = -80.0", "first_person = true"])
    node(lines, "Ambience", "AudioStreamPlayer", props=[
        'stream = ExtResource("40_ambience")', "volume_db = -6.0", "autoplay = true"])
    node(lines, "CryptAmbience", "AudioStreamPlayer", props=['stream = ExtResource("53_crypt_sound")', "volume_db = -6.0"])
    node(lines, "Hud", instance="10_hud")
    node(lines, "RingPuzzle", instance="52_puzzle")

    head = ["[gd_scene format=3]", ""]
    head += [f'[ext_resource type="{kind}" path="{path}" id="{identifier}"]' for kind, path, identifier in EXT]
    head += [SUBRESOURCES]
    for (sx, sy, sz, material), identifier in MESHES.items():
        head += [f'[sub_resource type="BoxMesh" id="{identifier}"]', f'material = SubResource("{material}")',
                 f"size = Vector3({sx:g}, {sy:g}, {sz:g})", ""]
    for (sx, sy, sz), identifier in SHAPES.items():
        head += [f'[sub_resource type="BoxShape3D" id="{identifier}"]', f"size = Vector3({sx:g}, {sy:g}, {sz:g})", ""]
    out = FRONTEND / "scenes" / "levels" / "marais" / "marais.tscn"
    out.write_text("\n".join(head + lines).rstrip("\n") + "\n", encoding="utf-8", newline="\n")
    print(out.name, len(head) + len(lines), "lignes")


if __name__ == "__main__":
    main()
