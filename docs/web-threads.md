# Version web : fils d'exécution, son et chargements

## Le problème

Sur la version web, la musique saccadait et les lieux mettaient du temps à se charger.

L'export était sans fils d'exécution (`variant/thread_support=false`, modèles `web_nothreads_*`). Dans ce mode, le mélangeur audio de Godot tourne sur le fil principal du navigateur, celui qui calcule aussi les images. Chaque image lente laissait le flux audio sans données, et on entendait un trou ou un hachement :

- le chargement d'un lieu, qui est une seule tâche de 15 à 34 s dans la mesure ci-dessous ;
- le `_ready` d'une scène ;
- le regroupement du décor du hub ;
- la compilation d'un shader.

La réserve de 200 ms (`audio/driver/output_latency.web`) ne couvre que les images de moins de 200 ms.

## Ce qui a changé

- **Export avec fils d'exécution.**
  - `frontend/export_presets.cfg` contient `variant/thread_support=true`.
  - `frontend/Dockerfile` installe les modèles `web_release.zip` et `web_debug.zip`.
  - Le son est mixé sur son propre fil, et écrit dans une mémoire partagée que lit l'AudioWorklet. Une image lente ne coupe plus la musique.
- **Page isolée.**
  - Les fils d'exécution demandent `SharedArrayBuffer`, que le navigateur ne donne qu'à une page isolée (`crossOriginIsolated`).
  - `infrastructure/Caddyfile` envoie, pour le jeu seulement, les en-têtes `Cross-Origin-Opener-Policy: same-origin` et `Cross-Origin-Embedder-Policy: require-corp`.
  - Le jeu ne charge rien d'un autre site : `require-corp` ne bloque rien. L'API (`/api/v1`) est sur la même origine.
  - Rien ne change pour `/reinitialisation`, qui garde `no-store`, `no-referrer`, sa CSP, `nosniff` et `DENY`, ni pour `/api`. La précompression (brotli, gzip) et la revalidation (`no-cache`) restent en place.
- **Chargement des lieux sur le fil principal** (`frontend/scripts/transition.gd`).
  - La scène se charge d'un bloc avec `ResourceLoader.load`, une fois le titre affiché, comme avant. La musique continue pendant ce temps.
  - Le chargement en arrière-plan (`load_threaded_request`) a été mesuré, et il est **bien plus lent** avec les fils d'exécution : 99 s au lieu de 18 s pour le hub, et 356 s au lieu de 56 s pour le Désert.
  - Pourquoi : le rendu Compatibility tourne sur le fil principal. Chaque texture ou maillage créé par le fil de chargement attend donc l'image suivante.
  - Sans fils, `load_threaded_request` chargeait de toute façon d'un bloc.
- **Musique préchargée** (`Music.prefetch`, `frontend/scripts/music.gd`).
  - La piste du lieu de destination se charge en arrière-plan, sous le titre, en même temps que la scène. Un fichier OGG ne touche pas au rendu.
  - `play()` la trouve prête et ne bloque plus l'image où le lieu apparaît.
- **GitHub Pages** (`deploy-web.yml`). Pages n'envoie pas d'en-têtes d'isolation : ce workflow repasse donc l'export sans fils avant d'exporter. Le jeu y fonctionne comme avant.

## Navigateurs

L'export avec fils d'exécution demande :

- un contexte sécurisé, donc HTTPS (ou `localhost`) ;
- l'isolation (COOP et COEP) ;
- `SharedArrayBuffer` et l'AudioWorklet.

Vérifié le 8 novembre, sur un serveur sans carte graphique (rendu logiciel), avec l'export identique à la production. Le détail, les causes et le banc sont dans `docs/navigateurs.md`.

| Navigateur | Version minimale | Version vérifiée | Ce qui marche | Ce qui ne marche pas, ou n'a pas pu être vérifié |
| --- | --- | --- | --- | --- |
| Chrome, Edge, Opera | 92 | Chromium 156 | Isolation, menu, son au premier clic, `musique.pck` monté. Bunker, roi et Merlon (E), sortie, hub, Plaine et sa musique. Clavier (ZQSD/WASD, E, H, Échap), souris capturée, caméra à la souris | Avec une fenêtre, le processus graphique (SwiftShader, rendu logiciel) s'est arrêté deux fois au premier dessin du hub dehors, pas sans fenêtre. Le joueur voit maintenant un message en français avec un bouton pour recharger, au lieu d'un écran noir |
| Safari, macOS | 15.2 | WebKit 27.2 sous Linux (moteur de Safari) | Comme Chromium, **après correction du type des `.pck` dans le Caddyfile** : sans elle, le jeu ne démarrait pas si le paquet arrivait en gzip (HTTP, ou proxy sans brotli). Souris capturée | 16 erreurs WebGL au menu (`glBlitFramebuffer`), sans effet visible. Caméra à la souris non vérifiable avec l'outil. Safari lui-même (Mac) non testé |
| Firefox | 79 | Firefox 157 | Isolation, menu, son au premier clic, `musique.pck` monté, écran d'introduction. Avec un rendu logiciel lent (softpipe) : bunker, clavier, E, H, Échap, souris capturée, caméra à la souris | Avec le rendu logiciel habituel du banc (llvmpipe), Firefox plante au premier dessin : défaut du pilote logiciel. Hub et Plaine non parcourus. À essayer sur un vrai PC |
| Safari, iOS et iPadOS | 15.2 | Non testé | | Mémoire plus limitée. Le jeu reste fait pour l'ordinateur (clavier et souris) |

