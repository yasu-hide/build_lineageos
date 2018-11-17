#!/bin/sh
DEBUG=true
BRANCH_NAME=lineage-16.0

docker run \
    -e BRANCH_NAME=$BRANCH_NAME \
    -v /build/ccache:/lineage/ccache \
    -v /build/src1:/lineage/src \
    -v /build/out:/lineage/out \
    -v $(pwd)/local_manifests:/lineage/src/.repo/local_manifests \
    --ulimit nproc=32768  --ulimit nofile=1048576 \
    --user root \
    -e DEBUG=$DEBUG \
    docker.io/yasu-hide/build_lineageos $*
