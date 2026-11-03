"""Génère les objets fixes du Désert : l'arche d'entrée, le sanctuaire et la cave des archives.

Les scènes produites s'ouvrent et se modifient dans Godot, mais le script les écrase :
pour un changement durable, modifier ce script puis le relancer depuis le dossier frontend :

    python tools/build_desert.py
"""

from pathlib import Path

from build_plaine import Scene

OUTPUT_DIR = Path(__file__).resolve().parent.parent / "scenes" / "levels" / "desert"
GATE_SCALE = 5.0
# Ouverture de l'arche du kit, à l'échelle 1 : demi-largeur et hauteur.
GATE_HALF_OPENING = 0.3
GATE_OPENING_HEIGHT = 0.65


def build_gate(scene):
    """Arche d'entrée à z = 16, entre deux pans de mur qui s'effritent, sur le chemin du portail."""
    z = 16.0
    scene.add("mini_arena/wall-gate", (0.0, 0.0, z), 0.0, GATE_SCALE)
    side = (0.5 - GATE_HALF_OPENING) * GATE_SCALE
    offset = (GATE_HALF_OPENING * GATE_SCALE) + side / 2
    for sign in (-1, 1):
        scene.add_box((sign * offset, GATE_SCALE / 2, z), (side, GATE_SCALE, 0.6 * GATE_SCALE))
    lintel = GATE_SCALE * (1 - GATE_OPENING_HEIGHT)
    scene.add_box((0.0, GATE_SCALE - lintel / 2, z), (GATE_HALF_OPENING * 2 * GATE_SCALE, lintel, 0.6 * GATE_SCALE))
    for sign in (-1, 1):
        for index, model in enumerate(("wall", "wall", "wall-corner")):
            x = sign * (GATE_SCALE * (index + 1))
            scene.add(f"mini_arena/{model}", (x, 0.0, z), 0.0 if sign > 0 else 180.0, GATE_SCALE)
            scene.add_box((x, GATE_SCALE / 2, z), (GATE_SCALE, GATE_SCALE, 0.6 * GATE_SCALE))
        scene.add("castle_kit/flag-banner-long", (sign * 3.0, 0.0, z + 1.8), -90.0, 2.4)
    for x, z_offset, degrees in ((-7.0, 3.0, 20.0), (8.0, 2.5, -40.0)):
        scene.add("mini_arena/bricks", (x, 0.0, z + z_offset), degrees, 3.0)


def build_sanctuary(scene):
    """Esplanade dallée du sanctuaire, centrée en z = -6 : colonnes, statue et trappe au centre."""
    for x in (-8.0, -4.0, 0.0, 4.0, 8.0):
        for z in (-14.0, -10.0, -6.0, -2.0, 2.0):
            scene.add("mini_arena/floor", (x, 0.02, z), 0.0, 4.0)
    for x, z, model in (
        (-10.0, -14.0, "column"), (-10.0, -6.0, "column-damaged"), (-10.0, 2.0, "column"),
        (10.0, -14.0, "column-damaged"), (10.0, -6.0, "column"), (10.0, 2.0, "column-damaged"),
    ):
        scene.add(f"mini_arena/{model}", (x, 0.0, z), 0.0, 3.6)
        scene.add_box((x, 1.8, z), (2.0, 3.6, 2.0))
    scene.add("mini_arena/statue", (0.0, 0.0, -17.0), 0.0, 3.4)
    scene.add_box((0.0, 2.2, -17.0), (2.2, 4.4, 2.2))
    for x in (-5.0, 5.0):
        scene.add("mini_arena/banner", (x, 0.0, -17.5), 0.0, 3.4)
    scene.add("castle_kit/rocks-small", (12.5, 0.0, -9.0), 30.0, 2.5)
    scene.add("mini_arena/bricks", (-12.0, 0.0, -1.0), 70.0, 3.2)
    scene.add("mini_arena/column-damaged", (6.5, 0.6, 6.5), 0.0, 3.0, tilt=85.0)
    scene.add("survival_kit/floor-hole", (0.0, 0.03, -6.0), 0.0, 5.0)


def build_cellar(scene):
    """Cave des archives : une salle de donjon, ses colonnes, ses tables et le coffre au fond."""
    scene.add("modular_dungeon_kit/room-wide", (0.0, 0.0, -6.0), 0.0, 1.0)
    scene.add_box((0.0, -0.25, -6.0), (20.0, 0.5, 12.0))
    scene.add_box((0.0, 4.45, -6.0), (20.0, 0.5, 12.0))
    for x, z, size in ((-10.25, -6.0, (0.5, 4.5, 12.0)), (10.25, -6.0, (0.5, 4.5, 12.0))):
        scene.add_box((x, 2.25, z), size)
    for z in (0.25, -12.25):
        scene.add_box((0.0, 2.25, z), (20.0, 4.5, 0.5))
    # Colonnes le long des murs et autour du coffre, pour laisser libre l'accès aux tablettes.
    for x, z in ((-8.2, -6.0), (8.2, -6.0), (-3.2, -9.8), (3.2, -9.8)):
        scene.add("mini_dungeon/column", (x, 0.0, z), 0.0, 3.6)
        scene.add_box((x, 2.0, z), (1.6, 4.0, 1.6))
    for x, z, degrees in ((-8.5, -2.0, 90.0), (8.5, -2.0, -90.0)):
        scene.add("mini_dungeon/table", (x, 0.0, z), degrees, 3.0)
        scene.add_box((x, 0.5, z), (2.0, 1.0, 2.7))
    for model, x, z in (("barrel", -8.8, -10.5), ("pot", -7.2, -11.0), ("barrel", 8.6, -10.8), ("pot", 8.8, -8.6)):
        scene.add(f"mini_dungeon/{model}", (x, 0.0, z), 20.0, 2.8)
        scene.add_box((x, 0.6, z), (1.4, 1.2, 1.4))
    for x in (-6.0, 6.0):
        scene.add("mini_dungeon/banner", (x, 0.6, -11.4), 180.0, 3.0)
    # Porte scellée au fond de la salle, sous l'inscription.
    scene.add("modular_dungeon_kit/gate-door", (0.0, 0.0, -12.0), 0.0, 1.0)


def main():
    for name, builders in (("desert_ruins", (build_gate, build_sanctuary)), ("desert_cellar", (build_cellar,))):
        scene = Scene(name.title().replace("_", ""))
        for build in builders:
            build(scene)
        (OUTPUT_DIR / f"{name}.tscn").write_text(scene.text(), encoding="utf-8", newline="\n")
        print(f"{name}.tscn : {len(scene.visuals)} modèles, {len(scene.colliders)} collisions")


if __name__ == "__main__":
    main()
