# Ombres et fluidité du jeu dans le navigateur (5 novembre 2026)

Portage sur `dev` du commit ae603f1 d'Anthony (branche locale `perf/fluidite-web`, 3 novembre), jamais fusionné. Le
code avait beaucoup bougé depuis : rien n'a été repris par cherry-pick, chaque partie a été refaite sur le code actuel.

## Ce qui change

| Partie | Avant | Après |
| --- | --- | --- |
| Soleil du Hub, du Village et de la Plaine | 4 découpes d'ombre, 70 à 90 m | 2 découpes, 50 m (comme le Désert et le Marais) |
| Soleil du Désert | 2 découpes, 55 m | 2 découpes, 50 m |
| Fin de la première découpe (`directional_shadow_split_1`) | 0,1 | 0,2, soit 10 m |
| Biais normal des 5 soleils (`shadow_normal_bias`) | 1 | 4 |
| Filtrage des ombres du soleil (`soft_shadow_filter_quality`) | 2 (5 échantillons) | 4 (13 échantillons) |
| Carte d'ombre du soleil | 4096 | 4096 : la carte de 2048 sur le web du commit d'Anthony n'est pas reprise (voir plus bas) |
| Petits détails dispersés : fleurs, buissons, herbes (Hub), herbes et gravats (Village), herbes et cailloux (Plaine) | projettent une ombre | sans ombre (déjà le cas au Désert et au Marais) |
| Ombre du corps du joueur | 37 morceaux | 5 maillages fondus, un par articulation |
| Visuel et caméra du joueur | suivent la physique (60 Hz) | placés à chaque image entre les deux dernières positions physiques |
| Résolution 3D | celle de l'écran | limitée au-delà de 1920 x 1080 pixels, F4 pour choisir, F3 pour le compteur |
| Fichiers du jeu servis par Caddy | compressés à chaque requête | compressés au build (brotli, gzip), revalidés par le navigateur |

Les réglages des soleils sont dans les générateurs `frontend/tools/write_<lieu>_tscn.py` (Hub, Désert, Marais,
Village) et dans `plaine.tscn`, éditée à la main. Relancer tous les générateurs (`build_*.py`, `write_*_tscn.py`) ne
produit aucune dérive.

## Mesures

