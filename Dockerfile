FROM debian:trixie-slim

LABEL org.opencontainers.image.authors="admin@minenet.at"
LABEL org.opencontainers.image.source="https://github.com/ich777/docker-owncast"

ARG DEBIAN_FRONTEND=noninteractive

# BtbN floating latest build.
# This URL always points at the latest successful master build.
ARG FFMPEG_ARCHIVE="ffmpeg-master-latest-linux64-gpl.tar.xz"
ARG FFMPEG_URL="https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/${FFMPEG_ARCHIVE}"

#
# Base utilities + modern Intel VAAPI/QSV stack.
#
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        wget \
        jq \
        unzip \
        xz-utils \
        passwd \
        util-linux \
        libdrm2 \
        libva2 \
        libva-drm2 \
        libva-x11-2 \
        intel-media-va-driver \
        libigdgmm12 \
        libvpl2 \
        libmfx-gen1.2 \
        vainfo && \
    update-ca-certificates && \
    rm -rf /var/lib/apt/lists/*

#
# Download the newest BtbN FFmpeg GPL static build.
#
# The find commands make this independent of the top-level
# directory name used inside the BtbN archive.
#
RUN mkdir -p /tmp/ffmpeg-extract && \
    wget \
        --progress=dot:giga \
        -O /tmp/ffmpeg.tar.xz \
        "${FFMPEG_URL}" && \
    tar -xJf /tmp/ffmpeg.tar.xz -C /tmp/ffmpeg-extract && \
    FFMPEG_BIN="$(find /tmp/ffmpeg-extract -type f -path '*/bin/ffmpeg' -print -quit)" && \
    FFPROBE_BIN="$(find /tmp/ffmpeg-extract -type f -path '*/bin/ffprobe' -print -quit)" && \
    test -n "${FFMPEG_BIN}" && \
    test -n "${FFPROBE_BIN}" && \
    install -m 0755 "${FFMPEG_BIN}" /usr/local/bin/ffmpeg && \
    install -m 0755 "${FFPROBE_BIN}" /usr/local/bin/ffprobe && \
    rm -rf /tmp/ffmpeg.tar.xz /tmp/ffmpeg-extract && \
    ffmpeg -version && \
    ffmpeg -hide_banner -encoders | grep -E 'h264_(vaapi|qsv)' || true

#
# Intel VAAPI driver.
#
ENV LIBVA_DRIVER_NAME=iHD

ENV DATA_DIR=/owncast
ENV START_PARAMS=""
ENV OWNCAST_V="latest"
ENV UMASK=000
ENV UID=99
ENV GID=100
ENV DATA_PERM=770
ENV USER="owncast"

RUN mkdir -p "${DATA_DIR}" && \
    groupadd -r owncast && \
    useradd \
        -d "${DATA_DIR}" \
        -s /bin/bash \
        -g owncast \
        owncast && \
    chown -R owncast:owncast "${DATA_DIR}"

ADD /scripts/ /opt/scripts/

RUN chmod -R 770 /opt/scripts/

ENTRYPOINT ["/opt/scripts/start.sh"]
