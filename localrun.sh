#!/bin/sh
DEBUG=true
BRANCH_NAME=lineage-16.0
TARGET_DEVICE="js01lte"

docker run \
    -e BRANCH_NAME=$BRANCH_NAME \
    -v /build/ccache:/lineage/ccache \
    -v /build/src1:/lineage/src \
    -v /build/out:/lineage/out \
    -v $(pwd)/local_manifests:/lineage/src/.repo/local_manifests \
    -w /lineage/src \
    --user root \
    -e DEBUG=$DEBUG \
    docker.io/yasu-hide/build_lineageos $TARGET_DEVICE
