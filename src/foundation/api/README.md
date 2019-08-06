# Welcome to IEC API Server
The IEC API server is got from Revel web framework. So the following information are
inherited from [Revel](https://github.com/revel/revel).
It can support both x86_64 and arm64 platforms now.


## Usage of the Makefile

The Makefile here is this directory can be used to build apiserver images, push/multi-arch
built images to docker hub repo and clean local images

### Building IEC API Server Docker Image:

   make apiserver

## Install:

    kubectl create -f k8s/iecapi.yaml

## Check if it works:
    k8s/check.sh

