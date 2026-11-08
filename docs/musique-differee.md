# Version web : la musique des lieux arrive après le menu

## Le problème

Avant d'afficher le menu, le navigateur téléchargeait tout le jeu : `index.wasm` (7,9 Mo en brotli) et `index.pck` (22,6 Mo, 20,0 Mo en brotli). La musique pesait 14,1 Mo de ce paquet, et l'OGG ne se compresse pas davantage. Le joueur attendait donc ces 14 Mo avant le menu, alors qu'il n'entend d'abord que la piste du menu.

## Ce qui a changé

- **Deux paquets pour le web** (`frontend/export_presets.cfg`).
  - Le préréglage « Web » ne garde que `menu.ogg`, `intro.ogg` et `hub.ogg` dans `index.pck` :
    - le menu en a besoin tout de suite ;
    - « Nouvelle partie » ouvre le bunker sur l'introduction ;
    - « Continuer » ouvre le hub.
  - Le préréglage « Web musique » exporte les six autres pistes dans `musique.pck` : les quatre lieux, la victoire et la défaite (10,8 Mo).
    - Son filtre retire les scripts et les scènes que Godot ajoute à tout export (les autoloads).
    - Il reste l'icône du projet, `project.binary` et deux petits index, que Godot met dans chaque paquet. Ils sont ignorés au montage.
- **Export** (`frontend/Dockerfile`, et `deploy-web.yml` pour GitHub Pages).
  - `godot --export-pack "Web musique" build/web/musique.pck` suit l'export du jeu.
  - Le fichier est précompressé en `.br` et `.gz` comme `index.pck`.
  - Un `.gdignore` dans `build/` garde le dossier d'export hors du projet. Sans lui, le second lancement de Godot importait les images que le premier venait d'y écrire, et des `.import` parasites finissaient sur le site.
- **Serveur** (`infrastructure/Caddyfile`). `musique.pck` passe par le même bloc que `index.pck` : COOP, COEP, `Cache-Control: no-cache` (revalidation par ETag) et `.br` ou `.gz` précompressés. Seul un commentaire a changé.
  - Vérifié sur l'image de production : `Content-Encoding: br` (10 493 476 octets), `gzip` (10 557 932) ou rien (11 007 288) selon `Accept-Encoding`, avec les mêmes en-têtes que `index.pck` ;
  - une revalidation (`If-None-Match`) reçoit `304 Not Modified`.
- **Jeu** (`frontend/scripts/music.gd`, autoload `Music`), sur le web seulement (`OS.has_feature("web")`) :
  1. Une fois la première scène (le menu) affichée, `Music` regarde s'il manque des pistes au paquet du jeu (`ResourceLoader.exists`).
  2. S'il en manque, il fait télécharger `musique.pck`, à côté de la page (`new URL('musique.pck', document.baseURI)`), par le navigateur, en arrière-plan (`fetch`, lancé par `JavaScriptBridge`).
  3. Une fois tout reçu, il reprend le paquet d'un bloc (`JavaScriptBridge.eval` rend un `PackedByteArray`), l'écrit dans un fichier, puis le monte avec `ProjectSettings.load_resource_pack(chemin, false)`. `false` : aucun fichier du jeu n'est remplacé, seules les pistes manquantes s'ajoutent.
- **Jeu natif et Windows** : aucun changement. Le préréglage « Windows Desktop » garde `assets/audio/music/*.ogg`. Son paquet contient toujours les neuf pistes, et le jeu natif ne télécharge rien. Il n'a aucune piste manquante.

## Pendant le téléchargement

- **Une piste demandée avant l'arrivée du paquet** (entrée rapide dans un lieu, par exemple) :
  - la piste précédente s'efface en fondu, comme d'habitude ;
  - la nouvelle attend en silence, sans erreur ni gel (`Music.is_waiting_for_pack()`) ;
  - elle part en fondu dès que le paquet est monté.
  - Si le joueur change encore de lieu entre-temps, c'est la dernière piste demandée qui part.
