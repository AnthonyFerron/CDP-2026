"""Textes à lire du récit environnemental des plaines d'Hexcole (BACKLOG n° 4), insérés dans plaine.tscn.

Repart chaque fois de la copie d'origine (base_plaine.tscn, posée à côté du dossier du script : c'est
`git show 69a21ae:frontend/scenes/levels/plaine/plaine.tscn`), puis ajoute :
- dehors, sous Exterior/Lore : trois panneaux (SignBoard sous un Readable) ;
- dedans, sous Interior/Lore : deux parchemins posés et un règlement au mur.

Usage : python3 lore.py <frontend>
"""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(sys.argv[1]) / "tools"))
from build_plaine import transform_of  # noqa: E402

FRONTEND = Path(sys.argv[1])
SCENE = FRONTEND / "scenes" / "levels" / "plaine" / "plaine.tscn"
BASE = Path(__file__).resolve().parent.parent / "base_plaine.tscn"


def q(text):
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def rotate(degrees, local):
    c, s = math.cos(math.radians(degrees)), math.sin(math.radians(degrees))
    x, y, z = local
    return (c * x + s * z, y, -s * x + c * z)


def add(a, b):
    return tuple(p + r for p, r in zip(a, b))


# ---------------------------------------------------------------------------------------------------------------
# Textes
# ---------------------------------------------------------------------------------------------------------------

FETE = (
    "Grande fête des foins d'Hexcole, an 5804, au premier jour de l'été, dans les prairies devant la bibliothèque. "
    "Fauche à l'aube, repas au bord des champs, concours du plus beau mouton et bal des moissonneurs à la nuit tombée. "
    "La bibliothécaire lira aux enfants l'histoire de Devlyn, vainqueur des Quatre Dragons du Chaos il y a deux ans. "
    "Elle mène la fête comme tous ses chantiers : chaque volontaire inscrit son nom au registre, et chacun saura sa "
    "tâche et son heure.\n\n"
    "En travers de l'affiche, quelqu'un a écrit au charbon : « Fête annulée. Vibelandia nous a déclaré la guerre. »"
)

ARPENTEUR = (
    "Relevé de l'arpenteur du roi Codeon V, an 5811.\n\n"
    "Les prairies d'Hexcole ne sont plus qu'un champ de bataille. J'ai compté sept cratères, creusés par les boulets "
    "de feu de Vibelandia ; au fond des plus profonds, la roche a fondu et la lave affleure. Une coulée relie "
    "maintenant deux d'entre eux et passe sous le pont du chemin.\n\n"
    "La terre est chaude jusqu'au pied du Mont Sam Altan, endormi depuis des siècles. Pourvu que les explosions ne le "
    "réveillent pas.\n\n"
    "Voyageur : ne quitte pas le pont, et n'approche pas des lacs de feu."
)

PROCLAMATION = (
    "Proclamation du roi Codeon V, an 5812.\n\n"
    "Codia ne peut plus contenir l'ennemi. Habitants d'Hexcole, quittez vos fermes et rejoignez sans attendre "
    "l'ancien bunker souterrain creusé non loin du château, bâti jadis pour servir de refuge en cas de catastrophe. "
    "N'emportez que de l'eau, du pain et une couverture. Les lourdes portes se refermeront à la nuit tombée.\n\n"
    "Au bas de l'affiche, d'une écriture pressée : « La bibliothécaire est restée pour sceller ses archives. "
    "Gardez-lui une place. »"
)

LETTRE = (
    "À toi qui descends dans les archives.\n\n"
    "Les troupes de Vibelandia sont aux portes des plaines. Je ne leur laisserai pas le Projenomicon : il repose "
    "derrière la grande dalle. La tablette à six emplacements des anciens bâtisseurs ne la rouvrira qu'à celui qui "
    "lui rendra, dans le même ordre, les paroles que je lui ai confiées.\n\n"
    "Ce sont les six répliques de ma dernière réunion avec mon employé. J'ai caché chaque morceau du compte rendu dans "
    "un livre de ces salles : un pillard ne lit pas, il brûle ; toi, tu liras. L'ordre est celui de tous nos projets, "
    "de la première idée au dernier bilan. Si tu te trompes, la pierre tremble.\n\n"
    "Ce soir, je rejoins les habitants au bunker du roi.\n"
    "La bibliothécaire d'Hexcole, an 5812"
)

