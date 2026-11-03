"""Génère les objets fixes du Marais : la cabane du gardien, le cimetière et la crypte.

La scène produite s'ouvre et se modifie dans Godot, mais le script l'écrase :
pour un changement durable, modifier ce script puis le relancer depuis le dossier frontend :

    python tools/build_marais.py
"""

import random
from pathlib import Path

from build_plaine import Scene

OUTPUT = Path(__file__).resolve().parent.parent / "scenes" / "levels" / "marais" / "marais_props.tscn"
# Hauteur du dessus des îlots, fixée dans MaraisTerrain.ISLANDS.
GROUND = 0.4

GRAVESTONES = (
    "gravestone-round",
    "gravestone-cross",
    "gravestone-wide",
    "gravestone-broken",
    "gravestone-bevel",
    "gravestone-decorative",
    "gravestone-roof",
)


def build_hut(scene):
    """Campement du gardien, sur l'îlot de l'ouest : tente, feu de camp et provisions."""
    scene.add("survival_kit/tent-canvas", (-22.5, GROUND, 24.5), 30.0, 4.5)
    scene.add_box((-22.5, 1.1, 24.5), (2.4, 2.2, 2.4), 30.0)
    scene.add("survival_kit/campfire-pit", (-18.0, GROUND, 21.0), 0.0, 5.0)
    for model, position, scale, size in (
        ("survival_kit/barrel", (-24.2, GROUND, 20.6), 4.0, (1.0, 1.4, 1.0)),
        ("survival_kit/bucket", (-23.2, GROUND, 19.6), 4.0, None),
        ("survival_kit/box", (-19.6, GROUND, 25.6), 4.0, (1.0, 1.0, 1.0)),
        ("survival_kit/box", (-25.0, GROUND, 22.8), 3.2, (0.8, 0.8, 0.8)),
    ):
        scene.add(model, position, 15.0, scale)
        if size:
            scene.add_box((position[0], GROUND + size[1] / 2, position[2]), size, 15.0)
    for x, z, degrees in ((-26.0, 19.0, 70.0), (-25.0, 26.5, 20.0), (-17.0, 26.8, -30.0)):
        scene.add("survival_kit/fence", (x, GROUND, z), degrees, 4.0)


def build_cemetery(scene, rng):
    """Cimetière clos de grilles, sur le grand îlot de l'est, ouvert à l'ouest face au ponton."""
    west, east, south, north = 7.0, 25.0, 9.0, -9.0
    for index in range(6):
        z = north + 1.5 + index * 3.0
        x = west + 1.5 + index * 3.0
        model = "iron-fence-damaged" if index in (1, 4) else "iron-fence"
        # Entrées : à l'ouest face au deuxième ponton, au nord-ouest vers le ponton de la crypte.
        if index not in (3, 4):
            scene.add(f"graveyard_kit/{model}", (west, GROUND, z), 90.0, 3.0)
            scene.add_box((west, 1.3, z), (0.3, 2.6, 3.0))
        scene.add(f"graveyard_kit/{model}", (east, GROUND, z), -90.0, 3.0)
        if index != 0:
            scene.add("graveyard_kit/iron-fence", (x, GROUND, north), 180.0, 3.0)
        scene.add("graveyard_kit/iron-fence", (x, GROUND, south), 0.0, 3.0)
    scene.add_box((east, 1.3, 0.0), (0.3, 2.6, 18.0))
    scene.add_box((17.5, 1.3, north), (15.0, 2.6, 0.3))
    scene.add_box((16.0, 1.3, south), (18.0, 2.6, 0.3))
    for z in (-0.3, 6.3):
        scene.add("graveyard_kit/lightpost-single", (west, GROUND, z), 90.0, 3.0)

    # Rangées de tombes de part et d'autre de l'allée centrale, qui va de la grille à la tombe du gardien.
    for z in (-6.5, -3.0, 6.5):
        for x in (10.5, 13.5, 16.5, 19.5):
            if (x, z) == (10.5, 6.5):
                continue
            model = rng.choice(GRAVESTONES)
            facing = 0.0 if z > 0 else 180.0
            scene.add(f"graveyard_kit/{model}", (x, GROUND, z), facing + rng.uniform(-8, 8), 2.6)
            scene.add_box((x, 0.9 + GROUND, z), (1.6, 1.8, 0.8))
            if rng.random() < 0.6:
                scene.add("graveyard_kit/grave", (x, GROUND, z + (1.6 if z > 0 else -1.6) * -1), facing, 2.6)

    # Tombe d'Ada, et tombe du gardien au bout de l'allée, plus grande que les autres.
    scene.add("graveyard_kit/gravestone-round", (10.5, GROUND, 6.5), 0.0, 2.8)
    scene.add_box((10.5, 0.9 + GROUND, 6.5), (1.4, 1.8, 0.8))
    scene.add("graveyard_kit/gravestone-cross", (23.0, GROUND, 1.5), -90.0, 3.6)
    scene.add_box((23.0, 1.7 + GROUND, 1.5), (1.0, 3.4, 1.8))
    scene.add("graveyard_kit/grave", (21.0, GROUND, 1.5), -90.0, 3.2)
    scene.add("graveyard_kit/candle-multiple", (21.8, GROUND, 3.2), 0.0, 3.0)
    scene.add("graveyard_kit/candle-multiple", (21.8, GROUND, -0.2), 40.0, 3.0)
    scene.add("graveyard_kit/bench-damaged", (16.5, GROUND, 4.6), 180.0, 3.0)
    scene.add_box((16.5, 0.75 + GROUND, 4.6), (2.7, 1.5, 1.3))
    for x, z in ((14.0, -9.5), (24.0, 7.5), (24.0, -7.5)):
        scene.add("graveyard_kit/pine-crooked", (x, GROUND, z), rng.uniform(0, 360), 3.5)
        scene.add_box((x, 2.0, z), (0.8, 4.0, 0.8))


