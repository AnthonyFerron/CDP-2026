"""Génère le modèle 3D de Devlyn, le héros, d'après son dessin : un chevalier chibi aux cheveux blonds,
grosse tête, armure argentée, short bleu et jambières. Il regarde vers -z, comme le joueur.

En vue à la première personne, le corps ne se voit pas mais projette son ombre au sol. Les jambes et les bras
pendent à des articulations (hanches, épaules) que devlyn.gd balance pendant la marche : l'ombre marche aussi.

    python tools/build_devlyn.py
"""

from pathlib import Path

OUTPUT = Path(__file__).resolve().parent.parent / "scenes" / "player" / "devlyn.tscn"

# Articulations : nom, parent, position dans le repère du personnage. Le haut du corps rebondit à chaque pas,
# les jambes tournent autour des hanches et les bras autour des épaules.
JOINTS = [
    ("HipLeft", ".", (-0.13, 0.46, 0.0)),
    ("HipRight", ".", (0.13, 0.46, 0.0)),
    ("Upper", ".", (0.0, 0.46, 0.0)),
    ("ShoulderJointLeft", "Upper", (-0.34, 0.96, 0.0)),
    ("ShoulderJointRight", "Upper", (0.34, 0.96, 0.0)),
]
# Articulation de chaque pièce ; les autres suivent le haut du corps.
LIMBS = {
    "HipLeft": ("LegLeft", "KneeLeft", "BootLeft", "StrapLeft"),
    "HipRight": ("LegRight", "KneeRight", "BootRight", "StrapRight"),
    "ShoulderJointLeft": ("ArmLeft", "GauntletLeft", "HandLeft"),
    "ShoulderJointRight": ("ArmRight", "GauntletRight", "HandRight"),
}

MATERIALS = {
    "skin": ("Color(0.96, 0.78, 0.62, 1)", 0.8, 0.0),
    "hair": ("Color(0.86, 0.62, 0.24, 1)", 0.9, 0.0),
    "armor": ("Color(0.74, 0.77, 0.82, 1)", 0.35, 0.7),
    "armor_dark": ("Color(0.55, 0.58, 0.64, 1)", 0.4, 0.7),
    "leather": ("Color(0.45, 0.3, 0.2, 1)", 0.9, 0.0),
    "cloth": ("Color(0.16, 0.32, 0.62, 1)", 0.9, 0.0),
    "eye": ("Color(0.05, 0.05, 0.06, 1)", 0.3, 0.0),
    "eye_white": ("Color(0.97, 0.97, 0.97, 1)", 0.5, 0.0),
}

