# Version web : le jeu dans Chromium, Firefox et WebKit

Vérification du 8 novembre, sur `dev` (65bf07f) puis avec les corrections de la branche `fix/compat-navigateurs`. Le tableau résumé est dans `docs/web-threads.md`, partie « Navigateurs ».

## En bref

| Navigateur testé | Démarrage, menu, son, `musique.pck` | Partie (bunker, hub, Plaine) | Ce qui reste |
| --- | --- | --- | --- |
| Chromium 156 | Oui | Oui : clavier, souris capturée, caméra à la souris, E, H, Échap, musique de chaque lieu | Rien de propre au jeu. Le processus graphique de Chromium a planté une fois au hub, avec un rendu logiciel |
| WebKit 27.2 (moteur de Safari) | Oui, **après correction** : avant, le jeu ne démarrait pas quand le paquet arrivait en gzip | Oui : clavier, souris capturée, E, H, Échap, musique de la Plaine venue de `musique.pck` | Une erreur WebGL à chaque image (`glBlitFramebuffer`, présentation d'Emscripten), sans effet visible. Caméra à la souris non vérifiable avec l'outil |
| Firefox 157 | Oui | Le bunker, avec un rendu logiciel plus lent (softpipe) : clavier, souris capturée, caméra à la souris, E, H, Échap, musique. Avec le rendu logiciel habituel (llvmpipe), Firefox plante au premier dessin du bunker | À essayer sur un vrai PC |

Ce banc n'a pas de carte graphique : chaque navigateur y dessine en logiciel. Chromium utilise SwiftShader. Firefox et WebKit utilisent llvmpipe (Mesa 25.2.8). Safari sur Mac ou sur iPhone n'a pas pu être testé : WebKit sous Linux en est le moteur, pas le navigateur.

## Corrections

### Le jeu ne démarrait pas dans WebKit quand le paquet arrivait en gzip

- **Symptôme.** Console : « Cannot open resource pack 'index.pck' », puis « Couldn't load project data ». Le jeu s'arrête sur l'écran de chargement.
- **Cause.**
  - `index.pck` et `musique.pck` ont une extension que Caddy ne connaît pas. Il ne leur donne donc aucun `Content-Type`.
  - Quand le navigateur ne demande pas brotli, Caddy envoie le `.gz` précompressé. La directive `encode` devine alors le type d'après les premiers octets du fichier envoyé : `Content-Type: application/x-gzip`, en plus de `Content-Encoding: gzip`.
  - WebKit ne décompresse pas un fichier ainsi annoncé : il le prend pour une archive gzip voulue telle quelle. Godot reçoit le paquet compressé, et ne le reconnaît pas.
  - Chromium et Firefox décompressent quand même : vérifié en forçant `Accept-Encoding: gzip, deflate`.
- **Qui était touché.** Tout navigateur WebKit qui reçoit le `.gz` :
  - WebKit en HTTP (sur `localhost`, en développement) ;
  - un proxy, un antivirus ou un pare-feu d'entreprise qui retire brotli de la demande.
  - En HTTPS, Safari demande brotli et reçoit le `.br`, qui n'a pas ce défaut : vérifié avec WebKit en HTTPS (certificat local de Caddy). Le site de production n'était donc pas en panne pour un Safari ordinaire.
- **Correction** (`infrastructure/Caddyfile`). Les `.pck` reçoivent un type explicite, `Content-Type: application/octet-stream`.
- **Vérification.**
  - `curl` avec `Accept-Encoding` à `gzip`, `br`, `identity`, `zstd` et la demande complète d'un navigateur : `application/octet-stream` partout. COOP, COEP, `no-cache`, ETag et longueurs sont inchangés.
  - WebKit en HTTP : le paquet reçu commence par `GDPC` (11 845 856 octets décompressés), le jeu démarre, et le parcours complet passe.

### Messages en français quand le jeu ne peut pas démarrer

`frontend/web/shell.html` est la page du jeu (préréglage « Web », `html/custom_html_shell`). C'est le modèle exact de Godot 4.7.2 (`godot.html` des modèles d'export), avec trois ajouts.

