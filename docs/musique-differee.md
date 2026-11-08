# Version web : la musique des lieux arrive après le menu

## Le problème

Avant d'afficher le menu, le navigateur téléchargeait tout le jeu : `index.wasm` (7,9 Mo en brotli) et `index.pck` (22,4 Mo, 20,0 Mo en brotli). La musique pesait 14,1 Mo de ce paquet, et l'OGG ne se compresse pas davantage. Le joueur attendait donc ces 14 Mo avant le menu, alors qu'il n'entend d'abord que la piste du menu.

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
- **Jeu** (`frontend/scripts/music.gd`, autoload `Music`), sur le web seulement (`OS.has_feature("web")`) :
  1. Une fois la première scène (le menu) affichée, `Music` regarde s'il manque des pistes au paquet du jeu (`ResourceLoader.exists`).
  2. S'il en manque, il télécharge `musique.pck` à côté de la page (`new URL('musique.pck', document.baseURI)`), avec un `HTTPRequest`, en arrière-plan.
  3. Il monte ensuite le paquet avec `ProjectSettings.load_resource_pack(chemin, false)`. `false` : aucun fichier du jeu n'est remplacé, seules les pistes manquantes s'ajoutent.
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

- **Pas de `download_file` : le corps arrive en mémoire, et le jeu écrit le fichier lui-même.**
  - Sur le web, `HTTPClientWeb` ne connaît jamais la longueur de la réponse (`get_response_body_length` vaut -1) : le téléchargement se termine par la branche « lu jusqu'à la fin » de `HTTPRequest`.
  - Cette branche ne pose pas `download_complete`, et `cancel_request()`, appelé juste avant `request_completed`, efface alors le fichier reçu (Godot 4.7.2, `scene/main/http_request.cpp`).
  - Avec `download_file`, le paquet arrivait en entier (11 007 352 octets), puis disparaissait avant le montage : « paquet illisible », et nouvelles tentatives sans fin.
  - Le corps passe donc par la mémoire du moteur (11 Mo, le temps de l'écrire), puis va dans le fichier.
- **`accept_gzip = false`.**
  - Le navigateur décode lui-même la réponse (brotli ou gzip), et `fetch` rend un corps déjà décodé.
  - Mais l'en-tête `Content-Encoding` reste dans la réponse. Avec `accept_gzip`, `HTTPRequest` décoderait une seconde fois un corps marqué gzip, et échouerait (`scene/main/http_request.cpp`, aucune exception pour le web).
- **`download_chunk_size` à 1 Mo.** Sans fil dédié, `HTTPRequest` lit au plus un bloc par image : 64 Ko par défaut, soit moins de 4 Mo/s à 60 images par seconde.
- **Le navigateur reçoit, le jeu lit entre les images.**
  - Le réseau, lui, ne dépend pas du jeu : le navigateur garde ce qu'il reçoit.
  - Godot, lui, ne reprend qu'un bloc du navigateur par image (`library_godot_fetch.js`). Dans la mesure à 20 Mbit/s, le navigateur avait tout reçu 4 s avant que le jeu ait tout lu.
  - Le chargement d'un lieu bloque le fil principal plusieurs secondes (docs/web-threads.md) : la lecture s'arrête pendant ce temps, puis reprend.
  - Le paquet part donc dès le menu : en général, il est là avant le premier lieu.

## Où le paquet est écrit

- **Emplacement choisi : `OS.get_cache_dir()`.** Sur le web, c'est `/home/web_user/.cache`.
- **Pourquoi pas `user://` :**
  - Sur le web, Godot monte seulement `user://` (`/userfs`) sur IndexedDB (IDBFS), qu'il recopie après chaque fichier fermé (`OS_Web`, `GodotFS`, voir le code de Godot 4.7.2). Le reste du système de fichiers d'Emscripten est en mémoire (MEMFS) : c'est là qu'est déjà `index.pck`.
  - Écrit dans `user://`, le paquet (11 Mo) serait recopié dans IndexedDB après chaque téléchargement. Surtout, il serait relu en entier à chaque lancement, avant le menu : au démarrage, `GodotFS.init` recopie tout IDBFS en mémoire (`FS.syncfs(true)`).
  - Il gonflerait aussi la sauvegarde, que le joueur ne vide jamais.
- **Coût en mémoire.** Le paquet occupe 11 Mo de mémoire JavaScript tant que la page est ouverte, comme `index.pck`. Une piste chargée y est lue au moment voulu.
- **Le cache du navigateur suffit pour la visite suivante.**
  - `HTTPRequest` passe par `fetch`, donc par le cache HTTP.
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
- **Le cas propre au web** (réponse sans longueur connue) ne se reproduit pas en natif : le client HTTP natif traite la fermeture de la connexion comme une erreur.
  - Il se vérifie dans le navigateur, avec le banc décrit plus bas.

## Mesures

(à compléter)

## Autres gains possibles, non appliqués

Mesurés sur l'export de production, ils sont proposés ici, pas faits :

- **Brotli au niveau 11 pour `index.wasm`** :
  - 6,89 Mo au lieu de 7,90 Mo au niveau 9, soit 1,0 Mo de moins avant le menu, sans aucun changement du jeu ;
  - pour `index.pck`, le gain n'est que de 0,17 Mo (9,54 Mo au lieu de 9,71) ;
  - coût : environ 100 s de calcul de plus à chaque construction sur ce serveur, contre 18 s au niveau 9.
  - Le `.wasm` est copié tel quel du modèle d'export : il pourrait être compressé une seule fois, dans la couche Docker des modèles, et réutilisé tant que Godot ne change pas.
- **ETag stables** :
  - Caddy calcule l'ETag à partir de la date et de la taille du fichier, et chaque construction redonne une date neuve ;
  - après chaque déploiement, un joueur qui revient retélécharge donc `index.wasm` (7,9 Mo) et `musique.pck` (10,5 Mo), même s'ils n'ont pas changé ;
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
