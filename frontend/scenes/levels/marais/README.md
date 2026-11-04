# Niveau 3 — Les marais de Kernel Swamp

Ouvrir `marais.tscn` dans le projet `frontend/project.godot`, puis appuyer sur **F6** pour jouer cette scène. En version de debug, **F1** ouvre aussi le menu des niveaux.

Énigme : **le tombeau du chiffrement**. Livre : le Logiconomicon, le livre de la logique et du chiffrement.

## Parcours

1. Le joueur arrive au sud, devant le portail éteint, près du vieux débarcadère de Brumeval. Le panneau d'accueil raconte le village de pêcheurs englouti quand la guerre contre Vibelandia a brisé les digues : ses toits sortent encore de l'eau, à l'est.
2. Trois pontons, bordés de lanternes, mènent au campement du gardien (son journal est sur sa table), au cimetière (la tombe du gardien Aldric, la tombe usée d'Ada, le fantôme du gardien) puis à la crypte, au nord, à moitié cachée par la mousse et les buissons.
3. La porte de la crypte ouvre sur un long escalier de pierre. En bas, la salle du mécanisme à cinq cercles ; sur le mur face au mécanisme, l'inscription gravée. Deux couloirs mènent à l'ouest aux tombeaux des rois Codeon I à IV (épitaphes et hommage gravé au-dessus de l'autel), à l'est au tombeau du livre ; deux embranchements au sud mènent à l'ossuaire et à la chambre des gardiens.
4. Le mécanisme s'ouvre en vue rapprochée. Une mauvaise combinaison fait rougir les lettres, la crypte gronde et le chronomètre perd 5 minutes. Solution : CODIA décalé de +3, −3, +3, −3, +3, soit **FLGFD**.
5. Les cercles s'illuminent de vert ; dans la chambre de l'est, le lourd couvercle du tombeau glisse et bascule. Prendre le Logiconomicon rallume le portail.

Les eaux peu profondes ralentissent le joueur ; dans les eaux profondes, la vase le ramène à son dernier point sûr. Une limite invisible, au pied de la berge (`MaraisTerrain.LIMIT_RADIUS`), empêche de sortir de la carte.

## Fichiers

| Fichier | Rôle |
| --- | --- |
| `marais.tscn`, `marais.gd` | Scène du niveau et sa logique (pas dans l'eau, crypte, mécanisme, tombeau, brume) |
| `marais_terrain.gd` | Îlots, fond de vase, berges et limite invisible |
| `marais_scatter.gd` | Pontons et lanternes, arbres, roseaux, nénuphars en fleur (par cases de 32 m), mousse et poussière ; pose au sol maillé le décor des berges |
| `marais_props.tscn`, `marais_grounded.tscn`, `marais_crypt.tscn` | Décor fixe, généré par `tools/build_marais.py` (à relancer après modification) |
| `ring_mechanism.gd`, `ring_puzzle.tscn`, `ring_puzzle.gd` | Mécanisme à cinq cercles et son écran |
| `will_o_wisps.gd` | Feux follets |
| `moss_overlay.gdshader`, `crypt_stone.gdshader` | Mousse et poussière en surcouche, dalles de pierre froide de la crypte |
| `marais_ground.gdshader`, `swamp_water.gdshader` | Sol et eau stagnante |

`marais.tscn` est écrit par un script Python (textes, indices, tombeaux de jeu, niches de l'ossuaire, lumières) : modifier ce script plutôt que la scène.