- **Préchargement** (`Music.prefetch`) : il ignore une piste absente.
- **Les fins** : elles avancent avec leurs propres minuteries, pas avec la musique. Une défaite demandée avant le paquet part à son arrivée, une seule fois, comme prévu.
- **Échec du téléchargement** (réseau coupé, erreur HTTP, paquet illisible) :
  - nouvelle tentative après 5 s, puis 15 s, 30 s, puis toutes les 60 s ;
  - un téléchargement qui ne reçoit plus rien pendant 60 s de jeu est abandonné, puis retenté. Une image compte au plus pour une demi-seconde : le chargement d'un lieu, qui bloque l'image plusieurs secondes, ne passe pas pour une panne ;
  - le jeu reste jouable, sans les pistes manquantes. Chaque échec écrit un avertissement dans la console du navigateur.

## Détails du téléchargement

- **Le navigateur télécharge, pas `HTTPRequest`.**
  - Le code JavaScript (`Music.WEB_FETCH`) lit la réponse jusqu'au bout, au rythme du réseau, et compte les octets reçus. Le jeu suit l'état à chaque image et reprend le paquet en une seule copie.
  - Avec `HTTPRequest`, le jeu ne reprenait qu'un morceau de la réponse par image (`library_godot_fetch.js`). Dans la mesure, le paquet était monté de 4 à 13 s après la fin du réseau. Au menu, les images de préparation des shaders durent jusqu'à 1 à 3 s en rendu logiciel (`docs/shaders-menu.md`), ce qui aurait encore ralenti cette lecture.
  - Le chargement d'un lieu bloque le fil principal plusieurs secondes (docs/web-threads.md). Le navigateur garde un peu de ce qu'il reçoit, puis attend, et la lecture reprend ensuite. Le paquet part donc dès le menu.
- **`HTTPRequest` sert seulement hors du web** (tests). Deux pièges du web, notés pour qui voudrait y revenir :
  - avec `download_file`, le fichier reçu est effacé juste avant `request_completed`. Sur le web, la réponse n'a jamais de longueur connue (`HTTPClientWeb::get_response_body_length` vaut -1). Le téléchargement se termine alors par la branche « lu jusqu'à la fin », qui ne pose pas `download_complete`, et `cancel_request()` efface le fichier (Godot 4.7.2, `scene/main/http_request.cpp`). Vu dans Chromium : 11 007 352 octets reçus, puis « paquet illisible » et nouvelles tentatives sans fin ;
  - avec `accept_gzip`, `HTTPRequest` décoderait une seconde fois un corps que le navigateur a déjà décodé, mais toujours marqué gzip. `Music` met donc `accept_gzip = false`.
- **Mémoire.** Pendant quelques instants, le paquet existe en plusieurs exemplaires de 11 Mo : les morceaux reçus puis leur assemblage dans le navigateur, sa copie dans la mémoire du moteur, puis le fichier. Seul le fichier reste.

## Où le paquet est écrit

- **Emplacement choisi : `OS.get_cache_dir()`.** Sur le web, c'est `/home/web_user/.cache`.
- **Pourquoi pas `user://` :**
  - Sur le web, Godot monte seulement `user://` (`/userfs`) sur IndexedDB (IDBFS), qu'il recopie après chaque fichier fermé (`OS_Web`, `GodotFS`, voir le code de Godot 4.7.2). Le reste du système de fichiers d'Emscripten est en mémoire (MEMFS) : c'est là que Godot copie aussi `index.pck` au démarrage.
  - Écrit dans `user://`, le paquet (11 Mo) serait recopié dans IndexedDB après chaque téléchargement. Surtout, il serait relu en entier à chaque lancement, avant le menu : au démarrage, `GodotFS.init` recopie tout IDBFS en mémoire (`FS.syncfs(true)`).
  - Il gonflerait aussi la sauvegarde, que le joueur ne vide jamais.
