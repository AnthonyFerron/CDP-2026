REPLACEMENTS = [
('''    ITEMS.append((model, center[0] - w / 2, center[0] + w / 2, center[2] - d / 2, center[2] + d / 2,
                  center[1], center[1] + h, CURRENT[0]))''',
'''    ITEMS.append((model, center[0] - w / 2, center[0] + w / 2, center[2] - d / 2, center[2] + d / 2,
                  center[1], center[1] + h, CURRENT[0], getattr(scene, "group", "")))'''),
('''run("hub", hub)''', '''run("hub", hub)

# Meubles qui se chevauchent dans un même groupe (une pièce, en ruine ou reconstruite) : les tapis et les objets
# plats (moins de 6 cm) passent sous les autres, et un objet posé sur un meuble ne le touche que par sa base.
by_group = {}
for item in ITEMS:
    if item[8].startswith("Repairs/") and not any(word in item[0] for word in ("rug", "planks", "crops_", "crop_", "flower")):
        by_group.setdefault(item[8], []).append(item)
for group, items in by_group.items():
    for index, a in enumerate(items):
        for b in items[index + 1:]:
            if a[6] - a[5] < 0.06 or b[6] - b[5] < 0.06:
                continue
            if overlap(a[1:7], b[1:7], margin=0.05):
                results.append(f"{group}: {a[0]} ({(a[1]+a[2])/2:.1f}, {(a[3]+a[4])/2:.1f}) chevauche {b[0]} "
                               f"({(b[1]+b[2])/2:.1f}, {(b[3]+b[4])/2:.1f})")'''),
]
