#########################################################################
# File Name: loadimages.sh
# Author   : rd-sw
# email    : rd-sw@ysemi.cn
# Created Time: 2022-04-27 10:04
#########################################################################
#!/bin/bash

IMAGES_DIR=~/images
IMAGE_MOUNT_DIR=${IMAGES_DIR}/images/android
mkdir -p ${IMAGES_DIR}/images/android

if [ ! -e /dev/binder1 ]; then
    echo "try to insmod binder"
    sudo modprobe ashmem_linux
    sudo rmmod binder_linux || true; sudo modprobe binder_linux num_devices=254
    sudo chmod 777 /dev/ashmem /dev/binder*
else
    echo "binder already loaded"
fi

if [[ `sudo docker images -a | grep robox` ]]; then
    echo "robox images already loaded"
else
    sudo mount ${IMAGES_DIR}/android.img ${IMAGE_MOUNT_DIR}
    cd ${IMAGE_MOUNT_DIR}
    sudo tar --numeric-owner -cf- . | sudo docker import - android:robox
    sleep 1
    if [[ `sudo docker images -a | grep robox` ]]; then
        echo "docker image loads successfully!"
    fi
fi
