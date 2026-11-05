# Niveau 3 — Les marais de Kernel Swamp

Ouvrir `marais.tscn` dans le projet `frontend/project.godot`, puis appuyer sur **F6** pour jouer cette scène. En version de debug, **F1** ouvre aussi le menu des niveaux.

Énigme : **le tombeau du chiffrement**. Livre : le Logiconomicon, le livre de la logique et du chiffrement.

## Parcours

1. Le joueur arrive au sud, devant le portail éteint, près du vieux débarcadère de Brumeval. Le panneau d'accueil raconte le village de pêcheurs englouti quand la guerre contre Vibelandia a brisé les digues : ses toits sortent encore de l'eau, à l'est.
2. Trois pontons, bordés de lanternes, mènent au campement du gardien (son journal est sur sa table), au cimetière (la tombe du gardien Aldric, la tombe usée d'Ada, le fantôme du gardien) puis à la crypte, au nord, à moitié cachée par la mousse et les buissons.
3. La porte de la crypte ouvre sur un long escalier de pierre. En bas, la salle du mécanisme à cinq cercles ; sur le mur face au mécanisme, l'inscription gravée. Deux couloirs mènent à l'ouest aux tombeaux des rois Codeon I à IV (épitaphes et hommage gravé au-dessus de l'autel), à l'est au tombeau du livre ; deux embranchements au sud mènent à l'ossuaire et à la chambre des gardiens.
4. Le mécanisme s'ouvre en vue rapprochée. Une mauvaise combinaison fait rougir les lettres, la crypte gronde et le chronomètre perd 5 minutes. Solution : CODIA décalé de +3, −3, +3, −3, +3, soit **FLGFD**.
5. Les cercles s'illuminent de vert ; dans la chambre de l'est, le lourd couvercle du tombeau glisse et bascule. Prendre le Logiconomicon rallume le portail.

Textes à lire du récit, en plus des indices : l'avis de la capitainerie de Brumeval (5807) au bout du débarcadère, l'ardoise d'Ada au cimetière (la méthode du décalage alterné, montrée sur BRUME avec deux pas, éclairée par sa lanterne), l'ordre du roi Codeon V (5812) devant la crypte, le registre de l'ossuaire (comment se lisent les cinq cercles) et le serment des gardiens, dans les deux chambres du sud de la crypte. Les panneaux sur poteaux portent leur texte des deux côtés.

Le long escalier se monte et se descend à pied ; on remonte à la surface d'en bas (« Remonter l'escalier ») comme d'en haut, sous la trappe (« Remonter à la surface »). Une lanterne pend à mi-escalier ; dans la crypte, la lumière d'ambiance est une faible lueur chaude (`CRYPT_AMBIENT` dans `marais.gd`), et non le ciel de nuit du dehors.

Les eaux peu profondes ralentissent le joueur ; dans les eaux profondes, la vase le ramène à son dernier point sûr. Une limite invisible, au pied de la berge (`MaraisTerrain.LIMIT_RADIUS`), empêche de sortir de la carte.

## Fichiers

| Fichier | Rôle |
| --- | --- |
| `marais.tscn`, `marais.gd` | Scène du niveau et sa logique (pas dans l'eau, crypte, mécanisme, tombeau, brume) |
| `marais_terrain.gd` | Îlots, fond de vase, berges et limite invisible |
| `marais_scatter.gd` | Pontons et lanternes, arbres, roseaux, nénuphars en fleur (par cases de 32 m), mousse et poussière ; pose au sol maillé le décor des berges |
| `marais_props.tscn`, `marais_grounded.tscn`, `marais_crypt.tscn` | Décor fixe, généré par `tools/build_marais.py` (à relancer après modification) |
| `ring_mechanism.gd`, `ring_puzzle.tscn`, `ring_puzzle.gd` | Mécanisme à cinq cercles et son écran dans le style des menus : cadran des cinq anneaux gravés, une colonne par cercle avec sa lettre et ses flèches ; rouge à l'erreur, vert à la réussite |
| `will_o_wisps.gd` | Feux follets |
| `marais_life.gd` | Grenouilles qui sautent à l'eau, poissons et ronds dans l'eau, corbeaux, chauves-souris de la crypte, lanternes pendues qui se balancent |
| `swamp_fog.gdshader`, `reeds_sway.gdshader` | Brume qui roule au ras de l'eau, roseaux qui ondulent |
| `moss_overlay.gdshader`, `crypt_stone.gdshader` | Mousse et poussière en surcouche, dalles de pierre froide de la crypte |
| `marais_ground.gdshader`, `swamp_water.gdshader` | Sol et eau stagnante |
| `marais_batch.gd` | Regroupement du décor fixe au chargement, pour le web : par cases (32 m dehors, 12 m dans la crypte), les modèles d'un même matériau sont fondus en un seul maillage ; les petits objets ne projettent plus d'ombre et s'effacent au-delà de 40 m |

Pour le web, le niveau ne dessine que le côté où l'on est (le dehors ou la crypte, `OUTSIDE_NODES` dans `marais.gd`), les lumières du dehors s'éteignent au-delà de 46 m et celles de la crypte ne portent que sur leur pièce. Mesures avant et après : `docs/agents/marais/PERFORMANCES.md`.

`marais.tscn` est écrit par un script Python (textes, indices, tombeaux de jeu, niches de l'ossuaire, lumières) : modifier ce script plutôt que la scène.
