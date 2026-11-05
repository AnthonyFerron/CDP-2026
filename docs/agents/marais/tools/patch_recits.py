"""Récit environnemental du Marais (BACKLOG n° 4) : cinq textes à lire de plus, et les panneaux sur poteaux lisibles des
deux côtés. Patch de write_marais_tscn.py, relançable : chaque remplacement vérifie qu'il s'applique une fois."""
import sys
from pathlib import Path

PATH = Path(sys.argv[1]) / "tools" / "write_marais_tscn.py"
text = PATH.read_text(encoding="utf-8")

REPLACEMENTS = [
    # Les nouveaux textes du dehors, après le panneau d'accueil.
    ('''     "veille sur les tombeaux des premiers rois de Codia.", "Lire le panneau", 2.6),
]''',
     '''     "veille sur les tombeaux des premiers rois de Codia.", "Lire le panneau", 2.6),
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
]'''),
    # Le panneau peut être lisible des deux côtés.
    ('''def sign(lines, name, parent, position, yaw, text, style, mount, size, height, line=0.15, serif=True, collision=True):
    """Panneau SignBoard : style 0 bois, 1 pierre, 2 parchemin, 3 fer ; mount 0 poteaux, 1 mur, 2 potence."""
    node(lines, name, "Node3D", parent, props=[
        at(*position, 1.0, yaw), f"script = {ext('17_sign')}", f"text = {quote(text)}", f"style = {style}",
        f"mount = {mount}", f"board_size = Vector2({size[0]:g}, {size[1]:g})", f"board_height = {height:g}",
        f"line_height = {line:g}", f"serif = {'true' if serif else 'false'}", f"collision = {'true' if collision else 'false'}"])''',
     '''def sign(lines, name, parent, position, yaw, text, style, mount, size, height, line=0.15, serif=True, collision=True,
         double_sided=False):
    """Panneau SignBoard : style 0 bois, 1 pierre, 2 parchemin, 3 fer ; mount 0 poteaux, 1 mur, 2 potence.
    double_sided : le texte et le cadre aussi au dos (panneau sur poteaux vu des deux côtés, jamais un dos nu)."""
    props = [
        at(*position, 1.0, yaw), f"script = {ext('17_sign')}", f"text = {quote(text)}", f"style = {style}",
        f"mount = {mount}", f"board_size = Vector2({size[0]:g}, {size[1]:g})", f"board_height = {height:g}",
        f"line_height = {line:g}", f"serif = {'true' if serif else 'false'}", f"collision = {'true' if collision else 'false'}"]
    if double_sided:
        props.append("double_sided = true")
    node(lines, name, "Node3D", parent, props=props)'''),
    # Panneaux du dehors : la plaque et l'accueil lisibles des deux côtés, puis les trois nouveaux.
    ('''    sign(lines, "Board", "Clues/Plaque", (0.0, -0.85, -0.35), 0.0, "Crypte du gardien", 1, 0, (1.3, 0.55), 1.05, 0.16)
    sign(lines, "Board", "Clues/Welcome", (0.0, -0.9, -0.35), 30.0, "Les marais de\\nKernel Swamp", 0, 0, (1.5, 0.8), 1.5, 0.2)''',
     '''    # Panneaux sur poteaux : texte et cadre des deux côtés, pour qu'aucun dos sombre ne se voie à contre-jour.
    sign(lines, "Board", "Clues/Plaque", (0.0, -0.85, -0.35), 0.0, "Crypte du gardien", 1, 0, (1.3, 0.55), 1.05, 0.16,
         double_sided=True)
    sign(lines, "Board", "Clues/Welcome", (0.0, -0.9, -0.35), 30.0, "Les marais de\\nKernel Swamp", 0, 0, (1.5, 0.8), 1.5, 0.2,
         double_sided=True)
    # L'avis du port, au bout du débarcadère, tourné vers l'arrivée ; l'ardoise d'Ada, entre sa tombe et la suivante,
    # tournée vers l'allée ; l'ordre du roi, au bout du dernier ponton, tourné vers lui.
    sign(lines, "Board", "Clues/Notice", (0.0, -0.9, 0.0), -42.0, "Capitainerie de Brumeval\\nAvis aux pêcheurs", 2, 0,
         (1.1, 0.75), 1.35, 0.13, double_sided=True)
    sign(lines, "Board", "Clues/AdaSlate", (0.0, -0.9, 0.0), 180.0, "Leçon d'Ada\\nBRUME devient DPWKG", 1, 0,
         (1.0, 0.6), 1.15, 0.13, double_sided=True)
    sign(lines, "Board", "Clues/RoyalOrder", (0.0, -0.9, 0.0), -19.0, "Ordre du roi\\nCodeon V", 2, 0, (1.0, 0.7), 1.35, 0.15,
         double_sided=True)'''),
    # Dans la crypte : le registre de l'ossuaire et le serment des gardiens, sur le mur plein de chaque chambre.
    ('''    write_niches(lines)
''',
     '''    # Registre de l'ossuaire et serment des gardiens : sur le pan de mur plein de chaque chambre du sud (au bout du
    # couloir, à z 2 à 6), sur le panneau central du mur, au-dessus de l'urne couchée et du cercueil.
    for name, x, facing, title, body, board, style, prompt in (
            ("OssuaryRegister", -14.0 - PANEL_FACE, -1.0, "Registre de l'ossuaire", OSSUARY_REGISTER,
             "Registre de l'ossuaire", 2, "Lire le registre"),
            ("GuardsOath", 14.0 + PANEL_FACE, 1.0, "Le serment des gardiens", GUARDS_OATH,
             "Serment des gardiens", 1, "Lire le serment")):
        node(lines, name, "Node3D", "Interior", props=[
            f"transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {x + facing * 0.37:g}, 1.6, 4)",
            'script = ExtResource("12_readable")', f"title = {quote(title)}", f"body = {quote(body)}",
            f"prompt = {quote(prompt)}", "radius = 3.0"])
        sign(lines, "Board", f"Interior/{name}", (-facing * 0.37, -1.6, 0.0), 90.0 * facing, board, style, 1,
             (1.3, 0.7), 1.75, 0.15)
    write_niches(lines)
'''),
    # Les deux textes de la crypte, à côté de l'inscription.
    ('''

# Pontons, comme MaraisTerrain.BOARDWALKS : début et fin.''',
     '''
OSSUARY_REGISTER = ("Ici reposent les bâtisseurs qui ont creusé la crypte sous le règne de Codeon I. Ils ont gravé "
                    "l'alphabet entier sur cinq cercles de pierre, un cercle par lettre du nom à inscrire : le premier "
                    "cercle, au centre, porte la première lettre, et le cinquième, au bord, la dernière. Le repère d'or, "
                    "au nord du mécanisme, montre la lettre choisie sur chaque cercle. Note du gardien : vérifier chaque "
                    "cercle avant de valider. Une erreur fait gronder la crypte, et le volcan s'éveille plus vite.")
GUARDS_OATH = ("Moi, gardien du marais, je jure de veiller sur le tombeau des rois et sur le livre des anciens "
               "bâtisseurs. Je ne prononcerai jamais le mot du mécanisme et ne l'écrirai jamais en clair. Je le "
               "garderai comme on me l'a appris : le nom du royaume, chaque lettre déplacée tour à tour vers l'avant "
               "puis vers l'arrière. Ainsi le secret survit aux gardiens.")


# Pontons, comme MaraisTerrain.BOARDWALKS : début et fin.'''),
]

for old, new in REPLACEMENTS:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"motif trouvé {count} fois : {old[:80]!r}")
    text = text.replace(old, new)
PATH.write_text(text, encoding="utf-8", newline="\n")
print("write_marais_tscn.py : récits ajoutés")