# Pièces : nom, forme, matériau, taille, position, rotation en degrés (x, y, z).
# Formes : box (x, y, z), sphere (rayon, hauteur), capsule (rayon, hauteur), cylinder (haut, bas, hauteur).
PARTS = [
    # Jambes : jambières et solerets d'acier, genouillères.
    ("LegLeft", "box", "armor", (0.2, 0.42, 0.22), (-0.13, 0.24, 0.0), (0, 0, 0)),
    ("LegRight", "box", "armor", (0.2, 0.42, 0.22), (0.13, 0.24, 0.0), (0, 0, 0)),
    ("KneeLeft", "box", "armor_dark", (0.22, 0.1, 0.06), (-0.13, 0.32, -0.12), (0, 0, 0)),
    ("KneeRight", "box", "armor_dark", (0.22, 0.1, 0.06), (0.13, 0.32, -0.12), (0, 0, 0)),
    ("BootLeft", "box", "armor", (0.24, 0.1, 0.34), (-0.13, 0.05, -0.05), (0, 0, 0)),
    ("BootRight", "box", "armor", (0.24, 0.1, 0.34), (0.13, 0.05, -0.05), (0, 0, 0)),
    ("StrapLeft", "box", "leather", (0.205, 0.05, 0.225), (-0.13, 0.43, 0.0), (0, 0, 0)),
    ("StrapRight", "box", "leather", (0.205, 0.05, 0.225), (0.13, 0.43, 0.0), (0, 0, 0)),
    # Short bleu et tassettes d'armure.
    ("Shorts", "box", "cloth", (0.46, 0.18, 0.28), (0.0, 0.53, 0.0), (0, 0, 0)),
    ("Tasset", "box", "armor", (0.36, 0.16, 0.06), (0.0, 0.55, -0.15), (8, 0, 0)),
    # Torse : plastron bombé et ceinture.
    ("Chest", "box", "armor", (0.54, 0.42, 0.34), (0.0, 0.83, 0.0), (0, 0, 0)),
    ("ChestPlate", "box", "armor", (0.42, 0.3, 0.06), (0.0, 0.87, -0.19), (-6, 0, 0)),
    ("Belt", "box", "armor_dark", (0.56, 0.07, 0.36), (0.0, 0.64, 0.0), (0, 0, 0)),
    ("Collar", "cylinder", "armor_dark", (0.17, 0.2, 0.08), (0.0, 1.06, 0.0), (0, 0, 0)),
    # Épaulières et bras : brassards de cuir, gantelets d'acier.
    ("ShoulderLeft", "sphere", "armor", (0.15, 0.22), (-0.33, 0.98, 0.0), (0, 0, 0)),
    ("ShoulderRight", "sphere", "armor", (0.15, 0.22), (0.33, 0.98, 0.0), (0, 0, 0)),
    ("ArmLeft", "box", "leather", (0.13, 0.22, 0.14), (-0.35, 0.82, 0.0), (0, 0, 6)),
    ("ArmRight", "box", "leather", (0.13, 0.22, 0.14), (0.35, 0.82, 0.0), (0, 0, -6)),
    ("GauntletLeft", "box", "armor", (0.17, 0.2, 0.17), (-0.37, 0.64, 0.0), (0, 0, 6)),
    ("GauntletRight", "box", "armor", (0.17, 0.2, 0.17), (0.37, 0.64, 0.0), (0, 0, -6)),
    ("HandLeft", "box", "armor_dark", (0.13, 0.1, 0.13), (-0.38, 0.5, 0.0), (0, 0, 0)),
    ("HandRight", "box", "armor_dark", (0.13, 0.1, 0.13), (0.38, 0.5, 0.0), (0, 0, 0)),
    # Tête de chibi : visage, oreilles, grands yeux.
    ("Head", "sphere", "skin", (0.33, 0.62), (0.0, 1.38, 0.0), (0, 0, 0)),
    ("EarLeft", "sphere", "skin", (0.06, 0.12), (-0.32, 1.36, 0.02), (0, 0, 0)),
    ("EarRight", "sphere", "skin", (0.06, 0.12), (0.32, 1.36, 0.02), (0, 0, 0)),
    ("EyeWhiteLeft", "sphere", "eye_white", (0.075, 0.15), (-0.12, 1.36, -0.27), (0, 0, 0)),
    ("EyeWhiteRight", "sphere", "eye_white", (0.075, 0.15), (0.12, 1.36, -0.27), (0, 0, 0)),
    ("EyeLeft", "sphere", "eye", (0.05, 0.1), (-0.12, 1.36, -0.32), (0, 0, 0)),
    ("EyeRight", "sphere", "eye", (0.05, 0.1), (0.12, 1.36, -0.32), (0, 0, 0)),
    ("Smile", "box", "eye", (0.09, 0.018, 0.02), (0.0, 1.24, -0.315), (0, 0, 0)),
    # Cheveux blonds : calotte, frange en mèches sur le front, longueurs sur la nuque et les côtés.
    ("HairCap", "sphere", "hair", (0.36, 0.6), (0.0, 1.47, 0.03), (0, 0, 0)),
    ("HairBack", "box", "hair", (0.6, 0.42, 0.24), (0.0, 1.3, 0.17), (0, 0, 0)),
    ("HairSideLeft", "box", "hair", (0.1, 0.36, 0.34), (-0.31, 1.3, 0.02), (0, 0, -6)),
    ("HairSideRight", "box", "hair", (0.1, 0.4, 0.3), (0.31, 1.27, 0.05), (0, 0, 8)),
    ("FringeLeft", "box", "hair", (0.3, 0.14, 0.08), (-0.14, 1.55, -0.28), (14, 0, -18)),
    ("FringeMiddle", "box", "hair", (0.22, 0.12, 0.08), (0.06, 1.56, -0.3), (14, 0, 10)),
    ("FringeRight", "box", "hair", (0.18, 0.12, 0.08), (0.22, 1.52, -0.27), (14, 0, 24)),
]


