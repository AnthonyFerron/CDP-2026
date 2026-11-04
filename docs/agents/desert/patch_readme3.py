from pathlib import Path

p = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/scenes/levels/desert/README.md")
t = p.read_text(encoding="utf-8")
old = '''## Ambiance et vie'''
new = '''## Récit du lieu

Outre les stèles, le carnet du caravanier, l'inscription et les algorithmes, cinq textes se lisent avec E : la plaque du monument (mur sud de la salle des colonnes), le journal d'Elias, marchand qui a fui Vibelandia (posé sur l'abreuvoir de l'oasis), la lettre de Joran (sous la planche des tombes des caravaniers), la tablette d'un apprenti bâtisseur (chambre du zénith) et le rouleau de l'archiviste (pupitre de la cave). Ils aident à comprendre les boucles, les conditions et les leurres sans donner la solution.

## Performances

Au chargement, `desert.gd` regroupe les maillages fixes des ruines par matériau et par case de 32 m (`_merge_static`) : environ 430 appels de dessin en moyenne sur le parcours de mesure au lieu de 1 030. Les petits objets n'ont pas d'ombre et s'effacent au-delà de 70 m ; le soleil projette ses ombres sur 55 m en deux cascades.

## Ambiance et vie'''
assert old in t
p.write_text(t.replace(old, new, 1), encoding="utf-8", newline="\n")
print("ok")
