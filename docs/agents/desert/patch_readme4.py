from pathlib import Path

p = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/scenes/levels/desert/README.md")
t = p.read_bytes().decode("utf-8")


def sub(old, new):
    global t
    assert t.count(old) == 1, old
    t = t.replace(old, new)


sub("| Chambres du levant et du zénith | Une stèle gravée dans chacune, jarres, tablettes brisées, une colonne tombée |",
    "| Chambres du levant et du zénith | Une stèle gravée dans chacune (socle, cadre, soleil et nom sur ses deux faces, fronton), jarres, tablettes brisées, une colonne tombée |")
sub("| Citerne | Fosse aux murs épais, colonnes de l'ancienne voûte, poutre tombée, jarres et squelette au fond |",
    "| Citerne | Fosse aux pans de muraille épais et piliers d'angle à chapiteau, colonnes de l'ancienne voûte, poutre tombée cerclée de bronze, jarres et squelette au fond |")
sub("Lumière chaude et dure, horizon voilé de chaleur",
    "Lumière chaude et dure ; la lumière ambiante est surtout chaude (le ciel n'en donne que 30 %), les ombres restent brunes au lieu de virer au vert-gris ; horizon voilé de chaleur")
sub("Les textes du monde sont écrits sur des `SignBoard` (panneau d'entrée, plaque de l'inscription) ou gravés à fleur de pierre (noms des stèles, algorithmes) : aucun texte ne flotte.",
    "Les textes du monde sont écrits sur des `SignBoard` (panneau d'entrée, plaque de l'inscription) ou gravés à fleur de pierre (noms des stèles, algorithmes) : aucun texte ne flotte. Les panneaux sur poteaux sont lisibles des deux côtés et les stèles n'ont pas de dos nu.\n\n"
    "Les collisions suivent les modèles au plus près : boîtes, cylindres et enveloppes taillés à la main dans `tools/build_desert.py`, et pour les formes ouvertes (étals sous leur auvent, charrette renversée, bannières sur pied, épaves de siège) leurs propres triangles (`EXACT_MODELS` dans `desert.gd`, `_add_wrecks` dans `desert_scatter.gd`).")
p.write_bytes(t.encode("utf-8"))
print("ok")
