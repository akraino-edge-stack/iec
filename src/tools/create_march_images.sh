#!/bin/bash

set -eux

registry=${1:-iecedge/sriov-cni:ba420ed48a87033a91c9f825d3581f60046a2ae8}
ARCHES="${ARCHES:-amd64 arm64}"
IFS=" " read -r -a __arches__ <<< "$ARCHES"

images=()
for arch in "${__arches__[@]}"; do
    image="${registry}-${arch}"
    #kind build node-image --image="${image}" --arch="${arch}" "${kdir}"
    images+=("${image}")
done

export DOCKER_CLI_EXPERIMENTAL=enabled

# images must be pushed to be referenced by docker manifest
# we push only after all builds have succeeded
#for image in "${images[@]}"; do
#    docker push "${image}"
#done

docker manifest rm "${registry}" || true
docker manifest create "${registry}" "${images[@]}"
docker manifest push "${registry}"

echo "Now check the manifest information:"
docker manifest inspect "${registry}"

