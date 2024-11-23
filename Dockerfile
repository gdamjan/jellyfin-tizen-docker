# syntax=docker/dockerfile:1

# Reusable image with tizen-studio
FROM ubuntu:24.04 AS tizen-studio

ARG TIZEN_STUDIO_VER=6.0

# Install tizen-studio
RUN --mount=type=tmpfs,target=/tmp <<EOT
  set -ex
  apt-get update
  apt-get -y install curl
  curl -L https://download.tizen.org/sdk/Installer/tizen-studio_${TIZEN_STUDIO_VER}/web-cli_Tizen_Studio_${TIZEN_STUDIO_VER}_ubuntu-64.bin -o /tmp/tizen.bin
  chmod +x /tmp/tizen.bin
  runuser -u ubuntu -- /tmp/tizen.bin --accept-license /home/ubuntu/tizen-studio
EOT

USER ubuntu
ENV PATH=${PATH}:/home/ubuntu/tizen-studio/tools/ide/bin:/home/ubuntu/tizen-studio/tools

RUN tizen certificate --alias "Jellyfin" --password "Ho5osiek^%xeeZuCh5"
#RUN tizen security-profiles add --name "default" \
#    --author tizen-studio-data/keystore/author/author.p12 \
#    --password "Ho5osiek^%xeeZuCh5"
COPY ./profiles.xml /home/ubuntu/tizen-studio-data/profile/profiles.xml


# Build jellyfin-web
FROM node:22 AS jellyfin-web

ARG WEB_VER=v10.10.3

ADD https://github.com/jellyfin/jellyfin-web.git#${WEB_VER} /src/jellyfin-web

WORKDIR /src/jellyfin-web
RUN SKIP_PREPARE=1 npm ci --no-audit --no-fund --no-update-notifier
RUN USE_SYSTEM_FONTS=1 npm run build:production


# Build jellyfin-tizen
FROM node:22 AS jellyfin-tizen

ADD https://github.com/jellyfin/jellyfin-tizen.git#master /src/jellyfin-tizen

WORKDIR /src/jellyfin-tizen
COPY --from=jellyfin-web /src/jellyfin-web/dist/ ./dist/
RUN JELLYFIN_WEB_DIR=./dist npm ci --no-audit --no-fund --no-update-notifier


# Build tizen package (wgt)
FROM tizen-studio AS package-wgt

# Copy built assets
USER ubuntu
WORKDIR /build
COPY --from=jellyfin-tizen --chown=ubuntu /src/jellyfin-tizen/config.xml ./config.xml
COPY --from=jellyfin-tizen --chown=ubuntu /src/jellyfin-tizen/icon.png ./icon.png
COPY --from=jellyfin-tizen --chown=ubuntu /src/jellyfin-tizen/index.html ./index.html
COPY --from=jellyfin-tizen --chown=ubuntu /src/jellyfin-tizen/tizen.js ./tizen.js
COPY --from=jellyfin-tizen --chown=ubuntu /src/jellyfin-tizen/www/ ./www/

# Build and sign Tizen App
RUN tizen build-web
RUN tizen package -t wgt -o . -- .buildResult

FROM tizen-studio
WORKDIR /app

COPY --from=package-wgt /build/Jellyfin.wgt ./Jellyfin.wgt
COPY --chmod=755 ./install-app.sh ./install-app.sh
ENTRYPOINT [ "./install-app.sh" ]
