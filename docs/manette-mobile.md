# Manette et appareils mobiles

Retour des testeurs : « Voir pour ajouter un support Mobile et support manette (Secondaire, à voir plus tard). »

- **Manette** : réalisée. Le jeu se joue en entier à la manette standard, menus, panneaux d'énigme et clavier virtuel compris. Rien ne change au clavier et à la souris.
- **Mobile** : étudié, pas réalisé. Un vrai support tactile coûterait plusieurs jours et des essais sur de vrais téléphones (voir l'étude plus bas). Sur un appareil seulement tactile, la page dit maintenant, en français, que le jeu se joue sur ordinateur ou à la manette, avant de rien télécharger, et propose de le lancer quand même. Avec une manette reliée au téléphone, le jeu se joue entièrement.

## Commandes à la manette

Disposition standard de l'API Gamepad des navigateurs, celle d'une manette Xbox. Une manette PlayStation ou Switch Pro y est ramenée par le navigateur : A est la croix (PlayStation) ou B (Switch), à la même place en bas.

### En jeu

| Bouton | Action | Touche équivalente |
| --- | --- | --- |
| Stick gauche | Avancer, reculer, se tourner (la vitesse suit l'inclinaison) | Z Q S D |
| Stick droit | Regarder | souris, flèches |
| A | Interagir, parler, lire ; maintenir pour dégager le sable (Désert) | E |
| X | Sauter | Espace |
| B (maintenu) ou L3 (stick gauche enfoncé) | Courir | Shift |
| Y | Indices | H |
| Menu (Start) | Pause | Échap, P |
| Affichage (Back) | Carnet des fragments (Village) | I, Tab |

Le plein écran (F, F11) reste au clavier : dans un navigateur, il n'est permis qu'après un clic ou une touche, pas après un bouton de manette.

### Menus, pause, indices, lecteur de textes et panneaux d'énigme

| Bouton | Action |
| --- | --- |
| Croix ou stick gauche | Choisir un bouton (cadre doré et deux losanges autour du bouton choisi) |
| A | Valider le bouton choisi ; sur un champ de saisie, ouvrir le clavier virtuel |
| B | Revenir en arrière : écran précédent des menus, fermer la confirmation, la pause, les indices, le texte lu ou le panneau d'énigme |
| Stick droit | Faire défiler une liste : carnet, fragments du dispositif des codes, classement |

- **Accueil et menus** : le premier appui choisit le bouton mis en avant (« Jouer en tant qu'invité », « Commencer »…) sans encore le presser. La confirmation « Nouvelle partie » commence sur « Annuler », et la sélection ne la quitte pas tant qu'elle est ouverte.
- **Pause** : Menu l'ouvre ; B ou Menu la referme ; « Reprendre » est choisi d'office. Le cadre « Commandes » montre les boutons de la manette.
- **Indices** : Y ouvre et referme, la croix relit les indices précédents, A sur « Fermer » ou B referme. « rouvrez avec H » devient « rouvrez avec Y », et les indices qui citent une touche la récrivent (« maintenez A », « avec le bouton Affichage »).
- **Lecteur de textes** : A ou B referme.
- **Tablette de la Plaine** : la croix passe des fragments aux six cases ; A choisit un fragment, puis A sur une case l'y pose (ou libère une case remplie) ; « Valider » en bas.
- **Table des runes du Désert** : de même avec les runes et les cases des deux algorithmes.
- **Cercles du Marais** : la croix passe d'une flèche à l'autre (le panneau s'ouvre sur celle qui avance le cercle I), A tourne le cercle ; « Valider » et « Se relever » en bas.
- **Dispositif des codes du Village** : la croix passe des onglets au champ de réponse et à « Valider » ; A sur le champ ouvre le clavier virtuel.
- **Carnet des fragments** : Affichage, A ou B le referme, la croix et le stick droit le font défiler.

### Clavier virtuel : la solution du Village

Les réponses des cinq codes sont libres (« 3 » ou « trois », « green » ou « vert »…). Une liste de réponses à choisir les aurait réduites à quelques propositions, et aurait donné la réponse par élimination. Le dispositif garde donc la saisie libre, avec un clavier virtuel dans le style des menus (`frontend/scenes/ui/menus/pad_keyboard.gd`) :

- chiffres, lettres de a à z, `- _ . @`, et une seconde page d'accents et de signes (é è ê ë à â ç ù î ô, ponctuation) ;
- la croix choisit une touche, A l'écrit ; X efface, Y met une espace, LB passe aux majuscules, RB aux accents et signes ; Menu valide, comme Entrée ; B referme en gardant le texte ;
- la question de l'épreuve est rappelée en tête, car le clavier recouvre le bas du dispositif ; l'extrait de code reste visible au-dessus ;
- il sert aussi aux menus : adresse e-mail, mot de passe (écrit en étoiles), pseudo, et les six cases du code de vérification ;
- il se referme dès que le joueur reprend le clavier ou la souris : le champ retrouve alors la frappe.

### Bascule entre la manette et le clavier

- Un bouton de la manette, ou un stick poussé à plus de la moitié, passe en mode manette. Une touche du clavier, un clic, ou un mouvement de souris de plus de 24 pixels revient au clavier.
- Les invites montrent le bouton de la manette (A dans un rond doré, à la lettre verte comme sur une manette Xbox), ou la touche du clavier (E dans sa touche). Les messages aussi : « [I] pour relire vos fragments » montre le bouton Affichage à la manette.
- Les rappels de commandes (accueil, pause, dispositif des codes, carnet) changent avec le mode.
- **Au clavier et à la souris, rien ne change** : les boutons ne prennent jamais le focus (`FOCUS_NONE`), comme avant ; le survol de la souris, les textes, les touches et les commandes sont les mêmes. Le stick droit et les flèches partagent les actions `look_*`, mais les flèches gardent leur vitesse (`key_turn_speed`).

### Réglages

Le jeu n'a pas d'écran de réglages : les valeurs sont des propriétés du joueur (`frontend/scenes/player/player.gd`, groupe « Manette »).

| Réglage | Valeur |
| --- | --- |
| Rotation au stick droit à fond | 3,2 rad/s à l'horizontale, 2,0 rad/s à la verticale |
| Courbe du stick droit | 1,7 : une petite inclinaison tourne lentement, pour viser un objet |
| Zone morte du stick droit | 0,15 (actions `look_*` de `project.godot`) |
| Zone morte du stick gauche | 0,2 (actions de déplacement) |
| Inversion du haut et du bas | `pad_invert_y`, désactivée |

La caméra au stick tourne à chaque image affichée (`_process`) : à 144 images par seconde, elle ne saute pas de 60 en 60.

### Version web

- Godot lit les manettes avec `navigator.getGamepads()` à chaque image. Une manette que le navigateur annonce en disposition « standard » (Xbox, PlayStation, Switch Pro dans Chrome, Edge et Safari ; Firefox sous Windows et macOS) suit la table ci-dessus. Une manette annoncée sans disposition standard (certaines sous Firefox et Linux) peut avoir ses boutons dans un autre ordre.
- Le navigateur ne fait connaître une manette qu'après l'appui sur l'un de ses boutons, la page étant affichée.
- **Son** : un navigateur n'ouvre le son qu'après un clic, une touche ou un toucher. Un bouton de manette ne compte pas : un joueur qui ne touche que la manette n'a pas de son tant qu'il n'a pas cliqué une fois dans la page.
- La souris n'est pas capturée tant que le joueur n'a pas cliqué : sans effet à la manette, qui ne s'en sert pas.
- **Vérifié** le 8 novembre dans Chromium 156, avec l'export identique à la production (`frontend/Dockerfile`, servi par Caddy et le vrai Caddyfile, sans API) : une manette standard simulée (`navigator.getGamepads()` remplacé avant le chargement, puis l'évènement `gamepadconnected`, comme le fait une vraie manette) choisit « Jouer en tant qu'invité » à la croix, valide avec A, commence la partie, marche dans le bunker au stick gauche, ouvre la pause (Menu) avec les commandes de la manette, la referme (B), ouvre et referme les indices (Y). Aucune erreur dans la console. Outil et captures : `.claude/captures/manette/outils/web_manette.py` et `.claude/captures/manette/web/` (hors dépôt).

### Fichiers

- `frontend/scripts/gamepad.gd` (classe `Gamepad`, autoload `GamepadInput`) : bascule, focus de la couche la plus haute (un panneau, la pause par-dessus, le clavier virtuel par-dessus tout), dernier bouton choisi de chaque couche retrouvé à sa fermeture, A et B ajoutés à `ui_accept` et `ui_cancel` au démarrage, A sur un champ, défilement au stick droit, textes adaptés. Ses fonctions statiques ne nomment aucun autoload : `Ornate` et les tests lancés avec `--script` s'en servent.
- `frontend/scenes/ui/menus/pad_keyboard.gd` : le clavier virtuel.
- `frontend/scenes/ui/menus/ornate.gd` : `focus_ring` (cadre du bouton choisi), `pad_glyph` (boutons dessinés : A, B, X, Y ronds à leur couleur, Menu, Affichage, LB, RB, sticks, croix), `KeyCap.action` (la touche devient le bouton lié à l'action), commandes à la manette.
- `frontend/project.godot` : boutons et sticks ajoutés aux actions, actions `look_*`, autoload.
- Les boutons de chaque panneau appellent `Gamepad.setup` au lieu de `focus_mode = FOCUS_NONE`, et dessinent le cadre doré quand ils sont choisis. Les panneaux reconstruits à chaque coup (tablette, runes) gardent le choix sur la même case.

### Vérifier

- `frontend/tests/scenes/gamepad_test.gd` (dans `run_all.sh`) injecte de vrais événements de manette (`InputEventJoypadButton`, `InputEventJoypadMotion`), avec `settle()` après chacun : accueil, introduction, connexion et clavier virtuel, code de vérification, déplacement, caméra et zone morte, saut, PNJ et panneau du Marais, invites manette et clavier, pause, indices, mécanisme aux cinq cercles, carnet et dispositif des codes du Village.
- `frontend/tests/scenes/pad_shots.gd` prend les captures (menus, invites, pause, indices, chaque panneau d'énigme avec le bouton choisi, clavier virtuel) :

  ```
  xvfb-run -a -s "-screen 0 1920x1080x24" godot --audio-driver Dummy --path frontend --resolution 1280x720 \
    --script res://tests/scenes/pad_shots.gd -- <dossier> [menu|marais|plaine|desert|village…] --api=http://127.0.0.1:9/api/v1
  ```

## Appareils mobiles : étude

Question : que coûterait un vrai support tactile (stick virtuel, boutons, caméra au glissé, panneaux d'énigme au toucher, textes lisibles, mémoire et performances WebGL 2 sur téléphone, plein écran, orientation) ?

### Ce que le jeu demande aujourd'hui

**Téléchargement** (export identique à la production, `frontend/Dockerfile`, servi en brotli par Caddy) :

| Fichier | Taille | Transféré (brotli) |
| --- | --- | --- |
| `index.wasm` (moteur) | 38,8 Mo | 6,9 Mo |
| `index.pck` (jeu) | 14,1 Mo | 10,4 Mo |
| `musique.pck` (pistes des lieux, après le menu) | 10,9 Mo | 10,3 Mo |
| Total | 63,8 Mo | 27,6 Mo |

Sur ce serveur, le menu s'affiche 4 à 6 s après le début du chargement, surtout le temps de compiler `index.wasm` (`docs/navigateurs.md`). Un téléphone compile plus lentement qu'un ordinateur : non mesuré ici, faute d'appareil.

**Mémoire et dessin**, mesurés en natif avec le rendu Compatibility (le même que WebGL 2), à 1280 × 720, au point d'arrivée de chaque lieu, après 40 à 240 images (`.claude/captures/manette/outils/mem_probe.gd`, hors dépôt) :

| Lieu | Mémoire du moteur | Mémoire vidéo | dont textures | dont tampons | Appels de dessin par image | Triangles par image | Objets dessinés |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Menu (prépare les shaders des lieux hors de l'écran) | 85 Mo | 33 Mo | 20 Mo | 12 Mo | 196 | 6 484 | 568 |
| Hub | 144 Mo (pic à 161 Mo) | 113 Mo | 43 Mo | 70 Mo | 534 | 569 245 | 604 |
| Plaine | 141 Mo | 66 Mo | 41 Mo | 25 Mo | 534 | 330 680 | 583 |
| Désert | 133 Mo | 66 Mo | 42 Mo | 24 Mo | 651 | 283 303 | 707 |
| Marais | 106 Mo | 70 Mo | 35 Mo | 35 Mo | 460 | 471 951 | 509 |
| Village (dans la grande rue) | 117 Mo | 62 Mo | 37 Mo | 25 Mo | 1 268 | 317 222 | 1 318 |

- La mémoire du moteur (`MEMORY_STATIC`) est celle que le paquet WebAssembly réserve dans le navigateur, à laquelle s'ajoutent le moteur lui-même, le JavaScript et la page. La mémoire vidéo est celle du pilote WebGL. Un lieu demande donc environ 300 Mo à l'onglet : supportable par un téléphone récent, juste pour un téléphone d'entrée de gamme.
- Le coût de dessin est le vrai obstacle : de 460 à 1 300 appels de dessin et de 280 000 à 570 000 triangles par image. Dans un navigateur, chaque appel WebGL est vérifié puis traduit (ANGLE) : un téléphone de milieu de gamme tient quelques centaines d'appels à 30 images par seconde. Les lieux ont été réglés pour un ordinateur (décor dispersé par cases, ombres, distances d'affichage), et il faudrait des réglages propres au téléphone.

**Textures** : le préréglage Web ne compresse les textures que pour l'ordinateur (`vram_texture_compression/for_desktop=true`, `for_mobile=false` : S3TC et BPTC). Les GPU des téléphones (Adreno, Mali, Apple) n'ont en WebGL que l'ETC2 ou l'ASTC : Godot décompresse alors ces 46 textures au chargement, ce qui allonge chaque chargement et multiplie leur mémoire par 4 à 8. Les exporter aussi en ETC2/ASTC (`for_mobile=true`) grossirait `index.pck`.

**Textes et boutons** : toute l'interface est placée à la main sur un écran de référence de 1920 × 1080, étiré en gardant ses proportions (`canvas_items`, `keep`). Sur un téléphone en paysage (844 × 390 points CSS, iPhone 13), l'échelle est de 390 / 1080 = 0,36 :

| Élément | Référence | Sur ce téléphone |
| --- | --- | --- |
| Texte des invites et des indices | 30 px | 10,8 px |
| Fragments de la tablette, runes | 22 à 25 px | 8 à 9 px |
| Texte d'aide, compteurs | 20 à 22 px | 7 à 8 px |
| Flèche d'un cercle du Marais | 60 × 50 px | 22 × 18 px |
| Bouton « Valider » | 340 × 80 px | 122 × 29 px |

En portrait, l'échelle tombe à 0,2. Les recommandations d'Apple et de Google demandent au moins 16 px pour lire et 44 à 48 px pour toucher : il faudrait refaire la mise en page de chaque panneau pour le téléphone, ou une seconde mise en page. Sur une tablette en paysage (1180 × 820, iPad Air), l'échelle est de 0,61 : textes de 13 à 18 px, lisibles mais petits.

### Ce que coûterait un vrai support tactile

| Poste | Travail | Risques |
| --- | --- | --- |
| Commandes tactiles : stick virtuel à gauche, caméra au glissé à droite, boutons (interagir, sauter, courir, indices, pause, carnet), maintien pour le sable | 1 à 2 jours : un calque de commandes, le suivi de plusieurs doigts (`InputEventScreenTouch`, `InputEventScreenDrag`), les invites aux boutons tactiles | Le joueur à la première personne attend une caméra fluide : à régler sur de vrais téléphones |
| Panneaux d'énigme au toucher | Déjà possible : Godot change un toucher en clic (`emulate_mouse_from_touch`). Il reste la taille des cibles (tableau plus haut) | Cibles trop petites sur téléphone |
| Textes et mises en page | 3 à 5 jours : une mise en page « téléphone » des menus, du HUD et des cinq panneaux, ou un agrandissement par panneau | Tout le texte est placé à la main en 1920 × 1080 |
| Saisie : connexion, dispositif des codes | Le clavier virtuel de la manette marche au toucher ; le clavier du téléphone demanderait `html/experimental_virtual_keyboard` | Clavier du système encore expérimental dans Godot 4.7 |
| Orientation | Message « tournez l'appareil » en portrait ; le verrouillage (`screen.orientation.lock`) n'est permis qu'en plein écran sur Android, jamais sur iPhone | |
| Plein écran | Android : possible après un toucher. iPhone : l'API plein écran n'existe pas hors vidéo ; seulement en ajoutant le site à l'écran d'accueil (manifeste d'application web) | |
| Mémoire et WebGL 2 | Exporter les textures en ETC2/ASTC ; essayer chaque lieu sur un iPhone et un Android de milieu de gamme, dont la mémoire par onglet est bien plus basse que sur un ordinateur | Safari sur iPhone et iPad, avec les fils d'exécution et la mémoire partagée qu'exige l'export (`docs/web-threads.md`) : jamais essayé |
| Performances | Le rendu adaptatif (`scripts/render_quality.gd`) baisse déjà la résolution 3D ; il faudrait des réglages téléphone (ombres, distance d'affichage du décor dispersé) | Chauffe et baisse de fréquence du téléphone après quelques minutes |
| Essais | Sur de vrais appareils (iPhone, Android, iPad) : le banc du serveur n'a ni écran tactile réel ni GPU de téléphone | Rien ne peut être vérifié ici au-delà de l'émulation de Chromium |

Total : de 1 à 2 semaines avec les essais, sans compter les corrections que demanderaient les vrais téléphones.

### Conclusion

Un vrai support tactile n'est pas raisonnable maintenant : il demanderait surtout de refaire la mise en page de toute l'interface pour des écrans 3 à 5 fois plus petits, d'alléger le dessin des lieux pour les GPU de téléphone, et des essais sur de vrais téléphones que le serveur ne permet pas. Les commandes tactiles seules, sans cette mise en page, laisseraient des textes de 8 px et des boutons de 20 px.

### Ce qui est fait

- **Message en français sur un appareil seulement tactile** (`frontend/web/shell.html`). La page reconnaît un appareil dont tous les pointeurs sont tactiles (`pointer: coarse` sans `any-pointer: fine`) : téléphone, tablette sans souris ni pavé. Une tablette avec un pavé tactile ou une souris, et un ordinateur à écran tactile, démarrent comme avant. Le message dit, avant de rien télécharger :
  - que CodeQuest se joue sur ordinateur, au clavier et à la souris, ou avec une manette, et qu'il n'a pas de commandes tactiles ;
  - qu'on peut relier une manette (Bluetooth ou USB) et appuyer sur l'un de ses boutons : le jeu se lance ;
  - ce qu'il télécharge (près de 30 Mo) ;
  - avec un bouton « Lancer quand même » (une tablette avec un clavier, par exemple).
- **La manette marche aussi sur un téléphone ou une tablette** : tout le jeu se joue sans toucher l'écran, avec la mise en page actuelle (lisible sur une tablette, petite sur un téléphone).
- Le message d'erreur de démarrage dit aussi que le jeu se joue au clavier et à la souris, ou avec une manette.
- **Vérifié** dans Chromium 156, export identique à la production : sur le bureau, pas de message, le jeu démarre comme avant ; en Pixel 7 émulé (écran tactile, `pointer: coarse`, pas de pointeur fin), le message s'affiche en portrait et en paysage, rien n'est téléchargé avant « Lancer quand même », qui télécharge et lance le jeu ; avec une manette simulée sur ce téléphone, son premier bouton lance le jeu. Captures : `.claude/captures/manette/web/mobile_*.png`.
