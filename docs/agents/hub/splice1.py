"""Intègre le château en ruine, les quartiers et le jardin du roi dans build_hub.py."""
import sys

AGENT = sys.argv[2]
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
castle = open(AGENT + "/castle_new.py", encoding="utf-8").read()
quarters = open(AGENT + "/quarters_new.py", encoding="utf-8").read()

# 1. En-tête : boîtes des nouveaux modèles et pose à l'échelle par axe.
old_import = "from build_plaine import WALL_HEIGHT, WALL_SCALE, OUTWARD_ANGLES, Scene, doorway, furniture, wall\n"
assert old_import in text
boxes = '''from build_plaine import (MEDIEVAL, MODEL_BOXES, OUTWARD_ANGLES, WALL_HEIGHT, WALL_SCALE, Scene, doorway, multiply,
                          rotation_x, rotation_y, rotation_z, wall)
from build_plaine import furniture as _furniture

# Boîtes englobantes (coin, taille, à l'échelle 1) des modèles ajoutés pour le hub.
MODEL_BOXES.update({
    "castle_kit/siege-catapult-demolished": ((-0.63, 0.0, -0.87), (1.67, 0.31, 1.66)),
    "castle_kit/siege-ram-demolished": ((-1.03, 0.0, -0.79), (2.07, 0.71, 1.64)),
    "fantasy_town_kit/chimney-base": ((0.07, 0.0, -0.25), (0.34, 1.0, 0.51)),
    "fantasy_town_kit/fountain-square": ((-1.0, 0.0, -1.0), (2.0, 0.45, 2.0)),
    "fantasy_town_kit/fountain-square-detail": ((-1.0, 0.0, -1.0), (2.0, 0.47, 2.0)),
    "fantasy_town_kit/hedge": ((0.25, 0.0, -0.5), (0.25, 0.25, 1.0)),
    "fantasy_town_kit/hedge-large": ((0.09, 0.0, -0.5), (0.39, 0.59, 1.0)),
    "food_kit/bag": ((-0.15, 0.0, -0.28), (0.31, 0.83, 0.57)),
    "food_kit/bag-flat": ((-0.31, 0.0, -0.22), (0.64, 0.18, 0.46)),
    "food_kit/loaf": ((-0.28, 0.0, -0.17), (0.57, 0.43, 0.37)),
    "food_kit/loaf-round": ((-0.38, 0.0, -0.25), (0.76, 0.28, 0.5)),
    "food_kit/loaf-baguette": ((-0.41, 0.0, -0.12), (0.82, 0.25, 0.25)),
    "food_kit/cutting-board": ((-0.28, 0.0, -0.4), (0.57, 0.05, 0.81)),
    "food_kit/rollingPin": ((-0.4, -0.07, -0.07), (0.81, 0.14, 0.15)),
    "food_kit/pot-stew": ((-0.32, 0.0, -0.4), (0.65, 0.35, 0.81)),
    "food_kit/mortar-pestle": ((-0.05, 0.0, -0.07), (0.1, 0.34, 0.12)),
    "food_kit/cabbage": ((-0.18, 0.0, -0.19), (0.37, 0.31, 0.39)),
    "food_kit/apple": ((-0.09, 0.0, -0.09), (0.19, 0.18, 0.19)),
    "food_kit/cheese": ((-0.34, 0.0, -0.34), (0.68, 0.21, 0.68)),
    "food_kit/carrot": ((-0.17, 0.0, -0.17), (0.34, 0.71, 0.34)),
    "food_kit/fish": ((-0.09, 0.0, -0.31), (0.19, 0.31, 0.62)),
    "mini_forest/ladder": ((-0.25, 0.0, -0.04), (0.5, 1.0, 0.14)),
    "mini_forest/target": ((-0.28, 0.0, -0.28), (0.55, 0.57, 0.46)),
    "mini_arena/weapon-rack": ((-0.41, 0.0, -0.14), (0.77, 0.46, 0.44)),
    "mini_arena/statue": ((-0.34, 0.0, -0.34), (0.69, 1.33, 0.69)),
    "mini_arena/trophy": ((-0.28, 0.0, -0.22), (0.56, 0.47, 0.44)),
    "mini_dungeon/shield-rectangle": ((-0.14, 0.0, -0.04), (0.28, 0.29, 0.12)),
    "mini_dungeon/potion": ((-0.15, 0.0, -0.15), (0.32, 0.39, 0.32)),
    "survival_kit/bucket": ((-0.07, 0.0, -0.07), (0.14, 0.18, 0.14)),
    "graveyard_kit/candle": ((-0.07, 0.0, -0.07), (0.14, 0.19, 0.14)),
    "graveyard_kit/bench-damaged": ((-0.47, 0.0, -0.22), (0.9, 0.51, 0.45)),
    "nature_kit/statue_block": ((-0.19, 0.0, -0.19), (0.39, 0.39, 0.39)),
    "nature_kit/statue_column": ((-0.14, 0.0, -0.14), (0.29, 1.0, 0.29)),
    "nature_kit/statue_columnDamaged": ((-0.14, 0.0, -0.14), (0.29, 0.69, 0.29)),
    "nature_kit/stump_old": ((-0.15, 0.0, -0.18), (0.35, 0.26, 0.37)),
    "nature_kit/tree_default": ((-0.37, 0.0, -0.32), (0.75, 1.7, 0.64)),
    "nature_kit/tree_oak": ((-0.31, 0.0, -0.37), (0.63, 1.23, 0.74)),
    "nature_kit/tree_fat": ((-0.37, 0.0, -0.32), (0.75, 1.14, 0.64)),
    "nature_kit/tree_thin_dark": ((-0.25, 0.0, -0.25), (0.68, 1.49, 0.62)),
    "nature_kit/canoe": ((-0.14, 0.0, -0.57), (0.29, 0.17, 1.14)),
})


def furniture(scene, model, center, degrees=0.0, scale=2.6, height=None, tilt=0.0, roll=0.0):
    """Comme furniture() de build_plaine, avec en plus une échelle par axe du modèle (x, y, z)."""
    if not isinstance(scale, tuple):
        return _furniture(scene, model, center, degrees, scale, height, tilt, roll)
    model = MEDIEVAL.get(model, model)
    (px, py, pz), (sx, sy, sz) = MODEL_BOXES[model]
    basis = multiply(multiply(rotation_y(degrees), rotation_x(tilt)), rotation_z(roll))
    corners = []
    for cx in (px, px + sx):
        for cy in (py, py + sy):
            for cz in (pz, pz + sz):
                local = (cx * scale[0], cy * scale[1], cz * scale[2])
                corners.append([sum(basis[r][i] * local[i] for i in range(3)) for r in range(3)])
    low = [min(c[i] for c in corners) for i in range(3)]
    high = [max(c[i] for c in corners) for i in range(3)]
    scene.add(model, (center[0] - (low[0] + high[0]) / 2, center[1] - low[1], center[2] - (low[2] + high[2]) / 2), degrees, scale,
              tilt=tilt, roll=roll)
    if height:
        if round(degrees) % 90 and not tilt and not roll:
            scene.add_box((center[0], center[1] + height / 2, center[2]), (sx * scale[0], height, sz * scale[2]), degrees)
        else:
            scene.add_box((center[0], center[1] + height / 2, center[2]), (high[0] - low[0], height, high[2] - low[2]))
'''
text = text.replace(old_import, boxes)

