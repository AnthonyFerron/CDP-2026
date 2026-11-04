from pathlib import Path

p = Path("C:/Users/lebos/AppData/Local/Temp/claude/D--Anthony-Documents-GitHub-CDP-2026/859f48d8-d83e-4666-9a42-4295b9c6e433/scratchpad/agents/desert/write_desert_tscn.py")
t = p.read_text(encoding="utf-8")


def rep(old, new, count=1):
    global t
    assert t.count(old) == count, (t.count(old), old[:90])
    t = t.replace(old, new)


rep('''def ext(identifier):''', '''# Récit du lieu : textes laissés par les bâtisseurs et par les voyageurs qui ont fui la guerre. Chacun aide à comprendre
# les algorithmes de la cave sans donner la solution. Nom, parent, position (x, y, z), cap, titre, invite, rayon, corps,
# puis le panneau qui le porte : style (0 bois, 1 pierre, 2 parchemin), montage (0 poteaux, 1 mur), taille, hauteur,
# texte court, inclinaison (couché à plat : -90), ou None s'il n'y a pas de panneau.
LORE = [
    ("MonumentPlaque", "Exterior/Clues", (-10.5, 0.0, 6.0), 0.0, "Plaque du monument", "Lire la plaque", 2.6,
     "Monument des anciens bâtisseurs de Codia. Ici, les maîtres enseignaient l'art des instructions : décomposer un "
     "ouvrage en gestes simples, les écrire dans l'ordre où ils s'accomplissent, répéter un geste tant que l'ouvrage "
     "l'exige, et choisir un geste selon la réponse à une question. Leurs leçons furent gravées sur des runes et "
     "gardées dans les archives, sous la salle des colonnes.",
     (1, 1, (1.8, 0.95), 1.45, "MONUMENT DES ANCIENS BÂTISSEURS\\nIci l'on enseignait l'art des instructions", 0.0)),
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
     (0, 0, (1.3, 0.75), 1.1, "Caravane de Joran\\nQu'ils reposent en paix", 0.0)),
    ("ApprenticeTablet", "Exterior/Clues", (14.6, 0.0, -13.6), 0.0, "La tablette de l'apprenti", "Lire la tablette", 2.2,
     "Tablette d'argile d'un apprenti bâtisseur. L'élève avait gravé : « Pour chaque grain de sable, compter un. Fermer "
     "la porte à clé. » Le maître a rayé les deux lignes et gravé dessous : « Compter les grains ne remplit aucune jarre, "
     "et une porte que l'on ferme ne répond à personne. Ne grave que ce que l'ouvrage demande. »",
     (1, 0, (0.95, 0.62), 0.85, "Tablette d'un apprenti", 0.0)),
    ("ArchivistScroll", "Interior/Clues", (3.75, 0.64, -2.65), 0.0, "Le rouleau de l'archiviste", "Lire le rouleau", 2.0,
     "Rouleau resté ouvert sur le pupitre. « Avant d'ouvrir la porte du temple, le gardien pose une question au "
     "voyageur. Si la réponse est la bonne, il agit d'une façon ; sinon, il agit d'une autre, et la cité entière "
     "l'entend. Une condition commence par sa question et s'achève quand ses deux chemins se rejoignent. » En marge, "
     "d'une autre main : « Les runes rangées ici ont été mêlées à celles du dehors. Remettez-les dans l'ordre des murs. »",
     None),
]


def ext(identifier):''')
rep('''    node(lines, "RoundTable", "Node3D", "Interior", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, -6)"])''',
    '''    for name, parent, (x, y, z), yaw, title, prompt, radius, body, board in LORE:
        node(lines, name, "Node3D", parent, props=[
            at(x, y - 40.0 if parent.startswith("Interior") else y, z, 1.0, yaw), 'script = ExtResource("12_readable")',
            f"title = {quote(title)}", f"body = {quote(body)}", f"prompt = {quote(prompt)}", f"radius = {radius:g}"])
        if board:
            style, mount, size, height, text, tilt = board
            props = ['script = ExtResource("14_sign")', f'text = "{text}"', f"style = {style}", f"mount = {mount}",
                     f"board_size = Vector2({size[0]:g}, {size[1]:g})", f"board_height = {height:g}"]
            if tilt:
                props.insert(0, "transform = Transform3D(1, 0, 0, 0, 0, 1, 0, -1, 0, 0, 0, 0)")
            if style == 2:
                props.append("serif = false")
            node(lines, "Board", "Node3D", f"{parent}/{name}", props=props)

    node(lines, "RoundTable", "Node3D", "Interior", props=["transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, -6)"])''')
p.write_text(t, encoding="utf-8", newline="\n")
print("ok")
