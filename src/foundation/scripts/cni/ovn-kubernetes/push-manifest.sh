#!/bin/bash

#Supported platforms of multi-arch images are: amd64 arm64
LINUX_ARCH=(amd64 arm64)
PLATFORMS=linux/${LINUX_ARCH[0]}
for i in $(seq 1  $[${#LINUX_ARCH[@]}-1])
do
    PLATFORMS=$PLATFORMS,linux/${LINUX_ARCH[$i]}
done

IMAGES_OVN=("ovn-daemonset")
#IMAGES_OVN=("ovn-daemonset" "ovn-daemonset-u")
BRANCH_TAG=latest

#Before push, 'docker login' is needed
push_multi_arch(){

       if [ ! -f "./manifest-tool" ]
       then
                sudo apt-get install -y jq
                wget https://github.com/estesp/manifest-tool/releases/download/v0.9.0/manifest-tool-linux-${BUILDARCH} \
                -O manifest-tool && \
                chmod +x ./manifest-tool
       fi

       for IMAGE in "${IMAGES_OVN[@]}"
       do
         echo "multi arch image: ""iecedge/${IMAGE}"
         ./manifest-tool push from-args --platforms ${PLATFORMS} --template iecedge/${IMAGE}-ARCH:${BRANCH_TAG} \
                --target iecedge/${IMAGE}:${BRANCH_TAG}
       done
}

echo "Push fat manifest for multi-arch images:"
push_multi_arch