- **Fonctions manquantes.** Godot affichait en anglais « The following features required to run Godot projects on the Web are missing ». La page dit maintenant ce qui manque, et ce que le joueur peut faire :
  - WebGL 2 absent : activer l'accélération matérielle, mettre à jour le pilote graphique, ne pas jouer dans une machine virtuelle ou un bureau à distance ;
  - page non isolée : ouvrir le jeu à son adresse, dans un onglet, et pas dans le cadre d'un autre site. Un proxy ou une extension qui retire les en-têtes peut aussi en être la cause ;
  - HTTP au lieu de HTTPS ;
  - navigateur trop ancien.
  - Le texte de Godot reste dessous, en petit, pour qui aide le joueur.
- **Erreur au démarrage** (mémoire, téléchargement) : « Le jeu n'a pas pu démarrer », avec quoi faire, puis le détail.
- **Affichage perdu en cours de partie** (`webglcontextlost`).
  - Godot ne sait pas recréer ses ressources graphiques. Il ouvrait une alerte en anglais, « WebGL context lost, please reload the page », puis laissait un écran noir.
  - La page affiche maintenant un message en français, avec un bouton « Recharger la page ». Le joueur reprend ensuite sa partie par « Charger partie ».
  - Les autres alertes passent comme avant.
- **Vérification.**
  - Firefox sans écran, qui n'a pas de WebGL : bon message.
  - Chromium sur une page privée de COOP et COEP (réécrite à la volée) : bon message.
  - Chromium, contexte WebGL perdu en plein menu (`WEBGL_lose_context`) : le message apparaît, et aucune alerte ne s'ouvre.

## Ce qui ne dépend pas de nous

### Firefox et llvmpipe : plantage du navigateur

- **Symptôme.** Firefox se ferme d'un coup :
  - au menu, pendant la préparation des shaders (`docs/shaders-menu.md`), de 8 à 20 s après son affichage ;
  - au premier dessin du bunker, si la préparation est coupée.
- **Cause.** Un `SIGSEGV` dans le processus principal de Firefox, relevé avec gdb :
  - fil `llvmpipe-0`, dans le code des shaders que llvmpipe compile avec LLVM ;
  - ou, avec `LP_NUM_THREADS=0`, dans le fil `CanvasRenderer` (le WebGL de Firefox), sur une lecture vectorielle hors de la mémoire (`ld1 {v2.s}[3], [x14]`).
  - Le plantage ne se produit qu'avec llvmpipe : le même menu tient 90 s avec softpipe, le rendu logiciel de Mesa sans LLVM. WebKit, sur le même llvmpipe, dessine tout le jeu sans planter.
- **Ce qu'on en conclut.**
  - Le plantage a lieu dans le pilote logiciel (llvmpipe), dans le processus de Firefox. Il ne se produit ni avec softpipe, ni dans WebKit sur le même llvmpipe, ni dans Chromium (SwiftShader).
  - Rien ne montre qu'il touche une vraie carte graphique.
  - Le cas d'un joueur sous Linux sans accélération matérielle (llvmpipe) n'est pas exclu. Il serait de toute façon bien trop lent pour jouer.
  - **Non vérifié avec une vraie carte graphique.** Firefox doit être essayé sur un vrai PC (Windows, ou Linux avec son pilote).
- **Contournement pour le joueur.** Activer l'accélération matérielle, ou prendre un autre navigateur. Sans WebGL du tout, la page le dit maintenant en français.
- **Ce qui a été vérifié dans Firefox 157**, jusqu'au plantage :
  - isolation ;
  - WebGL 2, une fois Firefox lancé avec une fenêtre (Xvfb). Sans écran, Firefox n'a pas de WebGL ;
  - démarrage et menu ;
  - son au premier clic, et piste du menu ;
  - `musique.pck` téléchargé, repris et monté ;
  - écran d'introduction ;
  - aucune erreur JavaScript.