Le jeu ne démarre pas si la page n'est pas isolée :

- derrière un autre proxy qui retire les en-têtes ;
- dans une iframe d'un autre site ;
- en HTTP, sauf sur `localhost`.

La page du jeu (`frontend/web/shell.html`) affiche alors, en français, ce qui manque et ce que le joueur peut faire, puis le texte de Godot (« The following features required to run Godot projects on the Web are missing: Cross-Origin Isolation… »). Elle fait de même sans WebGL 2, et si l'affichage est perdu en cours de partie. Pour vérifier les en-têtes :

```
curl -sI https://codequest.anthonyferron.com/ | grep -i cross-origin
```

Pour revenir à l'export sans fils :

1. Remettre `variant/thread_support=false` dans `frontend/export_presets.cfg`.
2. Remettre `'templates/web_nothreads_*'` dans `frontend/Dockerfile`.

Le code fonctionne dans les deux modes. Les en-têtes COOP et COEP peuvent rester : ils ne gênent pas l'export sans fils.

## Mesures

Ces mesures viennent d'un Chromium sans écran (Playwright), avec un rendu WebGL logiciel (SwiftShader), sur le serveur arm64. On y tourne entre 1 et 2 images par seconde dans les lieux : les durées absolues sont bien plus longues que sur une vraie carte graphique. Il faut surtout comparer avant et après.

Comment les mesures ont été faites :

- Le jeu est servi par le vrai Caddyfile, dans un conteneur jetable, sur un réseau Docker privé, avec une API morte.
- Un pilote, ajouté seulement à l'export de mesure, enchaîne les vraies transitions : menu, hub, Plaine, Désert, Marais, Village. Il reste 8 s dans chaque lieu.
- « Musique jouée » compare l'avancée de la piste en cours (`get_playback_position`) au temps écoulé. 100 % veut dire que la musique n'a pas décroché.
- Les longues tâches (plus de 50 ms) viennent de `PerformanceObserver`.
- Après, le worklet audio est aussi instrumenté : 0 quantum de 128 échantillons rendu sans données sur toute la session. Avant, sans fils, ce relevé n'est pas possible.

| Phase | Durée avant | Durée après | Plus longue tâche avant / après | Musique jouée avant | Musique jouée après |
| --- | --- | --- | --- | --- | --- |
| Démarrage jusqu'au menu | 3,2 s | 3,6 s | - | - | - |
| Menu, 8 s | - | - | 106 / 124 ms | 99 % | 100 % |
| Chargement : Hub | 18,1 s | 18,6 s | 5110 / 5018 ms | 10 % | 100 % |
| En jeu, 8 s : Hub | - | - | 2050 / 1367 ms | 16 % | 100 % |
| Chargement : Plaine | 64,2 s | 64,5 s | 31707 / 31587 ms | 2 % | 100 % |
| En jeu, 8 s : Plaine | - | - | 735 / 728 ms | 9 % | 100 % |
| Chargement : Désert | 56,1 s | 56,2 s | 22681 / 22624 ms | 2 % | 100 % |
| En jeu, 8 s : Désert | - | - | 592 / 1075 ms | 14 % | non relevé (la piste a bouclé), 0 ms de silence au worklet |
| Chargement : Marais | 47,4 s | 47,0 s | 15643 / 15486 ms | 2 % | 100 % |
| En jeu, 8 s : Marais | - | - | 1621 / 809 ms | 8 % | 100 % |
| Chargement : Village | 70,4 s | 69,1 s | 33926 / 34332 ms | 2 % | 100 % |
| En jeu, 8 s : Village | - | - | 3199 / 1344 ms | 3 % | 100 % |

Ce qu'on en retient :

- **Le son ne décroche plus.** Sans fils, la musique ne jouait que 2 à 16 % du temps pendant les chargements et dans les lieux : chaque image lente la coupait. Avec les fils, elle joue 100 % du temps, chargements compris.
- **Les durées de chargement sont les mêmes.** Les longues tâches restent, mais elles ne touchent plus le son.
- **Le chargement en arrière-plan a été essayé, puis écarté** : 99 s au lieu de 18 s pour le hub, 356 s au lieu de 56 s pour le Désert, 418 s au lieu de 47 s pour le Marais.
- **Le préchauffage des shaders a été essayé, puis écarté.** Sous le noir, il dessinait tout le décor une fois. Il ajoutait de 2 à 19 s par lieu dans cette mesure, sans gain mesurable en rendu logiciel. Avec les fils, une compilation de shader ne coupe de toute façon plus la musique.
- **Les shaders sont maintenant préparés au menu d'accueil**, hors de l'écran et par petites tranches, sans rien ajouter aux transitions : voir `docs/shaders-menu.md`.
- **La musique des lieux arrive maintenant après le menu**, dans un second paquet (`musique.pck`) que le navigateur télécharge en arrière-plan : le menu s'affiche plus tôt. Voir `docs/musique-differee.md`.

Les outils et les relevés sont dans `.claude/captures/perf-web/` (hors dépôt).
