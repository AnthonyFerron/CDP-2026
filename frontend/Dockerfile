# Exporte le jeu pour le web, puis le sert avec Caddy. Le contexte de build est la racine du dépôt.
FROM debian:trixie-slim AS build

ARG GODOT_VERSION=4.7.2

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl unzip libfontconfig1 \
    && rm -rf /var/lib/apt/lists/*

# Téléchargé avant de copier le jeu, pour rester en cache d'un déploiement à l'autre
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
    unzip -q -j /tmp/templates.tpz 'templates/web_nothreads_*' 'templates/version.txt' -d "$templates"; \
    rm /tmp/godot.zip /tmp/templates.tpz; \
    mkdir -p /licences; \
    base="https://raw.githubusercontent.com/godotengine/godot/${GODOT_VERSION}-stable"; \
    curl -fsSL -o /licences/GODOT_LICENSE.txt "$base/LICENSE.txt"; \
    curl -fsSL -o /licences/GODOT_COPYRIGHT.txt "$base/COPYRIGHT.txt"

COPY frontend /game
COPY LICENCES.md /licences/

RUN mkdir -p /game/build/web \
    && godot --headless --path /game --import \
    && godot --headless --path /game --export-debug "Web" build/web/index.html \
    && test -f /game/build/web/index.html \
    && cp /licences/* /game/build/web/

FROM caddy:2

COPY --from=build /game/build/web /srv
COPY infrastructure/Caddyfile /etc/caddy/Caddyfile