- **Coût en mémoire.** Le paquet occupe 11 Mo de mémoire JavaScript tant que la page est ouverte, comme `index.pck`. Une piste chargée y est lue au moment voulu.
- **Le cache du navigateur suffit pour la visite suivante.**
  - `fetch` passe par le cache HTTP.
  - Caddy envoie `no-cache` et un ETag : le navigateur demande seulement si le fichier a changé.
  - Réponse 304 : le paquet ne se retélécharge pas.

## Tests

- **`frontend/tests/scenes/music_test.gd`** couvre le chargement différé, en plus de ses contrôles d'avant.
  - Il simule une piste absente : `Music.dir` pointe vers un dossier qui n'existe pas (`res://tests/musique_differee/`, jamais exporté).
  - Il vérifie, sans aucune erreur au journal du moteur (un `Logger` compte les erreurs) :
    - l'attente silencieuse, sans gel ;
    - le fondu de sortie de l'ancienne piste ;
    - le remplacement d'une piste en attente par une autre ;
    - le téléchargement d'un vrai paquet (écrit par `PCKPacker`) par HTTP, depuis un petit serveur local, avec une réponse marquée gzip alors que déjà décodée, comme celle du navigateur. La requête ne doit pas demander gzip. Le paquet est ensuite écrit, puis monté ;
    - le départ de la bonne piste au montage ;
    - l'enchaînement des pistes du paquet, et l'absence de remplacement de fichiers du jeu.
  - Il vérifie enfin les nouvelles tentatives après un téléchargement raté : adresse morte, deux échecs espacés d'au moins 5 s, la musique continue.
- **Le téléchargement du web** (`fetch` du navigateur, reprise par `JavaScriptBridge`) ne tourne pas en natif : le test passe par `HTTPRequest`, puis par la même écriture du fichier, le même montage et les mêmes nouvelles tentatives. Le chemin du web se vérifie dans le navigateur, avec le banc décrit plus bas.

## Mesures

Mesures du 8 novembre, sur `dev` (a78b42c, préparation des shaders au menu comprise) avant et après ce changement.

### Ce que le navigateur télécharge avant le menu

Export de production (`frontend/Dockerfile`), tailles en octets :

| Fichier | Avant, brut | Avant, brotli | Après, brut | Après, brotli |
| --- | --- | --- | --- | --- |
| `index.wasm` | 38 820 072 | 7 896 845 | 38 820 072 | 7 896 845 |
| `index.pck` | 22 605 728 | 19 996 085 | 11 837 696 | 9 720 936 |
| `index.js` | 314 653 | 68 812 | 314 653 | 68 812 |
| `index.html`, worklets audio, `index.png` | 37 189 | 26 563 | 37 189 | 26 562 |
| **Total avant le menu** | **61,8 Mo** | **28,0 Mo** | **51,0 Mo** | **17,7 Mo** |
| `musique.pck`, après le menu | - | - | 11 007 288 | 10 493 476 |

- Le navigateur reçoit 10,3 Mo de moins avant le menu, soit 37 % de moins. Dans Chromium (Resource Timing, octets sur le fil, en-têtes compris) : 28,55 Mo avant, 18,27 Mo après.
- Les pistes ne changent pas : mêmes fichiers, même qualité. Le paquet du jeu les range seulement ailleurs.

### Temps jusqu'au menu, et arrivée du second paquet

Le banc de `docs/web-threads.md`, avec le débit limité par Chromium (`Network.emulateNetworkConditions`, 40 ms de latence, cache coupé). Deux mesures par cas.

- Le temps est compté depuis le début du chargement de la page jusqu'à l'apparition du menu.
- Le rendu est logiciel (SwiftShader) : la compilation du `.wasm` et le démarrage du moteur y comptent pour environ 4 s.