def basis(rotation):
    import math
    rx, ry, rz = (math.radians(a) for a in rotation)
    cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
    # Ordre Y * X * Z, comme Godot pour les nœuds.
    x = [[1, 0, 0], [0, cx, -sx], [0, sx, cx]]
    y = [[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]]
    z = [[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]]

    def mul(a, b):
        return [[sum(a[r][i] * b[i][c] for i in range(3)) for c in range(3)] for r in range(3)]

    m = mul(mul(y, x), z)
    return [m[r][c] for c in range(3) for r in range(3)]


def joint_of(part):
    for joint, parts in LIMBS.items():
        if part in parts:
            return joint
    return "Upper"


def joint_path(joint):
    """Chemin du nœud de l'articulation, depuis la racine, et sa position dans le repère du personnage."""
    joints = {name: (parent, position) for name, parent, position in JOINTS}
    parent, position = joints[joint]
    return (joint if parent == "." else f"{parent}/{joint}"), position


def main():
    lines = ['[gd_scene format=3]', "", '[ext_resource type="Script" path="res://scenes/player/devlyn.gd" id="1_devlyn"]', ""]
    for name, (color, roughness, metallic) in MATERIALS.items():
        lines += [f'[sub_resource type="StandardMaterial3D" id="Material_{name}"]', f"albedo_color = {color}",
                  f"roughness = {roughness:g}", f"metallic = {metallic:g}", ""]
    for name, shape, material, size, _, _ in PARTS:
        kind = {"box": "BoxMesh", "sphere": "SphereMesh", "cylinder": "CylinderMesh"}[shape]
        lines += [f'[sub_resource type="{kind}" id="Mesh_{name}"]', f'material = SubResource("Material_{material}")']
        if shape == "box":
            lines.append(f"size = Vector3({size[0]:g}, {size[1]:g}, {size[2]:g})")
        elif shape == "sphere":
            lines += [f"radius = {size[0]:g}", f"height = {size[1]:g}", "radial_segments = 12", "rings = 8"]
        else:
            lines += [f"top_radius = {size[0]:g}", f"bottom_radius = {size[1]:g}", f"height = {size[2]:g}", "radial_segments = 10"]
        lines.append("")
    lines += ['[node name="Devlyn" type="Node3D"]', 'script = ExtResource("1_devlyn")', ""]
    for name, parent, position in JOINTS:
        offset = (0.0, 0.0, 0.0) if parent == "." else joint_path(parent)[1]
        local = [round(position[i] - offset[i], 5) for i in range(3)]
        lines += [f'[node name="{name}" type="Node3D" parent="{"." if parent == "." else joint_path(parent)[0]}"]',
                  f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {local[0]:g}, {local[1]:g}, {local[2]:g})", ""]
    for name, _, _, _, position, rotation in PARTS:
        path, origin = joint_path(joint_of(name))
        local = [position[i] - origin[i] for i in range(3)]
        b = basis(rotation)
        values = ", ".join(f"{round(v, 5):g}" for v in b + local)
        lines += [f'[node name="{name}" type="MeshInstance3D" parent="{path}"]', f"transform = Transform3D({values})",
                  f'mesh = SubResource("Mesh_{name}")', ""]
    OUTPUT.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print(f"{OUTPUT.name} : {len(PARTS)} pièces")


if __name__ == "__main__":
    main()