- **Dans le jeu, avec softpipe** (`GALLIUM_DRIVER=softpipe`, rendu logiciel sans LLVM, une image toutes les quelques secondes) :
  - le bunker s'affiche comme dans Chromium et WebKit, et l'introduction joue ;
  - ZQSD/WASD déplacent le joueur, la souris capturée tourne la caméra ;
  - H ouvre et referme les indices, Échap ouvre et referme la pause ;
  - E auprès du roi ouvre son texte, E le referme ;
  - aucune erreur JavaScript.
  - Le parcours a été arrêté là : à ce rythme, le hub et la Plaine auraient pris plus d'une heure.
  - Le jeu tourne donc dans Firefox : seul llvmpipe plante.
- **Souris et images lentes.** Firefox n'accorde la souris que dans la seconde qui suit le clic ou la touche (« Request for pointer lock was denied because Element.requestPointerLock() was not called from inside a short running user-generated event handler »). Chromium laisse plusieurs secondes.
  - Godot traite le clic à l'image suivante. Si une image dure plus d'une seconde, le clic ne capture pas la souris : vu avec softpipe, où il a fallu un second clic.
  - Sur une machine normale, une image dure bien moins d'une seconde. Le joueur n'a qu'à recliquer.

### Chromium : processus graphique planté une fois

- **Ce qui s'est passé.** Une seule fois, au premier dessin du hub dehors, dans Chromium avec fenêtre (Xvfb) : « GPU process exited unexpectedly ».
  - Le contexte WebGL est perdu, puis Chromium le recrée, mais Godot ne sait pas s'en servir.
  - Ensuite : écran noir, et des milliers d'erreurs `glBlitFramebuffer` (« Blit feedback loop ») sur le cadre par défaut.
  - Le son, le clavier et les scènes continuaient.
- **Le même parcours sans fenêtre est passé au même endroit sans plantage.**
- **Ce qu'on en conclut.**
  - La cause n'est pas trouvée : le processus graphique (SwiftShader, rendu logiciel) s'est arrêté avec le code 512, sans pile exploitable.
  - Pour un joueur, c'est l'équivalent d'une réinitialisation du pilote graphique.
- **Ce qui change pour le joueur.** Le cas est maintenant expliqué en français, avec un bouton pour recharger, au lieu de l'alerte en anglais et de l'écran noir.

### WebKit : une erreur `glBlitFramebuffer` à chaque image

- **Symptôme.** WebKit écrit 16 fois « WebGL: INVALID_OPERATION: glBlitFramebuffer: Read and write color attachments cannot be the same image », dès l'affichage du menu, puis cesse de les compter (« No more validation messages will be reported »).
- **Ce que c'est.** Chaque appel WebGL a été suivi d'un `getError` pendant 8 s de menu (`outils/glerr.py`) :
  - dans WebKit, la copie qui échoue est la même à chaque image : `blitFramebuffer(0, 0, 1280, 720, 0, 0, 1280, 720, COLOR_BUFFER_BIT, NEAREST)`, de la mémoire d'image du moteur (une texture et un tampon de profondeur) vers la page ;
  - dans Chromium : aucune erreur sur 60 561 appels.
- **D'où vient cette copie.** C'est la présentation d'image d'Emscripten (`blitOffscreenFramebuffer`, dans `index.js`).
  - Godot crée son contexte WebGL avec `explicitSwapControl` (`platform/web/display_server_web.cpp`). Emscripten dessine alors chaque image hors de la page, puis la copie sur la page.
  - Ni le jeu ni la page ne la contrôlent.
- **Effet.** Aucun effet visible : les images changent comme prévu (captures du menu, du bunker, du hub et de la Plaine dans `mesures/wk_*`). WebKit signale l'erreur, mais l'image arrive.
- **Non vérifié** dans Safari sur Mac, qui dessine par Metal et non par OpenGL.