| Débit | Menu avant | Menu après | Gagné | Second paquet monté |
| --- | --- | --- | --- | --- |
| 20 Mbit/s | 16,1 / 16,0 s | 11,7 / 11,7 s | 4,3 s (27 %) | 5,7 s après le menu, 0,2 s après la fin du réseau |
| 5 Mbit/s | 49,4 / 49,3 s | 32,8 / 33,3 s | 16,2 s (33 %) | 17,4 s après le menu, 0,1 s après la fin du réseau |

- Le second paquet met le temps du réseau : 5 s à 20 Mbit/s, 17 s à 5 Mbit/s. Il est monté dans la foulée.
- Une première version passait par `HTTPRequest`. Le jeu n'y reprenait qu'un morceau du navigateur par image, et le paquet était monté de 4 à 13 s après la fin du réseau. D'où le téléchargement par le navigateur.

### Entrée au hub avant la fin du téléchargement

Parcours « tôt » à 5 Mbit/s : le pilote part au hub 2,4 s après l'apparition du menu, puis à la Plaine.

| Temps depuis le chargement de la page | Ce qui se passe | Reçu du second paquet |
| --- | --- | --- |
| 33,1 s | Menu affiché, sa piste joue. Le téléchargement de `musique.pck` part | 0 |
| 35,5 s | « Nouvelle partie » : transition vers le hub | 1,3 Mo |
| 43,7 s | Le bunker apparaît, l'introduction joue aussitôt (elle est dans `index.pck`) | 3,0 Mo |
| 58,4 s | Paquet reçu et monté, au hub. L'introduction continue sans coupure | 11,0 Mo |
| 154,3 s | Plaine : sa piste part dès l'arrivée, le paquet est là | 11,0 Mo |

- Pendant le chargement du hub (8 s de fil principal bloqué), le téléchargement n'avance presque pas (0,6 Mo), puis rattrape son retard.
- Le paquet arrive 25 s après le menu au lieu de 17 s quand le joueur reste au menu.

### Musique de chaque lieu, une fois le second paquet monté

Parcours complet à 20 Mbit/s : menu, puis hub et les quatre lieux par les vraies transitions, 8 s dans chacun. Après le changement, le pilote attend d'abord le second paquet au menu (5,7 s). « Musique jouée » compare l'avancée de la piste au temps écoulé (`docs/web-threads.md`).

| Phase | Musique jouée, avant | Musique jouée, après | Piste jouée, après |
| --- | --- | --- | --- |
| Menu, 8 s | 100 % | 100 % | `menu.ogg` (paquet du jeu) |
| Chargement et 8 s au hub | 100 % / 100 % | 100 % / 99 % | `intro.ogg` (paquet du jeu) |
| Chargement et 8 s à la Plaine | 100 % / 100 % | 100 % / 100 % | `plaine.ogg` (second paquet) |
| Chargement et 8 s au Désert | 100 % / la piste a bouclé | 100 % / la piste a bouclé | `desert.ogg` (second paquet) |
| Chargement et 8 s au Marais | 100 % / 100 % | 100 % / 100 % | `marais.ogg` (second paquet) |
| Chargement et 8 s au Village | 100 % / 100 % | 100 % / 100 % | `village.ogg` (second paquet) |

- Le worklet audio n'a rendu aucun quantum sans données sur toute la session, avant comme après : 0 ms de silence.
- Les pistes venues du second paquet jouent comme les autres, chacune dès l'apparition de son lieu.
- La console du navigateur a les mêmes messages avant et après : aucune erreur ni avertissement de la musique.
- Les durées de chargement des lieux restent du même ordre. Elles varient d'une mesure à l'autre avec la charge du serveur (rendu logiciel, sur une machine partagée).

### Entrée dans un lieu avant la fin du téléchargement

Parcours « plaine » à 5 Mbit/s : le pilote part à la Plaine 2,1 s après l'apparition du menu, sans passer par le hub. Sa piste est dans le second paquet.

