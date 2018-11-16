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

VOLUME $SRC_DIR
VOLUME $CCACHE_DIR
VOLUME $OUT_DIR

WORKDIR $SRC_DIR
COPY build.sh /
ENTRYPOINT /build.sh