# 2. Nœuds à script (la roue du moulin) dans StagedScene.
old_init = '''        self.group = "Fixed"
        self.metadata = {}
'''
assert old_init in text
text = text.replace(old_init, '''        self.group = "Fixed"
        self.metadata = {}
        # Nœuds de groupe portant une position et un script : chemin -> (transformée, script, propriétés).
        self.pivots = {}
        self.scripts = {}

    def pivot(self, path, position, script, properties):
        """Ouvre un groupe posé en un point, avec un script : les ajouts suivants s'y placent dans son repère."""
        self.scripts.setdefault(script, f"{len(self.scripts) + 1}_script")
        self.pivots[path] = (f"Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, {position[0]:g}, {position[1]:g}, {position[2]:g})", script, properties)
        self.group = path
''')
old_ext = '''            lines.append(f'[ext_resource type="PackedScene" path="{path}" id="{identifier}"]')
        lines.append("")
        for size, identifier in self.boxes.items():'''
assert old_ext in text
text = text.replace(old_ext, '''            lines.append(f'[ext_resource type="PackedScene" path="{path}" id="{identifier}"]')
        for path, identifier in self.scripts.items():
            lines.append(f'[ext_resource type="Script" path="{path}" id="{identifier}"]')
        lines.append("")
        for size, identifier in self.boxes.items():''')
old_meta = '''                for key, value in self.metadata.get(path, {}).items():
                    lines.append(f"metadata/{key} = {value}")'''
assert old_meta in text
text = text.replace(old_meta, '''                if path in self.pivots:
                    transform, script, properties = self.pivots[path]
                    lines.append(f"transform = {transform}")
                    lines.append(f'script = ExtResource("{self.scripts[script]}")')
                    for key, value in properties.items():
                        lines.append(f"{key} = {value}")
                for key, value in self.metadata.get(path, {}).items():
                    lines.append(f"metadata/{key} = {value}")''')

# 3. Château : remplace curtain_wall, square_tower, round_tower et build_castle.
start = text.index("def curtain_wall(")
end = text.index("def build_bunker(")
text = text[:start] + castle + text[end:]

# 4. Quartiers et jardin, avant les ponts ; appels dans main().
anchor = "# Ponts sur la rivière"
assert anchor in text
text = text.replace(anchor, quarters.strip("\n") + "\n\n\n" + anchor)
old_main = '''    build_bridges(scene, rng)
    OUTPUT.parent.mkdir'''
assert old_main in text
text = text.replace(old_main, '''    build_bridges(scene, rng)
    build_quarters(scene, random.Random(5820))
    build_park(scene, random.Random(5821))
    build_quarter_paths(scene)
    OUTPUT.parent.mkdir''')
# Réverbères des ponts : des lanternes du village, comme le long des chemins.
old_post = '''            scene.add("graveyard_kit/lightpost-single", (lx, 0.0, lz), 0.0 if side < 0 else 180.0, 2.2)
            scene.add_box((lx, 1.4, lz), (0.45, 2.8, 0.45))'''
assert old_post in text
text = text.replace(old_post, '''            scene.add("fantasy_town_kit/lantern", (lx, 0.0, lz), 0.0, 2.2)
            scene.add_box((lx, 1.0, lz), (0.45, 2.0, 0.45))''')
open(path, "w", encoding="utf-8", newline="\n").write(text)
print("build_hub.py intégré")