| Temps depuis le chargement de la page | Ce qui se passe | Reçu du second paquet |
| --- | --- | --- |
| 32,5 s | Menu affiché, sa piste joue. Le téléchargement part | 0 |
| 34,6 s | Transition vers la Plaine. La piste du menu s'efface | 1,2 Mo |
| 40,6 s | La scène de la Plaine est en place, sous le titre. Sa piste est demandée et attend en silence (`is_waiting_for_pack`) | 3,8 Mo |
| 58,0 s | Le navigateur a tout reçu | 11,0 Mo |
| 71,1 s | Paquet monté : la piste de la Plaine part aussitôt, en fondu | 11,0 Mo |
| 106,0 s | Fin de la transition : la Plaine se dévoile, sa musique joue depuis 35 s | 11,0 Mo |

- Aucune erreur ni avertissement dans la console, et aucune image bloquée par la musique.
- Le paquet est monté 13 s après la fin du réseau. Le navigateur l'avait reçu en entier, mais le jeu n'a produit aucune image entre 50,2 s et 70,8 s, pendant que la Plaine s'installait en rendu logiciel. La reprise du paquet attend la première image suivante.
- Sur une vraie carte graphique, ces pauses sont bien plus courtes.

### Outils

Les outils sont dans `.claude/captures/perf-musique/outils/` (hors dépôt) :

- `perf.py` est copié du banc de `perf-web`, avec le débit limité et le relevé Resource Timing ;
- le pilote `driver/perf_driver.gd` propose les parcours « menu », « complet », « tôt » et « plaine » ;
- `pck_list.py` liste le contenu d'un `.pck`.

Les relevés sont dans `mesures/`.

## Autres gains possibles, non appliqués

Mesurés sur l'export de production, ils sont proposés ici, pas faits :

- **Brotli au niveau 11 pour `index.wasm`** :
  - 6,89 Mo au lieu de 7,90 Mo au niveau 9, soit 1,0 Mo de moins avant le menu, sans aucun changement du jeu ;
  - pour `index.pck`, le gain n'est que de 0,17 Mo (9,54 Mo au lieu de 9,71) ;
  - coût : environ 100 s de calcul de plus à chaque construction sur ce serveur, contre 18 s au niveau 9.
  - `index.wasm` est identique d'une construction à l'autre (vérifié octet pour octet) : il pourrait être compressé une seule fois, dans une couche Docker en cache, tant que Godot ne change pas.
- **ETag stables** :
  - Caddy calcule l'ETag à partir de la date et de la taille du fichier, et chaque construction redonne une date neuve ;
  - après chaque déploiement, un joueur qui revient retélécharge donc `index.wasm` (7,9 Mo) et `musique.pck` (10,5 Mo), même s'ils n'ont pas changé. Tous deux sont identiques octet pour octet d'une construction à l'autre ;
  - une date tirée du contenu (par exemple `touch -d @<empreinte>` dans le `Dockerfile`) garderait leur ETag d'un déploiement à l'autre.
- **Images de l'interface** :
  - `ruminate_studio.png`, `devlyn_portrait.png` et `codequest_icon.png` pèsent 620 Ko dans `index.pck`, importées sans perte. Brotli n'y gagne rien.
  - Un import avec perte (WebP) en gagnerait la plus grande part, au prix d'une légère baisse de qualité.
  - L'icône du projet est en plus copiée brute dans chaque paquet (226 Ko, y compris `musique.pck`), et en favicon de 237 Ko (`index.icon.png`). Une icône plus petite allégerait les trois.
- **Moteur sur mesure** : un `index.wasm` compilé sans les modules inutiles au jeu serait nettement plus léger. Il faut alors construire et maintenir ses propres modèles d'export (Emscripten), ce qui n'est pas un gain sûr à court terme.

## Revenir en arrière

1. Remettre `assets/audio/music/*.ogg` dans le filtre d'inclusion du préréglage « Web ».
2. Le jeu ne télécharge alors plus rien : aucune piste ne manque.
3. Le préréglage « Web musique » et la ligne `--export-pack` du `Dockerfile` peuvent rester ou partir.
