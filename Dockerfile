FROM docker.io/lineageos/android_build
MAINTAINER yasu-hide

ENV USER root
ENV SRC_DIR /lineage/src
ENV CCACHE_DIR /lineage/ccache
ENV OUT_DIR /lineage/out

ENV USE_CCACHE 1
ENV CCACHE_SIZE "50G"
ENV CCACHE_COMPRESS 1

ENV GIT_USER_NAME "LineageOS Buildbot"
ENV GIT_USER_MAIL "lineageos-buildbot@docker.host"

ENV ANDROID_JACK_VM_ARGS "-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4G"

USER $USER
RUN apt-get update && apt-get install -y \
    bc bison build-essential \
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

VOLUME $SRC_DIR
VOLUME $CCACHE_DIR
VOLUME $OUT_DIR

WORKDIR $SRC_DIR
COPY build.sh /
ENTRYPOINT ["/build.sh"]