### Firefox : avertissement sur WebAssembly

- Firefox écrit 9 fois « The WebAssembly exception handling 'try' instruction is deprecated ».
- Le moteur (Godot 4.7.2, compilé avec Emscripten 4.0.20) gère ses exceptions avec l'ancienne forme des instructions WebAssembly. Firefox l'accepte encore, et le signale.
- Ce n'est qu'un avertissement, sans effet. Il partira avec un moteur compilé avec la nouvelle forme.
- Dans le bunker, Firefox écrit aussi une trentaine de fois « getBufferSubData: Reading from a buffer with usage other than *_READ causes pipeline stalls », puis cesse de les compter. C'est un conseil de performance sur une lecture de tampon faite par le moteur, pas une erreur.

### Verrou de la souris dans un navigateur sans écran

- **Les trois navigateurs** posent le verrou à l'image suivante d'un clic ou d'une touche, comme le fait Godot : vérifié avec fenêtre (Xvfb), sur une page de test et dans le jeu.
- **Sans écran :**
  - WebKit refuse toujours le verrou (« Pointer lock requires the window to have focus ») ;
  - Chromium le pose, mais ses mouvements ont `movementX = 0`.
- **Avec fenêtre, WebKit** pose le verrou, mais Playwright n'y produit pas de déplacement. La caméra à la souris n'a donc été vérifiée dans le jeu qu'avec Chromium.
- **Au début d'un lieu**, le jeu demande la souris longtemps après le dernier geste (le chargement dure plusieurs secondes). Le navigateur refuse alors : WebKit écrit « NotAllowedError: Pointer lock requires a user gesture ». Le premier clic dans le jeu la capture (`player.gd`), comme prévu.

### Clavier : ZQSD et WASD

