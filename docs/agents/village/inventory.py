"""Écrit agents/village/INVENTAIRE.md à partir des données de tools/build_village.py et de write_village_tscn.py."""
import importlib.util
import sys
from pathlib import Path

frontend = Path(sys.argv[1])
here = Path(__file__).resolve().parent
sys.path.insert(0, str(frontend / "tools"))
import build_village as bv  # noqa: E402

spec = importlib.util.spec_from_file_location("writer", here / "write_village_tscn.py")
writer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(writer)

lines = ["# Inventaire du Village détruit", "",
         "Chaque ligne est vérifiée à l'étape 4 de la passe (colonne Vérification : test ou capture qui la couvre).", "",
         "| # | Élément | Position | Contenu / rôle | Vérification |", "| --- | --- | --- | --- | --- |"]
n = [0]


def row(element, position, role, check):
    n[0] += 1
    lines.append(f"| {n[0]} | {element} | {position} | {role} | {check} |")


row("Portail de retour", "(0, 63)", "éteint sans le livre, ramène au hub", "audit, village_test, grille de marche")
row("Panneau d'entrée « Codia »", "(-4.5, 55)", "SignBoard sur poteaux", "captures entrée")
row("Rempart sud", "z = 42, x de -30 à 30", "murs étroits, demi-murs, éboulis aux x ±18, ±26…", "grille de marche, captures")
row("Tours de la porte", "(±6, 42)", "base, milieu, sommet ; passage x de -4 à 4", "portes et passages, captures")
row("Vantail arraché", "(2.5, 47)", "couché devant la porte", "captures")
row("Tour de siège, bélier", "(-16, 52), (14, 50)", "engins de Vibelandia démolis", "grille de marche, captures")
row("Rempart ouest", "x = -34", "pans, porte de l'ouest (z = 6), maison du meunier (z -18 à -10)", "portes et passages")
row("Rempart est", "x = 34", "pans, brèche (z = -6), pans rehaussés sur la colline", "grille de marche")
row("Porte de l'ouest", "(-34.6, 2.9) et (-34.6, 9.1)", "deux piliers, rue du pont", "portes et passages")
row("Limite invisible", "rayon 72 m", "anneau de 72 murs invisibles", "village_bounds_test")
for number, house in enumerate(bv.HOUSES):
    cx, cz, w, d, side, style, floors = house
    frame = bv.Frame(number, house)
    row(f"Maison {number} : {bv.TRADES[number]}", f"({cx:g}, {cz:g}), {w}×{d} cases",
        f"porte {side} en ({frame.door[0]:g}, {frame.door[1]:g}), {style}, {floors} étage(s)"
        + (f", enseigne « {bv.SIGNS[bv.TRADES[number]]} »" if bv.TRADES[number] in bv.SIGNS else ""),
        "portes et passages, grille de marche, captures")