Outil : `docs/agents/perf/outils/perf_ombres.gd`, copie de `.claude/captures/outils/perf_web.gd` complétée. En rendu
Compatibility, `RENDER_INFO_TYPE_SHADOW` reste à 0 : les passes d'ombre sont comptées avec les appels visibles.
L'outil mesure donc chaque direction deux fois, ombres allumées puis éteintes, et en déduit les appels d'ombre. Il
mesure aussi la part du corps du joueur (son visuel caché puis remontré). Point d'arrivée de chaque lieu, caméra du
joueur, 8 directions, serveur arm64 avec llvmpipe sous Xvfb en 1280 x 720. Les appels sont exacts et identiques d'un
passage à l'autre ; les temps d'image ne valent rien ici (serveur chargé par d'autres agents).

« Avant » : `dev` 0c8c89c (la version en ligne). « Après » : la branche `perf/ombres-web`.

| Lieu | Appels moyens avant | après | écart | dont ombres avant | après | Pire direction avant | après | écart | Corps du joueur avant | après |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Hub | 1220 | 758 | -38 % | 825 | 363 | 1842 (496 + 1346) | 991 (622 + 369) | -46 % | 138 | 10 |
| Désert | 323 | 307 | -5 % | 144 | 129 | 674 (408 + 266) | 647 (408 + 239) | -4 % | 15 | 1 |
| Marais | 226 | 217 | -4 % | 73 | 64 | 482 (349 + 133) | 455 (349 + 106) | -6 % | 10 | 0 |
| Village | 927 | 571 | -38 % | 626 | 270 | 2093 (588 + 1505) | 1265 (838 + 427) | -40 % | 17 | 2 |
| Plaine | 455 | 259 | -43 % | 310 | 114 | 986 (271 + 715) | 524 (271 + 253) | -47 % | 136 | 13 |

Chaque case donne les appels de dessin par image. « Dont ombres » : la part des passes d'ombre, en moyenne. « Pire
direction » : visibles + ombres. « Corps du joueur » : ce que coûte son corps caché, vers l'avant, à l'arrivée (il
dépend de la direction : son ombre n'est dessinée que dans les découpes où elle peut tomber).
- Hub, Village et Plaine passent de 4 à 2 découpes : 38 à 43 % d'appels en moins en moyenne, 40 à 47 % au pire.
- Désert et Marais avaient déjà 2 découpes : le gain vient des 5 m de portée en moins (Désert), de l'ombre du corps,
  et il est faible.
- La première découpe à 10 m coûte un peu : 758 appels au Hub au lieu de 741 avec une première découpe à 5 m,
  259 au lieu de 248 à la Plaine, 571 au lieu de 565 au Village (`.claude/captures/perf-ombres/apres.log`).

## Moiré au sol avec 2 découpes

La Plaine avait renoncé aux 2 découpes à cause de bandes et d'anneaux sur le sol proche
(`docs/agents/plaine/PERFORMANCES.md`). Essais sur la Plaine (façade, engins de siège, sol devant le pont), avec
`docs/agents/perf/outils/exp_shots.gd` (copie de `cam_shots.gd` qui change les réglages d'ombre pendant la prise). Sauf la première ligne, ces essais sont faits avec une carte de 2048, où le défaut est le plus net :

| Réglage, en plus de 2 découpes à 50 m | Sol proche |
| --- | --- |
| carte de 4096, réglages par défaut | anneaux nets |
| carte de 2048 (web) | anneaux et bandes fines, plus marqués |
| filtrage 3 | inchangé (5 échantillons, comme 2) |
| filtrage 4 ou 5 | anneaux adoucis en larges taches, toujours là |
| biais 1,0 (au lieu de 0,1) | anneaux toujours là |
| carte en 24 bits au lieu de 16 | anneaux toujours là |
| biais normal 3 | presque lisse, grain très fin |
| biais normal 6 | lisse |

C'est de l'acné d'ombre : le sol s'ombre lui-même, et seul le biais normal l'efface. Retenu :
- `shadow_normal_bias = 4.0` sur les 5 soleils ;
- `soft_shadow_filter_quality = 4` dans le projet (13 échantillons au lieu de 5) : il efface le grain qui reste et
  adoucit les bords en escalier des ombres.

La carte de 2048 sur le web (commit d'Anthony) n'est pas reprise. Avec elle, l'ombre du joueur devient floue, et au
Marais une ligne nette barre le sol à la limite des deux découpes (sol plus sombre en deçà). Ni un biais normal de 6,
ni le filtrage 2, ni le fondu entre découpes (`directional_shadow_blend_splits`) ne l'effacent ; en 4096, la même vue
est propre. La taille de la carte ne change pas le nombre d'appels, et 4096 est déjà la carte de la version en ligne.

Les captures avant et après (planches dans `.claude/captures/perf-ombres/planches/`) montrent un sol lisse, et les
ombres des objets à la même place, aux bords un peu plus doux.

## Première découpe à 10 m

Avec 2 découpes, la première s'arrête par défaut à 0,1 x 50 = 5 m. La seconde découpe ne reçoit pas ce qui est tout
près de la caméra : une ombre qui passe d'une découpe à l'autre est coupée net à 5 m. On le voyait sur l'ombre du
joueur (la tête coupée au Hub), et au Village, où le soleil est bas, sur les longues ombres des arbres et des buissons
proches. Ni une marge de visibilité de 6 m sur le corps (`extra_cull_margin`), ni une « crêpe » d'ombre plus épaisse
(`directional_shadow_pancake_size` 60 ou 150) n'y changent rien. Avec `directional_shadow_split_1 = 0.2` (10 m), les
mêmes vues redeviennent identiques à celles d'avant, pour 2 % d'appels en plus au Hub (741 à 758).

## Ombre du corps du joueur

À la première personne, le corps de Devlyn est caché mais projette son ombre. Il compte 37 morceaux, et chacun était
redessiné dans chaque découpe d'ombre. `Devlyn.merge_shadow()` les fond au chargement en 5 maillages, un par
articulation (les deux hanches, le haut du corps, les deux épaules), placés sous l'articulation : l'ombre a la même
forme et marche toujours. Les morceaux visibles ne projettent plus d'ombre (vue à la troisième personne), ou sont
cachés (première personne).

## Joueur lissé entre deux images physiques

Comme dans le commit d'Anthony, le visuel et la caméra sont placés à chaque image entre les deux dernières positions
physiques du corps. Différence avec son commit : le décalage passe par `Visual` et `SpringArm3D`, et non plus par
`CameraPivot`, que la secousse de caméra du Désert (`desert.gd`, `_shake`) déplace aussi. Un déplacement de plus de
2 m entre deux images physiques (portail, retour au point de départ) n'est pas lissé.

## Résolution 3D, F3 et F4

`scripts/render_quality.gd` (autoload `RenderQuality`), repris du commit d'Anthony, avec deux changements :
- le compteur est caché au lancement (il était affiché « le temps des tests ») ;
- son texte n'utilise plus que des caractères simples (`|`, `x`, `->`) : la version web n'a pas de police de secours.

Vérifié sur le paquet exporté (`docs/agents/perf/outils/verif_rq.gd` et `verif_pck.sh`), lancé en natif :
- fenêtre de 1280 x 720 : automatique à 100 %, puis F4 à 100, 75 et 50 %, puis retour en automatique ;
- fenêtre de 3840 x 2160 : automatique à 50 % (3D en 1920 x 1080), interface et texte nets ;
- F3 affiche puis cache le compteur.

## Qualité adaptative (6 novembre)

Retour d'Anthony : sur un PC neuf, le premier lancement n'est pas fluide. `render_quality.gd` adapte maintenant
la qualité tout seul, sur le web seulement (en natif : option `--qualite-auto` ; `--qualite-cran=N` impose un cran).
- À chaque arrivée dans un lieu (signal `scene_changed`, puis fin du fondu de `Transition`), le temps d'image moyen
  est mesuré pendant 3 s, sans les 20 premières images ni les 5 % d'images les plus lentes.
- Au-delà de 22 ms : un cran de moins, puis nouvelle mesure. Sous 12 ms, sans baisse dans le lieu : un cran de plus,
  mais seulement à l'arrivée dans le lieu suivant.
- Crans : 1 à 3, 3D à 85, 70 puis 55 % ; 4, ombres du soleil à 30 m, une découpe, carte de 2048 ; 5, ombres du soleil
  et des lumières ponctuelles coupées ; 6, `visibility_range_end` × 0,6 et moitié moins de particules.
  Les valeurs d'origine de chaque nœud sont gardées (méta `rq`) : remonter rend la scène telle qu'elle est.
- Le cran est retenu dans `user://qualite.cfg`. F3 l'affiche ; une résolution fixe (F4) suspend l'adaptation.
- Limite : à 60 Hz, le navigateur cale les images sur 16,7 ms ; la remontée (moins de 12 ms) ne se produit alors
  qu'avec un écran plus rapide.

Test : `tests/scenes/quality_test.gd -- --qualite-auto` (dans `run_all.sh`), images lentes simulées par `forced_ms`.

## Livraison web

- `frontend/Dockerfile` : `.wasm`, `.pck`, `.js` et `.html` du jeu compressés au build, en brotli 9 et gzip 9 :
  `index.wasm` passe de 39,5 Mo à 7,9 Mo (brotli) ou 10,1 Mo (gzip), `index.pck` de 21,2 à 18,8 Mo.
- `infrastructure/Caddyfile`, pour le jeu à la racine seulement : `precompressed br gzip` et
  `Cache-Control: no-cache`. La page `/reinitialisation` garde ses propres en-têtes, et `encode zstd gzip` reste pour
  le reste (API, page de réinitialisation, navigateur qui ne prend que zstd).

Vérifié sur l'image construite (`SITE_ADDRESS=:18080`) : `/` et `index.wasm` en brotli, gzip si le navigateur ne
prend que gzip, `If-None-Match` donne 304 sans corps, `/reinitialisation?token=…` garde `no-store`, `no-referrer`,
la CSP, `nosniff` et `DENY`.

## Captures avant et après

`docs/agents/perf/outils/shots.sh` et `views.py`, aux mêmes points avant et après, dans les 5 lieux :
- `arrivee` : le regard du joueur au point d'arrivée ;
- `ombre` : vers où tombent les ombres, l'ombre du joueur au premier plan ;
- `ombre_loin` : même direction, de 10 à 50 m ;
- Plaine en plus : `o3_facade` et `o5_siege`, où le moiré était le plus visible.

Captures dans `.claude/captures/perf-ombres/avant/shots/` et `apres3/shots/`, planches côte à côte dans
`planches/<lieu>.png` (`compare.py`). Ce qu'on y voit :
- le sol est lisse partout : plus d'anneaux à la Plaine, plus de fines bandes sur le sable du Désert ni sur l'herbe
  du Marais (à contraste triplé, un grain très fin reste à la Plaine ; à l'œil, il ne se voit pas) ;
- l'ombre du joueur a la même silhouette, aux bords un peu plus doux ; au Désert, elle est plus floue qu'avant, la
  première découpe couvrant 10 m au lieu de 5,5 ;
- les ombres des bâtiments, arbres, lanternes et engins restent à leur place ; les fleurs, herbes et cailloux n'en
  ont plus ;
- au-delà de 40 m, les ombres s'effacent en fondu jusqu'à 50 m (au lieu de 70 à 90 m) : rien ne saute, mais les
  bâtiments lointains du Hub n'ont plus d'ombre au sol ;
- au Village (soleil couchant, ombres très longues), le motif des ombres sur les murs à 30 m change un peu.

Les captures `apres2/` (carte de 2048, comme sur le web dans le commit d'Anthony) montrent les défauts qui ont fait
garder 4096.

## Tests

`frontend/tests/scenes/run_all.sh`, sur l'état final de la branche : 0 échec, sauf les 2 échecs voulus de
`hub_walk_0` et de `hub_walk_4` ; `run_tests` : 51 réussis, 0 échec. Aucune erreur de script.

## Outils (`docs/agents/perf/outils/`)

| Fichier | Rôle |
| --- | --- |
| `perf_ombres.gd` | appels de dessin d'un lieu, ombres comprises (par différence), et part du corps du joueur |
| `mesure.sh` | `perf_ombres.gd` puis les captures, dans les 5 lieux |
| `shots.sh`, `views.py` | captures seules, aux points de `views.py` |
| `exp_shots.gd` | copie de `cam_shots.gd` qui change les réglages d'ombre entre deux prises (`sun=`, `filter=`, `atlas=`, `atlas24=`, `bias=`, `blur=`, `blend=`, `pancake=`, `margin=`, `noterrain`) |
| `compare.py`, `planche.py`, `zoom.py` | planches avant et après, recadrages agrandis et contrastés |
| `tableau.py` | tableau avant et après depuis les journaux de `perf_ombres.gd` |
| `verif_rq.gd`, `verif_pck.sh` | F3, F4 et résolution automatique, sur le paquet exporté lancé en natif |

Attention : bash lit un script au fur et à mesure. Modifier `mesure.sh` pendant qu'il tourne casse la suite du
passage.
