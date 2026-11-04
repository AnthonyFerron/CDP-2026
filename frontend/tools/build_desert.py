"""Génère les objets fixes du désert de Pythania : l'arche d'entrée et l'allée des obélisques, le monument des
anciens bâtisseurs (salle des colonnes, chambres du levant et du zénith, sanctuaire englouti), la caravane, l'oasis
asséchée, la citerne, la tête de la statue, les ruines des dunes et la cave des archives.

Les scènes produites s'ouvrent et se modifient dans Godot, mais le script les écrase :
pour un changement durable, modifier ce script puis le relancer depuis le dossier frontend :

    python tools/build_desert.py

Tout ce qui est posé à la surface l'est à la hauteur 0 : sur l'esplanade, le chemin et les replats que
desert_terrain.gd aplanit (SITES, à garder identiques à REPLATS ci-dessous).
"""

import math
import random
from pathlib import Path

from build_plaine import MODEL_BOXES, Scene, furniture, multiply, rotation_x, rotation_y, rotation_z, transform_text

MODEL_BOXES.update({
    "nature_kit/tree_palm": ((-0.47, 0.0, -0.51), (0.94, 1.51, 1.01)),
    "nature_kit/tree_palmBend": ((-0.47, 0.0, -0.51), (0.94, 1.38, 1.01)),
    "nature_kit/tree_palmDetailedTall": ((-0.52, 0.0, -0.52), (1.03, 1.25, 1.03)),
    "nature_kit/tree_palmShort": ((-0.52, 0.0, -0.51), (1.03, 1.06, 1.03)),
    "nature_kit/tree_palmTall": ((-0.52, 0.0, -0.51), (1.03, 1.36, 1.03)),
    "nature_kit/statue_head": ((-0.36, 0.0, -0.31), (0.73, 1.0, 0.55)),
    "nature_kit/cactus_short": ((-0.17, 0.0, -0.12), (0.34, 0.53, 0.3)),
    "graveyard_kit/character-skeleton": ((-0.26, -0.2, -0.15), (0.51, 0.48, 0.32)),
    "graveyard_kit/urn-round": ((-0.13, 0.0, -0.13), (0.26, 0.28, 0.26)),
    "graveyard_kit/urn-square": ((-0.13, 0.0, -0.13), (0.26, 0.28, 0.26)),
    "graveyard_kit/detail-bowl": ((-0.2, 0.0, 0.0), (0.2, 0.13, 0.2)),
    "graveyard_kit/detail-chalice": ((-0.08, 0.0, -0.08), (0.16, 0.25, 0.16)),
    "graveyard_kit/debris": ((-0.29, 0.0, -0.31), (0.54, 0.16, 0.55)),
    "fantasy_town_kit/wheel": ((0.2, 0.0, -0.23), (0.24, 0.48, 0.47)),
    "survival_kit/tent-canvas": ((-0.28, 0.0, -0.28), (0.56, 0.49, 0.56)),
    "survival_kit/bucket": ((-0.07, 0.0, -0.07), (0.14, 0.19, 0.14)),
    "survival_kit/barrel-open": ((-0.12, 0.0, -0.12), (0.24, 0.34, 0.24)),
    "survival_kit/box-open": ((-0.13, 0.0, -0.13), (0.25, 0.31, 0.25)),
    "mini_dungeon/pot": ((-0.3, 0.0, -0.2), (0.6, 0.43, 0.41)),
    "mini_dungeon/stones": ((-0.45, 0.0, -0.4), (0.89, 0.45, 0.8)),
    "mini_dungeon/chair": ((-0.17, 0.0, -0.19), (0.35, 0.48, 0.38)),
    "mini_dungeon/weapon-sword": ((-0.12, -0.1, -0.05), (0.23, 0.45, 0.11)),
    "mini_arena/column": ((-0.3, 0.0, -0.3), (0.6, 1.0, 0.6)),
    "mini_arena/bricks": ((-0.39, 0.0, -0.42), (0.77, 0.41, 0.85)),
    "mini_arena/block": ((-0.5, 0.0, -0.5), (1.0, 0.5, 1.0)),
    "mini_arena/statue": ((-0.35, 0.0, -0.35), (0.7, 1.34, 0.7)),
    "castle_kit/rocks-small": ((-0.52, 0.0, -0.55), (1.03, 0.5, 1.11)),
    "food_kit/bag": ((-0.16, 0.0, -0.29), (0.31, 0.84, 0.58)),
    "food_kit/bag-flat": ((-0.32, 0.0, -0.23), (0.65, 0.19, 0.47)),
    "food_kit/bread": ((-0.22, 0.0, -0.18), (0.44, 0.04, 0.37)),
    "food_kit/loaf-round": ((-0.39, 0.0, -0.26), (0.77, 0.29, 0.51)),
    "food_kit/grapes": ((-0.14, 0.0, -0.12), (0.28, 0.42, 0.24)),
    "food_kit/wine-red": ((-0.1, 0.0, -0.08), (0.19, 0.7, 0.17)),
    "food_kit/pot": ((-0.33, 0.0, -0.41), (0.66, 0.36, 0.82)),
    "food_kit/bowl": ((-0.27, 0.0, -0.31), (0.54, 0.23, 0.62)),
    "food_kit/plate-broken": ((-0.28, 0.0, -0.24), (0.55, 0.09, 0.47)),
    "food_kit/coconut": ((-0.08, 0.0, -0.08), (0.17, 0.14, 0.17)),
})

OUTPUT_DIR = Path(__file__).resolve().parent.parent / "scenes" / "levels" / "desert"
SAND_SHADER = "res://scenes/levels/desert/desert_sand.gdshader"
SQ2 = math.sqrt(2.0)
GATE_SCALE = 5.0
# Ouverture de l'arche du kit, à l'échelle 1 : demi-largeur et hauteur.
GATE_HALF_OPENING = 0.3
GATE_OPENING_HEIGHT = 0.65
# Replats du décor, comme SITES dans desert_terrain.gd : centre (x, z) et rayon.
REPLATS = {
    "caravane": (-36.0, -30.0, 9.0),
    "sanctuaire": (0.0, -31.0, 9.0),
    "oasis": (40.0, -2.0, 10.0),
    "tete": (-34.0, 30.0, 7.0),
    "citerne": (-30.0, -2.5, 7.0),
    "poste": (38.0, 30.0, 6.0),
    "colonnade": (-22.0, -48.0, 6.0),
    "porte": (24.0, -44.0, 6.0),
    "tombes": (-24.0, 48.0, 6.0),
    "bete": (26.0, 50.0, 6.0),
}
# Fosse de la citerne (desert_terrain.gd, CISTERN) : x de -33,75 à -26,25, z de -5 à 0, 1,6 m de profondeur.
CISTERN_RECT = (-33.75, -5.0, -26.25, 0.0)
CISTERN_DEPTH = 1.6

# Matériaux des formes simples : couleur, rugosité, métal. Ces formes ne sont pas teintées en grès par desert.gd.
MATERIALS = {
    "stone": ((0.84, 0.66, 0.47), 0.95, 0.0),
    "stone_dark": ((0.64, 0.48, 0.33), 1.0, 0.0),
    "glyph": ((0.34, 0.22, 0.13), 1.0, 0.0),
    "gold": ((0.86, 0.64, 0.24), 0.45, 0.7),
    "bronze": ((0.36, 0.24, 0.13), 0.55, 0.6),
    "charcoal": ((0.08, 0.07, 0.06), 1.0, 0.0),
    "ash": ((0.42, 0.4, 0.38), 1.0, 0.0),
    "bone": ((0.9, 0.86, 0.74), 0.85, 0.0),
    "wood": ((0.4, 0.26, 0.14), 1.0, 0.0),
    "wood_dark": ((0.2, 0.13, 0.08), 1.0, 0.0),
    "wood_bleached": ((0.6, 0.47, 0.32), 1.0, 0.0),
    "rope": ((0.6, 0.48, 0.3), 1.0, 0.0),
    "void": ((0.015, 0.012, 0.01), 1.0, 0.0),
    "cloth_red": ((0.58, 0.16, 0.1), 1.0, 0.0),
    "cloth_blue": ((0.16, 0.25, 0.44), 1.0, 0.0),
    "cloth_ochre": ((0.76, 0.52, 0.18), 1.0, 0.0),
    "parchment": ((0.88, 0.8, 0.6), 1.0, 0.0),
    "clay": ((0.62, 0.35, 0.19), 1.0, 0.0),
    "tablet": ((0.56, 0.48, 0.39), 1.0, 0.0),
    "leather": ((0.33, 0.19, 0.09), 0.9, 0.0),
    "ink": ((0.08, 0.06, 0.05), 1.0, 0.0),
    "crack": ((0.26, 0.17, 0.1), 1.0, 0.0),
    "cave_stone": ((0.46, 0.42, 0.38), 1.0, 0.0),
    "cave_dark": ((0.28, 0.25, 0.22), 1.0, 0.0),
}
# Teinte des congères : la couleur du sable au soleil.
SAND_TINT = (0.86, 0.66, 0.42)
# Côté des cases qui découpent les formes qui s'effacent au loin : la distance de visibilité d'un MultiMesh se mesure
# jusqu'au centre de sa boîte, il en faut un par case pour que rien ne disparaisse loin du centre de la carte.
CHUNK = 32.0


def fmt(value):
    return f"{round(value, 5):g}"