- Les actions de déplacement sont liées à des codes physiques (`physical_keycode`, d'après `KeyboardEvent.code`).
- Sur un clavier AZERTY, Z, Q, S et D envoient les codes `KeyW`, `KeyA`, `KeyS` et `KeyD`, comme W, A, S et D en QWERTY.
- Playwright tape en QWERTY : le test appuie sur `KeyW`, `KeyA`, `KeyS` et `KeyD`, et le joueur bouge dans les trois navigateurs.
- E (`KeyE`) et H (`KeyH`) sont à la même place sur les deux claviers.

## Mesures

Même outil pour les trois navigateurs. Chaque temps est compté depuis le début du chargement de la page (menu), ou depuis la demande (clic sur « Commencer », entrée dans le portail). « Scène » : la scène est en place sous le titre. « Prête » : la transition est finie.

- Le rendu est logiciel, sur un serveur de 4 cœurs déjà chargé : les temps varient fortement d'un passage à l'autre. On compare les ordres de grandeur, pas les dixièmes.
- llvmpipe (Firefox, WebKit) est plus rapide que SwiftShader (Chromium) sur ce serveur : ces écarts ne disent rien d'un vrai PC.

### Export identique à la production

Le menu est repéré à la demande de `musique.pck`, que le jeu lance deux images après l'avoir affiché.

| | Chromium 156 | WebKit 27.2 | Firefox 157 |
| --- | --- | --- | --- |
| Menu affiché | 5,4 s | 5,5 s | 5,8 s |
| Musique du menu après le premier clic | oui | oui | oui |
| `musique.pck` reçu et repris | oui | oui | oui |
| Bunker, H, Échap, ZQSD | oui | oui | plantage au menu, pendant la préparation des shaders (llvmpipe) |
| Erreurs JavaScript ou de Godot | aucune | l'erreur `glBlitFramebuffer` de WebKit | aucune avant le plantage |

Captures et journaux : `mesures/ch_prod_1/`, `mesures/wk_prod_1/` et `mesures/ff_prod_1/`.

### Variante avec sonde : temps exacts

| | Chromium 156, sans écran | Chromium 156, fenêtre | WebKit 27.2, sans écran | WebKit 27.2, fenêtre | Firefox 157, fenêtre |
| --- | --- | --- | --- | --- | --- |
| Menu affiché | 4,2 s | 6,6 s | 4,6 s | 4,3 s | 5,3 s |
| `musique.pck` monté | 4,7 s | 8,1 s | 5,9 s | 5,8 s | 8,0 s |
| Bunker : scène | 12,9 s | 7,5 s | 12,7 s | 14,8 s | plantage |
| Bunker : prête | 24,4 s | 21,2 s | 17,0 s | 18,9 s | |
| Plaine : scène | 47,9 s | non valable (affichage perdu) | 19,9 s | 16,9 s | |
| Plaine : prête | 139,9 s | non valable | 25,1 s | 20,7 s | |

- Le menu et le second paquet arrivent dans les mêmes temps dans les trois navigateurs : quelques secondes, surtout la compilation de `index.wasm` et le démarrage du moteur.
- Les chargements de lieux varient du simple au triple d'un passage à l'autre dans Chromium sans écran (Plaine : 140 s ici, alors que le serveur était chargé par d'autres mesures). Ils ne disent rien de l'écart entre navigateurs sur un vrai PC.
- Firefox, sur ce banc, plante avant le bunker (voir plus haut).

Captures et journaux : `mesures/ch_sonde_2/` (sans écran), `mesures/ch_sonde_1/` (fenêtre), `mesures/wk_sonde_2/`, `mesures/wk_sonde_3/`, `mesures/ff_sonde_6/` (llvmpipe) et `mesures/ff_softpipe/` (softpipe).

## Le banc

Les outils sont dans `.claude/captures/navigateurs/outils/` (hors dépôt), et les relevés, captures et journaux dans `.claude/captures/navigateurs/mesures/`.

- **Image Playwright** `cdp-navigateurs-pw`.
  - Ubuntu 24.04 arm64, Playwright 1.64.1 : Chromium 156.0.8078.4, Firefox 157.0, WebKit 27.2.
  - PulseAudio avec une sortie nulle, pour que Firefox et WebKit aient une vraie sortie son.
  - Xvfb, car Firefox n'a pas de WebGL sans écran.
  - gdb, pour les piles de plantage.
- **Export.**
  - L'export identique à la production (`frontend/Dockerfile`), servi par son Caddy et le vrai Caddyfile.
  - Le conteneur tourne sur un réseau Docker interne, sans sortie : l'API est morte, et rien ne touche la production.
- **Variante avec sonde** (`outils/sonde/sonde.gd`, ajoutée par `build_sonde.sh`, jamais livrée).
  - La sonde observe le jeu : scène, transition, musique, paquet, souris, pause, indices, lecteur, invite.
  - Elle a une seule commande : placer le joueur devant un personnage, une porte ou un portail. Le reste passe par le clavier et la souris du navigateur.
- **Parcours** (`nav.py`). Contrôles :
  - isolation, `SharedArrayBuffer`, mémoire WebAssembly partagée, WebGL 2, AudioWorklet ;
  - menu, puis le son avant et après le premier clic ;
  - `musique.pck` reçu, repris et monté ;
  - « Jouer en tant qu'invité », « Commencer », puis le bunker ;
  - la souris capturée et la caméra, ZQSD/WASD, H, Échap ;
  - E auprès du roi, puis de Merlon, et la sortie du bunker ;
  - le hub et son thème ;
  - W tenu jusque dans le portail de la Plaine, puis la Plaine et sa musique.
- **Son.** Deux analyseurs sont branchés sur la sortie de Godot : tout le son, et le flux du mélangeur (la musique). Le niveau (RMS) dit si la musique est audible.
- **Commande.** `outils/run_nav.sh <image> <chromium|firefox|webkit> <nom> [--sonde] [--fenetre] [--lp0] [--softpipe]`. Une seule mesure de navigateur à la fois : le script attend la fin de celles des autres agents.