GREFFIER = (
    "Notes du greffier, réunion sur la restauration des archives.\n\n"
    "La bibliothécaire et son employé ont parlé chacun son tour : elle propose, il répond, et chaque réplique reprend "
    "le fil de la précédente. Six répliques en tout, que j'ai recopiées dans l'ordre sur une seule feuille.\n\n"
    "Ce soir, la bibliothécaire m'a repris la feuille. Elle l'a découpée aux ciseaux, une réplique par morceau, et "
    "m'a fait promettre de ne jamais en dire l'ordre. Je tiens ma promesse."
)

# Affiche de la proclamation : son titre, l'ordre du roi et sa signature, comme une vraie affiche.
PROCLAMATION_BOARD = "PROCLAMATION ROYALE\n\nHabitants d'Hexcole, rejoignez sans attendre le bunker, non loin du château.\n\nCodeon V, roi de Codia"

REGLEMENT = (
    "Règlement de la bibliothèque d'Hexcole, sous l'autorité de la bibliothécaire.\n\n"
    "I. On parle bas : les livres dorment.\n"
    "II. Tout livre emprunté s'inscrit au registre, avec le nom du lecteur et la date.\n"
    "III. Un livre sorti de son rang porte un signet, pour qu'on sache où le remettre.\n"
    "IV. Chaque chantier se mène pas à pas : on ne passe à l'étape suivante qu'une fois la précédente achevée.\n"
    "V. Pas de bougie entre les rayonnages, pas de feu près des archives."
)

# ---------------------------------------------------------------------------------------------------------------
# Ressources des parchemins posés
# ---------------------------------------------------------------------------------------------------------------

RESOURCES = """[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_letter"]
albedo_color = Color(0.9, 0.83, 0.66, 1)
roughness = 1.0

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_letter_ink"]
albedo_color = Color(0.1, 0.07, 0.06, 1)
roughness = 1.0

[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_letter_seal"]
albedo_color = Color(0.5, 0.07, 0.05, 1)
roughness = 0.5

[sub_resource type="BoxMesh" id="BoxMesh_letter_sheet"]
material = SubResource("StandardMaterial3D_letter")
size = Vector3(0.26, 0.003, 0.34)

[sub_resource type="BoxMesh" id="BoxMesh_letter_line"]
material = SubResource("StandardMaterial3D_letter_ink")
size = Vector3(0.18, 0.001, 0.006)

[sub_resource type="CylinderMesh" id="CylinderMesh_letter_seal"]
material = SubResource("StandardMaterial3D_letter_seal")
top_radius = 0.026
bottom_radius = 0.026
height = 0.008
radial_segments = 12
rings = 1

"""


def readable(name, parent, transform, title, body, prompt, radius):
    return [
        f'[node name="{name}" type="Node3D" parent="{parent}"]',
        f"transform = {transform}",
        'script = ExtResource("12_readable")',
        f"title = {q(title)}",
        f"body = {q(body)}",
        f"prompt = {q(prompt)}",
        f"radius = {radius:g}",
        "",
    ]


def sign(parent, local, text, style, mount, size, height, line_height, roof=False, serif=True):
    lines = [
        f'[node name="Sign" type="Node3D" parent="{parent}"]',
        f"transform = {transform_of(local)}",
        'script = ExtResource("13_sign")',
        f"text = {q(text)}",
    ]
    if style:
        lines.append(f"style = {style}")
    if mount:
        lines.append(f"mount = {mount}")
    lines += [
        f"board_size = Vector2({size[0]:g}, {size[1]:g})",
        f"board_height = {height:g}",
        f"line_height = {line_height:g}",
    ]
    if roof:
        lines.append("roof = true")
    if not serif:
        lines.append("serif = false")
    return lines + [""]


def board(name, parent, foot, degrees, title, body, prompt, text, style, mount, size, height, line_height,
          radius=2.4, roof=False, front=0.3, serif=True):
    """Panneau lisible : le Readable devant la planche, à sa hauteur, et le SignBoard posé au pied (foot)."""
    point = add(foot, rotate(degrees, (0.0, height, front)))
    lines = readable(name, parent, transform_of(tuple(round(v, 3) for v in point), degrees), title, body, prompt,
                     radius)
    return lines + sign(f"{parent}/{name}", (0.0, -height, -front), text, style, mount, size, height, line_height,
                        roof, serif)


