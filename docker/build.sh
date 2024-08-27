#!/usr/bin/env bash

set -eo pipefail
cd "$( dirname "${BASH_SOURCE[0]}" )"

REGISTRY="nvcr.io"
REPOSITORY="nvstaging/tao/data_services_base_image"

TAG="$USER-$(date +%Y%m%d%H%M)"
LOCAL_TAG="$USER"

BUILD_DOCKER="0"
PUSH_DOCKER="0"
FORCE="0"

# Parse command line.
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -b|--build)
    BUILD_DOCKER="1"
    shift
    ;;
    -p|--push)
    PUSH_DOCKER="1"
    shift
    ;;
    -f|--force)
    FORCE=1
    shift
    ;;
    --default)
    BUILD_DOCKER="1"
    PUSH_DOCKER="0"
    FORCE="0"
    shift
    ;;
    *)
    POSITIONAL+=("$1")
    shift
    ;;
esac
done

# Build docker
if [ $BUILD_DOCKER = "1" ]; then
    echo "Building base docker ..."
    if [ $FORCE = "1" ]; then
        echo "Forcing docker build without cache ..."
        NO_CACHE="--no-cache"
    else
        NO_CACHE=""
    fi
    DOCKER_BUILDKIT=1 docker build --pull -f $NV_TAO_DS_TOP/docker/Dockerfile -t $REGISTRY/$REPOSITORY:$LOCAL_TAG $NO_CACHE \
        --network=host $NV_TAO_DS_TOP/.

    if [ $PUSH_DOCKER = "1" ]; then
        echo "Pusing docker ..."
        docker tag $REGISTRY/$REPOSITORY:$LOCAL_TAG $REGISTRY/$REPOSITORY:$TAG
        docker push $REGISTRY/$REPOSITORY:$TAG
        digest=$(docker inspect --format='{{index .RepoDigests 0}}' $REGISTRY/$REPOSITORY:$TAG)
        echo -e "\033[1;33mUpdate the digest in the manifest.json file to:\033[0m"
        echo $digest
    else
        echo "Skip pushing docker ..."
    fi
# Exit by printing usage.
else
    echo "Usage: ./build.sh --build [--push] [--force]"
fi