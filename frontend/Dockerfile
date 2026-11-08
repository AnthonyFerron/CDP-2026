# Exporte le jeu pour le web, puis le sert avec Caddy. Le contexte de build est la racine du dépôt.
FROM debian:trixie-slim AS build

ARG GODOT_VERSION=4.7.2

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl unzip libfontconfig1 brotli \
    && rm -rf /var/lib/apt/lists/*

# Téléchargé avant de copier le jeu, pour rester en cache d'un déploiement à l'autre. Modèles web avec fils
# d'exécution (web_release, web_debug) : le son est mixé sur son propre fil, une image lente ne le hache plus.
# Ils exigent une page isolée (COOP et COEP, infrastructure/Caddyfile). Voir docs/web-threads.md.
RUN set -eu; \
    case "$(uname -m)" in \
        aarch64) arch=arm64 ;; \
        x86_64) arch=x86_64 ;; \
        *) echo "Architecture non prise en charge" >&2; exit 1 ;; \
    esac; \
    base="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable"; \
    curl -fsSL -o /tmp/godot.zip "$base/Godot_v${GODOT_VERSION}-stable_linux.$arch.zip"; \
    unzip -q /tmp/godot.zip -d /opt/godot; \
    mv "/opt/godot/Godot_v${GODOT_VERSION}-stable_linux.$arch" /usr/local/bin/godot; \
    curl -fsSL -o /tmp/templates.tpz "$base/Godot_v${GODOT_VERSION}-stable_export_templates.tpz"; \
    templates="/root/.local/share/godot/export_templates/${GODOT_VERSION}.stable"; \
    mkdir -p "$templates"; \
    unzip -q -j /tmp/templates.tpz 'templates/web_release.zip' 'templates/web_debug.zip' 'templates/version.txt' -d "$templates"; \
    rm /tmp/godot.zip /tmp/templates.tpz; \
    mkdir -p /licences; \
    base="https://raw.githubusercontent.com/godotengine/godot/${GODOT_VERSION}-stable"; \
    curl -fsSL -o /licences/GODOT_LICENSE.txt "$base/LICENSE.txt"; \
    curl -fsSL -o /licences/GODOT_COPYRIGHT.txt "$base/COPYRIGHT.txt"

COPY frontend /game
COPY LICENCES.md /licences/

# Second paquet (préréglage « Web musique ») : les pistes des lieux, de la victoire et de la défaite, que le jeu
# télécharge en arrière-plan une fois le menu affiché (scripts/music.gd). Le paquet du jeu n'a que celles du menu, de
# l'introduction et du hub : le menu arrive plus vite. Voir docs/musique-differee.md. Le .gdignore garde build/ hors
# du projet : sans lui, le second export importerait les images que le premier vient d'y écrire.
RUN mkdir -p /game/build/web \
    && touch /game/build/.gdignore \
    && godot --headless --path /game --import \
    && godot --headless --path /game --export-release "Web" build/web/index.html \
    && godot --headless --path /game --export-pack "Web musique" build/web/musique.pck \
    && test -f /game/build/web/index.html \
    && test -f /game/build/web/musique.pck \
    && cp /licences/* /game/build/web/

# Compressé une fois ici, mieux et sans coût à chaque requête : Caddy sert directement les .br et .gz du jeu.
RUN find /game/build/web -type f \( -name '*.wasm' -o -name '*.pck' -o -name '*.js' -o -name '*.html' \) \
        -exec gzip -k -9 {} \; -exec brotli -k -q 9 {} \;

FROM caddy:2

COPY --from=build /game/build/web /srv
# Page « nouveau mot de passe » du lien envoyé par e-mail, hors du projet Godot (la modifier ne relance pas
# l'export), avec les polices des menus du jeu et leur licence.
COPY infrastructure/web/reinitialisation /srv/reinitialisation
COPY frontend/assets/fonts/Cinzel.ttf frontend/assets/fonts/Cinzel-OFL.txt \
     frontend/assets/fonts/Lora.ttf frontend/assets/fonts/Lora-OFL.txt /srv/reinitialisation/
COPY infrastructure/Caddyfile /etc/caddy/Caddyfile