class DesertScene(Scene):
    """Scène de Scene, plus des formes simples (boîtes, cylindres, sphères, tores) regroupées en MultiMesh dès
    qu'elles se répètent, des congères de sable et des collisions tournées dans tous les sens ou convexes."""

    def __init__(self, root_name):
        super().__init__(root_name)
        self.shapes = {}
        self.extra_colliders = []
        self.footprints = []

    def shape(self, kind, params, material, position, degrees=0.0, tilt=0.0, roll=0.0, scale=1.0, spin=0.0,
              shadow=True, fade=0.0):
        """Forme simple : kind vaut box (size), cyl (top, bottom, height, segments), sphere (segments, rings) ou
        torus (inner, outer, rings, sides). La rotation est cap, puis inclinaison (x), roulis (z) et tour sur
        son axe (spin, en y) ; fade donne une distance au-delà de laquelle elle disparaît."""
        key = (kind, tuple(sorted(params.items())), material, shadow, fade)
        basis = multiply(multiply(multiply(rotation_y(degrees), rotation_x(tilt)), rotation_z(roll)), rotation_y(spin))
        axes = scale if isinstance(scale, tuple) else (scale, scale, scale)
        basis = [[row[c] * axes[c] for c in range(3)] for row in basis]
        self.shapes.setdefault(key, []).append((basis, tuple(position)))

    def box_collider(self, center, size, degrees=0.0, tilt=0.0, roll=0.0):
        basis = multiply(multiply(rotation_y(degrees), rotation_x(tilt)), rotation_z(roll))
        self.extra_colliders.append((transform_text(basis, center), "BoxShape3D", f"size = Vector3({fmt(size[0])}, {fmt(size[1])}, {fmt(size[2])})"))

    def cylinder_collider(self, center, radius, height, degrees=0.0, tilt=0.0):
        basis = multiply(rotation_y(degrees), rotation_x(tilt))
        self.extra_colliders.append((transform_text(basis, center), "CylinderShape3D",
                                     f"radius = {fmt(radius)}\nheight = {fmt(height)}"))

    def rubble_collider(self, center, model, degrees, scale):
        """Tas de gravats : une boîte plus basse et plus étroite que la boîte du modèle, au cœur du tas."""
        (px, py, pz), (sx, sy, sz) = MODEL_BOXES[model]
        self.add_box((center[0], sy * scale * 0.33, center[2]), (sx * scale * 0.75, sy * scale * 0.66, sz * scale * 0.75), degrees)

    def column_collider(self, x, z, width, height, base=0.0):
        """Colonne du kit : un socle carré au pied, puis un fût cylindrique un peu plus étroit que le chapiteau."""
        top = base + height
        if top <= 0.05:
            return
        foot = max(base, 0.0)
        self.add_box((x, foot + 0.12 * width / 2, z), (width, 0.12 * width, width))
        self.cylinder_collider((x, (foot + top) / 2, z), width * 0.36, top - foot)

    def convex_collider(self, center, degrees, points):
        text = ", ".join(f"{fmt(x)}, {fmt(y)}, {fmt(z)}" for x, y, z in points)
        self.extra_colliders.append((transform_text(rotation_y(degrees), center), "ConvexPolygonShape3D", f"points = PackedVector3Array({text})"))

    def solid(self, center, size, degrees=0.0, label=""):
        """Boîte de collision au sol, retenue aussi pour la vérification des chevauchements."""
        self.add_box((center[0], center[1] + size[1] / 2, center[2]), size, degrees)
        self.footprints.append((label, center, size, degrees))

    def _mesh_text(self, kind, params, material_id):
        lines = []
        if kind == "box":
            sx, sy, sz = params["size"]
            lines.append(f"size = Vector3({fmt(sx)}, {fmt(sy)}, {fmt(sz)})")
            return "BoxMesh", lines
        if kind == "cyl":
            lines += [f"top_radius = {fmt(params['top'])}", f"bottom_radius = {fmt(params['bottom'])}",
                      f"height = {fmt(params['height'])}", f"radial_segments = {params.get('segments', 8)}", "rings = 1"]
            if params.get("top", 1.0) == 0.0:
                lines.append("cap_top = false")
            return "CylinderMesh", lines
        if kind == "sphere":
            lines += ["radius = 1.0", "height = 2.0", f"radial_segments = {params.get('segments', 12)}",
                      f"rings = {params.get('rings', 6)}"]
            return "SphereMesh", lines
        if kind == "torus":
            lines += [f"inner_radius = {fmt(params['inner'])}", f"outer_radius = {fmt(params['outer'])}",
                      f"rings = {params.get('rings', 16)}", f"ring_segments = {params.get('sides', 6)}"]
            return "TorusMesh", lines
        raise ValueError(kind)

    def text(self):
        base = super().text()
        head, separator, body = base.partition(f'[node name="{self.root_name}"')
        head_lines = head.rstrip("\n").split("\n")
        last_ext = max((i for i, line in enumerate(head_lines) if line.startswith("[ext_resource")), default=1)
        resources, nodes = [], []
        materials = {}
        uses_sand = any(key[2] == "sand" for key in self.shapes)
        ext = []
        if uses_sand:
            ext.append(f'[ext_resource type="Shader" path="{SAND_SHADER}" id="sand_shader"]')
            resources += [
                '[sub_resource type="FastNoiseLite" id="FastNoiseLite_grain"]', "seed = 21", "frequency = 0.05",
                "fractal_octaves = 3", "",
                '[sub_resource type="NoiseTexture2D" id="NoiseTexture2D_grain"]', "width = 256", "height = 256",
                "seamless = true", 'noise = SubResource("FastNoiseLite_grain")', "",
                '[sub_resource type="ShaderMaterial" id="Material_sand"]', "render_priority = 0",
                'shader = ExtResource("sand_shader")', 'shader_parameter/grain_noise = SubResource("NoiseTexture2D_grain")',
                f"shader_parameter/tint = Vector3({fmt(SAND_TINT[0])}, {fmt(SAND_TINT[1])}, {fmt(SAND_TINT[2])})", "",
            ]
            materials["sand"] = "Material_sand"
        for key in self.shapes:
            name = key[2]
            if name in materials:
                continue
            color, roughness, metallic = MATERIALS[name]
            materials[name] = f"Material_{name}"
            resources += [f'[sub_resource type="StandardMaterial3D" id="Material_{name}"]',
                          f"albedo_color = Color({fmt(color[0])}, {fmt(color[1])}, {fmt(color[2])}, 1)",
                          f"roughness = {fmt(roughness)}"]
            if metallic:
                resources.append(f"metallic = {fmt(metallic)}")
            resources.append("")
        if self.shapes:
            nodes += ['[node name="Shapes" type="Node3D" parent="."]', ""]
        for index, (key, instances) in enumerate(self.shapes.items()):
            kind, params, material, shadow, fade = key
            mesh_type, mesh_lines = self._mesh_text(kind, dict(params), materials[material])
            resources += [f'[sub_resource type="{mesh_type}" id="Mesh_{index}"]',
                          f'material = SubResource("{materials[material]}")', *mesh_lines, ""]
            extra = []
            if not shadow:
                extra.append("cast_shadow = 0")
            if fade:
                extra += [f"visibility_range_end = {fmt(fade)}", "visibility_range_end_margin = 8.0",
                          "visibility_range_fade_mode = 1"]
            if len(instances) >= 3:
                # Une forme qui s'efface au loin est découpée en cases, chacune avec sa propre distance.
                groups = {}
                for basis, origin in instances:
                    cell = (math.floor(origin[0] / CHUNK), math.floor(origin[2] / CHUNK)) if fade else (0, 0)
                    groups.setdefault(cell, []).append((basis, origin))
                for part, members in enumerate(groups.values()):
                    values = []
                    for basis, origin in members:
                        for row in range(3):
                            values += [basis[row][0], basis[row][1], basis[row][2], origin[row]]
                    resources += [f'[sub_resource type="MultiMesh" id="MultiMesh_{index}_{part}"]', "transform_format = 1",
                                  f"instance_count = {len(members)}", f'mesh = SubResource("Mesh_{index}")',
                                  "buffer = PackedFloat32Array(" + ", ".join(fmt(v) for v in values) + ")", ""]
                    nodes += [f'[node name="{kind}_{index}_{part}" type="MultiMeshInstance3D" parent="Shapes"]',
                              f'multimesh = SubResource("MultiMesh_{index}_{part}")', *extra, ""]
            else:
                for number, (basis, origin) in enumerate(instances):
                    nodes += [f'[node name="{kind}_{index}_{number}" type="MeshInstance3D" parent="Shapes"]',
                              f"transform = {transform_text(basis, origin)}", f'mesh = SubResource("Mesh_{index}")',
                              *extra, ""]
        for index, (transform, shape_type, data) in enumerate(self.extra_colliders):
            resources += [f'[sub_resource type="{shape_type}" id="Shape_{index}"]', data, ""]
            nodes += [f'[node name="Shape{index}" type="CollisionShape3D" parent="Collision"]',
                      f"transform = {transform}", f'shape = SubResource("Shape_{index}")', ""]
        head_lines = head_lines[: last_ext + 1] + ext + head_lines[last_ext + 1:]
        return "\n".join(head_lines + [""] + resources) + "\n" + separator + body.rstrip("\n") + "\n\n" + "\n".join(nodes)


def local_frame(cx, cz, heading):
    """Repère d'un groupe : (u, v) tourné de heading degrés autour du centre."""
    c, s = math.cos(math.radians(heading)), math.sin(math.radians(heading))
    return lambda u, v, y=0.0: (cx + c * u + s * v, y, cz - s * u + c * v)


def put(scene, model, center, degrees=0.0, scale=1.0, height=None, tilt=0.0, roll=0.0, label=None, box=True):
    """furniture() de build_plaine, en retenant l'emprise de ce qui a une collision. box=False : pas de boîte,
    desert.gd taille la collision du modèle sur ses triangles (EXACT_MODELS), l'emprise reste vérifiée."""
    furniture(scene, model, center, degrees, scale, height=height if box else None, tilt=tilt, roll=roll)
    if height:
        (px, py, pz), (sx, sy, sz) = MODEL_BOXES[model]
        basis = multiply(multiply(rotation_y(degrees), rotation_x(tilt)), rotation_z(roll))
        xs, zs = [], []
        for cx in (px, px + sx):
            for cy in (py, py + sy):
                for cz in (pz, pz + sz):
                    local = (cx * scale, cy * scale, cz * scale)
                    xs.append(sum(basis[0][i] * local[i] for i in range(3)))
                    zs.append(sum(basis[2][i] * local[i] for i in range(3)))
        scene.footprints.append((label or model, center, (max(xs) - min(xs), height, max(zs) - min(zs)), 0.0))


# --- Éléments réutilisables -------------------------------------------------------------------------------


def mound(scene, x, z, a, h, b, degrees=0.0, y=0.0, collide=True):
    """Congère de sable : une calotte d'ellipsoïde de rayons a et b au sol et de hauteur h, en pente douce
    (h ≤ 0,3 a et 0,3 b pour rester praticable). Sa collision convexe se gravit à pied."""
    A, Bz = a / 0.866, b / 0.866
    scene.shape("sphere", {"segments": 14, "rings": 7}, "sand", (x, y - h, z), degrees, scale=(A, 2 * h, Bz))
    if collide and h > 0.25:
        points = [(0.0, h, 0.0)]
        for ratio, height in ((1.0, 0.0), (0.763, 0.5 * h), (0.503, 0.8 * h)):
            for k in range(10):
                angle = 2 * math.pi * k / 10
                points.append((math.cos(angle) * a * ratio, height, math.sin(angle) * b * ratio))
        scene.convex_collider((x, y, z), degrees, points)


def wall_piece(scene, x, z, length, height, degrees=0.0, thickness=1.2, base=0.0):
    """Pan de mur du monument : un mur du kit étiré, sa collision et quelques briques tombées au pied."""
    scene.add("mini_arena/wall", (x, base, z), degrees, (length, height, thickness / 0.6))
    if degrees % 180:
        scene.add_box((x, base + height / 2, z), (thickness, height, length))
    else:
        scene.add_box((x, base + height / 2, z), (length, height, thickness))