def paper(name, parent, position, degrees, title, body, prompt, radius, lines_count=6, seal=False, under=False):
    """Parchemin posé à plat : la feuille, ses lignes d'encre, et le cachet de cire d'une lettre.
    under : une seconde feuille dépasse dessous, pour une liasse de notes."""
    out = readable(name, parent, transform_of(position, degrees), title, body, prompt, radius)
    out += [f'[node name="Sheet" type="MeshInstance3D" parent="{parent}/{name}"]',
            'mesh = SubResource("BoxMesh_letter_sheet")', ""]
    if under:
        out += [f'[node name="Under" type="MeshInstance3D" parent="{parent}/{name}"]',
                f"transform = {transform_of((0.03, -0.0025, -0.025), 9.0)}",
                'mesh = SubResource("BoxMesh_letter_sheet")', ""]
    for index in range(lines_count):
        z = -0.125 + index * 0.04
        width = 0.55 if index == lines_count - 1 else 1.0
        out += [f'[node name="Line{index + 1}" type="MeshInstance3D" parent="{parent}/{name}"]',
                f"transform = {transform_of((-0.09 * (1 - width), 0.002, z), 0.0, (width, 1.0, 1.0))}",
                'mesh = SubResource("BoxMesh_letter_line")', ""]
    if seal:
        out += [f'[node name="Seal" type="MeshInstance3D" parent="{parent}/{name}"]',
                f"transform = {transform_of((0.06, 0.0055, 0.12))}",
                'mesh = SubResource("CylinderMesh_letter_seal")', ""]
    return out


# Positions : pied du panneau (x, y du sol, z) et orientation de sa face (+Z tourné de degrees).
FETE_FOOT = (3.3, 0.0, 47.8)
FETE_YAW = -30.0
DANGER_FOOT = (-4.3, 0.0, 35.0)
DANGER_YAW = 40.0
PROCLAMATION_FOOT = (-8.9, 0.0, 8.27)
# Sous la carte, en repère du nœud Interior (y = 0 au sol des archives).
# Dessus des tables, comme TABLE_TOP et DUNGEON_TABLE_TOP de build_plaine.py, à leur échelle.
TABLE_TOP = 0.327 * 3.0
DESK_TOP = 0.315 * 2.2
LETTER = (2.15, TABLE_TOP + 0.0015, -7.12)
NOTES = (2.48, DESK_TOP + 0.004, -15.95)
REGLEMENT_FOOT = (-0.95, 0.0, -11.75)


def exterior():
    out = []
    out += board("Fete", "Exterior/Lore", FETE_FOOT, FETE_YAW, "L'affiche de la fête des foins", FETE,
                 "Lire l'affiche", "Fête des foins d'Hexcole", 0, 0, (1.3, 0.78), 1.4, 0.17)
    out += board("Arpenteur", "Exterior/Lore", DANGER_FOOT, DANGER_YAW, "Le relevé de l'arpenteur royal", ARPENTEUR,
                 "Lire le panneau", "Danger : terre brûlante", 0, 0, (1.2, 0.66), 1.3, 0.16)
    out += board("Proclamation", "Exterior/Lore", PROCLAMATION_FOOT, 0.0, "La proclamation du roi", PROCLAMATION,
                 "Lire la proclamation", PROCLAMATION_BOARD, 2, 1, (0.9, 1.1), 1.55, 0.09, serif=False)
    return out


def interior():
    out = ['[node name="Lore" type="Node3D" parent="Interior"]', ""]
    out += paper("Lettre", "Interior/Lore", LETTER, -12.0, "La lettre de la bibliothécaire", LETTRE,
                 "Lire la lettre", 2.0, seal=True)
    out += paper("Greffier", "Interior/Lore", NOTES, 196.0, "Les notes du greffier", GREFFIER,
                 "Lire les notes", 2.2, lines_count=7, under=True)
    out += board("Reglement", "Interior/Lore", REGLEMENT_FOOT, 0.0, "Le règlement de la bibliothèque", REGLEMENT,
                 "Lire le règlement", "Règlement de la bibliothèque", 0, 1, (1.1, 0.7), 1.65, 0.15, radius=2.2)
    return out


def main():
    text = BASE.read_text(encoding="utf-8")
    lines = text.split("\n")
    first_node = lines.index('[node name="Plaine" type="Node3D"]')
    lines[first_node:first_node] = RESOURCES.rstrip("\n").split("\n") + [""]
    life = next(i for i, line in enumerate(lines) if line.startswith('[node name="Life" type="Node3D" parent="Exterior"'))
    lines[life:life] = exterior()
    books = lines.index('[node name="Books" type="Node3D" parent="Interior"]')
    lines[books:books] = interior()
    SCENE.write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print("plaine.tscn : textes du récit insérés")


if __name__ == "__main__":
    main()
