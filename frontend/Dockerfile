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

# Le moteur (index.wasm, 38,8 Mo) vient tel quel du modèle d'export : il est compressé ici, au plus fort (brotli 11 :
# 6,9 Mo au lieu de 7,9 au niveau 9, environ 100 s de calcul), dans une couche gardée en cache tant que Godot ne change
# pas. Après l'export, cette compression n'est reprise que si index.wasm est identique au fichier du modèle, octet pour
# octet. Voir docs/chargements-lieux.md.
RUN set -eu; \
    templates="/root/.local/share/godot/export_templates/${GODOT_VERSION}.stable"; \
    mkdir -p /wasm; \
    unzip -q -j "$templates/web_release.zip" '*.wasm' -d /wasm; \
    for wasm in /wasm/*.wasm; do brotli -k -q 11 "$wasm"; gzip -k -9 -n "$wasm"; done

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

# Compressé une fois ici, mieux et sans coût à chaque requête : Caddy sert directement les .br et .gz du jeu. Le moteur
# reprend la compression faite plus haut s'il n'a pas changé. gzip -n n'écrit ni nom ni date dans le fichier : un même
# fichier donne le même .gz d'une version à l'autre.
# Puis chaque fichier prend une date tirée de son contenu : Caddy calcule l'ETag de la date et de la taille, et un
# fichier inchangé d'une version à l'autre (le moteur, la musique) garde ainsi le même ETag. Le joueur qui revient
# après un déploiement reçoit « 304 Not Modified » au lieu de tout retélécharger. Ces dates ne servent qu'à cela : un
# navigateur qui a un ETag le présente (If-None-Match), et la date (If-Modified-Since) n'est alors pas regardée.
RUN set -eu; \
    cd /game/build/web; \
    for wasm in /wasm/*.wasm; do \
        if cmp -s index.wasm "$wasm"; then cp "$wasm.br" index.wasm.br; cp "$wasm.gz" index.wasm.gz; fi; \
    done; \
    for file in $(find . -type f \( -name '*.wasm' -o -name '*.pck' -o -name '*.js' -o -name '*.html' \)); do \
        [ -e "$file.br" ] || brotli -k -q 9 "$file"; \
        [ -e "$file.gz" ] || gzip -k -9 -n "$file"; \
    done; \
    for file in $(find . -type f); do \
        touch -d "@$(( 0x$(sha256sum "$file" | cut -c1-7) + 946684800 ))" "$file"; \
    done

FROM caddy:2

COPY --from=build /game/build/web /srv
# Page « nouveau mot de passe » du lien envoyé par e-mail, hors du projet Godot (la modifier ne relance pas
# l'export), avec les polices des menus du jeu et leur licence.
COPY infrastructure/web/reinitialisation /srv/reinitialisation
COPY frontend/assets/fonts/Cinzel.ttf frontend/assets/fonts/Cinzel-OFL.txt \
     frontend/assets/fonts/Lora.ttf frontend/assets/fonts/Lora-OFL.txt /srv/reinitialisation/
COPY infrastructure/Caddyfile /etc/caddy/Caddyfile