def brazier(scene, x, z, rng, toppled=False, y=0.0):
    """Brasero éteint : un fût de pierre, une vasque de bronze et ses charbons ; renversé, la vasque gît à côté."""
    scene.shape("cyl", {"top": 0.2, "bottom": 0.3, "height": 0.8, "segments": 8}, "stone_dark", (x, y + 0.4, z))
    scene.shape("cyl", {"top": 0.34, "bottom": 0.34, "height": 0.08, "segments": 8}, "stone", (x, y + 0.84, z))
    if toppled:
        angle = rng.uniform(0, 360)
        dx, dz = math.sin(math.radians(angle)), math.cos(math.radians(angle))
        bx, bz = x + dx * 0.95, z + dz * 0.95
        scene.shape("cyl", {"top": 0.46, "bottom": 0.22, "height": 0.3, "segments": 10}, "bronze", (bx, y + 0.3, bz),
                    angle, tilt=100.0)
        for k in range(6):
            r = rng.uniform(0.3, 1.0)
            a = angle + rng.uniform(-50, 50)
            scene.shape("box", {"size": (0.12, 0.08, 0.1)}, "charcoal",
                        (bx + math.sin(math.radians(a)) * r, y + 0.04, bz + math.cos(math.radians(a)) * r),
                        rng.uniform(0, 90), shadow=False)
        scene.shape("cyl", {"top": 0.5, "bottom": 0.5, "height": 0.02, "segments": 10}, "ash", (bx + dx * 0.5, y + 0.01, bz + dz * 0.5), shadow=False)
        scene.cylinder_collider((x, y + 0.45, z), 0.31, 0.9)
        return
    scene.shape("cyl", {"top": 0.48, "bottom": 0.24, "height": 0.32, "segments": 10}, "bronze", (x, y + 1.04, z))
    scene.shape("torus", {"inner": 0.44, "outer": 0.52, "rings": 12, "sides": 4}, "bronze", (x, y + 1.2, z))
    scene.shape("cyl", {"top": 0.42, "bottom": 0.42, "height": 0.04, "segments": 10}, "charcoal", (x, y + 1.15, z), shadow=False)
    for k in range(4):
        a = rng.uniform(0, 2 * math.pi)
        r = rng.uniform(0.05, 0.28)
        scene.shape("box", {"size": (0.12, 0.08, 0.1)}, "charcoal", (x + math.cos(a) * r, y + 1.19, z + math.sin(a) * r),
                    rng.uniform(0, 90), shadow=False)
    scene.cylinder_collider((x, y + 0.62, z), 0.32, 1.24)


def jars(scene, cx, cz, rng, count, radius, y=0.0, broken=True):
    """Groupe de jarres de terre : amphores et urnes, certaines couchées, des tessons autour."""
    placed = []
    for _ in range(count * 8):
        if len(placed) >= count:
            break
        angle, r = rng.uniform(0, 2 * math.pi), radius * math.sqrt(rng.random())
        x, z = cx + math.cos(angle) * r, cz + math.sin(angle) * r
        if any(math.hypot(x - px, z - pz) < 1.25 for px, pz in placed):
            continue
        placed.append((x, z))
        kind = rng.random()
        if kind < 0.55:
            scale = rng.uniform(1.4, 1.9)
            if rng.random() < 0.3:
                put(scene, "mini_dungeon/pot", (x, y, z), rng.uniform(0, 360), scale, height=0.5, roll=90.0)
            else:
                put(scene, "mini_dungeon/pot", (x, y, z), rng.uniform(0, 360), scale, height=0.43 * scale)
        else:
            scale = rng.uniform(2.4, 3.2)
            put(scene, "graveyard_kit/urn-round" if kind < 0.8 else "graveyard_kit/urn-square", (x, y, z),
                rng.uniform(0, 360), scale, height=0.28 * scale)
    if broken:
        for _ in range(2):
            angle, r = rng.uniform(0, 2 * math.pi), radius + rng.uniform(0.3, 0.9)
            put(scene, "food_kit/plate-broken", (cx + math.cos(angle) * r, y, cz + math.sin(angle) * r), rng.uniform(0, 360), 1.6)


GLYPHS = {
    "soleil": [("cyl", 0.0, 0.0, 0.0, 0.11), ("box", -0.19, 0.0, 0.0, (0.08, 0.04)), ("box", 0.19, 0.0, 0.0, (0.08, 0.04)),
               ("box", 0.0, 0.19, 0.0, (0.04, 0.08)), ("box", 0.0, -0.19, 0.0, (0.04, 0.08))],
    "oeil": [("box", 0.0, 0.0, 0.0, (0.36, 0.045)), ("cyl", 0.0, 0.0, 0.0, 0.075), ("box", 0.0, 0.12, 0.0, (0.26, 0.035))],
    "vagues": [("box", -0.12, 0.0, 35.0, (0.15, 0.04)), ("box", 0.0, 0.0, -35.0, (0.15, 0.04)), ("box", 0.12, 0.0, 35.0, (0.15, 0.04)),
               ("box", -0.12, -0.12, 35.0, (0.15, 0.04)), ("box", 0.0, -0.12, -35.0, (0.15, 0.04)), ("box", 0.12, -0.12, 35.0, (0.15, 0.04))],
    "colonnes": [("box", -0.12, 0.0, 0.0, (0.05, 0.28)), ("box", 0.0, 0.0, 0.0, (0.05, 0.28)), ("box", 0.12, 0.0, 0.0, (0.05, 0.28)),
                 ("box", 0.0, 0.16, 0.0, (0.34, 0.04))],
    "pointes": [("box", -0.07, 0.0, 40.0, (0.22, 0.045)), ("box", 0.07, 0.0, -40.0, (0.22, 0.045)), ("cyl", 0.0, -0.14, 0.0, 0.045)],
    "points": [("cyl", -0.12, 0.0, 0.0, 0.045), ("cyl", 0.0, 0.0, 0.0, 0.045), ("cyl", 0.12, 0.0, 0.0, 0.045)],
    "escalier": [("box", -0.12, -0.1, 0.0, (0.1, 0.06)), ("box", 0.0, -0.02, 0.0, (0.1, 0.06)), ("box", 0.12, 0.06, 0.0, (0.1, 0.06)),
                 ("box", 0.0, -0.13, 0.0, (0.34, 0.03))],
    "croix": [("box", 0.0, 0.0, 0.0, (0.3, 0.05)), ("box", 0.0, 0.0, 0.0, (0.05, 0.3))],
}


def glyph(scene, cx, cz, face, y, distance, lean, name, material="glyph"):
    """Symbole en relief sur la face d'un obélisque : face est le cap de la face, distance son écart à l'axe."""
    nx, nz = math.sin(math.radians(face)), math.cos(math.radians(face))
    rx, rz = math.cos(math.radians(face)), -math.sin(math.radians(face))
    for kind, u, v, roll, size in GLYPHS[name]:
        position = (cx + nx * distance + rx * u, y + v, cz + nz * distance + rz * u)
        if kind == "box":
            scene.shape("box", {"size": (size[0], size[1], 0.03)}, material, position, face, tilt=-lean, roll=roll,
                        shadow=False, fade=60.0)
        else:
            scene.shape("cyl", {"top": size, "bottom": size, "height": 0.03, "segments": 10}, material, position, face,
                        tilt=90.0 - lean, shadow=False, fade=60.0)


def obelisk(scene, x, z, rng, height=4.6, broken=False, degrees=0.0, fallen_towards=90.0):
    """Obélisque couvert de symboles en relief, sur un socle à deux degrés, coiffé d'or ; brisé, sa pointe gît à côté."""
    scene.shape("box", {"size": (1.9, 0.5, 1.9)}, "stone_dark", (x, 0.25, z), degrees)
    scene.shape("box", {"size": (1.35, 0.35, 1.35)}, "stone", (x, 0.675, z), degrees)
    y0, wb, wt = 0.85, 0.5, 0.3
    shaft = height * (0.5 if broken else 1.0)
    w_cut = wb - (wb - wt) * shaft / height
    lean = math.degrees(math.atan((wb - wt) / height))
    scene.shape("cyl", {"top": w_cut * SQ2, "bottom": wb * SQ2, "height": shaft, "segments": 4}, "stone",
                (x, y0 + shaft / 2, z), degrees + 45.0)
    if broken:
        for k in range(3):
            scene.shape("box", {"size": (0.32, 0.22, 0.28)}, "stone", (x + rng.uniform(-0.2, 0.2), y0 + shaft + 0.05, z + rng.uniform(-0.2, 0.2)),
                        rng.uniform(0, 90), tilt=rng.uniform(-20, 20))
        # La pointe brisée, couchée au pied du socle.
        length = height - shaft
        dx, dz = math.sin(math.radians(fallen_towards)), math.cos(math.radians(fallen_towards))
        px, pz = x + dx * (1.4 + length / 2), z + dz * (1.4 + length / 2)
        scene.shape("cyl", {"top": wt * SQ2, "bottom": w_cut * SQ2, "height": length, "segments": 4}, "stone",
                    (px, w_cut * 0.95, pz), fallen_towards, tilt=90.0, spin=45.0)
        tip = (px + dx * (length / 2 + 0.27), wt * 0.8, pz + dz * (length / 2 + 0.27))
        scene.shape("cyl", {"top": 0.0, "bottom": wt * SQ2, "height": 0.55, "segments": 4}, "gold", tip, fallen_towards, tilt=90.0, spin=45.0)
        scene.box_collider((px + dx * 0.25, w_cut * 0.9, pz + dz * 0.25), (w_cut * 2, w_cut * 1.8, length + 0.6), fallen_towards)
    else:
        scene.shape("cyl", {"top": 0.0, "bottom": wt * SQ2, "height": 0.55, "segments": 4}, "gold",
                    (x, y0 + height + 0.275, z), degrees + 45.0)
    names = list(GLYPHS)
    for face in range(4):
        f = degrees + face * 90.0
        row = 0
        while True:
            y = y0 + 0.6 + row * 0.7
            if y > y0 + shaft - 0.35:
                break
            distance = wb - (wb - wt) * (y - y0) / height + 0.012
            glyph(scene, x, z, f, y, distance, lean, rng.choice(names))
            row += 1
    scene.add_box((x, 0.25, z), (1.9, 0.5, 1.9), degrees)
    scene.add_box((x, 0.675, z), (1.35, 0.35, 1.35), degrees)
    scene.add_box((x, y0 + (shaft + 0.55) / 2, z), (wb * 2 + 0.04, shaft + 0.55, wb * 2 + 0.04), degrees)


