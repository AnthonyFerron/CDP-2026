# Licences

Liste de tout ce que le projet utilise et qui n'a pas été créé pour lui. À mettre à jour dès qu'un élément externe est ajouté.

## Jeu

### Contenu du projet

| Élément | Origine | Licence |
| --- | --- | --- |
| Code GDScript, scènes, `icon.svg` | Créés pour le projet | Aucune licence choisie : tous droits réservés par défaut |
| Modèles 3D et leurs textures | Kits Kenney, listés ci-dessous | CC0 1.0 |
| Sons du jeu (vent, lave, marais, désert, cave, hub, village, ruisseau, pas, feu, porte, tablettes) | Générés pour le projet par `frontend/tools/generate_sounds.py` | Comme le code du projet |
| Musiques, dans `frontend/assets/audio/music/` | Pixabay Music, NullRights, OpenGameArt, et une piste sans auteur tiers, listées dans la section Musiques ci-dessous | Voir la section Musiques |
| Polices : Cinzel (titres et boutons), Lora (textes) | [Google Fonts](https://github.com/google/fonts), dans `frontend/assets/fonts/` avec leur licence | SIL Open Font License 1.1 |

Pour chaque modèle, texture, son ou police venant de l'extérieur, ajouter une ligne ici avec son auteur, sa source et sa licence.

| Fichier | Auteur | Source | Licence |
| --- | --- | --- | --- |
| `frontend/assets/models/kenney/3d_road_tiles/` : 3D Road Tiles | Kenney Vleugels pour Kenney | [kenney.nl](https://kenney.nl/assets) | CC0 1.0 |
| `frontend/assets/models/kenney/castle_kit/` : Castle Kit 2.0 | Kenney | [kenney.nl](https://kenney.nl/assets) | CC0 1.0 |
| `frontend/assets/models/kenney/fantasy_town_kit/` : Fantasy Town Kit 2.0 | Kenney | [kenney.nl](https://kenney.nl/assets) | CC0 1.0 |
| `frontend/assets/models/kenney/food_kit/` : Food Kit 2.0 | Kenney | [kenney.nl](https://kenney.nl/assets) | CC0 1.0 |
| `frontend/assets/models/kenney/furniture_kit/` : Furniture Kit 2.0 | Kenney | [kenney.nl](https://kenney.nl/assets) | CC0 1.0 |
| `frontend/assets/models/kenney/graveyard_kit/` : Graveyard Kit 5.0 | Kenney | [kenney.nl](https://kenney.nl/assets) | CC0 1.0 |
| `frontend/assets/models/kenney/mini_arena/` : Mini Arena 1.1 | Kenney, Tony Schär | [kenney.nl](https://kenney.nl/assets) | CC0 1.0 |
| `frontend/assets/models/kenney/mini_dungeon/` : Mini Dungeon 2.0 | Kenney | [kenney.nl](https://kenney.nl/assets) | CC0 1.0 |
| `frontend/assets/models/kenney/mini_forest/` : Mini Forest 1.0 | Kenney | [kenney.nl](https://kenney.nl/assets) | CC0 1.0 |
| `frontend/assets/models/kenney/modular_dungeon_kit/` : Modular Dungeon Kit 2.1 | Kenney | [kenney.nl](https://kenney.nl/assets) | CC0 1.0 |
| `frontend/assets/models/kenney/nature_kit/` : Nature Kit 2.1 | Kenney | [kenney.nl](https://kenney.nl/assets) | CC0 1.0 |
| `frontend/assets/models/kenney/survival_kit/` : Survival Kit 2.0 | Kenney | [kenney.nl](https://kenney.nl/assets) | CC0 1.0 |

Le fichier `License.txt` de chaque kit est conservé dans son dossier. Le créditer n'est pas obligatoire, mais Kenney le demande à titre de soutien.

### Musiques

Les fichiers de `frontend/assets/audio/music/` sont réencodés en OGG Vorbis (qualité 4) pour alléger le jeu web, à leur fréquence d'échantillonnage et avec leurs canaux d'origine.

| Fichier | Titre | Auteur | Source | Licence |
| --- | --- | --- | --- | --- |
| `menu.ogg` | Epic Medieval | Kulakovka | [Pixabay Music](https://pixabay.com/music/adventure-epic-medieval-614879/) | Licence de contenu Pixabay |
| `intro.ogg` | Main Menu 2 | Kresiek The Furry | [NullRights](https://nullrights.com/track/m7yv9dk218) | CC0 1.0 |
| `hub.ogg` | Medieval 5 | Tozan | [OpenGameArt](https://opengameart.org/content/medieval-5) | licence OpenGameArt à confirmer |
| `plaine.ogg` | Volkano Part I | Nestor Dionis | [Pixabay Music](https://pixabay.com/music/dubstep-volkano-part-l-124659/) | Licence de contenu Pixabay |
| `desert.ogg` | — | Musique générée par IA, sans auteur tiers | — | — |
| `marais.ogg` | Cool Scary Background Track | Brolefilmer | [Pixabay Music](https://pixabay.com/music/horror-scene-cool-scary-background-track-by-brolefilmer-13959/) | Licence de contenu Pixabay |
| `village.ogg` | Village Countryside Harvest Morning | Alex Morgan | [Pixabay Music](https://pixabay.com/fr/music/pays-moderne-village-countryside-harvest-morning-578488/) | Licence de contenu Pixabay |
| `victoire.ogg` | Victory | Alex Morgan | [Pixabay Music](https://pixabay.com/music/marching-band-victory-591331/) | Licence de contenu Pixabay |
| `defaite.ogg` | KL Peach Game Over II | Lightyeartraxx | [Pixabay Music](https://pixabay.com/music/video-games-kl-peach-game-over-ii-135684/) | Licence de contenu Pixabay |

Licences :

- **Pixabay Music**, https://pixabay.com/music/ : licence de contenu Pixabay, https://pixabay.com/service/license-summary/ (texte complet : https://pixabay.com/service/terms/). Utilisation gratuite, commerciale ou non, sans attribution obligatoire. La revente ou la redistribution d'une piste seule est interdite.
- **NullRights**, https://nullrights.com/ : CC0 1.0 universel (domaine public), https://creativecommons.org/publicdomain/zero/1.0/ (présentation : https://nullrights.com/about).

### Moteur

| Composant | Version | Licence |
| --- | --- | --- |
| [Godot Engine](https://godotengine.org/license/) | 4.7.2 | MIT |

Le jeu exporté contient le moteur et les bibliothèques ci-dessous. Voici les principales :

| Bibliothèque | Rôle | Licence |
| --- | --- | --- |
| Jolt Physics | Physique | MIT |
| FreeType | Rendu des polices | FreeType License |
| HarfBuzz | Mise en forme du texte | Licence HarfBuzz (MIT ancienne) |
| ICU | Données Unicode | Licence Unicode |
| Graphite | Mise en forme du texte | MIT |
| Open Sans, Noto Sans | Polices du moteur | SIL OFL 1.1 |
| ENet | Réseau | MIT |
| Mbed TLS | Chiffrement | Apache 2.0 |
| Recast | Navigation | zlib |
| OggVorbis | Audio | BSD 3-Clause |
| Quite OK Audio | Audio | MIT |
| Basis Universal | Textures | Apache 2.0 |
| Brotli | Compression | MIT |
| WebP | Images | BSD 3-Clause |

La liste complète, avec les auteurs et le texte de chaque licence, se trouve dans [COPYRIGHT.txt](https://github.com/godotengine/godot/blob/4.7.2-stable/COPYRIGHT.txt). Elle est aussi publiée avec le jeu web, dans `GODOT_LICENSE.txt` et `GODOT_COPYRIGHT.txt`.

Portions of this software are copyright © 1996-2025 The FreeType Project (www.freetype.org). All rights reserved.

### Licence de Godot Engine

```text
Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md).
Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Backend

Ces éléments servent au backend et ne sont pas inclus dans le jeu exporté. Les versions sont fixées dans `backend/requirements.txt`, et les licences viennent des métadonnées PyPI de ces versions.

| Licence | Paquets Python |
| --- | --- |
| MIT | agent-detector, annotated-doc, annotated-types, anyio, charset-normalizer, fastapi, fastapi-cli, fastapi-cloud-cli, fastar, h11, httptools, markdown-it-py, mdurl, pydantic, pydantic-extra-types, pydantic-settings, pydantic_core, PyYAML, rich, rich-toolkit, rignore, sentry-sdk, SQLAlchemy, truststore, typer, typing-inspection, urllib3, watchfiles |
| BSD 3-Clause | click, httpcore, httpcore2, httpx, httpx2, idna, Jinja2, MarkupSafe, protobuf, python-dotenv, starlette, uvicorn, websockets |
| BSD 2-Clause | Pygments |
| Apache 2.0 | googleapis-common-protos, opentelemetry-api, opentelemetry-exporter-http-transport, opentelemetry-exporter-otlp-common, opentelemetry-exporter-otlp-proto-common, opentelemetry-exporter-otlp-proto-http, opentelemetry-proto, opentelemetry-sdk, opentelemetry-semantic-conventions, python-multipart, requests |
| MIT ou Apache 2.0 | uvloop |
| ISC | dnspython, shellingham |
| 0BSD | detect-installer |
| MPL 2.0 | certifi |
| LGPL 3.0 | psycopg, psycopg-binary |
| PSF 2.0 | typing_extensions |
| Unlicense | email-validator |

| Service | Version | Licence |
| --- | --- | --- |
| PostgreSQL (`infrastructure/docker-compose.yml`) | 17 | PostgreSQL License |
| Caddy (`frontend/Dockerfile`) | 2 | Apache 2.0 |