def build_crypt(scene, rng):
    """Crypte du gardien, au nord : sa porte regarde le ponton, encadrée d'obélisques et de murets."""
    scene.add("graveyard_kit/crypt-large", (0.0, GROUND, -41.0), 0.0, 4.0)
    scene.add("graveyard_kit/crypt-large-roof", (0.0, GROUND + 4.0, -41.0), 0.0, 4.0)
    scene.add_box((0.0, 3.0, -41.0), (7.6, 6.0, 9.6))
    for x in (-6.0, 6.0):
        scene.add("graveyard_kit/pillar-obelisk", (x, GROUND, -36.5), 0.0, 4.0)
        scene.add_box((x, 2.0 + GROUND, -36.5), (1.4, 4.0, 1.4))
    for x, z, degrees, model in (
        (-8.5, -40.0, 90.0, "stone-wall"),
        (-8.5, -44.0, 90.0, "stone-wall-damaged"),
        (8.5, -40.0, -90.0, "stone-wall-damaged"),
        (8.5, -44.0, -90.0, "stone-wall"),
    ):
        scene.add(f"graveyard_kit/{model}", (x, GROUND, z), degrees, 4.0)
        scene.add_box((x, 1.5 + GROUND, z), (0.8, 3.0, 4.0))
    for x, z in ((-10.0, -46.0), (9.5, -47.0), (-4.0, -48.5)):
        scene.add("graveyard_kit/pine", (x, GROUND, z), rng.uniform(0, 360), 4.0)
        scene.add_box((x, 2.0, z), (0.9, 4.0, 0.9))


CRYPT_OUTPUT = OUTPUT.with_name("marais_crypt.tscn")
CRYPT_TILE = 4.0
CRYPT_HEIGHT = 4.15
# Cases de la crypte souterraine, en indices de case de 4 m : (x, z) du centre = 4 × indice.
CRYPT_ROOMS = {
    "entree": [(0, 0), (0, 1)],
    "salle": [(x, z) for x in range(-2, 3) for z in range(-5, 0)],
    "couloir_est": [(3, -3), (4, -3)],
    "chambre_est": [(x, z) for x in range(5, 8) for z in range(-4, -1)],
    "couloir_ouest": [(-3, -3), (-4, -3)],
    "chambre_ouest": [(x, z) for x in range(-7, -4) for z in range(-4, -1)],
}
NEIGHBOURS = {(0, -1): 180.0, (0, 1): 0.0, (1, 0): 90.0, (-1, 0): -90.0}


