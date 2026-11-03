"""Génère les objets fixes du hub : le camp des survivants et le fort du nord, avec le bunker.

La scène produite s'ouvre et se modifie dans Godot, mais le script l'écrase :
pour un changement durable, modifier ce script puis le relancer depuis le dossier frontend :

    python tools/build_hub.py
"""

import math
from pathlib import Path

from build_plaine import Scene

OUTPUT = Path(__file__).resolve().parent.parent / "scenes" / "levels" / "hub" / "hub_props.tscn"
FORT_Z = -40.0
WALL_SCALE = 5.0


def build_camp(scene):
    """Camp des survivants autour du feu : tentes, bancs de rondins, provisions et établi."""
    scene.add("survival_kit/campfire-pit", (0.0, 0.0, 0.0), 0.0, 6.0)
    for index in range(5):
        angle = math.radians(90 + index * 72)
        x, z = math.cos(angle) * 3.0, math.sin(angle) * 3.0
        scene.add("nature_kit/log", (x, 0.0, z), -math.degrees(angle), 4.0)
        scene.add_box((x, 0.35, z), (0.9, 0.7, 2.4), -math.degrees(angle))
    for x, z, degrees in ((10.5, 1.0, -100.0), (-10.5, 1.0, 100.0), (7.5, 9.0, -150.0), (-7.5, 9.0, 150.0)):
        scene.add("mini_forest/tent", (x, 0.0, z), degrees, 3.2)
        scene.add_box((x, 1.6, z), (3.6, 3.2, 3.2), degrees)
    for model, x, z, degrees, scale, size in (
        ("survival_kit/workbench", 8.5, -4.0, -60.0, 5.0, (1.5, 1.2, 1.5)),
        ("survival_kit/barrel", -8.0, -3.5, 0.0, 4.0, (1.0, 1.4, 1.0)),
        ("survival_kit/barrel", -8.9, -2.6, 30.0, 4.0, (1.0, 1.4, 1.0)),
        ("survival_kit/box-large", 9.6, -5.6, 20.0, 4.0, (1.0, 1.0, 2.0)),
        ("survival_kit/box", -9.4, -4.6, 45.0, 4.0, (1.0, 1.0, 1.0)),
        ("survival_kit/bucket", 7.4, -5.2, 0.0, 4.0, None),
    ):
        scene.add(model, (x, 0.0, z), degrees, scale)
        if size:
            scene.add_box((x, size[1] / 2, z), size, degrees)
    scene.add("food_kit/bread", (9.6, 1.0, -5.6), 15.0, 2.5)


def build_fort(scene):
    """Fort du nord : un rempart percé de la porte du bunker, et deux tours à ses extrémités."""
    for index in range(-2, 3):
        scene.add("castle_kit/wall", (index * WALL_SCALE, 0.0, FORT_Z), 0.0, WALL_SCALE)
    scene.add_box((0.0, 3.3, FORT_Z), (WALL_SCALE * 5, 6.6, WALL_SCALE))
    scene.add("castle_kit/metal-gate", (0.0, 0.0, FORT_Z + WALL_SCALE * 0.5 + 0.05), 90.0, 5.5)
    for x in (-15.0, 15.0):
        y = 0.0
        for model, height in (("tower-square-base", 1.0), ("tower-square-mid-windows", 1.0), ("tower-square-mid", 1.0), ("tower-square-top", 0.3)):
            scene.add(f"castle_kit/{model}", (x, y, FORT_Z), 0.0, WALL_SCALE)
            y += height * WALL_SCALE
        scene.add("castle_kit/tower-square-roof", (x, y, FORT_Z), 0.0, WALL_SCALE)
        scene.add_box((x, y / 2, FORT_Z), (WALL_SCALE, y, WALL_SCALE))
        scene.add("castle_kit/flag", (x, y + WALL_SCALE * 2.0, FORT_Z), 0.0, 4.0)
    for x, z, degrees in ((-6.0, FORT_Z + 4.5, 20.0), (7.0, FORT_Z + 5.0, -35.0)):
        scene.add("castle_kit/rocks-small", (x, 0.0, z), degrees, 2.5)


def main():
    scene = Scene("HubProps")
    build_camp(scene)
    build_fort(scene)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(scene.text(), encoding="utf-8", newline="\n")
    print(f"{OUTPUT.name} : {len(scene.visuals)} modèles, {len(scene.colliders)} collisions")


if __name__ == "__main__":
    main()
