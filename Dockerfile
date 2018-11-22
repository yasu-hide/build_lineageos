FROM ubuntu:16.04 AS goma_client
ENV DEBIAN_FRONTEND noninteractive

# update, and install basic packages
RUN apt-get update \
    && apt-get install -y \
        build-essential \
        libxml2 \
        curl \
        git \
        python \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# install depot_tools http://www.chromium.org/developers/how-tos/install-depot-tools
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
ENV PATH /depot_tools:$PATH

RUN mkdir goma_packager
WORKDIR goma_packager
RUN gclient config https://chromium.googlesource.com/infra/goma/client
RUN gclient sync
RUN cd client \
    && gclient sync \
    && gn gen --args='is_debug=false' out/Release \
    && ninja -C out/Release


FROM docker.io/lineageos/android_build
MAINTAINER yasu-hide

ENV USER lineageos
ENV SRC_DIR /lineage/src
ENV CCACHE_DIR /lineage/ccache
ENV CCACHE_SIZE 20G
ENV ARTIFACT_OUT_DIR /lineage/out
ENV GOMA_DIR /lineage/goma

ENV GIT_USER_NAME "LineageOS Buildbot"
ENV GIT_USER_MAIL "lineageos-buildbot@docker.host"

ENV ANDROID_JACK_VM_ARGS "-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4G"

USER root
RUN apt-get update && apt-get install -y \
    bc bison build-essential \
    distcc distcc-pump \
    ccache curl \
    flex \
    g++-multilib gcc-multilib git gnupg gperf \
    imagemagick \
    lib32ncurses5-dev lib32readline-dev lib32z1-dev \
    liblz4-tool libncurses5-dev libsdl1.2-dev libssl-dev \
    libwxgtk3.0-dev libxml2 libxml2-utils lzop \
    pngcrush \
    rsync \
    schedtool squashfs-tools \
    xsltproc zip \
    zlib1g-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/* 
RUN groupadd -r -g 1000 buildbot && useradd -r -d /lineage -u 1000 -g buildbot $USER
RUN mkdir $SRC_DIR $CCACHE_DIR $ARTIFACT_OUT_DIR && chown -R 1000:1000 $SRC_DIR $CCACHE_DIR $ARTIFACT_OUT_DIR

# dirty hack for Python
RUN sed -i -e '1s%^#!/usr/bin/python2.4%#!/usr/bin/env python2%' /usr/lib/distcc-pump/include_server/*.py

VOLUME $SRC_DIR
VOLUME $CCACHE_DIR
VOLUME $ARTIFACT_OUT_DIR

COPY build.sh /
COPY --from=goma_client /goma_packager/client/out/Release $GOMA_DIR

USER $USER
WORKDIR $SRC_DIR
ENTRYPOINT ["/build.sh"]
