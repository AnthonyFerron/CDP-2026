from pathlib import Path

p = Path("D:/Anthony/Documents/GitHub/CDP-2026/.claude/worktrees/agent-aa0011c5a70da2d39/frontend/scenes/levels/desert/README.md")
t = p.read_text(encoding="utf-8")


def rep(o, n):
    global t
    assert t.count(o) == 1, o[:60]
    t = t.replace(o, n)


rep('''4. La table ronde de pierre ouvre l'écran des runes. « Valider » reste grisé tant que les six emplacements ne sont pas remplis.''',
    '''4. La table ronde de pierre ouvre l'écran des runes, dans le style des menus : les deux algorithmes se font face, leurs lignes manquantes sont des cases de pierre gravées, et les runes en main des tuiles marquées chacune de son symbole (boucle, seau, jarre, question, embranchement, porte, cadenas, grains). On choisit une tuile, puis la case où la graver. « Valider » reste grisé tant que les six cases ne sont pas remplies.''')
rep('''Les textes du monde sont écrits''', '''## Ambiance et vie

Lumière chaude et dure, horizon voilé de chaleur et brume au ras des dunes ; des voiles de sable passent autour du joueur. Le vent siffle dans les ruines (sources sonores posées sur le sanctuaire, l'arche, la porte des vents, la colonnade, la bête des sables et la tête colossale). Dans la cave, la poussière flotte et tombe en filets du plafond. Des vautours tournent haut au-dessus des ossements, des lézards et des scorpions filent entre les pierres et fuient le joueur, et les toiles claquent au vent : fanions de la caravane et du poste de garde, chiffons des pieux, bannières du sanctuaire (`desert_life.gd`, `desert_cloth.gdshader`).

Les textes du monde sont écrits''')
rep('''| `desert_scatter.gd` | Cactus, rochers, ruines, épaves, restes épars, ossements et crânes de vautours, sables mouvants |''',
    '''| `desert_scatter.gd` | Cactus, rochers, ruines, épaves de siège ensablées, restes épars, ossements et crânes de vautours, sables mouvants ; les détails sont découpés en cases de 32 m pour s'effacer au loin case par case |
| `desert_life.gd`, `desert_cloth.gdshader` | Vautours, lézards et scorpions, toiles qui claquent au vent |''')
p.write_text(t, encoding="utf-8", newline="\n")
print("ok")
