ARG TAG=latest
ARG IMAGEBASE=iecedge/iec-apiserver-base
ARG IMAGEFROM=${IMAGEBASE}:${TAG}
FROM ${IMAGEFROM} as builder
ADD ./apiserver $GOPATH/src/apiserver
RUN revel package apiserver -m prod && \
    mkdir -p /opt/apiserver && \
    tar xf $GOPATH/src/apiserver/apiserver.tar.gz -C /opt/apiserver

FROM alpine:3.10.1
COPY --from=builder /opt/apiserver /opt/apiserver
ENTRYPOINT ["/opt/apiserver/run.sh"]