def skeleton_beast(scene, x, z, degrees, size, rng, horns=False, walkable=False, y=0.0):
    """Squelette de bête couchée dans le sable : arceaux des côtes à demi enfouis, colonne, crâne et os épars.
    Avec walkable, on passe sous les côtes : seules leurs bases ont une collision."""
    frame = local_frame(x, z, degrees)
    ribs = 7
    length = 2.2 * size
    tops = []
    for i in range(ribs):
        t = i / (ribs - 1)
        v = -length / 2 + t * length
        radius = size * 0.55 * (1.0 - 0.45 * (2 * t - 1) ** 2)
        thick = 0.05 * size
        center = frame(0.0, v, y - 0.25 * radius)
        scene.shape("torus", {"inner": radius - thick, "outer": radius + thick, "rings": 14, "sides": 5}, "bone",
                    center, degrees, tilt=90.0)
        tops.append((v, y + 0.75 * radius + thick * 0.5))
        if walkable:
            for side in (-1, 1):
                foot = frame(side * radius * 0.97, v, 0.0)
                inward = frame(side * radius * 0.92, v, 0.0)
                scene.add_box((inward[0], y + 0.35, inward[2]), (thick * 2.2, 0.7, thick * 2.2), degrees)
    for i in range(ribs * 2 - 1):
        v0, h0 = tops[i // 2]
        v1, h1 = tops[min(i // 2 + 1, ribs - 1)]
        f = (i % 2) * 0.5
        v, h = v0 + (v1 - v0) * f, h0 + (h1 - h0) * f
        scene.shape("box", {"size": (0.16 * size, 0.12 * size, 0.14 * size)}, "bone", frame(0.0, v, h), degrees + rng.uniform(-8, 8))
    # Crâne allongé, orbites et mâchoire.
    skull = frame(0.0, length / 2 + 0.55 * size, y + 0.17 * size)
    scene.shape("cyl", {"top": 0.11 * size, "bottom": 0.22 * size, "height": 0.75 * size, "segments": 6}, "bone",
                skull, degrees, tilt=96.0, spin=30.0)
    for side in (-1, 1):
        eye = frame(side * 0.13 * size, length / 2 + 0.32 * size, y + 0.27 * size)
        scene.shape("sphere", {"segments": 8, "rings": 4}, "void", eye, scale=0.06 * size, shadow=False)
        if horns:
            horn = frame(side * 0.24 * size, length / 2 + 0.25 * size, y + 0.42 * size)
            scene.shape("cyl", {"top": 0.015 * size, "bottom": 0.06 * size, "height": 0.7 * size, "segments": 6}, "bone",
                        horn, degrees, tilt=-50.0, roll=-side * 35.0)
    jaw = frame(0.18 * size, length / 2 + 0.7 * size, y + 0.03 * size)
    scene.shape("box", {"size": (0.08 * size, 0.06 * size, 0.6 * size)}, "bone", jaw, degrees + 18.0)
    # Queue et os des pattes.
    for k in range(4):
        tail = frame(rng.uniform(-0.05, 0.05) * size, -length / 2 - (0.2 + 0.18 * k) * size, y + 0.04 * size)
        scene.shape("box", {"size": (0.1 * size, 0.08 * size, 0.12 * size)}, "bone", tail, degrees + rng.uniform(-30, 30), shadow=False)
    for side in (-1, 1):
        for along in (-0.6, 0.5):
            bone = frame(side * size * rng.uniform(0.75, 1.1), along * length, y + 0.04 * size)
            scene.shape("cyl", {"top": 0.035 * size, "bottom": 0.035 * size, "height": 0.85 * size, "segments": 6}, "bone",
                        bone, degrees + rng.uniform(40, 140), tilt=90.0)
    if not walkable:
        center = frame(0.0, 0.2 * size, 0.0)
        scene.add_box((center[0], y + 0.3 * size, center[2]), (1.15 * size, 0.6 * size, length + 1.2 * size), degrees)


def vulture_skull(scene, x, z, degrees, size=1.0, y=0.0, tilt=0.0):
    """Crâne de vautour : la boîte crânienne, le bec crochu et les orbites."""
    frame = local_frame(x, z, degrees)
    scene.shape("sphere", {"segments": 10, "rings": 5}, "bone", frame(0.0, 0.0, y + 0.09 * size), degrees,
                scale=(0.1 * size, 0.085 * size, 0.12 * size), fade=55.0)
    scene.shape("cyl", {"top": 0.012 * size, "bottom": 0.045 * size, "height": 0.2 * size, "segments": 5}, "bone",
                frame(0.0, 0.17 * size, y + 0.08 * size), degrees, tilt=100.0 + tilt, fade=55.0)
    scene.shape("cyl", {"top": 0.006 * size, "bottom": 0.018 * size, "height": 0.07 * size, "segments": 4}, "bone",
                frame(0.0, 0.265 * size, y + 0.045 * size), degrees, tilt=170.0, fade=55.0)
    for side in (-1, 1):
        scene.shape("sphere", {"segments": 6, "rings": 3}, "void", frame(side * 0.085 * size, 0.06 * size, y + 0.12 * size),
                    scale=0.03 * size, shadow=False, fade=40.0)


def lying_skeleton(scene, x, z, degrees, buried=True, y=0.0):
    """Squelette de voyageur couché sur le dos, à demi recouvert de sable."""
    put(scene, "graveyard_kit/character-skeleton", (x, y, z), degrees, 3.2, tilt=-90.0)
    if buried:
        frame = local_frame(x, z, degrees)
        a, _, b = frame(0.55, -0.35)
        mound(scene, a, b, 0.9, 0.22, 0.7, degrees, y=y, collide=False)


def stake_with_skull(scene, x, z, rng):
    """Pieu planté dans le sable, coiffé d'un crâne de vautour : la marque des pilleurs. Le chiffon noué au pieu,
    qui claque au vent, est posé par desert_life.gd (STAKES)."""
    scene.shape("cyl", {"top": 0.04, "bottom": 0.06, "height": 1.7, "segments": 5}, "wood_dark", (x, 0.85, z), rng.uniform(0, 90),
                tilt=rng.uniform(-6, 6))
    vulture_skull(scene, x, z + 0.02, rng.uniform(0, 360), 1.6, y=1.62)
    rng.choice(["cloth_red", "cloth_ochre"])
    rng.uniform(0, 360)
    rng.uniform(-10, 10)
    scene.add_box((x, 0.9, z), (0.25, 1.8, 0.25))


def shelf(scene, x, z, degrees, width, depth, height, levels, rng, contents):
    """Étagère de bois contre un mur, face vers +Z tournée de degrés : tablettes d'argile, rouleaux ou jarres."""
    frame = local_frame(x, z, degrees)
    for side in (-1, 1):
        scene.shape("box", {"size": (0.08, height, depth)}, "wood", frame(side * (width / 2 - 0.04), 0.0, height / 2), degrees)
    scene.shape("box", {"size": (width, height, 0.04)}, "wood_dark", frame(0.0, -depth / 2 + 0.02, height / 2), degrees)
    step = (height - 0.12) / levels
    for level in range(levels + 1):
        board = 0.1 + level * step
        scene.shape("box", {"size": (width - 0.08, 0.05, depth)}, "wood", frame(0.0, 0.0, board), degrees)
        if level == levels:
            break
        top = board + 0.025
        if contents == "tablettes":
            u = -width / 2 + 0.25
            while u < width / 2 - 0.2:
                if rng.random() < 0.8:
                    scene.shape("box", {"size": (0.26, min(0.36, step - 0.12), 0.05)}, "tablet",
                                frame(u, rng.uniform(-0.05, 0.08), top + min(0.36, step - 0.12) / 2), degrees + rng.uniform(-6, 6),
                                tilt=rng.uniform(-12, 4), shadow=False)
                u += rng.uniform(0.28, 0.4)
        elif contents == "rouleaux":
            count = int((width - 0.2) / 0.13)
            for row in range(2):
                for k in range(count - row):
                    if rng.random() < 0.85:
                        u = -width / 2 + 0.16 + (k + row * 0.5) * 0.13
                        scene.shape("cyl", {"top": 0.055, "bottom": 0.055, "height": depth * 0.85, "segments": 6}, "parchment",
                                    frame(u, 0.0, top + 0.055 + row * 0.1), degrees, tilt=90.0, shadow=False)
        elif contents == "jarres":
            u = -width / 2 + 0.3
            while u < width / 2 - 0.25:
                scene.shape("sphere", {"segments": 8, "rings": 5}, "clay", frame(u, 0.0, top + 0.17), scale=(0.17, 0.2, 0.17))
                scene.shape("cyl", {"top": 0.06, "bottom": 0.07, "height": 0.12, "segments": 6}, "clay", frame(u, 0.0, top + 0.38))
                u += rng.uniform(0.4, 0.55)
    center = frame(0.0, 0.0, 0.0)
    scene.solid(center, (width, height, depth) if degrees % 180 == 0 else (depth, height, width), 0.0, "étagère")


# --- Surface ----------------------------------------------------------------------------------------------


def build_gate(scene, rng):
    """Arche d'entrée à z = 16, entre deux pans de muraille qui s'effritent, sur le chemin du portail."""
    z = 16.0
    scene.add("mini_arena/wall-gate", (0.0, 0.0, z), 0.0, GATE_SCALE)
    side = (0.5 - GATE_HALF_OPENING) * GATE_SCALE
    offset = (GATE_HALF_OPENING * GATE_SCALE) + side / 2
    for sign in (-1, 1):
        scene.add_box((sign * offset, GATE_SCALE / 2, z), (side, GATE_SCALE, 0.6 * GATE_SCALE))
    lintel = GATE_SCALE * (1 - GATE_OPENING_HEIGHT)
    scene.add_box((0.0, GATE_SCALE - lintel / 2, z), (GATE_HALF_OPENING * 2 * GATE_SCALE, lintel, 0.6 * GATE_SCALE))
    for sign in (-1, 1):
        for index, model in enumerate(("wall", "wall", "wall-corner")):
            x = sign * (GATE_SCALE * (index + 1))
            scene.add(f"mini_arena/{model}", (x, 0.0, z), 0.0 if sign > 0 else 180.0, GATE_SCALE)
            if model == "wall-corner":
                # L'angle du kit est en L : un bras prolonge la muraille, l'autre tourne à son bout (vers le
                # portail à l'ouest, vers l'esplanade à l'est, l'angle étant retourné). Les bras font 1 m d'épaisseur
                # à hauteur d'homme ; le chapiteau qui couvre l'intérieur du L est hors de portée.
                scene.add_box((x - sign * 2.0, GATE_SCALE * 0.4, z - sign * 0.5), (1.0, GATE_SCALE * 0.8, 4.0))
                scene.add_box((x - sign * 0.5, GATE_SCALE * 0.4, z - sign * 2.0), (4.0, GATE_SCALE * 0.8, 1.0))
            else:
                scene.add_box((x, GATE_SCALE / 2, z), (GATE_SCALE, GATE_SCALE, 0.6 * GATE_SCALE))
        # Longues bannières plantées devant l'arche, côté portail : leur toile a sa collision.
        scene.add("castle_kit/flag-banner-long", (sign * 3.0, 0.0, z + 1.8), -90.0, 2.4)
        scene.add_box((sign * 3.0, 2.6, z + 1.85), (1.6, 5.2, 0.35))
        brazier(scene, sign * 5.8, z + 4.8, rng)
    for center, degrees in (((-7.0, 0.0, z + 3.0), 20.0), ((8.0, 0.0, z + 2.5), -40.0)):
        put(scene, "mini_arena/bricks", center, degrees, 3.0)
        scene.rubble_collider(center, "mini_arena/bricks", degrees, 3.0)
    # Le sable s'amasse contre la muraille, des deux côtés, loin du passage.
    for x, dz, a, h, b in ((-10.5, -2.4, 4.2, 1.0, 1.8), (10.5, -2.5, 4.5, 1.1, 2.0), (-12.8, 2.6, 4.0, 1.1, 1.7),
                           (12.6, 2.8, 4.0, 1.2, 1.8)):
        mound(scene, x, z + dz, a, h, b)
    # Un crâne de vautour sur un pieu, au bord du chemin : on entre sur une terre de pillards.
    stake_with_skull(scene, 4.6, 46.0, rng)


def build_avenue(scene, rng):
    """Allée des obélisques, de part et d'autre du chemin entre le portail et l'arche ; l'un est brisé."""
    for z in (24.0, 32.0, 40.0):
        for sign in (-1, 1):
            broken = sign > 0 and z == 32.0
            obelisk(scene, sign * 6.2, z, rng, broken=broken, fallen_towards=180.0 if broken else 90.0)


def build_monument(scene, rng):
    """Vestiges du monument des anciens bâtisseurs, centré en z = -6 : la salle des colonnes dallée, où la trappe
    de pierre s'ouvre sous le sable, entre les chambres du levant (ouest) et du zénith (est), devant le
    sanctuaire englouti au nord. Les pans de murs ont des hauteurs inégales et des brèches comblées de gravats."""
    for x in (-8.0, -4.0, 0.0, 4.0, 8.0):
        for z in (-14.0, -10.0, -6.0, -2.0, 2.0):
            scene.add("mini_arena/floor", (x, 0.02, z), 0.0, 4.0)
    for x, z, model in (
        (-10.0, -14.0, "column"), (-10.0, -6.0, "column-damaged"), (-10.0, 2.0, "column"),
        (10.0, -14.0, "column-damaged"), (10.0, -6.0, "column"), (10.0, 2.0, "column-damaged"),
    ):
        scene.add(f"mini_arena/{model}", (x, 0.0, z), 0.0, 3.6)
        scene.column_collider(x, z, 0.6 * 3.6, (1.0 if model == "column" else 0.72) * 3.6)
    scene.add("mini_arena/statue", (0.0, 0.0, -17.0), 0.0, 3.4)
    scene.add_box((0.0, 2.2, -17.0), (2.2, 4.4, 2.2))
    for x in (-5.0, 5.0):
        # Collision taillée sur la bannière par desert.gd (EXACT_MODELS) : son pied, sa hampe et sa toile.
        scene.add("mini_arena/banner", (x, 0.0, -17.5), 0.0, 3.4)
    # Autel des offrandes au pied de la statue, entre deux braseros.
    put(scene, "graveyard_kit/altar-stone", (0.0, 0.0, -14.6), 0.0, 2.0, height=1.0)
    put(scene, "graveyard_kit/detail-bowl", (-0.45, 0.98, -14.6), 20.0, 2.2)
    put(scene, "graveyard_kit/detail-chalice", (0.5, 0.98, -14.5), 0.0, 2.0)
    for x in (-2.8, 2.8):
        brazier(scene, x, -15.3, rng)
    # Braseros autour de la trappe, l'un renversé.
    brazier(scene, -3.6, -6.0, rng)
    brazier(scene, 3.6, -6.0, rng, toppled=True)
    # Colonne tombée dans l'avant-cour, une rune à côté (desert.tscn).
    put(scene, "mini_arena/column-damaged", (6.5, 0.0, 6.5), 0.0, 3.0, tilt=90.0)
    scene.cylinder_collider((6.5, 0.85, 6.5), 0.85, 2.16, 0.0, 90.0)

    # Murs de la salle des colonnes (x de -12 à 12, z de -19 à 5) : brèches à l'ouest et à l'est vers les
    # chambres, deux portes au nord vers le sanctuaire, une large ouverture au sud vers l'arche.
    for sign in (-1, 1):
        x = sign * 12.6
        wall_piece(scene, x, -16.7, 5.4, 3.4 if sign < 0 else 3.0, 90.0)
        wall_piece(scene, x, -8.0, 4.0, 2.6 if sign < 0 else 3.2, 90.0)
        wall_piece(scene, x, 0.0 if sign < 0 else -4.0, 4.0, 1.6, 90.0)
        wall_piece(scene, x, 4.0 if sign < 0 else 2.0, 4.0 if sign < 0 else 4.0, 2.8 if sign < 0 else 2.2, 90.0)
    # Gravats qui comblent les brèches de l'ouest (z de -6 à -2) et de l'est (z de 4 à 6 et de -2 à 0).
    put(scene, "mini_arena/bricks", (-12.6, 0.0, -4.0), 70.0, 3.2, height=1.3)
    put(scene, "mini_arena/bricks", (12.6, 0.0, -1.0), -20.0, 3.0, height=1.2)
    put(scene, "mini_arena/bricks", (12.4, 0.0, 4.9), 50.0, 2.6, height=1.05)
    wall_piece(scene, -10.9, -19.8, 3.4, 3.6)
    wall_piece(scene, 0.0, -19.8, 12.0, 4.2)
    wall_piece(scene, 10.9, -19.8, 3.4, 2.2)
    wall_piece(scene, -9.85, 5.4, 6.7, 2.2)
    wall_piece(scene, 10.6, 5.4, 5.2, 1.4)
    # Le sable a envahi les coins de la salle.
    mound(scene, -11.0, -18.2, 1.8, 0.5, 1.4)
    mound(scene, 11.2, 3.4, 1.5, 0.4, 1.6)
    mound(scene, 7.6, -18.4, 2.0, 0.45, 1.2)
    jars(scene, -10.6, -16.9, random.Random(31), 3, 0.8)
    jars(scene, 6.8, 2.8, random.Random(32), 3, 0.8)

    # Trappe de pierre au centre de la salle (desert.tscn) : son cadre de pierre et le sable qui la recouvre en partie.
    for dx, dz, sx, sz in ((0.0, -1.42, 3.1, 0.3), (0.0, 1.42, 3.1, 0.3), (-1.42, 0.0, 0.3, 2.54), (1.42, 0.0, 0.3, 2.54)):
        scene.shape("box", {"size": (sx, 0.1, sz)}, "stone_dark", (dx, 0.05, -6.0 + dz))
    mound(scene, 2.2, -7.0, 1.6, 0.32, 1.3, collide=False)
    mound(scene, -1.9, -4.8, 1.1, 0.22, 0.8, collide=False)

    build_west_room(scene, rng)
    build_east_room(scene, rng)
    build_sanctum(scene, rng)


def build_west_room(scene, rng):
    """Chambre du levant, à l'ouest de la salle : sa stèle (desert.tscn), une rune parmi les gravats, des jarres."""
    wall_piece(scene, -19.8, -14.6, 5.6, 2.8, 90.0)
    wall_piece(scene, -19.8, -7.9, 2.6, 2.0, 90.0)
    wall_piece(scene, -16.2, -17.4, 6.0, 3.0)
    wall_piece(scene, -17.4, -6.6, 3.6, 2.2)
    put(scene, "mini_arena/bricks", (-19.8, 0.0, -10.6), 80.0, 2.6, height=1.05)
    put(scene, "mini_arena/column-damaged", (-16.6, 0.0, -9.0), 30.0, 2.4, height=1.5, tilt=90.0)
    jars(scene, -18.2, -15.6, random.Random(41), 3, 0.8)
    mound(scene, -18.6, -12.4, 1.2, 0.35, 1.8)
    put(scene, "graveyard_kit/debris", (-14.6, 0.0, -16.2), 30.0, 2.6)


def build_east_room(scene, rng):
    """Chambre du zénith, à l'est : sa stèle (desert.tscn), un tas de sable vide, des tablettes brisées."""
    wall_piece(scene, 19.8, -12.6, 9.6, 2.6, 90.0)
    wall_piece(scene, 16.2, -17.4, 6.0, 2.4)
    wall_piece(scene, 15.0, -6.6, 3.6, 2.8)
    put(scene, "castle_kit/rocks-small", (18.0, 0.0, -7.8), 30.0, 2.2, height=1.1)
    put(scene, "mini_arena/block", (14.0, 0.0, -15.6), 25.0, 1.4, height=0.7)
    put(scene, "mini_arena/block", (15.9, 0.0, -16.2), 70.0, 1.2, height=0.6)
    jars(scene, 18.4, -15.6, random.Random(42), 2, 0.7)
    for k in range(5):
        scene.shape("box", {"size": (0.4, 0.06, 0.3)}, "tablet", (14.4 + k * 0.1, 0.03 + k * 0.06, -12.6 + k * 0.05),
                    rng.uniform(-30, 30), shadow=False)
    mound(scene, 18.6, -10.2, 1.2, 0.35, 1.6)


def build_sanctum(scene, rng):
    """Sanctuaire englouti au nord : une façade à demi enfouie sous une dune, sa porte scellée comblée de sable,
    un portique de colonnes dont une partie de l'architrave a basculé."""
    z = -29.0
    scene.add("mini_arena/wall-gate", (0.0, -2.0, z), 0.0, 6.0)
    for sign in (-1, 1):
        for k in (1, 2):
            scene.add("mini_arena/wall", (sign * 6.0 * k, -2.0, z), 0.0 if sign > 0 else 180.0, 6.0)
    scene.add_box((0.0, 2.0, z), (30.0, 4.0, 3.6))
    mound(scene, 0.0, -34.2, 18.0, 4.2, 6.5)
    mound(scene, -16.4, z, 3.8, 3.0, 3.6)
    mound(scene, 16.4, z, 3.8, 3.2, 3.6)
    mound(scene, 0.0, -26.3, 2.6, 1.3, 1.4)
    mound(scene, -8.5, -26.5, 4.2, 1.3, 1.5)
    mound(scene, 8.2, -26.4, 4.4, 1.4, 1.6)
    pz = -23.4
    for x in (-11.5, -7.5, -3.5, 3.5):
        scene.add("mini_arena/column", (x, -1.2, pz), 0.0, (4.0, 6.5, 4.0))
        scene.column_collider(x, pz, 0.6 * 4.0, 6.5, base=-1.2)
        mound(scene, x, pz, 1.9, 0.55, 1.6, collide=False)
    scene.add("mini_arena/column-damaged", (7.5, -1.2, pz), 0.0, (4.0, 3.0, 4.0))
    scene.add_box((7.5, 0.5, pz), (2.3, 1.0, 2.3))
    put(scene, "mini_arena/column", (14.6, 0.0, -21.6), 90.0, (4.0), height=2.4, tilt=90.0)
    scene.shape("box", {"size": (10.6, 0.9, 2.6)}, "stone", (-7.5, 5.75, pz))
    scene.shape("box", {"size": (11.0, 0.25, 2.9)}, "stone_dark", (-7.5, 6.32, pz))
    # L'architrave de l'est a basculé : elle repose sur la colonne et touche le sable.
    angle = math.degrees(math.atan2(5.0, 4.9))
    scene.shape("box", {"size": (7.1, 0.9, 2.6)}, "stone", (7.15, 2.8, pz), roll=-angle)
    scene.box_collider((7.15, 2.8, pz), (7.1, 0.9, 2.6), roll=-angle)
    for x, z2, degrees in ((10.0, -25.7, 25.0), (5.2, -25.9, 60.0), (12.1, -24.0, 80.0)):
        put(scene, "mini_arena/block", (x, 0.0, z2), degrees, 1.5, height=0.75)
    vulture_skull(scene, 9.4, -21.2, 200.0, 1.7)


def build_caravan(scene, rng):
    """Halte d'une caravane de marchands surprise par la tempête, à l'ouest : tentes, étals de marchandises,
    feu éteint, charrette renversée, le squelette du caravanier près de son carnet et celui de sa bête."""
    cx, cz, _ = REPLATS["caravane"]
    heading = 40.0
    at = local_frame(cx, cz, heading)
    put(scene, "nature_kit/campfire_stones", at(0.0, 0.0), heading, 3.0)
    for yaw in (30.0, -40.0):
        scene.shape("cyl", {"top": 0.09, "bottom": 0.09, "height": 1.1, "segments": 6}, "charcoal", at(0.0, 0.0, 0.12), heading + yaw, tilt=90.0)
    scene.shape("cyl", {"top": 0.6, "bottom": 0.6, "height": 0.02, "segments": 10}, "ash", at(0.0, 0.0, 0.01), shadow=False)
    put(scene, "survival_kit/tent-canvas", at(-4.2, -3.2), heading + 50.0, 5.5, height=2.7)
    put(scene, "nature_kit/tent_detailedOpen", at(4.0, -3.4), heading - 45.0, 3.6, height=2.0)
    # Étals ouverts sous leur auvent : collision taillée sur leurs triangles par desert.gd (EXACT_MODELS).
    put(scene, "fantasy_town_kit/stall-red", at(-6.0, 3.4), heading + 90.0, 2.6, height=3.2, box=False)
    put(scene, "fantasy_town_kit/stall-green", at(5.8, 3.8), heading - 90.0, 2.6, height=3.2, box=False)
    put(scene, "furniture_kit/rugRectangle", at(-2.0, -1.8), heading + 50.0, 1.6)
    put(scene, "furniture_kit/rugRound", at(2.0, -1.0), heading, 1.8)
    put(scene, "survival_kit/box-large", at(2.6, 1.8), heading + 20.0, 3.6, height=0.9)
    put(scene, "survival_kit/chest", at(3.9, 0.3), heading + 20.0, 3.4, height=0.9)
    # Deux tonneaux côte à côte, droits, sans se toucher (le vérificateur compare leurs boîtes alignées).
    for x, z in ((-38.1, -27.4), (-39.7, -27.0)):
        rng.uniform(0, 360)
        put(scene, "mini_dungeon/barrel", (x, 0.0, z), 0.0, 2.6, height=1.25)
    put(scene, "survival_kit/barrel-open", at(7.0, 0.2), heading, 3.0, height=1.0)
    put(scene, "food_kit/bag", at(-7.4, 0.4), heading + 10.0, 1.2, height=1.0)
    put(scene, "food_kit/bag", at(-7.2, -0.7), heading + 80.0, 1.1, height=0.92)
    put(scene, "food_kit/bag-flat", at(-6.2, -0.8), heading + 30.0, 1.5)
    put(scene, "fantasy_town_kit/cart", at(-1.0, -7.0), heading + 100.0, 2.8, height=1.5, roll=90.0, box=False)
    put(scene, "fantasy_town_kit/wheel", at(1.9, -6.4), heading + 30.0, 2.8, roll=90.0)
    wheel_center = at(1.9, -6.4)
    scene.cylinder_collider((wheel_center[0], 0.25, wheel_center[2]), 0.62, 0.5)
    put(scene, "survival_kit/bedroll", at(-1.6, 2.8), heading + 10.0, 3.0)
    put(scene, "survival_kit/bedroll", at(1.0, 3.3), heading - 20.0, 3.0)
    # Le caravanier, à côté de la caisse où repose son carnet (desert.tscn), et un compagnon près des tentes.
    lying_skeleton(scene, *at(1.0, 5.2)[0::2], heading + 80.0)
    lying_skeleton(scene, *at(6.6, -1.6)[0::2], heading - 120.0)
    a = at(-1.5, 6.8)
    skeleton_beast(scene, a[0], a[2], heading - 90.0, 1.25, rng)
    jars(scene, *at(-7.6, -2.4)[0::2], random.Random(51), 3, 0.9)
    mound(scene, *at(-5.8, -5.0)[0::2], 2.4, 0.7, 1.8, heading)
    mound(scene, *at(0.2, -8.4)[0::2], 2.6, 0.6, 1.4, heading + 100.0)
    for u, v, yaw in ((5.2, -6.0, 30.0), (-5.6, 6.0, 200.0), (8.0, 3.0, 120.0)):
        b = at(u, v)
        vulture_skull(scene, b[0], b[2], heading + yaw, 1.6)
    # Marchandises sur les étals : pains, raisins, vin, sacs, jarres et plats.
    red = local_frame(*at(-6.0, 3.4)[0::2], heading + 90.0)
    green = local_frame(*at(5.8, 3.8)[0::2], heading - 90.0)
    counter = 0.37 * 2.6
    for frame, items in ((red, (("food_kit/bread", -0.7, 0.15, 1.6), ("food_kit/loaf-round", 0.2, 0.2, 0.9), ("food_kit/grapes", 0.75, 0.0, 1.3))),
                         (green, (("food_kit/wine-red", -0.75, 0.1, 0.8), ("food_kit/pot", -0.1, 0.1, 1.0), ("food_kit/bowl", 0.7, 0.15, 1.1)))):
        for model, u, v, scale in items:
            put(scene, model, frame(u, v, counter), rng.uniform(0, 360), scale)


def build_oasis(scene, rng):
    """Oasis asséchée, à l'est : un bassin de boue craquelée bordé de roseaux secs, des palmiers morts dont un
    couché, le puits et son abreuvoir, la jarre sacrée sur son socle, et une bête morte de soif."""
    cx, cz, _ = REPLATS["oasis"]
    px, pz, rx, rz = 41.0, -3.0, 5.0, 3.8
    for _ in range(46):
        angle, r = rng.uniform(0, 2 * math.pi), 0.45 * math.sqrt(rng.random())
        scene.shape("box", {"size": (rng.uniform(0.6, 1.3), 0.02, 0.05)}, "crack",
                    (px + math.cos(angle) * r * rx, -0.69, pz + math.sin(angle) * r * rz), rng.uniform(0, 180), shadow=False, fade=50.0)
    for _ in range(54):
        angle = rng.uniform(0, 2 * math.pi)
        r = rng.uniform(1.02, 1.14)
        h = rng.uniform(0.5, 1.1)
        scene.shape("cyl", {"top": 0.012, "bottom": 0.025, "height": 1.0, "segments": 4}, "wood_dark",
                    (px + math.cos(angle) * r * rx, h / 2, pz + math.sin(angle) * r * rz), rng.uniform(0, 360),
                    tilt=rng.uniform(-18, 18), roll=rng.uniform(-18, 18), scale=(1.0, h, 1.0), shadow=False, fade=50.0)
    for model, x, z, scale, yaw, tilt in (
        ("tree_palmTall", 35.0, -6.8, 6.0, 20.0, 0.0), ("tree_palm", 36.6, 4.4, 6.5, 140.0, 5.0),
        ("tree_palmDetailedTall", 44.2, 4.6, 5.6, 260.0, 0.0), ("tree_palmBend", 47.6, -3.8, 6.2, 200.0, 0.0),
        ("tree_palmShort", 43.8, -9.4, 5.0, 80.0, 8.0),
    ):
        scene.add(f"nature_kit/{model}", (x, 0.0, z), yaw, scale, tilt=tilt)
        scene.add_box((x, 1.5, z), (0.7, 3.0, 0.7))
    # Palmier couché, le tronc sur le sable.
    scene.add("nature_kit/tree_palmTall", (38.0, 0.0, -10.2), 300.0, 6.0, tilt=86.0)
    scene.box_collider((38.0 - 0.864 * 3.4, 0.4, -10.2 + 0.499 * 3.4), (0.7, 0.8, 7.0), 300.0)
    # Le puits : margelle de pierre, potence de bois, seau suspendu.
    wx, wz = 34.2, 1.5
    scene.shape("cyl", {"top": 1.15, "bottom": 1.2, "height": 0.9, "segments": 12}, "stone", (wx, 0.45, wz))
    scene.shape("torus", {"inner": 0.82, "outer": 1.26, "rings": 12, "sides": 4}, "stone_dark", (wx, 0.92, wz), scale=(1.0, 0.6, 1.0))
    scene.shape("cyl", {"top": 0.84, "bottom": 0.84, "height": 0.02, "segments": 12}, "void", (wx, 0.93, wz), shadow=False)
    for side in (-1, 1):
        scene.shape("box", {"size": (0.16, 2.3, 0.16)}, "wood", (wx + side * 1.34, 1.15, wz))
        scene.add_box((wx + side * 1.34, 1.15, wz), (0.2, 2.3, 0.2))
    scene.shape("cyl", {"top": 0.07, "bottom": 0.07, "height": 2.9, "segments": 6}, "wood", (wx, 2.15, wz), roll=90.0)
    scene.shape("box", {"size": (0.06, 0.35, 0.06)}, "wood", (wx + 1.5, 2.0, wz))
    scene.shape("cyl", {"top": 0.02, "bottom": 0.02, "height": 0.32, "segments": 4}, "rope", (wx, 1.97, wz))
    scene.add("survival_kit/bucket", (wx, 1.06, wz), 10.0, 4.0)
    scene.add_box((wx, 0.5, wz), (2.4, 1.0, 2.4))
    # Abreuvoir sec et jarres.
    scene.shape("box", {"size": (2.6, 0.55, 0.9)}, "stone", (wx, 0.275, wz + 3.1))
    scene.shape("box", {"size": (2.3, 0.02, 0.6)}, "crack", (wx, 0.56, wz + 3.1), shadow=False)
    scene.add_box((wx, 0.3, wz + 3.1), (2.6, 0.6, 0.9))
    jars(scene, 30.4, 4.6, random.Random(61), 4, 1.0)
    # La jarre sacrée, sur son socle, ceinte d'or : celle que l'algorithme apprend à remplir.
    jx, jz = 31.4, -0.6
    scene.shape("box", {"size": (0.9, 0.7, 0.9)}, "stone_dark", (jx, 0.35, jz))
    scene.shape("sphere", {"segments": 12, "rings": 7}, "clay", (jx, 1.15, jz), scale=(0.42, 0.5, 0.42))
    scene.shape("cyl", {"top": 0.17, "bottom": 0.2, "height": 0.32, "segments": 10}, "clay", (jx, 1.72, jz))
    scene.shape("torus", {"inner": 0.15, "outer": 0.23, "rings": 10, "sides": 4}, "clay", (jx, 1.88, jz))
    scene.shape("torus", {"inner": 0.38, "outer": 0.45, "rings": 14, "sides": 4}, "gold", (jx, 1.2, jz))
    scene.add_box((jx, 0.95, jz), (0.95, 1.9, 0.95))
    # Le joug d'un porteur d'eau, ses deux seaux renversés.
    scene.shape("box", {"size": (0.08, 0.08, 1.8)}, "wood", (37.5, 0.04, 6.5), 30.0)
    for along in (-0.95, 0.95):
        scene.add("survival_kit/bucket", (37.5 + 0.5 * along, 0.27, 6.5 + 0.866 * along), 30.0 + along * 40, 3.5, tilt=90.0)
    skeleton_beast(scene, 46.6, 2.4, 75.0, 1.25, rng)
    for x, z, yaw in ((42.6, 4.2, 30.0), (36.4, -2.6, 250.0), (45.6, -7.0, 120.0)):
        vulture_skull(scene, x, z, yaw, 1.6)
    put(scene, "nature_kit/cactus_short", (47.0, 0.0, 6.0), 30.0, 3.0, height=1.5)


def build_cistern(scene, rng):
    """Citerne des bâtisseurs, à l'ouest de la salle : une fosse aux murs épais, des pans de muraille du kit comme
    ceux de la salle, pas des boîtes unies (desert_terrain.gd la creuse),
    des colonnes qui portaient sa voûte, une poutre tombée en travers, et au fond, des jarres et un squelette."""
    x0, z0, x1, z1 = CISTERN_RECT
    ring = 1.25
    depth = CISTERN_DEPTH
    top = 1.0
    height = top + depth + 0.1
    center_y = top - height / 2
    cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
    length_x = x1 - x0 + 2 * ring
    length_z = z1 - z0
    for z in (z0 - ring / 2, z1 + ring / 2):
        scene.add("mini_arena/wall", (cx, top - height, z), 0.0, (length_x, height, ring / 0.6))
        scene.shape("box", {"size": (length_x + 0.2, 0.16, ring + 0.2)}, "stone_dark", (cx, top + 0.08, z))
        scene.box_collider((cx, center_y + 0.75, z), (length_x, height + 1.5, ring))
    for x in (x0 - ring / 2, x1 + ring / 2):
        scene.add("mini_arena/wall", (x, top - height, cz), 90.0, (length_z, height, ring / 0.6))
        scene.shape("box", {"size": (ring + 0.2, 0.16, length_z)}, "stone_dark", (x, top + 0.08, cz))
        scene.box_collider((x, center_y + 0.75, cz), (ring, height + 1.5, length_z))
    for x in (x0 - ring / 2, x1 + ring / 2):
        for z in (z0 - ring / 2, z1 + ring / 2):
            scene.shape("box", {"size": (1.6, 0.35, 1.6)}, "stone_dark", (x, 0.175, z))
            scene.shape("box", {"size": (1.3, 1.1, 1.3)}, "stone", (x, 0.9, z))
            scene.shape("box", {"size": (1.55, 0.22, 1.55)}, "stone_dark", (x, 1.56, z))
            scene.shape("box", {"size": (1.0, 0.15, 1.0)}, "stone", (x, 1.745, z))
            scene.box_collider((x, 0.175, z), (1.6, 0.35, 1.6))
            scene.box_collider((x, 1.6, z), (1.3, 2.5, 1.3))
    floor = -depth
    for x, z, damaged in ((x0 + 1.3, z0 + 1.2, False), (x1 - 1.3, z0 + 1.2, True), (x0 + 1.3, z1 - 1.2, True), (x1 - 1.3, z1 - 1.2, False)):
        if damaged:
            scene.add("mini_arena/column-damaged", (x, floor, z), 0.0, (1.6, 3.4, 1.6))
        else:
            scene.add("mini_arena/column", (x, floor, z), 0.0, (1.6, 3.0, 1.6))
    beam = math.degrees(math.atan2(length_z + 2 * ring, length_x))
    yaw = 90.0 - beam + 8.0
    scene.shape("box", {"size": (0.6, 0.55, 9.4)}, "wood_bleached", (cx, top + 0.45, cz), yaw, roll=4.0)
    for u in (-3.2, 2.6):
        scene.shape("box", {"size": (0.66, 0.61, 0.14)}, "bronze",
                    (cx + math.sin(math.radians(yaw)) * u, top + 0.45, cz + math.cos(math.radians(yaw)) * u), yaw, roll=4.0)
    for x, z in ((cx - 1.4, cz + 0.8), (cx + 1.6, cz - 1.0)):
        put(scene, "mini_dungeon/pot", (x, floor, z), rng.uniform(0, 360), 1.6, roll=90.0 if x > cx else 0.0)
    lying_skeleton(scene, cx + 0.4, cz + 1.2, 200.0, buried=False, y=floor)
    scene.add("survival_kit/bucket", (cx - 0.6, floor + 0.2, cz - 1.3), 40.0, 3.5, tilt=90.0)
    jars(scene, x1 + 2.6, z1 + 2.0, random.Random(71), 3, 0.9)
    vulture_skull(scene, x0 - 1.8, z0 - 2.2, 60.0, 1.6)


def build_head(scene, rng):
    """Tête colossale d'une statue des bâtisseurs, à demi enfouie au nord-ouest de l'arche ; un obélisque brisé et
    les outils d'un pilleur mort à la tâche."""
    hx, hz, _ = REPLATS["tete"]
    # Le visage (-Z du modèle) regarde l'arche et le monument, la tête un peu renversée en arrière.
    scene.add("nature_kit/statue_head", (hx, -1.8, hz), -56.0, 7.5, tilt=10.0)
    scene.add_box((hx, 2.4, hz), (4.0, 4.8, 3.0), -56.0)
    mound(scene, hx - 1.4, hz + 1.6, 4.4, 1.3, 2.6, -56.0)
    mound(scene, hx - 2.4, hz - 1.2, 2.6, 0.9, 2.0, 30.0)
    mound(scene, hx + 2.6, hz - 1.4, 2.0, 0.6, 1.6, 80.0)
    obelisk(scene, hx + 5.0, hz - 3.6, rng, broken=True, fallen_towards=150.0)
    for x, z, degrees in ((hx - 4.4, hz + 2.8, 20.0), (hx - 5.2, hz - 1.6, 65.0)):
        put(scene, "mini_arena/block", (x, 0.0, z), degrees, 1.5, height=0.75)
    lying_skeleton(scene, hx + 3.2, hz + 3.8, 210.0)
    put(scene, "survival_kit/tool-pickaxe", (hx + 4.4, 0.0, hz + 2.8), 60.0, 3.0, tilt=90.0)
    for x, z, yaw in ((hx - 3.0, hz + 4.6, 100.0), (hx + 6.0, hz + 0.6, 300.0)):
        vulture_skull(scene, x, z, yaw, 1.6)


def build_dune_ruins(scene, rng):
    """Ruines éparses dans les dunes : un poste de garde tombé au combat, une colonnade engloutie, la porte des
    vents, les tombes des caravaniers et la carcasse d'une bête des sables."""
    # Poste de garde : deux pans de mur, le squelette d'un soldat de Codia avec son bouclier et son épée.
    x, z, _ = REPLATS["poste"]
    wall_piece(scene, x - 2.5, z + 2.4, 3.0, 2.4, 0.0, thickness=1.2, base=0.0)
    wall_piece(scene, x + 0.3, z - 0.2, 3.0, 1.8, 90.0, thickness=1.2)
    put(scene, "mini_arena/column-damaged", (x + 2.6, 0.0, z + 3.4), 0.0, 2.6, height=1.9)
    put(scene, "mini_arena/bricks", (x - 1.4, 0.0, z + 0.6), 30.0, 2.4, height=1.0)
    lying_skeleton(scene, x - 2.0, z - 1.6, 30.0)
    put(scene, "mini_dungeon/shield-round", (x - 3.2, 0.0, z - 2.4), 40.0, 2.6, tilt=90.0)
    put(scene, "mini_dungeon/weapon-sword", (x - 0.8, 0.0, z - 2.6), 110.0, 2.6, tilt=90.0)
    brazier(scene, x + 2.0, z - 2.6, rng, toppled=True)
    mound(scene, x - 2.5, z + 4.0, 2.6, 0.8, 1.4)
    vulture_skull(scene, x + 1.2, z + 1.0, 140.0, 1.6)
    # Colonnade engloutie.
    x, z, _ = REPLATS["colonnade"]
    at = local_frame(x, z, 20.0)
    for u, model, height in ((-4.5, "column", 5.0), (-1.5, "column", 5.0), (1.5, "column-damaged", 4.2), (4.5, "column", 3.0)):
        p = at(u, 0.0, -1.4)
        scene.add(f"mini_arena/{model}", p, 20.0, (2.4, height, 2.4))
        visible = (1.0 if model == "column" else 0.72) * height - 1.4
        scene.column_collider(p[0], p[2], 0.6 * 2.4, (1.0 if model == "column" else 0.72) * height, base=-1.4)
        mound(scene, p[0], p[2], 1.4, 0.4, 1.2, collide=False)
    beam = at(-3.0, 0.0, 3.6 + 0.3)
    scene.shape("box", {"size": (4.6, 0.6, 1.5)}, "stone", beam, 20.0)
    put(scene, "mini_arena/block", at(1.0, 2.6), 50.0, 1.3, height=0.65)
    mound(scene, *at(0.0, -2.2)[0::2], 5.0, 1.2, 1.8, 20.0)
    skeleton_beast(scene, *at(1.5, 3.8)[0::2], 110.0, 1.2, rng)
    # Porte des vents : une arche seule au milieu des dunes, que le sable traverse.
    x, z, _ = REPLATS["porte"]
    scene.add("mini_arena/wall-gate", (x, -0.6, z), 35.0, 3.6)
    # Ses deux piliers, son linteau et sa grille baissée, comme l'arche d'entrée : pas de boîte pleine
    # qui arrêterait le joueur à un mètre de la grille.
    scale = 3.6
    side = (0.5 - GATE_HALF_OPENING) * scale
    offset = GATE_HALF_OPENING * scale + side / 2
    for sign in (-1, 1):
        scene.box_collider((x + math.cos(math.radians(35.0)) * sign * offset, -0.6 + scale / 2,
                            z - math.sin(math.radians(35.0)) * sign * offset), (side, scale, 0.6 * scale), 35.0)
    lintel = scale * (1 - GATE_OPENING_HEIGHT)
    scene.box_collider((x, -0.6 + scale - lintel / 2, z), (GATE_HALF_OPENING * 2 * scale, lintel, 0.6 * scale), 35.0)
    opening = scale * GATE_OPENING_HEIGHT
    scene.box_collider((x, -0.6 + opening / 2, z), (GATE_HALF_OPENING * 2 * scale, opening, 0.5), 35.0)
    for side in (-1, 1):
        dx, dz = math.cos(math.radians(35.0)) * side * 3.0, -math.sin(math.radians(35.0)) * side * 3.0
        put(scene, "mini_arena/column-damaged", (x + dx, 0.0, z + dz), 0.0, 2.4, height=1.7)
    mound(scene, x + 1.2, z + 2.0, 3.2, 0.9, 1.6, 35.0)
    lying_skeleton(scene, x - 2.2, z + 2.6, 120.0)
    vulture_skull(scene, x + 2.6, z - 1.6, 30.0, 1.6)
    # Tombes des caravaniers : cairns, pieux coiffés de crânes de vautours, tissus délavés.
    x, z, _ = REPLATS["tombes"]
    for dx, dz, degrees in ((-2.4, -1.0, 10.0), (0.0, 0.4, 60.0), (2.4, -0.6, 100.0), (-1.0, 2.6, 30.0)):
        put(scene, "mini_dungeon/stones", (x + dx, 0.0, z + dz), degrees, 1.5, height=0.45)
    for dx, dz in ((-3.6, 1.4), (3.4, 1.6), (1.2, 3.4)):
        stake_with_skull(scene, x + dx, z + dz, rng)
    lying_skeleton(scene, x + 0.6, z - 3.0, 250.0)
    put(scene, "fantasy_town_kit/wheel", (x - 3.4, 0.0, z - 2.8), 20.0, 2.8, roll=90.0)
    wheel_center = (x - 3.4, 0.0, z - 2.8)
    scene.cylinder_collider((wheel_center[0], 0.25, wheel_center[2]), 0.62, 0.5)
    # Bête des sables : une cage thoracique géante sous laquelle on passe.
    x, z, _ = REPLATS["bete"]
    skeleton_beast(scene, x, z, 155.0, 5.2, rng, horns=True, walkable=True)
    jars(scene, x - 3.6, z - 3.4, random.Random(81), 2, 0.6)
    for dx, dz, yaw in ((4.4, -3.0, 20.0), (-4.0, 3.2, 210.0)):
        vulture_skull(scene, x + dx, z + dz, yaw, 1.7)


# --- Cave des archives ------------------------------------------------------------------------------------

CELLAR_TILE = 4.0
CELLAR_HEIGHT = 4.15
# Cases de 4 m de la cave, par leur centre : la salle de 5 × 3 cases (x de -10 à 10, z de 0 à -12) et, au sud,
# la case de l'escalier qui remonte vers la trappe. Les murs ont 0,6 m d'épaisseur, vers l'intérieur des cases.
CELLAR_TILES = [(x, z) for x in (-8.0, -4.0, 0.0, 4.0, 8.0) for z in (-2.0, -6.0, -10.0)] + [(0.0, 2.0)]
CELLAR_NEIGHBOURS = {(0, -1): 180.0, (0, 1): 0.0, (1, 0): 90.0, (-1, 0): -90.0}
# Bord du fond où s'élève la porte scellée, sous l'inscription.
SEALED_DOOR = (0.0, -12.0)
# Case de l'escalier et hauteur de sa cage, sous la trappe.
STAIR_TILE = (0.0, 2.0)
SHAFT_HEIGHT = 5.4


def build_cellar(scene, rng):
    """Cave des archives, sombre et poussiéreuse : la table ronde de pierre au centre (desert.tscn), un algorithme
    gravé sur chaque mur, la porte scellée au fond sous son inscription, le coffre de pierre dans le coin nord-est
    sous son tas de sable, des étagères de tablettes et de rouleaux, des coffres et des jarres."""
    tiles = set(CELLAR_TILES)
    for x, z in CELLAR_TILES:
        scene.add("modular_dungeon_kit/template-floor", (x, 0.0, z), 0.0, 1.0)
        scene.add_box((x, -0.25, z), (CELLAR_TILE, 0.5, CELLAR_TILE))
        # La cage de l'escalier monte plus haut que la salle : on tient debout sur la dernière marche.
        ceiling = SHAFT_HEIGHT if (x, z) == STAIR_TILE else CELLAR_HEIGHT
        scene.add_box((x, ceiling + 0.25, z), (CELLAR_TILE, 0.5, CELLAR_TILE))
        # Un mur sur chaque bord qui ne donne sur aucune case : son pied regarde l'intérieur de la case.
        for (dx, dz), degrees in CELLAR_NEIGHBOURS.items():
            if (x + dx * CELLAR_TILE, z + dz * CELLAR_TILE) in tiles:
                continue
            edge = (x + dx * CELLAR_TILE / 2, z + dz * CELLAR_TILE / 2)
            model = "gate-door" if edge == SEALED_DOOR else "template-wall"
            scene.add(f"modular_dungeon_kit/{model}", (edge[0], 0.0, edge[1]), degrees, 1.0)
            height = SHAFT_HEIGHT if (x, z) == STAIR_TILE else CELLAR_HEIGHT
            size = (0.6, height, CELLAR_TILE) if dx else (CELLAR_TILE, height, 0.6)
            scene.add_box((edge[0] - dx * 0.3, height / 2, edge[1] - dz * 0.3), size)
    # Derrière la porte scellée, la roche : on ne voit plus le vide par les jours de l'arc.
    scene.shape("box", {"size": (6.4, 4.6, 0.2)}, "void", (0.0, 2.3, -12.85), shadow=False)
    # Colonnes de part et d'autre de la porte scellée.
    for x in (-4.0, 4.0):
        scene.add("mini_dungeon/column", (x, 0.0, -10.2), 0.0, 3.6)
        scene.column_collider(x, -10.2, 0.5 * 3.6, 1.1 * 3.6)
    # Tables de part et d'autre de l'escalier : une rune est posée sur chacune, bien en vue (desert.tscn).
    for x in (-7.0, 7.0):
        furniture(scene, "mini_dungeon/table", (x, 0.0, -1.9), 0.0, 3.0, height=0.93)
    # Poutres du plafond.
    for z in (-3.0, -7.0, -11.0):
        scene.shape("box", {"size": (18.8, 0.35, 0.4)}, "wood_dark", (0.0, CELLAR_HEIGHT - 0.18, z))
    # Archives : étagère de tablettes au nord-ouest, casiers à rouleaux de part et d'autre de l'escalier.
    shelf(scene, -7.0, -10.95, 0.0, 2.6, 0.75, 2.7, 4, rng, "tablettes")
    shelf(scene, -3.9, -0.98, 180.0, 2.5, 0.65, 2.2, 4, rng, "rouleaux")
    shelf(scene, 3.9, -0.98, 180.0, 2.5, 0.65, 2.2, 4, rng, "rouleaux")
    # Coffre ouvert le long du mur ouest, des rouleaux rangés dedans ; tablettes empilées près des colonnes.
    put(scene, "mini_dungeon/chest", (-8.72, 0.0, -9.6), 0.0, 2.2, height=0.62)
    for k in range(3):
        scene.shape("cyl", {"top": 0.055, "bottom": 0.055, "height": 0.6, "segments": 6}, "parchment",
                    (-8.72 + (k - 1) * 0.14, 0.4, -9.6), 0.0, tilt=90.0, roll=0.0, shadow=False)
    for x, z in ((-5.25, -11.0), (5.25, -11.0)):
        for k in range(rng.randint(4, 7)):
            scene.shape("box", {"size": (0.42, 0.06, 0.3)}, "tablet", (x + rng.uniform(-0.04, 0.04), 0.03 + k * 0.062, z),
                        rng.uniform(-15, 15), shadow=False)
    # Pupitre de lecture : un rouleau ouvert, l'encrier et des bougies éteintes.
    furniture(scene, "mini_dungeon/table", (3.9, 0.0, -2.65), 0.0, 2.0, height=0.62)
    furniture(scene, "mini_dungeon/chair", (3.9, 0.0, -3.75), 180.0, 2.0, height=0.55)
    scene.shape("box", {"size": (0.7, 0.01, 0.42)}, "parchment", (3.75, 0.63, -2.65), 8.0, shadow=False)
    for dx in (-0.37, 0.37):
        scene.shape("cyl", {"top": 0.035, "bottom": 0.035, "height": 0.46, "segments": 6}, "parchment",
                    (3.75 + dx, 0.66, -2.65), 8.0, tilt=90.0, shadow=False)
    scene.shape("cyl", {"top": 0.04, "bottom": 0.05, "height": 0.08, "segments": 8}, "ink", (4.45, 0.66, -2.4), shadow=False)
    furniture(scene, "graveyard_kit/candle-multiple", (3.2, 0.62, -2.35), 0.0, 1.6)
    # Urnes contre les murs, sous les torches du sud.
    for x in (-8.9, 8.9):
        put(scene, "graveyard_kit/urn-round", (x, 0.0, -3.4), rng.uniform(0, 360), 2.8, height=0.78)
    # Rouleaux tombés au pied de l'étagère et poussière dans les coins.
    for k in range(5):
        scene.shape("cyl", {"top": 0.055, "bottom": 0.055, "height": 0.55, "segments": 6}, "parchment",
                    (-7.6 + k * 0.42 + rng.uniform(-0.1, 0.1), 0.055, -10.25 + rng.uniform(-0.12, 0.12)), rng.uniform(0, 180),
                    tilt=90.0, shadow=False)
    for x, z, a, b in ((-8.9, -0.9, 0.9, 0.7), (8.9, -11.0, 1.0, 0.9), (-2.2, -11.1, 1.2, 0.5), (2.3, -11.1, 1.2, 0.5)):
        mound(scene, x, z, a, 0.18, b, collide=False)


def check_footprints(scene):
    """Signale les emprises de collision qui se chevauchent dans une scène (boîtes alignées, sans tenir compte des caps)."""
    boxes = []
    for label, center, size, degrees in scene.footprints:
        half_x, half_z = size[0] / 2, size[2] / 2
        if degrees % 180:
            c, s = abs(math.cos(math.radians(degrees))), abs(math.sin(math.radians(degrees)))
            half_x, half_z = c * size[0] / 2 + s * size[2] / 2, s * size[0] / 2 + c * size[2] / 2
        boxes.append((label, center[0] - half_x, center[0] + half_x, center[2] - half_z, center[2] + half_z, center[1], center[1] + size[1]))
    for i, a in enumerate(boxes):
        for b in boxes[i + 1:]:
            if a[1] < b[2] - 0.05 and a[2] > b[1] + 0.05 and a[3] < b[4] - 0.05 and a[4] > b[3] + 0.05 and a[5] < b[6] - 0.05 and a[6] > b[5] + 0.05:
                print(f"  chevauchement : {a[0]} ({(a[1] + a[2]) / 2:.1f}, {(a[3] + a[4]) / 2:.1f}) et {b[0]} ({(b[1] + b[2]) / 2:.1f}, {(b[3] + b[4]) / 2:.1f})")


def main():
    for name, builders, seed in (
        ("desert_ruins", (build_gate, build_avenue, build_monument, build_caravan, build_oasis, build_cistern, build_head,
                          build_dune_ruins), 9),
        ("desert_cellar", (build_cellar,), 12),
    ):
        scene = DesertScene(name.title().replace("_", ""))
        rng = random.Random(seed)
        for build in builders:
            build(scene, rng)
        (OUTPUT_DIR / f"{name}.tscn").write_text(scene.text(), encoding="utf-8", newline="\n")
        shapes = sum(len(v) for v in scene.shapes.values())
        print(f"{name}.tscn : {len(scene.visuals)} modèles, {shapes} formes en {len(scene.shapes)} maillages, "
              f"{len(scene.colliders) + len(scene.extra_colliders)} collisions")
        check_footprints(scene)


if __name__ == "__main__":
    main()