def build_crypt_underground(scene, rng):
    """Crypte souterraine : couloir d'entrée, salle du mécanisme et deux chambres funéraires reliées."""
    tiles = {tile for room in CRYPT_ROOMS.values() for tile in room}
    for ix, iz in sorted(tiles):
        x, z = ix * CRYPT_TILE, iz * CRYPT_TILE
        scene.add("modular_dungeon_kit/template-floor", (x, 0.0, z), 0.0, 1.0)
        scene.add("modular_dungeon_kit/template-floor", (x, CRYPT_HEIGHT, z), 0.0, 1.0, tilt=180.0)
        scene.add_box((x, -0.25, z), (CRYPT_TILE, 0.5, CRYPT_TILE))
        scene.add_box((x, CRYPT_HEIGHT + 0.25, z), (CRYPT_TILE, 0.5, CRYPT_TILE))
        # Un mur sur chaque bord qui ne donne sur aucune case : son pied regarde l'intérieur de la case.
        for (dx, dz), degrees in NEIGHBOURS.items():
            if (ix + dx, iz + dz) in tiles:
                continue
            edge = (x + dx * CRYPT_TILE / 2, z + dz * CRYPT_TILE / 2)
            scene.add("modular_dungeon_kit/template-wall", (edge[0], 0.0, edge[1]), degrees, 1.0)
            size = (0.6, CRYPT_HEIGHT, CRYPT_TILE) if dx else (CRYPT_TILE, CRYPT_HEIGHT, 0.6)
            scene.add_box((edge[0] - dx * 0.3, CRYPT_HEIGHT / 2, edge[1] - dz * 0.3), size)
    # Salle du mécanisme : colonnes aux angles, bannières et cierges autour du mécanisme.
    for x in (-7.0, 7.0):
        for z in (-5.0, -19.0):
            scene.add("mini_dungeon/column", (x, 0.0, z), 0.0, 3.6)
            scene.add_box((x, 2.0, z), (1.6, 4.0, 1.6))
    for x in (-5.0, 5.0):
        scene.add("mini_dungeon/banner", (x, 0.8, -21.2), 0.0, 3.0)
    for x, z in ((-4.2, -8.0), (4.2, -8.0), (-4.2, -16.0), (4.2, -16.0)):
        scene.add("graveyard_kit/candle-multiple", (x, 0.0, z), rng.uniform(0, 360), 3.0)
    # Chambre de l'ouest : cercueils et urnes, pour le décor.
    for x, z, degrees in ((-24.0, -9.0, 90.0), (-24.0, -15.0, 90.0), (-28.5, -12.0, 0.0)):
        scene.add("graveyard_kit/coffin-old", (x, 0.0, z), degrees, 3.0)
        scene.add_box((x, 0.3, z), (2.6, 0.6, 1.8) if degrees else (1.8, 0.6, 2.6))
    for x, z in ((-20.8, -8.4), (-20.8, -15.6), (-29.0, -8.6)):
        scene.add("graveyard_kit/urn-round", (x, 0.0, z), 0.0, 3.0)
    # Chambre de l'est : les tombeaux des rois Codeon I à IV entourent celui du livre ; tous sont posés dans marais.tscn.
    for x, z in ((29.0, -9.0), (29.0, -15.0)):
        scene.add("graveyard_kit/lantern-candle", (x, 0.0, z), 0.0, 3.0)


def main():
    rng = random.Random(4040)
    scene = Scene("MaraisProps")
    build_hut(scene)
    build_cemetery(scene, rng)
    build_crypt(scene, rng)
    OUTPUT.write_text(scene.text(), encoding="utf-8", newline="\n")
    print(f"{OUTPUT.name} : {len(scene.visuals)} modèles, {len(scene.colliders)} collisions")
    crypt = Scene("MaraisCrypt")
    build_crypt_underground(crypt, rng)
    CRYPT_OUTPUT.write_text(crypt.text(), encoding="utf-8", newline="\n")
    print(f"{CRYPT_OUTPUT.name} : {len(crypt.visuals)} modèles, {len(crypt.colliders)} collisions")


if __name__ == "__main__":
    main()
