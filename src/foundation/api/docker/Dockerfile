ARG TAG=latest
ARG IMAGEBASE=iecedge/iec-apiserver-base
ARG IMAGEFROM=${IMAGEBASE}:${TAG}
FROM ${IMAGEFROM}
ADD ./apiserver $GOPATH/src/apiserver
ENTRYPOINT ["/bin/bash", "-c", "revel run apiserver prod"]