row("Grande rue", "x de -2.6 à 2.6, z de -20 à 64", "pavés, lanternes, traces de brûlure", "grille de marche, captures")
row("Place du marché", "(0, -2), rayon 11", "fontaine, colonne brisée, statue du roi fondateur, étals, cratère", "grille de marche, captures")
row("Fontaine", "(0, -2)", "bassin rond, collision en 4 boîtes", "grille de marche")
row("Rue du pont", "z = 6, x de -44 à 0", "jusqu'au pont du ruisseau", "portes et passages")
row("Ruisseau", "x = -38, z de -85 à 85", "lit creusé, eau à y = -0.45, sans collision d'eau", "liquides")
row("Pont de bois", "(-38, 6)", "traverse le ruisseau", "portes et passages, liquides")
row("Moulin à eau", "(-31, -14), roue en (-36.5, 1, -14)", "roue qui tourne, éclaboussures", "liquides, captures")
row("Moulin à vent", "(30, 4, -30)", "tour sur la colline, ailes, porte, sacs, meule", "grille de marche, captures")
row("Colline du moulin", "(30, -30), rayon 12", "relief", "grille de marche")
row("Barricade de la porte", "z = 35 à 39", "charrettes, tonneaux, caisses, pieux, armes, boucliers, flèches", "grille de marche, captures")
row("Mémorial des gardes", "(12, 37.5)", "stèle, plaque, lances, boucliers, bougies, fleurs ; Readable", "audit")
row("L'ordre du capitaine", "(-4.2, 35.2)", "Readable sur parchemin", "audit")
row("L'avis du maire", "(-4.6, 13)", "Readable, tableau d'affichage", "audit")
row("L'ardoise de la boulangère", "(4.9, 28.6)", "Readable", "audit")
row("Potagers", "(-27.8, 25.5) et (-27.8, 35)", "planches, clôture, épouvantail, potager brûlé", "grille de marche, captures")
row("Puits", "(-20, 29)", "margelle, toit, seau, chat gris", "grille de marche, captures")
row("Fils à linge", "(-18.5, 36.4) et (-22.5, -3)", "draps qui ondulent", "captures")
row("Écuries", "x 20 à 28, z 24 à 36", "stalles, mangeoires, foin, charrette, toit à demi effondré", "portes et passages, captures")
row("Enclos", "x 18 à 30, z 17.5 à 23.5", "clôture brisée, abreuvoir", "grille de marche")
row("Brèche de l'est et cratère", "(27, -3.5)", "boulet, charrette brûlée, poutres", "grille de marche, captures")
row("Champ de blé", "(19.25, -17.4)", "à moitié brûlé, bloc de collision", "grille de marche")
row("Tas de bois, billot, poulailler", "(-22, -25), (-26.4, -29)", "près du meunier", "grille de marche")
for x, z, size in writer.FIRES:
    row("Feu", f"({x:g}, {z:g})", f"taille {size:g}, braises, lumière", "captures")
row("Fumées", f"{len(writer.SMOKES)} colonnes + {len(writer.CHIMNEYS)} cheminées", "ruines, boulangerie, forge", "captures")
row("Corbeaux", f"{len(writer.CROWS)}", "s'envolent à l'approche (village_crow.gd)", "captures")
row("Chats", f"{len(writer.CATS)} qui marchent + 2 immobiles", "village_cat.gd", "captures")
row("Mairie (extérieur)", "(0, -26), 3×3 cases", "intacte, toit, enseigne, lanternes, fenêtres éclairées ; porte (HallDoor)", "audit, portes, captures")
row("Accueil (rez-de-chaussée)", "Interior, x ±8, z ±6", "comptoir, bureau de l'archiviste, armoires, étagères, table d'attente, coffre, bancs", "grille de marche intérieure, captures")
row("Escalier", "x 4.55 à 7.55, z 5 à -4", "15 marches et rampe, garde-corps", "escaliers")
row("Bureau du maire (étage)", "y +4.5", "bureau, tiroir, armoire, coffre, étagère, dispositif et inscription", "grille de marche, captures")
row("Plafonds", "accueil y 4, bureau y 8", "dalles", "plafonds")
row("Salle secrète", "x -16 à -8, z ±4", "pupitre de pierre, Codonomicon, bougies, bannières, urnes", "passage secret, captures")
row("Bibliothèque qui glisse", "(-7.25, 4.5, 0)", "devant le passage", "village_test, passage secret")
row("Sortie de la mairie", "(-2, 1.2, 5.55)", "porte de l'accueil", "audit, portes")
for number, (x, y, z), hidden in writer.FRAGMENT_SPOTS:
    row(f"Fragment {number}", f"({x:g}, {y:g}, {z:g})", "caché" if hidden else "posé", "audit")
for name, (x, y, z), label, number in writer.STORAGES:
    row(f"Meuble « {label} »", f"({x:g}, {y:g}, {z:g})", f"fragment {number}" if number is not None else "vide", "audit")
row("Dispositif des cinq codes", "(-1, 4.5, -5.4)", "panneau Ornate, sections, inscription", "audit, village_test")
row("Codonomicon", "(-12.6, 5.7, 0)", "sur le pupitre de pierre", "audit, village_test")
(here / "INVENTAIRE.md").write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
print(n[0], "éléments")
